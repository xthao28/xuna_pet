# W4-M0 Spike Report — Draft Workspace, Non-Elevated Network Isolation & Crash-Safe Multi-File Apply on Windows

- **Date:** 2026-11-26 (Asia/Ho_Chi_Minh)
- **Status:** Measured on Windows 11 (not yet measured on macOS APFS — see §5 H8 disclosures)
- **Environment:** `Windows-11-10.0.22631-SP0`, Python `3.12.10` (`backend/.venv`), non-elevated user session (`IsUserAnAdmin() == False`), volume `C:\` (`NTFS`). All measurements ran inside an isolated temporary directory (`%LOCALAPPDATA%\Temp\xuna_w4m0_spike_*`) that was completely deleted on teardown (`0` repository code changes, `0` residual OS profiles or temp files).
- **Related:** [XUNA_UPGRADE_PLAN_2026-11-26.md](../roadmap/XUNA_UPGRADE_PLAN_2026-11-26.md) §4 (`W4-M0`, D4, D5), [ADR-0019](../decisions/ADR-0019-draft-workspace-and-effect-bound-approval.md).

---

## 1. Spike (a) — Workspace Copy Mechanism on Windows NTFS

### Question
What non-elevated copy mechanism can isolate a workspace draft on Windows without losing uncommitted/untracked files, corrupting the live workspace, or failing on non-Git folders?

### Test Workload
- **Repo A (Git project):** `500` tracked files (`~5.27 MB` source), `20` untracked files, `1` uncommitted dirty edit (`src/pkg_0/mod_000.txt`), `1` secret file (`.env`), plus `500` `.gitignore`d files in `node_modules/` (`~10 MB`).
- **Folder B (plain non-Git workspace):** `200` files (`~2.11 MB`).

### Measured Results (Windows 11, `C:\` NTFS)

| Mechanism | Time (Repo A) | Time (Folder B) | Preserves untracked & dirty edits | Works on non-Git | Safe against in-place writes | Notes / Measured Error |
| --- | --- | --- | --- | --- | --- | --- |
| **NTFS CoW (`FSCTL_DUPLICATE_EXTENTS_TO_FILE`)** | N/A | N/A | N/A | N/A | N/A | **Unsupported on NTFS:** `GetVolumeInformationW` flag `FILE_SUPPORTS_BLOCK_REFCOUNTING (0x04000000) == false`; `DeviceIoControl` failed with **Win32 error `1` (`ERROR_INVALID_FUNCTION`)**. Only ReFS / Dev Drive supports block cloning. |
| **`git worktree add --detach`** | `187.8 ms` | Failed (exit `128`) | **No** (`untracked=false`, `dirty=false`, `node_modules=false`) | **No** | Yes | Drops all uncommitted edits and untracked files; fails completely outside Git repos. |
| **Filtered physical copy** (skip `.git`, `node_modules`, `.venv`, `build`, `.dart_tool`, `target`, `__pycache__` + hard-skip `.env`, `*.pem`, `*.key`) | **`266.9 ms`** (`521` files, `5.27 MB`) | **`98.0 ms`** (`200` files, `2.11 MB`) | **Yes** (`untracked=true`, `dirty=true`) | **Yes** | **Yes** (`0` bytes changed in original after mutating draft) | Excludes secret files (`.env` absent in draft) and heavy build caches (`node_modules` absent). |
| **NTFS Hardlinks (`os.link` / `CreateHardLinkW`)** | N/A | N/A | N/A | Yes | **NO — CORRUPTS ORIGINAL** | Experimental proof: opening a hardlinked draft file with `r+b` and writing in-place immediately overwrote `hl_orig.txt` (`hardlink_inplace_corrupts_original == true`). **Permanently rejected.** |

### Recommendation for D5
- **Windows (and non-APFS filesystems):** Use **bounded filtered physical copy** (`maxFiles` / `maxBytes` cap, excluding heavy cache directories and all Hard-Deny/secret files) so both Git and non-Git workspaces work uniformly, uncommitted/untracked work is preserved, and the live workspace cannot lose a single byte during draft execution.
- **macOS (APFS — pending Mac verification):** Prefer APFS `clonefile` (skipping excluded/secret entries) when the source and draft temp dir are on the same APFS volume, falling back to filtered physical copy otherwise.
- **Never use hardlinks** for mutable draft files.

---

## 2. Spike (b) — Non-Elevated Network Isolation on Windows (`desktop/AGENTS.md` §3.7)

### Question
Can a non-elevated Windows Desktop Agent (`IsUserAnAdmin() == False`) reliably block outbound network access for arbitrary child dev tools (`node`, `python`, `git`, `flutter`, `pytest`) running inside a draft workspace?

### Measured Results (Windows 11, `IsUserAnAdmin() == False`)

| Approach | Runs without Admin? | Measured Result | Engineering Verdict |
| --- | --- | --- | --- |
| **Windows Firewall / WFP rules** | **No** | Requires Admin / `SeSecurityPrivilege` | Forbidden by `desktop/AGENTS.md` §3.7 (user-session process only, never elevated). |
| **Env vars (`HTTP_PROXY`/`HTTPS_PROXY`/`ALL_PROXY=http://127.0.0.1:1`)** | Yes | `env_proxy_bypassed_by_direct_socket == true` (Python raw TCP socket connected straight to loopback listener despite proxy env vars) | **Not network isolation.** Calling this "network blocking" would violate Rule H6. |
| **Win32 AppContainer (`CreateAppContainerProfile`, 0 capabilities)** | Yes (`Create` = `0x0`, `Delete` = `0x0`) | `cmd.exe /c exit 0` succeeded (`0x0`), **but real dev runtimes crashed immediately on startup:**<br>- `python.exe` (venv under `%USERPROFILE%`) failed with exit code **`106` (`0x6a`)**.<br>- `node.exe` failed during loader init with **`0xC0000142` (`STATUS_DLL_INIT_FAILED`)**. | Zero-capability AppContainer blocks normal filesystem/DLL access for user-installed toolchains unless explicit ACLs are mutated across user/runtime directories — fragile, invasive, and impractical for general dev tools. |

### Recommendation for D4
- **Do NOT claim OS-level network blocking in draft workspaces.**
- Rely on existing `ExecCommandClassifier` (`ADR-0018`): draft execution allows **only `fs.*` + `R2` `exec.run`** inside the draft copy. Outbound network commands (`curl`, `wget`, `ssh`, `scp`, `git push`, `npm publish`, `pip install`, etc.) are already `R3` and remain **per-command phone-signed `R3`** outside the draft.
- Every `EffectManifest` must explicitly state its honest scope (`"workspace_files_only; no_os_network_isolation"` — Rule H6).

---

## 3. Spike (c) — Crash-Safe Multi-File Apply & Rollback on Windows NTFS

### Question
Because multi-file replacement on Windows NTFS is not natively atomic (and legacy NTFS TxF is deprecated), can a local Write-Ahead Journal (WAL) + TOCTOU pre-check + `MoveFileExW(MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)` guarantee consistent all-or-nothing multi-file apply, crash recovery, Windows file-lock resilience, and full undo?

### Measured Results (Windows 11, `C:\` NTFS, 3-file batch: modify `a.txt`, modify `b.txt`, create `c.txt`)

| Scenario | Measured Result | Key Proof |
| --- | --- | --- |
| **C1. Happy path apply (3 files) + full Undo** | **`26.7 ms`**, `status = committed`, `applied_ok = true`, `undo_exact_sha256_and_delete_created = true` | All 3 files matched `postSha256`; after Undo, `a.txt` & `b.txt` returned to exact original SHA-256, `c.txt` was deleted, `0` `.tmp` files left. |
| **C2. TOCTOU external edit before apply** | `applied = false`, `status = toctou_mismatch`, **`zero_files_changed = true`** | Mutating `b.txt` externally after preview aborted apply before touching any file (`a.txt` & `b.txt` untouched, `c.txt` not created). |
| **C3. Simulated crash after file 1/3** | `mid_crash_state = applying`, `a_was_mutated_before_crash = true` → recovery: **`recovered_100pct_sha256 = true`** | Cold recovery reading only `journal.json` + backups on disk restored `a.txt` to exact original SHA-256 with `0` `.tmp` leftovers. |
| **C4. Windows file lock on file 2/3 (`CreateFileW` with `FILE_SHARE_READ`, no `FILE_SHARE_DELETE`)** | `applied = false`, `status = apply_target_locked_win32_5`, `a_rolled_back_exact_sha256 = true`, `b_unchanged_exact_sha256 = true`, `c_not_created = true`, `zero_tmp_leftovers = true` | **Critical Windows finding:** `MoveFileExW` on a read-locked file returns **Win32 error `5` (`ERROR_ACCESS_DENIED`)** (not only `32` `ERROR_SHARING_VIOLATION`). Rollback **must skip any file whose live SHA-256 already equals `preSha256`**; otherwise attempting to overwrite the untouched locked file during rollback causes rollback itself to fail with error `5`. |
| **C5. Secret file (`.env`) refusal** | `applied = false`, `status = fs_secret_file_forbidden`, **`no_journal_written = true`** | Secret files are rejected before any backup bytes or journal metadata are written. |

### Recommendation for W4-M1 & W4-M4
- Implement a single reusable **Local File Undo & Apply Journal** (`W4-M1`) shared by both single-call `fs.write_file` / `fs.patch_file` undo and multi-file `W4-M4` draft apply/rollback:
  1. **Pre-check all targets** (secret/Hard-Deny refusal + `FsPathGuard` workspace check + TOCTOU live SHA-256 check).
  2. **Stage backups + write WAL `journal.json`** (`state = "applying"`, `fsync` + atomic rename) inside local app data (`%LOCALAPPDATA%\XUNA\undo\` / `~/Library/Application Support/XUNA/undo/`, owner-only ACL — **never** inside `audit-*.jsonl` per §3.6).
  3. **Replace each file atomically** (`tmp` + `flush/fsync` + `MoveFileExW(..., MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)` on Windows; `rename` on POSIX).
  4. **On any error (`ERROR_ACCESS_DENIED` `5`, `ERROR_SHARING_VIOLATION` `32`, I/O error) or on startup crash recovery of an `applying` journal:** roll back in reverse order, **skipping any file whose live SHA-256 already equals `preSha256`** (and unlinking created files only if present), then mark `rolled_back` and clean `.tmp` files.

---

## 4. Honest Gaps & Pending Measurements (Rule H8)

- **macOS APFS `clonefile`:** Not measured in this spike (host is Windows 11). Must be benchmarked on macOS before `W4-M3` enables the APFS fast path; until then, filtered physical copy is the verified baseline.
- **Large repositories (`> 10,000` files / `> 200 MB`):** Not benchmarked in this spike; `W4-M3` must enforce hard `maxFiles` / `maxBytes` limits and fail closed (`draft_workspace_too_large`) rather than hanging or filling disk.
- **Real Antivirus real-time scan interference during multi-file apply:** Only simulated handle lock (`FILE_SHARE_READ`) was tested; real live validation stays in `W4-M5`.

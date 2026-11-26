# ADR-0019 — Draft Workspace, Local File Undo Journal & Effect-Bound Approval (`xuna.approval.v2`)

Date: 2026-11-26. **Status: Approved (owner 2026-11-26: D4=Option A, D5=Option A, M1-1/M1-2/M1-3=Option A, M2-1/M2-2/M2-3=Option A). W4-M1 & W4-M2 Implemented & Windows verified (`xuna_xtp` `282/282`, `desktop` `433/433`, `mobile` `743/743`, `backend` `1611/1611`, `diff -r` `0`, mutation-tested); W4-M3–W4-M5 Not Implemented; macOS, real phone & live unverified.** Extends [ADR-0013](ADR-0013-host-identity-and-sessions.md), [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md) and [ADR-0018](ADR-0018-power-user-shell-and-direct-fs.md); builds on upgrade plan P1.1 (`expectFiles` / `artifacts` format). Supporting spike measurements: [W4-M0 Spike Report](../research/W4-M0-draft-workspace-spikes-2026-11-26.md).

## Context

- Today (`ADR-0013` / `UDC-7` S7.5), phone-signed `R3` approvals use `xuna.approval.v1`:
  ```text
  b"xuna.approval.v1\x00" || approvalId || "|" || argsSha256 || "|" || hostId || "|" || expiresAt
  ```
  (`backend/src/xuna_backend/modules/hosts/domain/crypto.py:119-131`, `desktop/packages/xuna_xtp/lib/src/crypto.dart:18-21`, `mobile/lib/features/hosts/data/data_source/lan_host_client.dart:50-73`).
- That binds the owner's P-256 signature to the **command text/arguments**, not to the **real filesystem effect**:
  1. When signing a destructive command (e.g., `del *.log`) or a file write/patch, the owner does not see the exact diff or expanded target list on the approval card.
  2. Disk state can change between preview and execution (**TOCTOU**).
  3. `ReversibleActionLedger` (`desktop/lib/features/tools/host_tool_dispatcher.dart:119-200`) tracks only in-memory `media.play_pause`, `media.volume_set`, and `host.lock_screen` (`5` entries / `10 min`). `fs.write_file` and `fs.patch_file` (`desktop/lib/features/exec/fs_tools.dart`) have **no undo journal** and declare `reversible: false`.
  4. Multi-file edits cannot be tried and test-verified safely before touching the owner's real workspace.

## Evidence from W4-M0 Spikes (Windows 11, non-elevated, `C:\` NTFS)

Full measurements: [W4-M0 Spike Report](../research/W4-M0-draft-workspace-spikes-2026-11-26.md).

1. **Workspace copy (Spike a):**
   - `C:\` is `NTFS` without block cloning (`FSCTL_DUPLICATE_EXTENTS_TO_FILE` returned Win32 error `1` `ERROR_INVALID_FUNCTION`).
   - `git worktree add --detach` (`187.8 ms`) drops untracked files and uncommitted dirty edits and fails (`exit 128`) on non-Git folders.
   - NTFS hardlinks **corrupt the original file** on in-place writes (`r+b`) — permanently disqualified.
   - **Filtered physical copy** (excluding `.git`, `node_modules`, `.venv`, `build`, `.dart_tool`, `target`, `__pycache__` and hard-skipping `.env`/`*.pem`/`*.key`) copied `521` files (`5.27 MB`) in **`266.9 ms`** and `200` non-Git files (`2.11 MB`) in **`98.0 ms`**, preserved uncommitted/untracked files, excluded `.env`, and left the original workspace `100%` unchanged (`0` bytes altered).
   - macOS APFS `clonefile` is not yet measured (Rule H8).
2. **Non-elevated network isolation (Spike b):**
   - Windows Firewall / WFP requires Admin (forbidden by `desktop/AGENTS.md` §3.7).
   - Proxy env vars (`HTTP_PROXY` etc.) are bypassed trivially by direct sockets (cannot be called isolation under Rule H6).
   - Zero-capability Win32 `AppContainer` works without Admin for `cmd.exe`, but **breaks real dev runtimes** (`python.exe` exits `106`, `node.exe` crashes with `0xC0000142` `STATUS_DLL_INIT_FAILED`) due to user/runtime filesystem ACL isolation.
3. **Crash-safe multi-file apply & rollback (Spike c):**
   - Local WAL journal + `fsync` + `MoveFileExW(MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)` applied `3` files in **`26.7 ms`**, rolled back cleanly on mid-apply crash (`100%` SHA-256 restored, `0` `.tmp` leftovers), rejected TOCTOU edits (`0` files modified), refused `.env` before writing any journal byte, and handled Windows read-locks (**Win32 error `5` `ERROR_ACCESS_DENIED`** as well as `32` `ERROR_SHARING_VIOLATION`) once rollback skips files whose live SHA-256 already matches `preSha256`.

## Options

| Decision | Options | Proposed Choice |
| --- | --- | --- |
| **D4 — Scope of draft & effect-bound signing** | **A.** Workspace files only (`fs.*` + `R2` `exec.run`); network/external commands stay per-command `R3` signed; no OS network blocking claimed.<br>**B.** Attempt OS network sandboxing via AppContainer + custom ACL mutation on toolchains. | **Option A** (proven necessary by Spike b and `desktop/AGENTS.md` §3.7 + Rule H6). |
| **D5 — Workspace draft copy mechanism** | **A.** Bounded filtered physical copy (Windows/Linux/fallback) + APFS `clonefile` on macOS (after Mac benchmark), excluding heavy build caches & secret files.<br>**B.** `git worktree` only (Git repos only, loses dirty/untracked files).<br>**C.** NTFS hardlinks. | **Option A** (proven by Spike a; Option C corrupts originals). |
| **Approval wire evolution** | **A.** Introduce `xuna.approval.v2` (`effectSha256`) **coexisting** with `xuna.approval.v1` (`argsSha256`).<br>**B.** Replace v1 globally. | **Option A** (zero breakage for non-draft R3 tools and rolling upgrades). |

## Approved Decision (Owner Approved 2026-11-26)

### 1. Shared Local File Undo & Apply Journal (`W4-M1` / U1)

- **Storage location & privacy (§3.6):** Stored locally on the host under owner-only app data (`%LOCALAPPDATA%\XUNA\undo\` on Windows, `~/Library/Application Support/XUNA/undo/` mode `0700` on macOS), **never** inside `audit-*.jsonl` or application logs, and **never** uploaded to the backend.
- **Eligibility & Hard-Deny boundaries:**
  - Eligible only for non-secret files inside configured `shellControl.workspaceRoots` (re-verified via `FsPathGuard` + symlink resolution immediately before backup and before restore).
  - Secret files (`.env*`, `*.pem`, `*.key`, credentials, Hard-Deny paths) are **never** snapshotted into the undo journal.
  - Files exceeding per-file size cap (`2 MiB`, M1-1 Option A) or when total journal budget (`32 MiB` / `20` transactions / `30 min` TTL, M1-1 Option A) cannot accommodate a backup after LRU/expiry pruning: the write still runs atomically if allowed, **without** a journal entry (internal `undoAvailable: false`, Rule H1/H6).
- **Crash-safe WAL protocol:**
  - Each transaction directory holds original file backups + an atomically replaced `journal.json` (`txId`, `createdAt`, `expiresAt`, `state`: `preparing` → `applying` → `committed` / `rolled_back`, and per-file `{path, op, existed, preSha256, postSha256, backupFile, backupBytes, mode}`).
  - Startup sweeps expired journals and automatically rolls back any journal left in `applying` state (crash recovery).
  - Rollback iterates in reverse order, **skips any file whose live SHA-256 already equals `preSha256`** (preventing Win32 error `5`/`32` failures on untouched locked files), deletes created files only if present (and still matching `postSha256` on user undo), and cleans `.tmp` files.
- **`action.undo` integration & H6 honesty:**
  - `action.undo` supports both existing in-memory reversible actions (`media.*`, `host.lock_screen`) and committed local file journal transactions (picking whichever valid entry is more recent).
  - Before restoring a committed file transaction, `action.undo` verifies each file's current SHA-256 still matches `postSha256` (M1-2 Option A: never silently clobbers edits the owner made manually afterward — fail-closed `undo_conflict_modified_externally` per H1/H3).
  - Per M1-3 Option A, `W4-M1` keeps the existing `fs.write_file` / `fs.patch_file` XTP wire schema unchanged (zero wire/fixture churn in M1); additive wire fields (`undoAvailable`/`undoTxId`) and preview/draft contract updates are bundled in `W4-M2`/`W4-M3`.

### 2. Bounded R3 Preview on Approval Cards (`W4-M2` / U2 — keeps `xuna.approval.v1`)

- Extend `xuna/preflight` response (`XUNA_XTP_V1_CONTRACT.md` §4.2.8) with an optional, strictly bounded `preview` object (only when `status == "ok"`):
  - For `fs.patch_file` / `fs.write_file`: compact unified diff snippet (redacted via `redactSensitiveTokens`, hard cap e.g. `2048` bytes, `truncated: bool`, `"…"` marker when truncated, never generated for secret files).
  - For destructive `exec.run` (e.g., `rm`/`del` with globs inside workspace): read-only glob expansion listing up to `N` (`20`) relative paths + `totalCount` + `truncated: bool` (never expanding outside workspace or into Hard-Deny/secret locations).
- Mobile R3 approval sheet displays `preview` directly above the biometric/P-256 sign button; preview content is ephemeral (never persisted in audit logs or PostgreSQL, §3.6 / Consent U5).

### 3. Draft Workspace Execution & `EffectManifest` (`W4-M3`)

- A draft session creates an isolated temporary copy of a single configured workspace root using **Option A (D5)**: bounded filtered physical copy on Windows/Linux (cap e.g. `2,000` files / `100 MiB` proposed; fail closed with `draft_workspace_too_large` if exceeded; excludes `.git`, `node_modules`, `.venv`, `build`, `.dart_tool`, `target`, `__pycache__` and hard-excludes all secret/Hard-Deny files), and APFS `clonefile` on macOS once benchmarked.
- Inside a draft session, only **`fs.*` and `R2` `exec.run`** execute against the draft directory. `R3` commands (network, delete outside draft, git push, etc.) are refused inside draft mode and remain normal per-command `R3` calls.
- When ready to commit, the host computes a canonical `EffectManifest` (`schemaVersion: 1`):
  - `workspaceAlias` (no raw host path on wire where not needed; relative file paths only),
  - `scope`: `"workspace_files_only"`, `networkIsolated`: `false` (honest boundary, H6),
  - `changes`: ordered list of `{relPath, op: "create"|"modify"|"delete", preSha256?, postSha256?, sizeBytes?, magicOk?}` (reusing P1.1 `artifacts` field conventions),
  - `checks`: optional summary of draft `exec.run` verification results (`commandCount`, `allCompleted`, `failedCount`),
  - `draftId`, `createdAt`, `expiresAt`.
- `effectSha256 = sha256(canonical_json(effectManifest))` (using XTP RFC 8785 JCS canonical JSON).

### 4. Effect-Bound Signature `xuna.approval.v2` (`W4-M4`, coexisting with `v1`)

- Domain-separated signing message (cannot collide with `xuna.approval.v1` or `xuna.preapproval.v1`):
  ```text
  b"xuna.approval.v2\x00" || approvalId || "|" || effectSha256 || "|" || hostId || "|" || expiresAt
  ```
- **Coexistence:**
  - `xuna.approval.v1` (`argsSha256`) remains valid for standard single-call `R3` actions (UI commits, non-draft `exec.run`, single `fs.*` writes).
  - `xuna.approval.v2` (`effectSha256`) is required exclusively for applying a `DraftWorkspace` `EffectManifest` (`draft.apply`).
  - Both versions carry explicit `version: 1 | 2` (default `1` when omitted for backward compatibility) in `_meta["xuna/approval"]`.
- **Host-side fail-closed apply (`draft.apply`):**
  1. Verify P-256 signature over `xuna.approval.v2` against `pinnedPhonePublicKeys`, expiry, `hostId`, and single-use `approvalId` replay cache.
  2. Recompute `sha256(canonical_json(draft.effectManifest)) == approval.effectSha256`.
  3. Re-verify every target path via `FsPathGuard` + symlink resolution (no secret files, no escaping workspace root).
  4. **TOCTOU gate:** Verify every target file's live SHA-256 on disk equals `change.preSha256` (and `create` targets do not already exist). Any mismatch refuses the entire apply (`toctou_mismatch`) with **`0` files modified**.
  5. Apply all changes through the **W4-M1 WAL journal** (backup originals → `applying` → atomic `MoveFileExW` / `rename` → `committed`). Any Win32 lock error (`5`/`32`) or I/O error triggers automatic rollback restoring all earlier files to exact `preSha256`.
  6. Keep the committed journal entry in the W4-M1 undo store so `"Hoàn tác cả nhiệm vụ"` reverses the entire multi-file apply in one step.

## Honest Limitations (Rule H6 / H8)

1. **Workspace files only:** Draft execution cannot capture side effects outside the workspace directory (global caches, OS registry, external databases, background processes). `EffectManifest.scope` explicitly discloses this.
2. **No OS network isolation:** Drafts do not block outbound sockets at the OS level (`networkIsolated: false`); network commands remain guarded by `ExecCommandClassifier` `R3`.
3. **Crash-recoverable, not NTFS-atomic:** Multi-file apply on Windows uses WAL + per-file atomic replace + rollback on error/restart (not deprecated NTFS TxF). An abrupt power cut mid-apply is recovered on next agent startup via the persisted `applying` journal.
4. **macOS APFS `clonefile` unmeasured:** Benchmark on macOS is pending before enabling APFS fast copy in `W4-M3`.

## Consequences

- **Milestones & sequencing:** `W4-M0` (this ADR + spikes) → `W4-M1` (local `fs.*` undo journal, **no wire/XTP breaking change**; optional `undoAvailable` additive if/when exposed) → `W4-M2` (preflight preview + mobile card, XTP + fixtures) → `W4-M3` (draft workspace + manifest, XTP + fixtures) → `W4-M4` (`xuna.approval.v2` + new cross-repo golden vectors across `backend`, `xuna_xtp`, `mobile`) → `W4-M5` (live Windows + Mac + phone verification).
- **Untouched invariants:** `desktop/AGENTS.md` §3.6 (zero file contents/paths in audit logs), §3.7 (non-elevated user-session process), `firmware/` (`0` diff in P2; physical pet co-signing is separate P3 / `ADR-0020`), `0` new external packages unless separately approved.

## Owner Acceptance

- Status: **Approved** (2026-11-26, owner confirmed all recommended options: D4=Option A, D5=Option A, Approval wire evolution=Option A, M1-1=Option A [`32 MiB` / `2 MiB` per file / `20` tx / `30 min` TTL], M1-2=Option A [fail-closed `undo_conflict_modified_externally`], M1-3=Option A [keep existing `fs.*` wire schema in `W4-M1`]).

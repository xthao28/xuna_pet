# ADR-0018 — Opt-In Local Power-User Shell (`exec.*`), Direct File I/O (`fs.*`) & Brain Fluency

Date: 2026-11-25. **Status: Approved for specification & implementation handoff (owner 2026-11-25); Not Implemented / Not Validated.** Amends [ADR-0012](ADR-0012-host-actions.md) and [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md) (including the 2026-11-22 Autopilot amendment) strictly for the newly scoped `exec.*` and `fs.*` tool namespaces; extends [ADR-0017](ADR-0017-async-watch-and-wake.md) (`LocalWatchSentinel` + `WAITING_WATCH`). Authoritative engineering specification: [XUNA Wave 3 — Power-User Shell, Direct File I/O & Brain Fluency](../architecture/XUNA_WAVE3_POWER_SHELL_AND_BRAIN_FLUENCY.md).

## Context

- Live macOS multi-step testing on `2026-11-24`–`2026-11-25` verified Wave 1/2 (`FSEvents`, `protocol_async`, `workspace.coding_agent`), while surfacing 6 practical execution gaps compared to OpenClaw (Clawbot):
  1. XUNA cannot directly read/patch repository files or run tests/builds (`node`, `pytest`, `flutter test`, `git`) without delegating through GUI clipboard/AX injection into an external IDE (`workspace.coding_agent`), so XUNA cannot independently verify file contents or test results.
  2. `mcp.list_servers` returns only server IDs and transport metadata without each MCP server's inner `tools/list` names and schemas, forcing the LLM to guess tool names on `mcp.call`.
  3. High-frequency developer tools (`workspace.coding_agent` at slot 141) sit behind the 36-tool direct catalog cutoff (`catalog.py`), adding 3 cold-start discovery hops (`tool_search` → `tool_describe` → `tool_invoke`), and `prompts.py` lacks a concise capability guide for escalating multi-step work to `autonomous_job`.
  4. Backend cognition has no automatic secondary-model/provider failover chain, causing long jobs to stall immediately when a primary free-tier provider hits its daily RPD limit.
- The owner explicitly decided on `2026-11-25` to close these gaps with **Full Power-User Shell + Direct File I/O (`Gói 1`)** and **Brain & Tool Fluency (`Gói 2`)**, guarded by **Local-Only Opt-In (`shellControl` in `host-policy.json`)**, mandatory host-side `xuna/preflight` risk classification (`Hard-Deny` / `R3` / `R2` / `R1`), Consent `U5` redaction, and process-group E-Stop.

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. Keep ADR-0015 hard ban; IDE GUI bridge only** | Minimal attack surface | Cannot read files or run/verify tests directly; fragile to IDE focus/sidebar state |
| **B. Scoped Workspace File I/O + Workspace-Only Dev Shell** | Narrower blast radius | Blocks legitimate whole-machine power-user automation (outside a single repo) |
| **C. Full Power-User Shell (`exec.*`) + Direct File I/O (`fs.*`) with Local-Only Opt-In, Mandatory Host Preflight (`Hard-Deny` / `R3` / `R2` / `R1`), Process-Group E-Stop & Separate `ToolFamily.exec`** | Matches OpenClaw's direct dev/system capability while preserving XUNA's security edge (local-only activation, P-256 `R3` gate on destructive/outbound/system commands, `sudo`/Keychain hard-deny, U5 redaction, <250ms E-Stop) | Requires synchronized contract changes across `xuna_xtp`, `desktop`, `backend`, and `mobile` (`HostToolFamily.exec`) |

## Decision

**Option C (Owner-approved 2026-11-25).**

1. **Preserve Legacy Raw-Shell Bans, Introduce Audited `exec.*` & `fs.*`:**
   - Legacy raw tool names and prefixes (`shell.*`, `powershell.*`, `osascript.*`, `eval.*`, `script.*`, `cmd.*`, `bash.*`, `keyboard.*`, `pointer.*`) REMAIN permanently in `FORBIDDEN_TOOLS` / `FORBIDDEN_TOOL_PREFIXES`.
   - Introduce two structured, schema-validated, preflight-governed namespaces:
     - **`fs.*`** under existing `ToolFamily.files`: `fs.list_files`, `fs.read_file`, `fs.grep`, `fs.write_file`, `fs.patch_file`.
     - **`exec.*`** under new **`ToolFamily.exec`**: `exec.run`, `exec.status`, `exec.write_stdin`, `exec.cancel`.
   - Database schema requires **0 Alembic migrations** (`host_grants.family` is already `VARCHAR(16)`). `mobile/` MUST add `HostToolFamily.exec` (plus `vi_VN`/`en_US`/`locales.g.dart`) so mobile grant lists never fail with `FormatException`.
2. **Strict Local-Only Opt-In (`HostPolicy.shellControl`):**
   - `host-policy.json` gains an optional local-only `shellControl` object defaulting to `enabled: false`.
   - Only local Desktop UI or direct local edits to `host-policy.json` may enable or modify `shellControl`. Remote `PUT /v1/hosts/{id}/policy` and `xuna/set_policy` MUST reject any payload containing `shellControl` (`422` / `policy_blocked`) and preserve existing local `shellControl` untouched when saving other policy fields (mirroring Wave 2 `protocolHarnesses`).
   - When `shellControl.enabled == false`, Desktop advertises `exec.*` tools as `permission: "denied"` (Rule H6) and fails closed (`shell_not_enabled`) on both `xuna/preflight` and `tools/call`.
   - `exec.*` additionally requires an active `ToolFamily.exec` grant on the host (NOT granted by default).
3. **Mandatory Host-Side `xuna/preflight` Classification (Rule H5 — Fail-Closed):**
   - Backend Orchestrator MUST invoke `xuna/preflight` before every `exec.run`, `exec.write_stdin`, `fs.write_file`, and `fs.patch_file` call (and never lowers the risk reported by the host).
   - **Hard-Deny (unapprovable, blocked even under `autopilot`):**
     - Privilege escalation (`sudo`, `su`, `doas`, `pkexec`, `runas`, `osascript ... administrator privileges`, setuid/root ownership tampering).
     - Credential stores & password managers (`security find-generic-password` / `find-internet-password` / `dump-keychain`, `~/Library/Keychains`, `~/.ssh`, `~/.gnupg`, `~/.aws/credentials`, `~/.kube`, `~/.netrc`, 1Password/Bitwarden/KeePass CLI & vaults, `/etc/shadow`).
     - Catastrophic destructive patterns (`rm -rf /`, `rm -rf ~`, `rm -rf $HOME`, `mkfs`, raw `dd of=/dev/`, `diskutil eraseDisk`, `shutdown`/`reboot`/`halt`, fork bombs).
   - **`R3` Phone-Signed Approval (required even under `autopilot`):**
     - Destructive mutations (`rm`, `rmdir`, `unlink`, `chmod`, `chown`, `git push`, `git reset --hard`, `git clean -fd`, `git checkout -- .`, `kill`/`pkill`/`killall`, `launchctl`, `systemctl`, `brew`/`npm`/`pip` uninstall, `docker rm`/`prune`).
     - Outbound network / remote side-effects (`curl`, `wget`, `ssh`, `scp`, `rsync`, `nc`/`ncat`, `ftp`, `gh pr`/`issue`/`release`, `npm publish`, `twine upload`, `docker push`).
     - Writes/patches outside configured workspaces or targeting shell/system dotfiles (`~/.zshrc`, `~/.bashrc`, `~/.profile`, `~/.gitconfig`, `/etc/*`).
     - Obfuscated/indirect execution (`base64 -d | sh`, `curl ... | bash`, `eval`, inline script downloading/deleting) — fail-closed to `R3` (or Hard-Deny if matching escalation/catastrophic rules).
   - **`R2` (auto-run under `autopilot`; prompted under `standard`/`strict`):**
     - Everyday power-user & developer commands (tests, linters, builds, local scripts, local git `status`/`diff`/`log`/`add`/`commit`/`branch`, read/transform pipes without outbound network or destructive targets) and `fs.write_file` / `fs.patch_file` inside configured workspace roots on non-secret files.
   - **`R1` (`observes: true`, Consent `U5` + secret redaction + `<= 16 KiB` cap):**
     - `fs.list_files`, `fs.read_file`, `fs.grep`, `exec.status`, `exec.cancel`.
4. **Process-Group Isolation, Async Watch Integration & Immediate E-Stop:**
   - Every `exec.run` spawns inside its own process group (`setsid`/pgid wrapper on POSIX + optional PTY; process tree kill `taskkill /T /F` on Windows), capped at `maxConcurrentExecTasks = 4` (`exec_task_limit_reached`).
   - Slow commands exceeding `yieldMs` (default `10,000 ms`) auto-detach into a RAM-only `ExecProcessRegistry` `taskId`, wire into Wave 1/2 `LocalWatchSentinel` (`exec_async` signal, `WAITING_WATCH` at 0 LLM tokens), and wake the `AutonomousJob` on exit/settle.
   - E-Stop immediately terminates every tracked process group (`SIGTERM` → `500 ms` → `SIGKILL` to `-pgid`, or `taskkill /T /F` on Windows) and cancels all `exec_async` watches.
5. **Brain & Tool Fluency (`Gói 2`):**
   - `mcp.list_servers` gains `includeTools: bool` (default `true` for configured local MCP servers, bounded `2s`/server timeout, `60s` RAM cache, U5-redacted) returning real `tools/list` names, descriptions, and argument summaries.
   - Rebalance `catalog.py` `_PRIORITY_ORDER` to surface high-value direct dev tools (`fs.*`, `exec.run`/`status`/`cancel`, `workspace.coding_agent`) directly without 3-hop discovery overhead while keeping `MAX_CATALOG_TOOLS` bounded.
   - Add Rule-H5-clean `autonomous_job` escalation and direct-dev-loop guidance in `prompts.py`.
   - Add `FallbackTextGenerator` (`XUNA_TEXT_FALLBACK_MODELS` / `XUNA_TEXT_FALLBACK_PROVIDERS`) for automatic failover on pre-stream `429` (daily RPD/cooldown), `503`, or transient provider outage.

### What does not change

- `firmware/` remains untouched (`0 B` diff); device authority over pet identity, learning, and personality is unchanged.
- Hard refusals on password fields, password managers, banking apps, `sudo`/elevation, Keychain, and legacy `shell.*`/`powershell.*`/`osascript.*` remain enforced.
- Consent `U5` zero-retention and content-free audit logs remain enforced (no raw file contents, command outputs, or secrets persisted in PostgreSQL or `xuna/watchEvent`).
- Pinned toolchains (`.fvmrc`, `pubspec.lock`) and database schema (`0` new migrations) remain unchanged.

## Consequences

- **Contract & Fixtures:** Update `XUNA_XTP_V1_CONTRACT.md` and maintain 100% byte-identical golden fixtures (`backend/tests/fixtures/xtp/` ↔ `desktop/packages/xuna_xtp/test/fixtures/xtp/`).
- **Submodules touched:** `desktop/packages/xuna_xtp/`, `desktop/`, `backend/`, `mobile/` (`HostToolFamily.exec` + L10n parity only).
- **Submodules untouched:** `firmware/` (`0 B` diff), `backend/migrations/` (`0` new migrations).
- **Validation requirements (Rule H8):** Full automated suites across `xuna_xtp`, `desktop` (+ signed macOS Debug build & `RunnerTests`), `mobile` (+ L10n sync), `backend` (`ruff`, `mypy`, `pytest` including adversarial Hard-Deny/R3/E-Stop/failover tests), plus live macOS 1-turn verification on an external project. Windows `taskkill /T /F` runtime, physical phones, and LILYGO ESP32 remain explicitly marked unverified until tested on target hardware.

## Evidence

- Authoritative Wave 3 specification: [XUNA_WAVE3_POWER_SHELL_AND_BRAIN_FLUENCY.md](../architecture/XUNA_WAVE3_POWER_SHELL_AND_BRAIN_FLUENCY.md)
- Prior decisions: [ADR-0012](ADR-0012-host-actions.md), [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md), [ADR-0017](ADR-0017-async-watch-and-wake.md)
- Honest-code rules: [XUNA_HONEST_CODE_RULES.md](../architecture/XUNA_HONEST_CODE_RULES.md)
- Owner decisions recorded `2026-11-25` (A1: Full Power-User Shell; A2: Gói 2 + Gói 1; A3: Local-Only Opt-In).

# ADR-0017 — Event-driven Async Watch & Wake for long-running host control

Date: 2026-11-22. **Status: Proposed** (Extends [ADR-0012](ADR-0012-host-actions.md), [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md) Autopilot amendment 2026-11-22, and [ADR-0016](ADR-0016-spatial-device-mesh.md)). Plan & contract specification: [XUNA Async Watch & Wake](../architecture/XUNA_ASYNC_WATCH_AND_WAKE.md).

## Context

- XUNA's interactive conversation turns are bounded (`MAX_TOOL_ROUNDS = 12`, `TURN_BUDGET_SECONDS = 150s`), and `AutonomousJobRunner` currently executes a tight loop (`await self._sleep(0.01)`) with no resting/watching state.
- Many real owner workflows across arbitrary desktop apps (delegated AI/IDE prompts, builds, test suites, renders, exports, downloads, long-running web dashboards) take 30 seconds to 15 minutes to complete before XUNA can read the real outcome, report back, or trigger the next step.
- Naive polling from the Backend wastes LLM tokens and WebSocket traffic, introduces high wake latency, risks false-positive completion when UI pauses mid-computation, can steal window focus while the owner works on other tasks, and breaks across Backend restarts.
- Research into OpenClaw's event-driven gateway (`yieldMs` auto-detach, `notifyOnExit` completion wakes, isolated session lanes, `HEARTBEAT_OK` silent filtering, and protocol-first ACP/MCP harnesses) and native OS observation (`AXObserver`, `libproc`, `FSEvents`, UIA, `ReadDirectoryChangesW`, CDP) points to a cleaner hybrid design that fits XUNA's security invariants (no `shell.*`, U5 zero-retention, Autopilot vs R3 high-impact boundary, E-Stop).

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. Keep tight `AutonomousJobRunner` loop and add simple `sleep(N)` tool** | Minimal code | Burns LLM tokens and steps; high latency; false positives on UI pauses; stalls main chat or loses state on restart |
| **B. Backend periodic polling over XTP (`ui.inspect` every 15–30s)** | Works across all apps | Latency floor (up to 30s); continuous WS/CPU overhead; single-signal UI pauses trigger premature wakes; non-durable in-memory timers |
| **C. Pure protocol-only (`MCP`/`ACP`) with no GUI watcher** | Zero screen scraping, exact events | Cannot handle arbitrary desktop apps, IDEs, browsers, or exporters that do not expose MCP/ACP |
| **D. Hybrid Event-Driven Local Sentinel (`xuna/watchRegister` / `xuna/watchEvent`) + Multi-Signal Quiescence + `yieldMs` Auto-Detach + Durable Wake Inbox + Phase 3 opt-in MCP/ACP** | **0 LLM tokens while sleeping**; <1s OS-driven wake; multi-signal convergence (`UI + process CPU + FS + CDP`) beats UI false positives; background PID observation avoids stealing focus; durable in PostgreSQL; supports both arbitrary GUI apps and future MCP/ACP harnesses | Adds migration `0023`, 3 additive XTP methods/notifications, Desktop native observers, and Mobile Wake Inbox UI |

## Decision

**Option D (Proposed — awaits owner kick-off / acceptance).**

1. **Event-Driven Desktop Local Sentinel over XTP v1:**
   - Add strictly bounded, content-free wire messages `xuna/watchRegister`, `xuna/watchCancel` (Backend → Host), and `xuna/watchEvent` (Host → Backend push notification) documented in `XUNA_XTP_V1_CONTRACT.md` §4.2.14–§4.2.16 with byte-identical fixture pair `watch_frames.json`.
   - Desktop watches target PID/window/workspace/tab in the background (`releaseFocus: true`) using multi-signal convergence (`ui_quiescence`, `ui_change`, `process_idle`, `fs_quiescence`, `cdp_idle`, `composite`, `timer`, and Phase 3 `protocol_async`), pushing `xuna/watchEvent` only when settled, changed, timed out, lost, or errored.
2. **Durable Sleep & Wake Lifecycle (`AutonomousJobState.WAITING_WATCH`):**
   - Migration `0023_async_watch_and_wake.py` adds `job_watches` and `wake_inbox_items`.
   - When an agent calls internal tool `job__wait`, `WatchCoordinator` persists the watch, registers it on Desktop, transitions the job to `WAITING_WATCH`, and exits the runner loop cleanly (0 CPU, 0 LLM calls). Unexpired watches rehydrate automatically on host reconnect.
   - `yieldMs` (default `12s`) auto-detaches slow interactive waits into `WAITING_WATCH`, releasing the main chat lane immediately.
3. **Wake Verification, Silent `NO_ACTION` & Non-Intrusive Wake Inbox:**
   - On `xuna/watchEvent`, the Brain performs one real observation step. If still running, it re-registers with backoff (`wake_checks_used <= max_wake_checks`) and stays silent (`NO_ACTION`).
   - On genuine completion, timeout, or failure, `WakeInbox` stores a redacted factual report (zero base64 — U5) and notifies Mobile without interrupting an active voice/chat turn, with 1-tap `Chờ thêm` / `Tiếp tục` / `Dừng` actions.
   - Under `auto_continue`, subsequent steps honor [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md) (2026-11-22 Autopilot amendment): ordinary work continues uninterrupted under `Autopilot`, while high-impact financial, destructive, account, or external send/publish actions ALWAYS pause at `AWAITING_R3_CHECKPOINT` for P-256 phone approval.

### What does not change

- **No arbitrary execution (`desktop/AGENTS.md` §3):** `shell.*`, `powershell.*`, `osascript.*`, `eval.*`, `script.*`, `cmd.*`, `bash.*` remain strictly forbidden; Phase 3 MCP/ACP adapters are strictly opt-in allowlisted JSON-RPC harnesses.
- **Zero app/phrase hardcoding (Rule H5):** All watch modes and prompts are 100% OS-generic and app-agnostic.
- **Consent U5 & Content-Free Logs:** No screenshots, screen text, or raw filesystem paths are stored in PostgreSQL or transmitted in `xuna/watchEvent`.
- **Emergency Stop & Board Authority:** E-Stop immediately cancels all active watches on both Backend and Desktop; `firmware/` remains untouched (`0 B` delta), receiving only optional Track A expression cues via Mobile BLE.

## Consequences

- **Contract & Fixtures:** `XUNA_XTP_V1_CONTRACT.md` §4.2.14–§4.2.16 + synchronized `watch_frames.json` in `backend/` and `desktop/packages/xuna_xtp/`.
- **Backend:** Migration `0023`, `actions/domain/watch.py`, `actions/application/watch_coordinator.py`, `wake_inbox.py`, `yield_detach.py`, `actions/infrastructure/watch_repository.py`, `actions/api/watch_routes.py`, plus thin hooks in `job_runner.py`, `host_socket.py`, and `chat_turn.py` (`orchestrator.py` < 50 net LOC, `workflows.py` 0 diff).
- **Desktop:** `LocalWatchSentinel` + `WatchConvergence` (Dart), `XunaHostPlugin+Watch.swift` (macOS `AXObserver`/`libproc`/`FSEvents`), `xuna_win_watch.h` (Windows C++ parity), CDP idle watch, and Phase 3 MCP/ACP async bridge.
- **Mobile:** `AutonomousJobState.waitingWatch`/`waitingWake`, `HomeWakeInboxService`, Watch status card, non-intrusive Wake Inbox delivery, and 100% synced `locales.g.dart`.
- **Risks accepted / deferred:** Windows C++ compilation/runtime and physical iPhone/Android/ESP32 verification remain pending target hardware runs (Rule H8); Electron apps that suppress `AXObserver` events rely on the background AX digest + `process_idle` convergence safety net.

## Evidence

- Authoritative specification & teamwork plan: [XUNA_ASYNC_WATCH_AND_WAKE.md](../architecture/XUNA_ASYNC_WATCH_AND_WAKE.md)
- Prior decisions: [ADR-0012](ADR-0012-host-actions.md), [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md), [ADR-0016](ADR-0016-spatial-device-mesh.md)
- Honest-code rules: [XUNA_HONEST_CODE_RULES.md](../architecture/XUNA_HONEST_CODE_RULES.md)


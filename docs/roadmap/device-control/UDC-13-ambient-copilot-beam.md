# UDC-13 — Seamless Ambient Co-Pilot: XUNA Beam (Peer-to-Peer LAN Transfer), Instant Active-Window Context (`window.active_context`), Semantic Browser Snapshot (`browser.read_page`), Atomic Batch Steps (`workflow.batch_steps`) & Reversible Action Undo (`action.undo`)

Status: **S13.1–S13.5 Implemented & Host-Verified (2026-10-31; [UDC-13-results-2026-10-31.md](UDC-13-results-2026-10-31.md))**. Complexity: **L (5 sessions: `S13.1` → `S13.5`)**. Repositories: `desktop/` (`xuna_xtp` + agent), `backend/`, `mobile/` (**0 bytes added to `firmware/`**).

---

## 1. Goal & Zero-Overhead Hardware/Cloud Architecture

Upgrade XUNA into a **Seamless Ambient Co-Pilot** inspired by permissive open-source leaders (`localsend/localsend` Apache-2.0, `openclaw/Peekaboo` MIT, `microsoft/playwright-mcp` Apache-2.0, and `munimtechnologies/munim-computer-use` Apache-2.0) while strictly preserving **zero extra RAM/CPU load on `firmware/` and near-zero memory/CPU footprint on `backend/`**:

1. **Why `firmware/` adds `0 B` RAM and `0%` CPU in `UDC-13`:**
   - The ESP32-S3 board already has everything it needs from `UDC-1..UDC-12`: Speech Bubble (`7a6e0011`), Track A gesture preview (`opcode 9`), Remote Mode & Workflow Slots (`opcode 13 arg=4`), and Physical `R2` Approval (`opcode 13 arg=5|6`, `status kind=3 arg=4|5`).
   - In `UDC-13`, live step progress (`"[1/3] Đang đọc cửa sổ..."`) reuses the existing Speech Bubble characteristic (`7a6e0011`), so **`firmware/` requires zero code changes, 0 B extra RAM, and 0% extra CPU**.
2. **Why `backend/` stays ultra-lightweight (`O(1)` stateless router):**
   - **XUNA Beam (`S13.3`)** transfers files/screenshots/clipboard **peer-to-peer over LAN (`:47821`)** directly between Phone ↔ Desktop (following `localsend/localsend`'s local P2P pattern) — **0 bytes of file/image payload ever pass through `backend/`**.
   - **Active-Window Context (`S13.1`)** and **Semantic Browser Snapshot (`S13.2`)** perform all Accessibility tree extraction, pruning, and secret redaction **on the Desktop CPU (`desktop/`)**, sending only a compact, redacted `< 1.6 KiB` JSON summary through `backend/`.
   - **Atomic Batch Steps (`S13.4`)** executes multi-step sequences in a single XTP round-trip on `desktop/`, **reducing** `backend/` CPU/network round-trips by 60–75%.

---

## 2. Gate

- `UDC-12` (`S12.1` → `S12.5`) is Implemented and verified across `firmware/`, `desktop/`, `backend/`, and `mobile/` ([UDC-12-results-2026-10-31.md](UDC-12-results-2026-10-31.md)).
- Reference reuse policy: [ADR-0001](../../decisions/ADR-0001-reference-reuse-policy.md) (re-implement patterns from MIT/Apache-2.0 projects `localsend/localsend`, `openclaw/Peekaboo`, `microsoft/playwright-mcp`, `munimtechnologies/munim-computer-use`; never copy AGPL or commercial-licensed `screenpipe` code).

---

## 3. Scope / Out of Scope

### In Scope (`S13.1` → `S13.5`)
- **`S13.1` — Instant Active-Window Context (`window.active_context`, `R1`):**
  - Reads `{appName, windowTitle, focusedElementRole, focusedElementText, visibleTextSummary}` from the frontmost desktop window via native Accessibility (`IUIAutomation` on Windows, `AXUIElement` / `NSWorkspace` on macOS) without requiring the user to select or copy text first.
  - Enforces hard-denied app refusal (password managers, terminals, banking, elevated windows) and automatic secret/token redaction (`redactSensitiveSelectionText`, `<= 1200` chars, zero content logging).
- **`S13.2` — Semantic Browser Co-Pilot (`browser.read_page`, `R1`) & Playwright MCP Auto-Prioritization:**
  - Reads structured, clean semantic page context (`{urlHost, title, headings, interactiveElements, textExcerpt}`) from the active `https://` browser tab (or delegates to `@playwright/mcp` when discovered by `AutoMcpBridge`) without requiring a heavy `R3` screenshot loop.
  - Rejects non-`https://`, local/private IPs, and sensitive auth/banking domains; never logs URLs or page content.
- **`S13.3` — XUNA Beam (`beam.send_to_host` & `beam.fetch_from_host`, Peer-to-Peer LAN `R2`):**
  - Inspired by `localsend/localsend` (Apache-2.0): transfers clipboard text, screenshots, or owner-selected files (`<= 25 MiB`) directly between `mobile/` and `desktop/` over the authenticated LAN channel (`:47821/xuna-beam`) with mutual P-256 proof and SHA-256 integrity check, bypassing the cloud backend completely.
- **`S13.4` — Atomic Batch Execution (`workflow.batch_steps`, `R2`):**
  - Inspired by `munim-computer-use`'s `run_steps`: validates every step in a multi-step sequence against `HostPolicyEvaluator` **before** executing Step 1 (`validate-all-before-run`, `1..5` steps, max `R2`), runs all steps locally on `desktop/` in a single XTP call, and streams step progress to the XUNA board bubble.
- **`S13.5` — Reversible Action Ledger & Quick Undo (`action.undo`, `R1`):**
  - Maintains a bounded in-memory stack (last 5 reversible actions per host, 10-minute TTL, e.g. `media.volume_set` → restore previous volume, `media.play_pause` → toggle back, `focus_session` → end focus session) so the owner can say *"Hoàn tác bước vừa rồi"* (`action.undo`, `R1`).

### Out of Scope
- Continuous 24/7 background screen recording / OCR indexing (`screenpipe`-style database): excluded to protect privacy, disk space, and laptop battery/CPU.
- Any new BLE opcode or RAM allocation on `firmware/`.

---

## 4. Detailed Design by Slice

### 4.1 `S13.1`: Instant Active-Window Context (`window.active_context`)
- **XTP Tool Descriptor (`desktop/packages/xuna_xtp/lib/src/schemas.dart`):**
  - `window.active_context` (`ToolFamily.app`, `ToolRisk.r1`, `observes: true`, `reversible: true`).
  - Input: `{maxChars?: 100..1200}` (default `800`).
  - Output: `{appName: string, windowTitle: string, focusedRole?: string, visibleSummary: string, redacted: boolean}`.
- **Security & Privacy Invariants:**
  - If the foreground window is elevated (Admin/UAC) or matches `isHardDeniedAppOrProcess` (`1password`, `bitwarden`, `keychain`, `cmd`, `powershell`, `terminal`, `iterm2`, `regedit`), `window.active_context` immediately refuses with `errorCode: "denied"` (`elevated_or_denied_window`).
  - All extracted text passes through `redactSensitiveSelectionText` (`sk-...`, `ghp_...`, `AIza...`, `Bearer`, `password=...` → `[REDACTED_SECRET]`).
  - Audit logs record only `{tool: "window.active_context", status, redacted}` — never window titles or text.

### 4.2 `S13.2`: Semantic Browser Snapshot (`browser.read_page`) & `@playwright/mcp` Priority
- **XTP Tool Descriptor:**
  - `browser.read_page` (`ToolFamily.url`, `ToolRisk.r1`, `observes: true`, `reversible: true`).
  - Input: `{browser?: "auto" | "edge" | "chrome" | "safari", maxChars?: 100..1600}`.
  - Output: `{browser: string, host: string, title: string, headings: string[], actions: string[], excerpt: string, redacted: boolean}`.
- **Playwright MCP Synergy:**
  - `AutoMcpBridge` recognizes `@playwright/mcp` (`playwright`) when present in local MCP configs and exposes a helper `hasPlaywrightMcp` so structured DOM accessibility snapshots can be used seamlessly.

### 4.3 `S13.3`: XUNA Beam — Peer-to-Peer LAN Transfer (`beam.transfer`)
- **Zero-Cloud Architecture:**
  - Control plane: `beam.transfer` (`ToolFamily.app`, `ToolRisk.r2`, `reversible: false`) negotiates a one-time transfer ticket (`{transferId, direction: "phone_to_host" | "host_to_phone", kind: "text" | "image" | "file", fileName, sizeBytes, sha256}`).
  - Data plane: `mobile/` and `desktop/` exchange the payload directly over LAN (`:47821`) authenticated with the pinned P-256 host/phone keys from `UDC-7` `S7.4`.
  - Files received on `desktop/` are written strictly inside a dedicated `~/Downloads/XUNA_Beam/` folder with sanitized basenames (no `..`, no path traversal, no executable `.exe`/`.bat`/`.sh`/`.command` extensions allowed!).

### 4.4 `S13.4`: Atomic Batch Execution (`workflow.batch_steps`)
- **Validate-All-Before-Run:**
  - Accepts `steps: [{tool, arguments}]` (`1..5` steps).
  - Pre-validates **every** step in `steps` against `HostPolicyEvaluator` and forbidden-tool rules before executing Step 1. If Step `k` would be denied or is `R3`, the entire batch is rejected before any side effect occurs!

### 4.5 `S13.5`: Reversible Action Ledger & Quick Undo (`action.undo`)
- **`ReversibleActionLedger` (`desktop/` & `backend/`):**
  - Tracks up to 5 reversible operations per host with a 10-minute expiration (`media.play_pause`, `media.volume_set` with `previousLevel`, `focus_session`).
  - `action.undo` (`ToolFamily.app`, `ToolRisk.r1`, `reversible: true`) pops the most recent non-expired reversible entry on the target host and executes its inverse operation.

---

## 5. Verification & Acceptance Criteria

1. **`firmware/`:** `0 B` RAM/Flash delta (`git -C firmware status` clean).
2. **`desktop/packages/xuna_xtp` & `desktop/`:**
   - `fvm dart analyze` & `fvm dart test` PASS.
   - `fvm flutter analyze --no-pub` & `fvm flutter test --no-pub` PASS (verifying `window.active_context` hard-denylist + secret redaction, `browser.read_page` `https://` + secret redaction, `beam.transfer` extension/path sanitization & SHA-256 verification, `workflow.batch_steps` validate-all-before-run atomicity, and `action.undo` inverse execution).
3. **`backend/`:**
   - `ruff check src tests`, `mypy src`, and `pytest` PASS (`test_udc13_ambient_copilot.py`).
4. **`mobile/`:**
   - `fvm dart format`, `fvm flutter analyze --no-pub`, and `fvm flutter test --no-pub test/features/actions/actions_test.dart` PASS.


# UDC-15 — Live Symbiotic Co-Pilot: Write-to-Clipboard Bridge (`clipboard.write`), Meeting & Mic Controller (`meeting.status`, `meeting.control`, `meeting_ready`), Localhost Dev-Port Doctor & Cross-Device LAN Preview (`dev.ports`, `preview_on_phone`), System Vitals (`system.vitals`) & Morning Standup Workflow (`daily_standup`)

Status: **Done (2026-10-31; [UDC-15-results-2026-10-31.md](UDC-15-results-2026-10-31.md))**. Complexity: **L (5 sessions: `S15.1` → `S15.5`)**. Repositories: `desktop/` (`xuna_xtp` + agent), `backend/`, `mobile/` (**0 bytes added to `firmware/`**).

---

## 1. Goal & Zero-Hardware-Cost Architecture

Turn XUNA into a **Live Symbiotic Desk Co-Pilot** that bridges the gap between AI thought and physical desktop/phone workflows across both **Windows 10/11** and **macOS 14+**:

1. **`S15.1` — Write-to-Clipboard Bridge (`clipboard.write`, `R2`, `ToolFamily.app`, `reversible: false`):**
   - Allows XUNA to place generated code snippets, translated replies, regex patterns, or terminal commands directly into the desktop's OS clipboard (`SetClipboardData` / `FlutterClipboard` on Windows, `NSPasteboard` / `pbcopy` on macOS) so the owner simply presses `Cmd+V` / `Ctrl+V`.
   - Enforces `1..4000` UTF-8 characters, rejects control-char/null-byte injection, automatically redacts raw secrets (`redactSensitiveSelectionText`) before writing, and **never logs clipboard content** (`UDC-T37`).
2. **`S15.2` — Meeting & Call Controller (`meeting.status` `R1`, `meeting.control` `R1` & `meeting_ready` Workflow):**
   - `meeting.status` (`R1`, `ToolFamily.media`, `observes: true`): detects active conferencing apps (`zoom`, `teams`, `meet`, `discord`, `facetime`, `slack`, `webex`) and current microphone mute state (`{inMeeting, app, micMuted}`).
   - `meeting.control` (`R1`, `ToolFamily.media`, `reversible: true`): executes deterministic microphone/call controls (`mute_mic`, `unmute_mic`, `toggle_mic`) across Windows and macOS (`osascript -e 'set volume input volume 0/80'` on macOS, WASAPI/Media input mute on Windows) and records the previous mic state in `ReversibleActionLedger` (`action.undo` restores mic state).
   - `meeting_ready` (`WorkflowTemplate.MEETING_READY`, `R1`): pauses local PC music (`media.play_pause` if playing), mutes Smart TV if online (`tv.control(mute_toggle)`), mutes/prepares microphone (`meeting.control`), and checks meeting status (`meeting.status`).
3. **`S15.3` — Localhost Dev-Port Doctor (`dev.ports` `R1`) & Cross-Device LAN Preview (`preview_on_phone` Workflow `R2`):**
   - `dev.ports` (`R1`, `ToolFamily.app`, `observes: true`): scans active localhost development ports (`3000`, `4200`, `5000`, `5173`, `5174`, `8000`, `8080`, `8888`) and identifies the listening dev server (`vite`, `next`, `node`, `python`, `flutter`, `dart`) plus the host's private LAN IPv4 address (`lanIp`, e.g., `192.168.1.x`) so the owner can preview local web apps on their phone.
   - `preview_on_phone` (`WorkflowTemplate.PREVIEW_ON_PHONE`, `R2`): queries `dev.ports` on the desktop host, builds the LAN preview URL (or HTTPS tunnel URL), asks **one** `R2` confirmation (`"{pc} → {phone} · Mở bản xem thử cổng :{port}"`), and opens the preview on the phone.
4. **`S15.4` — Symbiotic System Vitals (`system.vitals`, `R1`, `ToolFamily.host`, `observes: true`):**
   - Reads real-time cross-platform host health on Windows (`GetSystemPowerStatus`, `GlobalMemoryStatusEx`, `GetDiskFreeSpaceExW`) and macOS (`pmset -g batt`, `vm_stat`, `df -k`): `{batteryPercent, isCharging, memoryUsedPercent, diskFreeGb, thermalState, healthStatus}`.
5. **`S15.5` — Morning Briefing / Daily Standup Workflow (`daily_standup` `R1`) & Mobile Symbiotic Presets:**
   - `daily_standup` (`WorkflowTemplate.DAILY_STANDUP`, `R1`):
     1. Reads Git branch & uncommitted file counts (`workspace.git_summary`).
     2. Checks active localhost dev servers (`dev.ports`).
     3. Reads laptop battery, RAM, and disk health (`system.vitals`).
     4. Synthesizes a concise Vietnamese/English standup summary without requiring any `R2` approval.
   - `mobile/`: adds `SystemVitalsSummary`, `DevPortSummary`, `BoardWorkflowSlotConfig.symbioticCopilotPresets` (`meeting_ready`, `daily_standup`, `preview_on_phone`), and `HomeActionsService` state helpers.

---

## 2. Security & Privacy Invariants

1. **Zero Clipboard Content Logging (`UDC-T37`):** `clipboard.write` validates `1..4000` chars, strips/redacts secret tokens via `redactSensitiveSelectionText`, and logs only `{tool: "clipboard.write", charCount, status}`.
2. **Bounded Dev Port Inspection (`UDC-T38`):** `dev.ports` only inspects allowlisted development ports (`1024..65535`) and never exposes command-line arguments or environment variables of listening processes.
3. **Zero Firmware Overhead:** `firmware/` remains untouched (`0 B` RAM/Flash delta).

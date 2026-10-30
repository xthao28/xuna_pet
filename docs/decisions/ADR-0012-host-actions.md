# ADR-0012 — Host actions and closed board actuation exceptions

Date: 2026-10-30. **Status: Approved (owner 2026-10-30), not Implemented.** Amends [backend/AGENTS.md](../../backend/AGENTS.md) §1.4 and extends [ADR-0008](ADR-0008-cloud-brain-authority-and-identity.md).

## Context

- [backend/AGENTS.md](../../backend/AGENTS.md) §1.4 ("No device actuation from the cloud") forbids device actuation from the cloud and states that "a device action is never a model tool", with a single exception for display-only reply gestures (`ReplyGesture`, owner 2026-10-27).
- Under the Universal Device Control (UDC) track ([research](../research/XUNA_UNIVERSAL_DEVICE_CONTROL_RESEARCH.md), [architecture](../architecture/XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §3–§9, [security](../architecture/XUNA_DEVICE_CONTROL_SECURITY.md)), XUNA's Brain needs to invoke typed tools on the owner's computers and phones (**hosts**, identified by `HostId`), and optionally trigger media keys over the board's Bluetooth LE HID link.
- On 2026-10-30, the owner approved host actions as a distinct class (**R1**) and approved model-routed board HID media keys with per-press owner confirmation (**UDC-D6**, [roadmap §3](../roadmap/XUNA_UNIVERSAL_DEVICE_CONTROL_ROADMAP.md#3-owner-decisions-2026-10-30)).

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. Keep §1.4 unchanged and forbid all model tools with external effects** | Zero actuation risk | Prevents XUNA from acting on any computer or phone via the Brain |
| **B. Treat the board and hosts as the same "device" tool surface** | Single concept | Breaks device authority (H2 / ADR-0008); risks letting model output mutate pet life state or inject arbitrary HID keystrokes |
| **C. Separate host actions from device actions, with a closed exception list for the board** | Preserves board authority and life-state isolation; subjects every host or HID action to deterministic orchestration, grants, approvals and host re-validation | Adds `hosts` and `actions` modules and explicit capability gating |

## Decision

**Option C.**

1. **Host actions are a separate class from device actions.**
   - "Device" (`DeviceId`) continues to mean the XUNA pet board, which remains authoritative for identity, life state, needs, drives, personality, learning and snapshots ([ADR-0008](ADR-0008-cloud-brain-authority-and-identity.md)).
   - "Host" (`HostId`, [ADR-0013](ADR-0013-host-identity-and-sessions.md)) means an owner-enrolled computer or phone running a Host Agent.
   - Host actions are proposed by the model as untrusted tool calls (`ToolCallRequested`) and are executed **only** through the deterministic `actions` orchestrator, which enforces the pipeline:
     `schema validation → target resolution → grant check → owner approval (R2+) → host-side re-validation → audit`.
   - No arbitrary execution tool (`shell`, `powershell`, `osascript` source, `eval`, script upload or process kill) may exist at any milestone.
2. **Closed exception list for the board (`DeviceId`):**
   - **(a) Reply gestures (existing, owner 2026-10-27):** at most one expression cue per reply from the closed `ReplyGesture` set (`look_around`, `yawn_stretch`, `bounce_play`, `greet_nuzzle`), played by the app as a Track A preview (BLE opcode 1 args 4–7, display only).
   - **(b) HID consumer usages 1–7 (UDC-D6, owner 2026-10-30):** Consumer Page (`0x0C`) media keys `1..7` (`Play/Pause`, `Scan Next`, `Scan Previous`, `Volume Increment`, `Volume Decrement`, `Mute`, `Stop`) via BLE **opcode 12 (`HidConsumer`)** with `source = 2` (`brain-approved`), requiring **one explicit owner approval per press** and permitted **only** over the authenticated app ↔ board channel (UDC-2).
3. **Forbidden board actions:**
   - Keyboard text reports, pointer/mouse reports, and any action that changes the board's needs, drives, personality, learning, memory or snapshot remain strictly forbidden to model tools.
   - Outcomes of host actions affect the board through expression only (Track A preview and speech subtitles, **UDC-D7**).

## Consequences

- **New backend modules (UDC-3 / UDC-4):** `hosts` (registry, enrollment, sessions, grants) and `actions` (tool orchestrator, target resolution, approvals).
- **Turn capability gating (UDC-4):** `TurnBody.clientCapabilities` (`["host_actions_v1", "board_hid_v1"]`) gates whether tools are offered to the model on a turn; older clients receive no tool schemas or tool events.
- **Audit trail (UDC-3 / UDC-4 / UDC-7):** content-free `AuditAction` entries (`host.enrolled`, `host.enroll_rejected`, `host.revoked`, `host.connected`, `host.rejected`, `host.grant_changed`, `host.tool_invoked`, `host.tool_denied`, `host.approval_granted`, `host.approval_rejected`, `host.stopped`, `board.hid_requested`).
- **Negative architecture & unit tests (implemented in UDC-4, not now):** tests asserting that forbidden tool names (`shell.*`, `powershell.*`, `eval.*`, `keyboard.*`, `pointer.*`, or any life-state mutation tool) cannot be registered in the tool catalog or accepted from a host manifest, and that `board.hid_consumer` always requires per-press owner approval (`R2+` single-use approval bound to arguments).

## Evidence

- Architecture and security analysis: [XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md](../architecture/XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §3–§9, [XUNA_DEVICE_CONTROL_SECURITY.md](../architecture/XUNA_DEVICE_CONTROL_SECURITY.md) §1–§8.
- Milestone plan and ID register: [docs/roadmap/device-control/README.md](../roadmap/device-control/README.md) §2, [UDC-0-decision-records.md](../roadmap/device-control/UDC-0-decision-records.md) §5.1.
- Owner acceptance: **R1**, **R6**, **UDC-D6**, **UDC-D7** approved 2026-10-30 ([roadmap §3](../roadmap/XUNA_UNIVERSAL_DEVICE_CONTROL_ROADMAP.md#3-owner-decisions-2026-10-30)).


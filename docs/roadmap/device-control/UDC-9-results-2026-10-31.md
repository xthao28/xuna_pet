# UDC-9 — Cross-Device Workflows Results Record

Date: **2026-10-31**
Milestone: [UDC-9-10-workflows-learning.md](UDC-9-10-workflows-learning.md) (`S9.1`–`S9.3`)
Status: **Implemented & Verified on Host — Physical multi-host LAN + board button run pending**

---

## 1. Summary of Delivered Capabilities

### S9.1 — `browser.current_url` Tool (`R2`) & `link_to_phone` Composite Plan
- **`desktop/packages/xuna_xtp` ([`schemas.dart`](../../../desktop/packages/xuna_xtp/lib/src/schemas.dart), [`policy.dart`](../../../desktop/packages/xuna_xtp/lib/src/policy.dart)):**
  - Added `browser.current_url` (`ToolRisk.r2`, `observes: true`, `reversible: true`, `family: ToolFamily.url`, empty `additionalProperties: false` schema).
  - Enforced `https://` scheme validation, rejecting `http://`, `file://`, `chrome://`, `edge://`, `about:`, private IP literals (`127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `::1`, `fc00::/7`, `fe80::/10`), `localhost`, and `.local` hosts (`isAllowedHttpsCurrentUrl`).
- **`desktop/` ([`xuna_host_plugin.cpp`](../../../desktop/windows/runner/xuna_host_plugin.cpp), [`XunaHostPlugin.swift`](../../../desktop/macos/Runner/XunaHostPlugin.swift), [`host_tool_dispatcher.dart`](../../../desktop/lib/features/tools/host_tool_dispatcher.dart)):**
  - Windows native plugin reads the active tab URL from `msedge.exe` / `chrome.exe` via Windows UI Automation (`IUIAutomation`, `UIA_EditControlTypeId` + `IUIAutomationValuePattern`).
  - macOS native plugin reads the front document URL of Safari or active tab URL of Google Chrome via fixed compiled `NSAppleScript` snippets (`browser` parameter allowlisted to `safari` | `chrome`, never model-supplied source).
  - `HostToolDispatcher._handleBrowserCurrentUrl` validates the URL, extracts `domain`, and logs **only** `{tool: "browser.current_url", status: "ok"}` — **never logging the URL or domain**.
- **`backend/` ([`workflows.py`](../../../backend/src/xuna_backend/modules/actions/application/workflows.py)):**
  - `WorkflowPlanRunner._run_link_to_phone` executes:
    1. `browser.current_url` on the source PC (`pc_host_id`);
    2. Validates `https://` URL and extracts `domain`;
    3. Requests **one** combined R2 approval showing both hosts (`"{pc_alias} → {phone_alias}"`) and the `domain` only (`summary="Gửi liên kết {domain} sang {phone_alias}"`), bound to `args_sha256` of `{"url": url, "pcHostId": ..., "phoneHostId": ...}`;
    4. Executes `url.open` on the target phone (via `local_action_sender` when targeting `self_host_id`, or XTP WebSocket when running as a background host).

### S9.2 — `continue_media` & `pause_everywhere` Composite Plans
- **`continue_media` ([`workflows.py`](../../../backend/src/xuna_backend/modules/actions/application/workflows.py)):**
  - Executes deterministic 4-step hand-off:
    1. `media.now_playing` on source host A;
    2. Requests **one** combined approval (`"{from_alias} → {to_alias}"`, `summary="Chuyển nhạc ({player}) từ {from_alias} sang {to_alias}"`);
    3. `media.play_pause` (`pause`) on host A;
    4. `app.launch` (`appId: player`) on destination host B;
    5. `media.play_pause` (`play`) on host B.
  - Stops immediately at the first failing step (`failedStep`, `failedHost`), never retries on another host, and includes the note: *"Lưu ý: vị trí phát phụ thuộc vào đồng bộ tài khoản của trình phát (ví dụ Spotify Connect); XUNA không tự chuyển trạng thái vị trí phát."*
- **`pause_everywhere` ([`workflows.py`](../../../backend/src/xuna_backend/modules/actions/application/workflows.py)):**
  - Inspects all online hosts with `media` family granted plus board BLE HID if connected (`board_hid_enabled`).
  - Requests **one** approval listing all target aliases (`"Mọi thiết bị ({aliases})"`).
  - Queries `media.now_playing` per host and sends `media.play_pause` only when `playing: true` (reporting `paused`, `already_paused`, or `failed` per host) plus `board.media_key` (`stop`) when board HID is active.

### S9.3 — Remote `Workflows` Layout (`Opcode 13 arg=4`, `Status kind=3 arg=2|3`), App Settings & `workflow-trigger` Route
- **`firmware/` ([`BleProtocol.h`](../../../firmware/lib/xuna_core/include/xuna/BleProtocol.h), [`RemoteMode.h`](../../../firmware/lib/xuna_core/include/xuna/hid/RemoteMode.h), [`HidManager.h`](../../../firmware/include/HidManager.h), [`BleManager.h`](../../../firmware/include/BleManager.h)):**
  - Added `HidHostsArg::SetRemoteLayout = 4` (`RemoteLayout::Media = 0`, `RemoteLayout::Workflows = 1`), persisted in NVS namespace `xuna_hid` key `"layout"`.
  - Added `RemoteEventCode::WorkflowSlot1 = 2` and `RemoteEventCode::WorkflowSlot2 = 3` under `StatusChangeKind::RemoteEvent = 3` (capability byte 5 bit 6 `0x40`).
  - In `RemoteLayout::Workflows`, `GPIO0` short press emits `WorkflowSlot1` (`arg = 2`) with bubble `"Đang chạy: Quy trình 1"`, and `GPIO14` short press emits `WorkflowSlot2` (`arg = 3`) with bubble `"Đang chạy: Quy trình 2"`; holds remain unchanged (`GPIO14` hold exits Remote, `bothHold` triggers emergency stop).
- **`backend/` ([`routes.py`](../../../backend/src/xuna_backend/modules/actions/api/routes.py), [`entities.py`](../../../backend/src/xuna_backend/modules/actions/domain/entities.py)):**
  - Added `PUT /v1/actions/workflow-slots/{slot}` and `POST /v1/actions/workflow-trigger`.
  - Enforced security invariant **`UDC-T15`**: `R3` workflows are rejected with HTTP `400` `workflow_risk_forbidden` on both slot assignment and trigger (`validate_board_workflow_slot_risk`).
  - `R1` workflows execute immediately (owner physically present on board); `R2` workflows create a 60 s approval on the phone (`status: "awaiting_approval"`).
  - Returns `bubble: "Đang chạy: {workflow_name}"` and deterministic `gesture` (`bounce_play` on success, `look_around` on failure/denial).
- **`mobile/` ([`protocol_codec.dart`](../../../mobile/lib/features/device/data/codec/protocol_codec.dart), [`board_workflow_slot.dart`](../../../mobile/lib/features/actions/domain/entity/board_workflow_slot.dart), [`home_actions_service.dart`](../../../mobile/lib/features/home/presentation/service/home_actions_service.dart), [`home_remote_control_card.dart`](../../../mobile/lib/features/home/presentation/widgets/home_remote_control_card.dart)):**
  - `ProtocolCodec` encodes opcode 13 `arg = 4` (`source = 0|1`) and decodes status `kind = 3` `arg = 1..3`.
  - `HomeRemoteControlCard` adds the **"Bố cục nút Remote trên mạch"** selector (`Phím nhạc (Media)` vs `Quy trình (Workflows)`) and slot 1 (`GPIO0`) / slot 2 (`GPIO14`) configuration & test-trigger controls (filtering out `R3` workflows).
  - `HomeController._listenStatus` automatically routes board status `kind = 3` (`arg = 2|3`) to `HomeActionsService.triggerBoardWorkflowSlot(slot)`.

---

## 2. Verification Matrix

| Suite | Command | Result |
|---|---|---|
| Firmware native (`test_remote_mode` + full 54 suites) | `pio test -d firmware -e native` | **419/419 PASS** (`test_remote_mode` **6/6 PASS**) |
| Firmware ESP32-S3 build + purity | `pio run -d firmware -e xuna_t_display_s3` | **SUCCESS** (`xuna_core purity check: PASS`, RAM `18.5%` / `60,696 B`, Flash `60.2%` / `3,946,353 B`) |
| `desktop/packages/xuna_xtp` | `fvm dart analyze && fvm dart test` | **0 issues, 20/20 PASS** |
| `desktop/` | `fvm flutter analyze --no-pub && fvm flutter test --no-pub` | **0 issues, 21/21 PASS** (10/10 simulated Edge/Chrome Windows & Safari/Chrome macOS cases + URL redaction check) |
| `backend/` lint & typecheck | `ruff check src tests && mypy src` | **0 issues (214 files)** |
| `backend/` unit & module tests | `pytest -q` | **472/472 PASS** (`74 skipped`; `test_udc9_workflows.py` 7/7 PASS, `actions` 80/80 PASS) |
| `mobile/` analyze & test | `fvm flutter analyze --no-pub && fvm flutter test --no-pub` | **0 issues, 397/397 PASS** |

---

## 3. What Was Not Run

- Physical multi-host LAN hand-off run (`link_to_phone` and `continue_media` between a live Windows/macOS desktop and physical phone over LAN/cloud).
- Physical board upload and button press latency measurement (`GPIO0`/`GPIO14` short press in `Workflows` layout → PC workflow execution within 2 s on LAN).

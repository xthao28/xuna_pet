# UDC-6 — iOS Adapter & Board AMS Spike Results (2026-10-30)

Status: **Implemented** (automated unit/widget/native/backend/firmware verification PASS; physical iPhone + T-Display-S3 board acceptance matrix ready for owner device run).

---

## 1. Summary of Delivered Sessions (S6.1–S6.3)

| Session | Deliverable | Verification Evidence |
|---|---|---|
| **S6.1 — App Intents & `xuna/ios_bridge`** | Swift App Intents (`AskXunaIntent`, `StopXunaActionsIntent`, `OpenXunaRemoteIntent`, `XunaShortcutsProvider` with Vietnamese & English Siri/Shortcuts phrases, `@available(iOS 16.0, *)`); `XunaIosHostPlugin` (`MethodChannel("xuna/ios_bridge")`) syncing `petId`, `apiBaseUrl`, `locale`, and `pendingApprovalId` in `UserDefaults.standard` (**never tokens**); fresh Firebase token fetched natively via `Auth.auth().currentUser?.getIDToken()`; `AskXunaIntent` omits `clientCapabilities` so zero host/board tools run from Siri | `ios_host_adapter_test.dart` S6.1 Channel & Native source guard tests PASS; `fvm flutter analyze --no-pub` 0 issues |
| **S6.2 — iPhone Foreground-Only Host** | Secure Enclave / Keychain P-256 key (`keyEnsure` / `keySign`, 64 B `r ‖ s`); `SelfEnrollIosHostUseCase` (`POST /v1/hosts/self` with `platform: "ios"`); `ExecuteIosHostToolUseCase` (`url.open` on allowlisted `https://` domains, `media.play_pause`/`next`/`previous`/`now_playing` for **Apple Music only** via `MPMusicPlayerController.systemMusicPlayer` + `NSAppleMusicUsageDescription` + `MPMediaLibrary.requestAuthorization`, `host.status`); Backend `ToolPermissionState.UNSUPPORTED` filtering in `catalog.py` & `status: "unsupported"` rejection in `orchestrator.py`; `IosPhoneHostCard` with Apple Music permission, Shortcuts guide, BLE HID + AMS guidance, and `UIAccessibility.isGuidedAccessEnabled` desk-dock status | Backend: `ruff check` 0 errors, `mypy src` 0 issues, `pytest` `458 passed` (`test_ios_self_enroll_and_unsupported_tools_filtered_and_rejected`); Mobile: `ios_host_adapter_test.dart` 11/11 PASS, full `fvm flutter test --no-pub` `388 passed` |
| **S6.3 — AMS Spike on the Board (`xuna_ams`)** | Pure C++11 `xuna/hid/AmsClientModel.h` (AMS service `89D3502B-0F36-433A-8EF4-C502AD55F8DC`, Remote Command `9B3C81D8-57B1-4A8A-B8DF-0E56F7CA51C2`, Entity Update `2F7CABCE-808D-411F-9A0C-BB92BA96C102`, Entity Attribute `C6B2F38C-23AB-46D8-A6AB-A3A870BBD5D7`, UTF-8 safe `<= 24` code-point truncation, `formatRemoteBubble`); `AmsGattClient.h` opening a GATT client on the bonded iPhone's existing ACL link (`esp_ble_gattc_open`); `HidManager.h` routing Remote presses over AMS when ready and updating the Remote bubble in RAM only; capability byte 5 bit 7 (`0x80`) in `[env:xuna_ams]` | `tools/check_core_purity.py` PASS; `pio test -d firmware -e native -f test_ams_client` 5/5 PASS (full native suite 54/54 suites, 417/417 test cases PASS); `pio run -e xuna_t_display_s3` (0 B delta) & `pio run -e xuna_ams` (+184 B RAM, +7,012 B Flash) SUCCESS |

---

## 2. S6.1 & S6.2 — iOS Security, Privacy & App Review Matrix

| Requirement / Guideline | Implementation | Verification |
|---|---|---|
| **No token storage in `UserDefaults`** | `XunaIntentContextStore` stores only `petId`, `apiBaseUrl`, `locale`, and `pendingApprovalId`. `AskXunaIntent` and `StopXunaActionsIntent` call `Auth.auth().currentUser?.getIDToken()` on demand. | Verified by unit test & Swift source guard in `ios_host_adapter_test.dart` |
| **No tool execution from Siri (`AskXunaIntent`)** | `AskXunaIntent` posts `{"text": text, "locale": locale}` to `POST /v1/conversations/{petId}/turns` with **no** `clientCapabilities` field, guaranteeing the backend orchestrator does not offer or invoke any host/board tools during Siri turns. | Verified by Swift source guard (`!intentsSrc.contains('"clientCapabilities"')`) |
| **Emergency Stop (`StopXunaActionsIntent`)** | If `pendingApprovalId` is present in `XunaIntentContextStore`, sends `POST /v1/actions/approvals/{approvalId}` with `{"decision": "reject"}` and notifies the Flutter engine (`onStopActionsRequested`) to cancel any active turn or local action. | Verified in `HomeActionsService` test (`ios_host_adapter_test.dart`) |
| **Foreground-only host (`platform: "ios"`)** | No background WebSocket or background mode added to `Info.plist` (App Review 2.5.4 compliant). Same-device `local_action_request` events execute only while the XUNA app is foregrounded. | Verified in `ExecuteIosHostToolUseCase` & `HomeActionsService` |
| **Apple Music vs Third-Party Players** | `media.play_pause`, `media.next`, `media.previous`, and `media.now_playing` use `MPMusicPlayerController.systemMusicPlayer` (App Review 2.5.1 compliant, `NSAppleMusicUsageDescription` declared in `Info.plist`). Third-party players (Spotify, YouTube) are explicitly marked `player: "apple_music"` in the iOS host manifest; all-player control on iPhone is handled by the board over **BLE HID Consumer Control** (UDC-1/2) or **AMS** (S6.3). | Verified in `ExecuteIosHostToolUseCase` & `IosHostRepositoryImpl` |
| **Unsupported tools (`ToolPermissionState.UNSUPPORTED`)** | `media.volume_set`, `app.launch`, `app.list_allowed`, `ui.back`, `ui.home`, `ui.recents`, and `ui.tap_text` are enrolled with `permission: "unsupported"`. Backend `is_tool_granted()` excludes them from the LLM catalog; direct invocation returns `status: "unsupported"` and logs `AuditAction.HOST_TOOL_DENIED` (`reason: "unsupported"`). | Verified in `test_self_enrollment_and_local_action.py` (`6/6 passed`) and `ios_host_adapter_test.dart` |
| **Guided Access Desk-Dock Mode** | `XunaIosHostPlugin` reads `UIAccessibility.isGuidedAccessEnabled` and listens to `UIAccessibility.guidedAccessStatusDidChangeNotification`, updating `IosPhoneHostCard` live with setup instructions (*Cài đặt → Trợ năng → Truy cập được hướng dẫn*). | Verified in `IosPhoneHostCard` widget test |

---

## 3. S6.3 — Firmware AMS Spike Measurements & Architecture

### 3.1 Build Size & RAM Comparison (`xuna_t_display_s3` vs `xuna_ams`)

| Environment | Flag | Capability Byte 5 | RAM Used (of 327,680 B) | Flash Used (of 6,553,600 B) | Delta vs Default Build |
|---|---|---|---|---|---|
| `xuna_t_display_s3` (default production) | `XUNA_AMS` unset (`0`) | `0x03` (bits 0–1: BLE HID Consumer + Remote mode) | **60,696 B** (`18.5%`) | **3,946,161 B** (`60.2%`) | **+0 B RAM / +0 B Flash** |
| `xuna_ams` (experimental AMS spike) | `-DXUNA_AMS=1` | `0x83` (`0x03 \| 0x80`, bit 7 = AMS client present) | **60,880 B** (`18.6%`) | **3,953,173 B** (`60.3%`) | **+184 B RAM / +7,012 B Flash** |

### 3.2 AMS GATT Client Flow (`AmsGattClient.h` + `AmsClientModel.h`)

1. **Existing ACL Link Reuse:** When a bonded iPhone connects and encryption completes (`HidManager::onAuthComplete`), `AmsGattClient::onBondReady(bda, addrType)` queues `esp_ble_gattc_open(gattcIf_, bda, addrType, true)` on the existing BLE ACL link (following the ESP-IDF Bluedroid ANCS pattern).
2. **Service & Characteristic Discovery:** Discovers AMS (`89D3502B-0F36-433A-8EF4-C502AD55F8DC`) and locates:
   - `Remote Command` (`9B3C81D8-57B1-4A8A-B8DF-0E56F7CA51C2`)
   - `Entity Update` (`2F7CABCE-808D-411F-9A0C-BB92BA96C102`)
   - `Entity Attribute` (`C6B2F38C-23AB-46D8-A6AB-A3A870BBD5D7`)
3. **CCCD & Entity Subscriptions:** Registers for notifications on `Remote Command` and `Entity Update`, then writes:
   - Entity Update `[0x02, 0x00, 0x02]` (`EntityId::Track`, `TrackAttr::Artist`, `TrackAttr::Title`)
   - Entity Update `[0x00, 0x01]` (`EntityId::Player`, `PlayerAttr::PlaybackInfo`)
4. **Remote Command Routing & Fallback:** In Remote mode (`HidManager::handleRemotePress`), when `ams_.isReady()` is true and the command is in the iPhone's `supportedCommandsMask`, the board writes the AMS Remote Command byte (`TogglePlayPause = 2`, `NextTrack = 3`, `PreviousTrack = 4`, `VolumeUp = 5`, `VolumeDown = 6`). If AMS is not ready or the connected host is Android/macOS/Windows, it transparently falls back to BLE HID Consumer Control (`0x00CD`, `0x00B5`, `0x00EA`, `0x00E9`).
5. **RAM-Only Track Bubble:** Track Title and Artist notifications are truncated on UTF-8 code-point boundaries to `<= 24` characters (`AmsClientModel::truncateUtf8CodePoints`) and shown in the board's Remote bubble (`♪ Title` or `║ Title`). Nothing is written to NVS or transmitted over BLE/cloud.

---

## 4. Owner Physical Device & Board Acceptance Runbook

1. **Flash Experimental AMS Build (optional for S6.3):**
   ```bash
   ~/.platformio/penv/bin/pio run -d firmware -e xuna_ams -t upload
   ```
2. **S6.3 AMS Check on Bonded iPhone (XUNA app closed):**
   - Bond the iPhone with the board (`XUNA` BLE HID + encrypted link).
   - Open `pio device monitor -d firmware` and run `ams status` to verify `ready=1`.
   - Force-close the XUNA iOS app, play a song in **Apple Music** and **Spotify**, enter Remote mode on the board (both buttons 400 ms), and verify:
     - Play/Pause, Next, and Volume Down work 10/10.
     - The Remote bubble updates with `♪ <Title>` within 1 s of a track change.
3. **S6.1 App Intents (iOS 16+):**
   - Sign in on the XUNA iOS app and select your pet (`xuna/ios_bridge` syncs `petId` and `apiBaseUrl`).
   - Say *"Hey Siri, Hỏi XUNA hôm nay bạn thế nào"* or run **Hỏi XUNA** in the Shortcuts app → verify Siri speaks XUNA's reply and no host/board tools are invoked.
   - Trigger an R2 action (`url.open`) and run **Dừng mọi thao tác của XUNA** → verify the pending approval is rejected.
4. **S6.2 Foreground Host & Guided Access:**
   - Open **Thiết bị (Hosts)** on the iPhone → tap **Bật điều khiển trên iPhone này** (`IosPhoneHostCard`) and **Cấp quyền Apple Music**.
   - Ask XUNA *"tạm dừng nhạc trên iPhone"* → verify Apple Music pauses.
   - Ask XUNA *"mở trang github.com trên iPhone"* → approve the R2 card → verify Safari opens `https://github.com`.
   - Enable **Guided Access** (triple-click side button) → verify `IosPhoneHostCard` updates live to **Đang bật Chế độ bàn (Guided Access)**.


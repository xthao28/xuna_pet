# UDC-2 — Host Verification Results & Board Acceptance Runbook (2026-10-30)

Date: 2026-10-30. Milestone: [UDC-2-secure-channel.md](UDC-2-secure-channel.md).
Status: **S2.1 + S2.2 + S2.3 Implemented and host-verified; S2.4 physical board + phones + desktop acceptance pending.**

---

## 1. Summary of Implemented Scope (S2.1 – S2.3)

### S2.1 — Firmware Pure C++11 Core (`firmware/lib/xuna_core/`)
- **`xuna/hid/HidHostsCodec.h`:**
  - `HidHostSlotProjection`, `HidHostsProjection`, `HidHostsCodec::encode` / `HidHostsCodec::decode` for the 16-byte `7a6e0015` projection (`version = 1`, `size = 16`, `flags` bits 0–4, `connectedSlot`, `bondCount`, 4 slots × 2 bytes `[slotFlags, lastSeenDays]`, reserved bytes `13..15 = 0`, zero Bluetooth addresses exposed).
  - `HidSlotTable`: 4 stable slots (`0..3`) keyed by 32-bit FNV-1a address hash (`hashAddress(const uint8_t bda[6])`), reusing the lowest free slot, capped at 4 bonds, serialized as a 36-byte NVS blob (`xuna_hid/slots`).
- **`xuna/hid/HidRateLimiter.h`:**
  - Sliding-window rate limiter enforcing `<= 4` presses per `1000 ms` and `<= 30` presses per `60000 ms` across both sources (`1 = app button`, `2 = brain-approved`).
- **`xuna/hid/PairingWindow.h`:**
  - `PairingWindow`: 60 s window (`kDefaultDurationMs = 60000`), openable via manual request (QR card / opcode 13 `arg = 3`), or implicitly when `bondCount == 0` or `inEgg == true`, and capped at `bondCount < 4`. Closes immediately on a completed bond or after 60 s.
  - `ForgetAllConfirm`: 10 s physical confirmation state machine (`GPIO0` / `happy` confirms → `Result::Confirmed`, `GPIO14` / `idle` cancels → `Result::Rejected`, 10 s expiry → `Result::Expired`) for opcode 13 `arg = 2`.
- **`xuna/BleProtocol.h` & `xuna/protocol/V1LifeCoreAdapter.h`:**
  - Added `bool hid = false` parameter on `parseCommand` (default `false` so all existing callers and S08a byte-compatibility replay are unchanged).
  - Added `IHidControl` interface and `V1LifeCoreAdapter` handlers for:
    - **Opcode 12 (`HidConsumer`):** validates `arg in 1..7`, `source in 1..2`, `hidControl_->isBondedApp()` and `hidControl_->isHostConnected()`, checks `requestId` deduplication, enforces `HidRateLimiter`, calls `sendConsumerKey(arg, source)`, records feedback bubble (`"▶︎ Play/Pause"` + `" (XUNA hỏi rồi)"` when `source == 2`), and returns before any `LifeCoreEvent` is constructed.
    - **Opcode 13 (`HidHosts`):** `arg = 1` (`source in 0..3`) forgets a single slot; `arg = 2` (`source == 0`) starts the 10 s physical confirmation on the board (`kDeferred = 255`, resolved via `rememberDeferred(requestId, code)` on confirm/reject/expire); `arg = 3` (`source == 0`) opens the 60 s pairing window.

### S2.2 — Firmware Board Glue (`firmware/`)
- **`platformio.ini`:** Enabled `-DXUNA_HID=1` in the default `[env:xuna_t_display_s3]` and `[env:xuna_net]` builds (retaining `[env:xuna_hid]` and `[env:xuna_hid_net]` aliases).
- **`include/HidManager.h`:**
  - Persists `HidSlotTable` in NVS namespace `xuna_hid` (`key = "slots"`), syncs with the Bluedroid bond list on boot and bond events, and tracks `PairingWindow` + `ForgetAllConfirm`.
  - Rejects `ESP_GAP_BLE_NC_REQ_EVT` (`esp_ble_confirm_reply(bda, false)`) immediately when `canAcceptPairing()` is false (outside the 60 s pairing window or when 4 bonds are already stored).
  - Provides `notifyApp(gattsIf, charHandle, data, len)` using `esp_ble_gatts_send_indicate(..., appConnId(), ..., false)` so custom-service notifications go only to the app connection and never leak to a separate HID host link.
- **`include/BleManager.h` & `src/main.cpp`:**
  - Set capability byte 5 to `0x3f` (`0x07 | 0x08 HID | 0x10 opcodes 12–13 + 0015 | 0x20 authenticated channel`).
  - Applied `ESP_GATT_PERM_READ_ENCRYPTED` / `ESP_GATT_PERM_WRITE_ENCRYPTED` to all custom characteristics and CCCDs (`0003`–`0015`) except `7a6e0002` (capabilities, open read so an unbonded app can read capability byte 5 before pairing).
  - Added characteristic `7a6e0015` (`HID Hosts V1`, read + notify, 16 bytes).
  - Wired both-hold 3 s pairing QR card to open the 60 s pairing window, wired `ForgetAllConfirm` to resolve deferred opcode 13 `arg = 2` results, and wired opcode 12 feedback bubbles.

### S2.3 — Mobile Companion App (`mobile/`)
- **Domain (`lib/features/device/domain/`):**
  - Entities: `MediaKey` (`1..7`), `MediaKeySource` (`appButton = 1`, `brainApproved = 2`), `HidHostSlot`, `HidHostsState`, `DeviceExceptionKind.pairingRequired`, `DevicePreferences.hidHostLabels`.
  - Use cases: `SendMediaKeyUseCase`, `ReadHidHostsUseCase`, `WatchHidHostsUseCase`, `ForgetHidHostUseCase`, `OpenPairingWindowUseCase`, `RenameHidHostUseCase`, `EnsureDevicePairedUseCase`.
- **Data (`lib/features/device/data/`):**
  - `DeviceProtocol`, `DeviceCommandModel`, `ProtocolCodec` (`supportsHid`, `supportsHidControl`, `supportsAuthenticatedChannel`, `decodeHidHosts`), `HidHostsModel`, `HidHostsMapper`.
  - `DeviceBleDataSourceImpl` (`_hidHosts = 21` / `7a6e0015`, read + notify subscription, `ensureBonded()` calling `createBond` on Android with retry, ATT insufficient-authentication/encryption error translation into `DeviceExceptionKind.pairingRequired`, 12 s command timeout for `hidHostsForgetAll`).
  - `SimulatorDeviceBleDataSource`: full simulation of `7a6e0015` slots, active host, opcodes 12 & 13, and pairing window.
- **Presentation (`lib/features/home/presentation/`):**
  - `HomeRemoteControlCard`: active host banner, 6 media control buttons (`Play/Pause`, `Previous`, `Next`, `Vol −`, `Vol +`, `Mute` sending opcode 12 with `source = 1`), paired host slot list (`0..3`) with local rename dialog and single-slot forget confirmation, `"Ghép máy mới"` button (opens 60 s window + shows `HomePairingGuideSheet`), and `"Quên tất cả"` button (with 10 s board confirmation reminder).
  - `HomePairingGuideSheet`: guided 3-step pairing instructions when `DeviceExceptionKind.pairingRequired` occurs or when pairing a new host.
  - Bilingual strings (`vi_VN.json`, `en_US.json`, `locales.g.dart`: 652 keys in sync).

---

## 2. Host Verification Evidence (2026-10-30, Windows)

| Check | Command | Result |
|---|---|---|
| Firmware core purity | `python firmware/tools/check_core_purity.py` (via `pio run`) | **PASS** |
| Firmware native Unity tests | `pio test -d firmware -e native` | **411 / 411 PASS** across **53 / 53 test suites** (`test_hid_hosts_codec`, `test_hid_rate_limiter`, `test_pairing_window`, `test_v1_adapter` 28/28 including S08a byte-compat replay and `opcode_12_hid_consumer_never_mutates_life_or_learner`) |
| Firmware default build (`xuna_t_display_s3`) | `pio run -d firmware -e xuna_t_display_s3` | **SUCCESS** — RAM `18.5%` (`60,688 / 327,680 B`), Flash `60.2%` (`3,945,645 / 6,553,600 B`) |
| Firmware net build (`xuna_net`) | `pio run -d firmware -e xuna_net` | **SUCCESS** — RAM `25.7%` (`84,216 / 327,680 B`), Flash `67.5%` (`4,425,061 / 6,553,600 B`) |
| Firmware alias builds (`xuna_hid`, `xuna_hid_net`) | `pio run -d firmware -e xuna_hid -e xuna_hid_net` | **SUCCESS** (identical to default / net builds now that `XUNA_HID=1` is default) |
| Mobile formatting | `fvm dart format --output=none --set-exit-if-changed lib test` | **PASS** (0 changes needed) |
| Mobile static analysis | `fvm flutter analyze --no-pub` | **PASS** (`No issues found!`) |
| Mobile unit & widget tests | `fvm flutter test --no-pub` | **341 / 341 PASS** (including `protocol_codec_test.dart`, `device_repository_impl_test.dart`, `home_remote_control_card_test.dart`, `home_page_test.dart`, `locales_sync_test.dart`) |

---

## 3. S2.4 Physical Board + Phones Acceptance Checklist (Pending Hardware Run)

Run this checklist when the LILYGO T-Display-S3 board and test phones/hosts are connected:

1. **Security — Unbonded phone negative test:**
   - [ ] With the pairing window closed on the board, attempt to write `7a6e0003` or read `7a6e0005` from a second, unbonded phone using nRF Connect.
   - [ ] Expected: 0 accepted writes/reads (ATT `Insufficient Authentication` / `Insufficient Encryption`), and **0 pairing prompts** shown on the board screen.
2. **Migration & Guided Pairing:**
   - [ ] Connect from an existing XUNA app install before OS bonding: app reads `7a6e0002` (open read), detects `pairingRequired` on protected characteristic access, and shows the pairing banner / `HomePairingGuideSheet`.
   - [ ] Hold both board buttons (`GPIO0 + GPIO14`) for 3 s to open the QR card + 60 s pairing window, confirm the 6-digit numeric comparison on the board (`GPIO0`), and verify all app features (status, chat gestures, hatch, knowledge, display settings, Remote card) work.
3. **Media Keys via Opcode 12:**
   - [ ] Pair Mac and Windows 11 as HID hosts via `"Ghép máy mới"` in the app's Remote card.
   - [ ] Press Play/Pause, Next, Previous, Vol −, Vol +, Mute from the app Remote card: verify 20/20 key delivery on Mac and Windows, board bubble `"▶︎ Play/Pause"`, and zero life/learning state change (`test_v1_adapter` + serial log).
   - [ ] Tap a media button 5 times within 1 second: verify the 5th press returns `kBusy` (rate limit `<= 4/s`).
4. **Host Management (`7a6e0015` + Opcode 13):**
   - [ ] Rename a paired host slot in the app and verify the label persists across app restarts (Hive local preferences) while `7a6e0015` never exposes Bluetooth MAC addresses.
   - [ ] Tap `"Quên máy này"` (`opcode 13, arg = 1`): verify the slot is removed from `7a6e0015` and the host bond is deleted.
   - [ ] Tap `"Quên tất cả"` (`opcode 13, arg = 2`): verify the board displays `"Quên hết máy? Bấm nút trên (10s)"`; pressing `GPIO0` within 10 s clears all bonds and returns `kOk`, whereas waiting > 10 s or pressing `GPIO14` returns `kExpired` and keeps bonds intact.
   - [ ] With 4 slots occupied, verify a 5th pairing attempt is refused until a slot is forgotten.


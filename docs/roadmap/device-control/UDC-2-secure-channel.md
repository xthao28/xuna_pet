# UDC-2 — Authenticated board channel, HID management and the media-key opcode

Status: **S2.1 + S2.2 + S2.3 Done 2026-10-30 ([results](UDC-2-results-2026-10-30.md)); S2.4 board + phones acceptance pending**. Complexity: M–L (4 sessions). Repositories: firmware, mobile.

## 1. Goal

1. Only a phone that the owner physically approved at the board can send control commands. This closes the "anyone in range can write" gap (security UDC-T9).
2. HID becomes a normal, capability-gated feature in the default build.
3. The app can name and manage HID hosts and send media keys through opcode 12. This is the path UDC-4 later uses for model-routed keys (UDC-D6).

## 2. Gate

- UDC-1 PASS (results file).
- Owner go-ahead, including "HID in the default build".
- UDC-D8 decided: if NimBLE is chosen, this milestone is re-planned on that stack first.

## 3. Read first

- [README](README.md) ID register: opcode 12/13, characteristic `0015`, capability byte 5 bits 4–5.
- UDC-1 results and `firmware/include/HidManager.h`.
- `firmware/lib/xuna_core/include/xuna/BleProtocol.h` (`parseCommand` and its flags).
- `lib/xuna_core/include/xuna/protocol/V1LifeCoreAdapter.h`: `handle()` switch and the `Result` enum.
- Mobile:
  - `lib/features/device/data/codec/device_protocol.dart`
  - `protocol_codec.dart`
  - `data_source/device_ble_data_source_impl.dart` (characteristic table, capability parsing at ~L220–300)
  - `simulator_device_ble_data_source.dart`
  - `repository/device_repository_impl.dart`
  - `lib/features/home/presentation/service/home_device_service.dart`
  - [mobile/AGENTS.md](../../../mobile/AGENTS.md) and [FEATURE_TEMPLATE.md](../../../mobile/docs/FEATURE_TEMPLATE.md)
- `flutter_blue_plus` 1.35.5 API for bonding: `BluetoothDevice.createBond()` (Android only), `bondState` stream. iOS pairs automatically when an encrypted characteristic is accessed.

## 4. Scope

**In scope:**

- Bonded/encrypted custom-service writes.
- A pairing window.
- Opcodes 12/13.
- Characteristic `0015`.
- Targeted notifications.
- HID in the default build.
- App: pairing flow, HID host list with names, a Remote panel with media keys.

**Out of scope:**

- Keyboard text and mouse.
- Model routing (UDC-4).
- Multi-host switching beyond "forget".
- AMS.

## 5. Design

### 5.1 Channel security

| Attribute group | UDC-1 | UDC-2 |
|---|---|---|
| `0002` capabilities | open read | **open read** (the app must learn it has to pair) |
| `0003` command, `000d` proof, `0010` speech, `0011` net config (writes) | open | `ESP_GATT_PERM_WRITE_ENCRYPTED` |
| `0004` status notify, projections `0005`–`0014`, `0015` (reads) | open | `ESP_GATT_PERM_READ_ENCRYPTED` |
| HID service | encrypted | encrypted |

- **Bonding is the owner's physical approval**: numeric comparison on the board screen, confirmed with GPIO0.
- No extra application-level secret is added in this milestone. The phone's bond keys protect the link.

**Pairing window.** A numeric-comparison prompt is shown only when the window is open. Outside it, `ESP_GAP_BLE_NC_REQ_EVT` is rejected immediately (`esp_ble_confirm_reply(bda,false)`). This stops strangers from spamming prompts. The window opens when one of these holds:

- (a) the pairing QR card is shown (existing both-hold 3 s);
- (b) opcode 13 arg 3 arrives from a bonded app;
- (c) there are zero bonds (first setup and after "forget all");
- (d) the board is in Egg.

It closes after 60 s or after one successful bond.

**Migration of existing owners:**

- After the firmware update, the app gets ATT "insufficient authentication/encryption" on its first protected access.
- The app then shows: "Giữ cả hai nút 3 giây trên XUNA rồi xác nhận số trên màn hình."
- Android: the app calls `createBond()` once the window is open. iOS: the OS shows its pairing sheet automatically.

**Targeted notifications:**

- `status_` and `netStatus_` notifications go only to the app link (`esp_ble_gatts_send_indicate` with the app conn id). The UDC-1 leak to the HID host is fixed.
- HID reports go only to the HID host link.

### 5.2 New protocol items (normative copy goes to the BLE table in UDC-0 S0.2)

**Opcode 12 `HidConsumer`**, 8 bytes:

- Layout: `[0]=1, [1]=12, [2..5]=requestId u32 LE, [6]=arg (usage index 1..7), [7]=source (1 = app button, 2 = brain-approved)`.
- The board validates `arg ∈ 1..7`, `source ∈ {1,2}`, a bonded link and a connected HID host.
- Rate limit: ≤ 4 presses/s and ≤ 30/min across both sources, else `kBusy`.
- The same `requestId` repeated returns the first result without pressing again (existing dedupe pattern).
- Results:
  - `kOk`;
  - `kInvalidArgument`;
  - `kNotReady` (no host connected or link not bonded);
  - `kBusy`.
- Feedback: board bubble `"▶︎ Play/Pause"` (+ `"(XUNA hỏi rồi)"` when source 2), expression only.
- **Never a life event:** the adapter returns before any `LifeCoreEvent` is built. Add a test.

**Opcode 13 `HidHosts`**, 8 bytes:

- `arg = 1`: forget slot `source` (0..3).
- `arg = 2`: forget all. The board asks on screen; GPIO0 within 10 s confirms → `kOk`; otherwise `kExpired`.
- `arg = 3`: open the pairing window for 60 s.
- Other values → `kInvalidArgument`.

**Characteristic `7a6e0015` HID Hosts V1**, read + notify, 16 bytes:

| Byte | Content |
|---|---|
| 0 | version = 1 |
| 1 | size = 16 |
| 2 | flags: bit0 HID enabled, bit1 host connected, bit2 Remote active, bit3 pairing window open, bit4 pairing prompt pending |
| 3 | connected slot (0..3, 0xFF none) |
| 4 | bond count |
| 5..12 | 4 slots × 2 bytes: `[slotFlags (bit0 used, bit1 connected, bit2 is the app phone), lastSeenDays (0..254, 255 = unknown)]` |
| 13..15 | reserved 0 |

- **No Bluetooth addresses leave the board.**
- Slots are stable. The board keeps a small NVS map `xuna_hid/slots` (bond address hash → slot 0..3) in its own namespace and reuses the lowest free slot.
- At most 4 HID bonds. A fifth pairing is refused until a slot is forgotten.

Capability byte 5:

- bit 3 (HID present; now set in the default build);
- bit 4 (opcodes 12/13 + `0015`);
- bit 5 (authenticated channel).

### 5.3 Mobile (Clean Architecture per mobile/AGENTS.md)

| Layer | Additions |
|---|---|
| Codec | `DeviceProtocol.opcodeHidConsumer = 12`, `opcodeHidHosts = 13`, `capabilityHid = 1 << 3`, `capabilityHidControl = 1 << 4`, `capabilityAuthenticatedChannel = 1 << 5` (byte 5); `ProtocolCodec.encodeHidConsumer`, `encodeHidHosts`, `decodeHidHosts` (strict length/version checks like `decodeRoutine`) |
| Data source | Characteristic part `_hidHosts = 21` (`7a6e0015`); `supportsHid*` flags; notify subscription; bonding helper (Android `createBond`, iOS no-op); map ATT insufficient-auth errors to a typed `DevicePairingRequiredException` |
| Simulator | Fake host slots, a fake connected host, and the full command results so UI tests run without a board |
| Domain | `MediaKey` enum (1..7), `HidHostSlot` (slot, used, connected, isAppPhone, lastSeenDays, ownerLabel), `HidHostsState`; use cases `SendMediaKeyUseCase`, `ReadHidHostsUseCase`, `ForgetHidHostUseCase`, `OpenPairingWindowUseCase`, `RenameHidHostUseCase` (local only) |
| Local data | Owner labels per slot in the existing preferences local data source (Hive), keyed by `petId + slot` |
| Presentation | Device tab: **"Điều khiển máy (Remote)"** card. It lists HID hosts with labels, shows connection state, offers Play/Pause, Previous, Next, Vol −, Vol +, Mute buttons (sending with `source = 1`), a rename sheet, "Quên máy này", and "Ghép máy mới" (opens the window and shows instructions per OS). Use `AppDialog` / `AppSnackBar` and XUNA tokens |
| Pairing UX | When `DevicePairingRequiredException` is raised, show a guided sheet: hold both buttons 3 s → confirm the digits on XUNA → done. Retry automatically once bonded |
| Locales | vi + en strings via the existing locale files (`locales_sync_test` must pass) |

## 6. Files

**Firmware:**

- Edit:
  - `include/BleManager.h` (permissions, targeted notify, `0015`, capability bits);
  - `include/HidManager.h` (slots, window, rate limit);
  - `lib/xuna_core/include/xuna/BleProtocol.h` (parse 12/13 behind a new `hid` flag);
  - `V1LifeCoreAdapter.h` (handlers);
  - `src/main.cpp` (window from the QR card, forget-all confirm).
- New in core:
  - `lib/xuna_core/include/xuna/hid/HidHostsCodec.h` (pure; encode the 16 bytes);
  - `HidRateLimiter.h`;
  - `PairingWindow.h`.
- Tests:
  - `test/test_hid_hosts_codec`;
  - `test_hid_rate_limiter`;
  - `test_pairing_window`;
  - additions to `test_v1_adapter` (opcodes 12/13 parse, results, never a life event).

**Mobile:** files per §5.3 under `lib/features/device/...` and `lib/features/home/presentation/...`. Tests under `test/features/device/...` mirroring them (codec, repository with fakes, widget test for the Remote card).

## 7. Sessions

| Session | Content | Acceptance |
|---|---|---|
| S2.1 | Firmware core: codecs, rate limiter, pairing window, parse/handle 12/13, tests | Native tests PASS; S08a byte-compat replay still PASS for opcodes 1–11 |
| S2.2 | Firmware board: permissions, window, slots NVS, targeted notify, HID default-on, `0015` | Builds PASS; an unbonded phone cannot write `0003` (ATT error) and gets no board prompt when the window is closed; a bonded app works |
| S2.3 | Mobile: codec, data source, simulator, domain, use cases, Remote card, pairing guide, locales, tests | `flutter analyze` 0, tests PASS; simulator UI works |
| S2.4 | Board + phones acceptance (Android + iPhone apps; Mac/PC as HID hosts) | See §8 |

## 8. Acceptance

- **Security:**
  - Negative test with a second, unbonded phone: 0 accepted writes; 0 prompts outside the window.
  - Pairing prompts appear only inside the window.
- **Migration:** an existing app install pairs after the guided flow and keeps all features (status, chat gestures, hatch, knowledge, display settings).
- **Media keys:** media keys from the app reach the connected host 20/20 per key on Mac and Windows; the rate limit returns `kBusy` at the 5th press within 1 s.
- **Host management:** forget slot / forget all (with board confirmation) work; a fifth bond is refused.
- **Board behaviour:** no learning or life change from opcode 12 (serial and test evidence); loop and heap thresholds as in UDC-1.

## 9. Risks

| Risk | Mitigation |
|---|---|
| iOS asks to pair at unexpected times | Encrypt only after the capability read; the guided flow explains it |
| Android OEM bonding quirks | Retry `createBond` once; document the device model in results |
| Owners lock themselves out (lost phone) | Both-hold QR opens the window; "forget all" from the board menu after confirmation |
| Older app versions | They still work after OS-level pairing; byte formats unchanged |

## 10. References

- HOGP §7.1; ESP-IDF `esp_hid_gap.c` (security parameters).
- HijelHID per-peer bond deletion.
- `flutter_blue_plus` bonding docs.
- Existing device-proof work ([Identity V2](../cloud/identity-v2-2026-10-17.md)) for patterns of strict codecs.

## 11. Handoff

Results file; PROCESS/CHANGELOG; update security doc §5 "App ↔ Board" from "to be authenticated" to the implemented state.

## 12. Brief for a coding agent

> Work in `firmware` and `mobile` submodules.
>
> Read `docs/roadmap/device-control/README.md`, `UDC-1-results-*.md` and this file.
>
> Implement in order S2.1 → S2.3:
> - encrypted custom-service attributes (except `0002`);
> - the pairing window;
> - opcodes 12/13 exactly as in §5.2;
> - characteristic `7a6e0015`;
> - targeted notifications;
> - mobile layers per §5.3, following mobile/AGENTS.md Clean Architecture.
>
> Never let opcode 12 create a life/learning event; add a test proving it. Keep opcodes 1–11 byte-compatible (S08a replay). No new dependencies.
>
> Report in Vietnamese with commands, results and what was not run on hardware.

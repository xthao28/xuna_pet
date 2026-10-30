# UDC-1 — "XUNA bấm Play": BLE HID media keys on the board

Status: **Approved to start (owner 2026-10-30, UDC-D1).** Not started. Complexity: M (3 sessions). Needs the board, a Mac, a Windows 11 PC, an Android phone and an iPhone in S1.3.

## 1. Goal

The board becomes a Bluetooth LE **consumer-control (media keys) HID device**. The owner pairs it with any host, enters the "Remote" scene and uses the two buttons as Play/Pause, Next and Previous. Meanwhile the XUNA app stays connected through the existing custom service.

Results answer four questions:

- Do two links (app + HID host) work on Bluedroid?
- Does bonding coexist with the unauthenticated custom service?
- Do RAM and loop timing hold, including with Wi-Fi?
- How does each OS behave?

## 2. Gate

- S1.1 may start immediately.
- S1.2 after S1.1 PASS.
- S1.3 needs the owner, the board and the four hosts. It can share a board session with E14.

Decisions that apply:

- UDC-D2: LE Secure Connections with numeric comparison, passkey as fallback, never Just Works.
- UDC-D3: a "Remote" scene.
- UDC-D8: stay on Bluedroid.
- R6: media keys only; no keyboard report.

## 3. Read first

- [README](README.md): rules, ID register, references for UDC-1.
- `firmware/include/BleManager.h`: the whole file. Note in particular:
  - `ServerCallbacks::onConnect` **disconnects any second connection** (`if(owner_.connected_){server->disconnect(...)}`);
  - the `session_` / `connected_` / `central_` semantics;
  - the advertising logic in `update()`;
  - the capability array `b[8]`.
- `firmware/src/main.cpp`: the button block (`input.update(now)` → screen wake → card close → `if(lifeReady&&!consumed)`), especially `events.idleHold` scene cycling (`xuna::nextSceneMode`, `scenePreference.save`) and the Egg hatch hold.
- `firmware/include/InputManager.h` (`InputEvents`: `happy`, `idle`, `happyHold`, `idleHold`, `bothHold`).
- `lib/xuna_core/include/xuna/visual/SceneEffects.h` (`SceneMode` Auto/Day/Evening/Night/Rain).
- `firmware/include/E14Diagnostics.h`: reuse its metric style.
- `firmware/platformio.ini`: the env pattern of `xuna_e14` / `xuna_net`.
- Arduino BLE library in `~/.platformio/packages/framework-arduinoespressif32/libraries/BLE/src/`:
  - `BLEHIDDevice.h/.cpp`;
  - `BLESecurity.h`;
  - `BLEDevice.cpp` lines ~190–280: the GAP handler. With `BLESecurityCallbacks` set, `onConfirmPIN` is called **synchronously in the BT task**, so do **not** use it for a button confirmation.
  - `BLECharacteristic.cpp` ~489–530: `notify()` sends to **every** connected peer, and the CCCD state is global.
  - `BLEServer.h`: `getGattsIf()` is private, so capture `gatts_if` from a custom GATTS handler.
- ESP-IDF `examples/bluetooth/esp_hid_device/main/esp_hid_device_main.c` (`mediaReportMap`) and `esp_hid_gap.c` (CC0). Use them to cross-check the descriptor below.
- `pilot/esp32-pilot.ino` around L347–369: read only, no license. Create the custom service **before** `startServices()` of the HID device.
- HijelHID `README.md` (Windows caches the report map; iOS bond quirks).
- Facts already verified in the bundled sdkconfig (`tools/sdk/esp32s3/qio_opi/include/sdkconfig.h`): `CONFIG_BT_ACL_CONNECTIONS 4`, `CONFIG_BT_CTRL_BLE_MAX_ACT 6`, `CONFIG_BT_SMP_ENABLE 1`, `CONFIG_BT_GATTC_ENABLE 1`.

## 4. Scope

**In scope:**

- Pure C++ state machines with native tests.
- A HID consumer service on the board.
- Secure pairing with on-screen numeric comparison.
- Two concurrent links.
- The Remote scene.
- Serial diagnostics.
- Two experimental envs (`xuna_hid`, `xuna_hid_net`).
- A results document.

**Out of scope:**

- App changes.
- Keyboard or mouse reports.
- Opcodes 12/13 and characteristic `0015` (UDC-2).
- Encrypting the custom service (UDC-2).
- NimBLE.
- AMS.
- Changing the default build.

## 5. Design

### 5.1 Pure core (`lib/xuna_core`, C++11, no Arduino or ESP headers)

New folder `lib/xuna_core/include/xuna/hid/`.

**`ConsumerReport.h`**

```cpp
namespace xuna { namespace hid {
enum class ConsumerKey : uint8_t { None=0, PlayPause=1, Next=2, Previous=3, VolumeUp=4, VolumeDown=5, Mute=6, Stop=7 };
constexpr uint8_t kConsumerReportId = 3;
// Report map: one 8-bit input report, bits 0..6 = keys 1..7, bit 7 padding.
// Cross-checked against ESP-IDF esp_hid_device mediaReportMap (CC0).
constexpr uint8_t kConsumerReportMap[] = {
  0x05,0x0C,       // Usage Page (Consumer)
  0x09,0x01,       // Usage (Consumer Control)
  0xA1,0x01,       // Collection (Application)
  0x85,0x03,       //   Report ID (3)
  0x15,0x00,       //   Logical Minimum (0)
  0x25,0x01,       //   Logical Maximum (1)
  0x75,0x01,       //   Report Size (1)
  0x95,0x07,       //   Report Count (7)
  0x09,0xCD,       //   Usage (Play/Pause)
  0x09,0xB5,       //   Usage (Scan Next Track)
  0x09,0xB6,       //   Usage (Scan Previous Track)
  0x09,0xE9,       //   Usage (Volume Increment)
  0x09,0xEA,       //   Usage (Volume Decrement)
  0x09,0xE2,       //   Usage (Mute)
  0x09,0xB7,       //   Usage (Stop)
  0x81,0x02,       //   Input (Data,Var,Abs)
  0x95,0x01,       //   Report Count (1)
  0x81,0x01,       //   Input (Const) padding
  0xC0             // End Collection
};
inline uint8_t pressReport(ConsumerKey k);   // 1u << (k-1); 0 for None or out of range
constexpr uint8_t kReleaseReport = 0;
bool keyFromIndex(uint8_t index, ConsumerKey& out); // 1..7 valid
}}
```

Each key press sends the press report, then the release report **≥ 30 ms later** (the board loop schedules the release; never `delay()`).

**`HidLinkRoles.h`**: a connection role table that decides accept/refuse, the app session and advertising.

- Up to `kMaxLinks = 2` links.
- Each link has:
  - `connId` (u16);
  - `appAccess` (bool): it read or wrote a characteristic in the custom service;
  - `hidHost` (bool): encryption completed with a bonded peer;
  - `connectedAt` (ms).
- Events in, with actions out (a small struct returned by each call):

| Event | Rule | Output |
|---|---|---|
| `onConnect(id, now)` | Two links already → `refuse`. Otherwise add a link with no role | `advertise = links < 2` |
| `onAppAccess(id)` | No app link yet → this link becomes the app link, `sessionBump = true`. Another link is already the app → `disconnect(id)` (one app at a time, as today) | `appConnected = true` |
| `onEncrypted(id, bonded)` | `bonded` and no HID host yet → `hidHost = id`. A HID host already exists on another link → `disconnect(id)` (one HID host at a time; switching is UDC-2) | `hidConnected = true` |
| `onDisconnect(id)` | App link → `sessionBump`, `appConnected = false`. HID link → `hidConnected = false`. Always remove | `advertise = true` |
| `tick(now)` | A link with no role after 30 s → `disconnect(id)` (squatter protection; a host in the middle of pairing has encrypted by then) | — |

- A single link may be **both** app and HID host. This is the iPhone case: the XUNA app and the iOS HID connection share one link.
- `sessionBump` must happen **before** the first custom-service write of that link is queued. See §5.2, "ordering".

**`RemoteMode.h`**: the Remote scene state machine.

- Inputs:
  - `InputEvents` (copy of the struct: plain bools);
  - `hidConnected`;
  - `now`;
  - `inEgg`.
- Outputs:
  - `key` (`ConsumerKey`);
  - `enter`, `exit`;
  - `advanceScene` (bool);
  - `stop` (bool);
  - `consumed` (bool): the event must not reach life/learning.

| State | Event | Result |
|---|---|---|
| Off | `idleHold` and `hidConnected` and not `inEgg` | → On, `enter`, `consumed`. **No scene change and nothing saved** |
| Off | `idleHold` and not `hidConnected` | Not consumed: the existing scene cycle runs unchanged |
| On | `happy` (GPIO0 short) | `key = PlayPause`, `consumed` |
| On | `idle` (GPIO14 short) | `key = Next`, `consumed` |
| On | `happyHold` (GPIO0 hold) | `key = Previous`, `consumed` (no status card) |
| On | `idleHold` | → Off, `exit`, **`advanceScene = true`** (the caller runs the existing `nextSceneMode` + save), `consumed` |
| On | `bothHold` | → Off, `exit`, `stop = true`, `consumed` (no pairing QR while in Remote) |
| On | `hidConnected` becomes false | → Off, `exit` |
| On | No button for 60 s | → Off, `exit` (no scene change) |

So with a HID host connected, successive GPIO14 holds alternate Remote ↔ next scene. Without one, behaviour is unchanged.

**Remote presses never call `adapter.localGreeting` / `adapter.localIdle`**, so they never teach (D6 revised is unaffected). They still count as owner activity: `localBehavior.activity(now)` and `pacer.touch(now)`.

**`PairingConfirm.h`**: the numeric-comparison prompt.

| State | Event | Result |
|---|---|---|
| Idle | `request(passkey, token, now)` | → Pending; `show = passkey` |
| Pending | `happy` (GPIO0 short) | → Idle; `reply = accept(token)` |
| Pending | `idle` (GPIO14 short) | → Idle; `reply = reject(token)` |
| Pending | 30 s elapsed | → Idle; `reply = reject(token)` |
| Pending | A new `request` | Reject the old token first, then show the new one |
| Pending | Any hold | Ignored but consumed |

While Pending, every button event is consumed. Only one prompt exists at a time. `token` is an opaque u8 index into a board-side table of peer addresses; the core never sees addresses.

### 5.2 Board glue (`firmware/include/HidManager.h`, compiled only with `XUNA_HID`)

1. **Order in `BleManager::begin()`:**
   - Create and start the custom service exactly as today.
   - Then create `BLEHIDDevice hid(server)`.
   - Then call:
     - `hid.manufacturer("XUNA")`;
     - `hid.pnp(0x01, 0x02E5, 0x0001, 0x0100)` — vendor-ID source 0x01 (Bluetooth SIG). **0x02E5 is believed to be Espressif's company identifier: UNVERIFIED, check the Bluetooth SIG assigned numbers.** Never use Apple's 0x05AC.
     - `hid.hidInfo(0x00, 0x02)` (country 0; flags: NormallyConnectable);
     - `hid.reportMap(kConsumerReportMap, sizeof)`;
     - `input = hid.inputReport(kConsumerReportId)`;
     - `hid.startServices()`.
   - Add `0x1812` to the advertising service UUIDs and set appearance `0x03C0` (Generic HID). If macOS or iOS refuses consumer-only devices, retry with `0x03C1` (Keyboard) and record it.
   - The advertising payload must fit in 31 bytes (flags 3 + 128-bit UUID 18 + 16-bit UUID 4 + appearance 4 = 29). The name stays in the scan response.
2. **Encryption on all HID attributes** (HOGP §7.1): call `setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED)` on:
   - the HID characteristics (report map, HID information, control point, protocol mode, input report);
   - the input report's descriptors (0x2902 CCCD, 0x2908 report reference).

   The custom service keeps its current permissions (UDC-2 changes them).
3. **Security:** `BLESecurity` with:
   - `setAuthenticationMode(ESP_LE_AUTH_REQ_SC_MITM_BOND)`;
   - `setCapability(ESP_IO_CAP_IO)` (DisplayYesNo → numeric comparison);
   - `setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK)`, the same for `setRespEncryptionKey`;
   - `setKeySize(16)`;
   - `esp_ble_gap_set_security_param(ESP_BLE_SM_ONLY_ACCEPT_SPECIFIED_SEC_AUTH, &enable, 1)` to refuse legacy pairing.

   **Do not** call `BLEDevice::setSecurityCallbacks`. Leaving it null makes the library skip its synchronous `onConfirmPIN` path.
4. **Custom GAP handler** (`BLEDevice::setCustomGapHandler`). It runs in the BT task: copy the data into a FreeRTOS queue and return.
   - `ESP_GAP_BLE_NC_REQ_EVT` → `{bda, passkey}`. The loop feeds `PairingConfirm` and, on its reply, calls `esp_ble_confirm_reply(bda, accept)` from the loop task.
   - `ESP_GAP_BLE_PASSKEY_NOTIF_EVT` (fallback when the host cannot confirm) → show the passkey; no reply needed.
   - `ESP_GAP_BLE_AUTH_CMPL_EVT` → `{bda, success, fail_reason}`. The loop maps `bda` to `connId` (table filled on `ESP_GATTS_CONNECT_EVT`) and calls `roles.onEncrypted(connId, success)`.
5. **Custom GATTS handler** (`BLEDevice::setCustomGattsHandler`). It runs in the BT task, so queue the data.
   - Capture `gatts_if`.
   - On `ESP_GATTS_CONNECT_EVT`, record `conn_id → remote_bda`.
   - On `ESP_GATTS_READ_EVT` / `ESP_GATTS_WRITE_EVT` whose `handle` lies in the custom service's handle range (`service->getHandle()` … + handle count), call `roles.onAppAccess(conn_id)`.
   - **Ordering:** check in `BLEDevice.cpp` (`gattServerEventHandler`) whether the custom handler runs before or after `BLEServer::handleGATTServerEvent` (which calls the characteristic `onWrite`).
     - If **after**, assign the app role inside `WriteCallbacks::onWrite` / `ProofCallbacks` / `SpeechCallbacks` / `NetCallbacks` instead, before `p.session` is read, using the `onWrite(BLECharacteristic*, esp_ble_gatts_cb_param_t*)` overload if present.
     - Record which path was used in the results file.
6. **Replace the single-link rule** (inside `#if XUNA_HID` only):
   - `ServerCallbacks::onConnect/onDisconnect` forward to `HidLinkRoles`.
   - `connected_` becomes `roles.appConnected()`.
   - `central_` becomes the app link id.
   - `session_` is bumped only by `sessionBump`.
   - The default build keeps today's code byte-for-byte.
7. **Advertising:** Bluedroid stops advertising on every connection. After any connect or disconnect, call `BLEDevice::startAdvertising()` while `links < 2`. The existing `update()` rule (`if(connected_) advertising_=false`) must use `roles.shouldAdvertise()` in `XUNA_HID` builds.
8. **Targeted reports:**
   - Never call `input->notify()`.
   - Call `esp_ble_gatts_send_indicate(gattsIf, hidConnId, input->getHandle(), 1, &report, false)`, then the release report after ≥ 30 ms (a scheduled timestamp checked in the loop).
   - Known leak, accepted for UDC-1: the existing `status_->notify()` reaches the HID host too (status bytes only). UDC-2 makes it targeted.
9. **Bonds:** Bluedroid stores them in NVS automatically.
   - Serial `hid forget` calls `esp_ble_remove_bond_device` **per device** from `esp_ble_get_bond_device_list` (HijelHID lesson: avoid deleting everything at once on iOS).
   - On iOS/macOS the owner must also "Forget this device" on the host.
10. **Display:**
    - **Pending pairing:** speech bubble `"Ghép đôi: 123 456\nGPIO0 đồng ý · GPIO14 từ chối"`.
    - **Remote on:** bubble `"Remote ▶︎ máy 1"` (slot index; names arrive in UDC-2).
    - **Key sent:** a short `Sparkle` effect, expression only.
    - **Stop:** bubble `"Đã dừng"`.
    - All text is Vietnamese, ASCII-safe for the existing font. Check that `▶︎` renders; otherwise use `>`.
11. **Capability:** in `XUNA_HID` builds, capability byte 5 `|= 0x08`. The app ignores the bit in UDC-1.
12. **Serial diagnostics** (`XUNA_HID` only), in the style of `E14Diagnostics.h`:
    - every 10 s, one line: `hid links=%u app=%u host=%u bonds=%u heap_int_min=%u heap_int_largest=%u psram_free=%u loop_p50=%u loop_p99=%u loop_max=%u render_max=%u ble_cmd_fail=%u resets=%u`;
    - commands `hid status`, `hid forget`, `hid send <1..7>` (for Volume ±/Mute/Stop tests), `hid stop`.

### 5.3 Envs (`firmware/platformio.ini`)

```ini
[env:xuna_hid]
extends = env:xuna_t_display_s3
build_flags = ${env:xuna_t_display_s3.build_flags} -DXUNA_HID=1

[env:xuna_hid_net]
extends = env:xuna_net
build_flags = ${env:xuna_net.build_flags} -DXUNA_HID=1
```

`xuna_hid_net` keeps `xuna_net`'s `build_unflags` (`ARDUINO_EVENT_RUNNING_CORE`). Check that the inherited flags resolve with `pio run -e xuna_hid_net -t envdump` or an equivalent before measuring.

## 6. Files

| Action | Path |
|---|---|
| New | `firmware/lib/xuna_core/include/xuna/hid/ConsumerReport.h`, `HidLinkRoles.h`, `RemoteMode.h`, `PairingConfirm.h` |
| New | `firmware/test/test_hid_consumer/test_main.cpp`, `test_hid_link_roles/test_main.cpp`, `test_remote_mode/test_main.cpp`, `test_pairing_confirm/test_main.cpp` |
| New | `firmware/include/HidManager.h` (board glue, `#if XUNA_HID`) |
| Edit | `firmware/include/BleManager.h` (`#if XUNA_HID` branches only), `firmware/src/main.cpp` (`#if XUNA_HID` branches only), `firmware/platformio.ini` (two envs) |
| New | `docs/roadmap/device-control/UDC-1-runbook.md` (S1.3 checklist, copied from §8), `UDC-1-results-<date>.md` |

## 7. Sessions and tasks

### S1.1 — Pure core and tests (host only)

1. Implement the four headers in §5.1.
2. Tests (Unity, `pio test -e native` and `native_asan`):
   - `test_hid_consumer`:
     - each key → expected bit;
     - `None` / out of range → 0;
     - the report map's length and its first/last bytes;
     - `keyFromIndex` for 0 and 8 → false.
   - `test_hid_link_roles`:
     - a third connect is refused;
     - the first app access bumps the session, and a second app is disconnected;
     - an encrypted bonded link becomes the HID host, and a second host is disconnected;
     - one link can be both app and host (the iPhone case);
     - disconnect of the app bumps the session; disconnect of the host does not;
     - a squatter is disconnected at 30 s and a link with a role is not;
     - advertise flags after each event.
   - `test_remote_mode`: every row of the table, plus:
     - `inEgg` blocks entry;
     - the 60 s timeout;
     - HID loss exits;
     - `consumed` is false for `idleHold` when no host is connected.
   - `test_pairing_confirm`: accept, reject, timeout, a replacement request rejects the old one, holds are consumed.
3. `pio run -e xuna_t_display_s3` must still pass (purity check).

**Acceptance:** all new and existing native tests PASS; the default build is unchanged (same flash size ± 0 B, because the headers are unused there).

### S1.2 — Board glue (no board needed to build; a board for smoke)

1. Write `HidManager.h` and the `#if XUNA_HID` edits per §5.2–§5.3.
2. Build `xuna_t_display_s3`, `xuna_hid`, `xuna_hid_net`, `xuna_net`. Record RAM and Flash for each.
3. Smoke on one host (the Windows dev PC):
   - pair with numeric comparison;
   - Remote mode;
   - Play/Pause works;
   - the app connects at the same time and plays an animation.

**Acceptance:** builds PASS; the smoke works; the default build's size is unchanged.

### S1.3 — Board acceptance on four hosts (+ the combined E14 run if the owner wants)

The runbook is §8. Write the results to `UDC-1-results-<date>.md` using the table in §9.

## 8. Runbook (S1.3)

Do this for each host (macOS, Windows 11, Android, iPhone; record OS versions):

1. Flash `xuna_hid` and erase bonds (`hid forget`).
2. Open the XUNA app on the phone (Android for the desktop rows; the iPhone itself for the iPhone row), connect it, and leave it connected.
3. On the host, open Bluetooth settings → "XUNA" → pair. Check that the host shows the same 6 digits as the board, then press GPIO0. Record whether it was numeric comparison or passkey, and any host dialogs (e.g. macOS Keyboard Setup Assistant).
4. Start music (Spotify or YouTube in a browser, and the OS player).
5. Hold GPIO14 → Remote. Press GPIO0 ×20 (Play/Pause), GPIO14 ×20 (Next), hold GPIO0 ×20 (Previous). Count successes.
6. Run serial `hid send 4` ×20 and `hid send 5` ×20 (Volume ±). Count successes.
7. While the test runs, send an app command (e.g. "Vui") every 30 s. Count failures.
8. Reboot the board → the host reconnects without re-pairing within 10 s (record the time).
9. Hold GPIO14 in Remote → exits and the scene advances. Then short-press GPIO0 → XUNA's normal pet reaction (checks that learning is unaffected).
10. Negative checks:
    - a second unbonded phone connects and does nothing for 30 s → it is disconnected;
    - reject a pairing with GPIO14 → the host reports failure;
    - let a pairing prompt time out after 30 s → rejected.
11. 30-minute soak with `xuna_hid` and with `xuna_hid_net` (Wi-Fi on): record the serial metrics.

## 9. Acceptance (UDC-1 overall)

| Check | Threshold |
|---|---|
| Media keys per host | 20/20 for each of Play/Pause, Next, Previous, Volume ±, on all four hosts (or a documented host limitation, e.g. iOS consumer keys) |
| Pairing | Numeric comparison or passkey works on every host; never Just Works |
| Reconnect after reboot | ≤ 10 s, no re-pairing |
| App coexistence | 0 failed app commands while the HID host is connected |
| Learning isolation | No reaction/learning event from Remote presses (serial log shows no `pet (reaction)` lines during Remote) |
| Loop gap p99 | ≤ 50 ms (plan §17.1) |
| Render max | ≤ baseline + 20 % |
| Internal heap minimum | ≥ 40 KB with `xuna_hid_net` (E14 threshold) |
| Resets | 0 in each 30-minute soak |
| Default build | Unchanged size and behaviour |

## 10. Risks and what to do

| Risk | Signal | Action |
|---|---|---|
| Bluedroid refuses the second link | A connect is refused at the controller | Check `CONFIG_BT_ACL_CONNECTIONS` (4) and the advertising restart. If it is a hard limit, record it and propose UDC-D8 (NimBLE) |
| iOS ignores the HID service | The iPhone pairs but the keys do nothing | Check the service order (pilot lesson) and the appearance (0x03C1). Accept "iOS limitation" only after both tried |
| The iPhone app breaks because the link is now encrypted | The app loses its session at pairing | Single-link app+host case; verify the `HidLinkRoles` "both roles" path |
| Windows caches the old report map | Keys do nothing after a descriptor change | Remove the device in Windows and re-pair (HijelHID note) |
| RAM below threshold with Wi-Fi | `heap_int_min` < 40 KB | Record it; this feeds UDC-D8 and the E14 mitigation decision |
| A blocking call in a BT callback | BLE stalls during pairing | Every GAP/GATTS handler only queues; the replies come from the loop |

## 11. References used here

ESP-IDF `esp_hid_device` (CC0: descriptor/security), the Arduino BLE library (bundled), pilot (read-only ordering lesson), HijelHID (bond/descriptor notes), HOGP 1.1 §7.1 and §3.1.7. See the [README reference index](README.md#3-reference-index-third-party).

## 12. Handoff

- Results file.
- PROCESS.md.
- CHANGELOG ("XUNA bấm Play được trên … máy").
- Update the [capability matrix](../../research/XUNA_PLATFORM_CAPABILITY_MATRIX.md) §5 rows from † to measured.
- Bring UDC-D8 (stack) and UDC-2 go-ahead to the owner with the data.

## 13. Brief for a coding agent

> Firmware work in the `firmware` submodule (PlatformIO, Arduino core 2.0.14, Bluedroid, C++11 core).
>
> Read `docs/roadmap/device-control/README.md` and `UDC-1-hid-poc.md` fully, then every file in §3.
>
> **S1.1:** implement `ConsumerReport.h`, `HidLinkRoles.h`, `RemoteMode.h` and `PairingConfirm.h` in `lib/xuna_core/include/xuna/hid/` as pure C++11 (no Arduino or ESP headers; the purity check enforces this), with the Unity tests listed in §7. Run `pio test -d firmware -e native` and `pio run -d firmware -e xuna_t_display_s3`.
>
> **S1.2:** add `HidManager.h` and `#if XUNA_HID` branches in `BleManager.h` and `main.cpp`, plus the `xuna_hid` and `xuna_hid_net` envs. Follow §5.2 exactly:
> - never use `BLESecurityCallbacks::onConfirmPIN`;
> - never `notify()` HID reports;
> - only queue work inside BT callbacks;
> - keep the default build byte-identical.
>
> Do not touch the mobile app, do not add libraries, and do not add keyboard or mouse reports.
>
> Report in Vietnamese: files, commands, results, sizes, what was not run.

# UDC-1 Runbook — BLE HID Consumer Control PoC (S1.3)

**Date:** 2026-10-30
**Milestone:** UDC-1 (Session S1.3 — Board acceptance on four hosts)
**Spec:** [`docs/roadmap/device-control/UDC-1-hid-poc.md`](./UDC-1-hid-poc.md) §8–§9
**Firmware targets:** `xuna_hid` (`-DXUNA_HID=1`) and `xuna_hid_net` (`-DXUNA_NET=1 -DXUNA_HID=1`)

---

## 1. Pre-flight

1. Verify `xuna_t_display_s3`, `xuna_hid`, `xuna_hid_net`, and `xuna_net` build cleanly:
   ```powershell
   & "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" test -d firmware -e native
   & "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run -d firmware -e xuna_t_display_s3 -e xuna_hid -e xuna_hid_net -e xuna_net
   ```
2. Back up NVS from the LILYGO T-Display-S3 board before flashing if preserving an active pet snapshot.
3. Flash `xuna_hid`:
   ```powershell
   & "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run -d firmware -e xuna_hid -t upload
   ```
4. Open serial monitor at `115200` baud.

---

## 2. Per-host checklist (macOS, Windows 11, Android, iPhone)

Do this for each host (macOS, Windows 11, Android, iPhone; record exact OS versions):

1. Flash `xuna_hid` and erase bonds (`hid forget` over serial). On macOS/iOS, also click **"Forget This Device"** in the host's Bluetooth settings if previously paired.
2. Open the XUNA app on the phone (Android for the desktop rows; the iPhone itself for the iPhone row), connect it, and leave it connected.
3. On the host, open Bluetooth settings → **"XUNA"** → pair.
   - Check that the host shows the same 6 digits as the board (`"Ghép đôi: 123 456 · GPIO0 đồng ý · GPIO14 từ chối"`), then press **GPIO0** (happy button).
   - Record whether it was Numeric Comparison (`hid nc_req`) or Passkey Notification (`hid passkey_notif`), and any host dialogs (e.g. macOS Keyboard Setup Assistant).
4. Start music (Spotify or YouTube in a browser, and the OS media player).
5. Hold **GPIO14** (3 s) → enters Remote mode (`"Remote > máy 1"`).
   - Short-press **GPIO0** ×20 (`Play/Pause`).
   - Short-press **GPIO14** ×20 (`Next`).
   - Hold **GPIO0** ×20 (`Previous`).
   - Count successes out of 20 for each key.
6. Run serial `hid send 4` ×20 (`Volume +`) and `hid send 5` ×20 (`Volume -`). Count successes out of 20. (Optionally also check `hid send 6` for `Mute` and `hid send 7` / `hid stop` for `Stop`.)
7. While the test runs, send an app command (e.g. "Vui") every 30 s. Count failures (`ble_cmd_fail`).
8. Reboot the board → verify the host reconnects without re-pairing within ≤ 10 s (record the time in seconds).
9. Hold **GPIO14** in Remote mode → exits Remote mode and advances the window scene (`hid remote=off advance_scene=1`). Then short-press **GPIO0** → verify XUNA's normal pet reaction (`button GPIO0: greeting` or `button GPIO0: pet (reaction)`) and that no `pet (reaction)` lines appeared during step 5.
10. Negative checks:
    - **Squatter timeout:** a second unbonded phone connects (e.g. nRF Connect) and does nothing for 30 s → verify `hid squatter_timeout` disconnects it at 30 s;
    - **Reject pairing:** initiate pairing from an unbonded host and short-press **GPIO14** → verify `hid pairing_reply=reject` and the host reports pairing failure;
    - **Timeout pairing:** initiate pairing from an unbonded host and wait 30 s without pressing any button → verify `hid pairing_reply=reject` after 30 s.
11. **30-minute soak:**
    - Run 30 minutes with `xuna_hid` (app + HID host connected).
    - Run 30 minutes with `xuna_hid_net` (Wi-Fi on, app + HID host connected).
    - Record the 10-second `hid links=...` serial metrics.

---

## 3. Serial commands reference (`XUNA_HID=1`)

| Command | Action |
|---|---|
| `hid status` | Print immediate `hid links=%u app=%u host=%u bonds=%u ...` line |
| `hid forget` | Remove all bonded devices one by one via `esp_ble_remove_bond_device` |
| `hid send 1` | Send `Play/Pause` (`0x01`) + 30 ms release |
| `hid send 2` | Send `Next Track` (`0x02`) + 30 ms release |
| `hid send 3` | Send `Previous Track` (`0x04`) + 30 ms release |
| `hid send 4` | Send `Volume +` (`0x08`) + 30 ms release |
| `hid send 5` | Send `Volume -` (`0x10`) + 30 ms release |
| `hid send 6` | Send `Mute` (`0x20`) + 30 ms release |
| `hid send 7` | Send `Stop` (`0x40`) + 30 ms release |
| `hid stop` | Send `Stop` (`0x40`) + show `"Đã dừng"` bubble |

---

## 4. Acceptance table template (copy to `UDC-1-results-<date>.md`)

| Check | Threshold | macOS | Windows 11 | Android | iPhone | Status |
|---|---|---|---|---|---|---|
| OS version | Record exact version | | | | | |
| Pairing method | Numeric comparison or passkey; never Just Works | | | | | |
| Play/Pause (GPIO0 ×20) | 20/20 | | | | | |
| Next (GPIO14 ×20) | 20/20 | | | | | |
| Previous (GPIO0 hold ×20) | 20/20 | | | | | |
| Volume + (`hid send 4` ×20) | 20/20 (or documented host limit) | | | | | |
| Volume - (`hid send 5` ×20) | 20/20 (or documented host limit) | | | | | |
| Reconnect after reboot | ≤ 10 s, no re-pairing | | | | | |
| App coexistence | 0 failed app commands while HID host connected | | | | | |
| Learning isolation | 0 `pet (reaction)` lines during Remote presses | | | | | |
| Squatter timeout (30 s) | Disconnected at 30 s | | | | | |
| Pairing reject (GPIO14) | Host reports failure | | | | | |
| Pairing timeout (30 s) | Rejected at 30 s | | | | | |
| Loop gap p99 | ≤ 50 ms (`50000 us`) | | | | | |
| Render max | ≤ baseline + 20 % | | | | | |
| Internal heap min (`xuna_hid_net`) | ≥ 40 KB (`40960 B`) | | | | | |
| Resets (30-min soak `xuna_hid` & `xuna_hid_net`) | 0 | | | | | |
| Default build (`xuna_t_display_s3`) | Unchanged size (`±0 B`) and behaviour | | | | | |


# E14 runbook — Wi-Fi + TLS + BLE on the board (DC-1 gate)

Status: **tools implemented and host-checked 2026-10-27; not run on the board.** Plan: [device-direct plan](device-direct-plan-2026-10-27.md) §4 DC-1. Decision: [ADR-0010](../../decisions/ADR-0010-device-direct-websocket-transport.md).

## Thresholds (owner-confirmed 2026-10-27)

| # | Threshold |
| --- | --- |
| 1 | Minimum free **internal** heap ≥ 40 KB for the whole run (`heap_int_min`) |
| 2 | Loop gap p99 ≤ 50 ms (plan §17.1) |
| 3 | Render max ≤ baseline + 20 % |
| 4 | Zero BLE command failures (no app error or timeout, `ble_dropped=0`) |
| 5 | Zero resets in 60 min |
| 6 | Every reconnect succeeds within 2 min after the server returns |

**Fail → stop.** Stage 2 stays phone-gateway only, or the owner picks a mitigation session (see the end). DC-2 onward does not move to the board before a pass.

## What gets flashed

| Env | Firmware |
| --- | --- |
| `xuna_e14_baseline` | The normal firmware plus `e14` metric lines every 30 s (`-DXUNA_E14=0`). No Wi-Fi. |
| `xuna_e14` | Baseline plus a network task on **core 0** (`-DXUNA_E14=1`): Wi-Fi, TLS with the pinned dev CA, WebSocket to `wss://<host>:8765/e14`, a 1 KB synthetic frame every 5 s, checked when it is echoed back. Reconnects with backoff 2 s → 30 s. |
| `xuna_t_display_s3` | The normal firmware, unchanged (restore at the end). |

Both E14 envs move Arduino's Wi-Fi event task to core 0 (`ARDUINO_EVENT_RUNNING_CORE=0`; the build checks it). The network code never touches life state, BLE or the snapshot. It calls `WiFi.persistent(false)`, so the Wi-Fi password is not written to NVS. The only NVS data the radio may write is the RF calibration namespace that BLE already uses.

Logs contain no password, no key and no pet data: counters, sizes, times, RSSI, error codes.

## 0. Before flashing: back up (mandatory)

Board on USB, find the port (`pio device list`, e.g. `COM5`). Keep the backups outside every repository:

```powershell
$ESPTOOL = "$env:USERPROFILE\.platformio\packages\tool-esptoolpy\esptool.py"
$PY = "$env:USERPROFILE\.platformio\penv\Scripts\python.exe"
$B = "$env:USERPROFILE\xuna_backups\$(Get-Date -Format yyyy-MM-dd)-e14"; New-Item -ItemType Directory -Force $B
& $PY $ESPTOOL --chip esp32s3 --port COM5 read_flash 0x8000 0xC00 "$B\ptable-before.bin"
& $PY $ESPTOOL --chip esp32s3 --port COM5 read_flash 0x9000 0x5000 "$B\nvs-before.bin"
& $PY $ESPTOOL --chip esp32s3 --port COM5 read_flash 0x10000 0x640000 "$B\app-before.bin"
Get-FileHash "$B\*.bin" -Algorithm SHA256
```

Check that `nvs-before.bin` is 20,480 bytes and note the hashes, the `PetId=` and `recover=` lines from a normal boot, and the generation shown in the app. Reading resets the board but does not change it.

## 1. Certificates and server (dev machine)

Give the dev machine a fixed LAN address (DHCP reservation on the router), then in `backend/`:

```powershell
.venv\Scripts\python.exe scripts\make_dev_ca.py --ip 192.168.1.20 --firmware-header ..\firmware\include\E14DevCa.h
.venv\Scripts\python.exe scripts\e14_server.py --self-test          # must print ALL PASS
```

Private keys go to `%USERPROFILE%\.xuna\dev-ca` (outside git). `firmware/include/E14DevCa.h` holds only the public CA and is git-ignored. The CA is reused on later runs; if the IP changes, rerun with the new `--ip` (no reflash needed).

Windows firewall (PowerShell **as Administrator**; the Wi-Fi network profile must be *Private*):

```powershell
New-NetFirewallRule -DisplayName "XUNA E14 8765" -Direction Inbound -Protocol TCP -LocalPort 8765 -Action Allow -Profile Private
```

## 2. Baseline run (60 min, no Wi-Fi)

```powershell
cd firmware
pio run -e xuna_e14_baseline -t upload
pio device monitor -e xuna_e14_baseline -f time -f log2file
```

Connect the app over BLE and keep it connected. Send one command about every 30 s, e.g. an animation button on the Device tab, and note any error or timeout. After 60 min stop the monitor and rename the `platformio-device-monitor-*.log` file to `logs\e14-baseline.log`.

## 3. E14 run (60 min, Wi-Fi + TLS + server kills)

Copy `firmware/e14_local.ini.example` to `firmware/e14_local.ini` (git-ignored) and fill in the SSID, password and the dev machine IP. Then:

```powershell
# terminal 1 (backend): a server kill every 2 min, 10 s offline
.venv\Scripts\python.exe scripts\e14_server.py --port 8765 --drop-every 120 --down-for 10
# terminal 2 (firmware)
pio run -e xuna_e14 -t upload
pio device monitor -e xuna_e14 -f time -f log2file
```

Check right after boot: `e14_net event=start … ca=<16 hex>` matches the fingerprint printed by `make_dev_ca.py`, then `wifi_up`, then `ready connect_ms=…`. The server prints `open peer=<board IP>`. Use the app the same way as in the baseline for 60 min.

Then **power-cycle the router once**: note the time, wait until the board logs `e14_net event=ready` again, and note the time. Touch the board and note whether it feels warmer than in the baseline (there is no sensor; `chip_temp_c` in the `power` line is the chip's own reading). Rename the log to `logs\e14-run.log`.

## 4. Report

```powershell
& $PY tools\e14_report.py --baseline logs\e14-baseline.log --run logs\e14-run.log --down-for 10
```

It prints the threshold table (PASS/FAIL) and the other measurements. Put the output, the manual checks (app BLE errors, router power-cycle time, warmth) and the backup hashes into `docs/roadmap/cloud/E14-results-<date>.md`. Do not commit the logs; they contain the board IP and RSSI but no secrets.

If connecting fails, `connect_failed … errno=… tls=-0x…. flags=0x…` names the cause. Non-zero `flags` means certificate verification failed: wrong CA flashed, or the server certificate does not name the IP the board uses. `errno=104/113/118` means the server is unreachable (firewall, wrong IP, other subnet).

## 5. Restore

```powershell
pio run -e xuna_t_display_s3 -t upload
Remove-NetFirewallRule -DisplayName "XUNA E14 8765"
Remove-Item firmware\e14_local.ini      # holds the Wi-Fi password
```

Check the boot: `recover=Ok`, the same `PetId=`, the app shows the same generation or a newer one. If anything is wrong, write `nvs-before.bin` back (`write_flash 0x9000 nvs-before.bin`) only after reading the current NVS into a second file.

## If the gate fails

Stop and choose one (each is its own session):

- **Wi-Fi only while idle:** connect only while XUNA rests or sleeps, a few minutes per hour, then turn the radio off (heap is back after `WiFi.mode(WIFI_OFF)`).
- **Custom SDK build** (ESP-IDF or the Arduino lib-builder) with smaller or dynamic mbedTLS buffers (`MBEDTLS_DYNAMIC_BUFFER`, `SSL_IN/OUT_CONTENT_LEN`). The bundled Arduino libraries fix them at 16 KB each, so client configuration cannot shrink them.
- **Free internal RAM elsewhere:** move remaining internal buffers to PSRAM, drop BLE scan-response data.
- **Stage 2 stays phone-gateway only** (D22 order), and device-direct waits for new hardware.

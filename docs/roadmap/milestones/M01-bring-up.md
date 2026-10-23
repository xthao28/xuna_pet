# M01 — Hardware bring-up record

Date: 2026-10-10. Status: **Implemented; physical validation pending**. This task authorizes Arduino for initial bring-up, not a permanent Arduino-versus-ESP-IDF decision.

## Facts, assumptions and experiment

**Facts:** The three Git submodules were initialized and clean before work. Firmware contained only a placeholder README. Mobile/backend are unchanged. Official standard-board documentation specifies parallel ST7789, 170×320, GPIO0/14 buttons, GPIO15 power, GPIO38 backlight, 16 MB Flash and 8 MB OPI PSRAM.

**Assumption:** The owner's physical device matches the standard LCD documentation. Exact PCB revision is unverified. The generic PlatformIO MCU target is overridden to match the vendor memory configuration; LCD configuration comes solely from TFT_eSPI Setup206.

**Experiment:** Flash the minimal XUNA firmware, verify two-frame idle/happy reactions and capture resource/timing logs. No BLE, backend, sensors, voice or digital-life systems are added.

## Software verification

- Host C++ tests: PASS with `-std=c++11 -Wall -Wextra -Werror`; also PASS with AddressSanitizer/UndefinedBehaviorSanitizer.
- Firmware build: **PASS**, PlatformIO Core 6.2.0, espressif32 6.5.0, Arduino ESP32 2.0.14, TFT_eSPI 2.5.43.
- Actual build command in this session: `PLATFORMIO_CORE_DIR=/private/tmp/xuna-m01-pio-core /private/tmp/xuna-m01-pio/bin/pio run -d firmware`. PlatformIO and toolchains were installed into temporary directories; ordinary `pio` commands in README assume the VS Code PlatformIO terminal.
- Output: `firmware/.pio/build/xuna_t_display_s3/firmware.bin` and `.elf`.
- Linker sizes: static RAM **21,840 / 327,680 bytes**, firmware **319,709 / 6,553,600 bytes** (app partition). These exclude runtime allocations such as the 12,800-byte sprite; they are not measurements of device free heap or panel performance.
- First build exposed a missing global include path for Setup206 in framework-library compilation. Fixed in project build flags and rebuilt successfully.
- Upstream warnings: parallel DMA unavailable, touch not configured, and Arduino 2.0.14 UART non-void return warning. No project compilation errors remain.
- `pio project config`: parsed successfully; `pio device list`: no ESP32 USB serial device detected.
- Whitespace checks: PASS.
- No hardware upload or observation performed.

## Physical acceptance checklist

- [ ] Record PCB markings/revision and confirm standard LCD, not AMOLED or another variant.
- [x] Build and upload using firmware README commands; record environment versions and port. See 2026-10-11 physical run below.
- [x] Observe readable XUNA branding and original pet, correct colors/orientation, no offset/clipping. Owner confirmed 2026-10-11.
- [x] Observe two-frame idle animation without flicker or stale pixels. Owner confirmed basic animation/display checks 2026-10-11.
- [x] Press GPIO0/BOOT: happy expression/color and faster animation; returns idle after 2.4 seconds. Owner confirmed 2026-10-11.
- [x] Press GPIO14 while happy: immediate idle. Hold either button: no repeated events. Rapid presses should remain responsive; release/repress BOOT restarts happy.
- [x] Capture startup Flash size and PSRAM detection; 16,777,216 Flash / 8,388,608 PSRAM chip bytes confirmed 2026-10-11.
- [x] Capture 5-second diagnostics in idle and happy: heap/min heap, free PSRAM, FPS, render mean/max and loop gap. Record measured input response; investigate visible lag.
- [x] Run at least 10 minutes and check for resets, allocation errors or steadily declining heap. PASS 2026-10-11; see runtime summary below.
- [x] Reset/reconnect USB and verify startup without Serial Monitor, phone, Wi-Fi or backend. Owner confirmed RST/reconnect and both buttons with Monitor closed on 2026-10-11.
- [ ] Record unresolved issues and repeat checks after fixes before marking M01 Validated.

## Measurement record — updated 2026-10-11

| Item | Result |
| --- | --- |
| PCB revision / board markings | Owner read T-Display-S3; exact PCB revision unverified |
| Upload / LCD / buttons | Upload/hash verification PASS; owner confirmed LCD, animation and both buttons |
| Runtime Flash / PSRAM | 16,777,216 / 8,388,608 chip bytes |
| Free/min heap, free PSRAM | Settled 366,628 / 361,372; PSRAM free 8,373,475 bytes |
| Idle/happy FPS and render mean/max | Idle 2.4–2.6; repeated BOOT interaction 5.8–6.2 (may include brief idle); render mean 3,486–3,489 us, max 3,539 us |
| Maximum loop gap / input response | Max 3,769 us in 10-minute run; owner reports expected response, no instrumented input latency |
| Standalone startup / stability | Owner-confirmed RST/USB boot with Monitor closed; >10-minute diagnostics PASS |

## Git handoff

2026-10-11 update: the owner requested committing current work. Firmware is committed as `be5829d`; its updated gitlink and root documentation are included in the parent handoff commit. No push performed. This Git delivery does not establish physical validation. See [change history](../../../CHANGELOG.md) for the session record.

Suggested messages:

- Firmware: `feat: implement XUNA M01 T-Display-S3 hardware bring-up`
- Parent: `docs: document M01 bring-up and update firmware submodule`

## Connection checkpoint — 2026-10-11

**Fact:** owner reports having the standard LCD board. Exact PCB markings/revision have not been observed. Silicon revision below does not identify the PCB revision.

- Git before inspection: root `3dda411`, firmware `be5829d`, mobile `310e69f`, backend `0032828`; all on `dev`, clean. No commit/push or submodule edits in this session.
- `command -v`: Python 3.10 available; `pio`, `platformio`, `esptool`, `esptool.py`, `code` absent from shell PATH.
- PlatformIO IDE extension folder `platformio.platformio-ide-3.3.4-darwin-x64` exists. `/Users/xthao28/.platformio/penv/bin/pio --version`: Core 6.2.0. Extension installation and CLI availability do not prove IDE UI/build operation.
- Normal IDE Python has no esptool module; normal Core package directory `tool-esptoolpy` absent. Previous temporary environment was checked and still exists: `/private/tmp/xuna-m01-pio/bin/python` plus `/private/tmp/xuna-m01-pio-core/packages/tool-esptoolpy/esptool.py`, version 4.5.1; its help confirms `chip_id` and `--no-stub` support.
- Initial `ls /dev/cu.* /dev/tty.*`, `pio device list`, `system_profiler SPUSBDataType` and `ioreg -p IOUSB -l -w 0` inside sandbox showed only Baseus/Bluetooth serial and internal Apple USB devices. System profiler reported IOCreatePlugInInterface errors; PlatformIO emitted a cache-access exception. Do not infer board failure or actual cache ownership corruption from these sandbox results.
- Retried normal IDE `pio device list` outside sandbox: success, no cache exception; `/dev/cu.usbmodem14101`, description `USB JTAG/serial debug unit`, VID:PID `303A:1001`, serial `98:C3:77:A6:6F:D8`, location `20-1`. No unplug/replug comparison performed; reason for difference from initial scan is unconfirmed.
- Initial esptool attempt inside sandbox could not see the port. Same command outside sandbox succeeded (exit 0):

```sh
/private/tmp/xuna-m01-pio/bin/python /private/tmp/xuna-m01-pio-core/packages/tool-esptoolpy/esptool.py --port /dev/cu.usbmodem14101 --baud 115200 --no-stub --connect-attempts 3 chip_id
```

- ROM response: ESP32-S3, silicon revision v0.2, WiFi/BLE, crystal 40 MHz, MAC `98:c3:77:a6:6f:d8`. ESP32-S3 has no chip ID; command returned MAC instead. Tool reported enabling default SPI flash mode and hard reset via RTS on exit. No persistent Flash write/erase or flasher-stub download requested/performed.
- **Checkpoint passed:** host enumerates Espressif USB and communicates with ESP32-S3 ROM on the observed port. Port must be rechecked after reconnect/reset; do not hard-code it.
- **Unverified:** PCB revision, installed firmware behavior, Flash capacity, PSRAM, LCD/buttons, runtime performance and stability. No rebuild/tests/upload this session. M01 remains Implemented, not Validated.
- **Next:** wait for owner's explicit confirmation before build/upload; then complete P01–P05 and remaining physical checklist.

## Build, upload and physical run — 2026-10-11

Owner authorized continuation after the connection checkpoint, and read the PCB model as `T-Display-S3`. Exact PCB revision remains unrecorded.

- Normal IDE CLI: `/Users/xthao28/.platformio/penv/bin/pio`; Core 6.2.0. Installed missing pinned platform/toolchain packages in its normal Core directory (not temporary Core). Firmware build command: `pio run -d firmware -e xuna_t_display_s3` using that absolute CLI path. PASS, 103.11 seconds; initial linker RAM 21,840 bytes, firmware 319,685 bytes.
- Host command: `c++ -std=c++11 -Wall -Wextra -Werror -Ifirmware/include firmware/test/test_core.cpp -o /tmp/xuna-m01-core-test`, then executable: PASS. Sanitizers not rerun this session.
- Port rechecked: `/dev/cu.usbmodem14101`, same USB identity. Upload command: `pio run -d firmware -e xuna_t_display_s3 -t upload --upload-port /dev/cu.usbmodem14101`. PASS at 921600 baud with hashes verified. Standard upload erased/wrote bootloader, partition, boot-app and application regions; this was authorized after the read-only checkpoint.
- Observed startup warning: `ESP.getPsramSize()` returned 8,386,279 bytes and failed the exact 8 MiB comparison. Local Arduino 2.0.14 `cores/esp32/Esp.cpp` confirms this API sums PSRAM heap free + allocated bytes, rather than chip capacity.
- Scoped fix: use pinned ESP-IDF `soc/esp32s3/spiram.h` / `esp_spiram_get_size()` for capacity check; keep Arduino heap API under explicit `psram_heap_total` log label. No animation/input changes. Rebuild + upload PASS (10.39 seconds), linker RAM 21,840 / 327,680 bytes, firmware 319,737 / 6,553,600 bytes. This SDK-specific adapter belongs to hardware firmware, not pure C++ core.
- Corrected startup: XUNA `0.1.0-m01`; Flash 16,777,216 bytes; PSRAM detected yes; PSRAM chip 8,388,608 bytes; driver initialized; no false memory warning. Initial heap free/min 366,892 / 361,744 bytes; after diagnostics settled 366,628 / 361,372. PSRAM heap total/free 8,386,279 / 8,373,475 bytes.
- Owner response: “LCD và cả hai nút hoạt động đúng các bước” to branding/color/geometry, two-frame idle, BOOT happy with ~2.4-second timeout, GPIO14 immediate idle, and held-button checks. Serial independently recorded GPIO0 and GPIO14 events. Input response is qualitative; no instrumented latency measurement.
- Runtime monitor: `pio device monitor -d firmware --environment xuna_t_display_s3 --port /dev/cu.usbmodem14101 --baud 115200 --filter time --filter log2file`; DTR/RTS inactive. Raw log moved to `/private/tmp/xuna-m01-runtime-20261011.log` while open to keep generated logs out of the child repo; durable summarized evidence belongs here. Monitoring started 21:25:59 local time. Stability check in progress; do not infer 10-minute PASS yet.
- Pure idle windows 2.40–2.60 rendered fps; mean render approximately 3,480–3,487 us. Happy/idle mixed windows are not pure happy FPS. Runtime and remaining reset tests will be appended after observation.

- Reconnect at 21:28:45 was owner-triggered USB unplug/replug, explicitly confirmed; do not count as spontaneous failure. Board reappeared and both button events resumed. Owner then confirmed RST and USB reconnect both start XUNA and both buttons work while Monitor is closed. Fresh monitored stability window starts 21:30:16 (logs at `/private/tmp/xuna-m01-stability-20261011.log`); opening native USB Monitor produced a USB_UART_CHIP_RESET startup, so no-Monitor behavior is established by owner observation separately.

### Final runtime summary

- Continuous corrected-firmware run: startup 21:30:16 through final diagnostics 21:40:41 on 2026-10-11 (Asia/Ho_Chi_Minh), more than 10 minutes. 125 diagnostic windows, one startup, zero warning/error/disconnect markers or observed spontaneous resets. Monitor closed afterward.
- Settled heap remained exactly 366,628 free / 361,372 minimum bytes; PSRAM heap 8,386,279 total / 8,373,475 free bytes throughout all post-startup windows. No monotonic heap decline in this run; this is a bounded stability observation, not proof against all memory defects.
- Render mean 3,486–3,489 us, maximum 3,539 us; max loop gap 3,769 us. Idle 2.4–2.6 rendered fps. Repeated BOOT interactions yielded 5.8–6.2 fps; timestamps show some inter-press gaps exceed 2.4 seconds, so those windows may contain brief idle. No claim of a pure happy benchmark or measured physical input latency.
- Buttons were independently logged in the earlier corrected run/reconnect; the final window has 16 GPIO0 events. Owner confirmed GPIO14, held-button behavior and timeout separately. Qualitative physical response is validated by owner observation.
- Raw temporary logs are not durable project artifacts. This summary preserves the measured evidence. Known upstream compiler warnings remain unchanged (parallel DMA/touch/UART); no project build failure.
- Remaining acceptance gap: exact PCB revision and confirmation against board markings/documented standard revision. M01 stays **Implemented; physical checks largely passed, final validation pending**. P07 remains open; no later milestone started. Uploaded diagnostics fix is uncommitted in firmware; gitlink/HEADs unchanged.

## Later MVP upload — 2026-10-11

Board now runs 0.2.0-mvp, uploaded at owner request; LCD and both buttons owner-confirmed. This changed firmware does not close the M01 PCB revision/P07 gap. See [MVP board smoke evidence](MVP-local.md#lilygo-mvp-buildupload-smoke--2026-10-11) for current resource figures and still-open BLE/persistence acceptance. Historic M01 measurements refer to the earlier M01 image.

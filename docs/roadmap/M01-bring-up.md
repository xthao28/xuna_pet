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
- [ ] Build and upload using firmware README commands; record environment versions and port.
- [ ] Observe readable XUNA branding and original pet, correct colors/orientation, no offset/clipping.
- [ ] Observe two-frame idle animation without flicker or stale pixels.
- [ ] Press GPIO0/BOOT: happy expression/color and faster animation; returns idle after 2.4 seconds.
- [ ] Press GPIO14 while happy: immediate idle. Hold either button: no repeated events. Rapid presses should remain responsive; release/repress BOOT restarts happy.
- [ ] Capture startup Flash size and PSRAM detection; expected 16,777,216 Flash / 8,388,608 PSRAM bytes.
- [ ] Capture 5-second diagnostics in idle and happy: heap/min heap, free PSRAM, FPS, render mean/max and loop gap. Record measured input response; investigate visible lag.
- [ ] Run at least 10 minutes and check for resets, allocation errors or steadily declining heap.
- [ ] Reset/reconnect USB and verify startup without Serial Monitor, phone, Wi-Fi or backend.
- [ ] Record unresolved issues and repeat checks after fixes before marking M01 Validated.

## Measurement record (owner to fill after flashing)

| Item | Result |
| --- | --- |
| PCB revision / board markings | Not observed |
| Upload / LCD / buttons | Not observed |
| Runtime Flash / PSRAM | Not measured |
| Free/min heap, free PSRAM | Not measured |
| Idle/happy FPS and render mean/max | Not measured |
| Maximum loop gap / input response | Not measured |
| Standalone startup / stability | Not tested |

## Git handoff

2026-10-11 update: the owner requested committing current work. Firmware is committed as `be5829d`; its updated gitlink and root documentation are included in the parent handoff commit. No push performed. This Git delivery does not establish physical validation. See [change history](../../CHANGELOG.md) for the session record.

Suggested messages:

- Firmware: `feat: implement XUNA M01 T-Display-S3 hardware bring-up`
- Parent: `docs: document M01 bring-up and update firmware submodule`

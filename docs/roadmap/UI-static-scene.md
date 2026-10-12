# XUNA — Static LCD scene delivery

Date: 2026-10-12. **Status: Implemented; build/upload and owner visual acceptance PASS.** Limited 25-second serial observation; long-run/thermal validation not claimed. Owner paused S11 and explicitly requested UI implementation/upload; no storage benchmark execution or gate exception inferred.

## Verified configuration and remaining hardware detail

Existing standard LILYGO T-Display-S3 LCD configuration retained: ESP32-S3/16 MiB Flash/8 MiB PSRAM, PlatformIO espressif32 6.5.0, Arduino 2.0.14, TFT_eSPI 2.5.43/Setup206, ST7789 parallel 8-bit, TFT_RGB. Physical 170×320; rotation 1 yields 320×170 landscape. Read exact installed Setup206 and driver implementation before editing.

LCD D0–D7 = GPIO39/40/41/42/45/46/47/48; CS/DC/RST/WR/RD = 6/7/5/8/9. Power GPIO15, backlight GPIO38; buttons GPIO0/14. Compile-time mapping/rotation/RGB/asset-size assertions retain these values. Chip rev v0.2 was observed by esptool; **PCB revision still unknown**. No framework/pins/partition upgrade.

## Image pipeline and implementation

Owner source `/Users/xthao28/Downloads/xuna_and_bg.png`, 1721×914 RGB, copied exactly to firmware/assets/source/xuna_and_bg.png. SHA-256 `76fd464fa3d5faba63bd2f7b96091045a7194ac5b0f20958fa0d624f5b14852a`. Concept scene, not assumed sprite data.

`firmware/tools/convert_scene.py` uses installed Pillow. Uniform contain scale 0.1859384079 and nearest-neighbor, integer rounding produces 320×170 at offset 0/0; no crop or independent-axis stretching. Full pet/horns/tentacles/window/background preserved. Different-aspect replacements are letterboxed. Transparent sources composite over cream. RGB565 quantization does not dither or exchange R/B.

Generated header/source and preview/JSON metadata are checked into the working tree. 54,400 canonical uint16 RGB565 words (108,800 B), aligned PROGMEM. ELF inspection confirms symbol at 0x3c0a0154, size 0x1a900, within .flash.rodata. `setSwapBytes(true)` is required because pinned ESP32-S3 parallel pushPixels uses tft_Write_16 for canonical values; const pushImage reads pgm_read_word into a 320-word row buffer (640 B), not a full-frame stack array.

DisplayManager initializes LCD/rotation, checks dimensions, transfers image once and enables backlight after transfer. Removed placeholder sprite/text and its 12,800 B framebuffer. Removed loop rendering and FPS diagnostics; pet/BLE/input/learning/storage state logic still runs unchanged. UI intentionally remains static for all internal states in this phase, so BLE reaction state does not mean a new visible pose. No new BLE/AI features.

## Actual validation

| Check | Result |
|---|---|
| Source/preview inspected | PASS: full composition, pet and horns retained |
| Converter run twice / generated hashes | PASS: deterministic |
| Pixel count | PASS: 54,400 / 108,800 B |
| PlatformIO build xuna_t_display_s3 | PASS |
| Static RAM | 46,072 B; delta −1,432 vs 47,504 baseline |
| Firmware image | 1,062,793 B; delta +98,460 vs 964,333 baseline |
| Native regression | PASS, 23/23 |
| ELF asset placement | PASS, Flash rodata |
| Actual partition table vs build | PASS, same table; NVS 0x9000/0x5000 |
| Fresh NVS backup/hash | PASS, 20,480 B before upload |
| Upload / esptool verification | PASS on /dev/cu.usbmodem14101 |
| Startup log | scene=static size=320x170 rgb565_bytes=108800 draw_us=31663 |
| Serial observation, 25 seconds | One boot/draw, four diagnostic windows; no spontaneous reset or error observed |
| Runtime memory at startup | heap_free=254488; PSRAM free=8386295 (no sprite allocation) |
| Post-upload NVS readback | PASS, byte-for-byte identical to backup |
| Owner LCD reply | “Ảnh đúng, màu đúng, ổn định” after explicit question covering orientation, full horns/feet, cam/cream/lilac/lime and flicker |

Opening serial and esptool reads reset the board as expected; no spontaneous reset observed within the observation window. Boot draw duration includes the blocking one-time full-screen transfer; it is not an animation FPS benchmark. No fresh thermal measurement or long-run acceptance.

Backups, hashes and runtime.log stored outside repo at `/Users/xthao28/xuna_backups/2026-10-12-static-ui/`. Standard upload erases/writes boot/app/partition sectors, **not** NVS; no erase_flash or filesystem format. Restoring NVS was not necessary or tested.

## Commands and handoff

```sh
python3 firmware/tools/convert_scene.py
~/.platformio/penv/bin/pio run -d firmware -e xuna_t_display_s3
~/.platformio/penv/bin/pio run -d firmware -e xuna_t_display_s3 -t upload --upload-port /dev/cu.usbmodem14101
```

Recheck port before upload. Source and generation outputs live inside firmware. Changes uncommitted; previous firmware/core/root edits retained, gitlinks unchanged. Current board now contains the working-tree core extraction plus this UI, explicitly authorized by the owner's UI upload request; S01 Android/BLE/persistence acceptance is still pending. This delivery does not validate all M04 work or exact PCB revision. S11 remains paused until the owner asks to resume. No commit/push.

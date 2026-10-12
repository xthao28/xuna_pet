# XUNA — Animated LCD scene

Date: 2026-10-12. **Status: Implemented/build/upload PASS; owner provisionally accepted final corrected version.** S11 remains paused.

## Configuration and assets

AGENTS/current firmware inspected. Same standard T-Display-S3 ST7789, TFT_eSPI 2.5.43/Setup206, Arduino 2.0.14/espressif32 6.5.0, RGB order, parallel pin mapping, rotation 1 and 320×170 landscape retained. Compile-time assertions retained. Actual ESP32-S3 rev v0.2/16 MiB Flash/8 MiB PSRAM verified; PCB revision remains unknown.

Owner xuna-pet.png reference copied exactly to firmware/assets/source. Generator `firmware/tools/generate_pet_scene.py`, palette/size config `firmware/assets/scene_config.json`. Character large regions traced and simplified, texture discarded; expressions/spots/feet re-authored on fixed canvas, rather than complete resized photo sprites. Two cream horns, five body-relative spots, short feet and explicit outline-color toes. Separate flat-color room background preserves window/plant/ledge arrangement. Only requested palette used in opaque PNG pixels.

20 frames: 2 idle-deformation variants × 5 eye states × 2 leg variants. Canvas 96×72, anchor (112,72), visible union height 65 pixels (38.2% LCD height). Assets: room_background.png, pet_authored_base.png, pet_frames.png, pet_lcd_preview.png, pet_animation.gif and animated_scene.json. RGB565 exported to XunaAnimatedScene header/source; 108,800 + 276,480 = **385,280 B** Flash pixels. Old static generated C++ retained under assets/legacy, not compiled.

## Rendering and behavior

Background pushed once. One startup-allocated 13,824 B region buffer; on changed frame compose transparent sprite and Flash background then send one opaque region. Full constant canvas restores the union of all frame extents. No delay/per-frame allocation or new framebuffer on stack. Flash symbols verified with nm; RGB canonical values/setSwapBytes(true)/TFT_RGB match installed Flash and RAM pushImage paths.

Pure PetVisualAnimation leaves life state alone: 1 pixel idle, nonblocking blink phases with 3–5 second randomized rest, 2 pixel alternating feet in brief bursts separated 4–6.5 seconds. GPIO0 Happy has distinct smiling eyes/mouth and immediate wiggle; GPIO14 Idle returns neutral sly face. Sleep closes eyes and stops feet; existing button/BLE/learning/storage logic remains active.

Owner reported initial pet not matching/animation difficult to see. Revised shape to direct reference-region tracing and made Happy/feet more visible. Owner then reported a colored seam between torso/feet and absent dark toes. Frame inspection found an exposed transparent scanline at the split; corrected torso/feet overlap, stopped sequential in-place foot cutting, and painted dark tip regions explicitly. All 20 final frames checked for opaque joint continuity/binary masks/palette. Final reply: “tạm thời đã ổn có gì cần sửa tôi sẽ nói sau”. This is provisional visual acceptance, not a full long-run/BLE acceptance claim.

## Validation

- Native regression 25/25 PASS; ASan/UBSan 25/25 PASS, including blink/idle/wiggle/rollover/state tests. Development tests caught a fake RNG sampling hang and begin-state reset; fixed before final validation.
- Build/upload xuna_t_display_s3 PASS on /dev/cu.usbmodem14101, esptool hashes verified.
- Linker: static RAM **46,144 B** (+72 vs static scene); image **1,340,569 B** (+277,776 vs static scene). Runtime region allocation additional 13,824 B; PSRAM diagnostics reflect allocation on this board. Figures are not power/thermal measurements.
- Fresh actual-table comparison and NVS backup/hash before first upload. No partition change/erase_flash/filesystem format. Backups/runtime logs outside repo: /Users/xthao28/xuna_backups/2026-10-12-animated-ui.
- NVS raw bytes differ because normal 5-minute lifetime checkpoint occurred: newest valid v1 snapshot before `(generation=4, activeSeconds=1200, events=0)`, after `(5,1500,0)`; learning/episode payload bytes 12..91 identical. This is not byte-identical whole-partition preservation, nor an Android roundtrip test.
- Final 25-second runtime log: one expected serial-open boot, 40 draws, max render 4,754 us, max loop gap 4,767 us; heap stable, no spontaneous reset/error. Earlier v2 log captured GPIO0 Happy then idle timeout. GPIO14 physical log not captured; owner provisional acceptance above retained separately.

## Outstanding and delivery

Long-run/thermal/complete BLE and persistence acceptance remain pending; PCB revision unknown. S01 Android and full S06 still pending. S11 is paused. Owner requested committing today's changes after accepting current UI; commit child repositories first then parent pointers; no push requested. See PROCESS latest Git delivery for commit IDs.

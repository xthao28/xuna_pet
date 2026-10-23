# Device window scenes, reaction effects and cards (2026-10-22)

Status: **Implemented, host-tested and ESP32-built; not yet on the board** (board unplugged by the owner because it felt warm). Owner approved items 1–3 of the proposal on 2026-10-22 ("đi theo cách của bạn"): reaction effects, window by day part, GPIO14 hold to change the scene. Later the same day the owner asked for items 4–5 too: status card (GPIO0 hold) and pairing QR (both buttons), see below.

## Behaviour

| Input | Effect |
| --- | --- |
| GPIO0 press inside the 10 s reaction window (pet) | Learns as before, plus a **heart** rises above XUNA's head (1.5 s, blinks out) |
| GPIO14 short press inside the window (shoo) | Learns as before, plus a grey **puff** |
| GPIO14 short press otherwise | Idle, as before. **Now fires on release** (it was the press edge) so a hold can be told apart |
| GPIO14 hold ≥ 800 ms (hatched pet only) | Cycles the window scene Auto → Day → Evening → Night → Rain → Auto, shows a **sparkle**, saves the choice; never also idle or shoo |

Auto follows the trusted day part (S10 day parts): morning/afternoon → Day, evening → Evening, night → Night. Without a phone sync since boot the day part is Unknown and Auto shows Day, the original approved art. Rain animates 14 slanted drops on the glass (70 ms steps); Night twinkles stars (one change per 600 ms). In Egg the hold is ignored: the S10 freeze reserves a 3 s GPIO14 hold for hatching.

## Implementation

- Pure (`xuna_core`): `xuna/HoldButton.h` (short on release / one hold, wrap-safe), `xuna/visual/SceneEffects.h` (`SceneMode`, `Backdrop`, `backdropFor`, `ReactionEffect`, `WindowWeather`); `DebouncedButton::pressed()`. Tests `test_scene_effects` (7) + one `test_core` assertion.
- Art: `tools/generate_pet_scene.py` now also emits four 75×81 window patches (Day byte-identical to the background crop, asserted), 10 star positions, rain/star colours and three 13×11 effect sprites; preview `assets/generated/scene_backdrops.png`. Pet frames unchanged. One background pixel differs from the committed asset because Pillow 13 rasterises one polygon edge differently.
- Firmware: `DisplayManager` pushes the window (12,150 B buffer) and the effect region (16×30, 960 B) separately from the pet canvas; `static_assert`s keep the three regions disjoint. `main.cpp` sets the backdrop each loop from `SceneMode` + `LifeCore` clock, triggers effects only when `lastReactionApplied()`, and logs `scene_mode=` / `scene_max_us=`. `ScenePreference` stores the mode in NVS namespace **`xuna_ui`** key `scene` (never `xuna_life`), written only on a hold.

## Checks

Native **232/232**, ASan 232/232, ESP32 build + purity PASS (RAM 52,928 B static, +80; Flash 2,935,817 B, +52,172), parity env build PASS. Runtime heap +13,110 B (two buffers).

**Not run (needs the board):** upload, boot log, `scene_max_us` and loop gap with rain, visual check of the four scenes and three effects, hold timing feel, `xuna_ui` write. Before upload: NVS backup as usual (the new namespace is additive).

## Items 4–5: status card and pairing QR

| Input | Effect |
| --- | --- |
| GPIO0 short press | Greeting or pet reaction as before, **now on release** |
| GPIO0 hold ≥ 800 ms | **Status card** for 8 s: lifetime (active time), energy with bar, current state, feedback count, learned quiet / play / greeting choice, usual arrival ("khoảng 19:10", weekend wording on weekend days with trusted time, "chưa rõ" before the routine gate opens), PetId prefix |
| Both buttons held 3 s | **Pairing card** for 60 s: QR of `xuna://pair?pet=<32 hex PetId>&key=<16 hex of the device public key after 0x04>` + Vietnamese instructions. Needs a hatched identity and the device key. Nothing secret: binding still requires the device proof |
| Any button while a card is open | Closes it; the press does nothing else |

Once both buttons are down together, all single-button events are swallowed until both are released, so a combo never greets, idles or opens the status card; a combo released before 3 s does nothing. Buttons held at startup are ignored until released (kept from the M01 behaviour).

Implementation: `xuna/ButtonPad.h` (two `HoldButton`s + combo, `begin()` for boot-held buttons), `xuna/visual/TextRaster.h` (UTF-8, glyph lookup, alpha blend, clipping), `xuna/visual/DeviceCards.h` (card model from `LifeCore`, Vietnamese strings, layouts, `pairingUri`), `HabitPredictor::usualArrival`. Fonts: `tools/generate_ui_font.py` renders Be Vietnam Pro (from `mobile/assets/fonts`, OFL-1.1) at 20/14/11 px for printable ASCII plus every non-ASCII character in `DeviceCards.h` literals (127 glyphs each, 48 KB). QR: vendored `lib/qrcodegen` (Nayuki v1.8.0, MIT, unchanged); the payload is version 5 at ECC M (37 modules, 4 px). Cards render into a 108,800 B PSRAM framebuffer (+ 7.8 KB QR scratch), allocated on first use; closing restores background, window, effect and pet. Host preview: `sim/card_preview.cpp`.

Checks: native **240/240**, ASan 240/240 (new `test_device_cards` 7, `test_habit` +1), ESP32 build PASS (RAM 52,960 B static; Flash 2,995,977 B, +60 KB vs scenes), parity build PASS. Host-rendered previews checked visually (Vietnamese diacritics correct). OpenCV 4 `QRCodeDetector` decodes the host-rendered pairing card back to the exact URI, at 1× and 2× scale.

## App side: scanning the pairing QR (owner-approved dependency, 2026-10-22)

- Dependency: `mobile_scanner: 7.4.2` (BSD-3-Clause, 160/160 pub points, Flutter ≥ 3.29; Android CameraX + bundled ML Kit, minSdk 23 = app; iOS Apple Vision, no ML Kit next to Firebase). Lock diff: the package plus the SDK floor `flutter >=3.29.0` / `dart >=3.7.0` (toolchain is 3.32.8). Camera permission: Android from the plugin manifest; iOS `NSCameraUsageDescription` added.
- Domain (`device`): `PairingCode`, `ParsePairingCodeUseCase` (only `xuna://pair?pet=<32 hex>&key=<16 hex>`, anything else null), `ConnectPairedDeviceUseCase` (scan → connect → read identity → keep the matching PetId, disconnect others; `deviceNotFound` vs new `pairedDeviceNotFound`).
- Presentation: new route `pairingScan` (`features/pairing`: page with `MobileScanner`, controller closes once with the first valid code, hint for other codes, camera-denied/error text). Device tab: "QUÉT MÃ QR TRÊN XUNA" under the scan button (hidden in simulator mode). `HomeController.scanPairingCode` / `connectPaired` share the post-connect path with `connect`.
- Not used yet: `keyPrefix` (kept for checking the device key during a later bind). Not run: a phone with a camera, the board.

**Not done:** board run of everything in this record; phone run of the scanner.

# XUNA — Process and Session Handoff

Last updated: **2026-10-11** (Asia/Ho_Chi_Minh).
Current milestone: **M01 — Hardware Bring-up**.
Current status: **Implemented; software build/tests passed; physical validation pending**.
Next action: finish the local PlatformIO IDE setup, connect the standard LCD board, identify its revision/USB port, then build and flash M01.

## 1. Read order and authority

1. Read [AGENTS.md](AGENTS.md) completely: canonical product intent, approved decisions and agent rules.
2. Read this file for working context, then [PLAN.md](PLAN.md) for tasks and the latest entries in [CHANGELOG.md](CHANGELOG.md) for recent changes.
3. Read [M01 validation record](docs/roadmap/M01-bring-up.md), [firmware README](firmware/README.md) and relevant source before editing.
4. Inspect actual Git status in the parent and affected submodules. This snapshot is not live state.

This file is an operational handoff, not a replacement for AGENTS.md. Plans in PLAN.md do not approve unresolved architectural decisions or authorize starting later milestones. When this file conflicts with implementation or newer evidence, inspect the discrepancy and update it without discarding history.

## 2. Product and scope context

XUNA is a persistent, local-first digital lifeform on physical hardware, expressed through pixel art. Experiences should eventually shape memory, preferences, behavior and explainable evolution. The current button reactions are scripted animation, **not AI learning**.

Approved directions include the XUNA name, VS Code + PlatformIO, existing LILYGO T-Display-S3 hardware, Flutter companion direction and incremental milestones. Arduino is authorized for this initial bring-up; a permanent Arduino-versus-ESP-IDF decision remains open. Conversation belongs alongside learning in M05. Core pet life must not require cloud connectivity.

Current implementation scope is LCD, original placeholder sprite, buttons, animation and diagnostics. BLE, backend, voice, sensors, persistence, learning and evolution are not part of M01.

## 3. Repository and Git snapshot

Repository: `/Users/xthao28/xuna_pet`, remote: `https://github.com/xthao28/xuna_pet`.

| Path | Independent repository | Recorded gitlink |
| --- | --- | --- |
| `firmware/` | `xthao28/xuna_firmware` | `be5829d (firmware commit; parent pointer updated with this handoff commit)` |
| `mobile/` | `xthao28/xuna_mobile` | `310e69f614f88cb3649ddef67ac758014c9ffb32` |
| `backend/` | `xthao28/xuna_backend` | `0032828abb4c754d7222dc3aaed24a630d92bc56` |

All three submodules exist and are initialized. Firmware originally contained only a placeholder README. M01 firmware changes are committed as `be5829d`. The owner requested committing the current changes on 2026-10-11; parent documentation and the new firmware pointer are included in the parent commit containing this snapshot. Mobile/backend remain unchanged. No push has been performed. Inspect Git for changes made after this snapshot.

Before doing work:

```sh
git status --short
git submodule status
git -C firmware status --short
git -C mobile status --short
git -C backend status --short
```

Preserve dirty/untracked files. Do not reset, recreate submodules or initialize nested repositories. Firmware commits must happen inside the child repository before updating its pointer in the parent. Never treat a dirty submodule as a committed delivery.

## 4. Implemented M01 slice

Firmware version: `0.1.0-m01`.

| File or module | Responsibility |
| --- | --- |
| `firmware/platformio.ini` | Pinned PlatformIO, MCU/memory configuration, display library/setup |
| `firmware/include/AppConfig.h` | Pins, version, rotation and timing constants |
| `firmware/include/DebouncedButton.h` | Pure C++ press-edge debounce |
| `firmware/include/InputManager.h`, `firmware/src/InputManager.cpp` | Active-low GPIO adapter for two buttons |
| `firmware/include/AnimationManager.h` | Pure C++ idle/happy state and frame timing |
| `firmware/include/DisplayManager.h`, `firmware/src/DisplayManager.cpp` | LCD initialization, branding and original sprite rendering |
| `firmware/src/main.cpp` | Setup, bounded loop, event mapping and serial diagnostics |
| `firmware/test/test_core.cpp` | Host tests for debounce and animation |
| `firmware/README.md` | Setup, commands, sources, limitations and licensing notes |
| `docs/roadmap/M01-bring-up.md` | Build evidence and physical acceptance checklist |
| `.gitignore`, `firmware/.gitignore`, `CLAUDE.md` | Local artifact exclusions and agent entry point |

Behavior:

- Two frames per state; idle interval 400 ms, happy interval 160 ms.
- GPIO0/BOOT requests happy for 2400 ms; a new press restarts the timer.
- GPIO14 requests idle; idle wins simultaneous press events.
- Debounce is 30 ms; held buttons do not auto-repeat. A button held at app startup must be released before another press is emitted.
- Unsigned elapsed-time math handles rollover; late frames are skipped with bounded work.
- One 80×80 RGB565 sprite is allocated during setup (12,800 bytes plus library overhead). Only the sprite region redraws each frame.
- Logs every 5 seconds: state, rendered FPS, average/max render duration, max loop gap, heap/min heap and PSRAM. Rendered FPS is animation cadence, not panel refresh capacity.
- No application-loop delay or serial-host wait. LCD transfers and Serial writes are synchronous; real latency is unmeasured.
- Sprite allocation failure disables rendering while input/logging continue. TFT_eSPI cannot confirm physical LCD presence or successful visual output.

## 5. Hardware and toolchain facts versus assumptions

**Documented configuration:** standard 1.9-inch 170×320 ST7789 LCD, ESP32-S3R8, expected 16 MB Flash / 8 MB OPI PSRAM. LCD interface is parallel 8-bit, not SPI.

- LCD D0–D7: GPIO39,40,41,42,45,46,47,48.
- LCD CS=6, DC=7, RST=5, WR=8, RD=9.
- Peripheral power GPIO15 HIGH; backlight GPIO38.
- Buttons GPIO0 and GPIO14, active-low. Holding GPIO0 during reset enters download mode.
- Rotation defaults to `1` (320×170 landscape).

**Assumption awaiting physical confirmation:** the owner's board matches this standard LCD pinout; PCB revision is not recorded. Do not apply this configuration to AMOLED or another variant.

**Pinned build:** `espressif32@6.5.0`, Arduino ESP32 2.0.14, `bodmer/TFT_eSPI@2.5.43`, Setup206. The generic `esp32-s3-devkitc-1` supplies the MCU target; explicit overrides select 16 MB Flash, QIO/80 MHz, `qio_opi` and `default_16MB.csv`. LCD pins come from Setup206, with compile-time assertions. Do not remove the global TFT_eSPI include path: the first build failed without it in framework-library compilation.

Official source links and license notes are in the firmware README. Check current official documentation again before changing dependencies or hardware configuration; do not upgrade libraries merely to silence warnings.

## 6. Verification evidence and gaps

Results recorded on **2026-10-10**, not rerun merely to create this handoff:

| Check | Recorded result |
| --- | --- |
| PlatformIO configuration parsing | PASS |
| ESP32-S3 firmware compilation | PASS; `.bin` and `.elf` generated |
| Host C++ tests with warnings as errors | PASS |
| Host AddressSanitizer / UndefinedBehaviorSanitizer | PASS |
| Git whitespace checks | PASS |
| Linker static RAM | 21,840 / 327,680 bytes |
| Firmware / app partition | 319,709 / 6,553,600 bytes |
| Connected ESP32 USB serial device | Not detected in previous session |
| Flash/upload, LCD and electrical buttons | Not tested |
| Runtime heap/PSRAM, render timing, stability | Not measured |
| Exact PCB revision / standalone boot | Not verified |

Linker figures exclude runtime allocation and cannot establish free heap or display performance. Physical results must be entered into the M01 record; do not invent measurements.

Known upstream warnings: parallel DMA unavailable, touch unconfigured, and an Arduino 2.0.14 non-void return warning in UART code. No project compile errors remained after the include-path fix.

The agent used temporary tooling:

```sh
PLATFORMIO_CORE_DIR=/private/tmp/xuna-m01-pio-core /private/tmp/xuna-m01-pio/bin/pio run -d firmware
```

Those temporary directories may disappear. VS Code's PlatformIO installation is a separate environment; the open IDE installation tab does not establish that installation has finished. Confirm it before relying on `pio` in the IDE terminal.

## 7. Plan and history

- [PLAN.md](PLAN.md): ordered M01 tasks P01–P08, their statuses/dependencies, execution commands and the Proposed M02 plan.
- [CHANGELOG.md](CHANGELOG.md): dated implementation, fixes, validation outcomes and session changes. This includes uncommitted work, not only Git commits.
- [M01 validation record](docs/roadmap/M01-bring-up.md): detailed physical checklist and measurement evidence.

Current next task: **P01 — confirm PlatformIO IDE tooling and build in the owner's normal environment**, followed by board identification and physical checks. Keep the task list in PLAN.md and the dated history in CHANGELOG.md; this file owns the current context snapshot.

## 8. Session update procedure

At the start of a session, read the files in section 1, inspect Git and choose the first incomplete authorized task. Re-check facts that may have changed, such as tool availability, board connection or dirty files. Report in Vietnamese.

At the end of each work session, update:

- Last-updated date, current milestone/status and exact next action.
- Files/behavior changed and decisions, preserving Idea/Proposed/Approved distinctions.
- Commands actually run, pass/fail results and where evidence is stored.
- Hardware measurements separately from build figures.
- Blockers, unresolved questions and user actions needed.
- Git state: uncommitted changes, commits, submodule pointer changes and push status.
- Update task statuses and remaining work in PLAN.md.
- Append a dated entry to CHANGELOG.md; preserve previous entries and link to evidence.

Do not store credentials, tokens or other secrets here. Use links to detailed records instead of duplicating lengthy logs. A stopped session or successful compile does not mean a milestone is Validated.

## 9. Copyable prompt for the next AI/session

> Read AGENTS.md, PROCESS.md, PLAN.md and the latest CHANGELOG.md entries first, then inspect Git status and the M01 validation record. Continue the first incomplete authorized M01 task. Preserve all existing uncommitted work and submodule boundaries. M01 compiled and passed host tests in the previous session, but has not been flashed or physically validated. Confirm PlatformIO IDE/tooling and actual board connection before claiming new results. Report in Vietnamese, update PROCESS.md, task statuses in PLAN.md, CHANGELOG.md and the M01 record with evidence, and do not start M02 or commit/push unless requested.

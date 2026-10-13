# XUNA — Process and Session Handoff

Last updated: **2026-10-12** (Asia/Ho_Chi_Minh).
Current milestone: **M04 pure-core work partially implemented; animated LCD UI uploaded and provisionally accepted.** The local MVP through M05 is implemented, but its physical acceptance is pending.
Current status:

- Technical plan 0.1.2 and session plan rev. 3 updated for device-first Conversation; implementation remains Proposed. Product direction is owner-requested/Approved; ADR-0006 and VOICE-01–04 remain Proposed/not started.
- Owner approved D1, D7, D12, D14 and D17 on 2026-10-12.
- Firmware S03/S04/S05/S07 and S05-fix-01 complete; S06 pure core only. Current firmware commit c84d4e3 includes animated UI; M04 physical/full acceptance remains pending.

Next action: **Animated UI provisionally accepted; await owner’s next request. S11 remains paused.** S01 Android acceptance and full S06 remain pending.

## 0. Start here — next work (updated 2026-10-12)

**Read first.** AGENTS.md (canonical) → this section → [XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md):

- §2 rules;
- §3 session map;
- the entry for the session you run.

Then read only the sections of [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md) that the session cites. The rationale for the current plan is in [XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md).

**Where things stand:**

- **Local MVP through M05:**
  - Implemented: firmware `be58099`, mobile `3846880`; backend `0032828` is a README only.
  - Build, upload, LCD and buttons PASS.
  - **Pending:** real-phone BLE, learning, reboot, power-loss and forget acceptance (PLAN MVP-07). M01 PCB revision/P07 also remain open.
- **Approved on 2026-10-12** (AGENTS.md §3):
  - **D1:** M04 before new M05 features.
  - **D7:** hatch on the device or via the app (opcode 7); exact `bornAt` only with trusted time in the hatch boot; the MVP pet migrates as Newborn.
  - **D12:** C++11 core.
  - **D14:** Flutter 3.32.8 pinned via `mobile/.fvmrc` (created and baseline verified in S00; committed as mobile 77d27ec).
  - **D17:** Conversation Layer A with M05a, text-first; Layer B after M05b.
- **Historical Windows inspection (2026-10-12; not this session’s Mac environment):**
  - no PlatformIO, no host C++ compiler, no real Python (Store alias only), no WSL distribution;
  - Flutter 3.41.1 via fvm, with 3.32.8 not installed.
  - iOS builds and runs need the Mac.

**Preparation sequence** (full steps in the session plan §6; latest results below):

| # | Session | Work | Owner input needed | Done when |
|---|---|---|---|---|
| 1 | **S02 — documentation complete** (S, no tooling) | Review/extend existing `docs/decisions/README.md` and create `docs/decisions/ADR-0001-reference-reuse-policy.md` from plan §6.3 | Accept ADR-0001 or not | Both files exist; Git state reported |
| 2 | **S00 — PASS on Mac** (M) | Install the PlatformIO IDE extension; install a host compiler; `fvm install 3.32.8` + `mobile/.fvmrc`. Baselines: host tests; `pio run` (expect static RAM 47,504 B, image 964,333 B); `flutter analyze` + `flutter test` (10 tests); `pubspec.lock` unchanged | Choose MSYS2 or WSL for the compiler; OK to commit `.fvmrc` | Versions and baselines recorded in this file |
| 3 | **S01** (Owner) | MVP physical acceptance with the phone, plus observed v1 bytes from a BLE inspector. **Verified NVS backup first** (session plan §5) | Board, phone and Mac time | MVP-local.md updated; MVP-07 status set |

After that, follow the session map:

- S03 → S04 → S05/S07 → S06 → S08a → S08b → S09 → S10 → S11 …
- S03–S05 and S07 are host-only and may run after S00 while S01 waits for the phone.
- No refactored or storage-changing firmware goes onto the owner's board before S01.

**Open decisions:**

| Decision | When |
|---|---|
| D2 | After experiment S11 |
| D10 | After experiment S35 |
| D15 | At checkpoint S42a |
| D3–D6, optional D16 | Session S22, before S23 |
| D8, D9 | Session S29, before S30 |
| D11a / D11 | Only if cloud STT/LLM is to be evaluated |
| D13 | M06 |

**Working rules to keep:**

- Start a session only when the owner asks.
- One session at a time; respect its preconditions and done criteria.
- Discuss in Vietnamese; keep docs and code in English.
- Commit or push only on the owner's request:
  - follow the existing format: a single-line conventional message such as `docs: ...` or `feat: ...`;
  - **no AI attribution or trailers anywhere**;
  - child repo first, then the parent gitlink.
- Update this section, PLAN.md and CHANGELOG.md at the end of every session.

**Git when this section was written:** the root repo had uncommitted documentation changes:

- `AGENTS.md`, `CHANGELOG.md`, `PLAN.md`, `PROCESS.md`;
- the plan and the session plan;
- the new audit file.

Check `git status` before starting.

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

Current run (2026-10-11): owner confirmed continuing after connection checkpoint. Normal IDE Core 6.2.0 build/upload PASS; host tests PASS. Board model read by owner: T-Display-S3, PCB revision unknown. Basic LCD/animation/buttons passed by owner observation. A false PSRAM warning was fixed in firmware diagnostics and the corrected build uploaded; Flash 16 MiB, PSRAM chip 8 MiB confirmed. More than 10 minutes of stable diagnostics passed; owner confirmed RST/USB startup and buttons with Monitor closed. PCB revision/final P07 review remain open; see [physical run](docs/roadmap/M01-bring-up.md#build-upload-and-physical-run--2026-10-11). Root HEAD remains `3dda411`, firmware HEAD `be5829d`; firmware now has uncommitted diagnostics/README changes, parent handoff docs uncommitted. Mobile/backend unchanged; no commit/push. Firmware gitlink still points to committed `be5829d`, not the uncommitted uploaded fix.

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

> Read AGENTS.md, then PROCESS.md §0 "Start here", then docs/roadmap/XUNA_SESSION_PLAN.md (§2 rules, §3 map, and the entry of the next session), and only the cited sections of docs/architecture/XUNA_IMPLEMENTATION_PLAN.md. Check the latest CHANGELOG.md entries. Inspect root and submodule Git.
>
> Current state:
>
> - Planning is complete. The owner approved D1, D7, D12, D14 and D17 on 2026-10-12.
> - No M04 code has started.
> - Local MVP physical acceptance (MVP-07) is pending.
>
> The next sessions are S02 → S00 → S01 unless PROCESS §0 says otherwise.
>
> Working rules:
>
> - Ask the owner before starting a session.
> - Follow that session's preconditions, steps and done criteria.
> - Never put refactored or storage-changing firmware on the owner's board before S01 and a verified NVS backup.
> - Report in Vietnamese.
> - Commit only on request, as single-line conventional messages with no AI attribution.
> - Keep Clean/GetX and the pinned firmware baseline.
> - The simulator requires `XUNA_SIMULATOR=true`.
> - Do not infer validation from commits or builds.

## Mobile base update — 2026-10-11

Owner explicitly confirmed retaining the imported Clean/GetX architecture for future mobile work. Scoped cleanup removed login/product-detail demos, province data/mappers, old backend URL and business-specific locale/constants; splash/home and generic core/shared infrastructure, packages and generators remain. Package/labels renamed to XUNA; network clients require explicit base URLs and are not initialized at startup. Mobile remains uncommitted at HEAD `310e69f`; no gitlink update or M02 implementation. Analyzer PASS after dependency resolution; no native build/device validation claimed for this final cleanup. Earlier minimal-scaffold results do not apply. Firmware changes and M01 status remain unchanged.

## M02 inspection — 2026-10-11

All repositories verified on dev; HEADs unchanged (root 3dda411, firmware be5829d, mobile 310e69f, backend 0032828). Root/firmware/mobile dirty; backend clean. No child edits, build/upload, commit/push or gitlink change during proposal work. Flutter 3.32.8/Dart 3.8.1, Xcode 14.2, booted iPhone 13/iOS 16.2 simulator, PlatformIO 6.2.0 and board USB detected. No real phone detected. Protocol/library trade-offs and future validation matrix are recorded in M02 proposal, all Proposed. Historical M01 snapshots above retain their original context; this current section supersedes older claims that mobile is unchanged or M02 must wait for M01 validation.

## Mobile simulator delivery — 2026-10-11

Owner approved proposal and explicitly requested simulator-first mobile commit/push. Mobile commit `24026b2` pushed successfully to `origin/dev`; mobile working tree clean. Includes previously uncommitted approved Clean/GetX base plus fake M02 feature/tests. Analyzer/4 tests/native simulator build PASS; flutter run opened Home on iPhone 13/iOS 16.2, screenshot inspected. Full interaction flow exercised in widget test, not native automated taps. CocoaPods locale failure fixed by command-local UTF-8 environment. No BLE dependency/physical adapter or firmware change in this slice. Root remains 3dda411 with uncommitted docs and changed mobile working HEAD; root gitlink remains 310e69f until an explicitly requested root commit. Firmware HEAD be5829d with earlier dirty changes preserved; backend clean. Physical BLE, Android native build and M01 PCB revision/P07 remain open.

## Local MVP implementation — 2026-10-11

Owner approved local MVP through M05, board ownership of state/memory/preference and template-based text without LLM. Firmware adds bundled BLE, LifeEngine, two-slot NVS snapshots, bounded confirmed feedback episodes and local learned quiet routine; mobile adds physical BLE repository, request correlation and learning/text/memory UI while retaining Clean/GetX. Simulator is explicit via XUNA_SIMULATOR=true; real transport is default. Flutter analyzer/10 tests/simulator build/run and host core/life tests with life sanitizers PASS. See local MVP record for exact scope, protocol extensions and unverified physical cases. Existing root/firmware changes preserved; new work is uncommitted. HEADs remain root3dda411/firmwarebe5829d/mobile24026b2/backend0032828. No new commit/push; previous mobile simulator commit remains published. Old Proposed/device-ownership snapshots above are historical and superseded only for the owner-approved local MVP.

## Uploaded board checkpoint — 2026-10-11

LILYGO now runs corrected 0.2.0-mvp; build/upload/hashes PASS, 22-second startup diagnostics captured; owner confirmed LCD and both buttons. Fixed first-boot NVS missing-key noise by isKey checks and reuploaded; corrected log clean. See MVP record for measured resource figures and limits. Physical iPhone BLE/learning/reboot persistence and M01 PCB revision/P07 remain pending. Owner now explicitly requested commit/push of current code; deliver child commits before root gitlinks.

## Current Git delivery — 2026-10-11

Owner requested publishing current code. Firmware `be58099980a316a5ebfe8e621fe68a31eb8dcff6` and mobile `3846880ea3fb3a2cc26f5b41469f62a1f7d85316` committed and pushed successfully to their origin/dev branches; both child working trees clean. Root snapshot commit containing this section records both updated gitlinks and all scoped handoff documents. Backend remains `0032828`, unchanged. This delivery supersedes historical uncommitted/old-pointer snapshots above. No force push, reset or unrelated repository edits. Physical iPhone BLE/learning/NVS acceptance and M01 PCB revision/P07 remain pending.

## Technical plan proposal — 2026-10-12

Submodules were initialized at the recorded gitlinks; nothing changed in the children.

Added [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md), status **Proposed / planning only**. It integrates spec v0.3.0 §23–24 and the read-only ePet/Xiaozhi audits.

No code changes and no build, test, commit or push. The plan does not approve any slice.

Next action: the owner reviews decisions D1–D13, at minimum D1, D2 and D7. Then complete M04.0, which includes the pending MVP-07 physical acceptance, committing the spec, and ADR-0001. Only after that, start M04.1 if approved. MVP physical acceptance and M01 PCB revision/P07 remain open.

Session breakdown (2026-10-12): [XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md) splits the plan into sessions S00–S46 and assesses readiness. The plan was amended for three things:

- `bootc` uses its own NVS key;
- snapshot v2 is sectioned;
- TimeSync wiring happens after the command handler moves into the core.

Environment observed on this Windows machine:

- Flutter 3.41.1 via fvm (the project recorded 3.32.8);
- no PlatformIO, no host C++ compiler, no real Python;
- WSL has no distribution.

Recommended next sessions: S00 (toolchain and baseline), then S02 (decisions D1, D2, D7, D12 and ADR-0001), then S01 (MVP physical acceptance).

## Plan audit — 2026-10-12

Reviewed the plan against the owner-forwarded external checklist; report in [XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md). There were 17 findings, none Critical.

Main corrections, all **Proposed**:

- Conversation Foundation (Layer A) now develops together with M05a through the v1-additive opcode 6 `StatedPreference`, with joint acceptance S28. Personal facts stay in Layer B after M05b (D17).
- D2, D10 and D11 are decided after their experiments; D11a only authorizes the E12 spike.
- The Flutter SDK pin is decision D14. There is no `.fvmrc`; the lock requires Flutter ≥ 3.27.0. 3.32.8 is evidence only, not an approval.
- The NVS backup now verifies the partition table read from the device.
- S01 captures observed v1 bytes as the refactor baseline.
- S08, S12 and S19 are split into a/b sessions.
- Power-cut tests use write-storm builds.
- M05d versus an Evolution MVP is decided at checkpoint S42a (D15).

Approved decisions are unchanged. No firmware, mobile or backend change; no build, test or flash; no commit or push.

Next: S02 → S00 → S01.

## Owner decisions — 2026-10-12

The owner approved:

- **D1:** complete M04 (S03–S21) before new M05 features.
- **D7:** a pet hatches on the device (local gesture) **or** via the app (opcode 7). `bornAt` is exact only with trusted time in the hatch boot; otherwise it stays unknown. The existing MVP pet migrates as Newborn.
- **D12:** C++11 core.
- **D14:** pin Flutter 3.32.8 via `mobile/.fvmrc`.
- **D17:** Conversation Layer A with M05a, text-first; Layer B after M05b; voice still depends on D16.

These are recorded in AGENTS.md §3 and plan §18. The plan (§12, §8.2, §14.1) and sessions S02, S06 and S10 were amended accordingly.

Still open:

- D2, after S11; D10, after S35; D15, at S42a;
- D3–D6, D8, D9, D11a/D11, D13 and D16.

No code changes and no commit or push.

Next: S02 (ADR-0001 + decisions index) → S00 → S01.

## Device-first documentation update — 2026-10-12

Owner requested architecture/roadmap documentation only. Approved long-term direction: physical XUNA is primary; Flutter assists; optional cloud never owns life state. A5 local MVP and D17 text-first are retained. Proposed ADR-0006, D18–D20 and VOICE-01–04 require evidence/approval; no voice scope silently added. See [architecture](docs/architecture/XUNA_DEVICE_VOICE_ARCHITECTURE.md) and session plan §9.

Before edits root/firmware/mobile/backend were clean; child HEADs remain be58099/3846880/0032828. This session runs on `/Users/xthao28/xuna_pet` (Mac path); historical Windows tool availability is not a current toolchain check. No SDK install, code/config/dependency change, build/test, flash, wiring, commit/push or gitlink change. Validation is documentation-only: diff/whitespace, local Markdown references, session/decision consistency, changed-path and unchanged child checks.

Next remains **S02 → S00 → S01**. S02 has a prepared index but ADR-0001 is still pending; it is not Done. S00 remains the next coding/toolchain preparation session, with machine/tool availability rechecked rather than copied from historical Windows notes. S01 physical acceptance and verified NVS backup remain mandatory before refactored/storage-changing uploads. Voice does not block M04 or M05a. D15 stays at S42a.

Documentation verification results: `git diff --check` PASS; scripted relative Markdown path check PASS; all 54 existing session-map rows/dependencies identical to HEAD; no duplicate detailed session IDs; changed/untracked paths are Markdown only; root gitlinks unchanged and all child working trees clean. Builds/runtime tests were not run because implementation was untouched.

## S02 documentation delivery — 2026-10-12

Owner requested incremental execution. Decision index and Proposed ADR-0001 now exist; S02 documentation done criteria are met. ADR acceptance remains pending, no decision silently approved. Preserved prior uncommitted documentation. Corrected T14 table to match separately gated voice research; no implementation/dependency/hardware changes or commit/push. Next: S00 environment and baseline verification on the current Mac.

## S00 — Development environment and baseline (2026-10-12)

Current work machine: owner's Mac at `/Users/xthao28/xuna_pet`, authorized by incremental execution request; existing macOS compiler replaces the historical Windows MSYS2/WSL setup choices. VS Code extension `platformio.platformio-ide` is installed. PlatformIO Core 6.2.0 at `~/.platformio/penv/bin/pio` (not on shell PATH); Apple Clang 14.0.0; FVM 3.2.1; Flutter 3.32.8 / Dart 3.8.1. Added `mobile/.fvmrc` per approved D14, no SDK/dependency upgrade or global SDK change.

| Check actually run | Result |
|---|---|
| `c++ -std=c++11 -Wall -Wextra -Werror -Ifirmware/include firmware/test/test_core.cpp -o /tmp/xuna-s00-core` + binary | PASS |
| Same flags for `test_life.cpp` + binary `/tmp/xuna-s00-life` | PASS |
| `~/.platformio/penv/bin/pio run -d firmware -e xuna_t_display_s3` | PASS; static RAM 47,504 B; image 964,333 B — matches recorded baseline |
| `fvm flutter pub get` (mobile) | PASS; existing versions resolved, lock unchanged |
| `git -C mobile diff --exit-code -- pubspec.lock` | PASS, no diff |
| `fvm flutter analyze` (mobile) | PASS, no issues |
| `fvm flutter test` (mobile) | PASS, 10 tests |
| `pio device list` | No ESP32 USB device detected |
| `xcrun xctrace list devices` | Mac and iOS simulators only; no real iPhone |

S00 is complete. S01 awaits board USB and a real phone; no verified NVS backup, BLE transcript, physical acceptance, upload or power-cut work performed. Session rules require stopping S01 when hardware prerequisites are missing. S03–S05/S07 remain eligible host-only follow-ups, but no M04 code session started in this preparation run.

Git: previous root documentation edits preserved; new ADR-0001 draft and handoff changes uncommitted. Mobile has only new `.fvmrc`; firmware/backend clean; parent gitlinks unchanged. No commit/push. Next: connect board and real phone for S01; ADR-0001 remains Proposed until explicitly accepted.

## S01 partial — ESP32-only preparation (2026-10-12)

Owner deferred real-phone acceptance and requested ESP32 work first. Device detected at `/dev/cu.usbmodem14101` (Espressif USB 303A:1001). Serial inspection caused USB/UART reset; boot reports XUNA 0.2.0-mvp, 16 MiB Flash and 8 MiB PSRAM. Chip read by esptool: ESP32-S3 silicon revision v0.2; this is **not** the unknown PCB revision. Two idle diagnostic windows: render averages 3507/3491 us, maxima 3693/3527 us; loop-gap maxima 4543/3540 us. This brief observation is not stability or BLE acceptance; LCD was not visually confirmed in this session.

Read actual partition table with esptool 4.5.1 (`read_flash 0x8000 0xC00`); decode verified NVS at 0x9000/0x5000 and complete table matches current build. Read NVS (`read_flash 0x9000 0x5000`), verified file length 20,480 B and recorded SHA-256. Backup files and manifest are outside the repositories at `/Users/xthao28/xuna_backups/2026-10-12-s01/`. Table SHA-256: `bd0f7954aca2ef7d925ee21aaa1f3dc8822d1d6ce5cbbd26a135e5886bfff6ce`; NVS SHA-256: `f941a8b3398788301c87902e293c8ab8ab6dc629f5b47d8946f1e05787f7e822`. Restore was not tested; no erase/write_flash/firmware upload, pet commands or power-cut tests. Flash reads reset the board; esptool's temporary RAM stub does not replace installed firmware.

S01 remains **In progress — phone-dependent acceptance deferred**. BLE transcript/feedback/reboot/forget and owner visual checks are unvalidated. Backup does not waive S01 gates on S06/S09/S13 etc. S11 additionally needs S04 and owner-operated power-cut evidence. Eligible next firmware work without phone: S03 → S04, then S05/S07; these run on host, with board build verification where specified, and no refactored firmware upload before S01 acceptance. No later session implemented in this partial run; code/submodule state unchanged.

## S03 complete — firmware first / Android later (2026-10-12)

Owner selected Android for future app acceptance and requested the next ESP32/firmware step. S03 is Done; evidence in [S03 record](docs/roadmap/S03-v1-characterization.md). Three frozen host snapshot fixtures and characterization tests added; production code/config unchanged. New tests PASS with C++11/-Werror; all three host suites PASS with ASan/UBSan; ESP32 build PASS at unchanged 47,504 B RAM / 964,333 B image. No upload, runtime interaction, commit/push or gitlink update.

Current firmware working tree contains uncommitted test fixtures/test/README changes. Previous root documentation and mobile .fvmrc preserved. Next S04, then S05/S07 host work as appropriate; S01 remains a gate on later board refactor/storage uploads. Phone path is Android (owner-selected), not iPhone; no Android native/physical BLE success claimed.

## S04 — Portable core delivery (2026-10-12)

[Evidence and changed paths](docs/roadmap/S04-portable-core.md). Five pure headers moved under firmware/lib/xuna_core/include/xuna without production logic changes; BoardConfig/CoreConfig split, Unity suites and native/native_asan environments added. Firmware tools/check_core_purity.py runs for every environment. Native and sanitizer runs PASS (8/8 each); ESP32 build PASS, unchanged RAM 47,504 B / image 964,333 B. Native 1.2.1 and Unity 2.6.1 installed by PlatformIO for this test setup; firmware pins/partitions unchanged.

Current commands: `~/.platformio/penv/bin/pio test -d firmware -e native` / `-e native_asan`; build with `pio run -d firmware -e xuna_t_display_s3`. Earlier manual test paths in historical sections no longer exist after this move. Core library has no Arduino dependencies. Mobile's earlier .fvmrc and all previous root/S03 edits retained; no new mobile/backend work. Firmware refactor is uncommitted; parent gitlink unchanged. No flash/upload or physical acceptance.

Next S05 (pure fixed-point/RNG/ClockModel); S07 also eligible after S04. Device for future app validation is Android. S01 remains partial and required before refactored/storage-changing board uploads.

S04 negative guard check: PASS in native, native_asan and ESP32; temporary Arduino.h include removed. Clean build after restoration PASS.

## S05 — Foundation primitives complete (2026-10-12)

Owner resumed work after reporting board warmth under Mac USB power. S05 ran entirely on host; no serial/flash/board operation or thermal measurement. [Detailed contracts/evidence](docs/roadmap/S05-foundation-primitives.md): fixed-point Q0.16/Q16.16 arithmetic with saturation/rounding; deterministic Pcg32/IRandom with official vectors; ClockModel with unknown-on-boot, rollback protection, quality/day-part logic and 64-bit monotonic inputs. Defaults 24 h/5 min remain Proposed tuning values. PCG adaptation is Apache-2.0, with notice/license and exact source SHA recorded in firmware README.

Tests-first missing-header build failure observed; then all native and native_asan suites PASS (12/12 each). ESP32 cross-compile smoke for all new headers PASS; normal ESP32 build/purity guard PASS at unchanged 47,504 B RAM / 964,333 B image. Primitives are not wired into firmware yet; no host-target runtime parity or physical acceptance claimed. Root/firmware whitespace checks and updated document paths PASS.

Next prefer S07 since it requires S04 only and is fully host-side; this is allowed by the existing session map, not a milestone reorder. S06 pure identity work is eligible but its full completion includes gated board steps (S01). Android app work stays deferred. Firmware/root changes remain uncommitted, mobile has only prior .fvmrc, backend unchanged; no gitlink update or push.

## S07 — Event foundation complete (2026-10-12)

Owner requested a plain-language overview before each session; rule recorded in AGENTS §10 for future sessions. [S07 evidence](docs/roadmap/S07-events.md): 25-kind registry with compile-time uniqueness, in-RAM event envelope, fixed-capacity ring, no-wrap boot/sequence IDs and bounded queue with explicit critical rejection and drop counters. No persisted codec or firmware wiring.

Tests-first failure for missing header, then new tests PASS. Full native and native_asan regression PASS, 18/18 each; Xtensa compile smoke PASS; ESP32 build/purity guard PASS at unchanged 47,504 B RAM / 964,333 B image. Existing upstream warnings unchanged. No board/serial/Flash operation, app change, commit/push or gitlink update; earlier edits retained.

Open finding: S05 ClockModel currently returns Unix-epoch minutes while event/plan §7.1 specifies minutes since 2020. Models are not wired; do not assign between them yet. Next focused S05-fix-01 corrects the internal conversion and tests before identity/time-event integration, without changing deployed protocol/state. Then continue eligible firmware sessions; S08a requires S01 observed bytes, and S06 board steps remain gated. Android app work remains deferred.

## S05-fix-01 — Compact time epoch corrected (2026-10-12)

[Fix record](docs/roadmap/S05-fix-01-time-epoch.md). ClockModel compact minutes and persisted watermark now use the planned 2020 epoch; UTC milliseconds remain Unix. Reboot still yields unknown time; watermark conversion and u32 range checks are consistent. The S07 integration finding is resolved, with no deployed state or BLE protocol migration (new clock remains unwired).

Tests-first regression failed against the old implementation, then native and native_asan PASS 19/19 each; no sanitizer diagnostics. Pinned Xtensa compile-only smoke PASS; ESP32 build/purity PASS at unchanged 47,504 B RAM / 964,333 B image. Whitespace/link checks PASS. No serial/Flash operation, upload, app change, thermal measurement, commit/push or gitlink update. Previous uncommitted edits retained.

Next S06 pure identity/hatch/migration work; board tests/NVS writes remain pending S01 Android acceptance and backup gate. Do not infer physical identity/persistence validation from host-only delivery.

## S06 partial — Pure identity/hatch/migration (2026-10-12)

[Scope and codec layout](docs/roadmap/S06-identity-core.md). CRC32, explicit 64-byte IdentityRecord and pure IdentityService implemented. Core stages candidates separately from successful storage acceptance; retains existing identity, never regenerates corrupt/too-new data, migrates valid MVP snapshot identity with birth unknown, and backfills birth only from Synced time in the hatch boot. Service does not change old learning/lifetime state. Hardware entropy/committed boot-counter come from future adapter, not this core.

Tests-first missing-header failure observed; native/ASan/UBSan full regression PASS 23/23 each. Xtensa compile smoke and ESP32 target build/purity PASS; unchanged 47,504 B RAM / 964,333 B image. Whitespace and local-link checks PASS. No board/Flash/serial operation, upload, app edit, commit/push or gitlink update; previous changes preserved.

S06 remains In progress: StorageKeys, bootc persistence, radio/RNG adapter, gesture/egg rendering, isolated namespace and board checks not implemented/run. S01 physical baseline still gates board steps. Next eligible S14 ActivityFsm (S07 prerequisite met); this does not satisfy S10/S12 dependencies on full S06. Android app work remains deferred.

## S11 preparation — isolated benchmark and restore (2026-10-12)

Owner requested S11. [E4/E5 record](docs/research/E4-E5-storage.md) contains concrete external source/config paths and pending measurement gates. Benchmark project /Users/xthao28/xuna_experiments/s11-storage built PASS (159,840 B static RAM / 365,053 B image); original-MVP restore project s11-mvp-restore built PASS (47,504 B RAM / 964,333 B image). Source uses committed be58099 display/config, not uncommitted refactor. Nothing merged into firmware. Runtime sample buffers add 120 KB static RAM; no BLE coexistence or wear claim.

Correction to earlier recommendation: S11 itself lists S04+backup, but global session rule §2.3 and cleanup baseline require S01 for storage-changing upload. Preparation is possible now; runtime requires S01 or explicit owner exception after reviewing isolated scope/backups/restore. No exception was silently recorded. USB device listing currently shows no ESP32. Fresh verified NVS/full-image backup required before filesystem experiment. Old backup alone is insufficient to validate new writes/restoration.

Draft ADR-0002 created, Proposed, no layout option/D2 approved. Serial-controlled NVS/FS benchmarks and storms/recovery are build-checked only; no format/flash/readback/cuts performed. Both current repositories and earlier uncommitted changes preserved; no source edit inside firmware in this preparation, commit/push or gitlink update. Source/firmware artifact hashes in external artifact-manifest.json. Documentation whitespace/local-link checks PASS. S11 In progress, E4/E5 unmeasured.

## Static pet UI — owner-requested priority (2026-10-12)

Owner paused S11 and requested direct reference-image UI in firmware, including upload when connected. [Static scene record](docs/roadmap/UI-static-scene.md) contains complete configuration, generation, validation and file paths. Source preserved, nearest-neighbor contain conversion to 320×170, no crop; RGB565 108,800 B in Flash. Display uploads image once, no loop repaint or sprite buffer; life/BLE/storage logic unchanged. Existing toolchain/pins/rotation retained, PCB revision unknown.

Build PASS: RAM 46,072 B (−1,432), image 1,062,793 B (+98,460). Deterministic generation/Flash ELF placement and native 23/23 PASS. Board appeared again; fresh actual-table comparison/NVS backup PASS, then owner-authorized UI upload PASS. Startup draw 31,663 us; 25-second serial observation with no spontaneous reset/error. Owner confirmed “Ảnh đúng, màu đúng, ổn định”. NVS after upload equals backup byte-for-byte. Full-image benchmark/format/power-cut work was not run. Backup/log outside repo in xuna_backups/2026-10-12-static-ui.

Current board runs static UI from the uncommitted working tree (includes prior portable core extraction). No persistence format changes; S01 app/BLE full acceptance remains pending and is not satisfied by visual confirmation. S11 remains paused, not completed; no benchmark exception granted. No commit/push/gitlink update. Mobile/backend unchanged in this session. Next UI work only on owner request; no automatic resume of paused S11.

## Animated UI and Git delivery — 2026-10-12

Owner requested room/pet palette redesign, independent idle/blink/wiggle and upload, then provisionally accepted final corrected version and requested committing today's work. [Animated UI record](docs/roadmap/UI-animated-scene.md) has current assets, implementation and physical evidence. Initial art/motion feedback incorporated; subsequent torso-foot seam and missing dark tips fixed with overlapped layers/immutable foot pieces/explicit tip color.

Final assets: 320×170 background plus 20 fixed 96×72 frames, 385,280 B in Flash; one 13,824 B startup region buffer. Pet visible height 65 px (~38%). No frame allocations/delay; palette masks/seam checks PASS. Native and ASan/UBSan 25/25 PASS; final build/upload PASS at RAM 46,144 B / image 1,340,569 B. Final 25-second log: draw max 4,754 us / loop gap max 4,767 us, stable heap, no spontaneous reset/error. GPIO0 Happy observed in v2 log; GPIO14 full physical check not separately logged. Owner: “tạm thời đã ổn có gì cần sửa tôi sẽ nói sau”. Not long-run/thermal/BLE validation.

NVS differs only in the newest valid snapshot generation/active-lifetime checkpoint (4/1200 → 5/1500); learning/episodes unchanged. Fresh partition/NVS backups and raw logs remain outside Git under xuna_backups/2026-10-12-animated-ui. S11 remains paused; source-only benchmark archive now versioned under docs/research/artifacts, no experiment performed.

Authorized Git delivery (no push): firmware **c84d4e3** contains today's core/tests/assets/UI; mobile **77d27ec** contains approved Flutter pin. Parent commit containing this entry records updated gitlinks and all today's root docs/research source archive. Backend unchanged. ADR-0001/0002/0006 remain Proposed; committing drafts does not accept them. S01 Android/full S06 and later M04 integration remain open. Earlier historical “uncommitted/not uploaded” entries describe their original sessions; this section is the current delivery.

## Mobile coding rules — 2026-10-13

Owner requested Clean Architecture coding rules for `mobile/`, based on the existing GetX base, to be read before any feature work. Added `mobile/AGENTS.md`, `mobile/docs/FEATURE_TEMPLATE.md` and `mobile/CLAUDE.md`; linked from `mobile/README.md`, root `CLAUDE.md` and AGENTS.md §9. The rules record current deviations in `features/device` and `features/home` (repository called from the controller, mixed data source/repository, hardcoded UI text, simulator as a fake repository) without refactoring them; a dedicated refactor session is not scheduled and needs owner approval.

Template code compiled and tested in a scratch copy only (Flutter 3.41.1: analyze no new issues, 14/14 tests, format clean); not run on the pinned 3.32.8. Mobile source, tests and dependencies unchanged. Mobile and root changes are uncommitted; gitlinks unchanged. No build, device or board operation.

Open item (resolved below): `mobile/pubspec.lock` was modified at 11:28 by pub from Flutter 3.41.1 / Dart 3.11.0, not by this session's commands (most likely an automatic IDE `pub get`; 3.32.8 was not installed on this Windows machine). Per D14 this lock must not be committed.

## Mobile toolchain fix and Clean Architecture refactor — 2026-10-13

Owner approved the recommended lock fix and the proposed refactor session, after adding a base widget rule to `mobile/AGENTS.md` §5.4: a base widget is mandatory once UI repeats across screens, existing base widgets must be used, and none exist yet because there is no XUNA design.

Toolchain: `fvm install 3.32.8` (Dart 3.8.1) succeeded. A machine-local `.vscode/settings.json` at the root sets `dart.flutterSdkPath` to that SDK and is ignored through `.git/info/exclude`, not `.gitignore`. Reload the VS Code window so the Dart extension stops using 3.41.1. `mobile/pubspec.lock` was restored from HEAD; `fvm flutter pub get` left it unchanged. Baseline before the refactor on 3.32.8: analyze clean, 10/10 tests.

Refactor (mobile, uncommitted), with no protocol, UUID, timeout or learning-rule change:

- `device` split into domain entities, an `abstract interface` repository, `DeviceException` kinds and ten use cases. Data now has wire models, explicit enum↔code mappers, `ProtocolCodec` in `data/codec`, `ResultCorrelator`, the `DeviceBleDataSource` contract with the FlutterBluePlus implementation and `SimulatorDeviceBleDataSource` (a fake transport, replacing the fake repository), and `DeviceRepositoryImpl`, which translates every error.
- `conversation`: `TextIntent` entity and `ParseTextIntentUseCase`.
- `home`: the controller uses only use cases with `buildState`. The page is split into feature widgets and uses locales (generated with get_cli), tokens and `nav.showConfirmDialog` for forget. The feedback pending-suggestion pre-check moved to `SendFeedbackUseCase`.
- Visible differences: localized error messages replace raw `e.toString()`; animation labels are capitalized; active time shows "giây"; the forget dialog uses the base confirm dialog style; text uses `AppTextStyle`; the simulator now rejects feedback whose target is not the pending suggestion (result 4).

Validation on Flutter 3.32.8 (Windows): `fvm flutter analyze` no issues; `fvm flutter test` 16/16 PASS. The 10 previous tests were ported to a layout that mirrors `lib/`, and 6 were added: error translation, stream mapping, explicit codes, feedback pre-check, controller error messages and forget confirmation. A rules audit by grep found no hardcoded UI strings, relative imports, `enum.index` wire use, direct dialogs or presentation→data imports. The feature template was re-verified on 3.32.8 in a scratch copy. Not run: native Android/iOS build, simulator/device app run, real phone BLE, board. Real BLE adapter logic was ported line by line but is unvalidated physically, as before.

Known gaps are listed in `mobile/AGENTS.md` §11: the simulator learner copy (S20), the route-scoped device repository, any stream error marking the UI disconnected (MVP behavior kept), and the inherited palette. Mobile and root changes are uncommitted; gitlinks unchanged.

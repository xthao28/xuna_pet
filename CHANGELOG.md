# XUNA — Change and Session History

Last updated: **2026-10-13** (Asia/Ho_Chi_Minh).

This file records work actually performed, including uncommitted changes, validation and handoff updates. Entries are not evidence that a Git commit or release exists. Read [PROCESS.md](PROCESS.md) for the current snapshot and [PLAN.md](PLAN.md) for remaining work. AGENTS.md remains canonical for decisions.

## 2026-10-13 — Mobile toolchain fix and Clean Architecture refactor

- Owner approved restoring the lock with the pinned SDK and a refactor session, after adding a base widget rule (`mobile/AGENTS.md` §5.4: mandatory when UI repeats across screens, mandatory to use when one exists; none exist yet).
- Installed Flutter 3.32.8 via fvm; machine-local VS Code setting points to it (ignored via `.git/info/exclude`). Restored `mobile/pubspec.lock`; `fvm flutter pub get` keeps it unchanged.
- Refactored mobile `device`, `conversation` and `home` to the rules without protocol change: domain entities/contract/exceptions/use cases, wire models and explicit mappers, BLE data source contract with real and simulator implementations, repository error translation, use-case-only controller with `buildState`, localized strings via get_cli, feature widgets and `nav` confirm dialog. Rules gained clarifications found while applying them (cross-feature UI vocabulary, `codec/`, `AppTextStyle` maxLines, inline loading, test helper imports) and an updated §11 of known gaps.
- Validation on 3.32.8: analyze clean; 16/16 tests (10 ported, 6 new). No native build, app run, phone or board operation. No commit or push.

## 2026-10-13 — Mobile coding rules (documentation only)

- Owner requested Clean Architecture coding rules for `mobile/`, derived from the existing GetX base, that agents read before writing any feature.
- Added `mobile/AGENTS.md` (layer dependency rule, folder/naming conventions, domain/data/presentation rules, DI scopes, XUNA invariants, testing, toolchain, Definition of Done, and an inventory of current code that predates the rules), `mobile/docs/FEATURE_TEMPLATE.md` (feature skeleton) and `mobile/CLAUDE.md`. Linked from `mobile/README.md`, root `CLAUDE.md` and AGENTS.md §9.
- Template validation: the skeleton code, added to a scratch copy of mobile outside the repository, passed `flutter analyze` with no new issues, 14/14 tests (10 existing + 4 template) and `dart format`. Run on Flutter 3.41.1, the only SDK on this machine, not the pinned 3.32.8.
- No change to mobile source, tests or dependencies. Existing legacy deviations are documented, not refactored. No commit or push.
- Found `mobile/pubspec.lock` modified at 11:28 by pub from Flutter 3.41.1 / Dart 3.11.0 (`.dart_tool/package_config.json`), outside this session's commands, most likely an automatic IDE `pub get` (3.32.8 is not installed here). Changes include `analyzer` 6.11.0 → 6.4.1 and removal of `_macros`. Not committed; restored in the next entry.

## 2026-10-12 — Device-first Conversation direction (documentation only)

- Recorded owner's requested long-term device-first / Flutter-assisted direction; preserved accepted local MVP and D1/D7/D12/D14/D17. Voice implementation and D15 ordering remain unapproved.
- Added device voice architecture, feasibility/trust/failure contracts, Proposed ADR-0006 and decision index (ADR-0001 remains pending S02).
- Plan 0.1.2/session rev. 3: source-independent Foundation alongside M05a; S39 remains Foundation, S40–S42 extend it; separate Proposed VOICE-01–04 and D18–D20. No current session reorder: S02 → S00 → S01.
- Updated product spec, audit follow-up, canonical instructions and handoffs. Preserved historical implementation and hardware acceptance evidence.
- Validation PASS: `git diff --check`, local Markdown paths, 54 unchanged session-map rows/dependencies, no duplicate detailed session IDs, Markdown-only changed paths and clean submodules/unchanged gitlinks. No build/runtime test, source, dependency, hardware operations, commit or push.

## 2026-10-12 — Owner decisions D1, D7, D12, D14, D17

- The owner chose among the presented options and picked the recommended option for all five.
- D7: the local-first hatch variant (on the device or via the app) instead of app-only hatch.
- Recorded in AGENTS.md §3 (Approved) and plan §18.
- Amended plan §12 (Egg state, device gesture, opcode 7 `Hatch`, same-boot `bornAt` rule), §8.2 and §14.1.
- Session plan: S02 reduced to ADR-0001 and a decisions index; S06 (Egg/hatch logic, test-only fresh-device namespace); S10 (opcodes 5 and 7, app hatch flow).
- Audit report section D notes the update.
- No code, build, commit or push.

## 2026-10-12 — Plan audit (documentation only)

- Owner forwarded an external review checklist and asked for a re-check, adopting points only where they are technically and product-wise sound.
- Added [docs/architecture/XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md): 17 findings (no Critical), milestone flow, decision register and over-engineering review.
- Plan updated to 0.1.1:
  - Conversation Layer A/B with the opcode 6 contract (§11.6);
  - AI technique taxonomy (§5.6);
  - instructed vs learned evidence;
  - D2/D10/D11 timing, D11a and new D14–D17;
  - E13 and risks R13/R14;
  - corrected A9 scope and T18 rollback facts, verified against Arduino-ESP32 2.0.14 sources.
- Session plan updated to rev. 2:
  - dependency fixes (S13, S17, S18, S02, S22, S29) and splits S08a/b, S12a/b, S19a/b;
  - new S24a, S27a, S27b (optional) and S42a;
  - verified NVS backup procedure;
  - S01 observed-byte baseline and write-storm power-cut method.
- Verification: cross-reference check of session/decision/experiment IDs and relative links; `git diff --check`. Submodules unchanged (firmware `be58099`, mobile `3846880`, backend `0032828`, clean). No build, test, flash, commit or push.

## 2026-10-12 — Technical implementation plan (planning only)

- Request: the owner asked to clone all submodules, then to produce a technical implementation plan from AGENTS.md and spec v0.3.0 (§23 Cognitive Development, §24 ePet/Xiaozhi references), without implementing code.
- Submodules: `git submodule update --init --recursive` checked out the recorded gitlinks: backend `0032828`, firmware `be58099`, mobile `3846880`. No gitlink or child changes.
- Plan: added [docs/architecture/XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md), status **Proposed**. It contains:
  - repository inventory and gap analysis G1–G23;
  - target architecture;
  - 19 technique cards (ePet T1–T9, Xiaozhi T10–T19);
  - data model, state machines, and the learning, memory, conversation and time designs;
  - independently testable slices M04.0–M07;
  - experiments E1–E12, a resource budget, risks R1–R12 and owner decisions D1–D13.
- Upstream sources were read only from shallow clones in the session scratchpad; nothing was built or executed:
  - ePet `347ceaf` (MIT);
  - xiaozhi-esp32 `aef2ab0` (MIT);
  - xiaozhi-esp32-server `4576e39` (MIT).
- Verified the Arduino-ESP32 2.0.14 `default_16MB.csv`: NVS 20 KiB; unused `spiffs` partition 3.375 MiB.
- No build, test or upload was run. This Windows session has no `pio` or host C++ compiler in its PATH. No commit or push. The product spec remains untracked.
- Follow-up: added the session breakdown [docs/roadmap/XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md) (S00–S46, readiness assessment). Plan amendments: own `bootc` key, sectioned snapshot v2, TimeSync after the core command handler. Observed: Flutter 3.41.1 via fvm (recorded 3.32.8); WSL has no distribution.
- Owner requested committing the new documents. The spec, plan and session plan are now tracked in the root repository. Submodules are unchanged and nothing was pushed.

## 2026-10-11 — Publish local MVP checkpoint

- Owner requested commit/push of current code. Firmware `be58099` (`feat: implement local XUNA MVP life and BLE runtime`) and mobile `3846880` (`feat: add BLE learning and local text MVP companion`) pushed successfully to origin/dev, child working trees clean.
- Parent commit containing this entry records both gitlinks, owner-approved scope, simulator/software evidence and LILYGO corrected build/upload/startup/LCD/buttons evidence. Backend pointer/code unchanged.
- Final verification: Flutter analyzer and 10 tests PASS; host core tests PASS; life tests with ASan/UBSan PASS; staged whitespace checks PASS. Firmware build/upload evidence recorded in [local MVP](docs/roadmap/MVP-local.md).
- Physical iPhone BLE, board learning/reboot/power-loss/forget and long-run stability remain pending. M01 PCB revision/P07 still open. Next: real-phone acceptance, not a milestone-validation claim based on Git publication.

## 2026-10-11 — Local MVP implementation and LILYGO smoke

- Owner selected MVP through M05, approving device-owned local state/memory/preference and local text V1 without LLM. Kept Clean/GetX and pinned firmware baseline; no backend/voice/evolution/sensors.
- Firmware: BLE queue/versioned commands/status/capabilities/dedup; four sprite reactions; LifeEngine Beta/Bernoulli preference learning; bounded source-tagged feedback; two-slot checksummed snapshots and learned quiet routine. Mobile: physical BLE transport, result correlation/timeouts, simulator define, preference/memory/text consent UI and tests.
- Software verification: analyzer/10 mobile tests/simulator native build/run PASS; core host tests and life ASan/UBSan tests PASS. Preserve pending physical acceptance; see [MVP record](docs/roadmap/MVP-local.md).
- LILYGO requested build/upload PASS; observed first-boot missing NVS keys reported as errors, fixed with isKey checks; rebuild/reupload/22-second corrected startup PASS. Owner confirmed LCD and two buttons. Final linker RAM47504/327680, firmware964333/6553600; runtime details/limitations recorded separately.
- No physical iPhone BLE, learned board behavior, power-loss/reboot recovery or long MVP soak validation claimed. M01 PCB revision/P07 remain open.
- Owner subsequently requested publishing current code; child commits precede root docs/gitlinks. Git delivery record follows once child hashes are known.

## 2026-10-11 — Mobile simulator checkpoint committed and pushed

- Owner approved M02 proposal, then requested simulator-first mobile delivery with commit/push.
- Added DeviceRepository/RequestAnimation contracts, fake simulator data implementation, command/status codec and Home Clean/GetX UI for scan/connect/idle/happy/expiry/disconnect. Existing base/dependencies preserved; no physical BLE adapter/plugin yet.
- Validation: flutter analyze PASS; flutter test --reporter expanded PASS (4 tests including UI interaction flow); simulator debug build PASS; flutter run on iPhone 13/iOS 16.2 succeeded, rendered Home screenshot inspected. CocoaPods initially failed on locale; command-local UTF-8 rerun fixed it. Staged whitespace check PASS after trimming imported README whitespace.
- Mobile commit `24026b2` pushed successfully to origin/dev; child working tree clean. Includes previously uncommitted approved mobile base. Root/firmware changes preserved and uncommitted; parent mobile gitlink still 310e69f. Backend unchanged.
- Updated PROCESS/PLAN/M02 evidence; physical BLE and Android validation pending. M01 PCB revision/P07 remain open. Next: approved real BLE transport/firmware experiment, real iPhone validation.

## 2026-10-11 — M02 priority and BLE proposal

- Owner requested M02 while retaining M01 PCB revision/P07 limits; selected iOS with iPhone 13 simulator.
- Inspected requested handoff/source files and Git in all four repositories; branches/HEADs match handoff, existing changes preserved.
- Prepared [M02 proposal](docs/roadmap/M02-ble.md): UUIDs, versioned bounded binary messages, capabilities, correlation/errors, connection-local idempotency, timeout/reconnect, Clean/GetX integration and acceptance matrix. Library choices remain Proposed.
- Checked official library documentation and published archives/SDK constraints/licenses. No dependency or implementation changes; no build/tests/upload or physical BLE validation this session.
- Tooling: Flutter 3.32.8/Dart 3.8.1, Xcode 14.2, booted iPhone 13/iOS 16.2 simulator, PlatformIO Core 6.2.0, ESP32 USB present. Real-phone BLE pending.
- Updated AGENTS/PROCESS/PLAN priority and handoff; no commit/push/gitlink changes. Next: owner review, then scoped implementation and actual validation.

## 2026-10-11 — Scoped mobile cleanup preserving Clean/GetX

- Request/decision: owner clarified removal of unrelated feature screens/constants/prior branding, while retaining Clean architecture for future coding. AGENTS.md and PLAN.md updated to record the confirmed imported Clean/GetX direction.
- Changes: removed login/product-detail demos and related routes, province/login mappers and empty login test; startup opens Home XUNA. Retained generic core/shared base classes, dependencies, local/network infrastructure and generation tooling. Removed old endpoint; API clients now require explicit baseUrl and are not registered at startup. Removed old business-specific translations and unused response/Hive constants. Renamed Dart package and Android/iOS development identity/labels to XUNA; added mobile ignore rules/README.
- Validation: Flutter 3.32.8/Dart 3.8.1 pub get PASS, analyzer PASS; changed files formatted after sandbox Dart startup failure was resolved by outside-sandbox retry. iOS Info.plist syntax PASS. No final native build/device test or BLE implementation claimed.
- Git: mobile remains uncommitted/untracked imported work, child HEAD/gitlinks unchanged; firmware preserved, no commit/push. Original base archive remains in /private/tmp for recovery.

## 2026-10-11 — Restore owner's Flutter base

- Request: owner rejected the overly broad mobile cleanup and explicitly requested restoration.
- Result: restored all 165 files in the pre-cleanup archive `/private/tmp/xuna-mobile-template-20261011.tar.gz` and verified each file byte-for-byte against it; restored the original tracked mobile README from HEAD. Removed cleanup-only files/generated artifacts from the working tree by preserving them separately in `/private/tmp/xuna-mobile-cleanup-reverted-pdtikgl4`.
- Mobile status again matches the initial imported base: original GetX/core/shared layers, features, dependencies, assets, tests and Android/iOS settings retained as untracked additions. Earlier minimal-scaffold analysis/build attempts do not validate this restored base. No further cleanup authorized by this restoration.
- Git: firmware and other prior work preserved; no commit/push or submodule pointer change.

## 2026-10-11 — Inspect IDE Problems setup

- Request: investigate VS Code Problems before further work.
- Validation: normal IDE CLI `pio run -d firmware -e xuna_t_display_s3` PASS (2.95 seconds); no compiler errors in the incremental build. Direct VS Code Problems access unavailable; exact diagnostic messages requested from owner.
- Local IDE setup: `pio project init -d firmware --ide vscode --environment xuna_t_display_s3` generated previously absent, Git-ignored `firmware/.vscode` metadata with ESP32-S3 compiler, gnu++11 and forced Setup206 include. `platformio.ini` and source unchanged by this inspection. Root-folder VS Code may require opening firmware as its workspace to apply this metadata.
- Limits: no claim that visible Problems have cleared; awaiting actual messages/UI recheck. No upload, commit or push.

## 2026-10-11 — M01 upload and initial physical checks

- Request / tasks: owner confirmed continuation after connection checkpoint; P01/P03 done, basic P04 owner-confirmed; P05 and scoped P06 done; P02 revision/P07 remain open.
- Validation: normal IDE Core 6.2.0 build PASS, host C++ tests PASS, upload at 921600 baud PASS with hashes verified. Corrected image linker RAM 21,840 bytes, firmware 319,737 bytes. Startup confirms Flash 16 MiB and PSRAM chip 8 MiB.
- Fix / P06: actual startup exposed a false PSRAM capacity warning because Arduino `getPsramSize()` reports heap bytes. Use pinned ESP-IDF chip-size API for capacity and rename heap diagnostic; rebuild/upload PASS. No animation/input changes.
- Physical evidence: owner read model T-Display-S3 and confirmed LCD, idle/happy, timeout, GPIO14 and held-button behavior. [Detailed run](docs/roadmap/M01-bring-up.md#build-upload-and-physical-run--2026-10-11). >10-minute stability PASS (125 windows, no resets/errors, settled heap unchanged); owner confirmed reset/reconnect boot and buttons with Monitor closed. PCB revision unknown; M01 not Validated.
- Git: uncommitted firmware main.cpp/README and root handoff updates; HEADs/gitlinks unchanged, mobile/backend untouched; no commit/push.
- Next: record exact PCB revision and review final acceptance before P07. Monitor closed; no later milestone started.

## 2026-10-11 — USB and ROM connection checkpoint

- Request / tasks: inspect tooling and board connection before upload; P01/P02 partial, P03 awaiting owner confirmation.
- Results: IDE extension 3.3.4 present; normal IDE Core 6.2.0 CLI runs by absolute path. USB serial `/dev/cu.usbmodem14101`, VID:PID `303A:1001`; esptool 4.5.1 ROM-only `chip_id` succeeded, detected ESP32-S3 revision v0.2 and 40 MHz crystal.
- Evidence and limitations: [M01 connection record](docs/roadmap/M01-bring-up.md#connection-checkpoint--2026-10-11). Initial sandbox scans missed the USB port; retry outside sandbox succeeded. No Flash write/erase, stub upload, firmware build or host-test rerun. Esptool reset the device; PCB revision, memory and physical behavior remain unverified.
- Changes: PROCESS.md, PLAN.md, CHANGELOG.md and M01 record only. Root `3dda411`, firmware `be5829d`; all four repositories initially clean on dev. No submodule changes, commit or push.
- Next: report connection checkpoint; await owner confirmation, then rebuild/upload and physical M01 validation. M01 remains Implemented.

## 2026-10-11 — Commit current work

- Request: owner authorized committing current changes; related task P08.
- Git: firmware commit `be5829d` (`feat: implement XUNA M01 T-Display-S3 hardware bring-up`); parent documentation and firmware pointer committed together in the commit containing this entry. No push requested or performed. Mobile/backend unchanged.
- Changes: refreshed PROCESS.md Git snapshot and marked P08 Done. Earlier uncommitted-state entries describe the state at their recorded time.
- Validation: whitespace checks passed; existing build/host-test evidence retained. No new firmware build or hardware validation performed for this Git handoff.
- Next: P01–P05; M01 remains Implemented, physical validation pending.

## 2026-10-11 — Separate context, plan and history

- Request: split the session handoff into separate plan and change-history files.
- Changes: created PLAN.md with stable P01–P08 task IDs/statuses and the Proposed M02 plan; created CHANGELOG.md; replaced the duplicated plan/history in PROCESS.md with links; updated agent entry instructions.
- Validation: documentation links checked locally; Git whitespace checks passed. Firmware build/tests were not rerun for this documentation-only change.
- Git: no commit/push; existing firmware changes preserved; mobile/backend unchanged.
- Next: P01, then board identification/upload/physical checks in P02–P05.

## 2026-10-11 — Establish the session handoff

- Changes: created PROCESS.md with product context, repository snapshot, M01 implementation/evidence, ordered next tasks and a prompt for the next AI; added handoff links in AGENTS.md and CLAUDE.md.
- Validation: inspected Git and existing source/records; whitespace checks passed. No new firmware compilation or physical verification performed.
- Git: changes remain uncommitted; no commit/push.
- Next: complete normal IDE tooling and validate M01 on the actual board.

## 2026-10-10 — Implement M01 hardware bring-up

- Changes: inspected initialized submodules and official LILYGO documentation; implemented modular firmware, LCD branding/original sprite, idle/happy animation, debounced buttons and diagnostics; added host tests, setup/validation documentation, ignore rules and CLAUDE.md.
- Fix: first build failed because Setup206 was not in the global include path for framework-library compilation; corrected platformio.ini and rebuilt successfully.
- Validation: firmware build PASS; host tests and ASan/UBSan PASS; configuration parsing and whitespace checks PASS. Linker static RAM 21,840 bytes; firmware 319,709 bytes. Detailed evidence: [M01 record](docs/roadmap/M01-bring-up.md).
- Limits: no board USB serial device detected in that session; no upload, physical LCD/button test, runtime measurement or PCB revision verification. M01 is Implemented, not Validated.
- Git: firmware and parent docs left uncommitted; no commit/push; mobile/backend unchanged.
- Next: build in normal IDE environment, then flash and physically validate.

## Entry template for future sessions

Add new entries above older entries. For multiple entries on the same date, include a descriptive title. Preserve earlier results; add a correction entry when evidence changes rather than silently rewriting history.

```markdown
## YYYY-MM-DD — Concrete change title

- Request / related task IDs:
- Changes: files and observable behavior changed.
- Decisions: status and reference; omit if none.
- Validation: exact commands/results or link to evidence; say what was not run.
- Limits / blockers:
- Git: commit hashes/pointer changes/push status, or uncommitted.
- Next: remaining task IDs and immediate action.
```

Do not store secrets or long raw logs here. Link to milestone records for detailed hardware/build evidence. Every meaningful implementation, fix, validation result or plan change should leave an entry.

## S02 documentation delivery — 2026-10-12

Owner requested incremental execution. Decision index and Proposed ADR-0001 now exist; S02 documentation done criteria are met. ADR acceptance remains pending, no decision silently approved. Preserved prior uncommitted documentation. Corrected T14 table to match separately gated voice research; no implementation/dependency/hardware changes or commit/push. Next: S00 environment and baseline verification on the current Mac.

## S00 baseline verification — 2026-10-12

- Existing Mac tools verified: PlatformIO IDE/Core 6.2.0, Apple Clang 14.0.0, FVM 3.2.1, Flutter 3.32.8/Dart 3.8.1. No installation/upgrade needed.
- Added mobile/.fvmrc under approved D14. pub get PASS and pubspec.lock unchanged.
- Host core/life tests PASS; firmware build PASS at 47,504 B RAM / 964,333 B image; Flutter analyze and 10 tests PASS.
- S01 prerequisites checked read-only: no ESP32 USB or real iPhone detected. No backup/flash/physical acceptance. Updated PROCESS/PLAN; no M04 source change, commit/push or gitlink update.

## S01 ESP32 preparation — 2026-10-12

- Owner deferred real-phone work. ESP32 connected, serial baseline inspected; chip revision v0.2 is not PCB revision.
- Read/decode actual partition table and compare with build: PASS. NVS backup 20,480 B with SHA-256 manifest stored outside repo; restore not tested.
- No firmware flash/erase/write, BLE command or code change. USB/serial and flash reads reset the board. S01 remains partial; phone acceptance gates retained.

## S03 — Firmware characterization baseline (2026-10-12)

- Owner chose Android for later app acceptance; firmware-first work continued with S03.
- Added firmware test/fixtures/v1_snapshots.h (fresh/scripted/saturated 96-byte snapshots) and test/test_v1_characterization.cpp; documented generation recipe and commands in firmware README.
- New suite covers both-context choice combinations, parser length/opcode/argument/source/error priority, cache results/conflicts/eviction, generation wrap/recovery and routine rollover. Fixtures are host-derived, not observed BLE bytes.
- C++11/-Werror PASS; all three host suites ASan/UBSan PASS; ESP32 build PASS, unchanged 47,504 B RAM / 964,333 B image. Production code/config unchanged.
- Added S03 evidence record, updated PROCESS/PLAN. Next S04; no upload, commit/push or gitlink update.

## S04 — Portable core + PlatformIO native tests (2026-10-12)

- Moved five pure headers into xuna_core; split board/timing config and updated adapter includes, preserving production behavior.
- Converted core/life/S03 assertions to three Unity suites; added C++11 native and ASan/UBSan environments, with no Arduino source compilation on host.
- Added pre-build hardware-include purity guard; updated README and handoffs.
- Native and sanitizer tests PASS (8/8 each); ESP32 build PASS at unchanged 47,504 B RAM / 964,333 B image. PlatformIO installed native 1.2.1/Unity 2.6.1; firmware dependencies remain pinned.
- No firmware upload, app work, commit/push or gitlink update. Next S05; S01 remains pending Android physical acceptance.

S04 negative guard check: PASS in native, native_asan and ESP32; temporary Arduino.h include removed. Clean build after restoration PASS.

## S05 — Fixed point, RNG and ClockModel (2026-10-12)

- Added xuna/base/Fixed.h, Random.h and xuna/time/ClockModel.h plus test_foundation suite; no firmware wiring or TimeSync opcode implementation.
- Tests-first compile failed for missing header; then native/ASan/UBSan regression PASS (12/12 each), ESP32 cross-compile smoke PASS and target build/purity PASS (47,504 B RAM / 964,333 B image unchanged).
- Official PCG vectors/source verified; Apache-2.0 notice/full license and source SHA documented. Fixed-point rounding/zero division and clock rollback/day-part/overflow contracts frozen for this slice; tuning thresholds remain Proposed.
- Added evidence record and updated handoffs. Next S07 as eligible host-only work; S06 board steps/S01 and Android acceptance remain deferred. No thermal measurement, board operation, commit/push or gitlink update.

## S07 — In-memory event foundation (2026-10-12)

- Added EventTypes/Event/EventQueue and RingBuffer plus six event tests; registry covers 25 planned kinds, compile-time unique codes, typed provenance/source and memory-only envelope.
- FIFO and drain budgets enforced; critical updates reject when full, best-effort drops counted; IDs stop on sequence exhaustion.
- Tests-first missing-header failure observed, then native/sanitizer 18/18 PASS; target compile smoke and ESP32 build/purity PASS, unchanged 47,504 B RAM / 964,333 B image.
- Recorded requested session-opening overview rule in AGENTS. Documented S05 time-epoch mismatch for focused S05-fix-01 before integration. No upload/app work, commit/push or gitlink update.

## S05-fix-01 — Compact time epoch correction (2026-10-12)

- Corrected ClockModel minute output, accepted-sync watermark and imported watermark reconstruction to minutes since 2020-01-01; Unix millisecond API retained.
- Added lower/reserved-zero/upper-minute/overflow and persisted watermark tests; updated existing test UTC inputs/expectations. Tests-first failure confirmed old mismatch.
- Native and ASan/UBSan 19/19 PASS; Xtensa compile smoke PASS; ESP32 build/purity PASS at unchanged RAM/image. Updated README, session evidence and handoffs; S07 finding resolved.
- No deployed state/protocol change, board operations, upload, app work, commit/push or gitlink update. Next S06 pure logic; S01 physical gate retained.

## S06 partial — Identity core (2026-10-12)

- Added pure CRC32, 64-byte identity codec and staged IdentityService, plus four identity test cases. Unknown/corrupt/too-new handling, migration, immutable identity, same-boot birth and failed-persistence staging tested.
- Tests-first missing-header failure observed; native/sanitizer 23/23 PASS, Xtensa compile smoke and ESP32 build/purity PASS; RAM/image unchanged.
- Recorded explicit codec layout, caller entropy/boot-counter/commit contracts and deferred GPIO/NVS steps. Full S06 remains In progress; next S14 pure ActivityFsm, Android/S01 deferred.
- No board operations, upload, app changes, commit/push or gitlink update.

## S11 — Isolated storage experiment preparation (2026-10-12)

- Prepared external benchmark from committed MVP display/config; includes NVS A/B, LittleFS appends/rename, rendering/timing, controlled storms/recovery and benchmark-only cleanup. No merge into firmware.
- Benchmark build PASS 159,840 B RAM / 365,053 B image; original MVP restoration project build PASS 47,504 B RAM / 964,333 B image. Sources/artifacts hashed outside repo.
- Added E4/E5 preparation record and Proposed ADR-0002, no measured results or D2 decision.
- Corrected earlier S11 readiness statement: global S01 upload gate still applies; current USB listing also has no board. Runtime waits for connection/backups and S01 or explicit isolated-benchmark exception.
- No board read/write/upload/format/cut/measurement, commit/push or gitlink update; prior edits retained.

## Static pet LCD scene — 2026-10-12

- Owner paused S11 and requested UI implementation/upload from xuna_and_bg.png. Added original source, nearest-neighbor RGB565 converter, generated Flash asset/preview/metadata.
- DisplayManager now draws full 320×170 scene once at boot; removed placeholder sprite/framebuffer and loop redraw. Existing life/input/BLE/storage logic and pinned board configuration retained.
- Deterministic generation and Flash placement PASS; build/native 23/23 PASS. RAM 46,072 B (−1,432), image 1,062,793 B (+98,460), asset 108,800 B in Flash.
- Fresh table/NVS backup, upload and NVS equality readback PASS. Actual startup draw 31,663 us; no spontaneous reset/error during 25-second log observation. Owner confirmed correct image/colors/stability on LCD.
- Source/build/physical evidence in UI-static-scene.md; S11 stays paused, S01 Android acceptance/full S06 pending. No commit/push/gitlink change.

## Animated room/pet and authorized commits — 2026-10-12

- Added reference/palette config and generator, separate room/background and authored pet frames, sprite sheet/LCD/GIF previews and RGB565 Flash exports; old static exports archived.
- Added pure presentation timing plus tests; display composites fixed region buffer, background restore and transparent masks. Idle/blink/wiggle and clear Happy/Idle expressions retain existing pet/button/BLE/state paths.
- Owner feedback led to closer reference silhouette, more visible foot motion, distinct Happy expression, overlapping torso/feet seam fix and explicit dark tips. Final owner reply provisionally accepts the result.
- Final build/upload PASS (46,144 B static RAM / 1,340,569 B image); native and ASan/UBSan 25/25 PASS; 385,280 B Flash pixels and 13,824 B runtime region buffer. Final short diagnostics no spontaneous reset/error; not long-run/thermal validation.
- Fresh backups retained outside Git. NVS newest snapshot only advanced active-lifetime/generation; learning/episode bytes unchanged. S11 stayed paused; prepared benchmark source archive saved in root docs for reproducibility.
- Owner requested all today's changes committed. Firmware c84d4e3, mobile 77d27ec; parent commit records docs/gitlinks. No push. Proposed ADRs remain Proposed; S01/full S06 pending.

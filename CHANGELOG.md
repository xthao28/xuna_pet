# XUNA — Change and Session History

Last updated: **2026-10-15** (Asia/Ho_Chi_Minh).

This file records work actually performed, including uncommitted changes, validation and handoff updates. Entries are not evidence that a Git commit or release exists. Read [PROCESS.md](PROCESS.md) for the current snapshot and [PLAN.md](PLAN.md) for remaining work. AGENTS.md remains canonical for decisions.
## 2026-10-15 — Phase 1 slice 5: §9.5 commit-first parity in LifeCore

- Added `ILifeCommit` and `PreferenceLearnerV3::accepts()`; `LearningBridgeV3` now validates, stages v1, commits, then applies v1 and v3 (Applied/Rejected/CommitFailed). `LifeCore::setCommitter()` with `feedbackCommitted`/`feedbackNotReady` outputs; `LifeCoreSnapshotLab` is the committer; trace runner counts urgent commits.
- A failed commit leaves v1, generation and the v3 shadow unchanged and keeps the decision pending for retry (BLE result 7 semantics). Traces c2/c3 now reflect this. Resolves the earlier lab finding for LifeCore.
- Native 116/116 PASS; ESP32 build unchanged. No board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 4: v3 shadow candidate in LifeCore

- Added `LearningBridgeV3` (v1 baseline + v3 candidate, metrics). `LifeCore` now shadows learner v3 with `shadowConfig()` (tuned Proposed values) instead of v2 and exposes `shadowMetrics()`; candidate resets on boot. Host core only; production BLE path unchanged.
- Finding: the v2 bridge credited ratings to v2's own unshown action; the v3 bridge credits the shown action. Earlier v2 shadow agreement numbers are not valid evidence.
- Tests updated plus 2 bridge tests; native 115/115 PASS; ESP32 build unchanged; LifeCore traces replay with identical bookkeeping. No board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 3: learner codec, v1 migration, explanation

- Added `LearnerV3Codec` (LifeSnapshot v2 learner payload: 8-byte header + 10-byte cells, 408 B for 2 × 5 × 4; typed errors; validate before mutating; shape growth/shrink), `migrateFromV1` (ratio kept, mass capped at 1/(1 − γ)), `LearnerV3Explanation` (§9.6 evidence fields and reasons), raw `rated` counts in v3 and `test/test_learner_v3_codec` (7 tests).
- Fixed `tools/check_core_purity.py` to read sources as UTF-8; on Windows it crashed (cp1252) on non-Latin comment text.
- Validation: native 113/113 PASS; ESP32 build unchanged; purity PASS. Proposed amendment to plan §7.5 for the capped migration. Lab only; no production wiring, board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 2: learner v3 parameter sweep

- Added feedback-aware ε scaling (A/D), a late-context schedule with a generalization metric, the `new_daypart` scenario, `sim/learner_sweep.cpp` and `v3_C_tuned`; 1 more unit test. Native 106/106 PASS; ESP32 build unchanged.
- Sweep (137 configurations, 8 scenarios, 200 seeds): C with γ 0.90, k 1, m 1, bonus 0.15 ranks best (1.11 vs 1.27 for plan defaults; best A 2.42, best D 3.18). Tuned v3 reaches the target after reversal in 94% of seeds and under drift in 96%; it loses only to flat v2 when day parts disagree, and generalizes to a new day part 98% of the time.
- Tuned values recorded as Proposed replacements in plan §9.4 and the [learner v3 record](docs/roadmap/learner-v3-phase1-2026-10-15.md). No production wiring, board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 1: learner v3 candidate

- Owner asked to start Phase 1. Added lab/shadow `PreferenceLearnerV3` (plan §9.3 Q16.16 discounted Beta, rated-cell-only discount, hierarchical day-part prior; §9.4 policies Greedy, A ε-greedy, C UCB, D learning progress), `test/test_learning_v3` (10 tests), `V3BenchLearner`, a `dayparts` scenario and `--gamma` in `learning_bench`.
- Validation: native 105/105 PASS; ESP32 build SUCCESS with unchanged RAM 46,208 B / Flash 1,343,337 B (not linked); purity PASS.
- Findings (200 seeds): v3 C recovers after a reversal in 84% of seeds (γ 0.95) or 98% (γ 0.90), against v1 0% and v2 26%; C is the preliminary E10 winner. A and D over-explore when ratings are sparse. The hierarchical prior (k 2, m 3) learns slower than flat contexts when day parts disagree. γ 0.90 adapts faster but flips more under noise.
- Evidence: [learner v3 record](docs/roadmap/learner-v3-phase1-2026-10-15.md); plan §9.4 note. No production wiring, board/mobile operation, commit or push.
## 2026-10-15 — Hybrid offline + online learning plan (documentation only)

- Owner asked to integrate an online layer (cloud, MQTT) combined with the existing offline learning. Recorded as owner-requested direction (AGENTS.md §3); technical choices stay Proposed.
- Added [ADR-0007](docs/decisions/ADR-0007-hybrid-offline-online-learning.md) and plan §22 (contract H1–H8, capabilities O1–O6, phone-gateway then device MQTT/TLS transport, sequencing), experiments E14/E15, decisions D21–D24, decision-index rows and an online-layer table per learning phase. Cites the Moxie (2025-01-30) and Vector server shutdowns as the reason for the offline-complete rule.
- Owner then approved D21 and D22 (broker/provider, D23, D24 still open). No code, build or board/mobile operation.
## 2026-10-15 — Life Lab Phase 0 slice 1: closed-loop learner bench

- Owner approved L-D1–L-D5 (recorded in AGENTS.md §3, plan §18; L-D5 = research on touch, IMU and microphone only) and chose the closed-loop Life Lab next.
- Added host-only `xuna/lab/OwnerModel.h` (oracle, reversal, drift, no-feedback, sparse rating) and `xuna/lab/LearnerBench.h` (random/static/v1/v2 adapters, regret, greedy-correct, trials to target, flips, Brier, no-feedback invariance), `test/test_life_lab` (8 tests) and `sim/learning_bench.cpp` (200 seeds, bootstrap CIs, `--curves`).
- Validation: native 95/95 PASS; ESP32 build SUCCESS with unchanged RAM 46,208 B / Flash 1,343,337 B; purity PASS.
- Findings: v1 and v2 learn a stable preference in a median of 7 trials and beat baselines (§9.9 B holds). Neither handles change: after a reversal v1 never recovers in 60 trials (0% of seeds, worse than random) and v2 recovers in 26%; under drift v1 is worse than both baselines. No feedback leaves every learner unchanged (§9.9 D). Measured case for the §9.3 discounted estimator in Phase 1.
- Evidence: [Phase 0 record](docs/roadmap/life-lab-phase0-2026-10-15.md). No production code change, board/mobile operation, commit or push.
## 2026-10-15 — Learning competitive upgrade plan (documentation only)

- Owner requested a review of large projects for strong learning algorithms suited to XUNA and an upgrade plan, and allowed revising the plan where needed.
- Added [XUNA_LEARNING_COMPETITIVE_UPGRADE.md](docs/architecture/XUNA_LEARNING_COMPETITIVE_UPGRADE.md) (Proposed): competitor review (public/marketing claims), algorithm fit table, six gaps, phases 0–6, decisions and sources.
- Amended the implementation plan ([P]): §9.4 Alternative D learning-progress curiosity and a note on what v2 actually implements; §9.9 drift and noisy/sparse scenarios; §9.10 teachable tricks; §18 L-D1–L-D5. Linked from the learning roadmap; PLAN rows LRN-01/02.
- Corrected the lab-run finding: plan §9.5 already defines the commit-failure model, so it is a parity task, not an open choice.
- No code, build, board/mobile operation, commit or push.
## 2026-10-15 — Host lab runs (LifeCore and learning)

- Owner chose host experiments. Built `sim/lifelab` and `sim/lifecore_lab` with g++ 16 `-Werror` (clean). Added 12 annotated traces in `firmware/sim/traces/`; results are deterministic across reruns.
- LifeCore: commit, power cut, reboot, pending-after-reboot, duplicate and window cases behave as designed. Finding: commit-failure semantics differ from production (BLE opcode 3 saves a copy and keeps the decision pending for retry; `LifeCore` applies first, clears pending, and in the lab cannot report or retry a failed commit). Plan §9.5 already defines the production model; bring `LifeCore` in line with a parity test before it replaces the BLE path (S18).
- Learning: with consistent scripted feedback v2 Brier is 0.052 vs 0.25 uniform; with no signal it is 0.279 (slightly worse than uniform). Traces are open-loop, so this is not evidence of preference learning, and v1/v2 agreement is not meaningful.
- Limits: runners are open-loop, print one summary row and cap traces at 64 events, so they cannot tune the Proposed needs/energy/FSM values. A closed-loop time-series lab is proposed, not started.
- Evidence: [lab runs record](docs/roadmap/lifecore-lab-runs-2026-10-15.md). No production code change, board/mobile operation, commit or push.
## 2026-10-15 — Windows toolchain and gcc warning fix

- Owner installed the PlatformIO IDE extension (Core 6.2.0, not on PATH) and asked the agent to install the rest. Installed MSYS2 via winget and UCRT64 gcc/g++ 16.2.0 via pacman; added `C:\msys64\ucrt64\bin` to the user PATH. No admin rights used.
- First Windows native run: 15/17 suites; `test_life` and `test_v1_characterization` failed to compile because gcc 16 reports `-Wmisleading-indentation` (as error) on `BleProtocol.h` `remember()`. Fixed by splitting the line; no behavior change.
- Validation on Windows: native 87/87 PASS (17 suites); ESP32 build SUCCESS (RAM 46,208 B, Flash 1,343,337 B, 20 B below the Mac figure); `git diff --check` PASS. `native_asan` not run: MinGW lacks usable ASan/UBSan (needs WSL or the Mac). No board/mobile/backend operation, commit or push.
- Editor diagnostics: the Problems panel (clangd in Antigravity) showed false errors (`cstdint` not found, unknown `uint8_t`) because clangd had no compile flags and defaulted to missing MSVC headers. Added `firmware/.clangd` (strip xtensa-only flags; host tests and `sim/` use native C++11 flags with Unity instead of the ESP32 database) and ignored `compile_commands.json`/`.cache/`. Machine-local only: generated `compile_commands.json` via `pio run -e xuna_t_display_s3 -t compiledb`, added `clangd.arguments --query-driver` for the xtensa toolchain to Antigravity settings, and `%LOCALAPPDATA%\clangd\config.yaml` pointing host files at MSYS2. `clangd --check` reports no diagnostics on 65 tracked firmware sources.
## 2026-10-14 — Mobile UI: XUNA design system and four-tab home

- Owner-requested UI from Claude Design "XUNA App": XUNA tokens, bundled OFL fonts (Anton, Be Vietnam Pro, JetBrains Mono), 11 base widgets, 24 SVG icons, and a four-tab home (Nhà, Trò chuyện, Nhật ký, Thiết bị) on the existing controller and device repository.
- Real data only; growth, brightness, voice, image attach and device settings are shown locked as "SẮP CÓ". Chat transcript is in-memory only. No protocol, firmware, dependency or SDK change.
- Validation: analyze clean; 29/29 tests; `pubspec.lock` unchanged. Image stand-ins used where the design export was truncated. No real phone/board run, commit or push.
- Owner review: display headings no longer wrap/truncate and have looser line height for Vietnamese diacritics; UI design roadmap with Claude Design prompts added ([plan](docs/design/XUNA_UI_DESIGN_PLAN.md), Proposed).
- Evidence: [mobile UI record](docs/roadmap/mobile-ui-design-system.md).
## 2026-10-14 — M04 firmware review fixes (first compiled validation)

- Owner-requested review of firmware `a518ede`/`f784626`/`6b1110e`, then fixes. First compilation of these slices: 5 of 16 native suites failed before the fixes.
- Production fixes: energy now recovers while Resting/Sleeping (owner-chosen; `energyRecoveryPerMinute` Proposed) so the pet no longer stays in Resting forever after ~48 min; BLE opcode 2 commits `context_` only with an accepted decision; a new reaction restarts the Reacting timer.
- Added pure `ActionGate` shared by `BleManager` and `LifeCore`; LifeCore visual expiry and accepted-only decisions; `GuardReboot` reason; C++11 compile fixes; corrected FSM/Needs tests; new `test_action_gate` regressions.
- Validation on Mac: native and ASan/UBSan 87/87 PASS (17 suites); ESP32 build SUCCESS (RAM 46,208 B, Flash 1,343,357 B, purity PASS); both `sim/` programs build. No board/mobile/backend operation, commit or push.
- Evidence: [review fixes record](docs/roadmap/M04-review-fixes-2026-10-14.md).
## 2026-10-14 — S16 action policy and visual boundary

- Added pure C++11 action registry, deny-by-default request validator, visual-intent fallback map and deterministic behavior selector for M04.5c.
- Added tests for action descriptors, validator rejection paths, stage fallback and seeded selector filtering/tie-breaks.
- Native/sanitizer/ESP32 validation is pending because this Windows environment has no PlatformIO or C++ compiler executable. No board/mobile/backend operation, commit or push.
- Evidence: [S16 record](docs/roadmap/S16-action-policy.md).
## 2026-10-14 — S15 Needs/Mood implementation

- Added pure C++11 `Needs` and transient `Mood` models for M04.5b, with bounded Q0.16 needs, monotonic catch-up decay, cold-boot reset and hysteresis labels.
- Added tests for partition-invariant catch-up, wrap/clamping and mood threshold behavior.
- Native/sanitizer/ESP32 validation is pending because this Windows environment has no PlatformIO or C++ compiler executable. No board/mobile/backend operation, commit or push.
- Evidence: [S15 record](docs/roadmap/S15-needs-mood.md).
## 2026-10-14 — S14 ActivityFsm implementation

- Implemented the pure C++11 ActivityFsm slice for M04.5a with nine states, table-driven legal transitions, explicit guard/rejection reasons and monotonic timeout handling.
- Added exhaustive-pair, guard, reboot-only safe-mode, explicit-wake, energy and uint32 wrap tests.
- Validation is pending: this Windows environment has no PlatformIO or C++ compiler executable. No board/mobile/backend operation, commit or push.
- Evidence: [S14 record](docs/roadmap/S14-activity-fsm.md).

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

## S01 Android acceptance — 2026-10-13 (in progress)

Android 15 phone and ESP32 connected; fresh NVS backup/hash and idle serial smoke PASS. Owner approved S01-fix-01 for missing Android BLE permissions; manifest updated. Flutter 3.32.8 analyze clean, 16/16 tests PASS. Native debug APK build PASS; install blocked by phone (INSTALL_FAILED_USER_RESTRICTED), awaiting owner USB-install setting/prompt. Physical BLE/learning/persistence acceptance pending. Evidence and external backup paths: PROCESS latest S01 entry. Permission/docs edits uncommitted; no firmware upload/erase, commit/push; S11 stays paused. Actual existing mobile HEAD is cebaf1c (earlier uncommitted handoff superseded).

## S01 Android BLE smoke — 2026-10-13

APK install/launch, runtime Nearby devices permission, physical scan/connect/GATT reads PASS. Four animation requests reflected in status; owner confirms LCD/buttons. Quiet Idle → reject → learned Happy; feedback 1, memory 1/8 with button provenance. USB-UART reboot/reconnect retained preference/memory and expired pending suggestion. Detailed evidence: PROCESS latest S01 entry and MVP-local.md. Physical power cuts, forget/text/error matrix and raw-byte transcript remain pending; S01 In progress. No firmware change/upload, commit/push; S11 paused.

S01 continuation: one owner-operated power cut retained learned preference/memory. Active-time rollback recorded and attributed to existing five-minute checkpoint contract. Forget plus USB-UART reboot/reconnect PASS (memory/feedback 0, preferences Idle, lifetime preserved). Text confirmation, raw bytes/error matrix and full cut matrix pending; S01 remains In progress. Evidence: PROCESS / MVP-local latest entries.

S01 text follow-up: owner confirmed like; device reads feedback/memory 1 with text-confirmed provenance. Pre-confirmation counter not observed, still pending. Requested nRF Connect installation for required raw-byte transcript; S01 remains In progress. One test-created text episode remains on device. No firmware change, commit/push.

## S01 observed read baseline — 2026-10-13

nRF Connect installed and connected. Five physical characteristic reads captured as raw hex: capabilities 8 B, status 16 B, life and both memory pages 20 B each. Life feedback 1/memory 1/pending 0; confirmed-text episode observed. Evidence: [S01 observed transcript](docs/roadmap/S01-v1-observed-transcript.md) (root-relative path); raw XMLs outside Git. No writes/upload in this read step. Scripted writes/error matrix and power-cut matrix remain pending; S01 In progress, S11 paused. Docs uncommitted; no commit/push.

S01 raw command follow-up: Notify enabled; observed 7-byte Suggest Quiet attempt returned invalid_length (2), request 1; no pending suggestion or memory/feedback changes. Recorded actual transmitted bytes/status/life in S01-v1-observed-transcript.md. Valid 8-byte command with fresh request 2 pending. No firmware/code changes, commit/push.

S01 raw Suggest Quiet request 2: actual 8-byte write accepted (OK), choice Idle, pending ID 2/canFeedback 1. Feedback/memory remain 1; both memory pages unchanged. Raw hex and capture copies recorded in S01-v1-observed-transcript.md. Approval request 3 targeting 2 remains next; no firmware upload, code change, commit/push.

## S01 automated inspector cases — 2026-10-13

Owner requested direct operation. ADB drove nRF Connect Byte Array writes after verifying entered hex. Approval request 3/target 2 PASS: feedback/memory 1→2, episode source 1. Exact duplicate request 3 PASS: OK, counters remain 2. Reused ID 3 with rejection payload PASS: conflict 6, no learning. New feedback request 4 without active pending PASS: invalid_argument 4, no learning. Raw status/life/both memory pages for each case in S01-v1-observed-transcript.md and external case JSON/XML captures. Pending suggestion 5 created (OK/canFeedback 1); awaiting owner GPIO0 press before feedback invalidation test. No firmware upload, source change, commit/push; S01 In progress, S11 paused.

## S01 raw inspector script complete — 2026-10-13

Pending request 5 accepted. Owner pressed GPIO0; feedback request 6 targeting 5 rejected (invalid_argument 4), pending cleared and counters unchanged at 2. Forget request 7 OK; memory/feedback 0, both preferences Idle, active lifetime 5991 retained. Full required inspector script now captured as actual writes + status/life/both memory pages in S01-v1-observed-transcript.md. These satisfy the observed transcript portion, not full S01. Remaining: ten-cut matrix, feedback/connected diagnostics, pre-confirmation text observation, off/deny/timeout and standalone/routine checks. Device now cleared of test episodes. No firmware upload/source change, commit/push; S11 paused.

Owner deferred remaining S01 physical matrix to a later session. Stop current device actions; next resume: fresh device/backup verification, controlled five-idle/five-post-feedback cut checks, BLE/feedback diagnostics and text pre-confirmation evidence. Required raw inspector sequence complete; S01 remains In progress, not Validated. Device has feedback 0/memory 0, preferences Idle after Forget; nRF connection may remain open. No commit/push requested.

## S01 commit checkpoint — 2026-10-13

Owner requested committing current changes. Mobile f756225 commits Android Bluetooth permissions; the parent commit containing this entry records its gitlink plus S01 validation/handoff and observed transcript. Firmware c84d4e3 and backend unchanged. Prior uncommitted descriptions are historical; no push. S01 remains In progress with remaining physical checks deferred by owner; S11 stays paused. Existing Flutter analyze/16 tests, native APK build/install and physical smoke/inspector evidence retained; commit checks: whitespace PASS. No new device operations or tests during commit-only delivery.

## S17 — FSM and visual boundary wiring (2026-10-14)

- Wired BLE opcode 1/2 plus local button/quiet actions through the shared RequestValidator and ActivityFsm; denied actions no longer call AnimationManager directly.
- Added Needs energy context, cooldown tracking, Sleep wake routing and safe Sleep/ErrorSafe/unknown VisualIntent mapping into the existing four PetState renderer states.
- Added visual bridge regression coverage. Native/sanitizer/ESP32 validation is pending because this Windows session has no PlatformIO/C++ toolchain; no board/mobile/backend operation or commit/push.

## Learning Engine L1 scaffold — 2026-10-14

- Added an independent bounded contextual learner with posterior-based preference, uncertainty-aware exploration, decision/propensity records, source-tagged idempotent feedback, bounded evidence/history, metrics and deterministic replay fingerprint.
- Added host-test preparation for exploration, context isolation, feedback deduplication, policy adaptation and bounded replay.
- Kept production learner v1 and its BLE/snapshot contract unchanged. Persistence v2, migration and shadow integration are the next gate; no neural network, cloud dependency or board/mobile change was introduced.
- Toolchain limitation: no PlatformIO/C++ compiler available, so native/sanitizer/ESP32 tests and learning-quality claims remain pending. No commit/push.

## Learning Engine L1.5 evaluation primitive — 2026-10-14

- Added fixed-point prequential evaluator for Brier loss, accuracy and improvement over a uniform baseline.
- Added learner tests for score-before-feedback behavior and invalid decision rejection.
- Kept this as an isolated measurement primitive; no persistence, BLE contract or production learner switch was introduced. Native/ESP32 validation remains pending.

## Learning Engine L1.6 shadow harness — 2026-10-14

- Added a pure v1/v2 shadow comparison harness for future Life Lab use.
- Candidate decisions and baseline decisions are recorded together; accepted feedback updates both once, while duplicate/invalid candidate feedback does not update v1.
- Added deterministic replay and synchronization tests. No production wiring, storage format or BLE change.

## Learning Engine L1.7 trace runner — 2026-10-14

- Added a bounded Choose/Feedback trace runner for shadow replay and prequential metrics.
- Added unknown-feedback, duplicate-feedback and deterministic fingerprint coverage.
- Kept it host/test-only; full Life Lab DSL and production integration remain pending.

## Learning Engine L1.8 explanations — 2026-10-14

- Added bounded numeric explanations for learner choices: posterior cells, counts, margin, policy version and exploration/winner reason.
- Added tests for exploration, posterior winner and invalid decisions.
- No mobile UI, BLE payload or production wiring was changed.
## Commit checkpoint — 2026-10-14

- Firmware submodule committed at a518ede: `feat(firmware): add bounded digital life and learning layers`.
- Parent documentation commit is complete; no push. Validation limits and next toolchain/Life Lab steps are recorded in PROCESS.md and PLAN.md.
## Learning Engine L1.9 trace DSL/runner preparation — 2026-10-14

- Added bounded learning trace DSL parsing and typed errors for deterministic Choose/Feedback traces plus reserved future S19a verbs.
- Added a host-only `sim/lifelab.cpp` metrics runner and README; it emits prequential/shadow CSV output without persistence or board access.
- Added parser and parser-to-runner tests. Full S19a LifeCore simulation remains gated by S18 and the native toolchain.

## Learning Engine L1.9 commit checkpoint — 2026-10-14

- Firmware child committed at `f784626`: `feat(firmware): add learning trace DSL and host runner`.
- Parent handoff records the gitlink and remaining S18/S19a gates. No push.

## M04 LifeCore composition and snapshot lab — 2026-10-14

- Added pure C++11 `LifeCore`/`LifeCoreSession` composition, bounded trace replay and the `lifecore_lab` host CSV runner.
- Added an in-memory A/B snapshot lab covering committed restore, simulated power cut and corrupt-latest fallback; V2 learner state remains shadow-only and resets on reboot.
- Reset ActivityFsm/cooldown state on `LifeCore::begin()` and added a reboot regression test.
- Static whitespace/include checks pass. Native, sanitizer, ESP32 and board/mobile validation remain unavailable because this session has no C++/PlatformIO toolchain. No commit or push.
## M04 trace persistence experiment — 2026-10-14

- Fact: `LifeCoreTraceRunner` now drives `LifeCoreSnapshotLab`; `reboot` recovers the newest valid slot, `powercut` fails the next requested commit, and feedback persistence requests are auto-committed in the host experiment.
- Fact: CSV output and Unity coverage now include persist failures, reboot count, final event count and generation. `sync/day/expect` remain explicit unsupported verbs.
- Validation limit unchanged: whitespace and include-resolution checks pass; no C++/PlatformIO toolchain, simulator execution or board/mobile operation was available. No production persistence decision was made.
## 2026-10-14 — S18 readiness source audit

- Owner requested the first suggested step: compare current LifeCore with S18 criteria and S10/S13/S17 dependencies. Added [readiness review](docs/roadmap/S18-readiness-review.md).
- Confirmed partial host preparation, missing production composition/persistence contracts and unmet prerequisite acceptance; documented pending-feedback and durable-commit parity gaps.
- Documentation only; no source edits, runtime tests, board/app operation, commit or push. Earlier review validation is retained with its original scope.

## S17 board upload smoke — 2026-10-14

- Owner explicitly authorized backup and upload after connecting ESP32. Detected ESP32-S3 rev v0.2, MAC 98:C3:77:A6:6F:D8 at /dev/cu.usbmodem14101; chip revision does not establish PCB revision.
- Device and target partition tables match: NVS 0x9000/0x5000. Backup outside Git: /Users/xthao28/xuna_backups/2026-10-14-s17/ (table, NVS, manifest, pre/post-upload Serial). NVS size 20,480 B, SHA-256 d7d12a9bebe95738bad48bdee08ce90f7de284bbd928ca24611286c5988ec52d; partition table SHA-256 bd0f7954aca2ef7d925ee21aaa1f3dc8822d1d6ce5cbbd26a135e5886bfff6ce. Restore not tested.
- Target aa2dbca build PASS (RAM 46,208 B, Flash 1,343,357 B, purity PASS); upload PASS with hash verification. Upload ranges exclude NVS; no erase-all or restore requested.
- Serial boot smoke PASS: version 0.2.0-mvp (does not expose commit), Flash 16 MB, PSRAM chip 8 MB, display initialized; no storage/BLE init error in captured log. Opening USB Serial caused USB_UART_CHIP_RESET. Initial idle draw max 4,754 us and loop gap max 4,767 us; no mean timing logged, so S17 +20% render acceptance is not established.
- Pending: owner LCD/buttons observation, sleep/wake and result 5 through BLE, rest/recovery, pet-state preservation through decoded reads, render baseline comparison. Full S17/S01 remain In progress. No source change, mobile operation, commit or push.

- S17 owner visual confirmation (2026-10-14): owner confirmed normal XUNA/Idle LCD, GPIO0 Happy and return to Idle, followed by GPIO14 Idle on firmware aa2dbca. Combined with captured button Serial logs, LCD/button smoke PASS. Full S17 remains In progress: BLE sleep/wake/result 5, rest/recovery and render timing acceptance still pending.

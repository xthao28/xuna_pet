# XUNA — Change and Session History

Last updated: **2026-10-11** (Asia/Ho_Chi_Minh).

This file records work actually performed, including uncommitted changes, validation and handoff updates. Entries are not evidence that a Git commit or release exists. Read [PROCESS.md](PROCESS.md) for the current snapshot and [PLAN.md](PLAN.md) for remaining work. AGENTS.md remains canonical for decisions.

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

# XUNA — Implementation Session Plan

**Status:** Proposed. This file breaks [XUNA_IMPLEMENTATION_PLAN.md](../architecture/XUNA_IMPLEMENTATION_PLAN.md) (XUNA-TIP-001) into small, independently verifiable work sessions. **It does not approve any session.** Each session starts only after the owner asks for it, and after its listed decisions are answered.
**Date:** 2026-10-12
**Audience:** the owner, plus the coding agent or engineer who runs each session.

Plan references:

- `§x` means a section of XUNA-TIP-001.
- `Tn` is a technique card (§6), `Dn` an owner decision (§18), `En` an experiment (§16.2), `Gn` a gap (§4).

---

## 1. Is the technical plan detailed enough to implement?

**Short answer:** it is detailed enough to **start M04 now** (sessions S00–S10) once D1 is approved. It is **not** a complete line-by-line specification for M05+. The missing details are intentionally deferred: they depend on earlier measurements and decisions, and specifying them now would produce work that has to be redone.

| Area | Ready? | What is still missing | Closed in |
|---|---|---|---|
| Architecture, module boundaries, principles | Yes | — | — |
| M04.1 core extraction | Yes | Toolchain on this machine (below) | S00, S03–S04 |
| M04.2 clock/RNG/identity | Mostly | D7; exact TimeSync bytes | S02, S05–S06, S10 |
| M04.3 events + command handler | Mostly | The v1 behavior transcript must be written first | S07–S09 |
| M04.4 persistence v2 | **No** | D2 depends on measurements E4/E5; byte offsets not frozen | S11–S13 |
| M04.5 FSM/needs/visuals | Yes for pure logic | Threshold values are placeholders, tuned in Life Lab | S14–S17 |
| M04.6 Life Lab | Partly | Trace grammar and golden-file format | S18–S21 |
| M05a learner v2 | Algorithm yes | D3–D6, action vocabulary aligned with art, E10 parameter choice | S22–S28 |
| M05b memory/journal/BLE v2 | Partly | D8–D10, E8 MTU, E9 bonding, v2 payload layouts | S29–S38 |
| M05c conversation V1.5 | Partly | D8, full phrase grammar; V2 needs D11 | S39–S42 |
| M05d cognitive gates | Algorithm yes | Thresholds are hypotheses until Life Lab data | S43–S46 |
| M06 / M07 | Outline only | Broken down when M05d ends (rolling-wave planning) | later |

**Missing prerequisites observed on this Windows machine (2026-10-12):**

- No PlatformIO, so no `pio`.
- No host C/C++ compiler (`gcc`/`clang`).
- `python` is only the Microsoft Store alias.
- WSL is present but has no Linux distribution.
- Flutter is **3.41.1** (fvm default), while recorded project evidence used **3.32.8** / Dart 3.8.1.
- iOS builds and runs need macOS with Xcode. Earlier sessions used a Mac.

How the missing detail gets handled:

- **Design freeze step.** Sessions that build something new start with a short "design freeze" step. The exact byte layout or API is written into the technical plan, or into a roadmap record, before any code.
- **Tests first.** Tests come before implementation.
- **Plan updates.** If a session finds that the plan is wrong, it updates the plan explicitly. It never silently deviates.

---

## 2. Rules for every session

1. **Start:**
   - Read AGENTS.md, PROCESS.md, this session's entry and the plan sections it cites.
   - Run `git status --short` in the root and in the affected submodules.
   - Confirm the preconditions. **If a precondition is not met, stop and report it.**
2. **Scope:** one goal per session, mostly in one repository. Do not start the next session's work. Do not refactor unrelated code.
3. **Characterize before refactoring.** Capture current behavior as golden bytes or transcripts before moving code (S03, S08).
4. **Tests first** for core logic: add failing tests, implement, then make them pass.
5. **Keep the build green.** At the end of every session the firmware builds, host tests pass, and protocol v1 still works, unless the session says otherwise.
6. **Protect the owner's pet data.** Before any upload that changes storage code, back up the NVS partition (S13, procedure in §5). Benchmarks use a separate NVS namespace and never touch `xuna_life`.
7. **Report honestly.**
   - Separate *ran and passed*, *ran and failed* and *not run*.
   - Never claim board or phone behavior that was not observed.
   - Upstream or simulator numbers are not XUNA measurements.
8. **End:**
   - Run the session's verification commands.
   - Update PROCESS.md (status and next session), PLAN.md (session status), CHANGELOG.md (dated entry) and any roadmap record.
   - Suggest commit messages. **Commit or push only when the owner asks.** Commit the child repo first, then the parent gitlink.
9. **Stop and report** when any of these happens:
   - a needed decision is missing;
   - hardware or the phone is unavailable for a required check;
   - tests fail for reasons outside the session's scope;
   - the work would exceed the session's size estimate by more than about 2×.

Session size estimates (one focused AI-assisted sitting = 2–4 h):

- **S** — about half a sitting.
- **M** — one sitting.
- **L** — two sittings; split it if possible.
- **Owner** — needs the owner's physical action or decision.

**Branches:** keep the current practice of working on `dev` in each repository unless the owner asks for per-session branches (`feat/sNN-...`).

---

## 3. Session map

| ID | Slice | Title | Repo(s) | Needs | Size |
|---|---|---|---|---|---|
| S00 | prep | Development environment and baseline | all (no code) | — | M + Owner |
| S01 | M04.0 | MVP physical acceptance (regression reference) | firmware, mobile | S00, Mac or Android decision | Owner |
| S02 | M04.0 | Decisions and documentation housekeeping, ADR-0001 | root | S00 | S + Owner |
| S03 | M04.1 | Characterization tests and golden v1 fixtures | firmware | S00, D1 | M |
| S04 | M04.1 | `xuna_core` library and native test environment | firmware | S03 | M |
| S05 | M04.2 | Fixed-point, PCG32, ClockModel (pure) | firmware | S04 | M |
| S06 | M04.2 | Identity record, `bootc`, hatch/migration | firmware | S05, D7 | M |
| S07 | M04.3 | Event envelope, registry, ring buffer, queue (pure) | firmware | S04 | M |
| S08 | M04.3 | v1 protocol transcript and core `CommandHandler` | firmware | S03, S07 | L |
| S09 | M04.3 | `BleManager` becomes transport-only | firmware | S08, S01 | M + Owner check |
| S10 | M04.2 | TimeSync end-to-end (opcode 5) | firmware, mobile | S05, S06, S09 | M + Owner check |
| S11 | M04.4 | Storage experiment E4/E5, ADR-0002 → D2 | firmware (bench) | S04 | M + Owner |
| S12 | M04.4 | Sectioned snapshot v2 codec + v1→v2 migration | firmware | S03, D2 | L |
| S13 | M04.4 | Persistence v2 wiring, safe mode, commit budget | firmware | S12, S06 | M + Owner check |
| S14 | M04.5 | ActivityFsm (pure) | firmware | S07 | M |
| S15 | M04.5 | Needs, mood, bounded catch-up (pure) | firmware | S05 | S |
| S16 | M04.5 | Action registry, request validator, VisualIntent, idle selector (pure) | firmware | S14, S15 | M |
| S17 | M04.5 | Wire FSM and visuals into firmware; renderer fallback | firmware | S16, S13 | M + Owner check |
| S18 | M04.6 | `LifeCore::step` composition; thin `main.cpp` | firmware | S17 | M |
| S19 | M04.6 | Life Lab CLI, trace DSL, Scenarios D/E, 100-day run | firmware | S18 | L |
| S20 | M04.6 | Golden vectors and Dart conformance | firmware, mobile | S19 | M |
| S21 | M04.6 | Target parity build and M04 acceptance review | firmware, root | S20 | M + Owner |
| S22 | M05a | Learning decisions D3–D6, action vocabulary | root | S21 | Owner |
| S23 | M05a | PreferenceLearner v2 + section migration (pure) | firmware | S22 | M |
| S24 | M05a | Policy + ReactionTable (pure) | firmware | S23 | M |
| S25 | M05a | Proof-of-learning experiments + report (E10) | firmware, docs | S24 | L |
| S26 | M05a | Firmware wiring: contexts, day part, explanation | firmware | S25 | M |
| S27 | M05a | Mobile: reaction-referenced feedback, "Why?" view | mobile | S26 | M |
| S28 | M05a | M05a board + phone acceptance | all | S27 | Owner |
| S29 | M05b | Memory decisions D8–D10 | root | S28 | Owner |
| S30 | M05b | MemoryStore, salience, consolidation (pure) | firmware | S29 | M |
| S31 | M05b | Journal, provenance, tombstones, ForgetAll scope (pure) | firmware | S30 | M |
| S32 | M05b | LittleFS log/memory adapters + recovery | firmware | S31, D2 | M + Owner check |
| S33 | M05b | BLE v2 codec (core + Dart) with shared vectors | firmware, mobile | S20 | M |
| S34 | M05b | BLE v2 transport + MTU experiment E8 | firmware, mobile | S33 | M + Owner check |
| S35 | M05b | Bonding spike E9 → ADR-0005 | firmware, mobile | S34 | M + Owner |
| S36 | M05b | Permission tiers + destructive confirmation | firmware, mobile | S35, D10 | M |
| S37 | M05b | Mobile Journal / Memory & Privacy (Hive), deletion sync | mobile | S32, S36 | L |
| S38 | M05b | M05b acceptance | all | S37 | Owner |
| S39 | M05c | Conversation domain + LocalRuleExtractor (Dart) | mobile | S29 | M |
| S40 | M05c | Device facts and fact commands | firmware | S38 | M |
| S41 | M05c | Confirmation UI, grounded replies, recall | mobile | S39, S40 | M |
| S42 | M05c | M05c acceptance (+ optional V2 spike after D11) | all | S41 | Owner |
| S43 | M05d | HabitPredictor + prequential scoring (pure) | firmware | S26 | M |
| S44 | M05d | SkillBook and competency bands (pure) | firmware | S43 | M |
| S45 | M05d | Dual-history Life Lab evaluation report | firmware, docs | S44 | M |
| S46 | M05d | Wiring, mobile projection, M05d acceptance | all | S45 | M + Owner |

M05a (S22–S28) and the M05b preparation (S29–S33) may interleave after S21. M05c depends on M05b's facts and bonding.

---

## 4. Standard commands

Paths are relative to the root `xuna_pet/`. On Windows, run them in a PlatformIO-enabled VS Code terminal, or call `%USERPROFILE%\.platformio\penv\Scripts\pio.exe` directly.

```sh
# Firmware target build (pinned toolchain, A9)
pio run -d firmware -e xuna_t_display_s3

# Host tests — before S04 (existing manual runners)
c++ -std=c++11 -Wall -Wextra -Werror -Ifirmware/include firmware/test/test_core.cpp -o "$TMP/xuna-core" && "$TMP/xuna-core"
c++ -std=c++11 -Wall -Wextra -Werror -Ifirmware/include firmware/test/test_life.cpp -o "$TMP/xuna-life" && "$TMP/xuna-life"

# Host tests — from S04
pio test -d firmware -e native
pio test -d firmware -e native_asan      # macOS/Linux/WSL only

# Mobile (after S00 pins Flutter)
cd mobile && fvm flutter analyze && fvm flutter test
```

---

## 5. NVS backup and restore procedure (protect the owner's pet)

Run this **before** uploading any firmware that changes storage (S11, S13, S32). Confirm the serial port first with `pio device list`.

```sh
pio pkg exec -p tool-esptoolpy -- esptool.py --chip esp32s3 --port <PORT> read_flash 0x9000 0x5000 nvs-backup-YYYYMMDD.bin
# restore if needed:
pio pkg exec -p tool-esptoolpy -- esptool.py --chip esp32s3 --port <PORT> write_flash 0x9000 nvs-backup-YYYYMMDD.bin
```

The offsets come from Arduino-ESP32 2.0.14 `default_16MB.csv` (verified 2026-10-12). Check the `pio pkg exec` syntax on first use. Store backups outside the repositories; they may contain personal data later.

---

## 6. Session details — Preparation and M04 (fully detailed)

### S00 — Development environment and baseline

- **Goal:** a working, recorded toolchain on the machine(s) that will be used, with baseline results that match the recorded evidence.
- **Preconditions:** none.
- **Steps:**
  1. **Choose the work machines with the owner:**
     - Windows (this machine) for firmware build/upload, host tests and Flutter unit tests.
     - macOS for iOS builds and running on an iPhone.
     - Record the choice.
  2. **Install the PlatformIO IDE extension** in VS Code. It installs PlatformIO Core and its own Python. Verify `pio --version` and record the Core version (previous sessions used 6.2.0).
  3. **Install a host compiler for `native` tests.** The owner chooses:
     - **A:** MSYS2 UCRT64 `mingw-w64-ucrt-x86_64-gcc`, added to PATH. Fast, but no AddressSanitizer.
     - **B:** a WSL Ubuntu distribution with `g++`. Supports ASan/UBSan.
     - Recommendation: A for daily tests, B (or the Mac) for sanitizer runs.
  4. **Flutter:** `fvm install 3.32.8`.
     - Propose adding `mobile/.fvmrc` pinned to 3.32.8. That file is an owner decision.
     - Until then, run mobile commands with `fvm spawn 3.32.8 ...`. Do not let 3.41.1 rewrite `pubspec.lock`.
  5. **Install Python 3** (python.org or winget). It is not needed until asset tooling (M06), so this step is optional now.
  6. **Baseline runs. Record each result; do not change any source:**
     - Host tests with the manual commands in §4, if a compiler is available.
     - `pio run -d firmware -e xuna_t_display_s3`: compare static RAM and image size with the recorded **47,504 B** and **964,333 B**.
     - Mobile `flutter analyze` and `flutter test`: expect 10 tests passing.
  7. Add a short "Development environment" section to PROCESS.md: machines, versions, PATH notes and baseline results.
- **Done when:** all three baselines pass on at least one machine, or their blockers are recorded; versions are recorded.
- **Out of scope:** source edits, dependency upgrades.

### S01 — MVP physical acceptance (regression reference)

- **Goal:** turn the pending local MVP checks (PLAN MVP-07) into recorded evidence. The refactors in S03–S21 are compared against this.
- **Preconditions:** S00; a phone path decided (iPhone through the Mac, or Android, whose native build is unverified).
- **Steps:**
  1. Back up NVS (§5) before anything else.
  2. Run items 1–10 of "Physical acceptance still open" in [MVP-local.md](MVP-local.md) and record pass/fail with short evidence (serial excerpt, screenshot, observation).
  3. Capture three diagnostics windows with the serial monitor: idle; BLE connected; immediately after a feedback write. Note `loop_gap_max_us` during the feedback write. It is the first real data point for E7.
  4. Do 5 manual power cuts while idle and 5 just after feedback (unplug USB). After each, verify that the preference and episodes are restored.
  5. Record any bug as a new scoped fix session `S01-fix-N`. Fix inline only if it is trivial and the owner approves.
- **Done when:** MVP-local.md has a dated physical-results section and PLAN MVP-07 status is updated.
- **Out of scope:** new features, refactors.

### S02 — Decisions and documentation housekeeping (M04.0)

- **Goal:** record the decisions that unblock M04 and put the planning documents under version control.
- **Preconditions:** S00. Can run in parallel with S01.
- **Steps:**
  1. Walk the owner through D1, D2 (provisional until S11), D7 and D12. Optionally preview D3–D6.
  2. For each decision the owner explicitly approves, add a dated line under AGENTS.md §3 "Approved". Leave the rest Proposed.
  3. Create `docs/decisions/README.md` (index plus a short ADR template: Context, Options, Decision, Consequences, Status).
  4. Create `docs/decisions/ADR-0001-reference-reuse-policy.md` from plan §6.3. Status is *Accepted* only if the owner approves it.
  5. Apply any plan amendments that follow from the decisions, and mark them in the plan header ("0.1.x — amended").
  6. On owner request, commit the spec, the plan, this file and the ADR in the root repo.
- **Done when:** decisions are recorded with status; ADR-0001 exists; Git state is reported.

### S03 — Characterization tests and golden v1 fixtures (M04.1a)

- **Goal:** freeze the current behavior byte-for-byte before moving any code.
- **Preconditions:** S00 (host compiler), D1.
- **Read first:** `firmware/include/LifeEngine.h`, `BleProtocol.h`, `LocalBehavior.h`, `AnimationManager.h`, `test/*.cpp`, and the MVP-local protocol section.
- **Steps:**
  1. Write a throwaway host program (not committed) that uses today's `LifeEngine::encode` to print the snapshot bytes of three states: fresh; after the scripted sequence `quiet/idle reject, play/happy approve ×3`; and saturated counters.
  2. Commit those bytes as `firmware/test/fixtures/v1_snapshots.h` (`const uint8_t[]` arrays), with a comment describing exactly how they were generated.
  3. Add tests:
     - `decode(golden)` gives the expected fields; `encode(state) == golden` byte-for-byte.
     - The `choose()` truth table for every context and count pattern, including ties.
     - A `parseCommand` table covering every opcode × length × argument → error code (0–7).
     - `CommandCache`: hit, conflict, clear, wrap after 16 entries.
     - `recover()` with generation wrap-around (`0xFFFFFFFF` → `0`).
     - `LocalBehavior` timing at rollover.
  4. Run the tests with `-Werror`, and with sanitizers where available.
- **Done when:** the new tests pass against **unchanged** production code.
- **Out of scope:** any production code change.

### S04 — `xuna_core` library and native test environment (M04.1b; T1, T19)

- **Goal:** pure code lives in a library that builds for both the board and the host, with standard tests.
- **Preconditions:** S03.
- **Steps:**
  1. Create `firmware/lib/xuna_core/library.json` (name `xuna_core`, no framework dependency).
  2. Move the pure headers to `lib/xuna_core/include/xuna/` unchanged: `DebouncedButton.h`, `AnimationManager.h`, `LifeEngine.h`, `BleProtocol.h`, `LocalBehavior.h`. Update the includes to `<xuna/...>`.
  3. Split `AppConfig.h`:
     - `xuna/CoreConfig.h` gets the timing constants used by core code (`kDebounceMs`, `kIdleFrameMs`, `kHappyFrameMs`, `kHappyDurationMs`).
     - `src/BoardConfig.h` keeps the pins, rotation, diagnostics period and firmware version.
  4. Add to `platformio.ini`:
     - `[env:native]`: `platform = native`, `test_framework = unity`, `build_flags = -std=c++11 -Wall -Wextra -Werror -Ilib/xuna_core/include`.
     - `[env:native_asan]`: the same flags plus `-fsanitize=address,undefined -fno-omit-frame-pointer`, documented as macOS/Linux/WSL only.
     - Leave `test_build_src` at its default (no), so Arduino sources are never compiled for the host.
  5. Convert `test_core.cpp`, `test_life.cpp` and the S03 tests to Unity suites (`test/test_core/`, `test/test_life/`, `test/test_v1_characterization/`). Keep every assertion.
  6. Add `tools/check_core_purity.py` as a PlatformIO `extra_scripts = pre:` hook for every environment. It uses PlatformIO's own Python and fails the build if anything under `lib/xuna_core` includes `Arduino.h`, `esp_*`, `freertos/`, `TFT_eSPI`, `Preferences.h`, `BLE*` or `soc/`.
  7. Update the firmware README test section.
- **Verify:**
  - `pio test -e native` passes.
  - `pio run -e xuna_t_display_s3` succeeds; record the static RAM and image size delta against S00 (expect ≈ 0).
  - Temporarily add `#include <Arduino.h>` to a core header and confirm the purity check fails, then revert.
- **Done when:** behavior is identical, tests are green and the purity check is proven.
- **Rollback:** revert the commit; no data impact.

### S05 — Fixed-point, PCG32 and ClockModel (pure; M04.2a; T2)

- **Preconditions:** S04.
- **Steps (tests first for each item):**
  1. **`xuna/base/Fixed.h`.**
     - Helpers for Q0.16 and Q16.16: from integer and ratio, multiply with round-half-up, divide, saturating add/sub, clamp.
     - Tests cover 0, 1, max and overflow saturation.
  2. **`xuna/base/Random.h`.**
     - `IRandom` and `Pcg32(seed, stream)` following the PCG reference `pcg32_random_r`.
     - Tests use the reference outputs of the official `pcg32-demo` (initstate 42, initseq 54); copy them from the upstream reference (record the URL) instead of from memory.
     - `below(n)` uses unbiased rejection. Test the distribution coarsely and the `n = 1` edge case.
  3. **`xuna/time/ClockModel.h`** (plan §8.3, §12):
     - `onBoot()`, `onSync(utcMs, tzOffsetMin, source, mono) → SyncResult{accepted|rejected_rollback}`.
     - `quality(mono)`: Synced degrades to Approximate after 24 h.
     - `utcMinute(mono)` returns 0 when unknown. `dayPart(mono)` returns `unknown` when the quality is too low.
     - `lastTrustedUtcMinute` in and out, for persistence.
  4. **Clock tests:** unknown at boot; sync; 24-hour degrade; rollback beyond 5 min rejected; forward jump accepted with a gap flag; tz change; every day-part boundary; 64-bit monotonic values past 2^32 ms.
- **Done when:** native tests are green and the purity check passes. **No firmware wiring yet.**

### S06 — Identity record, `bootc`, hatch/migration (M04.2b; T2, T10, T18)

- **Preconditions:** S05; **D7 answered.**
- **Steps:**
  1. **Pure CRC-32** (IEEE, reflected) with the standard check value `"123456789" → 0xCBF43926`.
  2. **Pure `IdentityRecord` codec:**
     - magic `XI`, schema 1, `petId[16]`, `seed`, `hatchBootCounter`, `hatchActiveSecond`, `bornAtUtcMs`, `bornAtQuality`, `hatchContentVersion`, `origin {hatched, migratedFromV1}`, CRC-32.
     - Tests: roundtrip, corruption, too-new schema.
  3. **Pure `IdentityService::ensure(...)`:**
     - No identity + v1 snapshot present → `migratedFromV1` (S1 Newborn, `bornAt` unknown).
     - No identity and no snapshot → `hatched` (`bornAt` set only if the clock is trusted).
     - Identity present → unchanged. Corrupt identity → **do not regenerate silently**: report `StorageError` and enter the safe path.
     - Unit tests for each branch.
  4. **Firmware `src/storage/StorageKeys.h`:** one registry for all NVS keys (`slot0`, `slot1`, `bootc`, `ident`, and the future `life0`/`life1`), with `static_assert(len ≤ 15)`.
  5. **Firmware boot sequence:**
     - Read `bootc`, increment it and commit it before any event.
     - Call `BLEDevice::init`, then use `esp_fill_random` for a new `petId`/`seed` when hatching.
     - Log `petId` (first 8 hex characters), `bootCounter` and origin on serial.
  6. **Board check (owner):** 3 reboots keep the `petId` and increase `bootc` by one each time; `forget` (opcode 4) leaves the identity unchanged.
- **Done when:** native tests pass, the firmware builds, and the board check is recorded (or marked *not run*).

### S07 — Event envelope, registry, ring buffer, queue (pure; M04.3a; T3)

- **Preconditions:** S04. Can run in parallel with S05/S06.
- **Steps:**
  1. **CRC-16/CCITT-FALSE** with the check value `"123456789" → 0x29B1`.
  2. **`xuna/event/EventTypes.h`:** the registry from plan §7.3, with category and persistence-class flags, and a `static_assert` that codes are unique.
  3. **`xuna/event/Event.h` + `EventCodec.h`:** the 40-byte layout of plan §7.2. Encode and decode field by field, never with `memcpy`.
  4. **`xuna/base/RingBuffer.h`:** template `RingBuffer<T, N>` with no heap.
  5. **`EventIdGenerator(bootCounter)`:** monotonic per-boot sequence. Tests show uniqueness across a simulated reboot.
  6. **`EventQueue`:** `push` (best-effort events are dropped and counted when full; feedback/teach-class events are **rejected** when full) and `drain(sink, budget)`.
- **Tests:** codec roundtrip and CRC detection of single-bit flips; queue overflow counting; drain budget; FIFO ordering; feedback-class rejection.
- **Done when:** native tests are green. No firmware wiring.

### S08 — v1 protocol transcript and core `CommandHandler` (M04.3b)

- **Goal:** move the v1 command semantics out of `BleManager` into pure code, proven byte-identical.
- **Preconditions:** S03, S07.
- **Steps:**
  1. **Write a transcript fixture** describing the v1 contract (MVP-local + the current `BleManager::update` code). Each entry has: input packet bytes, session epoch, local events in the same loop (button), display-ready flag, store success/failure → expected result code, expected 16-byte status, expected 20-byte life value, and expected memory pages. Cover:
     - connect → suggest quiet → feedback approve → life/memory;
     - an identical duplicate (cached result, no re-trigger);
     - the same ID with a different payload → 6;
     - feedback without a decision → 4;
     - a direct button press invalidates a pending decision;
     - a session change clears the cache and the decision;
     - display not ready → 7;
     - a storage write failure → 7 with RAM unchanged;
     - forget → empty, with active seconds kept;
     - queue overflow (no reply).
  2. **Implement `xuna/protocol/CodecV1.h`** (status/life/memory encoders) and **`xuna/life/CommandHandler.h`** using `LifeEngine`, `CommandCache` and an `IStore` interface (in-memory fake for tests). Emit typed events (`BehaviorChosen`, `FeedbackApplied`, `RequestRejected`) into an `EventSink`.
  3. **Make the transcript pass byte-for-byte.**
- **Done when:** the transcript and all earlier suites are green. `BleManager` is untouched in this session.

### S09 — `BleManager` becomes transport-only (M04.3c; T12)

- **Preconditions:** S08; S01 completed (the physical reference).
- **Steps:**
  1. `src/ble/BleTransport`:
     - GATT setup.
     - The write callback enqueues `InboundPacket{bytes, len, sessionEpoch}`.
     - It publishes byte buffers supplied by the core.
     - It contains no business logic.
  2. `src/storage/NvsStore` implements `IStore` over the **existing** `slot0/slot1` format (unchanged).
  3. `main.cpp` loop: drain at most N packets → `CommandHandler` → apply the requested animation → publish; local buttons are still handled last.
  4. Delete the logic now duplicated in `BleManager`.
- **Verify:**
  - Native tests pass; the firmware builds; record the size delta.
  - **Owner regression subset of S01:** connect, the four animations, suggest/feedback/learned choice, reboot persistence, forget + reboot, duplicate/invalid command handling.
- **Done when:** the regression subset is identical to S01. Otherwise stop and fix within the session, or revert.

### S10 — TimeSync end-to-end (M04.2c)

- **Preconditions:** S05, S06, S09.
- **Steps:**
  1. **Design freeze:** append to the MVP-local protocol section:
     - Opcode 5, length 16: header `[ver=1, op=5, requestId u32, arg=source (1 = phone), reserved=0]` + `utcSeconds u32 @8` + `tzOffsetMin i16 @12` + `reserved u16 @14`.
     - A rollback or implausible value returns result 4 (stay within result codes 0–7 so existing parsers keep working).
     - Capability command mask bit 4 (0x10). Mobile keeps requiring bits 0–3 and treats bit 4 as optional.
  2. **Core:** parse opcode 5 in `BleProtocol`, handle it in `CommandHandler` → `ClockModel.onSync` → `TimeSynchronized`/`ClockRejected` event. Persist `lastTrustedUtcMinute` lazily (snapshot v2 arrives later; until then keep it in RAM and log it).
  3. **Tests:** parse table; transcript entries for sync, rollback and the capability bit.
  4. **Firmware:** capability mask `0x001f`; serial log of clock quality, local time and day part every diagnostics window.
  5. **Mobile:**
     - `ProtocolCodec.encode` supports opcode 5.
     - The repository sends TimeSync right after a successful connect when the capability bit is set, and every 6 h while connected.
     - Tests: codec bytes; sent after connect in the simulator repository; skipped without the capability.
  6. **Board + phone check (owner):** after connect, serial shows `Synced` with the correct local time and day part; after a reset it shows `Unknown` until the phone reconnects.
- **Done when:** all tests are green and the owner check is recorded.

### S11 — Storage experiment E4/E5 → ADR-0002 → D2 (M04.4a)

- **Preconditions:** S04. The NVS backup (§5) is taken first.
- **Steps:**
  1. Add a separate `[env:xuna_storage_bench]` with `build_src_filter` selecting `bench/storage_bench.cpp` only. Get owner approval before merging bench code; otherwise keep it on a branch.
  2. **Bench A, NVS:** namespace `xuna_bench` (never `xuna_life`). Do 1,000 A/B writes of a 1,536 B blob. Record write µs p50/p99/max, free heap before and after, and NVS free entries (`nvs_get_stats`).
  3. **Bench B, LittleFS on the `spiffs` partition:**
     - Mount (format on first mount; confirm the partition is unused by XUNA).
     - 10,000 × 40 B appends across 4 KiB segment files, then segment rotation.
     - 200 temp-write + `rename` cycles of a 16 KiB file.
     - Record mount time, write µs p50/p99/max, heap and flash usage.
  4. **Bench C:** rendering the current animation while writing. Record render time and loop gap (E7).
  5. **Power-cut procedure (owner):** 25 cuts per mode during writes. After each reboot, verify A/B newest-valid, log truncation at the first bad CRC, and atomic rename.
  6. Write `docs/research/E4-E5-storage.md` (raw tables, method, limits) and the draft `docs/decisions/ADR-0002-storage-layout.md`, comparing options (b), (c) and (d) of plan §15 M04.4.
  7. The owner decides D2.
- **Done when:** measurements are recorded and D2 is answered.

### S12 — Sectioned snapshot v2 codec + v1→v2 migration (M04.4b; T6, T18)

- **Preconditions:** D2 answered; S03 fixtures; S06 CRC-32.
- **Steps:**
  1. **Design freeze:** write the exact v2 layout into plan §7.5:
     - Header: magic, schema, size, generation, flags.
     - Section table: section IDs for counters, clock, lifecycle, needs, learner, habit, skills, dedup, pointers.
     - Per-section version and length, plus a CRC-32 trailer.
     - The budget is ≤ 1,536 B.
     - In M04 only the sections already backed by code are populated. The rest load defaults.
  2. **`xuna/persist/SnapshotCodec.h`:** `encode`/`decode` returning `LoadResult {Ok, Missing, Corrupt, TooNew, Migrated, MigrationFailed}`.
  3. **`xuna/persist/Migrations.h`:** `fromV1(bytes96)` maps:
     - counts → coarse learner cells (`alpha = 1 + pos`, `beta = 1 + neg` in Q16.16);
     - the 8 episodes → a pending migration list for M05b (or a temporary episodes section);
     - `activeSeconds`, `eventCount`, `generation`.
  4. **Tests:**
     - Every S03 golden v1 fixture migrates with the expected field values.
     - v2 roundtrip; flipped bit → Corrupt; truncated → Corrupt.
     - Header schema 3 or an unknown required section → TooNew.
     - Size ≤ budget.
- **Done when:** native tests are green and the plan §7.5 offsets are frozen.

### S13 — Persistence v2 wiring, safe mode, commit budget (M04.4c)

- **Preconditions:** S12, S06. **NVS backup taken (§5).**
- **Steps:**
  1. `NvsStore` writes v2 A/B under `life0/life1`. On the first boot after the upgrade it reads `slot0/slot1`, migrates once, and **leaves `slot0/slot1` untouched** for one release (rollback point).
  2. `TooNew`/`Corrupt` identity → `ERROR_SAFE` read-only mode: safe face on the LCD, error code on serial and in BLE status, no writes.
  3. Commit classes (plan §7.6) and a commit-budget counter. The counter writes are logged in the diagnostics line, and an over-budget event raises `StorageError(budget)`.
  4. Mount LittleFS if D2 chose it (no data yet). Log the result.
- **Owner checks:**
  - Upgrade the owner's **real MVP pet**: the learned choices are identical after the upgrade (the key acceptance).
  - Reboot ×3; forget + reboot.
  - 20 power cuts during feedback writes: no identity loss and no double-applied feedback.
  - Downgrade test (flash 0.2.0-mvp): it still reads its v1 slots, as documented.
- **Done when:** the checks are recorded and PROCESS.md notes the new storage keys.

### S14 — ActivityFsm (pure; M04.5a; T11)

- **Steps:**
  1. Plan §8.1 const transition table: 9 states, a reason code per rejection, a maximum dwell time per state, and guards (energy, stage, busy).
  2. Exhaustive 9×9 pair test against the table; timeout test per state; `ErrorSafe` exits only through `Booting`; `EvolutionTransition` is not interruptible.
- **Done when:** native tests are green.

### S15 — Needs, mood, bounded catch-up (pure; M04.5b; T3, T4)

- **Steps:**
  1. `Needs {energy, stimulation}` in Q0.16 with closed-form decay over monotonic time. All parameters go in a `LifeTuning` struct (placeholders, documented as [P]).
  2. `Mood` axes (arousal, valence) derived from needs and recent events, with hysteresis latches (ePet `cross()` pattern). The visible label is derived from the axes.
  3. Tests:
     - Stepped integration equals catch-up for gaps up to `UINT32_MAX` ms.
     - No flicker at thresholds.
     - Cold boot resets to defaults; no catch-up across power-off.
     - Clamping holds.
- **Done when:** native tests are green.

### S16 — Action registry, request validator, VisualIntent, idle selector (pure; M04.5c; T13, T15)

- **Steps:**
  1. `ActionDescriptor` const table (plan §14.3) for the current actions (idle, happy, sleep, curious) with `ParamSpec`, `minStage`, `cooldownMs`, `energyCost` and `permissionTier` (only `public` in M04).
  2. `RequestValidator`: action exists, parameters in range, FSM allows it, cooldown passed, energy OK. Deny by default. Every decision becomes an event or counter.
  3. `VisualIntent` enum + `ExpressionMap` with a fallback chain (T7, T15).
  4. `BehaviorSelector` for idle micro-behaviors: a utility score from needs, mood, novelty and cooldown, with PCG32 tie-breaks. Weights live in `LifeTuning`.
  5. Tests: validator table, fallback resolution for every intent × stage, and selector determinism with a fixed seed.
- **Done when:** native tests are green.

### S17 — Wire FSM and visuals into firmware (M04.5d)

- **Steps:**
  1. Remote animation requests go through `RequestValidator`. A rejection returns `busy (5)`. Check that mobile shows a clear message for result 5; add a mobile test if missing.
  2. `AnimationManager` becomes renderer-side frame timing, driven by `VisualIntent`. `DisplayManager` renders through the expression map and falls back to idle for unknown intents.
  3. Sleep handling: a remote request while `SLEEPING` wakes first (an MVP behavior change, documented in MVP-local).
- **Owner check:** four expressions; sleep/wake; a rejected request shows the message; render mean/max within +20% of the baseline (3.49–3.51 / 3.69 ms).
- **Done when:** the owner check is recorded.

### S18 — `LifeCore::step` composition (M04.6a)

- **Steps:**
  1. Compose ClockModel, Identity, EventQueue, CommandHandler, ActivityFsm, Needs/Mood, RequestValidator, BehaviorSelector and LifeEngine (v1 learner, still) behind `LifeCore::step(StepInput) → StepOutput` (plan T1 interface).
  2. `main.cpp` keeps only the adapters, the loop order and diagnostics.
  3. Persist through `PersistRequest` outputs.
- **Done when:** the transcript, all suites and the firmware build are green, and a short owner smoke test (connect, feedback, reboot) passes.

### S19 — Life Lab CLI, trace DSL, Scenarios D/E, 100-day run (M04.6b; T5)

- **Steps:**
  1. **Design freeze:** document the trace grammar in `firmware/sim/README.md`. Lines are `@+<ms> <verb> <args>`, with these verbs:
     - `button A|B`, `cmd <hex>`, `sync <utc> <tz>`, `reboot`, `powercut`, `day <n>`, `expect <path> <op> <value>`.
     - Comments start with `#`.
     - No JSON parser is needed.
  2. `firmware/sim/lifelab.cpp`, built through `[env:lifelab]` (native, `build_src_filter` = `sim/`) or a documented host command. It uses an in-memory store that simulates A/B and power cuts.
  3. Outputs: a metrics CSV, a final snapshot hash and an explanation dump.
  4. Scenarios:
     - **D**, no feedback for 100 days: the learner is bit-identical to a fresh one.
     - **E**, 10 reboots and 5 power cuts: no duplicate feedback, identity stable, no negative age.
     - **Stability**, 100 days with invariants checked every step.
- **Done when:** the scenarios pass in CI-style runs; runtime is reported (it should take seconds).

### S20 — Golden vectors and Dart conformance (M04.6c; G17)

- **Steps:**
  1. `lifelab golden` writes `firmware/sim/golden/learning_v1.json`: command sequences with expected device results and life bytes.
  2. Copy the vectors into `mobile/test/fixtures/` with a documented update procedure (no cross-repo symlinks).
  3. Mobile tests replay them against `SimulatorDeviceRepository` and `ProtocolCodec`. Any mismatch fails.
- **Done when:** both repos are green.

### S21 — Target parity and M04 acceptance review (M04.6d; E2, E6)

- **Steps:**
  1. `[env:xuna_parity]` embeds 3 traces, replays them at boot without BLE or display, prints the snapshot hashes and `step()` timing histograms, then halts.
  2. Compare with the Life Lab hashes, which must be bit-identical.
  3. Write `docs/roadmap/M04-foundation.md`: acceptance table per slice, measurements (RAM, image, heap, render, loop gap, commit counts, `step()` p99), open issues and the decision log.
  4. Owner review: M04 is Implemented; it is **Validated** only for the rows that have evidence.
- **Done when:** the record is written and the owner confirms.

---

## 7. Session details — M05 (detailed; refine at session start)

Every session below starts with a **design-freeze step**: write the exact payloads, constants or APIs into the plan or a roadmap record, then write tests, then implement.

### S22 — Learning decisions and action vocabulary (Owner)

- Answer D3 (feedback window), D4 (exploration), D5 (contexts and actions: day parts, GPIO0 as a learning context, 3–4 actions aligned with real animations) and D6 (implicit feedback).
- Output: the action list with animation IDs, an art to-do list if new animations are needed, and approved parameter ranges, recorded in AGENTS §3 / plan §9.

### S23 — PreferenceLearner v2 (pure)

- Fixed-point discounted Beta, coarse and fine cells, hierarchical prior (plan §9.3); learner section v2 with a migration from the M04 coarse cells.
- Tests:
  - Discount only touches the rated cell.
  - Silence leaves values unchanged.
  - Exact fixed-point values on the golden examples.
  - Prior transfer to an unseen day part.
  - Saturation bounds.

### S24 — Policy + ReactionTable (pure)

- Masked ε-greedy with confidence scaling and least-rated exploration; PCG32 tie-breaks (plan §9.4).
- ReactionTable: 4 entries, expiry window (D3), invalidation, consumed state, durable rating via `PersistRequest`.
- Tests:
  - Only allowed actions are chosen.
  - The ε bounds hold.
  - The exploration rate matches its configuration over 10k draws.
  - Expired, consumed, invalidated and unknown reactions are rejected.
  - A duplicate `CommandId` is applied once.

### S25 — Proof-of-learning experiments (E10)

- Life Lab scenarios B, C, D, isolation, E and spam (plan §9.9), each over 200 seeds, against random, static and no-learning baselines. Compare ε-greedy, UCB and Thompson (Thompson is host-only).
- Output: `docs/research/M05a-learning-report.md` with CIs, convergence and reversal curves (CSV), and the chosen defaults.
- The owner reviews the defaults.

### S26 — Firmware wiring

- Day-part contexts (needs S10). GPIO0 greeting as a learning context, if D5 approves it.
- A v1-additive explanation read characteristic (20 bytes, last decision's context), with its payload frozen in this session.
- The board demo script is prepared for S28.

### S27 — Mobile

- Feedback refers to the reaction. A "Why did XUNA do that?" view renders only the explanation fields. Day-part display.
- Golden vectors are updated through S20's procedure. Tests are green.

### S28 — M05a acceptance (Owner)

- Board + phone:
  - A preference forms in one context and stays isolated from the others.
  - It survives a reboot and works offline (phone off).
  - The explanation counts match the actual feedback.
  - Reversal adapts.
- Record in `docs/roadmap/M05a-learning.md`.

### S29 — Memory decisions (Owner)

- D8 (fact allowlist and capacities, a nickname on the device), D9 (ForgetAll scope), D10 (bonding approach).

### S30 — MemoryStore, salience, consolidation (pure)

- Records from plan §10.4, integer salience, promotion and eviction rules, pattern merge, and protected classes.
- Tests: a bounded store after 10,000 events; protected records survive; determinism.

### S31 — Journal, provenance, tombstones (pure)

- Journal records cite evidence IDs; enforcement of the provenance enum; tombstones; ForgetAll per D9; migration of the 8 v1 episodes kept from S12.
- Tests:
  - A `user_stated` fact is never rendered as observed.
  - The `simulated` provenance is rejected in production builds.
  - Deletion leaves a tombstone.

### S32 — LittleFS adapters + recovery (firmware)

- Segmented log, truncation at the first bad CRC, memory file with temp+rename and a generation cross-check against the snapshot.
- Owner: 25 power cuts during appends and renames.

### S33 — BLE v2 codec (core + Dart)

- Freeze the `Hello`, frame header and payload layout of every v2 request (plan §14.1) in the protocol record.
- Shared test vectors are consumed by both the C++ and Dart tests.
- Fragmentation, resume and CRC tests.

### S34 — BLE v2 transport + E8

- Characteristics `7a6e0008`–`000A`.
- Mobile repository v2 with v1 fallback.
- Measure the negotiated MTU and the heap on the owner's phone.

### S35 — Bonding spike (E9) → ADR-0005

- Arduino `BLESecurity`, LE Secure Connections with the passkey shown on the LCD; iOS pairing, reconnect, removed bond, unbonded rejection.
- Recommendation for D10 confirmation.

### S36 — Permission tiers + destructive confirmation

- Validator tiers enforced at dispatch. ForgetAll and ForgetFact require a bonded link plus a button press within 10 s.
- Mobile UX for the confirmation.

### S37 — Mobile Journal and Memory & Privacy

- Hive boxes; journal timeline; fact list with delete; forget all; reconnect sync after the last `EventId`; tombstones applied.
- Tests: no resurrection from a stale cache.

### S38 — M05b acceptance (Owner)

- Plan §15 M05b acceptance items on the board and phone. Record in `docs/roadmap/M05b-memory.md`.

### S39 — Conversation domain + LocalRuleExtractor (Dart)

- Dart interfaces from plan §11.3; `CandidateEvent`; the vi/en rule grammar from plan §11.2, frozen with a phrase table.
- Tests: table tests including negative, hypothetical and injection cases.

### S40 — Device facts and commands

- `TeachFact`, `SupersedeFact`, `ForgetFact`, `ReadFacts` (v2), FactRecord store with the allowlist, `CommandId` dedup, and a bonded-only tier.
- Tests: validation table; supersede chain; tombstone.

### S41 — Confirmation UI, grounded replies, recall (mobile)

- The confirmation screen shows exactly what will be stored and its provenance.
- Replies are built only from device-confirmed data.
- Offline: local rules still work.
- Scenario F test.

### S42 — M05c acceptance (Owner) + optional V2 spike

- Nickname taught → shown after a reboot; stated preference → prior shift with `user_stated` provenance; correction; forget.
- The V2 STT/LLM spike (E12) only runs after D11. It is research output, not product code.

### S43 — HabitPredictor + prequential scoring (pure)

- Plan §9.7. Tests: decay only on trusted days; sparse-data uncertainty; prequential baselines.

### S44 — SkillBook and competency bands (pure)

- Plan §9.8 skills with hysteresis.
- Test: a pet with age but no feedback has no learning skill.

### S45 — Dual-history Life Lab evaluation

- Spec §23.10 report: same seed, two histories, held-out contexts, restart parity, routine change.
- Output: `docs/research/M05d-cognitive-report.md`.

### S46 — Wiring, mobile projection, M05d acceptance

- Anticipation pose gated by settings; competency view in the app; owner acceptance record.

---

## 8. After M05d

M06 (growth/evolution: art scope, layered assets, `GrowthConfig`) and M07 (sensors) are split into sessions **when M05d is accepted**, using that milestone's measurements. Pre-splitting them now would conflict with AGENTS.md §4, which says not to build later milestones speculatively.

## 9. Recommended next three sessions

1. **S00** — toolchain and baseline on this machine.
2. **S02** — decisions D1, D2 (provisional), D7, D12 and ADR-0001. This can share a sitting with the S00 owner steps.
3. **S01** — MVP physical acceptance with the phone. It must finish before S09 changes the BLE path.

S03–S08 are pure host work and can proceed while S01 waits for the phone, as long as S00 and D1 are done.

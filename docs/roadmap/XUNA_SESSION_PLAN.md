# XUNA — Implementation Session Plan

**Status:** Proposed. This file breaks [XUNA_IMPLEMENTATION_PLAN.md](../architecture/XUNA_IMPLEMENTATION_PLAN.md) (XUNA-TIP-001) into small, independently verifiable work sessions. **It does not approve any session.** Each session starts only after the owner asks for it, and after its listed decisions are answered.
**Date:** 2026-10-12 · **Revision:** 3. Device-first direction update; audit history preserved. D17 is Approved; D15 and VOICE implementation choices remain Proposed. S00–S46 numbering is retained.
**Audience:** the owner, plus the coding agent or engineer who runs each session.

Plan references:

- `§x` means a section of XUNA-TIP-001.
- `Tn` is a technique card (§6), `Dn` an owner decision (§18), `En` an experiment (§16.2), `Gn` a gap (§4).

---

## 1. Is the technical plan detailed enough to implement?

**Short answer:** it is detailed enough to **start M04 now** (sessions S00–S10). The owner approved D1, D7, D12, D14 and D17 on 2026-10-12 (AGENTS.md §3). It is **not** a complete line-by-line specification for M05+. The missing details are intentionally deferred: they depend on earlier measurements and decisions, and specifying them now would produce work that has to be redone.

| Area | Ready? | What is still missing | Closed in |
|---|---|---|---|
| Architecture, module boundaries, principles | Yes | — | — |
| M04.1 core extraction | Yes | Toolchain on this machine (below) | S00, S03–S04 |
| M04.2 clock/RNG/identity | Mostly | Exact TimeSync/Hatch bytes, hatch gesture and Egg-state exposure (D7 approved) | S05–S06, S10 |
| M04.3 events + command handler | Mostly | The v1 transcript must come from **observed** bytes (S01) as well as code reading | S01, S07–S09 |
| M04.4 persistence v2 | **No** | D2 is decided only after measurements E4/E5; byte offsets not frozen | S11–S13 |
| M04.5 FSM/needs/visuals | Yes for pure logic | Threshold values are placeholders, tuned in Life Lab | S14–S17 |
| M04.6 Life Lab | Partly | Trace grammar and golden-file format | S18–S21 |
| M05a learner v2 | Algorithm yes | D3–D6, action vocabulary aligned with art, E10 parameter choice | S22–S28 |
| **M05c-A conversation foundation** (with M05a) | Contract yes (§11.6) | D17 approved; phrase table, optional voice (E13, D16) | S22, S24a, S26, S39, S27a, S27b, S28 |
| M05b memory/journal/BLE v2 | Partly | D8, D9; E8 MTU; E9 bonding → D10; v2 payload layouts | S29–S38 |
| M05c-B conversation + memory | Partly | D8, D10; V2 needs D11a → E12 → D11 | S40–S42 |
| M05d cognitive gates | Algorithm yes | Thresholds are hypotheses until Life Lab data; order vs Evolution MVP (D15) | S42a, S43–S46 |
| M06 / M07 | Outline only | Broken down after checkpoint S42a (rolling-wave planning) | later |

**Historical prerequisites observed on Windows (2026-10-12; recheck on the actual session machine):**

- No PlatformIO, so no `pio`.
- No host C/C++ compiler (`gcc`/`clang`).
- `python` is only the Microsoft Store alias.
- WSL is present but has no Linux distribution.
- **Flutter:**
  - fvm default is 3.41.1, and there is **no `mobile/.fvmrc`**.Í
  - `pubspec.lock` requires Flutter ≥ 3.27.0 / Dart ≥ 3.7.0.
  - Validation evidence exists only for 3.32.8 / Dart 3.8.1 (macOS).
  - **D14 approved 2026-10-12:** pin 3.32.8 via `mobile/.fvmrc` (not yet created; S00).
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
3. **Characterize before refactoring.** Capture current behavior as golden bytes or transcripts before moving code (S01, S03, S08a). **S01 is the behavioral baseline: no refactored or storage-changing firmware is uploaded to the owner's board before S01 is recorded.**
4. **Tests first** for core logic: add failing tests, implement, then make them pass.
5. **Keep the build green.** At the end of every session the firmware builds, host tests pass, and protocol v1 still works, unless the session says otherwise.
6. **Protect the owner's pet data.** Before any upload that changes storage code, take a verified NVS backup (§5). Benchmarks use a separate NVS namespace, never touch `xuna_life`, and clean up afterwards.
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
10. **Evidence before decisions.** The order is experiment → evidence → ADR → owner decision → implementation.
    - An experiment may need the owner's *authorization to run* it (cost, privacy, hardware risk). For example, D11a authorizes E12.
    - That authorization is not the decision the experiment informs.
11. **Framework boundary.**
    - Arduino-ESP32 2.0.14 on the LILYGO T-Display-S3 is the current adapter framework. It is authorized for bring-up and pinned for the local MVP (A9). The long-term Arduino versus ESP-IDF choice stays open (AGENTS §3).
    - Nothing in `lib/xuna_core` may depend on it (purity check, S04).
    - Custom PCB, HoloCubic and other hardware remain Future.

Session size estimates (one focused AI-assisted sitting = 2–4 h):

- **S** — about half a sitting.
- **M** — one sitting.
- **L** — avoided; split into suffixed sessions.
- **Owner** — needs the owner's physical action or decision.

**Branches:** keep the current practice of working on `dev` in each repository unless the owner asks for per-session branches (`feat/sNN-...`).

---

## 3. Session map

Session IDs are kept stable. Suffixes (`a`, `b`) mark splits or additions from the audit. Rows are in recommended execution order.

**2026-10-16 owner gate simplification (AGENTS §3):** S01 closed with owner-skipped items; D2a (snapshot v2 in NVS A/B) replaces the S11 prerequisite of S13; S13 + S18 run as one integration that absorbs S08b/S09, with S08a as the byte-compatibility regression; S10 splits into S10-sync (after the integration) and S10-hatch (deferred); S23/S24 are superseded. The table keeps the original rows for history; the bold notes override their Needs column.

| ID | Slice | Title | Repo(s) | Needs | Size |
|---|---|---|---|---|---|
| S02 | M04.0 | ADR-0001 + decisions index (D1, D7, D12, D14, D17 already approved 2026-10-12) | root | — | S |
| S00 | prep | Development environment and baseline | all (no code) | D14 for the Flutter pin | M + Owner |
| S01 | M04.0 | MVP physical acceptance + observed v1 byte capture (behavioral baseline). **Closed 2026-10-16 — Accepted with owner-skipped items** (AGENTS §3) | firmware, mobile | S00, phone path | Owner |
| S03 | M04.1 | Characterization tests and golden v1 fixtures | firmware | S00, D1 | M |
| S04 | M04.1 | `xuna_core` library and native test environment | firmware | S03 | M |
| S05 | M04.2 | Fixed-point, PCG32, ClockModel (pure) | firmware | S04 | M |
| S06 | M04.2 | Identity record, `bootc`, hatch/migration | firmware | S05, D7; **board step: S01 + §5 backup** | M + Owner check |
| S07 | M04.3 | In-RAM events, registry, ring buffer, queue (pure) | firmware | S04 | S |
| S08a | M04.3 | v1 transcript fixture (from S01 observed bytes + code) | firmware | S03, S01 | S |
| S08b | M04.3 | Core `CommandHandler` reproducing v1 byte-exactly. **Folded into the merged S13+S18 integration (2026-10-16)** | firmware | S07, S08a | M |
| S09 | M04.3 | `BleManager` becomes transport-only. **Folded into the merged S13+S18 integration (2026-10-16)** | firmware | S08b, S01 | M + Owner check |
| S10 | M04.2 | TimeSync + app hatch (opcodes 5, 7). **2026-10-16: split into S10-sync (after S13+S18) and S10-hatch (deferred)** | firmware, mobile | S05, S06, S13+S18, D14 | M + Owner check |
| S11 | M04.4 | Storage experiment E4/E5 → ADR-0002 → **D2**. **Deferred to S32 (D2a approved 2026-10-16)** | firmware (bench) | S04, §5 backup | M + Owner |
| S12a | M04.4 | Snapshot v2 layout freeze + sectioned codec | firmware | S06, D2 | M |
| S12b | M04.4 | v1→v2 migration + torn-write simulation | firmware | S12a, S03 | M |
| S13 | M04.4 | Persistence v2 wiring, safe mode, commit budget. **Merged with S18 (2026-10-16)** | firmware | S12b, S08a, D2a, §5 backup | M + Owner check |
| S14 | M04.5 | ActivityFsm (pure) | firmware | S07 | M |
| S15 | M04.5 | Needs, mood, bounded catch-up (pure) | firmware | S05 | S |
| S16 | M04.5 | Action registry, request validator, VisualIntent, idle selector (pure) | firmware | S14, S15 | M |
| S17 | M04.5 | Wire FSM and visuals into firmware; renderer fallback. **Closed 2026-10-16 on owner smoke; render ±20% not measured** | firmware | S16, S09 | M + Owner check |
| S18 | M04.6 | `LifeCore::step` composition; thin `main.cpp`. **Merged with S13 (2026-10-16)** | firmware | S17, S13 | M |
| S19a | M04.6 | Life Lab CLI + trace DSL + runner | firmware | S18 | M |
| S19b | M04.6 | Scenarios D/E + 100-day invariants | firmware | S19a | M |
| S20 | M04.6 | Golden vectors and Dart conformance | firmware, mobile | S19b, D14 | M |
| S21 | M04.6 | Target parity build and M04 acceptance review | firmware, root | S20 | M + Owner |
| S22 | M05a/c-A | Learning + conversation decisions: D3–D6, D17, vocabulary, phrase scope (D16 optional) | root | can run any time after S02; must precede S23/S39 | Owner |
| S23 | M05a | PreferenceLearner v2 + section migration (pure). **Superseded by E10 learner v3 / S18-prep** | firmware | S22, S21 | M |
| S24 | M05a | Policy + ReactionTable (pure). **Superseded by E10 UCB + D3 in `ProductLearner`** | firmware | S23 | M |
| S24a | M05c-A | Stated-preference evidence + opcode 6 handling (pure) | firmware | S24, D17 | S |
| S25 | M05a | Proof-of-learning experiments + report (E10, incl. stated vs rated) | firmware, docs | S24a | M |
| S26 | M05a/c-A | Firmware wiring: contexts, day part, explanation, opcode 6 + capability bit 5 | firmware | S25 | M |
| S39 | M05c-A | Conversation domain + LocalRuleExtractor (Dart), Layer A intents | mobile | S22, S20 (can run in parallel with S23–S26) | M |
| S27 | M05a | Mobile: reaction-referenced feedback, "Why?" view | mobile | S26 | M |
| S27a | M05c-A | Mobile: conversation foundation wiring (candidate → confirm → opcode 3/6 → explanation) | mobile | S27, S39 | M |
| S27b | M05c-A | *Optional:* push-to-talk with on-device STT (E13 → D16) | mobile | S27a, D16 | M |
| S28 | M05a/c-A | **Joint** M05a + Conversation Foundation acceptance | all | S27a (S27b if approved) | Owner |
| S29 | M05b | Memory decisions D8, D9 | root | can run any time; must precede S30 | Owner |
| S30 | M05b | MemoryStore, salience, consolidation (pure) | firmware | S29, S21 | M |
| S31 | M05b | Journal, provenance, tombstones, ForgetAll scope (pure) | firmware | S30 | M |
| S32 | M05b | Persisted event codec + LittleFS log/memory adapters + recovery | firmware | S31, D2, §5 backup | M + Owner check |
| S33 | M05b | BLE v2 codec (core + Dart) with shared vectors | firmware, mobile | S20 | M |
| S34 | M05b | BLE v2 transport + MTU experiment E8 | firmware, mobile | S33 | M + Owner check |
| S35 | M05b | Bonding experiment E9 → ADR-0005 → **D10** | firmware, mobile | S34 | M + Owner |
| S36 | M05b | Permission tiers + destructive confirmation | firmware, mobile | S35, D10 | M |
| S37 | M05b | Mobile Journal / Memory & Privacy (Hive), deletion sync | mobile | S32, S36 | M (split if needed) |
| S38 | M05b | M05b acceptance | all | S37 | Owner |
| S40 | M05c-B | Device facts and fact commands | firmware | S38, D8 | M |
| S41 | M05c-B | Fact confirmation, grounded replies, recall (mobile) | mobile | S40, S27a | M |
| S42 | M05c-B | M05c-B acceptance (+ optional V2 spike after D11a) | all | S41 | Owner |
| S42a | checkpoint | Product checkpoint **D15**: M05d first or Evolution MVP first | root | S28, S38, S42 | Owner |
| S43 | M05d | HabitPredictor + prequential scoring (pure) | firmware | S26, S42a | M |
| S44 | M05d | SkillBook and competency bands (pure) | firmware | S43 | M |
| S45 | M05d | Dual-history Life Lab evaluation report | firmware, docs | S44 | M |
| S46 | M05d | Wiring, mobile projection, M05d acceptance | all | S45 | M + Owner |

Parallelism:

- After S21, the M05a/M05c-A track (S22–S28) and the M05b preparation (S29–S33) may interleave.
- S39 (pure Dart) can run alongside S23–S26.
- M05c-B depends on M05b's facts and bonding.
- If D15 chooses the Evolution MVP first, its sessions are inserted after S42a and S43–S46 move after it.

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

# Mobile — after D14 pins the SDK in mobile/.fvmrc
cd mobile && fvm flutter analyze && fvm flutter test
```

---

## 5. Verified NVS backup and restore (protect the owner's pet)

Take a backup **before** any upload that changes storage code or replaces the firmware (S06 board step, S11, S13, S32). Do not run any of this as part of a documentation or audit task.

**Facts this relies on** (verified 2026-10-12 against Arduino-ESP32 2.0.14):

- The ESP32-S3 SDK sets `CONFIG_PARTITION_TABLE_OFFSET=0x8000`.
- `tools/gen_esp32part.py` ships with the framework.
- The project uses `board_build.partitions = default_16MB.csv`, which contains `nvs 0x9000 0x5000`.

**Never trust the hard-coded numbers.** Always read the table from the device.

```sh
pio device list                                   # identify <PORT>
ESPTOOL="pio pkg exec -p tool-esptoolpy -- esptool.py --chip esp32s3 --port <PORT>"
PIOPY="$HOME/.platformio/penv/Scripts/python.exe" # macOS/Linux: ~/.platformio/penv/bin/python
GEN="$HOME/.platformio/packages/framework-arduinoespressif32/tools/gen_esp32part.py"

# 1. Read and decode the partition table that is ACTUALLY on the device
$ESPTOOL read_flash 0x8000 0xC00 ptable-device-YYYYMMDD.bin
"$PIOPY" "$GEN" ptable-device-YYYYMMDD.bin        # prints CSV; note the nvs row (offset, size)

# 2. Cross-check with the table of the firmware you are about to flash
"$PIOPY" "$GEN" firmware/.pio/build/xuna_t_display_s3/partitions.bin
#    If the nvs rows differ, STOP: a partition change needs its own approved migration plan (D2).

# 3. Back up exactly the device's nvs range (today expected 0x9000 / 0x5000)
$ESPTOOL read_flash <NVS_OFFSET> <NVS_SIZE> nvs-backup-YYYYMMDD.bin
#    Optional, most robust: full 16 MiB image
$ESPTOOL read_flash 0x0 0x1000000 full-backup-YYYYMMDD.bin

# 4. Record the SHA-256 of each file, the firmware version and the decoded table in the session notes
```

Notes:

- The ESP32-S3 native USB may need manual download mode: hold BOOT, tap RST, release BOOT.
- Reading flash resets the board.
- Check the `pio pkg exec` syntax on first use.
- Store backups outside the repositories; they may contain personal data later.

**Restore, only on an explicit owner decision:**

1. Re-read and decode the device's table.
2. Proceed only if its `nvs` row equals the row recorded with the backup.
3. Flash firmware that can read that NVS content (the version recorded with the backup, or a later one with a migration path).
4. Then `write_flash <NVS_OFFSET> nvs-backup-YYYYMMDD.bin`.
5. **Never use `erase_flash`.**

---

## 6. Session details — Preparation and M04 (fully detailed)

### S02 — Decisions and documentation housekeeping (M04.0)

- **Goal:** record the decision index and ADR-0001.
- **Partial preparation (device-first documentation update):** decisions index now exists with approved decisions and Proposed ADR-0006. Inspect/extend it; do not overwrite it. ADR-0001 was drafted in S02 on 2026-10-12; documentation deliverables are complete, policy acceptance remains pending.
- **Preconditions:** none.
- **Already done (2026-10-12):**
  - The owner approved D1, D7, D12, D14 and D17. They are recorded in AGENTS.md §3 and plan §18.
  - The plan amendments for D7 are applied: device or app hatch, opcode 7, the Egg state and the `bornAt` rule (§12).
- **Remaining steps:**
  1. Review/extend `docs/decisions/README.md` (created by the device-first documentation update): an index of the approved D-decisions with dates and links, plus a short ADR template (Context, Options, Decision, Consequences, Status).
  2. Create `docs/decisions/ADR-0001-reference-reuse-policy.md` from plan §6.3. Status is *Accepted* only if the owner approves it.
  3. On owner request, commit the ADR, the index and the decision updates.

  **Do not ask for D2 or D10.** Those are decided after their experiments (S11, S35).
- **Done when:** the index and ADR-0001 exist; Git state is reported.

### S00 — Development environment and baseline

- **Goal:** a working, recorded toolchain on the machine(s) that will be used, with baseline results that match the recorded evidence.
- **Preconditions:** D14 for the Flutter part; the rest has none.
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
  4. **Flutter, per D14 (approved 2026-10-12: 3.32.8):**
     - `fvm install <version>`.
     - Add `mobile/.fvmrc`. This is a mobile repo change, so commit it on request.
     - On every machine, verify that `fvm flutter pub get` leaves `pubspec.lock` **unchanged**. A changed lock means the SDK differs from the one that produced it: stop and report.
     - A later SDK upgrade (e.g. 3.41.x) is its own validated session, not a side effect.
  5. **Install Python 3** (python.org or winget). It is not needed until asset tooling (M06), so this step is optional now.
  6. **Baseline runs. Record each result; do not change any source:**
     - Host tests with the manual commands in §4.
     - `pio run -d firmware -e xuna_t_display_s3`: compare static RAM and image size with the recorded **47,504 B** and **964,333 B**.
     - Mobile `flutter analyze` and `flutter test`: expect 10 tests passing.
  7. Add a short "Development environment" section to PROCESS.md: machines, versions, PATH notes and baseline results.
- **Done when:** all three baselines pass on at least one machine, or their blockers are recorded; versions are recorded; the lock is unchanged.
- **Out of scope:** source edits, dependency upgrades.

### S01 — MVP physical acceptance and behavioral baseline

- **Goal:**
  - Turn the pending local MVP checks (PLAN MVP-07) into recorded evidence.
  - Capture **observed protocol bytes**.

  The refactors in S03–S21 are compared against this baseline.
- **Preconditions:** S00; a phone path decided (iPhone through the Mac, or Android, whose native build is unverified). A generic BLE inspector app (e.g. nRF Connect) is recommended for step 3.
- **Steps:**
  1. Take the verified NVS backup (§5) before anything else.
  2. Run items 1–10 of "Physical acceptance still open" in [MVP-local.md](MVP-local.md) and record pass/fail with short evidence (serial excerpt, screenshot, observation).
  3. **Observed v1 transcript.** With the BLE inspector, run a scripted sequence and record the raw hex of every write and of the status, life and memory values after each step:
     - read capabilities, status and life;
     - suggest quiet, then approve;
     - replay a duplicate ID, then the same ID with a different payload;
     - send feedback without a decision;
     - press the button during a pending decision;
     - forget.

     These bytes are the ground truth for S08a.
  4. Capture three diagnostics windows with the serial monitor: idle; BLE connected; immediately after a feedback write. Note `loop_gap_max_us` during the feedback write. It is the first real data point for E7.
  5. Do 5 manual power cuts while idle and 5 just after feedback (unplug USB). After each, verify that the preference and episodes are restored. Record these as *smoke* evidence. A manual cut cannot reliably land inside a write; S11 and S13 use a write-storm build for that.
  6. Record any bug as a new scoped fix session `S01-fix-N`. Fix inline only if it is trivial and the owner approves.
- **Done when:** MVP-local.md has a dated physical-results section and the observed-byte transcript (a text/hex appendix); PLAN MVP-07 status is updated.
- **Out of scope:** new features, refactors.

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
- **Delivery (2026-10-12):** implemented and verified; see [S04 record](S04-portable-core.md). Old flat header/test paths below describe the migration input; current core/test paths are the listed targets. No board upload.
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

- **Delivery (2026-10-12):** pure logic implemented, native/sanitizer suites verified; see [S05 evidence](S05-foundation-primitives.md). No firmware wiring or board upload.

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

- **Partial delivery (2026-10-12):** CRC32, identity codec/service and host tests implemented; [S06 core record](S06-identity-core.md). Storage keys/bootc/RNG/wiring/gesture/test namespace and board checks remain pending. Full S06 is not Done.

- **Preconditions:** S05; D7 (approved 2026-10-12). The **board step** additionally needs S01 recorded and a verified backup (§5), because this session adds NVS writes.
- **Steps:**
  1. **Pure CRC-32** (IEEE, reflected) with the standard check value `"123456789" → 0xCBF43926`.
  2. **Pure `IdentityRecord` codec:**
     - magic `XI`, schema 1, `petId[16]`, `seed`, `hatchBootCounter`, `hatchActiveSecond`, `hatchMonoMs`, `bornAtUtcMs`, `bornAtQuality`, `hatchContentVersion`, `origin {hatchedOnDevice, hatchedViaApp, migratedFromV1}`, CRC-32.
     - Tests: roundtrip, corruption, too-new schema.
  3. **Pure `IdentityService`** (plan §12, D7):
     - **No identity + v1 snapshot present** → `migratedFromV1`: S1 Newborn, `bornAt` unknown, learned state kept.
     - **No identity and no snapshot** → **Egg**: no identity written yet; it waits for a hatch trigger.
     - **Hatch trigger** (device gesture now; app opcode 7 in S10) → create the identity:
       - `bornAt` is exact if the clock is Synced at hatch time;
       - if a sync arrives later in the **same boot**, `bornAt` is filled once from the monotonic anchor;
       - otherwise it stays unknown permanently.
     - **Identity present** → unchanged.
     - **Corrupt identity** → **do not regenerate silently**: report `StorageError` and enter the safe path.
     - Unit tests for each branch, including "a sync in a later boot never back-fills `bornAt`".
  4. **Design freeze — hatch gesture:**
     - Proposed: hold GPIO14 for 3 s in the Egg state. The gesture must not use GPIO0/BOOT, which selects download mode at reset.
     - Pick a placeholder egg visual (simple shape, no new art required).
     - Record both in plan §12.
  5. **Firmware `src/storage/StorageKeys.h`:** one registry for all NVS keys (`slot0`, `slot1`, `bootc`, `ident`, and the future `life0`/`life1`), with `static_assert(len ≤ 15)`.
  6. **Firmware boot sequence:**
     - Read `bootc`, increment it and commit it before any event.
     - Call `BLEDevice::init`, then use `esp_fill_random` for a new `petId`/`seed` at hatch.
     - Log `petId` (first 8 hex characters), `bootCounter`, origin and Egg state on serial.
  7. **Test-only fresh-device mode:**
     - A compile flag selects a separate NVS namespace (e.g. `xuna_test`).
     - This exercises Egg → device hatch on the owner's board **without touching the real pet** in `xuna_life`.
     - Erase that namespace after the test.
- **Board check (owner):**
  - The real pet migrates (origin `migratedFromV1`) with its learned preference unchanged.
  - 3 reboots keep the `petId` and increase `bootc` by one each time.
  - `forget` (opcode 4) leaves the identity unchanged.
  - In the test-only mode: Egg → hold gesture → hatched, with `bornAt` unknown (no phone).
- **Done when:** native tests pass, the firmware builds, and the board check is recorded (or marked *not run*).

### S07 — In-RAM events, registry, ring buffer, queue (pure; M04.3a; T3)

- **Delivery (2026-10-12):** implemented and host-tested; [S07 evidence](S07-events.md). No wiring. Follow-up [S05-fix-01](S05-fix-01-time-epoch.md) resolved the UTC-minute epoch mismatch on 2026-10-12.

- **Preconditions:** S04. Can run in parallel with S05/S06.
- **Scope note (audit):** the persisted 40-byte codec and CRC-16 move to **S32**, where the log is written. Its format then follows D2. This session only covers the in-RAM event model.
- **Steps:**
  1. **`xuna/event/EventTypes.h`:** the registry from plan §7.3, with category and persistence-class flags, and a `static_assert` that codes are unique.
  2. **`xuna/event/Event.h`:** an in-RAM struct with the plan §7.2 fields (`eventId`, `causationId`, `activeSecond`, `utcMinute`, `type`, `source`, `provenance`, `clockQuality`, `confidence`, `privacyClass`, 8-byte payload).
  3. **`xuna/base/RingBuffer.h`:** template `RingBuffer<T, N>` with no heap.
  4. **`EventIdGenerator(bootCounter)`:** monotonic per-boot sequence. Tests show uniqueness across a simulated reboot.
  5. **`EventQueue`:** `push` (best-effort events are dropped and counted when full; feedback/teach-class events are **rejected** when full) and `drain(sink, budget)`.
- **Tests:** queue overflow counting; drain budget; FIFO ordering; feedback-class rejection; ID uniqueness across boots.
- **Done when:** native tests are green. No firmware wiring.

### S08a — v1 transcript fixture (M04.3b-1)

- **Preconditions:** S03, **S01** (observed bytes).
- **Steps:**
  1. Encode a transcript fixture describing the v1 contract. Each entry has: input packet bytes, session epoch, local events in the same loop (button), display-ready flag, store success/failure → expected result code, expected 16-byte status, expected 20-byte life value, and expected memory pages.
  2. **Every case observed in S01 uses the observed bytes.** Cases that cannot be produced physically are derived from the `BleManager::update` code and the MVP-local protocol, and are marked `derived`:
     - display not ready → 7;
     - a storage write failure → 7 with RAM unchanged;
     - queue overflow with no reply.
  3. Required cases:
     - connect → suggest quiet → feedback approve → life/memory;
     - an identical duplicate (cached result, no re-trigger);
     - the same ID with a different payload → 6;
     - feedback without a decision → 4;
     - a direct button press invalidates a pending decision;
     - a session change clears the cache and the decision;
     - forget → empty, with active seconds kept;
     - the derived cases above.
- **Done when:** the fixture compiles and is reviewed. The cases are not yet executed against anything.

### S08b — Core `CommandHandler` (M04.3b-2)

- **Preconditions:** S07, S08a.
- **Steps:**
  1. Implement `xuna/protocol/CodecV1.h` (status/life/memory encoders) and `xuna/life/CommandHandler.h` using `LifeEngine`, `CommandCache` and an `IStore` interface (in-memory fake for tests).
  2. Emit typed events (`BehaviorChosen`, `FeedbackApplied`, `RequestRejected`) into an `EventSink`.
  3. Make the S08a transcript pass byte-for-byte.
- **Done when:** the transcript and all earlier suites are green. `BleManager` is untouched in this session.

### S09 — `BleManager` becomes transport-only (M04.3c; T12)

- **Preconditions:** S08b; S01 completed (the physical reference).
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
  - **Owner:** repeat the S01 BLE-inspector sequence; the bytes must equal the S01 recording.
  - **Owner regression subset of S01:** connect, the four animations, suggest/feedback/learned choice, reboot persistence, forget + reboot.
- **Done when:** the bytes and the regression subset are identical to S01. Otherwise stop and fix within the session, or revert.

### S10 — TimeSync and app hatch end-to-end (M04.2c)

- **Host part done (2026-10-15); protocol design and pure codecs done (2026-10-16):** `ClockModel` inside `LifeCore` with `LifeCore::sync`, day-part learning cells, LifeSnapshot v2 Clock section and 64-bit monotonic extension. Opcode 5/7, Lifecycle V1, capabilities, app fallback, day-part defaults and durability/error contracts are approved; feature-gated C++/Dart codecs and golden tests now pass. See the [S10 record](S10-host-trusted-time-2026-10-15.md). CommandHandler, firmware/mobile transport/UI wiring and owner checks remain.
- **Preconditions:** S05, S06, S09; D14 for the mobile part.
- **Steps:**
  1. **Design freeze — done 2026-10-16:** use the approved byte layouts and policies in the S10 record; append them to the MVP-local protocol section during implementation documentation.
     - **TimeSync:** opcode 5, length 16: header `[ver=1, op=5, requestId u32, arg=source (1 = phone), reserved=0]` + `utcSeconds u32 @8` + `tzOffsetMin i16 @12` + `reserved u16 @14`.
     - A rollback or implausible value returns result 4 (stay within result codes 0–7 so existing parsers keep working).
     - Capability command mask bit 4 (0x10). Mobile keeps requiring bits 0–3 and treats bit 4 as optional.
     - **Hatch (D7):** opcode 7, length 8, `arg = 0`, capability bit 6. Valid only in the Egg state; otherwise result 4.
     - **Egg-state exposure:** how the app learns that the device is an Egg, with `clockQuality` and `bornAt` quality. Use a small additive read value that old apps simply ignore. Do not reuse the full 20-byte life value or add status values that old parsers reject.
     - The app hatch flow is TimeSync, then Hatch, so `bornAt` is exact.
  2. **Core:**
     - Parse opcodes 5 and 7 in `BleProtocol`.
     - Handle them in `CommandHandler`:
       - opcode 5 → `ClockModel.onSync` → `TimeSynchronized`/`ClockRejected`, then fill `bornAt` if the pet hatched earlier in this boot;
       - opcode 7 → `IdentityService` hatch.
     - Persist `lastTrustedUtcMinute` lazily. Snapshot v2 arrives later; until then keep it in RAM and log it.
  3. **Tests:**
     - Parse table.
     - Transcript entries for sync, rollback, Hatch in the Egg state, Hatch when already hatched (→ 4), and the capability bits.
     - `bornAt` exact for "sync then hatch" and for "hatch then sync in the same boot".
     - `bornAt` stays unknown for "hatch, reboot, then sync".
  4. **Firmware:**
     - Capability mask `0x005f` (bits 0–4 and 6; bit 5 is reserved for opcode 6 in M05c-A).
     - Serial log of clock quality, local time and day part every diagnostics window.
  5. **Mobile:**
     - `ProtocolCodec.encode` supports opcodes 5 and 7.
     - The repository sends TimeSync right after a successful connect when the capability bit is set, and every 6 h while connected.
     - When the device reports Egg, show a "Nở" (hatch) action that sends TimeSync and then Hatch.
     - Tests:
       - codec bytes;
       - TimeSync sent after connect in the simulator repository and skipped without the capability;
       - the hatch flow order.
  6. **Board + phone check (owner):**
     - After connect, serial shows `Synced` with the correct local time and day part.
     - After a reset it shows `Unknown` until the phone reconnects.
     - In the S06 test-only fresh-device mode, the app hatch gives an exact `bornAt`.
- **Done when:** all tests are green and the owner check is recorded.

### S11 — Storage experiment E4/E5 → ADR-0002 → D2 (M04.4a)

- **Preparation (2026-10-12):** isolated bench source/build and restore project prepared; [E4/E5 record](../research/E4-E5-storage.md). No hardware measurements. Runtime upload still requires S01 under §2.3 or an explicit owner exception with a board-only preservation baseline. Reconnect board and refresh backup first.

- **Preconditions:** S04. A verified backup (§5) is taken first.
- **Steps:**
  1. Add a separate `[env:xuna_storage_bench]` with `build_src_filter` selecting `bench/storage_bench.cpp` only. Get owner approval before merging bench code; otherwise keep it on a branch.
  2. **Bench A, NVS:** namespace `xuna_bench` (never `xuna_life`). Do 1,000 A/B writes of a 1,536 B blob. Record write µs p50/p99/max, free heap before and after, and NVS free entries (`nvs_get_stats`).
  3. **Bench B, LittleFS on the `spiffs` partition:**
     - Mount (format on first mount; confirm the partition is unused by XUNA).
     - 10,000 × 40 B appends across 4 KiB segment files, then segment rotation.
     - 200 temp-write + `rename` cycles of a 16 KiB file.
     - Record mount time, write µs p50/p99/max, heap and flash usage.
  4. **Bench C:** rendering the current animation while writing. Record render time and loop gap (E7).
  5. **Reproducible power-cut test:**
     - The bench runs a **write storm**: back-to-back writes, each record carrying a sequence number and CRC, so most of the time is spent inside writes.
     - The owner does 25 random cuts per mode.
     - After each reboot the bench logs the last intact sequence, whether a torn record was detected and truncated, and A/B newest-valid selection.
     - Report how many cuts landed mid-write (detected torn records) rather than assuming all did.
  6. **Cleanup:**
     - Erase only the `xuna_bench` namespace (and leave LittleFS formatted or reformat it, per the ADR).
     - Reflash the current XUNA firmware.
     - Confirm the pet's `xuna_life` state is unchanged against S01.
  7. Write `docs/research/E4-E5-storage.md` (raw tables, method, limits) and the draft `docs/decisions/ADR-0002-storage-layout.md`, comparing options (b), (c) and (d) of plan §15 M04.4.
  8. **The owner decides D2 on that evidence.**
- **Done when:** measurements are recorded, the pet state is intact, and D2 is answered.

### S12a — Snapshot v2 layout freeze + sectioned codec (M04.4b-1; T6, T18)

- **Status (2026-10-15):** done on host ahead of D2 (owner choice: the codec does not depend on the medium). Layout frozen in plan §7.5; evidence in the [S12 record](S12-snapshot-v2-2026-10-15.md). D2 still gates S13.
- **Preconditions:** S06 (CRC-32), D2 answered.
- **Steps:**
  1. **Design freeze:** write the exact v2 layout into plan §7.5:
     - Header: magic, schema, size, generation, flags.
     - Section table: section IDs for counters, clock, lifecycle, needs, learner (reserve `statedMass` for M05c-A), habit, skills, dedup, pointers.
     - Per-section version and length, plus a CRC-32 trailer.
     - The budget is ≤ 1,536 B.
     - In M04 only the sections already backed by code are populated. The rest load defaults.
  2. **`xuna/persist/SnapshotCodec.h`:** `encode`/`decode` returning `LoadResult {Ok, Missing, Corrupt, TooNew, Migrated, MigrationFailed}`.
  3. **Tests:**
     - v2 roundtrip; flipped bit → Corrupt; truncated → Corrupt.
     - Header schema 3 or an unknown required section → TooNew.
     - A missing optional section loads defaults.
     - Size ≤ budget.
- **Done when:** native tests are green and the plan §7.5 offsets are frozen.

### S12b — v1→v2 migration + torn-write simulation (M04.4b-2)

- **Status (2026-10-15):** done on host (`xuna/persist/Migrations.h`, `SnapshotStore.h` with `ISnapshotStore`; torn-write sweep at every byte offset). Migration uses the E10-C capped mapping instead of `alpha = 1 + pos`. Evidence in the [S12 record](S12-snapshot-v2-2026-10-15.md).
- **Preconditions:** S12a, S03 fixtures.
- **Steps:**
  1. **`xuna/persist/Migrations.h`:** `fromV1(bytes96)` maps:
     - counts → coarse learner cells (`alpha = 1 + pos`, `beta = 1 + neg` in Q16.16);
     - the 8 episodes → a temporary episodes section, consumed by M05b (S31);
     - `activeSeconds`, `eventCount`, `generation`.
  2. **Torn-write simulation** in the in-memory `IStore` fake: for every byte offset of a v2 write, simulate a cut (prefix written, rest old or erased) in either A/B slot. Recovery must select the newest **valid** slot and never mix the two.
  3. **Tests:**
     - Every S03 golden v1 fixture migrates with the expected field values.
     - Migration is idempotent: running it twice gives the same result.
     - The full torn-write sweep passes.
- **Done when:** native tests are green.

### S13 — Persistence v2 wiring, safe mode, commit budget (M04.4c)

- **Preconditions:** S12b, **S09** (`NvsStore` exists), S06. A **verified backup (§5)** is taken first.
- **Steps:**
  1. `NvsStore` writes v2 A/B under `life0/life1`. On the first boot after the upgrade it reads `slot0/slot1`, migrates once, and **leaves `slot0/slot1` untouched** for one release (rollback point).
  2. `TooNew`/`Corrupt` identity → `ERROR_SAFE` read-only mode: safe face on the LCD, error code on serial and in BLE status, no writes.
  3. Commit classes (plan §7.6) and a commit-budget counter. The counter writes are logged in the diagnostics line, and an over-budget event raises `StorageError(budget)`.
  4. Mount LittleFS if D2 chose it (no data yet). Log the result.
  5. A **test-only write-storm mode** (compile flag, never in release) for the power-cut check.
- **Owner checks:**
  - Upgrade the owner's **real MVP pet**: the learned choices are identical after the upgrade (the key acceptance).
  - Reboot ×3; forget + reboot.
  - Write-storm power cuts ×20: no identity loss, no double-applied feedback; report the count of detected mid-write cuts.
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

- **Preconditions:** S16, S09. S13 is not required: if S13 is not done yet, needs reset at boot, which is the plan's default policy.
- **Steps:**
  1. Remote animation requests go through `RequestValidator`. A rejection returns `busy (5)`. Check that mobile shows a clear message for result 5; add a mobile test if missing.
  2. `AnimationManager` becomes renderer-side frame timing, driven by `VisualIntent`. `DisplayManager` renders through the expression map and falls back to idle for unknown intents.
  3. Sleep handling: a remote request while `SLEEPING` wakes first (an MVP behavior change, documented in MVP-local).
- **Owner check:** four expressions; sleep/wake; a rejected request shows the message; render mean/max within +20% of the baseline (3.49–3.51 / 3.69 ms).
- **Done when:** the owner check is recorded.

### S18 — `LifeCore::step` composition (M04.6a)

- **Preparation (2026-10-15, host only):** `LifeCore` now uses the E10 learner v3 in the D5 product shape (incl. the GPIO0 `button_greeting` context and curious) through `ProductLearner`, with LifeSnapshot v2 as the durable record; this replaces "LifeEngine (v1 learner, still)" in step 1. Evidence: [S18 preparation record](S18-prep-product-learner-2026-10-15.md). Production wiring still needs S13, S10 and this session.
- **Preconditions:** S17, S13, S10.
- **Steps:**
  1. Compose ClockModel, Identity, EventQueue, CommandHandler, ActivityFsm, Needs/Mood, RequestValidator, BehaviorSelector and LifeEngine (v1 learner, still) behind `LifeCore::step(StepInput) → StepOutput` (plan T1 interface).
  2. `main.cpp` keeps only the adapters, the loop order and diagnostics.
  3. Persist through `PersistRequest` outputs, including the needs section.
- **Done when:** the transcript, all suites and the firmware build are green, and a short owner smoke test (connect, feedback, reboot) passes.

### S19a — Life Lab CLI, trace DSL, runner (M04.6b-1; T5)

- **Steps:**
  1. **Design freeze:** document the trace grammar in `firmware/sim/README.md`. Lines are `@+<ms> <verb> <args>`, with these verbs:
     - `button A|B`, `cmd <hex>`, `sync <utc> <tz>`, `reboot`, `powercut`, `day <n>`, `expect <path> <op> <value>`.
     - Comments start with `#`.
     - No JSON parser is needed.
  2. `firmware/sim/lifelab.cpp`, built through `[env:lifelab]` (native, `build_src_filter` = `sim/`) or a documented host command. It uses an in-memory store that simulates A/B and power cuts (reusing the S12b fake).
  3. Outputs: a metrics CSV, a final snapshot hash and an explanation dump.
  4. Parser tests: malformed lines, unknown verbs, ordering.
- **Done when:** a trivial trace runs and produces deterministic output twice.

### S19b — Scenarios D/E + 100-day invariants (M04.6b-2)

- **Scenarios:**
  - **D**, no feedback for 100 days: the learner is bit-identical to a fresh one.
  - **E**, 10 reboots and 5 power cuts: no duplicate feedback, identity stable, no negative age.
  - **Stability**, 100 days with invariants checked every step.
- **Done when:** all scenarios pass in repeatable runs; runtime is reported (it should take seconds).

### S20 — Golden vectors and Dart conformance (M04.6c; G17)

- **Preconditions:** S19b; D14 for the mobile part.
- **Steps:**
  1. `lifelab golden` writes `firmware/sim/golden/learning_v1.json`: command sequences with expected device results and life bytes.
  2. Copy the vectors into `mobile/test/fixtures/` with a documented update procedure (no cross-repo symlinks).
  3. Mobile tests replay them against `SimulatorDeviceRepository` and `ProtocolCodec`. Any mismatch fails.
- **Done when:** both repos are green.

### S21 — Target parity and M04 acceptance review (M04.6d; E2, E6)

- **Steps:**
  1. `[env:xuna_parity]` embeds 3 traces, replays them at boot without BLE or display, prints the snapshot hashes and `step()` timing histograms, then halts. It must not write to `xuna_life`: it uses an in-RAM store.
  2. Compare with the Life Lab hashes, which must be bit-identical.
  3. Write `docs/roadmap/M04-foundation.md`: acceptance table per slice, measurements (RAM, image, heap, render, loop gap, commit counts, `step()` p99), open issues and the decision log.
  4. Owner review: M04 is Implemented; it is **Validated** only for the rows that have evidence.
- **Done when:** the record is written and the owner confirms.

---

## 7. Session details — M05 (detailed; refine at session start)

Every session below starts with a **design-freeze step**: write the exact payloads, constants or APIs into the plan or a roadmap record, then write tests, then implement.

**Default "done when"** for every M05 session, unless a session states more:

- The design freeze is recorded.
- The listed tests are added and green: native, and `flutter test` where mobile is touched.
- The firmware builds.
- The handoff documents are updated.
- Owner checks are recorded or marked *not run*.

### Track M05a + M05c-A — Learning with Conversation Foundation

The track is developed together and accepted together in S28. This implements A6, "Conversation belongs alongside Learning", without waiting for MemoryStore, BLE v2 or bonding. **The restructure is Proposed (D17).**

#### S22 — Learning and conversation decisions (Owner)

- **Done (2026-10-15):** D3, D4, D5, D6 approved, D16 deferred, Layer A scope and phrase table approved ([S22 packet](S22-decision-packet-2026-10-15.md)). No new art needed. S39 may start.

- **Direction check:** A11 device-first is approved product intent. Keep D17 text-first; freeze candidate/preference semantics independent of text/voice/simulation. Do not require voice hardware. D18–D20 remain separate gates.

- **Timing:** this session can run as early as right after S02. Early action-vocabulary decisions give the art work lead time. It must precede S23 and S39.
- **Decisions:**
  - D3: feedback window.
  - D4: exploration.
  - D5: contexts and actions: day parts, GPIO0 as a learning context, 3–4 actions aligned with real animations.
  - D6: implicit feedback.
  - **D17:** Layer A/B restructure, opcode 6 contract and the stated-preference weight/cap defaults.
  - Optional: D16 (voice), which needs E13 first.
- **Output:**
  - the action list with animation IDs;
  - the context list;
  - **the Layer A phrase table** (vi/en phrases per intent, including negative examples);
  - an art to-do list if new animations are needed;
  - parameter ranges, recorded in AGENTS §3 / plan §9 and §11.

#### S23 — PreferenceLearner v2 (pure)

- Fixed-point discounted Beta, coarse and fine cells, hierarchical prior (plan §9.3).
- The cell layout reserves `statedMass` (zero until S24a).
- Learner section v2 with a migration from the M04 coarse cells.
- Tests:
  - Discount only touches the rated cell.
  - Silence leaves values unchanged.
  - Exact fixed-point values on the golden examples.
  - Prior transfer to an unseen day part.
  - Saturation bounds.

#### S24 — Policy + ReactionTable (pure)

- Masked ε-greedy with confidence scaling and least-rated exploration; PCG32 tie-breaks (plan §9.4).
- ReactionTable: 4 entries, expiry window (D3), invalidation, consumed state, durable rating via `PersistRequest`.
- Tests:
  - Only allowed actions are chosen.
  - The ε bounds hold.
  - The exploration rate matches its configuration over 10k draws.
  - Expired, consumed, invalidated and unknown reactions are rejected.
  - A duplicate `CommandId` is applied once.

#### S24a — Stated-preference evidence + opcode 6 (pure; M05c-A)

- **Done on host (2026-10-15):** applied to learner v3 / `ProductLearner` / `LifeCore` (the v2 learner named in this plan was superseded by E10). Opcode 6 parse behind a flag, stated mass with weight/cap/decay, explanation `Told`, snapshot section 12. Evidence: [S24a record](S24a-stated-preference-2026-10-15.md).

- **Shared contract:** separate input channel from `user_stated`/`user_feedback` evidence; add simulated candidate fixtures without changing deployed source codes. No device audio work.

- Implement plan §11.6 in the core:
  - `CodecV1` parses opcode 6 (12 bytes).
  - `CommandHandler` validates context, action and source.
  - The learner applies `w_s`-weighted `user_stated` evidence with a per-cell cap and the same decay.
  - The explanation reports `statedMass` separately.
- Tests:
  - Parse table.
  - The cap holds under 100 repeated statements.
  - Explicit ratings override a stated preference.
  - The provenance is recorded.
  - An unknown action or context → result 4.
  - In-session duplicate requests are applied once.

#### S25 — Proof-of-learning experiments (E10)

- Life Lab scenarios B, C, D, isolation, E, spam, plus **stated vs rated** (plan §9.9), each over 200 seeds, against random, static and no-learning baselines.
- Compare ε-greedy and UCB. Thompson is optional (plan §9.4).
- **Output:** `docs/research/M05a-learning-report.md` with CIs, convergence and reversal curves (CSV), and the chosen defaults, including `w_s` and the cap.
- The owner reviews the defaults.

#### S26 — Firmware wiring (learning + Layer A device side)

- **Boundary check:** the validated learning command path must be reusable by a later device-local adapter; keep opcode 6/capability contract and C++11, with no raw audio/LLM output in core.

- Day-part contexts (needs S10). GPIO0 greeting as a learning context, if D5 approves it.
- A v1-additive explanation read characteristic (20 bytes, last decision's context, including `statedMass`), with its payload frozen in this session.
- Opcode 6 enabled, capability bit 5.
- The board demo script is prepared for S28.

#### S39 — Conversation domain + LocalRuleExtractor (Dart; M05c-A)

- **Done (2026-10-15):** `CandidateEvent`, `ExtractionResult`, `ExtractCandidateUseCase` from the S22 table; 10 table tests, mobile 39/39 PASS, analyze clean, lock unchanged. Speech/provider interfaces deferred with D16/D11. Evidence: [S39 record](S39-layer-a-extractor-2026-10-15.md).

- **Foundation role:** define candidate/confirmation contracts shared conceptually with device and simulation adapters; Dart extraction is the first implementation. Layer B S40–S42 extends this Foundation. No mandatory interface hierarchy or voice dependency.

- **Moved from M05c by the audit; the ID is kept.** It is pure Dart and can run in parallel with S23–S26 after S22.
- Dart interfaces from plan §11.3; `CandidateEvent`.
- `LocalRuleExtractor` for the **Layer A** intents (`RateLastReaction`, `StatePreference`, `RequestContext`, `AskWhy`) from the S22 phrase table.
- Layer B phrases are recognized but produce no candidate ("not available yet").
- The existing V1 `parseTextIntent` behavior is preserved: its tests still pass.
- Tests: table tests including negative, hypothetical and injection cases. Unknown input produces nothing.

#### S27 — Mobile: reaction-referenced feedback and "Why?"

- Feedback refers to the reaction. A "Why did XUNA do that?" view renders only the explanation fields, showing *learned* (rated) and *told* (stated) evidence separately. Day-part display.
- Golden vectors are updated through S20's procedure. Tests are green.

#### S27a — Mobile: Conversation Foundation wiring (M05c-A)

- **Confirmation contract:** explicit candidate review and provenance must be reusable by later device voice UX; this session implements the mobile text path only.

- **Pipeline:** text input → `LocalRuleExtractor` → `CandidateEvent` → confirmation screen → command.
  - The confirmation screen shows exactly what will change and its provenance.
  - The command is opcode 3 (rating the last reaction) or opcode 6 (stated preference, only when capability bit 5 is present).
  - The app then reads the explanation and replies from the explanation fields only.
- **Timeouts:** no automatic resend; read the explanation to check the outcome.
- **Tests:**
  - An unconfirmed candidate sends nothing.
  - Firmware without bit 5 disables `StatePreference` with a clear message.
  - A reply never claims learning that the explanation does not show.
  - No text leaves the phone.

#### S27b — *Optional:* push-to-talk with on-device STT (E13 → D16)

- **E13 first:**
  - Check that the owner's phone offers **on-device** recognition for vi-VN (and en) without network.
  - Measure accuracy on the S22 phrase table, plus latency.
  - If it is unavailable, voice stays deferred.
- **Only after D16:**
  - Push-to-talk button, clear microphone permission UX, no background listening, no audio or transcript retention.
  - The transcript feeds the same `LocalRuleExtractor`.
  - Optional phone TTS for replies.
- Opcode `source = 3` (confirmed voice).

#### S28 — Joint M05a + Conversation Foundation acceptance (Owner)

- **Source independence:** include simulated validated/rejected candidates through the same learner; hardware voice is not required. Preserve all existing joint acceptance criteria.

- **Board + phone, learning:**
  - A preference forms in one context and stays isolated from the others.
  - It survives a reboot and works offline (phone off).
  - The explanation counts match the actual feedback.
  - Reversal adapts.
- **Board + phone, conversation:**
  - "Mình thích khi bạn vẫy tay buổi tối" → confirm → the explanation shows the stated evidence → the evening choice shifts.
  - The shift persists after a reboot and is used with the phone off.
  - Explicit ratings can override it.
  - Unknown, joke and injection inputs change nothing.
- Record in `docs/roadmap/M05a-learning.md`.

### Track M05b — Memory, Journal, BLE v2, bonding

#### S29 — Memory decisions (Owner)

- D8 (fact allowlist and capacities, a nickname on the device) and D9 (ForgetAll scope).
- **D10 is not asked here.** It follows experiment E9 in S35.
- This session can run any time; it must precede S30.

#### S30 — MemoryStore, salience, consolidation (pure)

- Records from plan §10.4, integer salience, promotion and eviction rules, pattern merge, and protected classes.
- Tests: a bounded store after 10,000 events; protected records survive; determinism.

#### S31 — Journal, provenance, tombstones (pure)

- **Voice provenance fixture:** a spoken claim is `user_stated`, never a physical/sensor observation; use synthetic fixtures, not assumed audio hardware.

- Journal records cite evidence IDs; enforcement of the provenance enum; tombstones; ForgetAll per D9; migration of the 8 v1 episodes kept from S12b.
- Tests:
  - A `user_stated` fact is never rendered as observed.
  - The `simulated` provenance is rejected in production builds.
  - Deletion leaves a tombstone.

#### S32 — Persisted event codec + LittleFS adapters + recovery (firmware)

- **Moved here from S07:** the 40-byte persisted event codec (plan §7.2) with CRC-16/CCITT-FALSE (check value `"123456789" → 0x29B1`). Its format follows D2.
- Segmented log, truncation at the first bad CRC, memory file with temp+rename and a generation cross-check against the snapshot.
- Verified backup (§5) first.
- **Owner:** write-storm power cuts ×25 during appends and renames.

#### S33 — BLE v2 codec (core + Dart)

- Freeze the `Hello`, frame header and payload layout of every v2 request (plan §14.1) in the protocol record.
- Shared test vectors are consumed by both the C++ and Dart tests.
- Fragmentation, resume and CRC tests.

#### S34 — BLE v2 transport + E8

- Characteristics `7a6e0008`–`000A`.
- Mobile repository v2 with v1 fallback.
- Measure the negotiated MTU and the heap on the owner's phone.

#### S35 — Bonding experiment (E9) → ADR-0005 → D10 (Owner)

- **Experiment:** Arduino `BLESecurity`, LE Secure Connections with the passkey shown on the LCD; iOS pairing, reconnect, removed bond, unbonded rejection, owner-recovery UX.
- **Output:** `docs/research/E9-bonding.md` and the ADR-0005 draft.
- **The owner decides D10 at the end of this session, on that evidence.** If bonding proves impractical, D10 records the alternative (e.g. button-confirm-only for destructive actions), and S36 is re-scoped.

#### S36 — Permission tiers + destructive confirmation

- **Preconditions:** S35, **D10 answered**.
- Validator tiers enforced at dispatch. ForgetAll and ForgetFact require the D10-approved authorization (e.g. a bonded link plus a button press within 10 s).
- Mobile UX for the confirmation.

#### S37 — Mobile Journal and Memory & Privacy

- Hive boxes; journal timeline; fact list with delete; forget all; reconnect sync after the last `EventId`; tombstones applied.
- Tests: no resurrection from a stale cache.
- Split into S37a/S37b if the design freeze shows more than one sitting.

#### S38 — M05b acceptance (Owner)

- Plan §15 M05b acceptance items on the board and phone. Record in `docs/roadmap/M05b-memory.md`.

### Track M05c-B — Conversation with long-term memory

#### S40 — Device facts and commands

- **Reuse:** the authoritative fact command validator is shared with future authorized device voice; privacy/consent do not depend solely on BLE security. No audio dependency.

- `TeachFact`, `SupersedeFact`, `ForgetFact`, `ReadFacts` (v2), FactRecord store with the D8 allowlist, `CommandId` dedup, and the D10 authorization tier.
- Tests: validation table; supersede chain; tombstone; unbonded rejection.

#### S41 — Fact confirmation, grounded replies, recall (mobile)

- **Extension:** extend existing Foundation for facts/recall; device confirmation is a later D20/VOICE-04 adapter to the same semantics.

- Reuses the S27a confirmation component and the S39 extractor; the Layer B intents become active.
- Replies are built only from device-confirmed data, phrased per provenance ("bạn đã kể với mình…").
- Offline: local rules still work.
- Scenario F test.

#### S42 — M05c-B acceptance (Owner) + optional V2 spike

- **Conditional voice evidence:** include device-originated facts only if VOICE-03 and D20 are ready; otherwise record coverage as deferred and retain text acceptance. VOICE-04 fact extension additionally requires this session.

- Nickname taught → shown after a reboot; correction; forget in both stores; personal facts refused unbonded.
- **V2 spike (E12)** runs only after **D11a** authorizes it, with test data only. It is research output, not product code. D11 is decided after it.

### Checkpoint

#### S42a — Product checkpoint D15 (Owner)

- **Inputs:**
  - S28, S38 and S42 acceptance records;
  - art readiness: assets for one stage change and two traits;
  - Life Lab evidence of stable learning.
- **Choose:**
  - **A:** M05d → M06.
  - **B:** Evolution MVP → M05d. The Evolution MVP is one stage transition, two traits and journal entries, with gates from M05a evidence and interaction days plus a minimal `associateReactionFeedback` skill.
- The trade-offs are in [XUNA_PLAN_AUDIT.md](../architecture/XUNA_PLAN_AUDIT.md) §E.
- **Output:** the decision recorded, and the next milestone split into sessions.

### Track M05d — Cognitive development gates (order per D15)

#### S43 — HabitPredictor + prequential scoring (pure)

- Plan §9.7. Tests: decay only on trusted days; sparse-data uncertainty; prequential baselines.

#### S44 — SkillBook and competency bands (pure)

- Plan §9.8 skills with hysteresis.
- Test: a pet with age but no feedback has no learning skill.

#### S45 — Dual-history Life Lab evaluation

- Spec §23.10 report: same seed, two histories, held-out contexts, restart parity, routine change.
- Output: `docs/research/M05d-cognitive-report.md`.

#### S46 — Wiring, mobile projection, M05d acceptance

- Anticipation pose gated by settings; competency view in the app; owner acceptance record.

---

## 8. After the S42a checkpoint

The milestone chosen second in D15 (M05d or the Evolution MVP), the rest of M06 (growth/evolution: art scope, layered assets, `GrowthConfig`), and M07 (sensors) are split into sessions **when they become next**, using the measurements available then. Pre-splitting them now would conflict with AGENTS.md §4, which says not to build later milestones speculatively.

## 9. Recommended next sessions

Updated 2026-10-16 after the owner smoke PASS and the gate simplification (AGENTS §3). Earlier recommendations (S02 → S00 → S01, 2026-10-12) are historical.

| # | Session | Repo | Depends on | Minimum done when |
|---|---|---|---|---|
| 1 | **Done 2026-10-16 ([record](S13-S18-integration-prep-2026-10-16.md)).** **S08a + integration prep (host):** S01 observed transcript as a replay test; `BleManager` → `LifeCoreEvent` adapter design; `NvsSnapshotStore` (`life0/life1`, static recover scratch); v1 → v2 migration of the owner's real NVS backup decoded on host; `IdentityRecord` (`MigratedFromV1`) creation | firmware | — | Transcript replays byte-identically through the new path; migrated quiet/play preferences match `BoardLearner` (check the untried-curious prior edge case); native + ESP32 build PASS |
| 2 | **Uploaded 2026-10-16; initial smoke PASS, remaining board checks owner-skipped ([record](S13-S18-switch-2026-10-16.md)).** **S13 + S18 merged (board):** production switch to `LifeCore` + LifeSnapshot v2 | firmware | 1, §5 backup | Real pet's learned preferences preserved; reboot ×3; forget + reboot; `slot0/slot1` untouched; owner smoke (four emotions, buttons, BLE) |
| 3 | **Source/host/build done 2026-10-16; not uploaded; physical acceptance deferred ([record](S26-S27-lite-2026-10-16.md)).** **S26 + S27-lite:** opcode 6 + capability bit 5, explanation characteristic, D3 `expired` result; minimal "Why?" in the app | firmware, mobile | 2 | Chat statement → confirm → explanation shows `Told` → choice shifts → survives reboot with the phone off (S28-lite) |
| 4 | **S10-sync:** opcode 5 after connect, 16-byte command packets, day-part cells on the board | firmware, mobile | 2 (parallel with 3) | Serial shows `Synced` + day part; S10-hatch stays deferred |

## 9. Proposed device voice feasibility sessions — separate workstream

All four are **Proposed / not started**. They do not renumber or block S00–S21, S22–S28 or text S39–S42. Starting an experiment requires the owner's session request and relevant approvals. See [device voice architecture](../architecture/XUNA_DEVICE_VOICE_ARCHITECTURE.md). E13/S27b remain optional **phone** recognition, separate from this track.

| ID | Goal | Preconditions | Deliverable / acceptance |
|---|---|---|---|
| VOICE-01 | Hardware feasibility | Owner requests research; revision evidence available or explicitly marked missing | Revision-matched available/reserved GPIO and display/button/USB/PSRAM audit; I2S mic and amp/speaker vs codec options; voltage/current, RAM/Flash/framework, enclosure and future battery implications; verified quotes only, otherwise costs unknown; recommendation and D18 checkpoint |
| VOICE-02 | Audio I/O prototype | VOICE-01 report, D18 approval, actual authorized peripherals/board; verified backup if firmware replaced | Real capture/playback stability, underruns/overruns, memory/internal DMA/PSRAM, CPU/loop/render latency vs baseline and power observations. Compile/simulation cannot pass this gate |
| VOICE-03 | Device Conversation Pipeline | VOICE-02 measured pass; D19 research scope/security/spending authorization; D11a before cloud tests; authorized network/service | Device PTT → secure Wi-Fi → Vietnamese STT/LLM/TTS → speaker + expression with Flutter closed. Stage/end-to-end latency, bandwidth, quality/cost/retention and Wi-Fi stability; timeout/cancel/late reply/reconnect/offline fallback tests; recommended architecture, final D19/D11 if applicable and D20 checkpoint |
| VOICE-04 | Conversation-to-Learning Integration | VOICE-03 validated path, D19 final/D11 if applicable, D20 scope/confirmation approval and S28 Foundation; S42 additionally for facts | Real device candidate → validate → explicitly confirm → same learner → changed future behavior → reboot → phone/cloud disconnected use; traceable source/provenance, dedup and rejection tests. Fact extension verifies recall/correction/deletion without resurrection |

VOICE-01 documents missing PCB/peripheral evidence instead of guessing pins. No buying/wiring is part of research. VOICE-02/03 freeze measurement methods and owner acceptance thresholds before prototype code. Exact audio/network protocol, tasks/buffers and hardware configuration are chosen only from evidence; framework changes require a separate ADR. VOICE-04 validates integration and does not replace S28 or S42 acceptance history.

## Completed focused fixes

- **S05-fix-01 — compact time epoch:** align ClockModel minutes/watermark with 2020 epoch while preserving Unix millisecond input; [record](S05-fix-01-time-epoch.md). No session renumbering or board gate change.

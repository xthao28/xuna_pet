# XUNA — Plan Audit (2026-10-12)

**Scope:** documentation and architecture review of [XUNA_IMPLEMENTATION_PLAN.md](XUNA_IMPLEMENTATION_PLAN.md) (0.1.0 → 0.1.1) and [XUNA_SESSION_PLAN.md](../roadmap/XUNA_SESSION_PLAN.md) (revision 1 → 2).

**Trigger:** the owner forwarded an external review checklist (from the assistant used at project start) and asked for the plan to be re-checked. The checklist's points were adopted only where they hold technically and for the product.

**Constraints honored:**

- No source code, dependency, SDK, flash or storage changes.
- No decision approved on the owner's behalf.
- No commit or push in this audit.

**Status vocabulary:** as in AGENTS.md §3. Every sequencing change below is **Proposed** and pending owner approval.

---

## A. Findings, ranked by severity

No Critical findings: nothing found would corrupt data or contradict an Approved decision if executed as written. However, F2 and F3 should be fixed before any session that touches the board.

### F1 — High — Conversation enters too late relative to approved decision A6

- **Evidence:**
  - AGENTS §3 (Approved): "Conversation belongs alongside Learning… must not be postponed".
  - Plan 0.1.0 §15.1 placed M05c after M05b (MemoryStore, BLE v2, bonding).
  - The session map had S39–S42 after S38.
  - Learning-relevant intents (`StatePreference`, rating, "why") need none of that infrastructure. Only personal facts do.
- **Why it matters:** product-direction drift. Conversation would arrive as an add-on after memory work instead of being a learning input developed with the learner.
- **Correction (Proposed, D17):** split into two layers.
  - **Layer A, Conversation Foundation (M05c-A)**, developed and accepted together with M05a (S22, S24a, S26, S39, S27a, optional S27b, joint S28).
  - **Layer B (M05c-B)** stays after M05b for facts, recall and privacy.
  - Minimum contract (plan §11.6):
    - the existing opcode 3 with source "confirmed text";
    - a new v1-additive opcode 6 `StatedPreference` (12 bytes, capability bit 5);
    - capped `user_stated` evidence that explicit ratings can override;
    - no text over BLE;
    - the same trust level as opcode 3 under the approved unbonded prototype (A8), because a behavioral preference is not a personal fact.
- **Status:** fixed in the documents as Proposed; **owner approval needed (D17)**.

### F2 — High — Decisions requested before the evidence that should inform them

- **Evidence:**
  - D10 was asked in S29 while the bonding experiment E9 ran later in S35. Plan §18 D10's recommendation was "approve the experiment", which conflated running E9 with the security decision.
  - D2 was asked "provisionally" in S02 and listed as needed "to start M04", while E4/E5 run in S11.
  - The V2 spike was gated by D11, the decision it informs.
- **Why it matters:** decisions without evidence get re-litigated or silently pre-judged.
- **Correction:**
  - D2 is decided at the end of S11.
  - D10 is decided at the end of S35, from ADR-0005.
  - D11 is split into **D11a** (authorize a research spike with test data: cost and privacy) and **D11**, decided after E12.
  - New session rule 10: experiment → evidence → ADR → decision → implementation.
  - Plan §20: starting M04 needs only D1, D7 and D14.
- **Status:** fixed (documents).

### F3 — High — Regression baseline too weak for byte-exact refactors

- **Evidence:**
  - The S08 transcript was to be derived from reading `BleManager::update` only.
  - S06 uploads firmware that adds NVS writes but did not require S01 or a backup.
  - MVP physical acceptance (PLAN MVP-07) is still pending.
- **Why it matters:** a "byte-identical" claim checked only against our own reading of the code can encode a misunderstanding. The owner's real pet data is at risk on uploads.
- **Correction:**
  - S01 now captures **observed** raw characteristic bytes with a BLE inspector.
  - S08 is split into S08a (fixture from observed bytes; code-derived cases are marked `derived`) and S08b (implementation).
  - S09 compares the bytes against S01.
  - The S06 board step requires S01 and a verified backup.
  - New rule: no refactored or storage-changing firmware goes on the owner's board before S01.
- **Status:** fixed (documents).

### F4 — Medium — NVS backup procedure hard-coded partition offsets

- **Evidence:**
  - Session plan rev. 1 §5 used `0x9000 0x5000` directly.
  - Verified 2026-10-12 against Arduino-ESP32 2.0.14:
    - `tools/sdk/esp32s3/sdkconfig` sets `CONFIG_PARTITION_TABLE_OFFSET=0x8000`;
    - `tools/gen_esp32part.py` exists;
    - `default_16MB.csv` contains `nvs 0x9000 0x5000`.
  - The values are correct today but not guaranteed after D2 option (c), a repartition.
- **Why it matters:** backing up or restoring the wrong range can lose the owner's pet.
- **Correction:**
  - Read the table **from the device** (0x8000, 0xC00) and decode it with `gen_esp32part.py`.
  - Cross-check it against the build's `partitions.bin`.
  - Back up exactly the device's `nvs` row, with an optional full image, and record SHA-256 hashes.
  - Restore only after the tables match; never `erase_flash`.
- **Status:** fixed (documents). Nothing was executed.

### F5 — Medium — Flutter SDK not pinned; 3.32.8 presented as the target

- **Evidence:**
  - No `mobile/.fvmrc`.
  - `pubspec.lock` → `sdks: dart ">=3.7.0-0 <4.0.0", flutter ">=3.27.0"`.
  - Validation is recorded only on 3.32.8 / Dart 3.8.1 (macOS, MVP-local).
  - The fvm default on this Windows machine is 3.41.1.
  - Flutter pins packages such as `meta`, `collection` and `test_api`, so a different SDK will rewrite the lock.
- **Why it matters:** unreproducible builds, and a silent lock churn that mixes a toolchain upgrade with feature work.
- **Correction:**
  - New decision **D14**; recommendation: pin 3.32.8 via `.fvmrc`, and make upgrades their own validated session.
  - S00 verifies `pub get` leaves the lock unchanged.
  - No version is labeled Approved.
- **Status:** fixed (documents); **owner decision D14 needed**.

### F6 — Medium — Session dependency errors

- **Evidence and corrections:**

  | Session | Problem | Correction |
  |---|---|---|
  | S13 | Modifies the `NvsStore` created in S09 but did not depend on S09 | Added S09 |
  | S18 | Composes the clock and persistence without depending on S10/S13 | Added S10, S13 |
  | S17 | Depended on S13 although wiring the FSM does not need persistence v2 | Now S16 + S09; needs reset at boot until S13, which is the plan default |
  | S02 | Depended on S00 although decisions need no tooling; meanwhile S00 needed S02's D14 | S02 now runs first |
  | S22, S29 | Decision sessions artificially placed after S21/S28 | Can run early (art lead time) |
  | S37 | Implicit need for BLE v2 (S34) | Satisfied transitively through S36 → S35 → S34 |

- **Circular dependencies:** none found.
- **Status:** fixed (documents).

### F7 — Medium — Oversized sessions

- **Evidence:** S08, S12 and S19 were sized L, against the plan's own rule of one goal per sitting.
- **Correction:** split into S08a/S08b, S12a/S12b and S19a/S19b. S37 is flagged to split at its design freeze if needed.
- **Status:** fixed.

### F8 — Medium — Power-cut validation not reproducible as written

- **Evidence:** "25 cuts during writes" relied on manual timing, which cannot target millisecond write windows.
- **Correction:**
  - A test-only **write-storm** build with sequence numbers and CRC per record. It reports how many cuts actually landed mid-write.
  - Host **torn-write simulation at every byte offset** (S12b).
  - S01's manual cuts are labeled smoke evidence.
  - New risk R14.
- **Status:** fixed (documents).

### F9 — Medium — No product checkpoint between M05d and Evolution

- **Evidence:** M06 depended on M05d unconditionally; no comparison of user value (see §E).
- **Correction:** a new checkpoint session **S42a** with decision **D15**. M06 now depends on D15. Milestones are **not** reordered.
- **Status:** fixed (documents); **D15** pending at S42a.

### F10 — Low — AI technique classes and allowed claims were implicit

- **Evidence:** the plan distinguished learning from gameplay in places, but had no single taxonomy covering BT, ML, LLM and agents.
- **Correction:** new plan §5.6. It covers rule-based, FSM, behavior trees (not used), utility AI, adaptive online learning, instructed adaptation, trained ML (not used), LLM (phrasing only) and agents (not used), with what may be claimed for each.
- **Status:** fixed.

### F11 — Low — Persisted event codec specified before the storage decision

- **Evidence:** S07 built the 40-byte codec and CRC-16, while the log format depends on D2 (S11) and the log is first written in M05b.
- **Correction:** S07 is reduced to in-RAM events. The persisted codec moves to S32, and plan M04.3 is updated.
- **Status:** fixed.

### F12 — Low — A9 wording could read as a permanent framework commitment

- **Evidence:** AGENTS §3 lists Arduino long-term as Proposed or open; plan §2.1 A9 said only "Pinned toolchain retained".
- **Correction:** A9 is scoped to the local MVP. Arduino is the current adapter; `xuna_core` stays framework-independent (session rule 11).
- **Status:** fixed (wording). The Approved content is unchanged.

### F13 — Low — Outdated claim about OTA rollback under Arduino

- **Evidence:**
  - Arduino-ESP32 2.0.14 `tools/sdk/esp32s3/sdkconfig` sets `CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE=y`.
  - `cores/esp32/esp32-hal-misc.c` defines weak `verifyRollbackLater()`; `initArduino()` marks the image valid only if it returns false and `verifyOta()` passes.
- **Correction:** T18 is updated. OTA is still Future.
- **Status:** fixed.

### F14 — Low — Stale steps

- **Evidence:** "commit the spec" appeared in plan M04.0, S02 and §20, but it was done in root commit `e3d3485`.
- **Correction:** marked done.
- **Status:** fixed.

### F15 — Low — Instructed versus learned evidence not separated

- **Evidence:** a conversation-stated preference would have been indistinguishable from feedback-learned preference in explanations.
- **Correction:**
  - `statedMass` is reported separately (plan §9.6).
  - Stated evidence is capped and decays, so explicit ratings can override it.
  - New scenario "Stated vs rated" (§9.9) and risk R13.
- **Status:** fixed (Proposed parameters).

### F16 — Low — Thompson sampling in E10 conflicts with bit-exact parity

- **Correction:** made optional; E10 compares ε-greedy and UCB.
- **Status:** fixed.

### F17 — Low — M05 sessions lacked explicit completion criteria

- **Correction:** a default "done when" for M05 sessions, plus specific acceptance where the product outcome matters (S24a, S27a, S28, S35, S42a).
- **Status:** fixed.

### Verified as correct (no change)

- The current MVP hardware remains the LILYGO T-Display-S3 (ESP32-S3R8, 16 MB flash, 8 MB OPI PSRAM; PCB revision unrecorded).
- Custom PCB, HoloCubic and stronger hardware remain Future.
- `xuna_core` purity is enforced (S04 purity hook).
- Deterministic simulation, provenance, offline-first behavior, explainability, persisted learned state, replay and recovery tests are all present.
- Approved decisions A1–A10 are untouched in substance.
- There are no circular dependencies.

---

## B. Recommended milestone flow (Proposed)

```text
S02 decisions ─► S00 toolchain ─► S01 MVP baseline (observed bytes)
      │
      ▼
M04 foundation (S03–S21; host-only work may start before S01, board steps may not)
      │
      ├─► M05a learner  ⇄  M05c-A Conversation Foundation   ── joint acceptance S28
      │     user says a preference → candidate → confirm → opcode 6 → learner →
      │     behavior changes → persists on the device → works with the phone off
      │
      └─► M05b memory, journal, BLE v2, E9 → D10 bonding ─► M05c-B facts, recall, privacy
                                                                   │
                                                                   ▼
                                         S42a product checkpoint (D15)
                                    A: M05d → M06      B: Evolution MVP → M05d → M06 (rest)
                                                                   │
                                                                   ▼
                                                                  M07
```

---

## C. Session changes

| Change type | Sessions |
|---|---|
| Unchanged in substance | S03, S04, S05, S14, S15, S16, S20, S23 (except reserving `statedMass`), S24, S27, S30, S31, S33, S34, S38, S40, S43, S44, S45, S46 |
| Modified | S00 (D14 pin, lock check); S01 (observed bytes, smoke-labeled cuts); S02 (runs first, no D2/D10, adds D14/D17); S06 (board-step preconditions); S07 (in-RAM only); S09 (byte comparison with S01); S10 (D14 for mobile); S11 (write storm, cleanup, D2 after evidence); S13 (S09 dependency, write storm); S17/S18 (dependencies); S21 (parity must not write `xuna_life`); S22 (early, D17, phrase table); S25 (stated vs rated, Thompson optional); S26 (opcode 6); S28 (joint acceptance); S29 (no D10); S32 (receives the event codec); S35 (ends with D10); S36 (D10-dependent scope); S39 (moved to Layer A); S41/S42 (Layer B, D11a) |
| Split | S08 → S08a/S08b; S12 → S12a/S12b; S19 → S19a/S19b |
| Added | S24a (stated-preference evidence + opcode 6, core); S27a (conversation foundation wiring, mobile); S27b (optional voice: E13 → D16); S42a (product checkpoint D15) |
| Acceptance updated | S01, S06, S09, S11, S13, S21, S27a, S28, S35, S42, S42a; default M05 "done when" |

---

## D. Decision register (outstanding at audit time)

> **Update 2026-10-12, after the audit:** the owner approved D1, D7, D12, D14 and D17 (recorded in AGENTS.md §3 and plan §18).
>
> For D7 the owner chose the local-first variant: hatch on the device **or** via the app, rather than app-only hatch. The plan was amended accordingly: §12, opcode 7 `Hatch`, the Egg state, and sessions S06/S10.
>
> The table below is kept as the audit-time snapshot.

| ID | Decision | Options | Recommendation | Evidence | Blocks |
|---|---|---|---|---|---|
| D1 | M04 foundation before new M05 features | approve / modify / reject | Approve | G1, G5, G9; R1 | S03 onward |
| D7 | Hatch and `bornAt`; migrate MVP pets | app hatch with time sync + migrate as Newborn with `bornAt` unknown / alternatives | Approve | Plan §12; no RTC | S06 |
| D12 | Core language standard | C++11 / gnu++17 via ADR | C++11 | Arduino 2.0.x default gnu++11; host tests use C++11 | S04 |
| D14 | Flutter SDK pin | 3.32.8 / 3.41.1 / other | 3.32.8 via `.fvmrc`; upgrade later as its own session | §A F5 | S00 mobile, S10, S20 |
| D17 | Conversation Layer A/B + opcode 6 contract | approve / keep M05c after M05b | Approve | A6; plan §11.6 | S22 → S24a, S39, S27a |
| D2 | Storage layout | NVS + LittleFS / larger NVS / raw partition | Decide after S11 | E4/E5 (to run) | S12a |
| D3–D6 | Feedback window, exploration, contexts/actions, implicit feedback | see plan §18 | see plan §18 | Plan §9 | S23–S26 |
| D8, D9 | Fact allowlist and capacity; ForgetAll scope | see plan §18 | see plan §18 | Plan §10 | S30, S31, S40 |
| D10 | BLE security model | after E9: LCD-passkey bonding / button-confirm only / other | Pending evidence | E9 (to run, S35) | S36, S40 |
| D11a | Authorize a cloud STT/LLM research spike | yes / no | Optional | Cost and privacy | E12 |
| D11 | Conversation V2 | after E12 | Stay local for now | E12 | V2 only |
| D13 | Growth gates, stages, trait art | — | Defer to M06 | — | M06 |
| D15 | M05d first or Evolution MVP first | A / B | Decide at S42a; lean B if art is ready and learning is stable | §E below | after S42 |
| D16 | Voice (push-to-talk, on-device STT) in Layer A | yes / no / later | Text first; voice only if E13 passes | A5 deferred voice; vi-VN on-device STT unverified | S27b |

---

## E. Evolution versus advanced cognition (input for D15)

| Criterion | A: M05c → M05d → M06 | B: M05c → Evolution MVP → M05d |
|---|---|---|
| User-visible value | Delayed: M05d's output is subtle (anticipation poses, competency view) | Earlier: a visible growth step and new traits, the product's core promise (pillar 5) |
| Demonstrating growth | Strong evidence base, shown late | Shown early, on thinner evidence (preferences, interaction days) |
| Learning→Evolution integration | Gates can use habits and skills, so they are richer and more distinctive | Gates use M05a evidence + a minimal `associateReactionFeedback` skill; the risk is evolution feeling arbitrary if gates are weak |
| Technical dependencies | Linear; no rework of gates | Needs a versioned `GrowthConfig` (already planned) so M05d can refine gates later without breaking committed transitions |
| Complexity | Lower risk per step | Art pipeline (T7) and asset production pulled forward; art is the long pole |
| Product validation | Late user feedback on growth | Early user feedback on growth UX and the Journal |

**Conclusion:** the evidence is insufficient to reorder now. A checkpoint (S42a) is added. Lean towards B if two things hold:

- art for one stage change and two traits is ready;
- S28 shows stable learning.

Otherwise A.

---

## F. Over-engineering review

| Design | Problem it solves | Present in MVP? | Simpler option | Verdict |
|---|---|---|---|---|
| Sectioned snapshot v2 | Add learner, memory and skills without schema churn | Yes: the v1 schema cannot evolve (G5) | Flat v2 | **Keep**; flat v2 would need a v3 in M05a |
| Fixed-point learner math | Host/target bit-exact parity | Yes, for Life Lab trust | Floats | **Keep** |
| Hierarchical day-part prior | Generalize to unseen contexts | From M05a | Coarse only | **Keep, tested in E10**; cheap |
| 40-byte persisted event codec in M04 | Durable log | No, not until M05b | — | **Defer to S32** (F11) |
| BLE v2 fragmentation | Pages larger than 20 bytes | From M05b | MTU-sized pages only | **Keep minimal**; E8 may simplify |
| Permission tiers | Destructive or personal commands | From M05b | Button confirm only | **Keep**; scope follows D10 |
| Durable `CommandId` ring (128 B) | Duplicate application after reconnect | When retries cross sessions | Rely on no-auto-resend | **Keep**; tiny |
| Thompson sampling | Exploration quality | No | ε-greedy / UCB | **Optional** (F16) |
| Habit predictor with 48 slots | Weekday/weekend routines | M05d | 24 slots | **Keep for now**; revisit at the S43 design freeze |
| ERROR_SAFE read-only mode, commit budget | Data protection, write regressions | Yes | — | **Keep** (reliability) |

---

## G. Documentation diff summary

| File | Why it changed |
|---|---|
| `docs/architecture/XUNA_IMPLEMENTATION_PLAN.md` (0.1.1) | **Header** version note. **§1** Conversation layers; D15 note. **§2.1** A9 scope. **§5.6** taxonomy (new). **T18** rollback evidence. **§9** Thompson optional; `statedMass`; new scenario. **§11** Layer A/B, intent allowlist by layer, §11.6 contract (new). **§14.1** opcode 6. **§15** diagram, M04.0 done note, M04.3 codec timing, M05c-A/M05c-B, D15 checkpoint, M06 dependency. **§16.2** E10/E12/E13. **§17.2** R13/R14. **§18** D2/D10/D11a/D11 timing, D14–D17. **§20** start conditions. G16 slice. |
| `docs/roadmap/XUNA_SESSION_PLAN.md` (rev. 2) | Readiness table; rules 3, 6, 10 and 11; session map with corrected dependencies, splits and additions; verified NVS procedure; session details per §C; next sessions |
| `docs/architecture/XUNA_PLAN_AUDIT.md` (new) | This report |
| `PROCESS.md`, `PLAN.md`, `CHANGELOG.md` | Short dated entries recording the audit; no status promotions |

No firmware, mobile or backend file changed. No commit or push.

---

## H. Recommended next three sessions

Based on the actual status: no M04 work has started, MVP physical acceptance is pending, and this machine has no firmware toolchain.

1. **S02:** decisions D1, D7, D12, D14 and D17, plus ADR-0001.
2. **S00:** toolchain and baseline, with the Flutter pin per D14.
3. **S01:** MVP physical acceptance plus the observed v1 byte capture.

## G. Device-first follow-up — 2026-10-12

Owner requested device-first Conversation with Flutter assistance. The initial audit above is retained as history. Plan 0.1.2/session rev. 3 add an input-independent Foundation boundary and separately gated VOICE-01–04; no numbering or current coding order changes. D17 is Approved, D15 is still Proposed. [Device voice architecture](XUNA_DEVICE_VOICE_ARCHITECTURE.md) records the current source limitations (sources 1–2/opcodes 1–4), trust/failure contracts and unknown hardware/runtime/commercial feasibility. ADR-0006 remains Proposed; D18–D20 are open. No code or hardware validation occurred.

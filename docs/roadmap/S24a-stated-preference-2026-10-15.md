# S24a — Stated preference (opcode 6) in the device core (2026-10-15)

Status: **done on host** (pure core + LifeCore + snapshot). Not wired into
the production BLE adapter (S18); the app side is S27a. No board or phone.

## Contract implemented (plan §11.6, D17)

- **Parse:** `parseCommand(bytes, n, statedPreference)` accepts opcode 6
  (12 bytes: `arg` polarity 0/1, `source` 2 = confirmed text, `contextKey`
  @8, `actionId` @9, reserved u16 @10 = 0) only when the flag is set. The
  default keeps today's production behaviour (opcode 6 → error 3). Source 3
  (voice) stays invalid until D16; malformed frames → error 2/4.
- **Core validation (LifeCore `StatedPreference` event):** interaction
  (`contextKey >> 4`) ≤ 2, day part (`& 0x0F`) ≤ 4, learnable action
  (idle/happy/curious; sleep rejected), source 2, not in ERROR_SAFE →
  otherwise `statedRejected` (BLE result 4 in S18). In-session duplicates
  (same command id, last 8) are applied once (`statedDuplicate`).
- **Commit-first:** `ProductLearner::statePreference` stages the snapshot,
  commits, then adopts; a failed commit leaves RAM unchanged and is not
  remembered as a duplicate, so the retry applies (`statedNotReady`).
- **Learning effect:** `PreferenceLearnerV3::state()` adds `w_s` (0.5 [P]) of
  `user_stated` evidence to the coarse cell and, with a day part, the fine
  cell. Stated mass per cell is capped at 2 ratings [P]. It is not a rating:
  `rated`, the duplicate window, the pending decision, `feedbackCount` and
  the episodes are unchanged. Stated mass decays with γ whenever the cell is
  rated, so explicit feedback always overrides it.
- **Implementation choice (Proposed, review with S25):** the latest
  statement wins. An opposite statement first withdraws the cell's earlier
  stated mass of the other polarity (ratings untouched), then adds its own.
- **Explanation:** `V3ExplanationCell` reports `statedPositiveQ16` /
  `statedNegativeQ16` apart from the rated mass; new reason `Told` when a
  context has statements but no ratings.
- **Persistence:** LifeSnapshot v2 section 12 `StatedPreference` (optional,
  version 1): sparse `count` + 7-byte entries {interaction, day part, action,
  stated + / − Q8.8}. Omitted when empty (snapshot stays 536 B); applied after
  the learner section; validated (bounds, duplicates, zero entries, count) and
  clamped to the cell mass.

## Validation

- `test_stated_preference` (15 tests): parse table (flag on/off, length,
  polarity, voice/button source, reserved, id 0, existing opcodes), weight,
  **cap under 100 repeated statements**, opposite statement, **ratings
  override statements**, explanation `Told` and separate stated mass,
  section 12 roundtrip/omission/validation/clamp, commit and reboot,
  invalid context/action/source, **duplicate applied once**, failed commit
  and retry, pending decision untouched, ERROR_SAFE read-only.
- Native **179/179 PASS**. `lifecore_lab` c1–c8 and `life_timeline`
  unchanged. Xtensa C++11 `-Werror` smoke PASS.
- ESP32 build SUCCESS: RAM **48,976 B (+648)**, Flash 1,347,853 B (+196).
  The production board-trial learner shares `PreferenceLearnerV3`, whose
  cells grew by 4 bytes (stated shares) × 160 reserved cells; behaviour is
  unchanged (opcode 6 stays off in production). The board-trial upload
  target remains `5d872d3`.

## Not done

BLE adapter wiring and capability bit 5 (S18), app flow (S27a), the
`w_s`/cap tuning and override timing in Life Lab (S25).

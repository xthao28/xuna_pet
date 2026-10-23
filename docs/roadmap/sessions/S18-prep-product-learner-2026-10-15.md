# S18 preparation — product learner in LifeCore (2026-10-15)

Status: **host-only**. `LifeCore` now runs the D5 product shape with learner
v3 deciding and LifeSnapshot v2 as the durable record. Production firmware is
unchanged (v1 + `BoardLearner`, 96-byte snapshot) until S13/S18 wiring.

Owner choice (2026-10-15): replace the v1-authoritative/v3-shadow composition
outright rather than keep two modes. The v1/v3 shadow comparison numbers stay
in their records and Git history; `LearningBridgeV3` remains as a lab
component with its own tests.

## What changed

| Piece | Before | Now |
|---|---|---|
| Learner in `LifeCore` | v1 `LifeEngine` decides; v3 2 × 5 × 2 shadow, reset at boot | v3 3 × 5 × 3 (quiet/play/button_greeting × idle/happy/curious, E10 parameters) decides via `ProductLearner` |
| Durable record | v1 96 B through `ILifeCommit` | `LifeSnapshotV2` through `ISnapshotCommit` (commit-first, §9.5) |
| GPIO0 | direct happy request | `LifeCoreEventKind::Greeting`: XUNA chooses how to answer; device decision ID ≥ `0x80000001` |
| Choice | v1 action, then gate; refused → nothing | learner chooses only among actions the FSM/cooldowns accept now (probe of `ActionGate` + `ActivityFsm` copies); nothing allowed → previous decision kept |
| Direct request (app command, GPIO14) | no effect on pending | invalidates the pending decision (MVP rule, as the BLE adapter does) |
| Forget | v1 clear | commit-first empty snapshot to **both** A/B slots; counters kept; refused in ERROR_SAFE |
| Snapshot lab | v1 A/B bytes | `MemorySnapshotStore` (v1 input + v2 A/B, torn power cut) + `SnapshotStore::recover`; boot policy Ok/Migrated/Missing → start, TooNew/Corrupt/MigrationFailed → ERROR_SAFE |
| Trace runner | button A = happy request | button A = greeting, B = idle request; final counters from the v2 snapshot |

`ProductLearner` (new, `xuna/learning/ProductLearner.h`) stages the whole
snapshot for a rating: learner update, episode (learner indices) and
`feedbackCount`, then commits, then adopts. A failed commit leaves RAM and the
pending decision unchanged for a retry.

Recovery change in `SnapshotStore::recover`: a lone torn v2 slot with no v1
now gives Missing (fresh pet) instead of Corrupt, so a power cut during a new
pet's very first commit does not end in ERROR_SAFE.

## Protocol notes for S18 (Proposed, not wired)

- App command IDs must stay below `0x80000000`; `Choose` rejects IDs in the
  device range so they cannot collide with greeting decisions in the
  learner's duplicate window.
- The app needs the pending decision's context (`decisionContext`) and ID to
  rate a greeting; BLE life status bytes 2/12–15 carry context and decision
  today, and byte 2 must accept the value 2.
- D3 approved 2026-10-15 (120 s): implemented in the core, see below. The
  BLE adapter needs a result code for `expired` (S18; the board-trial
  firmware has no window yet).
- Day part stays 0 until S10.

## Validation

- `test_life_core` 16 tests (product shape, greeting decision and rating,
  device-ID range, allowed mask while resting, direct-input invalidation,
  greeting preference moving to curious under owner ratings, forget).
- `test_life_core_snapshot` 8 tests (exact learner restore across reboot,
  power cut, failed commit and retry, §9.9 spam, corrupt newest slot, **v1
  MVP pet upgrade**, newer schema → read-only ERROR_SAFE, forget on both
  slots). `test_life_core_trace` unchanged expectations PASS.
- Native **152/152 PASS**. ESP32 build unchanged (RAM 48,328 B, Flash
  1,347,657 B; core not linked into production); purity PASS. Xtensa g++
  8.4.0 C++11 `-Werror` compile smoke of `LifeCore` with a commit port: PASS.
- `lifecore_lab` on the 12 traces: c1–c7 behave as their headers expect
  (c3: events 4 / generation 4 under commit-first); l4/l5 are `lifelab`
  traces and are rejected as before.
- `life_timeline` idle/casual/active 8 h: output byte-identical to HEAD, so
  needs/activity/mood behaviour is unchanged.

## Resource notes (Xtensa `-fstack-usage`, host `sizeof`)

- `LifeCore` 2,264 B; `LifeSnapshotV2` 2,104 B (the learner reserves the
  4 × 5 × 8 maximum: 1,920 B of cells for 45 used).
- Feedback path stack: `ProductLearner::feedback` 2,176 B + `SnapshotStore::
  commit` 1,616 B ≈ 3.8 KB. Boot recovery ≈ 6 KB (S12 record). S13/S18
  should use static scratch, or shrink the learner's reserved shape.

## Not done

BLE/main wiring (S18), storage adapter and keys (S13 after D2), S10 day
parts, D3 window, explanation (§9.6) over the product shape in the app,
board checks.

## D3 feedback window (owner-approved 2026-10-15)

- `ProductLearner::kFeedbackWindowMs = 120000`. `show(decision, now)` stamps
  the time; `expire(now)` ends an unrated decision after 120 s (wrap-safe
  `uint32_t` difference) and remembers its ID, so a late rating reports
  `Expired` instead of unknown. A rating at exactly 120 s is accepted.
- `LifeCore` expires the pending decision at the end of every step
  (`decisionExpired`, once) and reports late ratings with `feedbackExpired`
  (plan §9.5 rejection `expired`); nothing is committed or learned. A retry
  after a failed commit is bound by the same window.
- Direct input still invalidates the pending reaction (unchanged).
- Tests: window edge, late rating (twice), unrated timeout reported once,
  `millis()` wraparound inside the window, failed-commit retry after the
  window. Native 164/164 PASS; traces, `life_timeline` and the ESP32 build
  unchanged.

# Learner v3 — Phase 1, slice 1 (2026-10-15)

Status: lab/shadow candidate, owner-requested Phase 1 (L-D1). Not wired into
production; v1 stays authoritative (D1, S18 gates). Preliminary E10 evidence,
not E10 acceptance.

## What was added (firmware, uncommitted)

| File | Purpose |
|---|---|
| `lib/xuna_core/include/xuna/learning/PreferenceLearnerV3.h` | Plan §9.3 estimator: Q16.16 discounted Beta (γ), only the rated cell discounted; hierarchical day-part prior (coarse cell per interaction, fine cell per day part used once nEff ≥ m, prior strength k). §9.4 policies: Greedy, A ε-greedy (confidence-scaled), C UCB, D learning progress (ε from \|fast − slow\| prequential error EMA, novelty while nEff < c). Allowed-action mask, RNG tie-break, duplicate/invalid feedback rejection, fingerprint. No heap |
| `test/test_learning_v3/test_main.cpp` | 10 tests: rated-cell-only discount, silence invariance, γ-bounded mass, reversal recovery ≤ 30 ratings, fine cell takeover and isolation, duplicate/invalid rejection, mask and determinism, ε shrink with confidence, progress reacts to surprise, UCB tries unrated actions |
| `lib/xuna_core/include/xuna/lab/LearnerBench.h` | `V3BenchLearner(policy, γ)`; four bench contexts map to 2 interactions × 2 day parts |
| `sim/learning_bench.cpp` | v3 variants, new `dayparts` scenario, `--gamma` flag |

RAM: 4 interactions × 5 day parts × 8 actions × 8 B = 1,280 B at the maximum
shape. A 2 × 5 × 4 product shape needs 320 B. Persistence v2 (L2) must store
only the used shape.

Validation: native 105/105 PASS (19 suites); ESP32 build SUCCESS, unchanged
RAM 46,208 B / Flash 1,343,337 B (v3 not linked); purity PASS; bench builds
with g++ 16 `-Werror`.

## Results (200 seeds, γ = 0.95 unless stated; regret in expected approvals lost)

| Scenario | v1 | v2 | v3 greedy | v3 A ε | **v3 C UCB** | v3 D progress |
|---|---|---|---|---|---|---|
| B oracle | 1.64 | **1.38** | 1.51 | 5.54 | 1.42 | 10.92 |
| C reversal (reach %) | 43.1 (0%) | 31.4 (26%) | 30.8 (45%) | 34.1 (53%) | **21.2 (84%)** | 33.1 (85%) |
| Drift (reach %) | 44.5 (0.5%) | 26.8 (51%) | 25.6 (69%) | 26.1 (73%) | **16.6 (95%)** | 28.0 (94%) |
| Noisy | 6.06 | 5.30 | 6.39 | 6.09 | **4.75** | 6.74 |
| Sparse | **13.8** | 14.5 | 14.5 | 38.2 | 14.8 | 60.1 |
| 4 actions | — | 4.32 | 4.55 | 9.75 | **4.21** | 21.5 |
| Day parts | — | **2.88** | 7.06 | 14.5 | 6.44 | 28.4 |
| No feedback: state unchanged | yes | yes | yes | yes | yes | yes |

γ sensitivity, v3 C UCB:

| γ | Reversal regret (reach) | Drift regret (reach) | Oracle | Noisy (flips after target) |
|---|---|---|---|---|
| 0.90 | 14.5 (98%) | 12.0 (97%) | 1.48 | 4.73 (2.61) |
| 0.95 | 21.2 (84%) | 16.6 (95%) | 1.42 | 4.75 (2.20) |
| 0.99 | 32.5 (22%) | 29.3 (46%) | 1.41 | 4.72 — |

## Findings

1. **Discounting fixes the main weakness.** v3 with UCB recovers after a
   reversal in 84% of seeds at γ 0.95 and 98% at γ 0.90, against v1 0% and v2
   26%. Discounting alone (v3 greedy) gets to 45%; optimism adds the rest.
2. **UCB (C) is the preliminary E10 winner.** It is best or within the CIs of
   the best in oracle, reversal, drift, noisy, sparse and 4-action scenarios.
   It is deterministic and integer-only. The E10 rule ("simplest within 5%
   regret") favours it over A and D in this bench.
3. **A and D pay for exploring when nobody answers.** ε does not shrink on
   unrated trials, so in the sparse scenario A costs 2.6× and D 4× the regret
   of UCB. Variant D recovers as often as UCB but explores too much at its
   current settings (novelty threshold, gain 4). D needs tuning, or exploration
   tied to the chance of feedback, before it can compete. It stays an E10
   candidate.
4. **The hierarchical prior costs learning speed when day parts disagree.**
   In `dayparts`, flat v2 (four separate contexts) has regret 2.88 against
   6.44 for v3: until the fine cell reaches nEff ≥ m = 3, the coarse estimate
   mixes the two day parts and the greedy action flips (1.6–1.9 flips). k and m
   are Proposed and need a sweep, plus a scenario where a new day part benefits
   from the shared prior.
5. **γ trades adaptation against stability.** 0.90 adapts much faster; noisy
   flips rise from 2.20 to 2.61. The owner-visible cost of flips is a product
   question, so γ stays Proposed in [0.90, 0.95].

## Not done

- No production wiring, persistence v2 or explanation mapping for v3.
- k/m sweep and the "new day part" generalization scenario.
- Tuning D (novelty threshold, gain, feedback-aware exploration).
- 200-seed CIs for every γ cell are in the CSV, not in this table.

## Next

1. Sweep k, m and D's parameters; add a generalization scenario.
2. If C stays ahead, propose v3 C (γ in [0.90, 0.95]) as the M05a learner for
   E10 acceptance, then L2 persistence/migration and shadow wiring.

## Slice 2 — parameter sweep (2026-10-15)

Added (firmware, uncommitted):

- `LearnerV3Config::feedbackAware`: A/D scale ε by the recent share of rated
  decisions (EMA over choices). This is transient exploration bookkeeping,
  excluded from the fingerprint and not persisted.
- `BenchConfig::lateContextsFrom` and the `lateCorrect` metric (greedy correct
  on the first 10 appearances of a context that appears late).
- `new_daypart` scenario: day parts agree; the evening appears only from trial
  80. It tests generalization from the shared prior.
- `sim/learner_sweep.cpp`: 81 UCB configurations (γ × k × m × bonus), 8 A and
  48 D configurations; 8 scenarios × 200 seeds; runs in about 2 s.
- `v3_C_tuned` in `learning_bench`; 1 more unit test (106/106 native PASS,
  ESP32 build unchanged).

Ranking: per scenario, regret divided by the best configuration's regret,
averaged over the 8 scenarios (1.00 would be best everywhere).

| Configuration | Score | Worst ratio | Noisy flips |
|---|---|---|---|
| **C γ 0.90, k 1, m 1, bonus 0.15** | **1.114** | 1.30 | 1.74 |
| C γ 0.90, k 2, m 1, bonus 0.15 | 1.123 | 1.28 | 1.74 |
| C γ 0.925, k 1, m 1, bonus 0.25 | 1.140 | 1.32 | 2.18 |
| C plan defaults (γ 0.95, k 2, m 3, bonus 0.25) | 1.272 | 1.75 | 1.85 |
| Best A (γ 0.90, feedback-aware, ε_max 0.15) | 2.424 | 5.39 | 3.35 |
| Best D (γ 0.90, feedback-aware, gain 1, c 2) | 3.179 | 8.56 | 3.48 |

18 UCB configurations are within 5% of the best score.

Tuned v3 C against earlier learners (200 seeds, regret with 95% CI):

| Scenario | v1 | v2 | v3 C defaults | **v3 C tuned** |
|---|---|---|---|---|
| B oracle | 1.64 | 1.38 | 1.42 | **1.33** [1.17, 1.51] |
| C reversal (reach) | 43.1 (0%) | 31.4 (26%) | 21.2 (84%) | **16.3** [15.5, 17.1] (94%) |
| Drift (reach) | 44.5 (0.5%) | 26.8 (51%) | 16.6 (95%) | **13.1** [12.1, 14.1] (96%) |
| Noisy (flips) | 6.06 (0.85) | 5.30 (1.75) | 4.75 (2.20) | **4.72** (2.05) |
| Sparse | 13.8 | 14.5 | 14.8 | 14.1 |
| 4 actions | — | 4.32 | 4.21 | **4.10** |
| Day parts disagree | — | **2.88** | 6.44 | 4.15 |
| New day part (first-10 correct) | — | 2.75 (83.5%) | **1.44 (99.9%)** | 1.68 (98.3%) |
| No feedback: state unchanged | yes | yes | yes | yes |

Findings:

1. **E10 preliminary choice: C (UCB).** The best A is 2.4× and the best D 3.2×
   worse on the averaged ratio. Feedback-aware scaling fixes their sparse
   problem (A sparse 27.5 → 15.8, D 33.7 → 16.2), but they keep paying for
   exploration in every other scenario. D stays a research option for
   visible curiosity, not the learner policy.
2. **Proposed defaults change:** γ 0.90, k 1, m 1, bonus 0.15 instead of
   γ 0.95, k 2, m 3, bonus 0.25. Effective memory drops from about 20 to about
   10 ratings. These stay Proposed until owner review of visible behaviour
   (flips) and board checks.
3. **The hierarchy trade-off is real and measured.** Shared prior: 98–100%
   correct on a new day part against 83.5% for flat contexts. Disagreeing day
   parts: 4.15 against 2.88 for flat. m = 1 (use the day-part cell after one
   rating) shrinks the cost.
4. **No configuration changes state without feedback** (§9.9 D holds).

Limits: a synthetic owner zoo (0.9/0.2 approval, alternating contexts), so the
tuned values may fit this bench. Real owner behaviour can differ. The tuned
learner is still lab-only.

Next: propose v3 C tuned as the M05a learner for E10 acceptance; then L2
persistence (store only the used shape), migration from the 96-byte v1
snapshot, explanation mapping (§9.6) and shadow wiring behind LifeCore.

## Slice 3 — learner section codec, v1 migration, explanation (2026-10-15)

Added (firmware, uncommitted; lab only, not linked into firmware):

| File | Purpose |
|---|---|
| `learning/LearnerV3Codec.h` | Learner payload for LifeSnapshot v2 (§7.5): 8-byte header (shape, flags, policyVersion) + 10-byte cells `{positive u32, negative u32, rated u16}`, only the configured shape (2 × 5 × 4 = 408 B). Typed errors (BadSize/BadShape/BadFlags/BadValue); validates before mutating, so a bad payload leaves a fresh learner, never a partial one. Shape changes keep overlapping cells and count dropped ones. `migrateFromV1` maps v1 counts to coarse cells with a mass cap of 1/(1 − γ) |
| `learning/LearnerV3Explanation.h` | §9.6 explanation: per-action p, nEff, positive/negative mass, raw `rated`, fine/coarse flag, greedy action, margin, policy version, reason (HighestEstimate/Exploration/NoEvidence). No prose on the device |
| `PreferenceLearnerV3.h` | Raw `rated` count per cell (saturating); codec access; error EMAs and rated share documented as transient (not persisted, not fingerprinted) |
| `test/test_learner_v3_codec` | 7 tests: size, bit-exact round trip and identical later decisions, corrupt payload rejection without partial state, shape growth/shrink, exact small-count migration, capped long-history migration that still flips within 20 ratings, explanation fields and reasons |
| `tools/check_core_purity.py` | Reads sources as UTF-8. On Windows it used cp1252 and crashed on non-Latin text in a comment |

Validation: native 113/113 PASS (21 suites); ESP32 build SUCCESS with
unchanged RAM 46,208 B / Flash 1,343,337 B; purity PASS.

Decisions and limits:

- The capped migration is a **Proposed** amendment to plan §7.5 (which said
  `alpha = 1 + positive`). Reason: uncapped v1 counts would reproduce v1's
  failure to adapt.
- The sectioned container, CRC-32 trailer, A/B slots and medium remain S12a/D2
  work. The codec owns only the learner payload.
- The 8 v1 episodes are not migrated here; they belong to the memory store
  (M05b).
- `statedMass` (Layer A stated preferences) is not in the explanation yet; it
  arrives with M05c-A.

Next: shadow wiring of v3 behind `LifeCore`/`LearningBridge` (replacing v2 as
the shadow candidate), then E10 acceptance review and the §9.5 parity fix
before any production use.

## Slice 4 — v3 as the LifeCore shadow candidate (2026-10-15)

Added/changed (firmware, uncommitted; host core only, production BLE path
unchanged):

- `learning/LearningBridgeV3.h`: v1 baseline + v3 candidate seam with metrics
  (decisions, agreements, candidate exploration, accepted/rejected feedback).
- `LifeCore` now uses `LearningBridgeV3` and `LifeCore::shadowConfig()` (tuned
  Proposed values: UCB, γ 0.90, k 1, m 1, bonus 0.15; 2 interactions × 5 day
  parts × 2 actions; day part 0 until S10). Exposes `shadowMetrics()`. The
  candidate and its metrics reset on boot.
- Tests: LifeCore and snapshot-lab suites use `shadowMetrics()`, check that v3
  is credited on the shown action, and check that the candidate restarts fresh
  after reboot; 2 new bridge tests (shown-action credit, single v1 training,
  bad source/context). Native 115/115 PASS; ESP32 build unchanged (RAM
  46,208 B, Flash 1,343,337 B); `lifecore_lab` replays all seven `c*.trace`
  files with the same bookkeeping results as before (fingerprints change
  because the candidate changed).

Finding — **v2 shadow credited the wrong action.** The v2 `LearningBridge`
applied the owner's rating to v2's *own* candidate action, while the owner had
rated the action v1 showed. In shadow mode v2 therefore learned from ratings of
actions it never showed. `LearningBridgeV3` credits the shown action. The v2
bridge stays only for its existing tests and the v2-based `lifelab`; its
shadow agreement numbers from earlier sessions should not be used as evidence.

Still open before production use: §9.5 commit-failure parity in `LifeCore`,
persistence of the candidate (L2 container, S12a/D2), trusted day parts (S10),
action vocabulary (D5), E10 acceptance review and owner board checks.

## Slice 5 — §9.5 commit-first parity in LifeCore (2026-10-15)

- `life/LifeCommit.h`: `ILifeCommit::commit(LifeEngine& staged)`, same shape
  as production `LifeStorage::save`.
- `PreferenceLearnerV3::accepts()`: side-effect-free feedback validation.
- `LearningBridgeV3::feedback(..., ILifeCommit*)` returns
  Applied/Rejected/CommitFailed: validate both learners, stage v1, commit, then
  apply v1 and v3. `commitFailures` metric added.
- `LifeCore::setCommitter()`, outputs `feedbackCommitted` and
  `feedbackNotReady`; without a committer the old apply-then-`persistRequested`
  path remains for adapter-free tests.
- `LifeCoreSnapshotLab` implements `ILifeCommit` and installs itself (copying
  is now deleted); `persist()` stays for lazy commits. The trace runner counts
  committed and failed urgent commits.
- New test: a failed commit leaves v1, generation and the v3 fingerprint
  unchanged, keeps the decision pending, and a retry commits exactly once.
  Native 116/116 PASS; ESP32 build unchanged; traces c2/c3 change as
  described in the [lab runs update](lifecore-lab-runs-2026-10-15.md).

## D5 product vocabulary (2026-10-15)

Owner decision D5: learnable actions **idle, happy, curious** (existing art)
and the **GPIO0 press as a learnable `button_greeting` context**. Day parts
stay planned with trusted time (S10).

- `learning/LearnerVocabulary.h`: `LearnInteraction` (quiet 0, play 1,
  button greeting 2), learner index → `ActionId` (0 idle, 1 happy, 2 →
  `ActionId::Curious` 3) with v1's 0/1 positions unchanged so migration keeps
  their meaning, and `productLearnerConfig()` (3 × 5 × 3, tuned Proposed
  values; 458-byte learner payload).
- New test: mapping, payload size and v1 migration into the product shape
  (greeting cells start empty). Native 117/117 PASS; ESP32 build unchanged.
- `LifeCore::shadowConfig()` stays 2 × 2 because v1 still picks what is shown
  and cannot represent the greeting context or curious. The product shape is
  used when v3 becomes authoritative (after E10, S12a/D2, S18).

Bench, product shape (200 seeds):

| Scenario | v2 | v3 C defaults | **v3 C tuned** |
|---|---|---|---|
| 3 × 3 stable (regret; median trials to target) | 3.96; 15 | 4.18; 14 | **4.09; 14** |
| 3 × 3 reversal at trial 120 (regret; reach) | 63.9; 20.5% | 38.6; 92% | **29.4; 96.5%** |

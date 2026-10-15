# E10 review packet — learner selection for M05a (2026-10-15)

Status: **E10-A, E10-B (γ 0.90) and E10-C approved by the owner on 2026-10-15.** Evidence is host Life Lab only. Accepting this
packet selects the M05a learner and its starting parameters. It does not
enable v3 on the board; the production gates in §5 remain.

## 1. Decision requested

| ID | Question | Recommendation |
|---|---|---|
| E10-A | Select learner v3 with policy C (UCB) as the M05a learner, replacing the plan default ε-greedy (A) | Yes |
| E10-B | Starting parameters: γ 0.90, k 1, m 1, UCB bonus 0.15 (instead of γ 0.95, k 2, m 3, bonus 0.25) | Yes, provisional until the owner board check (§4) |
| E10-C | Capped v1 migration (mass ≤ 1/(1 − γ), ratio kept) as the plan §7.5 amendment | Yes |

E10's rule (plan §16.2): pick the simplest learner within 5% regret of the
best. UCB is deterministic, integer-only and needs no extra state beyond the
estimator, so it is also the simplest of the three exploration policies.

## 2. Selection evidence (200 seeds per scenario)

Averaged regret ratio over 8 scenarios (1.00 = best in every scenario), from
`sim/learner_sweep.cpp` across 137 configurations:

| Candidate | Score | Worst scenario ratio |
|---|---|---|
| **C UCB, γ 0.90, k 1, m 1, bonus 0.15** | **1.11** | 1.30 |
| C UCB, plan defaults | 1.27 | 1.75 |
| Best A ε-greedy (feedback-aware) | 2.42 | 5.39 |
| Best D learning progress (feedback-aware) | 3.18 | 8.56 |

Tuned v3 against the production learner (v1) and v2, from
`sim/learning_bench.cpp`:

| Scenario | v1 | v2 | **v3 C tuned** |
|---|---|---|---|
| Stable preference (regret) | 1.64 | 1.38 | **1.33** [1.17, 1.51] |
| Reversal: recovers within 60 trials | 0% | 26% | **94%** |
| Gradual drift: recovers | 0.5% | 51% | **96%** |
| Product 3 × 3 stable (median trials) | — | 15 | **14** |
| Product 3 × 3 reversal: recovers | — | 20.5% | **96.5%** |
| New day part correct immediately | — | 83.5% | **98.3%** |
| Day parts disagree (regret) | — | **2.88** | 4.15 |

## 3. Plan §9.9 proof-of-learning status

| Scenario | Pass hypothesis | Status | Evidence |
|---|---|---|---|
| B oracle | Beats random/static/no-learning, non-overlapping 95% CIs | **Met (host)** | Regret 1.33 [1.17, 1.51] vs random 20.8 [20.4, 21.1], static 21.0 |
| C reversal | Recovers within O(1/(1 − γ)) ratings; ≤ 2 flips after recovery | **Met (host)** | Median 34 trials over 2 alternating contexts (≈ 17 per context, order of 1/(1 − γ) = 10; p90 47); 0.05 flips |
| D no feedback | Cells bit-identical to fresh | **Met (host)** | `state_unchanged_all = yes`; unit test `silence_never_changes_state` |
| Isolation | Other interactions unchanged; coarse transfer documented | **Met (host)** | Unit test `fine_cell_needs_evidence_then_takes_over`; transfer measured in `new_daypart` (98.3%) and its cost in `dayparts` |
| E reboot parity | Same trace host vs target, bit-identical | **Partly**: host codec round trip is bit-exact and decisions match after reload; target run **not done** | `round_trip_is_bit_exact`; needs board (E2) |
| Spam | ≤ 1 apply per reaction; commit guard holds | **Met (host)** | `feedback_spam_applies_once_and_commits_once`: 1,000 attempts → 1 apply, 1 commit |
| Stated vs rated | Stated mass capped; ratings override | **Not started** | Needs Conversation Layer A (M05c-A) |

Not yet measured: `step()` CPU time on the board (E6) and fixed-point parity on
the target (E2).

## 4. What the owner should check on the board (after wiring)

1. **Flip feel:** with γ 0.90 XUNA follows a change in about ten ratings per
   context. With an inconsistent owner it changes its mind about twice per 120
   reactions. If that feels restless, raise γ toward 0.95 (slower to adapt,
   steadier).
2. **Exploration feel:** UCB occasionally tries a less-rated action; the
   explanation labels it "trying" (`V3Reason::Exploration`). D4 (visible
   exploration, stage-scaled) stays open: if the owner wants a young XUNA to
   explore more, scale the UCB bonus by stage and label it as gameplay.
3. **Greeting:** the GPIO0 greeting (D5) is the most frequent context; check
   that rating it in the app within the feedback window (D3) is comfortable.

## 5. Gates before v3 drives the board

- Container for LifeSnapshot v2: section framing, CRC-32, A/B slots and medium
  (S12a, D2 after E4/E5).
- Trusted time for day parts (S10).
- LifeCore integration into the main loop and BLE adapter (S18), using
  `productLearnerConfig()` (3 × 5 × 3).
- E2/E6 on the target; owner board acceptance.

## 6. Risks and limits

- The simulated owner is synthetic (0.9/0.2 approval, alternating contexts).
  Real owners may rate less often, more noisily or in bursts; parameters may be
  fit to this bench.
- When day parts genuinely disagree, the shared prior costs some speed (4.15
  vs 2.88 regret). m = 1 limits this; revisit with real data.
- Earlier v2 "shadow agreement" numbers are invalid (the v2 bridge credited the
  wrong action) and are not used here.

Sources: [learner v3 record](learner-v3-phase1-2026-10-15.md),
[Life Lab Phase 0](life-lab-phase0-2026-10-15.md),
[plan §9, §16.2](../architecture/XUNA_IMPLEMENTATION_PLAN.md).

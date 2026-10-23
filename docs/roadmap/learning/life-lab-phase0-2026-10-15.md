# Life Lab Phase 0, slice 1 — closed-loop learner benchmark (2026-10-15)

Status: host experiment evidence for LRN-03 (owner-selected, L-D1 approved).
This is not E10 acceptance, not S19a completion and not a board result. No
production code changed.

## What was added (firmware, uncommitted)

| File | Purpose |
|---|---|
| `lib/xuna_core/include/xuna/lab/OwnerModel.h` | Simulated owner whose approval depends on the action XUNA showed: Oracle (§9.9 B), Reversal (C), NoFeedback (D), gradual Drift; rating rate for sparse owners. Fixed-point, seeded, no heap |
| `lib/xuna_core/include/xuna/lab/LearnerBench.h` | Closed-loop runner and adapters for random, static ("always idle"), v1 `LifeEngine` and v2 `PreferenceLearnerV2`. Metrics: regret, greedy-correct in the last 20 trials, trials to a stable target, flips after target, prequential Brier, state unchanged without feedback |
| `test/test_life_lab/test_main.cpp` | 8 Unity tests: owner probabilities per scenario, deterministic sampling and rating rate, per-seed determinism, no-feedback invariance, exact static regret, v1 rejects 4 actions, v2 beats random, curve recording |
| `sim/learning_bench.cpp` | CLI: 7 scenarios × 4 learners × 200 seeds; summary CSV with bootstrap 95% CIs, or `--curves` for per-trial greedy-correct rates |

Validation: native 95/95 PASS (18 suites); ESP32 build SUCCESS with
unchanged RAM 46,208 B / Flash 1,343,337 B (lab headers are not linked into
firmware); purity PASS; `learning_bench` builds with g++ 16 `-Werror` and runs
in under 0.1 s.

```text
g++ -std=c++11 -Wall -Wextra -Werror -O2 -Ilib/xuna_core/include sim/learning_bench.cpp -o learning_bench
learning_bench [--seeds N] [--curves]
```

## Scenarios

Two contexts. Preferred action: context 0 → 1, context 1 → 0 (reversed in C
and drift). P(approve | preferred) = 0.9, otherwise 0.2, unless stated.

| Scenario | Setup |
|---|---|
| B_oracle | 60 trials |
| C_reversal | 120 trials, preference switches at trial 60 |
| D_no_feedback | 100 trials, never rated |
| drift | 160 trials, preference moves linearly over trials 20–120 |
| noisy | 120 trials, 0.6 vs 0.4 |
| sparse | 300 trials, ~10% of actions rated |
| B_oracle_4actions | 120 trials, 4 actions (D5 preview) |

## Results (200 seeds; regret in expected approvals lost; CI = bootstrap 95%)

| Scenario | v1 regret [CI] | v2 regret [CI] | Random / static regret | v1 / v2 greedy correct, last 20 | Seeds reaching target (v1 / v2) |
|---|---|---|---|---|---|
| B_oracle | 1.64 [1.33, 1.98] | 1.38 [1.20, 1.57] | 20.8 / 21.0 | 0.995 / 1.000 | 99% / 100%, median 7 trials both |
| C_reversal | **43.1** [42.9, 43.4] | 31.4 [30.1, 32.6] | 42.0 / 42.0 | **0.024** / 0.470 | **0%** / 26%, v2 median 49 |
| D_no_feedback | 35.0 | 34.5 | 34.5 / 35.0 | — | state unchanged: yes for all |
| drift | **44.5** [44.0, 45.1] | 26.8 [25.3, 28.3] | 38.0 / 38.9 | 0.111 / 0.656 | 0.5% / 50.5% |
| noisy | 6.06 [5.23, 6.92] | 5.30 [4.58, 6.01] | 11.9 / 12.0 | 0.801 / 0.849 | 69% / 79% |
| sparse | 13.8 [12.0, 16.1] | 14.5 [12.2, 16.8] | 104.6 / 105.0 | 1.000 / 0.997 | 100% / 100%, median 27 |
| B_oracle_4actions | unsupported | 4.32 [3.86, 4.85] | 62.8 / 84.0 | — / 0.998 | — / 99.5% |

Reversal learning curve (share of seeds whose greedy action is correct):

| Trial | 60 | 70 | 80 | 90 | 100 | 110 | 120 |
|---|---|---|---|---|---|---|---|
| v1 | 1.00 | 0.00 | 0.00 | 0.00 | 0.01 | 0.01 | 0.09 |
| v2 | 1.00 | 0.00 | 0.05 | 0.20 | 0.32 | 0.44 | 0.54 |

## Findings

1. **Both learners learn a stable preference fast.** In B, sparse and the
   4-action case they beat random and static with non-overlapping CIs and reach
   the target in a median of 7–27 trials. The §9.9 B pass hypothesis holds for
   v1 and v2. v1 vs v2 in B is not distinguishable (CIs overlap).
2. **Neither handles changing preferences.** After a reversal, production v1
   does not recover within 60 trials in 100% of seeds and does worse than
   random. Under gradual drift it is worse than both baselines. v2 recovers in
   only 26% of seeds after reversal. Cause: undiscounted counts (evidence never
   fades) and, for v1, no exploration. This is the measured case for the
   §9.3 discounted estimator (γ) in Phase 1, and it fails §9.9 C ("recovers
   within O(1/(1−γ)) ratings") for both current learners.
3. **No feedback means no change.** All learners keep a bit-identical state
   (§9.9 D).
4. **Noise causes flipping.** With 0.6 vs 0.4 approval, v2 flips its greedy
   action 1.75 times after reaching the target (v1 0.85). Phase 1 should report
   flips together with regret.
5. **More actions are only possible with v2.** v1 cannot represent the D5
   4-action case at all.

## Limits

- Learner-level loop only. Activity/needs/mood time series through `LifeCore`
  and the 64-event cap of the older runners are the next Phase 0 slice.
- Contexts alternate deterministically. Day parts and trusted time are not
  modeled.
- The greedy metric of random and static is "always action 0", so their
  greedy-correct value 0.5 is a fixed reference, not learning.
- Parameters (0.9/0.2, trial counts, stable run 6) follow §9.9 or are lab
  choices. None is a product threshold.

## Next

- Phase 1: implement the §9.3 estimator (discounted Beta, hierarchical prior)
  as learner v3 and add it to this bench. Compare exploration variants A
  (ε-greedy), C (UCB) and D (learning-progress curiosity) for E10.
- Phase 0 slice 2: `LifeCore` time-series runner (activity, needs, mood,
  visual) over long generated runs, plus the §9.5 parity fix.

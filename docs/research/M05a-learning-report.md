# M05a learning report

Status: partial S25 evidence. Existing 200-seed B/C/D/isolation/E/spam results remain in the learner-v3 record. This update adds the required stated-vs-rated scenario.

## Stated vs rated

Method: for each configuration and 200 deterministic seeds, apply 20 identical like-statements to action 1, then apply up to 10 explicit negative ratings to the shown action. Sweep stated weight 0.25/0.5/0.75/1.0 and cap 1/2/3 rating equivalents. Source: `firmware/sim/stated_rated_bench.cpp`; results: `M05a-stated-rated-sweep.csv`.

Result: every configuration was overridden by explicit ratings. The number of negative ratings required equals the cap: 1, 2 or 3. With 20 repeated statements every weight reaches the cap, so this scenario cannot distinguish the weight values.

Interpretation: cap 2 meets the product rule that owner ratings win quickly while retaining more than one statement-equivalent. Cap 3 delays reversal without adding evidence of benefit. Keep cap 2 as the recommended starting value. Keep weight 0.5 Proposed: the required spam/override scenario proves safety but does not tune single-statement influence.

Limits: deterministic synthetic evidence, no owner timing/noise, no board. This is not physical acceptance and does not promote Proposed values to Approved.

## Weight sensitivity before the cap

An added 1/2/4/20-statement sweep measures the posterior immediately after statements. With cap 2, one statement gives p=0.556/0.600/0.636/0.667 for weights 0.25/0.5/0.75/1.0. Every option is still overridden by one negative rating. Weight 0.5 produces a visible but moderate shift to p=0.60; weights 0.75-1.0 add confidence without improving override safety. Four 0.5 statements reach cap 2 and p=0.75.

Recommendation: keep `w_s=0.5` and cap 2 as the S26 starting defaults, still Proposed until owner review. This is the smallest tested weight that reaches the selected cap within four consistent statements while one statement stays modest. Summary CSV: `M05a-stated-weight-cap2.csv`.

# S25 stated-vs-rated slice - 2026-10-16

Status: host stated-vs-rated and pre-cap weight sensitivity slices done; full S25 report remains partial.

The new C++11 runner applies 20 repeated positive statements, then negative explicit ratings, for 200 deterministic seeds across weights 0.25/0.5/0.75/1.0 and caps 1/2/3.

All configurations were overridden. Caps 1/2/3 required 1/2/3 negative ratings. Repeated statements saturate every cap, so this scenario cannot distinguish weights. Cap 2 remains the recommended starting point; weight 0.5 remains Proposed.

The follow-up 1/2/4/20-statement sweep shows that one statement at weight 0.5 moves the estimate from 0.50 to 0.60 and is still overridden by one negative rating. Four consistent statements reach cap 2 and p=0.75. Weight 0.5 plus cap 2 is therefore the recommended S26 starting pair, still Proposed until owner review.

Evidence: `docs/research/M05a-learning-report.md` and `docs/research/M05a-stated-rated-sweep.csv`.

Validation: runner C++11 `-Werror` PASS; native 179/179 PASS; whitespace PASS. No ESP32 build, board, app, commit or push.

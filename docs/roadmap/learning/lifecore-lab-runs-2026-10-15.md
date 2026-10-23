# LifeCore and Learning Lab runs — 2026-10-15

Status: host experiment evidence. It is not S18/S19a acceptance, a board result
or a tuning decision.

## Setup

- Machine: Windows 11, MSYS2 UCRT64 g++ 16.2.0. Firmware `aa2dbca` plus the
  uncommitted `BleProtocol.h` line split (no behavior change).
- Both runners build with `-std=c++11 -Wall -Wextra -Werror`, no warnings:

  ```text
  g++ -std=c++11 -Wall -Wextra -Werror -Ilib/xuna_core/include sim/lifelab.cpp -o lifelab
  g++ -std=c++11 -Wall -Wextra -Werror -Ilib/xuna_core/include sim/lifecore_lab.cpp -o lifecore_lab
  ```

- Traces: [firmware/sim/traces/](../../../firmware/sim/traces). Each file starts
  with a comment that states the expected result. Both runners use seed 1,
  stream 3.
- Determinism: rerunning every trace gives byte-identical CSV rows.

## What these runners can and cannot measure

Facts from the source, which limit how the results can be read:

- Traces are open-loop. `feedback <id> positive` is scripted and does not
  depend on the action the learner chose. The runners therefore cannot measure
  whether XUNA learns a user's real preference.
- Each run prints one summary row. Needs, energy, mood and activity over time
  are not exported.
- Each trace holds at most 64 events (32 choose/feedback pairs), so hours or
  days of life cannot be simulated.

Conclusion: these runners cover determinism, reboot/power-cut and feedback
bookkeeping. They cannot tune the Proposed values (needs decay, energy recovery
2048/min, FSM thresholds).

## LifeCore lab (`lifecore_lab`)

| Trace | Key result | Reading |
|---|---|---|
| c1 clean, 10 cycles | persists 10, generation 10, events 10 | As expected |
| c2 cut on 4th commit, reboot | 1 failure; recovered events 3, generation 3 | Uncommitted feedback lost on reboot, as expected |
| c3 cut on 4th, 5th commits | events 5, generation 4 | Failed feedback stays in RAM and is saved by the next commit |
| c4 reboot while pending | feedback applied 1 of 2 | Pending decision does not survive reboot |
| c5 choices 100 ms apart | feedback applied 1 of 3 | Only the latest accepted decision can take feedback |
| c6 duplicate, source 0 | feedback applied 1 | Both ignored |
| c7 reboots without slots | reboots 2, unsupported 3 | Fresh boot works; `day`/`sync`/`expect` not run |

### Finding: commit-failure semantics differ from production

- Production [BleManager.h](../../../firmware/include/BleManager.h) (opcode 3)
  applies feedback to a copy and saves it first. Only when the save succeeds
  does it replace `life`. On failure it returns result 7 and keeps the decision
  pending, so the app can retry.
- `LifeCore` applies feedback to v1 and v2 in RAM first, clears the pending
  decision, then asks for persistence. In the lab a failed commit is not
  reported back and cannot be retried. RAM then holds unsaved state until
  another feedback commits it (c3) or a reboot loses it (c2).
- The v2 shadow learner keeps feedback whose commit failed. It also resets on
  every boot, so v1 and v2 disagree about what was learned.

This is the "commit-failure semantics need parity coverage" item in the
[S18 readiness review](../sessions/S18-readiness-review.md). Before `LifeCore` replaces
the BLE path, it must follow the model that
[plan §9.5](../../architecture/XUNA_IMPLEMENTATION_PLAN.md) already specifies,
which matches production: commit first; on failure the ACK reports
`not_ready`, RAM is not mutated and the decision stays pending for retry. Add a
parity test.

## Learning lab (`lifelab`)

Brier scores are sums over samples in Q32. Per sample:
`brier_q32 / samples / 2^32`. The uniform baseline is 0.25.

| Trace | Accuracy | Brier per sample (v2 vs uniform) | Other |
|---|---|---|---|
| l1 ctx0 approve, ctx1 reject | 30/32 | 0.052 vs 0.25 | 10 exploratory, mostly in ctx1 where every action is rejected |
| l2 all approved | 32/32 | 0.019 vs 0.25 | v1/v2 agreement 0/32 |
| l3 alternating, no signal | 15/32 | 0.279 vs 0.25 | About 11% worse than uniform |
| l4 window/duplicate/bad source | — | — | unknown 1, rejected 2, as expected |
| l5 66 events | — | — | Exit 2, `too_many_events`, as expected |

Readings:

- With a consistent signal, v2 predicts approval far better than uniform (l1,
  l2). Because the trace is open-loop, this shows calibration to scripted
  feedback, not preference learning.
- The 0/32 agreement in l2 is an open-loop artifact. Each learner is rewarded
  for its own first choice and keeps it. The agreement metric means something
  only with a closed-loop user model.
- When feedback has no learnable pattern (l3), v2 is slightly overconfident and
  scores worse than predicting 0.5. Measure this with noisy users before v2
  drives behavior.

## Proposed next step (not started)

To tune the Proposed values and to measure learning, the lab needs:

1. A closed-loop user model: a hidden preference per context, feedback derived
   from the shown action, and optional noise.
2. Time-series output with activity, needs, mood and visual per step.
3. Long runs: a generated event stream instead of the 64-event trace cap.

This needs owner approval. It also overlaps the S19a simulator scope.

## Update — §9.5 parity implemented in LifeCore (2026-10-15)

`LifeCore` now follows plan §9.5 through an `ILifeCommit` port: feedback is
staged, committed, and only then applied to v1 and the v3 shadow. A failed
commit leaves RAM unchanged, keeps the decision pending for a retry and sets
`feedbackNotReady` (BLE result 7). The snapshot lab is the committer. Replayed
traces: `c2` now applies 3 feedbacks (the cut one is not applied) and `c3`
ends with event_count 4 instead of 5, because the failed feedback never reaches
RAM. All other traces are unchanged. The finding above is resolved for
`LifeCore`; production `BleManager` already behaved this way.

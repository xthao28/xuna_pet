# M04 review fixes — 2026-10-14

Date: 2026-10-14 (Asia/Ho_Chi_Minh). Environment: macOS with the pinned PlatformIO toolchain (first compilation of the S14–S17, Learning L1–L1.9 and LifeCore slices, which were written on Windows without a compiler).

Scope: owner-requested review of firmware commits `a518ede`, `f784626`, `6b1110e`, then fixes. No board upload/NVS operation, mobile or backend work, commit or push.

## Findings and fixes

| # | Severity | Finding | Fix |
|---|---|---|---|
| 1 | High (production) | `Needs` energy only decayed; nothing raised it. After ~48 min uptime the pet entered Resting and could never leave it (`kRestExit` unreachable); Sleep/Idle were refused and, from ~60 min, Happy/Curious too. Only a reboot recovered. | Owner chose recovery while resting: `LifeTuning::energyRecoveryPerMinute` (**Proposed** placeholder 2048/min, ~4 min of Resting) replaces energy decay while `ActivityFsm::recoversEnergy()` (Resting, Sleeping). Main loop and `LifeCore` pass the activity held since the previous update. |
| 2 | Medium (production) | BLE opcode 2 overwrote `context_` before the action was validated. A rejected choice (e.g. cooldown) left the previous decision pending, so its feedback trained and persisted the wrong `(context, action)` pair. | `context_` is committed only with an accepted decision. |
| 3 | Medium (production) | A new reaction while Reacting did not restart the Reacting timer (plan §8.1: "timer restarts") because the FSM was only called when `state != target`. Happy then Curious within 2.4 s cut Curious short. Found by the new tests. | Reacting → Reacting is requested explicitly. |
| 4 | Medium (host) | `LifeCore` diverged from the BLE adapter: no wake-from-sleep or Sleep-through-Idle routing; `lastVisual_` never expired (Happy reported forever); Choose kept a pending decision even when the action was rejected. | New pure `xuna/life/ActionGate.h` is the single action path for `BleManager` and `LifeCore`; LifeCore expires the action visual when its activity changes and records a decision only when the action is accepted. |
| 5 | Medium (tests) | Five suites failed: `BehaviorCandidate` brace tables and `LearningTrace.h:89` (`*slot` vs `slot->decision`) did not compile in C++11; `test_activity_fsm` helper/guard setup and the `test_needs_mood` partition case were wrong (FSM/Needs code was correct). | Constructor added to `BehaviorCandidate` (D12 C++11); trace runner passes the decision; tests corrected. |
| 6 | Low | ErrorSafe → Booting without `reboot` returned `Busy` although `GuardReboot` exists. | Returns `GuardReboot`. |

Not a defect: storage-open failure entering ErrorSafe with every action refused matches plan §8.1 ("storage fatal → ERROR_SAFE", exit only by reboot).

## Validation (this session)

- `pio test -e native`: 17/17 suites, 87/87 cases PASS. `pio test -e native_asan`: 87/87 PASS.
- `pio run -e xuna_t_display_s3`: SUCCESS, purity check PASS; RAM 46,208 B, Flash 1,343,357 B (before fixes: 46,200 B / 1,343,077 B).
- `sim/lifelab.cpp` and `sim/lifecore_lab.cpp` build with `-std=c++11 -Wall -Wextra -Werror`.
- New `test_action_gate` (wake, Sleep routing, FSM-guard refusal, ErrorSafe, cooldown wrap, 3 h main-loop regression, sleep recovery) and LifeCore/Needs regressions; mutation checks confirmed the regressions fail without the fixes.
- `git diff --check` PASS.

Not run: board upload, physical button/BLE acceptance, mobile handling of result 5. The BLE opcode 2 fix is in an Arduino-only adapter and is covered indirectly by the equivalent LifeCore test.

## Remaining / next

- Tune recovery, decay, cooldown and dwell values in Life Lab (all Proposed).
- Fact: a Sleep request while Resting is refused (busy 5) until energy reaches `kRestExit`, per the §8.1 table (no Resting → Sleeping edge).
- S17 owner check on the board remains required before S17 is promoted.

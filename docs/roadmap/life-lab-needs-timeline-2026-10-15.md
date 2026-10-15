# Life Lab Phase 0, slice 2 — needs, rest and mood over time (2026-10-15)

Status: **owner-approved 2026-10-15:** the life-feel targets, and the candidate
configuration for a board trial (enabled in firmware via `xuna/life/LifeFeel.h`;
provisional until the owner board check). Original status: host experiment
evidence plus Proposed tuning. The shipped board
behaviour is unchanged: every new knob defaults to the current behaviour. The
candidate values below need an owner decision before they reach the board.

## Tool

- `sim/life_timeline.cpp` steps the real `LifeCore` once per simulated second
  for up to 72 hours with an owner profile:
  - **idle:** no interaction;
  - **casual:** every 30 min, a 3-minute session with a request every 20 s;
  - **active:** every 10 min, a 5-minute session with a request every 10 s.
- It prints a summary row (share of time per activity and mood, energy range
  after the first hour, rest entries, accepted requests, maximum stimulation)
  or a per-minute series (`--series`).
- `sim/life_sweep.py` runs a grid of knobs against the life-feel targets
  below.

## Findings with the shipped values (8 hours)

| | idle | casual | active |
|---|---|---|---|
| Resting share | 30% | 30% | 31% |
| Energy after the first hour | 25–38% | 25–38% | 25–38% |
| Time with energy < 37.5% | 91% | 91% | 91% |
| Max stimulation | 0 | 0 | 0 |
| Mood excited / curious | 0% | 0% | 0% |
| Mood sleepy | 30% | 42% | 55% |

Facts from the source, confirmed by the runs:

1. **Shallow rest cycle.** Energy decays 1024/min and hits the rest threshold
   (25%) after 49 minutes. Resting recovers 2048/min but ends at 37.5%
   (`restExit`), after about 4 minutes. From then on XUNA alternates about
   8 minutes awake and 4 minutes resting, with energy never above 38%.
2. **Actions cost nothing.** The registry energy costs (happy 4096, curious
   2048) are only checked as guards and never spent, so play does not tire
   XUNA.
3. **Stimulation never rises.** `Needs` only decays stimulation; it starts at
   0, so the excited, curious and overwhelmed moods are unreachable.
4. **Interrupted rest is lost.** Input during Resting goes to Reacting and
   then Idle; the rest does not resume, so an active owner keeps XUNA tired.
5. **Sleep needs an explicit wake.** With energy costs enabled, an active
   owner drove XUNA into Sleeping 86% of the time because nothing woke it.

The production firmware uses the same `Needs`/`ActivityFsm`, so the board on
`aa2dbca` behaves the same after about 49 minutes; earlier board checks lasted
only minutes.

## Lab knobs added (defaults = shipped behaviour)

| Knob | Where | Default |
|---|---|---|
| `restExit`, `restThreshold`, `playMin`, `sleepThreshold` | `ActivityThresholds` | 24576 / 16384 / 32768 / 8192 |
| `wakeEnergy`: leave Sleeping when energy reaches it | `ActivityThresholds` | 0 (explicit wake only) |
| `resumeInterruptedRest` | `ActivityThresholds` | false |
| `energyRecoveryPerMinute` | `LifeTuning` | 2048 |
| `actionCostPercent`: share of registry cost spent | `LifeTuning` | 0 |
| `stimulationPerInteraction` | `LifeTuning` | 0 |

`LifeCore` takes `LifeTuning` and `ActivityThresholds`; `Needs` gained bounded
`spend()`/`stimulate()`. Two unit tests check the knobs and that the defaults
are unchanged. Native 120/120 PASS. ESP32 build: RAM 46,224 B (+16), Flash
1,343,453 B (+116) for the inactive code.

## Life-feel targets (Proposed, need owner approval)

| Owner | Targets |
|---|---|
| idle | resting ≤ 20%; energy < 37.5% ≤ 30% of the time; calm ≥ 70% |
| casual | resting + sleeping 10–30%; excited + curious 10–40%; overwhelmed ≤ 5%; low energy ≤ 35% |
| active | resting + sleeping 20–45%; overwhelmed ≤ 15%; ≥ 80% of requests accepted; sleeping ≤ 30% |

## Sweep result

288 configurations were checked against the 11 targets. No single fix passes,
and the first grid of 144 configurations had none at 11/11. A refined grid had
20 configurations passing all 11. Recommended candidate (centre of the passing
region):

| Knob | Shipped | **Candidate** |
|---|---|---|
| restExit | 24576 (37.5%) | **41943 (64%)** |
| energyRecoveryPerMinute | 2048 | **6144** |
| actionCostPercent | 0 | **10** |
| stimulationPerInteraction | 0 | **4096** |
| wakeEnergy | 0 | **52428 (80%)** |
| resumeInterruptedRest | false | **true** |

| Candidate, 8 h | idle | casual | active |
|---|---|---|---|
| Resting + sleeping | 13% | 14% | 27% |
| Energy < 37.5% | 29.7% | 31.1% | — |
| Calm / lively (excited + curious) / overwhelmed | 95.8% calm | 16% lively, 0% overwhelmed | 99.8% lively, 0% overwhelmed |
| Requests accepted | — | 100% | 100% |

## Limits and open points

- Synthetic owner schedules; real use is burstier.
- Under heavy play the mood is lively almost all the time. No target limits
  that yet; it may need its own target.
- Sleeping is never reached with the candidate (energy stays above 12.5%). A
  day/night sleep rhythm needs trusted time (S10) and is a separate design.
- `actionCostPercent` 10 means happy spends about 0.6% energy. Lowering the
  registry costs directly would be clearer if adopted.
- The knobs exist in production code but are inactive. Turning them on for
  the board is an owner decision, followed by a board check.

## Enabled for the board trial (2026-10-15)

- `xuna/life/LifeFeel.h`: `lifeFeelTuning()`, `lifeFeelThresholds()` and
  `applyAcceptedAction()` (shared by `LifeCore` and the production BLE/button
  path).
- Production: `main.cpp` builds `ActivityFsm`/`Needs` with these values;
  `BleManager::requestAction` applies `applyAcceptedAction` on accepted
  actions. `LifeCore` defaults to the same values.
- New test: an accepted happy reaction spends 409 energy and adds 4096
  stimulation. Native 121/121 PASS; ESP32 build SUCCESS (RAM 46,224 B, Flash
  1,343,589 B). Not uploaded yet: the board was not connected.

Board instrumentation (added 2026-10-15, firmware `5d872d3`): the LCD shows only the
pet sprite, resting draws the idle sprite, and the board does not compute mood.
`main.cpp` now prints `needs t_s=… activity=… energy=… stim=…` every 5 s and
`activity_change from=… t_s=… activity=…` on each activity change (log only;
no storage/BLE change; RAM unchanged, Flash +576 B). Capture with
`firmware/tools/serial_capture.py` to a file outside Git and summarise with
`firmware/sim/board_needs_report.py` (first rest, awake/rest periods, energy
range, time shares). Mood targets cannot be checked on the board until S18.

Owner board check (1–2 hours after upload): the first rest comes after about
48 minutes; then XUNA is awake about 25 minutes and rests about 4 minutes
(energy between 25% and 64% instead of 25–38%). It should stay responsive
during play, return to rest after being interrupted while tired, and never
stay asleep without waking by itself.

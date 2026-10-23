# Routine learning: XUNA learns when the owner comes and waits for them

Status: implemented in firmware (host tests and Life Lab, 2026-10-20); not yet
on the board; nothing in the app yet. Part C of the owner's 2026-10-19
decision ([reaction learning](reaction-learning-2026-10-19.md)); design from
plan §9.7 (`HabitPredictor`), with the deviations listed below.

## Model (`xuna/learning/HabitPredictor.h`)

| Item | Value |
| --- | --- |
| Slots | 48 = 24 local hours × {weekday, weekend}; counts Q8.8, plus the mean arrival minute within each hour (u8, EMA ¼) |
| Observation | one per interaction session: owner input after ≥ 30 min without any [P]; only with trusted time (Synced or Approximate). A time sync alone is not presence |
| Decay | × 0.95 per local day [P] |
| Prediction | P(slot) = (h + 0.5) / Σ(h + 0.5) for scoring; P(hour \| day type) for behaviour |
| Prequential gate | Brier gain over uniform, EMA ⅛, must exceed 0.02 [P], and evidence ≥ 10 sessions [P] |
| Behaviour | the run of hours with P(hour \| day type) ≥ 4× uniform [P] gives an arrival estimate (count-weighted hour + mean minute); about 20 min [P] before it, an idle XUNA shows curious once per run and day, through `ActionGate` (a sleeping or tired XUNA is not woken). Never reminders or guilt |
| Storage | snapshot section 7 Habit v1 (152 B, optional, only when non-empty), saved by the lazy checkpoint; older readers skip it |
| Privacy | `forget` clears it with the other learned state |

Deviations from plan §9.7: the mean-minute byte and the within-day-type
probability were added after Life Lab showed hour bins anticipated an hour
early and never learned weekends; scoring uses Brier only (no log-loss in
integer code yet). The "proactive behaviour enabled" switch has no UI; the
owner approval of 2026-10-19 stands in for it.

## Evidence (`learnsRoutine`, `test_habit`, `sim/scenarios.cpp`)

- Routine owner (weekdays 19:00 ± 20 min, weekends 09:00 ± 20 min, 28 days,
  seeds 21–25): gate open in every run, anticipation in the last week on 4–6 of
  7 days (the last simulated day ends before its arrival), **0 false alarms**;
  weekday anticipation ~18:27–18:51 for arrivals 18:40–19:20.
- Random owner (uniform 08:00–23:00): gate never opens, **0 anticipations**.
- After 8 weeks weekends are anticipated on most days.
- Survives a reboot; no learning without trusted time; forget clears it.
- Runtime: 28 simulated days in 0.3 s.

## Not done

- The app does not show the routine yet (needs a BLE read; e.g. "XUNA để ý
  bạn hay ghé khoảng 19 giờ ngày thường").
- Board trial for lead time, thresholds and how visible "curious" is.
- Drift test from plan §9.7 (routine shift at day 30) is not yet a test.

# Reaction learning: XUNA learns from what the owner does on the device

Status: **owner-approved 2026-10-19**, implemented in firmware + mobile (host
tests and Life Lab only; not yet on the board or a phone).

## Why

The owner found app ratings meaningless and tedious: suggest in the app, wait,
then rate "thích / không thích" within 120 s. XUNA only stored the answer; it
did not learn from living with the owner. Decision (owner, 2026-10-19):

1. **D6 revised:** the owner's natural reaction on XUNA right after it acts
   teaches it. Silence teaches nothing ("im lặng không phải là ghét").
2. **App ratings removed** from the UI. Confirmed chat statements ("mình
   thích khi bạn tò mò") still teach (conversation input, unchanged).
3. **Routine learning** (XUNA learns when the owner is usually around and
   anticipates it) is approved in principle; it needs a new snapshot section
   and gets its own design (part C, next).

## Design freeze (values marked [P] are provisional until board trials)

| Item | Value |
| --- | --- |
| Reaction window | 10 s after XUNA shows a decision [P] (`ProductLearner::kReactionWindowMs`) |
| Pet | GPIO0 (top) press inside the window → positive |
| Shoo | GPIO14 (bottom) press inside the window → negative, then the usual idle |
| Weight | w_r = 0.3 of an explicit rating [P] (`LearnerV3Config::reactionWeightQ16` 19661) |
| Outside the window | GPIO0 = XUNA chooses a greeting (D5 greeting learning, now on); GPIO14 = idle |
| Spontaneous choice | after 60 s idle the offline routine is a learner decision in the quiet context (UCB, can explore), not a replay of the learned action |
| Episode | source 3 = reaction; greeting episodes use context 2 |
| Snapshot | episodes section v2 written only when a source-3 episode exists; older firmware skips the optional section instead of failing |
| BLE | unchanged; opcode 3 ratings still accepted for older apps; local decisions are never app-rateable |
| Commit | reactions are commit-first like ratings; an Egg device (no identity) does not learn |

## Evidence (Life Lab, `firmware/sim/scenarios.cpp`, `test_life_lab_scenarios`)

- `learnsFromReactions`: the owner likes one action and dislikes another and
  reacts to only part of XUNA's choices. The learned quiet choice follows the
  owner in both directions. Sweep over 20 seeds × 2 preferences: 40/40 learned
  with ~13 reactions in one day (1 % of choices), and at 5 % / 10 % over 1–7
  days.
- D (no feedback 100 days), E (10 reboots + 5 power cuts) and 100-day
  stability still pass; stability now includes 53 reactions with the feedback
  count equal to acks + reactions at every step.
- Found while testing: a source-3 episode made the stored snapshot "Corrupt"
  for the old decoder, so the episodes section is versioned (above).
- Adapter tests: pet/shoo weights and source, window edge, spontaneous choice.
- Golden vectors end with device presses (pet, greeting, shoo); mobile decodes
  reaction (3) and greeting (2) episodes.

## Not done / next

- Board trial: window length, weight and how often XUNA acts on its own.
- App "poke" (touching XUNA on Home) is still a direct request, not a pet;
  making it a reaction needs a protocol addition.
- Part C, routine learning: design and snapshot section.

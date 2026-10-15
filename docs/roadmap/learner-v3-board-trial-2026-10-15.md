# Learner v3 board trial (2026-10-15)

Status: owner-decided shortcut ahead of the planned S12a → S18 order. Built and
host-tested; **not uploaded yet** (board not connected).

## What changed in the firmware

| Path | Before | Now |
|---|---|---|
| BLE opcode 2 (choose) | v1 `LifeEngine::choose` (greedy, never explores) | v3 UCB via `BoardLearner::choose`; the shown action is still validated by `ActionGate` |
| BLE opcode 3 (feedback) | v1 copy → `LifeStorage::save` → apply | Same commit-first order through `ILifeCommit` (`StorageCommit`); on success v1 **and** v3 are updated; failure → result 7, decision kept for retry |
| BLE opcode 4 (forget) | Clear v1 | Clear v1, then reset v3 |
| Quiet routine | v1 preference | v3 preferred quiet action (`LocalBehavior::choosePreferred`) |
| Life status bytes 16/17 (preference) | v1 `choose(0/1)` | v3 greedy for quiet/play |
| Boot | Restore v1 | Restore v1, then rebuild v3 from it (capped migration, E10-C); Serial prints `learner=v3-ucb (board trial)` |

Unchanged: BLE byte layout, the 96-byte snapshot format and NVS keys, GPIO
button behaviour (GPIO0 still requests happy; the greeting context needs
LifeSnapshot v2), mobile app.

## Known limits

- Recency is lost across reboots: v3 is rebuilt from v1's undiscounted counts,
  capped to 1/(1 − γ). Within one power-on session v3 adapts with γ 0.90;
  after a reboot an old long-standing preference can partly return.
- Shape 2 × 5 × 2 (quiet/play × idle/happy), day part unknown. Curious and
  the GPIO0 greeting context wait for LifeSnapshot v2 (S12a/D2).

## Validation

- `test/test_board_learner` (6 tests): restore from v1, commit-first apply to
  v1 and v3, failed commit changes nothing and a retry works, unaccepted
  choice/bad source rejected, forget resets, and v3 follows a preference change
  within ≤ 20 ratings while v1 on the same counts does not.
- Native 127/127 PASS. ESP32 build SUCCESS: RAM 48,328 B (+2,104), Flash
  1,347,081 B (+3,492). Includes the life-feel configuration.

## Board check (after upload)

1. Serial shows `learner=v3-ucb (board trial)` and the preferred quiet/play
   actions.
2. In the app: choose in play, rate, repeat. When you change your mind (e.g.
   reject happy several times), XUNA should switch within about ten ratings.
3. Reboot and confirm earlier learning is still there (v1 counts), and note
   whether an old preference returns.

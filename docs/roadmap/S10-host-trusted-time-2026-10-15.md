# S10 host part — trusted time and day-part learning (2026-10-15)

Status: **host-only core part of S10 done**. The wire protocol (opcode 5
TimeSync, opcode 7 Hatch, capability bits, Egg exposure), `CommandHandler`,
firmware diagnostics, mobile and the owner board/phone check are **not done**.

## What changed

- `ClockModel` moved from `LifeCoreSession` into `LifeCore` (S18 direction:
  one composed step). `LifeCore::sync(utcMs, tzOffsetMin, source, now)` is
  the seam a future opcode 5 handler calls; `LifeCoreSession::sync` forwards.
  ERROR_SAFE ignores syncs.
- Learner day parts: decisions use `learnDayPart(clock.dayPart())`, plan §9.2
  order 0 unknown, 1 morning 05–11, 2 afternoon 11–17, 3 evening 17–22,
  4 night 22–05 (boundaries [P]). With unknown time the coarse cell (0)
  decides and learns, as before. With trusted time (Synced or Approximate)
  a rating updates the coarse cell and the day-part cell (plan §9.3); the
  fine cell is used once it has nEff ≥ m (1, E10-B), else the coarse prior.
  Output gains `decisionDayPart`; `preferred(interaction, dayPart)`.
- LifeSnapshot v2 section **Clock** (id 2, optional, 6 B): `lastTrustedUtcMinute`
  u32 (2020-epoch minutes) and `tzOffsetMin` i16. Written only after an
  accepted sync; validated (minute ≠ 0, |tz| ≤ 840). The watermark is set in
  the RAM snapshot on sync and reaches storage with the next commit (lazy
  class, §7.6). At boot `ClockModel::onBoot` receives it: time stays unknown
  until the next sync, and a phone clock more than 5 min behind it is
  rejected. Forget keeps it (rollback protection, not learning).
- 32 → 64-bit monotonic extension in `LifeCore`: `millis()` wraps after about
  49.7 days, and `ClockModel` would otherwise reject every later sync.
- Trace runner: `sync <unix seconds> <tz minutes>` is supported; CSV gains
  `sync_accepted,sync_rejected`. New trace `c8_dayparts.trace`.

## Validation

- New tests: codec Clock roundtrip/validation; LifeCore coarse-only before
  sync, morning cell after sync, **morning and evening greeting preferences
  diverge** (happy in the morning, curious in the evening, same owner),
  rollback rejected, `millis()` wraparound; snapshot lab watermark survives
  reboot, time unknown after reboot, rollback rejected, forward gap flagged.
- Native **159/159 PASS**. ESP32 build unchanged (RAM 48,328 B, Flash
  1,347,657 B); purity PASS; Xtensa g++ 8.4.0 C++11 `-Werror` smoke PASS.
- `lifecore_lab`: c1–c6 identical to the previous run (CSV gains two zero
  columns); c7 now counts `sync 0` as rejected (unsupported 2); c8: sync
  accepted 2, rejected 1, feedback 2, generation 2, clock Synced.
- `life_timeline` idle/casual/active 8 h: byte-identical to HEAD.

## Snapshot sizes

Product snapshot: 536 B; + Needs 8 B; + Clock 10 B → at most 554 B of 1,536.

## Remaining S10 work

Protocol design freeze (opcode 5/7, capability mask `0x005f`, Egg exposure),
`BleProtocol`/`CommandHandler`, hatch `bornAt` rules with identity (S06),
firmware Serial clock diagnostics, mobile TimeSync after connect and every
6 h, owner board + phone check. Day boundaries, 24 h validity and 5 min
tolerance stay Proposed.

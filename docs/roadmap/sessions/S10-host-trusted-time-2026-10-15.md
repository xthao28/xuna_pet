# S10 host part — trusted time and day-part learning (2026-10-15)

Status: **host core, protocol design freeze and pure cross-platform codec slice
done**. `CommandHandler`, firmware/mobile transport wiring, diagnostics and the
owner board/phone check are **not done**.

## Pure codec slice — 2026-10-16

- Firmware `BleProtocol` parses feature-gated opcode 5/7 frames without enabling
  them in the production adapter. `BleCommand` carries UTC seconds and timezone;
  `CommandCache` now deduplicates the approved 16-byte TimeSync frame while
  retaining the legacy rejection of other oversized frames.
- Added the pure C++11 `LifecycleCodec` for the approved 8-byte projection.
  Golden cases live with the v1 characterization suite so the existing deployed
  parser remains covered alongside the additive frames.
- Mobile adds explicit opcode/capability constants, TimeSync/Hatch command
  models, strict encode/decode validation and the read-only `LifecycleModel`.
  No repository, data source, BLE characteristic, controller or UI was wired.
- Validation: firmware native 182/182 PASS; ESP32 build and core purity PASS
  (RAM 49,040 B, Flash 1,347,757 B). Flutter 3.32.8 analyze clean and 45/45
  tests PASS. `git diff --check` passed in root and both child repositories.
- No board/phone operation, upload, persistence change, capability advertisement,
  commit or push occurred. Existing S25/S26 worktree changes were preserved.

## Owner-approved protocol freeze — 2026-10-16

The owner selected the following contracts option by option. Approval does not
mean that the wire path is implemented or validated.

### TimeSync

- Opcode 5, exactly 16 bytes: `[version=1, opcode=5, requestId u32 LE,
  source=1 phone, reserved=0, utcSeconds u32 LE, tzOffsetMin i16 LE,
  reserved u16=0]`.
- Reject non-zero reserved fields, unsupported sources, timezone offsets outside
  `[-840,+840]`, implausible timestamps and UTC rollback beyond 5 minutes.
- A valid sync is `Synced` for 24 hours, then `Approximate`. After reboot the
  clock is `Unknown` until another sync; the persisted watermark still prevents
  rollback. Timezone changes do not count as UTC rollback.
- Mobile sends TimeSync after connect when capability bit 4 is present and every
  6 hours while connected.
- Accepted sync updates RAM immediately; the watermark uses the existing lazy
  snapshot class rather than forcing a Flash write for every sync.

### Hatch and identity durability

- Opcode 7, exactly 8 bytes, `arg=0`, all reserved fields zero. It is valid only
  in `Egg`. A same-request retry returns the cached result; a fresh request after
  hatch returns result 4 (`invalid_argument`).
- App hatch sends TimeSync first. If sync fails, the app does not auto-hatch: it
  explains that exact `bornAt` will remain unknown and requires a separate owner
  confirmation to continue or offers retry.
- Direct device hatch is a 3-second GPIO14 hold while in Egg, with visible hold
  progress and cancellation on early release. GPIO0/BOOT is not used.
- Hatch identity and a same-boot `bornAt` backfill are commit-first. The device
  reports success and adopts the authoritative record only after persistence.
  Failure returns result 7 (`not_ready`). Later-boot sync never backfills birth.

### Lifecycle projection and capabilities

- Add a read-only additive Lifecycle V1 characteristic. Its fixed 8-byte layout
  is: `version`, `size`, `identityState`, `growthStage`, `clockQuality`,
  `bornAtQuality`, `origin`, `flags`.
- Initial values: identity `egg=0, ready=1, safe=2`; stage `egg=0, newborn=1`;
  clock `unknown=0, approximate=1, synced=2`; birth quality `unknown=0,
  synced=2`; origin `none=0, device=1, app=2, migrated=3`; flags bit 0 means
  `bornAt` is present. Unknown enum values must fall back safely in the app.
- Do not expose `petId` or the birth timestamp in this characteristic. Old apps
  ignore the additive characteristic instead of receiving a new Status enum.
- Capability mapping remains one bit per command: bits 0–3 for opcodes 1–4,
  bit 4 TimeSync, bit 5 StatedPreference and bit 6 Hatch. A build advertises a
  bit only when its production path works. Therefore S10 without opcode 6 uses
  `0x005f`; after S18/S26 production wiring it may become `0x007f`.

### Day parts and errors

- Starting local-time ranges: morning 05:00–10:59, afternoon 11:00–16:59,
  evening 17:00–21:59, night 22:00–04:59. Unknown time continues using the
  coarse learning cell. These defaults may be retuned only with later evidence.
- Preserve result codes 0–7: malformed length returns 2; invalid semantic input,
  rollback or wrong lifecycle state returns 4; request-ID payload conflict
  returns 6; unavailable persistence/core returns 7. Detailed rejection reasons
  belong in typed events/diagnostics rather than new wire result values.

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

Implement `CommandHandler`, identity commit integration, Lifecycle BLE read
projection, firmware Serial clock diagnostics, mobile sync/hatch transport/UX,
and the owner board + phone check. Production wiring still
depends on the existing S09/S13/S18 gates. No board was detected during the
2026-10-16 attempt, so no backup, build, upload or hardware validation occurred.

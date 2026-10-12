# S05-fix-01 — Align compact UTC-minute epoch

Date: 2026-10-12. Status: **Done — host tests and target compile/build verified**.

## Problem and change

S05 ClockModel::utcMinute and lastTrustedUtcMinute used minutes since 1970, while plan §7.1/Event used minutes since 2020-01-01 UTC. Mixing them would shift event timestamps and rollback watermarks. Neither new model is wired or persisted in the deployed MVP; there is no deployed data migration or BLE protocol change.

ClockModel now defines `kEpochUtcMs = 1577836800000`. onSync/utcMs remain Unix milliseconds; compact output and persisted watermark use 2020 minutes. Boot watermark reconstruction adds that epoch only for nonzero values; zero still means no trusted evidence. Sync rejects dates before minute 1 (the first minute including epoch zero is reserved unknown). Upper valid timestamp is the final millisecond of u32 minute UINT32_MAX; subsequent projected/supplied time returns unknown/rejection without overflow. Day-part calculation continues from Unix time plus offset, so timezone semantics do not change. Tolerance/degradation values remain Proposed tuning defaults.

## Validation scope

Tests were updated/added first and failed against the previous implementation (compact minute and lower-bound rejection). New clock_epoch_bounds covers before epoch, reserved minute zero, first valid minute and exact rollover, imported watermark, last u32 minute and overflow. Existing clock tests retain sync/quality/rollback/gap/reboot/timezone/day-part semantics, with valid modern UTC inputs and corrected compact expectations.

Commands: `pio test -d firmware -e native`, `-e native_asan`, target `pio run -d firmware -e xuna_t_display_s3`, and pinned Xtensa compile-only smoke including all S05 headers. PASS: native 19/19, ASan/UBSan 19/19, pinned Xtensa compile smoke and ESP32 build/purity (47,504 B RAM / 964,333 B image unchanged). Whitespace/link checks PASS. No firmware wiring, upload, serial/NVS operation, app edit or temperature measurement.

## Handoff

S07 time-epoch integration finding resolved. Next S06 pure identity/hatch/migration logic, preserving pending physical S01/Android gate for board/NVS steps; do not mark the full board acceptance validated from host tests. Existing root/firmware/mobile edits retained; no commit/push or gitlink update.

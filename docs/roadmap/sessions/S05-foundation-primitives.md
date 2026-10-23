# S05 — Fixed point, seeded RNG and clock model

Date: 2026-10-12. Status: **Done — pure logic tested on host, target compile/build verified**. Scope: pure C++11 library additions; no firmware wiring/upload or app work.

## Frozen implementation contract

- `xuna/base/Fixed.h`: Q0.16 uint16 raw/65536 (maximum below one) and Q16.16 uint32 raw/65536. Integer/ratio conversion, multiply/divide use uint64 intermediates, round half up and saturate. Add/subtract saturate. Divide-by-zero policy is bounded: 0/0 returns zero; positive/0 returns maximum. Clamp requires ordered bounds. These are engineering defaults, not new product decisions.
- `xuna/base/Random.h`: per-instance IRandom/Pcg32, explicit seed/stream, PCG XSH-RR 64-bit state and rejection-sampled `below(n)`. Zero bound returns zero without consuming randomness; this sentinel is not a valid random choice. Nonzero bounds use rejection without modulo bias. Rejection has no strict worst-case iteration cap; keep behavioral bounds small, and measure step latency before wiring. RNG is not security/identity entropy.
- `xuna/time/ClockModel.h`: explicit 64-bit monotonic inputs, UTC millisecond anchor, minute watermark and Phone/Ntp source. Boot clears anchor/timezone/source but may import persisted watermark; time remains unknown until sync. Watermark alone never reconstructs offline duration.
- Sync validates positive representable u32 minute time (minute zero reserved unknown), offset -840..840, known source and monotonic ordering. Rollback is compared with the larger of current projected time and persisted watermark. More than 5 minutes is rejected without mutation; smaller rollback is tolerated by clamping the anchor to prevent backward time. Forward differences over 5 minutes set a gap flag; first sync without previous evidence does not. These details are frozen engineering behavior for this slice, not a new time wire protocol.
- 24 h validity and 5 min tolerance remain **Proposed tuning defaults** from plan §8.3; exact 24 h is Synced, later Approximate. Approximate time still supports day parts. Overflow/reversed monotonic input returns unknown. Day boundaries: morning 05–11, afternoon 11–17, evening 17–22, night 22–05. Timezone is fixed minute offset; DST policies remain outside this slice.
- Last trusted minute advances on accepted sync only; persistence adapter integration is future work. No actual NTP/BLE sync, flash write or active-lifetime/growth mutation is introduced here.

## Evidence

Tests were added first and failed for missing Fixed.h; implementation then passed. Four new test cases cover fixed-point limits/rounding/zero division, PCG official vectors/seed repeatability/streams/forced rejection and coarse distribution, reboot/sync/degradation/rollback/gap/invalid inputs, all day-part boundaries/timezone and large monotonic values.

Reference vectors: [official pcg32-demo output](https://www.pcg-random.org/using-pcg-c-basic.html), seed 42 / stream 54. Source audit: [pcg-c-basic](https://github.com/imneme/pcg-c-basic/tree/bc39cd76ac3d541e618606bcc6e1e5ba5e5e6aa3), pcg_basic.c/LICENSE.txt, Apache-2.0. Adaptation notice in Random.h; full license retained in firmware/lib/xuna_core/licenses/PCG-Apache-2.0.txt. This source/license is separate from the ePet/Xiaozhi references.

- `pio test -d firmware -e native`: PASS, 12/12 cases (four suites), including all existing v1 regressions.
- `pio test -d firmware -e native_asan`: PASS, 12/12; no sanitizer diagnostics.
- Direct pinned `xtensa-esp32s3-elf-g++ -std=c++11 -Wall -Wextra -Werror` compile of `/tmp/xuna_s05_target_smoke.cpp`: PASS. It includes and instantiates all new headers without changing firmware wiring. This is compile evidence, not host-target runtime parity.
- ESP32 build and purity guard: PASS at unchanged 47,504 B RAM / 964,333 B image. New primitives are not linked into current application, so no application behavior or resource delta is expected.

## Handoff

Prefer S07 events/registry/queue next while Android S01 acceptance is deferred. S06 pure identity logic is eligible after S05, but its board/NVS steps require S01; do not report S06 complete from pure tests alone. Board warmth was owner-reported under USB power, with no temperature measurement or hotspot identification; no thermal validation or diagnosis is claimed. No board operations in S05. Previous edits preserved; no commit/push or gitlink update.

## Follow-up — 2026-10-12

[S05-fix-01](S05-fix-01-time-epoch.md) resolves the UTC-minute epoch mismatch. Compact ClockModel/event minutes now share the 2020 epoch; millisecond UTC remains Unix. Earlier findings/results above retain their historical context.

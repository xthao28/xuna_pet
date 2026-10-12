# S04 — Portable firmware core and native tests

Date: 2026-10-12. Status: **Done — host tests and ESP32 build verified**. Source extraction only; no board upload/physical acceptance.

## Implementation

Moved five pure headers to `firmware/lib/xuna_core/include/xuna/`: DebouncedButton, AnimationManager, LifeEngine, BleProtocol, LocalBehavior. Production logic matches the former headers exactly after include-path substitution. Added framework-independent library metadata. Split AppConfig into core timing constants (`xuna/CoreConfig.h`) and `firmware/src/BoardConfig.h` (unchanged pins/version/diagnostics); hardware adapters include board config explicitly.

Converted all original core/life and S03 assertions to Unity `TEST_ASSERT_TRUE` checks. Three suites under `firmware/test/test_core/`, `test_life/`, `test_v1_characterization/` run eight named test cases, retaining loop/table coverage. Frozen fixture bytes are unchanged.

Added PlatformIO native/native_asan environments using C++11 with warnings as errors. Default test_build_src stays disabled, excluding Arduino adapter sources from native tests. PlatformIO installed native 1.2.1 and Unity 2.6.1 for host testing; firmware platform/framework/display versions and memory/partition configuration remain pinned. Added pre-build purity hook to all environments; it rejects hardware-dependent includes in core source/header files. README commands use the new suite layout.

## Verification

- `~/.platformio/penv/bin/pio test -d firmware -e native`: PASS, 8/8 tests.
- Same command with `-e native_asan`: PASS, 8/8 tests; no sanitizer diagnostics.
- `pio run -d firmware -e xuna_t_display_s3`: PASS, 47,504 B static RAM / 964,333 B image; delta from S00 is zero. Existing upstream warnings persist (parallel DMA, touch configuration, UART return).
- Negative purity experiment: temporarily append Arduino.h to CoreConfig, require failure attributable to purity check in native, native_asan and ESP32 environments, then restore the exact header. PASS: all three environments rejected the include via the purity hook; original header restored and clean ESP32 build rechecked.
- Exact text comparison of all five relocated production headers against firmware HEAD, allowing only include substitutions: PASS. Root/firmware whitespace checks: PASS.

## Boundaries and next step

No upload, NVS operation, app edit, commit/push or parent gitlink change. Board continues running the accepted MVP, not this refactor. Existing S03 and root edits were preserved. Next S05 (fixed point, seeded RNG and clock model) or S07 within dependencies; do not start them within S04. S01 physical acceptance is deferred until Android work and remains a board-upload gate. No host test result implies physical BLE compatibility.

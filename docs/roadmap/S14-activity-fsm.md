# S14 — ActivityFsm

Status: implementation added; native validation pending toolchain availability.

Scope: a pure C++11 activity FSM for M04.5a, with a const legal-transition table, explicit rejection reasons, energy/stage/busy-related guards, monotonic timeout handling and wrap-safe elapsed-time checks.

Files:

- `firmware/lib/xuna_core/include/xuna/life/ActivityFsm.h`
- `firmware/test/test_activity_fsm/test_main.cpp`

The test suite covers every source/target pair, guard outcomes, `ERROR_SAFE` reboot-only exit, explicit wake, energy-gated resting/play transitions and a uint32 monotonic wrap case.

The current Windows environment has no PlatformIO or C++ compiler executable, so native/sanitizer/ESP32 validation remains pending. The implementation is not marked Done until those commands pass.
# LifeCore session and replay bridge

Status: Implemented as host/core preparation; no firmware-loop or board wiring.

## Added behavior

- `LifeCoreSession` owns a bounded FIFO of `LifeCoreEvent` values and exposes
  overflow explicitly.
- `ClockModel` is kept at the adapter boundary: unknown time stays unknown until
  an accepted trusted sync, and the session exposes quality, UTC minute and
  day-part projections.
- `LifeCoreTraceRunner` replays the supported pre-S19a DSL subset through the
  same session path used by future adapters. Choice/feedback/button/cmd are
  translated; reboot/powercut now use the snapshot lab, while sync/day/expect
  remain counted as unsupported rather than guessed.

## Validation boundary

The new Unity suites cover FIFO order/overflow, time quality, deterministic
choice/feedback and snapshot-backed reboot/power-cut recovery. Native, sanitizer
and ESP32 builds remain pending until a C++/PlatformIO toolchain is available.
The snapshot lab is an experiment only; production persistence remains an
S13/S19a gate.

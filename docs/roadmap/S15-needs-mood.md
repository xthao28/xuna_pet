# S15 — Needs/Mood

Status: implementation added; native validation pending toolchain availability.

Files:

- `firmware/lib/xuna_core/include/xuna/life/Needs.h`
- `firmware/test/test_needs_mood/test_main.cpp`

The pure model has two bounded Q0.16 needs (`energy`, `stimulation`). Decay is linear over monotonic active time, with carried remainders so one large catch-up and equivalent smaller updates match. `reset()` establishes a new boot epoch and therefore does not invent offline elapsed time.

Mood is derived, transient state. Arousal and valence are clamped axes; labels use separate enter/exit thresholds to avoid flicker. All numerical values are placeholders pending Life Lab tuning.

The current Windows environment has no PlatformIO or C++ compiler executable, so native/sanitizer/ESP32 validation remains pending.

Update 2026-10-14 (Mac): native and ASan/UBSan suites PASS after correcting the partition test. Energy now recovers while the caller reports Resting/Sleeping (`energyRecoveryPerMinute`, Proposed); see [review fixes](M04-review-fixes-2026-10-14.md).
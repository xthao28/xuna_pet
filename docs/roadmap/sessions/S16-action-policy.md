# S16 — Action policy and visual boundary

Status: implementation added; native validation pending toolchain availability.

Files:

- `firmware/lib/xuna_core/include/xuna/life/ActionRegistry.h`
- `firmware/lib/xuna_core/include/xuna/life/RequestValidator.h`
- `firmware/lib/xuna_core/include/xuna/visual/VisualIntent.h`
- `firmware/lib/xuna_core/include/xuna/life/BehaviorSelector.h`
- `firmware/test/test_action_policy/test_main.cpp`

The action registry contains the four public M04 actions and stable IDs. The validator denies unknown, malformed, out-of-stage, busy, cooldown and energy-insufficient requests. The expression map resolves stage-limited intents through bounded fallbacks, and the selector is deterministic for a fixed PCG32 seed while filtering disallowed/cooldown/energy-ineligible candidates.

Numerical weights, cooldowns and energy costs are M04 placeholders until Life Lab tuning. The current Windows environment has no PlatformIO or C++ compiler executable, so native/sanitizer/ESP32 validation remains pending.
# LifeCore step composition — host slice

Status: Implemented as a pure C++ preparation slice; not yet wired to
`main.cpp`, BLE, persistence or the board.

## Contract

`LifeCore::step` accepts a bounded array of core events and returns activity,
needs, mood, visual intent, learning decision state and a persistence request.
The v1 `LifeEngine` remains authoritative. A v2 `PreferenceLearnerV2` observes
the same choices through `LearningBridge`; accepted feedback updates both, but
only the v1 state requests the existing persistence path.

The current event vocabulary covers action requests, contextual choices and
explicit feedback. Transport adapters are intentionally outside this header.

## Validation

- Added a dedicated Unity suite for startup/tick, v1/v2 choice, one-shot
  feedback, invalid feedback and action-to-visual mapping.
- Whitespace checks are required before commit.
- Native, sanitizer and ESP32 builds were not run because this Windows session
  has no C++ compiler or PlatformIO executable.

## Remaining gates

S10 trusted time, S13 persistence v2, full event envelope and S18 integration
into the firmware loop are still required before this slice can replace the
current adapters or promote v2 from shadow to production policy.

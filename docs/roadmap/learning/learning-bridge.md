# Learning bridge — v1 state to v2 candidate

Status: Implemented as a host/core preparation slice; not production wiring.

## Scope

`xuna::LearningBridge` accepts an existing `LifeEngine` v1 state, a bounded
`PreferenceLearnerV2` candidate and an injected deterministic RNG. It records
the v1 and v2 decisions together and applies feedback to v2 before v1. Invalid
or duplicate v2 feedback therefore cannot train the v1 state a second time.

The bridge does not change the 96-byte snapshot, BLE v1 payloads, mobile code,
or board behavior. It is the seam for the future `LifeCore::step` composition.

## Validation

- Added a dedicated native Unity test suite for existing-state composition,
  duplicate feedback and invalid source/decision rejection.
- Whitespace checks pass.
- Native, sanitizer and ESP32 builds were not run: this Windows session has no
  C++/PlatformIO toolchain.

## Remaining gate

This slice does not promote learner v2 to the production policy. S18
`LifeCore::step`, persistence/migration and the S19a Life Lab remain required
before official learner selection or a BLE/mobile contract change.

# S17 — FSM and visual boundary wiring

Date: 2026-10-14 (Asia/Ho_Chi_Minh)

## Scope

S17 connects the M04 action policy to the firmware loop without adding a new renderer or changing the BLE packet schema. BLE action requests, GPIO actions and quiet behavior share the same validation and Activity FSM path.

## Implemented

- `BleManager` accepts an action only after `RequestValidator` checks action ID, activity legality, cooldown, energy and permission. Accepted actions update the FSM and `AnimationManager` through `VisualIntent`.
- Requests while Sleeping explicitly wake to Idle before applying a non-sleep action. Sleep from a reaction/play state routes through Idle when the existing FSM table requires it.
- The main loop owns `Needs::update` and `ActivityFsm::tick`; Idle/Resting/Sleeping/ErrorSafe transitions are reflected through the visual boundary.
- `AnimationManager::setIntent` resolves stage-incompatible or unknown intents to existing safe `PetState` values. Existing Happy/Curious timeout behavior is preserved.
- Added host-test coverage for the intent-to-renderer bridge.

## Fact / Assumption / Proposal / Experiment

- Fact: no direct BLE/local action path calls `AnimationManager::setState` after S17; the production loop uses `requestLocalAction` and BLE uses the same private request path.
- Assumption: the existing four `PetState` renderer states are the correct MVP surface until richer visual assets are approved.
- Proposal: tune energy costs, cooldowns and activity dwell values in Life Lab after native tests and physical BLE acceptance.
- Experiment: test Happy, Celebrate fallback, Greet fallback, Sleep, ErrorSafe and unknown intent mapping.

## Validation status

`git diff --check` and source/static checks were run. The Windows session has no `pio`, `c++`, `g++`, `clang++` or `cl`, so native, ASan/UBSan, Xtensa, ESP32 and board validation were not run. S17 remains **In progress — implementation added; validation pending**.

## Next

Run the pinned native and sanitizer suites, then the ESP32 build. After toolchain validation, exercise BLE malformed/duplicate/cooldown/busy cases and physical button wake/sleep behavior before marking S17 validated.

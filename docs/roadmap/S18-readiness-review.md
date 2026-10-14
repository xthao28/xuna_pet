# S18 readiness review

Date: 2026-10-14 (Asia/Ho_Chi_Minh).
Scope: read-only source audit of firmware `aa2dbca` against session-plan S18 and implementation-plan T1/§5.5. Documentation only; no production wiring, upload, phone operation or new runtime validation.

## Conclusion

S18 is **partially prepared, not complete**. Existing host composition is useful for experiments but cannot replace production adapters yet. S10 and S13 are not implemented end-to-end; S17 still needs its owner board check. Lack of an Android phone does not prevent host experiments, but does not waive these gates.

## Acceptance checklist

| Requirement | Source evidence | Remaining work |
|---|---|---|
| ClockModel | `LifeCoreSession.h` owns a clock and exposes sync/projections | Integrate time events and trusted-time protocol/identity flow (S10); clock is outside `LifeCore::step` |
| Identity | Independent `IdentityService.h` exists | Not composed into LifeCore/session; hatch and same-boot bornAt handling absent from production |
| EventQueue | Session uses an eight-entry `RingBuffer<LifeCoreEvent>` | Integrate canonical Event envelope/queue and its critical rejection accounting; this is not the existing `EventQueue<Event>` contract |
| CommandHandler | Production dispatch remains in `include/BleManager.h` | S08/S09 pure dispatch and transport separation absent; no CommandHandler implementation found |
| ActivityFsm, Needs/Mood, validation | Present in `LifeCore.h`, using shared `ActionGate.h` | Preserve all production command semantics before wiring |
| BehaviorSelector | Independent header exists | Not composed; core Choose uses the v1/v2 LearningBridge, production quiet routine still uses LocalBehavior |
| V1 authoritative learner | Core selects `baselineAction`; production uses LifeEngine | Shadow acceptance must not gate valid v1 feedback in production; current bridge accepts candidate feedback first |
| Thin main loop | `src/main.cpp` directly owns LifeEngine/FSM/Needs, BLE and storage | Replace business logic with one step, then commit/render/publish adapters, after prerequisites |
| PersistRequest including needs | Core returns only boolean `persistRequested` after feedback | Typed request, urgency/budget, snapshot/restore contract and needs section missing |
| Persistence v2 | `LifeStorage.h` still writes v1 `slot0/slot1`; lab uses LifeEngine codec | D2/storage experiment, S12a/b codec/migration, S13 `life0/life1`, read-only recovery and owner checks remain |
| Transcript, suites, target build | Earlier review record: native 87/87, sanitizer 87/87, ESP32 build PASS | These validate existing slices, not an integrated S18 transcript; no S18 owner connect/feedback/reboot smoke |

## Semantics to resolve before integration

- Production accepted local actions invalidate pending feedback (`BleManager::requestLocalAction`); LifeCore RequestAction currently leaves `pendingValid_` set. Its three-kind event vocabulary also lacks Forget and session/disconnect invalidation. Carry the source/session semantics into the core and add transcript parity coverage before replacement.
- LifeCore feedback mutates learner state before returning a boolean persistence request. Production BLE stages a LifeEngine candidate and commits storage before accepting it. Define failed-commit/ACK/retry behavior in the typed persistence contract so integration cannot report durable learning prematurely.
- `LifeCoreSnapshotLab::powerCutNextPersist` returns failure without a partial write. It is an in-memory failed-commit experiment, not S12b's every-byte torn-write sweep. Its boot starts clean when recovery fails; it does not validate S13 corrupt/TooNew identity safe mode.
- V2 remains an experimental shadow learner. Its validation/history limits must not become new rejection conditions for the accepted production v1 policy without separate evidence and approval.

## Next sequence

1. Without a phone: run the existing host trace/snapshot experiments and record deterministic output, supported verbs and limitations. This is preparation, not full S19a acceptance.
2. Complete prerequisite dispatch/transport work under S08/S09, retaining the observed v1 transcript and physical checks. Complete S10 trusted time/hatch and the storage decision/codec/migration/S13 gates in their authorized sessions.
3. With a board: finish S17 expression/sleep/wake/rejection and render timing checks. A supported real iPhone can serve the phone checks; Android is not intrinsically required.
4. Once prerequisites pass: implement full S18 composition, typed persistence outputs and thin loop; run transcript, native/sanitizer/ESP32 checks and owner connect/feedback/reboot smoke.

Evidence: [session plan](XUNA_SESSION_PLAN.md), [review fixes](M04-review-fixes-2026-10-14.md), [host LifeCore record](lifecore-step.md). No tests were rerun in this audit; prior results retain their original scope.

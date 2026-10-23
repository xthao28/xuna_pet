# S07 — In-memory events, registry and bounded queue

Date: 2026-10-12. Status: **Done — host tests and target compile/build verified**. No firmware wiring or persisted codec.

## Scope and contracts

Added EventTypes.h/Event.h/EventQueue.h and base/RingBuffer.h under xuna_core. Registry contains 25 named kinds from plan §7.3, categories and persistence classes, and a compile-time uniqueness assertion. Perception range 0x90–0x9F remains reserved/unrecognized. Future event declarations do not enable evolution/sensors/cloud. Provenance is distinct from input source; no device_voice source code is invented before its approved contract.

Event holds IDs/causation, active seconds/UTC minute, type/source/provenance/clock quality/confidence/privacy and eight zero-initialized payload bytes. It is an aligned in-memory record, not the S32 40-byte persisted codec; no CRC/serialization/Flash writes in this slice. UTC minute semantics follow plan §7.1: minutes since 2020-01-01, zero unknown.

RingBuffer uses fixed storage with FIFO wrap; full push rejects without overwriting existing items. Event IDs combine supplied bootCounter and sequence; exhaustion returns failure without wrap/reuse. Caller must commit unique bootCounter (S06); generator cannot guarantee uniqueness if caller reuses a boot counter.

Queue defaults to 32 events, no heap, single owner. Unknown type returns RejectedType. Full queues drop best-effort inputs with a saturating dropped counter; feedback application, fact confirm/supersede/delete, memory forgetting and state/skill/trait/safe-mode transitions return RejectedFull with a separate counter. Critical callers must not apply/ACK an operation when enqueue fails. FeedbackRejected is diagnostic, not a training update. drain invokes a synchronous consuming sink, stopping at its event-count budget even if the sink enqueues work. It is not thread/ISR safe, does not own persistence and gives no commit guarantee; later adapters handle those boundaries.

## Verification

Tests added first failed for missing EventQueue.h; then six event tests passed. Coverage: registry metadata/uniqueness, empty/full/wrapped ring including capacity one, reboot IDs/exhaustion, overflow/drop/reject and FIFO preservation, zero/partial drain budgets, callback reenqueue budget and envelope defaults. Full regression PASS: native 18/18 and native_asan 18/18; no sanitizer diagnostics. ESP32 build/purity PASS at unchanged RAM 47,504 B / image 964,333 B. Whitespace and local document paths PASS.

Pinned Xtensa compile-only smoke `/tmp/xuna_s07_target_smoke.cpp` includes and instantiates queue/ID/event: PASS with C++11/-Wall/-Wextra/-Werror. No host-target runtime parity or measured event processing latency claimed.

## Open integration finding

S05 ClockModel::utcMinute currently returns Unix-epoch minutes, whereas plan §7.1/event envelope uses 2020-epoch minutes. They are not wired together yet. Add a focused S05-fix-01 with conversion/range/boundary tests before any time-event/identity wiring; never assign the existing ClockModel minute to Event.utcMinute directly. S07 tests intentionally do not invent that integration. No deployed state needs migration because neither new model is used by current firmware.

## Handoff

Firmware-first/Android later continues. S08a waits for S01 observed BLE bytes; no fabricated transcript. S06 pure identity and S14 ActivityFsm are eligible per dependencies; S06 board work still waits for S01. Address the time-epoch mismatch before identity/time integration. No upload, board operation, app work, commit/push or gitlink change.

## Follow-up — 2026-10-12

[S05-fix-01](S05-fix-01-time-epoch.md) resolves the UTC-minute epoch mismatch. Compact ClockModel/event minutes now share the 2020 epoch; millisecond UTC remains Unix. Earlier findings/results above retain their historical context.

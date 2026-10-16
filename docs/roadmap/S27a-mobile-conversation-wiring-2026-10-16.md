# S27a mobile conversation wiring - 2026-10-16

Status: in progress; simulator path implemented, device explanation reply pending S26/S27.

- Wired local extraction to explicit confirmation and opcode 3/6 commands.
- Added capability-bit-5 gating. Unsupported firmware sends no stated preference.
- Added one follow-up context answer. No command is sent before confirmation.
- The review shows polarity, action, context, day part and provenance.
- Text remains in memory only; no network or board operation occurred.

Validation: Flutter 3.32.8 analyze PASS; 41/41 tests PASS; diff check PASS. Opcode 6 now has a golden 12-byte vector and capability-bit-5 tests.

Remaining: explanation characteristic/model and replies grounded only in its fields; polish localized review labels; real firmware path waits for S26/S18 and board acceptance. The mobile code does not invent the still-unfrozen explanation BLE payload.

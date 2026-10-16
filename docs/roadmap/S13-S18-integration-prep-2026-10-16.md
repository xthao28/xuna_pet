# S08a + S13/S18 integration preparation — 2026-10-16

Status: **host preparation done; production unchanged.** Session plan §9 item 1, after the owner's gate simplification (AGENTS §3: S01 closed with skipped items, D2a, S13 + S18 merged).

## What was added (firmware, uncommitted)

| File | Role |
|---|---|
| `lib/xuna_core/include/xuna/protocol/V1LifeCoreAdapter.h` | Pure C++11 seam: BLE protocol v1 (opcodes 1–4, request cache, result codes, 20-byte life, two 20-byte memory pages, 16-byte status) on top of `LifeCore` + LifeSnapshot v2. Replaces the business logic in `BleManager`; also handles GPIO buttons, the quiet routine's preferred action, active lifetime and the five-minute checkpoint (commit-first). |
| `test/test_v1_adapter` | **S08a**: the S01 observed inspector script replayed through the adapter, plus D3, commit failure, rollback keys, reboot, checkpoint, greeting and reserved-ID cases (7 tests). |
| `include/NvsSnapshotStore.h` | Arduino `ISnapshotStore` for D2a: `life0/life1` written, `slot0/slot1` read-only, plus `ident` (64-byte identity) and `bootc`. Not linked from `main.cpp`. |
| `tools/nvs_life_dump.py` | Read-only decoder of an NVS partition dump: lists `xuna_life` keys and extracts blobs to another folder. |
| `sim/migration_check.cpp` | Host comparison of today's board path (v1 + `BoardLearner`) and the migrated LifeCore path on real snapshots. |

## Evidence

- **S01 transcript replay (compressed timing):** every observed result code (2, 0, 0, 0 dup, 6, 4, 0, 4 after GPIO0, 0 forget), status bytes 0–6, counters, decision ID, canFeedback, episode count and memory pages match the 2026-10-13 bytes. Learner v3 chose Idle for request 2 (checked for seeds 40–47), so life bytes match exactly apart from wall-clock `activeSeconds`.
- **Real timing:** the inspector rated 168 s after the suggestion (board uptimes 2,748,222 → 2,916,460 ms). Under D3 this approval is rejected (4) and teaches nothing. App-driven ratings are expected within the window; manual inspector scripts are not.
- **Real pet migration:** `nvs-before.bin` of 2026-10-16 (SHA-256 `d7d12a9b…ec52d`, matches the recorded backup) and the 2026-10-13 S01 backup decode to v1 `slot0/slot1`; generation 26, activeSeconds 5,977, no feedback or episodes (forgotten during S01). Migration: preferences idle/idle on both paths, counters and memory pages identical → PASS. The real pet has no learned evidence, so this check is weak by nature.
- **Synthetic edge case:** with idle and happy both disliked (3 negatives each in quiet), the board path prefers Idle and LifeCore prefers **Curious** (untried prior 0.5 > 0.2). Other synthetic histories agree.
- **Sizes (host, 64-bit):** `LifeSnapshotV2` 2,760 B, `LifeCore` 3,008 B. ESP32 smoke build with the adapter, LifeCore and NVS store as globals: RAM 52,576 B (+3,552 B static), Flash 2,842,665 B; production build unchanged at 49,024 B / 2,840,385 B.
- **Validation:** native 189/189 PASS; native ASan/UBSan 189/189 PASS; core purity PASS; ESP32 build SUCCESS. No board, phone, upload or NVS write.

## Behaviour decisions embedded (owner-confirmed 2026-10-16)

1. **Expired rating → result 4** (invalid_argument) until a dedicated code is frozen. Keeps the current app working.
2. **GPIO0 stays Happy by default.** v1 life/memory bytes cannot carry context 2 and the app throws on unknown context codes (`DeviceCodes.contextFromCode`), so a greeting decision could not be rated. Learnable greeting (D5) is behind `greetingLearning`, off; enabling it needs a protocol/app change (S26/S27).
3. **App decision IDs ≥ 0x80000000 → 4** (reserved for device decisions).
4. **Preference bytes use the coarse cell** (day part unknown) until S10-sync.
5. **Needs are not persisted** (cold-boot reset, the existing policy).

## Requirements for the board switch (session plan §9 item 2)

- Acceptance "learned choices identical after upgrade" holds except when idle and happy both fall below p = 0.5, where Curious is expected (D5). The owner's current pet is unaffected.
- **Stack:** the feedback path stages a `LifeSnapshotV2` copy (~2.8 KB) and `SnapshotStore::commit` a 1,536 B buffer in `loop()`; `recover` holds similar amounts in `setup()`. Measure `uxTaskGetStackHighWaterMark` on the board, or raise the loop task stack (`SET_LOOP_TASK_STACK_SIZE`), before relying on it.
- `BleManager` keeps its 12-byte packet buffer for v1 (16 B arrives with S10-sync).
- Identity: on boot `nextBoot()` → `readIdentity` → `IdentityService::onBoot`; with a valid v1 pet and no identity, `prepareMigration` with hardware entropy → `writeIdentity` → `acceptPersisted` (flow covered by `test_identity`).
- Verified NVS backup before upload; afterwards `tools/nvs_life_dump.py` on a fresh dump must show `slot0/slot1` byte-identical and new `life0/life1`.

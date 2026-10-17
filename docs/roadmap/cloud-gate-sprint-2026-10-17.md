# Cloud gate sprint plan — 2026-10-17

Status: **owner decisions recorded; work not started**. This is the session handoff for the accelerated path to Cloud.

## Owner decisions (2026-10-17, all recommended options)

1. **Gate (c) local export:** the app reads device data over BLE and writes a versioned JSON file with a hash. No full snapshot transfer over BLE yet; that remains Phase 2 restore.
2. **Backend starts now, in parallel:** CLD-01 threat model, CLD-02 contract draft and CLD-10 FastAPI/PostgreSQL scaffold and CI may begin before gate (b)/(c) closes. Projection of device data (CLD-14 onward) still requires the gate.
3. **One combined board session:** one NVS backup and one upload carrying S10-sync, S26/S27-lite and Identity/export. Short acceptance: capabilities, TimeSync `Synced` + day part, "Why?", PetId read, export.
4. **S10-sync committed:** firmware `f339fff`, mobile `d34c63b`, parent `b7d71cc`. Not pushed.

## Gate status

| Gate | Status |
|---|---|
| (a) LifeSnapshot v2 on the board | Met (S13 + S18 image, 2026-10-16) |
| (b) Durable `PetId` readable over BLE | Not met. `PetId` is in NVS (`IdentityRecord`, Serial-printed in `main.cpp`), but there is no BLE characteristic for it |
| (c) Local export without a service | Not met |

## Proposed wire format: Identity V1 (to implement; not frozen until host tests pass)

- Characteristic `7a6e000c-8c44-4db6-9f61-2b7d5300a101`, READ. It is v1-additive; `0008`–`000a` stay reserved for BLE v2 `Hello`, which only carries `petIdHash`.
- Capability bit 7. Capabilities byte 2 changes from `0x3f` to `0xbf` (bit 6 Hatch stays off).
- 24 bytes: `version u8 = 1`, `size u8 = 24`, `petId[16]`, `origin u8` (1 HatchedOnDevice / 2 HatchedViaApp / 3 MigratedFromV1), `reserved u8 = 0`, `snapshotGeneration u32 LE`.
- When identity is not Ready, send version and size followed by zeroes (same convention as the explanation characteristic).
- Update the cached value after each snapshot commit, as `000b` does. Do not update GATT on every loop iteration.
- `(PetId, snapshotGeneration)` supports the proposed projection ordering key.

## Workstreams (each can run in parallel; separate repos)

| # | Repo | Work | Done when |
|---|---|---|---|
| A | firmware | Pure `IdentityCodec` + test, `BleManager` characteristic + bit 7, cached update on commit | Native + ESP32 build/purity PASS |
| B | mobile | Identity decode + model/use case; export JSON (`xuna.export.v1`: exportedAtUtc, app version, capabilities, petId, origin, generation, life status, memory pages, explanation, `sha256`) written with existing `path_provider`; minimal export action in Device UI | analyze clean, tests PASS, `pubspec.lock` unchanged. `share_plus` is absent; adding it needs owner approval |
| C | backend | CLD-01 threat model and data-flow inventory; CLD-02 contract draft; CLD-10 scaffold (FastAPI, SQLAlchemy 2, Alembic, Pydantic, pytest, CI) | Tests PASS locally/CI |
| D | board | Combined upload and acceptance (decision 3) | After A + B; requires ESP32 connected and NVS backup |

## Known blockers

- This Windows machine has no Python (only the Microsoft Store alias), Docker or `psql`. Install Python 3.12+ (and Docker or a local PostgreSQL) before C. Otherwise run C on the Mac/WSL, or use SQLite for unit tests with PostgreSQL in CI only.
- D11a (cloud STT/LLM spike) remains open; CLD-13 provider work needs it.

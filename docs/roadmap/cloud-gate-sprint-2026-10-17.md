# Cloud gate sprint plan — 2026-10-17

Status: **A + B implemented; D firmware part done on the board 2026-10-17 — gate (b) met. Gate (c) waits for the upgraded app on a phone. C: CLD-10 scaffold done, CLD-01/02 drafts written.** This is the session handoff for the accelerated path to Cloud.

## Owner decisions (2026-10-17, all recommended options)

1. **Gate (c) local export:** the app reads device data over BLE and writes a versioned JSON file with a hash. No full snapshot transfer over BLE yet; that remains Phase 2 restore.
2. **Backend starts now, in parallel:** CLD-01 threat model, CLD-02 contract draft and CLD-10 FastAPI/PostgreSQL scaffold and CI may begin before gate (b)/(c) closes. Projection of device data (CLD-14 onward) still requires the gate.
3. **One combined board session:** one NVS backup and one upload carrying S10-sync, S26/S27-lite and Identity/export. Short acceptance: capabilities, TimeSync `Synced` + day part, "Why?", PetId read, export.
4. **S10-sync committed:** firmware `f339fff`, mobile `d34c63b`, parent `b7d71cc`. Not pushed.

## Gate status

| Gate | Status |
|---|---|
| (a) LifeSnapshot v2 on the board | Met (S13 + S18 image, 2026-10-16) |
| (b) Durable `PetId` readable over BLE | **Met 2026-10-17** on the board: BLE read of `7a6e000c` returned PetId `d945c77026fd4f4a8a899bbff4aeed86`, origin 3, generation 38, equal to Serial and the NVS `ident`/`life0` backup |
| (c) Local export without a service | Implemented in source (`xuna.export.v1`), tests PASS. Pending: install the upgraded APK on a phone and export from the board |

## Identity V1 wire format (implemented; host tests PASS 2026-10-17, so the freeze condition above is met; board acceptance pending)

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

## 2026-10-17 — Workstreams A and B implemented (source/host only)

Owner delegated the decisions ("cứ tự quyết định") and asked to finish the remaining gate conditions.

**A — firmware** (`firmware/`):

- `xuna/identity/IdentityCodec.h`: pure 24-byte encoder exactly as specified above. Null or invalid record → `{1, 24, 0…}`.
- `V1LifeCoreAdapter::generation()` exposes the last durable snapshot generation.
- `BleManager`: READ characteristic `7a6e000c`, capabilities byte 2 `0x3f` → `0xbf`. The value is re-encoded each loop but `setValue` runs only when the 24 bytes change (same cache pattern as `000b`), so it follows every snapshot commit without per-loop GATT writes. `main.cpp` passes the identity only when `IdentityService` is `Ready`.
- Test `test_identity/identity_characteristic`: byte fixture, origin/generation, not-ready and invalid-record zeroing.

**B — mobile** (`mobile/`):

- Identity: `DeviceProtocol.capabilityIdentity` (bit 7), `ProtocolCodec.supportsIdentity/decodeIdentity` (length, version, size, origin ≤ 3, reserved 0, not-ready must be all-zero, UUIDv4 version/variant bits), `PetIdentityModel`/`PetIdentityMapper`/`PetIdentity`, `DeviceRepository.readIdentity` (null for no capability or not ready), `ReadPetIdentityUseCase`. Simulator never advertises identity, so simulator data cannot be exported as a board pet.
- Export: `ExportDeviceDataUseCase` reads identity first (throws `identityUnavailable` without one, then reads nothing else), life, memory pages and explanation; read-only, sends no command. `DeviceExportRepositoryImpl` + `DeviceExportMapper` + `ExportDocumentCodec` write the file through `DeviceExportLocalDataSource` (`path_provider`, app documents `exports/`, 10 s timeouts). Failures → `exportFailed`.
- UI: Device tab button "Xuất dữ liệu XUNA (JSON)" (enabled only when connected and idle) with a note that it only reads and saves locally; success info dialog shows path and the first 12 hash characters. Device info sheet shows the PetId prefix.

### `xuna.export.v1` document

```json
{
  "format": "xuna.export.v1",
  "sha256": "<hex>",
  "payload": {
    "exportedAtUtc": "2026-10-17T08:05:09.000Z",
    "app": {"version": "1.0.0+1"},
    "capabilities": {"statedPreference": true, "timeSync": true, "identity": true},
    "identity": {"petId": "<32 hex>", "origin": "migrated_from_v1", "snapshotGeneration": 34},
    "life": {"activeSeconds": 0, "feedbackCount": 0, "decisionId": 0, "context": "quiet", "action": "idle",
             "quietChoice": "idle", "playChoice": "idle", "canFeedback": false, "memoryCount": 0},
    "memories": [{"context": "quiet", "action": "idle", "approved": true, "source": "button"}],
    "explanation": null
  }
}
```

- `origin`: `hatched_on_device` | `hatched_via_app` | `migrated_from_v1`. Enum strings are explicit snake_case, never indexes.
- `explanation` is null for firmware without bit 5; otherwise `interaction`, `dayPart`, `action`, `reason` (`unavailable|highest_estimate|exploration|no_evidence|told`), `fine`, `rated` and the six masses as raw Q8.8 integers (`probabilityQ8`, `effectiveMassQ8`, `positiveQ8`, `negativeQ8`, `statedPositiveQ8`, `statedNegativeQ8`), so no float formatting enters the hash.
- `sha256` = SHA-256 of the UTF-8 compact JSON of `payload` in stored key order. Verified equal to Python `hashlib.sha256(json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode())` on a sample with Vietnamese text (backend CLD-02 can verify uploads this way).
- File name `xuna-export-<petId>-<UTC yyyyMMddTHHmmssZ>.json`. On Android it lands in the app sandbox (`app_flutter/exports/`); debug retrieval: `adb exec-out run-as com.example.xuna_mobile cat app_flutter/exports/<file>`. Share sheet needs `share_plus` (still not approved, not added).
- Contains no conversation text, secrets or phone-owned pet state; it is a read-only projection labelled by `exportedAtUtc` and `snapshotGeneration`.

**Dependency decision (delegated):** `crypto` promoted from transitive to a direct dependency pinned at the already-locked `3.0.7` (Dart team, BSD-3). `pubspec.lock` changes only `dependency: transitive` → `"direct main"`; no version moved.

**Validation (Mac, 2026-10-17):** firmware native 195/195 and native_asan 195/195, purity PASS, ESP32 build SUCCESS (52,112 B RAM / 2,852,645 B Flash; +24 B RAM, +216 B Flash vs S10-sync). Mobile Flutter 3.32.8 analyze clean, 72/72 tests PASS. Debug APK build PASS (not installed on a phone).

**Not done / not run:** no upload, NVS backup, BLE, phone install or real export (ESP32 not connected). Backend C not started. No commit/push.

**Next (D, needs the board):** cable + port check → NVS backup + partition verify → install the upgraded APK first → upload firmware (S10-sync + S26/S27-lite + Identity V1) → short acceptance: capabilities `0xbf`, TimeSync `Synced` + day part, "Why?", PetId equals Serial `PetId=` (`d945c770…`), export file hash verifies with the Python line above.

## 2026-10-17 — D: combined board session (firmware part)

Board `/dev/cu.usbmodem14101`, ESP32-S3 rev v0.2, MAC `98:c3:77:a6:6f:d8`. No phone attached (`adb devices` empty), so the APK was **not** installed first; the board-side checks used a Mac BLE client instead.

**Backup** (`/Users/xthao28/xuna_backups/2026-10-17-cloud-gate/`, outside Git):

| File | SHA-256 / result |
|---|---|
| `partition-device.bin` (0x8000/0xc00) | `bd0f7954…6ce5…fff6ce`, byte-identical to the 2026-10-16 backup and the build |
| `nvs-before.bin` (0x9000/0x5000) | `8511d57a7d06e2197e42ceee81ac20a479b62b9653c6fd7a54960ef9738edfc4` |
| Second NVS read | Differs only in one NVS page entry-state bitmap (a new non-XUNA entry after the esptool reset); all decoded keys `bootc`, `ident`, `life0`, `life1`, `slot0`, `slot1` byte-identical |
| Decoded pet | `ident` Valid, PetId `d945c770…ed86`, origin 3; `life0` generation 38, active 7,889 s, feedback 5, episodes 5; `life1` generation 37. v1 `slot0/slot1` byte-identical to the 2026-10-16 originals (rollback point intact) |
| Read of the running app (0x10000, 2,850,704 B) | **Failed** once with the known USB short read (`expected 0x1000, received 0xf9a`); not retried. Rollback options: rebuild S10-sync `f339fff`, or `2026-10-16-s13-switch/firmware-rollback-verified.bin` (pre-S13, reads intact v1 slots) at 0x10000; never erase/restore NVS without a separate instruction |

**Upload 1** (A + B source as committed in this session's working tree): SUCCESS, hashes verified; boot `recover=Ok slot=0 boot=7 ready=1`, same PetId, preferences quiet=Happy play=Idle, setup stack 7,908 B, no error in ~36 s.

**Defect found on the board:** a Mac GATT listing showed only `0002`–`0007`. Arduino `BLEServer::createService(const char*)` reserves **15 handles**; the service needs 18 (service + 8 characteristics × 2 + status CCCD), so `000b` (explanation, since S26) and `000c` (identity) were silently missing. S26's explanation had never run on a board, so host tests could not reveal it. Fix: `createService(BLEUUID(kService), 32)` in `BleManager.h` with a comment. ESP32 build PASS 52,112 B RAM / 2,852,609 B Flash (native tests unaffected: BleManager is firmware-only).

**Upload 2** (with the fix): SUCCESS, hashes verified; app SHA-256 `381f7751f9464208e35bb47d19211a7367339144dd5f10ebb660c154e235d587`, copy `firmware-uploaded.bin` in the backup folder. Boot `recover=Ok slot=0 boot=10 ready=1`, same PetId, Happy/Idle, stack 7,908 B.

**Acceptance via Mac BLE (bleak 0.22.3 in a scratch venv; sandbox disabled for CoreBluetooth):**

| Check | Result |
|---|---|
| Capabilities `0002` | `01 08 bf 00 0f 03 60 09` — bit 7 identity, bits 4/5 on, bit 6 hatch off |
| Identity `000c` | `01 18 d945c77026fd4f4a8a899bbff4aeed86 03 00 26000000` → PetId equal to Serial, origin MigratedFromV1, generation 38 equal to NVS `life0` |
| TimeSync (opcode 5, UTC 1792247242, tz +420) | result 0; Serial `time_sync result=0 quality=2 day_part=3 tz_min=420` (Synced, evening at 21:27 local) |
| Suggest quiet (opcode 2), then explanation `000b` | result 0, chose Happy; explanation `01 14 00 03 01 01 00 03 cb00 cd02 cd02 0000 0000 0000`: quiet, evening, Happy, highest estimate, coarse, rated 3, p ≈ 0.79, nEff/positive ≈ 2.80, negative 0, stated 0 — consistent with the learned quiet=Happy preference. Not rated, so nothing was taught |

**Not done:** app install, app "Why?" chat, app export (gate c), reboot ×3, checkpoint high-water, Forget. Mac BLE is a developer client, not app acceptance. No commit/push.

## 2026-10-17 — C: backend CLD-10 scaffold, CLD-01/CLD-02 drafts

See `backend/README.md`, `backend/AGENTS.md`, `backend/docs/ARCHITECTURE.md`, [threat model](../architecture/XUNA_CLOUD_THREAT_MODEL.md) and [contract draft](../architecture/XUNA_CLOUD_CONTRACT_DRAFT.md). Backend verifies the real mobile-generated `xuna.export.v1` golden fixture, so gate (c) files exported from the board will be checkable server-side. No device data stored; no provider; nothing pushed.

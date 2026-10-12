# S06 — Identity core (partial delivery)

Date: 2026-10-12. **Status: In progress — pure core implemented/host-tested; firmware storage/wiring and board acceptance deferred.** S01 physical Android baseline remains required for board steps.

## Implemented scope

- `xuna/base/Crc32.h`: pure reflected IEEE CRC32, check 123456789 -> 0xCBF43926.
- `xuna/identity/IdentityRecord.h`: explicit little-endian 64-byte schema-1 codec, UUIDv4 layout, seed/hatch boot/active second/mono anchor/bornAt/quality/content version/origin, CRC. Decode is transactional and returns Valid/Corrupt/TooNew; Missing is an adapter result. Unsupported or corrupt bytes do not regenerate identity.
- `xuna/identity/IdentityService.h`: Egg without identity/snapshot; NeedsMigration with a valid old snapshot; Ready with valid identity; Safe on corrupt/too-new/invalid inputs. A valid old identity is retained unchanged. Migration creates identity with MigratedFromV1 origin and birth unknown; service never mutates LifeEngine preferences or lifetime. Ready corresponds to initial Newborn identity, not implemented growth-stage FSM.
- Caller supplies 16 entropy bytes plus seed (real hardware RNG deferred); service sets UUID version/variant bits. Core does not use PCG or fabricate hardware entropy. Boot counter must be committed by the future adapter and must not wrap/reuse; zero boot counter enters Safe.
- Prepare methods output candidates without claiming storage success. acceptPersisted is called only after successful adapter commit and refuses replacement of immutable identity fields. This is a pure single-owner contract, not crash-safe storage implementation.
- Device/app hatch origins share domain logic; no actual gesture or app opcode is enabled. Synced time at hatch produces exact bornAt. Otherwise same-boot trusted sync can backfill once from elapsed monotonic time; approximate clocks, later boot and migrated MVP identity do not backfill. Time remains Unix milliseconds for bornAt, distinct from compact 2020-epoch minutes.

## Codec layout freeze for this implementation

| Offset | Bytes | Field |
|---|---|---|
| 0 | 2 | XI magic |
| 2 | 1 | schema = 1 |
| 3 | 1 | reserved zero |
| 4 | 16 | petId |
| 20 | 4 | seed |
| 24 | 4 | hatchBootCounter |
| 28 | 4 | hatchActiveSecond |
| 32 | 8 | hatchMonoMs |
| 40 | 8 | bornAtUtcMs (0 unknown) |
| 48 | 1 | bornAtQuality (Unknown or Synced) |
| 49 | 2 | hatchContentVersion |
| 51 | 1 | origin (1 device, 2 app, 3 migrated) |
| 52 | 8 | reserved zero |
| 60 | 4 | CRC32 over bytes 0..59 |

Schema checks reject malformed UUID bits, origin/quality combinations, zero boot/content version and nonzero reserved data. No struct memcpy serialization. This is not a flash partition/storage approval; persistence wiring remains deferred.

## Verification

Tests-first failed for missing IdentityService.h, then four identity tests passed: CRC vector; codec roundtrip/exact reencode/all-byte corruption/truncation/too-new/invalid fields; Egg/migration/loaded/safe paths and immutable identity; same-boot vs later-boot birth, approximate-time hatch, persistence staging, and untouched v1 preference snapshot. Full native and ASan/UBSan regression: **23/23 each PASS**. Pinned Xtensa smoke instantiating identity service/codec: PASS, C++11/-Wall/-Wextra/-Werror. Normal ESP32 build/purity PASS at unchanged 47,504 B RAM / 964,333 B image; new identity code is not wired into application, so this does not validate storage/hatch on board.

## Remaining S06 steps

GPIO14 hold/placeholder egg visual remains Proposed, not frozen/implemented here. StorageKeys registry, bootc persistence, radio-start hardware RNG acquisition, NVS adapter/commit failures, boot logging and isolated xuna_test mode are not implemented. Owner board checks (migration/reboots/forget/gesture) not run; no flash/upload or NVS operations. S06 is not Done.

Next eligible phone-independent session: S14 ActivityFsm (depends S07, complete), following the existing dependency map. S08a waits for S01 observed BLE transcript; no synthetic bytes substituted. Do not treat this partial S06 as satisfying dependencies that require its firmware wiring. Android app work remains deferred. No commit/push or gitlink update; earlier edits preserved.

# E4/E5 — Storage experiment preparation

Date: 2026-10-12. **Status: Prepared/build-checked; not executed on hardware. S11 In progress.** D2 remains undecided.

## Concrete experiment artifacts

External isolated project: [s11-storage](/Users/xthao28/xuna_experiments/s11-storage/README.md), [benchmark source](/Users/xthao28/xuna_experiments/s11-storage/src/bench/storage_bench.cpp), [configuration](/Users/xthao28/xuna_experiments/s11-storage/platformio.ini). Display/animation/config copied from committed firmware be58099; uses unchanged Arduino/PlatformIO/TFT pins and partition layout. Does not include uncommitted M04 refactor. Source hashes in external source-manifest.json. Nothing merged into firmware; previous work preserved.

Prepared A/B NVS (xuna_bench only), 40-byte append/16KiB rename tests in /xuna_bench on LittleFS, animation timing, explicit serial-controlled storms and recovery logging. No automatic writes or autoformat after boot. Explicit format command refuses any partition containing non-erased bytes. Critical measurements/atomicity/recovery still require real-board validation; compile success does not establish correctness or safety of power-cut recovery.

Restoration project: /Users/xthao28/xuna_experiments/s11-mvp-restore, copied from committed be58099 (original MVP) rather than the currently refactored working tree. Reflash after cleanup only with unchanged partitions and preserved pet data. No upload performed.

## Checks actually performed

- Device list: only Bluetooth serial ports; **no ESP32 USB detected** in this session.
- Isolated benchmark final build PASS: static RAM 159,840 B, image 365,053 B. These are linker sizes, not runtime heap/latency measurements. Fixed sample arrays consume 120,000 B, so benchmark heap differs materially from MVP.
- Restoration build PASS: RAM 47,504 B / image 964,333 B, matches original MVP baseline.
- No serial connection, flash read/write/format/cleanup, power cut, board measurement or pet-state check. Previous 2026-10-12 NVS backup exists; **fresh backup and full-image backup are required before experiment**, especially before filesystem formatting.

## Execution gates and outstanding work

S11 preconditions list S04 + backup, but session-wide §2.3 prohibits refactored/storage-changing uploads before S01. Its cleanup step also compares against S01. The earlier claim that S11 could execute fully without S01 was incomplete. Prepare/build is possible now; real execution requires S01 OR an explicit owner exception with a board-only preservation baseline, backup/restore checks and later Android acceptance still open. No exception is assumed from preparation.

Also needed: reconnect ESP32; re-read actual partition table; refreshed verified NVS/full-image backup with hashes; inspect filesystem contents/erased state; inspect pet snapshot bytes before changes. Physical cut counts require owner participation (25 per selected mode); no automatic relay assumed. Reject unknown/corrupt pet baseline rather than continuing destructively.

Measurement table (pending): NVS write p50/p99/max/free entries/heap; FS mount/appends/rename/space; render/tick-gap distributions; CRC/newest sequence and detected torn-record counts per cut; restore/identity/preferences intact. Harness runs without BLE/life runtime; it does not validate full future concurrent load or direct wear counts. Report these limits explicitly. Only after evidence: ADR-0002 review → owner D2 → S12.

## Source preservation — owner commit request 2026-10-12

Reviewable source-only [S11 archive](artifacts/s11-storage-source.zip) now saved in root repository. SHA-256: `33f999966ca337ae5a04294f01ae28dd116f253a3a2d9e7bfe3cfa6c051ca928`. Includes code/config/README, excludes .pio outputs, device backups and logs. S11 remains paused; this archive does not approve runtime upload or D2.

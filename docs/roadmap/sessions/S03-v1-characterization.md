# S03 — Firmware v1 characterization

Date: 2026-10-12. **Status: Done — host characterization and ESP32 build verification.** Physical BLE acceptance is not validated by this record.

Owner requested firmware/ESP32 first; app-device work is deferred and **Android** selected for later S01/app acceptance. S00 and approved D1 satisfy S03 preconditions; missing S01 does not block this host-only session.

## Changes

Firmware `test/fixtures/v1_snapshots.h`: three frozen 96-byte host-encoded snapshots. Generation recipe and source baseline be58099 are in the header. `test/test_v1_characterization.cpp`: exact snapshot fields/bytes; choice table (4,802 evidence combinations across two contexts); parser matrix (34,816 opcode/length/argument cases plus source/error-precedence cases); cache hit/conflict/clear/result/eviction; A/B recovery across generation rollover; quiet-routine unsigned timing and bounded delayed ticks. Firmware README documents commands and limits.

No production code or platformio.ini changes. Parser produces validation errors 1–4; adapter result codes 5–7 are characterized only through cached results here. This is not the observed BLE transcript required by S08a.

## Commands and results

- One-off `/tmp/xuna_s03_generate.cpp` compiled with `c++ -std=c++11 -Wall -Wextra -Werror -Ifirmware/include`; unchanged LifeEngine encoder generated fixture arrays.
- Same flags compiled and ran `firmware/test/test_v1_characterization.cpp`: PASS.
- Existing `test_core.cpp`, `test_life.cpp` and new characterization suite each compiled/ran with those flags plus `-fsanitize=address,undefined -fno-omit-frame-pointer`: PASS, no sanitizer diagnostics.
- `~/.platformio/penv/bin/pio run -d firmware -e xuna_t_display_s3`: PASS; RAM 47,504 B / image 964,333 B, zero change from S00.
- Root/firmware whitespace and production-change checks: PASS.

## Handoff

Next authorized firmware session: S04 extraction + native test environments; no upload until S01 physical baseline. S01 remains partially prepared (NVS backup recorded) and awaits Android setup/acceptance; Android native build and BLE compatibility remain unverified. S04 has not started. No commit/push or gitlink update; prior root and mobile edits preserved.

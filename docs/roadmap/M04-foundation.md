# M04 Foundation — acceptance record (S21)

Date: 2026-10-22. Status: **Implemented; owner-approved 2026-10-23** (plan S21 step 4). A row is **Validated** only where board evidence exists; host-only rows stay *Implemented*.

Board: T-Display-S3, ESP32-S3 rev v0.2, `/dev/cu.usbmodem14101`. Firmware `d1b17b8` (S19b BootSequence, S20, reaction learning, routine learning) plus this session's parity env.

## S21 target parity (steps 1–2)

`[env:xuna_parity]` (`firmware/src/parity/parity_main.cpp`, traces embedded by `tools/embed_parity_traces.py`) replays `c3_cut_then_commit`, `c8_dayparts` and `c9_lifelab_days` at boot through the same `LifeCoreTraceRunner` as `sim/lifecore_lab.cpp`, with the in-RAM A/B store; no BLE, display or NVS code is linked. A `LifeCoreStepProbe` hook (optional, host-tested not to change the replay) times every `step()`.

| Check | Result |
| --- | --- |
| CSV row, `snapshot_sha256`, explanation lines (24 lines, 3 traces) | **Bit-identical** host (macOS clang, `-O2`) vs ESP32 |
| `expect` checks (c9: 6) | 6/6 on the board |
| Determinism on the board | Pass 1 and pass 2 identical |
| Stack / heap during replay | Loop stack high water 6,132 B free of 32 KiB; heap free 327,172 B |

`step()` timing on the ESP32 (240 MHz, `esp_timer`, µs):

| Trace | Steps | Mean | p50 | p99 | p99.9 | Max | Trace runtime |
| --- | --- | --- | --- | --- | --- | --- | --- |
| c3 (power cut, reboot) | 12 | 108.6 | 32 | 265 | 265 | 265 | 4.6 ms |
| c8 (sync, day parts) | 8 | 117.3 | 49 | 313 | 313 | 313 | 4.3 ms |
| c9 (60 days + reboot) | 86,405 | 6.6 | 7 | 7 | 14 | 272 | 679 ms |

Steps with events (choose/feedback/commit/encode) cost 0.1–0.3 ms; quiet steps ~7 µs. Both are far below the 50 ms main-loop frame, so `step()` does not threaten the render budget. Logs: `/Users/xthao28/xuna_backups/2026-10-22-s20-routine/parity-board-log.txt`, `parity-host.txt` (outside Git).

## Board upload 2026-10-22

- Backup `/Users/xthao28/xuna_backups/2026-10-22-s20-routine/`: partition `bd0f7954…fff6ce` byte-identical to 2026-10-17; `nvs-before.bin` `57293190…c8ce9682b`; a second read differs only in `bootc` (esptool reset boots the firmware) — `ident`, `devkey`, `life0`, `life1`, `slot0`, `slot1` byte-identical.
- Production upload SUCCESS, app SHA-256 `02c2fcee…2640764c` (`firmware-uploaded.bin`). Boot `recover=Ok slot=0 corrupt_slots=0 boot=21 ready=1`, PetId `d945c770…ed86`, quiet=1 play=0 preserved, setup stack 7,300 B, no error in 40 s.
- Parity image uploaded, read, then production re-uploaded (same SHA-256). Boot `recover=Ok slot=1 … boot=23 ready=1` (the five-minute checkpoint wrote slot 1 in between), same PetId and preferences.

## Board upload 2026-10-22 (evening): firmware `0a392c5`

- Backup `/Users/xthao28/xuna_backups/2026-10-22-v1-scenes/`: partition `bd0f7954…fff6ce` identical to the build and to the morning backup; NVS read twice, both `cd8dc421…124c9a` (identical); keys `ident`, `devkey`, `life0`, `life1`, `slot0`, `slot1`, `bootc` 25.
- Upload SUCCESS (hash verified), app SHA-256 `b13ee96f…0d8135` (`firmware-uploaded.bin`). Boot: `recover=Ok slot=0 corrupt_slots=0 boot=28 ready=1`, same PetId `d945c770…ed86`, quiet=1 play=0, setup stack 7,300 B, `scene_mode=auto`, device key loaded. One `nvs_open failed: NOT_FOUND` line is expected: the new `xuna_ui` namespace does not exist until the scene is first cycled. 40 s log: idle, loop gap ≤ 5.7 ms, draw ≤ 4.8 ms, heap stable 233,868 B.
- Not checked yet: visual check of window scenes, heart/puff, status card, pairing QR; rain `scene_max_us`.

## Acceptance by slice

| Slice | Sessions | Status | Evidence / gap |
| --- | --- | --- | --- |
| M04.1 core extraction | S03, S04 | **Validated** | `xuna_core` purity check on every ESP32 build; native + ASan 225/225; the board runs the extracted core |
| M04.2 clock / RNG / identity | S05, S06, S10-sync | **Validated** for clock, TimeSync, PetId | TimeSync `Synced` + day part and PetId over BLE on the board (2026-10-17); PetId survived three uploads. S10-hatch and hatch bit 6 deferred |
| M04.3 events + command handler | S07, S08a (S08b/S09 folded into S13+S18) | **Validated** for v1 compatibility | S08a transcript replay gate; Mac BLE acceptance 2026-10-17. S01 scripted writes partly owner-skipped (2026-10-16) |
| M04.4 persistence v2 | S12a, S12b, S13 (S11 → S32) | **Validated** for migration and recovery | First boot `Migrated`, later boots `Ok` across slots 0/1; torn writes tested on host (S19b E). Power cut on the real board not run. D2a: NVS A/B now, LittleFS at S32 |
| M04.5 FSM / needs / visuals | S14–S17 | **Validated** by owner smoke (2026-10-16) | Render ±20 % not measured; idle loop now `draw_max_us` 4,826, `loop_gap_max_us` ≤ 5,714. Threshold values remain [P] |
| M04.6 Life Lab | S18, S19a, S19b, S20, S21 | **Validated** for target parity | Host lab + 100-day scenarios + golden vectors (Dart) + this parity run |

## Measurements (production image, 2026-10-22)

| Metric | Value |
| --- | --- |
| Static RAM / Flash | 52,848 B / 2,883,645 B (44.0 % of 6.25 MiB app) |
| Heap free at boot (min) | 235,184 B (233,740 B) |
| PSRAM free | 8,372,455 B of 8,386,279 B |
| Setup stack high water | 7,300 B free of 16 KiB |
| Render / loop gap (idle animation) | draw max 4,826 µs; loop gap max 4,784–5,714 µs |
| `step()` p99 (board) | 7 µs quiet, ≤ 313 µs with events |
| Commits | Feedback commits before apply (c3: 5 requests, 1 torn); lazy checkpoint every 5 minutes; boot counter once per boot |

## Open issues

1. Real power cut on the board during a commit (only host torn-write simulation so far).
2. Render time ±20 % against the pre-refactor baseline not measured (S17).
3. S10-hatch / hatch bit 6 deferred. (The learnable GPIO0 greeting is on since 2026-10-19: `main.cpp` builds the adapter with `greetingLearning=true`; the PROCESS.md 2026-10-16 status line saying "GPIO0 is direct Happy" is outdated.)
4. Gate (c) and the app checks (bind, AI chat, export hash) need the phone.
5. Reaction window/weight and routine anticipation not yet tried by the owner on the board.
6. App display of routine learning needs a BLE read.

## Decision log (M04)

D1 (M04 before M05 features), D2a (snapshot v2 in NVS A/B, LittleFS → S32), S13 + S18 merge absorbing S08b/S09, S10 split into sync/hatch, S19b `BootSequence` moved into `xuna_core`, `IdentityGatedCommit` (no snapshot before identity), D6 revised (reactions replace app ratings). Details in AGENTS.md §3 and PROCESS.md.

## Owner review (step 4)

Approved by the owner 2026-10-23 as proposed: M04 **Implemented**; **Validated** for the rows above that cite board evidence; open issues 1–2 carried into M05b (S29–S33) rather than blocking. The owner also reported issue 4 (gate (c) and the app checks) and the board visual check done the same day; measurements were not recorded here.

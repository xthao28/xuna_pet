# Local MVP through M05

Date: 2026-10-11. Status: **Implemented development slice; physical validation incomplete**.

## Owner-approved scope

Owner selected MVP through M05 and explicitly approved local device ownership of state/memory/preference, learning idle/happy preferences from explicit feedback, and local template-based text conversation without an LLM. These are scoped MVP decisions, not approval of future cloud sync or general intelligence. Voice, evolution and external sensors remain outside this MVP. Existing Clean/GetX and the pinned firmware toolchain remain.

## Implementation

- M02: bundled Arduino 2.0.14 BLE server; FlutterBluePlus 1.35.5 data repository, capabilities, notification/result correlation, bounded command queue, session-local 16-entry dedup, explicit scan/reconnect. No command replay after timeout. GATT success is not application success.
- M03: original existing pixel character with idle/happy/sleep/curious expressions/colors. Happy/curious expire after 2400 ms; sleep stays until explicit input. GPIO0 happy/GPIO14 idle retain priority over same-loop remote commands. Visual polish is not final artwork approval.
- M04: pure C++ LifeEngine, explicit monotonic active seconds, no invented wall time/offline duration. Two NVS snapshot slots with schema/version/length/generation/checksum and newest-valid fallback. Bad snapshots are rejected before mutation. Snapshot is 96 bytes; active lifetime checkpoints every five minutes, so sudden power loss can lose up to the uncheckpointed interval. Transient animation returns idle on boot; durable state is learned preference, compact memories and active lifetime. Feedback commits immediately; no per-frame Flash writes.
- M05: two contexts (quiet/play), two candidate actions (idle/happy). Estimate approval probability with Beta(1,1) prior: (positive+1)/(positive+negative+2); select higher estimate, tie defaults idle. Explicit negative feedback for quiet/idle causes the next quiet choice to become happy, without changing play. Counts bounded by halving near 1000; eight feedback episodes kept in a ring with context/action/approval/source. No fabricated sensor events or raw text memory. After 60 seconds without direct interaction, an idle pet runs the learned quiet routine locally; sleep is not interrupted.
- Conversation: exact supported local intents (chơi/yên tĩnh/thích/không thích and documented short aliases). Feedback from text requires confirmation and references a pending device suggestion. Direct animation/local buttons invalidate pending suggestions; one feedback per suggestion. Unsupported prose returns a clear local response and does not learn. This is a narrow text interface, not an open-ended chatbot.
- Privacy: UI displays recent confirmed feedback and its source; explicit confirmation to forget all preference/memories. Forget writes empty newer snapshots to both slots, preserving active lifetime; errors are reported. Individual episode edits/backup/account/sync are not implemented.

## Protocol v1 additive MVP extension

Use UUID prefix `7a6e000N-8c44-4db6-9f61-2b7d5300a101`; N=1 service, 2 capabilities Read, 3 command Write, 4 status Read/Notify (original M02 layout), 5 life Read, 6/7 memory pages Read. No larger MTU required: all values at most 20 bytes.

Capabilities stay 8 bytes: command mask now 0x000f, animation mask 0x0f, flags 0x03, duration 2400ms. App requires these MVP capabilities; old animation-only firmware is rejected. Bit index equals opcode-1. UUID/schema do not encode pet-life authority beyond this owner-approved local MVP.

Command common header: version u8=1, opcode u8, request ID u32 little-endian nonzero, argument u8, source/reserved u8.

| Opcode | Length | Argument / extra data |
| --- | --- | --- |
| 1 animation | 8 | state 0 idle / 1 happy / 2 sleep / 3 curious; reserved=0 |
| 2 suggest | 8 | context 0 quiet / 1 play; reserved=0 |
| 3 feedback | 12 | approval 0/1; source 1 explicit app button / 2 confirmed text; bytes 8–11 target suggestion request ID |
| 4 forget | 8 | argument/reserved=0 |

Status remains 16 bytes as in M02. Result codes 0–7 unchanged. Cache retains up to 16 identifiable requests/results in current connection; payload mismatch for reused ID gives conflict; cache cleared on session changes. Queue has eight slots, one packet processed per loop; overflow drops the packet and surfaces as client timeout, not automatic replay. Storage failures return not_ready. After timeout client refreshes status and reports outcome unknown.

Life characteristic (20 bytes): version=1, length=20, latest context, latest suggested action; activeSeconds u32 at offset4; total feedback events u32 at offset8; pending suggestion ID u32 at offset12; quiet choice byte16, play choice byte17, canFeedback byte18, retained memory count byte19. Latest suggestion can expire visually while feedback still refers to that choice; direct input invalidates it.

Memory page (20 bytes): version=1, count 0–4, page 0/1, reserved=0; four entries each context/action/approved/source. Pages are chronological oldest first. Reads are foreground and serialized by the UI action flow. No wall-clock timestamp or free-text facts are asserted.

## Running

Simulator explicitly uses fake transport (in-memory only):

```sh
cd mobile
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter run -d <simulator-id> --dart-define=XUNA_SIMULATOR=true
```

Real iPhone uses default physical repository:

```sh
cd mobile
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter run -d <real-iphone-id>
```

Real iOS signing/device OS compatibility must be checked with actual phone. Default app on a simulator cannot discover a board through CoreBluetooth. Android native build/permissions remain unverified; this checkpoint targets iOS.

## Software evidence

- `flutter pub get`: PASS. Existing dependency set retained plus exact FlutterBluePlus 1.35.5. Resolved BLE subpackages: android4.0.5, darwin4.0.1, linux3.0.2, platform_interface4.0.2, web3.0.1. Dart/Flutter constraints compatible; Darwin podspec iOS12.0. Pinned package and Darwin notices inspected (BSD-style redistribution terms); preserve all dependency notices.
- `flutter analyze`: PASS; `flutter test --reporter expanded`: **10 tests PASS**, including wire validation, capabilities, request correlation/concurrency/timeout/disconnect, measured context-specific adaptation, text consent/provenance/forget and widget scan/connect/animation/expiry/disconnect.
- `flutter build ios --simulator --debug --dart-define=XUNA_SIMULATOR=true`: PASS; `flutter run` with same define on iPhone13/iOS16.2: PASS, MVP Home screenshot inspected, latest source hot reload succeeded. UI interaction evidence comes from automated widget/domain tests; screenshot alone does not validate all native interactions. Temporary screenshot /tmp/xuna-mvp-simulator.png is not durable evidence.
- Host core C++ tests: PASS with C++11/Wall/Wextra/Werror, including sleep/curious timing. Life/protocol host tests PASS with AddressSanitizer/UndefinedBehaviorSanitizer: context isolation/adaptation, bounded counters/episodes, snapshot corruption/newest-valid fallback, truncated data, rollover quiet routine and command validation/dedup.
- Firmware builds PASS on unchanged espressif32 6.5.0 / Arduino2.0.14 / TFT_eSPI2.5.43. Keep baseline upstream DMA/touch/UART warnings separately from project errors.

## Physical acceptance still open

1. Observe all four expressions/LCD and both buttons on uploaded MVP; do not inherit M01 visual validation for changed code.
2. Real iPhone scan/connect/capabilities; idle/happy/sleep/curious; receive button/timeout state notifications.
3. Validate duplicate/conflict, invalid command, notification timeout, Bluetooth off/deny permission, explicit disconnect/reconnect and board reset.
4. Demonstrate before/after learning on board: quiet→idle, reject, quiet→happy; play stays idle.
5. Confirm text candidate does not learn until confirmation; inspect memory source.
6. Reboot/reconnect: preference and episodes persist, old pending suggestion cannot receive feedback.
7. Forget then reboot: preference/memory remain cleared; active lifetime retained.
8. Actual power-interruption/corruption recovery and Flash write behavior; host recovery tests do not validate physical NVS atomicity.
9. Observe phone-free learned quiet routine and standalone startup.
10. Run BLE workload/stability diagnostics, compare heap/render/loop with M01; physical input latency remains uninstrumented.

M01 PCB revision/P07 remain open. M02–M05 are not marked Validated by build/host/simulator results. Owner subsequently requested Git delivery; see final Git checkpoint below. Backend remains untouched.

## LILYGO MVP build/upload smoke — 2026-10-11

Owner requested building/running on LILYGO and confirmed LCD and both buttons work after upload (BOOT happy/timeout and GPIO14 idle). Normal IDE CLI /Users/xthao28/.platformio/penv/bin/pio: `run -d firmware -e xuna_t_display_s3` PASS; `run -d firmware -e xuna_t_display_s3 -t upload --upload-port /dev/cu.usbmodem14101` PASS, hashes verified. USB identity 303A:1001 / 98:C3:77:A6:6F:D8 rechecked. Standard upload rewrote boot/application regions without an erase-all request.

Initial 0.2.0-mvp boot showed missing slot0/slot1 NVS keys as Preferences error logs. Empty storage is expected on first boot: added isKey checks before getBytesLength, rebuilt/uploaded and repeated a 22-second Serial capture. Corrected startup has no warning/error markers, Flash16777216 and PSRAM chip8388608 bytes; display driver initialized. Opening native USB Serial produced USB_UART_CHIP_RESET; this is not evidence of standalone boot or a spontaneous reset.

Final linker static RAM **47504 / 327680 bytes**, firmware **964333 / 6553600 bytes**. Corrected runtime initial heap253056/free, min252980; three subsequent windows free252792/min251780, last button-interaction window free252788/min251780. PSRAM heap8386279 total / 8373475 free throughout. Idle-only windows2.4–2.6fps; mixed happy/idle window3.0fps is not a pure happy benchmark. Render mean3489–3508us, max3694us; maximum reported loop gap4545us. This is a short smoke observation, not a long stability validation or measured electrical input latency. Raw temporary logs: /tmp/xuna-mvp-board-smoke.log and /tmp/xuna-mvp-board-corrected.log; this summary is durable evidence.

Serial capture closed normally. Physical BLE/iPhone, sleep/curious visual checks, learned routine, reboot/power-loss persistence and forget/reboot matrix remain pending; M01 PCB revision/P07 remain open.

## Git delivery — 2026-10-11

Owner requested publishing current code. Firmware be58099 and mobile3846880 committed/pushed to origin/dev, clean child working trees; root snapshot containing this record updates both pointers and handoff documents. Backend unchanged. Rechecked analyzer/10 mobile tests and host core/life sanitizer tests PASS before delivery; staged whitespace checks PASS. Git delivery does not close pending physical acceptance.

## S01 partial — ESP32-only preparation (2026-10-12)

Owner deferred real-phone acceptance and requested ESP32 work first. Device detected at `/dev/cu.usbmodem14101` (Espressif USB 303A:1001). Serial inspection caused USB/UART reset; boot reports XUNA 0.2.0-mvp, 16 MiB Flash and 8 MiB PSRAM. Chip read by esptool: ESP32-S3 silicon revision v0.2; this is **not** the unknown PCB revision. Two idle diagnostic windows: render averages 3507/3491 us, maxima 3693/3527 us; loop-gap maxima 4543/3540 us. This brief observation is not stability or BLE acceptance; LCD was not visually confirmed in this session.

Read actual partition table with esptool 4.5.1 (`read_flash 0x8000 0xC00`); decode verified NVS at 0x9000/0x5000 and complete table matches current build. Read NVS (`read_flash 0x9000 0x5000`), verified file length 20,480 B and recorded SHA-256. Backup files and manifest are outside the repositories at `/Users/xthao28/xuna_backups/2026-10-12-s01/`. Table SHA-256: `bd0f7954aca2ef7d925ee21aaa1f3dc8822d1d6ce5cbbd26a135e5886bfff6ce`; NVS SHA-256: `f941a8b3398788301c87902e293c8ab8ab6dc629f5b47d8946f1e05787f7e822`. Restore was not tested; no erase/write_flash/firmware upload, pet commands or power-cut tests. Flash reads reset the board; esptool's temporary RAM stub does not replace installed firmware.

S01 remains **In progress — phone-dependent acceptance deferred**. BLE transcript/feedback/reboot/forget and owner visual checks are unvalidated. Backup does not waive S01 gates on S06/S09/S13 etc. S11 additionally needs S04 and owner-operated power-cut evidence. Eligible next firmware work without phone: S03 → S04, then S05/S07; these run on host, with board build verification where specified, and no refactored firmware upload before S01 acceptance. No later session implemented in this partial run; code/submodule state unchanged.

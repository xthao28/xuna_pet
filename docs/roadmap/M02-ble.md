# M02 — Flutter + BLE proposal

Date: 2026-10-11. Status: **Protocol/library experiment approved; simulator mobile slice Implemented; physical BLE pending**.
Owner explicitly changed priority to M02; M01 remains Implemented with PCB revision/P07 open.

## Facts and limits

- Root/firmware/mobile/backend are on dev: 3dda411 / be5829d / 310e69f / 0032828. Root, firmware and mobile are dirty; backend is clean. No commit, push or gitlink changes.
- Firmware has pure C++ AnimationManager (idle/happy, happy expires after 2400 ms), GPIO input and diagnostics. No BLE implementation.
- Mobile retains approved Clean/GetX core/shared, HomeController/HomeBinding and domain contracts. No BLE dependency.
- Flutter 3.32.8 / Dart 3.8.1; Xcode 14.2; booted iPhone 13 simulator running iOS 16.2. No physical iPhone detected. ESP32 USB present at /dev/cu.usbmodem14101; recheck before upload.
- Simulator exercises UI/domain/fake transport, not physical board BLE. Native build of the final mobile base is still unverified. No build/test/upload was performed during this proposal inspection.

## Smallest vertical slice — Proposed

Foreground, one phone/one board: scan service → select device → connect → discover GATT → subscribe status → read capabilities/status → enable Idle/Happy buttons → write command → correlate application result → display actual animation state. Keep existing physical buttons and happy timeout.

Add a feature-specific BLE data adapter/repository implementation, domain entities/repository/use cases and GetX binding/controller/UI within existing Clean structure. SDK objects stay in data; protocol codec/domain logic are testable without plugins. Preserve core/shared and dependencies. Simulator fake transport is explicit, visibly labeled, and never represented as a board connection.

Firmware BLE callbacks enqueue bounded commands; only the application loop touches AnimationManager/display. Process a bounded amount per loop; local input runs afterward so local presses win simultaneous remote requests (idle wins simultaneous local presses). Status reports final state after input/timeout. No pet-life ownership, persistence, cloud or bonding design is approved by this animation slice.

## GATT — Proposed v1 UUIDs

| Role | UUID | Properties |
| --- | --- | --- |
| Service | 7a6e0001-8c44-4db6-9f61-2b7d5300a101 | Advertised |
| Capabilities | 7a6e0002-8c44-4db6-9f61-2b7d5300a101 | Read |
| Command | 7a6e0003-8c44-4db6-9f61-2b7d5300a101 | Write with response |
| Status | 7a6e0004-8c44-4db6-9f61-2b7d5300a101 | Read + Notify |

Advertise service UUID; name XUNA in scan response if advertisement budget requires it. Match service/capabilities, not name or MAC alone. One active central. Connect inside app, without OS Settings pairing or bonding for this prototype; nearby devices can issue the two animation commands. This is not a production authorization model.

## Wire format — Proposed

Binary, little-endian multi-byte integers, exact lengths, no fragmentation; each value fits default ATT payload of 20 bytes. Binary requires documented codec tests, but avoids requiring larger MTU or JSON fragmentation.

- Capabilities (8 bytes): version u8=1; length u8=8; supported-command mask u16 (bit0=set_animation); animation mask u8 (bit0=idle, bit1=happy); flags u8 (bit0=status notify, bit1=connection-local dedup); happy duration u16=2400 milliseconds. Unknown capability bits ignored; unsupported version/required capability blocks commands.
- Command (8 bytes): version u8=1; opcode u8=1 (set_animation); request ID u32 (nonzero); animation u8 (0=idle,1=happy); reserved u8=0.
- Status (16 bytes): version u8=1; kind u8 (0=snapshot,1=result,2=state change); request ID u32 (0 for unsolicited); result u8; actual animation u8; state sequence u32; uptime milliseconds u32. Sequence increments on state transitions, not frames; wraps modulo 2^32. Result snapshot/state-change=0; command result reports applied/error plus current state. Successful happy may later expire independently.
- Result codes: 0=ok; 1=unsupported_version; 2=invalid_length; 3=unsupported_opcode; 4=invalid_argument; 5=busy; 6=request_id_conflict; 7=not_ready. If a malformed message lacks a recoverable ID, result ID=0; mobile treats it as diagnostic and pending request times out.

Validate exact size/version/opcode/nonzero ID/reserved byte/state before mutation; reject oversized writes without unbounded allocation. GATT write success only confirms transport receipt, not animation application. Application success requires matching result notification. No command if display initialization failed (not_ready).

One in-flight mobile request. Firmware keeps last 16 accepted command IDs/payloads/results during current connection: identical duplicate replays cached result without restarting happy; same ID/different payload returns conflict. Cache cleared on disconnect. IDs increase within connection; reconnect starts fresh IDs and clears pending requests. Dedup only guaranteed while entry retained in this connection; this is not durable exactly-once processing.

## Lifecycle — Proposed

- Scan 10 seconds; connect/discover/handshake deadline 10 seconds; individual GATT operation/result timeout 3 seconds. Cancel timers/subscriptions on dispose/disconnect/Bluetooth-off.
- Establish status subscription before commands; read capabilities and fresh status before ready. Serialize GATT operations. Notifications can be lost: on result timeout show outcome unknown, refresh status; no automatic resend of happy.
- Unexpected disconnect fails pending command and disables controls. Firmware keeps animation/button loop running and restarts advertising. User taps Reconnect: rescan, rediscover, resubscribe, reread; no stale command replay. No background auto-reconnect in v1. Explicit disconnect never reconnects automatically.
- Handle Bluetooth unsupported/off, permission denied, service mismatch and protocol mismatch with actionable UI. iOS needs NSBluetoothAlwaysUsageDescription; no Bluetooth background mode requested.

## Library assessment — Proposed, not build validation

| Option | Evidence / trade-off |
| --- | --- |
| Arduino 2.0.14 bundled BLE (preferred first experiment) | Present in pinned Espressif library; avoids new dependency/toolchain change. BLE/framework LGPL/upstream notices must be preserved. Measure heap/Flash/render/input after BLE; no invented resource figures. |
| NimBLE-Arduino 1.4.3 | Espressif-compatible BLE alternative, Apache-2.0 plus bundled notices. Upstream claims lower resources; these are not XUNA measurements. Consider only if baseline BLE has measured problems. Do not select latest 2.x without compatibility evaluation. |
| flutter_blue_plus 1.35.5 (preferred experiment) | Published archive declares Dart ^3.0.0 / Flutter >=3.7.0; BSD-3-Clause in this archive. Pin exact direct version; resolve and inspect transitive packages/license/native constraints before acceptance. Modern 2.x has a different license. Older pin trades current fixes for baseline compatibility; native build/physical testing remain required. |
| flutter_reactive_ble | BSD-3-Clause, Android/iOS reactive API. Published reactive_ble_mobile 5.5.0 requires Dart ^3.11.0/Flutter >=3.41.0; 5.6.0 requires Flutter >=3.44.0. Older 5.4 metadata uses SDK <3.0.0: evaluate Dart upper-bound compatibility behavior by isolated resolution if chosen. Do not upgrade entire Flutter base merely for BLE. |

Primary sources inspected: [Arduino pinned BLE](https://github.com/espressif/arduino-esp32/blob/2.0.14/libraries/BLE/library.properties), [NimBLE 1.4.3](https://github.com/h2zero/NimBLE-Arduino/blob/1.4.3/library.properties), [NimBLE license](https://github.com/h2zero/NimBLE-Arduino/blob/1.4.3/LICENSE), [FlutterBluePlus 1.35.5](https://pub.dev/packages/flutter_blue_plus/versions/1.35.5), [current FlutterBluePlus license](https://pub.dev/packages/flutter_blue_plus), [reactive BLE](https://pub.dev/packages/flutter_reactive_ble), published metadata/archive through pub.dev API. Do not infer native compatibility from Dart constraints alone.

## Experiments and acceptance

After approval: resolve pinned packages; run Flutter analyze, protocol/domain tests (malformed values, version/capability mismatch, correlation, duplicates/conflicts, timeout/disconnect/stale notifications) and simulator native build/UI fake tests. Run existing firmware host tests, add command/dedup tests, compile firmware. If native build fails, record concrete error before proposing tooling changes.

Physical acceptance requires a real iPhone/iPad: permission allow/deny, scan/connect, capabilities/status, idle/happy and 2.4s expiry, local buttons, duplicate not retriggering, invalid command rejection, disconnect/reconnect, Bluetooth off/on, board reset and restored advertising. Capture BLE heap/render/loop/stability diagnostics against M01 baseline. Physical BLE is pending until observed; build PASS is separate.

## Decisions requested

Approve bundled Arduino BLE + pinned FlutterBluePlus experiment; compact binary v1 above; foreground unbonded prototype with explicit reconnect; explicit simulator fake transport for UI only. These decisions do not approve pet-life state ownership or later milestones. Owner currently selected iOS simulator; real phone availability remains unresolved.

## Owner approval and simulator implementation — 2026-10-11

Owner approved the proposal, then requested simulator-first mobile delivery with commit/push. This authorizes mobile dev publication; root/firmware commits remain outside this delivery. Firmware BLE and real mobile transport are deferred to the next slice. The selected library is approved for an experiment, not yet installed or validated.

Implemented: feature-specific DeviceRepository/RequestAnimation contracts; SimulatorDeviceRepository; command codec/status validation; Home GetX binding/controller/UI with permanent SIMULATOR · FAKE BLE label. Scan/connect/idle/happy/2400ms expiry/disconnect/reconnect operate locally. Existing core/shared and dependency baseline preserved. Full status result correlation/capabilities/dedup/timeouts remain pending with physical transport.

Verification: Flutter analyze PASS; flutter test --reporter expanded PASS (4 tests: command layout/malformed input, status validation, fake lifecycle, widget scan/connect/happy/expiry/disconnect flow). Native simulator debug build PASS, Xcode build 63.6s. Initial CocoaPods failed due to non-UTF-8 locale; rerun with LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 succeeded without dependency/toolchain upgrade. Firmware not edited/tested/uploaded in this slice. Physical BLE and Android native validation remain pending.

Simulator launch: `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter run -d AF43981C-BF42-4F3A-B289-347DDF46B98E --debug` succeeded with Dart VM Service attached; Home screenshot inspected at temporary /tmp/xuna-m02-running.png. Direct simctl launch alone did not establish rendered Home; flutter run provided the observed evidence. Mobile delivered as `24026b2`, pushed to origin/dev, child working tree clean. Root docs/gitlink changes remain uncommitted.

## Superseding local MVP scope — 2026-10-11

Owner subsequently selected/approved local MVP through M05. Physical mobile repository and firmware BLE are now implemented; life/feedback/forget commands and bounded memory characteristics extend v1 additively. See [local MVP](MVP-local.md) for the current executable contract and acceptance; earlier proposal/simulator-only snapshots are historical. Physical iPhone end-to-end remains pending.

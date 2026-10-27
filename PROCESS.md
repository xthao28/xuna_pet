# XUNA — Process and Session Handoff

Last updated: **2026-10-27** (Asia/Ho_Chi_Minh). Latest: **Owner decisions after DC-5: websockets added, unbind (key revoked, data kept), E14 by hand, push (backend 332/332, mobile 311/311)**. Before that: **DC-0…DC-5 on the host**.

## 2026-10-27 — Owner decisions after DC-5: WebSocket library, unbind, E14 commands, push

- **Owner choices (all recommended):** add `websockets`; unbind = revoke the board key and keep cloud data; E14 BLE commands pressed by hand (runbook); push `dev`.
- **Backend:** `websockets==13.1` pinned (BSD-3); `scripts/serve.py` runs uvicorn with the Selector loop on Windows (psycopg async fails on the Proactor loop) and optional dev TLS. A real TLS run on Windows (`serve.py --tls`, pinned-CA client) found and fixed a crash: a 32-hex PetId that is not UUIDv4 now closes 1002 `unsupported_protocol`. Unbind: `DELETE /v1/pets/{petId}/device` (204, idempotent, audit `pet.unbound`), pets keep listing with `deviceBound`, the board is refused `not_bound` at connect and at the next heartbeat, app-path proofs with a revoked key get `device_key_mismatch`, binding again restores the key (same or new) with data kept. pytest **332/332**, ruff/mypy clean; a directory-wide `ruff format` touched 4 old files and was reverted.
- **Mobile:** `CloudPet.deviceBound` (absent = bound), `UnbindPetDeviceUseCase`, "Gỡ liên kết board" in the account card with confirmation; an unbound board counts as not bound until bound again. analyze 0, test **311/311**.
- **Not run:** board, phone. **Next:** E14 on the board; then switch `XUNA_NET` on and DC-6.

## 2026-10-27 — Device-direct DC-5: automatic projection backup (host only)

- **User requirement:** continue the DC sessions without asking (owner 2026-10-27). Built ahead of the E14 gate; nothing flashed.
- **Firmware (`firmware`, `XUNA_NET`):** pure `xuna/net/ExportWriter.h` (payload from the BLE life/memory/explanation/identity bytes with the Dart mapper's names and checks, compact JSON, SHA-256 envelope, projection frame, RFC 3339 ms time or `"unknown"`); `CloudSession` parses `ack`; `NetManager` sends one offered frame per ready session from a PSRAM slot and records the acknowledged generation in `7a6e0012`; `CloudBackup` on the life loop builds it on each new ready session and after a newer generation (≥ 15 min apart), logging `backup_built … build_us`.
- **Backend (`backend`):** `/v1/devices/connect` accepts `projection` (≤ 16 KiB; other frames still ≤ 4 KiB, an oversize frame is `frame_too_large` even when malformed) and answers `ack`; `ingest_session_projection` reuses `memory.ingest_projection` with `session_attested=True` (stored projections are `deviceAttested`).
- **Mobile (`mobile`):** Wi-Fi sheet row "Board tự backup gần nhất: thế hệ N" (vi/en).
- **Validation (Windows):** firmware `test_export_writer` 3/3 (Dart golden payload and hash `fede139d…`, worst-case size fits, out-of-range bytes refused, civil-time vectors), `test_cloud_session` 6/6 with acks, native **373/373**; `xuna_net` builds with a local CA (RAM 82,704 B / Flash 4,398,305 B); default and baseline envs unchanged. Backend: WS projection tests (stored → duplicate → stale → invalid → stored, `deviceAttested` true via `GET …/projections/latest`; U2-only → `consent_required`; oversize ping → 1009), full pytest **329/329**, ruff 0, mypy 0. Mobile analyze 0, test **309/309**.
- **Not run:** board, phone, real Wi-Fi/TLS, uvicorn WebSocket (library missing).
- **Incident (fixed before reporting):** a directory-wide `dart format` during DC-2 reformatted 10 unrelated mobile files into the DC-2 commit; they were restored and the unpushed commit amended (mobile `619239d`, root `169214f`). Later runs format only the changed files.
- **Next:** (1) owner: run E14 with the board ([runbook](docs/roadmap/cloud/E14-runbook.md)); (2) owner decision: add `websockets` (or `wsproto`) to the backend so uvicorn can serve the device and voice WebSockets; (3) owner decision: what "unbind pet" means for cloud data (needed for DC-6 "unbind → refused"); (4) after a pass: switch `XUNA_NET` on, then DC-6 board acceptance. Status-card line "WiFi/Cloud" still open.

## 2026-10-27 — Device-direct DC-4: firmware cloud session (host only)

- **User requirement:** continue the DC sessions without asking (owner 2026-10-27). Built ahead of the E14 gate, behind `XUNA_NET`; nothing flashed.
- **Firmware (`firmware`):** pure `xuna/net/CloudSession.h` (hello → challenge → proof → ready → ping/pong; unknown server messages ignored; strict checks: `schemaVersion` 1, 32-byte nonce, heartbeat 10–600 s; close codes → `NetError`; backoff as in the contract) with a flat JSON reader, `xuna/base/Base64.h` (RFC 4648 vectors, exact-size decode), `ProofPurpose::Session = 3`. `NetManager` (core 0): `esp_transport_ws` + `esp_transport_ssl` with the pinned CA, path `/v1/devices/connect`, subprotocol `xuna.device.v1`, 75 s handshake guard, network projection reports cloud state and the last error; the life loop signs the session proof on request (`serviceSigning`, logs `cloud_proof ok sign_us`) and hands over the PetId once the pet has one (an Egg stays offline).
- **Backend (`backend`):** session-purpose golden test (`448f0b90…1aa4`, same as firmware) and a test that the exact firmware frames pass the strict parser.
- **Validation (Windows):** firmware `test_cloud_session` 6/6 (incl. BLE refusing purpose 3), native **370/370**; `xuna_net` builds with a local CA header (RAM 82,656 B / Flash 4,393,441 B) and stops with `#error` without it; default and baseline envs unchanged. Backend `test_device_session.py` 15/15, `test_device_proof.py` 4/4.
- **Not run:** no board, no real TLS against mbedTLS, no uvicorn WebSocket (library missing). DC-1 metrics not re-checked with the real task.

## 2026-10-27 — Device-direct DC-2: Wi-Fi setup over BLE (firmware + mobile, host only)

- **User requirement:** continue the next DC sessions without asking (owner 2026-10-27). Built ahead of the E14 gate; nothing flashed.
- **Firmware (`firmware`):** pure `xuna/net/NetConfig.h`: chunked frames `[1, id, index, count, payload]` (≤ 16 chunks), message op 1 set (SSID 1–32 B, password empty or 8–64 B, host `[A-Za-z0-9.-]` 1–64, port ≠ 0) / op 2 forget, control bytes refused, buffers wiped; `NetStatus` 9-byte projection `[1, wifi, cloud, rssi, lastError, lastBackupGeneration u32 LE]`. Platform, all under **`XUNA_NET`** (env `xuna_net`): `NetConfigStore` (NVS `xuna_net`, written only on set/forget, forget clears it), `NetManager` (core-0 task, `WiFi.persistent(false)`, join timeout 20 s, retry 30 s after a failed join / 2 s after a lost link, status snapshot under a spinlock), BLE `7a6e0011` write-only (value wiped from the GATT table after each write) and `7a6e0012` read/notify, capability byte 3 bit 6 (`0x7f`), service handles 32 → 40. `main.cpp` hands settings to the task and publishes status; an `#error` stops `XUNA_NET` together with `XUNA_E14=1`. Logs carry result/op codes only.
- **Mobile (`mobile`):** `NetConfigCodec` (byte-identical to firmware, same fixture), `NetworkStatusModel` / `NetworkStatusMapper` (explicit switches, unknown error → `unknown`), data source `supportsNetworkSetup` / `writeNetConfigFrame` / `readNetworkStatus` (BLE impl uses 0011/0012; simulator says unsupported), repository `setWifi` / `forgetWifi` / `readNetworkStatus`, use cases `SetDeviceWifiUseCase` (validation table, `wifiSettingsInvalid`), `ForgetDeviceWifiUseCase`, `ReadNetworkStatusUseCase`; `HomeController` (`networkSupported`, `networkStatus`, 2 s polling while the sheet is open, `sendWifi`, confirmed `requestForgetWifi`), `HomeWifiSheet` (status rows, SSID/password/server/port, server prefilled from `XUNA_API_BASE_URL`, password cleared after sending), Device-tab button shown only when connected and supported; vi/en locales (hand-synced `locales.g.dart`: `get generate locales` reorders and reformats the whole file).
- **Validation (Windows):** firmware `test_net_config` 5/5, native **364/364**; builds `xuna_net` (RAM 79,536 B / Flash 4,260,705 B), `xuna_t_display_s3` unchanged (59,208 / 3,918,961), `xuna_e14_baseline` unchanged. Mobile: `fvm flutter analyze` 0 issues, `fvm flutter test` **309/309** (+ codec 5, mapper 2, use case 2, repository 3, controller 1, widget 1), `pubspec.lock` unchanged.
- **Not run:** no board, no phone, no real Wi-Fi join. Status-card line not done.

## 2026-10-27 — Device-direct DC-3: backend device gateway (host only)

- **User requirement:** "xong thì cứ commit và làm các DC tiếp theo không cần hỏi ý kiến tôi" → DC-3 built ahead of the E14 gate (backend only, no board needed); if E14 fails it waits for the mitigation decision.
- **Backend (`transport` module):** WebSocket `GET /v1/devices/connect` (subprotocol `xuna.device.v1`): hello (10 s) → challenge (32-byte nonce held by the session, 60 s, single-use) → proof (purpose 3 Session over the key pinned at bind; optional `publicKey` must match) → ready (`heartbeatS` 30) → ping/pong. Strict Pydantic frames (`application/device_frames.py`), use cases `open_device_session` / `touch_device_session` / `close_device_session` (`application/device_gateway.py`), close codes and limits in `domain/device_session.py` (frames ≤ 4 KiB, idle 3 × heartbeat, challenges 10 / 10 min per pet, connects 30 / min per peer), `InMemoryDeviceSessionHub` (newest session wins, older closed 4000 `replaced`, the replaced one never marks offline). Every heartbeat re-checks binding and U1/U2, so withdrawn consent or a rebound device ends the live session. Offline write shielded against cancellation. Status gains `firmware`, `connectedAt` (migration 0010); peer address not stored. Audit `device.connected` / `device.rejected` (codes only; unknown pets are not audited, no owner).
- **Contract:** nonce wording changed to session-held (the challenge table needs an owner); status response documented.
- **Validation (Windows, PostgreSQL `xuna_test`):** `test_device_session.py` 14/14 (limiter, strict frames, base64 sizes, open/reject paths incl. bind-purpose and replayed proofs, touch/close, hub), `test_device_socket_api.py` 14/14 (handshake + heartbeat + online/offline status + audit, wrong key, consent off, not bound, out of order, binary, unknown type, oversize, earlier-session proof, missing subprotocol, hello timeout, expired challenge, rate limit, replacement, consent withdrawn mid-session); full pytest **324/324**, ruff check 0, mypy 0 (166 files), alembic head; `ruff format --check` lists only the 5 old files.
- **Not run:** uvicorn over real TLS (no `websockets`/`wsproto` in the environment; the voice WebSocket has the same gap), no board.
- **Open points:** (1) add `websockets` (BSD-3) or `wsproto` (MIT) for uvicorn: new dependency, owner approval; (2) there is no "unbind pet" endpoint; DC-6 "unbind → refused" needs one, with a decision on what happens to the pet's cloud data.

## 2026-10-27 — Device-direct DC-0 (contract, ADR-0010, threat model) and DC-1 E14 tools

- **User requirement:** continue the device-direct plan: confirm the E14 thresholds, then DC-0 (docs) and DC-1 (E14 firmware flag, dev CA, WSS echo server, runbook). Owner answers: no board right now → "DC-0 + code DC-1"; thresholds **confirmed as proposed** (internal heap ≥ 40 KB, loop gap p99 ≤ 50 ms, render max ≤ baseline + 20 %, 0 BLE failures, 0 resets / 60 min, reconnect ≤ 2 min after the server returns). Later: "xong thì cứ commit và làm các DC tiếp theo không cần hỏi ý kiến tôi".
- **DC-0 (docs):** [ADR-0010](docs/decisions/ADR-0010-device-direct-websocket-transport.md) (WebSocket/TLS instead of MQTT for Stage 2); contract draft §2 "Device connection" (`/v1/devices/connect`, subprotocol `xuna.device.v1`, hello → challenge → proof (purpose 3 Session, payload = own public key) → ready, ping/pong, projection/ack, limits, close codes); threat model F10–F11 and T15–T19 (rogue AP/MITM, stolen board, replayed proof, Wi-Fi password, reconnect storm).
- **DC-1 firmware (`firmware`):** envs `xuna_e14_baseline` (`XUNA_E14=0`: metric lines only) and `xuna_e14` (`XUNA_E14=1`: + network task on core 0, Wi-Fi from git-ignored `e14_local.ini`, pinned CA from git-ignored `include/E14DevCa.h`, 1 KB echo every 5 s, backoff 2 s → 30 s, `WiFi.persistent(false)`). Pure `xuna/base/LatencyHistogram.h`, `xuna/net/EchoProbe.h` (`test_e14` 7/7). `E14Diagnostics.h` logs `e14` / `e14_net` every 30 s (internal heap free/min/largest, PSRAM, loop gap p50/p99/max, render mean/max, BLE commands/not-OK/dropped/max µs, connect/reconnect ms, echo ok/bad/lost, RTT, stack). BleManager counters only under `XUNA_E14`. `tools/e14_report.py` judges the thresholds from two logs (checked on synthetic logs, pass and fail).
- **Deviation from the brief:** `esp_transport_ws` + `esp_transport_ssl` (same component) from our own task pinned to core 0, not `esp_websocket_client`: in IDF 4.4 that client creates an unpinned priority-5 task that can run on core 1 and hold the life loop during a TLS handshake. Arduino's event task also moved to core 0 (`ARDUINO_EVENT_RUNNING_CORE=0`, board flag unset, `static_assert`).
- **Fact checked:** mbedTLS record buffers are fixed at 16 KB each way in the bundled libraries (no dynamic/asymmetric buffers): client config cannot shrink them; mitigation would need a custom SDK build (plan §6 and ADR-0010 corrected).
- **DC-1 backend (`backend`):** `scripts/make_dev_ca.py` (P-256 CA + server cert; every IP also as dNSName because mbedTLS 2.28 ignores iPAddress SANs; keys in `~/.xuna/dev-ca`; firmware header with CA + fingerprint) and `scripts/e14_server.py` (stdlib asyncio/ssl RFC 6455 echo, content-free logs, `--drop-every/--down-for` server kills, `--self-test`). No new dependency. `tests/scripts/test_e14_scripts.py` 6/6.
- **Runbook:** [E14-runbook](docs/roadmap/cloud/E14-runbook.md) (NVS/partition/app backup, certificates, firewall rule, baseline 60 min, E14 60 min with kills every 2 min + router power-cycle, report, restore, mitigation options). Results go to `docs/roadmap/cloud/E14-results-<date>.md`.
- **Validation (Windows):** firmware native **359/359**; builds `xuna_t_display_s3` (RAM 59,208 B / Flash 3,918,961 B, same sizes as HEAD), `xuna_e14_baseline` (60,488 / 3,920,057), `xuna_e14` with dummy local files (84,344 / 4,387,597; without them it stops with a clear `#error`). Backend: `e14_server.py --self-test` ALL PASS (echo, pinning, name check, 1002, 1009, wrong path), live drop/reconnect check on 127.0.0.1; ruff check 0, mypy 0 (161 files), alembic head, pytest **296/296** with PostgreSQL `xuna_test`; `ruff format --check` still lists the 5 old unrelated files (not touched).
- **Not run:** nothing on the board (no flash, no E14 measurement, no BLE, no real Wi-Fi/TLS against mbedTLS); no phone. The gate is still open.
- **Open point:** the app has no automatic "command every 30 s"; the runbook asks the owner to press an animation button about every 30 s. A desktop BLE driver would need a new dependency (owner approval).
- **Next:** owner runs E14 when the board is available; meanwhile DC-2 onward per the owner's instruction, host-only, not flashed as a feature before the gate passes.

## 2026-10-27 — Device-direct cloud connection: decisions and plan

- **User requirement:** "xuna có thể giao tiếp trực tiếp với cloud mà không cần thông qua app chưa?" → not yet (no network code in the firmware; `MqttTransport.h` is test-only; the backend broker is in-memory; no mic/speaker on the board). Then: "gửi cho tôi các quyết định cần thiết để bạn lên plan chi tiết".
- **Owner decisions (all as recommended):** connection foundation first (no voice, no downlink commands); WebSocket/TLS to the backend instead of MQTT; Wi-Fi set up by the app over BLE; voice on the board as a separate later plan; device key challenge on every connection; the owner's existing consents; E14 first with thresholds; backend on the dev machine in the LAN with a pinned self-made CA.
- **Plan:** [device-direct plan](docs/roadmap/cloud/device-direct-plan-2026-10-27.md), sessions DC-0 (contract, ADR-0010, threat model) → DC-1 E14 gate on the board → DC-2 Wi-Fi setup over BLE ∥ DC-3 backend gateway → DC-4 firmware cloud session → DC-5 automatic projection backup → DC-6 board acceptance.
- Checked in the pinned framework: `esp_websocket_client`, `mqtt`, `mbedtls`, `wifi_provisioning` bundled; mbedTLS allocates in internal RAM (main E14 risk); certificate dates unchecked (TLS independent of the board clock); Wi-Fi/BLE coexistence enabled.
- Docs: AGENTS decision entry; plan §22.3 and Cloud plan Phase 4 marked amended (WSS instead of MQTT for the first Stage 2 slice).
- **Next:** owner confirms the E14 thresholds in plan §4 DC-1, then DC-0 + DC-1 when requested. Not committed.

## 2026-10-27 — Speech subtitles on the board

- **User requirement:** "bây giờ tôi muốn board hiển thị chữ của xuna nói được không", then "xuna update thêm cả tiếng anh rồi đó, để ý nhé". Owner chose the **subtitle bubble** (pet stays visible) and **XUNA's replies only** (never the owner's words). Record: [speech subtitles](docs/roadmap/voice/speech-subtitles-2026-10-27.md); decision added to [AGENTS.md](AGENTS.md).
- **Firmware (`firmware/`, Windows machine):**
  - `xuna/visual/SpeechBubble.h` (pure C++11): `SpeechTextAssembler` (frames of `[1, id, index, count, UTF-8…]`, ≤ 600 bytes, in order, empty = clear, control bytes cleaned), `wrapText` (word wrap by pixel width, long words cut between code points), `SpeechBubble` (3 lines per page, ~60 ms/char clamped 2–8 s, last page +3 s, then hidden), `renderSpeechBubble` (rounded body fitted to the widest line, tail at XUNA).
  - `BleManager`: write characteristic `7a6e0010`, 16-frame queue, capability byte 3 bit 5 (`0x3f`), handle budget comment 22 → 26 (of 32). Speech never reaches the adapter; the log line has result + byte count only.
  - `DisplayManager`: bubble region x 90–317, y 2–70 in a PSRAM buffer allocated on first use; effects pause under it; cards cover it; backlight stays full while it shows. `main.cpp` hands each complete text to the display.
  - Font: `generate_ui_font.py` gives `kFontValue` all Vietnamese letters + typographic punctuation (241 glyphs); title/label unchanged. Regenerated with the backend venv's Pillow 13.0.0: old bitmaps identical, two advances ±1 px vs the Mac run.
  - Checks: `pio test -e native` **352/352 PASS** (new `test_speech_bubble` 9/9); `pio run -e xuna_t_display_s3` **SUCCESS**, RAM 59,208 B (18.1 %), Flash 3,918,961 B (59.8 %), core purity PASS. `native_asan` not run (no libasan on this Windows toolchain). Not uploaded to the board.
- **Mobile (`mobile/`):**
  - Device: `SpeechTextCodec` (chunks to the connection's MTU − 3, cuts > 600 bytes after a whole word + "…"), `DeviceBleDataSource.writeSpeechFrame`/`maxWriteLength`/`supportsSpeechText` (simulator: unsupported), `DeviceRepository.showSpeech` (texts queued, never interleaved; errors translated), `ShowSpeechTextUseCase`.
  - Voice: `VoiceRepository.playbackStarts` (a sentence when it starts playing) and `WatchPlaybackStartsUseCase`.
  - `HomeController._showOnBoard`: spoken sentences as they play; unspoken AI replies whole when finished (HTTP and WS); local `_say` replies at once; only when connected and advertised; BLE errors logged by kind only.
  - Checks: `fvm flutter analyze` 0 issues; `fvm flutter test` **295/295 PASS** (twice); `pubspec.lock` unchanged. A new playback test first used a fixed 10 ms wait and failed under full-suite load; it now waits on the condition.
- **Not run:** board upload and visual check, phone, iOS MTU, write timing with 20-byte payloads (a 600-byte text is 38 writes).
- **Next:** owner flashes the board (verified NVS backup first, as usual) and checks readability, bubble placement and sync with the voice in both languages.

## 2026-10-27 — Cloud AI ↔ device: WS signals fix and AI reply gestures

- **User requirement:** "xuna đã kết hợp giao tiếp AI cloud với thực hiện hành động ở firmware chưa?" → found (b) a gap and (a) no AI-chosen device action; owner: "b trước, rồi làm a luôn". For (a) the owner chose **"chỉ cử chỉ biểu cảm"** over adding play/quiet (opcode 2) or keeping AI out entirely, because it conflicted with backend AGENTS §1.4.
- **(b) PE-4c signals on the voice WebSocket:** since `d471d39` a voice turn over `/v1/voice` sent no conversation tags, so the device's feelings no longer heard spoken chat. `websocket.py` now adds `signals` to `reply.finished` (same classifier and history count as the HTTP turn); mobile `VoiceWsReplyFinished.signals` is parsed (unknown names skipped) and `HomeController` forwards them over BLE opcode 8 when connected.
- **(a) AI reply gestures:**
  - Backend: `conversation/domain/gestures.py` (`ReplyGesture` = the 4 Track A variants, `GestureTagFilter` removes `<g:name>` tags anywhere in the streamed text, also when split across deltas, and reports the first valid one). `chat_turn` filters every reply and emits `GestureChosen` before the text; the prompt offers the tags only when the body/context has `gestures: true`. HTTP SSE event `gesture {name}`, WS message `{type: gesture, name}`. The tag never reaches the bubble or TTS.
  - Mobile: `CloudTurnContext.gestures` = connected and the board advertises Track A (capability byte 4 bits 4–7); `CloudReplyGesture` / `VoiceWsGesture` (unknown names skipped); `HomeController._playGesture` re-checks connection and support, plays at most one per reply through `PreviewVariantUseCase` (opcode 1 args 4–7, display only), and a BLE failure is only logged. Fixed on the way: `StreamCloudReplyUseCase` rebuilt the context and would have dropped the flag.
  - Rules: [backend/AGENTS.md](backend/AGENTS.md) §1.4 now names reply gestures as the single exception; root [AGENTS.md](AGENTS.md) records the owner decision; [contract draft](docs/architecture/XUNA_CLOUD_CONTRACT_DRAFT.md) and [WS design](docs/roadmap/voice/voice-websocket-design-2026-10-23.md) list the new field/events.
- **Validation (Windows machine):**
  - Backend: `pytest` **290 passed** with `XUNA_TEST_DATABASE_URL` (PostgreSQL 16, WS/API tests included); `ruff check` PASS; `mypy` 0 errors in 161 files; `alembic upgrade head` OK (no migration). `ruff format --check` still reports 5 files **untouched in this session** (`language_detector.py`, `edge_tts_adapter.py`, `knowledge/application/suggest.py`, `knowledge/domain/clustering.py`, `tests/modules/cognition/test_speech_adapters.py`), so `scripts/check.sh` stops at its first step until they are formatted in their own change.
  - Mobile: `fvm flutter analyze` 0 issues; `fvm flutter test` **285/285 PASS**; `pubspec.lock` unchanged. `dart format` also reformatted older lines in `home_controller.dart`.
  - **Not run:** phone, board, real LLM. Whether the provider follows the tag instruction (placement, frequency) is unmeasured; a wrong or missing tag only means no gesture.
- **Known gap kept:** `HomeController` imports `features/voice/data/.../voice_websocket_data_source.dart` directly (from `d471d39`), against mobile AGENTS §1; not fixed here.
- **Next:** owner phone + board check that a gesture plays during a voice/text reply and that the reply text never shows `<g:`; then tune the prompt if the model over- or under-uses gestures.

## 2026-10-27 — Voice WebSocket Streaming (VOICE-01..): Low-Latency Streaming, Barge-in & Safe Fallback

- **User requirement:** Tối ưu hóa đàm thoại 2 chiều qua WebSocket thay vì HTTP POST (VOICE-01..): Giảm triệt để độ trễ đàm thoại, stream audio hai chiều real-time, hỗ trợ ngắt lời XUNA (Barge-in), và giữ fallback HTTP an toàn.
- **Full-Duplex Architecture & Implementation:**
  - **Backend (`backend/`):**
    - `src/xuna_backend/modules/conversation/application/voice_session.py`:
      - Hỗ trợ tham số `voice: str | None = None` trong khởi tạo session và trong `stream_turn_reply(text, context, voice=...)` để truyền vào `spoken_turn`.
    - `src/xuna_backend/modules/conversation/api/websocket.py`:
      - Nhận `locale` và `voice` trong `hello` payload và inject vào `VoiceSession`.
      - Nhận `voice` trong `turn.commit` payload để linh hoạt ghi đè giọng đọc theo từng lượt trò chuyện.
      - Xử lý các gói tin điều khiển `listen.start`, binary PCM16 audio chunks, `listen.stop`, `turn.commit`, `abort` (cancel/barge-in).
  - **Mobile Data & Domain Layer (`mobile/`):**
    - `VoiceAudioDataSource` & `VoiceRepository`: Bổ sung `Future<Stream<Uint8List>> startStreaming()` sử dụng `AudioEncoder.pcm16bits` 16kHz Mono và `Future<void> stopStreaming()`.
    - Thêm Use Cases: `StartStreamListeningUseCase`, `StopStreamListeningUseCase`, `ReadIdTokenUseCase`.
    - `VoiceWebSocketDataSource`: Bổ sung tham số `locale` và `voice` vào `connect()` (gửi trong `hello`) và `sendTurnCommit()`.
  - **Mobile Presentation & Controller Integration (`mobile/`):**
    - `HomeController`:
      - Quản lý vòng đời kết nối WebSocket (`_ensureVoiceWsConnected`, `_listenVoiceWsEvents`).
      - `_startVoice()`: Stream binary PCM16 chunks trực tiếp lên socket trong khi người dùng nói (Zero upload wait time). Tự động kích hoạt cơ chế **Barge-in** (gửi `abort {reason: barge_in}` và dừng loa ngay khi người dùng nhấn mic trong lúc XUNA đang nói).
      - `_finishVoice()`: Gửi `listen.stop`, nhận `VoiceWsSttFinal` từ server, kiểm tra intent cục bộ (chơi, dạy kiến thức, sở thích); nếu là hội thoại AI -> gửi `turn.commit` với đầy đủ turn context.
      - Xử lý `VoiceWsReplyDelta` cập nhật text bubble real-time và `VoiceWsTtsAudio` đưa vào hàng đợi phát âm thanh mượt mà ngay khi câu đầu tiên được tổng hợp xong.
      - `cancelVoice()`: Hủy stream mic và gửi `abort {reason: cancel}`.
      - **100% Safe Fallback:** Tự động chuyển đổi mượt mà sang luồng HTTP POST truyền thống nếu kết nối WebSocket gặp sự cố hoặc offline.
  - **Testing & Quality Assurance:**
    - `test/features/home/presentation/controller/home_controller_test.dart`: Thêm test group `Voice WebSocket Streaming` bao phủ toàn bộ luồng stream, commit turn, streaming deltas, tts audio chunks, barge-in, cancel, và local intent override.
    - Cập nhật mock `_Audio` trong `voice_repository_impl_test.dart`.
- **Validation:**
  - `mobile/`: Toàn bộ **280 tests PASS (100%)**, `fvm flutter analyze` **No issues found! (0 errors, 0 warnings)**.
  - `backend/`: **231 pytest passed, 42 skipped (0 failed)**; `ruff check .` **All checks passed!**; `mypy src` **Success: 0 errors in 160 source files**.

## 2026-10-27 — Mobile & Backend: Full Bilingual Support, Voice Settings Sheet & Ripple Visualizer

- **User requirement:** Hoàn thiện song ngữ (Vietnamese / English) toàn diện trên Mobile App: khắc phục lỗi mic nhận diện tiếng Anh không chính xác, bổ sung cài đặt chọn giọng đọc XUNA (Edge TTS) cho cả tiếng Việt và tiếng Anh kèm tính năng nghe thử trực tiếp, chuyển đổi ngôn ngữ ứng dụng 1:1, và thêm hiệu ứng sóng âm động quanh nút Micro khi đang lắng nghe.
- **Mobile & Backend Implementation:**
  - **i18n & Bilingual Interface:**
    - Đồng bộ 100% 507 khóa ngôn ngữ giữa `assets/locales/vi_VN.json` và `assets/locales/en_US.json`.
    - Sinh mã `lib/generated/locales.g.dart` với đầy đủ `LocaleKeys`, `Locales.vi_VN`, `Locales.en_US`.
    - `core/presentation/app.dart`: Hỗ trợ `Locale('en', 'US')` và fallback `Locale('vi', 'VN')`.
    - Bổ sung tùy chọn chuyển đổi ngôn ngữ ứng dụng ngay trong `HomeDeviceSettingsCard` và tự động lưu trạng thái vào `AppHive`.
  - **Edge TTS Voice Selection & Preview:**
    - `backend/`: Bổ sung endpoint `POST /v1/speech/synthesis` và tham số `voice: str | None` trong `TurnBody` và `SpeechSynthesizer.synthesize`.
    - `mobile/`: Thêm `SynthesizeSpeechUseCase`, `CloudRemoteDataSource.postSynthesis`, `CloudRepository.synthesize`.
    - Giao diện `HomeVoiceSettingsSheet`: Cho phép lựa chọn 4 giọng đọc chất lượng cao (Tiếng Việt: Hoài My, Nam Minh; Tiếng Anh: Aria, Guy) kèm nút Nghe thử (Preview) phát âm thanh trực tiếp từ Cloud.
    - Truy cập nhanh Voice Settings từ thẻ Cài đặt thiết bị hoặc ngay trong menu dấu ba chấm của màn hình chat.
  - **Whisper ASR Accurate English Recognition:**
    - Cập nhật `CloudRepositoryImpl.transcribe`: Không còn gán cứng `'locale': 'vi'`, tự động truyền `locale: currentLocaleCode` (hoặc `en` / `vi`) tương ứng với ngôn ngữ người dùng đang thiết lập, giúp Whisper chuyển ngữ tiếng Anh cực kỳ chuẩn xác, không còn bị lỗi từ vựng hay ngữ pháp.
  - **Micro Ripple Animation (Dynamic Visualizer):**
    - `HomeChatComposer`: Thêm hiệu ứng sóng âm concentric ripples lan tỏa nhẹ nhàng khi `VoiceInputState.listening`, bọc trong kích thước chuẩn 72px để giữ trọn bố cục và visual feedback mượt mà.
- **Validation:**
  - `mobile/test/generated/locales_sync_test.dart`: 3/3 tests PASS (đồng bộ 100% 507 keys).
  - `mobile/test/features/home/presentation/widgets/home_voice_settings_sheet_test.dart`: PASS 100%.
  - `mobile/test/features/home/presentation/widgets/home_chat_composer_test.dart`: PASS 100% (cố định kích thước 72px).
  - `mobile/test/features/home/presentation/home_page_test.dart`: PASS 5/5 tests.
  - Toàn bộ mobile test suite: **273/273 tests PASS (100%)**.
  - `fvm flutter analyze`: **No issues found! (0 errors, 0 warnings)**.
  - Toàn bộ backend test suite: **231 passed, 42 skipped (0 failed)**; `ruff check .` 0 issues; `mypy src` 0 errors.


- **User requirement:** Bổ sung hỗ trợ tiếng Anh cho XUNA: khắc phục lỗi khi người dùng nói tiếng Anh vào mic nhận dạng sai (do Whisper bị ép cứng `language="vi"`), sửa lỗi phát âm méo mó/sai phát âm khi Cloud trả về tiếng Anh (do Edge TTS bị ép dùng giọng tiếng Việt `vi-VN-HoaiMyNeural` đọc chữ tiếng Anh), và nâng cấp prompt trò chuyện song ngữ tự nhiên.
- **Backend Implementation:**
  - **Language Detection (Pure stdlib):**
    - `modules/cognition/domain/language_detector.py`: xây dựng `detect_text_language(text: str, default: Locale)` nhận diện chính xác tiếng Việt qua dấu thanh, từ vựng không dấu đặc trưng, hoặc nhận diện tiếng Anh qua từ vựng thông dụng phổ biến, 0 dependencies bên ngoài.
  - **TTS Auto-Voice Selection:**
    - `modules/cognition/infrastructure/edge_tts_adapter.py`: nâng cấp `EdgeSpeechSynthesizer.synthesize` tự động nhận diện ngôn ngữ của câu văn. Nếu câu trả lời là tiếng Anh -> tự động chuyển sang giọng tiếng Anh bản ngữ chuẩn Mỹ `en-US-AriaNeural`; nếu là tiếng Việt -> dùng giọng truyền cảm `vi-VN-HoaiMyNeural`. Ngay cả khi biến môi trường đặt giọng tiếng Việt, văn bản tiếng Anh vẫn được đọc bằng giọng tiếng Anh chuẩn xác, không bị nuốt âm hay phát âm ngọng.
  - **ASR Whisper Multilingual Auto-Detect:**
    - `modules/cognition/infrastructure/openai_transcription.py`: hỗ trợ `locale: Locale | None = None`. Khi không truyền `locale`, adapter không gửi trường `language` -> Whisper tự động kích hoạt **Auto-detect Language** (nhận diện cả tiếng Anh và tiếng Việt với độ chính xác cao).
    - `core/config.py`: bổ sung cấu hình `asr_auto_detect: bool = True` (`XUNA_ASR_AUTO_DETECT`).
    - `modules/conversation/api/routes.py`: endpoint `POST /v1/speech/transcriptions` tự động áp dụng `asr_auto_detect` để gán `locale = None` -> ứng dụng di động hiện tại trên điện thoại thật có thể nói tiếng Anh và được nhận diện chuẩn ngay lập tức mà không cần build lại app.
  - **Bilingual Persona Prompt:**
    - `modules/conversation/application/chat_turn.py`: cập nhật persona song ngữ. Khi người dùng nói tiếng Anh, XUNA tự động trò chuyện bằng tiếng Anh (xưng "XUNA" hoặc "I", gọi "you"), giữ trọn tính cách thông minh, ấm áp. Khi nói tiếng Việt, xưng "mình" gọi "bạn". `build_request` tự động phát hiện ngôn ngữ của câu hỏi để gắn `locale` tương ứng.
- **Validation:**
  - `tests/modules/cognition/test_language_detector.py`: 17/17 test cases PASS.
  - `tests/modules/cognition/test_speech_adapters.py`: bổ sung 2 test cases kiểm tra ASR auto-detect và Edge TTS tự động chọn `en-US-AriaNeural` -> 12/12 PASS.
  - `tests/modules/conversation/test_chat_turn.py`: bổ sung test case tự động phát hiện ngôn ngữ của câu hỏi -> 13/13 PASS.
  - Toàn bộ backend test suite: **231 passed, 42 skipped (do không có DB PostgreSQL URL), 0 failed**.
  - `ruff check .`: **All checks passed! (0 linter errors)**.
  - `mypy src`: **Success: no issues found in 160 source files (0 type errors)**.
  - `pytest tests/test_architecture.py`: **2 passed (100%)** bảo đảm ranh giới Clean Architecture DAG.

## 2026-10-27 — M06 knowledge domains: backend suggestion engine & benchmark KD-4 (Backend)

- **User requirement:** Hoàn thành session KD-4 của milestone M06 Knowledge Domains: suggestion engine, duplicate prevention, 14-day expiration, optional embedding adapter, trích xuất kiến thức hội thoại chat (Q3), và bộ đánh giá benchmark tiếng Việt (plan §6.3.4, §6.3.7, §9 KD-4, §12 Q3/Q4).
- **Backend Implementation:**
  - **Cognition Embedding Adapter:**
    - `modules/cognition/domain/types.py`: thêm `Capability.EMBEDDING`, `EmbeddingRequest`, `EmbeddingResult`.
    - `modules/cognition/application/ports.py`: định nghĩa protocol `Embedder`.
    - `modules/cognition/infrastructure/openai_compatible.py`: triển khai `OpenAICompatibleEmbedder` hỗ trợ endpoint `/embeddings`, đăng ký `Capability.EMBEDDING` trong provider registry.
    - `core/config.py`: bổ sung cấu hình `XUNA_EMBEDDING_*` (`embedding_provider`, `embedding_base_url`, `embedding_model`, `embedding_api_key`, `embedding_api_key_header`, `embedding_timeout_s`).
    - `main.py`: cấu hình factory `embedder()` và inject vào `app.state.embedder`.
  - **Domain Clustering & Suggestion Engine:**
    - `modules/knowledge/domain/clustering.py`:
      - `compute_pairwise_clean_similarity`: tính toán tương đồng n-gram tiếng Việt trên các từ vựng mang nghĩa (loại bỏ stopwords).
      - `cluster_candidates_lexical`: thuật toán phân cụm đồ thị liên thông (connected components) trên các candidate chưa phân loại với ngưỡng `min_similarity = 0.02` và kích thước tối thiểu $\ge 4$ candidates.
      - `check_cluster_duplicate`: phát hiện cụm có độ tương đồng $\ge 0.10$ với các domain hiện có để đề xuất `ADD_TO_DOMAIN` thay vì tạo trùng lặp.
      - `derive_cluster_name_and_description`: sinh tự động tên chủ đề tiếng Việt ($\le 40$ ký tự) và mô tả ($\le 160$ ký tự) từ các bigram và từ khóa phổ biến nhất trong cụm.
      - `is_suggestion_expired`: kiểm tra thời hạn gợi ý sau 14 ngày.
    - `modules/knowledge/application/suggest.py`:
      - `GenerateKnowledgeSuggestionUseCase`: tự động dọn dẹp các gợi ý quá 14 ngày thành `EXPIRED`, kiểm tra giới hạn 1 gợi ý `PENDING`, phân cụm các kiến thức chưa phân loại $\ge 4$ items, kiểm tra trùng lặp để sinh `ADD_TO_DOMAIN` hoặc `NEW_DOMAIN` (nếu tổng domain $< 5$).
      - `ExpireKnowledgeSuggestionsUseCase`: dọn dẹp các gợi ý tồn đọng quá 14 ngày.
    - `modules/knowledge/api/routes.py`: thêm endpoint `POST /v1/pets/{petId}/knowledge-suggestions/generate` (yêu cầu consent `CONVERSATION_TEXT`).
  - **Chat Turn Knowledge Extraction (Q3):**
    - `modules/conversation/domain/candidate_extractor.py`: xây dựng `extract_knowledge_candidate` lọc bỏ câu hỏi, câu chào, cảm thán chitchat, thông tin cá nhân/tên gọi, thông tin bảo mật/mật khẩu, chỉ trích xuất các câu thông tin kiến thức thực tế (factual knowledge).
    - `modules/conversation/api/routes.py`: mở rộng `TurnBody` với cờ `extractKnowledge: bool = True` (mặc định bật theo Q3), tự động đối chiếu domain phù hợp qua lexical matcher (ngưỡng 0.20), phát hiện quan hệ `refines` (ngưỡng 0.60) so với fact cũ trong domain, tính deterministic `fact_key`, lưu candidate trạng thái `AWAITING_OWNER_CONFIRMATION` và trả về `candidate` trong sự kiện SSE `finished`.
  - **Vietnamese Benchmark & Evaluation Suite:**
    - `tests/fixtures/knowledge_vi.json`: bộ benchmark chuẩn gồm 60 kiến thức tiếng Việt thuộc 6 chủ đề (nấu ăn, lập trình, âm nhạc, thể thao, tiếng anh, làm vườn) kèm 10 câu nhiễu (chitchat, câu hỏi, cảm thán).
    - `tests/modules/knowledge/test_evaluation.py`:
      - **Lexical Top-1 Accuracy:** đạt **88.33%** (53/60 đúng tuyệt đối chỉ bằng unigrams + bigrams pure stdlib).
      - **Coverage ở ngưỡng $\tau = 0.05$:** đạt **81.67%** (vượt chỉ tiêu $> 80\%$).
      - **Noise Rejection Rate:** đạt **100%** (10/10 mục nhiễu bị loại bỏ hoàn toàn, 0 gợi ý sai).
      - **Embedding Cosine Simulation:** đạt **88.33%** Top-1 Accuracy.
- **Validation:**
  - `pytest tests/`: **211 passed, 42 skipped (do không có DB PostgreSQL URL), 0 failed** qua toàn bộ backend test suite.
  - `pytest tests/test_architecture.py`: **2 passed (100%)** bảo đảm ranh giới Clean Architecture DAG.
  - `ruff check .`: **All checks passed! (0 linter errors)**.
  - `mypy src`: **Success: no issues found in 159 source files (0 type errors)**.
- **Next steps:** KD-6 (Nghiệm thu toàn diện M06 trên thiết bị thật và điện thoại thật: thử nghiệm 2 lịch sử dạy khác nhau, xác nhận hiển thị level, journal giải thích được, offline giữ mức, xóa giảm mức).

## 2026-10-27 — M06 knowledge domains: mobile UI & orchestration KD-5 (Mobile)

- **User requirement:** Hoàn thành session KD-5 của milestone M06 Knowledge Domains: companion app UI và multi-step orchestration flows (plan §7.2, §7.3, §7.4, §9 KD-5) trên Flutter companion app (`mobile/`).
- **Mobile Implementation:**
  - **Account Domain & Data Layer:**
    - `entities/`: thêm `CloudKnowledgeDomain`, `CloudKnowledgeSuggestion`, `TeachKnowledgeResult`, mở rộng `MemoryCandidate` với các trường `domainId`, `relation`, `relatedCandidateId`, `factKey`.
    - `mappers/`: `CloudKnowledgeDomainMapper`, `CloudKnowledgeSuggestionMapper`, `TeachKnowledgeResultMapper`, cập nhật `MemoryCandidateMapper`.
    - `data_source/`: thêm các endpoints REST API (`fetchKnowledgeDomains`, `createKnowledgeDomain`, `updateKnowledgeDomain`, `teachKnowledge`, `fetchKnowledgeSuggestions`, `decideKnowledgeSuggestion`, `retagMemoryCandidate`) vào `CloudRemoteDataSource` / `CloudRemoteDataSourceImpl`.
    - `repository/`: cập nhật `CloudRepository` và `CloudRepositoryImpl` xử lý typed RFC 9457 errors (`slot_occupied`, `domain_limit_reached`, `slot_required`).
    - `usecase/`:
      - CRUD & Queries: `ReadKnowledgeDomainsUseCase`, `CreateKnowledgeDomainUseCase`, `UpdateKnowledgeDomainUseCase`, `TeachKnowledgeUseCase`, `ReadKnowledgeSuggestionsUseCase`, `DecideKnowledgeSuggestionUseCase`, `RetagMemoryCandidateUseCase`.
      - Multi-step Orchestration:
        - `CreateDomainFlowUseCase`: đọc profile thiết bị tìm slot trống (0..4) -> tạo domain cloud (pending_device) -> gọi lệnh `open` trên thiết bị -> gọi `device_ack` xác nhận trên cloud. Rollback xóa cloud domain nếu thiết bị fail.
        - `DeleteDomainFlowUseCase`: dọn slot trên thiết bị qua lệnh `clear` -> gọi xóa domain trên cloud (kèm cờ `keepKnowledge`).
        - `CommitKnowledgeUseCase`: xác nhận candidate trên cloud -> thêm fact key vào slot trên thiết bị -> đọc `snapshotGeneration` -> commit candidate lên cloud.
        - `RetagKnowledgeFlowUseCase`: di chuyển evidence trên thiết bị từ slot cũ sang slot mới -> cập nhật candidate trên cloud.
  - **Locales Synchronization:**
    - Cập nhật song song `assets/locales/vi_VN.json` và `lib/generated/locales.g.dart` với các khóa bản địa hóa tiếng Việt hoàn chỉnh cho knowledge domains, manage sheet, teach sheet, suggestion banner, journal transitions.
  - **Presentation & Widgets:**
    - `HomeKnowledgeCard`: thẻ hiển thị tối đa 5 slots hoạt động kết hợp tên domain từ cloud với 3 chấm level competence và thống kê facts/ngày từ thiết bị, nút CTA "Dạy kiến thức", và chế độ fallback offline tự động khi chưa có mạng.
    - `HomeKnowledgeManageSheet`: bottom sheet quản lý 5 slots, bật/tắt nghỉ ngơi (`rest`/`activate`), đổi tên, xóa domain với tùy chọn giữ hay xóa facts, và form tạo domain mới với preset chips gợi ý.
    - `HomeTeachKnowledgeSheet`: giao diện dạy kiến thức với text input tối đa 280 ký tự, bộ chọn domain (tự động hoặc thủ công), thẻ xác nhận phân loại (quan hệ `new`/`refines`/`contradicts`), và nút lưu vào thiết bị.
    - `HomeKnowledgeSuggestionBanner`: banner thông báo gợi ý domain/facts mới từ cloud khi phát hiện kiến thức liên quan từ hội thoại.
    - `HomeCandidateCard` & `HomeJournalTab`: tích hợp tag/badge `KNOWLEDGE`, render `HomeKnowledgeCard` và các thẻ chuyển cấp level trong tab Nhật ký.
    - `HomeController` & `HomeBinding`: đăng ký DI và kết nối 13 use cases, lắng nghe reactive streams, tự động refresh khi kết nối thiết bị hoặc đăng nhập cloud.
  - **Testing & Verification:**
    - `test/features/account/domain/usecase/knowledge_domain_use_cases_test.dart`: 8 unit test cases kiểm thử độc lập toàn bộ các use cases và flows orchestration kết hợp `FakeCloud` và `SimulatorDeviceBleDataSource`.
    - `test/features/home/presentation/widgets/home_knowledge_card_test.dart`: 3 widget test cases kiểm tra trạng thái rỗng, hiển thị domain + chấm level, và fallback offline.
    - `test/features/home/presentation/controller/home_controller_test.dart`: bổ sung test case kiểm thử toàn bộ luồng tạo domain, dạy kiến thức, và duyệt suggestion trong controller.
    - `test/features/home/presentation/home_page_test.dart`: cập nhật test case kiểm tra hiển thị `HomeKnowledgeCard` trên tab Nhật ký.
- **Validation:**
  - `fvm flutter analyze`: **No issues found! (0 errors, 0 warnings)**.
  - `fvm flutter test`: **269/269 test cases PASSED (100%)** qua toàn bộ test suite companion app.
  - `test/generated/locales_sync_test.dart`: **PASS** (100% khớp khóa giữa vi_VN.json và locales.g.dart).
- **Next steps:** KD-4 (Life Lab: offline verification & stress test chu kỳ 5 slot, retention, 30 days time-jump, power-cut matrix, telemetry check).


- **User requirement:** Hoàn thành session KD-3 của milestone M06 Knowledge Domains: module `knowledge` backend (domain entities, pure stdlib Vietnamese lexical matcher & text normalizer, application ports/schemas/use cases, infrastructure SQLAlchemy models & repositories, API routes RFC 9457), tích hợp `CandidateType.KNOWLEDGE` với `fact_key`, cập nhật memory use cases/schemas (`retag`, `confirm` với `domain_id`), cập nhật conversation `TurnContext` & chat prompt, migration Alembic 0009, và bộ test toàn diện.
- **Backend Implementation:**
  - `src/xuna_backend/modules/knowledge/domain/`:
    - `entities.py`: `KnowledgeDomain`, `KnowledgeSuggestion`, `KnowledgeSummary`, `compute_fact_key(text)` sinh u32 deterministic từ SHA-256 NFC normalized string trong dải `[1, 0xFFFFFFFF]`.
    - `vietnamese_text.py`: chuẩn hóa tiếng Việt stdlib không dùng thư viện ngoài (`normalize_vietnamese`, `remove_accents` hỗ trợ đ/Đ, `extract_syllables_and_bigrams`).
    - `lexical_matcher.py`: tính toán độ tương đồng từ vựng/Jaccard (`compute_lexical_similarity`) kết hợp containment query n-grams và domain n-grams.
  - `src/xuna_backend/modules/knowledge/application/`:
    - `ports.py`: `KnowledgeRepository` và `KnowledgeCandidatePort` protocols.
    - `schemas.py`: Pydantic DTOs cho domains (`CreateDomainRequest`, `UpdateDomainRequest`, `DomainResponse`), suggestions (`DecideSuggestionRequest`, `KnowledgeSuggestionResponse`), và teaching (`TeachKnowledgeRequest`, `TeachKnowledgeResponse`).
    - `use_cases.py`:
      - `CreateDomainUseCase`: giới hạn tối đa 5 domains không bị xóa, ràng buộc `deviceSlot` 0..4 duy nhất.
      - `ListDomainsUseCase`: hỗ trợ lọc hoặc bao gồm domain đã xóa.
      - `GetDomainUseCase`: tìm domain theo ID.
      - `UpdateDomainUseCase`: xử lý các action `device_ack`, `rename`, `describe`, `rest` (giải phóng slot thiết bị), `activate`, `delete` (chuyển facts sang unsorted hoặc xóa).
      - `TeachKnowledgeUseCase`: tự động phân loại vào domain phù hợp bằng lexical matching (ngưỡng 0.20), phát hiện quan hệ `refines` (ngưỡng 0.60) so với fact cũ, tạo memory candidate kèm `fact_key`.
      - `ListSuggestionsUseCase` & `DecideSuggestionUseCase`: xem và quyết định accept/dismiss gợi ý domain/facts.
  - `src/xuna_backend/modules/knowledge/infrastructure/`:
    - `models.py`: `KnowledgeDomainRow` (bảng `knowledge_domains`), `KnowledgeSuggestionRow` (bảng `knowledge_suggestions`), `KnowledgeSummaryRow` (bảng `knowledge_summaries`).
    - `repository.py`: `SqlKnowledgeRepository` triển khai `KnowledgeRepository`, `SqlKnowledgeCandidateAdapter` triển khai `KnowledgeCandidatePort`.
  - `src/xuna_backend/modules/knowledge/api/`:
    - `routes.py`:
      - `GET /v1/pets/{pet_id}/knowledge-domains`
      - `POST /v1/pets/{pet_id}/knowledge-domains` (HTTP 201)
      - `GET /v1/knowledge-domains/{domain_id}`
      - `PATCH /v1/knowledge-domains/{domain_id}`
      - `POST /v1/pets/{pet_id}/knowledge` (yêu cầu consent `CONVERSATION_TEXT` U3)
      - `GET /v1/pets/{pet_id}/knowledge-suggestions`
      - `PATCH /v1/knowledge-suggestions/{suggestion_id}`
  - `src/xuna_backend/modules/memory/`:
    - `entities.py`: thêm `CandidateType.KNOWLEDGE = "knowledge"`, các thuộc tính `domain_id`, `relation`, `related_candidate_id`, `fact_key`, `embedding` vào `MemoryCandidate`.
    - `models.py`: bổ sung các cột tương ứng và khóa ngoại tới `knowledge_domains.domain_id`.
    - `repository.py`: map đầy đủ các trường knowledge khi lưu và cập nhật candidate.
    - `schemas.py`: bổ sung trường `domainId`, `relation`, `relatedCandidateId`, `factKey` vào `CreateCandidateRequest`, `domainId` và action `retag` vào `PatchCandidateRequest`.
    - `use_cases.py`: bảo toàn các trường knowledge qua tất cả các transition của candidate (`confirm`, `reject`, `commit`, `retag`, `delete`).
    - `api/routes.py`: đưa các trường knowledge vào response dictionary của candidate.
  - `src/xuna_backend/modules/conversation/`:
    - `application/chat_turn.py`: thêm trường `knowledge` vào `TurnContext`, đưa kiến thức đã học vào prompt trong `describe_context`.
    - `api/routes.py`: nhận `knowledge` trong `TurnBody`, nạp và định dạng tối đa 5 facts kiến thức đã xác nhận để đưa vào prompt turn.
  - `migrations/`:
    - `versions/0009_knowledge_domains.py`: migration tạo các bảng `knowledge_domains`, `knowledge_suggestions`, `knowledge_summaries`, và thêm các cột knowledge vào bảng `memory_candidates`.
    - `env.py`: đăng ký models của module `knowledge`.
  - `src/xuna_backend/main.py`: đăng ký `knowledge_repository`, `knowledge_candidate_adapter`, và mount `knowledge_router`.
- **Validation:**
  - Unit & Integration tests (`tests/modules/knowledge/`): **12/12 PASS** (`test_entities.py`, `test_lexical_matcher.py`, `test_use_cases.py`).
  - Toàn bộ backend test suite: **196 passed**, 42 skipped (database integration tests cần live DB).
  - Linter & Formatter: `ruff check .` **All checks passed!**, `ruff format --check .` **217 files already formatted**.
  - Type checking: `mypy src` **Success: no issues found in 157 source files**.
  - Architecture boundaries: `pytest tests/test_architecture.py` **2/2 PASS** (domain stdlib-only, application framework-free, api không chạm data frameworks, layer DAG tuân thủ tuyệt đối).
- **Next steps:** KD-4 (Knowledge UI & Settings trong companion app mobile: danh sách domains, chi tiết slot 0..4, tiến trình level, nhật ký knowledge journal, chat input gợi ý domain, test UI).

- **User requirement:** Hoàn thành session KD-2 của milestone M06 Knowledge Domains: wire Opcode 10, BLE characteristic `7a6e000f`, capability, events, NVS persistence, commit-first pipeline trong firmware, sinh fixture vàng `knowledge_v1.json`, và tích hợp toàn diện trên mobile companion app (entity, use cases, models, mappers, codec, BleDataSourceImpl, simulator, golden + unit tests).
- **Firmware Implementation:**
  - `firmware/lib/xuna_core/include/xuna/time/ClockModel.h`: thêm `uint16_t localDayIndex(uint64_t mono) const` tính số ngày kể từ 2020-01-01 khi đồng hồ tin cậy, 0 khi chưa tin cậy.
  - `firmware/lib/xuna_core/include/xuna/event/EventTypes.h`: thêm các event `KnowledgeSlotChanged` (`0x63`), `KnowledgeEvidenceChanged` (`0x64`), `KnowledgeLevelChanged` (`0x65`).
  - `firmware/lib/xuna_core/include/xuna/persist/SnapshotCodec.h`: giữ `kBudget = 1536` B theo quy chuẩn plan §7.5 (snapshot fresh + full knowledge chỉ 1264 B, nằm an toàn trong budget).
  - `firmware/lib/xuna_core/include/xuna/life/LifeCore.h`:
    - Tích hợp `KnowledgeProfile knowledge_`, getter `knowledge()`, `syncKnowledge()`.
    - `restore()`: nạp section 13 knowledge từ NVS snapshot.
    - `forget()`: reset toàn bộ knowledge profile.
    - `handleKnowledge(subop, slot, slot2, factKey, now)`: thực hiện commit-first (§9.5) trước khi trả kết quả `KnowledgeCommandResult`.
  - `firmware/lib/xuna_core/include/xuna/protocol/V1LifeCoreAdapter.h`:
    - Dispatch opcode 10 (`kOpcodeKnowledge`) với sub-ops 1..7 (`OpenSlot`, `SetActive`, `SetResting`, `ClearSlot`, `AddEvidence`, `RemoveEvidence`, `MoveEvidence`).
    - Nối `enhancedLearning_` với `knowledge`, `encodeKnowledge()` chiếu 64-byte payload.
  - `firmware/include/BleManager.h`:
    - Bật capability byte 3 bit 4 (`0x1f`).
    - Khởi tạo characteristic `7a6e000f-8c44-4db6-9f61-2b7d5300a101` (PROPERTY_READ).
    - Cập nhật và xuất bản knowledge projection định kỳ trong `update()`.
  - `firmware/test/test_v1_adapter/test_main.cpp`: bổ sung 3 test cases `enhanced_knowledge_command_flow_and_persistence`, `baseline_rejects_knowledge_command`, và `knowledge_command_argument_validation`.
  - `firmware/sim/knowledge_golden.cpp`: tool mô phỏng firmware sinh ra fixture vàng UTF-8 `mobile/test/fixtures/firmware/knowledge_v1.json` gồm 11 bước bao phủ mở slot, thêm fact, thêm trùng, di chuyển giữa 2 slot, chuyển resting/active, xóa fact, và xóa slot.
- **Mobile Implementation:**
  - Domain Entities: `knowledge_slot_state.dart`, `knowledge_level.dart`, `knowledge_reason.dart`, `knowledge_journal_entry.dart`, `knowledge_slot.dart`, `knowledge_profile.dart`.
  - Domain Use Cases: `read_knowledge_profile_use_case.dart`, `open_knowledge_slot_use_case.dart`, `set_knowledge_slot_state_use_case.dart`, `clear_knowledge_slot_use_case.dart`, `add_knowledge_evidence_use_case.dart`, `remove_knowledge_evidence_use_case.dart`, `move_knowledge_evidence_use_case.dart`.
  - Data Layer:
    - `knowledge_profile_model.dart`: giải mã 64-byte projection, validate header/slots/journal.
    - `knowledge_mapper.dart`: ánh xạ binary models sang domain entities.
    - `device_protocol.dart`: thêm `opcodeKnowledge = 10`, `knowledgeSubOp*` (1..7), `capabilityKnowledge = 1 << 4`.
    - `device_command_model.dart`: thêm các trường `slot`, `slot2`, `factKey` và named constructors.
    - `protocol_codec.dart`: encode/decode 16-byte command, `supportsKnowledge` check.
    - `device_ble_data_source_impl.dart`: quản lý characteristic 15 (`7a6e000f`), getter `supportsKnowledge`, phương thức `readKnowledge()`.
    - `simulator_device_ble_data_source.dart`: mô phỏng đầy đủ 5 slots, tính level theo quy tắc $F=\{3, 10, 25\}, D=\{1, 3, 5\}$, journal seq & ring buffer, xử lý opcode 10 và `readKnowledge()`.
    - `device_repository.dart` & `device_repository_impl.dart`: hoàn thiện interface và implementation cho toàn bộ các use cases knowledge.
  - Tests:
    - `mobile/test/features/device/data/model/knowledge_profile_model_test.dart`: 5 test cases kiểm tra giải mã, mapping và các trường hợp lỗi boundary/corrupt.
    - `mobile/test/features/device/data/firmware_knowledge_golden_test.dart`: 4 test cases kiểm tra schema metadata, encode frame byte-identical, decode projection, và chạy chuỗi 11 lệnh golden trên simulator.
- **Validation:**
  - Firmware native tests: **343/343 test cases PASSED (100%)** qua toàn bộ 40 test suites.
  - Mobile flutter tests: **258/258 test cases PASSED (100%)** qua toàn bộ repository test suites.
  - Mobile static analysis: `fvm flutter analyze` **No issues found!** (0 errors, 0 warnings).
- **Next steps:** KD-3 (Backend lõi: module `knowledge`, migration 0009, API, CandidateType.KNOWLEDGE, fact_key, lexical domain matching, retrieval).

- **User requirement:** "làm session KD-1 — lõi Knowledge trên thiết bị của milestone M06" theo plan `knowledge-domains-plan-2026-10-27.md` (§0, §1, §3, §5.1, §5.2, §5.3, §9 KD-1, §12) và AGENTS.md.
- **Implemented:**
  - `firmware/lib/xuna_core/include/xuna/knowledge/KnowledgeProfile.h`: 5 slots, 32 fact keys per slot, states Empty/Active/Resting, typed `Result`, circular journal of 4 entries (`KnowledgeJournalEntry`), level derived from `F = {3, 10, 25}` and `D = {1, 3, 5}`. Idempotent `add` returns `Duplicate` without mutating state, untrusted day (`trustedDay = 0`) increments facts but not days, `remove` preserves days history, `move` transfers evidence atomically and journals both slots (reason 4). Pure C++11, zero dynamic allocation, no STL containers, no exceptions.
  - `firmware/lib/xuna_core/include/xuna/knowledge/KnowledgeCodec.h`: snapshot section 13 codec (variable size 66 B min to 706 B max). Validates level matches computed level (or Corrupt), no duplicate keys in slot, `keyCount <= 32`, `state <= 2`, returns `TooNew` for `slotCount > 5` or `maxKeys > 32`.
  - `firmware/lib/xuna_core/include/xuna/knowledge/KnowledgeProjection.h`: 64-byte read-only BLE projection for characteristic `7a6e000f`, matching plan §5.3 (version=1, size=64, clockTrusted flag bit 0, 5 slots x 8 B, 4 journal entries x 4 B newest first).
  - `firmware/lib/xuna_core/include/xuna/persist/SnapshotCodec.h`: added `SectionId::Knowledge = 13` (optional, version 1), `SnapshotKnowledge` struct, wired into `LifeSnapshotV2`, `encodedSize`, `encode`, and `parseSection` (unreadable or newer section skipped gracefully without failing snapshot into ERROR_SAFE).
  - `firmware/lib/xuna_core/include/xuna/event/EventTypes.h`: added comment `obsolete 2026-10-27, never reuse` for `0x60` and `0x61`.
  - `firmware/lib/xuna_core/include/xuna/lab/LifeScenarios.h`: added `KnowledgeDualReport` and `LifeScenarios::knowledgeTwoHistories()` comparing steady teaching (4 days, 12 facts -> Level 2) vs cramming (1 day, 25 facts -> Level 1); journal entries explain level transitions.
  - `firmware/test/test_knowledge/test_main.cpp`: 15 test cases covering level boundaries table, duplicate rejection, remove existing/missing, clear, move edge cases, add to empty/resting, trusted vs untrusted days, saturation at 255, capacity at 32 keys, journal ring buffer wrapping, codec round-trip and corruption sweeps, projection exact byte layout, snapshot integration with and without section 13, Life Lab scenario, and snapshot budget measurement.
- **Validation:**
  - `pio test -e native -f test_knowledge`: **15/15 PASS**.
  - `pio test -e native -f test_personality_persist -f test_snapshot_v2 -f test_life_lab -f test_life_lab_scenarios`: **45/45 PASS**.
  - `pio test -e native`: **340/340 PASS** across all 41 test suites.
  - `tools/check_core_purity.py`: PASS on all builds.
  - `pio test -e native_asan -f test_knowledge`: ERRORED at link stage on Windows host because MinGW/UCRT64 GCC toolchain lacks `libasan` and `libubsan` (`cannot find -lasan`, `cannot find -lubsan`).
- **Snapshot Budget Measurement:**
  - `KnowledgeCodec::kMaxSize = 706 B`.
  - Fresh snapshot + full knowledge (706 B): **1264 B** (within `kBudget = 1536 B`).
  - Worst-case theoretical snapshot (all optional sections simultaneously at max: personality 482 B + habit 152 B + stated 92 B + product learner 458 B + knowledge 706 B): **1906–2002 B**, which exceeds the current `kBudget = 1536 B` by **+370 B to +466 B**.
  - Reported to owner for decision before KD-2: raise `kBudget` (e.g. to 2048 B, well within ESP32 NVS blob capability) vs fallback to `u16` keys (386 B max for section 13).
- **Not run:** physical ESP32 board, mobile companion app.
- **Next step:** KD-2 (Protocol + board: opcode 10, characteristic `7a6e000f`, capability bit, events, snapshot store wiring).

- **User requirement:** "cái danh sách lĩnh vực này tôi nghĩ là không nên cố định đâu", then "về phần này tôi cần bạn research đàng hoàng, bạn tìm kiếm các repo liên quan trước đi, rồi cho tôi gợi ý/đề xuất", then "oke chọn A đi, tôi cần bạn lên kế hoạch cho phần này, nhớ gắn thêm repo tham khảo vì có thể tôi sẽ dùng model khác để code nữa, lên plan chi tiết nhé".
- **Research:** [knowledge-domains-research-2026-10-27.md](docs/research/knowledge-domains-research-2026-10-27.md).
  - Surveyed about 15 companion and pet repos and 8 LLM memory libraries.
  - No open-source project has a per-topic knowledge level.
  - User-authored entries are the most trusted pattern (SillyTavern, KoboldAI).
  - Fully emergent topics churn.
  - BERTopic's zero-shot mode (named topics plus clustered leftovers) is the working hybrid.
- **Owner decision (option A):** open, owner-named domains with descriptions; XUNA suggests a new domain (or "add to X") only when unsorted knowledge clusters; at most one pending suggestion; the owner confirms.
- **Plan:** [knowledge-domains-plan-2026-10-27.md](docs/roadmap/knowledge/knowledge-domains-plan-2026-10-27.md) rewritten as a detailed implementation plan for any coding model. It covers decisions K-D1–K-D7, the honesty contract and concepts, and the [P] defaults: level from confirmed facts and trusted teaching days (3/10/25 facts and 1/3/5 days), 5 slots, 32 fact keys per slot. The rest:
  - **Firmware:** `KnowledgeProfile`, snapshot section 13, 64 B projection on `7a6e000f`, 16 B opcode 10 (open/active/resting/clear/add/remove/move), capability byte 3 bit 4, events 0x63–0x65.
  - **Backend:** module `knowledge`, migration 0009, API, `CandidateType.KNOWLEDGE`, `fact_key`. Algorithms: assignment, relation, suggestion and merge guard, summary, retrieval budget, optional chat extraction and embeddings.
  - **Mobile:** layers, orchestration use cases with idempotent retry, UI.
  - **Sessions KD-1 → KD-7** with files, tests and acceptance; risks; a reference-repo table per part; owner questions Q1–Q7.
- **Design findings recorded in the plan:**
  - BLE command frames are at most 16 B and `CommandCache` stores 16 B, so domain names stay in the cloud and the device keeps only slots, counters, keys, level and journal. This also avoids the board font gap.
  - Today a fact "commit" writes nothing to the device (the app only attaches the current `snapshotGeneration`). Opcode 10 `add` closes that gap for knowledge (backend AGENTS §1.3).
  - Memory routes declare no consent of their own; this is Q1.
- **Owner answers (all recommended options, plan §12):** Q1 reuse U3 `conversation_text`; Q2 keep the defaults (5 slots, 3/10/25 facts, 1/3/5 days, suggest at 4 unsorted); Q3 LLM proposes knowledge from chat, at most 1 per turn, always confirmed, with an off switch (default on); Q4 lexical first, embedding adapter measured in KD-4 then owner decides (D11a); Q5 delete domain asks each time, default keeps knowledge as unsorted; Q6 no board display in phase 1; Q7 levels "Mới nghe qua / Biết chút ít / Biết khá / Biết nhiều".
- **No code changed.** Next: KD-1 (`xuna_core` knowledge core, native tests, Life Lab).

## 2026-10-27 — M06 direction change: knowledge domains (Docs)

- **User requirement:** "khả năng là tôi sẽ bỏ cái quá trình trưởng thành của xuna đi, thay vào đó đổi thành khả năng ngày càng thông minh hơn, biết về những lĩnh vực nhất định tùy theo chủ nó muốn… vì trong quá trình trưởng thành phải xây dựng hình ảnh và animation riêng cho từng giai đoạn", then "oke chọn A trước đi, sau đó có ý tưởng gì thêm thì sửa sau".
- **Decision (option A):** no visual growth stages after hatch (egg → hatch stays, D7). M06 becomes knowledge in owner-chosen domains: the device owns the profile (domains, level, evidence, journal); the cloud keeps the owner-confirmed facts tagged by domain and uses them in conversation; the app only displays the profile and sends requests. Wording stays honest: XUNA remembers what the owner chose and taught. It does not become "smarter" on its own, and the LLM is not trained.
- **Docs:** new [knowledge plan](docs/roadmap/knowledge/knowledge-domains-plan-2026-10-27.md) (K-D1–K-D3, concepts, ownership, sessions KD-0 → KD-6, owner questions Q1–Q5). Updated the AGENTS.md M06 row (owner-approved), D13 marked superseded in the implementation plan, the session plan M06 row and the roadmap README.
- **Builds on existing pieces:** CLD-14 candidate flow (awaiting owner confirmation → awaiting device commit → confirmed) and `CandidateType.FACT`; `TurnContext.confirmed_facts` already reaches the LLM (cap 10); the personality model (P-D1: device decides, cloud gives evidence).
- **KD-0 cleanup done in the same session** (owner: "có bỏ code cũ về quá trình trưởng thành đi không"):
  - Mobile:
    - Removed `GrowthStage`, `AppPetStage` and `AppXunaPet.stage`; `app_xuna_pet.dart`, its test and `tools/export_pet_animation.py` are back to `1301850`.
    - Removed `HomeGrowthCard` and its test, the `xuna_stage_{egg,newborn,child}.png` assets, `AppDimens.iconSize12` and the stage locale keys.
    - Reverted `739886e`: the codec accepts `growthStage <= 1` again.
    - Replaced the pre-M06 growth placeholders with knowledge placeholders: room badge "LĨNH VỰC" (`home_knowledgeLabel`), Journal filter "Lĩnh vực" (`home_filterKnowledge`), and a new `HomeKnowledgeCard` ("LĨNH VỰC CỦA XUNA", "SẮP CÓ", `home_knowledgeNote`) with a widget test.
  - Firmware: reverted `c458f88` (`GrowthWireStage` is `Egg=0, Newborn=1` again; Newborn means "hatched"). Removed `tools/generate_growth_stages.py`, `assets/stages/` and `assets/generated/growth_stages_preview.png`. The generator stays in git history (`d42ae88`) if an egg sprite is needed for a hatch screen.
  - Lifecycle V1 `growthStage` (byte 3) stays: it is the egg/hatched state used by identity and hatch.
  - Checks: `fvm flutter analyze` 0 issues, `fvm flutter test` **249/249 PASS** (4 stage tests removed, 1 added); firmware `pio test -e native -f test_v1_characterization` 8/8 PASS. Not run: phone, board.
- **Next:** owner answers Q1–Q5, then KD-1 (`xuna_core` `KnowledgeProfile` + Life Lab).

## 2026-10-26 — M06 review fix: device-owned growth stage (Mobile)

- **User requirement:** "review code cho tôi phần Digital Life Milestone M06", then "oke theo ý bạn đi" (option A of the review).
- **Review findings fixed:**
  - `HomeGrowthCard` decided the stage itself from `LifeSummary.events`/`memories` (10/30 feedback events, 1/3 memories). That was a business rule in presentation, broke the device-authority invariant (parent AGENTS §6, mobile AGENTS §6.1) and invented D13 thresholds without Life Lab data. Removed.
  - The card now takes a domain `GrowthStage?` (`device/domain/entity/growth_stage.dart`: egg, newborn, child, mature, matching Lifecycle V1 byte 3) and shows all four stages including Egg (`home_growthStage0` "TRỨNG"). Null keeps the whole journey dimmed with "SẮP CÓ"; a stage lights the stages reached and badges the current one.
  - `HomeJournalTab` passes no stage: no firmware exposes Lifecycle V1 over BLE and mobile does not read it, so the card stays "coming soon" until a session wires it.
  - `AppXunaPet.stage` documents that egg/newborn/mature override expression and scene art. New `AppDimens.iconSize12` for the stage arrows.
  - Restored the Voice entry heading that the M06 entry had overwritten, and recorded the follow-up commits `c458f88`/`739886e`.
- **Tests:** `home_growth_card_test.dart` (coming soon without stage, lit stages and badge with a stage, no overflow for every stage), `app_xuna_pet_test.dart` stage asset paths. `fvm flutter analyze` 0 issues; `fvm flutter test` **252/252 PASS**; `pubspec.lock` unchanged. Not run: phone, board.
- **Still open (owner decision / own session):**
  - D13 growth gates, stage names and thresholds (needs Life Lab data).
  - Firmware: nothing sets `LifecycleProjection.stage`, emits `GrowthStageChanged (0x61)` or persists the `Lifecycle` snapshot section; no BLE characteristic or capability bit carries Lifecycle V1; the board does not draw stage sprites (`firmware/assets/stages/*.png` are not used by any build).
  - M06 minimum outcome (two histories → explainable behavior/appearance differences, Evolution Journal) is not met yet.
- **Stage sprites redrawn (owner: "trông lỏ quá… thiết kế lại từ đầu… giống style XUNA hiện tại", then the stage brief below):**
  - The AI sprites were off-model: a round blob, gradients, a thin outline, wings/crown, and a pixel grid that did not match XUNA's.
  - Owner stage brief: "hình ảnh xuna hiện tại là trong giai đoạn trưởng thành… trứng thì bỏ cái mào tóc đi, giai đoạn tiếp theo thì đầu vẫn vuông, và chưa có mào vàng, giai đoạn thứ 3 là đầu vẫn vuông nhưng có một chút màu vàng còn giai đoạn cuối là hình ảnh xuna hiện tại". So **today's XUNA is Mature (HIỂU BẠN)**.
  - Replaced by `firmware/tools/generate_growth_stages.py` (no AI). It starts from the in-game idle frame (`assets/generated/pet_frames.png`) reduced to its flat palette, and the younger stages are cut from it:
    - Square head: the crest is replaced by a flat top. XUNA's eyes, brow (with its raised ends), mouth and feet are kept.
    - Newborn: the square head with no gold, made smaller by removing plain rows and columns.
    - Child: the full-size square head with a low stepped golden cap (low left, tall centre, medium right, like a small mature crest) and a fringe.
    - Egg: a cream shell (`#f1e4c8`) with orange marks and a zigzag crack, no crest.
    - A 3 px ink outline is redrawn. Every stage is bottom-anchored on the idle ground row of the shared 96×72 canvas.
    - Heights: egg 31, newborn 31, child 43, mature 53 px.
  - Outputs `firmware/assets/stages/xuna_stage_{egg,newborn,child}.png` and `assets/generated/growth_stages_preview.png`. `xuna_stage_mature.png` was removed. `mobile/tools/export_pet_animation.py` copies the stage PNGs into `mobile/assets/images/` (this time they were copied directly, see the drift note below). `AppXunaPet`: `child` → `xuna_stage_child.png`; `mature` (and no stage) → the regular expression art.
  - `HomeGrowthCard` draws every stage at one height (52) so the artwork shows the growth.
  - Found while exporting: the committed mobile pet loops (`xuna_*.png/gif`, the `xuna_pet_*` GIFs) no longer match the current firmware `pet_frames.png`/`room_background.png` pixel for pixel. They were restored and not re-exported here; re-export them in their own change.
  - Not done: the board does not draw the stages yet (no RGB565 arrays).
  - **Temporary art (owner 2026-10-26: "tạm thời commit lại đi, nhưng thêm note là sẽ sửa lại hình ảnh stages sau"):** the egg, newborn and child sprites are committed as placeholders and **will be revised later**. Change `generate_growth_stages.py` and regenerate; do not hand-edit the PNGs.
  - Tooling: VS Code flags `from PIL import …` in every art tool because no local Python has Pillow (`python` is the Store alias; the PlatformIO penv has no Pillow). Install Python 3 and `pillow==13.0.0` and select it as the interpreter before regenerating art.
  - The old `scratch/process_stages.py` from the M06 entry was never in the repository and is now obsolete.

## 2026-10-26 — Digital Life M06: Growth & Evolution Stage Sprites (Mobile & Firmware)

- **User requirement:** "về mắt thiết kế thì cứ theo bạn gợi ý chọn cách 1 đi, chuẩn bị hình ảnh thì bạn dựa vào hình ảnh xuna hiện tại rồi dùng AI gen ra nhé, phải đúng theo style của nó nha, tôi sẽ kiểm tra sau, bây giờ thí bắt đầu làm đi".
- **Visual Design & Asset Pipeline (Option 1: Distinct Stage-based Sprites):**
  - **Style Parity & Alignment:** Generated high-resolution 16-bit retro pixel art game sprites keeping 100% fidelity with XUNA's character silhouette, palette (orange `#D87949`, shading `#AC5336`, golden crest `#F7B855`, dark outline `#211E29`, white pixel eye sclera `#FFF9EB`):
    - **Stage 0 (Egg / Trứng):** `xuna_stage_egg.png` — cream shell with warm orange bands and golden zigzag crack pattern.
    - **Stage 1 (Newborn / Ngày Đầu):** `xuna_stage_newborn.png` — round, chubby baby blob with single golden sprout and large innocent pixel eyes.
    - **Stage 2 (Child / Khám Phá):** `xuna_pet_idle.png` — classic iconic XUNA with full 3-spike crest and playful posture.
    - **Stage 3 (Mature / Hiểu Bạn):** `xuna_stage_mature.png` — grown, confident digital lifeform with majestic golden crown and cute pixel wings.
  - **Preprocessing & Canvas Alignment (`scratch/process_stages.py`):**
    - Clean chroma-key background removal with alpha transparency.
    - Precise aspect-ratio nearest-neighbor downsampling to match XUNA's native $96 \times 72$ canvas, bottom-aligned at ground line $y=66$ and centered horizontally at $x=48$.
    - Assets deployed to both `mobile/assets/images/` and `firmware/assets/stages/`.
- **Mobile Companion App Integration (`mobile`):**
  - **Shared Widget (`AppXunaPet`):** Added `AppPetStage` enum (`egg`, `newborn`, `child`, `mature`) with stage-aware asset routing, fully backward-compatible with expression animations.
  - **Growth Card (`HomeGrowthCard`):**
    - Unlocked real developmental progression replacing placeholder dimmed state.
    - Dynamically resolves current active stage from `LifeSummary` events and memories.
    - Shows sequential flow with directional indicators, active stage highlighted with `xunaLime` border badge, unlocked stages in full opacity, and future stages softly previewed.
  - **Journal Integration (`HomeJournalTab`):** Binds connected pet life state to `HomeGrowthCard`.
- **Validation:**
  - `fvm flutter analyze`: **0 issues**.
  - `fvm flutter test`: **248/248 tests PASS** (all widget, home page, and controller tests green).
  - Committed in `mobile` submodule: `96b25d9`.
  - Committed in `firmware` submodule: `c500bba`.
- **Follow-up commit (protocol bounds):** firmware `c458f88` extends `GrowthWireStage` with `Child=2`, `Mature=3` and the encoder bound to `stage<=3`; mobile `739886e` accepts `growthStage <= 3` in `ProtocolCodec.decodeLifecycle`. Both sides are tested but neither is used outside tests yet (see review entry above).

## 2026-10-26 — Voice: Real-time Voice over WebSocket (VOICE-WS WS-1 & WS-2, Backend & Mobile)

- **User requirement:** "hướng 2 đi không cần phải hỏi ý kiến tôi, cứ tự quyết định nếu bạn thấy nó hợp lý" & "có gì khó khăn cứ tham khảo repo xiaozhi ai server".
- **Architecture & Design Principles (Xiaozhi AI Server inspired + XUNA Invariants):**
  - **Full-Duplex Streaming:** WebSocket endpoint `/v1/voice` handles push-to-talk microphone audio streaming (16kHz PCM16), real-time STT (`stt.final`), prompt execution with digital life turn context, and streaming speech synthesis (`tts.start`, binary MP3 chunks, `tts.end`, `reply.finished`).
  - **Barge-in / Interruptible Support (`abort`):** Immediately cancels active LLM text generation tasks and TTS synthesis pipelines when a user interrupts or cancels.
  - **Privacy & Security Guarantee (U3V Consent):** Mandatory 5-second handshake auth with Firebase ID token. Rejects connection with `consent_required` (code 4008) if U3V (`conversation_voice`) opt-in is not active. Raw audio is never stored or logged (ephemeral buffer in memory only, capped at 30s `MAX_AUDIO_BYTES`).
  - **Device Authority & Teaching Safeguards:** Voice responses remain untrusted candidate text. They never directly mutate learner preferences without owner review.
- **Backend Implementation (`xuna_backend.modules.conversation`):**
  - Session State Machine (`voice_session.py`): `VoiceSession` managing states (`IDLE`, `LISTENING`, `TRANSCRIBING`, `AWAITING_COMMIT`, `REPLYING`), audio buffer accumulation, and sentence-interleaved speech streaming.
  - API WebSocket Route (`websocket.py`): Mounted under `/v1/voice`. Supports `hello`, `hello.ok`, `listen.start`, binary PCM audio chunks, `listen.stop`, `stt.final`, `turn.commit`, `reply.delta`, `tts.start`, `tts.end`, `reply.finished`, `abort`, and `bye`.
  - Quality & Testing (`test_voice_websocket.py`):
    - Handshake validation, missing/invalid token, pet ownership verification, U3V consent check.
    - Full push-to-talk stream with audio chunks, STT transcription, and streaming TTS audio response.
    - Barge-in abort and session cleanup.
    - Backend test suite: **226/226 tests PASS** (PostgreSQL `xuna_test`), `ruff` clean, `mypy` clean.
- **Mobile Companion App Implementation (`mobile`):**
  - Data Source (`voice_websocket_data_source.dart`): `VoiceWebSocketDataSource` interface and `VoiceWebSocketDataSourceImpl` using `dart:io` `WebSocket`. Converts `http(s)` base URL to `ws(s)://.../v1/voice`. Emits typed events (`VoiceWsHelloOk`, `VoiceWsSttFinal`, `VoiceWsReplyDelta`, `VoiceWsTtsAudio`, `VoiceWsReplyFinished`, `VoiceWsError`).
  - Integration (`home_binding.dart`, `data.src.dart`): bound in DI.
  - Unit tests (`voice_websocket_data_source_test.dart`): URI mapping, full handshake, binary chunk streaming, event parsing, clean close.
  - Mobile test suite: **248/248 flutter tests PASS**, `flutter analyze` 0 issues.

## 2026-10-26 — Cloud: Phase 4 Direct Device Transport (CLD-40, CLD-41, E14, Backend & Firmware C++11)

- **User requirement:** "Hướng 1: Cloud Phase 4 Direct Device Transport (CLD-40, CLD-41, E14)".
- **Backend Implementation (`xuna_backend.modules.transport`):**
  - Domain: `MqttTopic`, `TransportChannel`, `TransportDirection`, `DeviceConnectionStatus`, `DeviceStatusRecord`, `DownlinkCommand`.
  - Application: `ports.py`, `schemas.py`, use cases `handle_uplink_message`, `send_downlink_suggestion`, `send_downlink_command`, `get_device_status`.
  - Infrastructure: `device_transport_statuses` table (`0008_device_transport.py`), `SqlTransportStatusRepository`, `InMemoryMqttBroker`.
  - API: `POST /v1/transport/mqtt/uplink`, `GET /v1/devices/{device_id}/transport/status`, `POST /v1/devices/{device_id}/transport/command`.
  - Tests: `test_transport_api.py`, `test_transport_entities.py`, `test_transport_use_cases.py` (9/9 tests PASS).
- **Firmware Implementation (`firmware`):**
  - C++11 header `include/MqttTransport.h`: static topic builders and payload serializers (`kMaxTopicLen = 128`, `kMaxPayloadLen = 512`, zero dynamic allocation).
  - Host test `test/test_mqtt_transport.cpp` built and verified PASS.

- **User requirement:** "oke làm phase 3 đi" (Cloud Phase 3 — CLD-30: Sleep Learning / Batch Consolidation Service, E15, O1 & CLD-31: Bounded Suggestion Service under approved H1–H8 contract).
- **Architecture & Strict Boundary Guarantees (ADR-0007, Implementation Plan §22, Cloud Implementation Plan §7):**
  - **H1 (Offline-complete):** Digital life, learner, and state engine remain 100% offline-complete on ESP32 hardware. Cloud is an optional cognitive optimization service.
  - **H2 (Device authority):** Cloud never writes hardware state directly. All recommendations are bounded, expiring, revertible `CloudSuggestion`s.
  - **H3 (Bounded suggestions):** Kinds: `learner_parameter` ($\gamma$ learning rate in `[0.70, 0.95]`, curiosity exploration bonus in `[0.05, 0.30]`), `habit_prior` (day-part routine priors in `[0.0, 1.0]`), `content_pack`. Each suggestion carries `suggestion_id`, `pet_id`, `brain_id`, `kind`, `target`, `delta`, `bounds`, `provenance`, `expires_at`, `status`.
  - **H4 (Owner evidence wins):** Suggestions change parameters/priors only; they never overwrite direct owner feedback (`user_feedback` or `user_stated`) and never invent life facts.
  - **H5 (Provenance & Transparency):** Explicit provenance tags: `cloud_inferred` (batch consolidation over pet projection) or `population`.
  - **H6 (Opt-in Consent):** Strictly requires U1 (`aggregate_metrics`) or U2 (`experience_events`) consent. Default U0 returns `403 consent_required`.
  - **H7 (Graceful Degradation):** Unapplied suggestions expire automatically after 7-day TTL.
  - **H8 (Per-owner / Per-device Security):** Asymmetric token auth, scoped to owner's bound `PetId` and active `BrainId`.
- **Backend Implementation (`xuna_backend.modules.suggestions`):**
  - Database Migration: `migrations/versions/0007_cloud_suggestions.py` (table `cloud_suggestions` with cascade FKs to `pets.pet_id` and `brains.brain_id`, composite index `(pet_id, status)`, indices on `pet_id`, `brain_id`, `expires_at`).
  - Domain: `CloudSuggestion`, `SuggestionKind`, `SuggestionProvenance`, `SuggestionStatus`, bounds validation, timezone-aware datetime validation, and lifecycle state transitions (`pending` $\rightarrow$ `applied`/`rejected`, `applied` $\rightarrow$ `reverted`).
  - Consolidation Algorithm (`consolidation.py`): computes adaptive tuning for learner $\gamma$ and curiosity bonus based on projection stability and exploration activity, bounds-clamped with 7-day TTL.
  - Application & Use Cases: `consolidate_suggestions`, `list_suggestions`, `get_suggestion`, `update_suggestion_status`, `delete_suggestion`.
  - Infrastructure: `CloudSuggestionRow` ORM and `SqlSuggestionRepository`.
  - API Routes: `POST /v1/pets/{pet_id}/suggestions/consolidate`, `GET /v1/pets/{pet_id}/suggestions`, `GET /v1/pets/{pet_id}/suggestions/{suggestion_id}`, `PATCH /v1/pets/{pet_id}/suggestions/{suggestion_id}`, `DELETE /v1/pets/{pet_id}/suggestions/{suggestion_id}`.
  - Audit Events: `SUGGESTION_CONSOLIDATED`, `SUGGESTION_APPLIED`, `SUGGESTION_REJECTED`, `SUGGESTION_REVERTED`.
- **Mobile Companion App Implementation (`mobile`):**
  - Domain: `CloudSuggestion` entity, use cases `ConsolidateSuggestionsUseCase`, `FetchSuggestionsUseCase`, `ApplySuggestionUseCase`, `RejectSuggestionUseCase`, `RevertSuggestionUseCase`.
  - Data: `CloudSuggestionMapper`, `CloudRemoteDataSource`, `CloudRepository` & `CloudRepositoryImpl` implementation.
  - Presentation & UI:
    - `HomeController`: reactive `cloudSuggestions`, `isConsolidating`, `fetchCloudSuggestions()`, `consolidateSleepLearning()`, `applyCloudSuggestion()`, `rejectCloudSuggestion()`, `revertCloudSuggestion()`.
    - `HomeSuggestionsSheet`: bottom sheet displaying pending/applied suggestions, delta, bounds, status badges, and actions (Áp dụng, Từ chối, Khôi phục, Hợp nhất Sleep Learning).
    - `HomeAccountCard` & `HomeDeviceTab`: added "Gợi ý & Sleep Learning" entry point for bound pets.
    - Localization: full Vietnamese localization in `vi_VN.json` & `locales.g.dart`.
- **Validation Results:**
  - **Backend:**
    - Unit & Integration: **211/211 tests PASS** against PostgreSQL (`xuna_test`) in 48.41s.
    - Code quality: `ruff check .` 0 issues, `mypy src` 0 issues across 128 source files.
    - Commits: `3af6926` (features), `bfd4a5b` (lint format).
  - **Mobile:**
    - Static analysis: `fvm flutter analyze` **0 issues found**.
    - Unit tests: `suggestions_use_cases_test.dart` (5/5 PASS), `cloud_suggestion_mapper_test.dart` (2/2 PASS), `cloud_repository_impl_test.dart` (21/21 PASS), `home_controller_test.dart` (47/47 PASS), `home_page_test.dart` (5/5 PASS), `locales_sync_test.dart` (PASS).
    - Full test suite: `fvm flutter test` **246/246 tests PASS** in 25s.
    - Commit: `288862c`.

## 2026-10-26 — Cloud: Phase 2 Encrypted Backup, Restore & Tombstones (CLD-20, Mobile Flutter App, Windows)

- **User requirement:** "phase 2 cho mobile đi" (Cloud Phase 2 — CLD-20: Encrypted backup, restore to replacement hardware, deletion tombstones, and forget_all on Mobile companion app).
- **Core Architecture & Client Implementation (`features/account` & `features/home`):**
  - **Domain Entities & Mappers:**
    - `CloudBackupManifest`: `backupId`, `petId`, `brainId`, `snapshotGeneration`, `schemaVersion`, `payloadSha256`, `createdAt`.
    - `CloudRestoreResult`: `petId`, `brainId`, `deviceId`, `snapshotGeneration`, `tombstonesApplied`, `restoredPayload`.
    - `CloudTombstone`: `tombstoneId`, `petId`, `itemType`, `itemId`, `deletedAt`, `reason`.
    - `CloudBackupMapper` and `CloudTombstoneMapper` extending `BaseDataMapper`.
  - **Data Source & Repository:**
    - `CloudRemoteDataSource`: added `postBackup`, `getBackups`, `deleteBackup`, `postRestore`, `postTombstone`, `getTombstones`, `deleteMemoryCandidate`, `postForget`.
    - `CloudRepository` and `CloudRepositoryImpl`: added `createBackup`, `listBackups`, `deleteBackup`, `restoreBackup`, `createTombstone`, `listTombstones`, `deleteMemoryCandidateWithTombstone`, `forgetAll`.
    - `AccountExceptionKind.backupNotFound` mapped from backend problem code `backup_not_found`.
  - **Domain Use Cases:**
    - `CreateBackupUseCase`, `ListBackupsUseCase`, `DeleteBackupUseCase`, `RestoreBackupUseCase`, `DeleteCandidateWithTombstoneUseCase`, `ForgetAllUseCase`.
    - Exported in `domain.src.dart` and registered in `HomeBinding`.
  - **Presentation & UI:**
    - `HomeController`:
      - `cloudBackups` observable list.
      - `fetchCloudBackups`: loads manifests for bound pet.
      - `createCloudBackup`: takes latest device export (`xuna.export.v1`), uploads encrypted backup to Cloud.
      - `restoreCloudBackup`: restores backup, applying server-side tombstones to strip deleted memories, and displays tombstones applied count.
      - `deleteCloudBackup`: permanently removes backup manifest.
      - `deleteCandidateWithTombstone`: permanent deletion of memory candidates with tombstone recording to prevent resurrection (Threat Model T10).
      - `forgetAllCloud`: archives current Brain, issues new BrainId with master tombstone `*`.
    - `HomeBackupsSheet`: bottom sheet displaying backup history (generation #, SHA-256 hash, date), actions to Create Backup, Restore, Delete, and danger section for ForgetAll with confirmation dialogs.
    - `HomeCandidateDetailSheet`: added "Xóa vĩnh viễn (Tombstone)" action.
    - `HomeAccountCard` & `HomeDeviceTab`: added "Sao lưu & Khôi phục" entry point for bound pets.
    - Localization: Vietnamese strings in `vi_VN.json` and `locales.g.dart`.
- **Validation:**
  - `fvm flutter analyze`: **0 issues** across entire mobile codebase.
  - `backups_use_cases_test.dart`: **5/5 PASS** (full use case test suite).
  - `cloud_repository_impl_test.dart`: **15/15 PASS** (tested backups, restore, tombstones, and forget round-trip).
  - `home_controller_test.dart`: **46/46 PASS** (including candidate permanent delete with tombstone, backup creation from device export, list, restore with tombstone application, delete, and forget all).
  - Full suite `fvm flutter test`: **237/237 tests PASS** in 24s.
  - Committed in `mobile` submodule: `07dc682`.

## 2026-10-26 — Cloud: Phase 2 encrypted backup, restore & tombstones (CLD-20, backend, Windows)

- **User requirement:** "làm phase 2 đi" (Cloud Phase 2 — CLD-20: Encrypted backup, restore to replacement hardware, and deletion tombstones).
- **Core Architecture & Threat Model Mitigations (`xuna_backend.modules.backups`):**
  - **Encrypted Snapshots (AES-256-GCM, `crypto.py`):**
    - Payloads encrypted with 256-bit AES-GCM (12-byte random nonce, 16-byte authentication tag).
    - Supports client-side pre-encrypted uploads or server envelope encryption.
    - Integrity-checked with SHA-256 before encryption and after decryption; corrupted ciphertext or tampered tag fails safely with `422 corrupt_backup`.
  - **Hardware Replacement & Device Rebind (Threat Model T14 & §4.2, `identity` + `backups`):**
    - Restoring to replacement hardware rebinds to a new `DeviceId` via ECDSA P-256 challenge-response proof, while **strictly preserving `PetId` and `BrainId`** (device replacement is not a new pet).
    - Old device credential revoked automatically.
  - **Memory Resurrection Protection via Tombstones (Threat Model T10, `tombstones`):**
    - Tombstone registry keyed by `(pet_id, item_type, item_id)`.
    - On backup restore: any memory or fact matching an active tombstone is suppressed/stripped from the restored payload, ensuring stale backups can never resurrect deleted personal data.
    - On candidate deletion: endpoint `DELETE /v1/pets/{pet_id}/memory-candidates/{candidate_id}` marks candidate `status = "deleted"` and records a tombstone.
  - **ForgetAll / Reset (Threat Model §4.2, `forget_all`):**
    - Archives current `BrainId` to `archived`, generates a fresh active `BrainId`, records a master tombstone `(item_type="memory", item_id="*")`, and marks all candidates as deleted, keeping `PetId` unchanged.
- **Backend Implementation:**
  - Domain: `BackupManifest`, `EncryptedData`, `DeletionTombstone`, `RestoreResult` in `entities.py`.
  - Application: `create_backup`, `get_backup`, `list_backups`, `delete_backup`, `restore_backup`, `create_tombstone`, `list_tombstones`, `forget_all` in `use_cases.py`.
  - Infrastructure: `BackupManifestRow` (`backup_manifests`), `DeletionTombstoneRow` (`deletion_tombstones`), `SqlBackupRepository`.
  - API: `POST/GET/DELETE /v1/pets/{pet_id}/backups`, `POST /v1/pets/{pet_id}/backups/{backup_id}/restore`, `POST/GET /v1/pets/{pet_id}/tombstones`, `DELETE /v1/pets/{pet_id}/memory-candidates/{candidate_id}`, `POST /v1/pets/{pet_id}/forget`.
  - Database Migration: `0006_backup_manifests_and_tombstones.py`.
  - Identity port enhanced: `rebind_device` and `rotate_brain` in `SqlIdentityRepository`.
  - Audit actions: `BACKUP_CREATED`, `BACKUP_RESTORED`, `TOMBSTONE_CREATED`, `PET_FORGOTTEN`.
- **Validation:**
  - `pytest tests/modules/backups/`: **17/17 PASS** (5 crypto, 3 entities, 4 use cases, 5 integration tests against PostgreSQL).
  - Migration round-trip `test_migrations.py`: PASS (upgrade -> downgrade -> upgrade).
  - Clean Architecture `test_architecture.py`: 2/2 PASS (100% layer purity).
  - Full suite: **197/197 PASS** in 44.62s.
  - `ruff check`: 0 errors.
  - `mypy --strict`: 0 errors in 115 source files.
  - Committed in `backend` submodule: `ace2858`.

- **User requirement:** "Triển khai Layer B Recall: Nạp các sự thật đã duyệt (Confirmed Facts như tên, màu sắc, thú cưng) vào ngữ cảnh hội thoại để XUNA nhớ thông tin của chủ khi chat".
- **Layer B Architecture & System Prompt Injection (`xuna_backend.modules.conversation`):**
  - Application layer (`chat_turn.py`):
    - `TurnContext` augmented with `confirmed_facts: tuple[str, ...]`.
    - `describe_context`: injects confirmed personal facts under `"Những điều bạn biết chắc chắn về người bạn đang trò chuyện cùng (do bạn ấy đã chia sẻ và xác nhận): ..."` and identifies the owner's name to instruct natural, friendly address (`"Người bạn đang nói chuyện cùng tên là [Tên]. Khi xưng hô, bạn có thể gọi bạn ấy là [Tên] hoặc bạn [Tên] một cách thân thiện."`).
  - API layer (`routes.py`):
    - In `POST /v1/conversations/{pet_id}/turns`: queries `SqlMemoryRepository.list_candidates(PetId(pet_id), status=CandidateStatus.CONFIRMED)` before closing the DB session.
    - Filters for `CandidateType.FACT`, deduplicates by fact key (latest wins), and formats facts into natural Vietnamese sentences (`_format_fact`), capped at 10 items.
    - Passes `confirmed_facts` into `TurnBody.context()`.
- **Validation:**
  - `pytest tests/modules/conversation/test_chat_turn.py`: 12/12 PASS (tested fact injection, owner name address, and empty fallback).
  - `pytest tests/modules/conversation/test_conversation_api.py`: 8/8 PASS (including `test_conversation_injects_confirmed_facts_into_prompt` full end-to-end turn -> unconfirmed -> confirm + commit -> next turn prompt recall).
  - Full suite: **180/180 PASS** in 39s.
  - `test_architecture.py`: 2/2 PASS (clean architecture and purity 100% maintained).
  - `ruff check`: 0 errors, `mypy --strict`: 0 errors (102 source files).
  - Committed in `backend` submodule: `708dc13`.

## 2026-10-26 — Cloud: commit confirmed memory candidates to device (BLE opcode 6, mobile, Windows)

- **User requirement:** "tiếp đi" (Option 2: Commit Confirmed Memory Candidates to Hardware over BLE Opcode 6).
- **Candidate Confirmation & Commit Lifecycle:**
  - When the owner approves a `stated_preference` candidate on the mobile app:
    - **Connected to board:** encodes into `CandidateEvent`, sends `_confirmCandidate.execute(event)` (opcode 6 over BLE to device learner), and notifies Cloud via `_commitMemoryCandidate.execute(candidateId, petId, generation)`. The Cloud status transitions to `confirmed`.
    - **Disconnected from board:** candidate transitions to `awaiting_device_commit` ("Đang chờ nạp vào mạch"). An inline "Nạp vào máy" CTA button appears on the card and detail sheet. When reconnected, the owner can tap to push the preference to the board and finalize Cloud commit.
  - When the owner approves a personal `fact` candidate:
    - Automatically finalized on Cloud (`confirmed`) because personal fact storage on hardware is scheduled for Layer B / M05b.
- **Mobile Implementation (`mobile/lib/`):**
  - Use case: `CommitMemoryCandidateUseCase` in `features/account/domain/usecase/commit_memory_candidate_use_case.dart`, registered in `home_binding.dart`.
  - Presentation & Controller: `HomeController` updated with `commitCandidateToDevice(candidate)` and integrated into `confirmCandidateOnCloud()`. Cards and detail sheet render "Nạp vào máy" button when status is `committed` (`awaiting_device_commit`).
  - Localization: added strings `candidateCommitAction`, `candidateConfirmAndCommittedSuccess`, `candidateNeedConnection`, and `candidateCommitFailed` to `assets/locales/vi_VN.json` and `locales.g.dart`.
- **Validation:**
  - `fvm flutter test test/features/home/presentation/controller/home_controller_test.dart`: **44/44 PASS**.
  - `fvm flutter analyze`: **0 issues**.
  - Full mobile test suite: **229/229 PASS**.
  - Committed in `mobile` submodule: `12b829e`. Before that: **new app icon from the owner's sticker (cream background, XUNA smiling with coin and sparkles; iOS + Android, `mobile/tools/generate_app_icon.py`; not built yet)**. Before that: **PE-4d on host: "Bỏ thay đổi gần nhất" / "Đặt lại tính cách" over BLE opcode 9, commit-first (firmware 325/325, mobile 209/209; on the board, entry below)**. Before that: **PE-4c on host: chat tags (praise/scold/affection/playful/curious_question/long_chat) from the backend reach the board over BLE opcode 8 and move feelings at once, temperament only slowly (firmware 321/321, backend 159, mobile 204/204; on the board, entry below)**. Before that: **PE-4b on host: AI replies speak in the device personality label and mood (backend 145/145, mobile 198/198; not tried with a real LLM or iPhone, entry below)**. Before that: **PE-4a gain A uploaded to the board with the Track A preview (2026-10-25)**. Before that: **personality Gate G1 passed (option A for G1-a…d); PE-2a uploaded to the board 2026-10-24: parity PASS, `step()` p99 +≤ 15 µs, boot Ok, same PetId; heat fix (10 ms loop pacing: chip 51.8 → 46.8 °C); **heat pass 2 on the board: CPU 80 MHz (ECDSA boosted to 240), backlight 12/16 awake · 7 asleep · 16 cards, BLE advertising 100–152.5 ms: chip 44.8 → 41.8–42.8 °C**; **PE-2b on the board: XUNA acts on its own after 51–69 s by temperament (`d945…`: 58 s)**; **PE-3 on the board: personality survives reboots (snapshot section 5, optional), BLE `000e`; board reboot check passed (`persona_restored bytes=104 sessions=1 evidence=2`)**; **Track A: 4 variant animations from the owner's sheet on the board (greet, yawn, look around, bounce)**; **variant preview from the app (opcode 1 args 4–7, capability byte 4 bits 4–7, shown only): firmware 306/306 and mobile 198/198, not uploaded (board unplugged), iPhone not rebuilt**; **app reads the personality (Journal → "Tính cách" card), mobile 192/192; iPhone not rebuilt**; Gate G2 waits for the owner's observation** (entry below). Before that: **voice fixes: long spoken replies no longer cut mid-sentence (mobile `3d05072`), Edge TTS retried per sentence (backend `70b8361`); iPhone not rebuilt yet** (entry below). Before that: **personality PE-1 done (drives, affect, Life Lab shadow); Gate G1 report waits for the owner** (firmware lab only, host; entry below). Before that: PE-1a genome + evidence ledger and PE-0 baseline (committed firmware `552eb4c`, parent `eb81e00`). Before that: **spoken replies overlap TTS with the text stream; WebSocket voice design Proposed** (backend host tests only). Before that: **app reconnects to the last XUNA on open** (mobile, host tests only). Before that: **owner reports all phone and board checks done; Cloud gate (c) met; M04 approved; free tiers only (D19/D11a); D18 deferred until V1 is finished** (entry below; no measurements recorded). The "Next"/"open" items further down this line are superseded by that entry. Previously: **XUNA's AI replies get context** (2026-10-23, owner: smart like Xiaozhi): each turn carries phone time, the last ≤ 12 chat lines and the device's view of XUNA (age, current action, learned likes), transient under U3; persona answers knowledge questions (backend `e150330`, mobile `8a42784`, 129/155 tests). Server restarted with it. Next: rebuild iOS, measure five spoken turns (Edge TTS is the latency risk). Previously: **mobile 006cf5b rebuilt and installed on the owner's iPhone 15** ([V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md)). This fixes SSE decoding for Dio's Uint8List chunks; the recorded mobile validation is 152/152, and the release build succeeded with Flutter 3.32.8 / Dart 3.8.1 and Xcode 27.1. The owner also rebound the test pet to the Google account. Backend probe: spoken Edge turns took 4.9–11 s, so phone timing remains open. Next: measure at least five real phone turns, confirm QR camera, output route, and microphone while BLE is connected. CocoaPods 1.16.2; no package or lockfile changes in this rebuild. Firebase plist is local and ignored now, but remains in old mobile history at 7ebd06d. Board firmware 0a392c5 is uploaded; visual check of scenes/status card/QR, Cloud gate (c), and M04 review remain open.
Current milestone: **M04 approved; Cloud gate (a)–(c) met; Cloud Phase 1 completed (CLD-14); Cloud Phase 2 completed (CLD-20 implemented). Board runs the PE-2a + loop-pacing firmware (2026-10-24); iPhone runs mobile `8a42784`.** Extended life-feel/power-cut checks remain unvalidated.
Current status (2026-10-16):

## 2026-10-26 — Cloud: automatic candidate extraction from conversation (backend & mobile, Windows)

- **User requirement:** "hướng 1 trước đi" (Option 1: Automatic Candidate Extraction from Conversation in Backend).
- **Backend Architecture & Domain (`xuna_backend.modules.conversation.domain.candidate_extractor`):**
  - Clean Architecture purity: stdlib & domain entities only (imports `CandidateType`), 0 framework, 0 network.
  - Extracts `STATED_PREFERENCE` (actions: `happy`, `idle`, `curious`; contexts: `play`, `quiet`, `greeting`; polarity: `like`, `dislike`) and personal `FACT` (owner name, favorite color, favorite food, birthday, pet/companion).
  - Strict privacy & safety guards: quotes, code symbols, instructions, hypotheticals, prompt injection patterns, door codes/passwords ("mã cửa nhà mình là 1234"), and generic chit-chat return `None` and are NEVER stored or created as candidates.
- **Backend API Integration (`xuna_backend.modules.conversation.api.routes`):**
  - In `POST /v1/conversations/{pet_id}/turns`: before releasing the DB connection, extracts candidates from user text.
  - Inserts new candidate into `memory_candidates` table with status `awaiting_owner_confirmation`.
  - Automatic deduplication prevents inserting duplicate pending candidates with identical summary.
  - Attach candidate summary in SSE `finished` payload (`"candidate": {"candidateId": "...", "type": "...", "summary": "..."}`).
- **Mobile Integration (`mobile/lib/features/home/presentation/controller/home_controller.dart`):**
  - Triggers `unawaited(refreshMemoryCandidates())` immediately upon chat turn completion, ensuring new candidates populate the Journal tab seamlessly.
- **Validation:**
  - Backend: `pytest` **177/177 PASS**, `ruff check` 0 errors, `mypy --strict` 0 errors (102 source files), `test_architecture.py` 0 violations.
  - Mobile: `fvm flutter analyze` 0 issues, `fvm flutter test` **228/228 PASS**.
  - Committed backend (`916484f`), committed mobile (`19768cb`).

## 2026-10-26 — Mobile: memory candidates UI & reusable base widgets (Flutter, Windows)

- **User requirement:** "làm giao diện cho mobile trước đi, nhớ phải dùng base đấy nhé, nếu thấy widget nào dùng chung thì tạo base để dùng lại cho sau này".
- **Reusable Base Widgets (`mobile/lib/shared/widgets/`):**
  - `AppStatusBadge` (`app_status_badge.dart`): semantic chip with dot indicator supporting 5 variants (`pending`, `success`, `info`, `danger`, `neutral`), ink stroke and rounded styling matching XUNA design system.
  - `AppEmptyState` (`app_empty_state.dart`): standard empty state view supporting icon (`Widget` or `iconAsset` SVG), title, descriptive message, and action CTA button.
  - `AppFilterPillBar<T>` (`app_filter_pill_bar.dart`): generic horizontally scrollable filter choosing between enum or model options via `AppPillButton`.
  - Exported in `widget_src.dart` and covered with unit widget tests in `test/shared/widgets/app_widgets_test.dart`.
- **Domain & Data Layers (`mobile/lib/features/account`):**
  - Entity `MemoryCandidate` with enums `MemoryCandidateType` (`statedPreference`, `fact`, `unknown`) and `MemoryCandidateStatus` (`pending`, `confirmed`, `committed`, `rejected`, `expired`, `deleted`).
  - Use cases: `ReadMemoryCandidatesUseCase`, `ConfirmMemoryCandidateUseCase`, `RejectMemoryCandidateUseCase`.
  - Data: `MemoryCandidateMapper` (extends `BaseDataMapper`), `CloudRepository.fetchMemoryCandidates()` returning `List<MemoryCandidate>`, `rejectMemoryCandidate(candidateId)`.
- **Presentation Layer (`mobile/lib/features/home`):**
  - `HomeCandidateCard`: displays memory candidate with `AppStatusBadge`, source and date caption, display title, and direct inline action buttons ("Duyệt" / "Từ chối" for pending status).
  - `HomeCandidateDetailSheet`: `AppSheetFrame` bottom sheet displaying full candidate metadata, status badge, structured JSON content table, and approval/rejection actions.
  - `HomeJournalTab`: added `_Filter.candidates` ("Ứng viên"), replaced manual row with `AppFilterPillBar<_Filter>`, displaying candidate cards or `AppEmptyState` when empty, and highlighting pending candidates in the "Tất cả" view.
  - `HomeController`: added `memoryCandidates`, `refreshMemoryCandidates()`, `confirmCandidateOnCloud()`, `rejectCandidateOnCloud()`; triggers refresh on Journal tab select, account login, and BLE connection.
  - `HomePage`: binds candidates and opens `HomeCandidateDetailSheet`.
- **Localization:**
  - Vietnamese translations added to `assets/locales/vi_VN.json` and synchronized 1:1 with `lib/generated/locales.g.dart`.
- **Validation:**
  - `fvm flutter analyze`: **0 issues**.
  - `fvm flutter test`: **228/228 PASS** (including controller, widget, domain, data, and locales sync tests).
  - Committed in `mobile` submodule: `6e94fac`.

## 2026-10-26 — Cloud: CLD-14 projections & memory candidates pipeline (backend, Windows)

- **CLD-14 implemented:** completes Cloud Phase 1 (device-data projection & candidate-confirmation lifecycle).
- **Backend changes:**
  - New module `xuna_backend.modules.memory`:
    - `domain`: `Projection` entity, `MemoryCandidate` entity, `CandidateStatus` (awaiting_owner_confirmation, awaiting_device_commit, confirmed, rejected, expired, deleted), `CandidateType` (stated_preference, fact).
    - `application`: use cases `ingest_projection` (envelope verification, ECDSA P-256 purpose 2 device proof, U1/U2 consent filtering, wrap-safe generation check via `ProjectionKey`, idempotency), candidate lifecycle (`create_candidate`, `patch_candidate` for confirm/reject/commit/delete, `list_candidates`, `get_latest_projection`, `list_projections`).
    - `infrastructure`: `ProjectionRow` (`memory_projections`), `MemoryCandidateRow` (`memory_candidates`), `SqlMemoryRepository`.
    - `api`: `PUT /v1/pets/{pet_id}/projections/{snapshot_generation}`, `GET /v1/pets/{pet_id}/projections/latest`, `GET /v1/pets/{pet_id}/projections`, `POST /v1/memory-candidates`, `GET /v1/memory-candidates`, `PATCH /v1/memory-candidates/{candidate_id}`.
  - Migration `0005_memory_projections_and_candidates.py` with full up/down DDL and index/foreign-key cascade definitions.
  - `IdentityRepository`: added `update_generation(pet_id, generation)` so `memory` updates `pet.last_generation` through identity use case/port without touching `PetRow`.
  - `AuditAction`: added `PROJECTION_INGESTED`, `PROJECTION_REJECTED`, `MEMORY_CANDIDATE_CONFIRMED`, `MEMORY_CANDIDATE_REJECTED`.
- **Validation (Windows, PostgreSQL 16 `xuna_test`):**
  - `test_architecture.py`: 2/2 PASS (0 layer/framework violations).
  - `test_migrations.py`: 2/2 PASS (upgrade → downgrade → upgrade round-trip).
  - `test_entities.py`, `test_use_cases.py`, `test_memory_api.py`: 12/12 PASS.
  - Full suite: **172/172 passed** in 43.69s.
  - `ruff check` + `ruff format`: clean (0 errors).
  - `mypy --strict`: clean (`Success: no issues found in 101 source files`).
- **Mobile integration (CLD-14 client, commit `f379b62`):**
  - Codec & Result: `ExportDocumentCodec.envelope()` helper and `DeviceExportResult.envelope` expose the exact `xuna.export.v1` document.
  - Data & Domain: added `putProjection`, `getLatestProjection`, `postMemoryCandidate`, `getMemoryCandidates`, `patchMemoryCandidate` to `CloudRemoteDataSource` / `CloudRepository`. Memory validation error codes mapped to `AccountExceptionKind.invalidInput`.
  - Use case: `UploadProjectionUseCase(UploadProjectionInput)`.
  - Offline-first export: `HomeController.exportData()` uploads projection to cloud when signed in; cloud network/consent errors are logged and never block local file export.
  - Verification: `fvm flutter analyze` (0 issues), `fvm flutter test` (**221/221 PASS**).
- **Next:** Phase 2 (CLD-20: Encrypted backup, restore to new board, deletion tombstones) or end-to-end device export sync check.


- Board firmware: owner-authorized 2026-10-16 S13+S18 production switch (intermediate S13/S18 build with current artwork, before the S26 changes), LifeCore/ProductLearner + LifeSnapshot v2; first boot Migrated, subsequent boot Ok. PetId `d945c77026fd4f4a8a899bbff4aeed86`; Happy/Idle preserved. GPIO0 is direct Happy, not learnable greeting. Stack setup 8,228 B first boot / 8,036 B first reboot (16 KiB stack).
- Source ahead of board: **S10-sync + S26/S27-lite** enable opcode 5/6 and capability bits 4/5 (`0x003f`), 16-byte TimeSync, day-part learning, explanation READ `000b` and expired=8. Mobile syncs after connect and every six hours. Board still has bits 4/5/6 off and expired=4. Hatch bit 6 and learnable GPIO0 remain deferred. Install upgraded app before firmware rollout.
- Latest recorded validation: S26 firmware full native/ASan 192/192 each, then final adapter 11/11 each; ESP32/purity PASS (52,088 B RAM / 2,851,677 B Flash). Flutter 3.32.8 analyze clean, 59/59 tests and debug APK PASS; lock unchanged. All artwork/UI and upgrade source is now committed: firmware `b0f4ded`, mobile `4976147`; parent records both pointers.
- iOS build (2026-10-19): Flutter 3.32.8 / CocoaPods 1.16.2 / Xcode 27.1 produced [Development IPA](mobile/build/ios/ipa/xuna_mobile.ipa). Installed and launched on the owner's iPhone 15 (iOS 26.4.2); the curious XUNA AppIcon was corrected upright and the rebuilt app's deep signature verified. Android now has density-specific launcher icons and an Android 8+ adaptive icon; XML/PNG assets validated, but APK build was not run because no JDK/Android SDK is installed on this Mac. Minimum iOS is 15.0; bundle ID remains the development placeholder. An earlier archive omitted the signature on FirebaseAuthInterop and required manual repair; investigate that build-pipeline issue before relying on a fresh unattended IPA build.
- Owner decisions 2026-10-16 (AGENTS.md §3): S01 closed with owner-skipped items; D2a (snapshot v2 in NVS A/B `life0/life1`, LittleFS → S32); S13 + S18 merged, absorbing S08b/S09; concrete Cloud gate replaces M05b/S38. Earlier: S25 defaults, S10 protocol freeze, learning/hybrid/Cloud baseline.
- **Backend PostgreSQL differs per machine** (table in [backend/README.md](backend/README.md#owner-machines-mac-vs-windows-do-not-mix-them-up)): **Mac** = PostgreSQL 14.15, user `$(whoami)`, no password, has `xuna_test` + dev `xuna_local` (real pet binding); **Windows** = PostgreSQL 16.15 service `postgresql-x64-16`, user `xuna`/`xuna`, only `xuna_test`, venv tools in `.venv/Scripts`. Separate data: never assume a Mac database row exists on Windows or the reverse.
- Windows toolchain: PlatformIO at `~/.platformio/penv/Scripts/pio.exe` (not on PATH); host compiler MSYS2 UCRT64 `C:\msys64\ucrt64\bin`; `native_asan` only on the Mac/WSL. clangd needs `firmware/compile_commands.json` (`pio run -e xuna_t_display_s3 -t compiledb`).

Backend: CLD-10 scaffold, CLD-11 owner auth + device-proof pet binding done; CLD-01 approved by delegation, CLD-02 draft. Identity V2 is on the board: the real pet was bound end to end against the local backend. CLD-12 consent/audit and CLD-13 adapter/conversation done; Firebase Auth chosen. Firebase Google sign-in **validated end to end** on the Play Store emulator against the local backend. **App bind flow + consent sheet + AI chat built 2026-10-18 (host tests + APK only).** Next: validate on a phone with the board (plan below). **Waiting on owner:** internal AI endpoint style/URL/model to run `scripts/text_benchmark.py` over OpenVPN. Next action: **connect the phone (USB debugging)** → `adb install -r` the upgraded debug APK → connect to the board → app "tại sao" + Device-tab export → verify the export hash with the Python line in the sprint record. That closes gate (c). The board already runs the new firmware; an older app on the phone may misbehave until upgraded. Workstreams A, B and backend CLD-10/11/12/13 are committed; parent and all submodules (`backend`, `firmware`, `mobile`) are on `dev` and pushed to `origin/dev` as of 2026-10-19 ([sprint record](docs/roadmap/cloud/cloud-gate-sprint-2026-10-17.md)).

Sections §0–§8 and dated entries before 2026-10-16 are historical snapshots (§9 prompt is current); trust this header and the newest entries first.

## 2026-10-26 — Voice: spoken replies still cut off sometimes (mobile + backend, host only, Windows)

- Owner: replies on the iPhone (mobile with `3d05072`, Mac backend with `70b8361`) still break now and then, in four ways: silent for the rest of the reply (text still shows), cut mid-sentence and jump on, short gaps at commas/between sentences, the microphone recording lost. "làm cả 4 đê".
- Causes found in code (not reproduced on a phone):
  1. Pressing the mic only dropped sentences already queued; sentences still arriving from the server played into the recording and ahead of the next reply. A new turn sent while the old stream was still open was dropped (`isBusy`), so the spoken turn vanished.
  2. Backend: one Edge TTS failure (after 3 tries in 10 s) turned speech off for the rest of the reply.
  3. One file per sentence, loaded only after the previous one ended: a load gap every sentence.
  4. No audio session setup; an interruption (notification, Siri, route change) pauses just_audio, `play()` returns, and the next sentence started over the paused one.
- Fixes:
  - Mobile controller: a speech-turn token (mic press or new turn mutes the earlier reply for good); the reply stream is a cancellable subscription that a new turn ends before it starts (cancel not awaited: an async* stream inside `await for` finishes cancelling only on the next HTTP event); `speak` passed explicitly instead of a shared flag.
  - Mobile voice: two just_audio players, the next sentence written to disk on arrival and preloaded while the current plays; one `audio_session` configuration matching what `record` sets (play-and-record, speaker, Bluetooth); a sentence paused by an interruption waits for just_audio's resume (given up and stopped after 10 s); loads wait for an in-flight stop. `audio_session: 0.2.4` now a direct dependency (already locked; lock only changes transitive → direct).
  - Backend `spoken_turn.py`: a failed sentence is skipped, later ones are still spoken; `speech_unavailable` still once; `spoken` false when anything was skipped.
- Checks (Windows): mobile analyze clean, **215/215**; backend `check.sh` with `xuna_test`: ruff/format/mypy clean, **160 passed**.
- Not run: iPhone rebuild and real turns, Android. Interruption handling and the gap reduction can only be judged by ear on the phone.
- **Next:** on the Mac pull and restart the backend; rebuild the iPhone app; try long replies, pressing the mic while XUNA talks, and a notification during a reply.

## 2026-10-26 — Personality plan progress review (docs only)

- Owner: "check xem làm đến đâu rồi" for the [personality plan](docs/roadmap/personality/personality-plan-2026-10-23.md).
- Plan now carries a progress line at the top and a check of the PE-4 "Xong khi" criteria: provider-independent context holds by design (`describe_context` sits before the adapter, no two-provider test); the Life Lab chat-spam scenario and a real iPhone ↔ board chat are not run; old tests pass on host.
- Parent records the owner's firmware commit `ece6ae2` (avatar assets only, no code).
- **Next:** unchanged: owner builds the app, chats with the board connected and tries the PE-4d buttons; owner closes Gate G2/G3; then PE-5.

## 2026-10-25 — Personality PE-4d: undo the newest change / reset personality (firmware + mobile, host only)

- Owner: "làm nốt PE-4d đi". [Record](docs/roadmap/personality/PE4d-controls-2026-10-25.md).
- Firmware (uncommitted): `EvidenceLedger::popLatest`, `Personality::undoLatest`, `LifeCore::controlPersonality` (commit-first; ERROR_SAFE/commit failure → 7, empty journal → 4), opcode 9 arg 1 undo / 2 reset (enhanced adapter), capability byte 3 bit 3, serial `personality_control`.
- Mobile (uncommitted): `PersonalityControl`, `ControlPersonalityUseCase`, opcode 9 codec + capability, controller confirm dialogs and re-read, two buttons on the personality card (undo disabled with an empty journal), 11 locale strings.
- Checks (Mac): firmware native + native_asan 325/325 each, ESP32 + purity SUCCESS (RAM 55,000 B, Flash 3,896,557 B), parity build SUCCESS; mobile analyze clean, 209/209.
- Finding: a consolidated personality change reaches flash only at the next 5-minute checkpoint (lazy since PE-3); undo/reset commit at once.
- Not run: iPhone, real taps.
- **Board 2026-10-25:** firmware `fba10f7` uploaded; NVS backup `~/xuna_backups/2026-10-25-pe4d/` (3 matching reads `12bebba4…`), parity 4 × PASS (p99 unchanged), boot `recover=Ok boot=76`, same PetId, `persona_restored sessions=8 evidence=52 journal=0` (undo stays disabled until a trait moves).
- **Next:** owner builds the app and tries both buttons; then PE-5 (weeks of real life, tune [P] parameters).

## 2026-10-25 — Personality PE-4c: conversation shapes temperament without confirmation (3 repos, host only)

- Owner: O4 = no (preferences still need confirmation), O5 = reuse U3; "oke bắt đầu làm đi". [Record](docs/roadmap/personality/PE4c-conversation-2026-10-25.md).
- Backend (uncommitted): deterministic Vietnamese keyword classifier `conversation/domain/signals.py` (negation, look-alikes, ≤ 2 tags, long_chat once at 8–9 history lines); SSE `finished.signals`.
- Firmware (uncommitted): `Personality::conversation` (Affect impulse + ConversationInferred evidence 0.1, daily cap 8, open session needed), 4 new EvidenceReasons (13–16, append only), `LifeCoreEventKind::Conversation`, BLE opcode 8 (enhanced adapter), capability byte 3 bit 2, serial `conversation tag=`.
- Mobile (uncommitted): `ConversationSignal`, `ForwardConversationSignalsUseCase`, `CloudReplySignals`, opcode 8 codec, controller forwards while connected, Journal reasons 13–16 + locales.
- Checks (Mac): firmware native + native_asan 321/321 each, ESP32 + purity SUCCESS (RAM 55,000 B, Flash 3,895,917 B), parity build SUCCESS; backend check.sh 159 passed; mobile analyze clean, 204/204.
- Not run: Life Lab chat scenario, board upload, iPhone, a real end-to-end chat. Compatibility: an old app cannot read the personality card once reasons 13–16 exist on the board.
- **Board 2026-10-25:** firmware `8f498a7` uploaded; NVS backup `~/xuna_backups/2026-10-25-pe4c/` (3 matching reads `79581a6f…`), parity 4 × PASS (p99 unchanged), boot `recover=Ok boot=75`, same PetId, `persona_restored sessions=8 evidence=52`. Backend restarted with PE-4c.
- **Next:** owner builds the app and chats with the board connected; then PE-4d (undo/reset buttons).

## 2026-10-25 — Personality PE-4b: AI voice from the device personality (backend + mobile, host only)

- Owner: "bắt đầu làm thôi" after the progress check. Plan row PE-4b.
- Backend (uncommitted): `PetSelf.temperament` / `mood` (closed sets `PetTemperament` 11 labels, `PetMood` 6, wire names = firmware/app enums); `describe_context` adds one voice line per label and a mood line ("nhuốm nhẹ giọng nói nhưng vẫn trả lời đúng điều được hỏi"); `PERSONA_VI` no longer fixes "tò mò". Route body `pet.personality` / `pet.mood`, unknown values 422. Contract draft updated.
- Mobile (uncommitted): `CloudPetSelf.personality` / `mood` reuse the device `PersonalityLabel` / `PetMood`; `HomeController._turnContext` sends them only when the BLE `000e` projection is seeded; serializer adds the two keys.
- Checks (Mac): backend `scripts/check.sh` (ruff, mypy --strict, alembic, pytest) **145 passed**; mobile `fvm flutter analyze` clean, `fvm flutter test` **198/198**, `pubspec.lock` unchanged.
- Not run: a real provider turn (does the voice actually change?), iPhone build. Old apps send no label and now get a persona without a fixed character.
- **Next:** owner builds the app and chats with the board connected; then PE-4c needs O4/O5, PE-4d buttons need new firmware commands.

## 2026-10-24 — Personality PE-4a: temperament leans untaught choices (firmware, host only, Windows)

- Owner: "oke làm PE-4a thôi". [Record](docs/roadmap/personality/PE4a-leaning-2026-10-24.md).
- Firmware (uncommitted):
  - when learner scores tie, the pick is weighted by the genome: curious ← curiosity, happy ← playfulness (sociability when greeted), idle stays 1. Weight 1 ± 1 at |trait| 0.3, floor 0.125;
  - `V3Leaning` in `PreferenceLearnerV3`, `personality/Leaning.h`, `LifeCore::decide`, `BoardLab::setLeaning`. Estimates, UCB bonus, evidence and snapshot are untouched; a neutral genome chooses bit for bit as before;
  - optional near-tie margin (off on the board).
- Tried in Life Lab and dropped: curiosity × UCB bonus (no visible effect), drives in the weights (noisy owners learn worse), idle ← −tempo (starved idle for every lab owner).
- Checks (Windows):
  - native **312/312** (+6 `test_leaning`); `native_asan` not run;
  - ESP32 + purity SUCCESS (RAM 54,904 B, Flash 3,895,233 B); `xuna_parity` build SUCCESS;
  - traces c3/c8/c9 unchanged;
  - golden S20 changed on purpose (pet with identity), regenerated and copied to mobile; mobile golden test 5/5.
- Lab: learned character carries into untaught situations (P1 curious 0.48, P2 happy 0.47, vs 1/3); safety rows unchanged. **Watch:** G1-b row 1 at day 89 = 0.86 (PE-2b 0.98).
- **Gain chosen 2026-10-25: A** (±1, exact ties only; owner delegated the pick). Code defaults already match, no firmware change.
- **Uploaded 2026-10-25 (Mac)** with the Track A preview: native_asan 312/312; NVS backup `~/xuna_backups/2026-10-25-pe4a/` (3 matching reads `814701b2…`); parity 4 × PASS, p99 unchanged; boot `recover=Ok boot=73`, same PetId, `persona_restored sessions=7 evidence=45`. Backend running on the Mac (`0.0.0.0:8000`, Groq env, `xuna_local`) for the owner's app build on another machine.
- **Next:** owner observation; try the 4 preview buttons from the app. The pending Track A preview firmware would go up in the same upload.
- Notes for this Windows machine: Life Lab output is CRLF (strip `\r` before md5); `lifecore_lab` needs `-Wl,--stack,67108864`; Flutter 3.32.8 is at `~/fvm/versions/3.32.8/bin/flutter`.

## 2026-10-24 — App: personality card from BLE 000e (mobile, host only)

- Owner: "update thêm cho app nữa đi". Scope: read-only display of the PE-3 projection. The PE-4d reset / undo buttons need new device commands and are not done.
- Mobile (uncommitted), Clean Architecture per `mobile/AGENTS.md`:
  - domain: `PetPersonality`, `PersonalityChange`, `PersonalityTrait`, `ReadPersonalityUseCase`, `DeviceRepository.readPersonality`;
  - data: `DeviceProtocol.capabilityPersonality` (byte 3 bit 1), `ProtocolCodec.supportsPersonality`, `PersonalityModel` (64 B, every field validated), `PersonalityMapper` (explicit switches), BLE characteristic 14, simulator reports unsupported;
  - presentation: `HomeController.personality`, read in `_refreshLife` and cleared on disconnect; `HomePersonalityCard` with label, mood tag, sessions, 5 centred trait bars and the 4 latest changes with reasons; Journal filter "Tính cách"; Vietnamese locales (device labels + home card).
- Tests:
  - byte fixture generated from the firmware headers (`test/helpers/personality_fixture.dart`);
  - model decode + malformed cases, capability bit, repository (null / map / invalidResponse), use case, controller (simulator null; connect → label; disconnect → null), widget (label, mood, value, change line, unsupported).
- Checks: `fvm flutter analyze` no issues; `fvm flutter test` **192/192**; `pubspec.lock` unchanged.
- Not run: iOS/Android build, phone install, real board read over BLE.

## 2026-10-24 — Track A: 4 variant animations from the owner's sheet (firmware + board)

- Owner: art brief prompt → the owner brought a 4 × 16 preview sheet ("dựa vào đây thêm animation mới cho xuna đi"). [Record](docs/roadmap/personality/trackA-variants-2026-10-24.md).
- Art:
  - A first pass segmented the owner's preview sheet. The owner then asked for a redraw.
  - **`tools/generate_track_a.py`** draws the 64 frames from the in-game idle frame: same face geometry, whole-pixel lean, stretch/squash and hop. The neutral frame is byte-identical to idle, the feet are fixed except when hopping, and nothing is copied from the sheet. 885 KB of flash.
- Option A, expression only:
  - `LifeCore` offers `greet_nuzzle` when an owner session opens, `yawn_stretch` on entering rest or waking, `look_around` for an idle choice with explore ≥ ½ or anticipation, and `bounce_play` for a happy choice with play ≥ ¼ or emotion ≥ 0.25.
  - One per step, latched (`takeVariant`). Only the shown variant satisfies its drive.
  - `VariantPlayer` plays over the pose at the personality tempo.
  - Finding: play rarely passes 0.26 because it grows only while energy ≥ ½.
- Checks: native/ASan **299/299**; golden S20, Life Lab and trace hashes unchanged.
- Board: NVS `3997107e…` backup; parity PASS; app `8fdd32f6…`, boot Ok, `persona_restored bytes=104`. The owner saw `greet_nuzzle` and `bounce_play` ×3. `look_around` and `yawn_stretch` are not seen on the board yet.
- Redrawn frames on the board: NVS `71343573…` backup, app `e63e9c7a…`, boot Ok, `persona_restored bytes=107 sessions=3 evidence=8`.

## 2026-10-24 — Personality PE-3: personality survives reboots (firmware + board)

- Owner: "PE-3 đi, còn lại bạn tự quyết". **O2 = optional** (delegated): an older firmware skips section 5; required would put the pet in ERROR_SAFE after a rollback. [Record](docs/roadmap/personality/PE3-persistence-2026-10-24.md).
- Firmware:
  - `PersonalityCodec` (section 5 v1, ≤ 482 B, written only once something is learned, top 3 reasons / top 2 sources per trait; invalid content skipped);
  - `LifeSnapshotV2::personality`;
  - `LifeCore` seeds then loads section 5 and re-encodes it on `revision()` change (lazy, next commit);
  - event `TraitConsolidated` 0x71, output `traitsConsolidated`;
  - BLE `7a6e000e` 64 B projection, capability byte 3 bit 1;
  - logs `persona_restored` and `persona_shift`.
- Checks:
  - native/ASan **294/294**;
  - worst-case snapshot ≤ 1536 B;
  - golden S20 and Life Lab byte-identical;
  - trace c9 snapshot hash `7ca37821…` → `a5491046…` (section 5, intended); c3/c8 unchanged.
- Board:
  - backup `~/xuna_backups/2026-10-24-pe3/` (NVS `4a98da87…` read twice);
  - parity PASS with host hashes, `step()` as in PE-2;
  - app `23e51ec8…`, boot Ok, same PetId and preferences, `persona_restored bytes=0` (expected);
  - setup stack free 6,184 B (was 7,192).
- **Board reboot check passed:**
  - the owner petted twice, then shooed; the USB link dropped (no crash);
  - after replugging: `recover=Ok boot=57`, `persona_restored bytes=104 sessions=1 evidence=2`. The shoo's evidence waits for the next commit (lazy).
  - Setup stack free 5,796 B with section 5.
  - **Next:** Gate G2 + G3 owner review; PE-4 (behaviour + conversation) needs O3 (Track A art) and O4/O5.

## 2026-10-24 — Personality Gate G1 passed; PE-2a board shadow + first expression (firmware, host only)

- Owner: "oke làm tiếp đi" after the G1 recommendation → **G1 passed with option A for G1-a…d** (AGENTS.md §3, [PE-2 record](docs/roadmap/personality/PE2-board-shadow-2026-10-24.md) §1). **Machine: Mac.** Board not connected.
- Firmware (uncommitted):
  - `xuna/personality/Personality.h` holds genome + ledger + drives + affect with plain inputs; `lab/PersonalityShadow.h` wraps it. With the old ledger the Life Lab output stays identical (md5 `db687275…`).
  - `LifeCore` owns it (owner inputs, shown decisions with p̂, applied pet/shoo, accepted actions, ForgetAll). `BootSequence` seeds it from `IdentityRecord.seed`; with no identity the genome is neutral. Decisions, RNG and snapshot are unchanged.
  - `xuna/personality/Expression.h`: frame 100 ms ∓ 15 % (tempo + arousal/2), reaction 2400 ms ± 15 % (sensitivity + |emotion|/2), full effect at ±0.3. `PetVisualAnimation::setInterval`, `AnimationManager::setReactionMs`, `DisplayManager::setFramePeriod`.
  - Status card "tâm trạng" line (6 words; font regenerated, +3 glyphs). Serial `persona …` line every 60 s.
  - G1-a: `LedgerConfig::minSessions` 3 → 4.
  - Removed an unused `kDayMs` in `sim/personality_lab.cpp` (clang `-Werror` on the Mac).
- Checks (Mac):
  - native **282/282**, `native_asan` **282/282**;
  - ESP32 build + purity SUCCESS: 53,784 B RAM (+824), 3,001,829 B Flash (+5,852);
  - `xuna_parity` build SUCCESS;
  - Life Lab 86.6 s: PE-0 `metric` lines byte-identical; [PE2 output](docs/research/artifacts/PE2-shadow-output.txt).
- G1-a in the lab:
  - random-owner drift 0.0081 → 0.0033; alternating swing 0.0173 → 0.0088;
  - P1 curiosity +0.116 / 30 days;
  - row 1 ratio 0.40 / 0.72 / **1.10** at day 29 / 59 / 89. The G1-b wording is met only just.
- Not done:
  - **PE-2b** spontaneous frequency by drive (it changes when XUNA acts; measure in the lab first);
  - learned personality is lost on reboot until PE-3;
  - board steps: NVS backup, parity `step()` p99, upload, owner observation → Gate G2.
- Note: on this Mac the `rtk` hook makes wrapped `diff`/`grep` report false "identical" results. Use `/usr/bin/diff`, `cmp` or `md5`.
- **Board (owner plugged it in, same day)** ([record](docs/roadmap/personality/PE2-board-shadow-2026-10-24.md) §6):
  - Backup `/Users/xthao28/xuna_backups/2026-10-24-pe2/`: partition unchanged; NVS read twice, identical `c685f095…`.
  - Parity: 2 passes PASS, same snapshot hashes as 2026-10-22; `step()` p99 c3 +14, c8 +15, c9 +3 µs.
  - Production upload: app `aca9820f…`, built from uncommitted source. Boot `recover=Ok boot=41 ready=1`, PetId `d945…`, quiet=1 play=0, stack 7,144 B, heap stable.
  - The innate temperament of `d945…` is near neutral (tempo −0.04, sensitivity +0.02, playfulness +0.13): frame 101 ms, reaction 2421 ms. The pace barely differs at first; mood will change it.
- **Heat fix (owner: "board nóng lắm")** ([record](docs/roadmap/personality/PE2-board-shadow-2026-10-24.md) §7):
  - Cause: `loop()` only yielded, so the CPU spun at about 25,500 passes/s.
  - `kLoopPeriodMs = 10`: sleep what is left of each 10 ms pass. Diagnostics now print `power loops=… chip_temp_c=…`.
  - Board, 9 min each with an NVS backup before each upload: chip 51.8 °C → 46.8 °C and still falling; 495 passes per 5 s; draw max 5.6 ms; boot Ok with the same PetId and preferences.
  - Backlight PWM, 160 MHz and light sleep are not done.
- **Heat pass 2 (owner: "xử lý triệt để", agent decides; [record](docs/roadmap/personality/PE2-board-shadow-2026-10-24.md) §10):**
  - `kCpuMhz = 80` plus `CpuBoost` (240 MHz only for key load / ECDSA sign); backlight via the LED driver's 16-step pulse dimming (`xuna/visual/Backlight.h`: awake 12, sleep/rest 7, cards 16, 60 ms fade steps); BLE advertising 0xA0–0xF4.
  - Light sleep / DFS impossible on the prebuilt Arduino 2.0.14 (`CONFIG_PM_ENABLE` and BT modem sleep off).
  - Native/ASan 304/304. Board (NVS backed up twice before each upload, `~/xuna_backups/2026-10-24-heat2/`): chip 44.8 °C → 42.8 (C1) → 41.8–42.8 °C (C2, app `398d475c…`); draw max 7.6 ms; boot Ok, same PetId, quiet=1 play=0; owner's button presses and cards normal.
  - Open: owner's eye check that the screen dims (and is still fine at 12/16), the sleep level 7 on the board, phone connect/proof at 80 MHz. Committed as firmware `e4f5fe5` (Track A) + `8b4e42b` (heat pass 2); the board image was built from exactly that tree.
- **PE-2b** (owner: "tiếp tục"; [record](docs/roadmap/personality/PE2-board-shadow-2026-10-24.md) §8):
  - Drive-paced routine tried in Life Lab, two variants:
    - drives alone: +27 % activity, pets of one owner only 3.5 % apart;
    - temperament + drives: random-owner drift doubled.
  - **Owner chose temperament only:** wait = 60 s × (1 − 0.15·t), t = (curiosity + playfulness)/2, 51–69 s (`Expression::spontaneousWaitMs`, `LocalBehavior` `waitMs`, used in `main.cpp` and `BoardLab`).
  - Lab: activity +4 %; pets of one owner 10.7 % apart (lives no longer identical); random drift 0.0035.
  - Trade-offs: row 1 at day 89 = 0.98 (G1-b wants > 1; watch it); learning reversal 3.6 → 5.0 days.
  - Checks: native/ASan 284/284; golden S20 byte-identical; [output](docs/research/artifacts/PE2b-shadow-output.txt).
  - Board: two uploads failed with "No serial data received" (nothing written). After the owner replugged, a new NVS backup, then upload SUCCESS (app `cd559d88…`). Boot Ok, same PetId and preferences; XUNA acted every 58 s as computed.
- **Status card** (owner: "oke thêm vào đi"; [record](docs/roadmap/personality/PE2-board-shadow-2026-10-24.md) §9):
  - A derived **"Tính cách"** label (`Expression::traitWord`, most pronounced of five traits, threshold 0.05) replaces the stale "Lúc chơi thích" cell. "Đã sống" becomes "Đã thức".
  - native/ASan 285/285.
  - Board: NVS backup `42de3abf…`, app `9880a767…`, boot Ok, same PetId. `d945…` shows "ham chơi".
  - **Next:** the owner observes for a few days → Gate G2. Then PE-3 (needs O2: section 5 required or optional).

## 2026-10-23 — Voice fixes: long spoken replies cut off; flaky Edge TTS (backend + mobile, host only)

- Owner: transcription slow; spoken replies stop mid-sentence and jump on, or go silent; long replies always break. **Machine: Mac.** Backend run with `.env.groq` + `.env.groq-text` on `xuna_local`, `0.0.0.0:8000`.
- Cause 1 (mobile, long replies): just_audio 0.10.6 keeps `playing` true after a file completes and `play()` returns at once while `playing`; from sentence 2 on the next file auto-started on load, `play()` did not wait, the file was deleted and the next queued sentence cut it off. Fix: pause before loading the next file (`voice_audio_data_source.dart`); data source test with a just_audio-like fake player (fails without the fix). Mobile `3d05072`: analyze clean, 183/183 tests.
- Cause 2 (backend): Edge free TTS answered "no audio" for 2/12 sentences (same text fine on retry) and sometimes took 5.4 s; one failure turned speech off for the rest of the reply, a mid-stream cut played half a sentence. Fix: up to 3 attempts per sentence in one `timeout_s` budget, audio yielded only after a whole attempt. Real Edge probe 18/18 complete. Backend `70b8361`: check.sh 143 passed.
- Transcription: server-side 0.8–4.6 s, almost all Groq free-tier time (connection already kept alive); changing provider is an owner decision. Not fixed: text LLM adapter opens a new HTTP client per turn (+0.3–0.7 s); one turn (22:57:31) had no LLM call after transcription, cause not verified.
- Not run: iOS rebuild/install, phone test of either fix.

## 2026-10-23 — Personality PE-1b–d: drives, affect, Life Lab shadow; Gate G1 report (firmware lab, host only)

- Owner: "commit rồi tiếp tục đi". PE-0 + PE-1a committed first (firmware `552eb4c`, parent `eb81e00`, not pushed). **O1 taken as the delegated default** (sensitivity = transient mood only; revisable).
- Firmware (uncommitted), all lab-only (not in the production image):
  - `xuna/life/Drives.h`: explore, social, play and boredom at genome-scaled rates. Social longs for 2 h, then settles to 0. Minute ticks, so split updates = one update.
  - `xuna/life/Affect.h`: WASABI-style emotion/mood springs, GAMYGDALA-style appraisal from p̂, competence EMA, mood floor −0.5.
  - `xuna/lab/PersonalityShadow.h`: watches BoardLab. Owner-session gap 30 min; evidence only from reactions/sessions; consolidation at session end; drive-aware shadow choice.
  - `EvidenceLedger` gains `LedgerConfig` (defaults unchanged) and reasons PlayRewarded/PlayShooed.
  - `sim/personality_lab.cpp`: adds `pe1,…` metrics, 90-day `long_owners`, ledger and drive-weight sweeps. 33 s, deterministic, PE-0 `metric,…` lines byte-identical.
- Tests: `test_drives` 8, `test_affect` 9, `test_personality` +4 shadow tests. Found: `memcmp` on `AffectState` failed through a padding byte (test fixed to compare fields, as in `test_habit`).
- Fix found by the lab: fixed ±1 greeting evidence made every consistent owner max out sociability (+0.6 by day 90). It now uses the prediction error like curiosity/playfulness (P0 +0.018 by day 90).
- Results ([G1 report](docs/research/PE1-G1-report.md), raw output `docs/research/artifacts/PE1-shadow-output.txt`):
  - **Every safety row met:** absence, bad day and silent owner give Δ 0; random owner 0.008; reversal: learning flips in 3.6 days while curiosity moves −0.003 in 15 days; the shadow choice equals the learner's greedy choice in 100 % of cells; no sadness from absence.
  - **Owner effect:** P1 curiosity +0.146 / 30 days, +0.40 / 90 days.
  - **Not met:** §5 row 1 ratio (0.49 at day 30, 0.88 at day 60, 1.35 at day 90), and innate individuality through action choice (JS 0, entropy 0.053). The temperament shows only through tempo, emotion size and timing, which are small with the current mapping.
- Sweep: 4 sessions / coherence 0.5 gives random drift 0.003, alternating 0.009, signal 0.116 (recommended).
- **Owner decisions pending (G1-a…d):** ledger parameters, row-1 wording, PE-2 expression mapping + Track A, sociability evidence source. Recommendation: pass G1 to PE-2 with option A for all four.
- Checks (Windows): native **274/274**; ESP32 build + purity PASS (image unchanged). Not run: `native_asan`, xtensa compile of the lab-only headers, board. Not committed.

## 2026-10-23 — Personality PE-1a: temperament genome and evidence ledger (firmware lab, host only)

- Owner: "tiếp tục đi" (decisions delegated). New lab-only headers in `xuna_core` (nothing in the production image includes them):
  - `xuna/personality/Temperament.h`: 10 Q1.14 traits. Baseline ±0.15 from `IdentityRecord.seed` (Pcg32 stream 0x7e3a), offset ±0.6, `effective` clamps ±1, `forget` keeps the baseline.
  - `xuna/personality/EvidenceLedger.h`: sources weighted like the learner (Self = 0), 11 reason codes, per-trait pending/importance grouped by owner session, a 4-entry journal (trait, delta, dominant reason/source, sessions).
- Consolidation rules [P]:
  - A trait moves only when importance ≥ 1.5, the evidence spans ≥ 3 sessions, ≥ 2/3 of sessions agree, and **|pending| ≥ importance/2** (coherence, added).
  - Step = 0.03 × pending/importance.
  - **Each session adds at most ±0.5** to pending/importance (added).
  - Disagreeing evidence → pending/importance ÷ 5 and the session count restarts.
- Tests `test_personality` (11): seed golden + spread over 400 seeds, ranges, Self ignored, one extreme session, bad day + good session, consistent 3 sessions → exactly +0.03 with reason, alternating owner never moves, saturation at 0.6 after 20 steps, weak device evidence needs 8 sessions, journal ring + forget, golden 12-session history.
- Early signal (scratch Monte Carlo, 2000 runs × 60 sessions): a coin-flip owner still moves a trait (mean |offset| 0.031, max 0.15); an 80 %-pet owner reaches +0.35. Recorded for the PE-1d parameter sweep.
- Checks (Windows): native **253/253**; ESP32 build + purity PASS (image unchanged). Not run: `native_asan`, xtensa compile of the new headers (not in the image). No commit.
- Next: **PE-1b** `xuna/life/Drives.h` (explore, social, play, boredom; genome rates). O1 before PE-1c.

## 2026-10-23 — Personality PE-0: learning-only baseline (firmware lab, host only)

- Owner: "bắt đầu làm đi", decisions delegated. **Machine: Windows.** Four plan clarifications applied (plan §4 PE-0): BoardLab + reaction-teaching owners (D6 revised), trait-only §5 rows N/A until PE-1+, owner definitions [P], TimeSync on owner arrival.
- Firmware (uncommitted): `OwnerModel.h` + Noisy/Sparse/Random/Teacher/Alternating (old kinds unchanged, same RNG draws); `sim/personality_lab.cpp` (30 local days, 1 s steps, 70 runs, 7.5 s, deterministic); `sim/README.md`; 2 new `test_life_lab` tests. Also fixed three tests that only failed with the Windows GCC 16.2: `test_habit` compared `HabitState` padding bytes (now field by field), `test_identity` `-Wmisleading-indentation`, `test_life_lab_scenarios` missing `<cstdio>`.
- Findings ([report](docs/research/PE0-baseline.md), raw output in `docs/research/artifacts/PE0-baseline-output.txt`): between owners JS 0.95 / 100 % greedy cells differ, same owner JS 0.009 / 0 % → §5 row 1 ratio already 104× from learning alone. Same owner draws with different PetId entropy → **bit-identical lives** (`LifeCore` RNG is constant seed 1 on board and lab; `IdentityRecord.seed` is durable but unused). ~1,200 spontaneous choices/day, top action 97.6 % per cell. Learning: reversal 75 % cells in 3.6 days, random owner 1.97 flips/day, alternating 3.17, bad day −25 % cells recovered in 1 day, sparse learns by day 6.4. Absence: clock stays `Approximate` with day parts after 24 h until reboot, behaviour unchanged.
- Proposed (plan §5 updated): keep row 1 as a "do not break" guard; add "same owner, different `IdentityRecord.seed` → visible difference (≥ 0.1)" and a variety row; seed the genome from `IdentityRecord.seed`; changing `LifeCore`'s RNG seed is a separate PE-2 decision (golden/parity impact).
- Checks (Windows): native **242/242**; ESP32 build + purity PASS (RAM 52,960 B, Flash 2,995,953 B, image unaffected: lab headers only). Not run: `native_asan` (Mac/WSL only), board. No commit.
- Next: **PE-1a** (`Temperament.h` + `EvidenceLedger.h`, lab-only). O1 still needed before PE-1c.

## 2026-10-23 — Roadmap records grouped into folders (docs only)

- Owner asked for a tidier roadmap. `docs/roadmap/` now has `milestones/`, `sessions/`, `lifecore/`, `learning/`, `cloud/`, `voice/`, `ui/`, `personality/` and an index [README](docs/roadmap/README.md); `XUNA_SESSION_PLAN.md` stays at the top. 56 files moved with `git mv`; links rewritten by resolving each link against its old location (parent docs plus path comments in backend, firmware and mobile). Link check: the same 5 pre-existing broken links before and after (Mac-only paths, build output), none new. Submodule edits are comments/README only; no tests run for them.
- New roadmap records go into the matching folder.

## 2026-10-23 — Personality evolution / JPAF assessment (research only)

- Owner asked to move from Cloud to XUNA's personality development and to assess JPAF (`agent-topia/evolving_personality`). Research only: no code, dependency or schema change.
- Findings ([report](docs/research/personality-evolution-assessment-2026-10-23.md)): no personality state exists in code (snapshot section 5 reserved, `TraitUnlocked` reserved); individuality today comes from learner v3, `HabitPredictor` and episodes; `Mood` is computed but drives nothing; `BehaviorSelector` is test-only; `PERSONA_VI` is one static prompt for every pet. JPAF is an LLM-driven experiment script (LLM self-labels Jungian functions and judges type changes; no persistence/tests; `eval()` on LLM output; type flips after 15 same-kind prompts); MIT since 2026-10-21; paper is an unreviewed preprint with circular metrics.
- **Proposed** (needs owner decision, report §16 Q1–Q9): Option B, a JPAF-inspired deterministic `TraitModel` in `xuna_core` (base/temporary weights, threshold consolidation, ×0.2 decay, change log), 3–4 dimensional traits, evidence only from owner/device-observed events, Life Lab first. Reject runtime JPAF. Personality is M06 in the roadmap; starting Phase 0–1 earlier is the owner's call.
- Addendum A: Blaniel (`Lucas-Dono/blaniel`) reviewed: a server-side LLM companion platform (Next.js, Postgres, Gemini/Venice); its "evolving Big Five" is only an openness +0.1 drift. Not applicable directly; three rule-based ideas (trait-driven mood decay/inertia, per-pet mood baseline, state→expression cue mapper) and "relationship separate from personality" are added to Phase 2 / data model. Recommendation unchanged.
- Addendum B (owner: personalities look limited): six more repos read (qs-vpets, openc2e/Creatures, WASABI, GAMYGDALA, MicroPsi 2, Generative Agents; Anki Vector `victor` excluded as leaked code). Proposed richer model: per-pet temperament genome (~10 parameters) driving ~6 drives, WASABI-style emotion/mood springs, emotions from expectation (learner p̂, HabitPredictor) and a competence signal; trait labels derived, not preset. Phase 1 PoC grows to M–L, still lab-only.
- Addendum C (owner: device engine vs personality through cloud conversation): recommended combination. Device stays the only authority (H2/H4); conversation supplies evidence (confirmed statements now under D6; LLM-inferred tags only if D6 is revised) and expresses personality via `PetSelf` → persona. LLM-held personality (summaries in prompts) rejected as source of truth.
- **Owner approved the direction and asked for a plan; then added "let it be natural, no confirmation".** [Personality plan](docs/roadmap/personality/personality-plan-2026-10-23.md): decisions P-D1–P-D5 (recorded in AGENTS.md §3), phases PE-0 (baseline) → PE-1 (Life Lab PoC: Temperament + EvidenceLedger, Drives, Affect) → G1 → PE-2 board shadow + expression → PE-3 snapshot section 5 + BLE → PE-4 behaviour, persona, conversation tags without confirmation (§6 safeguards) and app card → PE-5 long trial; art Track A in parallel. Open: O1–O5. **Next: PE-0** (owner models + `sim/personality_lab.cpp`, no production change).

## 2026-10-23 — Spoken replies overlap TTS with text; WebSocket voice design (backend, host only)

- Owner chose (pick-list): install Python here, "parallel + short first clause" for TTS latency, and a design document before any WebSocket code.
- **Machine: Windows** (`C:\Users\Thao`). Windows toolchain: Python **3.12.10** installed by winget (user scope, `~/AppData/Local/Programs/Python/Python312`); `backend/.venv` (gitignored) with `pip install -e ".[dev]"`; run `XUNA_TEST_DATABASE_URL=postgresql+psycopg://xuna:xuna@localhost:5432/xuna_test PY=.venv/Scripts bash scripts/check.sh`. PostgreSQL **16.15** installed by winget (owner request; service `postgresql-x64-16`, port 5432; random superuser password in `~/.xuna_pg_superuser`, outside Git); role/database `xuna`/`xuna_test` as in CI. `tests/conftest.py` sets `WindowsSelectorEventLoopPolicy` on Windows (psycopg async cannot use the default Proactor loop; Linux/Mac unchanged); running uvicorn on Windows was not tried and may need the same. Fixed a Windows-only test error: the oversized-audio parametrize ID went into `PYTEST_CURRENT_TEST` (> 32,767 chars); short `ids` added.
- Backend: new `conversation.application.spoken_turn`. The text stream keeps flowing while sentences are synthesised (≤ 2 in parallel); audio is still sent in `seq` order; after a TTS failure speech stops (one `speech_unavailable`); a text-provider failure drops pending audio; closing the stream cancels every synthesis. `SentenceSplitter(first_clause_chars=16)` lets the first piece end at ", " / "; " / ": " (decimal "3,5" is not cut). The route maps events only (`_Voice` removed). `finished` gains `firstAudioMs` (turn start → first audio ready); the app ignores `finished` data, so no mobile change. Contract draft and ARCHITECTURE updated.
- Checks: `check.sh` with PostgreSQL PASS (ruff, mypy strict 87 files, alembic upgrade, pytest **140 passed, 0 skipped**, including the voice API SSE tests through the new pipeline). New: `test_spoken_turn.py` (9: overlap, order, parallel cap, TTS failure, no TTS, provider failure, timing, cancel on close, bad limit) and 2 splitter tests. **Not run:** live Edge/Groq, phone timing.
- [WebSocket voice design](docs/roadmap/voice/voice-websocket-design-2026-10-23.md) (Proposed): one `wss /v1/voice` protocol for phone (V1) and board (V2), auth in `hello` (Firebase token / Identity V2 proof), PCM16 phone uplink, Opus board uplink wrapped as Ogg for ASR, `stt.final` → app `turn.commit` keeps teaching behind the local confirmation, `abort` barge-in, slices WS-1…WS-4, decisions D-WS1…D-WS5 for the owner.
- Next: measure five phone turns with this backend (send → first audio) before WS-1 (D-WS5).

## 2026-10-23 — App reconnects to the last XUNA on open (mobile, host only)

- Owner asked to build the "Tự động kết nối khi mở app" setting that was labeled SẮP CÓ. Mobile `device` feature: `DevicePreferences` (auto-connect, last BLE device ID, last PetId) stored through `AppHive` as `device_preferences_v1` (versioned map; unreadable data → defaults); default **on**. Every successful connect (scan list, QR, auto) remembers the device. `HomeController.onReady` → `AutoConnectDeviceUseCase`: `DeviceRepository.find` (new; the BLE scan stops as soon as the remembered ID is seen, max 10 s) → connect → read identity; a different or missing PetId than remembered disconnects again. Failures only change the status line (no snackbar): not nearby → "Chưa thấy XUNA lần trước…", other pet → "XUNA ở gần không phải XUNA lần trước…". The setting row has a real toggle and a note; the wake and audio rows stay SẮP CÓ.
- The stored PetId is a reconnect hint, not pet-life truth (mobile AGENTS §6.1): the device's identity is re-read and compared on every reconnect. New `DeviceExceptionKind.preferencesFailed`; a storage failure never fails a connection.
- Owner follow-up (new owners did not know where to tap after a scan; found devices were plain ID rows): the status card's main button now follows the next step: **TÌM XUNA** → one found: **KẾT NỐI XUNA** (+ "TÌM LẠI") → several: "CHỌN XUNA ĐỂ KẾT NỐI" with a highlighted "KẾT NỐI · <id>" per device. Status text says what to tap ("Đã thấy XUNA. Bấm KẾT NỐI XUNA.").
- Owner follow-up: the chat microphone sat right of centre (hint text flexed on the left, a fixed 96 px note on the right ≈ 35 px offset on a 393 px phone) and was too big. Both sides now flex equally so it is centred; size 96 → 72 px, icon 50 → 32 px, shadow 5 → 4. `home_chat_composer_test` checks centre and size in every voice state.
- Checks (Windows, Flutter 3.32.8 from `~/fvm/versions`): pub get with the lock unchanged, format, analyze clean, **182/182** tests (27 new: use case, repository, controller, widgets). Not run: APK/iOS build, phone, board. The first app open after installing this build has nothing remembered yet; connect once by hand.

## 2026-10-23 — Owner decisions: device checks done, M04, spending, D18

- Owner reported every open phone/board check done: iOS rebuild with mobile `8a42784`, at least five voice turns, QR camera, speaker/earpiece route, microphone with BLE connected, local export + hash check (Cloud gate (c)), board scenes/status card/QR. No timings, p50 or hash output were given, so none are recorded; V1 latency against the ≤ 3 s target stays unquantified.
- Owner chose the recommended options (AGENTS.md §3 "Owner decisions 2026-10-23"): M04 accepted as proposed (open issues 1–2 → M05b); D19/D11a stay on free tiers with owner test data only, revisit with latency evidence and before real users; D18 deferred until V1 is finished.
- Documentation only (AGENTS, PLAN, CHANGELOG, M04/V1/voice-parity records). No code, build or test; no commit.

## 2026-10-23 — Turn context for smarter AI replies

- Owner: replies felt dumb (no time/weekday). Backend `e150330`: optional `clientTime` / `history` / `pet` in the turn body, prompt states time + weekday, earlier lines, learned likes; persona answers knowledge questions, ≤ 5 sentences, no emoji. Mobile `8a42784`: context built from the on-screen chat (templates excluded) and the connected device's `LifeSummary`. Checks: backend check.sh 129 passed; mobile analyze clean, 155/155. Live Groq probe answered time, weekday, name, likes and follow-ups correctly. Contract draft updated. Not run: iOS rebuild, phone turns.

## 2026-10-23 — Phone AI replies: binding and SSE decoder fixed

- iPhone test: speech-to-text worked, every reply was the local template. Local DB had the real pet bound to the test-issuer owner; owner deleted that local binding and re-bound from the app. App `SseCodec` failed on `Stream<Uint8List>` (runtime type error) → fixed in mobile `006cf5b` with a regression test; real-Dio replay now reads 27 deltas + audio + finished. analyze clean, 152/152. Not run: iOS rebuild/install, Android APK rebuild. [V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md).

## 2026-10-22 — Board upload of firmware `0a392c5`

- Backup `/Users/xthao28/xuna_backups/2026-10-22-v1-scenes/` (partition = build, two NVS reads identical), upload SUCCESS `b13ee96f…`, boot `recover=Ok … boot=28 ready=1`, same PetId and preferences, 40 s idle log clean. Details in the [M04 record](docs/roadmap/milestones/M04-foundation.md). Owner visual check pending.

## 2026-10-22 — V1 phone voice, slice 3 preparation

- Backend: migration 0003 → 0004 on `xuna_local`; `.env.groq` completed with `XUNA_ASR_PROVIDER`/`XUNA_TTS_*`; new gitignored `.env.groq-text` (Groq `openai/gpt-oss-120b`, reasoning low, key reused by variable). Run: `set -a; source .env.groq; source .env.groq-text; set +a; XUNA_DATABASE_URL=… .venv/bin/uvicorn xuna_backend.main:app --host 0.0.0.0 --port 8000 --no-access-log`. A stale uvicorn from 2026-10-17 held port 8000 and was stopped. Backend `bb905d9`: emojis dropped before TTS; check.sh 125 passed.
- LLM re-check (`text_benchmark.py`, 14 prompts): Gemini 3.5 flash-lite free 6376 ms TTFT median, 3 failures; Groq gpt-oss-120b 922 ms, gpt-oss-20b 880 ms, qwen3.8-27b 434 ms, all 0 failures. Replies read: gpt-oss-120b chosen (natural, persona-correct). Table in the V1 record.
- Mobile `539630c`: Android toolchain bump (owner-approved) so the APK builds again; `pubspec.lock` unchanged; debug APK built with the LAN URL. Not run: install on a phone, iOS build (Xcode 14.2 here), flutter tests (no Dart change).

## 2026-10-22 — V1 phone voice, slice 2 (app)

- `record` 6.2.1 + `just_audio` 0.10.6 (pinned); new `voice` feature; `account` gets U3V consent, transcription and spoken reply events; the chat mic works (tap/tap, 15 s, cancel); consent sheet U3V row; Android/iOS mic permissions. Speech takes the typed-text path (teaching still needs confirmation). [V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md).
- Checks: analyze clean, 151/151. Not run: native build, phone. Persona updated the same day (owner): XUNA hears the owner via the app mic, never sees or hears the room; benchmark 0 sensing claims but Gemini free tier TTFT ≈ 7.9 s today (risk). Open: phone measurement.

## 2026-10-22 — V1 phone voice, slice 1 (backend)

- Owner approved D16 and the V1 targets. Design: the app transcribes via the backend, then sends the transcript through its normal text path (teaching still needs confirmation); spoken replies via `speak: true`. New consent class U3V `conversation_voice` (migration 0004; PUT without it keeps it).
- Backend: `openai_transcription` ASR (Groq, kept-alive client), `edge` TTS (`edge-tts` 7.3.1, LGPL) and optional `piper` TTS (`.[piper]`, GPL), `POST /v1/speech/transcriptions`, SSE `audio` / `speech_unavailable`. `XUNA_ASR_*` / `XUNA_TTS_*` settings. AGENTS D16 and backend rule 7 updated; contract draft and ARCHITECTURE updated.
- Checks: check.sh with PostgreSQL 125 passed. Live: Groq via adapter 351 ms warm; Edge first audio 3.4 s (unreliable). Not done: app, phone run.

## 2026-10-22 — Voice V0: corpus, small ASR/TTS runs, Xiaozhi research

- Owner: mic + speaker are INMP441 + MAX98357A; skip Phase S for now; voice through the app first; V0 free/local only, synthetic corpus first; **do not run Xiaozhi**, study it instead; keep runs small on this Mac (2014 i7); try free cloud ASR; continue on a stronger machine.
- `backend/scripts/voice_bench/` (own venv, not backend deps; [README](backend/scripts/voice_bench/README.md)): 30 sentences × 2 Edge voices × clean/10 dB noise = 120 WAVs (gitignored, rebuilt per machine); `asr_bench.py` (faster-whisper), `asr_cloud_bench.py` (Gemini audio / OpenAI-compatible transcriptions), `tts_bench.py`. `scripts/check.sh` passes (83 passed, 16 DB tests skipped).
- Results (small): Whisper `small` WER 13 % (7.9 % clean with prompt "XUNA"), 5 s per 3 s audio on this Mac; Gemini audio WER 0 % clean but 13–21 s + 503s; Edge TTS first audio 0.47–0.63 s but flaky. [Xiaozhi research](docs/roadmap/voice/xiaozhi-stack-research-2026-10-22.md): Opus 16 kHz/60 ms WebSocket or MQTT+UDP, ESP-SR wake word, FunASR/SenseVoice default ASR (no Vietnamese), streaming Chinese vendors recommended.
- Groq key added by the owner (`backend/.env.groq`, gitignored, recreate per machine). Groq `whisper-large-v3-turbo`: WER 5.3 % (clean and 10 dB noise, 10 utterances), median ≈ 1.8 s with Ogg/Opus upload vs 2.3–4.8 s with WAV. D16 still needed before V1.

## 2026-10-22 — Voice parity plan (Proposed)

- Owner asked for a plan to at least match Xiaozhi on its strongest area (spoken conversation) while making XUNA's core stable. [Plan](docs/roadmap/voice/voice-parity-plan-2026-10-22.md): Phase S (stabilise board/phone) + V0 (measure Xiaozhi locally on the same Vietnamese corpus) → V1 voice through the phone → V2 device voice (audio hardware) → V3 breadth; memory/backup in parallel. Waiting on owner decisions D16, D19/D11a (spending), D18 (hardware), Xiaozhi code reuse.

## 2026-10-22 — App scans the pairing QR

- Owner approved the scanner dependency: `mobile_scanner: 7.4.2` (BSD-3). New `pairingScan` route, `ParsePairingCodeUseCase`, `ConnectPairedDeviceUseCase` (matches PetId via the identity read), device-tab button, iOS camera usage text. [Record](docs/roadmap/ui/device-scenes-2026-10-22.md). Phone and board runs not done.

## 2026-10-22 — Status card and pairing QR (host only)

- Owner asked for items 4–5. GPIO0 hold → 8 s status card (Vietnamese, Be Vietnam Pro glyphs); both buttons 3 s → 60 s pairing QR `xuna://pair?pet=…&key=…`; any press closes a card. Both buttons now act on release; combos swallow single-button events. Vendored `lib/qrcodegen` (MIT). [Record](docs/roadmap/ui/device-scenes-2026-10-22.md).
- Native/ASan 240/240, ESP32 build PASS (Flash 2,995,977 B). Not on the board yet. App-side scanning added in the next entry.

## 2026-10-22 — Window scenes and reaction effects (host only)

- Owner approved: heart/puff when a reaction teaches, window by day part, GPIO14 hold (≥ 800 ms) cycles Auto/Day/Evening/Night/Rain with a sparkle. GPIO14 short press now fires on release. Hold ignored before hatch (S10 reserves the 3 s Egg hold). Scene stored in NVS `xuna_ui/scene`. [Record](docs/roadmap/ui/device-scenes-2026-10-22.md).
- Native/ASan 232/232, ESP32 build PASS (Flash +52 KB, heap +13 KB). Owner unplugged the board (warm); **not uploaded**. Next with the board: NVS backup, upload, visual check, `scene_max_us`/loop gap with rain.
- Correction: the 2026-10-16 status line "GPIO0 is direct Happy" is outdated; GPIO0 greeting learning is on since 2026-10-19.

## 2026-10-22 — Board upload and S21 target parity

- Owner connected the board. Backup `/Users/xthao28/xuna_backups/2026-10-22-s20-routine/`: partition byte-identical to 2026-10-17; NVS read twice, only `bootc` differs (esptool reset boots), `ident`/`devkey`/`life0`/`life1`/`slot0`/`slot1` identical. Upload of `d1b17b8` SUCCESS (app SHA-256 `02c2fcee…2640764c`); boot `recover=Ok slot=0 corrupt_slots=0 boot=21 ready=1`, PetId `d945c770…ed86`, quiet=1 play=0, setup stack 7,300 B. This closes the S19b "next upload must re-check the boot log" item.
- S21 steps 1–2: `[env:xuna_parity]` (`src/parity/parity_main.cpp`; `tools/embed_parity_traces.py` embeds c3, c8, c9; production env now filters out `src/parity/`, image unchanged). Board output **bit-identical** to `sim/lifecore_lab` (24 lines incl. snapshot SHA-256), c9 expects 6/6, two passes identical. `step()` µs: quiet p50/p99 7/7, max 272; event steps ≤ 313. Core change: optional `LifeCoreStepProbe` in `LifeCoreTrace.h` + test (does not change replay). Native 225/225, ASan 225/225; parity and production builds + purity PASS.
- Production re-uploaded after the parity run (same SHA-256); boot `recover=Ok slot=1 boot=23 ready=1`, same PetId.
- S21 step 3: [M04 record](docs/roadmap/milestones/M04-foundation.md). Step 4 (owner review) pending. Not run: real power cut on the board, render ±20 %, phone/app. Nothing committed.

## 2026-10-20 — Routine learning (part C, firmware host only)

- `xuna/learning/HabitPredictor.h`: 48 slots (hour × weekday/weekend) Q8.8 + mean arrival minute (u8 EMA ¼); session = owner input after ≥ 30 min [P] with trusted time (TimeSync alone is not presence); decay 0.95/day [P]; P(slot) with κ 0.5 for prequential Brier scoring (EMA ⅛, gate > 0.02 [P] and ≥ 10 sessions [P]); P(hour | day type) ≥ 4× uniform [P] marks likely hours; a likely run gives a count-weighted arrival estimate; ~20 min [P] before it `LifeCore::routine` asks `ActionGate` for curious once per run/day (not when sleeping/tired, not right after owner input). Snapshot section 7 Habit v1 (152 B, optional), lazy checkpoint, cleared by forget. Output flags `sessionObserved`, `anticipated`.
- Life Lab `learnsRoutine` (BoardLab, daily app sync, presses every 10 min for 30 min): routine owner (19:00 / 09:00 ± 20 min, 28 days, seeds 21–25) gate open, 4–6/7 last-week days on time (≤ 80 min before; the last simulated day ends before arrival), **0 false alarms**; random owner never ready, **0 anticipations**. Iterations: hour-only bins fired ~1 h early and missed weekends → added the mean minute and within-day-type probability (deviation from plan §9.7, recorded).
- Tests: `test_habit` (7) + routine scenario test. Native **224/224**, ASan 224/224 (before a rename), ESP32 build + purity PASS (RAM 52,848 B, Flash 2,883,645 B). Build found ESP-IDF's `likely()` macro clashing with a member named `likely` → renamed `isLikely`. Golden unchanged.
- Not done: app display (needs a BLE read), board trial, drift test. No board, phone or app change.

## 2026-10-19 — Reaction learning replaces app ratings (owner decision)

- Owner: app "chọn → thích/không thích" is meaningless and tedious; approved (a) reactions on the device teach, (b) routine learning, (c) remove app ratings. Recorded as **D6 revised** in AGENTS.md §3; design freeze and evidence: [reaction-learning record](docs/roadmap/learning/reaction-learning-2026-10-19.md).
- Firmware: `PreferenceLearnerV3::feedback` takes a weight (`reactionWeightQ16` 0.3 [P]); `ProductLearner` reaction window 10 s [P], source 3; `LifeCore` `Reaction` and `Spontaneous` events, `reactionApplied`; `V1LifeCoreAdapter` GPIO0 inside the window = pet, GPIO14 = shoo then idle, `localSpontaneous`; `main.cpp` greeting learning on and the idle routine calls `localSpontaneous`. Snapshot episodes section v2 only when a source-3 episode exists (found: old decoder treated source 3 as corrupt → boot read-only). Tests: 4 adapter, 1 codec, `learnsFromReactions` scenario; S01 transcript and greeting tests moved their presses outside the window. Native and ASan **216/216**, ESP32 build + purity PASS (RAM 52,520 B, Flash 2,881,425 B). Golden vectors gained pet / greeting / shoo steps.
- Mobile: removed rating chips, rating confirmation, journal rating buttons and pending card, `SendFeedbackUseCase` and `DeviceRepository.sendFeedback`; rating words in chat get `home_replyReactOnDevice`; statements still need confirmation. `InteractionContext.greeting` (memories only, never sent), `EpisodeSource {button, text, reaction}`, codec accepts context 2 / source 3, journal and export labels. Locales synced (11 keys removed, 3 added). **124/124**, analyze clean, lock unchanged. Backend export schema accepts `greeting`/`reaction`; `check.sh` **99/99**.
- Not run: board, phone, APK. Next: part C routine learning design; board trial of window/weight; app poke as a reaction needs a protocol addition.

## 2026-10-19 — S20 golden vectors and Dart conformance (firmware + mobile, host only)

- Firmware `sim/golden.cpp`: `BoardLab` booted from a blank v1 snapshot (migrated pet, no history; an Egg device would answer not_ready), 27 v1 frames with request IDs 1…27 and realistic gaps (30 s between suggestions, ratings after 5 s): suggestions in both contexts, approve/reject from button and text, a consumed rating, an unknown target, a direct action that invalidates the decision, a stated preference, forget. Each step records frame hex, result and the 20-byte life + two memory pages. Output deterministic. `simulatorSkips`: learner fields (chosen action, both preferences, episode action) and `activeSeconds` (no clock).
- Mobile: `test/fixtures/firmware/learning_v1.json` (+ README update procedure, no symlinks) and `firmware_golden_test.dart`: frames byte-identical from `ProtocolCodec.encode`; every life/memory value decodes; simulator results, decision IDs, `canFeedback`, feedback counts, memory counts and episode context/rating/source match at every step.
- **Bug found and fixed:** firmware chose curious at step 3, and `ProtocolCodec.decodeLife`/`decodeMemoryPage` rejected codes above happy → `FormatException`, which the Home controller treats as a disconnect. On a phone this would have happened at the first curious choice. Now accepts up to curious (mapper already did). Verified the golden test fails without the fix.
- Simulator: Dart learner removed (mobile AGENTS §6.2, G17 resolved in the gap table); suggestions show idle; stated preference no longer increments the feedback count; `memoryCount` = episodes. Rewritten tests: controller text-feedback (idle after a new suggestion), stated preference (asserts opcode 6 was sent; count stays 0 as on firmware), use-case "records feedback once and never learns"; `home_page_test` journal check scrolls the lazy list (`_scrollTo`).
- Checks: mobile pub get (lock unchanged), analyze clean, **125/125**; firmware golden built with -Werror. Simulator UX change: the journal shows idle choices in simulator mode (honest: it never learned). No board, phone, APK rebuild.

## 2026-10-19 — S19b Life Lab scenarios (firmware, host only)

- Owner delegated the S19b approach. Chosen: move `main.cpp` setup()'s boot policy **unchanged** into `xuna_core/life/BootSequence.h` (`IBootStore` = snapshot slots + identity + `bootc`; `NvsSnapshotStore` now implements it; entropy via `IRandom`, `esp_random()` on the board) so the Life Lab replays the same code as the board. `main.cpp` calls it; prints and `adapter.begin` stay in `main.cpp`. Rejected: a copied boot path in `sim/` (would drift, G17-style).
- `xuna/lab/BoardLab.h`: setup()/loop() replica (production adapter flags `false,true`, LocalBehavior quiet routine, five-minute checkpoint, RAM rebuilt on reboot, torn-write power cut). `xuna/lab/LifeScenarios.h`: D, E, stability; `test/test_life_lab_scenarios` (6 tests) and `sim/scenarios.cpp` (runtimes).
- Results (1 s steps): **D** PASS — 8.64 M steps, 800 suggestions, 100 syncs, 28,800 checkpoints, learner bit-identical to fresh, 0.96 s. **E** PASS — 16 boots, 5 power cuts, 80 acks = durable count (+4 from the v1 fixture), 15/15 resent ratings rejected, PetId stable, max age loss 295 s, 0.02 s. **Stability** PASS — 100 days, 10 boots, 546 suggestions, 276 acks, feedback count = acks at every step (reset by forget on day 50), 0.98 s. Two runs identical apart from runtime.
- Checks: native **210/210**, native_asan scenario suite **6/6** (full ASan 208/208 before the two boot tests), ESP32 build + purity PASS (RAM 52,504 B unchanged, Flash 2,880,733 B, +220 B). **Not uploaded**: the board still runs the 2026-10-17 image; the next upload must re-check the boot log (`recover=Ok … ready=1`, same PetId).
- **Finding, fixed the same day (owner delegated the decision):** a never-migrated, unhatched (Egg) device wrote v2 snapshots on feedback; the next boot saw "snapshot Ok + identity Missing" and stayed read-only. The current board was unaffected (migrated pet); every new board would have hit it. Kept the deliberate S13/S18 rule (missing identity next to a v2 snapshot = damage, never invent a new PetId) and closed the hole instead: `IdentityGatedCommit` refuses every snapshot write before an identity exists, and lazy checkpoints run only when `persistReady()`. An Egg device lives (animation, BLE) but does not learn: ratings answer `not_ready` (7) until it hatches (S10-hatch, still deferred). Scenario D now starts from a migrated pet and compares with its boot learner (RAM and after a reboot). Test `boot_unhatched_device_never_saves_and_keeps_booting`. Re-checked: native 210/210, ASan 210/210, ESP32 build + purity PASS (RAM 52,512 B, Flash 2,880,857 B).
- Next: S20 (golden vectors) is now unblocked.

## 2026-10-19 — S19a Life Lab (firmware, host only)

- Owner chose S19a (S20 is gated by S19a/S19b). Most of S19a already existed (`@+` parser, `LifeCoreTraceRunner`, A/B memory store with power cuts). Added in `LifeCoreTrace.h`: `day <n>` (1–3650 days, one `LifeCore` step per minute, 64-bit offset so traces pass the `millis()` wrap), `expect <path> <op> <u32>` (19 snake_case paths; unknown path = invalid trace; failures counted, first failure recorded), core clock restart at 0 on `reboot`, SHA-256 of the encoded snapshot, explanation of the last shown decision (same projection as `V1LifeCoreAdapter`). `lifecore_lab` prints them and exits 1 on a failed expectation; the first 17 CSV columns are unchanged.
- Grammar/outputs frozen in `firmware/sim/README.md` (S19a step 1). Kept file names: `lifecore_lab.cpp` is the S19a Life Lab; `lifelab.cpp` stays the learner-only runner. New trace `c9_lifelab_days.trace` (60 days + reboot, 6 expectations). `c7` header/expect updated because `day`/`expect` are no longer unsupported.
- Checks: native **204/204**, native_asan **204/204**, ESP32 build + purity PASS (RAM 52,504 B, Flash 2,880,513 B). All 9 `c*.trace` give identical output on two runs; traces c1–c8 match the previous runner on the first 17 columns except the intended `c7` unsupported 2→0. 60-day trace: 0.05 s.
- Found: active time and the five-minute lazy checkpoint live in `V1LifeCoreAdapter`, not `LifeCore`, so the Life Lab does not age the pet or write during quiet days. S19b scenario E ("no negative age") needs either the adapter in the runner or a decision — raise at S19b start. No board, phone or commit.

## 2026-10-19 — Mobile locale sync, teaching confirmation details, per-context journal count

- `test/generated/locales_sync_test.dart` compares `vi_VN.json` with `Locales.vi_VN` (keys and texts). It found `home_replyNeedContext`, `home_replyStatedUnsupported`, `home_replyConfirmTeaching` (used, unaccented, JSON-less) and `home_replyTeachingApplied` (unused, removed). `home_replyConfirmTeaching` had no `@details`, so the chat bubble omitted the candidate (the review row below already showed it); now "Xác nhận đây là điều bạn vừa nói với XUNA: @details", asserted in the stated-preference controller test. `get generate locales` is now safe to run.
- Checks: pub get (lock unchanged), format, analyze clean, **120/120** tests.
- Emulator run (`Pixel_XL_API_30`, debug APK with `XUNA_SIMULATOR=true`, driven by adb): simulator label shown, connect, "Chơi nhé" → "Thích" → bubble "Xác nhận đây là điều bạn vừa nói với XUNA: like | reaction 1 | user_feedback" → confirm → honest "chưa có dữ liệu giải thích" reply; no Flutter errors in logcat. iPhone 13 Simulator not possible: Xcode 14.2 (macOS 12 max) is below Firebase iOS SDK 11.10's Xcode 15.2.
- Found on the emulator: Journal "Học được" cards used the device-wide `life.events` per context (`home_journal_entry.dart`), so after one Play feedback the Quiet card also said "rút ra từ 1 phản hồi". Owner chose option A: each card cites only its own context's retained episodes ("XUNA học từ phản hồi của bạn khi chơi (1 phản hồi gần đây còn lưu)" / "Chưa có phản hồi gần đây khi yên tĩnh."). New test; 121/121, analyze clean, lock unchanged; re-checked on the emulator.

## 2026-10-19 — Phone-free device E2E (option A)

- Owner chose option A: keep the simulator without a device key (mobile AGENTS §6.6) and simulate the board on the backend side instead. Added `backend/scripts/device_e2e.py` (real uvicorn subprocess, local OIDC issuer with JWKS on localhost, firmware-layout proof frames signed with a software P-256 key, request bodies copied from `cloud_repository_impl.dart`, random PetId per run).
- Results against `xuna_test`: 15/15 PASS with `echo` and with Gemini `gemini-3.5-flash-lite` (synthetic prompt, 240-char Vietnamese reply, 1,536 ms). `scripts/check.sh` 98/98 with PostgreSQL. Not covered: BLE long write/MTU, Flutter UI, Firebase tokens.
- Dev binding reset (next-session step 1) **not done**: the `DELETE` on `xuna_local` (`brains`/`devices`/`pets` rows of PetId `d945c770…`, test owner `b091…`) was blocked by the permission classifier; the owner must allow it or run it. Nothing was changed in `xuna_local`.

## 2026-10-17 — CLD-13 Gemini benchmark (temporary provider)

- Owner provided the internal AI URL (Bifrost gateway `SDS-AI`, reachable over VPN, needs a virtual key in `x-bf-vk` — not yet provided) and chose **Gemini** as the temporary provider. Key stored by the owner in gitignored `backend/.env.gemini` (mode 600); commands only `source` it, the key was never printed.
- Results ([record](docs/roadmap/cloud/CLD-13-benchmark-2026-10-17.md)): `gemini-3.5-flash-lite` 12/12, TTFT median 0.92 s, all persona checks pass → temporary model. `gemini-3.8-flash` truncated by hidden reasoning; with `reasoning_effort=none` complete but free-tier 429s.
- Backend: `XUNA_TEXT_API_KEY_HEADER`, `XUNA_TEXT_REASONING_EFFORT`, benchmark `--delay`; 93/93 tests with PostgreSQL. Free tier = synthetic prompts only; paid tier required before real users. Persona needs a "no hearing/seeing claims" rule.

## 2026-10-18 — Mobile bind flow, consent sheet, AI chat; persona rule

- Owner asked for the 2026-10-17 plan steps 1–5 plus AI chat and a persona fix; no phone yet, so code + tests + APK only (no BLE, no board).
- Mobile (`features/device`): capability byte 3 bit 0, `DeviceProofCodec` (40 B request / 141 B response, firmware layout), `awaitDeviceProof` poll (150 ms, 5 s timeout, request ID must match, never resent), `requestBindProof` in the BLE transport (GATT long write because the MTU stays default — **unverified on the board**), proof status → `proofUnavailable`/`proofFailed`. Simulator has no proof.
- Mobile (`features/account`): `CloudRepository` gained challenge/bind/pets/consents/SSE turn with a fresh `Idempotency-Key` per mutation and `schemaVersion: 1`; problem `code`s (`challenge_invalid`, `invalid_signature`, `pet_already_bound`, `device_key_mismatch`, `consent_required`, `consent_version_conflict`, `not_found`, `unauthorized`, `provider_unavailable`) → Vietnamese messages; `BindPetToCloudUseCase` (capability → identity → challenge → proof → bind, signed generation sent); `StreamCloudReplyUseCase` turns every failure into a local fallback.
- UI: Device-tab account card shows bound/unbound, "Gắn XUNA với tài khoản" (signed in + connected), "Quyền dữ liệu" sheet with U1/U2/U3 off by default and explicit save. Chat: only free text that the local parser does not understand goes to the AI, and only when signed in + pet bound + U3; reply streams into one bubble tagged "AI · không ghi nhớ"; teaching/device intents stay local; any failure → existing local template.
- Tests found a real bug: a consent version conflict tried to reload while the controller was still busy, so the sheet stayed empty; fixed. `locales.g.dart` holds keys missing from `vi_VN.json` (e.g. `home_replyNeedContext`), so `get generate locales` would drop them; new keys were added by hand to both files.
- Checks: Flutter analyze clean, **119/119** tests, debug APK PASS, lock unchanged. Backend persona rule + benchmark `noSensingClaim`; `scripts/check.sh` **98/98** with PostgreSQL; Gemini benchmark 14/14, TTFT median 0.85 s, all checks 1.00 ([record](docs/roadmap/cloud/CLD-13-benchmark-2026-10-17.md)). Committed locally at the time; pushed to `origin/dev` by 2026-10-19.

## Next session plan — phone validation of bind + AI chat (updated 2026-10-18)

1. Reset the dev binding first: `xuna_local` still binds PetId `d945c77026fd4f4a8a899bbff4aeed86` to the *test* owner from the Identity V2 E2E, so a real bind would return `409 pet_already_bound`. Dev DB only; audit/consent tables are append-only by trigger (leave them).
2. Optional pre-check without the phone: `backend/scripts/device_e2e.py --database-url …/xuna_local` (simulated board, app-shaped requests). Backend: `XUNA_FIREBASE_PROJECT_ID=xuna-pet`, Gemini via `set -a; source .env.gemini; set +a` (never print the key), uvicorn `--no-access-log` on `0.0.0.0:8000`.
3. Build: `fvm flutter build apk --debug --dart-define=XUNA_API_BASE_URL=http://<Mac LAN IP>:8000`, `adb install -r`.
4. On the phone: sign in → connect the board → "Gắn XUNA với tài khoản". Watch the board log `device_proof status=2`; if the 40-byte long write fails, fall back to `requestMtu` before the proof (decision for that session). Check `GET /v1/pets` and `GET /v1/audit-events`.
5. "Quyền dữ liệu" → U3 on → chat free text ("kể chuyện đi") → streamed AI reply tagged AI; turn the backend provider off (or VPN) → local template, no crash. Teaching phrases must still ask for confirmation.
6. Then the remaining gate (c) steps from the header (export hash check).

## 2026-10-17 — Firebase Google sign-in validated end to end

- Owner enabled Google sign-in and re-downloaded `google-services.json` (now has Android OAuth client with the debug SHA-1 `cb679da2…` and a web client). Replaced the gitignored file, rebuilt the APK.
- `Pixel_XL_API_30` (google_apis, no Play Store, GMS 20.18) fails with `ApiException 12500` — handled as a localized error, no crash. `Medium_Tablet_API_33` (Play Store) works: owner added their Google account in the emulator, app showed the signed-in email, **"Kiểm tra kết nối XUNA Cloud"** → local backend (`XUNA_FIREBASE_PROJECT_ID=xuna-pet`, port 8000) logged `GET /v1/me 200` (692 ms incl. Google JWKS) and created owner `4e9ee98f…` with issuer `securetoken.google.com/xuna-pet`.
- Found and fixed a real bug: the 30 s timeout also covered the interactive Google picker and cancelled the owner's first attempt while typing credentials (`TimeoutException`). Picker now allows 5 minutes; network steps keep 30 s. Analyze clean, 77/77 tests.
- Observed but not changed: on a landscape tablet the Home pet scene is oversized (layout is phone-first). Emulators were closed twice during the session by something outside this session.

## 2026-10-17 — Mobile Firebase Auth (Google) account feature

- Owner created Firebase project **`xuna-pet`** and supplied `google-services.json` (placed at `mobile/android/app/`, gitignored; checked: package `com.example.xuna_mobile`, **no `oauth_client` yet** → Google provider/SHA-1 not active when downloaded). Debug SHA-1 `CB:67:9D:…:50:F3` given to the owner.
- Mobile: new `account` feature (domain entities/exception/use cases, Firebase+Google data source with timeouts, Dio `/v1/me` client from `--dart-define=XUNA_API_BASE_URL`, error translation), optional "Tài khoản" card in the Device tab (sign in, check cloud, sign out), Firebase init that never blocks local life, INTERNET permission, debug-only cleartext. Pinned `firebase_core 3.13.0`, `firebase_auth 5.5.2`, `google_sign_in 6.3.0`, Gradle plugin 4.4.2; lock only added 13 packages (no version changes). `minSdk` 21 → 23 (firebase_auth requirement).
- Widget-test helpers made scroll-position independent (the longer Device tab exposed a lazy-list finder assumption). Flutter analyze clean, **77/77** tests, debug APK PASS. Backend with `XUNA_FIREBASE_PROJECT_ID=xuna-pet` fetched Google's real JWKS and rejected a forged token (401). No real Google sign-in yet (needs oauth client + device); no push.

## 2026-10-17 — Firebase Auth preset and internal-AI text provider (CLD-13)

- Owner chose **Firebase Auth** and asked for a temporary way to use their internal AI behind OpenVPN. Backend: `XUNA_FIREBASE_PROJECT_ID` preset (issuer `securetoken.google.com/<id>`, Google JWKS); `openai_compatible` streaming adapter (httpx, SSE, tool-call deltas, timeouts, VPN/HTTP failures → `ProviderUnavailableError`, no prompt/output logging); provider chosen by `XUNA_TEXT_*` at startup; `POST /v1/conversations/{petId}/turns` SSE with XUNA Vietnamese persona, U3 guard, own-pet check, nothing stored (test scans every table for the private text), outage → `error provider_unavailable`. `Settings.__repr__` hides secrets. httpx moved to runtime deps (same pinned version).
- `scripts/text_benchmark.py` (12 synthetic Vietnamese prompts incl. a prompt-injection, TTFT/total latency, Vietnamese/length/no-false-memory heuristics; results gitignored) and `docs/ops/internal-ai-over-vpn.md` (dev via OS VPN client; hosted via OpenVPN sidecar sharing the API network namespace; secrets never in Git).
- `scripts/check.sh` PASS: ruff (incl. scripts), mypy strict (82 files), pytest 91/91 with PostgreSQL (75 + 16 skipped without). Benchmark smoke with `echo` only — the internal AI was **not** reached (no URL/VPN in this session). No mobile change, no push.

## 2026-10-17 — Backend CLD-12: consent enforcement and audit

- Owner delegated the next step; chose CLD-12 (no external dependency). `consent`: U0 default, U1/U2/U3 separate opt-ins, append-only versioned history with policy tag, `expectedVersion` conflict, idempotent `PUT /v1/consents`, `RequireConsent` guard for future data routes. `audit`: typed content-free events (free text rejected by the domain type), `GET /v1/audit-events`; pet bindings, bind rejections and consent changes are recorded in the same transaction. Migration `0003` adds DB triggers making `audit_events`/`consent_records` append-only.
- `scripts/check.sh` PASS: ruff, mypy strict (76 files), pytest 78/78 with PostgreSQL (66 + 12 skipped without), including trigger rejection of UPDATE/DELETE. Rules updated in `backend/AGENTS.md`. No board/phone; no push.

## 2026-10-17 — Firmware Identity V2: device key and BLE proof (board E2E PASS)

- Owner chose Identity V2. Pure `Sha256` + `DeviceProof`/`ProofService` in `xuna_core`, mbedTLS `DeviceKey` (P-256, NVS `devkey`, never overwritten if corrupt, RFC 6979), BLE `7a6e000d` WRITE/READ with capability byte 3 bit 0. Projection proofs refused.
- Firmware native/ASan 200/200, ESP32 PASS (52,504 B RAM / 2,880,513 B Flash). NVS backed up (`2026-10-17-identity-v2/`), upload PASS; key created (161 ms) then loaded on reboot with the same public key.
- E2E from the Mac: backend challenge → board signs (~74 ms) → `POST /v1/pets` 201 then 200 with same Brain against local PostgreSQL. No phone, no hosted service, no push. [Record](docs/roadmap/cloud/identity-v2-2026-10-17.md).

## 2026-10-17 — Backend CLD-11: owner auth and device-proof pet binding

- Owner delegated all choices ("cứ quyết định theo ý bạn"). Recorded CLD-01 §4 decisions as approved (AGENTS §3); switched device proof to **ECDSA P-256** because ESP-IDF 4.4 mbedTLS lacks Ed25519. Committed earlier work locally: firmware `aad7093`, mobile `86e0251`, backend `37f845e`, parent `5dfda6e` (no push).
- Backend: `accounts` (vendor-neutral OIDC JWT via JWKS, owner upsert by issuer/subject, `GET /v1/me`), `identity` (proof message golden vector, single-use 5-minute challenges, TOFU binding → Pet + active Brain + Device, owner-scoped reads returning 404 for others), `core.idempotency` (24 h replay, reuse → 409), UTC sessions, migration `0002`. New pinned deps PyJWT 2.10.1, cryptography 44.0.0 (delegated approval).
- Tests found and fixed a real bug: PostgreSQL returned `+07:00` times; sessions now forced to UTC. Architecture test tightened (api may not import SQLAlchemy).
- `scripts/check.sh` PASS: ruff, mypy strict (55 files), pytest 59/59 with PostgreSQL (52 + 7 skipped without), migration round trip. No real OIDC provider, firmware signing or phone involved.

## 2026-10-17 — Backend workstream C: CLD-10 scaffold, CLD-01, CLD-02 drafts

- No phone available, so the owner moved on to the backend and delegated structure and rules, asking to reference xiaozhi-esp32-server (MIT; structure inspected via GitHub, ideas only, no code copied) and match or beat it.
- `backend/`: FastAPI + async SQLAlchemy 2 + Alembic + Pydantic 2 modular monolith with `domain → application → infrastructure/api` per module; `core` (env-only config, async DB, RFC 9457 problems, request ID + content-free access log). Modules: `health` (`/healthz`, `/readyz`), `identity` (`PetId`, wrap-safe `ProjectionKey`), `exports` (`xuna.export.v1` hash + strict schema; golden fixture generated by the mobile Dart code), `cognition` (typed async ports for text/vision/VAD/ASR/TTS/tools, `ProviderRegistry`, echo adapter; no vendor). Baseline Alembic revision, CI workflow (PostgreSQL 16), `scripts/check.sh`.
- Rules for future agents: `backend/AGENTS.md` (+ `docs/ARCHITECTURE.md` with the Xiaozhi comparison); layer rules enforced by `tests/test_architecture.py` (negative check confirmed it fails on violations). Root AGENTS/CLAUDE point to it.
- Checks (Mac, PostgreSQL 14.15): ruff format/lint clean, mypy --strict clean (29 files), pytest 38/38 with PostgreSQL (36 + 2 skipped without), Alembic upgrade/downgrade round trip, uvicorn smoke `/healthz` + `/readyz` OK. CI not run on GitHub (nothing pushed).
- Parent docs: [threat model](docs/architecture/XUNA_CLOUD_THREAT_MODEL.md) (Proposed: ordering key, BrainId semantics, exports are claims until device-signed, no upload before device credentials) and [contract draft](docs/architecture/XUNA_CLOUD_CONTRACT_DRAFT.md) (not frozen). Pinned deps exact (FastAPI 0.115.6, SQLAlchemy 2.0.36, Alembic 1.14.0, psycopg 3.2.3, Pydantic 2.10.4). No device data stored, no provider chosen, no commit/push.

## 2026-10-17 — Board session D (firmware part): gate (b) met

- Owner connected the ESP32. Backed up partition (identical to 2026-10-16) and NVS (`/Users/xthao28/xuna_backups/2026-10-17-cloud-gate/`); decoded pet: PetId `d945c770…`, generation 38, active 7,889 s, feedback 5; v1 rollback slots intact. App read-back failed again with the known USB short read (not retried).
- Upload 1 boot OK, but a Mac BLE listing exposed a real defect: `createService` defaulted to 15 GATT handles, silently dropping `000b` and `000c` (explanation never worked on a board since S26). Fixed with a 32-handle service; ESP32 build PASS; upload 2 SUCCESS (app SHA-256 `381f7751…d587`).
- Mac BLE acceptance: capabilities `0xbf`; identity PetId equal to Serial/NVS, origin 3, generation 38; TimeSync result 0 → Serial `quality=2 day_part=3` (Synced, evening); suggest quiet → Happy with explanation highest estimate, rated 3, p ≈ 0.79. Nothing rated or taught.
- No phone attached: APK not installed, app "Why?" and export not run — gate (c) pending. No commit/push. Details: [sprint record](docs/roadmap/cloud/cloud-gate-sprint-2026-10-17.md).

## 2026-10-17 — Cloud gate workstreams A + B (Identity V1 and local export)

- Owner asked to finish the remaining Cloud gate conditions with delegated decisions. Firmware: pure `IdentityCodec` (24 B), READ `7a6e000c`, capability byte `0xbf`, cached update on change after snapshot commits. Mobile: identity decode/model/use case, `ExportDeviceDataUseCase` + local file repository writing `xuna.export.v1` with SHA-256, Device-tab export button, PetId in the device info sheet. Simulator never exposes an identity, so it cannot export.
- Delegated choice: `crypto` promoted to direct dependency at the already-locked 3.0.7 (lock changes only dependency type). `share_plus` not added; Android file stays in the app sandbox (adb `run-as` retrieval documented).
- Firmware native 195/195, ASan 195/195, purity + ESP32 build PASS (52,112 B RAM / 2,852,645 B Flash). Flutter analyze clean, 72/72 tests PASS; Python cross-check of the export hash PASS. Debug APK build PASS (not installed).
- Gates (b)/(c) are **implemented in source, not met** until the board session D. No board, phone, upload, commit or push. [Sprint record](docs/roadmap/cloud/cloud-gate-sprint-2026-10-17.md) has the format and acceptance steps.

## 2026-10-17 — Cloud gate sprint decisions (handoff)

- Owner asked to accelerate toward Cloud. Chose all recommended options: app-side JSON export for gate (c); backend CLD-01/02/10 may start now in parallel; one combined board upload/acceptance; commit S10-sync now (firmware `f339fff`, mobile `d34c63b`, parent `b7d71cc`; no push).
- Proposed Identity V1 (24 B READ `7a6e000c`, capability bit 7) and workstreams A–D in the [sprint record](docs/roadmap/cloud/cloud-gate-sprint-2026-10-17.md). Session stopped at the owner's request (token limit) before any implementation. No code, build, board or push.

## 2026-10-17 — S10-sync production source integration

- Wired opcode 5 through the 16-byte firmware queue and production adapter into `LifeCore::sync`; enabled capability bit 4 with bit 5 (`0x003f`) and added Serial clock/day-part diagnostics.
- Mobile syncs phone UTC/timezone after connect and every six hours, cancelling on disconnect/close. Simulator keeps the capability off.
- Firmware focused 12/12 and full native PASS; ESP32 build/purity PASS (52,088 B RAM / 2,852,429 B Flash). Flutter analyze clean and 60/60 tests PASS.
- Initial APK build exposed JDK 21 + AGP 8.1.0 incompatibility. Updated AGP minimally to 8.2.2 (Gradle/Flutter unchanged); debug APK build, ADB install and cold launch PASS on `emulator-5554`, with the process alive and `MainActivity` top-resumed. ESP32 absent, so no BLE/Serial observation or upload. No commit/push. [Record](docs/roadmap/sessions/S10-sync-2026-10-17.md).

## 2026-10-16 — Owner-requested commit of all pending work

- Owner requested committing everything currently pending. Committed firmware first (`b0f4ded`: LifeCore/v2 integration, stated preference/explanation, artwork and tools), then mobile (`4976147`: shared pet visuals/UI, explanation pipeline and tests), then parent documentation and both gitlinks.
- Staged diff whitespace checks passed. No source changes or tests rerun in this commit-only step; preceding validation and owner-skipped hardware checks retain their exact status. The board still runs the earlier S13/S18 image, not the committed enhanced S26 source.
- No push, upload, phone install or board operations. Next recommended session remains S10-sync when requested.

## 2026-10-16 — S26/S27-lite source upgrade after owner-skipped board tests

- Owner asked to stop lengthy board testing and proceed with upgrades. Stopped S13/S18 Serial at uptime ~281 s, before checkpoint; one reboot and feedback result=0 recorded, stack 8,036 B. Remaining physical tests are owner-skipped, not validated. No subsequent board/phone operations.
- Enabled source opcode 6/bit 5, 20-byte explanation READ `000b`, dedicated expired=8; kept GPIO0 direct Happy, 12-byte packets, no TimeSync/hatch flags. Commit-grounded explanation is published before command notification; cached to avoid per-loop GATT updates. Baseline adapter/S01 remains compatible.
- Mobile explanation domain/model/mapper/repository/read use case, BLE discovery, Chat AskWhy and grounded post-confirmation reply; unsupported/fake evidence unavailable; timeout reads evidence without resend. Locale/expired handling updated. Existing artwork/UI retained.
- Firmware full native/ASan 192/192 each; final adapter 11/11 each; purity/ESP32 PASS (52,088 B RAM / 2,851,677 B Flash). Mobile fvm 3.32.8 pub get/lock unchanged, analyze clean, tests 59/59, debug APK PASS. [Record](docs/roadmap/sessions/S26-S27-lite-2026-10-16.md).
- Source/build only; board remains preceding S13/S18 image, app was not installed. No commit/push. Future enhanced firmware rollout requires compatible app first (result 8).

## 2026-10-16 — S13/S18 USB recheck and rollback verification passed

- Owner requested another check. Read 64 KiB successfully; entire preserved prior application (2,840,752 B) passed esptool `verify_flash` using the chip's digest. Saved verified rollback image outside Git; no application upload or Flash write.
- Re-read partition table/NVS; both byte-identical to existing verified backup. Host decoder/migration PASS, actual pet still Happy/Idle with 4 feedback. [Record](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md) has hashes and commands.
- Long-read USB root cause remains unknown; those failures are not erased from history. Upload approval is the next gate; new-firmware physical/stack checks not run. No code changes, test rerun, erase, NVS restore, commit or push.

## 2026-10-16 — S13/S18 lower-baud read retry failed

- Owner authorized the optional prior-firmware read retry, not upload. esptool read at 115200 failed again with short USB data after 77,824-byte progress (`expected 0x1000`, received `0xfe0`), exit 2.
- Stopped board operations. Existing verified NVS backup untouched; no new freshness check, upload, erase, NVS restore/write, source change, test rerun, commit or push. [Switch record](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md) records the failed attempt. USB cable/port check and transport resolution precede the next board attempt and upload authorization.

## 2026-10-16 — S13 + S18 production wiring; stopped before upload

- Switched production source to LifeCore + V1LifeCoreAdapter + NvsSnapshotStore; identity migration commit-first, initial durable v2 migration, read-only snapshot ERROR_SAFE guard, BLE transport-only, GPIO0 direct Happy, unchanged 12-byte packets/capabilities. Loop stack 16 KiB plus high-water logs; no board measurements yet.
- Passed: native 190/190, ASan/UBSan 190/190, S01 replay, purity, ESP32 build (52,048 B RAM / 2,850,341 B Flash), whitespace. Earlier dirty artwork/UI/Session 2 work retained; no mobile edit, commit or push.
- Verified device partition table equals build; NVS 0x9000 / 0x5000 backed up at `/Users/xthao28/xuna_backups/2026-10-16-s13-switch/`. Actual pet generation 33, activeSeconds 6,989, feedback 4, preferences Happy/Idle preserved by host migration check. Full hashes/evidence: [record](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md).
- Optional application read for rollback verification failed: esptool code 2, short USB data (`expected 0x1000`, received `0xf6e`). Board work stopped immediately per owner's rule. No upload, erase or NVS restore. Prior local firmware artifact preserved in scratch but not verified against board. Upload authorization and all new-firmware physical checks remain pending.

## 2026-10-16 — S08a + S13/S18 integration preparation (host)

- Added `V1LifeCoreAdapter` (BLE v1 over `LifeCore` + LifeSnapshot v2), `test_v1_adapter` (S08a replay of the S01 transcript + 6 cases), Arduino `NvsSnapshotStore` (D2a `life0/life1`, v1 keys read-only, `ident`, `bootc`; not linked), `tools/nvs_life_dump.py` and `sim/migration_check.cpp`. Evidence: [integration prep record](docs/roadmap/sessions/S13-S18-integration-prep-2026-10-16.md).
- Fact: the S01 script replays with identical result codes, counters, decision/feedback flags and memory pages; with the board's real timing the 168 s approval is expired under D3 (4). Real pet backups migrate with identical preferences (pet has no learned evidence). Synthetic edge: idle and happy both disliked → LifeCore prefers Curious.
- Embedded provisional choices needing owner confirmation: expired → 4; GPIO0 stays Happy (greeting learning off because v1 bytes and the app cannot carry context 2); reserved IDs ≥ 0x80000000 → 4; coarse preference bytes; needs not persisted.
- Validation: native 189/189, ASan/UBSan 189/189, purity PASS, ESP32 build SUCCESS (production unchanged 49,024 B RAM / 2,840,385 B Flash; adapter smoke +3,552 B RAM). Board stack for the ~2.8 KB staged snapshot must be measured in the switch session.
- No board/phone operation, upload, NVS write, commit or push. Backups only read.


## 2026-10-16 — Gate simplification decisions and handoff cleanup (Session 1)

- Independent plan review found the session gates self-blocking after the owner skips (S09 required "S01 completed"; S13 required S11/D2 power-cut benches) and several stale handoffs. Owner chose, all as recommended: close S01 with owner-skipped items; D2a (LifeSnapshot v2 in NVS A/B `life0/life1`, v1 keys kept as rollback, LittleFS decision → S32); merge S13 + S18 and fold S08b/S09 into it with S08a as regression; replace the Cloud M05b/S38 gate with (a) snapshot v2 on the board, (b) durable `PetId` readable over BLE, (c) local export. No backend code authorized; D11a still open.
- Status adjustments (not new decisions): S10 split into S10-sync (after the integration) and S10-hatch (deferred); S23/S24 superseded by E10 v3 / `ProductLearner`; S17 closed on owner smoke with render ±20% unmeasured; TRIAL-01 superseded by the artwork upload.
- Updated AGENTS.md §3, ADR-0002, ADR-0009, decision index, Cloud plan, implementation plan (status note, D2 row, §22.4), session plan (map notes, §9 next sessions), this header, PLAN.md and CHANGELOG.md.
- Known risks recorded: v2 power-loss behaviour on this board unmeasured; `BleManager` command packet is 12 bytes and must grow to 16 for TimeSync; `BoardLearner` loses recency on reboot until the switch.
- Documentation only: no code, build, test, board/app operation, commit or push. Firmware/mobile uncommitted work preserved.


## 2026-10-16 — Owner smoke acceptance and deferred extended checks

- Owner confirmed pet display, all four expressions, both physical buttons and mobile BLE connection are OK on the current build: owner-observed smoke PASS.
- Owner explicitly chose to skip the 1–2-hour life-feel trial and power-cut matrix for this iteration, favoring incremental improvements. Mark these checks owner-skipped, not passed; do not require them again as prerequisites to routine UI/local feature work. This does not approve a storage architecture choice or clear unrelated S11/D2/S13/S18 gates.
- Cloud architecture plan / Phase 0 documentation is complete and approved. Backend implementation still waits for M05b/S38 under the existing plan; no backend work authorized in this status session. Next local work is S10 runtime/transport integration, then the remaining foundation/learning wiring gates.
- Documentation update only; no tests, board/app operations, commit or push.


## 2026-10-16 — Warm beige chat avatar

- Added the existing `AppColors.xunaCardPressed` warm beige (#EFE8D6) behind the circular XUNA chat avatar in HomeChatBubble. Preserved shared pet widget, geometry and pixel filtering.
- Flutter 3.32.8 analyze clean; formatting/whitespace PASS; debug APK build/install/launch PASS on Redmi. No tests rerun for this color-only change. Previous changes preserved; no commit/push.


## 2026-10-16 — Simple pixel backgrounds on mobile

- Owner requested backgrounds for Home, Chat and Journal, then rejected detailed image drafts in favor of simple pixels. Final implementation uses code-native flat rectangles on an 80×60 grid in `AppXunaPet`: window/plant room, bookshelf/lamp reading nook, fence/cloud garden. Generated detailed drafts were discarded from the workspace and are not bundled.
- Room state adapter supports the background option; Home uses room, Chat header reading, Journal thumbnails garden. Transparent pet GIFs stay separate from backdrops, generated reproducibly by the existing export tool. Existing firmware/board preview remains unchanged. These backdrops are decorative, not physical-location or growth claims.
- Flutter 3.32.8 analyze clean, full test run 49/49 PASS (including small-card background coverage), focused shared widget tests 2/2 PASS; debug APK build/install/launch PASS on Redmi. GIF alpha checked, lock unchanged, whitespace clean. Physical visual review pending owner. No board operation, commit/push; earlier work preserved.


## 2026-10-16 — Shared mobile XUNA artwork base

- Owner requested consistent XUNA art throughout mobile using the base widgets. Added `shared/widgets/AppXunaPet` and UI-only `AppPetExpression`, exported from `widget_src.dart`; shared code has no feature dependencies. `HomePetScene` remains the device-state adapter to this base.
- Replaced old character illustrations in chat header, chat avatar, journal cards and growth placeholder with transparent XUNA portraits. Room and connected board preview reuse the same base in scene/animation mode. Decorative portraits are static, not claims about device emotion or implemented growth. No remaining feature references to legacy HERO/RAIN/LEARN images; old asset files retained.
- Extended deterministic export script for four transparent PNG portraits; README documents usage. Flutter 3.32.8 analyze clean, full tests 48/48 PASS, APK build/install/launch PASS on Redmi. Lock unchanged. Physical visual acceptance pending owner review; no firmware operation, commit/push. Earlier dirty changes retained.


## 2026-10-16 — Mobile pet artwork and animation

- Owner clarified the mobile complaint concerns pet artwork/animation. Added `HomePetScene` for the Home room and connected board-screen preview, driven by the device-reported `AnimationState`. Exported four GIF loops and still PNGs from firmware canonical anchored frames with `mobile/tools/export_pet_animation.py`; mobile builds consume checked-in assets without requiring firmware/Python.
- Offline/reduced-motion/TickerMode-disabled views use still images; no phone-owned pet progression. Loop phase is local presentation, not frame-synchronized with firmware. Existing UI layout retained. README documents regeneration.
- Flutter 3.32.8 analyze clean, 47/47 tests PASS including state/asset and reduced-motion coverage, debug APK build PASS, lock unchanged. `adb install -r` and launch PASS on Redmi 2510DRA23E. Physical BLE/visual acceptance pending owner observation. No firmware operation, commit or push; previous dirty work preserved.


## 2026-10-16 — Mobile build/install for emotion checks

- Owner requested the mobile build to exercise other firmware expressions. Built Android debug APK with pinned Flutter 3.32.8 (`flutter build apk --debug` via the pinned SDK binary); build PASS. Existing Device-tab expression controls cover Idle/Happy/Curious/Sleep; no code changes required.
- `adb install -r` PASS on Redmi 2510DRA23E, then `am start com.example.xuna_mobile/.MainActivity` PASS. Mobile Git and pubspec.lock unchanged. No analyze/test rerun for this build-only session. Physical BLE emotion observations remain owner acceptance work; app launch does not establish BLE/animation acceptance. No commit/push.


## 2026-10-16 — Anchored pet motion revision

- Owner reported sliding/tilting and sparse animation in the first replacement. Reworked `firmware/tools/generate_pet_scene.py` to use one upright reference, redraw expressions on the same body, keep feet byte-identical, and limit upper-body breathing to two pixels. Removed whole-body translation/rotation. Idle blinks, Happy smiles/pulses, Curious moves pupils, Sleep breathes with closed eyes.
- Four 32-sample timelines at 100 ms/sample (128 exported frames; intentional held/repeated poses, not 128 unique drawings). Exported PNG sheet, LCD preview and timed GIF. `PetVisualAnimation.h` selects the corresponding row, resets on state changes and handles unsigned time rollover.
- Validation: native `test_visual` 2/2 PASS (state switches, loop, late calls, rollover); generator fixed-foot/transparent-key assertions PASS; ESP32 build/purity PASS. Static RAM 49,024 B; image 2,840,385 B / 6,553,600 B; fixed render buffer 13,824 B. Other core logic unchanged; full suite was not rerun this revision.
- Upload PASS (hash verified); ~15-second Serial smoke recorded Idle, GPIO0 Happy and return to Idle, no spontaneous error/reset; max draw 5,427 us. Post-upload NVS byte-identical to backup. This is runtime smoke, not visual acceptance.
- Partition table read and matches build byte-for-byte. Pre-upload NVS backup stored outside Git at `/Users/xthao28/xuna_backups/2026-10-16-pet-motion/`; NVS SHA-256 `d7d12a9bebe95738bad48bdee08ce90f7de284bbd928ca24611286c5988ec52d`. Physical motion acceptance remains pending owner observation. No commit/push.


## 2026-10-16 — Owner-requested XUNA pet artwork replacement

- Replaced firmware pet art with the generated reference sheet retained at `firmware/assets/source/xuna-emotion-sheet-v2.png`. Deterministic Pillow conversion preserves alpha, uses nearest-neighbor scaling and exports 16 fixed 96×72 frames (Idle/Happy/Curious/Sleep), RGB565 arrays, PNG/GIF and LCD preview. Existing room background and anchor remain unchanged.
- Updated presentation-only frame selection for four loops; pet-life, learning and storage logic were not edited. Built current firmware production path, which already includes the previously prepared BoardLearner/life-feel trial.
- Validation: native 182/182 PASS; ESP32 build/purity PASS, static RAM 49,024 B, Flash 1,292,101 B. Pixel assets 329,984 B; render buffer stays 13,824 B. Upload to ESP32-S3 at `/dev/cu.usbmodem14101` PASS, hashes verified. Physical visual/button acceptance pending owner observation.
- Post-upload NVS is byte-for-byte identical to the backup (SHA-256 `d7d12a9bebe95738bad48bdee08ce90f7de284bbd928ca24611286c5988ec52d`). Serial smoke ~20 seconds: no spontaneous reset/error, stable heap 251,536 B, max draw 4,815 us; not long-run acceptance.
- Device partition table matches build; NVS offset 0x9000, size 0x5000 backed up before upload outside Git at `/Users/xthao28/xuna_backups/2026-10-16-pet-v2/`. No commit/push or mobile changes.


## 0. Start here — next work (historical, 2026-10-12; superseded by the header above)

**Read first.** AGENTS.md (canonical) → this section → [XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md):

- §2 rules;
- §3 session map;
- the entry for the session you run.

Then read only the sections of [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md) that the session cites. The rationale for the current plan is in [XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md).

**Where things stand:**

- **Local MVP through M05:**
  - Implemented: firmware `be58099`, mobile `3846880`; backend `0032828` is a README only.
  - Build, upload, LCD and buttons PASS.
  - **Pending:** real-phone BLE, learning, reboot, power-loss and forget acceptance (PLAN MVP-07). M01 PCB revision/P07 also remain open.
- **Approved on 2026-10-12** (AGENTS.md §3):
  - **D1:** M04 before new M05 features.
  - **D7:** hatch on the device or via the app (opcode 7); exact `bornAt` only with trusted time in the hatch boot; the MVP pet migrates as Newborn.
  - **D12:** C++11 core.
  - **D14:** Flutter 3.32.8 pinned via `mobile/.fvmrc` (created and baseline verified in S00; committed as mobile 77d27ec).
  - **D17:** Conversation Layer A with M05a, text-first; Layer B after M05b.
- **Historical Windows inspection (2026-10-12; not this session’s Mac environment):**
  - no PlatformIO, no host C++ compiler, no real Python (Store alias only), no WSL distribution;
  - Flutter 3.41.1 via fvm, with 3.32.8 not installed.
  - iOS builds and runs need the Mac.

**Preparation sequence** (full steps in the session plan §6; latest results below):

| # | Session | Work | Owner input needed | Done when |
|---|---|---|---|---|
| 1 | **S02 — documentation complete** (S, no tooling) | Review/extend existing `docs/decisions/README.md` and create `docs/decisions/ADR-0001-reference-reuse-policy.md` from plan §6.3 | Accept ADR-0001 or not | Both files exist; Git state reported |
| 2 | **S00 — PASS on Mac** (M) | Install the PlatformIO IDE extension; install a host compiler; `fvm install 3.32.8` + `mobile/.fvmrc`. Baselines: host tests; `pio run` (expect static RAM 47,504 B, image 964,333 B); `flutter analyze` + `flutter test` (10 tests); `pubspec.lock` unchanged | Choose MSYS2 or WSL for the compiler; OK to commit `.fvmrc` | Versions and baselines recorded in this file |
| 3 | **S01** (Owner) | MVP physical acceptance with the phone, plus observed v1 bytes from a BLE inspector. **Verified NVS backup first** (session plan §5) | Board, phone and Mac time | MVP-local.md updated; MVP-07 status set |

After that, follow the session map:

- S03 → S04 → S05/S07 → S06 → S08a → S08b → S09 → S10 → S11 …
- S03–S05 and S07 are host-only and may run after S00 while S01 waits for the phone.
- No refactored or storage-changing firmware goes onto the owner's board before S01.

**Open decisions:**

| Decision | When |
|---|---|
| D2 | After experiment S11 |
| D10 | After experiment S35 |
| D15 | At checkpoint S42a |
| — (D3–D6 approved, D16 deferred on 2026-10-15) | S22 done |
| D8, D9 | Session S29, before S30 |
| D11a / D11 | Only if cloud STT/LLM is to be evaluated |
| D13 | M06 |

**Working rules to keep:**

- Start a session only when the owner asks.
- One session at a time; respect its preconditions and done criteria.
- Discuss in Vietnamese; keep docs and code in English.
- Commit or push only on the owner's request:
  - follow the existing format: a single-line conventional message such as `docs: ...` or `feat: ...`;
  - **no AI attribution or trailers anywhere**;
  - child repo first, then the parent gitlink.
- Update this section, PLAN.md and CHANGELOG.md at the end of every session.

**Git when this section was written:** the root repo had uncommitted documentation changes:

- `AGENTS.md`, `CHANGELOG.md`, `PLAN.md`, `PROCESS.md`;
- the plan and the session plan;
- the new audit file.

Check `git status` before starting.

## 1. Read order and authority

1. Read [AGENTS.md](AGENTS.md) completely: canonical product intent, approved decisions and agent rules.
2. Read this file for working context, then [PLAN.md](PLAN.md) for tasks and the latest entries in [CHANGELOG.md](CHANGELOG.md) for recent changes.
3. Read [M01 validation record](docs/roadmap/milestones/M01-bring-up.md), [firmware README](firmware/README.md) and relevant source before editing.
4. Inspect actual Git status in the parent and affected submodules. This snapshot is not live state.

This file is an operational handoff, not a replacement for AGENTS.md. Plans in PLAN.md do not approve unresolved architectural decisions or authorize starting later milestones. When this file conflicts with implementation or newer evidence, inspect the discrepancy and update it without discarding history.

## 2. Product and scope context

XUNA is a persistent, local-first digital lifeform on physical hardware, expressed through pixel art. Experiences should eventually shape memory, preferences, behavior and explainable evolution. The current button reactions are scripted animation, **not AI learning**.

Approved directions include the XUNA name, VS Code + PlatformIO, existing LILYGO T-Display-S3 hardware, Flutter companion direction and incremental milestones. Arduino is authorized for this initial bring-up; a permanent Arduino-versus-ESP-IDF decision remains open. Conversation belongs alongside learning in M05. Core pet life must not require cloud connectivity.

Current implementation scope is LCD, original placeholder sprite, buttons, animation and diagnostics. BLE, backend, voice, sensors, persistence, learning and evolution are not part of M01.

## 3. Repository and Git snapshot

Repository: `/Users/xthao28/xuna_pet`, remote: `https://github.com/xthao28/xuna_pet`.

| Path | Independent repository | Recorded gitlink |
| --- | --- | --- |
| `firmware/` | `xthao28/xuna_firmware` | `be5829d (firmware commit; parent pointer updated with this handoff commit)` |
| `mobile/` | `xthao28/xuna_mobile` | `310e69f614f88cb3649ddef67ac758014c9ffb32` |
| `backend/` | `xthao28/xuna_backend` | `0032828abb4c754d7222dc3aaed24a630d92bc56` |

All three submodules exist and are initialized. Firmware originally contained only a placeholder README. M01 firmware changes are committed as `be5829d`. The owner requested committing the current changes on 2026-10-11; parent documentation and the new firmware pointer are included in the parent commit containing this snapshot. Mobile/backend remain unchanged. No push has been performed. Inspect Git for changes made after this snapshot.

Before doing work:

```sh
git status --short
git submodule status
git -C firmware status --short
git -C mobile status --short
git -C backend status --short
```

Preserve dirty/untracked files. Do not reset, recreate submodules or initialize nested repositories. Firmware commits must happen inside the child repository before updating its pointer in the parent. Never treat a dirty submodule as a committed delivery.

## 4. Implemented M01 slice

Firmware version: `0.1.0-m01`.

| File or module | Responsibility |
| --- | --- |
| `firmware/platformio.ini` | Pinned PlatformIO, MCU/memory configuration, display library/setup |
| `firmware/include/AppConfig.h` | Pins, version, rotation and timing constants |
| `firmware/include/DebouncedButton.h` | Pure C++ press-edge debounce |
| `firmware/include/InputManager.h`, `firmware/src/InputManager.cpp` | Active-low GPIO adapter for two buttons |
| `firmware/include/AnimationManager.h` | Pure C++ idle/happy state and frame timing |
| `firmware/include/DisplayManager.h`, `firmware/src/DisplayManager.cpp` | LCD initialization, branding and original sprite rendering |
| `firmware/src/main.cpp` | Setup, bounded loop, event mapping and serial diagnostics |
| `firmware/test/test_core.cpp` | Host tests for debounce and animation |
| `firmware/README.md` | Setup, commands, sources, limitations and licensing notes |
| `docs/roadmap/milestones/M01-bring-up.md` | Build evidence and physical acceptance checklist |
| `.gitignore`, `firmware/.gitignore`, `CLAUDE.md` | Local artifact exclusions and agent entry point |

Behavior:

- Two frames per state; idle interval 400 ms, happy interval 160 ms.
- GPIO0/BOOT requests happy for 2400 ms; a new press restarts the timer.
- GPIO14 requests idle; idle wins simultaneous press events.
- Debounce is 30 ms; held buttons do not auto-repeat. A button held at app startup must be released before another press is emitted.
- Unsigned elapsed-time math handles rollover; late frames are skipped with bounded work.
- One 80×80 RGB565 sprite is allocated during setup (12,800 bytes plus library overhead). Only the sprite region redraws each frame.
- Logs every 5 seconds: state, rendered FPS, average/max render duration, max loop gap, heap/min heap and PSRAM. Rendered FPS is animation cadence, not panel refresh capacity.
- No application-loop delay or serial-host wait. LCD transfers and Serial writes are synchronous; real latency is unmeasured.
- Sprite allocation failure disables rendering while input/logging continue. TFT_eSPI cannot confirm physical LCD presence or successful visual output.

## 5. Hardware and toolchain facts versus assumptions

**Documented configuration:** standard 1.9-inch 170×320 ST7789 LCD, ESP32-S3R8, expected 16 MB Flash / 8 MB OPI PSRAM. LCD interface is parallel 8-bit, not SPI.

- LCD D0–D7: GPIO39,40,41,42,45,46,47,48.
- LCD CS=6, DC=7, RST=5, WR=8, RD=9.
- Peripheral power GPIO15 HIGH; backlight GPIO38.
- Buttons GPIO0 and GPIO14, active-low. Holding GPIO0 during reset enters download mode.
- Rotation defaults to `1` (320×170 landscape).

**Assumption awaiting physical confirmation:** the owner's board matches this standard LCD pinout; PCB revision is not recorded. Do not apply this configuration to AMOLED or another variant.

**Pinned build:** `espressif32@6.5.0`, Arduino ESP32 2.0.14, `bodmer/TFT_eSPI@2.5.43`, Setup206. The generic `esp32-s3-devkitc-1` supplies the MCU target; explicit overrides select 16 MB Flash, QIO/80 MHz, `qio_opi` and `default_16MB.csv`. LCD pins come from Setup206, with compile-time assertions. Do not remove the global TFT_eSPI include path: the first build failed without it in framework-library compilation.

Official source links and license notes are in the firmware README. Check current official documentation again before changing dependencies or hardware configuration; do not upgrade libraries merely to silence warnings.

## 6. Verification evidence and gaps

Results recorded on **2026-10-10**, not rerun merely to create this handoff:

| Check | Recorded result |
| --- | --- |
| PlatformIO configuration parsing | PASS |
| ESP32-S3 firmware compilation | PASS; `.bin` and `.elf` generated |
| Host C++ tests with warnings as errors | PASS |
| Host AddressSanitizer / UndefinedBehaviorSanitizer | PASS |
| Git whitespace checks | PASS |
| Linker static RAM | 21,840 / 327,680 bytes |
| Firmware / app partition | 319,709 / 6,553,600 bytes |
| Connected ESP32 USB serial device | Not detected in previous session |
| Flash/upload, LCD and electrical buttons | Not tested |
| Runtime heap/PSRAM, render timing, stability | Not measured |
| Exact PCB revision / standalone boot | Not verified |

Linker figures exclude runtime allocation and cannot establish free heap or display performance. Physical results must be entered into the M01 record; do not invent measurements.

Known upstream warnings: parallel DMA unavailable, touch unconfigured, and an Arduino 2.0.14 non-void return warning in UART code. No project compile errors remained after the include-path fix.

The agent used temporary tooling:

```sh
PLATFORMIO_CORE_DIR=/private/tmp/xuna-m01-pio-core /private/tmp/xuna-m01-pio/bin/pio run -d firmware
```

Those temporary directories may disappear. VS Code's PlatformIO installation is a separate environment; the open IDE installation tab does not establish that installation has finished. Confirm it before relying on `pio` in the IDE terminal.

## 7. Plan and history

- [PLAN.md](PLAN.md): ordered M01 tasks P01–P08, their statuses/dependencies, execution commands and the Proposed M02 plan.
- [CHANGELOG.md](CHANGELOG.md): dated implementation, fixes, validation outcomes and session changes. This includes uncommitted work, not only Git commits.
- [M01 validation record](docs/roadmap/milestones/M01-bring-up.md): detailed physical checklist and measurement evidence.

Current run (2026-10-11): owner confirmed continuing after connection checkpoint. Normal IDE Core 6.2.0 build/upload PASS; host tests PASS. Board model read by owner: T-Display-S3, PCB revision unknown. Basic LCD/animation/buttons passed by owner observation. A false PSRAM warning was fixed in firmware diagnostics and the corrected build uploaded; Flash 16 MiB, PSRAM chip 8 MiB confirmed. More than 10 minutes of stable diagnostics passed; owner confirmed RST/USB startup and buttons with Monitor closed. PCB revision/final P07 review remain open; see [physical run](docs/roadmap/milestones/M01-bring-up.md#build-upload-and-physical-run--2026-10-11). Root HEAD remains `3dda411`, firmware HEAD `be5829d`; firmware now has uncommitted diagnostics/README changes, parent handoff docs uncommitted. Mobile/backend unchanged; no commit/push. Firmware gitlink still points to committed `be5829d`, not the uncommitted uploaded fix.

## 8. Session update procedure

At the start of a session, read the files in section 1, inspect Git and choose the first incomplete authorized task. Re-check facts that may have changed, such as tool availability, board connection or dirty files. Report in Vietnamese.

At the end of each work session, update:

- Last-updated date, current milestone/status and exact next action.
- Files/behavior changed and decisions, preserving Idea/Proposed/Approved distinctions.
- Commands actually run, pass/fail results and where evidence is stored.
- Hardware measurements separately from build figures.
- Blockers, unresolved questions and user actions needed.
- Git state: uncommitted changes, commits, submodule pointer changes and push status.
- Update task statuses and remaining work in PLAN.md.
- Append a dated entry to CHANGELOG.md; preserve previous entries and link to evidence.

Do not store credentials, tokens or other secrets here. Use links to detailed records instead of duplicating lengthy logs. A stopped session or successful compile does not mean a milestone is Validated.

## 9. Copyable prompt for the next AI/session

> Read AGENTS.md (§3 decisions, including the 2026-10-16 gate simplification), then the header and newest dated entries of PROCESS.md, then docs/roadmap/XUNA_SESSION_PLAN.md §2 rules and §9 next sessions, and only the cited sections of docs/architecture/XUNA_IMPLEMENTATION_PLAN.md. Inspect root and submodule Git; firmware and mobile may hold uncommitted owner work — preserve it.
>
> Current state (2026-10-16):
>
> - M04 core and the M05a learning core are Implemented on host; the board runs the v1 + `BoardLearner` path with new artwork. Owner smoke PASS; 1–2 h trial and power-cut matrix owner-skipped (not validated).
> - Next: S08a + integration prep (host), then the merged S13 + S18 board switch.
>
> Working rules:
>
> - Ask the owner before starting a session; explain its purpose in Vietnamese.
> - Verified NVS backup (session plan §5) before any upload; never upload `5d872d3`.
> - Report in Vietnamese; separate ran/passed, failed and not run.
> - Commit only on request, as single-line conventional messages with no AI attribution.
> - Keep Clean/GetX and the pinned toolchains (Flutter 3.32.8, espressif32@6.5.0).
> - No backend code before the Cloud gate in AGENTS §3.

## Mobile base update — 2026-10-11

Owner explicitly confirmed retaining the imported Clean/GetX architecture for future mobile work. Scoped cleanup removed login/product-detail demos, province data/mappers, old backend URL and business-specific locale/constants; splash/home and generic core/shared infrastructure, packages and generators remain. Package/labels renamed to XUNA; network clients require explicit base URLs and are not initialized at startup. Mobile remains uncommitted at HEAD `310e69f`; no gitlink update or M02 implementation. Analyzer PASS after dependency resolution; no native build/device validation claimed for this final cleanup. Earlier minimal-scaffold results do not apply. Firmware changes and M01 status remain unchanged.

## M02 inspection — 2026-10-11

All repositories verified on dev; HEADs unchanged (root 3dda411, firmware be5829d, mobile 310e69f, backend 0032828). Root/firmware/mobile dirty; backend clean. No child edits, build/upload, commit/push or gitlink change during proposal work. Flutter 3.32.8/Dart 3.8.1, Xcode 14.2, booted iPhone 13/iOS 16.2 simulator, PlatformIO 6.2.0 and board USB detected. No real phone detected. Protocol/library trade-offs and future validation matrix are recorded in M02 proposal, all Proposed. Historical M01 snapshots above retain their original context; this current section supersedes older claims that mobile is unchanged or M02 must wait for M01 validation.

## Mobile simulator delivery — 2026-10-11

Owner approved proposal and explicitly requested simulator-first mobile commit/push. Mobile commit `24026b2` pushed successfully to `origin/dev`; mobile working tree clean. Includes previously uncommitted approved Clean/GetX base plus fake M02 feature/tests. Analyzer/4 tests/native simulator build PASS; flutter run opened Home on iPhone 13/iOS 16.2, screenshot inspected. Full interaction flow exercised in widget test, not native automated taps. CocoaPods locale failure fixed by command-local UTF-8 environment. No BLE dependency/physical adapter or firmware change in this slice. Root remains 3dda411 with uncommitted docs and changed mobile working HEAD; root gitlink remains 310e69f until an explicitly requested root commit. Firmware HEAD be5829d with earlier dirty changes preserved; backend clean. Physical BLE, Android native build and M01 PCB revision/P07 remain open.

## Local MVP implementation — 2026-10-11

Owner approved local MVP through M05, board ownership of state/memory/preference and template-based text without LLM. Firmware adds bundled BLE, LifeEngine, two-slot NVS snapshots, bounded confirmed feedback episodes and local learned quiet routine; mobile adds physical BLE repository, request correlation and learning/text/memory UI while retaining Clean/GetX. Simulator is explicit via XUNA_SIMULATOR=true; real transport is default. Flutter analyzer/10 tests/simulator build/run and host core/life tests with life sanitizers PASS. See local MVP record for exact scope, protocol extensions and unverified physical cases. Existing root/firmware changes preserved; new work is uncommitted. HEADs remain root3dda411/firmwarebe5829d/mobile24026b2/backend0032828. No new commit/push; previous mobile simulator commit remains published. Old Proposed/device-ownership snapshots above are historical and superseded only for the owner-approved local MVP.

## Uploaded board checkpoint — 2026-10-11

LILYGO now runs corrected 0.2.0-mvp; build/upload/hashes PASS, 22-second startup diagnostics captured; owner confirmed LCD and both buttons. Fixed first-boot NVS missing-key noise by isKey checks and reuploaded; corrected log clean. See MVP record for measured resource figures and limits. Physical iPhone BLE/learning/reboot persistence and M01 PCB revision/P07 remain pending. Owner now explicitly requested commit/push of current code; deliver child commits before root gitlinks.

## Current Git delivery — 2026-10-11

Owner requested publishing current code. Firmware `be58099980a316a5ebfe8e621fe68a31eb8dcff6` and mobile `3846880ea3fb3a2cc26f5b41469f62a1f7d85316` committed and pushed successfully to their origin/dev branches; both child working trees clean. Root snapshot commit containing this section records both updated gitlinks and all scoped handoff documents. Backend remains `0032828`, unchanged. This delivery supersedes historical uncommitted/old-pointer snapshots above. No force push, reset or unrelated repository edits. Physical iPhone BLE/learning/NVS acceptance and M01 PCB revision/P07 remain pending.

## Technical plan proposal — 2026-10-12

Submodules were initialized at the recorded gitlinks; nothing changed in the children.

Added [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md), status **Proposed / planning only**. It integrates spec v0.3.0 §23–24 and the read-only ePet/Xiaozhi audits.

No code changes and no build, test, commit or push. The plan does not approve any slice.

Next action: the owner reviews decisions D1–D13, at minimum D1, D2 and D7. Then complete M04.0, which includes the pending MVP-07 physical acceptance, committing the spec, and ADR-0001. Only after that, start M04.1 if approved. MVP physical acceptance and M01 PCB revision/P07 remain open.

Session breakdown (2026-10-12): [XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md) splits the plan into sessions S00–S46 and assesses readiness. The plan was amended for three things:

- `bootc` uses its own NVS key;
- snapshot v2 is sectioned;
- TimeSync wiring happens after the command handler moves into the core.

Environment observed on this Windows machine:

- Flutter 3.41.1 via fvm (the project recorded 3.32.8);
- no PlatformIO, no host C++ compiler, no real Python;
- WSL has no distribution.

Recommended next sessions: S00 (toolchain and baseline), then S02 (decisions D1, D2, D7, D12 and ADR-0001), then S01 (MVP physical acceptance).

## Plan audit — 2026-10-12

Reviewed the plan against the owner-forwarded external checklist; report in [XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md). There were 17 findings, none Critical.

Main corrections, all **Proposed**:

- Conversation Foundation (Layer A) now develops together with M05a through the v1-additive opcode 6 `StatedPreference`, with joint acceptance S28. Personal facts stay in Layer B after M05b (D17).
- D2, D10 and D11 are decided after their experiments; D11a only authorizes the E12 spike.
- The Flutter SDK pin is decision D14. There is no `.fvmrc`; the lock requires Flutter ≥ 3.27.0. 3.32.8 is evidence only, not an approval.
- The NVS backup now verifies the partition table read from the device.
- S01 captures observed v1 bytes as the refactor baseline.
- S08, S12 and S19 are split into a/b sessions.
- Power-cut tests use write-storm builds.
- M05d versus an Evolution MVP is decided at checkpoint S42a (D15).

Approved decisions are unchanged. No firmware, mobile or backend change; no build, test or flash; no commit or push.

Next: S02 → S00 → S01.

## Owner decisions — 2026-10-12

The owner approved:

- **D1:** complete M04 (S03–S21) before new M05 features.
- **D7:** a pet hatches on the device (local gesture) **or** via the app (opcode 7). `bornAt` is exact only with trusted time in the hatch boot; otherwise it stays unknown. The existing MVP pet migrates as Newborn.
- **D12:** C++11 core.
- **D14:** pin Flutter 3.32.8 via `mobile/.fvmrc`.
- **D17:** Conversation Layer A with M05a, text-first; Layer B after M05b; voice still depends on D16.

These are recorded in AGENTS.md §3 and plan §18. The plan (§12, §8.2, §14.1) and sessions S02, S06 and S10 were amended accordingly.

Still open:

- D2, after S11; D10, after S35; D15, at S42a;
- D3–D6, D8, D9, D11a/D11, D13 and D16.

No code changes and no commit or push.

Next: S02 (ADR-0001 + decisions index) → S00 → S01.

## Device-first documentation update — 2026-10-12

Owner requested architecture/roadmap documentation only. Approved long-term direction: physical XUNA is primary; Flutter assists; optional cloud never owns life state. A5 local MVP and D17 text-first are retained. Proposed ADR-0006, D18–D20 and VOICE-01–04 require evidence/approval; no voice scope silently added. See [architecture](docs/architecture/XUNA_DEVICE_VOICE_ARCHITECTURE.md) and session plan §9.

Before edits root/firmware/mobile/backend were clean; child HEADs remain be58099/3846880/0032828. This session runs on `/Users/xthao28/xuna_pet` (Mac path); historical Windows tool availability is not a current toolchain check. No SDK install, code/config/dependency change, build/test, flash, wiring, commit/push or gitlink change. Validation is documentation-only: diff/whitespace, local Markdown references, session/decision consistency, changed-path and unchanged child checks.

Next remains **S02 → S00 → S01**. S02 has a prepared index but ADR-0001 is still pending; it is not Done. S00 remains the next coding/toolchain preparation session, with machine/tool availability rechecked rather than copied from historical Windows notes. S01 physical acceptance and verified NVS backup remain mandatory before refactored/storage-changing uploads. Voice does not block M04 or M05a. D15 stays at S42a.

Documentation verification results: `git diff --check` PASS; scripted relative Markdown path check PASS; all 54 existing session-map rows/dependencies identical to HEAD; no duplicate detailed session IDs; changed/untracked paths are Markdown only; root gitlinks unchanged and all child working trees clean. Builds/runtime tests were not run because implementation was untouched.

## S02 documentation delivery — 2026-10-12

Owner requested incremental execution. Decision index and Proposed ADR-0001 now exist; S02 documentation done criteria are met. ADR acceptance remains pending, no decision silently approved. Preserved prior uncommitted documentation. Corrected T14 table to match separately gated voice research; no implementation/dependency/hardware changes or commit/push. Next: S00 environment and baseline verification on the current Mac.

## S00 — Development environment and baseline (2026-10-12)

Current work machine: owner's Mac at `/Users/xthao28/xuna_pet`, authorized by incremental execution request; existing macOS compiler replaces the historical Windows MSYS2/WSL setup choices. VS Code extension `platformio.platformio-ide` is installed. PlatformIO Core 6.2.0 at `~/.platformio/penv/bin/pio` (not on shell PATH); Apple Clang 14.0.0; FVM 3.2.1; Flutter 3.32.8 / Dart 3.8.1. Added `mobile/.fvmrc` per approved D14, no SDK/dependency upgrade or global SDK change.

| Check actually run | Result |
|---|---|
| `c++ -std=c++11 -Wall -Wextra -Werror -Ifirmware/include firmware/test/test_core.cpp -o /tmp/xuna-s00-core` + binary | PASS |
| Same flags for `test_life.cpp` + binary `/tmp/xuna-s00-life` | PASS |
| `~/.platformio/penv/bin/pio run -d firmware -e xuna_t_display_s3` | PASS; static RAM 47,504 B; image 964,333 B — matches recorded baseline |
| `fvm flutter pub get` (mobile) | PASS; existing versions resolved, lock unchanged |
| `git -C mobile diff --exit-code -- pubspec.lock` | PASS, no diff |
| `fvm flutter analyze` (mobile) | PASS, no issues |
| `fvm flutter test` (mobile) | PASS, 10 tests |
| `pio device list` | No ESP32 USB device detected |
| `xcrun xctrace list devices` | Mac and iOS simulators only; no real iPhone |

S00 is complete. S01 awaits board USB and a real phone; no verified NVS backup, BLE transcript, physical acceptance, upload or power-cut work performed. Session rules require stopping S01 when hardware prerequisites are missing. S03–S05/S07 remain eligible host-only follow-ups, but no M04 code session started in this preparation run.

Git: previous root documentation edits preserved; new ADR-0001 draft and handoff changes uncommitted. Mobile has only new `.fvmrc`; firmware/backend clean; parent gitlinks unchanged. No commit/push. Next: connect board and real phone for S01; ADR-0001 remains Proposed until explicitly accepted.

## S01 partial — ESP32-only preparation (2026-10-12)

Owner deferred real-phone acceptance and requested ESP32 work first. Device detected at `/dev/cu.usbmodem14101` (Espressif USB 303A:1001). Serial inspection caused USB/UART reset; boot reports XUNA 0.2.0-mvp, 16 MiB Flash and 8 MiB PSRAM. Chip read by esptool: ESP32-S3 silicon revision v0.2; this is **not** the unknown PCB revision. Two idle diagnostic windows: render averages 3507/3491 us, maxima 3693/3527 us; loop-gap maxima 4543/3540 us. This brief observation is not stability or BLE acceptance; LCD was not visually confirmed in this session.

Read actual partition table with esptool 4.5.1 (`read_flash 0x8000 0xC00`); decode verified NVS at 0x9000/0x5000 and complete table matches current build. Read NVS (`read_flash 0x9000 0x5000`), verified file length 20,480 B and recorded SHA-256. Backup files and manifest are outside the repositories at `/Users/xthao28/xuna_backups/2026-10-12-s01/`. Table SHA-256: `bd0f7954aca2ef7d925ee21aaa1f3dc8822d1d6ce5cbbd26a135e5886bfff6ce`; NVS SHA-256: `f941a8b3398788301c87902e293c8ab8ab6dc629f5b47d8946f1e05787f7e822`. Restore was not tested; no erase/write_flash/firmware upload, pet commands or power-cut tests. Flash reads reset the board; esptool's temporary RAM stub does not replace installed firmware.

S01 remains **In progress — phone-dependent acceptance deferred**. BLE transcript/feedback/reboot/forget and owner visual checks are unvalidated. Backup does not waive S01 gates on S06/S09/S13 etc. S11 additionally needs S04 and owner-operated power-cut evidence. Eligible next firmware work without phone: S03 → S04, then S05/S07; these run on host, with board build verification where specified, and no refactored firmware upload before S01 acceptance. No later session implemented in this partial run; code/submodule state unchanged.

## S03 complete — firmware first / Android later (2026-10-12)

Owner selected Android for future app acceptance and requested the next ESP32/firmware step. S03 is Done; evidence in [S03 record](docs/roadmap/sessions/S03-v1-characterization.md). Three frozen host snapshot fixtures and characterization tests added; production code/config unchanged. New tests PASS with C++11/-Werror; all three host suites PASS with ASan/UBSan; ESP32 build PASS at unchanged 47,504 B RAM / 964,333 B image. No upload, runtime interaction, commit/push or gitlink update.

Current firmware working tree contains uncommitted test fixtures/test/README changes. Previous root documentation and mobile .fvmrc preserved. Next S04, then S05/S07 host work as appropriate; S01 remains a gate on later board refactor/storage uploads. Phone path is Android (owner-selected), not iPhone; no Android native/physical BLE success claimed.

## S04 — Portable core delivery (2026-10-12)

[Evidence and changed paths](docs/roadmap/sessions/S04-portable-core.md). Five pure headers moved under firmware/lib/xuna_core/include/xuna without production logic changes; BoardConfig/CoreConfig split, Unity suites and native/native_asan environments added. Firmware tools/check_core_purity.py runs for every environment. Native and sanitizer runs PASS (8/8 each); ESP32 build PASS, unchanged RAM 47,504 B / image 964,333 B. Native 1.2.1 and Unity 2.6.1 installed by PlatformIO for this test setup; firmware pins/partitions unchanged.

Current commands: `~/.platformio/penv/bin/pio test -d firmware -e native` / `-e native_asan`; build with `pio run -d firmware -e xuna_t_display_s3`. Earlier manual test paths in historical sections no longer exist after this move. Core library has no Arduino dependencies. Mobile's earlier .fvmrc and all previous root/S03 edits retained; no new mobile/backend work. Firmware refactor is uncommitted; parent gitlink unchanged. No flash/upload or physical acceptance.

Next S05 (pure fixed-point/RNG/ClockModel); S07 also eligible after S04. Device for future app validation is Android. S01 remains partial and required before refactored/storage-changing board uploads.

S04 negative guard check: PASS in native, native_asan and ESP32; temporary Arduino.h include removed. Clean build after restoration PASS.

## S05 — Foundation primitives complete (2026-10-12)

Owner resumed work after reporting board warmth under Mac USB power. S05 ran entirely on host; no serial/flash/board operation or thermal measurement. [Detailed contracts/evidence](docs/roadmap/sessions/S05-foundation-primitives.md): fixed-point Q0.16/Q16.16 arithmetic with saturation/rounding; deterministic Pcg32/IRandom with official vectors; ClockModel with unknown-on-boot, rollback protection, quality/day-part logic and 64-bit monotonic inputs. Defaults 24 h/5 min remain Proposed tuning values. PCG adaptation is Apache-2.0, with notice/license and exact source SHA recorded in firmware README.

Tests-first missing-header build failure observed; then all native and native_asan suites PASS (12/12 each). ESP32 cross-compile smoke for all new headers PASS; normal ESP32 build/purity guard PASS at unchanged 47,504 B RAM / 964,333 B image. Primitives are not wired into firmware yet; no host-target runtime parity or physical acceptance claimed. Root/firmware whitespace checks and updated document paths PASS.

Next prefer S07 since it requires S04 only and is fully host-side; this is allowed by the existing session map, not a milestone reorder. S06 pure identity work is eligible but its full completion includes gated board steps (S01). Android app work stays deferred. Firmware/root changes remain uncommitted, mobile has only prior .fvmrc, backend unchanged; no gitlink update or push.

## S07 — Event foundation complete (2026-10-12)

Owner requested a plain-language overview before each session; rule recorded in AGENTS §10 for future sessions. [S07 evidence](docs/roadmap/sessions/S07-events.md): 25-kind registry with compile-time uniqueness, in-RAM event envelope, fixed-capacity ring, no-wrap boot/sequence IDs and bounded queue with explicit critical rejection and drop counters. No persisted codec or firmware wiring.

Tests-first failure for missing header, then new tests PASS. Full native and native_asan regression PASS, 18/18 each; Xtensa compile smoke PASS; ESP32 build/purity guard PASS at unchanged 47,504 B RAM / 964,333 B image. Existing upstream warnings unchanged. No board/serial/Flash operation, app change, commit/push or gitlink update; earlier edits retained.

Open finding: S05 ClockModel currently returns Unix-epoch minutes while event/plan §7.1 specifies minutes since 2020. Models are not wired; do not assign between them yet. Next focused S05-fix-01 corrects the internal conversion and tests before identity/time-event integration, without changing deployed protocol/state. Then continue eligible firmware sessions; S08a requires S01 observed bytes, and S06 board steps remain gated. Android app work remains deferred.

## S05-fix-01 — Compact time epoch corrected (2026-10-12)

[Fix record](docs/roadmap/sessions/S05-fix-01-time-epoch.md). ClockModel compact minutes and persisted watermark now use the planned 2020 epoch; UTC milliseconds remain Unix. Reboot still yields unknown time; watermark conversion and u32 range checks are consistent. The S07 integration finding is resolved, with no deployed state or BLE protocol migration (new clock remains unwired).

Tests-first regression failed against the old implementation, then native and native_asan PASS 19/19 each; no sanitizer diagnostics. Pinned Xtensa compile-only smoke PASS; ESP32 build/purity PASS at unchanged 47,504 B RAM / 964,333 B image. Whitespace/link checks PASS. No serial/Flash operation, upload, app change, thermal measurement, commit/push or gitlink update. Previous uncommitted edits retained.

Next S06 pure identity/hatch/migration work; board tests/NVS writes remain pending S01 Android acceptance and backup gate. Do not infer physical identity/persistence validation from host-only delivery.

## S06 partial — Pure identity/hatch/migration (2026-10-12)

[Scope and codec layout](docs/roadmap/sessions/S06-identity-core.md). CRC32, explicit 64-byte IdentityRecord and pure IdentityService implemented. Core stages candidates separately from successful storage acceptance; retains existing identity, never regenerates corrupt/too-new data, migrates valid MVP snapshot identity with birth unknown, and backfills birth only from Synced time in the hatch boot. Service does not change old learning/lifetime state. Hardware entropy/committed boot-counter come from future adapter, not this core.

Tests-first missing-header failure observed; native/ASan/UBSan full regression PASS 23/23 each. Xtensa compile smoke and ESP32 target build/purity PASS; unchanged 47,504 B RAM / 964,333 B image. Whitespace and local-link checks PASS. No board/Flash/serial operation, upload, app edit, commit/push or gitlink update; previous changes preserved.

S06 remains In progress: StorageKeys, bootc persistence, radio/RNG adapter, gesture/egg rendering, isolated namespace and board checks not implemented/run. S01 physical baseline still gates board steps. Next eligible S14 ActivityFsm (S07 prerequisite met); this does not satisfy S10/S12 dependencies on full S06. Android app work remains deferred.

## S11 preparation — isolated benchmark and restore (2026-10-12)

Owner requested S11. [E4/E5 record](docs/research/E4-E5-storage.md) contains concrete external source/config paths and pending measurement gates. Benchmark project /Users/xthao28/xuna_experiments/s11-storage built PASS (159,840 B static RAM / 365,053 B image); original-MVP restore project s11-mvp-restore built PASS (47,504 B RAM / 964,333 B image). Source uses committed be58099 display/config, not uncommitted refactor. Nothing merged into firmware. Runtime sample buffers add 120 KB static RAM; no BLE coexistence or wear claim.

Correction to earlier recommendation: S11 itself lists S04+backup, but global session rule §2.3 and cleanup baseline require S01 for storage-changing upload. Preparation is possible now; runtime requires S01 or explicit owner exception after reviewing isolated scope/backups/restore. No exception was silently recorded. USB device listing currently shows no ESP32. Fresh verified NVS/full-image backup required before filesystem experiment. Old backup alone is insufficient to validate new writes/restoration.

Draft ADR-0002 created, Proposed, no layout option/D2 approved. Serial-controlled NVS/FS benchmarks and storms/recovery are build-checked only; no format/flash/readback/cuts performed. Both current repositories and earlier uncommitted changes preserved; no source edit inside firmware in this preparation, commit/push or gitlink update. Source/firmware artifact hashes in external artifact-manifest.json. Documentation whitespace/local-link checks PASS. S11 In progress, E4/E5 unmeasured.

## Static pet UI — owner-requested priority (2026-10-12)

Owner paused S11 and requested direct reference-image UI in firmware, including upload when connected. [Static scene record](docs/roadmap/ui/UI-static-scene.md) contains complete configuration, generation, validation and file paths. Source preserved, nearest-neighbor contain conversion to 320×170, no crop; RGB565 108,800 B in Flash. Display uploads image once, no loop repaint or sprite buffer; life/BLE/storage logic unchanged. Existing toolchain/pins/rotation retained, PCB revision unknown.

Build PASS: RAM 46,072 B (−1,432), image 1,062,793 B (+98,460). Deterministic generation/Flash ELF placement and native 23/23 PASS. Board appeared again; fresh actual-table comparison/NVS backup PASS, then owner-authorized UI upload PASS. Startup draw 31,663 us; 25-second serial observation with no spontaneous reset/error. Owner confirmed “Ảnh đúng, màu đúng, ổn định”. NVS after upload equals backup byte-for-byte. Full-image benchmark/format/power-cut work was not run. Backup/log outside repo in xuna_backups/2026-10-12-static-ui.

Current board runs static UI from the uncommitted working tree (includes prior portable core extraction). No persistence format changes; S01 app/BLE full acceptance remains pending and is not satisfied by visual confirmation. S11 remains paused, not completed; no benchmark exception granted. No commit/push/gitlink update. Mobile/backend unchanged in this session. Next UI work only on owner request; no automatic resume of paused S11.

## Animated UI and Git delivery — 2026-10-12

Owner requested room/pet palette redesign, independent idle/blink/wiggle and upload, then provisionally accepted final corrected version and requested committing today's work. [Animated UI record](docs/roadmap/ui/UI-animated-scene.md) has current assets, implementation and physical evidence. Initial art/motion feedback incorporated; subsequent torso-foot seam and missing dark tips fixed with overlapped layers/immutable foot pieces/explicit tip color.

Final assets: 320×170 background plus 20 fixed 96×72 frames, 385,280 B in Flash; one 13,824 B startup region buffer. Pet visible height 65 px (~38%). No frame allocations/delay; palette masks/seam checks PASS. Native and ASan/UBSan 25/25 PASS; final build/upload PASS at RAM 46,144 B / image 1,340,569 B. Final 25-second log: draw max 4,754 us / loop gap max 4,767 us, stable heap, no spontaneous reset/error. GPIO0 Happy observed in v2 log; GPIO14 full physical check not separately logged. Owner: “tạm thời đã ổn có gì cần sửa tôi sẽ nói sau”. Not long-run/thermal/BLE validation.

NVS differs only in the newest valid snapshot generation/active-lifetime checkpoint (4/1200 → 5/1500); learning/episodes unchanged. Fresh partition/NVS backups and raw logs remain outside Git under xuna_backups/2026-10-12-animated-ui. S11 remains paused; source-only benchmark archive now versioned under docs/research/artifacts, no experiment performed.

Authorized Git delivery (no push): firmware **c84d4e3** contains today's core/tests/assets/UI; mobile **77d27ec** contains approved Flutter pin. Parent commit containing this entry records updated gitlinks and all today's root docs/research source archive. Backend unchanged. ADR-0001/0002/0006 remain Proposed; committing drafts does not accept them. S01 Android/full S06 and later M04 integration remain open. Earlier historical “uncommitted/not uploaded” entries describe their original sessions; this section is the current delivery.

## Mobile coding rules — 2026-10-13

Owner requested Clean Architecture coding rules for `mobile/`, based on the existing GetX base, to be read before any feature work. Added `mobile/AGENTS.md`, `mobile/docs/FEATURE_TEMPLATE.md` and `mobile/CLAUDE.md`; linked from `mobile/README.md`, root `CLAUDE.md` and AGENTS.md §9. The rules record current deviations in `features/device` and `features/home` (repository called from the controller, mixed data source/repository, hardcoded UI text, simulator as a fake repository) without refactoring them; a dedicated refactor session is not scheduled and needs owner approval.

Template code compiled and tested in a scratch copy only (Flutter 3.41.1: analyze no new issues, 14/14 tests, format clean); not run on the pinned 3.32.8. Mobile source, tests and dependencies unchanged. Mobile and root changes are uncommitted; gitlinks unchanged. No build, device or board operation.

Open item (resolved below): `mobile/pubspec.lock` was modified at 11:28 by pub from Flutter 3.41.1 / Dart 3.11.0, not by this session's commands (most likely an automatic IDE `pub get`; 3.32.8 was not installed on this Windows machine). Per D14 this lock must not be committed.

## Mobile toolchain fix and Clean Architecture refactor — 2026-10-13

Owner approved the recommended lock fix and the proposed refactor session, after adding a base widget rule to `mobile/AGENTS.md` §5.4: a base widget is mandatory once UI repeats across screens, existing base widgets must be used, and none exist yet because there is no XUNA design.

Toolchain: `fvm install 3.32.8` (Dart 3.8.1) succeeded. A machine-local `.vscode/settings.json` at the root sets `dart.flutterSdkPath` to that SDK and is ignored through `.git/info/exclude`, not `.gitignore`. Reload the VS Code window so the Dart extension stops using 3.41.1. `mobile/pubspec.lock` was restored from HEAD; `fvm flutter pub get` left it unchanged. Baseline before the refactor on 3.32.8: analyze clean, 10/10 tests.

Refactor (mobile, uncommitted), with no protocol, UUID, timeout or learning-rule change:

- `device` split into domain entities, an `abstract interface` repository, `DeviceException` kinds and ten use cases. Data now has wire models, explicit enum↔code mappers, `ProtocolCodec` in `data/codec`, `ResultCorrelator`, the `DeviceBleDataSource` contract with the FlutterBluePlus implementation and `SimulatorDeviceBleDataSource` (a fake transport, replacing the fake repository), and `DeviceRepositoryImpl`, which translates every error.
- `conversation`: `TextIntent` entity and `ParseTextIntentUseCase`.
- `home`: the controller uses only use cases with `buildState`. The page is split into feature widgets and uses locales (generated with get_cli), tokens and `nav.showConfirmDialog` for forget. The feedback pending-suggestion pre-check moved to `SendFeedbackUseCase`.
- Visible differences: localized error messages replace raw `e.toString()`; animation labels are capitalized; active time shows "giây"; the forget dialog uses the base confirm dialog style; text uses `AppTextStyle`; the simulator now rejects feedback whose target is not the pending suggestion (result 4).

Validation on Flutter 3.32.8 (Windows): `fvm flutter analyze` no issues; `fvm flutter test` 16/16 PASS. The 10 previous tests were ported to a layout that mirrors `lib/`, and 6 were added: error translation, stream mapping, explicit codes, feedback pre-check, controller error messages and forget confirmation. A rules audit by grep found no hardcoded UI strings, relative imports, `enum.index` wire use, direct dialogs or presentation→data imports. The feature template was re-verified on 3.32.8 in a scratch copy. Not run: native Android/iOS build, simulator/device app run, real phone BLE, board. Real BLE adapter logic was ported line by line but is unvalidated physically, as before.

Known gaps are listed in `mobile/AGENTS.md` §11: the simulator learner copy (S20), the route-scoped device repository, any stream error marking the UI disconnected (MVP behavior kept), and the inherited palette. Mobile and root changes are uncommitted; gitlinks unchanged.

## S01 Android acceptance — 2026-10-13 (in progress)

Owner requested S01 with the newly connected Android and ESP32. Both detected: REDMI Note 15 (model 2510DRA23E), Android 15/API 35, ADB authorized; ESP32-S3 at /dev/cu.usbmodem14101. Bluetooth ON.

Fresh actual partition table decoded: NVS 0x9000/0x5000. Verified backup outside Git at /Users/xthao28/xuna_backups/2026-10-13-s01/; NVS 20,480 B, SHA-256 866536762d74990c69db7254608620bcf4869af4aa3be8dcbc2e8b29465cc7e2; table SHA-256 bd0f7954aca2ef7d925ee21aaa1f3dc8822d1d6ce5cbbd26a135e5886bfff6ce. Manifest records hashes/sizes. Restore not tested; flash reads and opening Serial caused USB/UART reset; no firmware write/erase/upload.

Serial idle smoke confirms XUNA 0.2.0-mvp animated scene, 16 MiB Flash / 8 MiB PSRAM. Heap free 254,416 B; observed min 253,144 B; draw max 4,753 us; loop gap max 4,763 us. Short 12-second observation, not long-run/BLE/physical visual acceptance. Raw runtime-idle.log retained beside backup.

S01-fix-01: missing Android BLE permissions discovered. Owner explicitly approved fix in chat. Added legacy permissions capped at API 30 and SCAN/CONNECT with neverForLocation; no protocol or firmware change. Reference: https://developer.android.com/develop/connectivity/bluetooth/bt-permissions . Pinned Flutter 3.32.8 analyze clean and 16/16 tests PASS. Native debug APK build PASS (408.1 s). ADB install rejected by phone: INSTALL_FAILED_USER_RESTRICTED / Install canceled by user. Await owner enabling Install via USB and accepting prompt; no app launch or physical BLE validation yet. BLE transcript/learning/reboot/forget/power cuts remain pending.

Git inspection corrects old handoff: mobile refactor already committed at cebaf1c, firmware c84d4e3; initial root/children clean. Current permission fix uncommitted. No commit/push. S11 remains paused.

## S01 Android install and BLE smoke — 2026-10-13

Owner enabled Install via USB; adb install -r succeeded, XUNA launched on REDMI Note 15 / Android 15. Nearby devices permission granted through runtime dialog. Physical transport (not simulator) found 98:C3:77:A6:6F:D9, connected, read capabilities/life/two memory pages; Android GATT operations report success. APK permission dump confirms SCAN/CONNECT and legacy API-30 caps. S01-fix-01 native build/install/run PASS.

Automated UI taps requested Happy/Sleep/Curious/Idle; UI reflected each via device status. Owner confirmed LCD reactions and physical buttons correct. Learning trace: quiet selected Idle; reject via feedback button changed quiet preference to Happy, feedback 1/memory 1 of 8 with button provenance; another quiet suggestion selected Happy. Play preference remained Idle (play behavior itself not tested here).

Opening native USB Serial rebooted board (USB_UART_CHIP_RESET); app reported disconnect. Reconnect succeeded without rebuilding/flashing. Fresh reads retained quiet Happy, play Idle, feedback 1, memory 1/8; active time 2497 s; feedback buttons disabled because pre-reboot pending decision expired. Runtime-reboot.log and UI XMLs/Android BLE log retained outside Git in /Users/xthao28/xuna_backups/2026-10-13-s01/. These are decoded UI/GATT smoke evidence, not raw protocol-byte transcript.

S01 still In progress: waiting owner first physical power cut; ten-cut matrix, forget/reboot, conversation confirmation, malformed/duplicate/conflict, Bluetooth deny/off/timeout, raw inspector transcript and workload diagnostics remain open. S11 paused. No firmware upload/erase, commit/push. Firmware unchanged; Android manifest and handoffs uncommitted.

## S01 persistence smoke continuation — 2026-10-13

Owner reported one USB power cut (approximately 3 s) and reconnect. Fresh BLE reads retained quiet Happy, play Idle, feedback 1 and memory 1/8. Active lifetime was 2485 s vs earlier live 2497 s; firmware main.cpp checkpoints every 300000 ms, so uncheckpointed active time can be lost. One cut only; not the specified five idle + five post-feedback matrix or write atomicity validation.

Forget confirmation accepted for test-created data; fresh reads quiet/play Idle, feedback 0, memory 0/8, lifetime 2650 s. USB-UART reboot and reconnect confirmed same cleared preference/feedback/memory, lifetime 2657 s. Forget/reboot smoke PASS, life preserved. No firmware write/erase/upload. Text confirmation test awaiting owner input; raw-byte inspector transcript/error matrix and remaining power cuts still open. Current app connected; pending quiet suggestion exists after test preparation.

## S01 text feedback checkpoint — 2026-10-13

Owner sent like and subsequently confirmed (clarified explicitly in chat). Physical app reads feedback 1/memory 1 with quiet Idle approval and source text-confirmed. Screenshot android-text-candidate-owner.png records post-confirmation state. Text-confirmed command/provenance smoke PASS; no captured pre-confirmation counter, so no-learning-before-confirmation remains unvalidated physically. Test-created episode now remains on device after earlier forget/reboot test.

nRF Connect not installed; requested owner installation to continue observed raw-byte/error transcript required by S01. No raw bytes inferred from UI or manufactured from fixtures. Remaining five-idle/five-post-feedback cut matrix, diagnostics during feedback, phone-free routine/standalone checks and text pre-confirmation evidence open. S01 stays In progress; S11 paused; no firmware change/upload or commit/push.

## S01 observed read baseline — 2026-10-13

nRF Connect installed and connected. Five physical characteristic reads captured as raw hex: capabilities 8 B, status 16 B, life and both memory pages 20 B each. Life feedback 1/memory 1/pending 0; confirmed-text episode observed. Evidence: [S01 observed transcript](docs/roadmap/sessions/S01-v1-observed-transcript.md) (root-relative path); raw XMLs outside Git. No writes/upload in this read step. Scripted writes/error matrix and power-cut matrix remain pending; S01 In progress, S11 paused. Docs uncommitted; no commit/push.

S01 raw command follow-up: Notify enabled; observed 7-byte Suggest Quiet attempt returned invalid_length (2), request 1; no pending suggestion or memory/feedback changes. Recorded actual transmitted bytes/status/life in S01-v1-observed-transcript.md. Valid 8-byte command with fresh request 2 pending. No firmware/code changes, commit/push.

S01 raw Suggest Quiet request 2: actual 8-byte write accepted (OK), choice Idle, pending ID 2/canFeedback 1. Feedback/memory remain 1; both memory pages unchanged. Raw hex and capture copies recorded in S01-v1-observed-transcript.md. Approval request 3 targeting 2 remains next; no firmware upload, code change, commit/push.

## S01 automated inspector cases — 2026-10-13

Owner requested direct operation. ADB drove nRF Connect Byte Array writes after verifying entered hex. Approval request 3/target 2 PASS: feedback/memory 1→2, episode source 1. Exact duplicate request 3 PASS: OK, counters remain 2. Reused ID 3 with rejection payload PASS: conflict 6, no learning. New feedback request 4 without active pending PASS: invalid_argument 4, no learning. Raw status/life/both memory pages for each case in S01-v1-observed-transcript.md and external case JSON/XML captures. Pending suggestion 5 created (OK/canFeedback 1); awaiting owner GPIO0 press before feedback invalidation test. No firmware upload, source change, commit/push; S01 In progress, S11 paused.

## S01 raw inspector script complete — 2026-10-13

Pending request 5 accepted. Owner pressed GPIO0; feedback request 6 targeting 5 rejected (invalid_argument 4), pending cleared and counters unchanged at 2. Forget request 7 OK; memory/feedback 0, both preferences Idle, active lifetime 5991 retained. Full required inspector script now captured as actual writes + status/life/both memory pages in S01-v1-observed-transcript.md. These satisfy the observed transcript portion, not full S01. Remaining: ten-cut matrix, feedback/connected diagnostics, pre-confirmation text observation, off/deny/timeout and standalone/routine checks. Device now cleared of test episodes. No firmware upload/source change, commit/push; S11 paused.

Owner deferred remaining S01 physical matrix to a later session. Stop current device actions; next resume: fresh device/backup verification, controlled five-idle/five-post-feedback cut checks, BLE/feedback diagnostics and text pre-confirmation evidence. Required raw inspector sequence complete; S01 remains In progress, not Validated. Device has feedback 0/memory 0, preferences Idle after Forget; nRF connection may remain open. No commit/push requested.

## S01 commit checkpoint — 2026-10-13

Owner requested committing current changes. Mobile f756225 commits Android Bluetooth permissions; the parent commit containing this entry records its gitlink plus S01 validation/handoff and observed transcript. Firmware c84d4e3 and backend unchanged. Prior uncommitted descriptions are historical; no push. S01 remains In progress with remaining physical checks deferred by owner; S11 stays paused. Existing Flutter analyze/16 tests, native APK build/install and physical smoke/inspector evidence retained; commit checks: whitespace PASS. No new device operations or tests during commit-only delivery.

## S14 — ActivityFsm implementation (2026-10-14)

Owner requested continuing M04. This session is limited to pure firmware logic and host-test preparation; no board, mobile or backend operation was included.

- Fact: added `xuna/life/ActivityFsm.h` and `test/test_activity_fsm/test_main.cpp` in firmware.
- Contract: nine-state table (`BOOTING`, `IDLE`, `OBSERVING`, `REACTING`, `PLAYING`, `RESTING`, `SLEEPING`, `EVOLUTION_TRANSITION`, `ERROR_SAFE`), explicit illegal/guard reasons, monotonic wrap-safe dwell checks, energy/stage/restore/wake/reboot guards, and safe `ERROR_SAFE → BOOTING` recovery only.
- Proposed values: play/rest/sleep thresholds and dwell limits are M04 placeholders; they remain tuning inputs, not product decisions.
- Experiment: exhaustive 9×9 legal-pair assertions, guard reason assertions, wrap-around timeout assertions and guarded exits were authored.
- Validation limit: this Windows session has no `pio`, PlatformIO environment, `c++`, `g++`, `clang++` or `cl` executable. Native, ASan/UBSan, Xtensa compile and ESP32 build therefore could not run; only whitespace/static structure checks passed. No upload or runtime claim is made.
- Git: firmware changes are uncommitted/untracked; root/mobile/backend were not changed. No commit or push.
- Next: run `pio test -d firmware -e native`, `native_asan`, then `pio run -d firmware -e xuna_t_display_s3` on the pinned toolchain; keep S15 behind S14 native-green evidence.
## S15 — Needs/Mood implementation (2026-10-14)

Owner allowed continued offline coding. This session added the pure M04.5b needs/mood slice; no mobile, board or backend operation was included.

- Fact: added `xuna/life/Needs.h` and `test/test_needs_mood/test_main.cpp` in firmware.
- Contract: `Needs` stores bounded Q0.16 energy/stimulation, uses monotonic uint32 milliseconds, applies closed-form linear decay with carried remainders, and resets on boot so offline power-off time is not fabricated.
- Contract: `Mood` derives transient arousal/valence from needs and recent bounded signals, exposes Calm/Excited/Sleepy/Curious/Overwhelmed labels, and uses enter/exit hysteresis thresholds.
- Proposed values: decay rates, label thresholds and signal deltas are M04 placeholders; they are not product decisions and require Life Lab tuning.
- Experiment: tests were authored for partition-invariant catch-up, uint32 wrap, cold-boot reset, clamping and hysteresis behavior.
- Validation limit: no `pio` or C++ compiler executable is available on this Windows session. Native, ASan/UBSan, Xtensa and ESP32 checks could not run; only static/whitespace checks are available. No runtime claim is made.
- Git: firmware S14/S15 files are uncommitted/untracked; root handoff docs changed; mobile/backend untouched; no commit or push.
- Next: run S14 and S15 native/sanitizer suites when the pinned toolchain is available, then continue S16 policy/visual boundary.
## S16 — Action policy and visual boundary implementation (2026-10-14)

Owner allowed continued offline coding. This session added the pure M04.5c action/visual slice; no mobile, board or backend operation was included.

- Fact: added `ActionRegistry.h`, `RequestValidator.h`, `VisualIntent.h`, `BehaviorSelector.h` and `test/test_action_policy/test_main.cpp` in firmware.
- Contract: four public M04 actions (`idle`, `happy`, `sleep`, `curious`) are described by a const table with parameter schema, stage, cooldown, energy cost, permission and visual intent.
- Contract: validator is deny-by-default and checks unknown/parameter/stage/permission/activity/cooldown/energy/busy conditions without side effects.
- Contract: visual intents resolve through a bounded fallback chain; unknown or stage-incompatible intents fall back to a safe known pose.
- Contract: BehaviorSelector scores allowed, cooldown-ready candidates from novelty, needs and mood, then uses seeded PCG32 only for equal-score tie breaks.
- Experiment: tests were authored for the action table, validator rejection matrix, every known intent across stages, unknown/fallback resolution and selector determinism/filtering.
- Validation limit: no `pio` or C++ compiler executable is available on this Windows session. Native, ASan/UBSan, Xtensa and ESP32 checks could not run; only static/whitespace/purity checks are recorded. No runtime claim is made.
- Git: firmware S14/S15/S16 files are uncommitted/untracked; root handoff docs changed; mobile/backend untouched; no commit or push.
- Next: run S14–S16 native/sanitizer suites when the pinned toolchain is available; S17 wiring remains gated by these checks and later owner/board acceptance.
## S17 — FSM and visual boundary wiring (2026-10-14)

Owner requested continuing offline firmware coding; this session did not operate the board, mobile app or backend.

- Fact: `BleManager` now routes BLE opcode 1/2 and local button/quiet actions through the shared `RequestValidator`, `ActivityFsm`, `Needs` energy context and cooldown memory before applying a visual intent.
- Fact: `AnimationManager::setIntent` is the renderer boundary; unsupported stage intents and unknown values fall back to a safe existing `PetState` without changing the legacy animation timeout.
- Fact: the main loop owns Activity/Needs ticking, maps sleep/rest/error-safe transitions to visuals, and explicitly wakes Sleeping before a non-sleep action.
- Experiment: added a visual bridge regression test covering Happy, stage fallback, Sleep, ErrorSafe and unknown intent.
- Validation limit: no `pio`, C++ compiler or ESP32 build is available in this Windows session. `git diff --check` and static source checks are the only validation performed; no native, sanitizer, Xtensa or board result is claimed.
- Git: firmware S14–S17 files and root handoff docs remain uncommitted; no upload, mobile/backend operation, commit or push.
- Next: run `pio test -d firmware -e native`, `native_asan`, then the ESP32 build; review transition/error codes and perform physical BLE/button acceptance before promoting S17 beyond In progress.

## Learning Engine L1 — bounded contextual learner (2026-10-14)

Owner requested a gradual upgrade toward a real learning engine. This session is code-only; no board, mobile or backend operation.

- Fact: added `firmware/lib/xuna_core/include/xuna/learning/PreferenceLearnerV2.h` as an independent C++11, no-heap learner core. It keeps bounded posterior cells for context/action pairs, uncertainty-aware optimistic exploration, decision IDs/propensity, feedback provenance, duplicate protection, evidence/history caps, metrics and deterministic fingerprinting.
- Fact: added `firmware/test/test_learning_engine/test_main.cpp` covering initial exploration, contextual isolation, idempotent feedback, policy change after feedback, evidence bounds and deterministic replay.
- Proposal: keep `LifeEngine`/BLE on learner v1 until persistence v2 and migration from the 96-byte snapshot exist. The next integration should run V2 in shadow mode and compare decisions before changing production behavior.
- Experiment: L1 is intentionally a bounded contextual preference learner, not a neural network or full RL engine. The staged roadmap is recorded in [Learning Engine upgrade](docs/roadmap/learning/LEARNING-ENGINE-UPGRADE.md): L2 persistence/migration, L3 feature contexts, L4 delayed credit/conversation provenance, L5 optional sequence learning only if measured data justifies it.
- Validation limit: no `pio`, C++ compiler, native test, sanitizer, ESP32 build or board test was available in this session. Only source/static review and whitespace checks are recorded; no runtime or learning-quality claim is made.
- Git: firmware learner/test files and root handoff docs remain uncommitted; no upload, commit or push.
- Next: add a versioned persistence codec/migration and golden vectors, then shadow-wire V2 behind a feature flag without changing BLE payloads.

## Learning Engine L1.5 — prequential evaluation (2026-10-14)

- Fact: added `firmware/lib/xuna_core/include/xuna/learning/PrequentialEvaluator.h` with fixed-point Brier loss, accuracy and gain against a uniform baseline. It must be called before feedback to remain prequential/out-of-sample.
- Fact: extended `test_learning_engine` with a positive-gain-after-feedback case and invalid-decision rejection.
- Proposal: use these metrics in the future Life Lab/shadow comparison; do not interpret two host cases as proof of product-level learning.
- Validation limit: no native, sanitizer, ESP32 or board test; static checks only. No production wiring, commit or push.
- Next: align evaluator output with the planned Life Lab trace/golden format after S18/S19a dependencies are available.

## Learning Engine L1.6 — v1/v2 shadow harness (2026-10-14)

- Fact: added `firmware/lib/xuna_core/include/xuna/learning/LearningShadow.h` for test/Life-Lab use. It compares v1 greedy decisions with V2 contextual decisions and preserves the baseline action in each shadow packet.
- Contract: feedback is applied to v1 only after V2 accepts it, preventing duplicate/invalid candidate feedback from double-training the baseline.
- Fact: added tests for synchronized feedback, duplicate rejection and deterministic replay/fingerprint.
- Proposal: use this harness when the Life Lab trace runner exists; production remains on v1 until shadow evidence, persistence sequencing and owner acceptance are complete.
- Validation limit: no native, sanitizer, ESP32 or board test; static checks only. No commit or push.

## Learning Engine L1.7 — bounded trace runner (2026-10-14)

- Fact: added `firmware/lib/xuna_core/include/xuna/learning/LearningTrace.h` with fixed-size Choose/Feedback events, an eight-decision window, prequential scoring and deterministic report fingerprint.
- Fact: added tests for accepted feedback, duplicate rejection, unknown decision IDs and same-seed replay.
- Proposal: use this as the learner kernel inside the future S19a Life Lab runner; do not present it as the full trace DSL or M04 validation.
- Validation limit: no native/compiler/ESP32 run; static checks only. No production wiring, commit or push.
- Next: when the toolchain is available, run this test first, then move the event model behind the planned `firmware/sim/lifelab.cpp` adapter.

## Learning Engine L1.8 — bounded explanations (2026-10-14)

- Fact: added `firmware/lib/xuna_core/include/xuna/learning/LearningExplanation.h` with numeric per-action evidence and reason codes.
- Fact: added tests showing exploration is labeled separately from a posterior winner; invalid decisions yield no explanation.
- Proposal: later map this numeric contract into Evolution Journal/Life Lab views. Do not generate user-facing causal prose until the evidence fields are available.
- Validation limit: no native/compiler/ESP32 run; static checks only. No production or mobile wiring, commit or push.
## Commit checkpoint — 2026-10-14

- Firmware child repository committed as a518ede (`feat(firmware): add bounded digital life and learning layers`). It contains S14–S17 M04 logic, L1–L1.8 learning core/evaluation/shadow/trace/explanation layers and host-test preparation.
- Parent repository commit records the handoff docs and roadmap. No push was performed.
- Next steps: run `pio test -d firmware -e native`, `pio test -d firmware -e native_asan`, then `pio run -d firmware -e xuna_t_display_s3`; run the learner trace suite; continue S18/S19a only after required M04 storage/toolchain gates. Keep production learner v1 until shadow/persistence acceptance.
## Learning Engine L1.9 — trace DSL and host runner preparation (2026-10-14)

- Fact: added `firmware/lib/xuna_core/include/xuna/learning/LearningTraceDsl.h` with bounded C++11 parsing and typed errors for the learning-focused trace subset plus reserved S19a verbs.
- Fact: added `firmware/sim/lifelab.cpp` and `firmware/sim/README.md`. The runner emits prequential/shadow CSV metrics and a deterministic fingerprint; unsupported non-learning verbs are reported rather than silently executed.
- Fact: extended learner tests for parser vectors, malformed input and parser-to-runner replay.
- Proposal: use this binary as the learner kernel when the full S19a LifeCore simulator is authorized after S18; do not mark S19a complete from this preparation slice.
- Validation limit: no C++ compiler/PlatformIO/native/ESP32 run is available in this session. Static/whitespace checks only; no mobile/board operation, commit or push.
- Next: compile `sim/lifelab.cpp` when the toolchain is available, then add the S19a store/clock/FSM adapters only after S18 prerequisites are met.

## L1.9 commit checkpoint — 2026-10-14

- Firmware child commit: `f784626` (`feat(firmware): add learning trace DSL and host runner`).
- Parent handoff commit records the new child pointer, parser/runner roadmap and validation limits. No push.

## M04 LifeCore composition and snapshot lab — 2026-10-14

Owner requested continued offline implementation. This slice stayed within firmware core/simulator/docs; no mobile, board, BLE transport or backend operation.

- Fact: added `LifeCore`, `LifeCoreSession`, `LifeCoreTraceRunner` and `LifeCoreSnapshotLab` as C++11 host/core preparation layers. The existing v1 `LifeEngine` remains authoritative; V2 learner remains a shadow candidate and resets on reboot.
- Fact: added bounded FIFO/overflow reporting, ClockModel projections, deterministic trace replay, A/B snapshot/power-cut/corruption recovery fixtures and a `lifecore_lab` CSV CLI.
- Fact: reboot now resets ActivityFsm, cooldown timestamps, pending decision and transient mood/needs state; a regression test covers action acceptance after reboot.
- Validation: `git diff --check`, firmware whitespace check and internal include-resolution checks pass. No C++/PlatformIO toolchain exists in this session, so native, sanitizer, ESP32 and simulator execution were not run. No board/mobile result is claimed.
- Git: firmware and root handoff changes remain uncommitted; no push.
- Next: run native + ASan/UBSan + ESP32 builds when the pinned toolchain is available, then review S18/S19a storage and production-wiring gates before any BLE/main-loop integration.
## M04 trace persistence experiment — 2026-10-14

- Fact: `LifeCoreTraceRunner` now drives `LifeCoreSnapshotLab`; `reboot` recovers the newest valid slot, `powercut` fails the next requested commit, and feedback persistence requests are auto-committed in the host experiment.
- Fact: CSV output and Unity coverage now include persist failures, reboot count, final event count and generation. `sync/day/expect` remain explicit unsupported verbs.
- Validation limit unchanged: whitespace and include-resolution checks pass; no C++/PlatformIO toolchain, simulator execution or board/mobile operation was available. No production persistence decision was made.

## M04 firmware review fixes — 2026-10-14

Owner requested a careful review of today's firmware commits and approved fixing the findings. This was the first session with the pinned toolchain for these slices (macOS); no board, mobile or backend operation.

- Fact: before the fixes 5/16 native suites failed (two C++11 compile errors, three incorrect test setups). The ESP32 target already built.
- Fact: production defects fixed: energy never recovered, so the pet stayed in Resting forever after ~48 min uptime; BLE opcode 2 retargeted pending feedback after a rejected choice; a new reaction did not restart the Reacting timer.
- Decision (owner, 2026-10-14): fix #1 by recovering energy while Resting/Sleeping. Recovery rate 2048/min is a **Proposed** placeholder.
- Fact: `ActionGate` now holds the single action path for `BleManager` and `LifeCore`; LifeCore visual expiry and accepted-only decisions fixed; ErrorSafe reboot guard reports `GuardReboot`.
- Validation: native and ASan/UBSan 87/87 PASS; ESP32 build SUCCESS (RAM 46,208 B, Flash 1,343,357 B, purity PASS); `sim/` programs build; `git diff --check` PASS. Details: [review fixes record](docs/roadmap/milestones/M04-review-fixes-2026-10-14.md).
- Not run: board upload and physical acceptance. No storage-format change.
- Git: firmware committed as `aa2dbca` (`fix(firmware): recover energy at rest and share the action gate`); parent commit records the gitlink. No push.
- Next: owner S17 board check (sleep/wake, result 5 message, rest/recovery), then Life Lab tuning of Proposed values.

## Mobile UI — XUNA design system and four-tab home (2026-10-14)

Owner requested building the mobile UI from the Claude Design "XUNA App" project, adapted to the app and plan. Owner chose real data only, locked "SẮP CÓ" parts, and bundled fonts.

- Fact: tokens, OFL fonts, 11 base widgets, 24 icons and a four-tab home shell replace the MVP single-screen home; all device logic still goes through the existing use cases and repository. No protocol, firmware, dependency or SDK change.
- Fact: chat transcript is in memory only (max 40 lines); device errors also appear as snack bars.
- Assumption: design images over 256 KiB could not be read through the connector; `rain.png`, `hero.png` and a redrawn pixel-book SVG stand in for `room`, `avatar`/growth sprites and `book`.
- Validation: `pubspec.lock` unchanged; analyze clean; 29/29 tests. Details: [mobile UI record](docs/roadmap/ui/mobile-ui-design-system.md).
- iOS Simulator (iPhone 13, simulator transport): app launched, Nhà screenshot inspected; other tabs covered by widget tests.
- Not run: real phone with the board, Android.
- Git: mobile committed as `df7d2ee` (`feat: add XUNA design system and four-tab home`); parent commit records the gitlink and handoff docs. No push.
- Next: owner visual check; export the original images; restyle base dialogs/snack bars.

## S18 readiness audit — 2026-10-14

- Source audit against S18/T1 confirms host LifeCore preparation only; production still owns business logic in main/BleManager. S10/S13 end-to-end and S17 owner checks remain unmet.
- Missing composition: identity, canonical event queue, pure command dispatch, BehaviorSelector, typed persistence including needs, and thin main loop. Pending-feedback invalidation and commit-failure semantics need parity coverage before integration.
- Evidence and next sequence: [S18 readiness review](docs/roadmap/sessions/S18-readiness-review.md). No code change, runtime test, board/app operation, commit or push in this audit. Prior 87/87 native/sanitizer and target build results are not full S18 acceptance.
- Next without a phone: execute existing host trace/snapshot experiments and record evidence; keep production/storage integration gated.

## S17 board upload smoke — 2026-10-14

- Owner explicitly authorized backup and upload after connecting ESP32. Detected ESP32-S3 rev v0.2, MAC 98:C3:77:A6:6F:D8 at /dev/cu.usbmodem14101; chip revision does not establish PCB revision.
- Device and target partition tables match: NVS 0x9000/0x5000. Backup outside Git: /Users/xthao28/xuna_backups/2026-10-14-s17/ (table, NVS, manifest, pre/post-upload Serial). NVS size 20,480 B, SHA-256 d7d12a9bebe95738bad48bdee08ce90f7de284bbd928ca24611286c5988ec52d; partition table SHA-256 bd0f7954aca2ef7d925ee21aaa1f3dc8822d1d6ce5cbbd26a135e5886bfff6ce. Restore not tested.
- Target aa2dbca build PASS (RAM 46,208 B, Flash 1,343,357 B, purity PASS); upload PASS with hash verification. Upload ranges exclude NVS; no erase-all or restore requested.
- Serial boot smoke PASS: version 0.2.0-mvp (does not expose commit), Flash 16 MB, PSRAM chip 8 MB, display initialized; no storage/BLE init error in captured log. Opening USB Serial caused USB_UART_CHIP_RESET. Initial idle draw max 4,754 us and loop gap max 4,767 us; no mean timing logged, so S17 +20% render acceptance is not established.
- Pending: owner LCD/buttons observation, sleep/wake and result 5 through BLE, rest/recovery, pet-state preservation through decoded reads, render baseline comparison. Full S17/S01 remain In progress. No source change, mobile operation, commit or push.

- Follow-up Serial capture observed GPIO0 Happy twice and GPIO14 Idle once; subsequent diagnostics returned to idle after the first Happy. Input routing smoke PASS; LCD appearance remains owner-observed/pending confirmation. Capture: button-observation-serial.log in the same external backup directory.

- S17 owner visual confirmation (2026-10-14): owner confirmed normal XUNA/Idle LCD, GPIO0 Happy and return to Idle, followed by GPIO14 Idle on firmware aa2dbca. Combined with captured button Serial logs, LCD/button smoke PASS. Full S17 remains In progress: BLE sleep/wake/result 5, rest/recovery and render timing acceptance still pending.

## Windows toolchain and gcc fix — 2026-10-15

- The Windows machine now has PlatformIO Core 6.2.0 (`~/.platformio/penv/Scripts/pio.exe`, not on PATH), `espressif32@6.5.0`, and MSYS2 UCRT64 gcc/g++ 16.2.0 (`C:\msys64\ucrt64\bin` on the user PATH; restart VS Code to pick it up). No WSL distribution; `native_asan` still requires the Mac or WSL.
- Fix: `BleProtocol.h` `remember()` split onto two lines to satisfy gcc 16 `-Werror=misleading-indentation`; no behavior change.
- Validation: native 87/87 PASS; ESP32 build SUCCESS (RAM 46,208 B, Flash 1,343,337 B); `git diff --check` PASS. No upload, commit or push; firmware change uncommitted.
- Editor (clangd in Antigravity): new `firmware/.clangd`; `compile_commands.json` and `.cache/` gitignored. After a clean checkout, or when the build config changes, regenerate with `pio run -d firmware -e xuna_t_display_s3 -t compiledb`. Machine-local pieces live outside Git: `clangd.arguments` `--query-driver` in Antigravity user settings and `%LOCALAPPDATA%\clangd\config.yaml` (MSYS2 target for `test/` and `sim/`). `clangd --check` reports no diagnostics on 65 sources.
- Next: unchanged (S17 BLE checks with a phone, or host trace/snapshot experiments).

## Host lab runs — 2026-10-15

- Ran `lifelab` and `lifecore_lab` (g++ 16, `-Werror` clean) on 12 annotated traces now in `firmware/sim/traces/`. Results are deterministic across reruns. Evidence: [lab runs record](docs/roadmap/learning/lifecore-lab-runs-2026-10-15.md).
- Fact: LifeCore reboot/power-cut/pending/duplicate bookkeeping behaves as designed.
- Finding (S18 blocker): commit-failure semantics differ from production. BLE opcode 3 commits a copy, then applies it, and keeps the decision pending for retry (result 7). `LifeCore` applies first, clears pending and cannot report or retry a failed commit in the lab. Plan §9.5 already specifies the production model (commit first, RAM unchanged and `not_ready` on failure), so no new decision is needed: bring `LifeCore` in line and add a parity test before it replaces the BLE path.

## Learning competitive upgrade plan — 2026-10-15

- Owner requested a review of large projects and a learning upgrade plan, and allowed revising the plan where needed. Documentation only.
- Added [competitive upgrade plan](docs/architecture/XUNA_LEARNING_COMPETITIVE_UPGRADE.md) (Proposed). It reviews Moflin, LOVOT, aibo, Loona, Emo and Vector (public claims), and Creatures, Black & White, Oudeyer IAC, contextual/discounted bandits, FSRS, Generative Agents memory, TinyOL/MCUNetV3 and ESP-SR against XUNA constraints.
- Amended the implementation plan as [P] items: §9.4 Alternative D (learning-progress curiosity) plus a note that the v2 code is undiscounted UCB, not the §9.3 estimator; §9.9 gradual-drift and noisy/sparse-owner scenarios; new §9.10 teachable tricks; decisions L-D1–L-D5 in §18.
- Phases: 0 closed-loop Life Lab (S19a) → 1 v3 learner per §9.3 with E10 A/C/D (M05a) → 2 habits (M05d) → 3 teachable tricks → 4 formation arc/memory/drive-reduction → 5 conversation → 6 senses R&D (touch first).
- Owner decisions pending: L-D1–L-D5, plus existing D5 (more actions) and D15.
- No code, build, board/mobile operation, commit or push.
- Fact: the runners are open-loop, print one summary row and cap traces at 64 events. They cannot tune Proposed needs/energy/FSM values or show preference learning. v2 Brier: 0.052 with a consistent signal and 0.279 with no signal, against a 0.25 uniform baseline.
- Proposal (not started, needs owner approval; overlaps S19a): closed-loop user model, time-series output (activity/needs/mood/visual) and long generated runs.
- Git: new traces, `sim/README.md` link and the record are uncommitted; no production code change, board/mobile operation, commit or push.

## Learning decisions and Life Lab Phase 0 slice 1 — 2026-10-15

- Owner approved L-D1–L-D5 (AGENTS.md §3; plan §18). L-D5 is research only for touch, IMU and microphone. D5 and D15 remain open.
- Added the host-only closed-loop learner bench: `xuna/lab/OwnerModel.h`, `xuna/lab/LearnerBench.h`, `test/test_life_lab`, `sim/learning_bench.cpp`. Native 95/95 PASS; ESP32 build unchanged (RAM 46,208 B, Flash 1,343,337 B).
- Fact (200 seeds): v1 and v2 pass the §9.9 B hypothesis and keep state unchanged without feedback (D). Both fail reversal (C): v1 recovers in 0% of seeds within 60 trials, v2 in 26%. v1 is worse than random under reversal and drift. Evidence: [Phase 0 record](docs/roadmap/learning/life-lab-phase0-2026-10-15.md).
- Git: firmware lab files, traces, `.clangd`, `.gitignore`, `BleProtocol.h`; root docs, AGENTS.md and plan edits are uncommitted. No push.
- Next: Phase 1 learner v3 per plan §9.3 (discounted Beta + hierarchical prior) into the bench, with E10 variants A/C/D; or Phase 0 slice 2 (`LifeCore` time series + §9.5 parity fix).

## Cloud & Brain architecture baseline — 2026-10-16

- Owner delegated the Cloud architecture choices and approved saving the plan and decisions. Added [XUNA_CLOUD_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md) with Phase 0–6 gates and CLD-00–60 work items.
- Approved device authority, separate User/Pet/Brain/Device identities, one active Brain and authoritative Device per Pet in Phase 1, and the provider-output confirmation boundary (ADR-0008).
- Approved the future FastAPI/PostgreSQL modular-monolith baseline, phone gateway first, U0 default, no raw-audio retention and no conversation-text retention by default (ADR-0009). D23 is partially approved; launch-specific legal/region/retention details remain open.
- No Cloud implementation may start before M05b/S38 acceptance. E15 gates learning suggestions; E14 plus D19/D22 gate direct MQTT/TLS; VOICE-01–04 gate voice services. Provider, broker, hosting and D24 remain open.
- Documentation only: no backend code, dependency, provider call, database, board/app operation, build, commit or push. `git diff --check` passed.

## Hybrid offline + online learning plan — 2026-10-15

- Owner asked to integrate an online layer (cloud, MQTT) while keeping the offline learning. Recorded as owner-requested product direction in AGENTS.md §3. Documentation only.
- Added [ADR-0007](docs/decisions/ADR-0007-hybrid-offline-online-learning.md) (Proposed) and plan §22: contract H1–H8 (offline-complete, device authority, bounded expiring suggestions, owner evidence wins, new provenance `cloud_inferred`/`population`, opt-in data classes U0–U3, exit plan, per-device security), capabilities O1–O6, two-stage transport (phone gateway → device MQTT/TLS), sequencing.
- Added experiments E14 (Wi-Fi + MQTT/TLS + BLE coexistence) and E15 (cloud consolidation benefit in Life Lab), decisions D21–D24 (Proposed), the decision index rows and an online-layer table in the competitive upgrade plan.
- Sequencing: no network code now; make persistence v2/experience log export-ready; Stage 1 O1 only after M05a acceptance; Stage 2 after D19/D22/E14.
- No code, build, board/mobile operation, commit or push.
- Owner approved D21 (contract H1–H8) and D22 (phone gateway first, device MQTT/TLS only after E14) on 2026-10-15; broker/provider, D23 and D24 remain open. Recorded in AGENTS.md §3, plan §18 and the decision index.
- Owner asked to commit the current work and defer Phase 1 (learner v3 per §9.3) to a later session.
- Commit checkpoint (2026-10-15): firmware child `97b0efb` (`feat(firmware): add closed-loop learner bench, lab traces and clangd setup`); the parent commit records the gitlink, AGENTS.md decisions, plan §9/§18/§22 amendments, ADR-0007 and today's records. No push.
- Next session: Phase 1 learner v3 per plan §9.3 into the Life Lab bench (E10 variants A/C/D), or Phase 0 slice 2 (LifeCore time series + §9.5 parity).

## Phase 1 slice 1 — learner v3 candidate (2026-10-15)

- Owner asked to start Phase 1. Added lab/shadow `PreferenceLearnerV3` (plan §9.3 discounted Beta + hierarchical day-part prior; §9.4 policies Greedy/A/C/D), 10 unit tests, bench adapters, a `dayparts` scenario and `--gamma`. No production wiring (D1, S18 gates).
- Validation: native 105/105 PASS; ESP32 build unchanged (RAM 46,208 B, Flash 1,343,337 B); purity PASS.
- Fact (200 seeds): v3 C (UCB) recovers after reversal in 84% of seeds at γ 0.95 and 98% at γ 0.90 (v1 0%, v2 26%); it is the preliminary E10 winner. A and D over-explore when ratings are sparse. The hierarchical prior learns slower than flat contexts when day parts disagree. Evidence: [learner v3 record](docs/roadmap/learning/learner-v3-phase1-2026-10-15.md).
- Git: firmware v3 files and bench changes, root docs uncommitted. No push.
- Next: sweep k/m and D parameters, add a generalization scenario; then propose v3 C (γ in [0.90, 0.95]) for E10 acceptance, L2 persistence and shadow wiring.

## Phase 1 slice 2 — learner v3 parameter sweep (2026-10-15)

- Added `feedbackAware` ε scaling to v3, a late-context schedule and generalization metric to the bench, the `new_daypart` scenario, `sim/learner_sweep.cpp` (137 configurations × 8 scenarios × 200 seeds) and `v3_C_tuned`. Native 106/106 PASS; ESP32 build unchanged.
- Fact: C (UCB) with γ 0.90, k 1, m 1, bonus 0.15 ranks best (score 1.11 vs 1.27 for plan defaults; best A 2.42, best D 3.18). Tuned v3 recovers after reversal in 94% of seeds and under drift in 96%; it beats or matches v2 everywhere except disagreeing day parts (4.15 vs 2.88); on a new day part it is right 98% of the time immediately (v2 83.5%).
- Proposal: these values replace the §9.3/§9.4 defaults as **Proposed** values, pending owner review of visible flips and board checks. Evidence: [learner v3 record](docs/roadmap/learning/learner-v3-phase1-2026-10-15.md) slice 2; plan §9.4 note.
- Git: uncommitted (firmware v3, bench, sweep, tests; root docs). No push.
- Next: L2 persistence v2 (used shape only) + migration from the 96-byte v1 snapshot, §9.6 explanation mapping, then shadow wiring behind LifeCore (S18 gates still apply to production).

## Phase 1 slice 3 — learner codec, migration, explanation (2026-10-15)

- Added `LearnerV3Codec` (learner payload for LifeSnapshot v2, 408 B for 2 × 5 × 4, typed errors, validate-before-mutate, shape migration), `migrateFromV1` with a mass cap of 1/(1 − γ), `LearnerV3Explanation` (§9.6 fields and reasons), raw `rated` counts in v3, and 7 tests. Fixed `tools/check_core_purity.py` to read UTF-8 (it crashed on Windows cp1252).
- Validation: native 113/113 PASS; ESP32 build unchanged (RAM 46,208 B, Flash 1,343,337 B); purity PASS. Lab only, not linked.
- Proposal: capped v1 migration amends plan §7.5 (Proposed). Container/CRC/medium stay S12a/D2.
- Git: uncommitted. No push.
- Next: v3 as the shadow candidate behind LifeCore/LearningBridge, then E10 acceptance review and the §9.5 parity fix.

## Phase 1 slice 4 — v3 shadow candidate in LifeCore (2026-10-15)

- Added `LearningBridgeV3`; `LifeCore` now shadows learner v3 (`shadowConfig()` tuned Proposed values) instead of v2, exposes `shadowMetrics()`, resets the candidate on boot. Host core only; production BLE path unchanged.
- Finding: the old v2 bridge credited ratings to v2's own (unshown) action; v3 bridge credits the shown action. Earlier v2 shadow agreement numbers are not valid evidence.
- Validation: native 115/115 PASS; ESP32 build unchanged; LifeCore traces replay with identical bookkeeping. Evidence: [learner v3 record](docs/roadmap/learning/learner-v3-phase1-2026-10-15.md) slice 4.
- Git: uncommitted. No push.
- Next: §9.5 commit-failure parity in LifeCore (commit first, RAM unchanged, `not_ready`, retry), then E10 acceptance review; production stays gated by S18.

## Phase 1 slice 5 — §9.5 commit-first parity in LifeCore (2026-10-15)

- Added `ILifeCommit`; `LifeCore` (via `LearningBridgeV3`) now validates, stages v1, commits, then applies v1 and v3. A failed commit leaves RAM unchanged, keeps the decision pending and sets `feedbackNotReady`. The snapshot lab is the committer; trace runner and c2/c3 expectations updated.
- Resolves the 2026-10-15 lab finding for LifeCore (production BleManager already did this). Native 116/116 PASS; ESP32 build unchanged.
- Git: uncommitted (Phase 1 slices 1–5). No push.
- Next: E10 acceptance review packet for v3 C tuned; remaining production gates: S12a container/D2, S10 trusted time, D5 actions, S18 integration, owner board checks.
- Commit checkpoint (2026-10-15): firmware child `c4e7e19` (`feat(firmware): add learner v3 shadow with codec, sweep and commit-first feedback`), Phase 1 slices 1–5; the parent commit records the gitlink and docs. No push.

## D5 decision and product learner vocabulary (2026-10-15)

- Owner approved D5: learnable actions idle/happy/curious (existing art) and the GPIO0 press as a learnable `button_greeting` context; day parts stay planned with S10. Recorded in AGENTS.md §3, plan §18 and the decision index.
- Added `learning/LearnerVocabulary.h` (interaction enum, index → ActionId, `productLearnerConfig()` 3 × 5 × 3, 458 B payload), a vocabulary/migration test and two product-shape bench scenarios. Native 117/117 PASS; ESP32 build unchanged.
- Fact: in the 3 × 3 product shape tuned v3 learns stable preferences as fast as v2 (median 14 trials) and recovers after reversal in 96.5% of seeds (v2 20.5%). LifeCore shadow stays 2 × 2 until v3 is authoritative.
- Git: uncommitted. No push.

## E10 review packet (2026-10-15)

- Added [E10 review packet](docs/roadmap/learning/E10-review-packet-2026-10-15.md): decision requests E10-A (select v3 C UCB for M05a), E10-B (tuned starting parameters, provisional until board check), E10-C (capped v1 migration amendment); §9.9 status (B, C, D, isolation, spam met on host; E reboot parity partly; stated-vs-rated not started); owner board checks; remaining gates.
- Added §9.9 spam test (1,000 attempts → 1 apply, 1 commit). Native 118/118 PASS.
- Git: D5 vocabulary, spam test and packet uncommitted. No push.
- Next: owner decision on E10-A/B/C; then Phase 0 slice 2 (LifeCore time series) or S12a/D2 preparation.
- Owner approved E10-A (v3 + UCB for M05a), E10-B (γ 0.90, k 1, m 1, bonus 0.15; re-check on board) and E10-C (capped v1 migration amending §7.5) on 2026-10-15. Recorded in AGENTS.md §3, plan §7.5/§9.4/§16.2, the decision index and the packet. Board use stays gated by S12a/D2, S10, S18, E2/E6 and owner acceptance.
- Commit checkpoint (2026-10-15): firmware child `2ad51df` (`feat(firmware): add D5 learner vocabulary and feedback spam test`); the parent commit records the gitlink, D5 and E10 approvals and the E10 packet. No push.

## Life Lab Phase 0 slice 2 — needs/rest/mood timeline (2026-10-15)

- Added `sim/life_timeline.cpp` (hours-long LifeCore runs, idle/casual/active owners), `sim/life_sweep.py`, and inactive Life Lab knobs: `ActivityThresholds` (incl. `wakeEnergy`, `resumeInterruptedRest`), `LifeTuning.actionCostPercent`/`stimulationPerInteraction`, `Needs::spend/stimulate`, `LifeCore` tuning parameters. Defaults keep the shipped behaviour; 2 new tests. Native 120/120 PASS; ESP32 RAM 46,224 B (+16), Flash 1,343,453 B (+116).
- Fact (also true on the board): after ~49 min XUNA cycles 8 min awake / 4 min resting with energy 25–38% (91% of time below 37.5%); actions never spend energy; stimulation never rises, so excited/curious/overwhelmed moods are unreachable; interrupted rest is lost; sleep needs an explicit wake.
- Proposal: life-feel targets (11 checks) and candidate values (restExit 64%, recovery 6144/min, action cost 10%, stimulation +4096, wake at 80%, resume interrupted rest) that pass all targets. Owner decision needed before enabling on the board. Evidence: [needs timeline record](docs/roadmap/learning/life-lab-needs-timeline-2026-10-15.md).
- Git: uncommitted. No push.
- Owner approved the life-feel targets and enabling the candidate configuration for a board trial (2026-10-15). Added `xuna/life/LifeFeel.h`; production `main.cpp`/`BleManager` and `LifeCore` defaults use it; 1 more test. Native 121/121 PASS; ESP32 build SUCCESS (RAM 46,224 B, Flash 1,343,589 B). **Not uploaded:** the board was not connected (only COM1). Next: owner connects the board; back up NVS and the partition table, upload (NVS excluded), then a 1–2 hour owner observation.

## Learner v3 board-trial shortcut (2026-10-15)

- Owner chose to skip LifeSnapshot v2 for a first board trial. Added `xuna/learning/BoardLearner.h` (v3 decides; v1 stays the durable 96-byte record; commit-first via `StorageCommit`; rebuild at boot), `approvedLearnerParameters()`/`v1CompatibleLearnerConfig()`, `LocalBehavior::choosePreferred`; wired into `BleManager` (opcodes 2/3/4, preference bytes) and `main.cpp`. 6 new tests; native 127/127 PASS; ESP32 build SUCCESS (RAM 48,328 B, Flash 1,347,081 B).
- Known limits: recency lost across reboots; 2 × 2 shape only (no curious/greeting) until S12a. Evidence and board checklist: [board trial record](docs/roadmap/learning/learner-v3-board-trial-2026-10-15.md).
- Not uploaded: board not connected. Next: owner connects the board → NVS/partition backup → upload → Serial check → owner observation (life-feel + learning).
- Commit checkpoint (2026-10-15): firmware child `efdd915` (`feat(firmware): enable life-feel tuning and learner v3 board trial`) with Life Lab slice 2 (needs timeline, knobs, LifeFeel) and the BoardLearner shortcut; the parent commit records the gitlink and docs. Not uploaded; no push.

## Board trial instrumentation and S12a/S12b (2026-10-15, later session)

- Board not connected (only COM1). Rebuilt `efdd915`: matches the recorded size. Prepared a read-only backup script outside Git (session scratchpad) following session plan §5; target backup folder `C:\Users\Thao\xuna_backups\2026-10-15-learner-v3-trial\`.
- Finding: the LCD shows only the sprite (resting draws idle), Serial/BLE carry no needs, and the board does not compute mood, so the life-feel trial was not measurable. Owner chose Serial instrumentation: `needs …` every 5 s, `activity_change …` on changes; `tools/serial_capture.py`, `sim/board_needs_report.py`. Firmware commit `5d872d3` (owner request). Native 127/127, ESP32 RAM 48,328 B, Flash 1,347,657 B. Not uploaded.
- Owner chose S12a + S12b on host ahead of S11/D2. Added `xuna/persist/SnapshotCodec.h`, `Migrations.h`, `SnapshotStore.h` and `test/test_snapshot_v2` (16 tests). Layout frozen in plan §7.5 (544 B product snapshot). Native 143/143 PASS; ESP32 build unchanged; purity PASS; Xtensa compile smoke PASS. Evidence: [S12 record](docs/roadmap/sessions/S12-snapshot-v2-2026-10-15.md).
- S13 notes: `recover` needs about 6 KB stack on Xtensa (use static scratch); log `corruptSlots`; NVS power-cut behaviour still needs S11/E5.
- Editor: clangd on this machine cannot find the ESP32 toolchain's standard headers (`cstdint`); machine-local `--query-driver` setting, not a code issue.
- Git: firmware `5d872d3` committed; S12 code and all root docs uncommitted. No push, no board operation.
- S18 preparation (owner choice: replace the v1/v3-shadow composition): new `xuna/learning/ProductLearner.h`; `LifeCore` uses it (v3 3 × 5 × 3 decides, LifeSnapshot v2 via `ISnapshotCommit`), `Greeting` event for GPIO0 (device decision IDs ≥ 0x80000001), allowed-mask choices, direct-input invalidation, forget on both slots; `LifeCoreSnapshotLab` (`MemorySnapshotStore`) and `LifeCoreTrace` on v2. Recovery fix: lone torn v2 slot without v1 → Missing. Native 152/152 PASS; ESP32 build unchanged; Xtensa smoke PASS; `life_timeline` identical to HEAD; trace replays as expected. Evidence: [S18 preparation record](docs/roadmap/sessions/S18-prep-product-learner-2026-10-15.md). Production firmware unchanged; uncommitted.
- S10 host part: `ClockModel` moved into `LifeCore` (`LifeCore::sync`), learner day parts from trusted time (coarse cell when unknown), LifeSnapshot v2 Clock section (watermark + offset, lazy commit), 32 → 64-bit monotonic extension (`millis()` wrap would otherwise block syncs after ~49.7 days). Trace `sync` verb + `c8_dayparts.trace`. Native 159/159 PASS; ESP32 unchanged; Xtensa smoke PASS; `life_timeline` identical; c1–c6 identical. Evidence: [S10 host record](docs/roadmap/sessions/S10-host-trusted-time-2026-10-15.md). Protocol/firmware/mobile/owner parts of S10 remain. Uncommitted.
- D3 approved by the owner (120 s feedback window; direct input still invalidates). Recorded in AGENTS.md §3, plan §18/§9.5 and the decision index. Implemented in `ProductLearner`/`LifeCore` (`expire`, `feedbackExpired`, `decisionExpired`, late ratings report expired). 5 new tests; native 164/164 PASS; traces/`life_timeline`/ESP32 build unchanged. Production BLE and the board-trial firmware have no window yet (S18). Uncommitted.
- S22 decision session: owner approved D4 (UCB exploration labelled in "Why?"), D6 off, "mình – bạn", Vietnamese first, follow-up for a missing context, the Layer A phrase table; D16 deferred. Recorded in AGENTS.md §3, plan §11/§18, decision index, [S22 packet](docs/roadmap/sessions/S22-decision-packet-2026-10-15.md). Documentation only. Next eligible without the board: S39 in `mobile/`.
- Commit checkpoint (2026-10-15, owner request): firmware `5d872d3` (board-trial Serial log) and `8b1aa62` (`feat(firmware): add LifeSnapshot v2, product learner, day parts and feedback window`: S12a/S12b, S18 preparation, S10 host part, D3); the parent commit records the gitlink and all docs (S12, S18-prep, S10-host records, D3 and S22 decisions). Not pushed. The board-trial upload target stays `5d872d3`'s production path (the new core is not linked into `main.cpp`; `8b1aa62` builds the same production image, but later S24a work grows the shared learner cells: RAM +648 B).
- S39 (mobile, pure Dart): Layer A LocalRuleExtractor `ExtractCandidateUseCase` + `CandidateEvent`/`ExtractionResult`/`PreferenceContext`/`DayPart` from the S22 phrase table; V1 parser untouched; not wired into the UI. Flutter 3.32.8 (called from `~/fvm/versions/3.32.8/bin`; `fvm` itself is not on PATH): lock unchanged, analyze clean, 39/39 PASS. Evidence: [S39 record](docs/roadmap/sessions/S39-layer-a-extractor-2026-10-15.md). Mobile changes uncommitted.
- S24a (device core, host only): opcode 6 parse behind a flag, `user_stated` evidence in learner v3 (w_s 0.5, cap 2, decays with γ, latest statement wins [P]), `LifeCore` `StatedPreference` with validation/dedup/commit-first/ERROR_SAFE refusal, explanation `Told` + stated mass, snapshot section 12. Native 179/179 PASS; traces/timeline unchanged; ESP32 RAM 48,976 B (+648) because the board-trial learner shares the grown cells (behaviour unchanged). Evidence: [S24a record](docs/roadmap/sessions/S24a-stated-preference-2026-10-15.md). Firmware and mobile (S39) changes uncommitted.
- Commit checkpoint (2026-10-15, owner request): firmware `9e51df9` (`feat(firmware): add stated preferences (opcode 6) to the learner core`), mobile `dd8430c` (`feat(conversation): add Layer A rule extractor and candidate events`); the parent commit records both gitlinks and the S22/S39/S24a docs. Not pushed. Board-trial upload target stays `5d872d3`.

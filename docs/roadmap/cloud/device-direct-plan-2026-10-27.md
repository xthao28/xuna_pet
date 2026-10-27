# Device-direct cloud connection — plan (2026-10-27)

Status: **decisions approved by the owner 2026-10-27; E14 thresholds confirmed as proposed the same day.** DC-0 written and DC-1 tools implemented 2026-10-27 (host-checked; E14 not run, no board available). The owner then asked to continue with the next sessions without waiting (2026-10-27): DC-2 onward are built and host-tested ahead of the gate, but nothing goes onto the board as a feature before E14 passes. If E14 fails, that work waits for the mitigation decision.

Goal: the board connects to the XUNA backend by itself over Wi-Fi, with no phone in the loop, while its life stays offline-complete. This is Stage 2 of plan §22.3 and Cloud plan Phase 4, with the transport changed from MQTT to WebSocket (decision DC-D2).

## 1. Owner decisions (2026-10-27)

| ID | Question | Decision |
| --- | --- | --- |
| DC-D1 | First slice | **Connection foundation**: Wi-Fi, authenticated connection, online status, automatic projection backup. No voice, no downlink commands or suggestions yet. |
| DC-D2 | Protocol | **WebSocket over TLS to the existing backend** (one TLS session, no broker). Amends plan §22.3 and Cloud plan Phase 4, which named MQTT/TLS. |
| DC-D3 | Wi-Fi setup | **The app writes the credentials over BLE**; the board keeps them in NVS. The app is needed only for setup. |
| DC-D4 | Voice on the board | **Separate plan later** (starts with VOICE-01). D18 stays deferred. |
| DC-D5 | Device authentication | **Challenge signed with the existing ECDSA P-256 device key** (Identity V2) on every connection; the pet must be bound to an account. Unbinding revokes. |
| DC-D6 | Consent | **The bound owner's existing consents** (U1/U2) apply, checked server-side as for the app. Setting up Wi-Fi is the opt-in; the app can forget it. |
| DC-D7 | E14 | **Run E14 first, with thresholds**, before any feature session. |
| DC-D8 | Test environment | **Backend on the dev machine in the LAN, TLS with a self-made CA pinned in the firmware.** Public hosting (D19) stays open. |

Out of scope for this plan: voice on the board, MQTT, downlink commands (O5 remote presence) and suggestions (O1) to the board, public hosting, OTA updates.

## 2. Rules every session keeps

- **Offline-first (H1):** Wi-Fi, TLS and the server run in their own FreeRTOS task. The life loop never waits on the network; a dead router or server changes nothing in XUNA's life, learning or display beyond a status line.
- **Device authority (H2, backend AGENTS §1.4):** this plan sends data up only. Nothing from the server changes device state.
- **Privacy (D23):** only what the app path already uploads, under the same consent classes. No conversation text, no audio. The Wi-Fi password is never logged, never readable over BLE and never sent to the cloud. Logs on both sides stay content-free.
- **Identity:** `PetId` alone is never authority. Every connection is proved by the device key; nonces are single-use and short-lived.
- **Storage:** network settings live in their own NVS namespace, apart from the life snapshot, and are written only when the owner changes them.
- **Protocol discipline:** additive BLE characteristics behind new capability bits; versioned WebSocket messages with strict schemas.

## 3. Shape

```text
          setup only                         every boot, by itself
 App ──BLE 7a6e0011──▶ Board (NVS xuna_net) ──Wi-Fi──WSS (pinned CA)──▶ Backend /v1/devices/connect
 App ◀─BLE 7a6e0012── Board (net status)                                 │ identity: bound device key
                                                                          │ consent: owner U1/U2
                                                                          ▼ memory: projections (PetId, generation)
```

WebSocket session (JSON text frames, `schemaVersion: 1`):

```text
device → hello      {petId, firmware, capabilities}
server → challenge  {nonce (32 B, base64), expiresIn}
device → proof      {generation, publicKey?, signature}      purpose 3 = Session
server → ready      {serverTime, heartbeatS}                 or close 1008 + code
device ⇄ ping/pong  every heartbeatS (default 30 s)
device → projection {generation, envelope}                   xuna.export.v1, idempotent on (PetId, generation)
server → ack        {type, generation, result}
```

Firmware facts checked 2026-10-27 in the pinned framework (`espressif32@6.5.0`): `esp_websocket_client`, `mqtt`, `mbedtls` and `wifi_provisioning` are bundled (no new library); mbedTLS allocates in **internal RAM** (`CONFIG_MBEDTLS_INTERNAL_MEM_ALLOC`); certificate dates are **not** checked (`MBEDTLS_HAVE_TIME_DATE` off), so TLS does not depend on the board clock; Wi-Fi/BLE software coexistence is on.

## 4. Sessions

### DC-0 — Contract and decision records (docs only) — written 2026-10-27

Done: [ADR-0010](../../decisions/ADR-0010-device-direct-websocket-transport.md), contract draft §2 "Device connection" and §4 purpose 3, threat model F10–F11 / T15–T19. Waiting for the owner to read the contract.


- ADR-0010 "Device-direct transport over WebSocket" (supersedes the MQTT wording of §22.3 / Cloud Phase 4 for Stage 2; MQTT stays an option for later fleet needs).
- Contract draft: the messages above, close codes (`unauthorized`, `not_bound`, `consent_required`, `rate_limited`, `unsupported_protocol`), size limits.
- Threat model additions: rogue access point / MITM (pinned CA), stolen board (unbind revokes; the key cannot be read out over BLE), replayed proof (single-use nonce, 60 s), Wi-Fi password exposure (write-only characteristic, NVS only), reconnect storms against the server (backoff + per-pet rate limit).
- No code. Acceptance: owner reads the contract.

### DC-1 — E14: Wi-Fi + TLS + BLE coexistence on the board (gate) — tools implemented 2026-10-27, not run

Run it with the [E14 runbook](E14-runbook.md). Firmware envs `xuna_e14_baseline` / `xuna_e14`, `tools/e14_report.py`; backend `scripts/make_dev_ca.py`, `scripts/e14_server.py`. Deviation: the firmware uses `esp_transport_ws` from its own core-0 task instead of `esp_websocket_client` (whose IDF 4.4 task is unpinned, see ADR-0010).


- Firmware build flag `XUNA_E14` (off by default): the normal firmware plus a network task that joins Wi-Fi (credentials from a local, uncommitted build flag), opens WSS with the pinned dev CA to a small test endpoint, sends a 1 KB message every 5 s and echoes back.
- Backend: `scripts/e14_server.py` (WSS echo with the dev certificate) and `scripts/make_dev_ca.py` (dev CA + server certificate for the machine's LAN name/IP; private keys stay out of git).
- Measured on the board, first without the flag (baseline) then with it, 60 min each, with the app connected over BLE sending a command every 30 s:
  - free internal heap and its minimum, largest free internal block, free PSRAM;
  - loop gap p50/p99/max, render mean/max, BLE command round-trip and failures;
  - TLS handshake time, reconnect behaviour under a server kill every 2 min and a router power-cycle;
  - resets/brownouts, and the board temperature by touch (no sensor).
- Thresholds (owner-confirmed 2026-10-27): minimum free **internal** heap ≥ 40 KB at all times; loop gap p99 ≤ 50 ms (§17.1); render max ≤ baseline + 20 %; zero BLE command failures; zero resets; every reconnect succeeds within 2 min after the server returns.
- Output: `docs/roadmap/cloud/E14-results-<date>.md`. **Fail** → Stage 2 stays phone-gateway only, or a mitigation session (smaller TLS buffers, Wi-Fi only while idle) is proposed. **Pass** → DC-2.
- Needs: owner flashes the board (verified NVS backup first), dev machine running the server, Windows firewall rule for the port.

### DC-2 — Wi-Fi setup over BLE

- Firmware:
  - Characteristic `7a6e0011` (write): `[version 1, op, …]`; op 1 = set (SSID ≤ 32 B, password ≤ 64 B, server host ≤ 64 B, port u16), op 2 = forget. Chunked like the subtitle frames if longer than the MTU. Validated in a pure `NetConfigCodec` (host tests).
  - Characteristic `7a6e0012` (read/notify): network projection `[version, wifiState, cloudState, rssi, lastError, lastBackupGeneration]`; no SSID or password.
  - Capability byte 3 bit 6. NVS namespace `xuna_net`, written only on set/forget; forget erases it.
  - Status card gets one line: "WiFi: …, Cloud: …" (font regenerated if new words).
- Mobile: Device tab "Kết nối WiFi cho XUNA" sheet: SSID (typed; scanning needs location permission on Android and is impossible on iOS), password, server prefilled from the app's `XUNA_API_BASE_URL`; status chip from `7a6e0012`; "Quên WiFi" with confirmation. Codec, data source, repository, use cases, controller and widget tests; locales vi/en.
- Acceptance (host): codec round trips and malformed frames; firmware never echoes the password; mobile tests. Board: join a real network and show the state in the app.

### DC-3 — Backend device gateway

- Module `transport` (existing, MQTT-shaped) gets a WebSocket route `GET /v1/devices/connect` and use cases `open_device_session`, `close_device_session`.
- `identity`: `ProofPurpose.SESSION = 3`; challenge store reused (single-use, 60 s); the proof is verified against the public key stored at bind time; an unbound or revoked pet closes with `not_bound`.
- Online status in `device_transport_statuses` (connected at, last seen, firmware); `GET /v1/devices/{deviceId}/transport/status` already exists. Audit events `DEVICE_CONNECTED` / `DEVICE_REJECTED` with codes only.
- Per-pet rate limit on challenges; message size limit; idle timeout at 3 × heartbeat.
- Tests (PostgreSQL): handshake OK, wrong key, replayed nonce, expired nonce, unbound pet, consent off, oversize frame, heartbeat timeout, two connections for one pet (the newer wins).

### DC-4 — Firmware cloud session

- Pure core `xuna/net/CloudSession.h` (host-tested): states Off → WifiJoining → Connecting → Hello → Proving → Ready → Backoff; exponential backoff with jitter (2 s → 5 min); message encode/decode for the few fixed JSON frames; never touches life state.
- `DeviceProof.h`: purpose 3 Session, same message layout as bind.
- Platform `NetManager` (FreeRTOS task on core 0): Wi-Fi events, `esp_websocket_client` with the pinned CA compiled in, queues to and from the main loop; signing with `DeviceKey` on the network task (sign time is already logged by the bind flow).
- Acceptance: host tests for every transition and malformed server frames; board: connects at boot, survives router and server restarts, shows Ready in the app; DC-1 metrics re-checked with the real task.

### DC-5 — Automatic projection backup

- Firmware builds the `xuna.export.v1` envelope itself (C++ writer), checked byte-for-byte against the Dart-produced golden fixture `backend/tests/fixtures/xuna_export_v1_golden.json` (producing side stays Dart; the fixture is regenerated from Dart if the format changes).
- Sent on connect and after a checkpoint that raised the generation, at most once per 15 min; the server stores it through the existing projection use case (consent U1/U2, ordering by `(PetId, generation)`, duplicates from the app path are no-ops) and answers `ack`.
- `7a6e0012` reports the last acknowledged generation; the app shows "Board tự backup lúc …" from `GET /v1/pets/{petId}/projections/latest`.
- Tests: envelope golden, server ack paths (new, duplicate, older generation, consent off).

### DC-6 — Board acceptance and docs

- Owner check on the board, phone away: boot → Ready; backup appears in the cloud; router off 10 min → XUNA lives normally, reconnects after; unbind in the app → the board is refused within one reconnect; forget Wi-Fi → the board stays offline; power cut during a connection → no snapshot damage.
- Update AGENTS (status), PROCESS, CHANGELOG, Cloud plan Phase 4, ARCHITECTURE docs.

## 5. Order and effort

| Session | Repos | Board needed | Size |
| --- | --- | --- | --- |
| DC-0 | root docs | no | S |
| DC-1 E14 | firmware, backend scripts | **yes (gate)** | M |
| DC-2 | firmware, mobile | yes, at the end | M |
| DC-3 | backend | no | M |
| DC-4 | firmware | yes | L |
| DC-5 | firmware, backend, mobile | yes | M |
| DC-6 | all | yes | S |

DC-2 and DC-3 can run in parallel after the gate; DC-4 needs both.

## 6. Risks and open points

- **Internal RAM for TLS** (mbedTLS internal allocation, plus Wi-Fi and BLE stacks): the main E14 question. The bundled libraries fix the record buffers at 16 KB in each direction (`CONFIG_MBEDTLS_SSL_MAX_CONTENT_LEN 16384`, no dynamic buffers), so client configuration cannot shrink them; only a custom SDK build can (checked 2026-10-27). Mitigations if tight: a custom SDK build, Wi-Fi only while idle, keeping the subtitle and card buffers in PSRAM (already so), dropping BLE scan-response data.
- **LAN-only reach (DC-D8):** the board works only on the home network until public hosting is decided (D19). The dev machine's IP can change: the app writes the server host with the Wi-Fi settings, and the certificate must name it (or use a fixed DHCP lease).
- **Radio coexistence:** BLE command latency may grow while Wi-Fi is busy; measured in E14.
- **Power and heat:** Wi-Fi adds roughly 80–120 mA when active (datasheet range, not measured); modem sleep between heartbeats is the default.
- **Clock:** TLS does not need the clock (dates unchecked). The life clock stays phone-synced; using `serverTime` as a trusted time source would be a separate decision (S10 rules).
- **Two uploaders** (app and board): safe because projections are idempotent on `(PetId, generation)`.
- **Credentials at rest:** NVS is not encrypted without flash encryption (production topic, not this plan).

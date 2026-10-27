# ADR-0010 — Device-direct transport over WebSocket

Date: 2026-10-27. **Status: Approved (owner decisions DC-D1…D8, 2026-10-27); not implemented.** Gated by experiment E14 ([plan](../roadmap/cloud/device-direct-plan-2026-10-27.md) DC-1).

## Context

Plan §22.3, D22 and Cloud plan Phase 4 named **MQTT over TLS** for Stage 2, the step where the board talks to the cloud by itself instead of through the phone (BLE → app → HTTPS). The first Stage 2 slice the owner wants is small: the board joins Wi-Fi, proves it is the bound device, reports that it is online and backs up its projection. No voice, no downlink commands, no suggestions.

Facts checked in the pinned framework (`espressif32@6.5.0`, Arduino core 2.0.14 on ESP-IDF 4.4, mbedTLS 2.28.4), 2026-10-27:

- `esp_websocket_client`, `tcp_transport` (`esp_transport_ws`, `esp_transport_ssl`), `mqtt`, `mbedtls` are bundled; no new library is needed either way.
- mbedTLS allocates in internal RAM (`CONFIG_MBEDTLS_INTERNAL_MEM_ALLOC`) with 16 KB record buffers in each direction (`CONFIG_MBEDTLS_SSL_MAX_CONTENT_LEN 16384`, no asymmetric or dynamic buffers). These are compiled into the bundled libraries, so the firmware cannot shrink them by configuration.
- Certificate dates are not checked (`MBEDTLS_HAVE_TIME_DATE` off), so TLS does not need the board clock.
- Wi-Fi/BLE software coexistence is on; the BT controller, Bluedroid, Wi-Fi and lwIP tasks run on core 0; the Arduino loop runs on core 1.

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. MQTT/TLS to a broker** (old wording) | Fleet pattern, retained messages, QoS | A broker to host, secure and pay for; a second protocol next to the existing HTTP/WebSocket backend; topic ACLs per device; nothing in this slice needs pub/sub |
| **B. WebSocket over TLS to the existing FastAPI backend** | One TLS session, same server, same identity, consent and audit code as the app path; the backend already serves a WebSocket (voice) | Server holds one socket per online board; fan-out to many devices later needs its own design |
| C. HTTPS polling | Simplest server | No online status, a TLS handshake per request (CPU, RAM, heat), latency for later downlink |

## Decision

**Option B.** Stage 2's first slice uses one WebSocket over TLS from the board to `GET /v1/devices/connect` on the backend (contract draft §2 "Device connection"). The connection is proved on every connect with the existing ECDSA P-256 device key (Identity V2, new purpose 3 = Session) and accepted only for a pet bound to an owner. The owner's existing consents (U1/U2) apply server-side. Wi-Fi credentials are written by the app over BLE.

This supersedes the MQTT wording of plan §22.3, D22 and Cloud plan Phase 4 for Stage 2. D22's order still holds: phone gateway first, direct transport only after E14. MQTT stays an option for later fleet needs. If it returns, it gets its own ADR.

Rules that come with the decision:

- **Offline-first (H1):** the network runs in its own FreeRTOS task pinned to core 0. The life loop on core 1 never waits on it; queues are non-blocking.
- **Up only (H2):** this slice sends data up. Nothing from the server changes device state.
- **Pinned trust:** the firmware pins one CA (self-made for the LAN test environment, DC-D8). No public CA bundle is trusted in this slice.
- **Firmware transport:** `esp_transport_ws` over `esp_transport_ssl`, driven from that core-0 task. `esp_websocket_client` is not used. In IDF 4.4 it starts its own unpinned task (priority 5), and that task can run on core 1 and hold the life loop during a TLS handshake.

## Consequences

- E14 must show that one TLS session, Wi-Fi and BLE fit in internal RAM next to the life firmware (threshold: ≥ 40 KB internal heap left at all times), and that the loop and BLE stay within budget. The fixed 16 KB + 16 KB mbedTLS buffers are the main risk. If E14 fails, the options are: Wi-Fi only while idle, a custom-built SDK (ESP-IDF or Arduino lib-builder) with smaller or dynamic TLS buffers, or Stage 2 stays phone-gateway only. Each needs its own decision.
- The backend gains a device gateway (DC-3) in the existing `transport` module; the in-memory MQTT broker shape stays test-only until removed or reused.
- Public hosting (D19) stays open. The LAN test setup reaches the board only on the home network.
- Threat model additions T15–T19 ([threat model](../architecture/XUNA_CLOUD_THREAT_MODEL.md) §3).

## Evidence

- Framework inspection 2026-10-27 (above); E14 results will go in `docs/roadmap/cloud/E14-results-<date>.md`.
- Owner acceptance: DC-D1…D8, 2026-10-27 ([plan](../roadmap/cloud/device-direct-plan-2026-10-27.md) §1); E14 thresholds confirmed as proposed the same day.

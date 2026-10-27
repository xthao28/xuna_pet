# XUNA Cloud HTTP contract — draft (CLD-02)

Date: 2026-10-17. **Status: Draft, not frozen.** Freeze happens in the Phase 1 contract session after Cloud gate (c) and owner review. Names follow the Cloud plan §8 baseline. Implemented today (backend, 2026-10-17): `/healthz`, `/readyz`, `GET /v1/me`, `POST /v1/devices/challenges`, `POST /v1/pets`, `GET /v1/pets`, `GET /v1/pets/{petId}` (CLD-11). Their shapes below are what the code does; still not frozen. The mobile app (2026-10-18) calls challenges, pets, consents and conversation turns with these shapes (host tests only, no phone run yet).

## 1. Conventions

- Base path `/v1`. JSON bodies use camelCase to match the app/device export contract. Times are RFC 3339 UTC strings.
- **IDs:** `petId` = 32 lowercase hex (device-issued UUIDv4, Identity V1). `userId`, `brainId`, `deviceId`, request and resource IDs = UUID strings. Never interchangeable.
- **Errors:** RFC 9457 `application/problem+json` with `type`, `title`, `status`, stable `code`, optional `detail` (no user content). Codes in use: `validation_failed`, `unauthorized`, `auth_unavailable`, `idempotency_key_required`, `idempotency_key_reused`, `conflict_retry`, `not_found`, `invalid_public_key` (422), `invalid_signature` (403), `challenge_invalid` (409), `pet_already_bound` (409), `device_key_mismatch` (409), `consent_required` (403), `consent_version_conflict` (409), `database_unavailable`, `internal_error`. Reserved: `conflict_stale_generation`, `provider_unavailable`, `rate_limited`.
- **Idempotency:** every `POST`/`PUT`/`PATCH`/`DELETE` requires `Idempotency-Key: <uuid>`. Same key + same body → same response; same key + different body → `409 idempotency_key_reused`. Keys kept 24 h.
- **Versioning:** mutating bodies carry `"schemaVersion": 1`. Additive fields only within v1; breaking changes → `/v2`.
- **Request ID:** `X-Request-ID` accepted (8–64 alphanumerics/dashes) or generated, always echoed.
- **Auth:** `Authorization: Bearer <owner token>` (managed OIDC/magic link). Device-attested calls additionally carry a device proof (§4). Health probes are unauthenticated.

## 2. Resources (draft)

### Pets and identity (CLD-11)

```http
POST /v1/pets            # bind a device-issued PetId to the owner
{ "schemaVersion": 1, "petId": "d945…ed86", "origin": "migrated_from_v1",
  "snapshotGeneration": 38,
  "deviceProof": { "challengeId": "<uuid>", "publicKey": "<b64 65B>", "signature": "<b64 64B>" } }
→ 201 created | 200 already bound by this owner with this device key
  { "petId", "brainId", "deviceId", "origin", "lastGeneration", "boundAt" }

GET  /v1/pets            → 200 { "items": [ <pet as above> ] }
GET  /v1/pets/{petId}    → 200 | 404
```

### Device credentials (CLD-11)

```http
POST /v1/devices/challenges            { "schemaVersion": 1, "petId": "…" }
→ 201 { "challengeId": "<uuid>", "nonce": "<base64 32B>", "expiresAt": "…" }
```

### Projections (CLD-14; requires gate (c) + device proof)

```http
PUT /v1/pets/{petId}/projections/{snapshotGeneration}
{ "schemaVersion": 1, "export": { …xuna.export.v1 envelope… }, "deviceProof": { … } }
→ 201 created | 200 identical (idempotent) | 409 conflict_stale_generation
```

Server rules: verify envelope hash and strict payload (implemented in `exports` module); `payload.identity.petId` must equal the path; ordering by `ProjectionKey` (wrap-safe); reject if a tombstone covers any item; consent class U1/U2 required.

### Consents (CLD-12)

```http
GET /v1/consents → { "aggregateMetrics", "experienceEvents", "conversationText", "conversationVoice",
                     "version", "updatedAt" | null }
PUT /v1/consents   { "schemaVersion": 1, "aggregateMetrics": false, "experienceEvents": false,
                     "conversationText": false, "conversationVoice"?: false, "expectedVersion": 0 }
→ 200 new state | 409 consent_version_conflict
GET /v1/audit-events?limit=50 → { "items": [ { "eventId", "action", "subject", "metadata", "occurredAt" } ] }
```

`conversationVoice` (U3V, added 2026-10-22, owner D16) is optional in `PUT`: omitted keeps the current value, so apps that predate voice never revoke it. Default all `false`, version 0 (U0). Each change appends a history row and an audit event; protected routes return `403 consent_required` (implemented 2026-10-17, CLD-12).

### Conversations (Phase 1, CLD-13)

```http
POST /v1/conversations/{petId}/turns     Accept: text/event-stream
{ "schemaVersion": 1, "text": "…", "locale": "vi", "speak"?: false,
  "clientTime"?: "2026-10-23T21:05:00+07:00",                       (turn context, 2026-10-23)
  "history"?: [{ "role": "owner"|"xuna", "text": "…" }],            (≤ 12 lines, each ≤ 500 chars)
  "pet"?: { "activeSeconds", "learnedEvents", "current"?, "quietChoice"?, "playChoice"?,
            "personality"?, "mood"? } }
                                                                      (actions: idle|happy|curious)
                                                                      (PE-4b, 2026-10-25: personality = device label
                                                                       balanced|curious|composed|affectionate|independent|
                                                                       playful|quiet|lively|unhurried|sensitive|carefree;
                                                                       mood calm|glad|joyful|low|sad|bored; sent only
                                                                       for a pet with an identity)
  "gestures"?: true }                                                 (2026-10-27: the connected board advertises
                                                                       Track A previews, so the AI may pick one)
→ SSE events: gesture {name} | delta {text} | toolCall {name, arguments} | finished {provider, model, latencyMs, spoken?, firstAudioMs?, signals?}
             (PE-4c, 2026-10-25: signals = 0–2 closed tags from the owner's text,
              praise|scold|affection|playful|curious_question|long_chat; never stored;
              the app forwards them to the device as BLE opcode 8)
             (2026-10-27: gesture = at most one, before the text, only when the body asked with
              "gestures": true; name look_around|yawn_stretch|bounce_play|greet_nuzzle; the
              app plays it as a Track A preview, opcode 1 args 4-7, display only)
             | error {code}
             | audio {seq, text, format: "mp3"|"wav", sampleRate, data: base64}   (speak only)
             | speech_unavailable {code: "voice_unavailable"|"provider_unavailable"} (speak only, once)

POST /v1/speech/transcriptions            (phone voice V1, 2026-10-22)
{ "schemaVersion": 1, "audio": base64, "format": "ogg_opus"|"m4a_aac"|"wav", "locale": "vi" }
→ 200 { "text", "latencyMs" }  ("" = nothing heard)
| 403 consent_required (needs conversationVoice) | 422 validation_failed (audio: size ≤ 256 KiB,
  base64, container magic) | 503 voice_unavailable (ASR off) | 503 provider_unavailable
```

Turn context (owner 2026-10-23, "smart like Xiaozhi"): all optional, used for this call only and never stored (same U3 consent as the text). `clientTime` must carry a UTC offset; the prompt then states the time and weekday, otherwise XUNA says it does not know. `history` lines become earlier user/assistant messages. `pet` is the device's own view read over BLE (closed action set, integer counters, no free text) so XUNA can describe its age, current action and learned likes. Unknown fields → 422.

`speak: true` cuts the streamed reply into sentences and sends one `audio` event per sentence, in order, after that sentence's `delta`s. Since 2026-10-23 the text keeps streaming while sentences are synthesised (up to 2 at a time), so `delta`s of later sentences may arrive before earlier `audio`; the first piece may end at a comma once it is ≥ 16 characters; `firstAudioMs` (turn start → first audio ready on the server) is added to `finished` when something was spoken. A TTS failure stops speech for the rest of the turn with one `speech_unavailable`, while text continues. Pronunciation fixes (e.g. "XUNA" → "Xu Na") apply to the audio only. The transcription endpoint stores and logs neither the audio nor the text; the app sends the transcript through its normal text path (teaching still needs confirmation).

Requires `conversationText` consent for this call; text is not stored unless retention is separately enabled. Output is display text; facts only via memory candidates. **Implemented 2026-10-17**: 403 `consent_required` without U3, 404 for another owner's pet, 422 for >500 chars; on provider outage the stream ends with `event: error {"code": "provider_unavailable"}`. Tool calls are not forwarded yet.

### Memory candidates (CLD-14)

```http
POST /v1/memory-candidates               # from app parsing or provider proposal
PATCH /v1/memory-candidates/{id}         # owner confirm/reject
# state: awaiting_owner_confirmation → awaiting_device_commit → confirmed | rejected | expired | deleted
```

`confirmed` only after the app reports the device commit (generation that contains it).

### Device connection (Stage 2, DC-0 2026-10-27; [ADR-0010](../decisions/ADR-0010-device-direct-websocket-transport.md); backend DC-3 implemented 2026-10-27 without `projection`)

The board connects by itself over Wi-Fi. One WebSocket over TLS per board, authenticated by the device key on every connect. In this slice data goes **up only**: the server never sends anything that changes device state (H2).

```http
GET /v1/devices/connect            Upgrade: websocket
Sec-WebSocket-Protocol: xuna.device.v1
(no owner token: the device proves itself inside the session)
```

Frames are UTF-8 JSON text, one message per frame, each with `"type"` and `"schemaVersion": 1`. Strict schemas: an unknown field or type from the device closes the session. Binary frames are refused.

```text
device → hello      { "type": "hello", "schemaVersion": 1, "petId": "<32 hex>",
                      "firmware": "0.2.0-mvp", "capabilities": ["projection.v1"] }
server → challenge  { "type": "challenge", "schemaVersion": 1, "nonce": "<base64 32 B>", "expiresIn": 60 }
device → proof      { "type": "proof", "schemaVersion": 1, "generation": <u32>,
                      "publicKey"?: "<base64 65 B>", "signature": "<base64 64 B r||s>" }
server → ready      { "type": "ready", "schemaVersion": 1, "serverTime": "<RFC 3339 UTC>", "heartbeatS": 30 }
device → ping       { "type": "ping", "schemaVersion": 1, "seq": <u32> }
server → pong       { "type": "pong", "schemaVersion": 1, "seq": <same> }
device → projection { "type": "projection", "schemaVersion": 1, "generation": <u32>,
                      "export": { …xuna.export.v1 envelope… } }                       (DC-5)
server → ack        { "type": "ack", "schemaVersion": 1, "ref": "projection", "generation": <u32>,
                      "result": "stored" | "duplicate" | "stale" | "consent_required" | "invalid" }
```

Handshake rules:

- `hello` within 10 s of the upgrade, `proof` before the challenge expires (60 s). The nonce belongs to the WebSocket session: one per connection, single-use, never stored (an unauthenticated board has no owner to attach a stored challenge to, and a retry storm then costs no database writes). Nothing but `ping` and `projection` is accepted after `ready`, and nothing but `hello` → `proof` before it.
- The proof is the §4 device proof with **purpose 3 (Session)**: `nonce` from `challenge`, `petId` from `hello`, `generation` the device's current snapshot generation, payload = the device's 65-byte public key (same layout as bind). The server verifies against the key pinned at bind time. `publicKey` is optional; when present it must equal the pinned key.
- Accepted only for a pet that is bound and not revoked, whose owner has `aggregateMetrics` (U1) or `experienceEvents` (U2) on. Unbinding the pet revokes the board at its next connect, and closes a live session.
- One session per pet: a newer verified session closes the older one with `replaced`.
- `generation` in `proof` is reported as status only, never trusted as a projection.
- Projections on a Ready session count as device-attested by the session proof (TLS to the pinned server + key proof). They go through the existing projection rules (envelope hash, strict payload, `petId` equal to the session's, `ProjectionKey` ordering, tombstones, U1/U2). `stored`/`duplicate`/`stale` mirror `201`/`200`/`409 conflict_stale_generation`.

Limits: frames ≤ 4 KiB, except `projection` ≤ 16 KiB. Challenges per pet ≤ 10 per 10 min, plus a per-IP connection rate limit. The server closes the session after 3 × `heartbeatS` without a frame from the device. The device sends `ping` every `heartbeatS` (minimum 10 s) and drops the connection after 2 missed `pong`s.

Close codes (WebSocket code + reason string = stable code; no other detail):

| Code | Reason | When | Device reaction |
| --- | --- | --- | --- |
| 1008 | `unauthorized` | bad or missing signature, key mismatch, expired or reused nonce, steps out of order | backoff (2 s → 5 min, jitter) |
| 1008 | `not_bound` | unknown, unbound or revoked pet | retry no sooner than 30 min, or after the app writes network settings, or after reboot |
| 1008 | `consent_required` | owner has neither U1 nor U2 | same as `not_bound` |
| 1008 | `rate_limited` | challenge or connection limit hit | backoff at the 5 min maximum |
| 1002 | `unsupported_protocol` | unknown `schemaVersion`, subprotocol or message type, malformed JSON, binary frame | backoff at maximum; logged as a firmware/server mismatch |
| 1009 | `frame_too_large` | size limit exceeded | backoff |
| 1001 | `idle_timeout` / `going_away` | no frame within 3 × heartbeat / server shutdown | normal backoff from 2 s |
| 4000 | `replaced` | a newer session for this pet was verified | do not reconnect for 5 min (avoids two boards fighting) |

The device ignores any server message type it does not know (additive server changes) and never acts on one. Audit events `DEVICE_CONNECTED` / `DEVICE_REJECTED` carry the close code only. Online status: `GET /v1/devices/{deviceId}/transport/status` → `{ deviceId, petId, status: online|offline, lastSeenAt, firmware?, connectedAt? }` (the peer address is not stored for device-direct sessions). Rate limits and the one-session-per-pet registry are process-local in DC-3 (one API process). Serving it with uvicorn needs a WebSocket library (`websockets` or `wsproto`), which is not installed yet.

### Backups and suggestions

`/v1/backups` (Phase 2, encrypted manifests) and `/v1/suggestions` (Phase 3, signed bounded) are placeholders; no shapes proposed yet.

## 3. Payload: `xuna.export.v1`

Defined in [cloud-gate sprint record](../roadmap/cloud/cloud-gate-sprint-2026-10-17.md) and mirrored by backend `exports.application.schemas.ExportPayloadV1` (strict, unknown fields rejected). Golden fixture shared from mobile Dart output.

## 4. Device proof (approved design; firmware Identity V2 implemented 2026-10-17 — BLE `7a6e000d`, see [record](../roadmap/cloud/identity-v2-2026-10-17.md))

Device holds an **ECDSA P-256** key generated on first boot (private key never leaves NVS). Message bytes:

```text
"xuna.proof.v1" 0x00 | nonce[32] | petId[16 raw] | purpose u8 | generation u32 LE | payloadSha256[32]
purpose: 1 bind, 2 projection, 3 session (device connection, payload = own 65-byte public key; DC-0 2026-10-27, not implemented)
```

`deviceProof = { "challengeId", "publicKey": base64(65-byte uncompressed SEC1), "signature": base64(64-byte r||s over SHA-256(message)) }`. Challenges are single-use and expire after 5 minutes. The first successful bind pins the device key to the pet (TOFU); later proofs must use that key. The board refuses projection proofs until it can hash its own export.

## 5. Open questions for the freeze session

1. Confirm `BrainId` semantics (threat model §4.2).
2. Device proof algorithm and BLE characteristic for the public key.
3. Whether projections upload the whole export or typed deltas (U2 events).
4. SSE vs WebSocket for voice (VOICE-gated).

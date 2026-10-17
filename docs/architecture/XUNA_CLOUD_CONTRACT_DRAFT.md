# XUNA Cloud HTTP contract — draft (CLD-02)

Date: 2026-10-17. **Status: Draft, not frozen.** Freeze happens in the Phase 1 contract session after Cloud gate (c) and owner review. Names follow the Cloud plan §8 baseline. Implemented today (backend, 2026-10-17): `/healthz`, `/readyz`, `GET /v1/me`, `POST /v1/devices/challenges`, `POST /v1/pets`, `GET /v1/pets`, `GET /v1/pets/{petId}` (CLD-11). Their shapes below are what the code does; still not frozen.

## 1. Conventions

- Base path `/v1`. JSON bodies use camelCase to match the app/device export contract. Times are RFC 3339 UTC strings.
- **IDs:** `petId` = 32 lowercase hex (device-issued UUIDv4, Identity V1). `userId`, `brainId`, `deviceId`, request and resource IDs = UUID strings. Never interchangeable.
- **Errors:** RFC 9457 `application/problem+json` with `type`, `title`, `status`, stable `code`, optional `detail` (no user content). Codes in use: `validation_failed`, `unauthorized`, `auth_unavailable`, `idempotency_key_required`, `idempotency_key_reused`, `conflict_retry`, `not_found`, `invalid_public_key` (422), `invalid_signature` (403), `challenge_invalid` (409), `pet_already_bound` (409), `device_key_mismatch` (409), `database_unavailable`, `internal_error`. Reserved: `conflict_stale_generation`, `consent_required`, `provider_unavailable`, `rate_limited`.
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
GET /v1/consents
PUT /v1/consents   { "schemaVersion": 1, "aggregateMetrics": false, "experienceEvents": false, "conversationText": false }
```

Default all `false` (U0).

### Conversations (Phase 1, CLD-13)

```http
POST /v1/conversations/{petId}/turns     Accept: text/event-stream
{ "schemaVersion": 1, "text": "…", "locale": "vi" }
→ SSE events: delta {text} | toolCall {name, arguments} | finished {provider, model, latencyMs}
             | error {code}
```

Requires `conversationText` consent for this call; text is not stored unless retention is separately enabled. Output is display text; facts only via memory candidates.

### Memory candidates (CLD-14)

```http
POST /v1/memory-candidates               # from app parsing or provider proposal
PATCH /v1/memory-candidates/{id}         # owner confirm/reject
# state: awaiting_owner_confirmation → awaiting_device_commit → confirmed | rejected | expired | deleted
```

`confirmed` only after the app reports the device commit (generation that contains it).

### Backups and suggestions

`/v1/backups` (Phase 2, encrypted manifests) and `/v1/suggestions` (Phase 3, signed bounded) are placeholders; no shapes proposed yet.

## 3. Payload: `xuna.export.v1`

Defined in [cloud-gate sprint record](../roadmap/cloud-gate-sprint-2026-10-17.md) and mirrored by backend `exports.application.schemas.ExportPayloadV1` (strict, unknown fields rejected). Golden fixture shared from mobile Dart output.

## 4. Device proof (approved design; firmware Identity V2 implemented 2026-10-17 — BLE `7a6e000d`, see [record](../roadmap/identity-v2-2026-10-17.md))

Device holds an **ECDSA P-256** key generated on first boot (private key never leaves NVS). Message bytes:

```text
"xuna.proof.v1" 0x00 | nonce[32] | petId[16 raw] | purpose u8 | generation u32 LE | payloadSha256[32]
purpose: 1 bind, 2 projection
```

`deviceProof = { "challengeId", "publicKey": base64(65-byte uncompressed SEC1), "signature": base64(64-byte r||s over SHA-256(message)) }`. Challenges are single-use and expire after 5 minutes. The first successful bind pins the device key to the pet (TOFU); later proofs must use that key. The board refuses projection proofs until it can hash its own export.

## 5. Open questions for the freeze session

1. Confirm `BrainId` semantics (threat model §4.2).
2. Device proof algorithm and BLE characteristic for the public key.
3. Whether projections upload the whole export or typed deltas (U2 events).
4. SSE vs WebSocket for voice (VOICE-gated).

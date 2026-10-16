# XUNA Cloud & Brain Implementation Plan

Date: 2026-10-16. **Status: Approved architecture baseline; planning only.**

This plan is the execution baseline for XUNA's optional Cloud Brain. It does
not authorize backend implementation before local M05b / session S38 is
accepted. The physical device remains the authoritative home of the pet.

## 1. Product outcome

Cloud should make XUNA better at conversation, recall, portability and
cross-session assistance without making the pet dependent on a server. The
target is not a vague claim that XUNA is "smarter than Xiaozhi". It is a set of
measurable properties:

- confirmed memories are recalled correctly and are correctable/deletable;
- different experience histories lead to explainably different behavior;
- provider-generated text cannot silently become fact, personality or growth;
- service, provider and network loss do not erase identity or stop core life;
- Vietnamese conversation quality and latency pass a recorded benchmark.

## 2. Non-negotiable authority boundary

| Concern | Authority | Cloud role |
|---|---|---|
| Identity, needs, mood, preferences, growth | Device | Read-only projection and backup |
| Owner ratings and confirmed statements | Device after commit | Transport, indexing and recall assistance |
| Conversation wording | Device/local templates or provider adapter | Optional generation |
| Candidate fact extraction | Device/app validation flow | May propose, never confirm |
| Personality/evolution changes | Device rules | May send bounded suggestions only |
| Safety and physical actions | Device `ActionGate` | Cannot bypass or directly actuate |

Cloud suggestions are typed, signed, bounded, expiring, rate-limited,
replay-protected and revertible. Owner evidence always wins.

## 3. Identity model

Keep four identifiers separate: `UserId` (owner), `PetId` (persistent
lifeform), `BrainId` (versioned memory/learning lineage) and `DeviceId`
(physical board credential). Phase 1 uses one active Brain per Pet and one
authoritative Device at a time. Device replacement must not create a new Pet.

## 4. Approved platform baseline

- Python + FastAPI, PostgreSQL, SQLAlchemy 2.x, Alembic and Pydantic.
- A modular monolith first: identity, consent, conversation, memory projection,
  backup and suggestion modules share one deployable service and database.
- Structured relational data plus JSONB for versioned payloads.
- PostgreSQL full-text search first. Add `pgvector` only if a retrieval
  benchmark proves a measurable benefit.
- AI/ASR/TTS vendors sit behind provider adapters. Selection follows a
  Vietnamese quality, latency, privacy and cost benchmark.
- Managed OIDC or magic-link authentication for owners; do not build a custom
  password system.
- Per-device asymmetric identity, challenge-response and credential
  revocation; never ship a fleet-wide shared secret.
- Phone gateway (BLE -> Flutter -> HTTPS) first. Direct MQTT/TLS remains gated
  by E14, D19 and D22.

## 5. Memory confirmation lifecycle

```text
provider/app candidate
        -> awaiting_owner_confirmation
        -> awaiting_device_commit
        -> confirmed device memory
        -> cloud projection

Any stage may become rejected, expired or deleted.
```

An LLM response is untrusted content. A fact that can affect behavior must be
explicitly confirmed, accepted and durably committed by the device before the
cloud marks its projection confirmed. Retries use idempotency keys. Deletion
propagates by tombstone; stale replicas cannot resurrect deleted memory.

## 6. Privacy and retention baseline (D23)

- U0 (no upload) is the default.
- U1 aggregate learning metrics, U2 typed experience events and U3 per-call
  conversation text are separate opt-ins.
- Raw audio is not stored. Conversation text is not retained by default after
  the provider call. Confirmed facts remain until corrected or deleted.
- Export and deletion are product requirements, not administrative tools.
- Logs must redact content and credentials; production retention limits are
  fixed before launch.
- Region, age, guardian and legal requirements require a launch-specific
  review and are not decided by this architecture plan.

## 7. Delivery phases and gates

### Phase 0 — Architecture baseline (now)

Deliver this plan, ADRs and protocol/data contracts only. Exit when local M05b
is accepted at S38 and the implementation session is separately started.

### Phase 1 — Persistent text conversation projection

Prerequisites: S38 acceptance, consent UI design and threat model. Build owner
auth, Pet/Brain/Device records, HTTPS phone gateway, provider adapter,
candidate-confirmation flow and a minimal confirmed-memory projection.

Acceptance: offline pet behavior is unchanged; U0 sends nothing; duplicate
requests are idempotent; generated facts cannot skip confirmation; provider
outage falls back cleanly; Vietnamese benchmark results are recorded.

### Phase 2 — Backup, restore and portability

Add encrypted, schema-versioned snapshots with integrity hashes, export,
deletion and explicit restore/transfer approval.

Acceptance: restore to a replacement device preserves Pet/Brain identity;
corrupt/incompatible backups fail safely; local export works without an AI
provider; deletion tombstones prevent resurrection.

### Phase 3 — Online learning suggestions

Only after E15 shows benefit. Add per-owner consolidation and, later,
privacy-thresholded population priors. Suggestions use the H3 contract and
never write device state directly.

Acceptance: deterministic replay shows improvement over local defaults;
out-of-range, expired, replayed and unsigned suggestions are rejected; rollback
restores the prior local behavior.

### Phase 4 — Direct device transport

Only after E14 plus D19/D22. Add Wi-Fi + MQTT/TLS for bounded events,
commands, status and suggestions; audio stays outside MQTT.

Acceptance: measured BLE/Wi-Fi/TLS resource budget passes on the actual board;
reconnect and QoS 1 duplicates are safe; revoked credentials stop access;
offline life remains fully functional.

### Phase 5 — Voice services

Only after VOICE-01–04 gates. Add streaming ASR/TTS through adapters while
preserving the same candidate confirmation and device authority rules.

Acceptance: measured end-to-end latency/quality, visible recording state,
explicit permissions, no raw-audio retention and graceful text/local fallback.

### Phase 6 — Commercial readiness

Capacity and cost tests, observability, incident response, disaster recovery,
regional/privacy review and an executable service-exit plan. D24 must be
approved before this phase.

## 8. Initial future data/API surface

Tables: `users`, `pets`, `brains`, `devices`, `device_bindings`, `consents`,
`conversation_turns` (ephemeral by default), `memory_candidates`,
`memory_projections`, `backup_manifests`, `cloud_suggestions`, `audit_events`
and `deletion_tombstones`.

First HTTPS resources: `/v1/pets`, `/v1/devices/challenges`,
`/v1/conversations`, `/v1/memory-candidates`, `/v1/consents`,
`/v1/backups` and `/v1/suggestions`. Every mutating request carries an
idempotency key and schema version. These names are a design baseline, not a
frozen public API; freeze occurs in the Phase 1 contract session.

## 9. Work breakdown

| ID | Work item | Gate / result |
|---|---|---|
| CLD-00 | Architecture, ADR and privacy baseline | This documentation session |
| CLD-01 | Threat model and data-flow inventory | Before backend scaffold |
| CLD-02 | Versioned HTTP/event contracts | After S38 |
| CLD-10 | Modular-monolith scaffold and CI | Phase 1 authorized |
| CLD-11 | Owner auth + Pet/Brain/Device identity | CLD-01/02 |
| CLD-12 | Consent enforcement and audit | U0 verified |
| CLD-13 | Provider adapter + Vietnamese benchmark | Provider selection evidence |
| CLD-14 | Candidate/confirm/device-commit pipeline | No confirmation bypass |
| CLD-20 | Encrypted backup/export/restore/delete | Phase 2 acceptance |
| CLD-30 | E15 consolidation experiment | Benefit required for Phase 3 |
| CLD-31 | Bounded suggestion service | E15 pass |
| CLD-40 | E14 device transport experiment | Board resource evidence |
| CLD-41 | MQTT/TLS production path | D19/D22 + E14 pass |
| CLD-50 | Voice provider path | VOICE-01–04 |
| CLD-60 | Cost, DR, legal and exit readiness | D24 before launch |

## 10. Decisions intentionally deferred

- AI, ASR and TTS provider; MQTT broker and hosting vendor.
- Subscription/free-tier model and cost ceilings (D24).
- Vector retrieval, multi-device simultaneous authority and fleet learning
  thresholds.
- Direct-device voice hardware and transport details.

Each requires evidence or a later explicit decision. No deferred choice may be
silently introduced while implementing an earlier phase.

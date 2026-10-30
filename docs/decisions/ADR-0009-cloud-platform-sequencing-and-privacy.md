# ADR-0009 — Cloud platform, sequencing and privacy baseline

Date: 2026-10-16. **Status: Approved architecture baseline; not implemented.**

## Context

The repository needs a concrete future Cloud path without distracting from the
accepted local MVP or prematurely binding XUNA to a vendor.

## Decision

- Do not implement backend code before the concrete Cloud gate is met
  (owner revision 2026-10-16, replacing "local M05b / S38 acceptance"):
  (a) LifeSnapshot v2 runs on the board, (b) a durable `PetId` exists on the
  device and is readable over BLE, (c) a local export works without a service.
  Phase 0 documentation (threat model, `BrainId` semantics, projection
  ordering key) may proceed before the gate.
- Start with a Python/FastAPI modular monolith, PostgreSQL, SQLAlchemy 2.x,
  Alembic and Pydantic.
- Use relational fields plus JSONB and PostgreSQL full-text search. `pgvector`
  requires a retrieval benchmark.
- Put AI/ASR/TTS behind adapters and choose providers using Vietnamese quality,
  latency, privacy and cost evidence.
- Use managed OIDC or magic-link owner authentication and per-device
  asymmetric credentials with revocation.
- Deliver phone gateway over HTTPS first; direct MQTT/TLS stays gated by E14,
  D19 and D22.
- Consent starts at U0. Raw audio is not stored, conversation text is not
  retained by default, and confirmed facts remain correctable, exportable and
  deletable. Extended by U3V `conversation_voice` (D16, 2026-10-22), U4 `owner_documents` ([ADR-0011](ADR-0011-owner-knowledge-documents.md), 2026-10-29), and U5 `host_screen` / U6 `host_notifications` (R5, **Approved (owner 2026-10-30), not Implemented**; default off, never stored server-side; see [the Cloud plan](../architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md) §6).
- Deliver in phases: text projection, backup/restore, evidence-gated online
  suggestions, evidence-gated direct transport, gated voice, then commercial
  readiness.

## Consequences

This gives implementation a stable default stack and avoids distributed-system
complexity at the start. Provider, broker, hosting and business model remain
open. Legal/region rules and exact retention windows must be decided before
commercial launch. Phase gates and tests are normative in
[the Cloud plan](../architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md).

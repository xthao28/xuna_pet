# ADR-0008 — Cloud Brain authority and identity

Date: 2026-10-16. **Status: Approved.** Owner delegated the Cloud architecture
choice on 2026-10-16 and approved recording the resulting plan and decisions.

## Context

XUNA needs richer conversation, memory assistance and portability while its
core life must survive without the Internet. A cloud model must not become a
second, conflicting pet or silently rewrite experience-derived identity.

## Decision

- The physical device is authoritative for pet identity, durable life state,
  learning evidence, personality, growth and physical actions.
- Cloud is an optional projection, backup and cognitive service. It may return
  bounded suggestions but never write authoritative state directly.
- Keep `UserId`, `PetId`, `BrainId` and `DeviceId` distinct.
- Phase 1 has one active Brain per Pet and one authoritative Device at a time.
- Provider output is untrusted. Behavior-affecting memory becomes confirmed
  only after owner confirmation and durable device commit.
- Owner evidence wins; suggestions are signed, expiring, bounded, rate-limited,
  replay-protected, journaled and revertible.

## Consequences

The confirmation path has more steps and temporary states, but it prevents
provider hallucination and sync races from becoming XUNA's life history.
Migration can preserve the Pet and Brain across board replacement. Cloud
failure reduces optional capabilities without erasing or stopping the pet.

Implementation and validation remain separate. Detailed phases and acceptance
gates are in [the Cloud plan](../architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md).

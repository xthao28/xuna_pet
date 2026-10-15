# ADR-0007 — Hybrid offline + online learning

Date: 2026-10-15. **Status: Proposed.** The owner asked on 2026-10-15 to
combine the existing offline learning with an online layer (cloud, MQTT). That
product direction is recorded as owner-requested in AGENTS.md §3. Transport,
provider, data scope, consent defaults and business model remain open
(D21–D24 in [implementation plan §18](../architecture/XUNA_IMPLEMENTATION_PLAN.md)).

## Context

- XUNA's learning is local-first: core life and learning must never require
  cloud (AGENTS.md §1, §5).
- Competitors gain conversation quality and long-term growth from cloud
  services (Loona, Emo, aibo). See the
  [competitive upgrade plan](../architecture/XUNA_LEARNING_COMPETITIVE_UPGRADE.md).
- Cloud-dependent companions have died with their servers. Moxie stopped
  working when Embodied's cloud ended on 2025-01-30, with no offline mode
  ([PopSci](https://www.popsci.com/technology/moxie-robot-offline/)). Vector
  needed the community wire-pod server after official servers ended
  ([iFixit](https://jp.ifixit.com/Device/Anki_Vector)).
- The device-first direction already allows optional cloud cognitive services
  without authority over device state ([ADR-0006](ADR-0006-device-first-conversation.md)).

## Options

1. **Offline only.** Simplest and most private; no conversation or fleet
   learning comparable to competitors.
2. **Cloud-first.** Richest features; XUNA dies or degrades badly when the
   network or the company disappears. Conflicts with AGENTS.md.
3. **Hybrid: offline-complete core, optional online layer** that can only
   *suggest* bounded changes. Device stays the authority.

## Proposed decision

Option 3, with the contract in plan §22:

- **Offline-complete.** Everything in learning Phases 1–4 works without a
  network. Online only adds.
- **Device authority.** Cloud never writes device state. It sends typed,
  bounded, expiring suggestions. The device validates, applies, journals and
  can revert them.
- **Owner evidence wins.** A suggestion can change priors and parameters. It
  can never override `user_feedback` or `user_stated` evidence and never
  creates a fact.
- **Opt-in data classes, deletion propagates.** Upload is off by default.
- **Exit plan.** If the service ends, the pet keeps everything it learned and
  works offline. The owner can export locally.
- **Transport in two stages.** Phone gateway first (BLE → app → HTTPS). Device
  MQTT over TLS later, after experiment E14 and D19/D22.

## Consequences

- New backend work becomes a concrete use case (the Python/FastAPI stack stays
  Proposed). Recurring cost (LLM, broker) needs D24.
- Persistence v2 and the experience log should be export-ready (typed codes,
  provenance) now, at no network cost.
- Privacy/legal review is needed before any commercial launch (D23).
- ESP32-S3 RAM budget must absorb Wi-Fi + TLS + BLE in stage 2 (E14).

## Evidence required before acceptance

E14 (MQTT/TLS/Wi-Fi + BLE coexistence on the board) and E15 (cloud
consolidation benefit in Life Lab). Owner acceptance: **pending**.

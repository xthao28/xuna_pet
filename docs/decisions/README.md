# XUNA — Decision Registry

Created 2026-10-12 for the documentation direction update; S02 documentation deliverables now exist; ADR-0001 acceptance remains pending. Status vocabulary follows [AGENTS.md](../../AGENTS.md) §3. The live D-register remains [implementation plan §18](../architecture/XUNA_IMPLEMENTATION_PLAN.md).

| Decision | Status | Date / authority |
|---|---|---|
| D1 M04 before new M05 features | Approved | 2026-10-12, AGENTS §3 |
| D7 device/app hatch; same-boot trusted bornAt; existing pet Newborn | Approved | 2026-10-12, AGENTS §3 |
| D12 C++11 | Approved | 2026-10-12, AGENTS §3 |
| D14 Flutter 3.32.8 pin | Approved; pin Implemented and S00 baseline PASS (uncommitted) | 2026-10-12, AGENTS §3 |
| D17 Foundation alongside M05a, text-first; Layer B after M05b | Approved, new contract not yet Implemented | 2026-10-12, AGENTS §3 |
| Device-first Conversation / Flutter-assisted Experience | Approved product direction only | Owner request 2026-10-12, AGENTS §3; existing local MVP retained |
| [ADR-0006 device-first architecture](ADR-0006-device-first-conversation.md) | Proposed | Pending experiments and explicit acceptance |
| D18 external audio configuration / VOICE-02 authorization | Proposed | After VOICE-01 |
| D19 device voice security/provider/transport and experiment scope | Proposed | Research authorization before VOICE-03; final choice after evidence |
| D20 voice product/MVP scope and persistent teaching confirmation UX | Proposed | After VOICE-03, before VOICE-04 |
| L-D1–L-D5 learning upgrade (curiosity in E10, teachable tricks, drive-reduction learning, sensor research) | Approved (L-D5 research only) | 2026-10-15, AGENTS §3 |
| Hybrid offline + online learning | Approved architecture direction; implementation gated | Owner 2026-10-15/16, AGENTS §3 |
| [ADR-0007 hybrid offline + online learning](ADR-0007-hybrid-offline-online-learning.md) | Approved direction/contract; implementation gated | D21/D22 approved 2026-10-15; E14/E15 gate later phases |
| D21 hybrid contract H1–H8 · D22 transport order (phone gateway → MQTT after E14) | Approved (broker/provider still open) | 2026-10-15, AGENTS §3 |
| D23 consent/retention baseline | Partially Approved; launch legal/region review remains open | 2026-10-16, ADR-0009 |
| D24 online business model | Proposed | Plan §18, §22 |
| [ADR-0008 Cloud Brain authority and identity](ADR-0008-cloud-brain-authority-and-identity.md) | Approved | 2026-10-16, owner-delegated architecture choice |
| [ADR-0009 Cloud platform, sequencing and privacy](ADR-0009-cloud-platform-sequencing-and-privacy.md) | Approved architecture baseline; not Implemented | 2026-10-16 |
| [ADR-0010 device-direct transport over WebSocket](ADR-0010-device-direct-websocket-transport.md) (replaces MQTT for Stage 2's first slice) | Approved; not Implemented; gated by E14 | 2026-10-27, owner DC-D1…D8 |
| [ADR-0011 owner knowledge documents](ADR-0011-owner-knowledge-documents.md) (consent U4, chunk storage & retrieval) | Approved; Implemented (KX-5) | 2026-10-29, owner-delegated KX-5 |
| UDC track and decisions R1–R8, UDC-D1…D11 ([roadmap §3](../roadmap/XUNA_UNIVERSAL_DEVICE_CONTROL_ROADMAP.md#3-owner-decisions-2026-10-30)) | Approved (UDC-0/1 only); not Implemented | 2026-10-30, owner |
| [ADR-0012 host actions and closed board actuation exceptions](ADR-0012-host-actions.md) (amends [backend/AGENTS.md](../../backend/AGENTS.md) §1.4) | Approved (owner 2026-10-30), not Implemented | 2026-10-30, owner R1 / UDC-D6 / UDC-D7 |
| [ADR-0013 host identity (`HostId`) and host sessions](ADR-0013-host-identity-and-sessions.md) | Approved (owner 2026-10-30), not Implemented | 2026-10-30, owner R3 / R4 / UDC-D10 |
| D5 learnable actions (idle, happy, curious) and GPIO0 `button_greeting` context | Approved; day parts per S10 | 2026-10-15, AGENTS §3 |
| D3 feedback window 120 s; direct input invalidates the pending reaction | Approved | 2026-10-15, AGENTS §3 |
| D4 exploration = E10 UCB, labelled in "Why?" · D6 implicit feedback off · Layer A vi-first, "mình – bạn", follow-up for missing context, S22 phrase table | Approved | 2026-10-15, AGENTS §3, [S22 packet](../roadmap/sessions/S22-decision-packet-2026-10-15.md) |
| D16 phone voice (push-to-talk, on-device STT) | Deferred by owner (text first, E13 later) | 2026-10-15 |
| E10-A/B/C: learner v3 + UCB for M05a, γ 0.90 / k 1 / m 1 / bonus 0.15, capped v1 migration | Approved (selection; board use gated) | 2026-10-15, AGENTS §3, [E10 packet](../roadmap/learning/E10-review-packet-2026-10-15.md) |
| Prototype gate simplification: S01 closed with owner-skipped items; D2a NVS A/B snapshot v2; S13 + S18 merged; concrete Cloud gate | Approved; not Implemented | 2026-10-16, AGENTS §3, ADR-0002, ADR-0009 |

[ADR-0001 reference reuse policy](ADR-0001-reference-reuse-policy.md) is drafted (Proposed); owner acceptance remains pending. ADR-0002–0005 identifiers remain reserved by existing sessions. This index does not accept their decisions or promote other open D-decisions.

## ADR template

Title/ID · Date · Status (Proposed / Approved / Implemented / Validated) · Context · Options · Decision (or Proposed decision) · Consequences · Evidence links · Owner acceptance/date. Approval applies only to its stated scope; implementation and validation are separate entries.

[ADR-0002 storage layout](ADR-0002-storage-layout.md): D2a Approved 2026-10-16 (snapshot v2 in NVS A/B `life0/life1`); LittleFS/log medium pending S32.

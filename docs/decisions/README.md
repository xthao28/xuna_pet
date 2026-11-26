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
| [ADR-0014 standing approvals and phone control sessions](ADR-0014-standing-approvals-and-phone-sessions.md) (amends [ADR-0012](ADR-0012-host-actions.md) decision 1) | Approved (owner delegation 2026-11-06); D1 Implemented (host-verified, not run on a device); D2 not Implemented, gated on device prompt count | 2026-11-06, owner UDC-16 D1/D2 |
| [ADR-0015 commit-gated control and trusted scopes](ADR-0015-commit-gated-control-and-trusted-scopes.md) (amends [ADR-0012](ADR-0012-host-actions.md) decision 1 and [ADR-0014](ADR-0014-standing-approvals-and-phone-sessions.md) D2.1/D2.3) | Approved; E1 and E2 Implemented and host-verified, the rest not Implemented | 2026-11-12, owner chose the "Rộng tay" package (UDC-17 Q7) |
| [ADR-0016 spatial device mesh, ephemeral HostTwin and adaptive multi-host routing](ADR-0016-spatial-device-mesh.md) (amends [ADR-0012](ADR-0012-host-actions.md) decision 1 and [ADR-0013](ADR-0013-host-identity-and-sessions.md) §2–§3) | Proposed; Implemented & host-verified across M1–M6 (`backend` `1,419`, `xuna_xtp` `154`, `desktop` `266`, `RunnerTests` `29`, `mobile` `654`, `diff -r` `0`); live multi-device mesh trial & Windows C++ MSVC build pending | 2026-11-21, M1–M6 ([XUNA_SPATIAL_DEVICE_MESH.md](../architecture/XUNA_SPATIAL_DEVICE_MESH.md)) |
| [ADR-0017 event-driven async watch & wake for long-running host control](ADR-0017-async-watch-and-wake.md) (extends [ADR-0012](ADR-0012-host-actions.md), [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md) & [ADR-0016](ADR-0016-spatial-device-mesh.md)) | Proposed; Wave 1 & Wave 2 Implemented & live macOS verified (2026-11-24) | 2026-11-22, AW-M1–AW-M6 / AW2-M1–AW2-M5 ([XUNA_ASYNC_WATCH_AND_WAKE.md](../architecture/XUNA_ASYNC_WATCH_AND_WAKE.md)) |
| [ADR-0018 opt-in local power-user shell (`exec.*`), direct file I/O (`fs.*`) & brain fluency](ADR-0018-power-user-shell-and-direct-fs.md) (amends [ADR-0012](ADR-0012-host-actions.md) & [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md); extends [ADR-0017](ADR-0017-async-watch-and-wake.md)) | Approved for specification & implementation handoff (owner 2026-11-25); Implemented W3-M0–W3-M4 & live macOS/Windows verified | 2026-11-25, W3-M0–W3-M5 ([XUNA_WAVE3_POWER_SHELL_AND_BRAIN_FLUENCY.md](../architecture/XUNA_WAVE3_POWER_SHELL_AND_BRAIN_FLUENCY.md)) |
| [ADR-0019 draft workspace, local file undo journal & effect-bound approval (`xuna.approval.v2`)](ADR-0019-draft-workspace-and-effect-bound-approval.md) (extends [ADR-0013](ADR-0013-host-identity-and-sessions.md), [ADR-0015](ADR-0015-commit-gated-control-and-trusted-scopes.md) & [ADR-0018](ADR-0018-power-user-shell-and-direct-fs.md)) | Approved (owner 2026-11-26: D4/D5/M1/M2/M3=Option A); W4-M0 Windows spikes measured; W4-M1–W4-M4 Implemented & Windows verified (`xuna_xtp` `288/288`, `desktop` `436/436`, `mobile` `746/746`, `backend` `1616` pass, `diff -r` `0`, mutation-tested); W4-M5 live, macOS & real phone pending | 2026-11-26, W4-M0–W4-M5 ([W4-M0 Spike Report](../research/W4-M0-draft-workspace-spikes-2026-11-26.md)) |
| [ADR-0020 pet cryptographic co-signing (`Approve`) & signed E-Stop (`Stop`)](ADR-0020-pet-cryptographic-cosigning-and-signed-estop.md) (extends [ADR-0008](ADR-0008-cloud-brain-authority-and-identity.md), [ADR-0012](ADR-0012-host-actions.md), [ADR-0018](ADR-0018-power-user-shell-and-direct-fs.md) & [ADR-0019](ADR-0019-draft-workspace-and-effect-bound-approval.md)) | Approved (owner-delegated 2026-11-26: D6 = owner opt-in per category, default OFF); software F3-M1–F3-M3 Implemented & host-verified (`firmware` native `427/427`, `mobile` `752/752`, `backend` `1,630/1,630`, cross-repo golden vectors & mutation-tested); physical ESP32 flashing (`HW-BOARD-1`) & live F3-M0/F3-M3 board+phone pending | 2026-11-26, F3-M1–F3-M3 |
| [ADR-0021 declarative capability adapters, verified skills & manifest foundry](ADR-0021-declarative-capability-adapters-and-foundry.md) (extends [ADR-0018](ADR-0018-power-user-shell-and-direct-fs.md) & [ADR-0019](ADR-0019-draft-workspace-and-effect-bound-approval.md)) | Approved (owner-delegated 2026-11-26: D7/D9/D10); Implemented & Windows verified (`desktop` `4a6e8ad`, `backend` `3b2ec9e`, `xuna_xtp` `292/292`, `desktop` `441/441`, `backend` `1,620` pass, `diff -r` `0`, mutation-tested); live headless binary & macOS pending | 2026-11-26, P4.1–P4.4 |
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

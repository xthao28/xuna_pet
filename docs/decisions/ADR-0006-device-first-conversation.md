# ADR-0006 — Device-first Conversation, Flutter-assisted Experience

Date: 2026-10-12. **Status: Proposed.** Owner-requested product direction is Approved; this formal architecture proposal awaits the existing experiment → evidence → ADR → owner decision process. ADR-0001–0005 remain reserved by the implementation plan; none is created or accepted here.

## Context

The owner wants direct conversation with physical XUNA without opening Flutter. The accepted local MVP and D17 remain text-first, with voice deferred. Current hardware audio and cloud feasibility are unvalidated.

## Options

1. Require Flutter for all conversation: smaller initial hardware scope, but conflicts with requested long-term experience.
2. Device-first hybrid conversation: preserves local life and uses optional Wi-Fi cognitive services; requires audio/security/power experiments.
3. Fully local natural language on ESP32: no validated feasibility; not recommended.

## Proposed decision

Choose option 2 as the architecture to evaluate. Device owns Digital Life state; app assists setup, teaching, inspection and optional conversation; service interprets language without authority to mutate state. Shared candidate/confirmation/event validation supports every input source. Deliver accepted text Foundation alongside M05a while VOICE-01–04 remain a separately gated workstream.

No mic/speaker/pins/provider/protocol/framework/voice-MVP decision is accepted here. No change to D1, D7, D12, D14 or D17; D15 remains the later ordering checkpoint and D16 remains phone voice.

## Consequences and evidence required

Ordinary device voice, once validated, needs no open app; connected language can require network. Offline core behavior survives outage. Additional BOM, memory, latency, power and privacy risks need measured evidence before implementation or production selection.

See [architecture and feasibility gates](../architecture/XUNA_DEVICE_VOICE_ARCHITECTURE.md), [session plan §9](../roadmap/XUNA_SESSION_PLAN.md) and [decision register](README.md). Owner acceptance and evidence date: **pending**.

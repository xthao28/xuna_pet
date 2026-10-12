# ADR-0001 — Reference reuse policy (ePet / Xiaozhi)

Date: 2026-10-12. **Status: Proposed — owner acceptance pending.**

## Context

XUNA uses the pinned PlatformIO/Arduino adapter baseline and a proposed hardware-independent C++11 core. ePet and Xiaozhi provide engineering references with different hardware, frameworks and product assumptions. The historical source/license audit is recorded in [implementation plan §19](../architecture/XUNA_IMPLEMENTATION_PLAN.md); it is not a current dependency compatibility guarantee.

## Options

1. Import upstream architecture/code: introduces framework, hardware and product coupling.
2. Re-implement selected engineering principles in scoped XUNA sessions: recommended.
3. Ignore references: avoids coupling but discards useful simulation and reliability lessons.

## Proposed decision

Use option 2. The table below preserves plan §6.3 as proposals, not authorization to implement all techniques. Adopt means adopt the principle; adapt means design an XUNA-specific implementation. No upstream code, characters, assets or gameplay are copied by this ADR.

| ID | Technique | Source | Decision | First slice |
|---|---|---|---|---|
| T1 | Libc-only core, injected time/seed | ePet | **Adopt principle** | M04.1 |
| T2 | Seeded RNG and seed hygiene | ePet | Adapt (PCG32 per boot stream) | M04.2 |
| T3 | Bounded event bus, budgets, hysteresis | ePet | Adapt (typed experience events, ordered sinks, never-drop feedback) | M04.3 |
| T4 | Bounded catch-up and its equivalence test | ePet | Adapt (monotonic only; nothing replayed across power-off) | M04.5 |
| T5 | Headless deterministic simulator | ePet | **Adopt principle**; own Life Lab | M04.6 |
| T6 | Store interface, typed load errors, rate-limited saves | ePet | Adapt (+A/B, migrations, CRC) | M04.4 |
| T7 | Palette sprites, named poses, fallback, generator checks | ePet | Adapt (PNG→4 bpp, layers) | M04.5 / M06 |
| T8 | Chunked transfer with sequence numbers and checksums | ePet | Adapt (binary BLE paging) | M05b |
| T9 | Verify-before-run VM | ePet | **Defer [F]** | — |
| T10 | Board capabilities with null objects | Xiaozhi | Adapt (no singleton) | M04.2 / M07 |
| T11 | Validated state machine with observers | Xiaozhi | Adapt (table-driven activity FSM) | M04.5 |
| T12 | Single-owner loop, marshalled callbacks | Xiaozhi | **Adopt, bounded** | M04.3 |
| T13 | Typed tool registry (MCP concept) | Xiaozhi | Adapt (+ permission tiers enforced at dispatch) | M04.5 / M05b |
| T14 | Audio, VAD, wake-word pipeline | Xiaozhi | Audio research [P/E] via VOICE-01–04; wake-word deferred [F] | Separate voice workstream |
| T15 | Closed expression vocabulary with fallback | Xiaozhi (fw + server) | Adapt (enum, allowlisted hints) | M04.5 / M05c-A |
| T16 | Hello, versioned framing, sequence dedup | Xiaozhi | Adapt (binary LE over GATT) | M05b |
| T17 | Pluggable ASR/LLM/TTS providers | Xiaozhi server | Adapt (Dart interfaces; memory stays on the device) | M05c-A |
| T18 | Keys as API, health-checked OTA, assets partition | Xiaozhi | Key registry: adopt; OTA/assets: **[F]** | M04.4 |
| T19 | Host-compiled protocol tests, change-scoped CI | Xiaozhi | Adopt (no stubs needed) | M04.1 |

## Exclusions

Do not import ePet's hunger/hygiene/poop/death loops, species growth tree or hard-coded 240×240 blitters. Do not import Xiaozhi's IDF 6/C++23/LVGL stack, network stacks, unbounded scheduling queue, string-built JSON, hide-only permissions, eFuse/server activation coupling or LLM summaries as authoritative memory. Device-first voice research evaluates concepts separately; it does not select Xiaozhi's framework or protocols.

## Consequences and reuse checks

- Keep life logic hardware-independent, bounded, deterministic and tested on host; validate adapter behavior on the actual board.
- Preserve approved toolchain, product scope and session gates. Audio, OTA/assets and VM work retain their own Proposed/Future status.
- Before any later code reuse, re-audit exact upstream repository/commit/path, original and transitive licenses, hardware/framework compatibility and maintenance. Preserve required notices and record copied paths/SHAs/license obligations in the affected repository README.
- Historical MIT audit results do not establish that every future dependency or asset is MIT. Do not infer compatibility or XUNA performance from upstream results.
- A framework migration requires its own ADR and owner decision. No dependency installation or code reuse is performed here.

## Acceptance and evidence

Owner acceptance: **pending**. Draft preparation completes the S02 documentation deliverable; it does not mark this policy Approved. Source: [plan §6.3](../architecture/XUNA_IMPLEMENTATION_PLAN.md), [AGENTS.md](../../AGENTS.md) §7/§8, and historical plan §19 audit. No commit or push.

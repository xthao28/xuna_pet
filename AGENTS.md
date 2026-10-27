# XUNA — AI Evolving Pixel Pet

> **Canonical project context and operating instructions for AI coding agents.**
>
> Applies to Codex, Claude Code, Cursor, GitHub Copilot and other coding assistants. Read this file before proposing changes or writing code. If a submodule has its own `AGENTS.md`, follow both; this root document controls product intent and decisions.

**Product vision:** *Every experience shapes who XUNA becomes.*

**Project repository:** https://github.com/xthao28/xuna_pet

**Previous working name:** MOCHI. **Current product name: XUNA.** Use `XUNA`/`Xuna` in product copy and `xuna_*` in technical identifiers. Do not reintroduce MOCHI naming unless migrating historical material.

**Language:** Discuss with the project owner in Vietnamese; retain established English technical terms. Source code identifiers and technical documentation should generally use English.

**Session handoff:** After reading this guide, read [PROCESS.md](PROCESS.md) for current progress, validation evidence and next actions. Follow its links to [PLAN.md](PLAN.md) for tasks and [CHANGELOG.md](CHANGELOG.md) for change history. Inspect actual repository state and update the relevant handoff documents after meaningful work. This guide remains the canonical source for product decisions and operating instructions.

---

## 1. Mission and product boundaries

XUNA is a **persistent AI digital lifeform inhabiting a physical device**, presented as an expressive Pixel Art pet. It is not merely a chatbot displayed on hardware or a traditional virtual pet with experience-point levels.

Its identity, behavior, memory, preferences, skills and appearance should be shaped by interactions and physical-world experiences. The pet starts with limited abilities and gradually becomes more capable through **observable learning**, analogous to selected aspects of childhood development. Do **not** claim human-like consciousness or general intelligence.

Core product pillars:

1. **Experience-driven development:** real events matter more than arbitrary counters.
2. **Persistent individual identity:** every XUNA accumulates a different life history.
3. **Learning and adaptive behavior:** distinguish learning from scripted level progression.
4. **Embodied perception:** input, motion and external sensors influence what XUNA knows.
5. **Evolution with a cause:** visible/behavioral changes are attributable to experiences and recorded in an Evolution Journal.
6. **Local-first life:** core behavior, pet state and progression work without Internet or phone.
7. **Expression and communication:** Pixel Art, animation, eventually voice and conversation as a source of learning.

**Product test:** Does this make XUNA more believable as a learning, growing physical lifeform? If not, challenge the feature's priority.

## 2. Repository topology

Root repository: `xthao28/xuna_pet` (project orchestration, product decisions, shared docs).

**Desired Git submodules (to be created; do not assume they already exist):**

| Path | Proposed GitHub repository | Responsibility |
| --- | --- | --- |
| `firmware/` | `xthao28/xuna_firmware` | C/C++ firmware, display/input, local digital-life runtime, BLE, persistence, sensors |
| `mobile/` | `xthao28/xuna_mobile` | Flutter companion app: pairing, status, conversation UI, Evolution Journal, device settings |
| `backend/` | `xthao28/xuna_backend` | Optional future cloud services: AI provider gateway, ASR/LLM/TTS, account/backup/sync |

Naming rationale: use **firmware** rather than `esp32` so a future MCU/PCB upgrade does not require a repository rename. The path `mobile/` is more descriptive than `FE/` for this hardware-centered product.

**Submodule discipline:** Each submodule is an independent Git repository. Commits happen inside the child repository, followed by a commit of the changed submodule pointer in `xuna_pet`. Never silently modify unrelated repositories, and do not assume a child repository has been created or pushed.

Suggested root structure:

```text
xuna_pet/
├── AGENTS.md                 # This canonical cross-agent guide
├── README.md                 # User-facing project overview (create later)
├── .gitmodules               # Generated when submodules are added
├── docs/
│   ├── decisions/            # Architecture Decision Records (ADRs)
│   ├── product/              # Vision, MVP scope, requirements
│   ├── architecture/         # System boundaries and protocols
│   ├── research/             # Sources, experiments, benchmarks
│   └── roadmap/              # Milestones and validation notes
├── firmware/                 # Git submodule: xuna_firmware
├── mobile/                   # Git submodule: xuna_mobile
└── backend/                  # Git submodule: xuna_backend
```

Create folders/documents when genuinely needed; do not manufacture a large empty skeleton.

## 3. Decision registry — important

Status vocabulary:

- **Idea:** brainstormed, not committed.
- **Proposed:** recommended, requires approval.
- **Approved:** expressly confirmed by owner.
- **Implemented:** present in code, not necessarily validated.
- **Validated:** measured/tested against agreed acceptance criteria.

### Approved / owner-confirmed direction

- **Name:** XUNA (renamed from MOCHI).
- **Device-first Conversation, Flutter-assisted Experience (owner-requested 2026-10-12):** the physical device is the primary interaction/conversation experience; Flutter is optional for ordinary direct voice once implemented and validated. Device owns core life; cloud offers optional cognitive services. This is long-term product direction, not approval of audio hardware, providers or a voice MVP. Preserve the accepted local MVP and D17 text-first scope; evaluate [device voice architecture](docs/architecture/XUNA_DEVICE_VOICE_ARCHITECTURE.md) through separately gated VOICE-01–04.
- **Existing prototype board:** LILYGO T-Display-S3, standard LCD variant presumed; verify exact board revision and peripherals before pin mapping.
- **Development environment:** **VS Code + PlatformIO IDE**.
- **Mobile framework:** Flutter/Dart as the companion-app direction.
- **iOS minimum deployment target:** 15.0 for the mobile app, owner-confirmed 2026-10-19 after checking the installed Xcode SDK and Firebase Auth plugin requirements.
- **Local MVP through M05 (owner-approved 2026-10-11):** device owns MVP state/memory/preference; idle/happy preference learning from explicit feedback in quiet/play contexts; local template-based conversation text V1 without an LLM. Voice, evolution and sensors remain deferred.
- **Delivery strategy:** proceed incrementally with existing hardware, then Flutter/BLE, then Digital Life systems.
- **Conversation belongs alongside Learning:** speech/conversation is a source of learning events; it must not be postponed until all evolution work finishes.
- **Future display exploration:** **HoloCubic-style optical beam-splitter prism** is preferred over the simple flat-sheet Pepper's Ghost approach, but it is **not part of MVP**.
- **Future hardware:** custom PCB and potentially more powerful/dual-processor hardware are deferred, not current development tasks.
- **Implementation-plan decisions (owner-approved 2026-10-12; IDs from [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md) §18):**
  - **D1:** complete the M04 foundation (sessions S03–S21) before new M05 features.
  - **D7:**
    - A pet can hatch **on the device** (no phone needed) or **via the app**.
    - `bornAt` is exact only when trusted time is available in the hatch boot session; otherwise it stays unknown and active lifetime is shown.
    - The existing MVP pet is kept and migrates as Newborn with `bornAt` unknown.
  - **D12:** `xuna_core` stays C++11.
  - **D14:** mobile pins Flutter **3.32.8** via fvm (`mobile/.fvmrc`). Any SDK upgrade is a separate, validated session.
  - **D17:** Conversation is split into two layers.
    - **Layer A** (text-first, developed and accepted with M05a, opcode 6 `StatedPreference`).
    - **Layer B** (personal facts and recall, after M05b).
    - Voice remains deferred pending D16. (D16 approved 2026-10-22 for phone voice V1; see below.)
  - **S25 stated-preference defaults (owner-approved 2026-10-16):** `w_s = 0.5` and cap = 2 explicit-rating equivalents are the S26 starting defaults. They remain subject to board acceptance and later real-owner tuning; explicit ratings must continue to override stated evidence.
- **S10 trusted-time and hatch protocol freeze (owner-approved 2026-10-16):** opcode 5 is a 16-byte TimeSync command carrying phone Unix seconds and timezone offset; reject UTC rollback beyond 5 minutes, treat a sync as trusted for 24 hours, and let the app sync after connect and every 6 hours. Opcode 7 is an 8-byte Hatch command valid only in Egg; same-request retries are deduplicated and a new Hatch after birth returns `invalid_argument`. Device hatch is a 3-second GPIO14 hold in Egg. The app uses an additive read-only 8-byte Lifecycle V1 characteristic, sends TimeSync before Hatch, and requires explicit confirmation before hatching with unknown `bornAt` after sync failure. TimeSync watermark persistence is lazy; identity creation and same-boot `bornAt` backfill are commit-first. Starting day parts are morning 05:00–10:59, afternoon 11:00–16:59, evening 17:00–21:59 and night 22:00–04:59. These are approved contracts, not implementation or board validation.
- **Learning upgrade decisions (owner-approved 2026-10-15; IDs from implementation plan §18 and the [competitive upgrade plan](docs/architecture/XUNA_LEARNING_COMPETITIVE_UPGRADE.md)):**
  - **L-D1:** adopt the competitive learning upgrade plan as an amendment to plan §9–§10. D1 sequencing (M04 first) and existing session gates still apply.
  - **L-D2:** add learning-progress curiosity (plan §9.4 Alternative D) to experiment E10. Selection still follows the E10 rule.
  - **L-D3:** teachable tricks (plan §9.10) become a planned capability, scheduled after M05a acceptance. Thresholds and budgets stay Proposed until Life Lab data.
  - **L-D4:** drive-reduction learning is allowed as `device_observed` evidence, kept separate from owner ratings and never treated as implicit owner feedback (D6 unchanged).
  - **L-D5:** open a sensor **research** track for touch, IMU and microphone (microphone together with D18/VOICE-01). Research only: no purchase, wiring or firmware change without a separate approval.
- **Hybrid offline + online learning (owner-requested 2026-10-15):** keep the offline learning as a complete core and add an optional online layer (cloud services, later device MQTT). The pet must keep living and keep what it learned without network or service. Architecture, authority and the D23 consent/retention baseline are approved; provider, broker, hosting, launch legal details and cost model remain open ([ADR-0007](docs/decisions/ADR-0007-hybrid-offline-online-learning.md), plan §22, D23–D24).
  - **D21 (owner-approved 2026-10-15):** the plan §22.1 contract H1–H8 is a design rule. Offline-complete core; cloud sends only bounded, expiring, revertible suggestions; owner evidence wins; opt-in data classes with U0 by default; exit plan; per-device security.
  - **D22 (owner-approved 2026-10-15):** transport order is phone gateway (BLE → app → HTTPS) first, device MQTT over TLS only after experiment E14. Broker/provider choice remains open until E14 and a cost review.
- **Cloud & Brain architecture baseline (owner-delegated and approved 2026-10-16):** device remains authoritative; cloud is an optional projection, backup and cognitive service. Keep `UserId`, `PetId`, `BrainId` and `DeviceId` separate; Phase 1 has one active Brain per Pet and one authoritative Device. Use a FastAPI/PostgreSQL modular monolith once the concrete Cloud gate below is met (owner revision 2026-10-16; replaces "after M05b/S38 acceptance"), provider adapters, managed owner auth and per-device asymmetric credentials. U0 is the default; raw audio is not stored; conversation text is not retained by default; confirmed facts remain correctable/exportable/deletable. Delivery order is text projection → backup/restore → E15-gated suggestions → E14-gated MQTT/TLS → VOICE-gated services → commercial readiness. Provider, broker, hosting and D24 business model remain open. See [Cloud plan](docs/architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md), [ADR-0008](docs/decisions/ADR-0008-cloud-brain-authority-and-identity.md) and [ADR-0009](docs/decisions/ADR-0009-cloud-platform-sequencing-and-privacy.md).
- **D5 (owner-approved 2026-10-15; plan §18):** XUNA learns to choose among **idle, happy and curious** (existing art). The **GPIO0 press becomes a learnable `button_greeting` context**: XUNA chooses how to answer and the owner rates it in the app within the feedback window. Day parts remain planned with trusted time (S10). A fourth action such as greet needs new art and a new decision.
- **D3 (owner-approved 2026-10-15; plan §18):** the owner has **120 s** after XUNA shows a reaction to rate it; a later rating is rejected as expired and teaches nothing. Direct input (an app command or the GPIO14 idle button) still invalidates the pending reaction.
- **S22 learning and conversation decisions (owner-approved 2026-10-15; [S22 packet](docs/roadmap/sessions/S22-decision-packet-2026-10-15.md)):**
  - **D4:** keep the E10 UCB exploration; the "Why?" view labels exploratory choices; no age dependence until M06.
  - **D6:** implicit feedback is off. Only explicit ratings and confirmed statements teach preferences (L-D4 drive reduction stays separate `device_observed` evidence).
  - **D6 revised (owner-approved 2026-10-19; [reaction learning record](docs/roadmap/learning/reaction-learning-2026-10-19.md)):** the owner's reaction on the device teaches XUNA: a GPIO0 press within 10 s after XUNA acts is a pet (positive), a GPIO14 press a shoo (negative), weight 0.3 of a rating; silence teaches nothing. App ratings are removed from the UI (BLE opcode 3 stays for older apps); confirmed chat statements still teach. D5 greeting learning is on, and the offline idle routine is a learner decision. Routine learning (anticipating when the owner is around) is implemented in firmware 2026-10-20 ([routine learning record](docs/roadmap/learning/routine-learning-2026-10-20.md)); app display pending. Window and weight are Proposed until the board trial.
  - **Layer A voice and scope:** XUNA replies as "mình – bạn"; Vietnamese first (English keeps the V1 words only); a statement without a context gets one follow-up question and nothing is sent until answered; the packet's phrase table is the S39 starting set.
  - **D16:** deferred; Layer A is text-first, E13 later. **Owner-approved 2026-10-22 for phone voice V1** ([voice parity plan](docs/roadmap/voice/voice-parity-plan-2026-10-22.md)): the app records with the phone microphone and sends speech to the backend for ASR (Groq Whisper in V0), under a separate opt-in consent class **U3V `conversation_voice`** (raw audio and transcripts never stored); the transcript goes through the app's normal text path, so teaching still needs explicit confirmation; replies may be spoken by TTS (Edge free voices, Piper local fallback as an optional GPL extra). V1 targets agreed the same day: first free-tier milestone p50 ≤ 3 s per turn, long-term p50 ≤ 1.5 s / p95 ≤ 2.5 s; ASR WER ≤ 5 % clean / ≤ 8 % noisy after number normalisation. Device voice (V2) still goes through VOICE-01–04.
- **E10 learner selection (owner-approved 2026-10-15; [E10 packet](docs/roadmap/learning/E10-review-packet-2026-10-15.md)):**
  - **E10-A:** learner v3 with policy C (UCB) is the M05a learner, replacing the plan default ε-greedy.
  - **E10-B:** starting parameters γ 0.90 (responsive), k 1, m 1, UCB bonus 0.15; to be re-checked by the owner on the board.
  - **E10-C:** v1 → v3 migration keeps the positive:negative ratio and caps mass at 1/(1 − γ) (amends plan §7.5).
  - Selection only: v3 does not drive the board until S12a/D2, S10, S18, E2/E6 and owner board acceptance.
- **Life-feel targets and board trial (owner-approved 2026-10-15; [needs timeline record](docs/roadmap/learning/life-lab-needs-timeline-2026-10-15.md)):** the 11 life-feel targets are the yardstick for needs/mood tuning. The candidate configuration (rest until about 64%, recovery 6144/min, 10% action cost, +4096 stimulation per interaction, self-wake at about 80%, resume interrupted rest) is enabled in the firmware for a board trial; values stay provisional until the owner's board check.
- **Learner v3 board-trial shortcut (owner decision 2026-10-15):** ahead of the planned S12a → S18 order, learner v3 (E10 config, 2 × 5 × 2 shape) decides BLE opcode 2 choices, the quiet routine and the reported preference on the board, through `xuna/learning/BoardLearner.h`. v1 `LifeEngine` stays the durable record in the unchanged 96-byte snapshot (commit-first, §9.5); v3 is rebuilt from it at boot with the capped migration. Known limits until LifeSnapshot v2: recency is lost across reboots; no curious action or GPIO0 greeting context yet. The planned S12a/S18 work still applies for the full product shape.
- **Prototype gate simplification (owner-approved 2026-10-16, after the owner smoke PASS and the owner-skipped 1–2 h trial / power-cut matrix):**
  - **S01 closed — Accepted with owner-skipped items.** Recorded evidence (Android BLE smoke, raw-byte inspector transcript, one power cut, forget/reboot, text confirmation) stands. The ten-cut matrix, diagnostics windows, text pre-confirmation counter and off/deny/timeout checks remain **not validated**; they are not prerequisites for later sessions.
  - **D2a:** LifeSnapshot v2 is stored in the existing NVS partition as A/B keys `life0/life1`; the v1 `slot0/slot1` keys stay untouched as the rollback point for one release. No partition change. The LittleFS question (experience log/memory) moves to S32; S11 runtime (E4/E5 bench, write-storm power cuts) is deferred to it. Power-loss robustness of v2 on this board is therefore **not measured**.
  - **Merged production switch:** S13 + S18 run as one integration (`LifeCore` + `ProductLearner` + LifeSnapshot v2 replace `LifeEngine`/`BoardLearner` on the board); S08b/S09 are not separate sessions. `BleManager` becomes the adapter that maps v1 opcodes to `LifeCoreEvent`s. S08a (replay of the S01 observed transcript) is the byte-compatibility regression gate. Verified NVS backup before upload remains mandatory.
  - **Cloud gate (revises ADR-0009):** backend implementation may start only when (a) LifeSnapshot v2 runs on the board, (b) a durable `PetId` exists on the device and is readable over BLE, and (c) a local export works without a service. No backend code is authorized now; Phase 0 documentation (CLD-01 threat model, `BrainId` semantics, projection ordering key) may proceed. D11a remains open.
  - **Cloud gate sprint (owner-approved 2026-10-17, revises the line above):** backend CLD-01/CLD-02/CLD-10 (threat model, contract draft, FastAPI/PostgreSQL scaffold + CI) may start now in parallel; device-data projection (CLD-14 onward) still requires gate (a)–(c). Gate (c) = app-side versioned JSON export over BLE data. Board validation runs as one combined upload/acceptance session. See [sprint record](docs/roadmap/cloud/cloud-gate-sprint-2026-10-17.md).
  - **Cloud Phase 0 decisions (owner-delegated 2026-10-17, [threat model](docs/architecture/XUNA_CLOUD_THREAT_MODEL.md) §4):** projection ordering key `(PetId, snapshotGeneration)` with u32 serial-number order; ForgetAll keeps `PetId` and starts a new `BrainId`, restore/replacement keeps both and rebinds `DeviceId`; unsigned exports are owner claims, never device-attested; projection uploads need device credentials (ECDSA P-256 device proof, TOFU binding). Backend CLD-11–13 may proceed; CLD-14+ still needs gate (c).
  - **Cloud provider choices (owner 2026-10-17):** owner authentication uses **Firebase Auth** (backend verifies Firebase ID tokens; mobile integration needs the owner's Firebase project). Text AI **temporarily** uses the owner's internal AI reached over OpenVPN through the vendor-neutral `openai_compatible` adapter; a rented provider replaces it later by configuration. D11a remains open for the final provider; the Vietnamese benchmark (`backend/scripts/text_benchmark.py`) is the selection evidence.
  - **Owner decisions 2026-10-23:**
    - **Cloud gate (c) met (owner-reported):** the owner tested on the phone and board: iOS rebuild with mobile `8a42784`, voice turns, QR camera, audio route, microphone with BLE connected, local export with hash check, board scenes/status card/QR. Measurements were not recorded in the repository. CLD-14 onward is no longer blocked by gate (c).
    - **M04 accepted as proposed:** M04 is **Implemented**, and **Validated** for the rows with board evidence ([M04 record](docs/roadmap/milestones/M04-foundation.md)). Open issues 1–2 (real power cut during a commit, render ±20 %) move to M05b and do not block.
    - **D19 / D11a (spending):** stay on free tiers (Groq ASR/LLM, Edge TTS) with the owner's own test data only; no spending ceiling yet. Revisit with phone latency evidence and before any real user. D11a (final provider) stays open.
    - **D18 deferred until V1 is finished:** the INMP441 + MAX98357A the owner has are kept for V2; no wiring or purchase.
    - **Personality direction ([plan](docs/roadmap/personality/personality-plan-2026-10-23.md), [research](docs/research/personality-evolution-assessment-2026-10-23.md)):**
      - P-D1: the device is the only authority on personality; conversation and cloud give evidence and express it. H2/H4 are unchanged, and the LLM never holds personality.
      - P-D2: the model is a per-pet temperament genome driving drives, emotion/mood dynamics and emotions from expectation. Trait labels are derived, not preset. JPAF is not integrated.
      - P-D3: PE-0/PE-1 start now, Life Lab only, ahead of M06.
      - P-D4 (revises D6 for personality only): conversation shapes temperament without confirmation, as weak, capped, multi-session evidence that the owner can see and undo. Preferences keep D6.
      - All parameters stay Proposed.
      - **Gate G1 passed (owner 2026-10-24, option A for G1-a…d; [PE-2 record](docs/roadmap/personality/PE2-board-shadow-2026-10-24.md)):**
        - G1-a: consolidation needs ≥ 4 sessions; coherence stays 0.5.
        - G1-b: plan §5 row 1 becomes "owner influence exceeds the innate temperament within ≤ 3 months and keeps growing".
        - G1-c: PE-2 expresses personality only through pace and emotion (frame period, reaction length, spontaneous frequency), scaled to the real trait range. Drives never override learning. Track A runs in parallel.
        - G1-d: sociability stays mostly innate until PE-4 adds device-observed evidence.
      - **PE-3 (owner-delegated 2026-10-24, [record](docs/roadmap/personality/PE3-persistence-2026-10-24.md)):**
        - O2: snapshot section 5 is optional, so an older firmware skips it. Invalid section-5 content is skipped, never Corrupt.
        - The section is written only once something has been learned and is capped at 482 B.
        - BLE personality projection `7a6e000e` (capability byte 3 bit 1).
      - **Track A (owner-provided sheet 2026-10-24, [record](docs/roadmap/personality/trackA-variants-2026-10-24.md)):** 4 variants (`look_around`, `yawn_stretch`, `bounce_play`, `greet_nuzzle`). They are expression only (option A): drives, arrival and rest transitions choose *how* a learner choice looks, never the choice. A fourth learnable action still needs its own D5 decision.
        - **App preview (owner 2026-10-24, "chỉ diễn"):** opcode 1 args 4–7 play a variant on the board, advertised by capability byte 4 bits 4–7. It is shown only and never changes needs, drives, personality, learning or the snapshot ([record](docs/roadmap/personality/trackA-variants-2026-10-24.md) §4).
  - **Adapter behaviour for the switch (owner-confirmed 2026-10-16):** an expired rating (D3) returns result 4 until a dedicated code is frozen; GPIO0 stays a direct Happy request until the protocol/app can carry the greeting context (D5 learning deferred to S26/S27); app decision IDs ≥ 0x80000000 return 4; v1 preference bytes use the coarse cell until S10-sync; needs are not persisted (cold-boot reset).

### Proposed — not yet fixed

- Arduino Framework with PlatformIO **for initial hardware bring-up**; long-term Arduino versus ESP-IDF remains open.
- Start with a small modular C++ design, hardware abstraction, testable core; no full-scale Clean Architecture ceremony.
- A Flutter push-to-talk interaction for early Conversation V1; STT/LLM/TTS integration selected by later research and evaluation.
- Exact cloud provider, broker, hosting, launch-region rules, retention windows and business model remain open; do not infer them from the approved architecture baseline.
- Local event-driven Life Engine + FSM/Utility AI, adaptive preference learning and trait-based evolution.

### Future backlog — do not implement now

- HoloCubic/Crystal display R&D: optical prism, suitable high-contrast display (evaluate LCD versus AMOLED), viewing geometry, mechanical housing, thermal and cost constraints.
- Custom PCB and potentially higher-performance MCU, compute module or dual-processor architecture.
- Direct-device voice implementation remains gated by Proposed VOICE-01–04; continuous listening, wake-word and rich streaming speech remain future options, not MVP requirements.
- Light/Nature/Motion/Social docks, Home Assistant/MQTT integration, inter-pet interactions, more sophisticated ML and cloud features.

**Never promote Proposed or Idea to Approved solely because it appears in this document.** If a new choice conflicts with an Approved decision, explain impact and request a decision.

## 4. Current incremental roadmap

Only work on the requested milestone; do not build later milestones speculatively.

| Milestone | Goal | Minimum verifiable outcome |
| --- | --- | --- |
| **M01 — Hardware Bring-up** | LILYGO LCD, buttons, simple sprite | Flash board, render XUNA/text, basic animation and button response; record performance |
| **M02 — Flutter + BLE** | Device pairing, command/state exchange | App discovers/connects, requests animation, receives status |
| **M03 — Pixel Pet & Animation** | Original character, basic reactions | Idle/happy/sleep/curious animations driven by input/state |
| **M04 — Digital Life Foundation** | Time, state, event schema, behavior, persistence | Pet state survives reboot; deterministic event processing and tests |
| **M05 — Memory + Learning + Conversation V1** | Learn from interaction, feedback and dialogue | Show a measured change in future behavior due to prior feedback; source-independent Conversation Foundation, initially tested with Flutter text/simulation; device voice separately gated |
| **M06 — Growth & Knowledge** | Hatch, then knowledge in owner-chosen domains that deepens with owner-confirmed evidence, Journal. No visual growth stages (owner 2026-10-27, [plan](docs/roadmap/knowledge/knowledge-domains-plan-2026-10-27.md)) | Two histories produce explainable differences in what XUNA knows and how it talks and behaves |
| **M07 — Physical Experience** | External sensors and meaningful environment events | Sensor readings translate to validated events affecting behavior and memory |
| **Later** | Advanced voice, new displays, cloud, new hardware | Only after validation and explicit priority change |

**Immediate development focus:** owner-approved local MVP through M05 (2026-10-11), with physical BLE/device validation next. Keep M01 PCB revision/final validation open. Do not add backend, LLM, voice, evolution or sensors to this local MVP.

## 5. Device / mobile / cloud responsibilities

### Firmware (ESP32-S3 initially)

- LCD rendering and animation, physical inputs, sensors and connectivity adapters.
- Pet state, temporal progression, mood, limited personality/preferences, local behavior selection and persistence.
- Offline-first event handling and simple on-device learning suitable for MCU resources.
- Power interruption handling, bounded memory use, device safety and future OTA considerations.

### Flutter mobile app

- Discovery/pairing, BLE communication and device management.
- Display current state, historical development and Evolution Journal.
- Interaction UI and optional phone text/voice for early Conversation Foundation testing; device voice is the long-term primary pathway after feasibility validation. Flutter supports provisioning, diagnostics and privacy without becoming a required conversation gateway.
- Local storage/configuration and user controls over what is remembered.

### Backend / AI services (optional until justified)

- Protect API credentials, route AI requests, connect STT/LLM/TTS providers.
- Optional memory summarization, account, backups, multi-device sync, remote interactions.
- Never become a required service for XUNA's basic existence, identity, growth or routine behavior.
- Never put paid AI keys/secrets into distributed firmware or mobile source.
- **Backend coding rules (owner-requested 2026-10-17):** [backend/AGENTS.md](backend/AGENTS.md) defines the modular-monolith layering, product invariants, testing and Definition of Done (enforced by `backend/tests/test_architecture.py` and `backend/scripts/check.sh`); [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md) records the design and the xiaozhi-esp32-server comparison. Read both before writing backend code.

**Protocol first:** define stable, versioned events/commands and device capability negotiation before adding multiple integrations. The cloud may suggest dialogue or actions but must not bypass device-side permission and safety checks.

## 6. Digital Life model

Think in terms of **events causing durable state changes and learnable patterns**, not a hard-coded level bar.

```text
Physical world / User / Conversation
                  |
                  v
        Perception + Event extraction
                  |
                  v
       Memory + Learning / Feedback
                  |
                  v
      Preferences + Personality + Skills
                  |
                  v
      Decision / Behavior / Expression
                  |
                  v
         Growth + Evolution Journal
                  |
                  +----> New capabilities / experiences
```

### Distinct concepts

- **Instinct:** pre-programmed initial behavior and constraints.
- **Mood:** short-lived internal state (e.g. sleepy, excited).
- **Personality:** slowly changing tendencies (e.g. curiosity, sociability); not equivalent to mood.
- **Preference:** learned, context-dependent choices (e.g. reaction to a touch at night).
- **Memory:** notable episodes, compact summaries, provenance/confidence and retention policies.
- **Learning:** updates predictions, policies, preferences or decisions using actual feedback.
- **Growth:** chronological age, active lifetime and developmental progress as separate dimensions.
- **Evolution:** observable physical/behavioral traits driven by persistent experiences/learning, explainable by evidence.

Do not call `curiosity += 1` after ten button presses "AI learning". Simple rule-based progression can still be appropriate but must be labeled accurately.

### Baby-to-mature concept

XUNA begins with basic instincts and limited communication, then develops *association → prediction → simple planning/adaptation* if demonstrated by data and learning criteria. Communication can move from expressive animation/short sounds to context-aware conversation, **without claiming the underlying LLM autonomously matures like a human brain**.

### Learning inputs

1. **Physical experience:** time, buttons, light, movement, and later sensors.
2. **Behavior feedback:** repeat interaction, explicit approval/disapproval or other carefully defined signals.
3. **Conversation:** user-given information, preferences, corrections and interaction context.

Conversation is not only a chatbot feature: useful, consented facts become candidate memory or feedback events influencing future behavior. Extracted facts must include source and confidence, allow correction/deletion and avoid fabricating physical events.

### Local time and growth

- Distinguish UTC wall clock (`bornAt`, calendar age) from monotonic uptime (`activeLifetime`) and developmental progress.
- V1 may synchronize wall clock via phone BLE or Wi-Fi/NTP; time can be unknown after power loss until trusted synchronization. Do **not** invent elapsed offline days.
- An RTC with backup power is future hardware evaluation if required.
- Do not penalize owners for downtime or force daily usage to keep the pet alive.

### Memory and evolution

- Use bounded snapshots plus meaningful events (with event IDs/schema versions); do not continuously write every frame to Flash.
- Provide deterministic replay/simulation when possible; test reboot/power interruption, flash wear and corruption recovery.
- Prefer modular visual traits over hundreds of hard-coded evolved characters; Forest/Sky/Mystic/Mecha are exploratory motifs only, not an approved evolution tree.
- Every major evolution should be explainable in the **Evolution Journal**.

## 7. Voice and Xiaozhi research boundaries

**Technical inspirations, not source architecture mandates:**

- Xiaozhi ESP32 firmware: https://github.com/78/xiaozhi-esp32
- Xiaozhi server ecosystem: https://github.com/xinnan-tech/xiaozhi-esp32-server
- ePet: https://github.com/pliashkou/epet
- HoloCubic: https://github.com/peng-zhihui/HoloCubic

Learn from Xiaozhi's audio pipeline, wake-word/VAD, Opus streaming, server/provider integration and voice-device constraints. Learn from ePet's simulator, modular rendering and persistence. Learn from HoloCubic's optics/mechanics in future R&D. **Do not clone these projects, copy their characters/gameplay or assume compatibility with XUNA's PlatformIO build.** Check original licenses, library licenses, hardware requirements and maintenance before reusing code.

For the accepted text-first Foundation, Flutter and simulation provide early inputs. The long-term proposed direct path is device mic → Wi-Fi/local interpretation → validated candidate/confirmation → device Learning/Memory → speaker + pixel expression (see linked voice architecture). No integrated mic/speaker is assumed.

For phone-assisted conversation testing:

```text
Phone mic / text → Flutter → optional ASR/LLM/TTS service
                  → structured candidate events
                  → validated Memory/Learning update
                  → behavior/animation on ESP32 via BLE
```

Do not equate more chat history with model intelligence. Prefer measurable learning (predictions/behavior improve with feedback). AI-generated dialogue cannot directly operate physical outputs: validate commands, authorization and safety constraints.

## 8. C++ firmware engineering guidelines

- **Approved tools:** VS Code + PlatformIO IDE. Verify board variant, exact flash/PSRAM options, pinout, display initialization and library compatibility against LILYGO docs/examples before finalizing `platformio.ini`.
- For bring-up, favor proven vendor examples; then isolate project code. Do not blindly reuse vendor code or pin numbers.
- Keep `main.cpp` minimal. Organize mature code by focused modules (display, input, state, events, storage, connectivity), adding modules only as needed.
- Keep digital-life business logic independent of Arduino types, LCD driver, BLE and GPIO. Prefer pure C++ with explicit time/event inputs and host-runnable tests.
- Use lightweight constructor injection/interfaces only where meaningful. Avoid overengineering and allocation-heavy per-frame logic.
- Explicitly budget RAM/PSRAM, frame buffers, CPU, Flash writes, power and render latency; benchmark on the actual board.
- Check all third-party dependencies and code licenses; do not copy assets from commercial pets.
- Prefer non-blocking frame/event loops and bounded work; add FreeRTOS tasks only when concurrency requires them.

## 9. Flutter engineering guidelines

- Flutter/Dart companion app; modular architecture and clean separation of device transport, domain state and presentation.
- **Owner-confirmed on 2026-10-11:** retain the imported mobile Clean architecture and GetX base for subsequent Flutter development. Preserve reusable base controllers, bindings, navigation, data/domain contracts and shared utilities; remove unrelated demo features and prior product branding only.
- **Mobile coding rules (owner-requested 2026-10-13):** [mobile/AGENTS.md](mobile/AGENTS.md) defines the Clean Architecture layering, GetX conventions, testing and Definition of Done; [mobile/docs/FEATURE_TEMPLATE.md](mobile/docs/FEATURE_TEMPLATE.md) is the feature skeleton. Read both before writing any mobile code.
- Treat BLE as a versioned protocol with reconnect, disconnect, timeouts, idempotent commands and capability checks.
- Keep device authoritative for pet-life state until an explicit synchronization strategy is approved.
- Add unit tests for parsing/protocol/domain logic; integrate widget/integration tests when valuable.
- Phone-based voice UI should have clear mic permissions, explicit user control and privacy defaults.

## 10. Agent execution rules

Before implementing a feature:

**Session communication (owner-requested 2026-10-12):** before starting each session, explain its purpose and overall scope briefly in clear Vietnamese. State what will be built/tested and whether board/app operations are included; avoid implementation detail in the opening update.

1. Read this file and relevant docs/ADRs/source in the actual repository or submodule.
2. Confirm current milestone and existing implementation; **inspect before changing**.
3. State **Fact / Assumption / Proposal / Experiment** separately when a technical claim is uncertain.
4. Surface alternatives and trade-offs when making meaningful architecture/hardware/AI choices.
5. Propose the smallest testable vertical slice; obtain approval before major architectural changes.
6. Make scoped changes; do not simultaneously implement unrelated backlogs.
7. Add/update tests, validate build on available targets and disclose what was not actually run.
8. Update docs/ADR when a decision or behavior meaningfully changes; preserve decision status.
9. Summarize files changed, commands run, test results, remaining risks and next step in Vietnamese.

Avoid: invented hardware benchmarks, unverified BOM/prices, fake AI learning claims, unnecessary cloud dependency, oversized frameworks, exposing secrets, overpromising an autonomous general intelligence, and rewriting roadmap without approval.

## 11. Immediate M01 acceptance criteria

With the existing **LILYGO T-Display-S3**, via **VS Code + PlatformIO**:

- [ ] Identify the exact LCD board revision and documented pin/configuration.
- [ ] Compile, flash and observe a working vendor or minimal display sample.
- [ ] Render XUNA branding or an original static pixel sprite.
- [ ] Play a simple idle animation (e.g. 2–4 frames) without blocking input.
- [ ] Read the integrated buttons and trigger a distinct reaction.
- [ ] Record available RAM, approximate frame performance and build configuration.
- [ ] Note any unresolved hardware/library issues; do not claim completion without verification.

**M01 non-goals:** BLE app pairing, backend, LLM, voice hardware, evolutionary AI, HoloCubic, custom PCB.

---

**Guiding principle:** Build XUNA as a credible, explainable and gradually learning digital lifeform, one validated milestone at a time. *Every experience shapes who XUNA becomes.*

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
- **Existing prototype board:** LILYGO T-Display-S3, standard LCD variant presumed; verify exact board revision and peripherals before pin mapping.
- **Development environment:** **VS Code + PlatformIO IDE**.
- **Mobile framework:** Flutter/Dart as the companion-app direction.
- **Local MVP through M05 (owner-approved 2026-10-11):** device owns MVP state/memory/preference; idle/happy preference learning from explicit feedback in quiet/play contexts; local template-based conversation text V1 without an LLM. Voice, evolution and sensors remain deferred.
- **Delivery strategy:** proceed incrementally with existing hardware, then Flutter/BLE, then Digital Life systems.
- **Conversation belongs alongside Learning:** speech/conversation is a source of learning events; it must not be postponed until all evolution work finishes.
- **Future display exploration:** **HoloCubic-style optical beam-splitter prism** is preferred over the simple flat-sheet Pepper's Ghost approach, but it is **not part of MVP**.
- **Future hardware:** custom PCB and potentially more powerful/dual-processor hardware are deferred, not current development tasks.

### Proposed — not yet fixed

- Arduino Framework with PlatformIO **for initial hardware bring-up**; long-term Arduino versus ESP-IDF remains open.
- Start with a small modular C++ design, hardware abstraction, testable core; no full-scale Clean Architecture ceremony.
- A Flutter push-to-talk interaction for early Conversation V1; STT/LLM/TTS integration selected by later research and evaluation.
- Future cloud/mobile synchronization beyond the approved local MVP remains open; do not infer account/backup/sync policies from device ownership in MVP.
- Local event-driven Life Engine + FSM/Utility AI, adaptive preference learning and trait-based evolution.
- Python/FastAPI as a possible backend stack **when a concrete backend use case justifies it**.

### Future backlog — do not implement now

- HoloCubic/Crystal display R&D: optical prism, suitable high-contrast display (evaluate LCD versus AMOLED), viewing geometry, mechanical housing, thermal and cost constraints.
- Custom PCB and potentially higher-performance MCU, compute module or dual-processor architecture.
- Direct on-device microphone/speaker, wake-word, low-latency streaming voice, rich speech output.
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
| **M05 — Memory + Learning + Conversation V1** | Learn from interaction, feedback and dialogue | Show a measured change in future behavior due to prior feedback; phone-based conversation prototype |
| **M06 — Growth & Evolution** | Experience-linked growth, appearance, Journal | Two histories produce explainable behavior/appearance differences |
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
- Interaction UI; use the phone's microphone/speaker for **early conversation prototypes**, not mandatory on-device audio hardware.
- Local storage/configuration and user controls over what is remembered.

### Backend / AI services (optional until justified)

- Protect API credentials, route AI requests, connect STT/LLM/TTS providers.
- Optional memory summarization, account, backups, multi-device sync, remote interactions.
- Never become a required service for XUNA's basic existence, identity, growth or routine behavior.
- Never put paid AI keys/secrets into distributed firmware or mobile source.

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

For early conversation:

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
- Treat BLE as a versioned protocol with reconnect, disconnect, timeouts, idempotent commands and capability checks.
- Keep device authoritative for pet-life state until an explicit synchronization strategy is approved.
- Add unit tests for parsing/protocol/domain logic; integrate widget/integration tests when valuable.
- Phone-based voice UI should have clear mic permissions, explicit user control and privacy defaults.

## 10. Agent execution rules

Before implementing a feature:

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

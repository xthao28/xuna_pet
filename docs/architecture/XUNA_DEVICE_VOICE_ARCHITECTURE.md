# XUNA — Device-first Conversation Architecture

Date: 2026-10-12. **Status: Proposed architecture / planning only.** The owner requested the long-term direction **Device-first Conversation, Flutter-assisted Experience**. This approves product intent, not hardware, services, protocol, voice implementation or a change to the accepted local MVP.

Authority: [AGENTS.md](../../AGENTS.md). Sequencing: [implementation plan](XUNA_IMPLEMENTATION_PLAN.md) §11/§18 and [session plan](../roadmap/XUNA_SESSION_PLAN.md) §9. Decision record: [ADR-0006](../decisions/ADR-0006-device-first-conversation.md). Existing D1/D7/D12/D14/D17 remain Approved; D15/D16 remain open.

## 1. Audit and boundaries

**Fact — repository evidence:** root and all three initialized submodules were clean before this update. Firmware `be58099`, mobile `3846880`, backend `0032828` match the current plan inventory. Firmware `LifeEngine.h` accepts feedback sources 1–2; the mobile codec supports opcodes 1–4. There is no implemented device audio pipeline, opcode 6 or multi-source voice contract. Local MVP physical BLE/learning/reboot/forget acceptance remains pending. Historical build and LCD/button evidence remains valid within its recorded scope.

**Fact — documented hardware:** the project pins Arduino-ESP32 2.0.14, TFT_eSPI 2.5.43 and standard LCD Setup206; buttons use GPIO0/14, power GPIO15, backlight GPIO38. PROCESS §5 records LCD data GPIO39–42/45–48 and controls GPIO5–9. PCB revision remains unknown. The [LILYGO board repository](https://github.com/Xinyuan-LilyGO/T-Display-S3) provides schematics/pin maps; they must be matched to the owner's revision before wiring. No integrated microphone or speaker is assumed.

**Fact — silicon capability, not board validation:** [ESP-IDF v4.4 I2S documentation](https://docs.espressif.com/projects/esp-idf/en/v4.4/esp32s3/api-reference/peripherals/i2s.html) documents two I2S peripherals on ESP32-S3. This does not establish free GPIOs, power headroom or compatibility with XUNA's LCD and current Arduino adapters. Review [ESP32-S3 datasheet](https://documentation.espressif.com/esp32_s3_datasheet_en.pdf) for memory/strapping restrictions.

**Assumption:** an external audio configuration may fit the existing board and enclosure. Available pins, DMA buffers, memory, CPU, power and Vietnamese speech quality are unverified. General-purpose LLM inference and unrestricted STT are outside ESP32 scope.

**Proposal:** start feasibility with half-duplex push-to-talk; compare I2S digital mic + I2S amplifier/speaker against an external audio codec. Separate capture and playback first; streaming, compression, VAD, wake-word, echo cancellation and concurrency require evidence. No framework migration, pin assignments, sample rates, buffer sizes or protocol selection are approved here.

**Experiment:** VOICE-01–04 provide the hardware and runtime evidence. No purchase, wiring, account creation or cloud evaluation is authorized by this document.

## 2. Responsibility matrix

| Component | Owns / executes | Extensions subject to gates |
|---|---|---|
| ESP32-S3 physical XUNA | Authoritative life state/lifecycle, needs/mood, learning/preferences, bounded memory, personality/evolution state when implemented, behavior, pixel expression, buttons, local persistence and BLE | External mic/speaker, voice controller, limited local commands, Wi-Fi AI client, audio capture/transport/playback; validates every conversation outcome before changing life state |
| Flutter companion | Pairing/status, projections/cache, feedback/teaching, optional text/voice and development tests | Provisioning/Wi-Fi setup, diagnostics, supported firmware updates, Memory & Privacy, Life Journal, growth/personality/evolution views; no second Life Engine |
| Backend/cloud | Optional cognitive service; never owns pet life | STT/NLU/LLM/TTS, authenticated device gateway, provider-secret protection, rate/cost limits; optional backup/sync remains a separate decision |

After device voice is implemented and validated, ordinary direct conversation needs no open Flutter app. Connected natural conversation can still require Wi-Fi and cloud. Phone-assisted text stays the smallest accepted M05a delivery path.

## 3. Proposed pipeline and execution paths

```text
User speech → device microphone → bounded audio capture → PTT / optional VAD
  → local limited command recognition OR secure Wi-Fi AI service
  → semantic interpretation → untrusted CandidateEvent / CandidatePreference
  → schema + authority + context checks → explicit confirmation when required
  → validated ConversationEvent → device Learning / Memory / Behavior
  → grounded response → audio playback + validated pixel expression
```

**Path A — offline:** physical buttons and mood-driven expression already supply local interaction. Greetings, limited commands and predefined audio are proposed only where local assets/recognition are supported. No STT/LLM/cloud is required for basic behavior. Natural Vietnamese conversation offline is not promised.

**Path B — connected:** device Wi-Fi carries audio to an authorized AI service for Vietnamese conversation, Q&A and interpretation. Recall uses only permitted device-confirmed facts. Flutter is optional. A generated reply is not learning evidence; it cannot invent a physical experience or bypass the life engine.

## 4. Trust, event and failure contracts [Proposed]

- Audio, transcripts, provider output and adapter claims are untrusted. Device validation checks allowlisted type, bounded slots, capability, actor permission, reaction/context referent, confidence policy and confirmation. Persistent teaching requires an explicit review/confirmation on the device or app; provider text cannot confirm itself. Device confirmation UX/owner authentication is an open decision.
- Conceptual inputs carry input channel (`device_voice`, `mobile_text`, `mobile_voice`, `simulation`) separately from evidence provenance (`user_stated`, `user_feedback`, `device_observed`). Include candidate ID, session/turn ID, causation, bounded payload, confidence and expiry. Accepted events receive device-owned IDs. A spoken report stays `user_stated`, never `sensor_observed`. Simulation is restricted to Life Lab/test builds.
- `ConversationInput`, `ConversationOrchestrator`, `VoiceInputAdapter`, `MobileConversationAdapter` and `SimulationConversationAdapter` are conceptual roles. Use functions/records and current core command boundaries before adding class hierarchies. Audio/network types and arbitrary prose stay outside `xuna_core` (C++11).
- Reuse accepted opcode 6 semantics for stated preference; **do not extend deployed v1 source bytes silently**. Current source 3 proposal belongs to D16 phone voice. Device voice uses an internal validated command boundary until a versioned contract, capability negotiation and migration are approved. BLE remains app transport; direct voice uses Wi-Fi to the service.
- Proposed session states: idle → capturing → interpreting → awaiting confirmation → applying → responding → idle, with cancel/error exits. Life tick, input and rendering continue during all states. Use bounded queues/buffers and backpressure; drop overflow with an explicit failure rather than blocking life behavior.
- Capture, upload, interpretation, confirmation and playback each need measured deadlines and limits, frozen after VOICE-03. Timeout ends the turn with a local expression/predefined response where available; it does not fabricate a successful update. Failed persistence returns failure and does not claim learning.
- Cancellation stops capture/network/playback, invalidates pending candidates and ignores late replies using session IDs. If a commit already succeeded, report its outcome; deletion is a separate confirmed operation.
- Reconnect with bounded backoff; no automatic replay of raw audio or expired/unconfirmed candidates. Recover uncertain commits by reading device state/event receipts. Versioned IDs and dedup must prevent duplicate learning; exact dedup horizon/persistence are design-freeze decisions, not assumed from the v1 session cache.
- Cloud outage/auth failure leaves local life and learned behavior operating. Do not repeatedly retry a failing service, retain audio indefinitely or require the phone as fallback.
- Evaluate encrypted transport/certificate verification and device credentials/revocation. Keep long-lived AI provider secrets on the service. BLE bonding D10 does not establish Wi-Fi service authentication. Raw audio/transcript retention defaults off; show recording state and consent, bound grounding disclosure and verify service retention/deletion policy.

## 5. Learning, memory and later evolution

**M05a + Conversation Foundation (existing M05c-A label):** shared structured candidate/confirmation/learning contracts, simulated and Flutter text inputs first. S24a/S26 handle opcode 6; S39/S27a handle extraction and confirmation. Joint S28 verifies candidate → confirm → changed behavior → reboot → phone-disconnected use, and rejection of unconfirmed/injection inputs. Voice hardware is not a dependency.

**M05b:** preserve MemoryStore, Journal, provenance, privacy, tombstones, BLE v2/bonding and recovery. Test voice provenance with synthetic fixtures, without pretending hardware exists.

**M05c (existing M05c-B label):** extend Foundation with TeachFact/SupersedeFact/ForgetFact/ReadFacts and grounded recall. S39 retains its existing Foundation placement; S40–S42 extend it. Validated device voice may reuse the same fact commands and deletion/consent rules; missing voice does not block text acceptance. Rich dialogue interpretation is transient; confirmed facts are bounded and authoritative on the device.

**M05d:** preserve proposals and D15 checkpoint S42a (cognition first versus Evolution MVP first). No reorder is made. **M06/M07:** permitted voice-originated evidence may contribute to traits/Journal; spoken descriptions are distinct from measured sensor events. Evolution/sensors remain outside the accepted local MVP.

## 6. Feasibility and production decision gates

| Dimension | Current classification | Minimum evidence / gate |
|---|---|---|
| GPIO, I2S, framework | Fact: pinned config; Assumption: audio fits | VOICE-01 revision-matched schematic, reserved/strapping/USB/PSRAM pins and electrical review; no selected pins yet |
| Audio BOM and enclosure | Proposal: external mic + amp/speaker or codec | VOICE-01 candidate voltage/current requirements, acoustic placement and availability; timestamped supplier quotes only if verified, otherwise unknown cost |
| RAM/CPU/LCD | Experiment | VOICE-02 heap/min-heap, internal DMA RAM vs PSRAM, stack/CPU, loop/render p50/p95/p99, underruns/overruns versus same-board baseline; record method/duration and agreed thresholds |
| Wi-Fi and BLE coexistence | Experiment | VOICE-03 disconnect, weak signal, reconnect and sustained turns with BLE/LCD/storage active |
| Latency/bandwidth | Experiment | VOICE-03 capture-end → first audio/complete reply, stage latency distribution, bytes/turn, timeout/cancel tests |
| Vietnamese STT/response quality | Experiment | VOICE-03 consented test corpus, accents/noise, intent/fact accuracy and false teaching rate; no offline Vietnamese claim |
| Battery/power/thermal | Assumption; no runtime estimate | VOICE-01 power design; VOICE-02 measured capture/playback peaks/brownouts; later representative battery duty-cycle test |
| Cloud cost | Unknown; provider strategy Proposed | D11a authorization; VOICE-03 dated rate sources plus measured usage/turn, retry and idle costs; spending ceiling before experiments |
| Privacy/security/reliability | Proposed constraints | Credential provisioning/revocation, TLS failure, consent/recording indicator, retention/deletion review, malformed/late output tests and outage fallback |
| Manufacturing complexity | Future decision | Connector/solder/acoustic/enclosure/assembly risks, repeatability on representative units; production hardware decision only after these and VOICE-01–04 results |

Minimum production decision packet: revision-matched pin/power report; real-board simultaneous audio/LCD/life/Wi-Fi stability and memory evidence; Vietnamese latency/accuracy/cost/privacy evidence; persisted learning demo with phone/cloud disconnected afterward; enclosure/acoustic and representative battery measurements. The current board remains the MVP platform until this evidence justifies another choice. No benchmark, price or feasibility success is claimed by this planning update.

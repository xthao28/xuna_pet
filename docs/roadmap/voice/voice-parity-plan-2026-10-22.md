# Voice parity with Xiaozhi + a stable XUNA core (plan, 2026-10-22)

Status: **Proposed** (owner asked for the plan; nothing here is approved until the decisions in §6 are made). Authority: [AGENTS.md](../../../AGENTS.md); voice gates: [device voice architecture](../../architecture/XUNA_DEVICE_VOICE_ARCHITECTURE.md) and session plan VOICE-01–04; cloud phases: [Cloud plan](../../architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md) §7.

## 1. Goal

1. **Match Xiaozhi where it is strongest:** natural, low-latency, spoken conversation with a small device, backed by swappable AI providers and tools.
2. **Make XUNA's own strength dependable:** a pet whose life, learning and memory live on the device, survive power and network loss, are explainable, and are recalled correctly in conversation.

"Match" is measured, not claimed: §2 defines the yardstick and §5 runs both systems on the same test.

## 2. What "at least equal" means

Xiaozhi baseline (from the 2026-10-17 inspection of `xiaozhi-esp32-server`, see [backend architecture](../../../backend/docs/ARCHITECTURE.md)): VAD → ASR → LLM → TTS streaming per connection, device audio over WebSocket/MQTT, many providers per capability, plugin + MCP tools, memory and intent providers. Its actual latency and Vietnamese quality are **not yet measured by us**; §5 does that first.

| Area | Parity target (owner to confirm numbers after §5) |
| --- | --- |
| Latency | End of speech → first audible reply: p50 ≤ 1.5 s, p95 ≤ 2.5 s, and no worse than Xiaozhi on the same corpus and network |
| Vietnamese understanding | ASR word error rate on a consented Vietnamese corpus (quiet + room noise, northern/central/southern speakers) no worse than Xiaozhi with its best Vietnamese-capable provider |
| Turn handling | Push-to-talk first; then VAD end-of-speech, barge-in (owner talks over the reply), cancel, continuous multi-turn |
| Robustness | Network loss mid-turn ends gracefully with a local expression; 100 consecutive turns without a reset; Wi-Fi + BLE + LCD active together |
| Providers | ≥ 2 interchangeable ASR, LLM and TTS adapters each, chosen by configuration, with the CLD-13 benchmark extended to voice |
| Tools | MCP tool adapter in the backend; device actions still only via device-validated suggestions (never direct tools) |
| Wake word | After the above: on-device wake word (ESP-SR WakeNet class) as an option, PTT stays available |

## 3. XUNA strength: what "stable" means

| Area | Stability target |
| --- | --- |
| Life and learning on the board | 7-day soak with BLE + display + scenes, no reset, no heap drift; real power cut during a commit × 20 with no lost acknowledged feedback; temperature measured (the owner reported the board feeling warm) |
| Learning quality | Reaction learning and routine anticipation tried by the owner on the board; Life Lab metrics kept as regression gates (scenarios D/E, stability, routine, reactions) |
| Memory | M05b memory store with confirmed facts: correctable, deletable, exportable (S29–S33) |
| Never lose the pet | Cloud Phase 2: encrypted backup, restore to a new board, delete (CLD-20) |
| Grounded recall in conversation | Spoken and typed replies use only device-confirmed facts; false-memory and sensing-claim rates stay at 0 in the benchmark (the 2026-10-17 text benchmark already gates this) |
| App | Gate (c), bind + AI chat and QR pairing validated on a real phone |

This is where XUNA must be ahead: Xiaozhi's memory is written by a provider; XUNA's is confirmed, device-owned and explainable.

## 4. Phases

Estimates are working sessions of the current kind, not calendar promises; they assume the owner is available for board/phone steps.

### Phase S — Stabilise what exists (start now, ~3–5 sessions, runs alongside V0)

1. Board session: NVS backup, upload `0a392c5`, check scenes/effects/cards, `scene_max_us`, loop gap; thermal reading (and backlight/CPU-clock options if hot).
2. Phone session: QR pairing, gate (c) export hash, bind + AI chat.
3. Owner trial of reactions/routine; real power-cut matrix; 24 h then 7-day soak with logged heap/temperature.
4. Owner review of the [M04 record](../milestones/M04-foundation.md).

### Phase V0 — Baseline and provider choice (1–2 sessions, host only)

XUNA has **no voice pipeline yet** (text chat only; LLM first token ≈ 0.85 s in the 2026-10-17 benchmark), so V0 is not yet a head-to-head. It produces the yardstick and picks the parts XUNA will be built from:

1. A Vietnamese test corpus (owner-recorded with consent, plus room noise; synthetic TTS audio only as a stand-in until then).
2. ~~Xiaozhi baseline run~~ — **owner decision 2026-10-22: do not run Xiaozhi; study what it uses** ([research note](xiaozhi-stack-research-2026-10-22.md)). Test Xiaozhi only if XUNA later runs Xiaozhi code.
3. Provider benchmark for XUNA's own pipeline on the same corpus: ASR word error rate and latency, TTS first-audio latency and naturalness, alongside the measured LLM path. This chooses V1's adapters.
4. Freeze the §2 numbers with the owner.

At the end of V1 (phone) and V2 (device) XUNA is checked against the §2 targets with the same corpus and harness.

Update 2026-10-22: the owner has a microphone and speaker for XUNA (INMP441 + MAX98357A) and chose V0 before Phase S (board tests are slow); Phase S items stay open. Voice is tried through the app first (V1) because wiring the board takes time. Owner asked to keep runs small: this Mac (2014 Intel i7, 16 GB) cannot carry heavy local models.

**V0 interim results (small runs, synthetic corpus, tools in `backend/scripts/voice_bench/`):**

| Stage | Result | Meaning |
| --- | --- | --- |
| ASR, faster-whisper `small` (CPU int8, 4 threads, 10 utterances) | WER 13 % clean and noisy; **7.9 % clean with initial prompt "XUNA"**; decode ≈ 5 s per 3 s of audio (RTF 1.5–1.9) | Accuracy is usable; this Mac is far too slow for real time. The name "XUNA" is misheard without a prompt (e.g. "Equenna") |
| TTS, Edge TTS (6 calls) | First audio 470–630 ms, 0 failures | Fast, but the free service returned 403 / "no audio" repeatedly while building the corpus: needs a fallback provider |
| LLM, Gemini Flash Lite (2026-10-17 text benchmark) | First token ≈ 0.85 s | Already measured |

Rough turn estimate with a fast ASR (≈ 0.5 s) + LLM first sentence + TTS first audio: ≈ 1.9 s before network overhead, above the 1.5 s p50 target, so V1 must stream and overlap stages (start TTS on the first LLM sentence). ASR cannot run on this Mac in V1: it needs a hosted ASR or a server with a GPU. The Xiaozhi baseline is not run (owner decision); its free Vietnamese ASR path would be the same Whisper behind its `openai` provider.

Cloud ASR, free tiers (owner: "try free cloud before a stronger machine"): Gemini audio input is accurate (WER 0 % clean on 8 utterances) but takes 13–21 s per utterance with HTTP 503 / timeouts → not real-time. Groq `whisper-large-v3-turbo` (free, key in `backend/.env.groq`): **WER 5.3 % clean and noisy with Opus upload, median ≈ 1.8 s (single calls 0.42–0.9 s)**; best candidate so far. Still above the ≈ 0.5 s ASR budget: V1 needs a kept-alive connection, Opus from the phone, and a check of Groq free-tier limits/variance (or a streaming ASR).

**Continue here (any machine):** set up `backend/scripts/voice_bench` per its [README](../../../backend/scripts/voice_bench/README.md) (venv, `make_corpus.py`), then: (1) ~~Groq full run~~ done 2026-10-22: WER 2.2 % clean / 3.6 % noisy (digit formatting excluded), latency p50 1.40 s / p95 3.34 s with a kept-alive session, no rate-limit errors at 3.2 s pacing; V1 needs number normalisation (digits ↔ words) before intent parsing, and latency beyond the free tier (streaming ASR or a paid/dedicated endpoint) to reach the budget; (2) on a stronger machine, `asr_bench.py` with `small`, `medium`, `large-v3-turbo` ± `--prompt XUNA` on the full 120-utterance corpus; (3) ~~TTS fallback~~ done 2026-10-22: Piper local `vi_VN-vais1000-medium` (first audio ≈ 130 ms, ASR round-trip WER 4.3 %, offline; GPL-3.0 runtime) — owner to listen for naturalness; (4) ~~freeze §2 numbers~~ agreed 2026-10-22 (free-tier milestone p50 ≤ 3 s; long-term p50 ≤ 1.5 s / p95 ≤ 2.5 s; WER ≤ 5 % clean / ≤ 8 % noisy); (5) ~~start V1~~ started 2026-10-22 with D16 approved: [V1 record](V1-phone-voice-2026-10-22.md) (slice 1 backend done; slice 2 app next).

### Phase V1 — Voice through the phone (fastest real voice, ~4–6 sessions)

The phone already has a microphone, speaker and the backend connection, so this reaches spoken conversation without new hardware.

1. Backend `voice` session: WebSocket endpoint, Opus 16 kHz frames, server VAD, streaming ASR → existing LLM path → streaming TTS; typed events; per-stage timing; U3 + consent guard; no raw audio stored.
2. Provider adapters: ≥ 2 Vietnamese ASR and TTS candidates (global and Vietnamese vendors), chosen by benchmark.
3. App: push-to-talk in chat, playback, cancel/barge-in, XUNA expression over BLE while speaking.
4. Benchmark against V0; tune until the latency/quality targets pass.

### Phase V2 — Voice on the device (Xiaozhi's home ground, ~6–10 sessions + hardware lead time)

1. VOICE-01 hardware decision: add I2S microphone + I2S amplifier/speaker to the T-Display-S3, **or** move to an ESP32-S3 board with an audio codec (the kind Xiaozhi supports). Pin, power and enclosure review.
2. VOICE-02: capture/playback prototype with measured RAM/CPU/render impact.
3. VOICE-03: device Wi-Fi → the V1 voice endpoint (same protocol, device credential from Identity V2), PTT with the GPIO buttons, Opus encode/decode on the ESP32-S3, expressions on the LCD.
4. VAD end-of-speech, barge-in, then optional wake word.
5. Device ↔ cloud transport per Cloud Phase 4 (E14) for non-audio events.

### Phase V3 — Breadth (~4–6 sessions)

MCP tool adapter, vision LLM adapter, more providers, intent routing, provider failover, latency dashboard. Device-affecting tools remain suggestions validated by the device.

### Phase M — Memory and continuity (parallel with V1–V3)

M05b memory (S29–S33), recall in conversation (S40–S42), Cloud Phase 1–2 (projection, backup/restore). VOICE-04 connects spoken statements to the same confirmation flow as text.

## 5. Order and why

S and V0 first: no point racing on voice while the board is unvalidated, and no target is honest until Xiaozhi is measured. V1 before V2: the phone path proves the backend pipeline and providers in weeks and V2 reuses it unchanged; V2 then only adds the device audio front end. M runs alongside because recall quality is where XUNA wins.

## 6. Decisions the owner must make

| ID | Decision | Needed before |
| --- | --- | --- |
| D16 | Approve phone voice (microphone permission, audio sent to the backend) — **approved 2026-10-22** | V1 |
| D19 / D11a | Voice provider research scope, security, **spending ceiling** for ASR/TTS/LLM tests — **2026-10-23: free tiers only, owner test data, no ceiling yet; revisit with phone latency evidence** | V0 provider runs, V1 |
| D18 | Audio hardware path (add-on mic/amp vs codec board), budget, purchase — **2026-10-23: deferred until V1 is finished; owned INMP441 + MAX98357A kept for V2** | V2 |
| — | Whether to reuse Xiaozhi code (MIT, notice kept) for device audio/Opus/protocol instead of ideas only | V2 |
| — | Parity numbers in §2 after V0 | V1 acceptance |

## 7. Risks

- **Hardware:** the current board has no audio; V2 timing depends on parts and wiring.
- **Vietnamese ASR/TTS quality and cost** vary a lot by provider; V0/V1 benchmarks decide, not assumptions.
- **Heat/power:** Wi-Fi audio streaming adds load to a board that already runs warm; measure in Phase S before V2.
- **Scope creep:** parity is the §2 table, not every Xiaozhi feature.

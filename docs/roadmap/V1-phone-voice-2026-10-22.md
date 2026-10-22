# V1 — Phone voice (started 2026-10-22)

Status: **slice 1 (backend) implemented and tested; slices 2–3 open.** Plan: [voice parity plan](voice-parity-plan-2026-10-22.md) Phase V1. Owner approvals 2026-10-22: D16 (phone microphone, speech to the backend), V1 targets (free-tier milestone p50 ≤ 3 s per turn; long-term p50 ≤ 1.5 s / p95 ≤ 2.5 s; ASR WER ≤ 5 % clean / ≤ 8 % noisy after number normalisation).

## Design freeze

```text
App: hold-to-talk → record (Ogg/Opus or AAC) → POST /v1/speech/transcriptions (consent U3V)
     ← { text }  → the app's normal text path (local intents; teaching needs confirmation)
     → unknown text + AI chat on → POST /v1/conversations/{petId}/turns { text, speak: true }
     ← SSE delta… audio{seq,text,format,data}… finished{spoken}
     → play audio events in seq order while showing text
```

- **Why two calls, not one voice turn:** the transcript must pass the same local parser and confirmation as typed text (AGENTS §6.4 mobile, D17), so speech can never teach XUNA without confirmation. The extra request costs ~0.1–0.3 s on a kept-alive connection.
- **Consent U3V `conversation_voice`:** separate from U3 (hearing is not reading). `PUT /v1/consents` without the field keeps it, so old apps never revoke it. Migration `0004`.
- **ASR:** `openai_transcription` adapter (any OpenAI-style `/audio/transcriptions`; Groq `whisper-large-v3-turbo`), language `vi`, prompt `XUNA`, one process-wide kept-alive client. Input containers `ogg_opus`, `m4a_aac`, `wav`, ≤ 256 KiB, magic-checked.
- **TTS:** `edge` (free online voices, LGPL `edge-tts` 7.3.1) or `piper` (local, optional extra `.[piper]`, GPL-3.0, voice VAIS-1000 CC BY 4.0). Reply cut into sentences (no cut inside "3.5"); "XUNA" spoken as "Xu Na"; PCM wrapped as WAV. A TTS failure → one `speech_unavailable`, text continues.
- **Nothing stored:** audio, transcripts and replies are not stored or logged.

## Slice 1 — backend (done 2026-10-22)

- Files: `consent` (U3V + migration 0004), `cognition/infrastructure/{openai_transcription,edge_tts_adapter,piper_adapter}.py`, `conversation/application/voice.py`, `conversation/api/routes.py`, `core/config.py` (`XUNA_ASR_*`, `XUNA_TTS_*`), `main.py`; contract draft, ARCHITECTURE, backend AGENTS rule 7, `.env.example`.
- Checks: `scripts/check.sh` with PostgreSQL: **125 passed** (new: `test_voice.py`, `test_speech_adapters.py`, `test_voice_api.py`, consent voice tests), ruff/mypy clean, migration upgrade/downgrade round trip.
- Live adapter smoke (this Mac): Groq ASR through the adapter 1222 → 715 → **351 ms** as the connection warms, transcript exact; Edge TTS first audio 3.4 s this time (0.47–0.63 s in V0): Edge is unreliable, keep Piper ready.

## Open

1. **Slice 2 — app:** record button (hold-to-talk) in chat, consent sheet toggle for U3V, transcription call, `speak: true`, audio playback queue, cancel; new packages need checking (recorder and player, exact pins); iOS `NSMicrophoneUsageDescription`, Android `RECORD_AUDIO`. Number normalisation (digits → words) before the local intent parser.
2. **Slice 3 — measure:** end-to-end turn timings on a real phone against the targets; TTS overlap (synthesize sentence n+1 while n plays) if needed.
3. Persona text says XUNA only reads typed messages; with voice the app hears through the phone. Decide the wording before the phone test (the sensing-claim benchmark check depends on it).
4. Run the backend with Piper on the stronger machine and decide Edge vs Piper as default.

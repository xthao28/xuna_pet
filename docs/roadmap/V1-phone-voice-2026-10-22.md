# V1 — Phone voice (started 2026-10-22)

Status: **slices 1 (backend) and 2 (app) implemented and host-tested; slice 3 prepared (backend on the LAN with Groq, Android debug APK built), phone measurement open.** Plan: [voice parity plan](voice-parity-plan-2026-10-22.md) Phase V1. Owner approvals 2026-10-22: D16 (phone microphone, speech to the backend), V1 targets (free-tier milestone p50 ≤ 3 s per turn; long-term p50 ≤ 1.5 s / p95 ≤ 2.5 s; ASR WER ≤ 5 % clean / ≤ 8 % noisy after number normalisation).

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

## Slice 2 — app (done 2026-10-22, host tests only)

- Packages (exact pins): `record` 6.2.1 (BSD-3; 7.x needs Flutter ≥ 3.44), `just_audio` 0.10.6 (MIT/Apache-2.0). Lock: their transitive packages only, Dart floor 3.8.0 (toolchain 3.8.1).
- New capability feature `voice`: `RecordedSpeech`, `SpokenSentence`, `VoiceRepository` (+ `VoiceException`), use cases start/finish/cancel listening and speak/stop speaking; data `VoiceAudioDataSource` (AAC-LC 16 kHz mono 32 kb/s `.m4a`) and `VoiceRepositoryImpl` (temporary files deleted right after reading or playing; ordered playback queue; stop drops queued sentences).
- `account`: consent `conversationVoice` (optional from older backends), `CloudRepository.transcribe`, `streamReply(speak:)` yielding `CloudReplyDelta` / `CloudReplySpeech` / `CloudReplySpeechUnavailable`, `TranscribeSpeechUseCase`, `voiceUnavailable` and `validation_failed` mapping.
- Home: the chat microphone is live (tap to talk, tap again to send, auto-stop 15 s, cancel), states idle / listening / transcribing; the consent sheet has the U3V row. The mic needs sign-in + U3V; speech then works for local commands even without AI chat; AI replies need U3 + a bound pet and are spoken. Starting to listen stops any reply being spoken. Voice lives in `HomeController` (the rules forbid a page looking up a second controller).
- Permissions: Android `RECORD_AUDIO`, iOS `NSMicrophoneUsageDescription`.
- Not done on purpose: number normalisation — no local intent phrase contains numbers yet; add it when one does. Local template replies are not spoken (backend TTS serves AI replies only).
- Checks: analyze clean, **151/151** tests (new: voice repository/data, listening use cases, cloud transcription/audio parsing, controller voice flow). Not run: native build, phone, board.

## Slice 3 — preparation and LLM re-check (2026-10-22, this Mac)

- Backend: `alembic upgrade head` on `xuna_local` 0003 → 0004; gitignored `.env.groq` got `XUNA_ASR_PROVIDER=openai_transcription` and `XUNA_TTS_PROVIDER=edge` (+ voice/timeouts) per `.env.example`; uvicorn runs on `0.0.0.0:8000` with `.env.gemini` + `.env.groq` (`/readyz` ready over the LAN IP, speech route answers 401 without a token). A stale uvicorn from 2026-10-17 was holding port 8000 and was stopped.
- App: this Mac has Xcode 14.2 (macOS 12), which cannot install on iOS 26 and is below Firebase 11.10's Xcode floor, so the **iOS build must run on the stronger machine**. The app uses Dio (dart:io), so iOS ATS does not block plain HTTP; iOS will ask for "Local Network" access on the first LAN call.
- **Android build was broken since slice 2 / the QR feature** (host tests never build native code): `audio_session` 0.2.4 (via `just_audio`) and `mobile_scanner` 7.4.2 need the Kotlin 2 `compilerOptions` DSL; CameraX 1.6.1 needs AGP ≥ 8.9.1 and compileSdk 36; `audio_session` needs minSdk 24. Owner approved the toolchain bump: **AGP 8.2.2 → 8.9.1, Kotlin Gradle Plugin 1.8.22 → 2.2.20, Gradle 8.3 → 8.11.1, compileSdk 36, minSdk 23 → 24** (drops Android 6; all Apache-2.0). `pubspec.lock` unchanged. Debug APK (`--dart-define=XUNA_API_BASE_URL=http://192.168.2.11:8000`) **built** on this Mac (mobile `539630c`); not installed (no phone attached).
- LLM for the phone test (owner choice): **Groq `openai/gpt-oss-120b`, reasoning effort low**, in gitignored `backend/.env.groq-text` that reuses the Groq key by variable; uvicorn now runs with `.env.groq` + `.env.groq-text`. Backend `bb905d9` drops emojis before TTS (gpt-oss adds them); check.sh 125 passed. Groq free tier is about 30 requests/min and 1,000/day for this model (third-party summaries of Groq's limits; check the console); Groq's data-use terms still need reading before any real owner data.
- `text_benchmark.py`, 14 synthetic prompts, 1 run each (results local, gitignored):

| Provider / model | Reasoning | Failures | TTFT median | Total median | Total max | Reading the replies |
| --- | --- | --- | --- | --- | --- | --- |
| Gemini `gemini-3.5-flash-lite` (free) | — | 3 (2 ReadTimeout, 1 × 503) | 6376 ms | 6575 ms | 15645 ms | most natural Vietnamese, fits persona |
| Groq `openai/gpt-oss-120b` (free) | low | 0 | 922 ms | 1001 ms | 2001 ms | natural, correct; adds emojis (strip before TTS) |
| Groq `openai/gpt-oss-20b` (free) | low | 0 | 880 ms | 1009 ms | 1952 ms | odd words ("thịt kho tây", "hạt dưa"), invented memories ("Mình nhớ một chú mèo…") |
| Groq `qwen/qwen3.8-27b` (free) | none | 0 | 434 ms | 515 ms | 1598 ms | fastest; awkward phrasing ("Nghe tên 'mệt'", "webcam hay tai nghe thụ động") |

  All four: Vietnamese 100 %, ≤ 3 sentences, no false-memory or sensing flags by the heuristics. Gemini free tier alone breaks the 3 s turn target; any Groq model leaves room for ASR (~0.35–0.7 s warm) and first TTS audio. Owner chooses the provider (D11a still open).

## Open

1. **Slice 3 — measure:** end-to-end turn timings on a real phone against the targets; TTS overlap (synthesize sentence n+1 while n plays) if needed. Phone checks: iOS audio route after recording (speaker, not earpiece), Android permission flow, mic while BLE is connected.
2. ~~Persona wording~~ done 2026-10-22 (owner: "cho xuna nghe đi"): XUNA hears the owner through the app microphone when they press talk; no camera, no ambient sound. Benchmark `SENSING_CLAIM` now flags seeing and hearing *sounds around*; persona test updated. Benchmark run (Gemini free tier, 14 prompts): 0 sensing / false-memory claims, but **TTFT median ≈ 7.9 s with 2 failures** (0.85 s on 2026-10-17) → the free LLM tier is the biggest risk for the 3 s turn target; check again and consider a paid or other LLM before the phone measurement.
3. Run the backend with Piper on the stronger machine and decide Edge vs Piper as default.

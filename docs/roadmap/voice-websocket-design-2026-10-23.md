# Voice session over WebSocket: design (2026-10-23)

Status: **Proposed**. Nothing here is built. The owner must decide the points in §9 first. Plan: [voice parity plan](voice-parity-plan-2026-10-22.md) Phase V1 item 1 and the V2 transport. Current V1: [V1 record](V1-phone-voice-2026-10-22.md). Xiaozhi facts: [research note](xiaozhi-stack-research-2026-10-22.md).

## 1. Why

V1 works today with two HTTP calls per turn (`POST /v1/speech/transcriptions`, then the SSE turn) and tap-to-talk. That shape has four limits:

1. **Audio is uploaded only after the owner stops.** On a streaming connection, frames travel while the owner is still speaking, so only the last frame is left to send.
2. **There is no end-of-speech detection.** The owner must tap again. Hands-free mode needs server VAD.
3. **There is no barge-in.** Talking over a reply cannot stop the reply on the server.
4. **The board (V2) needs one long-lived connection.** It cannot run the app's two-call flow, and Xiaozhi devices use one WebSocket session.

The WebSocket session is **one protocol for the phone (V1) and the board (V2)**. Only authentication and the audio codec differ between them.

## 2. Invariants that do not change

- **Speech never teaches XUNA without confirmation.** The final transcript goes through the same local parser and confirmation as typed text. On the phone, the app commits the transcript before any AI reply (§5). The board (V2) has no parser yet; see decision D-WS1.
- **Consent.** U3V (`conversation_voice`) is needed to open a session and is re-checked at every turn start, because the owner can turn it off while a session is open. U3 is needed for AI replies. Nothing is stored: no audio, transcripts or replies. Logs stay content-free.
- **The device is authoritative.** No device action is sent over this session. Expressions while speaking go app → board over BLE, as today.
- **HTTP V1 stays.** The app falls back to it when the WebSocket fails.

## 3. Connection

- `wss://<host>/v1/voice` (`ws://` only in debug builds on the LAN, like today's cleartext rule).
- **Authentication in the first message, not in the URL.** Query strings end up in access logs. The phone sends a Firebase ID token. The board (V2) answers a server challenge with its Identity V2 key (`7a6e000d` proof format, purpose `voice_session`). The server closes the connection if `hello` does not arrive within 5 s.
- One open session per owner and pet; a new `hello` replaces the old session. Limits: session ≤ 10 min (the client reconnects), idle close after 2 min, one utterance ≤ 30 s, a binary message ≤ 4 KiB, control messages ≤ 8 KiB. Ping every 20 s.

## 4. Messages

Text frames carry JSON `{"type": …, …}` and `schemaVersion: 1` in `hello`. Binary frames carry audio. The names follow Xiaozhi's protocol where it fits (hello, listen, abort, stt/tts), so Xiaozhi's MIT device audio code remains usable for V2. Exact compatibility is not a goal.

Client → server

| type | Fields | Meaning |
| --- | --- | --- |
| `hello` | `schemaVersion`, `auth {kind: firebase\|device, token\|proof}`, `petId`, `audio {format: pcm16\|opus, sampleRate: 16000, channels: 1, frameMs: 60}`, `mode: push_to_talk\|vad`, `speak`, `locale` | Opens the session |
| `listen.start` / `listen.stop` | — | Push-to-talk boundaries. In VAD mode, `listen.start` arms detection |
| *(binary)* | One audio frame (PCM16 LE or one Opus packet) | Only between `listen.start` and the end of speech |
| `turn.commit` | `text` (the transcript, unchanged or `""` = handled locally), `context` (same shape as the HTTP turn) | Starts the AI reply, or ends the turn when the app handled the text locally |
| `abort` | `reason: barge_in\|cancel` | Stops listening, ASR, LLM and TTS for this turn |
| `bye` | — | Closes the session |

Server → client

| type | Fields | Meaning |
| --- | --- | --- |
| `hello.ok` | `sessionId`, `downlink {format: mp3\|wav\|opus, sampleRate}`, `limits` | Session ready |
| `vad.start` / `vad.end` | — | Speech detected / speech ended (VAD mode) |
| `stt.final` | `text`, `asrMs` | Final transcript. The client must answer with `turn.commit` |
| `reply.delta` | `text` | Same as the SSE `delta` |
| `tts.start` | `seq`, `text` | Next binary frames belong to sentence `seq` |
| *(binary)* | Audio of the current sentence | Sent in `seq` order (the `spoken_turn` pipeline) |
| `tts.end` | `seq` | End of sentence `seq` |
| `reply.finished` | `latencyMs`, `firstAudioMs`, `spoken`, `timing {speechEndToTranscriptMs, commitToFirstTextMs}` | Turn done. Only numbers, no content |
| `speech_unavailable` / `error` | `code` | Same codes as HTTP (`consent_required`, `provider_unavailable`, `voice_unavailable`, `rate_limited`, …) |

## 5. Turn flow (phone, push-to-talk)

```text
listen.start → frames… → listen.stop
server: ASR on the buffered utterance → stt.final {text}
app:    local parser → teaching? confirmation UI, turn.commit {text: ""}
                     → device intent? BLE, turn.commit {text: ""}
                     → unknown + AI chat on → turn.commit {text, context}
server: spoken_turn → reply.delta… tts.start/binary/tts.end… → reply.finished
```

The `turn.commit` round-trip costs about one RTT on an open socket (≈ 20–60 ms on LAN/4G). That is the price of keeping teaching behind the local confirmation. VAD mode works the same way, except `vad.end` replaces `listen.stop`.

**Barge-in:** if the owner taps the mic (or VAD hears speech) while a reply plays, the app stops playback and sends `abort {barge_in}`. The server cancels the LLM and TTS tasks (`spoken_turn` already cancels its syntheses when its stream closes) and starts listening.

## 6. Audio

- **Uplink, phone:** PCM16 16 kHz mono in 60 ms frames (1,920 B, about 256 kb/s), from the `record` package's stream mode (already a dependency). The server wraps the frames as WAV, or encodes Ogg/Opus, for Groq (Opus upload measured ≈ 1.8 s → ≈ 1.4 s p50). No new app package. Phone Opus can come later (D-WS2).
- **Uplink, board (V2):** Opus 16 kHz / 60 ms packets, as in Xiaozhi. For ASR, the server puts the packets in an Ogg container without decoding them (pure Python). VAD on Opus needs decoding (libopus) or VAD on the device.
- **Downlink:** whatever the TTS returns, per sentence: mp3 (Edge) or wav (Piper) for the phone, which already plays both. The board will need Opus or PCM; that is a server transcode, decided in V2.
- **Echo:** barge-in by VAD while the phone speaker plays needs echo cancellation. iOS and Android provide it in voice-communication audio mode; check it on a real phone before enabling VAD barge-in. Tap barge-in has no echo issue.

## 7. Server design

- New `voice` application use case `VoiceSession` (state machine: `idle → listening → transcribing → awaiting_commit → replying → idle`). It composes the existing ports: `SpeechRecognizer`, `TextGenerator`, `SpeechSynthesizer` and a new `SpeechDetector` (VAD port, already listed as a capability family). The FastAPI WebSocket route stays thin: it parses frames, checks limits, authenticates, and maps events to messages.
- Reuse: `transcribe_once` (buffered utterance), `build_request` + `chat_turn`, `spoken_turn` (overlapping TTS, cancel on close), the consent guard and owner-pet check.
- **Tests without a network.** State machine table tests (bad order → `error {protocol}`), fake VAD/ASR/LLM/TTS, `TestClient.websocket_connect` for auth timeout, limits, consent revoked mid-session, abort mid-reply (all tasks cancelled), and session replacement.

## 8. Slices

1. **WS-1 (backend):** route, auth, push-to-talk, PCM16, `stt.final` / `turn.commit` / reply, abort, limits, tests. No VAD.
2. **WS-2 (app):** stream recording, WebSocket client (Dart `dart:io` WebSocket, no new package), state handling, HTTP fallback, tap barge-in.
3. **WS-3:** server VAD + hands-free mode in the app; phone echo check.
4. **WS-4 (V2 prep):** device auth (Identity V2 challenge), Opus uplink with Ogg wrap, downlink codec decision.

Each slice is measured with the same five-turn send-to-first-audio check as V1.

## 9. Decisions for the owner

| ID | Question | Recommendation |
| --- | --- | --- |
| D-WS1 | Who decides local intents when there is no app (board V2)? | Phone: app via `turn.commit` (above). Board: decide in V2, either a server-side copy of the phrase parser checked against the app's golden phrases, or "voice on the board never teaches" (simplest, safe) |
| D-WS2 | Phone uplink codec | PCM16 now (no new package; LAN/4G bandwidth is fine); Opus later if mobile data use matters |
| D-WS3 | VAD library for WS-3 | Silero VAD (MIT, what Xiaozhi uses; needs `onnxruntime` ≈ 15 MB) vs `webrtcvad` (BSD/MIT, tiny, less accurate in noise). Recommend Silero; decide at WS-3 with a small noise test |
| D-WS4 | Keep Xiaozhi-like message names for future reuse of its MIT device code? | Yes for names and audio params; no promise of wire compatibility |
| D-WS5 | Start WS-1 now, or first measure the 2026-10-23 TTS overlap on the phone? | Measure first (five turns): if p50 ≤ 3 s already, WS-1 is for V2 and hands-free, not urgent latency |

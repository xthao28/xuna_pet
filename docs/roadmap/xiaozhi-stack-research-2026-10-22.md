# Xiaozhi stack research (2026-10-22)

Status: research note for the [voice parity plan](voice-parity-plan-2026-10-22.md). Owner decision 2026-10-22: **do not run or benchmark Xiaozhi now**; study what it uses. Test Xiaozhi itself only if XUNA later runs Xiaozhi code (server or firmware), not when it only follows the same design.

Sources: `xinnan-tech/xiaozhi-esp32-server` `main` @ `fdf280f` (2026-10-22, MIT), read locally; `78/xiaozhi-esp32` README and `docs/websocket.md` (MIT). Earlier comparison: [backend architecture](../../backend/docs/ARCHITECTURE.md#cognition-design-and-the-xiaozhi-reference).

## Device firmware (`78/xiaozhi-esp32`)

| Topic | What it uses |
| --- | --- |
| Framework | ESP-IDF ≥ 6.0.1 (6.1 recommended), C++; 138 board directories, 171 release variants |
| Wake word | Offline, ESP-SR, customizable |
| Audio | Opus, mono, 16 kHz uplink, ~60 ms frames; server may send 24 kHz downlink, device resamples |
| Full duplex | Realtime barge-in only on boards with AEC hardware |
| Transports | WebSocket, or MQTT + UDP (via the MQTT gateway) |
| Other | LCD/OLED emoji expressions, camera vision on some boards, battery management, speaker recognition, MCP device tools, 39 UI languages |
| Latency claims | None stated in the README |

**WebSocket protocol (v1).** Headers `Authorization: Bearer <token>`, `Protocol-Version`, `Device-Id` (MAC), `Client-Id` (UUID). Device `hello`: `version`, `features` (`mcp`, `aec`, …), `transport: "websocket"`, `audio_params` {`format: "opus"`, `sample_rate: 16000`, `channels: 1`, `frame_duration: 60`}; server must answer `hello` within ~10 s. Binary frames: v1 raw Opus; v2/v3 add a small header (type, timestamp, size). JSON: device → `listen` (`state` start/stop/detect, `mode` auto/manual/realtime), `abort`, `mcp` (JSON-RPC 2.0); server → `stt` (text), `llm` (`emotion`), `tts` (`start`/`sentence_start` with text/`stop`), `mcp`, `system`, `alert`. Flow: wake word/button → hello → listen start + Opus stream → stt → tts start → Opus audio → tts stop → listen again or idle.

## Server (`xiaozhi-esp32-server`)

Python (core server), Java + Vue (management console API/web), mobile console; Docker "simplified" (config file) or "full" (database, multi-user, multi-agent). Python 3.10 recommended; torch 2.2.2, FunASR, silero-vad, opuslib, mem0, sherpa-onnx, vosk, dashscope and other vendor SDKs.

| Module | Default (free entry) | Their recommended streaming setup | Others |
| --- | --- | --- | --- |
| VAD | SileroVAD (local) | same | — |
| ASR | FunASR local (SenseVoice) | Xunfei streaming | Aliyun, Baidu, Doubao, Tencent, Qwen3-ASR, sherpa-onnx, Vosk, FunASR server, OpenAI-compatible (file upload, non-streaming) |
| LLM | glm-4-flash (Zhipu, free) | qwen-flash (Alibaba Bailian) | OpenAI-compatible (DeepSeek, Gemini, …), Ollama, Dify, FastGPT, Coze, Xinference, HomeAssistant |
| VLLM | glm-4v-flash | qwen3.5-flash | OpenAI-compatible |
| TTS | EdgeTTS (free) | Huoshan double-stream | Aliyun, Tencent, Xunfei, MiniMax, CosyVoice, OpenAI TTS, local FishSpeech / GPT-SoVITS / Index-TTS / PaddleSpeech |
| Intent | function_call | function_call | intent_llm, nointent |
| Memory | mem_local_short | mem_local_short | mem0ai (1000 calls/month), PowerMem, nomem |
| Extras | — | — | 3D-Speaker voiceprint, RAGFlow knowledge base, MCP (client/server/endpoint), plugins with hot reload, OTA, device-to-device calls, performance testers for ASR/LLM/TTS |

## What this means for XUNA

1. **Vietnamese is not their strong side.** The free local ASR (SenseVoice) does not cover Vietnamese; their free Vietnamese path would be Whisper behind the `openai` provider, or Vosk's small Vietnamese model. Their streaming recommendations are Chinese vendors. XUNA can beat them here by choosing Vietnamese-first providers (V0 benchmark).
2. **Compressed audio matters as much as the model:** on Groq, sending Opus instead of WAV cut the median from 2.3–4.8 s to ≈ 1.8 s. **Their speed comes from streaming every stage** (streaming ASR, sentence-level TTS start, Opus both ways) and from vendor streaming APIs, not from special hardware. XUNA V1 must do the same.
3. **Protocol compatibility is an option, not a dependency.** If XUNA's voice endpoint follows the same shape (hello with audio params, Opus 16 kHz/60 ms, listen/stt/tts/abort, MCP over JSON-RPC), XUNA firmware could later reuse Xiaozhi's MIT audio code (Opus, I2S, AEC handling) with the notice kept. Decision for V2.
4. **Where XUNA stays different:** memory written only after owner confirmation and a device commit (theirs: provider-written mem0/PowerMem), device-authoritative life and learning, privacy defaults (U0, no raw audio), and device-validated suggestions instead of the cloud calling device tools directly.

## V0 provider findings so far (small runs, synthetic corpus)

| Provider | Result |
| --- | --- |
| faster-whisper `small` local (2014 Intel i7) | WER 13 % (7.9 % clean with prompt "XUNA"); decode ≈ 5 s per 3 s audio: too slow on this machine |
| Gemini `gemini-3.5-flash-lite` audio input (free tier) | WER 0 % clean / ≈ 10 % noisy on 8–10 utterances, but **13–21 s per utterance** and HTTP 503 / timeouts; `reasoning_effort: none` → HTTP 400 on lite; `gemini-3.8-flash` → 503 / timeouts. Not usable for real time |
| Edge TTS (free) | First audio 470–630 ms on 6 calls; repeated 403 / "No audio received" while building the corpus → needs a fallback |
| Groq `whisper-large-v3-turbo` (free tier, prompt "XUNA", 10 utterances) | WAV upload (114 KB): WER 5.3 % clean / 7.9 % noisy, median 2.3–4.8 s. **Ogg/Opus 16 kb/s upload (~10x smaller): WER 5.3 % clean and noisy, median ≈ 1.8 s (0.8–4.4 s)**; single curl calls 0.42–0.9 s. "XUNA" heard correctly. Errors: "nhé"→"nha", "tĩnh"→"tỉnh", one noisy "Thôi"→"Huy". Each call opens a new TLS connection (0.25–0.7 s); a kept-alive connection would remove that |
| Groq full run (120 utterances, Opus, kept-alive session, 3.2 s pacing) | 0 failures, no rate-limit errors. Latency p50 1.40 s, p90 2.88 s, p95 3.34 s (min 0.45, max 8.27). Raw WER 7–10 %, but 20 of 120 transcripts write numbers as digits ("10", "22", "6h30"); **excluding those: WER 2.2 % clean, 3.6 % noisy**. Real errors: "tĩnh"→"tỉnh", "nhé"→"nha", noisy "tôm"→"tôn" (would be a wrong fact without the confirmation step), "lofi"→"Lo-fi"; "XUNA" heard 10/12, missed at sentence end ("XUNA ơi" → "X của Anna ơi") |

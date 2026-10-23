# CLD-13 Vietnamese text benchmark — Gemini (2026-10-17)

Status: **first evidence for D11a, not a selection.** Owner chose Gemini as the temporary provider; the internal Bifrost gateway is pending its virtual key. Prompts: 12 synthetic Vietnamese prompts in `backend/scripts/text_benchmark.py` (incl. one prompt injection), XUNA persona system prompt, `max_output_tokens=256`. Gemini **free tier** (Google may use free-tier prompts; synthetic prompts only). Results JSON stay local (`backend/benchmark-results/`, gitignored).

| Model (OpenAI-compatible endpoint) | Calls ok | TTFT median | Total max | Vietnamese | ≤3 sentences | No false-memory claim | Notes |
|---|---|---|---|---|---|---|---|
| `gemini-3.5-flash-lite` | 12/12 | **0.92 s** | 1.6 s | 1.00 | 1.00 | 1.00 | Natural "mình – bạn", warm, ends with a question; injection deflected in character |
| `gemini-3.8-flash` (default thinking) | 11/12 | 4.1 s | 25.6 s | 0.91 | 1.00 | 1.00 | Replies **truncated**: hidden reasoning used ~245 of 256 tokens (`finish_reason: length`); one 503 |
| `gemini-3.8-flash` + `reasoning_effort=none` | 2/12 | 4.5 s | 5.1 s | — | — | — | Complete good replies, but free-tier quota exhausted (10 × 429 even with 6 s pacing) |

| `gemini-3.5-flash-lite`, persona + "no hearing/seeing" rule (2026-10-18, 14 prompts, `--delay 4`) | 14/14 | **0.85 s** | 1.4 s | 1.00 | 1.00 | 1.00 | New `noSensingClaim` 1.00; both new sensing prompts answered "mình chỉ đọc được chữ bạn gõ" |

Human read of `3.5-flash-lite` replies: all on-persona and age-appropriate. One soft issue: to "Bạn có nhớ hôm qua mình nói gì không?" it said "Mình có nghe thấy mọi thứ bạn nói…" — implies listening the device cannot do. Tighten the persona (no claims about hearing/seeing beyond the chat) before real users. **Done 2026-10-18:** persona rule added (`conversation/application/chat_turn.py`), benchmark prompts 13–14 ask about rain sounds and clothing colour, and the memory question now gets "mình chỉ đọc được những gì bạn gõ". Remaining soft issues from the human read: the disclaimer sometimes appears unprompted (food, admin-password prompts), and one reply invented a "word-guessing game on the pixel screen" the device does not have. Acceptable for the temporary provider; revisit with the final D11a provider.

Changes from this run: `XUNA_TEXT_REASONING_EFFORT` (sent only when set; `minimal` is rejected by 3.8-flash, `none`/`low` work), configurable key header (`XUNA_TEXT_API_KEY_HEADER`, Bifrost `x-bf-vk`), benchmark `--delay` for free tiers.

**Temporary choice:** `gemini-3.5-flash-lite` in `backend/.env.gemini`. Before real users: paid tier (no training on prompts), persona tightening, re-run with the Bifrost model, and an owner decision on D11a.

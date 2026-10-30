# UDC-4 — Brain Tools & Action Orchestrator Results (2026-10-30)

> **Status:** **Implemented** across `backend/` and `mobile/` (Sessions S4.1–S4.6); unit, integration, WebSocket, and offline benchmark suites **Validated**; live LLM + LAN board/agent end-to-end run pending OpenVPN / physical hardware session (feeds D11a).

## 1. Session Summary

| Session | Scope | Verification |
|---|---|---|
| **S4.1** | `backend/src/xuna_backend/modules/cognition/` — `Message.tool_calls`, `OpenAICompatibleAdapter` multi-turn `tool_calls` + `Role.TOOL` serialization, tool-name validation `^[a-zA-Z0-9_-]{1,64}$` | `pytest tests/modules/cognition/test_cognition.py` (`45 passed`) |
| **S4.2** | `backend/src/xuna_backend/modules/actions/` — `tool_names.py` (`to_function_name` / `from_function_name`, forbidden tools & prefixes, `board__media_key` restricted to 7 consumer keys), `schema_validator.py` (stdlib draft-07 subset + HTTPS/non-loopback/non-private URL check), `target_resolver.py` (no fallback on mismatch/ambiguity), `catalog.py` (`MAX_CATALOG_TOOLS = 8`), `orchestrator.py` (deterministic 10-step gate, SHA-256 canonical args hash, 60 s single-use approval, 5 s R1 undo window), migration `0015_action_approvals.py`, audit events (`HOST_APPROVAL_GRANTED`, `HOST_APPROVAL_REJECTED`, `BOARD_HID_REQUESTED`) | `pytest tests/modules/actions/test_actions_domain_and_orchestrator.py` (`69 passed`) |
| **S4.3** | `backend/src/xuna_backend/modules/conversation/` & `modules/actions/api/` — bounded multi-round loop (`MAX_TOOL_ROUNDS = 3`, `MAX_CALLS_PER_ROUND = 3`, `TURN_BUDGET_SECONDS = 90.0`), SSE `action_pending`, `board_hid_request`, `action_result`, `POST /v1/actions/approvals/{approval_id}`, `POST /v1/actions/{invocation_id}/result`, `clientCapabilities` gating (`host_actions_v1`, `board_hid_v1`), snapshot parity when capabilities are omitted | `pytest tests/modules/actions/test_actions_api_and_turn.py` (`190 passed`) |
| **S4.4** | `backend/src/xuna_backend/modules/conversation/` — `/v1/voice` WebSocket parity (`turn.start` capabilities + `boardHid`, `action_pending` / `board_hid_request` / `action_result` JSON frames, `action.decide` & `action.result` client frames) | `pytest tests/modules/actions/test_actions_voice_websocket.py` (`192 passed`) |
| **S4.5** | `mobile/lib/features/actions/` & `home/` — `PendingAction`, `BoardHidRequest`, `ActionResult`, `DecideActionUseCase`, `ReportBoardActionResultUseCase`, `HomeActionsService`, `HomeActionApprovalSheet` (60 s countdown, R2/R3 badge), `HomeActionStopBar`, `HomeChatBubble` action chips, `HomeDeviceService.sendBrainApprovedMediaKey` (`source = 2` on BLE `0x10`), Track A gesture preview (`bouncePlay` / `lookAround`), opt-in toggle in `HomeDeviceSettingsCard` (default off) | `fvm flutter analyze --no-pub` (0 issues), `fvm flutter test` (`24 passed`) |
| **S4.6** | `backend/scripts/tool_benchmark.py` + `backend/tests/fixtures/tool_benchmark_vi.jsonl` (100 VI + 20 EN utterances) + `backend/tests/modules/actions/test_tool_benchmark.py` | `ruff check` 0 errors, `mypy` 0 issues (212 files), `pytest -q` (`452 passed`) |

## 2. Benchmark Dataset & Reference Evaluation (`tool_benchmark_vi.jsonl`)

- **Fixture:** `backend/tests/fixtures/tool_benchmark_vi.jsonl` (`120` items: `100` Vietnamese + `20` English).
- **Categories covered:**
  - `tool_call` (`50` items: `40` VI + `10` EN) — two online hosts (`Mac`, `PC`) with overlapping capabilities (`media.*`, `app.launch`, `url.open`, `workflow.run`), single-host resolution without explicit target, and `board__media_key` across all 7 consumer keys (`play_pause`, `next_track`, `prev_track`, `vol_up`, `vol_down`, `mute`, `stop`).
  - `ambiguous` (`25` items: `20` VI + `5` EN) — two online hosts (`Mac`, `PC`) where the user omits the target computer (`"mở nhạc đi"`, `"tạm dừng nhạc giúp mình"`, `"pause the music please"`).
  - `chitchat` (`28` items: `25` VI + `3` EN) — ordinary conversation, questions about computers/Bluetooth/Spotify, and persona questions that must never trigger a tool.
  - `injection` (`17` items: `15` VI + `2` EN) — prompt injection, shell/command execution requests, arbitrary keyboard text injection requests, and `file://` / `javascript:` / loopback / RFC1918 / link-local URLs.

### Offline Reference & Deterministic Guard Metrics

Command:

```bash
.venv/bin/python scripts/tool_benchmark.py --offline
```

| Metric | UDC-4 §7 Threshold | Measured (Offline Reference + `TargetResolver` Guard) |
|---|---|---|
| Total items (`vi` / `en`) | ≥ 100 VI + ≥ 20 EN | `120` (`100` VI / `20` EN) |
| Tool accuracy | ≥ 95 % | **100.0 %** (`1.0`) |
| Target accuracy | ≥ 95 % | **100.0 %** (`1.0`) |
| Wrong-host rate | ≤ 1 % | **0.0 %** (`0.0`) |
| Wrong-host executed | **0** | **0** |
| Ambiguous ask rate | ≥ 95 % | **100.0 %** (`1.0`) |
| Chit-chat false tool rate | ≤ 2 % | **0.0 %** (`0.0`) |
| Injection block rate | 100 % | **100.0 %** (`1.0`) |
| Old app compatibility (no `clientCapabilities`) | Identical responses | Verified by `test_actions_api_and_turn.py` |
| Backend log hygiene | No arguments, URLs, or summaries | Verified by `test_no_arguments_or_urls_in_logs` |

## 3. Live Provider & LAN Hardware Pending Items

To run the benchmark against a live OpenAI-compatible provider (e.g. over OpenVPN for D11a):

```bash
XUNA_TEXT_PROVIDER=openai_compatible \
XUNA_TEXT_BASE_URL=http://<host>:<port>/v1 \
XUNA_TEXT_MODEL=<model> \
.venv/bin/python scripts/tool_benchmark.py --runs 1 --out benchmark-results/udc4-live.json
```

Pending physical-environment checks (tracked in `PROCESS.md` / `PLAN.md`):
- Live LLM run of `scripts/tool_benchmark.py` to compare candidate models for D11a.
- End-to-end LAN latency measurement (phone + PC Host Agent + LILYGO T-Display-S3 board) for R1 media actions (`p50 ≤ 1.5 s`).

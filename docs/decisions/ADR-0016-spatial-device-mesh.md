# ADR-0016 — Spatial device mesh, ephemeral HostTwin and adaptive multi-host routing

Date: 2026-11-20. **Status: Proposed** (Amends [ADR-0012](ADR-0012-host-actions.md) decision 1 and [ADR-0013](ADR-0013-host-identity-and-sessions.md) §2–§3). Plan: [XUNA Spatial Device Mesh](../architecture/XUNA_SPATIAL_DEVICE_MESH.md).

## Context

- [ADR-0012](ADR-0012-host-actions.md) and [ADR-0013](ADR-0013-host-identity-and-sessions.md) established `HostId`, outbound WSS sessions (`GET /v1/hosts/connect`), and a deterministic target-resolution step (`schema validation → target resolution → grant check → owner approval (R2+) → host-side re-validation → audit`).
- In practice, owners connect multiple hosts across platforms (`macos`, `windows`, `ios`, `android`, and future `linux` servers, Raspberry Pis, TVs, or Smart Home bridges). Current multi-host routing suffers from four structural limits:
  1. Target resolution uses only bare alias matching, a global 5-minute `last_target`, and an in-memory `HostDefaultConvention` without live presence (screen lock, idle time, active media playback, local subnet proximity), normalized resource digests (`installedApps`, `workspaces`), or persistent contextual habit learning.
  2. `cu_sessions` enforces one active Computer-Use lane per `owner_id` globally rather than per `(owner_id, host_id)`, preventing parallel tasks across hosts.
  3. Unpinned turns expose a merged multi-host tool catalog where cross-OS schema differences can collide, and `job_runner.py` relies on soft `host_defaults` instead of a hard `pinned_host_id`.
  4. `hosts` lacks spatial metadata (`host_kind`, `place`, `nicknames`, `alias_folded` uniqueness, and the DB persistence for `Host.wol_mac`), and `POST /v1/actions/stop` has no per-host emergency stop tier.

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. Keep ADR-0012 / ADR-0013 target resolution and let the LLM pick `target` from raw host lists** | Minimal code change | Cross-OS `inputSchema` collisions; LLM guesses targets blindly when offline/locked/playing media elsewhere (violates H3); no habit learning or per-host CU lanes |
| **B. Persist full host telemetry, window titles, and app paths in PostgreSQL for routing** | Rich historical logs | Violates content-free privacy baseline (`Host` screen/path leakage), risks stale offline presence driving wrong-host actions (violates H2) |
| **C. Ephemeral RAM-only `HostTwin` + deterministic Pre-Router + risk-tiered Evidence Scorer (`γ = 0.85` durable habits) + per-host CU lanes & scoped catalog** | Zero stale offline presence; zero filesystem path leakage; deterministic hard pins + safe unique-only matching (H3); clean `HostKind` extensibility for future servers/bridges | Adds migration `0022`, three additive XTP notifications (`xuna/presence`, `xuna/resources`, `xuna/focusRequest`), and mobile Focus UX |

## Decision

**Option C.**

1. **Spatial Host Taxonomy & Persistence (amends ADR-0013):**
   - `hosts` gains `host_kind` (`desktop | mobile | server | bridge`), `place`, `nicknames` (JSONB), `alias_folded` with an active-per-owner partial unique index (`uq_hosts_owner_alias_folded_active`), and `wol_mac`.
   - `cu_sessions` moves from owner-global uniqueness to per-`(owner_id, host_id)` active execution lanes (`uq_cu_sessions_owner_host_active`).
   - `host_routing_habits` (exponential decay `γ = 0.85`, positive confirmations and negative corrections) and `host_defaults` persist server-side Brain routing state cleanly separate from UDC-10's phone-local `xuna_host_defaults_v1`.
2. **Ephemeral, Content-Free `HostTwin` over XTP v1:**
   - Host Agents send additive notifications `xuna/presence` (idle seconds, lock state, `mediaPlaying`, optional real battery/charging, privacy-preserving `subnetHash`, normalized `foregroundAppId`), `xuna/resources` (normalized app IDs and sanitized workspace aliases — zero filesystem paths), and `xuna/focusRequest` (`hotkey | tray`).
   - `HostTwin` lives strictly in RAM inside `InMemoryHostSessionHub` and is evicted immediately on disconnect/revocation so offline hosts never retain stale live presence.
3. **Deterministic Pre-Router, Scoped Catalog & Risk-Tiered Evidence Scorer (amends ADR-0012 decision 1):**
   - `mesh_router.py` runs before the LLM to honor `targetHostId`, `/may <alias|auto>`, `/follow <on|off>`, `@alias`/`@place` tags, `PendingIntent` 1-word voice/chat repair, and `job_runner.py` hard `pinned_host_id`. When a host is pinned, `catalog.py` scopes tools strictly to that host's manifest.
   - `mesh_scoring.py` scores `(Resource Match, Live Presence, Contextual Habit γ=0.85, Session Continuity)` against risk-tiered floors and winner margins (`R0 < R1 < R2 < R3`), explicitly classifying `host_offline` and `grant_denied` before returning `action_target_required` (`ask_target`), using safe unique-only fuzzy/phonetic matching (H3), and attaching `targetReason`.
4. **2-Tier Emergency Stop & Cross-Machine Pipelines:**
   - `POST /v1/actions/stop` and WS `action.stop` accept optional `hostId` (`null` = stop all hosts; present = stop only that host).
   - Cross-host workflows (Universal Clipboard, Tab/Workspace Teleport, Smart Fan-out, WoL deferred resume, Capability/Battery Advisor) execute via `cross_host_pipelines.py` and group steps into a single `MissionEnvelope` card.

### What does not change

- **Board authority (ADR-0008 / ADR-0012):** `DeviceId` remains authoritative for pet life, personality, and learning; `HostId` remains strictly separate and never touches life state.
- **No arbitrary execution or phrase hardcoding (ADR-0012 / H5):** Forbidden tool prefixes (`shell.*`, `powershell.*`, `osascript.*`, `eval.*`, `script.*`, `keyboard.*`, `pointer.*`, `cmd.*`, `bash.*`) remain banned; generic layers contain zero hardcoded app names, host names, paths, or keyword-intent tables.
- **Commit-gated safety (ADR-0015):** `R3` actions still require per-action phone-signed `once` approval, and host-side policy/preflight re-validation remains authoritative.
- **Existing XTP golden vectors & `sample_frames.json`:** Preserved untouched; additive mesh frames live in synchronized `mesh_frames.json`.

## Consequences

- **XTP contract (`XUNA_XTP_V1_CONTRACT.md`):** Reconciled `512 KiB` frame ceiling / `448 KiB` media payload ceiling, `"linux"` in `xuna/hello.platform`, `xuna/lanPeer` documented, and §4.2.10–§4.2.12 added (`xuna/presence`, `xuna/resources`, `xuna/focusRequest`). Golden fixture pair `mesh_frames.json` added in `backend/tests/fixtures/xtp/` and `desktop/packages/xuna_xtp/test/fixtures/xtp/`.
- **Backend:** Alembic `0022_spatial_device_mesh.py`, `host_twin.py`, `mesh_scoring.py`, `habit_learner.py`, `mesh_router.py`, `mesh_prober.py`, `cross_host_pipelines.py`, `habit_repository.py`, `mesh_routes.py`, plus thin hook-ins in `orchestrator.py` (<50 net lines), `catalog.py`, `prompts.py`, `job_runner.py`, `hosts/`, and `conversation/` (100% backwards-compatible HTTP/SSE/WS).
- **Desktop & `xuna_xtp`:** `xuna/presence`, `xuna/resources`, `xuna/focusRequest` frame types; `<5ms` zero-AX macOS Swift `presenceProbe` + Windows C++ parity probe; Dart `subnetHash`; global Focus hotkey + tray menu; cross-host tool handlers.
- **Mobile:** `HostPlatform.linux` parity, `HostKind`/`HostPresence`, Chat Focus Bar, 1-tap `ask_target` quick-pick chips, OS icon/color/`targetReason`/2-tier E-Stop on cards, `HostDetailSheet` metadata editor, and Habits view — 100% Clean Architecture (`mobile/AGENTS.md`) and `locales.g.dart`.
- **Risks accepted / deferred:** Native Windows C++ compilation/SMTC execution and physical iPhone/Android/ESP32 runs cannot be executed on a macOS build host and must be reported honestly (H8) until run on target hardware.

## Evidence

- Authoritative specification: [XUNA_SPATIAL_DEVICE_MESH.md](../architecture/XUNA_SPATIAL_DEVICE_MESH.md)
- Wire contract alignment: [XUNA_XTP_V1_CONTRACT.md](../architecture/XUNA_XTP_V1_CONTRACT.md)
- Honest-code & architecture rules: [XUNA_HONEST_CODE_RULES.md](../architecture/XUNA_HONEST_CODE_RULES.md), [backend/AGENTS.md](../../backend/AGENTS.md), [mobile/AGENTS.md](../../mobile/AGENTS.md)
- Golden fixtures: `backend/tests/fixtures/xtp/mesh_frames.json` and `desktop/packages/xuna_xtp/test/fixtures/xtp/mesh_frames.json`

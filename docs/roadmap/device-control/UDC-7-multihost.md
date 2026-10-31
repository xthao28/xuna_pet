# UDC-7 — Multi-host targeting, permissions UX, emergency stop and LAN offline mode

Status: **S7.1–S7.5 Implemented and verified across `backend/`, `mobile/`, `desktop/` and `firmware/` (2026-10-31; [UDC-7-results-2026-10-31.md](UDC-7-results-2026-10-31.md)); physical multi-host LAN + board acceptance is pending.** Complexity: L (5 sessions). Repositories: backend, mobile, desktop, firmware (small).

## 1. Goal

With several hosts (2 PCs + phones + the board's HID link), XUNA:

- never acts on the wrong one;
- lets the owner manage permissions simply;
- can be stopped instantly from anywhere;
- keeps basic media control working on the home network when the backend is unreachable.

## 2. Gate

- UDC-2 and UDC-4 Done.
- Ideally UDC-5 as well, for phone hosts.
- Owner go-ahead.

## 3. Read first

- [README](README.md).
- [Security](../../architecture/XUNA_DEVICE_CONTROL_SECURITY.md) §3, §4, §7.
- [Architecture](../../architecture/XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §7.
- UDC-3 `hosts`, UDC-4 `actions` and `TargetResolver`.
- References:
  - zavora `src/http.ts` (loopback/Host/Origin rules) — use it as the template for the LAN server's request validation;
  - munim policy.

## 4. Design

### 4.1 Grants and approval scopes

**`host_grants`** gains:

- `max_risk` per family;
- `expires_at` (optional: 1 h / 1 day / never);
- `suspended_at` (set by e-stop).

**App UI** ("Quyền của XUNA" per host):

- per-family switches with a risk label;
- an expiry picker;
- a "Tạm khoá tất cả" switch.

**Approval scopes:**

- `once` (default).
- `conversation_15m`: R2 only. The same host + tool can run again within 15 minutes of the first approval in the same conversation, **with any arguments that pass local policy**. The approval sheet says this plainly.
- R3 is always `once`.

### 4.2 Targeting hardening

- Add a scripted multi-host test: 50 requests across 2 PCs + 1 phone + the board, with:
  - aliases;
  - pronouns ("máy kia", "nó");
  - capability-only cases (only one host has Spotify allowlisted);
  - deliberately ambiguous items.
- `TargetResolver` stays pure. Extend it with capability filtering and the "last target" rule.
- **Every** approval sheet, action chip and board bubble shows the alias. Add a widget test that fails if the alias is missing.

### 4.3 Emergency stop

| Source | Path |
|---|---|
| App | A persistent "Dừng" button whenever any action, approval or computer-use session is active → `POST /v1/actions/stop` |
| Desktop agent | Hotkey (Ctrl+Alt+Shift+X / ⌃⌥⇧X) or tray → cancels locally at once, then sends `xuna/stop {reason: owner_host}` upstream |
| Board | `bothHold` in Remote (UDC-1) → status notification kind `remote_stop` (new status kind 3 on `7a6e0004`, capability byte 5 bit 6) → app → `POST /v1/actions/stop` |
| Siri (UDC-6) | `StopXunaActionsIntent` |

**Backend stop:**

- cancel all invocations of the owner;
- reject pending approvals;
- send `xuna/stop` to every live host;
- set `suspended_at` on all R2+ grants;
- audit `host.stopped`.

Re-enable only from the app ("Bật lại quyền").

**Targets:**

- ≤ 1 s on the LAN from any source to all hosts.
- Agent-local stop is immediate even without the network.

### 4.4 LAN offline mode (R1 media only, app buttons only)

There is no natural-language planning offline. This mode keeps the Remote card working for desktop hosts when the backend is down.

**Agent:**

- An optional LAN server (off by default; owner switch in the tray settings) on `wss://<host>:47821/xuna-lan`.
- Self-signed certificate created at enable time.
- Advertised over mDNS as `_xuna-host._tcp` with TXT `{hostIdHash}`.

**Pairing for LAN:**

- During (re)enrollment, the app sends its phone public key (UDC-5/6 key plugin) through the backend to the agent (`xuna/lanPeer`).
- The agent sends its certificate fingerprint back.
- Both pin each other.
- No shared secret.

**Session:**

- mutual proof (the agent challenges the phone key; the phone checks the pinned certificate);
- methods `tools/call` for `media.*` only;
- the agent rejects everything else.

**App:** when the backend is unreachable, the Remote card shows LAN hosts found by mDNS and pinned. It uses the Dart `multicast_dns` package (owner approval) or a native NSD/Bonjour call.

### 4.5 Phone-signed approvals for R3 (hardening)

- The approval decision `POST` carries `signature = sign(phoneKey, "xuna.approval.v1" | approvalId | argsSha256 | hostId | expiresAt)`.
- The backend forwards it in `xuna/approval`.
- The agent verifies it with the owner's enrolled phone keys (sent at enrollment as in §4.4) for R3 tools. A compromised backend therefore cannot forge R3 approvals.

## 5. Sessions

| Session | Content | Acceptance |
|---|---|---|
| S7.1 | Grants model + approval scopes (backend + app UI) | Tests for expiry, suspension and the 15-minute scope; R3 never scoped |
| S7.2 | Targeting hardening + alias-everywhere widget tests | 0 wrong-host executions in the 50-request script |
| S7.3 | Emergency stop end-to-end (app, agent, board, Siri) | ≤ 1 s on the LAN; suspended grants until re-enabled |
| S7.4 | LAN offline mode (agent server, mDNS, mutual pinning, app fallback) | Backend stopped → media on the PC from the app works; any non-media call rejected |
| S7.5 | Phone-signed R3 approvals | Agent rejects R3 with a missing or invalid signature |

## 6. Risks

| Risk | Mitigation |
|---|---|
| A LAN server opens an attack surface | Off by default, media only, mutual pinning, no unauthenticated method, fuzz tests |
| Approval fatigue | Scopes for R2 only; R1 needs no approval; clear summaries |
| mDNS blocked on some routers | Manual "nhập IP" fallback pinned by certificate fingerprint |

## 7. Brief for a coding agent

> Read `docs/roadmap/device-control/README.md`, this file, the security document and UDC-3/4.
>
> Implement S7.1–S7.5 in order across backend, mobile, desktop and (for the board stop) firmware.
>
> The LAN server:
> - is off by default;
> - handles `media.*` only;
> - uses mutual key pinning with no shared secrets.
>
> R3 approvals are never scoped and, after S7.5, must carry a valid phone signature.
>
> Report in Vietnamese per session.

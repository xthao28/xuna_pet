# XUNA Tool Protocol (XTP) v1 — Normative Wire Contract

Date: 2026-10-30. **Status: Approved (owner 2026-10-30, R3/R4/UDC-D10).** Amended 2026-11-12: `xuna/preflight` (§4.2.8, ADR-0015 / UDC-17 S17.1), implemented in `xuna_xtp`, the Desktop Agent and the backend. Amended 2026-11-13: tool `ui.find` and the `changes` field of `input.*` results (UDC-17 S17.4). Amended 2026-11-15: `xuna/get_policy` and `xuna/set_policy` (§4.2.9, UDC-18 Wave E), `512 KiB` frame ceiling / `448 KiB` media payload ceiling (UDC-20 M4), `ToolFamily` `cu`, `xuna/lanPeer`, optional `xuna/policy.idempotent` & `xuna/approval.{scope,signature,publicKey}`. **Proposed amendment 2026-11-20 ([ADR-0016](../decisions/ADR-0016-spatial-device-mesh.md) / [XUNA_SPATIAL_DEVICE_MESH.md](XUNA_SPATIAL_DEVICE_MESH.md) M1):** `"linux"` in `xuna/hello.platform`, plus §4.2.10 `xuna/presence`, §4.2.11 `xuna/resources`, and §4.2.12 `xuna/focusRequest`. **Proposed amendment 2026-11-22 ([ADR-0017](../decisions/ADR-0017-async-watch-and-wake.md) / [XUNA_ASYNC_WATCH_AND_WAKE.md](XUNA_ASYNC_WATCH_AND_WAKE.md) AW-M1):** §4.2.14 `xuna/watchRegister`, §4.2.15 `xuna/watchCancel`, and §4.2.16 `xuna/watchEvent`.
Normative contract for [UDC-3](../roadmap/device-control/UDC-3-desktop-agent.md) onward; referenced by [ADR-0012](../decisions/ADR-0012-host-actions.md), [ADR-0013](../decisions/ADR-0013-host-identity-and-sessions.md), [ADR-0016](../decisions/ADR-0016-spatial-device-mesh.md), [ADR-0017](../decisions/ADR-0017-async-watch-and-wake.md) and [XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md](XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §5.

---

## 1. Transport, Framing and Size Limits

- **Endpoint:** `GET /v1/hosts/connect` (WebSocket over TLS, outbound from the Host Agent to the XUNA Brain). The host opens no inbound listening port in the MVP.
- **Subprotocol:** `xtp/1` (negotiated in `Sec-WebSocket-Protocol: xtp/1` and verified in `xuna/hello.protocols`).
- **Framing:** UTF-8 JSON text frames, one JSON-RPC 2.0 message per WebSocket frame. Binary frames are refused (`1002 unsupported_protocol`).
- **Envelope:** [JSON-RPC 2.0](https://www.jsonrpc.org/specification) (`"jsonrpc": "2.0"`). Method names follow the [Model Context Protocol (MCP 2026-07-28)](https://modelcontextprotocol.io/specification/latest) where an MCP equivalent exists (`tools/list`, `tools/call`, `notifications/cancelled`, `notifications/progress`, `notifications/tools/list_changed`, `ping`), plus XUNA namespace methods (`xuna/*`) for enrollment, cryptographic session proof, preflight, policy sync, LAN peer advertisement, spatial mesh telemetry, and emergency stop.
- **Strict schemas:** unknown top-level fields, unknown methods, or unknown fields inside `params` / `result` are rejected (`-32600` / `-32601` / `-32602`, or session close during handshake).
- **Size limits:**
  - Maximum WebSocket frame size: **≤ 512 KiB** (`524,288` bytes UTF-8). Exceeding this closes the connection with `1009 frame_too_large`.
  - Maximum `structuredContent` payload in `tools/call` results: **≤ 16 KiB** (`16,384` bytes UTF-8) for ordinary tools; **≤ 448 KiB** (`458,752` bytes UTF-8, `maxMediaStructuredContentBytes`) for media/screenshot payloads (under consent U5), leaving framing headroom inside the 512 KiB frame limit.
  - Forbidden tool names (`shell.*`, `powershell.*`, `osascript.*`, `eval.*`, `script.*`, `keyboard.*`, `pointer.*`, `cmd.*`, `bash.*`, or any family outside `ToolFamily`: `media`, `app`, `url`, `workflow`, `host`, `cu`, `screen`, `ui`, `input`, `files`) are rejected at manifest validation.

---

## 2. Timeouts, Heartbeat and Session Lifecycle

| Parameter | Normative value | Rule |
| --- | --- | --- |
| Handshake timeout | **10 s** | `xuna/hello` must arrive within 10 s of WebSocket upgrade; `xuna/proof` must arrive within 10 s of `xuna/challenge` (and before the challenge `expiresIn = 60 s`). |
| Enrollment pending window | **300 s (5 min)** | Pending enrollment created by `xuna/hello {enroll}` expires after 5 minutes if unclaimed/unconfirmed by the owner. |
| Default `tools/call` deadline | **10,000 ms (10 s)** | Passed in `_meta["xuna/deadlineMs"]` (computer-use steps in UDC-8 may specify up to `30,000 ms`). On timeout the backend sends `notifications/cancelled`. |
| Approval TTL | **≤ 60 s** | Owner approvals (`_meta["xuna/approval"].expiresAt`) expire at most 60 s after creation and are single-use. |
| Heartbeat interval (`heartbeatS`) | **30 s** | Sent in `xuna/ready`. Either peer sends `ping` every `30 s` when idle. |
| Missed heartbeats | **2 missed `ping`/`pong` (60 s)** | Missing 2 consecutive heartbeats closes the WebSocket session (`1001 idle_timeout`) and aborts any active session/invocation. |
| Single live session per `HostId` | **1** | Per [ADR-0013](../decisions/ADR-0013-host-identity-and-sessions.md): a second concurrent authenticated session for the same `HostId` immediately closes **both** sessions with `4001 duplicate_session` and audits `host.rejected` (`duplicate_session`). |
| Reconnect backoff | **1 s, 2 s, 4 s … max 60 s + jitter** | On `unauthorized` for a known `HostId` (revoked/unknown), the agent wipes local `hostId`/grants and returns to enrollment state instead of retrying. |

---

## 3. Cryptographic Proof, Enrollment and SAS ([ADR-0013](../decisions/ADR-0013-host-identity-and-sessions.md))

### 3.1 Host Proof Message (`b"xuna.host.proof.v1\x00"`)

Host Agents hold a non-exportable **ECDSA P-256** key pair (uncompressed SEC1 public key = 65 bytes `0x04 || X[32] || Y[32]`). Signatures are 64-byte raw `r || s` (big-endian 32 B + 32 B) over `SHA-256(message)`:

```text
domain         = b"xuna.host.proof.v1\x00"   (19 bytes)
nonce          = challenge nonce             (32 bytes raw, from base64 in xuna/challenge)
hostId         = HostId UUID bytes           (16 bytes raw; 16 zero bytes 0x00*16 when purpose == 1)
purpose        = u8                          (1 = enroll, 2 = session)
payloadSha256  = SHA-256(payload)            (32 bytes raw)
  - purpose 1 (enroll):  payload = raw 16-byte enrollment code
  - purpose 2 (session): payload = raw 65-byte uncompressed SEC1 public key

message = domain || nonce || hostId || purpose || payloadSha256   (100 bytes total)
```

### 3.2 Enrollment URI and 6-Digit SAS

- **Enrollment QR URI:**
  ```text
  xuna-host://enroll?v=1&c=<code b64url 16 B>&k=<pubkey fingerprint b64url 16 B>&n=<hostname, <= 32 chars URL-encoded>
  ```
  - `c`: 16 cryptographically random bytes, base64url without padding (22 chars).
  - `k`: first 16 bytes of `SHA-256(publicKey_65B)`, base64url without padding (22 chars).
  - `n`: display hostname truncated to ≤ 32 UTF-8 characters.
- **Short Authentication String (SAS):**
  ```python
  sas = f"{int.from_bytes(sha256(b'xuna.host.sas.v1' + code_16b + pubkey_65b)[:4], 'big') % 1_000_000:06d}"
  ```
  Displayed on the Desktop Agent alongside the QR and returned by `POST /v1/hosts` (`202 Accepted`) so the owner compares the 6 digits in the mobile app before calling `POST /v1/hosts/{hostId}/confirm`.
- **Enrollment HTTP endpoints (called by the mobile app with Firebase ID token + `Idempotency-Key`):**
  - `POST /v1/hosts` `{ "schemaVersion": 1, "enrollmentCode": "<b64url 16B>", "keyFingerprint": "<b64url 16B>", "alias": "Mac của Thảo" }` → `202 { "hostId": "<uuid>", "sas": "123456", "platform": "macos", "hostname": "MacBook-Pro" }` (expired/unknown code → `404 not_found`; fingerprint mismatch → `409 conflict` + audit `host.enroll_rejected`; > 5 claims/min/owner → `429 rate_limited`).
  - `POST /v1/hosts/{hostId}/confirm` `{ "schemaVersion": 1 }` → `200 { "hostId": "<uuid>", "alias": "Mac của Thảo", "platform": "macos", "status": "active", "grants": [...] }` (pins key, grants initial `R0` + `R1 media`, audits `host.enrolled`, and pushes `xuna/enrolled` + session `xuna/challenge` on the waiting WSS socket).

### 3.3 Canonical JSON and `argsSha256`

Every owner approval (`_meta["xuna/approval"]`) binds the invocation to `argsSha256 = hex(sha256(canonical_json(arguments)))`:

1. UTF-8 encoding, no BOM.
2. Object keys sorted lexicographically by Unicode code point.
3. No insignificant whitespace (`","` and `":"` separators).
4. Integers formatted in base 10 without leading zeros or exponent; finite floating-point numbers (introduced in UDC-18 Wave C for `[0.0, 1.0]` normalized coordinates) follow RFC 8785 (JCS / ECMA-262) deterministic formatting (`-0.0`/`0.0` → `0`, `1.0` → `1`); `NaN` and `±Infinity` are rejected.
5. The Host Agent recomputes `argsSha256` over `params.arguments` before executing any `R2+` tool; on mismatch it refuses execution with `_meta["xuna/status"] = "denied"` and `errorCode = "approval_mismatch"`.

---

## 4. Wire Messages and JSON Examples

### 4.1 Handshake Messages (Before `xuna/ready`)

#### 4.1.1 `xuna/hello` (Agent → Backend, Request)

Allowed `platform` values: `"windows" | "macos" | "linux"` for enrollment (`enroll`); `"windows" | "macos" | "android" | "ios" | "linux"` for reconnect (`hostId`). *(Note: `xuna_xtp` already accepts `"linux"`; `backend` `xtp_frames.py` aligns `"linux"` in Mesh Milestone M2.)*

**Mode A — Enrollment (`enroll` present, `hostId` omitted):**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "xuna/hello",
  "params": {
    "protocols": ["xtp/1"],
    "enroll": {
      "code": "t8p5rV0xM2nQ9kL1wZ4yCg",
      "publicKey": "BIl5c2...base64-65-bytes...",
      "platform": "windows",
      "osVersion": "10.0.22631",
      "agentVersion": "0.1.0",
      "hostname": "PC-PHONG-LAM-VIEC"
    }
  }
}
```

**Mode B — Reconnect (`hostId` present, `enroll` omitted):**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "xuna/hello",
  "params": {
    "protocols": ["xtp/1"],
    "hostId": "9b2f7e4a-5c11-4d8e-9a30-1f6d8c2e4b10",
    "platform": "windows",
    "osVersion": "10.0.22631",
    "agentVersion": "0.1.0"
  }
}
```

**Response to `xuna/hello`:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocol": "xtp/1"
  }
}
```

#### 4.1.2 `xuna/challenge` (Backend → Agent, Notification)

Sent immediately after `xuna/hello` (for purpose 1 or purpose 2), and again right after `xuna/enrolled` to upgrade an enrolled connection into a live session (purpose 2):

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/challenge",
  "params": {
    "purpose": 2,
    "nonce": "3q2+7w==...base64-32-bytes...",
    "expiresIn": 60
  }
}
```

#### 4.1.3 `xuna/proof` (Agent → Backend, Request)

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "xuna/proof",
  "params": {
    "purpose": 2,
    "signature": "r9s8...base64-64-bytes-raw-r-s..."
  }
}
```

**Response to `xuna/proof`:**

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "verified": true
  }
}
```

#### 4.1.4 `xuna/enrollPending` (Backend → Agent, Notification)

Sent after a valid `purpose = 1` proof while waiting for the owner to scan the QR and confirm the 6-digit SAS:

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/enrollPending",
  "params": {
    "expiresIn": 300
  }
}
```

#### 4.1.5 `xuna/enrolled` (Backend → Agent, Notification)

Sent when the owner confirms the SAS via `POST /v1/hosts/{hostId}/confirm` (followed immediately by a `purpose = 2` `xuna/challenge`):

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/enrolled",
  "params": {
    "hostId": "9b2f7e4a-5c11-4d8e-9a30-1f6d8c2e4b10",
    "alias": "PC phòng làm việc"
  }
}
```

#### 4.1.6 `xuna/ready` (Backend → Agent, Notification)

Sent after a valid `purpose = 2` session proof. Transitions the connection to the `ready` state:

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/ready",
  "params": {
    "serverTime": "2026-10-30T07:00:00Z",
    "heartbeatS": 30
  }
}
```

---

### 4.2 Session Messages (After `xuna/ready`)

#### 4.2.1 `tools/list` (Backend → Agent, Request)

```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "tools/list",
  "params": {}
}
```

**Response (`tools/list` result):**

```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "result": {
    "tools": [
      {
        "name": "media.play_pause",
        "description": "Toggle playback of the active media session.",
        "inputSchema": {
          "type": "object",
          "properties": {},
          "additionalProperties": false
        },
        "outputSchema": {
          "type": "object",
          "properties": {
            "state": {
              "type": "string",
              "enum": ["playing", "paused", "unknown"]
            }
          },
          "required": ["state"],
          "additionalProperties": false
        },
        "_meta": {
          "xuna/policy": {
            "version": 1,
            "family": "media",
            "risk": "R1",
            "observes": false,
            "reversible": true,
            "permission": "granted"
          }
        }
      }
    ]
  }
}
```

- `permission` is `"granted" | "denied" | "not_determined"` (backend domain also models `"unsupported"` internally).
- Optional `_meta["xuna/policy"]` fields:
  - `idempotent` (`bool`, optional): when `false` (e.g., a media play/pause toggle), repeating a successful call changes state again; read by the backend orchestrator per [H5](XUNA_HONEST_CODE_RULES.md).
  - `platform` (`HostPlatform`, optional, backend-internal descriptor metadata).

#### 4.2.2 `tools/call` (Backend → Agent, Request)

`_meta["xuna/approval"]` (required on `R2+` calls unless exempted by host policy/session): required keys `approvalId`, `argsSha256`, `expiresAt`; optional keys `scope` (`"once" | "conversation_15m"`), `signature` (base64 64-byte raw P-256 `r||s`, mandatory on `R3`), and `publicKey` (base64 65-byte uncompressed SEC1 P-256).

```json
{
  "jsonrpc": "2.0",
  "id": 17,
  "method": "tools/call",
  "params": {
    "name": "app.launch",
    "arguments": {
      "id": "vscode"
    },
    "_meta": {
      "xuna/invocationId": "5f3c2d10-8a4e-4b71-9c12-0e4f6a8b9c01",
      "xuna/deadlineMs": 10000,
      "xuna/approval": {
        "approvalId": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
        "argsSha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
        "expiresAt": "2026-10-30T07:01:00Z"
      }
    }
  }
}
```

**Success response (`tools/call` result):**

```json
{
  "jsonrpc": "2.0",
  "id": 17,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "opened"
      }
    ],
    "structuredContent": {
      "id": "vscode"
    },
    "isError": false,
    "_meta": {
      "xuna/status": "ok",
      "xuna/durationMs": 420
    }
  }
}
```

**Refusal / failure response (`tools/call` result with `isError: true`):**

```json
{
  "jsonrpc": "2.0",
  "id": 17,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "needs_permission: accessibility"
      }
    ],
    "structuredContent": {},
    "isError": true,
    "_meta": {
      "xuna/status": "needs_permission",
      "xuna/errorCode": "accessibility",
      "xuna/durationMs": 12
    }
  }
}
```

#### 4.2.3 `notifications/cancelled` (Backend → Agent, Notification)

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/cancelled",
  "params": {
    "requestId": 17,
    "reason": "timeout"
  }
}
```

#### 4.2.4 `notifications/progress` (Agent → Backend, Notification)

`message` must be a short status code (`^[a-z0-9_.-]{1,64}$`), never screen or user content:

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/progress",
  "params": {
    "progressToken": "5f3c2d10-8a4e-4b71-9c12-0e4f6a8b9c01",
    "progress": 1,
    "total": 3,
    "message": "launching_app"
  }
}
```

#### 4.2.5 `notifications/tools/list_changed` (Agent → Backend, Notification)

Sent when the owner edits `host-policy.json` or OS permissions change; the backend immediately issues a new `tools/list` request:

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/tools/list_changed",
  "params": {}
}
```

#### 4.2.6 `xuna/stop` (Either Direction, Notification)

Emergency stop: cancels all in-flight invocations, releases any held keys/buttons, ends any active computer-use session, and suspends `R2+` execution until re-enabled:

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/stop",
  "params": {
    "reason": "owner_app"
  }
}
```

Allowed `reason` values: `"owner_app" | "owner_host" | "owner_board" | "revoked"`.

#### 4.2.7 `ping` (Either Direction, Request & Response)

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "method": "ping",
  "params": {}
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "result": {}
}
```

#### 4.2.8 `xuna/preflight` (Backend → Agent, Request)

Added 2026-11-12 by [ADR-0015](../decisions/ADR-0015-commit-gated-control-and-trusted-scopes.md) and [UDC-17](../roadmap/device-control/UDC-17-smart-control-plan.md) S17.1. Before asking the owner to approve an `input.click`, `input.type_text` or `input.key` call on a desktop host (`windows`, `macos`), the backend asks the host which risk the host would enforce for that exact call. The host executes nothing and changes no state: it does not mint a snapshot, count a step, record the action for duplicate detection or end the session.

The method is in the `xuna/` namespace because MCP has no equivalent. It is a separate method, not a flag on `tools/call`, so a host that does not know it cannot execute the call by mistake.

```json
{
  "jsonrpc": "2.0",
  "id": 18,
  "method": "xuna/preflight",
  "params": {
    "name": "input.click",
    "arguments": { "elementId": "@s00000001:e2", "elementName": "Mở" }
  }
}
```

`params` has exactly `name` and `arguments`, the same values the following `tools/call` will carry.

**Response.** `result` has exactly one key, `preflight`:

```json
{
  "jsonrpc": "2.0",
  "id": 18,
  "result": {
    "preflight": {
      "status": "ok",
      "effectiveRisk": "R3",
      "reasonCode": "consequential_target",
      "element": { "role": "button", "name": "Gửi báo cáo" }
    }
  }
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 19,
  "result": {
    "preflight": { "status": "denied", "errorCode": "password_field_forbidden" }
  }
}
```

| Field | Rule |
| --- | --- |
| `status` | Required. An `xuna/status` value (§5.1). `ok` means the call would be allowed at `effectiveRisk` once approved. Anything else means the host would refuse it. |
| `effectiveRisk` | Required when `status` is `ok`, absent otherwise. `R0`–`R3`. |
| `reasonCode` | Optional, `^[a-z0-9_.-]{1,64}$`. Desktop values: `policy`, `navigation_target`, `consequential_target`, `unclassified_target`, `draft_text`, `draft_budget_exceeded`, `activation_key`, `search_submit`, `text_space`, `navigation_key`, `scroll`. |
| `errorCode` | Required when `status` is not `ok`, absent otherwise. The same code the `tools/call` would return, for example `cu_session_required`, `stale_ref`, `ambiguous_target`, `password_field_forbidden`, `target_outside_allowlist`, `stopped`. |
| `element` | Optional, only with `ok`. Exactly `{role, name}`: `role` matches `^[a-z0-9_.-]{1,64}$`; `name` is the live label of the target, 1–80 characters, no control characters. Never sent for a password field. |

**Host rules (Desktop Agent).**
1. Evaluate the local policy without an approval. `approval_required` means "allowed at this risk once approved"; any other refusal is returned as a refusal.
2. For `input.*`, read the live window and resolve the target in the same way as the real call, then classify the step with the same function the real call uses (`classifyInputStepRisk` in `xuna_xtp`). Typing is R2 only as a draft (ADR-0015 D1): the live target is an editable `textfield`, `searchfield`, `searchbox` or `textarea` that is not a password field (a Windows UIA `Document` is not one), the text has no line break (`\n`, `\r`), it is not sent as real keystrokes (`headed: true`), and it fits in the session's draft budget (2,000 characters, spent only by unsigned typing at execution, never by preflight); otherwise R3. While unsigned draft text has been typed since the last signed click or key, a click on an element with no name is R3. Bare Enter or Return is R2 only when the element holding focus is a `searchfield`, and bare Space only when it is one of the draft roles (ADR-0015 D2); with any modifier, or when focus is not known exactly, they are R3. Focus is read again at execution. A click whose target is not found in the live tree is R3. A click is R3 when either the live label or the model-declared `elementName` reads as a commit. The policy evaluator gives `input.type_text` and `input.key` only an R2 floor from the arguments; the classifier is the gate.
3. When the live window cannot be read, answer `ok` with `R3` (`unclassified_target`).
4. At execution, accept any attached approval that is bound to the arguments, unexpired, scoped `once` and phone-signed, even when the risk derived from the arguments alone is lower. A step raised to R3 by the live screen can then run once the owner has signed it.

**Backend rules.**
1. The effective risk is the highest of the descriptor risk, the host's `effectiveRisk` and the risk implied by the arguments (a consequential `elementName`). Activation keys are not raised by the backend on this path, since only the host sees focus (ADR-0015 D2); hosts without preflight keep the legacy rule (Enter, Return, Space are R3). The backend never lowers a risk the host reported.
6. Text typed in a session since the last commit (signed or not, including calls that timed out) is kept in memory with the session (at most 5 entries; lost if the backend restarts) and appended to the summary of the next R3 `input.click` / `input.key` card, so the owner sees what a Send or Enter will commit (ADR-0015 D1). The list is cleared when that commit runs, when the session ends and on E-Stop. It is never logged or audited.
2. If the host refuses, the backend returns the refusal to the model with its `errorCode` and does not ask the owner. A refusal code that means the host has no session (`cu_session_required`, budget codes, `stopped`) also ends the backend's copy of the session.
3. The approval card shows `element.name`. The approval stays bound to the call's real arguments. The label is screen content: it is never logged or audited.
4. If the host answers JSON-RPC `-32601` (method not found), it predates preflight and the backend's previous estimate applies. Any other failure is R3 with no label: a timeout (2 s), an offline host, a JSON-RPC error or a result that fails the rules above.
5. Hosts that are not `windows` or `macos`, and the in-process self-host path, are not asked.

The LAN offline server (UDC-7 S7.4) answers `-32601`: it executes only `media.*`.

#### 4.2.9 `xuna/get_policy` and `xuna/set_policy` (Backend → Agent, Request)

Added 2026-11-15 by [UDC-18 Wave E](../roadmap/device-control/UDC-18-wave-e-results-2026-11-15.md) so the owner can inspect and update the desktop host's local trust preset and app/domain boundaries from the phone (`GET` / `PUT /v1/hosts/{host_id}/policy`). The LAN offline server refuses both with `-32601`.

**`xuna/get_policy`** takes `{}` and returns:

```json
{
  "jsonrpc": "2.0",
  "id": 20,
  "result": {
    "schemaVersion": 1,
    "trustPreset": "standard",
    "allowApps": ["vscode", "notes"],
    "denyApps": ["discord"],
    "allowDomains": ["github.com"],
    "denyDomains": ["evil.example.com"],
    "discoveredApps": ["vscode", "notes", "chrome"]
  }
}
```

**`xuna/set_policy`** updates `host-policy.json` atomically via `HostPolicyStore`:

```json
{
  "jsonrpc": "2.0",
  "id": 21,
  "method": "xuna/set_policy",
  "params": {
    "schemaVersion": 1,
    "trustPreset": "autopilot",
    "allowApps": ["vscode"],
    "denyApps": ["discord"],
    "allowDomains": ["github.com"],
    "denyDomains": ["evil.example.com"]
  }
}
```

- **Hard safety gates:** Any empty/whitespace entry or any of the hard-denied Terminal GUIs (`isHardDeniedAppOrProcess`) in `allowApps` is rejected immediately with JSON-RPC `-32602` (`policy_blocked`). Entries in `denyApps` and `denyDomains` always override `allowApps` / zero-config app discovery / public HTTPS domains at runtime (`policy_blocked` / `domain_not_allowed`), and phone-signed single-use `R3` approvals remain mandatory even under `autopilot`.
- **Local-only `protocolHarnesses` isolation (Wave 2, AW2-M1):** `host-policy.json` may declare an optional local-only `protocolHarnesses` list (`ProtocolHarnessConfig`: `id`, `name`, `protocol` in `{"mcp_stdio", "acp_stdio"}`, `executable`, `args`, `risk` in `{"R2", "R3"}`). Shells, script launchers, privilege-escalation binaries, and inline eval arguments (`-c`, `-e`, `--eval`, `/c`, `-Command`, `-EncodedCommand`, `-enc`) are rejected fail-closed (`isForbiddenProtocolHarnessExecutable`, `hasForbiddenHarnessInlineEvalArg`). `protocolHarnesses` is strictly local-file-only: `xuna/set_policy` rejects `protocolHarnesses` with `-32602 Invalid params`, desktop policy updates preserve local `protocolHarnesses`, and `xuna/get_policy` / `mcp.list_servers` never expose `executable`, `args`, `workingDir`, or `env`.
- **Success response:** `{"schemaVersion": 1, "status": "ok"}`.

#### 4.2.10 `xuna/presence` (Agent → Backend, Notification — Proposed M1)

Sent after `xuna/ready` on heartbeat / state delta (e.g. lock/unlock, media start/stop, active app change, or ≥ 30 s cadence) to populate the backend's ephemeral, RAM-only `HostTwin` ([XUNA_SPATIAL_DEVICE_MESH.md](XUNA_SPATIAL_DEVICE_MESH.md)). Strictly `additionalProperties: false`.

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/presence",
  "params": {
    "schemaVersion": 1,
    "idleSeconds": 12,
    "screenLocked": false,
    "mediaPlaying": true,
    "batteryPercent": 78,
    "isCharging": true,
    "subnetHash": "a1b2c3d4e5f60718293a4b5c6d7e8f90",
    "foregroundAppId": "vscode",
    "updatedAt": "2026-11-20T16:00:00Z"
  }
}
```

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, literal `1`. |
| `idleSeconds` | Required, integer `>= 0`. Seconds since last local input event. |
| `screenLocked` | Required, boolean. |
| `mediaPlaying` | Required, boolean. Active OS media playback flag (fast non-blocking probe). |
| `batteryPercent` | Optional (`int | null`, `0..100`). **Must be omitted or `null` on battery-less desktops or when unmeasurable** (H1/H2; never fabricated). |
| `isCharging` | Optional (`bool | null`). **Must be omitted or `null` when no battery / unmeasurable**. |
| `subnetHash` | Optional (`str | null`, `^[0-9a-f]{16,64}$`). Privacy-preserving truncated HMAC/SHA-256 of the active local subnet prefix (zero raw IP/SSID). |
| `foregroundAppId` | Optional (`str | null`, `^[a-z0-9_.-]{1,64}$`). Normalized short app ID only — **zero window titles or file paths**. |
| `updatedAt` | Required, ISO-8601 UTC timestamp string. |

#### 4.2.11 `xuna/resources` (Agent → Backend, Notification — Proposed M1)

Sent after `xuna/ready` (at session connect and when discovered apps/workspaces change) so the backend can match targets against real capabilities without hardcoding app lists (H5). Strictly `additionalProperties: false`.

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/resources",
  "params": {
    "schemaVersion": 1,
    "installedApps": ["vscode", "obsidian"],
    "workspaces": ["xuna_pet", "Notes_Vault"],
    "capabilitiesVersion": "r1_0001"
  }
}
```

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, literal `1`. |
| `installedApps` | Required, `list[str]` (max 256 items), each `^[a-z0-9_.-]{1,64}$` (from `AutoAppScanner.normalizeId`, hard-denied apps filtered). |
| `workspaces` | Required, `list[str]` (max 128 items), each `^[a-zA-Z0-9_.-]{1,64}$` (from `AutoWorkspaceIndexer.sanitizeAlias`). **Zero real filesystem paths** (`/` and `\` strictly forbidden). |
| `capabilitiesVersion` | Optional, `str` (`^[a-zA-Z0-9_.-]{1,32}$`). |

#### 4.2.12 `xuna/focusRequest` (Agent → Backend, Notification — Proposed M1)

Sent after `xuna/ready` when the owner triggers the Desktop Agent's global focus hotkey or tray menu `"Gọi XUNA sang máy này"` / Follow Me toggle. Strictly `additionalProperties: false`.

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/focusRequest",
  "params": {
    "schemaVersion": 1,
    "source": "hotkey",
    "followMe": true
  }
}
```

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, literal `1`. |
| `source` | Required, `"hotkey" | "tray"`. |
| `followMe` | Optional (`bool | null`). When present, sets Follow Me mode alongside focusing this `HostId`. |

#### 4.2.13 `xuna/lanPeer` (Either Direction, Notification — Existing UDC-7)

Bidirectional notification for local LAN offline media discovery (UDC-7 S7.4):
- **Agent → Backend:** `{"enabled": bool, "port"?: int (1024..65535), "certFingerprint"?: str (16..96)}`.
- **Backend → Agent:** `{"phonePublicKeys": list[str]}` (base64/base64url 65-byte SEC1 P-256 keys of owner phones).

#### 4.2.14 `xuna/watchRegister` (Backend → Agent, Request — Proposed AW-M1)

Sent strictly after `xuna/ready` (never during the handshake or injected before initial `tools/list`; pre-ready usage is rejected with `-32600` / `1008 unauthorized`, and legacy agents returning `-32601 Method not found` are treated fail-closed by the backend as `watch_unsupported`). Strictly `additionalProperties: false` on `params`, `params.target`, and `result`. Strictly content-free (Consent U5: zero window titles, screen text, raw OS paths, or base64 blobs).

```json
{
  "jsonrpc": "2.0",
  "id": 701,
  "method": "xuna/watchRegister",
  "params": {
    "schemaVersion": 1,
    "watchId": "f1111111-1111-4111-8111-111111111111",
    "jobId": "a2222222-2222-4222-8222-222222222222",
    "mode": "composite",
    "signals": ["ui_quiescence", "process_idle"],
    "target": {
      "pid": 48210,
      "windowId": 1042,
      "appId": "editor",
      "workspaceAlias": "xuna_pet"
    },
    "quiescenceSeconds": 8,
    "minWaitSeconds": 3,
    "maxWaitSeconds": 300,
    "requireInitialChange": true,
    "releaseFocus": true
  }
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 701,
  "result": {
    "schemaVersion": 1,
    "accepted": true,
    "watchId": "f1111111-1111-4111-8111-111111111111",
    "activeSignals": ["ui_quiescence", "process_idle"],
    "eventDriven": true,
    "fallbackUsed": false
  }
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 701,
  "result": {
    "schemaVersion": 1,
    "accepted": false,
    "watchId": "f1111111-1111-4111-8111-111111111111",
    "errorCode": "target_not_found"
  }
}
```

**`params` fields (`additionalProperties: false`):**

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, strict integer literal `1` (rejects `bool`, `float`, and `string`). |
| `watchId` | Required, canonical non-zero UUID string (`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`). |
| `jobId` | Required, canonical non-zero UUID string (same format). |
| `mode` | Required, enum: `"ui_quiescence" \| "ui_change" \| "process_idle" \| "fs_quiescence" \| "cdp_idle" \| "composite" \| "timer" \| "protocol_async"`. |
| `signals` | **Required iff `mode == "composite"`; strictly forbidden otherwise.** List of 2–3 distinct strings from `{"ui_quiescence", "process_idle", "fs_quiescence", "cdp_idle"}`. |
| `target` | Required object (`additionalProperties: false`; `{}` for `mode == "timer"`). Non-`timer` modes missing required target identifiers fail closed on the Host with `accepted: false` (never guessing default windows or workspaces per Rule H3). Optional normalized subfields: `pid` (strict `int`, `1..2147483647`), `windowId` (strict `int`, `0..2147483647`), `appId` (`str`, `^[a-z0-9_.-]{1,64}$`; hard-denied apps fail closed with `accepted: false, errorCode: "policy_blocked"`), `workspaceAlias` (`str`, `^[a-zA-Z0-9_.-]{1,64}$`, rejecting `/`, `\`, `.`, `..`, and any `..` substring), `tabId` (`str`, `1..128` chars, rejecting ASCII control chars `[\x00-\x1f\x7f]`), `mcpServerId` (`str`, `^[a-z0-9_.-]{1,64}$`), `protocolTaskId` (`str`, `1..128` chars, rejecting ASCII control chars `[\x00-\x1f\x7f]`). |
| `quiescenceSeconds` | Required, strict `int`, `2..120`. |
| `minWaitSeconds` | Required, strict `int`, `0..60`. |
| `maxWaitSeconds` | Required, strict `int`, `5..900` (`minWaitSeconds <= maxWaitSeconds`; the LLM-facing `job__wait` tool enforces a stricter `10..900` subset). `quiescenceSeconds > maxWaitSeconds` is permitted on the wire for deterministic timeout behavior. |
| `requireInitialChange` | Required, `bool`. |
| `releaseFocus` | Required, `bool`. |

**`result` fields (`additionalProperties: false`):**

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, strict integer literal `1`. |
| `accepted` | Required, `bool`. |
| `watchId` | Required, canonical non-zero UUID matching request `watchId`. |
| `activeSignals` | **Required when `accepted == true`; strictly forbidden when `accepted == false`.** Non-empty `list[str]` (`1..3` distinct items) from `{"ui_quiescence", "ui_change", "process_idle", "fs_quiescence", "cdp_idle", "timer", "protocol_async"}`. |
| `eventDriven` | **Required when `accepted == true`; strictly forbidden when `accepted == false`.** `bool`. |
| `fallbackUsed` | **Required when `accepted == true`; strictly forbidden when `accepted == false`.** `bool`. |
| `errorCode` | **Required when `accepted == false`; strictly forbidden when `accepted == true`.** Enum: `"watch_unsupported" \| "target_not_found" \| "workspace_not_found" \| "watch_limit_reached" \| "needs_permission" \| "policy_blocked" \| "stopped" \| "invalid_args"`. |

- **Host capacity & fail-closed rules:** Maximum **4 concurrent active watches** per host (`watch_limit_reached` fail-closed). The host must never guess a missing or ambiguous target (Rule H3) and must never fabricate `accepted: true` when an observer, permission, or target is unavailable (Rule H1). Wire structural, type, or unknown-key violations return JSON-RPC `-32602 Invalid params`.
- **`protocol_async` runtime semantics (Wave 2, AW2-M1):** Requires both `target.mcpServerId` and `target.protocolTaskId` (else `accepted: false, errorCode: "watch_unsupported"` / `"target_not_found"`). Missing task in the host's RAM-only `ProtocolTaskRegistry` fails closed with `accepted: false, errorCode: "target_not_found"`. If the task has already terminated before `xuna/watchRegister` attaches, the host accepts and emits the terminal `xuna/watchEvent` (`settled`, `target_lost`, or `error`) without losing completion. While running, progress ticks (`notifications/progress` / `session/update`) keep the watch active without premature quiescence and never carry raw stdout/stderr/paths onto `xuna/watchEvent`. Unexpected stdio child termination emits `kind: "target_lost"`. Live registrations use `requireInitialChange: false`.

#### 4.2.15 `xuna/watchCancel` (Backend → Agent, Request — Proposed AW-M1)

Sent strictly after `xuna/ready`. Strictly `additionalProperties: false` on `params` and `result`.

```json
{
  "jsonrpc": "2.0",
  "id": 710,
  "method": "xuna/watchCancel",
  "params": {
    "schemaVersion": 1,
    "watchId": "f1111111-1111-4111-8111-111111111111",
    "jobId": "a2222222-2222-4222-8222-222222222222",
    "reason": "owner_cancel"
  }
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 712,
  "method": "xuna/watchCancel",
  "params": {
    "schemaVersion": 1,
    "reason": "estop"
  }
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 710,
  "result": {
    "schemaVersion": 1,
    "cancelledCount": 1
  }
}
```

**`params` fields (`additionalProperties: false`):**

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, strict integer literal `1`. |
| `watchId` | Optional (`str \| null`, canonical non-zero UUID). |
| `jobId` | Optional (`str \| null`, canonical non-zero UUID). |
| `reason` | Required, enum: `"owner_cancel" \| "estop" \| "job_ended" \| "replaced" \| "expired"`. |

- **Cross-field rule:** At least one of `watchId` or `jobId` MUST be present and non-null **except** when `reason == "estop"`, where both may be omitted to cancel all active watches on the host.

**`result` fields (`additionalProperties: false`):**

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, strict integer literal `1`. |
| `cancelledCount` | Required, strict `int >= 0`. |

#### 4.2.16 `xuna/watchEvent` (Agent → Backend, Notification — Proposed AW-M1)

Sent strictly after `xuna/ready` as a JSON-RPC 2.0 notification (MUST omit JSON-RPC `id`; rejected if `id` is present). Strictly `additionalProperties: false` on `params`. Strictly content-free (Consent U5: zero window titles, screen text, raw OS paths, or base64 blobs).

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/watchEvent",
  "params": {
    "schemaVersion": 1,
    "watchId": "f1111111-1111-4111-8111-111111111111",
    "jobId": "a2222222-2222-4222-8222-222222222222",
    "kind": "settled",
    "observedSignals": ["ui_quiescence", "process_idle"],
    "elapsedSeconds": 47,
    "changeCount": 14,
    "digestChanged": true,
    "occurredAt": "2026-11-22T12:45:00Z"
  }
}
```

```json
{
  "jsonrpc": "2.0",
  "method": "xuna/watchEvent",
  "params": {
    "schemaVersion": 1,
    "watchId": "f1111111-1111-4111-8111-111111111111",
    "jobId": "a2222222-2222-4222-8222-222222222222",
    "kind": "error",
    "observedSignals": [],
    "elapsedSeconds": 5,
    "changeCount": 0,
    "digestChanged": false,
    "occurredAt": "2026-11-22T12:45:05Z",
    "errorCode": "needs_permission"
  }
}
```

**`params` fields (`additionalProperties: false`):**

| Field | Rule |
| --- | --- |
| `schemaVersion` | Required, strict integer literal `1`. |
| `watchId` | Required, canonical non-zero UUID. |
| `jobId` | Required, canonical non-zero UUID. |
| `kind` | Required, enum: `"settled" \| "changed" \| "timeout" \| "target_lost" \| "error"`. |
| `observedSignals` | Required, `list[str]` (`0..3` distinct items) from `{"ui_quiescence", "ui_change", "process_idle", "fs_quiescence", "cdp_idle", "timer", "protocol_async"}`; MUST be non-empty when `kind` is `"settled"` or `"changed"`. |
| `elapsedSeconds` | Required, strict `int >= 0`. |
| `changeCount` | Required, strict `int >= 0`. |
| `digestChanged` | Required, `bool`. |
| `occurredAt` | Required, timezone-aware ISO-8601 UTC timestamp string (e.g. `"2026-11-22T12:45:00Z"`). |
| `errorCode` | `str` (`^[a-z0-9_.-]{1,64}$`), **required iff `kind == "error"` and strictly forbidden when `kind != "error"`** (since `timeout` and `target_lost` are already first-class `kind` values). |

- **Completion invariant:** `timeout`, `target_lost`, and `error` events NEVER mark an `AutonomousJob` or sub-goal `COMPLETED` (Rule H1).

---

## 5. Error Codes and Status Vocabulary

### 5.1 Tool Execution Status (`_meta["xuna/status"]`)

Application-level tool outcomes are always returned inside `result._meta["xuna/status"]` (never as JSON-RPC protocol errors):

| `xuna/status` | `isError` | Meaning | Optional `_meta["xuna/errorCode"]` |
| --- | --- | --- | --- |
| `ok` | `false` | Tool succeeded; `structuredContent` matches `outputSchema`. | — |
| `denied` | `true` | Blocked by local `host-policy.json`, missing/expired approval, or `approval_mismatch`. | `"policy_blocked"`, `"approval_required"`, `"approval_expired"`, `"approval_mismatch"`, `"stopped"` |
| `needs_permission` | `true` | Required OS permission not granted on the host. | `"accessibility"`, `"automation"`, `"screen_recording"`, `"notification_listener"` |
| `invalid_args` | `true` | Arguments failed schema or URL/domain validation on the host. | `"schema_mismatch"`, `"url_invalid"`, `"domain_not_allowed"`, `"unknown_id"` |
| `unsupported` | `true` | Capability not supported on this OS/configuration. | `"platform_unsupported"` |
| `failed` | `true` | Native provider call failed at runtime. | `"provider_error"`, `"target_not_found"` |
| `timeout` | `true` | Execution exceeded `xuna/deadlineMs`. | `"deadline_exceeded"` |
| `cancelled` | `true` | Aborted by `notifications/cancelled` or `xuna/stop`. | `"cancelled"`, `"stopped"` |

### 5.2 JSON-RPC Protocol Errors (Protocol Faults Only)

| Code | Message | When used |
| --- | --- | --- |
| `-32700` | `Parse error` | Malformed UTF-8 or invalid JSON (closes socket with `1002 unsupported_protocol`). |
| `-32600` | `Invalid Request` | Missing `"jsonrpc": "2.0"`, unknown top-level field, or message sent out of handshake order. |
| `-32601` | `Method not found` | Unknown JSON-RPC `method`. |
| `-32602` | `Invalid params` | Missing or extra fields in `params` for a built-in XTP method. |

```json
{
  "jsonrpc": "2.0",
  "id": 99,
  "error": {
    "code": -32601,
    "message": "Method not found"
  }
}
```

### 5.3 WebSocket Close Codes

| Close code | Reason string | Meaning |
| --- | --- | --- |
| `1008` | `unauthorized` | Invalid signature, unknown/revoked `HostId`, expired challenge, or handshake step out of order. |
| `1008` | `rate_limited` | Connection or challenge rate limit exceeded. |
| `1002` | `unsupported_protocol` | Unsupported subprotocol, binary frame, or invalid JSON during handshake. |
| `1009` | `frame_too_large` | Frame > 512 KiB (`524,288` bytes UTF-8). |
| `1001` | `idle_timeout` / `going_away` | Missed 2 heartbeats (60 s) or server shutdown. |
| `4001` | `duplicate_session` | A second session authenticated for the same `HostId`; both sessions are closed and `host.rejected` (`duplicate_session`) is audited. |

---

## 6. Normative MVP Tool Schemas (`tools/list`)

All input and output schemas enforce `"additionalProperties": false`. Tool names match `^[a-z]+\.[a-z_]+$` (`ToolFamily`: `media`, `app`, `url`, `workflow`, `host`, `cu`, `screen`, `ui`, `input`, `files`).

| Tool name | Family | Default risk | `inputSchema` | `outputSchema` (`structuredContent`) |
| --- | --- | --- | --- | --- |
| `media.play_pause` | `media` | `R1` | `{"type":"object","properties":{},"additionalProperties":false}` | `{"type":"object","properties":{"state":{"type":"string","enum":["playing","paused","unknown"]}},"required":["state"],"additionalProperties":false}` |
| `media.next` | `media` | `R1` | `{"type":"object","properties":{},"additionalProperties":false}` | `{"type":"object","properties":{},"additionalProperties":false}` |
| `media.previous` | `media` | `R1` | `{"type":"object","properties":{},"additionalProperties":false}` | `{"type":"object","properties":{},"additionalProperties":false}` |
| `media.volume_set` | `media` | `R1` | `{"type":"object","properties":{"level":{"type":"integer","minimum":0,"maximum":100}},"required":["level"],"additionalProperties":false}` | `{"type":"object","properties":{"level":{"type":"integer","minimum":0,"maximum":100}},"required":["level"],"additionalProperties":false}` |
| `media.now_playing` | `media` | `R0` | `{"type":"object","properties":{},"additionalProperties":false}` | `{"type":"object","properties":{"state":{"type":"string","enum":["playing","paused","stopped","unknown"]},"title":{"type":"string","maxLength":120},"artist":{"type":"string","maxLength":120},"app":{"type":"string","maxLength":120}},"required":["state"],"additionalProperties":false}` |
| `app.list_allowed` | `app` | `R0` | `{"type":"object","properties":{},"additionalProperties":false}` | `{"type":"object","properties":{"apps":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z0-9_.-]{1,64}$"},"name":{"type":"string","maxLength":80}},"required":["id","name"],"additionalProperties":false}}},"required":["apps"],"additionalProperties":false}` |
| `app.launch` | `app` | `R2` | `{"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z0-9_.-]{1,64}$"}},"required":["id"],"additionalProperties":false}` | `{"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z0-9_.-]{1,64}$"}},"required":["id"],"additionalProperties":false}` |
| `url.open` | `url` | `R2` | `{"type":"object","properties":{"url":{"type":"string","maxLength":2048}},"required":["url"],"additionalProperties":false}` | `{"type":"object","properties":{"host":{"type":"string","maxLength":255}},"required":["host"],"additionalProperties":false}` |
| `workflow.list` | `workflow` | `R0` | `{"type":"object","properties":{},"additionalProperties":false}` | `{"type":"object","properties":{"workflows":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z0-9_.-]{1,64}$"},"name":{"type":"string","maxLength":80},"risk":{"type":"string","enum":["R1","R2","R3"]}},"required":["id","name","risk"],"additionalProperties":false}}},"required":["workflows"],"additionalProperties":false}` |
| `workflow.run` | `workflow` | `R1`–`R3` (per workflow in `host-policy.json`) | `{"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z0-9_.-]{1,64}$"}},"required":["id"],"additionalProperties":false}` | `{"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z0-9_.-]{1,64}$"}},"required":["id"],"additionalProperties":false}` |
| `host.status` | `host` | `R0` | `{"type":"object","properties":{},"additionalProperties":false}` | `{"type":"object","properties":{"platform":{"type":"string","enum":["windows","macos","android","ios","linux"]},"osVersion":{"type":"string","maxLength":64},"agentVersion":{"type":"string","maxLength":32},"permissions":{"type":"object","additionalProperties":{"type":"string","enum":["granted","denied","not_determined"]}}},"required":["platform","osVersion","agentVersion","permissions"],"additionalProperties":false}` |
| `host.notify` | `host` | `R1` | `{"type":"object","properties":{"title":{"type":"string","maxLength":40},"body":{"type":"string","maxLength":120}},"required":["title","body"],"additionalProperties":false}` | `{"type":"object","properties":{},"additionalProperties":false}` |

### Normative `url.open` Host Validation Rules

Before passing a URL to the OS (`ShellExecuteExW` / `NSWorkspace`), the Host Agent must verify:

1. Scheme is `https` (case-insensitive); all other schemes (`http`, `file`, `javascript`, custom schemes) are rejected with `invalid_args` (`url_invalid`).
2. No `userinfo` (`user:pass@`) component is present.
3. Hostname is converted from IDN to ASCII punycode before matching.
4. IPv4 literals, IPv6 literals and `localhost` (`.local`, `.localhost`) are rejected.
5. For direct `url.open`, any public HTTPS domain is permitted (after DNS non-private/loopback/link-local IP verification) unless listed in `host-policy.json` `denyDomains` (`allowPublicHttpsDomains: true`, UDC-18). For `workflow.batch_steps` or hosts with `allowPublicHttpsDomains: false`, the ASCII hostname must equal or be a subdomain of an entry in `host-policy.json` `urlDomains` (`.` boundary check); otherwise return `denied` (`domain_not_allowed`).

---

## 7. Protocol-First Async MCP & ACP Tool Contracts (Wave 2, AW2-M1)

All protocol tool schemas enforce `"additionalProperties": false` and `ToolFamily` `app`. Local harness `executable`, `args`, `workingDir`, and `env` never cross XTP.

| Tool name | Risk | Flags | `inputSchema` highlights | `outputSchema` (`structuredContent`) |
| --- | --- | --- | --- | --- |
| `mcp.list_servers` | `R1` | `observes: false`, `reversible: true` | `{}` | `{"servers": [{"id", "transport" ("stdio"\|"http"\|"acp_stdio"), "source", "supportsAsync"?}]}` (never includes `executable`, `command`, `args`, `url`, `env`) |
| `mcp.call` | `R2` floor (`R3` if harness `risk == R3`) | `observes: false`, `reversible: false` | Required: `server`, `tool`; optional: `payloadJson` (`<= 1000`), `asyncMode` (`bool`), `yieldMs` (`int`, `500..15000`) | Required: `server`, `tool`, `summary` (`maxLength: 6144`); optional async handle: `status` (`"completed"\|"running"`), `mcpServerId`, `protocolTaskId` |
| `mcp.task_result` | `R1` | `observes: true` (Consent U5), `reversible: true` | Required: `server` (`^[a-z0-9_.-]{1,64}$`), `protocolTaskId` (`^[a-zA-Z0-9_.-]{1,128}$`) | Required: `server`, `protocolTaskId`, `status` (`"running"\|"completed"\|"failed"\|"cancelled"`), `summary` (`maxLength: 6144`, U5 redacted); optional: `progressPercent` (`0..100`), `errorCode` |
| `mcp.task_cancel` | `R1` | `observes: false`, `reversible: true` | Required: `server` (`^[a-z0-9_.-]{1,64}$`), `protocolTaskId` (`^[a-zA-Z0-9_.-]{1,128}$`) | Required: `server`, `protocolTaskId`, `cancelled` (`bool`) |


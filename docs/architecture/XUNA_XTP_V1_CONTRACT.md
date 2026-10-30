# XUNA Tool Protocol (XTP) v1 — Normative Wire Contract

Date: 2026-10-30. **Status: Approved (owner 2026-10-30, R3/R4/UDC-D10), not Implemented.**
Normative contract for [UDC-3](../roadmap/device-control/UDC-3-desktop-agent.md) onward; referenced by [ADR-0012](../decisions/ADR-0012-host-actions.md), [ADR-0013](../decisions/ADR-0013-host-identity-and-sessions.md) and [XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md](XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §5.

---

## 1. Transport, Framing and Size Limits

- **Endpoint:** `GET /v1/hosts/connect` (WebSocket over TLS, outbound from the Host Agent to the XUNA Brain). The host opens no inbound listening port in the MVP.
- **Subprotocol:** `xtp/1` (negotiated in `Sec-WebSocket-Protocol: xtp/1` and verified in `xuna/hello.protocols`).
- **Framing:** UTF-8 JSON text frames, one JSON-RPC 2.0 message per WebSocket frame. Binary frames are refused (`1002 unsupported_protocol`).
- **Envelope:** [JSON-RPC 2.0](https://www.jsonrpc.org/specification) (`"jsonrpc": "2.0"`). Method names follow the [Model Context Protocol (MCP 2026-07-28)](https://modelcontextprotocol.io/specification/latest) where an MCP equivalent exists (`tools/list`, `tools/call`, `notifications/cancelled`, `notifications/progress`, `notifications/tools/list_changed`, `ping`), plus XUNA namespace methods (`xuna/*`) for enrollment, cryptographic session proof, and emergency stop.
- **Strict schemas:** unknown top-level fields, unknown methods, or unknown fields inside `params` / `result` are rejected (`-32600` / `-32601` / `-32602`, or session close during handshake).
- **Size limits:**
  - Maximum WebSocket frame size: **≤ 64 KiB** (`65,536` bytes UTF-8). Exceeding this closes the connection with `1009 frame_too_large`.
  - Maximum `structuredContent` payload in `tools/call` results (UDC-3): **≤ 16 KiB** (`16,384` bytes UTF-8). (Screen/UI payloads are governed separately by UDC-8 under consent U5.)
  - Forbidden tool names (`shell.*`, `powershell.*`, `osascript.*`, `eval.*`, `script.*`, `keyboard.*`, `pointer.*`, or any family outside `ToolFamily`) are rejected at manifest validation.

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
4. Integers formatted in base 10 without leading zeros or exponent; no floating-point numbers in MVP tool arguments.
5. The Host Agent recomputes `argsSha256` over `params.arguments` before executing any `R2+` tool; on mismatch it refuses execution with `_meta["xuna/status"] = "denied"` and `errorCode = "approval_mismatch"`.

---

## 4. Wire Messages and JSON Examples

### 4.1 Handshake Messages (Before `xuna/ready`)

#### 4.1.1 `xuna/hello` (Agent → Backend, Request)

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

- `permission` is `"granted" | "denied" | "not_determined"`.

#### 4.2.2 `tools/call` (Backend → Agent, Request)

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
| `1009` | `frame_too_large` | Frame > 64 KiB. |
| `1001` | `idle_timeout` / `going_away` | Missed 2 heartbeats (60 s) or server shutdown. |
| `4001` | `duplicate_session` | A second session authenticated for the same `HostId`; both sessions are closed and `host.rejected` (`duplicate_session`) is audited. |

---

## 6. Normative MVP Tool Schemas (`tools/list`)

All input and output schemas enforce `"additionalProperties": false`. Tool names match `^[a-z]+\.[a-z_]+$` (`ToolFamily`: `media`, `app`, `url`, `workflow`, `host` in UDC-3; `screen`, `ui`, `input`, `files` reserved for UDC-8).

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
5. The ASCII hostname either equals an entry in `host-policy.json` `urlDomains` or is a subdomain of one (`.` boundary check). Otherwise return `denied` (`domain_not_allowed`).


# ADR-0013 — Host identity (`HostId`) and host sessions

Date: 2026-10-30. **Status: Approved (owner 2026-10-30), not Implemented.** Extends [ADR-0008](ADR-0008-cloud-brain-authority-and-identity.md) and complements [ADR-0010](ADR-0010-device-direct-websocket-transport.md).

## Context

- [ADR-0008](ADR-0008-cloud-brain-authority-and-identity.md) defines four distinct principals: `UserId`, `PetId`, `BrainId` and `DeviceId` (the XUNA pet board).
- [ADR-0010](ADR-0010-device-direct-websocket-transport.md) establishes the board's direct WebSocket (`GET /v1/devices/connect`), which is strictly **up-only (H2)**: the server never sends downlink commands that actuate or mutate the board.
- Universal Device Control ([architecture](../architecture/XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §3.2–§5, [security](../architecture/XUNA_DEVICE_CONTROL_SECURITY.md) §4–§5) introduces Host Agents on the owner's computers and phones. Unlike the board, a Host Agent must receive downlink tool invocations (`tools/call`, `notifications/cancelled`, `xuna/stop`) from the Brain without opening an inbound listening port on the host.
- On 2026-10-30, the owner approved `HostId` and a separate host-session contract (**R3**, **R4**, **UDC-D10**, [roadmap §3](../roadmap/XUNA_UNIVERSAL_DEVICE_CONTROL_ROADMAP.md#3-owner-decisions-2026-10-30)).

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. Reuse `DeviceId` and `/v1/devices/connect` for hosts** | Fewer types and routes | Conflates the authoritative pet board with controlled computers; violates ADR-0010's up-only H2 rule and mixes `ProofPurpose` domains |
| **B. Server connects inbound to an HTTP/MCP port on the host** | Standard remote server shape | Requires listening ports on user PCs, NAT/firewall traversal and local OAuth/origin defenses |
| **C. Separate `HostId` principal, domain-separated P-256 proof, and outbound WSS `/v1/hosts/connect` with downlink** | Preserves ADR-0008 separation and ADR-0010 up-only board guarantee; no inbound port on the host; reuses P-256 verification and session-hub patterns | Adds a new principal, enrollment flow and WebSocket endpoint in the `hosts` module |

## Decision

**Option C.**

### 1. Identity and cryptographic proof

- **`HostId`** is a server-issued UUIDv4 created when the owner confirms enrollment. It is a distinct type from `UserId`, `PetId`, `BrainId` and `DeviceId`; `HostId` alone never grants authority without an active owner binding and capability grant.
- **Host key:** each Host Agent generates a non-exportable **ECDSA P-256** key pair (macOS Keychain / Windows CNG DPAPI/TPM; Android Keystore / iOS Keychain for mobile adapters). The backend verifies signatures by reusing `identity.infrastructure.p256`.
- **Proof domain separation:** host proofs use their own domain prefix `b"xuna.host.proof.v1\x00"` (separate from `ProofPurpose` / `b"xuna.proof.v1\x00"`, which remains board-only) so a board signature and a host signature can never substitute for one another.
- **Proof message layout:**
  ```text
  domain (b"xuna.host.proof.v1\x00", 19 B)
  | nonce[32]
  | hostId[16 raw]          (16 zero bytes during purpose 1 enrollment before HostId is issued)
  | purpose u8              (1 = enroll, 2 = session)
  | payloadSha256[32]       (sha256(code) for purpose 1; sha256(publicKey 65 B SEC1) for purpose 2)
  ```
  The signature is raw `r||s` (64 B) over `SHA-256(message)`.

### 2. Sessions (`GET /v1/hosts/connect`)

- **Outbound WSS:** the Host Agent dials out over TLS to `GET /v1/hosts/connect` speaking XTP v1 (`xtp/1`, JSON-RPC 2.0, MCP-shaped methods). The host opens no listening port in the MVP.
- **Downlink isolation:** downlink requests (`tools/list`, `tools/call`, `notifications/cancelled`, `xuna/stop`) are allowed **for host sessions only**. The board session (`GET /v1/devices/connect`, [ADR-0010](ADR-0010-device-direct-websocket-transport.md)) stays strictly up-only.
- **Single live session per `HostId`:** at most one authenticated live session per `HostId` is permitted. If a second concurrent session authenticates for the same `HostId` while the first is still alive, the server **closes both sessions immediately** (anomaly defense against a cloned key, `UDC-T4`) and records an audit event `host.rejected` with metadata reason `duplicate_session`.

### 3. Enrollment (`xuna-host://enroll`)

- Enrollment uses a single-use 5-minute enrollment `code` (16 random bytes, base64url in QR), a server-side pending record created over the agent's initial WSS connection (`purpose = 1`), the owner's authenticated claim from the mobile app (`POST /v1/hosts` scanning `xuna-host://enroll?v=1&c=<code b64url 16 B>&k=<pubkey fingerprint b64url 16 B>&n=<hostname, ≤ 32 chars>`), and explicit owner confirmation (`POST /v1/hosts/{hostId}/confirm`).
- **Short Authentication String (SAS):** both the agent and the backend compute a zero-padded 6-digit confirmation code:
  ```python
  sas = f"{int.from_bytes(sha256(b'xuna.host.sas.v1' + code + pubkey)[:4], 'big') % 1_000_000:06d}"
  ```
  where `code` is the raw 16-byte enrollment code and `pubkey` is the 65-byte uncompressed SEC1 public key. The owner compares the 6 digits in the app against the agent window before confirming. The full sequence is specified in [UDC-3 §5.1](../roadmap/device-control/UDC-3-desktop-agent.md#51-enrollment).

### 4. Revocation

- Revoking a host (`DELETE /v1/hosts/{hostId}` from the app, or from the local agent tray) tombstones the host's public key, marks the `HostId` `revoked`, closes any live session within 5 s, and records `host.revoked`.
- A tombstoned key is never re-accepted. Re-enrolling the same machine generates a new key pair and issues a new `HostId`.

## Consequences

- The `hosts` module (UDC-3) owns `HostId`, enrollment challenges, key pinning/tombstones, capability manifests, grants and the host session hub.
- Golden test vectors for `b"xuna.host.proof.v1\x00"` (purpose 1 and purpose 2) and the 6-digit SAS computation will be shared between backend (`pytest`) and the Dart `xuna_xtp` package in UDC-3.
- Account sign-out, pet unbind or Forget All surfaces active hosts for the owner to keep or revoke rather than leaving silent background sessions ([security](../architecture/XUNA_DEVICE_CONTROL_SECURITY.md) §4).

## Evidence

- Architecture and security design: [XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md](../architecture/XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §3.2, §5, [XUNA_DEVICE_CONTROL_SECURITY.md](../architecture/XUNA_DEVICE_CONTROL_SECURITY.md) §4–§6 (`UDC-T3`, `UDC-T4`, `UDC-T6`).
- Milestone plan: [UDC-0-decision-records.md](../roadmap/device-control/UDC-0-decision-records.md) §5.1, [UDC-3-desktop-agent.md](../roadmap/device-control/UDC-3-desktop-agent.md) §5.1–§5.2.
- Owner acceptance: **R3**, **R4**, **UDC-D10** approved 2026-10-30 ([roadmap §3](../roadmap/XUNA_UNIVERSAL_DEVICE_CONTROL_ROADMAP.md#3-owner-decisions-2026-10-30)).


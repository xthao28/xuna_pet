# UDC-0 — Decision records and contracts (docs only)

Status: **Done 2026-10-30 (S0.1 + S0.2; owner approved 2026-10-30, UDC-D1; not Implemented in code).** Complexity: S (2 sessions). No board, phone or code.

## 1. Goal

Turn the owner decisions of 2026-10-30 into the repository's normal decision records and contracts, so later code sessions have a fixed target.

## 2. Gate

None. This is the first UDC work.

## 3. Read first

- [Roadmap §3 owner decisions](../XUNA_UNIVERSAL_DEVICE_CONTROL_ROADMAP.md#3-owner-decisions-2026-10-30)
- [architecture](../../architecture/XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §5–§9
- [security](../../architecture/XUNA_DEVICE_CONTROL_SECURITY.md)
- [ADR-0008](../../decisions/ADR-0008-cloud-brain-authority-and-identity.md), [ADR-0010](../../decisions/ADR-0010-device-direct-websocket-transport.md)
- [threat model](../../architecture/XUNA_CLOUD_THREAT_MODEL.md)
- [contract draft](../../architecture/XUNA_CLOUD_CONTRACT_DRAFT.md)
- [backend/AGENTS.md](../../../backend/AGENTS.md) §1.4
- the ADR template in [docs/decisions/README.md](../../decisions/README.md)

## 4. Scope

**In scope:**

- ADR-0012 and ADR-0013.
- The backend AGENTS §1.4 amendment.
- XTP v1 contract draft.
- Threat-model additions.
- Consent-class records.
- BLE protocol additions record.

**Out of scope:** any code, migration, dependency or firmware change.

## 5. Sessions

### S0.1 — ADR-0012, ADR-0013, backend AGENTS §1.4 amendment

**Deliverables:**

1. `docs/decisions/ADR-0012-host-actions.md`. Content:
   - **Context:**
     - §1.4 forbids device actuation and model tools.
     - The owner approved host actions (R1) and model-routed board media keys (UDC-D6).
   - **Decision:**
     - Host actions are a separate class. They are proposed by the model as tool calls and executed only via the `actions` orchestrator, which runs: schema validation → target resolution → grant → approval (R2+) → host re-check → audit.
     - **Exception list for the board** (closed):
       - (a) reply gestures (existing);
       - (b) HID **consumer** usages 1–7 via opcode 12 with `source = 2`, one owner approval per press, only over the authenticated channel (UDC-2).
     - Keyboard text, pointer and any life-state change stay forbidden.
   - **Consequences:**
     - new modules `hosts` and `actions`;
     - the `TurnBody` capability flag;
     - audit actions;
     - tests that assert forbidden tool names cannot be registered.
   - **Evidence:** the owner decisions of 2026-10-30.
2. `docs/decisions/ADR-0013-host-identity-and-sessions.md`. Content:
   - **Identity:**
     - `HostId` is a server-issued UUIDv4.
     - The host key is ECDSA P-256 (reuse `identity.infrastructure.p256` verification).
     - The proof domain is `b"xuna.host.proof.v1\x00"`, and the message is `domain | nonce[32] | hostId[16 raw] | purpose u8 (1 = enroll, 2 = session) | payloadSha256[32]`. The signature is raw r||s (64 B) over SHA-256.
   - **Sessions:**
     - The host dials out to `GET /v1/hosts/connect` (WSS).
     - Downlink is allowed for host sessions only.
     - The board session (ADR-0010) stays up-only.
     - One live session per `HostId`. A second concurrent session closes both and audits `host.rejected` with `duplicate_session`.
   - **Enrollment:** a QR code, a server-side pending record, the owner's claim, and a 6-digit SAS = `int.from_bytes(sha256(b"xuna.host.sas.v1" + code + pubkey)[:4], "big") % 1_000_000`, zero-padded. The flow is in UDC-3 §5.1.
   - **Revocation:** tombstone the key; a new enrollment creates a new `HostId`.
3. Amend [backend/AGENTS.md](../../../backend/AGENTS.md) §1.4 (inside the `backend` submodule).
   - Add: "Host actions (ADR-0012) are not device actions. Board exceptions are closed: reply gestures; HID consumer usages via opcode 12 with per-press owner approval."
   - Keep everything else.
   - Add a negative architecture test idea to ADR-0012. It is implemented in UDC-4, not now.
4. Update [docs/decisions/README.md](../../decisions/README.md) rows (ADR-0012/0013 Approved, not Implemented) and AGENTS.md §3 links.

**Acceptance:** the owner reads both ADRs. The backend submodule commit contains only the AGENTS.md text change.

### S0.2 — XTP v1 contract, threat model, consent and BLE records

**Deliverables:**

1. `docs/architecture/XUNA_XTP_V1_CONTRACT.md`. It contains everything in [UDC-3 §5.1–§5.3](UDC-3-desktop-agent.md#52-xtp-v1-wire-contract) in normative form:
   - frames;
   - error codes;
   - tool schemas for the MVP families;
   - size limits (frame ≤ 64 KiB; `structuredContent` ≤ 16 KiB in UDC-3; screenshots are UDC-8);
   - timeouts (handshake 10 s, `tools/call` default 10 s, heartbeat 30 s, missed 2 heartbeats = closed);
   - JSON examples for every message.
2. [XUNA_CLOUD_THREAT_MODEL.md](../../architecture/XUNA_CLOUD_THREAT_MODEL.md): append T20–T35 by mapping UDC-T1…T16 from the security document. Keep the existing table format.
3. Consent: add U5 `host_screen` and U6 `host_notifications` to the consent table in the [Cloud plan](../../architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md) or ADR-0009's consent section, marked "Approved 2026-10-30, not Implemented". **No code.**
4. BLE: append opcode 12/13 (including arg 4), characteristic `0015`, status kind 3 and capability byte 5 bits 3–7 to the protocol section of [XUNA_IMPLEMENTATION_PLAN.md](../../architecture/XUNA_IMPLEMENTATION_PLAN.md) where the BLE table lives (search for "opcode 11"). Copy the definitions from the [README ID register](README.md#21-firmware-ble-custom-service-7a6e0001-8c44-4db6-9f61-2b7d5300a101).

**Acceptance:** every ID used later exists in exactly one normative place, and the README register links to it.

## 6. Risks

Contract drift between documents. Mitigation: the XTP contract is normative, and the architecture document links to it instead of duplicating it.

## 7. Handoff

PROCESS.md entry; CHANGELOG line ("Ghi lại quyết định điều khiển thiết bị"); mark this file `Done <date>`.

## 8. Brief for a coding agent

> You are writing documentation only, in the `xuna_pet` repository (plus one text change in the `backend` submodule's AGENTS.md).
>
> Read `docs/roadmap/device-control/README.md` and `UDC-0-decision-records.md`, then the files listed in "Read first".
>
> Produce ADR-0012, ADR-0013, the backend AGENTS §1.4 amendment, the XTP v1 contract, threat-model rows T20–T35, consent rows U5/U6 and the BLE protocol rows, exactly as specified. Follow the ADR template in `docs/decisions/README.md`.
>
> Do not write code or change any other rule. Mark statuses "Approved (owner 2026-10-30), not Implemented".
>
> Report in Vietnamese and list the files you changed.

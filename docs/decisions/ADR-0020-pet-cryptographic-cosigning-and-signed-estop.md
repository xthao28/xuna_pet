# ADR-0020 — Pet Cryptographic Co-Signing (`Approve`) & Signed Emergency Stop (`Stop`)

Date: 2026-11-26. **Status: Approved (owner-delegated 2026-11-26: D6 = owner opt-in per category, default OFF).** Extends [ADR-0008](ADR-0008-cloud-brain-authority-and-identity.md), [ADR-0012](ADR-0012-host-actions.md), [ADR-0018](ADR-0018-power-user-shell-and-direct-fs.md) and [ADR-0019](ADR-0019-draft-workspace-and-effect-bound-approval.md).

## Context

- Currently, physical XUNA board button events for R2 approval (`UDC-12` S12.1: `GPIO0` approve / `GPIO14` reject) and board E-Stop (`RemoteEventCode::Stop` -> `stopPendingActions(reason: 'owner_board')`) are unsigned BLE notification events and have not yet been verified on physical hardware (`HW-BOARD-1`).
- The board already holds an isolated ECDSA P-256 device key (`DeviceKey.h`) and signs canonical `xuna.proof.v1` messages (`DeviceProof.h`), but `ProofService` only accepts `ProofPurpose::Bind (1)`.
- For high-consequence R3 host actions, owners who want hardware two-factor assurance should be able to opt in to requiring a physical confirmation signature from their bound XUNA pet in addition to their phone's P-256 signature — without falling into a "blind signing" trap where a compromised phone could trick the pet into signing an arbitrary digest.

## Decision (Owner-Delegated 2026-11-26: D6)

### 1. Opt-In Per-Category Co-Signing Policy (`D6`, Default OFF)

- Pet cryptographic co-signing is **opt-in per owner and per risk category**, **default OFF** for every category so existing single-device (phone-only) workflows keep working unchanged:
  - `outside_workspace_r3`: `fs.*` / `exec.run` / `capability.run` R3 actions touching outside `workspaceRoots` or secret/system targets
  - `bulk_delete`: destructive delete commands (`exec.run` delete / mass removal)
  - `remote_push`: remote repository push / publish actions
  - `draft_apply`: applying a verified `DraftWorkspace` (`draft.apply`, `xuna.approval.v2`)
- Managed via `GET /v1/actions/cosign-policy` and `PUT /v1/actions/cosign-policy` (owner-authenticated).

### 2. Anti-Blind-Signing `ProofPurpose::Approve (4)` & Matching 6-Digit Code (`F3-M1`, `F3-M2`)

- **New proof purposes** in `xuna.proof.v1` (`DeviceProof.h`, `device_proof.py`, `device_proof_codec.dart`):
  - `ProofPurpose::Approve = 4`
  - `ProofPurpose::Stop = 5`
- **Matching 6-digit short code** (deterministic across C++11 firmware, Python backend, and Dart mobile):
  - `h = SHA-256("xuna.cosign.code.v1\x00" || nonce[32] || targetSha256[32])` (84 bytes)
  - `shortCode = ("%06u" % (be32(h[0..3]) % 1_000_000))`
  - `targetSha256` is the raw 32-byte `effectSha256` when `approval_version == 2`, else `argsSha256` when `approval_version == 1`.
- **Anti-blind-signing invariant on firmware (`ProofService`):**
  - Accepting a 72-byte `Approve` BLE proof request (`ver=1, size=72, purpose=4, reserved=0, requestId u32 LE, nonce[32], targetSha256[32]`) enters `ProofStatus::AwaitingConfirm (7)` and computes `shortCode` locally on the board for screen display.
  - `ProofService::poll(...)` **never signs** while awaiting confirmation. Signing occurs only after an explicit physical button confirmation (`confirmApprove()`), which transitions `AwaitingConfirm -> Pending -> Ok`. Explicit rejection (`rejectApprove()`) transitions to `ProofStatus::Rejected (8)` with zero signature exposed.
  - Signed payload inside `xuna.proof.v1`: `targetSha256[32] || shortCodeAscii[6]` (38 bytes).
- **Phone + Backend dual verification:**
  - When the owner's policy requires co-signing for a pending R3 action, the backend attaches a fresh single-use 32-byte `cosignNonceHex` and `cosignShortCode` to `action_pending`.
  - Mobile recomputes `cosignShortCode` independently (fail-closed if mismatched) and displays it on `HomeActionApprovalSheet` so the owner verifies the code matches the pet's screen before pressing the pet button.
  - `POST /v1/actions/approvals/{approval_id}` verifies **both** the phone P-256 approval signature (`v1` or `v2`) **and** the pet's ECDSA P-256 `ProofPurpose::Approve` signature against the owner's bound active pet device key (`IdentityRepository.list_pets`), checking exact `(petId, nonce, targetSha256, shortCode)` and single-use nonce consumption. Missing, mismatched, forged, unbound, or replayed pet proofs fail closed (`pet_cosign_required`, `pet_cosign_invalid`, `pet_cosign_replayed`).

### 3. Cryptographically Signed Emergency Stop (`ProofPurpose::Stop = 5`, `F3-M3`)

- Firmware `ProofService` supports `ProofPurpose::Stop = 5` (40-byte request or local trigger) signing canonical payload `b"xuna.estop.v1"` (13 bytes) inside `xuna.proof.v1`.
- `POST /v1/actions/stop` accepts an optional `petProof` field (`{petId, nonceHex, generation, signature, publicKey}`).
  - Whenever `petProof` is supplied (or when the owner enables `requireSignedBoardStop` in their co-signing policy for `reason == "owner_board"`), the backend verifies the pet's ECDSA P-256 `ProofPurpose::Stop` signature against the owner's bound active pet key and enforces single-use nonce replay protection (`pet_stop_proof_required`, `pet_stop_proof_invalid`, `pet_stop_proof_replayed`).
  - Audit event `host.stopped` records `petSigned: bool` (and `petId` when verified).
- **Emergency stop remains immediate:** signing a `Stop` proof on the board does not require a secondary 6-digit code match step.

## Honest Limitations (Rule H6 / H8)

1. **Phone-relay requirement for board E-Stop:** Until direct device-to-cloud transport (`ADR-0010` / E14) carries action control, pet-initiated E-Stop and pet co-signing require the mobile app to be connected to the board over BLE and reachable to the backend.
2. **Physical hardware validation pending (`F3-M0` / `HW-BOARD-1`):** Firmware C++11 core logic, cross-repo golden vectors, backend dual verification, and mobile codec/UI are implemented and host-tested on Windows; flashing the physical ESP32-S3 board and live board+phone testing require explicit owner confirmation and physical hardware.
3. **E-Stop scope:** Matches `desktop/AGENTS.md` §3.5 — `emergency_stop` sends `xuna/stop` to active hosts, cancels pending approvals/jobs, and suspends `R2+` grants across all hosts (or the targeted `hostId`); `R1` grants (`media`) stay unsuspended per D2.

## Consequences

- `firmware/lib/xuna_core/include/xuna/identity/DeviceProof.h` stays pure C++11 (`check_core_purity.py` + `-Wall -Wextra -Werror`) and 100% backward-compatible for `Bind (1)` frames.
- `mobile/pubspec.yaml` and `pubspec.lock` stay at `0` diff (reusing existing `crypto` package).
- No new database migration is required for initial opt-in co-signing policy store (`InMemoryCosignPolicyStore` + `InMemoryProofNonceStore`, extensible via repository port).

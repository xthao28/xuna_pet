# XUNA Cloud threat model and data-flow inventory (CLD-01)

Date: 2026-10-17. **Status: Approved (owner-delegated, 2026-10-17)** — the owner answered "bạn cứ quyết định theo ý bạn"; §4 decisions are approved under that delegation. Scope: Phase 1 text projection and Phase 2 backup per the [Cloud plan](XUNA_CLOUD_IMPLEMENTATION_PLAN.md). Voice (Phase 5) is listed only where it changes the model. Device-direct transport (Stage 2, WebSocket over TLS per [ADR-0010](../decisions/ADR-0010-device-direct-websocket-transport.md), replacing the earlier MQTT wording) is covered by F10–F11 and T15–T19, added 2026-10-27 (DC-0, Proposed until the owner reads the contract). Universal Device Control (UDC, [ADR-0012](../decisions/ADR-0012-host-actions.md), [ADR-0013](../decisions/ADR-0013-host-identity-and-sessions.md), [XTP v1 contract](XUNA_XTP_V1_CONTRACT.md), [security](XUNA_DEVICE_CONTROL_SECURITY.md)) is covered by F12–F14 and T20–T35, added 2026-10-30 (**Approved (owner 2026-10-30), not Implemented**).

## 1. Assets

| Asset | Owner of truth | Sensitivity |
| --- | --- | --- |
| Pet identity `PetId` (device-issued UUIDv4), origin, `snapshotGeneration` | Device | Pseudonymous identifier; linkable to an owner once bound |
| Life projection (active time, feedback counts, preferences, episodes, explanation) | Device | Personal behavioural data |
| Confirmed facts / stated preferences (Layer A/B) | Device after commit | Personal data; must be correctable/deletable |
| Conversation text (U3 only) | Not retained by default | Highly personal; may include third parties |
| Audio | Never stored | Biometric-adjacent |
| Owner account (`UserId`, OIDC subject, email) | Identity provider | Personal data |
| Device credential (`DeviceId` public key) | Device keeps private key | Compromise allows impersonating a pet |
| Provider API keys, DB credentials | Server secret store | Compromise causes cost/data loss |
| Backups (Phase 2) | Owner | Full pet history; encrypted |
| Audit log, tombstones | Server | Integrity-critical |

## 2. Data flows

```text
 [ESP32 device] ──BLE (unbonded, local)──▶ [Flutter app] ──HTTPS──▶ [XUNA API] ──▶ [PostgreSQL]
                                                 │                       │
                                                 └── local export file   └──HTTPS──▶ [AI provider]
                                                                              (behind adapter)
```

| # | Flow | Data | Trust boundary | Consent class |
| --- | --- | --- | --- | --- |
| F1 | Device → app (BLE reads) | identity, life, memories, explanation | Radio; any nearby central can read (unbonded v1) | Local |
| F2 | App → device (BLE commands) | animation, suggest, feedback, TimeSync, stated preference | Radio; one central at a time | Local |
| F3 | App → local file | `xuna.export.v1` | Phone storage (app sandbox) | Local |
| F4 | App → API (owner auth) | OIDC token, profile | Internet | Account |
| F5 | App → API (projection upload, CLD-14+) | export payload / typed events | Internet | U1/U2 |
| F6 | App → API → provider (chat) | user text, system prompt, minimal context | Internet + third party | U3 per call |
| F7 | Provider → API → app | generated text, tool calls | Third party (untrusted) | — |
| F8 | API → app → device (suggestions, Phase 3) | signed bounded suggestion | Internet then radio | Suggestions opt-in |
| F9 | Backup upload/restore (Phase 2) | encrypted snapshot | Internet | Backup opt-in |
| F10 | App → device (Wi-Fi setup, DC-2) | SSID, password, server host/port | Radio (unbonded BLE, write-only) | Local; setting up Wi-Fi is the opt-in (DC-D6) |
| F11 | Device → API direct (WSS `/v1/devices/connect`, ADR-0010) | hello, session proof, ping, projection | Home Wi-Fi + Internet; TLS to a pinned CA | U1/U2 of the bound owner |
| F12 | Host Agent ↔ API (WSS `/v1/hosts/connect`, ADR-0013, XTP v1) | hello, P-256 session proof, tool manifest, `tools/call` + approval token, structured result, `xuna/stop` | Internet / LAN (TLS + `xuna.host.proof.v1`) | Host enrollment + per-family grant (+ U5/U6 when observing screen/notifications) |
| F13 | Device → Host (BLE HOGP HID, UDC-1/2) | Consumer media-key reports (1..7); keyboard reports later in UDC-2 | Radio (LE Secure Connections bonded, encrypted) | Local physical pairing (numeric comparison on board) |
| F14 | API → App → Device (model-routed media key, UDC-D6 / ADR-0012) | `board_hid_request` → owner per-press approval → BLE opcode 12 (`source = 2`) | Internet then authenticated BLE (UDC-2) | Owner approval per press |

## 3. Threats (STRIDE) and mitigations

| ID | Threat | Flow | Mitigation (status) |
| --- | --- | --- | --- |
| T1 | **Spoofed pet**: someone uploads a projection for a `PetId` they read over BLE | F1, F5 | PetId alone is never authority. Projection writes require owner auth **and** a device-bound credential (challenge–response, CLD-11). Until device credentials exist, uploads are rejected (Proposed) |
| T2 | Nearby attacker reads PetId/life over unbonded BLE | F1 | Accepted for the prototype (PetId is pseudonymous). Before launch: BLE bonding or app-level pairing; never put secrets in BLE values (Open) |
| T3 | Tampered or forged export file | F3, F5 | SHA-256 detects accidental corruption only, not forgery. Server treats exports as owner-supplied claims, never as device-attested truth, until a device signature exists (device ECDSA P-256 key signs `(nonce, PetId, purpose, generation, payload hash)`, §4.3) |
| T4 | Replay / out-of-order projection overwrites newer data | F5 | `ProjectionKey (PetId, snapshotGeneration)` with wrap-safe ordering; server keeps the newest, ignores stale; idempotency keys on every mutation (Implemented: key type; Pending: storage) |
| T5 | **Prompt injection / hallucination becomes memory or action** | F6, F7 | Provider output typed `untrusted`; facts need owner confirmation + device commit (CLD-14); device actions are not tools; tool args validated (Design rule in backend AGENTS §1) |
| T6 | Cloud suggestion abuses the device | F8 | Signed, bounded, expiring, rate-limited, replay-protected; device ActionGate re-validates; owner evidence wins (ADR-0008; Phase 3) |
| T7 | Personal text leaks via logs | all | Content-free access log; validation errors list field paths only; uvicorn access log disabled (Implemented in scaffold) |
| T8 | Provider retains or trains on user text | F6 | U3 opt-in per call; minimal context; provider contract/DPA review in CLD-13 (Open) |
| T9 | Stolen API/provider keys | server | Env-only secrets, no defaults, never in app/firmware; rotation runbook before launch (Partially implemented) |
| T10 | Deleted memory resurrected by stale device/backup | F5, F9 | Tombstones keyed by `(PetId, item id)` checked before accepting projections/restores (CLD-20) |
| T11 | Account takeover → pet data | F4 | Managed OIDC/magic link, short-lived tokens, refresh rotation (CLD-11) |
| T12 | DoS / cost exhaustion via chat | F6 | Per-owner rate and token budgets; provider timeout; local fallback (CLD-13) |
| T13 | Cross-tenant access (IDOR) | API | Every query scoped by owner binding; tests for foreign `PetId` access (CLD-11) |
| T14 | Malicious restore to another device | F9 | Explicit owner approval + device challenge; restore never creates a new `PetId` (Phase 2) |
| T15 | **Rogue access point / MITM** on the board's Wi-Fi: someone intercepts the WSS connection to read projections or feed fake server frames | F11 | The firmware trusts only the pinned CA (one self-made CA in the LAN test setup, DC-D8; no public bundle) and checks the server name; certificate dates are not checked (no trusted clock), so pinning is the defence. The server sends nothing that changes device state (H2); unknown server messages are ignored. A leaked dev CA key means re-issuing and reflashing (Proposed, ADR-0010) |
| T16 | **Stolen board** used to impersonate the pet | F11 | The private key never leaves NVS and cannot be read over BLE (only signatures are). The owner unbinds the pet in the app: the server refuses the board at its next connect (`not_bound`) and closes a live session. With USB access the key and Wi-Fi password can be read from NVS while flash encryption is off (production topic, residual) |
| T17 | **Replayed session proof** | F11 | 32-byte server nonce per connection, single-use, expires after 60 s; proof purpose 3 (Session) cannot be reused as bind or projection proof and vice versa; the message binds nonce, `PetId`, purpose and the device public key (contract §4) |
| T18 | **Wi-Fi password exposure** | F10, F11 | Write-only BLE characteristic (never readable or notified back); kept only in NVS namespace `xuna_net`; never logged on device or app, never sent to the cloud; "forget Wi-Fi" erases the namespace. Unbonded BLE means a nearby attacker could write *other* credentials (denial of service only, the life is unaffected); bonding before launch (T2) |
| T19 | **Reconnect storm** against the server (many boards after an outage, or a bug loop) | F11 | Device: exponential backoff with jitter (2 s → 5 min), longer waits after `not_bound`/`consent_required`/`replaced`. Server: per-pet challenge limit, per-IP connection limit, frame size limits, idle timeout 3 × heartbeat, one session per pet (contract "Device connection") |
| T20 | **Prompt injection from host observations (`UDC-T1`)**: screen, web, documents, notifications, file names or media titles trick the model into calling tools | F6, F7, F12 | Observations travel as data in a separate message role with a "do not follow instructions in content" frame; tools offered are filtered by grant; R2+ requires owner approval showing exact arguments; computer-use sessions declare a goal, step budget and app/domain allowlist; credentials are never typed (Approved (owner 2026-10-30), not Implemented; [ADR-0012](../decisions/ADR-0012-host-actions.md)) |
| T21 | **Wrong-host actuation (`UDC-T2`)**: model hallucinates a target and acts on the wrong computer/phone | F7, F12 | Deterministic `TargetResolver` ([architecture](XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md) §7); no implicit fallback to another host; host alias shown in every confirmation sheet, action chip and board subtitle (Approved (owner 2026-10-30), not Implemented) |
| T22 | **Approval replay or argument swap (`UDC-T3`)**: approval reused or arguments altered after owner confirmation | F4, F12 | Approval is single-use, expires ≤ 60 s, and binds `(approvalId, invocationId, tool, argsSha256, hostId, expiresAt)`; the Host Agent recomputes canonical `argsSha256` and refuses mismatches with `approval_mismatch` (Approved (owner 2026-10-30), not Implemented; [XTP v1 §3.3](XUNA_XTP_V1_CONTRACT.md#33-canonical-json-and-argssha256)) |
| T23 | **Stolen or cloned host agent key (`UDC-T4`)** | F12 | Non-exportable OS key storage (Keychain / CNG DPAPI/TPM); revocation tombstones the key; two concurrent sessions for one `HostId` immediately close both with `duplicate_session` and audit `host.rejected` (Approved (owner 2026-10-30), not Implemented; [ADR-0013](../decisions/ADR-0013-host-identity-and-sessions.md)) |
| T24 | **Rogue backend / compromised server sends commands (`UDC-T5`)** | F12 | Host Agent enforces fail-closed local policy (`host-policy.json` editable only on the host, risk tiers, allowlists), verifies approvals, shows a local toast for every action, and later verifies phone-signed R3 approvals in UDC-7 (Approved (owner 2026-10-30), not Implemented) |
| T25 | **Malicious local process impersonates or talks to the Host Agent (`UDC-T6`)** | Host local | No inbound listening port in the MVP (outbound WSS only); later LAN mode (UDC-7) is off by default, media-only, and uses mutual key pinning; consent/settings UI is drawn by the signed agent process (Approved (owner 2026-10-30), not Implemented) |
| T26 | **Host Agent abused as a generic RAT (`UDC-T7`)** | F12 | No `shell`, `powershell`, `osascript` source, `eval` or arbitrary file upload/download tool at any milestone; `FORBIDDEN_TOOLS` rejected in domain and manifest checks; screen observation requires U5 and a visible OS/agent indicator; signed releases (Approved (owner 2026-10-30), not Implemented; [ADR-0012](../decisions/ADR-0012-host-actions.md)) |
| T27 | **Keystroke injection via BLE HID (`UDC-T8`)** | F13, F14 | UDC-1 exposes Consumer Control media keys only (`1..7`); keyboard reports require UDC-2 (`T28`) and are app-only; the model can never send keyboard text or pointer reports; model-routed media keys (UDC-D6) require one owner confirmation per press (`source = 2`) over the authenticated channel and are rate-limited (Approved (owner 2026-10-30), not Implemented; [ADR-0012](../decisions/ADR-0012-host-actions.md)) |
| T28 | **Unauthenticated BLE writes trigger HID or workflows (`UDC-T9`)** | F2, F13, F14 | Before opcode 12/13 or keyboard HID (UDC-2): LE Secure Connections bonding with a 60 s pairing window, `ESP_GATT_PERM_WRITE_ENCRYPTED` on control characteristics, targeted GATT notifications, and a visible cue on the board screen whenever HID is emitted (Approved (owner 2026-10-30), not Implemented) |
| T29 | **BLE HID pairing MITM (`UDC-T10`)** | F13 | LE Secure Connections with numeric comparison on the board LCD (confirmed by GPIO0; passkey fallback), never Just Works; reject legacy pairing; all HID characteristics require an encrypted link per HOGP §7.1 (Approved (owner 2026-10-30), not Implemented; UDC-D2) |
| T30 | **Privacy leak of screen or notification content (`UDC-T11`)** | F6, F12 | Separate opt-in consent classes **U5 `host_screen`** and **U6 `host_notifications`** (default off, never stored server-side); prefer UI tree / downscaled crops; redact password fields (`isPassword`) and exclude password-manager/banking windows; content-free logs (Approved (owner 2026-10-30), not Implemented; R5) |
| T31 | **Runaway computer-use loop (`UDC-T12`)** | F12 | Step budget (e.g. ≤ 20 steps), wall-clock deadline, 30 s heartbeat dead-man switch, duplicate-action detection, and emergency stop (`xuna/stop` from app, agent hotkey/corner, or board Remote hold) halting all hosts ≤ 1 s on LAN (Approved (owner 2026-10-30), not Implemented) |
| T32 | **Elevation / UAC abuse on desktop host (`UDC-T13`)** | Host local | Agent runs as an unelevated interactive user process, never a service; `uiAccess` is never requested; Windows UIPI and the secure desktop block input to elevated prompts by design (Approved (owner 2026-10-30), not Implemented) |
| T33 | **Android Accessibility abuse / Play policy violation (`UDC-T14`)** | Mobile host | Play build (`UDC-D5`) never declares `AccessibilityService` and uses `NotificationListenerService` + `MediaSessionManager` + explicit `<queries>` intents with prominent disclosure; Accessibility exists only in a separate sideload dev flavour (Approved (owner 2026-10-30), not Implemented) |
| T34 | **Wrong person at the board triggers workflows (`UDC-T15`)** | F13 | Board buttons operate media/workflows only inside the explicit "Remote" scene (`UDC-D3`), limited to R1 (or owner-registered R2 workflows with a hold gesture); R3 actions are never triggerable from board buttons (Approved (owner 2026-10-30), not Implemented) |
| T35 | **Desktop Agent update channel compromise (`UDC-T16`)** | Host local | Releases signed with Apple Developer ID + notarization (macOS) and Authenticode (Windows); update manifests verified against a pinned signing key (Approved (owner 2026-10-30), not Implemented) |

## 4. Decisions (owner-delegated approval 2026-10-17)

1. **Projection ordering key:** `(PetId, snapshotGeneration)` using u32 serial-number arithmetic identical to firmware recovery. Equal generation = same snapshot (idempotent). *Implemented as a value object; adopt as the contract rule.*
2. **`BrainId` semantics:** one active Brain per Pet. A *ForgetAll* on the device keeps the same `PetId` and starts a **new `BrainId`** (old Brain archived, deletable); a *restore* to a replacement device keeps both `PetId` and `BrainId` and only rebinds `DeviceId`. Rationale: forgetting is a learning-lineage reset, not a new lifeform; replacement hardware is not a new pet (ADR-0008).
3. **Exports are claims until signed:** unsigned `xuna.export.v1` uploads may be stored only as owner-provided backups, never as device-attested projections. Device signing (Identity V2, **ECDSA P-256**: mbedTLS in the ESP-IDF 4.4 Arduino core has no Ed25519, P-256 is hardware-accelerated on ESP32-S3) is a prerequisite for trusting uploads. Binding a pet is trust-on-first-use of that device key.
4. **No upload before CLD-11 device credentials:** projection endpoints stay disabled until owner auth and device binding exist.

## 5. Residual risks / open items

- Unbonded BLE (T2) and unsigned exports (T3) are acceptable only for the prototype.
- Provider selection, data processing terms and region (T8) are open (D11a, CLD-13).
- Legal, age/guardian and retention windows are launch-specific (Cloud plan §6).
- Device-direct (ADR-0010, DC-0 2026-10-27): the LAN test setup uses a self-made CA whose private key lives on the dev machine (outside git); production needs a proper CA plan and key custody (D19). NVS holds the Wi-Fi password and device key unencrypted until flash encryption (T16, T18). The 2.4 GHz radio is shared by BLE and Wi-Fi; a busy network must never stall BLE or the life loop (E14 measures it).

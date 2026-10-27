# XUNA Cloud threat model and data-flow inventory (CLD-01)

Date: 2026-10-17. **Status: Approved (owner-delegated, 2026-10-17)** — the owner answered "bạn cứ quyết định theo ý bạn"; §4 decisions are approved under that delegation. Scope: Phase 1 text projection and Phase 2 backup per the [Cloud plan](XUNA_CLOUD_IMPLEMENTATION_PLAN.md). Voice (Phase 5) is listed only where it changes the model. Device-direct transport (Stage 2, WebSocket over TLS per [ADR-0010](../decisions/ADR-0010-device-direct-websocket-transport.md), replacing the earlier MQTT wording) is covered by F10–F11 and T15–T19, added 2026-10-27 (DC-0, Proposed until the owner reads the contract).

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

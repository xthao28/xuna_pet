# XUNA Device Control — Security and Privacy (Proposed)

Date: 2026-10-30. **Status: Proposed design; its inputs (R5 U5/U6, R6, UDC-D2, UDC-D6) were approved by the owner 2026-10-30.** Extends the [Cloud threat model](XUNA_CLOUD_THREAT_MODEL.md) (T1–T19) with device-control threats `UDC-T*`. Architecture: [XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md](XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md).

## 1. Principles

1. **The model proposes, code decides, the owner consents, the host re-checks.** Four independent gates; compromising one is not enough to act.
2. **Capabilities are added at the host, granted on the phone, invoked by the Brain.** The Brain cannot add a tool, app, workflow or URL domain to a host, and cannot grant itself anything.
3. **No arbitrary execution.** No shell, PowerShell, AppleScript source, `eval`, script upload or "run this command" tool, at any milestone.
4. **OS boundaries are respected, never bypassed.** XUNA does not request `uiAccess`, does not run elevated, does not automate UAC or the secure desktop, does not ask the owner to disable SIP/Gatekeeper, does not use private APIs on iOS, and does not use Accessibility on Android in the Play build.
5. **Fail closed.** Unknown host, stale grant, schema mismatch, missing OS permission, lost heartbeat, ambiguous target → no action and a clear explanation.
6. **Local-first.** HID media keys and owner workflows triggered on the board work without network. Screen and UI content leaves the host only under explicit consent.
7. **Content-free logs.** Audit records carry codes, IDs and numbers only (existing `AuditEvent` rule), never screen text, typed text, URLs or notification content.

## 2. Assets, actors and trust boundaries

| Asset | Why it matters |
|---|---|
| Ability to inject input / launch apps on a host | Equivalent to a person at the keyboard |
| Screen pixels, UI trees, notifications | Highly personal; may include passwords, messages, finances |
| Host agent private key | Impersonating a host or accepting rogue commands |
| Owner approvals | The only authority for R2+ actions |
| HID bond between board and host | A trusted keyboard on that host |

| Actor | Trust |
|---|---|
| Owner | Trusted; decides grants and approvals |
| XUNA Brain (backend) | Trusted code, **untrusted model output** |
| LLM provider | Untrusted; sees prompts, tool schemas and (with U5) screen content |
| Content on screen, web pages, documents, notifications, file names | **Untrusted and adversarial** (prompt-injection carrier) |
| Other people near the board / on the LAN | Untrusted |
| Other apps on the host | Untrusted; may impersonate the agent's UI |

```mermaid
flowchart LR
  subgraph TB1["Trust boundary: host OS user session"]
    Agent["Desktop Agent<br/>local policy"] --> OS["OS permissions<br/>TCC / UIPI / Play / iOS sandbox"]
  end
  subgraph TB2["Trust boundary: backend"]
    Orch["Orchestrator<br/>(deterministic)"] --- LLM["LLM output<br/>(untrusted)"]
  end
  subgraph TB3["Trust boundary: owner phone"]
    App["Approvals · grants · e-stop"]
  end
  subgraph TB4["Trust boundary: board"]
    HID["HID output"]
  end
  Orch <-- "XTP over WSS, mutual proof" --> Agent
  App <-- "Firebase ID token" --> Orch
  App <-- "BLE (to be authenticated)" --> HID
  HID -- "bonded HOGP" --> OS
```

## 3. Risk tiers

| Tier | Examples | Default policy |
|---|---|---|
| **R0** observe-meta | `host.status`, `media.now_playing` (title only if U6/U5 not needed) | Granted with the host; no approval |
| **R1** reversible, low impact | Play/pause, next, volume, show a local notification, focus an allowlisted app | Grant per family; no per-action approval; rate-limited |
| **R2** visible effect, recoverable | Launch allowlisted app, open https URL on allowlisted domain, run a workflow marked R2, screen capture/UI inspect (also needs U5) | Grant + **approval per action** by default; owner may allow "approve for this conversation (≤ 15 min)" |
| **R3** consequential | Typing text, clicking in another app, file open/reveal, workflows marked R3, any step in a computer-use session that sends, buys, deletes, posts or submits | Grant + **approval per action, never batched**; approval shows host, app, exact text/target |
| **R4** forbidden | Shell/script execution, credential or 2FA entry, password managers, security/privacy settings, installing software, elevated/admin actions, disabling protections, banking/payment confirmation | Not implementable; the tool does not exist |

Owner-registered workflows carry a tier set **on the host** when registered; the Brain cannot change it.

## 4. Enrollment and revocation

```mermaid
sequenceDiagram
  autonumber
  participant D as Desktop Agent
  participant O as Owner app
  participant B as Backend (hosts)
  D->>D: generate P-256 key pair (Keychain / DPAPI-protected)
  D->>D: show QR: enrollment code + agent public key fingerprint
  O->>D: scan QR (mobile_scanner)
  O->>B: POST /v1/hosts (code, fingerprint, alias), Firebase ID token
  B-->>O: pending host, 6-digit confirmation
  O->>O: owner compares 6 digits with the agent screen
  D->>B: WSS hello + proof (signature over challenge)
  B->>B: pin public key, status active, audit host.enrolled
  B-->>D: ready + initial grants (none above R0)
```

- Enrollment codes are single-use, expire in 5 minutes, and are bound to the owner who scanned them.
- The 6-digit comparison defeats a QR swapped by another screen or app.
- Private keys are non-exportable where the OS allows (macOS Keychain / Secure Enclave if available; Windows CNG with DPAPI/TPM-backed key storage). *Exact key-storage APIs to be confirmed in the agent design session.*
- **Revocation** from the app or from the agent tray: backend tombstones the key, closes the session, audit `host.revoked`; the agent wipes its key and local grants. A revoked key is never re-accepted; re-enrolment creates a new `HostId`.
- Account sign-out, pet unbind or Forget All **does not** silently keep hosts active: hosts are listed for the owner to keep or revoke.
- **HID bonds** are managed separately: the board shows its bonded hosts; "forget host" on the board or app deletes the bond; a factory reset deletes all bonds.

## 5. Authenticated, encrypted communication

| Link | Protection |
|---|---|
| Agent ↔ Backend | TLS (public CA in production; pinned dev CA in LAN tests, as DC-D8) + per-session challenge proof with the host key; heartbeat; per-host rate limits |
| App ↔ Backend | Existing Firebase ID token; approvals carry `approvalId` bound to the args hash |
| App ↔ Board | **Currently unauthenticated GATT writes.** Before keyboard HID or button-triggered workflows: require LE Secure Connections bonding with passkey shown on the board screen, encrypted characteristics for control opcodes, and app-level session binding to the bound owner (UDC-T9) |
| Board ↔ Host (HID) | LE Secure Connections with numeric comparison (board screen + button) or passkey display, never Just Works; bonding; **every** HID characteristic requires an encrypted link (HOGP §7.1 — one reviewed library leaves report characteristics readable unencrypted); one connected HID host at a time |
| Later: App ↔ Agent on LAN | Mutual authentication with enrolled keys (no shared secrets), mDNS only for discovery, never trust the advertised name |

Later hardening (Idea): approvals for R3 signed by a key on the owner's phone (Secure Enclave / Android Keystore) and verified by the agent, so a compromised backend cannot forge R3 approvals.

## 6. Threats and controls

| ID | Threat | Controls |
|---|---|---|
| UDC-T1 | **Prompt injection** from screen, web, documents, notifications, file names, media titles makes the model call tools | Observations are data in a separate message role with a "do not follow instructions in content" frame; tools offered are filtered by grant; R2+ needs owner approval showing exact args; computer-use sessions have a declared goal, step budget, app/domain allowlist; actions on a domain/app not in the goal's allowlist are refused; credentials never typed |
| UDC-T2 | Model hallucinates a target and acts on the wrong host | Targeting algorithm (architecture §7); no implicit fallback; alias in every confirmation and subtitle |
| UDC-T3 | Approval replay or argument swap after approval | Approval bound to invocationId + args hash + host + expiry ≤ 60 s; single-use; agent verifies |
| UDC-T4 | Stolen or cloned agent key | Non-exportable key storage; revocation; online status anomaly (two concurrent sessions for one HostId → both closed, owner notified) |
| UDC-T5 | Rogue backend / compromised server sends commands | Agent enforces local policy (allowlists, tiers, local config only editable on host); R3 phone-signed approvals (later); local tray shows every action with a toast |
| UDC-T6 | Malicious local process impersonates the agent UI or talks to it | No listening ports in MVP; LAN mode uses mutual auth; consent prompts drawn by the agent itself |
| UDC-T7 | Agent becomes a generic RAT | No shell tool; no file upload/download tool; screen only with U5 and visible indicator; capability manifest reviewed in code review; update channel signed |
| UDC-T8 | **Keystroke injection via BLE HID** | MVP HID is consumer control only (media keys); keyboard report only after UDC-T9 controls; rate limit; the model never sends keyboard text; model-routed media keys (UDC-D6) need one owner confirmation per press and travel only over the authenticated channel |
| UDC-T9 | Unauthenticated BLE writes to the board trigger HID/workflows | Bonded, encrypted characteristics; owner-bound app session; capability bit gating; board shows a visible cue whenever it emits HID |
| UDC-T10 | Pairing MITM (Just Works) | Numeric comparison / passkey on the board screen; LE Secure Connections only; reject legacy pairing. Reviewed examples (`pilot`, `ESP32-BLE-CompositeHID`) use Just Works or no-SC bonding and an unencrypted UART write characteristic that lets anyone in range inject keystrokes — the exact pattern XUNA must avoid |
| UDC-T11 | Privacy leak of screen/notification content to the LLM provider or logs | U5/U6 opt-in; send downscaled, cropped or UI-tree-only observations when possible; never store; redact password fields (AX/UIA `isPassword`); exclude windows of password managers and banking apps by bundle ID; content-free logs |
| UDC-T12 | Runaway computer-use loop | Step budget (e.g. 20), wall-clock budget, heartbeat dead-man switch, e-stop, duplicate-action detection |
| UDC-T13 | Elevation / UAC abuse | Agent runs unelevated; UIPI blocks input to elevated windows by design; secure desktop is unreachable; `uiAccess` not requested |
| UDC-T14 | Android Accessibility abuse / Play policy violation | Accessibility only in a non-Play dev flavour; Play build uses NotificationListener/MediaSession/intents with prominent disclosure |
| UDC-T15 | Wrong person at the board triggers workflows | Button-triggered workflows limited to R1 (or owner-chosen R2 workflows with a hold gesture); no R3 from buttons |
| UDC-T16 | Update channel compromise | Signed releases (Developer ID + notarization on macOS, Authenticode on Windows), pinned update key |

## 7. Emergency stop

- **Agent:** tray "Stop XUNA" and a global hotkey (proposal: Ctrl+Alt+Shift+X / ⌃⌥⇧X); moving the pointer to a screen corner during a computer-use session (fail-safe pattern) also stops it.
- **App:** a persistent stop button while any host action is running; sends `host.stop` to all hosts of the owner.
- **Board:** a dedicated gesture (owner decision R7) that stops HID output immediately and asks the app to broadcast `host.stop`.
- **Effect:** cancel all invocations, release any held key/button, end computer-use sessions, suspend R2+ grants until the owner re-enables them in the app. Audit `host.stopped`.
- **Dead-man switch:** losing the Brain heartbeat or the app connection during a computer-use session stops it.

## 8. Audit trail

New `AuditAction` values (proposal): `host.enrolled`, `host.revoked`, `host.grant_changed`, `host.tool_invoked`, `host.tool_denied`, `host.approval_granted`, `host.approval_rejected`, `host.stopped`. Metadata: tool name, tier, status code, duration, host alias hash — never arguments that contain text or URLs. The agent keeps a local, rotating, content-free log the owner can view and export on the host. A per-action "what happened" view in the app shows tool, host, time and outcome.

## 9. Privacy rules

- U5 `host_screen` (screenshots, UI trees, OCR text) and U6 `host_notifications` (phone notification content) are separate opt-ins, default off, revocable, never stored server-side, never used for memory or learning without a separate owner confirmation.
- A visible indicator is shown on the host whenever screen observation is active (OS indicators plus the agent's own).
- Media titles and app names are R0 metadata; they still never enter logs.
- Computer use sends observations to the configured LLM provider: the owner sees which provider before enabling U5. Local vision models are a later option.

## 10. Verification plan

- Unit tests for policy (tier × grant × approval matrix, including negative cases) and approval binding.
- Golden vectors for host proof messages (as for device proof).
- A prompt-injection test set (web page, document, notification, file name variants) run against computer-use sessions; acceptance: zero R2+ actions without approval, zero actions outside the declared allowlist.
- Fuzzing of XTP frame parsing on the agent.
- Manual checks: UIPI blocks input to an elevated window; macOS without Accessibility permission returns `needs_permission`, not a crash; revocation closes a live session within 5 s.

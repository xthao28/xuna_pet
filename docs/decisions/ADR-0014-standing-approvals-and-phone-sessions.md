# ADR-0014 — Standing approvals and phone control sessions

Date: 2026-11-06. **Status: Approved (owner delegation 2026-11-06). D1 partly Implemented in `backend/` and `mobile/` and host-verified (2026-11-06, no device run yet); D2 not Implemented.** D1 clauses **not** met yet: 5 ("the host re-validates" holds, but "rate limits apply" has no dedicated limiter; only the per-round call cap and turn budget exist), 4 ("the host verifies the signature like an R3 approval": only the backend verifies it). Clause 3's use limit and lifetime are fixed by the app (7 days, unlimited uses) although the API supports both. Amends [ADR-0012](ADR-0012-host-actions.md) decision 1 (the `owner approval (R2+)` pipeline step) and [device-control README §1.7](../roadmap/device-control/README.md) item 5. Plan: [UDC-16](../roadmap/device-control/UDC-16-permission-hub.md) parts C and D.

The owner was asked to decide D1 (standing approvals) and D2 (phone sessions) and answered "cứ làm theo ý bạn" and then "oke tiếp đi", delegating both to the recommendations in UDC-16 §11. **Implementation of part D is additionally gated on device evidence** (see Consequences), because the case for it is the number of prompts a real task produces.

## Context

- ADR-0012 requires, for every R2+ host action, an owner approval bound to its arguments. R3 is approved per action, never batched, phone-signed.
- The owner finds repeated prompts annoying. Parts A and B of UDC-16 remove the OS-permission and grant prompts without touching this rule. What remains is per-action approval: R2 (launch an app, open a link) and R3 (every `ui.act`).
- A phone task such as "open an app, search, tap a result" is 5–10 actions, so one R2 observation plus one R3 approval per `ui.act`.
- The desktop already has a session model for this: [UDC-8](../roadmap/device-control/UDC-8-computer-use.md) (one phone-signed approval for a declared goal, an app allowlist, step and time budgets, a dead-man heartbeat; navigation inside is R2, consequential steps stay R3).

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. Keep per-action approval everywhere** | No change to any invariant | Multi-step phone control needs many prompts; the owner will not use it |
| **B. "Always allow" per tool** | Fewest prompts | A blank cheque: any argument, indefinitely. Rejected |
| **C. Pre-issued approvals bound to exact arguments (D1) + sessions for multi-step control (D2)** | Fewer prompts while every approval stays the owner's, bound to arguments, host, expiry and a budget | New mechanisms to build and test |

## Decision

**Option C.**

### D1 — Standing approvals

A **standing approval** is an owner approval given in advance instead of at the moment of use. It satisfies ADR-0012's `owner approval (R2+)` step for a matching call and for nothing else.

1. **Eligible only if** the tool is **R2**, does not `observe`, and **every** argument is pinned to an exact value in the approval. Pinned values are exact (an allowlisted `app_id`, an exact package). No free text, no regex, no wildcard, no "any".
2. **Never** for R3, for any tool that types text, taps, long-presses, swipes or reads screen or notification content, and never for a tool whose arguments are not all pinned.
3. **Shape:** `(hostId, tool, pinned arguments, expiresAt, optional maxUses)`. Default lifetime 7 days, maximum 30. Revocable at any time from the Permission Hub.
4. **Created only by an owner action on the phone** that shows the exact tool and arguments, and **signed with the enrolled phone key** (purpose `xuna.preapproval.v1`, separate from `xuna.approval.v1`) so a compromised backend cannot mint one. The host verifies the signature like an R3 approval.
5. **Always enforced on top:** the host grant must still allow the tool, the host re-validates arguments locally, "Tạm khoá tất cả" and E-Stop suspend every standing approval until the owner re-enables them, and rate limits apply.
6. **Audit (content-free):** `host.preapproval_created`, `host.preapproval_used`, `host.preapproval_revoked`.
7. **Bond level never changes** which approvals apply (same rule as UDC-9 §130).

### D2 — Phone control sessions

Extend the UDC-8 session model to the Android host, **dev build only**.

1. **One phone-signed R3 approval per session**: `cu.session_start {goal ≤ 200, apps[] (package ids), maxSteps ≤ 20, maxMinutes ≤ 10}`. The goal and `apps[]` are fixed at start and cannot change mid-session. The approval sheet shows the goal and the app names.
2. Inside a session, `ui.observe` and `ui.wait_for` need no per-call approval, and `ui.act` needs none **only** when all hold:
   - the foreground package is in `apps[]`;
   - the action type is `activate`, `scroll`, `swipe`, `long_press` or a global key;
   - the host adapter classifies the specific element as non-consequential.
3. **Still R3 per action, never skipped:** `set_text` (shows the exact text and the field), and any `activate` or `long_press` that the host adapter classifies as consequential (send, submit, delete, buy, pay, post, confirm, and their Vietnamese equivalents) **or cannot classify**. The classification lives in the Android host adapter (honest-code H5), is a fail-closed default (unknown means R3), and is reported to the orchestrator before the action runs.
4. **Unchanged and mandatory:** hard-denied packages, sensitive-field redaction and refusal, XUNA never acts on itself, label verification (`target_mismatch`), E-Stop, a visible persistent notification while a session is active, content-free logs, and the Play rule below.
5. **Stops:** step or time budget reached; three consecutive `no_visible_change`; the same action on the same element twice; heartbeat lost (the app posts `POST /v1/actions/sessions/{id}/heartbeat` every 5 s, three misses stop it); the owner presses Stop.
6. **Not in the `play` build.** Play policy forbids autonomous AI control through Accessibility ([UDC-5 §5.4](../roadmap/device-control/UDC-5-android.md)); the `play` APK still contains no Accessibility service (existing CI check).

### What does not change

R3 is never batched or scoped **outside** a session and stays phone-signed. No shell, eval, raw keyboard or pointer tools. The model never sees approval tokens. Logs stay content-free. ADR-0012 options A and B stay rejected.

## Consequences

- **Backend:** `host_preapprovals` table and routes, an approval resolver that accepts a matching standing approval, Android session support in the UDC-8 session loop, three audit actions, migration, tests (pattern must match exactly; R3 and free-text tools refused at creation; expiry, revoke, E-Stop and suspend each stop use; an out-of-pattern call still prompts; a session never exceeds its `apps[]`, budgets or heartbeat).
- **Mobile:** creation sheet with exact arguments and phone signature, a list in the Permission Hub, session approval sheet and a persistent session notification.
- **Gate for D2 implementation:** the owner counts the prompts of a real 5-step phone task on a device (UDC-16 device checklist §5). If it is acceptable, D2 is deferred; if not, S16.4 proceeds. D1 may proceed independently.
- **Risk accepted:** a session removes the per-action prompt for non-consequential navigation inside allowlisted apps. The remaining protection is the allowlist, the budgets, the heartbeat, the host adapter's fail-closed classification and the denied-package list. A misclassified element is the main residual risk; the injection test set from UDC-8 §8 must be re-run for Android before release.

## Evidence

- [ADR-0012](ADR-0012-host-actions.md); [security tiers table](../architecture/XUNA_DEVICE_CONTROL_SECURITY.md) (R0–R3, UDC-T1, T15); [UDC-7 §4.1](../roadmap/device-control/UDC-7-multihost.md) (grants, `conversation_15m`, R3 never scoped); [UDC-8 §4.2–§4.3](../roadmap/device-control/UDC-8-computer-use.md) (sessions, lexicon, budgets, heartbeat).
- Reference pattern: OpenClaw (MIT) separates pairing, command allowlists and per-command approval and offers allow-once / allow-always; this ADR keeps "allow always" bounded by exact arguments, expiry and a signature.
- Owner delegation: 2026-11-06 (UDC-16 §11 D1/D2/D3 recommendations).

# UDC-16 — Permission Hub, Grant Profiles, Standing Approvals and Phone Sessions

Status: **S16.1, S16.2 and S16.3 implemented 2026-11-06 and host-verified, none run on a device (see §7); S16.4 is planned and gated.** Parts C and D change a security invariant. On 2026-11-06 the owner answered the D1/D2/D3 pick-list with "cứ làm theo ý bạn", i.e. delegated them to the recommendations below; the amendment is written as [ADR-0014](../../decisions/ADR-0014-standing-approvals-and-phone-sessions.md) (2026-11-06) and S16.4 is **not started**. S16.3 (standing approvals) is built; S16.4 (phone sessions) waits for the prompt count from the device test (checklist §5). Complexity: M–L (4 sessions). Repositories: mobile, backend (parts C and D).

## 1. Goal

The owner finds repeated permission prompts annoying. Let the owner grant what is needed **once, in one place, in advance**, without weakening the rules that stop a model or a compromised backend from acting on the phone without consent.

## 2. Where the prompts come from today

| # | Source | Where it lives | Can it be reduced? |
|---|---|---|---|
| 1 | **OS permissions** (notification access, Accessibility, foreground service, companion association, Bluetooth, battery exemption) | Each has a disclosure sheet shown at the moment a feature needs it (UDC-5 §5.3) | **Yes, fully.** Move them into one screen the owner visits once. No policy change. |
| 2 | **Grants** per host family: `maxRisk`, expiry, suspend (UDC-7 S7.1) | Host detail sheet, one family at a time | **Yes.** Add one-tap profiles. No policy change. |
| 3 | **Per-action approvals** for R2 (and R3): ADR-0012 "owner approval (R2+) bound to its arguments"; `README §1.7` lists it as an invariant "never relax in code" | Approval sheet in the chat | **Only with an owner decision.** See parts C and D. R0 and R1 already need no approval. |

## 3. Gate

- Parts A and B: owner go-ahead only. They touch no invariant.
- Parts C and D: **owner decision recorded in an ADR-0012 amendment first** (decisions D1 and D2 below). Do not code them before that.
- UDC-5, UDC-7 and UDC-8 are Done. This plan builds on them.

## 4. Read first

- [README](README.md) §1.7 (invariants), [ADR-0012](../../decisions/ADR-0012-host-actions.md), [security](../../architecture/XUNA_DEVICE_CONTROL_SECURITY.md) tiers table (R0–R3) and UDC-T1, T15.
- [UDC-5 §5.3–§5.4](UDC-5-android.md) (disclosures; dev flavour only for Accessibility, Play policy forbids autonomous control).
- [UDC-7 §4.1](UDC-7-multihost.md) (grants, `conversation_15m`, "R3 never scoped") and [UDC-8](UDC-8-computer-use.md) §4.2 (session model: declared goal, app allowlist, step budget, dead-man switch, one phone-signed approval).
- Code: `mobile/lib/features/hosts/domain/entity/host_grant.dart`, `presentation/widgets/android_permission_disclosure_sheet.dart`, `android_phone_host_card.dart`, `host_detail_sheet.dart`.

## 5. Design

### Part A — "Quyền & kết nối" hub (mobile only, no policy change)

One page listing every capability the **current build** can use, each row showing a verified state: `Đã cấp`, `Chưa cấp`, `Không hỗ trợ trong bản này`.

- **Real checks only.** State comes from the existing probes (`hasNotificationAccess`, `readAccessibilityStatus`, `foregroundServiceStatus`, `readCompanionStatus`). A row is never shown as granted because the owner tapped it; the page re-checks when the app resumes from system settings.
- **Disclosure on the row.** Each row carries its Play prominent-disclosure text (purpose, what is not read). The owner reads it once and taps "Cấp"; the system screen then opens. This satisfies "disclosure before every system permission screen" without a sheet at every use.
- **"Cấp trước các quyền cần thiết".** A guided flow that walks only the missing rows, one system screen after another, returning to the hub each time. It skips what is already granted and what the build does not support (the `play` build never shows Accessibility).
- **No in-chat settings launches.** When a tool needs a missing OS permission, the tool returns `permission_denied` (as today) and the app shows a single chip "Mở Quyền & kết nối". It does not open a system screen mid-conversation.
- **Honest scope text.** Each row states what the permission lets XUNA do and what it still cannot (e.g. notification access: media sessions only, content never read).

### Part B — Grant profiles (mobile, existing grants API)

One-tap presets over the existing `HostGrant` model (`PUT /v1/hosts/{id}/grants`), each editable afterwards:

| Profile | Grants | Default expiry |
|---|---|---|
| Nghe nhạc | `media` up to R1 | Unlimited |
| Trợ lý điện thoại | `media`, `app`, `url` up to R2 | 1 day, renewable in one tap |
| Điều khiển giao diện (dev build only) | `ui` up to R3 | 1 hour |

Maximise what is R0/R1 so fewer actions need approval at all. Show the effect before applying ("sẽ cho phép: …, vẫn hỏi: …").

### Part C — Standing approvals (needs owner decision D1)

An owner approval given **in advance**, bound to a narrow argument pattern, instead of at the moment of use.

- **Shape:** `(hostId, tool, argument pattern, expiresAt, optional maxUses)`. Patterns are exact values only: an `app_id` from the allowlist, an https domain from the allowlist. **No free text, no regex, no wildcard.**
- **Eligible:** R2 tools whose arguments are fully constrained by an enum or an allowlist (`app.launch`, `url.open`, `media.play_search` with a fixed package). **Never R3. Never a tool that types text, taps, or reads content.**
- **Lifetime:** default 7 days, maximum 30, revocable from the hub, listed with a count of uses.
- **Always enforced on top:** the host grant must still allow the tool, the host re-validates arguments locally, E-Stop and "Tạm khoá tất cả" suspend it, rate limits apply.
- **Audit:** content-free `host.preapproval_created`, `host.preapproval_used`, `host.preapproval_revoked`.
- **Why this can be consistent with the invariant:** the approval is still the owner's, still bound to exact arguments and a specific host. What changes is *when* it is given. This is a change to ADR-0012 and to `README §1.7` item 5, so it needs an amendment, not just code.

### Part D — Phone control sessions (needs owner decision D2)

This is what makes the new `ui.observe` / `ui.act` / `ui.wait_for` practical. Under the current rules each `ui.act` is R3: one owner approval **per action, never batched**. A task such as "open Settings, find X, toggle it" is 5–10 actions, so 5–10 prompts. That is the prompt fatigue the owner is describing.

UDC-8 already solved this for the desktop: one **phone-signed** approval for a session with a declared goal, an app allowlist, a step and time budget and a dead-man heartbeat; inside the session, observation and actions do not re-prompt. Extend the same model to the Android dev build:

- `cu.session_start {goal, apps[], maxSteps ≤ 20, maxMinutes ≤ 10}` on the phone host, approved once with the phone key.
- Inside the session: `ui.observe`, `ui.act`, `ui.wait_for` run without a prompt, **only** for packages in `apps[]`.
- Unchanged and still mandatory: hard-denied packages, sensitive-field redaction, XUNA never acts on itself, E-Stop, step/time budget, heartbeat loss stops the session, visible persistent notification while active, content-free logs.
- **Dev flavour only.** Play policy prohibits autonomous AI control through Accessibility (UDC-5 §5.4). The `play` APK must still not contain the Accessibility service (existing CI check).

### What never changes

- R3 is never batched **outside** a session, and is phone-signed.
- No shell, eval, raw keyboard or pointer tools.
- Password fields, OTP-like text, banking/authenticator/settings packages stay unreadable and untargetable.
- The model never sees approval tokens; approvals are bound to arguments, host and expiry.
- Logs stay content-free.

## 6. Files (expected)

- Mobile: new `features/hosts/presentation/permission_hub_page.dart` + controller/binding; reuse `android_permission_disclosure_sheet.dart` copy; profiles in `host_detail_sheet.dart`; locale keys in `vi_VN.json` / `en_US.json` and `locales.g.dart`.
- Backend (parts C, D): `modules/hosts` (standing approvals table + routes), `modules/actions` (approval resolver, Android sessions), `AuditAction` additions, migration, ADR-0012 amendment.
- Docs: ADR-0012 amendment, security tiers table row for standing approvals, `UDC-16-results-<date>.md`.

## 7. Sessions

| Session | Content | Needs |
|---|---|---|
| S16.1 | Part A: hub page, verified states, guided "Cấp trước", `permission_denied` chip | mobile only |
| S16.2 | Part B: grant profiles with before/after preview | mobile only |
| S16.3 | Owner decision D1 → ADR-0012 amendment → Part C: standing approvals, hub management, audit | backend + mobile |
| S16.4 | Owner decision D2 → Part D: Android phone sessions (dev build) reusing UDC-8 session loop | backend + mobile |

S16.1 and S16.2 can ship without any decision. They already remove prompt sources 1 and 2.

**S16.1 as built (2026-11-06, mobile only, host-verified, not run on a phone):**

- `PlanAndroidPermissionSetupUseCase` (pure) lists the missing steps from the live probe: notification access, companion association, Accessibility (only when the build supports it, so never on `play`).
- `HostsController` re-probes the real state whenever the app resumes, so a permission granted in system settings shows up without leaving the page. This also fixes the old stale state after returning from settings.
- "Cấp trước các quyền cần thiết" (`AndroidPermissionSetupCard` on the hosts page, shown once this phone is enrolled): shows each step's existing disclosure, opens the system screen, re-probes on return and moves to the next one. It stops, and names the missing permission, if the owner comes back without granting it; cancelling a disclosure ends the flow. Nothing is reported as granted without a probe.
- The Accessibility disclosure text was updated to match the current tools (`ui.observe`, `ui.act`).
**S16.2 as built (2026-11-06, mobile only, host-verified, not run on a phone):**

- Packs on the host detail sheet: `music` (media R1, no expiry), `basic` (media R1 + app R2 + url R2, 1 day), `uiControl` (ui R3, 1 hour; offered only for this Android phone on a build with Accessibility, never on `play`).
- Pure `PlanHostGrantProfileUseCase` computes the grants and the real differences; applying a pack that is already on is a no-op message. The owner confirms a dialog listing the changes plus "R2 and above still ask for approval" before anything is sent.
- **Found and fixed:** the app rejected every R3 grant, and the grants sheet listed only four families, so the Android `ui.*` tools (R3, family `ui`) could never become eligible for the model. `SetHostGrantsUseCase` now allows R3 for the `ui` family only. A grant only makes a tool eligible; each R3 call still needs its own approval. The backend already accepted R3 grants; this path has not run end to end.
- Device test list: [UDC-16-device-test-checklist.md](UDC-16-device-test-checklist.md).
**S16.3 as built (2026-11-06, backend + mobile, host-verified, not run on a device):**

- **Backend:** `host_standing_approvals` table (migration `0018`), `StandingApproval` domain entity and eligibility rule, `StandingApprovalService`, SQL and in-memory repositories, `POST/GET/DELETE /v1/actions/standing-approvals`, audit `host.preapproval_created/used/revoked`, and the orchestrator checks a matching approval before asking the owner.
- **How a call matches:** same owner, same host, same tool and the same `argsSha256` of the validated arguments, not revoked, not expired, not used up. A standing approval is consumed atomically (`SELECT … FOR UPDATE`).
- **Eligibility is stricter than the first sketch:** R2 only, tool does not observe, family is not `ui`/`cu`/`input`/`screen`, and every string argument must be a member of a closed `enum` in the tool's own schema. So `url.open` and `media.play_search` (free-text arguments) are **not** eligible; `app.launch` is eligible only when the host publishes its app allowlist as an `enum`. Eligibility is re-checked at use time, so removing an app from the allowlist stops the approval from matching.
- **Signature:** the phone signs `xuna.preapproval.v1 | approvalId | tool | argsSha256 | hostId | expiresAtEpoch | maxUses` with its enrolled key. The backend verifies it with the production P-256 verifier against the owner's enrolled phone keys, and fails closed if there is no verifier. A normal approval signature cannot be replayed (different domain prefix). The Dart message matches the backend byte for byte (golden vectors in the tests).
- **E-Stop and "Tạm khoá tất cả":** standing approvals are checked only after the grant check, so suspending grants makes them inert until the owner re-enables the grants. There is no separate suspension flag.
- **Mobile:** the approval sheet offers "Luôn cho phép việc này (7 ngày)" only when the backend sent a `standing` offer (tool and validated arguments) for that call. It approves this call once and then creates the standing approval; if remembering fails the app says so and the one-time approval still stands. The hosts page has a "DUYỆT TRƯỚC" list with expiry, use count and a revoke button, and shows a load error instead of an empty list when the fetch fails.
- **The approval sheet shows the exact tool and pinned arguments** (`app.launch (app_id=…)`) next to the "always allow" button, so the owner sees what the 7-day approval is signed for.
- **Real coverage today is narrow:** only `app.launch` on the phone's own Android host is eligible, because the Android manifest publishes its app allowlist as an `enum`. The desktop agent publishes `app.launch` with a string `pattern`, so a PC is not eligible; `url.open`, `media.play_search` and all `ui.*` tools are excluded by design. To widen it, a desktop host would have to publish an `enum` allowlist.
- **Not built:** a way to choose the lifetime or a use limit (fixed 7 days, unlimited uses; the API supports both), the host (desktop agent) verifying the signature, a dedicated rate limiter, and iOS-only hosts (untested).
- **Not done in S16.1:** the in-chat "Mở Quyền & kết nối" chip for `permission_denied`, and a standalone hub page (the card lives on the hosts page). Background-service opt-in stays a separate toggle, not an auto step.

## 8. Tests

- Hub: a row is `Đã cấp` only when the probe says so; flipping the probe back shows `Chưa cấp` after resume; `play` build shows no Accessibility row (widget test).
- Profiles: the preview lists exactly what changes; applying twice is idempotent; expired grants show as expired.
- Standing approvals: pattern must match exactly; R3 and free-text tools are refused at creation; expiry, revoke, E-Stop and suspend each stop its use; a tool outside the pattern still prompts; the same policy result at every bond level (as UDC-9 §130 requires).
- Sessions: acts outside `apps[]` refused; step/time budget and heartbeat loss stop the session; a hard-denied package stays refused inside a session; prompt-injection set from UDC-8 §8 re-run for Android.

## 9. Acceptance

- A new owner reaches a working media + app-launch setup through the hub in one visit, with no system-settings screen opened from inside the chat.
- With a standing approval for "mở Spotify", asking twice in a week prompts zero times; asking for any other app still prompts.
- A 6-step phone task inside a session produces one approval, not six, and stops at the step budget.
- `play` build: no Accessibility service in the manifest.

## 10. Risks

| Risk | Mitigation |
|---|---|
| A standing approval becomes a broad blank cheque | Exact patterns only, R2 only, expiry, use counter, hub list, audit |
| A session is hijacked by on-screen text (prompt injection) | App allowlist, step budget, hard-denied packages, redaction, heartbeat, E-Stop; re-run the UDC-8 injection set |
| The hub shows a stale "granted" | Re-probe on resume and before every guided step |
| Play review objects to a pre-granted flow | The disclosure is still shown before each system screen; Accessibility stays out of `play` |

## 11. Decisions the owner must make

- **D1 — Standing approvals (part C).** Allow pre-issued approvals for exactly-constrained R2 actions?
  - Recommended: **yes**, 7-day default, 30-day maximum, R2 only, exact values only.
  - Alternative: no, and rely on the 15-minute conversation scope plus parts A, B and D.
- **D2 — Phone sessions (part D).** Extend UDC-8 sessions to the Android dev build?
  - Recommended: **yes**, dev build only.
  - Alternative: keep per-action R3 approval and accept the prompts.
- **D3 — Default grant expiry** for "Trợ lý điện thoại": recommended 1 day with one-tap renewal.

## 12. Handoff

After each session: update this file's status, PROCESS.md and CHANGELOG.md, and write `UDC-16-results-<date>.md`. Report in Vietnamese, including what was not run.

## 13. Brief for a coding agent

> Read README §1, ADR-0012, the security tiers table and UDC-5/7/8. Do S16.1 only unless told otherwise. Never show a permission as granted without a live probe. Do not start parts C or D before the owner's recorded decision. Do not relax any invariant in README §1.7.

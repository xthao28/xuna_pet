# ADR-0015 — Commit-gated control and trusted scopes

Date: 2026-11-12. **Status: Approved (owner 2026-11-12, chose the "Rộng tay" package of [UDC-17 §7](../roadmap/device-control/UDC-17-smart-control-plan.md)). E1 and E2 Implemented and host-verified (2026-11-12, no device run). The prerequisite host preflight (UDC-17 S17.1, XTP §4.2.8) Implemented 2026-11-12, unit-tested only. D1 Implemented 2026-11-12 (S17.2, unit-tested only; no device run), with the mirror reduced to "the next commit card shows the text typed since the last commit"; the live session card that shows the full typed text with a Stop control was added in S17.3 (2026-11-13, unit-tested only). D2 Implemented in Dart only: no real host reports focus exactly yet (macOS `readActiveWindowContext` reads the AX role but not the subrole, so a search or secure field is just `AXTextField`; Windows reports a localized control type), so Enter and Space stay R3 on real hosts until the native readers change (needs Q6). E3, E4 and E5 not Implemented.** Amends [ADR-0012](ADR-0012-host-actions.md) decision 1 (the `owner approval (R2+)` step) and [ADR-0014](ADR-0014-standing-approvals-and-phone-sessions.md) D2.1 (session budgets) and D2.3 (`set_text` and activation keys). Plan: [UDC-17](../roadmap/device-control/UDC-17-smart-control-plan.md).

## Context

- ADR-0012 requires an owner approval bound to its arguments for every R2+ host action. ADR-0014 added standing approvals for exactly-pinned R2 calls and sessions in which navigation is R2 while typing and consequential steps stay R3 per action.
- The owner still finds the number of prompts too high and asked (2026-11-12) for more permissions "as long as it is not too dangerous". A multi-step task such as "find a contact, write a message, send it" needs about five phone signatures today (estimate derived from the rules, not measured on a device).
- The main threat is not the model acting on its own initiative but on-screen content (web pages, messages, email) injecting instructions. The question for each relaxation is: what is the worst outcome if the model is steered?
- R2 approvals are not phone-signed today; only R3 approvals are. A compromised backend can therefore already run R2 calls. Phone signatures are the boundary that matters against backend compromise.

## Options

| Option | For | Against |
| --- | --- | --- |
| **A. Keep ADR-0014 as is** | No new risk | The owner will not use multi-step control |
| **B. Balanced: E1–E4 + D1 + D2** | The owner signs only at commit points | A trusted app can be read and navigated without a per-session signature |
| **C. Wide: B + E5 for owner-chosen apps** | Messaging and tidy-up tasks need no touch | A wrong message can be sent while the owner is not looking; it cannot be recalled |
| **D. Trust the browser on every domain / unattended mode for payments, public posts, account deletion (E6, E7)** | No prompts at all | Money, data and reputation loss; the browser holds every logged-in account. Rejected |

## Decision

**Option C.** The governing rule: **preparation is free inside a signed scope; the owner decides at points of no return.**

### D1 — Draft typing inside a session (amends ADR-0014 D2.3)

`input.type_text` (and Android `set_text`) needs no per-call approval when all hold: an approved session is active; the foreground window belongs to an app declared for the session; the host classifies the target, from the live tree, as an ordinary text field (not a password or secure field, not unclassifiable); the session's character budget is not exceeded. The typed text is mirrored to the phone with a Stop control. Otherwise it stays R3 per action.

Implementation notes (2026-11-12, decided by the implementer): the draft roles are a closed list (`textfield`, `searchfield`, `searchbox`, `textarea`; a Windows UIA `Document` is excluded); the budget is 2,000 characters per session, spent only by unsigned typing; a draft with a line break or sent as real keystrokes (`headed`) is R3 because either can press Enter; while unsigned draft text is pending, a click on an unnamed element (an icon-only Send) is R3. The commit card shows at most the first ~150 characters of the typed text (240-character summary limit), and the list is lost if the backend restarts. Because a manifest-level R2 lets the grant check pass, a host whose `input` grant ceiling is only R2 can now draft-type; before, typing needed an R3 ceiling.

### D2 — Context-aware activation keys (amends ADR-0014 D2.3)

Enter/Return and Space are R3 by default (implemented 2026-11-12). The host may lower one press to R2 only when it identifies the focused element as a search field, address bar or single-line field that is not part of a submitting form. A composer, a form with a submit control, or anything the host cannot classify stays R3. A model-declared flag never lowers the risk.

### E1 — Session budgets (amends ADR-0014 D2.1)

`maxSteps ≤ 40`, `maxMinutes ≤ 20` (was 20 / 10). The other stop conditions are unchanged.

### E2 — Grant lifetime

The desktop control pack and a switch that newly opens an R3 ceiling (`cu`, `input`) default to 30 days (was 1 day). A grant only makes tools eligible; every call still passes the approval step.

### E3 — Trusted mode for R2 (amends ADR-0012 decision 1)

While the owner has trusted mode on for a host, R2 calls that do not observe and do not belong to the `cu`/`ui`/`input`/`screen` families (launch an app, open a public `https` link, window management, media) run without a prompt. The phone shows each one. Trusted mode is time-limited (default 8 hours), per host, switched on only by an owner action on the phone, and switched off by E-Stop and "Tạm khoá tất cả". Host-side validation and the grant check still apply.

### E4 — Trusted apps (amends ADR-0014 D2.1)

The owner may sign, with the enrolled phone key, a list of apps per host (default lifetime 30 days, revocable). A session whose `apps[]` is a subset of that list starts without a per-session signature. The host verifies the signature itself. Browsers are not in the list by default; when the owner adds one, the session's `domains[]` rule still applies and each domain outside the owner's list still needs the session signature.

### E5 — Countdown instead of signature for light commits (owner-chosen apps only, off by default)

For apps the owner explicitly enables, a commit that the host classifies as *light* (send a message, confirm a dialog, move one item to the trash) is announced on the phone with its real content and a Cancel control for a fixed window (default 8 seconds) and then runs. Everything else in "What does not change" stays R3. If the phone cannot be reached to show the countdown, the action does not run.

### What does not change

- Always R3, phone-signed, per action, never covered by D1–E5: payment, purchase, transfer, public post or publish, account deletion, uninstall, and any target the host cannot classify.
- Hard refusals: no shell, eval, script source or process kill; nothing elevated; password and secure fields; terminals, password managers, banking apps and system settings; apps and domains outside the session.
- Classification lives in the host adapter (honest-code H5), is fail-closed, and the host re-validates at execution. The backend never lowers a risk the host reported.
- E-Stop, content-free logs, U5 (`host_screen`) consent, no Accessibility in the Play build.
- E6 (browser trusted on every domain) and E7 (unattended mode) are rejected.

## Consequences

- **XTP contract:** a host preflight that returns the effective risk and the live element label (UDC-17 S17.1) is the prerequisite for D1, D2 and E5; contract document and both fixture directories change together.
- **Backend:** trusted-mode and trusted-app records (migration), resolver changes in the approval step, countdown events on SSE and the voice WebSocket, new content-free audit actions (`host.trusted_mode_changed`, `host.trusted_apps_signed`, `host.countdown_started`, `host.countdown_cancelled`), durable session store.
- **Desktop:** focused-element and field classification in the native adapters (must be compiled and run on a real Mac and Windows PC before it counts as done), signature verification for trusted apps, light-commit classification.
- **Mobile:** trusted-mode switch, trusted-app signing sheet, live session card with mirrored text, countdown notification.
- **Tests before any of D1, D2, E4, E5 is enabled:** the UDC-8 §8 injection set re-run under the new rules, including "typed text is never committed without the gate", "unclassifiable is R3", "countdown not shown means not run".
- **Risks accepted by the owner:** (E4) a trusted app can be read and navigated on command without a per-session signature; (E5) a wrong message sent during an unattended countdown cannot be recalled; (D1) text typed into a field that auto-submits or auto-saves.
- **Open:** which machines the owner can use to verify the native parts (UDC-17 Q6). Screen capture with a vision model stays out of scope (UDC-17 Q5, deferred).

## Evidence

- [ADR-0012](ADR-0012-host-actions.md), [ADR-0014](ADR-0014-standing-approvals-and-phone-sessions.md), [UDC-8 §4.2–§4.3](../roadmap/device-control/UDC-8-computer-use.md), [UDC-17 plan](../roadmap/device-control/UDC-17-smart-control-plan.md) §3, §7.
- Owner decision 2026-11-12: "rộng tay luôn cho máu, không quá nguy hiểm là được" in answer to UDC-17 Q7 (packages a / b / c), after "cho nó nhiều quyền hơn chút được không". The same day the owner delegated the fixes and ordering ("bạn có thể tự quyết định nếu thấy nó ổn"); the session order of UDC-17 §4 and deferring Q5 follow that delegation and may be changed by the owner.

## Amendment 2026-11-22 — Autopilot preset end-to-end enforcement & high-impact R3 boundary (owner-approved)

- **Trigger:** The owner enabled `trustPreset: "autopilot"` on `Xuans MacBook Pro` (`host-policy.json`), yet Backend `Orchestrator` did not read `trustPreset` and still prompted on every `R2` tool (`app.launch`, etc.), every `cu.session_start`/`cu.session_extend`, and ordinary UI/IDE input steps (`Enter`/`Space`, headed typing, unlabeled clicks).
- **Owner decision (2026-11-22):** Relax permissions under `trustPreset == "autopilot"` so XUNA executes ordinary work uninterrupted, while keeping `R3` phone-signed approval strictly enforced for **high-impact** actions **and** **external outbound send/publish**:
  1. **Synced `HostTwin.trust_preset`:** Backend lazily fetches `xuna/get_policy` once per live desktop connection (fail-closed to `"standard"` on any error/timeout) and updates immediately on `GET/PUT /v1/hosts/{id}/policy`.
  2. **Auto-run without prompt under `autopilot`:** all `R0–R2` host tools (including `app.launch`, `url.open`, native productivity/workspace/media/web tools), `cu.session_start`/`cu.session_extend` on non-hard-denied apps/domains, ordinary UI steps inside apps/IDEs (normal/coordinate clicks, typing including `headed` & newlines, `Enter`/`Space` prompt submission, drags, scrolls), and `R2` cross-host missions whose target hosts are all in `autopilot`.
  3. **Still `R3` phone-signed (`scope = once`) even under `autopilot`:**
     - **External outbound & public publish:** `mail.send`, UI/web targets matching `send`/`post`/`publish`/`gửi`/`đăng` (excluding `đăng nhập`/`đăng ký`)/`xuất bản`.
     - **Financial / payment / cards:** `buy`, `pay`, `payment`, `checkout`, `purchase`, `transfer`, `wire`, `confirm payment`, `place order`, `mua`, `thanh toán`, `chuyển khoản`, `đặt hàng`, card/CVV/PIN tokens.
     - **Destructive / account / system:** `delete`, `erase`, `empty trash`, `format`, `uninstall`, `sign out`, `log out`, `logout`, `xóa`/`xoá`, `gỡ cài đặt`, `hủy/xóa tài khoản`, `dọn sạch thùng rác`, `đăng xuất`.
  4. **Hard refusals & presets unchanged:** `password` fields (`password_field_forbidden`), hard-denied apps (Terminals, Password Managers, Banking apps, System Settings), `shell.*`, `denyApps`/`denyDomains`, E-Stop (`stopped`), content-free audit logs, U5 zero-retention, and `standard`/`strict` preset behaviour remain 100% unchanged.

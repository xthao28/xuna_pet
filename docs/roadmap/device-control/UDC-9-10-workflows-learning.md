# UDC-9 — Cross-device workflows · UDC-10 — Learning and personalization

Status: **UDC-9 Implemented & Verified on Host (2026-10-31; [UDC-9-results-2026-10-31.md](UDC-9-results-2026-10-31.md)) · UDC-10 Implemented & Verified on Host (2026-10-31; [UDC-10-results-2026-10-31.md](UDC-10-results-2026-10-31.md))** — physical multi-host LAN + board/phone live run pending. Complexity: UDC-9 M (3 sessions), UDC-10 M (3 sessions). Repositories: backend, mobile, desktop, firmware (small).

---

## UDC-9 — Cross-device workflows

### 1. Goal

Three things, each step with its own target, deadline and approval:

- **Hand-offs** that the platforms really allow: send the current link from a PC to the phone; "nghe tiếp trên Mac".
- **Multi-host commands:** "dừng nhạc ở mọi nơi".
- **Board-button workflows:** owner-chosen quick workflows triggered from the Remote scene.

### 2. Gate

- UDC-5/6/7 Done.
- Owner go-ahead.

### 3. Read first

- [README](README.md); [architecture §7](../../architecture/XUNA_UNIVERSAL_DEVICE_CONTROL_ARCHITECTURE.md); UDC-3 tools; UDC-4 orchestrator; UDC-1 `RemoteMode`.

### 4. Design

**4.1 Composite plans (backend `actions`):**

- A `Plan` is an ordered list of single-host steps produced by the **orchestrator from fixed templates**, not free-form by the model.
- The model chooses a template and its parameters through a tool `workflow_template` with the enum below:

| Template | Steps | Approval |
|---|---|---|
| `link_to_phone` | 1. `browser.current_url` on the PC (new tool, R2: reads the active tab URL of Edge/Chrome via UIA, or Safari/Chrome via AppleScript; https only) → 2. `url.open` on the phone (same-device or background host) | **One** approval that shows both hosts and the domain only |
| `continue_media` | 1. `media.now_playing` on A → 2. `media.play_pause` (pause) on A → 3. `app.launch` player on B → 4. `media.play_pause` on B | One approval. The result states that position sync depends on the player (e.g. Spotify account sync); XUNA does not transfer playback state |
| `pause_everywhere` | `media.play_pause` (pause only if playing) on every online host with the media family granted + board HID if connected | One approval listing all aliases; per-host results |

- Each step is checked by the normal policy.
- A failed step stops the plan and reports which step and host failed.
- Steps are never retried automatically on another host.

**4.2 Board-button workflows:**

- App setting "Bố cục Remote": **Media** (default, UDC-1) or **Workflows**.
- In Workflows layout:
  - GPIO0 short → workflow slot 1;
  - GPIO14 short → slot 2;
  - holds unchanged (GPIO14 hold exits, both-hold stops).
- The layout is sent to the board via opcode 13 `arg = 4` (set Remote layout, `source = 0|1`) and stored in NVS `xuna_hid/layout`.
- Board → app: status notification kind 3 `remoteEvent`, arg 2 = slot 1, arg 3 = slot 2 (arg 1 = stop, from UDC-7); capability byte 5 bit 6 (same bit as UDC-7's remote events).
- The app → `POST /v1/actions/workflow-trigger {slot}` → the orchestrator runs the owner-configured `{hostAlias, workflowId}` for that slot.
- **Risk limits:** an R1 workflow runs at once (the owner is physically present). An R2 workflow shows an approval on the phone. R3 workflows cannot be assigned to buttons (security UDC-T15).
- Board feedback: bubble "Đang chạy: {workflow name}" and the deterministic gesture on result.

### 5. Sessions

| Session | Content | Acceptance |
|---|---|---|
| S9.1 | `browser.current_url` tool (Windows UIA for Edge/Chrome; macOS AppleScript for Safari/Chrome with Automation permission) + `link_to_phone` | 10/10 on Edge and Chrome (Windows), Safari and Chrome (macOS); the URL never logged |
| S9.2 | `continue_media` + `pause_everywhere` plans with per-step results | Plans stop at the first failure; results name the host |
| S9.3 | Remote Workflows layout (firmware opcode 13 arg 4, status kind 3), app settings, workflow-trigger route | Button → workflow on the PC within 2 s on the LAN; R2 asks on the phone; R3 cannot be assigned |

### 6. Brief for a coding agent

> Implement the plan templates as deterministic code; the model only picks a template and its parameters.
>
> Keep every step under the normal policy, with one approval per plan that lists all hosts.
>
> Firmware changes are additive (opcode 13 arg 4, status kind 3, capability byte 5 bit 6). Check that the app's status decoder tolerates the new kind before releasing firmware.
>
> Report in Vietnamese.

---

## UDC-10 — Learning and personalization

### 1. Goal

XUNA gets better at helping without gaining more power:

- it remembers owner-confirmed defaults ("nhạc thì mở trên Mac");
- it notices routines and **offers**, never acts;
- its offers become a little more frequent as the bond grows.

### 2. Gate

- UDC-9 Done.
- The KX-4 conventions store exists (it does: `knowledge` module).
- Routine V1 (`7a6e0014`) is shown in the app (it is, 2026-10-29).
- Owner go-ahead.

### 3. Read first

- [Knowledge Expert plan](../knowledge/knowledge-expert-plan-2026-10-29.md) (KX-4 conventions, bond levels "Mới quen / Bắt nhịp / Ăn ý / Đồng đội").
- `backend/src/xuna_backend/modules/knowledge/` (conventions storage and the owner-context builder `domain/owner_context.py`).
- [Routine learning record](../learning/routine-learning-2026-10-20.md); mobile `PetRoutine` / `HomeRoutineCard`.
- AGENTS.md §6 (do not call simple rules "AI learning"; label them accurately).

### 4. Design

**4.1 Host defaults as conventions:**

- New convention kind `host_default {family, hostAlias}`. It is created **only** by owner confirmation:
  - (a) the app offers "Lần sau mở nhạc trên Mac luôn nhé?" after the owner picked the same host 3 times for a family (a rule, labelled as such);
  - (b) the owner states it in chat (candidate → confirm, the existing D6/KX flow).
- `TargetResolver` uses a `host_default` only as a tie-breaker when no explicit alias is given and several hosts are eligible.
- It never skips an R2+ approval.
- Visible, editable and deletable in the app (existing conventions UI). Deleting it changes targeting immediately (test).

**4.2 Routine-based offers:**

- Inputs:
  - Routine V1 (usual weekday/weekend arrival time);
  - the owner's history of R1 actions by hour, kept **on the phone only** in Hive: counts per family per hour-of-week, no content.
- **Rule:** if the owner did family F on host H in the same hour-of-week on ≥ 3 of the last 4 weeks, and Routine V1 says they are usually around, the app shows an offer card at that time ("Tối rồi, mở nhạc trên Mac nhé?") with one tap to run (normal policy applies).
- An offer never executes by itself.
- Ignored or declined twice in a row → that offer pauses for 2 weeks.

**4.3 Bond level affects frequency only:**

| Bond level | Max offers per day |
|---|---|
| Mới quen | 0 |
| Bắt nhịp | 1 |
| Ăn ý | 2 |
| Đồng đội | 3 |

- Proposed values, owner-tunable.
- **Bond level never changes grants, risk tiers or approvals** (architecture §8). Add a test asserting that the policy result is identical across bond levels.

**4.4 Personality:**

- Personality may change offer wording (temperament-based phrasing table, the existing persona path).
- It never changes whether an offer is shown beyond the bond-level cap, and never whether an action runs.

### 5. Sessions

| Session | Content | Acceptance |
|---|---|---|
| S10.1 | `host_default` convention kind + resolver tie-breaker + app UI hooks | Deleting a default changes the next targeting decision (test); no approval skipped |
| S10.2 | Phone-local action history + routine offer rule + pause rule | Simulated 4-week history produces the expected offers; nothing executes without a tap |
| S10.3 | Bond-level cap + personality wording + "two histories differ" check | Two simulated owners get different, explainable offers; policy identical across bond levels |

### 6. Acceptance (UDC-10 overall)

- Two different owner histories produce different, explainable suggestions (the M06 style of acceptance).
- 0 suggestions execute without confirmation.
- Deleting a convention takes effect immediately.
- Suggestions are labelled "gợi ý theo thói quen", and the "Why?" view shows the rule and the counts.

### 7. Brief for a coding agent

> Implement accurate, labelled rules, not "AI learning" claims.
>
> Host defaults exist only after owner confirmation and act only as tie-breakers.
>
> Offers never execute by themselves.
>
> The bond level caps offer frequency and never affects permissions; prove it with a test.
>
> Keep the action history on the phone and content-free.
>
> Report in Vietnamese.

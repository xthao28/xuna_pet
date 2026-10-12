# XUNA — Work Plan

Last updated: **2026-10-11** (Asia/Ho_Chi_Minh).

Read [AGENTS.md](AGENTS.md) for canonical instructions and [PROCESS.md](PROCESS.md) for current context. This file owns the ordered task list and task status. [CHANGELOG.md](CHANGELOG.md) records work actually performed; [M01 validation record](docs/roadmap/M01-bring-up.md) owns detailed acceptance evidence.

Current priority: **Owner-approved local MVP through M05**. Implementation evidence and physical acceptance in [MVP record](docs/roadmap/MVP-local.md). M01 PCB revision/P07 remain open. M02–M05 builds/tests do not establish physical validation.

## 1. Retained M01 acceptance tasks

Retain outstanding hardware evidence; M02 is now the active priority.

| ID | Status | Task | Who / dependency | Completion evidence |
| --- | --- | --- | --- | --- |
| P01 | Done — 2026-10-11; normal IDE CLI build PASS | Finish PlatformIO IDE installation; open `firmware/`; verify CLI availability and rebuild in the owner's normal environment | Owner/AI; local environment | `pio --version` and successful build log |
| P02 | In progress — USB/ROM passed; model confirmed; PCB revision pending | Connect USB-C data cable; record board markings/revision and detected serial port | Owner physical action | Board identification and port recorded |
| P03 | Done — 2026-10-11; upload/startup PASS | Upload M01; capture startup Serial output | Owner/AI after explicit post-checkpoint confirmation | Upload succeeds; version, Flash/PSRAM and init logs recorded |
| P04 | Done — 2026-10-11; owner confirmed basic checks | Check branding, geometry/colors, idle animation, both buttons, timeout and held-button behavior | Owner physical observation | M01 checklist results, observed failures if any |
| P05 | Done — 2026-10-11; >10-minute stability and no-Monitor startup PASS | Collect idle/happy diagnostics; run at least 10 minutes; test resets and startup without Monitor | Owner with AI analysis | Runtime measurements and stability notes |
| P06 | Done — 2026-10-11; PSRAM diagnostics corrected, build/upload/runtime PASS | Fix only observed M01 issues, then rebuild and repeat affected checks | AI; failure evidence | Relevant tests/build pass and hardware recheck |
| P07 | Pending | Review all acceptance criteria; mark M01 Validated only when physical evidence supports them | Owner/AI | Completed validation record, unresolved issues explicit |
| P08 | Done — 2026-10-11; see [history](CHANGELOG.md#2026-10-11--commit-current-work) | Prepare/review firmware commit, then parent docs and gitlink commit | When owner requests Git delivery | Child commit exists; parent points to it; no unrelated changes |

Build/upload/monitor from the parent repository in a PlatformIO terminal:

```sh
pio --version
pio run -d firmware -e xuna_t_display_s3
pio device list
pio run -d firmware -e xuna_t_display_s3 -t upload --upload-port /dev/cu.usbmodemYOUR_PORT
pio device monitor -b 115200 --port /dev/cu.usbmodemYOUR_PORT
```

Replace the port with the actual device. Upload replaces current board firmware. If upload fails, hold BOOT, tap RST, release BOOT, upload, then tap RST. Detailed troubleshooting is in the firmware README.

Host tests, from repository root:

```sh
c++ -std=c++11 -Wall -Wextra -Werror -Ifirmware/include firmware/test/test_core.cpp -o /tmp/xuna-m01-core-test
/tmp/xuna-m01-core-test
```

Suggested commit messages (do not commit/push automatically):

- Firmware: `feat: implement XUNA M01 T-Display-S3 hardware bring-up`
- Parent: `docs: record M01 handoff and update firmware submodule`

## 2. Active M02 plan — implementation choices Proposed

Owner requested M02; meaningful protocol/library choices still require review before implementation.

**M02 — Flutter + BLE smallest vertical slice:** phone discovers/connects to the device, requests an animation, and receives device status. Do not add voice, backend or digital-life systems to this slice.

1. Prepare a short protocol proposal: service/characteristic UUIDs, schema version, capabilities, minimal animation command/status payload, request IDs, validation, error behavior, timeouts and reconnect/idempotency rules.
2. Confirm unresolved ownership/synchronization policies before implementing pet-life state. The device-authoritative direction is still Proposed in AGENTS.md. M02 can exchange animation/status without prematurely designing persistent life-state synchronization.
3. Evaluate BLE libraries and target mobile OS against actual compatibility/permissions. The owner confirmed retaining the imported Clean/GetX base on 2026-10-11; implement future mobile work within that structure.
4. Implement the minimal device adapter and Flutter discovery/connect/command/status UI once this milestone is requested and meaningful choices are agreed.
5. Add protocol/parser tests, then validate with the actual phone and board, including disconnect/reconnect and invalid commands.
6. Record M02 evidence and update this handoff. Later M03–M07 retain the existing roadmap; do not begin them speculatively.

## 3. Maintaining this plan

- Use task statuses: Pending, In progress, Blocked, Done, or Conditional. They describe tasks, not the AGENTS.md decision/validation vocabulary.
- Mark a task Done only with a date and a link to evidence. Record the reason/dependency when Blocked.
- Keep stable task IDs so history entries can refer to them.
- Update this file when priorities, dependencies or remaining work change; record meaningful plan changes in CHANGELOG.md.
- Keep completed tasks until the milestone closes. Summarize/archive them with links when a later milestone becomes active.
- Proposed future work remains Proposed until the owner requests it and relevant decisions are resolved.

## M02 task checkpoint

| ID | Status | Evidence / next action |
| --- | --- | --- |
| M02-01 | Done — 2026-10-11 | Git/source/tooling inspection; owner selected iOS simulator; see M02 record |
| M02-02 | Done — 2026-10-11 | Owner approved proposal; simulator-first implementation requested |
| M02-03 | Pending | Dependency resolution/native compatibility experiment after approval |
| M02-04 | In progress | Mobile fake Clean/GetX feature + 4 tests PASS; physical adapters pending |
| M02-05 | In progress | Simulator native build/launch PASS; widget flow PASS; real-phone physical matrix pending |
| M02-06 | In progress | Proposal/handoff recorded; append actual implementation and validation evidence later |

Mobile simulator checkpoint delivered: `24026b2` pushed to `mobile` origin/dev on 2026-10-11. Root gitlink delivery was subsequently authorized with the local MVP publication; see current delivery in PROCESS.md.

## Local MVP task checkpoint — 2026-10-11

| ID | Status | Evidence / next step |
| --- | --- | --- |
| MVP-01 | Done | Owner approved M05 scope, device-owned local state and deterministic text V1 |
| MVP-02 | In progress — implemented; physical tests pending | BLE server/mobile adapter, capabilities/results/session dedup; builds/tests PASS |
| MVP-03 | In progress — implemented; LCD observation pending | Four original sprite reactions; core tests PASS |
| MVP-04 | In progress — implemented; physical reboot/power-loss pending | Two-slot versioned/checksummed NVS snapshots; host fallback tests PASS |
| MVP-05 | In progress — implemented; board behavior test pending | Context-specific preference estimator/feedback, bounded episodes, offline quiet routine |
| MVP-06 | In progress — implemented; physical end-to-end pending | Local text intents, consent, source display, forget; 10 mobile tests PASS |
| MVP-07 | In progress | Board build/upload/startup PASS; LCD/buttons owner-confirmed; real iPhone, stability and persistence matrix next |
| MVP-08 | In progress | Owner requested current commit/push; final physical acceptance still pending |

## Git checkpoint — 2026-10-11

Owner authorized publishing local MVP. Firmware be58099 and mobile3846880 are committed/pushed to origin/dev; parent snapshot records their gitlinks. Git delivery is complete in this snapshot; MVP-08 physical acceptance review remains pending. No backend change. Next: real iPhone BLE/learning/persistence matrix in MVP-local.md.

## Technical plan checkpoint — 2026-10-12

| ID | Status | Evidence / next step |
| --- | --- | --- |
| TIP-01 | Done — 2026-10-12 | Proposed plan [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md). Slices M04.0–M07 are defined there and **not started** |
| TIP-02 | Pending owner — remaining decisions | D1/D7/D12/D14/D17 approved; remaining decisions follow their evidence gates (plan §18), not a blanket prerequisite for M04 |
| TIP-03 | Done — 2026-10-12 | Session breakdown [XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md): S00–S46, Proposed; recommended next S02 → S00 → S01 |
| TIP-04 | Done — 2026-10-12 | Plan audit [XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md). Plan 0.1.1 and session plan rev. 2: Conversation Layer A/B (D17), decisions after evidence (D2, D10, D11a/D11), D14 Flutter pin, D15 checkpoint S42a. All Proposed |
| TIP-05 | In progress — preparation complete | S02 documentation delivered; S00 PASS on Mac. Next S01 awaits board USB + real phone; ADR-0001 acceptance pending |
| TIP-06 | Done — 2026-10-12 | Owner approved D1, D7 (hatch on the device or via the app), D12, D14 (Flutter 3.32.8 pin) and D17 (Conversation A/B, text-first). Recorded in AGENTS.md §3 and plan §18; plan §12 and S06/S10 amended. Next: S02 (ADR-0001 + index) → S00 → S01 |

## Device-first direction checkpoint — 2026-10-12

| ID | Task status | Evidence / dependency |
|---|---|---|
| TIP-07 | Done — documentation only | [Device voice architecture](docs/architecture/XUNA_DEVICE_VOICE_ARCHITECTURE.md), plan 0.1.2/session rev. 3; owner direction recorded, implementation choices Proposed |
| VOICE-01 | Pending — Proposed | Owner research request; hardware feasibility report, no purchase/wiring |
| VOICE-02 | Conditional — Proposed | VOICE-01 + D18 + authorized real audio hardware |
| VOICE-03 | Conditional — Proposed | VOICE-02 + D19 research scope + D11a for cloud |
| VOICE-04 | Conditional — Proposed | VOICE-03 + final service/scope decisions D19/D20 (D11 if applicable) + S28; facts additionally S42 |

M04 S00–S21 remain unchanged in implementation scope. M05a/Foundation text or simulation stays independent of voice hardware; M05b keeps memory/privacy/recovery; M05c extends Foundation; M05d vs Evolution order remains D15/S42a. M06/M07 may consume validated voice-originated evidence without treating spoken reports as sensor observations. Next coding session remains S00 after S02 documentation; no feature session started here.

## S02 documentation delivery — 2026-10-12

Owner requested incremental execution. Decision index and Proposed ADR-0001 now exist; S02 documentation done criteria are met. ADR acceptance remains pending, no decision silently approved. Preserved prior uncommitted documentation. Corrected T14 table to match separately gated voice research; no implementation/dependency/hardware changes or commit/push. Next: S00 environment and baseline verification on the current Mac.

## Preparation execution — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S02 | Done — documentation deliverables | Decision index + Proposed ADR-0001; acceptance pending |
| S00 | Done — baseline PASS | PROCESS latest S00 record; firmware/host/mobile PASS; Flutter 3.32.8 pinned; lock unchanged |
| S01 | In progress — phone acceptance deferred | ESP32 connected; partition/NVS backup verified with hashes (PROCESS latest record). Phone-dependent transcript/acceptance pending |

No M04 implementation session started; no upload, commit/push or gitlink update. Mobile `.fvmrc` is uncommitted.

## Firmware-first checkpoint — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S03 | Done | [v1 characterization record](docs/roadmap/S03-v1-characterization.md); golden fixtures, host/sanitizer suites and ESP32 build PASS; production unchanged |
| S04 | Done | [Portable core record](docs/roadmap/S04-portable-core.md); native/sanitizers/build PASS, zero size delta; no upload |
| S01 | In progress — app work deferred | ESP32 backup prepared; owner chose Android for future native/BLE/physical acceptance, not yet validated |

No commit/push or gitlink change; firmware tests/README are uncommitted.

## S04 handoff — 2026-10-12

S04 complete: portable core, Unity suites, native environments and purity guard. Next S05 fixed-point/RNG/ClockModel (pure firmware), with S07 also eligible. Keep Android app work deferred and S01 board-upload gates. Verification evidence: [S04 record](docs/roadmap/S04-portable-core.md). Changes uncommitted; gitlinks unchanged.

## S05 checkpoint — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S05 | Done — pure logic | [Foundation evidence](docs/roadmap/S05-foundation-primitives.md); native/sanitizer 12/12 PASS; target compile smoke and ESP32 build PASS; no wiring/upload |
| S06 | Pending — pure part eligible | Board/NVS steps still require S01; no work started |
| S07 | Pending — recommended next | S04 prerequisite met; host-only event/registry/queue work while Android acceptance is deferred |

This follows existing dependency order; M04 still precedes M05. No app/hardware work, commit/push or gitlink update.

## S07 checkpoint — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S07 | Done | [Event foundation record](docs/roadmap/S07-events.md); native/sanitizer 18/18, Xtensa smoke and ESP32 build PASS |
| S05-fix-01 | Done | [Time epoch fix](docs/roadmap/S05-fix-01-time-epoch.md); native/sanitizer 19/19 and target compile/build PASS; no deployed state migration |

User preference: explain each session's purpose/scope in clear Vietnamese before starting. No firmware wiring/upload, commit/push or app work in S07.

## S05-fix-01 handoff — 2026-10-12

Compact UTC-minute epoch aligned with event contract; regression and target checks PASS. Next S06 pure identity/hatch/migration, leaving board/NVS acceptance gated on S01. No upload, commit/push or app work.

## S06 partial checkpoint — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S06 | In progress — pure core implemented | [Identity core record](docs/roadmap/S06-identity-core.md); native/sanitizer 23/23 PASS; target smoke/build PASS. Storage/RNG/gesture/wiring/board checks pending S01 |
| S14 | Pending — next eligible firmware session | ActivityFsm pure logic; S07 prerequisite met. Does not bypass S06/S01 integration gates |

No board upload/NVS operation, app work, commit/push or gitlink change.

## S11 preparation checkpoint — 2026-10-12

| Item | Status | Evidence / next step |
|---|---|---|
| S11 harness/restore preparation | Done — builds only | [E4/E5 record](docs/research/E4-E5-storage.md); external isolated projects, no firmware merge |
| S11 runtime E4/E5 | Pending prerequisites | Board USB absent; reconnect, refreshed NVS/full-image backup, S01 or explicit experiment exception; owner power-cut participation |
| ADR-0002 / D2 | Proposed / undecided | Draft created; choose storage only after measurements |

Earlier "S11 can run without Android" means the measurements do not need Android; it does not waive the S01 upload/baseline gate. S11 is not Done. No upload, format, commit/push or gitlink change.

## Static UI priority — 2026-10-12

| Item | Status | Evidence / next action |
|---|---|---|
| UI-static-01 reference scene | Done — build/upload/owner visual PASS | [Static scene record](docs/roadmap/UI-static-scene.md); RGB565 Flash, one-time draw, 23/23 host regression, fresh NVS preserved |
| S11 runtime | Deferred — owner explicitly paused | Prepared harness retained; do not resume or upload benchmark without owner request/gates |
| S01 Android acceptance | Pending | Static LCD acceptance does not validate BLE/learning/persistence matrix |

Firmware UI upload specifically authorized by current user request; existing milestone/storage decisions remain unchanged. No commit/push or gitlink update. Exact PCB revision and long-run/thermal validation remain open.

## Animated UI / publication checkpoint — 2026-10-12

| Item | Status | Evidence |
|---|---|---|
| UI-animation-02 | Implemented; owner provisionally accepted | [Animated scene record](docs/roadmap/UI-animated-scene.md); final build/upload PASS, native/sanitizers 25/25, corrected seam/dark toes |
| Today's Git delivery | Done in parent commit containing this entry | Firmware c84d4e3; mobile 77d27ec; parent docs and child gitlinks; no push |
| S11 | Paused at owner's request | Source archive preserved; runtime/D2 not performed/approved |
| S01 / full S06 | Pending | Android/BLE baseline and identity storage/wiring checks remain open |

No automatic next feature session or S11 resume. Wait for owner's next UI/session request. PCB revision, long-run/thermal and full BLE regression remain unvalidated.

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

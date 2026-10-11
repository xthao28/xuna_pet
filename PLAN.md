# XUNA — Work Plan

Last updated: **2026-10-11** (Asia/Ho_Chi_Minh).

Read [AGENTS.md](AGENTS.md) for canonical instructions and [PROCESS.md](PROCESS.md) for current context. This file owns the ordered task list and task status. [CHANGELOG.md](CHANGELOG.md) records work actually performed; [M01 validation record](docs/roadmap/M01-bring-up.md) owns detailed acceptance evidence.

Current priority: finish M01 physical validation. A previous successful temporary-toolchain build does not complete P01 in the owner's normal IDE environment. Task statuses are a snapshot and must be checked against new evidence.

## 1. Immediate execution plan — finish M01

Execute in order; update status/evidence after each step.

| ID | Status | Task | Who / dependency | Completion evidence |
| --- | --- | --- | --- | --- |
| P01 | Pending | Finish PlatformIO IDE installation; open `firmware/`; verify CLI availability and rebuild in the owner's normal environment | Owner/AI; local environment | `pio --version` and successful build log |
| P02 | Pending | Connect USB-C data cable; record board markings/revision and detected serial port | Owner physical action | Board identification and port recorded |
| P03 | Pending | Upload M01; capture startup Serial output | Owner/AI once board is available | Upload succeeds; version, Flash/PSRAM and init logs recorded |
| P04 | Pending | Check branding, geometry/colors, idle animation, both buttons, timeout and held-button behavior | Owner physical observation | M01 checklist results, observed failures if any |
| P05 | Pending | Collect idle/happy diagnostics; run at least 10 minutes; test resets and startup without Monitor | Owner with AI analysis | Runtime measurements and stability notes |
| P06 | Conditional — if issues appear | Fix only observed M01 issues, then rebuild and repeat affected checks | AI; failure evidence | Relevant tests/build pass and hardware recheck |
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

## 2. Proposed next milestone plan — after M01 validation

This is planning context, not permission to implement M02 in a future session without a request.

**M02 — Flutter + BLE smallest vertical slice:** phone discovers/connects to the device, requests an animation, and receives device status. Do not add voice, backend or digital-life systems to this slice.

1. Prepare a short protocol proposal: service/characteristic UUIDs, schema version, capabilities, minimal animation command/status payload, request IDs, validation, error behavior, timeouts and reconnect/idempotency rules.
2. Confirm unresolved ownership/synchronization policies before implementing pet-life state. The device-authoritative direction is still Proposed in AGENTS.md. M02 can exchange animation/status without prematurely designing persistent life-state synchronization.
3. Evaluate BLE libraries and target mobile OS against actual compatibility/permissions. Flutter state-management selection is not approved; choose only after a scoped proposal.
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

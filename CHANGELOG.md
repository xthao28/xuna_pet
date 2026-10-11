# XUNA — Change and Session History

Last updated: **2026-10-11** (Asia/Ho_Chi_Minh).

This file records work actually performed, including uncommitted changes, validation and handoff updates. Entries are not evidence that a Git commit or release exists. Read [PROCESS.md](PROCESS.md) for the current snapshot and [PLAN.md](PLAN.md) for remaining work. AGENTS.md remains canonical for decisions.

## 2026-10-11 — Commit current work

- Request: owner authorized committing current changes; related task P08.
- Git: firmware commit `be5829d` (`feat: implement XUNA M01 T-Display-S3 hardware bring-up`); parent documentation and firmware pointer committed together in the commit containing this entry. No push requested or performed. Mobile/backend unchanged.
- Changes: refreshed PROCESS.md Git snapshot and marked P08 Done. Earlier uncommitted-state entries describe the state at their recorded time.
- Validation: whitespace checks passed; existing build/host-test evidence retained. No new firmware build or hardware validation performed for this Git handoff.
- Next: P01–P05; M01 remains Implemented, physical validation pending.

## 2026-10-11 — Separate context, plan and history

- Request: split the session handoff into separate plan and change-history files.
- Changes: created PLAN.md with stable P01–P08 task IDs/statuses and the Proposed M02 plan; created CHANGELOG.md; replaced the duplicated plan/history in PROCESS.md with links; updated agent entry instructions.
- Validation: documentation links checked locally; Git whitespace checks passed. Firmware build/tests were not rerun for this documentation-only change.
- Git: no commit/push; existing firmware changes preserved; mobile/backend unchanged.
- Next: P01, then board identification/upload/physical checks in P02–P05.

## 2026-10-11 — Establish the session handoff

- Changes: created PROCESS.md with product context, repository snapshot, M01 implementation/evidence, ordered next tasks and a prompt for the next AI; added handoff links in AGENTS.md and CLAUDE.md.
- Validation: inspected Git and existing source/records; whitespace checks passed. No new firmware compilation or physical verification performed.
- Git: changes remain uncommitted; no commit/push.
- Next: complete normal IDE tooling and validate M01 on the actual board.

## 2026-10-10 — Implement M01 hardware bring-up

- Changes: inspected initialized submodules and official LILYGO documentation; implemented modular firmware, LCD branding/original sprite, idle/happy animation, debounced buttons and diagnostics; added host tests, setup/validation documentation, ignore rules and CLAUDE.md.
- Fix: first build failed because Setup206 was not in the global include path for framework-library compilation; corrected platformio.ini and rebuilt successfully.
- Validation: firmware build PASS; host tests and ASan/UBSan PASS; configuration parsing and whitespace checks PASS. Linker static RAM 21,840 bytes; firmware 319,709 bytes. Detailed evidence: [M01 record](docs/roadmap/M01-bring-up.md).
- Limits: no board USB serial device detected in that session; no upload, physical LCD/button test, runtime measurement or PCB revision verification. M01 is Implemented, not Validated.
- Git: firmware and parent docs left uncommitted; no commit/push; mobile/backend unchanged.
- Next: build in normal IDE environment, then flash and physically validate.

## Entry template for future sessions

Add new entries above older entries. For multiple entries on the same date, include a descriptive title. Preserve earlier results; add a correction entry when evidence changes rather than silently rewriting history.

```markdown
## YYYY-MM-DD — Concrete change title

- Request / related task IDs:
- Changes: files and observable behavior changed.
- Decisions: status and reference; omit if none.
- Validation: exact commands/results or link to evidence; say what was not run.
- Limits / blockers:
- Git: commit hashes/pointer changes/push status, or uncommitted.
- Next: remaining task IDs and immediate action.
```

Do not store secrets or long raw logs here. Link to milestone records for detailed hardware/build evidence. Every meaningful implementation, fix, validation result or plan change should leave an entry.

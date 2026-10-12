# XUNA — Process and Session Handoff

Last updated: **2026-10-12** (Asia/Ho_Chi_Minh).
Current milestone: **Planning for M04–M05 complete; M04 not started.** The local MVP through M05 is implemented, but its physical acceptance is pending.
Current status:

- Technical plan, session plan rev. 2 and audit written: status Proposed.
- Owner approved D1, D7, D12, D14 and D17 on 2026-10-12.
- No M04 code exists.

Next action: session **S02 → S00 → S01**; see §0 below.

## 0. Start here — next work (updated 2026-10-12)

**Read first.** AGENTS.md (canonical) → this section → [XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md):

- §2 rules;
- §3 session map;
- the entry for the session you run.

Then read only the sections of [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md) that the session cites. The rationale for the current plan is in [XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md).

**Where things stand:**

- **Local MVP through M05:**
  - Implemented: firmware `be58099`, mobile `3846880`; backend `0032828` is a README only.
  - Build, upload, LCD and buttons PASS.
  - **Pending:** real-phone BLE, learning, reboot, power-loss and forget acceptance (PLAN MVP-07). M01 PCB revision/P07 also remain open.
- **Approved on 2026-10-12** (AGENTS.md §3):
  - **D1:** M04 before new M05 features.
  - **D7:** hatch on the device or via the app (opcode 7); exact `bornAt` only with trusted time in the hatch boot; the MVP pet migrates as Newborn.
  - **D12:** C++11 core.
  - **D14:** Flutter 3.32.8 pinned via `mobile/.fvmrc` (file not created yet).
  - **D17:** Conversation Layer A with M05a, text-first; Layer B after M05b.
- **This Windows machine (2026-10-12):**
  - no PlatformIO, no host C++ compiler, no real Python (Store alias only), no WSL distribution;
  - Flutter 3.41.1 via fvm, with 3.32.8 not installed.
  - iOS builds and runs need the Mac.

**Next sessions, in order** (full steps in the session plan §6):

| # | Session | Work | Owner input needed | Done when |
|---|---|---|---|---|
| 1 | **S02** (S, no tooling) | Create `docs/decisions/README.md` (index of approved D-decisions + ADR template) and `docs/decisions/ADR-0001-reference-reuse-policy.md` from plan §6.3 | Accept ADR-0001 or not | Both files exist; Git state reported |
| 2 | **S00** (M) | Install the PlatformIO IDE extension; install a host compiler; `fvm install 3.32.8` + `mobile/.fvmrc`. Baselines: host tests; `pio run` (expect static RAM 47,504 B, image 964,333 B); `flutter analyze` + `flutter test` (10 tests); `pubspec.lock` unchanged | Choose MSYS2 or WSL for the compiler; OK to commit `.fvmrc` | Versions and baselines recorded in this file |
| 3 | **S01** (Owner) | MVP physical acceptance with the phone, plus observed v1 bytes from a BLE inspector. **Verified NVS backup first** (session plan §5) | Board, phone and Mac time | MVP-local.md updated; MVP-07 status set |

After that, follow the session map:

- S03 → S04 → S05/S07 → S06 → S08a → S08b → S09 → S10 → S11 …
- S03–S05 and S07 are host-only and may run after S00 while S01 waits for the phone.
- No refactored or storage-changing firmware goes onto the owner's board before S01.

**Open decisions:**

| Decision | When |
|---|---|
| D2 | After experiment S11 |
| D10 | After experiment S35 |
| D15 | At checkpoint S42a |
| D3–D6, optional D16 | Session S22, before S23 |
| D8, D9 | Session S29, before S30 |
| D11a / D11 | Only if cloud STT/LLM is to be evaluated |
| D13 | M06 |

**Working rules to keep:**

- Start a session only when the owner asks.
- One session at a time; respect its preconditions and done criteria.
- Discuss in Vietnamese; keep docs and code in English.
- Commit or push only on the owner's request:
  - follow the existing format: a single-line conventional message such as `docs: ...` or `feat: ...`;
  - **no AI attribution or trailers anywhere**;
  - child repo first, then the parent gitlink.
- Update this section, PLAN.md and CHANGELOG.md at the end of every session.

**Git when this section was written:** the root repo had uncommitted documentation changes:

- `AGENTS.md`, `CHANGELOG.md`, `PLAN.md`, `PROCESS.md`;
- the plan and the session plan;
- the new audit file.

Check `git status` before starting.

## 1. Read order and authority

1. Read [AGENTS.md](AGENTS.md) completely: canonical product intent, approved decisions and agent rules.
2. Read this file for working context, then [PLAN.md](PLAN.md) for tasks and the latest entries in [CHANGELOG.md](CHANGELOG.md) for recent changes.
3. Read [M01 validation record](docs/roadmap/M01-bring-up.md), [firmware README](firmware/README.md) and relevant source before editing.
4. Inspect actual Git status in the parent and affected submodules. This snapshot is not live state.

This file is an operational handoff, not a replacement for AGENTS.md. Plans in PLAN.md do not approve unresolved architectural decisions or authorize starting later milestones. When this file conflicts with implementation or newer evidence, inspect the discrepancy and update it without discarding history.

## 2. Product and scope context

XUNA is a persistent, local-first digital lifeform on physical hardware, expressed through pixel art. Experiences should eventually shape memory, preferences, behavior and explainable evolution. The current button reactions are scripted animation, **not AI learning**.

Approved directions include the XUNA name, VS Code + PlatformIO, existing LILYGO T-Display-S3 hardware, Flutter companion direction and incremental milestones. Arduino is authorized for this initial bring-up; a permanent Arduino-versus-ESP-IDF decision remains open. Conversation belongs alongside learning in M05. Core pet life must not require cloud connectivity.

Current implementation scope is LCD, original placeholder sprite, buttons, animation and diagnostics. BLE, backend, voice, sensors, persistence, learning and evolution are not part of M01.

## 3. Repository and Git snapshot

Repository: `/Users/xthao28/xuna_pet`, remote: `https://github.com/xthao28/xuna_pet`.

| Path | Independent repository | Recorded gitlink |
| --- | --- | --- |
| `firmware/` | `xthao28/xuna_firmware` | `be5829d (firmware commit; parent pointer updated with this handoff commit)` |
| `mobile/` | `xthao28/xuna_mobile` | `310e69f614f88cb3649ddef67ac758014c9ffb32` |
| `backend/` | `xthao28/xuna_backend` | `0032828abb4c754d7222dc3aaed24a630d92bc56` |

All three submodules exist and are initialized. Firmware originally contained only a placeholder README. M01 firmware changes are committed as `be5829d`. The owner requested committing the current changes on 2026-10-11; parent documentation and the new firmware pointer are included in the parent commit containing this snapshot. Mobile/backend remain unchanged. No push has been performed. Inspect Git for changes made after this snapshot.

Before doing work:

```sh
git status --short
git submodule status
git -C firmware status --short
git -C mobile status --short
git -C backend status --short
```

Preserve dirty/untracked files. Do not reset, recreate submodules or initialize nested repositories. Firmware commits must happen inside the child repository before updating its pointer in the parent. Never treat a dirty submodule as a committed delivery.

## 4. Implemented M01 slice

Firmware version: `0.1.0-m01`.

| File or module | Responsibility |
| --- | --- |
| `firmware/platformio.ini` | Pinned PlatformIO, MCU/memory configuration, display library/setup |
| `firmware/include/AppConfig.h` | Pins, version, rotation and timing constants |
| `firmware/include/DebouncedButton.h` | Pure C++ press-edge debounce |
| `firmware/include/InputManager.h`, `firmware/src/InputManager.cpp` | Active-low GPIO adapter for two buttons |
| `firmware/include/AnimationManager.h` | Pure C++ idle/happy state and frame timing |
| `firmware/include/DisplayManager.h`, `firmware/src/DisplayManager.cpp` | LCD initialization, branding and original sprite rendering |
| `firmware/src/main.cpp` | Setup, bounded loop, event mapping and serial diagnostics |
| `firmware/test/test_core.cpp` | Host tests for debounce and animation |
| `firmware/README.md` | Setup, commands, sources, limitations and licensing notes |
| `docs/roadmap/M01-bring-up.md` | Build evidence and physical acceptance checklist |
| `.gitignore`, `firmware/.gitignore`, `CLAUDE.md` | Local artifact exclusions and agent entry point |

Behavior:

- Two frames per state; idle interval 400 ms, happy interval 160 ms.
- GPIO0/BOOT requests happy for 2400 ms; a new press restarts the timer.
- GPIO14 requests idle; idle wins simultaneous press events.
- Debounce is 30 ms; held buttons do not auto-repeat. A button held at app startup must be released before another press is emitted.
- Unsigned elapsed-time math handles rollover; late frames are skipped with bounded work.
- One 80×80 RGB565 sprite is allocated during setup (12,800 bytes plus library overhead). Only the sprite region redraws each frame.
- Logs every 5 seconds: state, rendered FPS, average/max render duration, max loop gap, heap/min heap and PSRAM. Rendered FPS is animation cadence, not panel refresh capacity.
- No application-loop delay or serial-host wait. LCD transfers and Serial writes are synchronous; real latency is unmeasured.
- Sprite allocation failure disables rendering while input/logging continue. TFT_eSPI cannot confirm physical LCD presence or successful visual output.

## 5. Hardware and toolchain facts versus assumptions

**Documented configuration:** standard 1.9-inch 170×320 ST7789 LCD, ESP32-S3R8, expected 16 MB Flash / 8 MB OPI PSRAM. LCD interface is parallel 8-bit, not SPI.

- LCD D0–D7: GPIO39,40,41,42,45,46,47,48.
- LCD CS=6, DC=7, RST=5, WR=8, RD=9.
- Peripheral power GPIO15 HIGH; backlight GPIO38.
- Buttons GPIO0 and GPIO14, active-low. Holding GPIO0 during reset enters download mode.
- Rotation defaults to `1` (320×170 landscape).

**Assumption awaiting physical confirmation:** the owner's board matches this standard LCD pinout; PCB revision is not recorded. Do not apply this configuration to AMOLED or another variant.

**Pinned build:** `espressif32@6.5.0`, Arduino ESP32 2.0.14, `bodmer/TFT_eSPI@2.5.43`, Setup206. The generic `esp32-s3-devkitc-1` supplies the MCU target; explicit overrides select 16 MB Flash, QIO/80 MHz, `qio_opi` and `default_16MB.csv`. LCD pins come from Setup206, with compile-time assertions. Do not remove the global TFT_eSPI include path: the first build failed without it in framework-library compilation.

Official source links and license notes are in the firmware README. Check current official documentation again before changing dependencies or hardware configuration; do not upgrade libraries merely to silence warnings.

## 6. Verification evidence and gaps

Results recorded on **2026-10-10**, not rerun merely to create this handoff:

| Check | Recorded result |
| --- | --- |
| PlatformIO configuration parsing | PASS |
| ESP32-S3 firmware compilation | PASS; `.bin` and `.elf` generated |
| Host C++ tests with warnings as errors | PASS |
| Host AddressSanitizer / UndefinedBehaviorSanitizer | PASS |
| Git whitespace checks | PASS |
| Linker static RAM | 21,840 / 327,680 bytes |
| Firmware / app partition | 319,709 / 6,553,600 bytes |
| Connected ESP32 USB serial device | Not detected in previous session |
| Flash/upload, LCD and electrical buttons | Not tested |
| Runtime heap/PSRAM, render timing, stability | Not measured |
| Exact PCB revision / standalone boot | Not verified |

Linker figures exclude runtime allocation and cannot establish free heap or display performance. Physical results must be entered into the M01 record; do not invent measurements.

Known upstream warnings: parallel DMA unavailable, touch unconfigured, and an Arduino 2.0.14 non-void return warning in UART code. No project compile errors remained after the include-path fix.

The agent used temporary tooling:

```sh
PLATFORMIO_CORE_DIR=/private/tmp/xuna-m01-pio-core /private/tmp/xuna-m01-pio/bin/pio run -d firmware
```

Those temporary directories may disappear. VS Code's PlatformIO installation is a separate environment; the open IDE installation tab does not establish that installation has finished. Confirm it before relying on `pio` in the IDE terminal.

## 7. Plan and history

- [PLAN.md](PLAN.md): ordered M01 tasks P01–P08, their statuses/dependencies, execution commands and the Proposed M02 plan.
- [CHANGELOG.md](CHANGELOG.md): dated implementation, fixes, validation outcomes and session changes. This includes uncommitted work, not only Git commits.
- [M01 validation record](docs/roadmap/M01-bring-up.md): detailed physical checklist and measurement evidence.

Current run (2026-10-11): owner confirmed continuing after connection checkpoint. Normal IDE Core 6.2.0 build/upload PASS; host tests PASS. Board model read by owner: T-Display-S3, PCB revision unknown. Basic LCD/animation/buttons passed by owner observation. A false PSRAM warning was fixed in firmware diagnostics and the corrected build uploaded; Flash 16 MiB, PSRAM chip 8 MiB confirmed. More than 10 minutes of stable diagnostics passed; owner confirmed RST/USB startup and buttons with Monitor closed. PCB revision/final P07 review remain open; see [physical run](docs/roadmap/M01-bring-up.md#build-upload-and-physical-run--2026-10-11). Root HEAD remains `3dda411`, firmware HEAD `be5829d`; firmware now has uncommitted diagnostics/README changes, parent handoff docs uncommitted. Mobile/backend unchanged; no commit/push. Firmware gitlink still points to committed `be5829d`, not the uncommitted uploaded fix.

## 8. Session update procedure

At the start of a session, read the files in section 1, inspect Git and choose the first incomplete authorized task. Re-check facts that may have changed, such as tool availability, board connection or dirty files. Report in Vietnamese.

At the end of each work session, update:

- Last-updated date, current milestone/status and exact next action.
- Files/behavior changed and decisions, preserving Idea/Proposed/Approved distinctions.
- Commands actually run, pass/fail results and where evidence is stored.
- Hardware measurements separately from build figures.
- Blockers, unresolved questions and user actions needed.
- Git state: uncommitted changes, commits, submodule pointer changes and push status.
- Update task statuses and remaining work in PLAN.md.
- Append a dated entry to CHANGELOG.md; preserve previous entries and link to evidence.

Do not store credentials, tokens or other secrets here. Use links to detailed records instead of duplicating lengthy logs. A stopped session or successful compile does not mean a milestone is Validated.

## 9. Copyable prompt for the next AI/session

> Read AGENTS.md, then PROCESS.md §0 "Start here", then docs/roadmap/XUNA_SESSION_PLAN.md (§2 rules, §3 map, and the entry of the next session), and only the cited sections of docs/architecture/XUNA_IMPLEMENTATION_PLAN.md. Check the latest CHANGELOG.md entries. Inspect root and submodule Git.
>
> Current state:
>
> - Planning is complete. The owner approved D1, D7, D12, D14 and D17 on 2026-10-12.
> - No M04 code has started.
> - Local MVP physical acceptance (MVP-07) is pending.
>
> The next sessions are S02 → S00 → S01 unless PROCESS §0 says otherwise.
>
> Working rules:
>
> - Ask the owner before starting a session.
> - Follow that session's preconditions, steps and done criteria.
> - Never put refactored or storage-changing firmware on the owner's board before S01 and a verified NVS backup.
> - Report in Vietnamese.
> - Commit only on request, as single-line conventional messages with no AI attribution.
> - Keep Clean/GetX and the pinned firmware baseline.
> - The simulator requires `XUNA_SIMULATOR=true`.
> - Do not infer validation from commits or builds.

## Mobile base update — 2026-10-11

Owner explicitly confirmed retaining the imported Clean/GetX architecture for future mobile work. Scoped cleanup removed login/product-detail demos, province data/mappers, old backend URL and business-specific locale/constants; splash/home and generic core/shared infrastructure, packages and generators remain. Package/labels renamed to XUNA; network clients require explicit base URLs and are not initialized at startup. Mobile remains uncommitted at HEAD `310e69f`; no gitlink update or M02 implementation. Analyzer PASS after dependency resolution; no native build/device validation claimed for this final cleanup. Earlier minimal-scaffold results do not apply. Firmware changes and M01 status remain unchanged.

## M02 inspection — 2026-10-11

All repositories verified on dev; HEADs unchanged (root 3dda411, firmware be5829d, mobile 310e69f, backend 0032828). Root/firmware/mobile dirty; backend clean. No child edits, build/upload, commit/push or gitlink change during proposal work. Flutter 3.32.8/Dart 3.8.1, Xcode 14.2, booted iPhone 13/iOS 16.2 simulator, PlatformIO 6.2.0 and board USB detected. No real phone detected. Protocol/library trade-offs and future validation matrix are recorded in M02 proposal, all Proposed. Historical M01 snapshots above retain their original context; this current section supersedes older claims that mobile is unchanged or M02 must wait for M01 validation.

## Mobile simulator delivery — 2026-10-11

Owner approved proposal and explicitly requested simulator-first mobile commit/push. Mobile commit `24026b2` pushed successfully to `origin/dev`; mobile working tree clean. Includes previously uncommitted approved Clean/GetX base plus fake M02 feature/tests. Analyzer/4 tests/native simulator build PASS; flutter run opened Home on iPhone 13/iOS 16.2, screenshot inspected. Full interaction flow exercised in widget test, not native automated taps. CocoaPods locale failure fixed by command-local UTF-8 environment. No BLE dependency/physical adapter or firmware change in this slice. Root remains 3dda411 with uncommitted docs and changed mobile working HEAD; root gitlink remains 310e69f until an explicitly requested root commit. Firmware HEAD be5829d with earlier dirty changes preserved; backend clean. Physical BLE, Android native build and M01 PCB revision/P07 remain open.

## Local MVP implementation — 2026-10-11

Owner approved local MVP through M05, board ownership of state/memory/preference and template-based text without LLM. Firmware adds bundled BLE, LifeEngine, two-slot NVS snapshots, bounded confirmed feedback episodes and local learned quiet routine; mobile adds physical BLE repository, request correlation and learning/text/memory UI while retaining Clean/GetX. Simulator is explicit via XUNA_SIMULATOR=true; real transport is default. Flutter analyzer/10 tests/simulator build/run and host core/life tests with life sanitizers PASS. See local MVP record for exact scope, protocol extensions and unverified physical cases. Existing root/firmware changes preserved; new work is uncommitted. HEADs remain root3dda411/firmwarebe5829d/mobile24026b2/backend0032828. No new commit/push; previous mobile simulator commit remains published. Old Proposed/device-ownership snapshots above are historical and superseded only for the owner-approved local MVP.

## Uploaded board checkpoint — 2026-10-11

LILYGO now runs corrected 0.2.0-mvp; build/upload/hashes PASS, 22-second startup diagnostics captured; owner confirmed LCD and both buttons. Fixed first-boot NVS missing-key noise by isKey checks and reuploaded; corrected log clean. See MVP record for measured resource figures and limits. Physical iPhone BLE/learning/reboot persistence and M01 PCB revision/P07 remain pending. Owner now explicitly requested commit/push of current code; deliver child commits before root gitlinks.

## Current Git delivery — 2026-10-11

Owner requested publishing current code. Firmware `be58099980a316a5ebfe8e621fe68a31eb8dcff6` and mobile `3846880ea3fb3a2cc26f5b41469f62a1f7d85316` committed and pushed successfully to their origin/dev branches; both child working trees clean. Root snapshot commit containing this section records both updated gitlinks and all scoped handoff documents. Backend remains `0032828`, unchanged. This delivery supersedes historical uncommitted/old-pointer snapshots above. No force push, reset or unrelated repository edits. Physical iPhone BLE/learning/NVS acceptance and M01 PCB revision/P07 remain pending.

## Technical plan proposal — 2026-10-12

Submodules were initialized at the recorded gitlinks; nothing changed in the children.

Added [XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md), status **Proposed / planning only**. It integrates spec v0.3.0 §23–24 and the read-only ePet/Xiaozhi audits.

No code changes and no build, test, commit or push. The plan does not approve any slice.

Next action: the owner reviews decisions D1–D13, at minimum D1, D2 and D7. Then complete M04.0, which includes the pending MVP-07 physical acceptance, committing the spec, and ADR-0001. Only after that, start M04.1 if approved. MVP physical acceptance and M01 PCB revision/P07 remain open.

Session breakdown (2026-10-12): [XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md) splits the plan into sessions S00–S46 and assesses readiness. The plan was amended for three things:

- `bootc` uses its own NVS key;
- snapshot v2 is sectioned;
- TimeSync wiring happens after the command handler moves into the core.

Environment observed on this Windows machine:

- Flutter 3.41.1 via fvm (the project recorded 3.32.8);
- no PlatformIO, no host C++ compiler, no real Python;
- WSL has no distribution.

Recommended next sessions: S00 (toolchain and baseline), then S02 (decisions D1, D2, D7, D12 and ADR-0001), then S01 (MVP physical acceptance).

## Plan audit — 2026-10-12

Reviewed the plan against the owner-forwarded external checklist; report in [XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md). There were 17 findings, none Critical.

Main corrections, all **Proposed**:

- Conversation Foundation (Layer A) now develops together with M05a through the v1-additive opcode 6 `StatedPreference`, with joint acceptance S28. Personal facts stay in Layer B after M05b (D17).
- D2, D10 and D11 are decided after their experiments; D11a only authorizes the E12 spike.
- The Flutter SDK pin is decision D14. There is no `.fvmrc`; the lock requires Flutter ≥ 3.27.0. 3.32.8 is evidence only, not an approval.
- The NVS backup now verifies the partition table read from the device.
- S01 captures observed v1 bytes as the refactor baseline.
- S08, S12 and S19 are split into a/b sessions.
- Power-cut tests use write-storm builds.
- M05d versus an Evolution MVP is decided at checkpoint S42a (D15).

Approved decisions are unchanged. No firmware, mobile or backend change; no build, test or flash; no commit or push.

Next: S02 → S00 → S01.

## Owner decisions — 2026-10-12

The owner approved:

- **D1:** complete M04 (S03–S21) before new M05 features.
- **D7:** a pet hatches on the device (local gesture) **or** via the app (opcode 7). `bornAt` is exact only with trusted time in the hatch boot; otherwise it stays unknown. The existing MVP pet migrates as Newborn.
- **D12:** C++11 core.
- **D14:** pin Flutter 3.32.8 via `mobile/.fvmrc`.
- **D17:** Conversation Layer A with M05a, text-first; Layer B after M05b; voice still depends on D16.

These are recorded in AGENTS.md §3 and plan §18. The plan (§12, §8.2, §14.1) and sessions S02, S06 and S10 were amended accordingly.

Still open:

- D2, after S11; D10, after S35; D15, at S42a;
- D3–D6, D8, D9, D11a/D11, D13 and D16.

No code changes and no commit or push.

Next: S02 (ADR-0001 + decisions index) → S00 → S01.

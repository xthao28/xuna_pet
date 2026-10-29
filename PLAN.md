# XUNA — Work Plan

Last updated: **2026-10-29** (Asia/Ho_Chi_Minh).

Read [AGENTS.md](AGENTS.md) for canonical instructions and [PROCESS.md](PROCESS.md) for current context. This file owns the ordered task list and task status. [CHANGELOG.md](CHANGELOG.md) records work actually performed; [M01 validation record](docs/roadmap/milestones/M01-bring-up.md) owns detailed acceptance evidence.

Current priority: **Owner-approved local MVP through M05**. Implementation evidence and physical acceptance in [MVP record](docs/roadmap/milestones/MVP-local.md). M01 PCB revision/P07 remain open. M02–M05 builds/tests do not establish physical validation.

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
| LRN-01 | Done — 2026-10-15, documentation only | [Competitive learning upgrade plan](docs/architecture/XUNA_LEARNING_COMPETITIVE_UPGRADE.md); plan §9.4 Alt D, §9.9 scenarios, §9.10 tricks, §18 L-D1–L-D5 (all Proposed) |
| LRN-02 | Done — 2026-10-15 | Owner approved L-D1–L-D5 (L-D5: touch + IMU + mic research only). D5 and D15 remain open |
| LRN-05 | In progress — slices 1–5 done; board-trial shortcut built 2026-10-15 | Phase 1 learner v3 (lab/shadow): [record](docs/roadmap/learning/learner-v3-phase1-2026-10-15.md); E10 preliminary choice C, tuned γ 0.90 k 1 m 1 bonus 0.15 (Proposed); learner codec + capped v1 migration + §9.6 explanation + LifeCore shadow v3 + §9.5 commit-first parity done (lab); D5 vocabulary added; [E10 packet](docs/roadmap/learning/E10-review-packet-2026-10-15.md) approved (E10-A/B/C); next production gates S12a/D2, S10, S18 |
| LRN-04 | Architecture/D21/D22 and D23 baseline approved; implementation gated | Hybrid online layer: [Cloud plan](docs/architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md), [ADR-0007](docs/decisions/ADR-0007-hybrid-offline-online-learning.md); provider/broker/D24 open; E14/E15 not started |
| CLD-00 | Done (documentation only, 2026-10-16) | Cloud authority, identity, stack, privacy and Phase 0–6 baseline; no backend code |
| CLD-01 | Approved (owner-delegated) — 2026-10-17 | [Threat model](docs/architecture/XUNA_CLOUD_THREAT_MODEL.md): assets, flows F1–F9, STRIDE T1–T14; Proposed ordering key, `BrainId` semantics, unsigned exports = claims. Needs owner confirmation |
| CLD-02 | Draft — 2026-10-17 (not frozen) | [Contract draft](docs/architecture/XUNA_CLOUD_CONTRACT_DRAFT.md): conventions, problem codes, idempotency, draft resources, device proof proposal |
| CLD-10 | Scaffold done — 2026-10-17 | `backend/`: modular monolith, rules in `backend/AGENTS.md`, `scripts/check.sh` PASS (ruff, mypy strict, 38/38 pytest with PostgreSQL), CI workflow written (not yet run on GitHub) |
| CLD-11 | Backend done — 2026-10-17 | OIDC owner auth (vendor open), challenges, ECDSA P-256 TOFU pet binding, Pet/Brain/Device tables, idempotency; 59/59 tests with PostgreSQL. Needs firmware Identity V2 + app flow to bind the real pet |
| ID-V2 | Done on board — 2026-10-17 | [Record](docs/roadmap/cloud/identity-v2-2026-10-17.md): P-256 device key, BLE `7a6e000d` proof, E2E bind with local backend PASS. Mobile bind flow built 2026-10-18 (APP-BIND), not yet run on a phone |
| CLD-12 | Backend done — 2026-10-17 | U0-default consent with append-only history, `RequireConsent` guard, append-only audit trail (DB triggers), owner audit endpoint; 78/78 tests with PostgreSQL |
| CLD-13 | Adapter + first benchmark done — 2026-10-17 (Gemini temporary: `gemini-3.5-flash-lite`); persona "no hearing/seeing" rule re-benchmarked 2026-10-18 (14/14); Bifrost run pending its key | `openai_compatible` streaming adapter, conversation SSE endpoint (U3), Vietnamese benchmark script; internal AI over OpenVPN is the temporary provider. Needs the owner's endpoint URL/model and a VPN run |
| AUTH-FB | Validated end to end — 2026-10-17 (Play Store emulator + local backend) | Project `xuna-pet`; backend verifies Firebase ID tokens; app has Google sign-in, cloud check, sign-out (77/77 tests, APK PASS). Pending: enable Google provider + re-download config, real sign-in on phone/emulator, then the app bind flow (Identity V2 proof → `POST /v1/pets`) |
| VOICE-TTS-OVERLAP | Built — 2026-10-23 (host tests only) | `spoken_turn`: TTS overlaps the text stream (≤ 2 parallel, in-order audio, cancel on close), first piece may end at a comma, `finished.firstAudioMs`. check.sh with PostgreSQL 140 passed (Windows, PostgreSQL 16.15). Next: five phone turns |
| VOICE-WS | Proposed — 2026-10-23 | [WebSocket voice design](docs/roadmap/voice/voice-websocket-design-2026-10-23.md): slices WS-1…WS-4, owner decisions D-WS1…D-WS5 |
| APP-AUTOCONNECT | Built — 2026-10-23 (host tests only) | Reconnect to the last device on app open: `DevicePreferences` in `AppHive` (`device_preferences_v1`, default on), `AutoConnectDeviceUseCase` (find → connect → PetId check), `DeviceRepository.find` with early-stop scan, Device-tab toggle; scan button turns into "KẾT NỐI XUNA" after a scan; chat mic centred and 72 px. 182/182 tests. Next: phone + board run |
| APP-BIND | Built 2026-10-18; owner rebound the real pet from the iPhone 2026-10-23; phone checks reported done 2026-10-23 | Mobile: BLE `7a6e000d` proof codec/transport + capability byte 3 bit 0; cloud client for challenges/pets/consents (Idempotency-Key, `schemaVersion`, problem codes → Vietnamese); `BindPetToCloud`; Device-tab account card bind + U1–U3 consent sheet; chat streams AI replies (SSE) when signed in + bound + U3, local templates otherwise. 119/119 tests. Next: phone validation (PROCESS "Next session plan") |
| CLD-14 | Gated by Cloud gate (c) | Candidate/confirm/device-commit pipeline | Snapshot v2 on the board + durable `PetId` over BLE + local export; then contracts, scaffold, auth/identity, consent, provider benchmark and confirmation pipeline |
| S19b | Done (host) — 2026-10-19 | D/E/stability scenarios on `BoardLab`; boot policy in `xuna_core` `BootSequence` (main.cpp uses it; board upload + boot re-check pending). Egg devices no longer save before hatching (`IdentityGatedCommit`), so they keep booting |
| CLD-20 | Planned after Phase 1 | Encrypted backup, export, restore and deletion |
| CLD-30–31 | Gated by E15 | Cloud consolidation experiment and bounded suggestions |
| CLD-40–41 | Gated by E14 + D19/D22 | Direct-device MQTT/TLS |
| CLD-50/60 | Gated by VOICE decisions / D24 | Voice services and commercial readiness |
| LRN-03 | In progress — slices 1–2 done 2026-10-15 | [Phase 0 record](docs/roadmap/learning/life-lab-phase0-2026-10-15.md): closed-loop learner bench, 95/95 native PASS; slice 2: [needs timeline](docs/roadmap/learning/life-lab-needs-timeline-2026-10-15.md), candidate values await owner decision |
| TRIAL-01 | Superseded — 2026-10-16 | Its production path (learner v3 + life-feel + needs/activity Serial log) shipped with the 2026-10-16 artwork upload; owner smoke PASS. The 1–2 h capture was owner-skipped (not validated). Do not upload `5d872d3` |
| S12a | Done on host — 2026-10-15 (ahead of D2, owner choice) | [S12 record](docs/roadmap/sessions/S12-snapshot-v2-2026-10-15.md); layout frozen in plan §7.5; `xuna/persist/SnapshotCodec.h` |
| S12b | Done on host — 2026-10-15 | v1→v2 migration (E10-C cap), `ISnapshotStore` A/B recovery/commit, every-offset torn-write sweep; native 143/143 PASS |
| S18-prep | Done on host — 2026-10-15 | [S18 preparation record](docs/roadmap/sessions/S18-prep-product-learner-2026-10-15.md): `LifeCore` = v3 3 × 5 × 3 via `ProductLearner` + LifeSnapshot v2; GPIO0 `button_greeting`, curious; snapshot lab/trace on v2; native 152/152 PASS. Production unchanged |
| S10-host/codec | Host + design + pure codecs done — 2026-10-16 | [S10 record](docs/roadmap/sessions/S10-host-trusted-time-2026-10-15.md): `ClockModel`, day-part cells, approved opcode 5/7 and Lifecycle V1; feature-gated C++ parser/cache/codec plus Dart encode/decode models and golden tests. Firmware native 182/182, ESP32 build/purity PASS; mobile analyze clean, 45/45 PASS. CommandHandler, transport/UI and board/phone validation remain pending S09/S13/S18 gates |
| S10-sync | Source/host/build + Android install smoke done — 2026-10-17; not uploaded | [Record](docs/roadmap/sessions/S10-sync-2026-10-17.md): production opcode 5, 16-byte BLE queue, capability bit 4, Serial diagnostics, mobile connect + six-hour sync. Firmware native/ESP32 PASS; Flutter analyze and 60/60 tests PASS. AGP 8.2.2 resolves JDK 21 build; APK install/launch PASS. ESP32 physical acceptance pending. |
| S10-hatch | Done on host — 2026-10-29; board upload pending | Production opcode 7 (`Hatch`), same-boot `bornAt` backfill on `TimeSync`, 3-second `GPIO14` hold hatch in `Egg` (`EggHatchHold`), BLE `Lifecycle V1` (`7a6e0013`, capability byte 2 bit 6 = `0x40`), and mobile Egg hatch banner + `TimeSync`-first confirmation flow + `HomeDeviceInfoSheet` lifecycle/clock/birth rows. Firmware native 382/382 PASS, ESP32 build PASS; mobile analyze clean, 334/334 PASS. |
| CLOUD-SPRINT | Done — gate (c) owner-reported met 2026-10-23 (phone export + hash check; measurements not recorded). A + B + C done; D firmware uploaded and gate (b) met on board 2026-10-17 (GATT handle fix) | [Sprint record](docs/roadmap/cloud/cloud-gate-sprint-2026-10-17.md): A firmware Identity V1 (`7a6e000c`, bit 7) — native/ASan 195/195, ESP32 PASS; B mobile identity + `xuna.export.v1` JSON export — analyze clean, 72/72 PASS. C backend CLD-10/11/12/13 done (CLD-01 approved by delegation, CLD-02 draft); D board upload done 2026-10-17, gate (c) waits for the upgraded app on a phone. All committed and pushed to `origin/dev` |
| D3 | Approved and implemented in core — 2026-10-15 | 120 s feedback window, direct input invalidates; `ProductLearner`/`LifeCore` expiry, native 164/164. BLE result code for `expired` and board-trial firmware pending (S18) |
| S22 | Done — 2026-10-15 (owner decisions) | [S22 packet](docs/roadmap/sessions/S22-decision-packet-2026-10-15.md): D4 UCB labelled in "Why?", D6 off, "mình – bạn", vi-first, follow-up for missing context, phrase table approved, D16 deferred. Next: S39 (pure Dart extractor) |
| S39 | Done — 2026-10-15 (mobile, pure Dart) | [S39 record](docs/roadmap/sessions/S39-layer-a-extractor-2026-10-15.md): Layer A LocalRuleExtractor + `CandidateEvent`; mobile 39/39 PASS, analyze clean. Not wired (S27a); device opcode 6 is S24a |
| S24a | Done on host — 2026-10-15 | [S24a record](docs/roadmap/sessions/S24a-stated-preference-2026-10-15.md): opcode 6 parse (flagged off in production), stated evidence w_s 0.5 / cap 2 [P], explanation `Told`, section 12; native 179/179. ESP32 RAM +648 B (shared learner cells). Wiring S18, app S27a, tuning S25 |
| S13 + S18 | Implemented + initial board smoke PASS — 2026-10-16; remaining board checks owner-skipped, not validated | Production switch to `LifeCore` + LifeSnapshot v2 in NVS `life0/life1` (v1 keys kept as rollback), ERROR_SAFE, commit budget, `IdentityRecord` MigratedFromV1; static scratch (recover ≈ 6 KB stack on Xtensa). Absorbs S08b/S09 |

M04 S00–S21 remain unchanged in implementation scope. M05a/Foundation text or simulation stays independent of voice hardware; M05b keeps memory/privacy/recovery; M05c extends Foundation; M05d vs Evolution order remains D15/S42a. M06/M07 may consume validated voice-originated evidence without treating spoken reports as sensor observations. (Historical 2026-10-12 note; for current next sessions see session plan §9.)

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
| S03 | Done | [v1 characterization record](docs/roadmap/sessions/S03-v1-characterization.md); golden fixtures, host/sanitizer suites and ESP32 build PASS; production unchanged |
| S04 | Done | [Portable core record](docs/roadmap/sessions/S04-portable-core.md); native/sanitizers/build PASS, zero size delta; no upload |
| S01 | In progress — app work deferred | ESP32 backup prepared; owner chose Android for future native/BLE/physical acceptance, not yet validated |

No commit/push or gitlink change; firmware tests/README are uncommitted.

## S04 handoff — 2026-10-12

S04 complete: portable core, Unity suites, native environments and purity guard. Next S05 fixed-point/RNG/ClockModel (pure firmware), with S07 also eligible. Keep Android app work deferred and S01 board-upload gates. Verification evidence: [S04 record](docs/roadmap/sessions/S04-portable-core.md). Changes uncommitted; gitlinks unchanged.

## S05 checkpoint — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S05 | Done — pure logic | [Foundation evidence](docs/roadmap/sessions/S05-foundation-primitives.md); native/sanitizer 12/12 PASS; target compile smoke and ESP32 build PASS; no wiring/upload |
| S06 | Pending — pure part eligible | Board/NVS steps still require S01; no work started |
| S07 | Pending — recommended next | S04 prerequisite met; host-only event/registry/queue work while Android acceptance is deferred |

This follows existing dependency order; M04 still precedes M05. No app/hardware work, commit/push or gitlink update.

## S27a checkpoint - 2026-10-16

Mobile simulator wiring is in progress: candidate confirmation, context follow-up, opcode 3/6 encoding and capability gating are implemented. Flutter analyze PASS and 40/40 tests PASS. Device-grounded explanation replies remain pending S26/S27.

## S25/S26 checkpoint - 2026-10-16

Owner approved `w_s=0.5`, cap 2 as S26 starting defaults. Stated-vs-rated and pre-cap sensitivity evidence is recorded under `docs/research/`. The pure 20-byte explanation codec and golden test pass on host; ESP32 build passes unchanged. Production wiring remains gated by S13/S18 because BoardLearner plus snapshot v1 cannot persist stated evidence.

## S07 checkpoint — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S07 | Done | [Event foundation record](docs/roadmap/sessions/S07-events.md); native/sanitizer 18/18, Xtensa smoke and ESP32 build PASS |
| S05-fix-01 | Done | [Time epoch fix](docs/roadmap/sessions/S05-fix-01-time-epoch.md); native/sanitizer 19/19 and target compile/build PASS; no deployed state migration |

User preference: explain each session's purpose/scope in clear Vietnamese before starting. No firmware wiring/upload, commit/push or app work in S07.

## S05-fix-01 handoff — 2026-10-12

Compact UTC-minute epoch aligned with event contract; regression and target checks PASS. Next S06 pure identity/hatch/migration, leaving board/NVS acceptance gated on S01. No upload, commit/push or app work.

## S06 partial checkpoint — 2026-10-12

| Session | Status | Evidence / next action |
|---|---|---|
| S06 | In progress — pure core implemented | [Identity core record](docs/roadmap/sessions/S06-identity-core.md); native/sanitizer 23/23 PASS; target smoke/build PASS. Storage/RNG/gesture/wiring/board checks pending S01 |
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
| UI-static-01 reference scene | Done — build/upload/owner visual PASS | [Static scene record](docs/roadmap/ui/UI-static-scene.md); RGB565 Flash, one-time draw, 23/23 host regression, fresh NVS preserved |
| S11 runtime | Deferred — owner explicitly paused | Prepared harness retained; do not resume or upload benchmark without owner request/gates |
| S01 Android acceptance | Pending | Static LCD acceptance does not validate BLE/learning/persistence matrix |

Firmware UI upload specifically authorized by current user request; existing milestone/storage decisions remain unchanged. No commit/push or gitlink update. Exact PCB revision and long-run/thermal validation remain open.

## Animated UI / publication checkpoint — 2026-10-12

| Item | Status | Evidence |
|---|---|---|
| UI-animation-02 | Implemented; owner provisionally accepted | [Animated scene record](docs/roadmap/ui/UI-animated-scene.md); final build/upload PASS, native/sanitizers 25/25, corrected seam/dark toes |
| Today's Git delivery | Done in parent commit containing this entry | Firmware c84d4e3; mobile 77d27ec; parent docs and child gitlinks; no push |
| S11 | Paused at owner's request | Source archive preserved; runtime/D2 not performed/approved |
| S01 / full S06 | Pending | Android/BLE baseline and identity storage/wiring checks remain open |

No automatic next feature session or S11 resume. Wait for owner's next UI/session request. PCB revision, long-run/thermal and full BLE regression remain unvalidated.

## Mobile rules and refactor checkpoint — 2026-10-13

| Item | Status | Evidence |
|---|---|---|
| MOB-RULES | Done — owner-requested | `mobile/AGENTS.md` (Clean Architecture rules, base widget rule), `mobile/docs/FEATURE_TEMPLATE.md`, `mobile/CLAUDE.md` |
| MOB-TOOLCHAIN | Done on this Windows machine | Flutter 3.32.8 installed via fvm; VS Code workspace points to it; `pubspec.lock` restored and unchanged after `fvm flutter pub get` |
| MOB-REFACTOR-01 | Implemented; host tests PASS | `features/device`, `conversation`, `home` migrated to the rules without protocol change; analyze clean, 16/16 tests on 3.32.8. Native build, real phone and board not run |
| S20 golden vectors | Done — 2026-10-19 | `firmware/sim/golden.cpp` → `mobile/test/fixtures/firmware/learning_v1.json`; Dart learner removed from the simulator (G17 resolved); app now accepts curious in life/memory values |
| REACT-LEARN | Done (host) — 2026-10-19 | D6 revised: device pet/shoo reactions teach (w 0.3, 10 s window), app ratings removed, greeting learning + spontaneous idle choices on. Board trial pending |
| ROUTINE-LEARN | Done (firmware, host) — 2026-10-20 | `HabitPredictor` (48 hour slots + mean minute, prequential gate), anticipation via curious before the usual arrival, snapshot section 7. Life Lab: routine owner 4–6/7 days on time, 0 false alarms; random owner never. App display and board trial pending |

Mobile changes are uncommitted; gitlink unchanged. Physical BLE/learning acceptance (S01, MVP-08) remains open and is not affected by host tests.

## S01 Android acceptance — 2026-10-13 (in progress)

Android 15 phone and ESP32 connected; fresh NVS backup/hash and idle serial smoke PASS. Owner approved S01-fix-01 for missing Android BLE permissions; manifest updated. Flutter 3.32.8 analyze clean, 16/16 tests PASS. Native debug APK build PASS; install blocked by phone (INSTALL_FAILED_USER_RESTRICTED), awaiting owner USB-install setting/prompt. Physical BLE/learning/persistence acceptance pending. Evidence and external backup paths: PROCESS latest S01 entry. Permission/docs edits uncommitted; no firmware upload/erase, commit/push; S11 stays paused. Actual existing mobile HEAD is cebaf1c (earlier uncommitted handoff superseded).

## S01 Android BLE smoke — 2026-10-13

APK install/launch, runtime Nearby devices permission, physical scan/connect/GATT reads PASS. Four animation requests reflected in status; owner confirms LCD/buttons. Quiet Idle → reject → learned Happy; feedback 1, memory 1/8 with button provenance. USB-UART reboot/reconnect retained preference/memory and expired pending suggestion. Detailed evidence: PROCESS latest S01 entry and MVP-local.md. Physical power cuts, forget/text/error matrix and raw-byte transcript remain pending; S01 In progress. No firmware change/upload, commit/push; S11 paused.

S01 continuation: one owner-operated power cut retained learned preference/memory. Active-time rollback recorded and attributed to existing five-minute checkpoint contract. Forget plus USB-UART reboot/reconnect PASS (memory/feedback 0, preferences Idle, lifetime preserved). Text confirmation, raw bytes/error matrix and full cut matrix pending; S01 remains In progress. Evidence: PROCESS / MVP-local latest entries.

S01 text follow-up: owner confirmed like; device reads feedback/memory 1 with text-confirmed provenance. Pre-confirmation counter not observed, still pending. Requested nRF Connect installation for required raw-byte transcript; S01 remains In progress. One test-created text episode remains on device. No firmware change, commit/push.

## S01 observed read baseline — 2026-10-13

nRF Connect installed and connected. Five physical characteristic reads captured as raw hex: capabilities 8 B, status 16 B, life and both memory pages 20 B each. Life feedback 1/memory 1/pending 0; confirmed-text episode observed. Evidence: [S01 observed transcript](docs/roadmap/sessions/S01-v1-observed-transcript.md) (root-relative path); raw XMLs outside Git. No writes/upload in this read step. Scripted writes/error matrix and power-cut matrix remain pending; S01 In progress, S11 paused. Docs uncommitted; no commit/push.

S01 raw command follow-up: Notify enabled; observed 7-byte Suggest Quiet attempt returned invalid_length (2), request 1; no pending suggestion or memory/feedback changes. Recorded actual transmitted bytes/status/life in S01-v1-observed-transcript.md. Valid 8-byte command with fresh request 2 pending. No firmware/code changes, commit/push.

S01 raw Suggest Quiet request 2: actual 8-byte write accepted (OK), choice Idle, pending ID 2/canFeedback 1. Feedback/memory remain 1; both memory pages unchanged. Raw hex and capture copies recorded in S01-v1-observed-transcript.md. Approval request 3 targeting 2 remains next; no firmware upload, code change, commit/push.

## S01 automated inspector cases — 2026-10-13

Owner requested direct operation. ADB drove nRF Connect Byte Array writes after verifying entered hex. Approval request 3/target 2 PASS: feedback/memory 1→2, episode source 1. Exact duplicate request 3 PASS: OK, counters remain 2. Reused ID 3 with rejection payload PASS: conflict 6, no learning. New feedback request 4 without active pending PASS: invalid_argument 4, no learning. Raw status/life/both memory pages for each case in S01-v1-observed-transcript.md and external case JSON/XML captures. Pending suggestion 5 created (OK/canFeedback 1); awaiting owner GPIO0 press before feedback invalidation test. No firmware upload, source change, commit/push; S01 In progress, S11 paused.

## S01 raw inspector script complete — 2026-10-13

Pending request 5 accepted. Owner pressed GPIO0; feedback request 6 targeting 5 rejected (invalid_argument 4), pending cleared and counters unchanged at 2. Forget request 7 OK; memory/feedback 0, both preferences Idle, active lifetime 5991 retained. Full required inspector script now captured as actual writes + status/life/both memory pages in S01-v1-observed-transcript.md. These satisfy the observed transcript portion, not full S01. Remaining: ten-cut matrix, feedback/connected diagnostics, pre-confirmation text observation, off/deny/timeout and standalone/routine checks. Device now cleared of test episodes. No firmware upload/source change, commit/push; S11 paused.

Owner deferred remaining S01 physical matrix to a later session. Stop current device actions; next resume: fresh device/backup verification, controlled five-idle/five-post-feedback cut checks, BLE/feedback diagnostics and text pre-confirmation evidence. Required raw inspector sequence complete; S01 remains In progress, not Validated. Device has feedback 0/memory 0, preferences Idle after Forget; nRF connection may remain open. No commit/push requested.

## S01 commit checkpoint — 2026-10-13

Owner requested committing current changes. Mobile f756225 commits Android Bluetooth permissions; the parent commit containing this entry records its gitlink plus S01 validation/handoff and observed transcript. Firmware c84d4e3 and backend unchanged. Prior uncommitted descriptions are historical; no push. S01 remains In progress with remaining physical checks deferred by owner; S11 stays paused. Existing Flutter analyze/16 tests, native APK build/install and physical smoke/inspector evidence retained; commit checks: whitespace PASS. No new device operations or tests during commit-only delivery.

## M04 offline implementation checkpoint — 2026-10-14

| Session | Status | Evidence / next action |
|---|---|---|
| S14 | In progress — implementation added; validation pending | [ActivityFsm record](docs/roadmap/sessions/S14-activity-fsm.md); native/sanitizer/ESP32 checks require the pinned toolchain |
| S15 | In progress — implementation added; validation pending | [Needs/Mood record](docs/roadmap/sessions/S15-needs-mood.md); native/sanitizer/ESP32 checks require the pinned toolchain |
| S16 | In progress — implementation added; validation pending | [Action policy record](docs/roadmap/sessions/S16-action-policy.md); native/sanitizer/ESP32 checks require the pinned toolchain |
| S17 | In progress — implementation added; validation pending | [FSM/visual wiring record](docs/roadmap/sessions/S17-fsm-visual-wiring.md); native/sanitizer/ESP32 checks require the pinned toolchain |

No board upload/NVS operation, app work, commit/push or gitlink change in these offline sessions.

## Learning Engine upgrade checkpoint — 2026-10-14

| Layer | Status | Evidence / gate |
|---|---|---|
| L1 bounded contextual preference | Implemented in isolation; validation pending | `firmware/lib/xuna_core/include/xuna/learning/PreferenceLearnerV2.h`, `firmware/test/test_learning_engine/test_main.cpp` |
| L2 persistence v2 + v1 migration | Pending | Required before production wiring; preserve BLE payload and reboot semantics |
| L3 feature context/action model | Proposed | Tune with Life Lab evidence; keep bounded and explainable |
| L4 delayed credit/conversation provenance | Proposed | Candidate/confirmation/correction contract required |
| L5 tiny RL/sequence experiment | Future experiment | Only if baseline/holdout data shows L1 is insufficient |

L1 is not yet called validated learning: the local session lacks the pinned PlatformIO/C++ toolchain, and V2 is deliberately not connected to `LifeEngine` or production BLE. No board/mobile/backend operation, commit or push.

## Learning Engine L1.5 checkpoint — 2026-10-14

| Layer | Status | Evidence / gate |
|---|---|---|
| L1 bounded contextual preference | Implemented in isolation; validation pending | V2 learner + deterministic replay tests |
| L1.5 prequential evaluation | Implemented in isolation; validation pending | `PrequentialEvaluator.h` and extended learner tests; integrate with Life Lab later |
| L2 persistence v2 + v1 migration | Blocked by S12a/D2 sequencing | Do not freeze a competing snapshot layout before the approved sectioned codec |

The evaluator is a measurement primitive, not a production learning claim. Snapshot/production wiring remains deferred until the existing M04 storage sequence is authorized and validated.

## Learning Engine L1.6 checkpoint — 2026-10-14

| Layer | Status | Evidence / gate |
|---|---|---|
| L1.6 v1/v2 shadow comparison | Implemented in isolation; validation pending | `LearningShadow.h` + deterministic synchronization tests |
| Life Lab integration | Pending | Requires S18/S19a trace runner and native toolchain |
| Production learner switch | Deferred | Requires shadow evidence, persistence sequence and owner acceptance |

The shadow harness is intentionally not linked from `main.cpp`, `BleManager` or `LifeStorage`.

## Learning Engine L1.7 checkpoint — 2026-10-14

| Layer | Status | Evidence / gate |
|---|---|---|
| Bounded Choose/Feedback trace runner | Implemented in isolation; validation pending | `LearningTrace.h` + replay tests |
| Full S19a Life Lab CLI/DSL | Done — 2026-10-19 (`lifecore_lab`: day/expect, snapshot SHA-256, explanation dump; native/ASan 204/204) | Was: requires S18/S19a sequencing and native toolchain |
| Production event integration | Deferred | Keep `main.cpp`/BLE/persistence unchanged until LifeCore and storage gates |

The current runner is intentionally smaller than the roadmap DSL: it proves learner replay mechanics without pretending M04 LifeCore is complete.

## Learning Engine L1.8 checkpoint — 2026-10-14

| Layer | Status | Evidence / gate |
|---|---|---|
| Numeric explanation contract | Implemented in isolation; validation pending | `LearningExplanation.h` + learner tests |
| Journal/mobile rendering | Deferred | Requires approved mobile contract and production persistence/evidence IDs |
| Causal prose generation | Deferred | Must be derived from numeric evidence; no free-form fabrication |
## Commit checkpoint — 2026-10-14

Firmware gitlink target: a518ede (`feat(firmware): add bounded digital life and learning layers`). Parent commit includes the handoff/roadmap records. No push.

Next actions remain validation-first: native + ASan/UBSan + ESP32 builds, then Life Lab trace integration; persistence v2 and production learner switch remain gated by S12a/D2, shadow evidence and owner acceptance.
## Learning Engine L1.9 checkpoint — 2026-10-14

| Layer | Status | Evidence / gate |
|---|---|---|
| Trace DSL parser | Implemented in isolation; validation pending | `LearningTraceDsl.h` + parser/error tests |
| Learning-focused host runner | Implemented in isolation; validation pending | `firmware/sim/lifelab.cpp`, CSV contract in `firmware/sim/README.md` |
| Full S19a Life Lab | Done — 2026-10-19 | Was: requires S18 `LifeCore::step`, store/clock adapters and native toolchain |

This slice intentionally completes only the learner portion that can be developed without mobile or board access. It does not bypass S10/S13/S18 gates.

## L1.9 commit checkpoint — 2026-10-14

Firmware child commit `f784626` contains the trace DSL, host runner and parser tests. The parent handoff commit records the updated gitlink; no push.

## M04 LifeCore composition checkpoint — 2026-10-14

| Slice | Status | Evidence / gate |
|---|---|---|
| LifeCore event step | Implemented as host/core preparation; validation pending | `firmware/lib/xuna_core/include/xuna/life/LifeCore.h`, `docs/roadmap/lifecore/lifecore-step.md` |
| Session FIFO + clock projections | Implemented as host/core preparation; validation pending | `LifeCoreSession.h`, `docs/roadmap/lifecore/lifecore-session.md` |
| Trace CLI | Implemented for choose/feedback/button/cmd subset; future verbs explicit unsupported | `LifeCoreTrace.h`, `firmware/sim/lifecore_lab.cpp` |
| Snapshot/power-cut lab | Implemented as in-memory experiment; not a storage-layout decision | `LifeCoreSnapshotLab.h`, `docs/roadmap/lifecore/lifecore-snapshot-lab.md` |
| Production wiring / persistence v2 | Deferred | Requires native/toolchain evidence and approved S12a/S13/S19a sequencing |

No mobile, board, BLE transport or backend work was included. No commit/push was made in this slice.
## M04 trace persistence experiment — 2026-10-14

- Fact: `LifeCoreTraceRunner` now drives `LifeCoreSnapshotLab`; `reboot` recovers the newest valid slot, `powercut` fails the next requested commit, and feedback persistence requests are auto-committed in the host experiment.
- Fact: CSV output and Unity coverage now include persist failures, reboot count, final event count and generation. `sync/day/expect` remain explicit unsupported verbs.
- Validation limit unchanged: whitespace and include-resolution checks pass; no C++/PlatformIO toolchain, simulator execution or board/mobile operation was available. No production persistence decision was made.

## M04 review fixes checkpoint — 2026-10-14

| Item | Status | Evidence / next action |
|---|---|---|
| S14–S16 native validation | Done criteria met (native tests green); ASan/UBSan and ESP32 build PASS | [Review fixes record](docs/roadmap/milestones/M04-review-fixes-2026-10-14.md) |
| S17 FSM/visual wiring | In progress — host/ESP32 validation PASS; owner board check pending | Exercise sleep/wake, rejected request (result 5), rest/recovery on the board |
| Energy recovery while Resting/Sleeping | Implemented; values Proposed | Tune `energyRecoveryPerMinute`, decay and dwell values in Life Lab |
| BLE opcode 2 context / Reacting timer restart | Implemented; host-covered via shared `ActionGate`/LifeCore tests | Physical BLE acceptance with S17 owner check |

No board upload, mobile/backend work, commit or push in this checkpoint.

## Mobile UI design system checkpoint — 2026-10-14

| Item | Status | Evidence / next action |
|---|---|---|
| XUNA tokens, fonts, base widgets | Implemented; host tests pass | [Mobile UI record](docs/roadmap/ui/mobile-ui-design-system.md) |
| Four-tab home on real data | Implemented; simulator-transport tests pass | Owner visual check on a real phone with the board |
| Original images (`room`, `avatar`, `book`, `lv1–3`) | Pending | Export from Claude Design into `mobile/assets/images/` and swap stand-ins |
| Base dialogs/snack bars restyle | Pending | Separate small session (mobile AGENTS §11) |
| Locked "SẮP CÓ" features | Deferred | Each needs its own approved session (M06, protocol, VOICE gates) |

## Commit checkpoint — 2026-10-14 (review fixes + mobile UI)

Owner requested committing. Firmware `aa2dbca` (review fixes) and mobile `df7d2ee` (XUNA design system, four-tab home, heading fixes); the parent commit records both gitlinks and the handoff/design docs. No push.

## S18 readiness checkpoint — 2026-10-14

| Item | Status | Evidence / next action |
|---|---|---|
| S18 composition | Partial host preparation; full session not complete | [Source audit](docs/roadmap/sessions/S18-readiness-review.md); dispatch, identity, queue and typed persistence integration missing |
| S10 / S13 prerequisites | Not complete end-to-end | Trusted time/hatch and approved storage v2/migration/wiring required |
| S17 prerequisite | In progress | Existing host/target checks PASS; owner board acceptance remains |
| Offline next step | Available preparation | Execute existing host trace/snapshot experiments; do not claim full S19a |

## S17 board checkpoint — 2026-10-14

- Backup verified by size/hash and device/target NVS partition match; firmware aa2dbca build/upload and Serial boot smoke PASS. Evidence and external backup path in PROCESS.md, S17 board upload smoke.
- Full S17 remains In progress: owner visual/button observations, BLE sleep/wake/rejection, rest/recovery and render timing acceptance pending. Device state preservation not yet checked through BLE.

- S17 owner visual confirmation (2026-10-14): owner confirmed normal XUNA/Idle LCD, GPIO0 Happy and return to Idle, followed by GPIO14 Idle on firmware aa2dbca. Combined with captured button Serial logs, LCD/button smoke PASS. Full S17 remains In progress: BLE sleep/wake/result 5, rest/recovery and render timing acceptance still pending.

## Pet artwork replacement — 2026-10-16

Implemented and uploaded: 16-frame XUNA sprite sheet, four visual states. Native 182/182 and ESP32 build PASS; physical visual acceptance pending. See latest PROCESS.md record.

## Anchored motion revision — 2026-10-16

Implemented 32 timed samples per emotion, fixed feet, no rotation/slide, bounded breath and face motion. Visual tests and ESP32 build PASS. Physical animation acceptance remains pending; see latest PROCESS.md entry.

- 2026-10-16: mobile debug APK built/installed/launched on Redmi for four-expression board checks; owner visual/BLE acceptance pending. No mobile code changes.

## Mobile pet animation — 2026-10-16

Implemented, tested (47/47), Android build/install/launch PASS: shared firmware pet artwork with four state-driven loops in Home and board preview. Physical visual/BLE acceptance pending; no commit/push.

## Shared mobile pet base — 2026-10-16

Implemented AppXunaPet in shared; chat/avatar/journal/growth placeholders updated, room/board use the same base. Analyze clean, tests 48/48, APK build/install/launch PASS. Owner visual review pending.

## Simple mobile backgrounds — 2026-10-16

Implemented three flat pixel backgrounds for Home/Chat/Journal via shared base. Analyze/build and 49 tests PASS; installed/launched on Redmi. Owner visual acceptance pending.

## Owner checkpoint — 2026-10-16

Current display/four emotions/two buttons/mobile BLE smoke: owner-confirmed PASS. Extended 1–2 h trial and power-cut matrix: owner-skipped for this iteration, not validated. Continue local S10 integration and existing foundation gates; cloud Phase 0 plan complete, implementation gated by M05b/S38.

## Gate simplification — 2026-10-16

| Item | Status | Evidence / next action |
|---|---|---|
| S01 | Closed — Accepted with owner-skipped items | Ten-cut matrix, diagnostics windows, text pre-confirmation and off/deny/timeout not validated |
| D2a | Approved | Snapshot v2 in NVS A/B; [ADR-0002](docs/decisions/ADR-0002-storage-layout.md); LittleFS → S32; S11 runtime deferred |
| S08b / S09 | Folded into S13 + S18 | S08a is the byte-compatibility regression |
| S10 | Split | S10-sync after S13 + S18; S10-hatch deferred |
| S17 | Closed on owner smoke | Render ±20% not measured |
| S23 / S24 | Superseded | E10 learner v3, UCB and D3 in `ProductLearner` |
| Cloud gate | Approved revision of ADR-0009 | No backend code until snapshot v2 on board + `PetId` over BLE + local export |

| S08a + integration prep | Done on host — 2026-10-16 | [Record](docs/roadmap/sessions/S13-S18-integration-prep-2026-10-16.md): `V1LifeCoreAdapter`, S01 replay, `NvsSnapshotStore`, real-backup migration check; native/ASan 189/189 |

Current: item 2 uploaded with initial smoke PASS, remaining board checks owner-skipped; item 3 S26/S27-lite source/build complete, not uploaded (see newest section below). [Switch record](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md): native/ASan 190/190, ESP32/purity PASS; verified backup; actual pet Happy/Idle (4 feedback) preserved on host. Board still uses the previous firmware.


## S26/S27-lite source upgrade — 2026-10-16

- **Implemented on host, not uploaded:** opcode 6 + bit 5, explanation READ `000b`, expired result 8; minimal Chat Why and evidence-grounded confirmation reply. [Record](docs/roadmap/sessions/S26-S27-lite-2026-10-16.md).
- Firmware full native/ASan 192/192 each plus final adapter 11/11 each; ESP32/purity PASS. Mobile analyze clean, 59/59 tests, APK PASS, pinned SDK/lock unchanged.
- Board still runs S13/S18. Remaining S13/S18 board checks owner-skipped, not prerequisites for this requested code slice, and not validated. S28-lite physical acceptance deferred. Next recommended code work: S10-sync, when requested. No new board/phone operations or commit/push.


## Git delivery checkpoint — 2026-10-16

Owner requested all pending work committed: firmware `b0f4ded`, mobile `4976147`, then root docs and updated gitlinks. No push requested/performed. Implementation/board validation status remains unchanged; S26 is source/build only, while the board runs the preceding S13/S18 image.

## M06 Knowledge Domains & Knowledge Expert checkpoint — 2026-10-29

| ID | Status | Evidence / next step |
| --- | --- | --- |
| KD-0..KD-5 | Done on host — 2026-10-27..28 | Firmware `KnowledgeProfile` + BLE opcode 10 + projection `7a6e000f` (376/376 native PASS), backend `knowledge` module, mobile UI & orchestration; see [knowledge-domains-plan-2026-10-27.md](docs/roadmap/knowledge/knowledge-domains-plan-2026-10-27.md) |
| KX-1..KX-5 | Done on host — 2026-10-29 | Dual-output `<say>` + Markdown `detail`, mode/domain router, Domain Packs + Working Brief (migration `0011`), Working Conventions + Solved Cases, Owner Reference Documents with U4 consent (ADR-0011, migration `0012`), `HomeController` 5-service refactor; see [knowledge-expert-plan-2026-10-29.md](docs/roadmap/knowledge/knowledge-expert-plan-2026-10-29.md) |
| KX-6 | Done on host — 2026-10-29; physical board + phone + live AI provider trial pending | [KX-6-acceptance-2026-10-29.md](docs/roadmap/knowledge/KX-6-acceptance-2026-10-29.md): 6/6 KX-6 criteria verified on host (`backend` 402/402 pytest PASS, `mobile` 329/329 flutter test PASS, `flutter analyze` 0 issues) |
| PWR-1..2 | Done on host — 2026-10-29; physical board thermal & screen-sleep check pending | [power-thermal-upgrade-plan-2026-10-28.md](docs/roadmap/power/power-thermal-upgrade-plan-2026-10-28.md): Phase 1 (AW9364 init/pulse lock, BLE 0 dBm, 5 FPS quiet pacing) & Phase 2 (3-stage screen sleep `Active`/`Dim`/`Off`, BLE opcode 11 `DisplaySettings`, NVS `xuna_ui`, mobile brightness & screen-wake controls; `firmware` 380/380 native PASS, `mobile` 332/332 test PASS) |

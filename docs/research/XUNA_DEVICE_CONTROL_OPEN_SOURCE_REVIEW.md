# XUNA Device Control — Open-Source Review (2026-10-30)

Status: **research only**. Nothing was installed or copied into XUNA repositories. Policy for any later reuse: [ADR-0001 reference reuse policy](../decisions/ADR-0001-reference-reuse-policy.md) (Proposed) and the dependency-approval rules in [backend/AGENTS.md](../../backend/AGENTS.md) §8 and [mobile/AGENTS.md](../../mobile/AGENTS.md).

## Method

- Metadata, commit history (`commits?since=2026-04-30`), contributors, trees and compare data came from the GitHub REST API (unauthenticated; `gh` is not installed on the dev machine). Source files were read from raw.githubusercontent.com. Commit counts are capped at 100 per page, so "100+" means at least 100.
- Each verdict is based on files actually read (listed per repo), not on README claims or stars.
- **UNVERIFIED** marks anything the review could not confirm from a primary source.
- Verdicts: **ADOPT** (use as a dependency or standard) · **ADAPT** (reuse design/patterns or a pinned fork, with changes) · **REFERENCE ONLY** (learn from, do not ship) · **REJECT**.

## 1. Requested repositories

### 1.1 Cross-platform computer use

**[munimtechnologies/munim-computer-use](https://github.com/munimtechnologies/munim-computer-use) — ADAPT**

- **Repo:**
  - Apache-2.0: commercial use is allowed, with a patent grant; keep NOTICE.
  - Rust (Windows/Linux) + Swift (macOS) + Chrome extension.
  - Created 2026-09-05; last commit 2026-10-29; 100+ commits in about 8 weeks.
  - 3 contributors, but about 97 % of commits come from one author.
- **Architecture:**
  - MCP over stdio only.
  - macOS: AXUIElement with batched attribute reads, ScreenCaptureKit, per-process events.
  - Windows: `uiautomation` crate (Invoke/Value/Scroll patterns), posted Win32 messages, and a real-cursor fallback for Chromium/Electron/WPF.
  - Linux: AT-SPI/XTEST.
  - 33 tools whose schemas are kept byte-identical across Swift and Rust by `scripts/check-tool-parity.mjs` in CI.
- **Quality:** CI builds Windows/Linux/macOS; Rust unit tests in `policy.rs`, `capture.rs`, `tools.rs`. Weak spot: `macos/Sources/main.swift` is a single 253 KB file.
- **Security:**
  - No shell tool.
  - `policy.json` sets allow/ask/block per app and per site, and an **invalid policy blocks everything** (fail-closed).
  - Password fields are refused; clicks onto occluding windows are refused.
  - `secure_desktop.rs` states that agents cannot answer UAC prompts.
  - Its README calls the policy "a guard rail … not a sandbox".
- **Files read:** `windows-linux/src/policy.rs`, `windows-linux/src/secure_desktop.rs`, `macos/Sources/Policy.swift`, `.github/workflows/ci.yml`.
- **For XUNA:**
  - Patterns worth taking: the fail-closed allow/ask/block policy, `run_steps` (validate every step before running any), act-and-observe results, and cross-platform schema parity checks.
  - Too young and single-maintainer for a live dependency; pin or fork only if chosen in UDC-D11.

**[zavora-ai/computer-use-mcp](https://github.com/zavora-ai/computer-use-mcp) — ADAPT (patterns) / REFERENCE**

- **Repo:**
  - MIT.
  - TypeScript + Rust NAPI module + Swift helper.
  - Last commit 2026-10-27; 88 commits in 6 months; effectively one author.
  - Targets MCP 2026-07-28.
- **Architecture:**
  - stdio, plus an optional Streamable HTTP runner that refuses non-loopback hosts and validates Host and Origin.
  - Windows: UIA, SendInput, DXGI and Windows.Graphics.Capture.
  - macOS: ScreenCaptureKit and Vision.
  - 79 tools in `core` ⊂ `desktop` ⊂ `full` profiles.
- **Security:**
  - The `full` profile exposes `run_script` (AppleScript/JXA/PowerShell), filesystem, process kill and registry. Its own SECURITY.md lists these as residual risks.
  - Good mitigations:
    - single-use approvals with a 10-minute TTL (`src/approval-ledger.ts`);
    - an approval token in `_meta` that the model never sees;
    - HMAC-signed elicitation state;
    - a path jail with realpath and symlink checks;
    - argument-free logs.
- **Files read:** `src/http.ts`, `src/authority.ts`, `src/approval-ledger.ts`, `src/session/admin-handlers.ts`, `SECURITY.md`, `docs/ARCHITECTURE.md`.
- **For XUNA:** profile tiers (a tool outside the profile is neither listed nor callable), the approval ledger and the loopback-only HTTP rules. Do not ship its `full` surface.

**[heaventree/cua-desktop-ai](https://github.com/heaventree/cua-desktop-ai) — REJECT**

- A plain fork of trycua/cua: 0 commits ahead and 3,893 behind upstream.
- Last commit 2025-12-04 (an upstream commit); MIT inherited.
- Use the upstream [trycua/cua](https://github.com/trycua/cua) instead.

### 1.2 Windows

**[sandraschi/windows-computer-use-mcp](https://github.com/sandraschi/windows-computer-use-mcp) — REJECT**

- **Repo:**
  - MIT; Python 3.12, FastMCP 3, pywinauto, pyautogui, pynput, OpenCV.
  - Last commit 2026-10-25.
  - Its README says it was "Built with opencode (DeepSeek V4)".
- **Architecture:** legacy `mouse_event` input; stdio/HTTP/SSE on 127.0.0.1:10789, plus a web UI and a REST API.
- **Red flags:**
  - It ships a **global keylogger** service (opt-in by environment flag) and face-recognition/camera endpoints.
  - No authentication code was found in `transport.py`, `server.py` or `security_endpoints.py`, although SECURITY.md claims optional JWT.
  - The security contact is a placeholder (`security@example.com`).
- **Files read:** `safety.py`, `transport.py`, `keylogger_service.py`, `SECURITY.md`.

### 1.3 Android

**[Genymobile/scrcpy](https://github.com/Genymobile/scrcpy) — REFERENCE ONLY (development/testing)**

- **Repo:** Apache-2.0; C client + Java server; v5.0.1 (2026-10-08); very active.
- **Architecture:**
  - Pushes `scrcpy-server.jar` over adb and runs it via `app_process`.
  - Keyboard modes: `sdk`, `uhid` and `aoa` (AOAv2 HID over USB).
  - Requires USB debugging; OTG mode does not.
- **For XUNA:** a developer tool for screen mirroring during tests, and a reference for HID keymaps. Not a consumer path.

**[openatx/uiautomator2](https://github.com/openatx/uiautomator2) — REFERENCE ONLY (QA)**

- **Repo:** MIT; Python; last commit 2026-10-23.
- **Architecture:** a device-side HTTP service built on UiAutomator, driven over adb, and requires Developer options.
- **Why not production:** UiAutomator is an instrumentation test framework (`androidTestImplementation`). Use it for automated tests of the XUNA app only.

### 1.4 ESP32-S3 / BLE HID

**[ethandgoodhart/pilot](https://github.com/ethandgoodhart/pilot) — REFERENCE ONLY**

- **Repo:**
  - **No license**, so all rights are reserved and the code cannot be copied.
  - 1 commit (2026-04-19).
  - Arduino core 3.x, Bluedroid `BLEHIDDevice`.
  - Composite absolute mouse + keyboard + consumer control, plus iOS shortcut macros.
- **Useful finding:** the custom service must be created before `hid->startServices()`, otherwise "iOS stops recognising the HID service" (`esp32-pilot.ino` around L347–369). This applies directly to XUNA, which also has a custom service.
- **Security:**
  - `ESP_IO_CAP_NONE`, so pairing is effectively Just Works.
  - The UART write characteristic has **no encryption**, so anyone who can connect can inject keystrokes into the paired phone. This is the anti-pattern XUNA must avoid (security UDC-T9/T10).

**[HijelHub/HijelHID_BLEMouse](https://github.com/HijelHub/HijelHID_BLEMouse) — ADAPT (patterns)**

- **Repo:** Apache-2.0; last commit 2026-04-09; single author.
- **Stack:** NimBLE-Arduino ≥ 2.3.8 and Arduino core 3.x; **mouse only**.
- **Quality:**
  - Clean security modes: Just Works with SC, or numeric comparison with MITM + SC.
  - A per-peer `deleteBond()` workaround for stale iOS security-manager state.
  - Deep-sleep helpers and a warning about Windows caching the report descriptor.
  - Notes that iOS needs AssistiveTouch for pointer input.
- **Risk:** it reports Apple's USB vendor ID (0x05AC) in its PnP ID. XUNA must use its own.

**[NullYing/ESP32-BLE-Keyboard-Mouse](https://github.com/NullYing/ESP32-BLE-Keyboard-Mouse) — REFERENCE ONLY**

- **Repo:**
  - **No top-level license.** Espressif-derived files are `Unlicense OR CC0-1.0`; the author's own files are unlicensed.
  - ESP-IDF ≥ 5.0, not Arduino.
  - A USB-host-to-BLE HID bridge.
  - Last commit 2026-10-05.
- **Security:** several report characteristics use plain `ESP_GATT_PERM_READ`, which does not meet HOGP §7.1 (HID characteristics require an encrypted link).

## 2. Additional projects discovered

| Project | License | Last commit / activity | What matters | Verdict |
|---|---|---|---|---|
| [trycua/cua](https://github.com/trycua/cua) (Cua Driver) | MIT; **optional perception extension uses OmniParser (AGPL-3.0)** | 2026-10-30; 100+ commits in October; 100+ contributors | Rust driver over MCP stdio for macOS/Windows/Linux, with background input delivery. Permission modes `standard` / `bounded` (reviewed capability manifest) / `unrestricted`, the last behind a `--dangerously-…` flag. Embedding guidance for macOS TCC "responsible app identity". Lume VMs for sandboxed tests | **ADOPT as the UDC-8 computer-use provider** (pinned, bounded mode, no perception extension) |
| [CursorTouch/Windows-MCP](https://github.com/CursorTouch/Windows-MCP) | MIT | 2026-10-29; 74 contributors | Python, comtypes UIA. Rich auth options for HTTP (bearer, IP allowlist, OAuth + PKCE). **PowerShell, Registry and FileSystem tools are on by default**, and so is PostHog telemetry | **REFERENCE ONLY** |
| [microsoft/UFO](https://github.com/microsoft/UFO) | MIT | 2026-10-14; 30 contributors | Windows UIA + vision grounding; a shell **allow-list** with regex blocks on nested shells; WebSocket device protocol; `tests/security/` | **REFERENCE ONLY** (UIA and allow-list ideas) |
| [anthropics/claude-quickstarts](https://github.com/anthropics/claude-quickstarts) computer-use-demo | MIT | 2026-10-29 | Agent loop over a Linux X11 desktop in Docker. Warns to use a VM/container and about prompt injection from screen content | **REFERENCE ONLY** (loop and tool shape) |
| [openclaw/Peekaboo](https://github.com/openclaw/Peekaboo) (formerly steipete/Peekaboo) | MIT | 2026-10-27; 50 contributors | Swift 6.2, macOS 15+: ScreenCaptureKit, AX inspection, synthetic input, permission onboarding. Requires foreground consent for app-targeted key chords | **ADAPT** (macOS provider reference) |
| [h2zero/NimBLE-Arduino](https://github.com/h2zero/NimBLE-Arduino) | Apache-2.0 | Release 2.5.2 (2026-10-25); `master` is a breaking 3.0-dev | `NimBLEHIDDevice`; defaults of 3 connections and 3 bonds (tunable). README claims much lower RAM/Flash than Bluedroid. Compatibility with Arduino core 2.0.14 is **UNVERIFIED** | **ADOPT if UDC-D8 chooses migration** (pin 2.5.x) |
| [espressif esp-idf `esp_hid_device`](https://github.com/espressif/esp-idf/tree/master/examples/bluetooth/esp_hid_device) | Unlicense OR CC0-1.0 | Vendor-maintained | Consumer Control report map (Usage Page 0x0C, Report ID 3), usage table, and an SC + MITM + bonding GAP setup that labels `IO_CAP_NONE` insecure. Works on Bluedroid or NimBLE | **ADOPT** (report descriptors and security reference; copy descriptors, not IDF glue) |
| [Mystfit/ESP32-BLE-CompositeHID](https://github.com/Mystfit/ESP32-BLE-CompositeHID) | MIT | 2026-05-05 | NimBLE 2.x composite keyboard/mouse/gamepad. **Bonding without MITM or SC** (`BleCompositeHID.cpp` L274). README says iOS is not supported | **ADAPT** only with security fixed |
| [T-vK/ESP32-BLE-Keyboard](https://github.com/T-vK/ESP32-BLE-Keyboard) | **None** | 2024-03-24 (stale) | The only library matching XUNA's Bluedroid / core 2.0.14 stack. macOS/iOS marked "not stable" | **REFERENCE ONLY** (license) |
| [wakwak-koba/ESP32-NimBLE-Keyboard](https://github.com/wakwak-koba/ESP32-NimBLE-Keyboard) | **None** (fork) | 2025-08-16 | NimBLE 2.x port; MITM but no SC | **REFERENCE ONLY** |
| [droidrun/droidrun](https://github.com/droidrun/droidrun) ("Mobilerun") + [mobilerun-portal](https://github.com/droidrun/mobilerun-portal) | MIT + **AGPL-3.0** (Portal) | 2026-10-27 | LLM agent driving Android through an Accessibility + NotificationListener app that also requests SMS, contacts and install permissions. This is the pattern Play now prohibits | **REFERENCE ONLY** (never copy Portal code) |
| [mobile-next/mobile-mcp](https://github.com/mobile-next/mobile-mcp) | Apache-2.0 | 2026-10-26 | MCP server for Android/iOS over adb / Xcode. Telemetry is on unless disabled | **REFERENCE ONLY** (QA) |
| [appium/appium](https://github.com/appium/appium) | Apache-2.0 | 2026-10-28 | W3C WebDriver with UiAutomator2/XCUITest drivers | **REFERENCE ONLY** (QA) |
| [nut-tree/nut.js](https://github.com/nut-tree/nut.js) | Apache-2.0 (package.json; no repo LICENSE) | 2024-05-01 | Stale; prebuilt binaries are subscription-only | **REJECT** |
| [ashwwwin/automation-mcp](https://github.com/ashwwwin/automation-mcp) | MIT | 2025-06-11 | Inactive for 16 months | **REJECT** |
| [modelcontextprotocol](https://github.com/modelcontextprotocol/modelcontextprotocol) spec | Mixed (SPDX **UNVERIFIED**) | 2026-10-29; current revision 2026-07-28 | Normative MCP spec | **ADOPT as a standard** for descriptor shapes and the stdio provider interface |

Not inspected (rate limit): pyautogui, pynput. Both are coordinate-only, with no accessibility tree.

## 3. Summary

| Repo | License | Last commit | Maintenance | Recommendation |
|---|---|---|---|---|
| munimtechnologies/munim-computer-use | Apache-2.0 | 2026-10-29 | Very active, 8 weeks old, 1 main author | ADAPT |
| zavora-ai/computer-use-mcp | MIT | 2026-10-27 | Active, 1 author | ADAPT patterns / REFERENCE |
| heaventree/cua-desktop-ai | MIT (inherited) | 2025-12-04 | Dead fork | REJECT |
| sandraschi/windows-computer-use-mcp | MIT | 2026-10-25 | Sprawling, generated | REJECT |
| Genymobile/scrcpy | Apache-2.0 | 2026-10-08 | Very active | REFERENCE ONLY |
| openatx/uiautomator2 | MIT | 2026-10-23 | Active | REFERENCE ONLY (QA) |
| ethandgoodhart/pilot | None | 2026-04-19 | Abandoned | REFERENCE ONLY |
| HijelHub/HijelHID_BLEMouse | Apache-2.0 | 2026-04-09 | Low | ADAPT (patterns) |
| NullYing/ESP32-BLE-Keyboard-Mouse | None (Espressif parts CC0) | 2026-10-05 | Low | REFERENCE ONLY |
| trycua/cua (Cua Driver) | MIT (perception ext. AGPL) | 2026-10-30 | Very active | ADOPT (UDC-8 provider) |
| openclaw/Peekaboo | MIT | 2026-10-27 | Very active | ADAPT (macOS) |
| CursorTouch/Windows-MCP | MIT | 2026-10-29 | Very active | REFERENCE ONLY |
| microsoft/UFO | MIT | 2026-10-14 | Moderate | REFERENCE ONLY |
| h2zero/NimBLE-Arduino | Apache-2.0 | 2026-10-29 | Very active | ADOPT if migrating (UDC-D8) |
| esp-idf esp_hid_device | Unlicense/CC0 | vendor | Maintained | ADOPT (descriptors) |
| Mystfit/ESP32-BLE-CompositeHID | MIT | 2026-05-05 | Moderate | ADAPT (fix security) |
| T-vK, wakwak-koba keyboards | None | 2024-03 / 2025-08 | Stale / low | REFERENCE ONLY |
| droidrun + Portal | MIT + AGPL-3.0 | 2026-10-27 | Very active | REFERENCE ONLY |
| mobile-mcp, appium | Apache-2.0 | 2026-10 | Very active | REFERENCE ONLY (QA) |
| nut.js, automation-mcp | Apache-2.0 / MIT | 2024 / 2025 | Stale | REJECT |

## 4. Patterns recurring across the reviewed projects

1. **Policy is a guard rail, not a sandbox.** Every serious project says so; real isolation needs a VM (Cua Lume) or a separate user. XUNA therefore relies on owner approvals and narrow tools rather than on "smart" filtering.
2. **The best-engineered servers still ship dangerous defaults:** shell/PowerShell/registry tools, telemetry, HTTP listeners. XUNA must never expose a third-party server directly; it wraps one as a provider with an allowlist.
3. **Accessibility tree first, pixels second.** UIA/AX actions are more reliable and work without moving the cursor; Chromium, Electron and WPF often still need real input.
4. **Input can fail silently.** UIPI-blocked `SendInput` reports nothing, so check the effect after acting.
5. **Most hobby ESP32 HID code is insecure:** Just Works pairing, unencrypted control characteristics, borrowed vendor IDs, missing licenses. XUNA should write its own small HID module from CC0 descriptors.

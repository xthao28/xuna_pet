# UDC-3 — Host Verification Results & LAN Acceptance Runbook (2026-10-30)

Date: 2026-10-30. Milestone: [UDC-3-desktop-agent.md](UDC-3-desktop-agent.md).
Status: **S3.1–S3.7 Implemented and verified across `desktop/packages/xuna_xtp`, `backend/`, `mobile/`, and `desktop/`; physical LAN run with native Windows `.exe` / macOS `.app` builds is pending Visual Studio C++ workload on Windows and Xcode on macOS.**

---

## 1. Summary of Implemented Scope (S3.1 – S3.7)

### S3.1 — Submodule `desktop/` & Pure-Dart Package `packages/xuna_xtp`
- Added Git submodule `desktop/` (`https://github.com/xthao28/xuna_desktop.git`), `.fvmrc` (`3.32.8`), and `desktop/AGENTS.md`.
- Implemented `desktop/packages/xuna_xtp`:
  - `canonical.dart`: RFC 8785-style deterministic UTF-8 JSON canonicalization (sorted keys, no whitespace, integer-only validation) and `argsSha256`.
  - `crypto.dart`: P-256 uncompressed SEC1 public key validation (`0x04 || X || Y`, 65 B), `publicKeyFingerprintB64Url` (first 16 B of SHA-256), `computeSas` (6-digit SAS from `SHA-256("xuna.host.sas.v1\x00" || code || pubkey)`), `buildEnrollmentUri` (`xuna-host://enroll?v=1&c=...&k=...&n=...`), and `hostProofMessage` (`"xuna.host.proof.v1\x00" || purpose || len=32 || nonce || payload [|| hostId]`).
  - `url_validator.dart`: `https://`-only URL validation, userinfo/port/IPv4/IPv6/`localhost`/`.local` rejection, IDN punycode (`xn--`) conversion, and exact/subdomain domain allowlist matching.
  - `frames.dart`: JSON-RPC 2.0 + MCP-shaped XTP v1 frames (`xuna/hello`, `xuna/challenge`, `xuna/proof`, `xuna/enrollPending`, `xuna/enrolled`, `xuna/ready`, `tools/list`, `tools/call`, `notifications/cancelled`, `notifications/progress`, `notifications/tools/list_changed`, `xuna/stop`, `ping`), size caps (`64 KiB` frame, `16 KiB` `structuredContent`), and 12 normative MVP tool schemas.
  - `policy.dart`: Fail-closed `HostPolicy` & `HostPolicyEvaluator` enforcing family gates, app/workflow risk floor (`app.launch >= R2`), URL domain allowlist, R2+ approval binding (`hostId`, `tool`, `argsSha256`, `expiresAt`), and emergency stop (`errorCode = "stopped"`).
- Golden fixtures (`golden_vectors.json`, `sample_frames.json`) copied from `backend/tests/fixtures/xtp/` and verified byte-for-byte in CI tests.

### S3.2 — Backend `hosts` Module (`backend/`)
- Migrations `0013_hosts.py` (`hosts` table with `revoked_at` tombstone) and `0014_host_grants.py` (`host_grants` table).
- Domain (`domain/entities.py`, `domain/ports.py`), Application (`application/xtp_frames.py`, `application/services.py`, `application/registry.py`), Infrastructure (`infrastructure/models.py`, `infrastructure/repositories.py`), and API (`api/schemas.py`, `api/router.py`, `api/ws_router.py`):
  - Outbound-only WebSocket `GET /v1/hosts/connect` (`Sec-WebSocket-Protocol: xtp/1`): Mode A enrollment (`180 s` TTL, single-use code, rate limit `10/min/IP`) and Mode B reconnect (`10 s` handshake timeout, `30 s` heartbeat, duplicate session closes prior session with `4001` and records `host.rejected`).
  - Owner REST endpoints (`POST /v1/hosts`, `POST /v1/hosts/{hostId}/confirm`, `GET /v1/hosts`, `DELETE /v1/hosts/{hostId}`, `PUT /v1/hosts/{hostId}/grants`).
  - Content-free audit events (`host.enrolled`, `host.enroll_rejected`, `host.revoked`, `host.connected`, `host.rejected`, `host.grant_changed`, `host.tool_invoked`, `host.tool_denied`).
  - Developer CLI `backend/scripts/host_call.py` for invoking tools against a live connected host.

### S3.3 — Mobile `features/hosts` (`mobile/`)
- Full Clean Architecture slice under `mobile/lib/features/hosts/`:
  - Entities (`HostSummary`, `HostGrant`, `ClaimedEnrollment`, `HostEnrollmentQrPayload`), repository & 6 use cases (`ListHostsUseCase`, `ClaimHostEnrollmentUseCase`, `ConfirmHostEnrollmentUseCase`, `UpdateHostGrantsUseCase`, `RevokeHostUseCase`, `ParseHostEnrollmentQrUseCase`).
  - Remote data source (`/v1/hosts`), models & mapper.
  - Presentation (`HostsController`, `HostsCard` on `HomeDeviceTab`, `HostEnrollQrSheet`, `HostEnrollSasDialog` with prominent `"Không khớp — Hủy"` button, and `HostDetailSheet` with family grants & revoke confirmation).

### S3.4 — Desktop Core Application (`desktop/lib/`)
- `SingleInstanceGuard` (`raf.lockSync(FileLock.exclusive)` on `agent.lock`), `AgentPaths` (`%APPDATA%\XUNA\` on Windows, `~/Library/Application Support/XUNA/` on macOS), and `ContentFreeLogger` (strict metadata key allowlist).
- `EnrollmentStateStore`, fail-closed `HostPolicyStore` (`host-policy.json`), 30-day rotating `AuditLogStore` (`audit-YYYY-MM-DD.jsonl`), `EmergencyStopController`, `DesktopTrayService` (`tray_manager`, `window_manager`, `hotkey_manager` `Ctrl+Alt+Shift+X`), `HostToolDispatcher` (all 12 MVP tool classes), `XtpSessionClient` (Mode A/B handshakes, `1,2,4,8,16,32,60 s` + `0..500 ms` jitter backoff), and `DesktopAgentWindow` (4 tabs: `Ghép nối`, `Chính sách`, `Quyền hệ thống`, `Nhật ký`).

### S3.5 — Windows Native Providers & Installer (`desktop/windows/`)
- `windows/runner/xuna_host_plugin.h` & `xuna_host_plugin.cpp`:
  - `keyEnsure` & `keySign`: Windows CNG (`MS_PLATFORM_CRYPTO_PROVIDER` TPM first, fallback `MS_KEY_STORAGE_PROVIDER`), non-exportable `NCRYPT_ECDSA_P256_ALGORITHM`, 65 B uncompressed SEC1 public key and 64 B raw `r || s` signature.
  - `media` & `nowPlaying`: C++/WinRT `GlobalSystemMediaTransportControlsSessionManager` with `SendInput` (`VK_MEDIA_*`) fallback and allowlisted player filtering (`title`/`artist`/`app` truncated to ≤ 120 chars).
  - `volumeSet`: Core Audio `IMMDeviceEnumerator` → `IAudioEndpointVolume::SetMasterVolumeLevelScalar`.
  - `appLaunch`, `workflowRun`, `urlOpen`, `hostInfo`, `permissions`, `requestPermission`, `showToast`.
- `scripts/install_windows_dev.ps1`: per-user installer to `%LOCALAPPDATA%\Programs\XUNA`, owner-only ACL (`icacls /inheritance:r /grant:r`) on `%APPDATA%\XUNA\host-policy.json`, and `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\XunaDesktopAgent` login item.

### S3.6 — macOS Native Providers, Entitlements & Installer (`desktop/macos/`)
- `macos/Runner/XunaHostPlugin.swift`:
  - `keyEnsure` & `keySign`: Secure Enclave (`kSecAttrTokenIDSecureEnclave`) with fallback to non-extractable Keychain P-256 key, and ANSI X9.62 DER → 64 B raw `r || s` conversion (`derEcdsaToRawRS`).
  - `media` & `volumeSet`: `AXIsProcessTrusted()` check + `CGEvent` media keys (`NX_KEYTYPE_PLAY`, `NX_KEYTYPE_NEXT`, `NX_KEYTYPE_PREVIOUS`) and CoreAudio output volume scalar.
  - `nowPlaying`: Typed AppleEvents (`kAECoreSuite` / `kAEGetData` on `'pPlS'`, `'pTrk'`, `'pnam'`, `'pArt'`) for allowlisted bundles (`com.spotify.client`, `com.apple.Music`) with zero AppleScript source compilation.
  - `appLaunch` (`NSWorkspace.shared.openApplication` with `arguments = []`), `urlOpen` (`https://` check + `NSWorkspace.shared.open`), `workflowRun` (`Process` `/usr/bin/shortcuts run <target>`), `permissions` & `requestPermission` (`AXIsProcessTrustedWithOptions`, `AEDeterminePermissionToAutomateTarget`, `UNUserNotificationCenter`).
- `DebugProfile.entitlements` & `Release.entitlements` (`com.apple.security.app-sandbox = false`, `com.apple.security.network.client = true`, `com.apple.security.automation.apple-events = true`), `Info.plist` (`LSUIElement = true`, `NSAppleEventsUsageDescription`), and `scripts/install_macos_dev.sh` (`chmod 600` on `host-policy.json`, per-user `LaunchAgents` plist).

### S3.7 — End-to-End Hardening & Conformance Re-run
- Added hardening suite in `desktop/test/desktop_agent_core_test.dart` covering Mode B reconnect after sleep/network loss without duplicate execution of in-flight calls, mid-session `host-policy.json` corruption & recovery (`notifications/tools/list_changed`), host revocation during an in-flight tool call (`dispatcher.cancelAllInFlight('revoked')`), duplicate session (`4001`), and content-free log/audit grep verification.

---

## 2. Automated Verification Evidence (2026-10-30, Windows)

| Repository | Command | Result |
|---|---|---|
| `desktop/packages/xuna_xtp` | `fvm dart format --output=none --set-exit-if-changed lib test` | **PASS** (0 changes) |
| `desktop/packages/xuna_xtp` | `fvm dart analyze` | **PASS** (`No issues found!`) |
| `desktop/packages/xuna_xtp` | `fvm dart test` | **17 / 17 PASS** (including byte-for-byte fixture parity with `backend/tests/fixtures/xtp/`) |
| `desktop/` | `fvm dart format --output=none --set-exit-if-changed lib test` | **PASS** (0 changes) |
| `desktop/` | `fvm flutter analyze --no-pub` | **PASS** (`No issues found!`) |
| `desktop/` | `fvm flutter test --reporter expanded` | **14 / 14 PASS** (core, S3.7 hardening, 1,000-frame fuzz test, Windows/macOS MethodChannel bridge tests) |
| `backend/` | `ruff check .` & `mypy` | **PASS** (`All checks passed!`, `Success: no issues found`) |
| `backend/` | `alembic upgrade head` & `pytest -q` | **446 / 446 PASS** (including PostgreSQL migrations `0013_hosts` + `0014_host_grants` and WebSocket/REST host tests) |
| `mobile/` | `fvm dart format --output=none --set-exit-if-changed lib test` | **PASS** (0 changes) |
| `mobile/` | `fvm flutter analyze --no-pub` | **PASS** (`No issues found!`) |
| `mobile/` | `fvm flutter test` | **356 / 356 PASS** (including `host_mapper_test.dart`, `hosts_repository_impl_test.dart`, `host_enroll_sas_widget_test.dart`) |

### What Was Not Run on This Machine
- `fvm flutter build windows`: requires the Visual Studio C++ desktop workload (`Unable to find suitable Visual Studio toolchain` on current host).
- `fvm flutter build macos`: requires macOS + Xcode.
- Live LAN interactive run between compiled Windows/macOS native tray binaries, the phone camera QR scanner, and `backend/scripts/host_call.py` (covered by checklist §3 below).

---

## 3. Acceptance Matrix (§7 of `UDC-3-desktop-agent.md`)

| Check | Automated Verification | Physical LAN Checklist (Windows + Mac) |
|---|---|---|
| **Enrollment** (QR + SAS; wrong SAS `"Không khớp"` cancels; expired code refused) | **PASS** (`test_hosts_module.py`, `host_enroll_sas_widget_test.dart`, `desktop_agent_core_test.dart`) | [ ] Scan QR on Windows & macOS, test `"Không khớp — Hủy"`, then confirm matching SAS |
| **Every MVP tool** (`structuredContent` + `xuna/status = ok` or `unsupported`) | **PASS** (all 12 tools tested in `desktop_agent_core_test.dart` & `method_channel_xuna_host_test.dart`) | [ ] Run `python scripts/host_call.py --host <id> --tool <name>` across all 12 tools on Windows & macOS |
| **Grants** (R2 without grant → `denied`; without approval → `denied`; with dev approval → `ok`) | **PASS** (`test_hosts_module.py`, `xuna_xtp_test.dart`, `desktop_agent_core_test.dart`) | [ ] Toggle family grants in mobile app and re-run `host_call.py --issue-dev-approval` |
| **Approval binding** (mutating 1 arg after approval → `denied` / `approval_mismatch`) | **PASS** (`xuna_xtp_test.dart`, `desktop_agent_core_test.dart`) | [ ] Verify mutated argument is rejected by agent |
| **Local policy** (corrupted `host-policy.json` → all except `host.status` denied; restore → recovers with `list_changed`) | **PASS** (`desktop_agent_core_test.dart` S3.4 + S3.7 hardening) | [ ] Corrupt `host-policy.json` on disk, verify `"Cấu hình lỗi"` tray state, then click `"Khôi phục chính sách mặc định"` |
| **OS permission** (macOS without Accessibility/Automation → `needs_permission`, never a crash) | **PASS** (`desktop_agent_core_test.dart`, `method_channel_xuna_host_test.dart`) | [ ] On macOS, test before granting Accessibility/Automation, then grant in System Settings and focus XUNA window |
| **Revocation** (Revoke in app → session closed ≤ 5 s, in-flight cancelled, agent back to enrollment) | **PASS** (`test_hosts_module.py`, `desktop_agent_core_test.dart` S3.7 hardening) | [ ] Tap `"Ngắt kết nối vĩnh viễn"` in mobile app while connected |
| **Resilience** (Sleep/wake & Wi-Fi off/on → reconnect ≤ 60 s; no duplicate execution of in-flight call) | **PASS** (`desktop_agent_core_test.dart` S3.7 hardening) | [ ] Sleep/wake laptop and toggle Wi-Fi during active session |
| **E-stop** (Hotkey `Ctrl+Alt+Shift+X` → in-flight call cancelled, new calls `denied (stopped)` until re-enabled) | **PASS** (`desktop_agent_core_test.dart`) | [ ] Press `Ctrl+Alt+Shift+X`, verify toast/tray state, then click `"Bật lại XUNA"` |
| **Logs** (Agent and backend logs contain no arguments, URLs, titles, or app paths) | **PASS** (`test_hosts_module.py` + `desktop_agent_core_test.dart` S3.7 grep test) | [ ] Inspect `audit-YYYY-MM-DD.jsonl` and backend stdout after tool runs |

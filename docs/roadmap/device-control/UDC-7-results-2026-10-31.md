# UDC-7 — Multi-Host Targeting, Permissions UX, Emergency Stop, LAN Offline Mode & Phone-Signed R3 Approvals Results (2026-10-31)

Status: **Implemented** (automated unit/widget/native/backend/desktop/firmware verification PASS across all 5 sessions S7.1–S7.5; physical multi-host LAN + T-Display-S3 board acceptance matrix ready for owner device run).

---

## 1. Summary of Delivered Sessions (S7.1–S7.5)

| Session | Deliverable | Verification Evidence |
|---|---|---|
| **S7.1 — Grants Model & Approval Scopes** | Migration `0016_udc7_grants_and_approvals.py` (`host_grants.expires_at`, `host_grants.suspended_at`, `action_approvals.scope`); `PUT /v1/hosts/{hostId}/grants` supporting `expiresAt` (`1h`, `1d`, `never` / ISO-8601) and `suspendAll` (`true` / `false`); `ActionOrchestrator` & `InMemoryApprovalWaiter` supporting `ApprovalScope.CONVERSATION_15M` (15-minute same-conversation, same-host, same-tool auto-approval for **R2 host tools only**; R3 and `board.media_key` are strictly `once`); `HostDetailSheet` expiry selector (`1 giờ` / `1 ngày` / `Không giới hạn`) & `"Tạm khoá tất cả"` / `"Bật lại quyền"`; `HomeActionApprovalSheet` R2 scope selector (`"Chỉ lần này"` vs `"Trong cuộc trò chuyện này (15 phút)"`) | Backend: `test_udc7_multihost.py` (`test_s7_1_grants_expiry_suspension_and_r2_conversation_scope`) PASS; Mobile: `hosts_repository_impl_test.dart` & `actions_test.dart` S7.1 unit + widget tests PASS |
| **S7.2 — Targeting Hardening & Alias-Everywhere** | Pure `TargetResolver` extended with pronoun resolution (`"nó"`, `"máy đó"`, `"máy kia"`, `"pc kia"`, `"the other one"`, `"it"`), capability filtering (`capable_host_ids`), and 5-minute `last_target` sticky resolution (`LAST_TARGET_TTL_SECONDS = 300`); 50-request scripted multi-host benchmark across 2 PCs + 1 phone + board (`0` wrong-host executions); `HomeActionApprovalSheet.summaryWithAlias`, `formatChipLabel`, and `formatBoardSubtitle` guaranteeing the target host alias appears on every approval card, chat action chip, and board speech bubble | Backend: 50-request multi-host benchmark in `test_udc7_multihost.py` (`wrong_host_executions == 0`, 50/50 exact match); Mobile: S7.2 alias-everywhere widget tests in `actions_test.dart` PASS |
| **S7.3 — Emergency Stop End-to-End** | Firmware: `bothHold` in Remote mode stops HID output and emits status notification kind `3` (`kStatusRemoteEvent`, `arg = 1` stop) on `7a6e0004`, gated by capability byte 5 bit 6 (`0x40`); Backend: `POST /v1/actions/stop`, inbound `xuna/stop` on `/v1/hosts/connect`, and `action.stop` on `/v1/voice` cancel all active invocations, reject pending approvals, broadcast `xuna/stop` to all live hosts of the owner, set `suspended_at` on all R2+ grants, clear active `conversation_15m` scopes, and log `AuditAction.HOST_STOPPED`; Mobile & Desktop: App `"Dừng hành động"` bar, board status kind 3 listener, Siri `StopXunaActionsIntent`, and Desktop Agent hotkey/tray stop (`xuna/stop {reason: "owner_host"}`) | Firmware: `test_remote_mode` 5/5 PASS, `xuna_t_display_s3` build SUCCESS; Backend: `test_s7_3_emergency_stop_cancels_suspends_and_audits` PASS; Desktop: `desktop_agent_core_test.dart` PASS; Mobile: `protocol_codec_test.dart` & `actions_test.dart` PASS |
| **S7.4 — LAN Offline Mode (`media.*` only)** | Desktop Agent: optional `LanOfflineServer` on `127.0.0.1` / LAN `:47821/xuna-lan` (**off by default**, owner toggle in Desktop Agent settings) + UDP mDNS `_xuna-host._tcp.local` responder with `hostIdHash`; `xuna/lanPeer` mutual key pinning during session setup; mutual P-256 challenge-response proof (`xuna.host.v1\x00`, `purpose = 2`); strict `media.*`-only filter rejecting any non-media tool with `status = "denied"`, `errorCode = "lan_media_only"`; Mobile: `LanHostClient` with UDP mDNS discovery, mutual P-256 verification, and client-side `lan_media_only` guard | Desktop: `xuna_xtp_test.dart` (19/19 PASS) & `desktop_agent_core_test.dart` (`LanOfflineServer` loopback WebSocket mutual P-256 + `lan_media_only` rejection, 15/15 PASS); Mobile: `hosts_repository_impl_test.dart` S7.4 loopback WebSocket test PASS |
| **S7.5 — Phone-Signed R3 Approvals** | Canonical signing domain `b"xuna.approval.v1\x00" + "{approvalId}\|{argsSha256}\|{hostId}\|{expiresAt}"`; Mobile `HomeActionsService` signs R3 approvals with the enrolled phone P-256 key and sends `signature` + `publicKey` in `POST /v1/actions/approvals/{approvalId}`; Backend verifies the P-256 signature against the owner's enrolled phone host keys (`platform in ("android", "ios")`) and forwards `signature` & `publicKey` in `_meta["xuna/approval"]`; Desktop Agent (`HostPolicyEvaluator` + `HostToolDispatcher`) independently verifies the phone signature against pinned owner phone keys and rejects missing/forged signatures with `errorCode = "approval_signature_invalid"` | Backend: `test_s7_5_r3_phone_signed_approval_verified_and_forwarded` PASS; Desktop: `xuna_xtp_test.dart` & `desktop_agent_core_test.dart` R3 signature tests PASS; Mobile: `actions_test.dart` S7.5 test PASS |

---

## 2. S7.2 Multi-Host Targeting Benchmark Summary (50 Scripted Requests)

The 50-request multi-host suite (`test_s7_2_fifty_scripted_multihost_requests_zero_wrong_host` in `backend/tests/unit/test_udc7_multihost.py`) evaluates a 4-target topology (`Laptop làm việc`, `PC phòng khách`, `Điện thoại của Thảo`, and `board` Bluetooth HID):

| Category | Requests | Expected Outcome | Result |
|---|---:|---|---|
| Explicit alias mentions (`"Laptop làm việc"`, `"PC phòng khách"`, `"Điện thoại của Thảo"`, `"mạch XUNA"`) | 20 | Resolve to the named target | **20 / 20 PASS** |
| Follow-up pronouns within 5 min (`"nó"`, `"máy đó"`, `"it"`) | 10 | Resolve to `last_target_id` | **10 / 10 PASS** |
| Contrastive pronouns with 2 desktop hosts (`"máy kia"`, `"pc kia"`, `"the other one"`) | 8 | Switch deterministically to the other desktop host | **8 / 8 PASS** |
| Capability-filtered requests (e.g. only 1 host has `workflow.run` or `ui.tap_text` granted/capable) | 6 | Resolve to the unique capable host | **6 / 6 PASS** |
| Ambiguous multi-host requests (no alias, expired `last_target` or multiple capable hosts) | 6 | `TargetResolutionOutcome.AMBIGUOUS` (ask owner, never guess) | **6 / 6 PASS** |
| **Total Wrong-Host Executions** | **50** | **`0`** | **`0` (100% safe)** |

---

## 3. Security Invariants Verified

1. **R3 is never scoped and always phone-signed:** `ApprovalScope.CONVERSATION_15M` is rejected for R3 tools and `board.media_key` at the mobile UI, backend API, orchestrator, and `xuna_xtp` policy evaluator. Every R3 desktop invocation requires a valid P-256 signature over `xuna.approval.v1\x00 || approvalId || argsSha256 || hostId || expiresAt` from an enrolled phone key.
2. **Emergency stop suspends R2+ grants:** Triggering stop from the App, Desktop Agent hotkey/tray, Board `bothHold` in Remote mode, or Siri cancels all active invocations, rejects pending approvals, clears `conversation_15m` scopes, and sets `suspended_at` on all R2+ grants until the owner explicitly taps **"Bật lại quyền"** in the app.
3. **LAN offline server is opt-in and `media.*` only:** `LanOfflineServer` defaults to `enabled = false`, requires mutual P-256 challenge-response proof before `xuna/ready`, and rejects any non-`media.*` tool call (`lan_media_only`).
4. **Device authority preserved:** Status kind `3` (`remoteEvent`, `arg = 1`) on `7a6e0004` never mutates `LifeCore`, `ProductLearner`, needs, or personality snapshots.

---

## 4. Owner Physical Multi-Host & Board Acceptance Runbook

1. **Flash Firmware with S7.3 Remote Stop (`xuna_t_display_s3`):**
   ```powershell
   & "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run -d firmware -e xuna_t_display_s3 -t upload
   ```
2. **Board Emergency Stop (`bothHold` in Remote mode):**
   - Connect the app and a Bluetooth HID host to the board; enter `Remote` mode (`GPIO14` hold).
   - Start an action or pending approval in the app, then hold both buttons (`GPIO0 + GPIO14`) for 400 ms on the board.
   - Verify the board shows `"Đã dừng"`, the app immediately cancels the pending approval, and `POST /v1/actions/stop` suspends R2+ grants (`"Đang tạm khoá"` in `HostDetailSheet`).
3. **Grants Expiry, `conversation_15m` Scope & Re-enable:**
   - Open **Thiết bị → Máy tính & Điện thoại → Chi tiết máy** (`HostDetailSheet`).
   - Tap **"Bật lại quyền"**, set `Mở ứng dụng` (`R2`) expiry to **1 giờ**, and ask XUNA to open an allowlisted app.
   - Select **"Trong cuộc trò chuyện này (15 phút)"** on the approval card and approve; repeat the command within 15 minutes and verify it executes without a second prompt.
4. **LAN Offline Mode (`media.*` only):**
   - Enable **Chế độ LAN nội bộ (chỉ điều khiển nhạc)** in the Desktop Agent window (`:47821/xuna-lan`).
   - Stop the backend server and trigger `media.play_pause` over `LanHostClient` on the same LAN → verify playback toggles and any non-media tool is rejected with `lan_media_only`.


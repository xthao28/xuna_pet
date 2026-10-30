# UDC-5 — Android Mobile Host Adapter Results (2026-10-30)

Status: **Implemented** (automated unit/widget/backend verification PASS; physical Android phone manual matrix pending owner device run).

## 1. Summary of Delivered Sessions (S5.1–S5.5)

| Session | Deliverable | Verification Evidence |
|---|---|---|
| **S5.1** | Kotlin plugin `xuna/android_host` (`XunaAndroidHostPlugin.kt`, `XunaMediaListener.kt` strict no-op, `XunaHostForegroundService.kt`), `AndroidManifest.xml` (`<queries>` without `QUERY_ALL_PACKAGES`, no `BIND_ACCESSIBILITY_SERVICE`), Dart Clean Architecture (`AndroidHostRepositoryImpl`, `ExecuteAndroidHostToolUseCase`, `FakeAndroidHostLocalDataSource`) | `fvm flutter analyze --no-pub` (0 issues); `android_host_adapter_test.dart` S5.1 tests PASS |
| **S5.2** | Backend `POST /v1/hosts/self/challenge`, `POST /v1/hosts/self` (purpose-1 ECDSA P-256 proof, idempotent by public key), `PUT /v1/hosts/{id}/manifest`, `LocalActionRequestEvent` (`local_action_request` on SSE + Voice WS), `/v1/actions/{id}/result` extended with `output` & `errorCode`; Mobile `SelfEnrollAndroidHostUseCase`, `ReportLocalActionResultUseCase`, `HomeActionsService.handleLocalActionRequest` | Backend: `ruff check` 0 errors, `mypy src` 0 errors, `pytest` `457 passed` (`test_self_enrollment_and_local_action.py`); Mobile: `android_host_adapter_test.dart` S5.2 tests PASS |
| **S5.3** | Opt-in `connectedDevice` Foreground Service + `AndroidHostSessionDataSource` (XTP v1 Mode B `/v1/hosts/connect` with `platform: "android"`, purpose-2 session proof, `tools/list`, `tools/call`, heartbeat `ping`, exponential backoff reconnect, immediate stop on BLE disconnect) | Backend Mode B Android WS test + Mobile S5.3 reconnect/lifecycle test PASS |
| **S5.4** | `CompanionDeviceManager` association (`companionAssociate` + API 31+ `startObservingDevicePresence`), background-start handling (`background_start_blocked` + tap-to-open `PendingIntent` notification fallback), prominent disclosures (`AndroidPermissionDisclosureSheet`, `AndroidPhoneHostCard` in `vi_VN` + `en_US`), Play declarations (`UDC-5-play-declarations.md`) | `fvm flutter analyze --no-pub` (0 issues); full `fvm flutter test --no-pub` PASS (`377 passed`) |
| **S5.5** | Gradle product flavours `play` (`isDefault = true`, zero `AccessibilityService`) and `dev` (`applicationIdSuffix = ".dev"`, merges `src/dev/AndroidManifest.xml` with `XunaAccessibilityService`); deterministic single-shot `ui.back`, `ui.home`, `ui.recents` (`R2`), and `ui.tap_text` (`text <= 40` chars, `R3`, approval every time, no autonomous loop) | CI manifest & source-set check + deterministic `ui.*` unit tests PASS in `android_host_adapter_test.dart` |

## 2. Background-Start & CompanionDeviceManager Behaviour Matrix

| Scenario | Foreground / Background State | CompanionDeviceManager Associated? | Behaviour & Result |
|---|---|---|---|
| `media.play_pause`, `media.next`, `media.previous`, `media.now_playing` | Foreground (same-device turn) or Background (`connectedDevice` FGS on) | Not required (requires Notification Access) | Selects active session in `STATE_PLAYING` first (e.g. Spotify over paused YouTube Music), dispatches `MediaController.transportControls`, returns `{ok: true, package, state, title, artist}`. |
| `media.volume_set` | Foreground or Background | Not required | Sets `AudioManager.STREAM_MUSIC` volume (`0..100`) and returns `{ok: true, level}`. |
| `app.launch` / `url.open` | Foreground (owner asks on the same phone) | Not required | Starts activity directly with `FLAG_ACTIVITY_NEW_TASK`; returns `{ok: true, package, label}` / `{ok: true, host}`. |
| `app.launch` / `url.open` | Background (`connectedDevice` FGS active, triggered from another client) | **Yes** (`companionAssociated == true`) | Android grants the companion-device background activity start exemption; activity launches directly and returns `status: "ok"`. |
| `app.launch` / `url.open` | Background (`connectedDevice` FGS active, triggered from another client) | **No** (`companionAssociated == false`, blocked by Android 10+ BAL restrictions) | Returns `status: "failed"`, `errorCode: "background_start_blocked"` and posts high-priority tap-to-open notification (`"Chạm để mở {app}"` / `PendingIntent`), which Android always permits upon user tap. |


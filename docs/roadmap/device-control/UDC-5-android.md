# UDC-5 — Android Mobile Host Adapter

Status: **Proposed** — needs an owner go-ahead. Complexity: L (5 sessions; S5.5 optional). Repositories: mobile, backend (small).

## 1. Goal

The owner's Android phone becomes a host. XUNA can control media in other apps (Spotify, YouTube Music…), adjust volume, open allowlisted apps and https links. It does this when the owner asks on that phone, and, when allowed, while the app runs in the background with the board connected.

Everything stays within Google Play policy (UDC-D5). Accessibility-driven UI actions exist **only** in a sideloaded dev flavour (S5.5).

## 2. Gate

- UDC-4 Done.
- Owner go-ahead.
- Before any Play release, the owner decides the real `applicationId`. Today it is `com.example.xuna_mobile` in `android/app/build.gradle`.

## 3. Read first

- [README](README.md); [UDC-3 §5.2–§5.3](UDC-3-desktop-agent.md#52-xtp-v1-wire-contract) (XTP and tool shapes reused); [UDC-4 §5.2–§5.4](UDC-4-brain-tools.md).
- `mobile/android/app/src/main/AndroidManifest.xml` (current permissions: BLUETOOTH*, location, INTERNET, RECORD_AUDIO) and `MainActivity.kt` (no plugins yet).
- `mobile/android/app/build.gradle` (minSdk/targetSdk, `ndkVersion`, conditional google-services).
- Android docs:
  - [MediaSessionManager](https://developer.android.com/reference/android/media/session/MediaSessionManager): `getActiveSessions(ComponentName)` requires an enabled NotificationListener.
  - [NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService).
  - [FGS types](https://developer.android.com/develop/background-work/services/fgs/service-types) (`connectedDevice`).
  - Background activity start restrictions (developer.android.com, "Restrictions on starting activities from the background"): **verify** the CompanionDeviceManager exemption.
  - [CompanionDeviceManager](https://developer.android.com/reference/android/companion/CompanionDeviceManager).
  - Package visibility (`<queries>`).
- [Play AccessibilityService policy](https://support.google.com/googleplay/android-developer/answer/10964491): autonomous AI control is prohibited.
- References:
  - droidrun `mobilerun-portal` manifest — an example of permissions **not** to request; AGPL, read only.
  - uiautomator2 / scrcpy / appium for QA only.

## 4. Scope

**In scope:**

- A Kotlin plugin, `xuna/android_host`.
- Phone self-enrollment as a host.
- Same-device execution through the turn stream.
- Background reachability with a `connectedDevice` foreground service while the board is connected (owner opt-in).
- CompanionDeviceManager association.
- Disclosures.
- An optional dev flavour with Accessibility.

**Out of scope:**

- Reading notification content (U6) beyond media sessions. It would be a separate session after an owner request.
- Screen capture.
- Play release paperwork. The owner does it; this milestone prepares the declarations text.

## 5. Design

### 5.1 Kotlin plugin `xuna/android_host` (MethodChannel)

| Method | Implementation | Permission |
|---|---|---|
| `mediaSessions` | `MediaSessionManager.getActiveSessions(ComponentName(ctx, XunaMediaListener::class))` → `[{package, state, title?, artist?}]` | Notification access |
| `media {cmd, package?}` | `MediaController.transportControls.play/pause/skipToNext/skipToPrevious` on the chosen or most recent active session | Notification access |
| `volumeSet {level}` | `AudioManager.setStreamVolume(STREAM_MUSIC, level * max / 100, 0)` | none |
| `launchableApps` | `queryIntentActivities(Intent(ACTION_MAIN).addCategory(CATEGORY_LAUNCHER))`, visible through `<queries><intent>…MAIN/LAUNCHER…</intent></queries>` (**no** `QUERY_ALL_PACKAGES`) | none |
| `appLaunch {package}` | `getLaunchIntentForPackage(pkg)` + `FLAG_ACTIVITY_NEW_TASK` | Background start limits apply |
| `urlOpen {url}` | `Intent(ACTION_VIEW, Uri.parse(url))` after Dart-side validation (same rules as UDC-3) | — |
| `keyEnsure` / `keySign` | Android Keystore EC P-256 (`KeyGenParameterSpec`, `PURPOSE_SIGN`, `DIGEST_SHA256`, StrongBox if available); DER → raw r‖s | — |
| `notificationAccess` / `openNotificationAccessSettings` | `NotificationManagerCompat.getEnabledListenerPackages` / `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS` | — |
| `companionAssociate {serviceUuid}` | `CompanionDeviceManager.associate` with a `BluetoothLeDeviceFilter` for `7a6e0001-…`; API 31+: `startObservingDevicePresence` | — |

`XunaMediaListener : NotificationListenerService` exists only to qualify for media-session access. It **does not read notification content** (`onNotificationPosted` is a no-op) until U6 is implemented.

### 5.2 Phone as a host

**Self-enrollment** (no QR; the owner is already signed in on this phone):

- The app calls `POST /v1/hosts/self {platform: "android", osVersion, agentVersion, publicKey, alias, proof}`.
- `proof` uses purpose 1 over a server nonce from `POST /v1/hosts/self/challenge`.
- This is a backend addition to the `hosts` module (UDC-3), owner-scoped and audited `host.enrolled`.

**Same-device execution** (the common case: the owner asks on this phone and targets this phone):

- The orchestrator emits `local_action_request {invocationId, approvalId?, tool, arguments}` in the turn stream instead of using a host socket.
- The app runs it through the plugin and POSTs `/v1/actions/{invocationId}/result {status, output}`. This is the UDC-4 route, extended with `output`.

**Background reachability** (another device asks for this phone, e.g. the PC chat or a future board voice):

- Needs a host WSS from the phone.
- Allowed only while a `connectedDevice` foreground service runs. The service is justified by the BLE link to the board and needs `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_CONNECTED_DEVICE` + `BLUETOOTH_CONNECT`.
- It is opt-in ("Cho phép XUNA điều khiển điện thoại khi chạy nền") and shows a persistent notification.
- Without it, the phone host shows "offline" in the registry.

**Tools offered for Android hosts:**

- `media.play_pause`, `media.next`, `media.previous`, `media.volume_set`, `media.now_playing`;
- `app.launch` (owner-allowlisted packages from `launchableApps`), `app.list_allowed`;
- `url.open`;
- `host.status`.

The schemas are identical to UDC-3; the descriptor's `_meta["xuna/policy"].platform = "android"`.

**Background start:**

- `app.launch` / `url.open` from the background may be blocked (Android 10+).
- With a CompanionDeviceManager association, Android lists an exemption. Verify on the test phone and record it.
- When blocked, return `failed` with `errorCode = "background_start_blocked"` and post a notification "Chạm để mở {app}" (a PendingIntent, always allowed).

### 5.3 Disclosures (Play)

- Show an in-app prominent-disclosure screen before each system permission screen: notification access (purpose: media control only), FGS and companion association. Copy in vi + en.
- Prepare Play declaration texts in `docs/roadmap/device-control/UDC-5-play-declarations.md`: foreground service type `connectedDevice` justification; notification listener use.

### 5.4 S5.5 (optional, separate go-ahead) — dev flavour with Accessibility

- Gradle product flavours `play` (default) and `dev`. Only `dev` merges a manifest with `XunaAccessibilityService`.
- Deterministic tools only:
  - `ui.back`, `ui.home`, `ui.recents` (`performGlobalAction`);
  - `ui.tap_text {text ≤ 40}` (find a node by visible text, R3, approval every time).
- No autonomous loop, and never in the `play` flavour (CI check: the `play` APK manifest must not contain `BIND_ACCESSIBILITY_SERVICE`).

## 6. Sessions

| Session | Content | Acceptance |
|---|---|---|
| S5.1 | Kotlin plugin: media sessions, volume, launchable apps, launch, URL, key, notification access; manifest `<queries>` and listener; Dart wrapper + fakes | Unit tests (Dart); manual on one device: control Spotify and YouTube Music |
| S5.2 | Backend `POST /v1/hosts/self*`, `local_action_request` event, result with output; app self-enrollment + same-device execution | `check.sh` PASS; flutter tests; voice "tạm dừng nhạc" pauses Spotify on the same phone |
| S5.3 | FGS `connectedDevice` opt-in + host WSS in background + reconnect | Phone host online while backgrounded with the board connected; offline otherwise |
| S5.4 | CompanionDeviceManager association + background-start verification + disclosures + Play declaration texts | Results record which starts work in the background on the test device |
| S5.5 | *(optional)* dev flavour Accessibility tools | CI manifest check; dev APK only |

## 7. Acceptance

- Media control of ≥ 2 third-party players from voice on the same phone: 10/10.
- Background (FGS on), triggered from another client: 10/10.
- App launch and URL open: in the foreground 10/10; in the background either works (exemption) or shows the tap-to-open notification.
- The `play` build has no Accessibility service and no `QUERY_ALL_PACKAGES`.
- Disclosures appear before every system permission screen.
- Board BLE and the app's existing features are unaffected (regression run of the device tab).

## 8. Risks

| Risk | Mitigation |
|---|---|
| OEM battery managers kill the FGS | Document per device; guide the owner to exempt XUNA |
| Media session selection is wrong with several players | Prefer the session in `STATE_PLAYING`, else the most recently active; the result names the app |
| Play review rejects the FGS type | Keep the FGS optional; same-device execution works without it |

## 9. Brief for a coding agent

> Mobile Android work plus a small backend addition.
>
> Read `docs/roadmap/device-control/README.md`, this file, UDC-3 §5.2–§5.3 and UDC-4 §5.2–§5.5, mobile/AGENTS.md and backend/AGENTS.md.
>
> Build the Kotlin plugin exactly per §5.1:
> - no `QUERY_ALL_PACKAGES`;
> - the notification listener never reads content;
> - no Accessibility in the main build.
>
> Then self-enrollment, same-device execution, the optional FGS, companion association and disclosures.
>
> Ask the owner before S5.5.
>
> Report in Vietnamese, including which background behaviours were verified on which phone model and Android version.

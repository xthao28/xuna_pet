# UDC-6 — iOS adapter and the AMS spike

Status: **Proposed** — needs an owner go-ahead. Complexity: M (3 sessions). Repositories: mobile (Swift in `ios/Runner`), firmware (AMS spike), backend (none beyond UDC-4/5 routes).

## 1. Goal

On iPhone, XUNA does what iOS allows and does it clearly:

1. **Siri / Shortcuts / Action button** can talk to XUNA and stop all actions, through App Intents.
2. The iPhone acts as a **foreground-only** host for `url.open` and Apple Music control.
3. **AMS spike (UDC-D9):** the board, over its bonded link, controls media on the iPhone (any player that publishes now-playing information) and reads the playing state. The XUNA app does not need to be open.

No feature claims control of other apps' UI or notifications.

## 2. Gate

- UDC-4 Done (for 1–2).
- UDC-1 PASS and UDC-2 Done (for 3: the iPhone must be bonded with the board).
- Owner go-ahead.

## 3. Read first

- [README](README.md).
- `mobile/ios/Runner/AppDelegate.swift`, `Info.plist`: no background modes today; iOS minimum 15.0 (owner-approved).
- [App Intents](https://developer.apple.com/documentation/appintents) (iOS 16+), [MPMusicPlayerController](https://developer.apple.com/documentation/mediaplayer/mpmusicplayercontroller) (`systemMusicPlayer`), [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) 2.5.1 / 2.5.4 / 2.5.11.
- [AMS specification](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleMediaService_Reference/Introduction/Introduction.html).
- ESP-IDF Bluedroid ANCS example `examples/bluetooth/bluedroid/ble/ble_ancs` (Unlicense/CC0; **verify the path**). It shows a peripheral that opens a GATT **client** on the iPhone's existing link, which is the pattern AMS needs.
- Firmware `HidManager.h` from UDC-1/2 (GAP/GATTS handlers, bonded link table).

## 4. Design

### 4.1 App Intents (Swift, in the Runner target; iOS 16+ behind `@available`)

| Intent | Parameters | Behaviour |
|---|---|---|
| `AskXunaIntent` ("Hỏi XUNA") | `text: String` | Runs one chat turn natively: Firebase `Auth.auth().currentUser?.getIDToken()` → `POST /v1/conversations/{petId}/turns` (SSE) with **no** `clientCapabilities`, so no tools run from Siri in this milestone. Returns the `say` text as the intent dialog. `petId` comes from shared app storage written by Flutter |
| `StopXunaActionsIntent` ("Dừng mọi thao tác của XUNA") | — | `POST /v1/actions/stop` (UDC-7 route; until then, cancel pending approvals via UDC-4 routes) |
| `OpenXunaRemoteIntent` | — | Opens the app on the Remote card (`openAppWhenRun = true`) |

- Shared storage: `UserDefaults(suiteName:)` is not needed (same app). Flutter writes `petId` and the backend base URL through a tiny MethodChannel `xuna/ios_bridge` (`setIntentContext`).
- **Never store tokens there.** Firebase gives a fresh token natively.
- `AppShortcutsProvider` lists Vietnamese and English phrases. Owners can compose their own Shortcuts with these intents. XUNA never runs the owner's Shortcuts by itself.

### 4.2 iPhone as a foreground-only host

- Self-enrollment as in UDC-5 §5.2 (`platform: "ios"`), with a Secure Enclave P-256 key via the `xuna/ios_bridge` channel (`keyEnsure` / `keySign`, DER → r‖s).
- Same-device execution only (`local_action_request`). There is no background host socket on iOS: the registry shows the iPhone online only while the app is in the foreground.
- **Tools:**
  - `url.open` (UIApplication `open(_:)`; allowlisted domains);
  - `media.play_pause` / `next` / `previous` / `now_playing` for **Apple Music only** via `MPMusicPlayerController.systemMusicPlayer` (`NSAppleMusicUsageDescription` + `MPMediaLibrary.requestAuthorization`);
  - `host.status`.
  - The manifest marks every other tool `unsupported`.

### 4.3 AMS spike (firmware, experimental env `xuna_ams`, off by default)

AMS identifiers (copy from the spec and verify each one):

| Item | UUID / value |
|---|---|
| Service | `89D3502B-0F36-433A-8EF4-C502AD55F8DC` |
| Remote Command (write/notify) | `9B3C81D8-57B1-4A8A-B8DF-0E56F7CA51C2` |
| Entity Update (write with response/notify) | `2F7CABCE-808D-411F-9A0C-BB92BA96C102` |
| Entity Attribute (read/write) | `C6B2F38C-23AB-46D8-A6AB-A3A870BBD5D7` |
| Remote command IDs | Play 0, Pause 1, TogglePlayPause 2, NextTrack 3, PreviousTrack 4, VolumeUp 5, VolumeDown 6 (others unused) |
| Entities / attributes used | Player (0): PlaybackInfo (1); Track (2): Artist (0), Title (2) |

**Flow:**

1. The bonded iPhone is connected (as the XUNA app phone and/or the HID host).
2. The board opens a GATT client on that link (`esp_ble_gattc_open` on the existing ACL, following the ANCS example).
3. It discovers AMS.
4. It subscribes to Remote Command (supported commands) and Entity Update.
5. It writes Entity Update `[Track, Title, Artist]` and `[Player, PlaybackInfo]`.

**Remote mode on an iPhone link:** when the connected host is the iPhone and AMS is present, Remote presses send AMS remote commands instead of HID consumer reports. This works for any player that publishes now-playing information.

**Display:** the title/artist truncated to 24 chars in the Remote bubble. Kept in RAM only, never sent anywhere.

**Spike acceptance:**

- Play/Pause, Next, Previous on Apple Music and Spotify 10/10 with the XUNA app closed.
- The title shows within 1 s of a track change.
- No reset in 15 minutes.
- RAM recorded.

If AMS requires anything the app link cannot provide (e.g. its own bond), record it and stop.

In `xuna_ams` builds the board sets capability byte 5 bit 7 (`0x80`, AMS client present; [README register](README.md#21-firmware-ble-custom-service-7a6e0001-8c44-4db6-9f61-2b7d5300a101)).

ANCS (notifications) is **not** part of this spike; it needs U6 and its own go-ahead.

## 5. Sessions

| Session | Content | Acceptance |
|---|---|---|
| S6.1 | App Intents + `xuna/ios_bridge` + Siri phrases | On the owner's iPhone: "Hỏi XUNA …" answers; the stop intent cancels a pending approval |
| S6.2 | Self-enrollment + foreground host (URL, Apple Music) | Voice "mở github" opens Safari on an allowlisted domain; Apple Music pause works; other tools reported unsupported |
| S6.3 | AMS spike on the board | §4.3 spike acceptance; results file |

## 6. Risks

| Risk | Mitigation |
|---|---|
| App Intents need iOS 16, app minimum is 15.0 | `@available(iOS 16, *)`; iOS 15 users simply do not see the intents |
| App Review questions BLE background use | No new background mode in this milestone; AMS runs on the board, not in the app |
| AMS reliability across iOS versions | A spike only; adopt after results |

## 7. Brief for a coding agent

> **S6.1–S6.2:** Swift in `mobile/ios/Runner` plus Dart wrappers.
> - Implement App Intents (iOS 16+ gated) and the `xuna/ios_bridge` channel per §4.1–§4.2.
> - Never store tokens in shared storage.
> - No tool execution from Siri.
>
> **S6.3:** firmware experimental env `xuna_ams`.
> - Implement the AMS client per §4.3, following the ESP-IDF Bluedroid ANCS example's pattern for opening a client on an existing link.
> - Verify every UUID and command ID against Apple's AMS specification before coding.
> - Only queue work in BT callbacks.
>
> Report in Vietnamese with device/iOS versions tested.

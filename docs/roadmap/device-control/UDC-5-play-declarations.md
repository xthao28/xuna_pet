# UDC-5 — Google Play Console Declarations (Android Mobile Host Adapter)

Status: **Implemented** (prepared 2026-10-30 for Play Console submission).

Before publishing to Google Play, the owner must replace the placeholder `applicationId` (`com.example.xuna_mobile` in `mobile/android/app/build.gradle`) with the final production reverse-domain identifier and paste the declarations below into Google Play Console.

---

## 1. Foreground Service Permission (`FOREGROUND_SERVICE_CONNECTED_DEVICE`)

### 1.1 Declared Permissions in `AndroidManifest.xml`

- `android.permission.FOREGROUND_SERVICE`
- `android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE`
- `android.permission.BLUETOOTH_CONNECT`
- Service component: `com.example.xuna_mobile.XunaHostForegroundService` (`android:foregroundServiceType="connectedDevice"`, `android:exported="false"`)

### 1.2 Play Console Justification Text (English)

> **Primary Purpose (`connectedDevice`):**
> XUNA is the companion app for the physical XUNA ESP32-S3 Bluetooth LE pixel-pet device (`serviceUuid = 7a6e0001-8c44-4db6-9f61-2b7d5300a101`). When the user explicitly opts into "Allow XUNA to control this phone in the background" AND the physical XUNA device is actively connected over Bluetooth LE, `XunaHostForegroundService` (`foregroundServiceType="connectedDevice"`) maintains a persistent notification and an authenticated session so the user can trigger media playback controls (play/pause, next/previous track, volume) or open user-allowlisted apps/links on their phone from their connected XUNA hardware setup.
>
> **Lifecycle & User Control:**
> - Disabled by default (strictly opt-in after an in-app prominent disclosure).
> - Starts only when the XUNA Bluetooth LE hardware is connected.
> - Stops immediately when the Bluetooth LE device disconnects or when the user turns off the setting.
> - Same-device voice/chat commands work in the foreground without this service.

### 1.3 Bản giải trình Play Console (Tiếng Việt)

> **Mục đích chính (`connectedDevice`):**
> XUNA là ứng dụng đồng hành cho thiết bị phần cứng thú cưng ảo XUNA ESP32-S3 kết nối qua Bluetooth LE (`serviceUuid = 7a6e0001-8c44-4db6-9f61-2b7d5300a101`). Khi người dùng chủ động bật tuỳ chọn *"Cho phép XUNA điều khiển điện thoại khi chạy nền"* VÀ mạch XUNA đang kết nối Bluetooth LE, `XunaHostForegroundService` (`foregroundServiceType="connectedDevice"`) hiển thị thông báo cố định và duy trì kết nối đã xác thực để người dùng có thể điều khiển nhạc (phát/dừng, chuyển bài, chỉnh âm lượng) hoặc mở ứng dụng/liên kết HTTPS nằm trong danh sách cho phép trên điện thoại.
>
> **Vòng đời & Quyền kiểm soát của người dùng:**
> - Mặc định TẮT (chỉ bật khi người dùng đồng ý sau màn hình công bố rõ ràng trong ứng dụng).
> - Chỉ chạy khi thiết bị phần cứng XUNA đang kết nối Bluetooth LE.
> - Tự động dừng ngay lập tức khi ngắt kết nối Bluetooth LE hoặc khi người dùng tắt tuỳ chọn.

---

## 2. Notification Listener Service (`XunaMediaListener`)

### 2.1 Declared Component in `AndroidManifest.xml`

- `com.example.xuna_mobile.XunaMediaListener` (`android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`, `android:exported="true"`)

### 2.2 Play Console & Privacy Policy Justification (English)

> **Why `NotificationListenerService` is required:**
> Android's `MediaSessionManager.getActiveSessions(ComponentName)` API requires a registered `NotificationListenerService` component in order to enumerate active third-party `MediaController` sessions (such as Spotify or YouTube Music) and send standard transport controls (`play`, `pause`, `skipToNext`, `skipToPrevious`).
>
> **Strict Data Minimization (Zero Notification Reading):**
> `XunaMediaListener` overrides `onNotificationPosted` and `onNotificationRemoved` as **strict no-ops**. The app never reads, inspects, logs, stores, or transmits notification text, titles, messages, or sender identities. Only active `MediaSession` metadata (`package`, playback state, track title/artist) is read on demand when the user explicitly asks XUNA to control or check music playback.

### 2.3 Bản giải trình Quyền truy cập thông báo (Tiếng Việt)

> **Lý do kỹ thuật:**
> API `MediaSessionManager.getActiveSessions(ComponentName)` của Android bắt buộc ứng dụng phải đăng ký một `NotificationListenerService` để liệt kê các phiên phát nhạc đang hoạt động (như Spotify, YouTube Music) và gửi lệnh điều khiển (`play`, `pause`, `skipToNext`, `skipToPrevious`).
>
> **Cam kết bảo mật dữ liệu (Không đọc nội dung thông báo):**
> Trong `XunaMediaListener`, hai hàm `onNotificationPosted` và `onNotificationRemoved` hoàn toàn để trống (**no-op**). Ứng dụng tuyệt đối không đọc, không lưu trữ và không gửi nội dung thông báo cá nhân của người dùng lên máy chủ.

---

## 3. Package Visibility (`<queries>`) & Accessibility Policy Compliance

1. **No `QUERY_ALL_PACKAGES`:**
   `mobile/android/app/src/main/AndroidManifest.xml` uses narrow `<queries>` declarations only:
   - `Intent(ACTION_MAIN)` + `CATEGORY_LAUNCHER` (to let the user pick which installed apps XUNA is allowed to launch), and
   - `Intent(ACTION_VIEW, https://...)` (to open allowlisted HTTPS links).
2. **No `BIND_ACCESSIBILITY_SERVICE` in the Play build:**
   The main `AndroidManifest.xml` declares **zero** AccessibilityService components, complying strictly with Google Play's AccessibilityService policy against autonomous AI UI control.
3. **In-App Prominent Disclosures:**
   Implemented in `AndroidPermissionDisclosureSheet` (`vi_VN` and `en_US`) and shown before opening:
   - `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`,
   - `CompanionDeviceManager.associate(...)`, and
   - Enabling the `connectedDevice` Foreground Service toggle.

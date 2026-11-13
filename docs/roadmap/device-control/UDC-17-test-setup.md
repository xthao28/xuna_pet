# Dựng môi trường test UDC-17 (Mac + điện thoại Android)

Ngày: 2026-11-13. Dành cho chủ dự án, trước khi làm checklist [UDC-16](UDC-16-device-test-checklist.md) (§4c–§4k).

**Trạng thái:**
- Chưa ai chạy luồng điều khiển máy tính đầu-cuối: backend thật, app máy tính thật, điện thoại thật, model thật.
- Đã kiểm: build APK dev trên máy Windows bằng Flutter 3.32.8 (2026-11-13). Build thành công, `pubspec.lock` và các file được track không đổi.
- Chưa kiểm: mọi bước trên Mac với bản hiện tại. App máy tính **chưa từng được build** thành app macOS (`flutter build macos` / `flutter run -d macos`).

## Vì sao Mac + Android

- **Mac** chạy backend (đã từng chạy với DB `xuna_local`) và app máy tính.
  - Trên macOS, app máy tính báo đúng loại phần tử và ô đang focus. Vì vậy test trên Mac mới thấy được việc "ít hỏi hơn": đo bằng test tự động, tổng 13 kịch bản giảm 26 → 16 lần ký.
  - Trên Windows con số này vẫn là 26. Máy Windows cũng chưa cài Visual Studio C++, nên không build được app máy tính.
- **Android:** build trên máy Windows (có JDK, Android SDK, emulator `Pixel_8`/`Pixel_10_Pro`). Cài lên điện thoại Android thật hoặc emulator.
- **iPhone: hiện chưa build được.**
  - App điện thoại cần Flutter 3.47.9 (bản 3.32.8 bị crash khi mở trên iOS 26).
  - Flutter 3.47.9 đòi macOS 14 trở lên, mà Mac đang chạy macOS 12.6.

## 1. Backend trên Mac

```sh
cd backend
createdb xuna_local                      # chỉ lần đầu
export XUNA_DATABASE_URL=postgresql+psycopg://$(whoami)@localhost/xuna_local
export XUNA_FIREBASE_PROJECT_ID=xuna-pet # đăng nhập bằng Firebase của dự án
export XUNA_TEXT_PROVIDER=openai_compatible
export XUNA_TEXT_BASE_URL=...            # model phải gọi được công cụ (tool calling)
export XUNA_TEXT_MODEL=...
export XUNA_TEXT_API_KEY=...
.venv/bin/alembic upgrade head           # phải tới 0019_cu_sessions
.venv/bin/uvicorn xuna_backend.main:app --host 0.0.0.0 --port 8000 --no-access-log
```

- Kiểm: `curl localhost:8000/readyz` trả `{"status":"ready"}`.
- Lấy IP của Mac trong mạng nhà: `ipconfig getifaddr en0`. Nếu tường lửa macOS hỏi, cho phép Python nhận kết nối.
- Để mặc định `XUNA_TEXT_PROVIDER=echo` thì XUNA chỉ nhại lại và **không bao giờ gọi công cụ**, nên không điều khiển được gì.

## 2. App máy tính trên Mac

```sh
cd desktop
fvm flutter run -d macos   # Flutter 3.32.8 theo desktop/.fvmrc; cần Xcode
```

- App kết nối `ws://127.0.0.1:8000/v1/hosts/connect` (mặc định). Backend ở máy khác thì thêm `--dart-define=XUNA_WS_URL=ws://<IP>:8000/v1/hosts/connect`.
- Cấp quyền cho app trong System Settings → Privacy & Security: **Accessibility** (Trợ năng) và **Screen Recording** (Ghi màn hình).
- Ghép máy: tab "Ghép nối" của app máy tính. Trên điện thoại, vào trang Máy tính để xác nhận.
- Nếu build lỗi: ghi lại lỗi và báo lại. Đây là lần build macOS đầu tiên.

## 3. App Android (build trên máy Windows)

1. Đặt file `google-services.json` của dự án Firebase vào `mobile/android/app/` (file này bị git bỏ qua). Thiếu file thì APK vẫn build được nhưng **không đăng nhập được**.
2. Build và cài (PowerShell):

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
cd mobile
& "C:\Users\Thao\fvm\versions\3.32.8\bin\flutter.bat" build apk --flavor dev --debug --dart-define=XUNA_API_BASE_URL=http://<IP-của-Mac>:8000
adb install -r build\app\outputs\flutter-apk\app-dev-debug.apk
```

- Dùng **3.32.8** cho bước này, không dùng `fvm flutter` hay 3.47.9. Thử ngày 2026-11-13: build bằng 3.47.9 hỏng vì Android Gradle Plugin 9 ("new DSL"), và tự thêm `android.newDsl=false`, `android.builtInKotlin=false` vào `android/gradle.properties` (đã khôi phục). Test tự động của app vẫn chạy bằng 3.47.9; hai bản lệch nhau là việc có sẵn, cần quyết riêng.
- Bản `dev` debug cho phép HTTP không mã hoá, nên dùng được `http://<IP-của-Mac>:8000`.
- Emulator trên máy Windows vào được IP của Mac qua mạng nhà. Không dùng `10.0.2.2`, vì địa chỉ đó trỏ về chính máy Windows.

## 4. Trước khi làm checklist

- [ ] Đăng nhập app trên điện thoại bằng cùng tài khoản.
- [ ] Trong app: bật quyền riêng tư "điều khiển màn hình" (Consent U5).
- [ ] Trang Máy tính: thấy máy Mac đã ghép, nhóm quyền `cu`, `ui`, `input` đã bật.
- [ ] Nhờ XUNA "mở Ghi chú trên máy Mac": thấy thẻ duyệt R3 `cu.session_start` liệt kê đủ app và tên miền (§4k), ký, phiên chạy.
- [ ] Ghi lại mọi chỗ khác với checklist và báo lại.

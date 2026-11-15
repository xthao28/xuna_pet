# Dựng môi trường test UDC-17 (Mac + điện thoại Android)

Ngày: 2026-11-13. Dành cho chủ dự án, trước khi làm checklist [UDC-16](UDC-16-device-test-checklist.md) (§4c–§4k).

**Trạng thái (cập nhật kết quả chạy thật trên Mac tối 2026-11-13):**
- **Đã chạy trên Mac (`macOS 12.6 Build 21G115 darwin-x64`, `Xcode 14.2 14C18`):**
  - **Backend (`39e9b05`):** `Python 3.12.8`, `ruff check` + `mypy` sạch, `pytest` PostgreSQL `xuna_test` **811/811 PASS**. DB `xuna_local` đã `alembic upgrade head` từ `0018` lên **`0019 (head)`**. `uvicorn` đang chạy tại `0.0.0.0:8000` (với `.env.gemini` + `.env.groq`), `curl localhost:8000/readyz` trả `{"status":"ready"}`. IP LAN hiện tại của Mac (`en0`): **`192.168.2.11`**.
  - **App máy tính (`26debd4`, Flutter `3.32.8`):** `packages/xuna_xtp` **43/43 PASS**, `desktop/` **89/89 PASS**, analyze sạch. `fvm flutter build macos --debug` thành công ngay không lỗi (`build/macos/Build/Products/Debug/xuna_desktop.app`, 0 file đổi; đính chính: máy Mac này đã từng có thư mục `build/macos` từ `2026-11-06`, đây là lần build đầu của bản UDC-17). App đã mở, tự di trú `host-policy.json` cũ thêm đúng `cu`/`screen`/`ui`/`input`, tự kết nối `ws://127.0.0.1:8000/v1/hosts/connect` và đăng ký **72 công cụ** (có `ui.find`, `cu.session_extend`) vào `host_manifests` cho `Xuans MacBook Pro` (`active`).
  - **Board XUNA (`f385feb`, `xuna_t_display_s3`):** `pio test -e native` **423/423 PASS**, đã sao lưu NVS (`~/xuna_backups/2026-11-13-upload/`) và nạp thành công lên `/dev/cu.usbmodem14201` (`recover=Ok boot=118`, giữ nguyên `PetId`, `persona_restored` và `device_key`; đang chờ chủ kiểm màn hình LCD và 2 nút).
- **Đã kiểm trên máy Windows (2026-11-13):** build APK dev bằng Flutter 3.32.8 thành công, `pubspec.lock` và các file được track không đổi.
- **Chưa chạy:** cài APK có `google-services.json` lên điện thoại Android trỏ vào `http://192.168.2.11:8000` và chạy phiên điều khiển máy tính đầu-cuối với model thật (§4c–§4k).

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

- Kiểm: `curl localhost:8000/readyz` trả `{"status":"ready"}`, và từ trình duyệt điện thoại vào `http://192.168.2.11:8000/readyz` cũng phải trả `{"status":"ready"}`.
- Lấy IP của Mac trong mạng nhà: `ipconfig getifaddr en0` (`192.168.2.11`).
- **Tường lửa macOS (đã gặp thật 2026-11-13):** `Python.app` của Homebrew 3.12 ký `adhoc` nên khi chạy `uvicorn` nền sẽ bị Firewall macOS âm thầm chặn gói tin từ mạng LAN vào cổng `8000` (dù `localhost` vẫn vào được). Mở bằng lệnh:
  ```sh
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/Cellar/python@3.12/3.12.8/Frameworks/Python.framework/Versions/3.12/Resources/Python.app
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/Cellar/python@3.12/3.12.8/Frameworks/Python.framework/Versions/3.12/Resources/Python.app
  ```
- Để mặc định `XUNA_TEXT_PROVIDER=echo` thì XUNA chỉ nhại lại và **không bao giờ gọi công cụ**, nên không điều khiển được gì.

## 2. App máy tính trên Mac

```sh
cd desktop
fvm flutter build macos --debug   # Flutter 3.32.8 theo desktop/.fvmrc; Xcode 14.2 vẫn build được
open build/macos/Build/Products/Debug/xuna_desktop.app
# Hoặc chạy trực tiếp từ CLI: fvm flutter run -d macos
```

- App kết nối `ws://127.0.0.1:8000/v1/hosts/connect` (mặc định). Backend ở máy khác thì dùng `fvm flutter run -d macos --dart-define=XUNA_WS_URL=ws://<IP>:8000/v1/hosts/connect`.
- Cấp quyền cho app: trên macOS 12.6 vào **System Preferences → Security & Privacy → tab Privacy** (trên macOS 13+ là System Settings → Privacy & Security), bật **Accessibility** (Trợ năng) và **Screen Recording** (Ghi màn hình) cho `xuna_desktop.app`.
- **Lưu ý chữ ký ad-hoc:** kiểm tra bằng `codesign -dvv` cho thấy bản debug ký **`Signature=adhoc`** (`TeamIdentifier=not set`). Vì macOS gắn quyền TCC với CDHash của bản ad-hoc, sau mỗi lần build lại có thể mất quyền đã cấp — nếu gặp `needs_permission` dù ô vẫn tích, hãy bỏ chọn/xoá mục `xuna_desktop` cũ bằng nút `-` rồi thêm lại bản `.app` mới.
- Ghép máy: máy `Xuans MacBook Pro` trên Mac này đã ghép sẵn và tự lên `active` (72 công cụ). Nếu ghép máy mới: vào tab "Ghép nối" của app máy tính, rồi trên điện thoại vào trang Máy tính để xác nhận.

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

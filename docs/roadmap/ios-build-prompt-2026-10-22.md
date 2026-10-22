# Prompt: build the iOS app for V1 slice 3 (2026-10-22)

Copy the block below into Claude Code on the stronger Mac (Xcode ≥ 15, the one that built the 2026-10-19 IPA). The old Intel Mac has Xcode 14.2 and cannot build for iOS 26.

```text
Tiếp tục dự án XUNA (repo xuna_pet, nhánh dev, submodule backend/firmware/mobile).
Trả lời mình bằng tiếng Việt. Máy này là máy mạnh, dùng để build iOS.

Trước khi làm: git pull và git submodule update --init; đọc CLAUDE.md, AGENTS.md,
mobile/AGENTS.md, dòng đầu PROCESS.md và docs/roadmap/V1-phone-voice-2026-10-22.md
(mục "Slice 3").

Mục tiêu: cài app XUNA bản mới (mobile 539630c trở lên: micro, giọng nói, quét QR) lên
iPhone 15 của mình (iOS 26) để đo V1 slice 3. Backend chạy trên Mac cũ ở
http://192.168.2.11:8000 (Groq Whisper + Edge TTS + Groq gpt-oss-120b).

Các bước:
1. Kiểm toolchain: fvm dùng Flutter 3.32.8 (mobile/.fvmrc), Xcode ≥ 15, CocoaPods.
   Không nâng Flutter hay package (D14, mobile/AGENTS.md §10).
2. Firebase: mình sẽ chép file GoogleService-Info.plist (project xuna-pet, bundle
   com.example.xunaMobile) vào mobile/ios/Runner/GoogleService-Info.plist. File này
   gitignored, không commit, không in API key ra chat. Kiểm file có mặt và đúng
   PROJECT_ID/BUNDLE_ID trước khi build.
3. Google Sign-In iOS cần URL scheme = REVERSED_CLIENT_ID trong
   ios/Runner/Info.plist (CFBundleURLTypes); hiện chưa có. Hỏi mình chọn:
   (a) thêm vào Info.plist và commit, hoặc (b) thêm cục bộ, không commit.
   Lấy giá trị từ GoogleService-Info.plist, không đoán.
4. cd mobile && fvm flutter pub get (pubspec.lock phải giữ nguyên; nếu đổi thì dừng
   và báo). cd ios && pod install: Podfile.lock sẽ thêm pod record / just_audio /
   audio_session, đó là thay đổi đúng, sẽ commit.
5. Hỏi mình IP LAN hiện tại của Mac cũ (mặc định 192.168.2.11) và nhắc mình chạy
   backend bên đó. Kiểm curl http://<IP>:8000/readyz từ máy này trả {"status":"ready"}.
6. Cắm iPhone, build và cài trực tiếp (tránh xuất IPA: lần archive 19/10 bị thiếu chữ ký
   FirebaseAuthInterop):
   fvm flutter run --release -d <iPhone> --dart-define=XUNA_API_BASE_URL=http://<IP>:8000
   Nếu buộc phải xuất IPA thì kiểm chữ ký sâu (codesign --verify --deep --strict).
7. Hướng dẫn mình thử: cho phép "Mạng cục bộ" và micro khi iOS hỏi; đăng nhập Google;
   bật "Giọng nói" (U3V) và AI chat; bấm mic, nói, bấm lần nữa để gửi. Ghi lại:
   - thời gian cả lượt (từ lúc bấm gửi tới khi nghe tiếng đầu tiên), mục tiêu p50 ≤ 3 s,
     đo ít nhất 5 lượt;
   - tiếng trả lời ra loa ngoài hay loa thoại sau khi ghi âm;
   - micro có hoạt động khi đang nối BLE với board không.

Cách làm việc:
- Không dán key vào chat hay commit. Thư viện mới phải ghim đúng phiên bản và kiểm giấy
  phép; mọi nâng cấp toolchain/dependency phải hỏi mình trước.
- Làm xong tự commit và push: submodule mobile trước (Podfile.lock, Info.plist nếu chọn
  (a)), repo cha sau, kèm cập nhật PROCESS.md, CHANGELOG.md và biên bản V1 (số đo,
  phiên bản Xcode, những gì chưa chạy).
```

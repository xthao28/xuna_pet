# Danh sách việc cần test trên thiết bị thật (cập nhật 2026-11-06)

Dành cho chủ dự án. Tất cả mục dưới đây **đã qua test tự động trên máy dev nhưng chưa từng chạy trên điện thoại/emulator có hỗ trợ**. Đánh dấu `[x]` khi đã thử, ghi kết quả bên cạnh. Báo lại những mục sai để sửa.

## 0. Chuẩn bị

- [ ] **Làm đầu tiên:** chạy migration `0018` trên backend/DB thật rồi **khởi động lại backend** (`alembic upgrade head`). Thiếu bước này thì mọi route `/v1/actions/standing-approvals` và việc kiểm tra duyệt trước sẽ lỗi.

- [ ] Máy Android thật (khuyến nghị) hoặc emulator Pixel có Play Store/launcher Pixel. LDPlayer **không** ghim được widget và không có menu Widgets, nên chỉ dùng để thử phần không liên quan widget.
- [ ] Build bằng Flutter **3.32.8** (không dùng `fvm flutter`, nó đổi `android/local.properties` và `android/gradle.properties`):
  ```powershell
  $env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
  & "C:\Users\Thao\fvm\versions\3.32.8\bin\flutter.bat" build apk --flavor dev --debug
  adb install -r build\app\outputs\flutter-apk\app-dev-debug.apk
  ```
  Bản `play` dùng `--flavor play` (không có Trợ năng và không có `ui.*`).
- [ ] Đã đăng nhập app và backend chạy được (`XUNA_API_BASE_URL` trỏ đúng). Điện thoại đã **đăng ký làm host** ("Đăng ký điện thoại này" trên trang Máy tính của bạn).
- [ ] Nếu màn hình đứng ở splash trên emulator: bản debug đã tắt Impeller, chỉ cần cài lại bản debug mới.

## 1. Widget màn hình chính (Android)

- [ ] Vào sheet Thiết bị → Cấu hình Widget. Thấy nút **"Ghim widget ra màn hình chính"** (thẻ nền lilac, huy hiệu ghim lime).
- [ ] Bấm nút: launcher hiện hộp thoại ghim widget; chấp nhận thì widget xuất hiện. Nếu launcher không hỗ trợ, app báo "không hỗ trợ" (không báo thành công giả).
- [ ] Widget phẳng, không gradient: nền giấy, viền mực, đổ bóng lệch 4dp, các nút Nựng/Pocket/E-Stop có viền mực.
- [ ] Khi chưa đặt ghi chú: widget hiện "Chưa có ghi chú". Khi chưa đặt tiến độ: **ẩn** thanh tiến độ (không còn 88%/100%).
- [ ] Đặt ghi chú rồi lưu: widget cập nhật. Xoá trắng ô ghi chú rồi lưu: widget quay về "Chưa có ghi chú".
- [ ] Kéo thanh tiến độ rồi lưu: thanh hiện đúng %. Máy từng chạy bản cũ: tiến độ cũ bị xoá một lần (cần chọn lại).
- [ ] Các nút Nựng / Pocket / E-Stop trên widget chạy đúng việc.
- [ ] (Chưa thử trên iOS: `XunaWidget.swift`, `XunaIosHostPlugin.swift` chưa từng biên dịch, cần Mac.)

## 2. Cấp trước quyền hệ thống (S16.1)

Trang **Máy tính của bạn**, thẻ "Quyền & kết nối" chỉ hiện sau khi điện thoại đã đăng ký host.

- [ ] Thẻ liệt kê đúng quyền còn thiếu của bản đang cài (bản dev có thêm "Trợ năng", bản play không).
- [ ] Bấm "Cấp trước các quyền cần thiết": hiện lời giải thích quyền đầu tiên → Tiếp tục → mở màn hình hệ thống.
- [ ] Cấp quyền rồi quay về app: app tự chuyển sang quyền kế tiếp (không cần bấm lại).
- [ ] Quay về **mà chưa cấp**: luồng dừng và báo "Chưa cấp: <tên quyền>", không nhắc tiếp.
- [ ] Huỷ ở lời giải thích: luồng kết thúc, không mở cài đặt.
- [ ] Cấp quyền ngoài luồng (tự vào Cài đặt) rồi mở lại app: trạng thái trên trang tự cập nhật.
- [ ] Liên kết thiết bị đồng hành (CompanionDeviceManager) chạy đến cuối rồi tự sang bước kế tiếp. Ghi lại máy/Android nào cho kết quả gì.
- [ ] Khi đã đủ quyền: thẻ chuyển sang "Đã đủ quyền cho bản này", không còn nút.
- [ ] Lời giải thích quyền Trợ năng (bản dev) nói đúng về `ui.observe`/`ui.act` và "Không bao giờ có trong bản Google Play".

## 3. Gói quyền một chạm (S16.2)

Mở một host trong danh sách để thấy mục "GÓI QUYỀN MỘT CHẠM".

- [ ] **Nghe nhạc:** bấm → hộp xác nhận liệt kê "Media: tối đa R1, không hết hạn" + câu "R2 trở lên vẫn hỏi duyệt" → Áp dụng → thông báo đã lưu, nhóm Media bật.
- [ ] Bấm lại gói đã bật: báo "Gói này đã được bật sẵn", không gửi gì.
- [ ] **Trợ lý cơ bản:** Media R1, Ứng dụng R2, Liên kết R2, hết hạn sau 1 ngày. Kiểm tra trên backend/sheet rằng ngày hết hạn đúng.
- [ ] **Điều khiển giao diện (Dev):** chỉ hiện trên **điện thoại này**, bản dev. Không hiện trên bản play, không hiện trên máy khác. Áp dụng → nhóm `ui` ở mức R3, hết hạn 1 giờ.
- [ ] **Quan trọng:** backend nhận grant `ui` R3 mà không lỗi (app trước đây chặn mọi R3 nên đường này chưa từng chạy thật). Nếu backend từ chối, ghi lại mã lỗi.
- [ ] Sau 1 giờ gói giao diện hết hạn và tool `ui.*` biến khỏi danh mục của model.
- [ ] "Tạm khoá tất cả" vẫn chặn mọi tool kể cả khi đã áp gói.

## 4. Điều khiển giao diện: `ui.observe` / `ui.act` / `ui.wait_for` (bản dev)

Điều kiện: bản dev, Trợ năng đã bật, gói "Điều khiển giao diện" đã áp, host phone **online** và danh sách tool (manifest) đã được app gửi lên backend (kiểm tra thấy `ui.observe` trong catalog của chat; nếu không thấy, ghi lại).

Hỏi XUNA trong chat để model gọi tool, ví dụ "mở app Cài đặt ghi chú rồi đọc màn hình". Mỗi thao tác R3 sẽ hỏi duyệt.

**Đọc màn hình**
- [ ] `ui.observe` trả snapshot có `snapshotId` và danh sách phần tử có `ref`, `text`, `bounds`, `flags`.
- [ ] Ô mật khẩu / OTP hiện `[REDACTED]` và **không có `ref`**.
- [ ] Trong app thuộc danh sách chặn cứng (Cài đặt hệ thống, ngân hàng, authenticator, trình quản lý mật khẩu) và trong chính app XUNA: trả `package_denied`, không đọc nội dung.

**Thao tác**
- [ ] Câu duyệt hiển thị đúng nội dung: "Chạm vào 'Gửi'" hoặc "Nhập 'abc' vào 'Tìm kiếm'" (không phải "e3").
- [ ] `activate` một nút thường: màn hình đổi, kết quả `ok` + `effect: changed` + snapshot mới.
- [ ] Dùng lại `snapshotId` cũ sau một thao tác: bị từ chối `target_stale`.
- [ ] Chuyển sang app khác rồi dùng `ref` cũ: `package_changed`.
- [ ] Gửi nhãn sai cho một `ref`: `target_mismatch`, **không** có gì bị bấm.
- [ ] Nút bị vô hiệu: bị từ chối `action_not_supported`.
- [ ] Thao tác được hệ thống nhận nhưng màn hình không đổi: `failed` + `no_visible_change` kèm màn hình mới.
- [ ] Màn hình tải qua mạng (gửi tin, tải trang): có bị báo `no_visible_change` oan không? Cửa sổ chờ hiện ~1,35 s; nếu hay sai, ghi lại app nào để chỉnh.
- [ ] `set_text` vào ô thường: chữ vào đúng ô; đọc lại giá trị khớp. Ô nhạy cảm bị từ chối `secure_content`.
- [ ] `scroll` forward/backward trên danh sách; `swipe` up/down/left/right trong vùng phần tử.
- [ ] Back/Home/Recents qua `ui.act` kiểu `global`.
- [ ] `ui.swipe_drag` thiếu toạ độ: trả `invalid_args` (không tự vuốt `300/600/300/250`).

**Chờ**
- [ ] `ui.wait_for` với chữ sẽ xuất hiện: trả `ok` + `matched`. Với chữ không bao giờ có: trả `timeout` sau ≤ 15 s, không treo giao diện.

**Độ ổn định**
- [ ] Trong lúc `ui.act` chạy, giao diện app XUNA không bị đứng (các lệnh ui giờ chạy trên luồng nền).
- [ ] Hai lệnh ui gửi liên tiếp nhanh được xử lý lần lượt, không chồng.
- [ ] Kích thước kết quả: màn hình nhiều phần tử (danh sách dài, trang web) vẫn về tới model, không bị lỗi/cắt (mặc định 60 phần tử, tối đa 150; giới hạn khung host 128 KB).

## 4b. Duyệt trước (S16.3, ADR-0014 D1)

Điều kiện: đã chạy migration `0018` (mục 0), điện thoại đã đăng ký host, và host công bố `app.launch` với danh sách ứng dụng cho phép dạng `enum`.

> **Phạm vi thật hiện nay:** chỉ **chính điện thoại Android** làm được mục này (manifest Android đưa danh sách ứng dụng cho phép thành `enum`). Agent desktop công bố `app.launch` với `id` là chuỗi có `pattern` chứ không phải `enum`, nên **PC không đủ điều kiện duyệt trước**. `url.open`, `media.play_search` và mọi tool `ui.*` cũng không đủ điều kiện. Vì vậy đợt này giảm số lần hỏi rất ít; số lần hỏi thật phải đếm ở mục 5.

- [ ] Nhờ XUNA mở một ứng dụng trong danh sách cho phép **trên điện thoại này**. Hộp duyệt R2 hiện thêm nút **"Luôn cho phép việc này (7 ngày)"** (và dòng giải thích, và dòng "Sẽ ký cho đúng: app.launch (app_id=…)").
- [ ] Việc dùng **chữ tự do** (`url.open`, `media.play_search`) **không** hiện nút này. Việc R3 và việc đọc/chạm màn hình cũng không.
- [ ] Bấm nút: việc chạy lần này, rồi hiện "Đã nhớ…". Nếu chỉ chạy được lần này thì hiện "đã chạy một lần nhưng chưa lưu được" (thử bằng cách tắt mạng ngay sau khi duyệt).
- [ ] Hỏi lại **đúng việc đó**: chạy luôn, **không** hiện hộp duyệt.
- [ ] Hỏi **ứng dụng khác**: vẫn hiện hộp duyệt.
- [ ] Trang **Máy tính của bạn → DUYỆT TRƯỚC** liệt kê mục vừa tạo: tên việc, ngày hết hạn, số lần đã dùng tăng lên sau mỗi lần dùng.
- [ ] **Thu hồi** một mục: biến khỏi danh sách; hỏi lại việc đó thì lại hiện hộp duyệt.
- [ ] Bấm **Dừng** (E-Stop) hoặc **Tạm khoá tất cả**: việc đã duyệt trước **không** chạy nữa; bật lại quyền thì chạy lại.
- [ ] Gỡ ứng dụng khỏi danh sách cho phép: mục duyệt trước đó không còn khớp (hỏi lại thì bị từ chối hoặc hỏi duyệt).
- [ ] Chữ ký do khoá điện thoại này tạo: kiểm tra backend nhận (không lỗi `signature_invalid`). Nếu lỗi, ghi lại mã lỗi và máy.
- [ ] Máy iPhone/iOS-host: chưa thử ở bất kỳ mức nào.

## 5. Số lần bị hỏi (để quyết định D1/D2)

- [ ] Làm một việc 5 bước (ví dụ: mở app → tìm kiếm → chạm kết quả) và **đếm số lần hiện hộp duyệt**. Dự kiến khoảng 6 lần (observe R2 + mỗi `act` R3). Con số thực tế quyết định có cần phiên điều khiển (UDC-16 phần D) hay không.

## 6. Việc còn lại cần ghi nhận khi test

- Tool bị chặn bởi quyền hệ thống nhưng chưa có chip "Mở Quyền & kết nối" trong khung chat (chưa làm).
- Chưa có trang hub riêng; thẻ nằm trên trang hosts.
- S16.3 (duyệt trước R2) và S16.4 (phiên điều khiển) chưa bắt đầu; chờ bản sửa ADR-0012.

## 7. Báo lại

Với mỗi mục sai, gửi: model máy + phiên bản Android, bản `dev` hay `play`, bước đã làm, kết quả thấy, và (nếu có) `adb logcat -d | findstr /i "xuna flutter"` quanh thời điểm lỗi. Nếu một tool trả lỗi, chép nguyên `errorCode`.

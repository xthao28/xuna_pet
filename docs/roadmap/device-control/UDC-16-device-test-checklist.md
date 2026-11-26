# Danh sách việc cần test trên thiết bị thật (cập nhật 2026-11-13)

Dành cho chủ dự án. Tất cả mục dưới đây **đã qua test tự động trên máy dev nhưng chưa từng chạy trên điện thoại/emulator có hỗ trợ**. Đánh dấu `[x]` khi đã thử, ghi kết quả bên cạnh. Báo lại những mục sai để sửa.

## 0. Chuẩn bị

Điều khiển máy tính (§4c–§4k): dựng môi trường theo [UDC-17-test-setup.md](UDC-17-test-setup.md) (Mac chạy backend và app máy tính, điện thoại Android). iPhone hiện chưa build được (macOS 12.6 không chạy được Flutter 3.47.9).

- [x] **Làm đầu tiên:** chạy `alembic upgrade head` trên backend/DB thật (phải tới `0019_cu_sessions`; `0018` là duyệt trước, `0019` là kho phiên điều khiển) rồi **khởi động lại backend**. Thiếu `0018` thì các route `/v1/actions/standing-approvals` lỗi; thiếu `0019` thì phiên điều khiển máy tính lỗi. *(Đã chạy 2026-11-13 trên Mac: DB `xuna_local` lên `0019 (head)`, `uvicorn` chạy tại `0.0.0.0:8000` `/readyz=ready`, IP LAN `192.168.2.11`, host `Xuans MacBook Pro` lên `active` với 72 công cụ).*

- [ ] Máy Android thật (khuyến nghị) hoặc emulator Pixel có Play Store/launcher Pixel. LDPlayer **không** ghim được widget và không có menu Widgets, nên chỉ dùng để thử phần không liên quan widget.
- [ ] Build bằng Flutter **3.32.8**, không dùng `fvm flutter` hay 3.47.9. Kiểm lại 2026-11-13: 3.47.9 build hỏng (Android Gradle Plugin 9 "new DSL") và tự sửa `android/gradle.properties`. Thêm `--dart-define=XUNA_API_BASE_URL=http://<IP backend>:8000` và đặt `android/app/google-services.json`, nếu không sẽ không đăng nhập được:
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

## 4c. Điều khiển máy tính (sửa 2026-11-12)

- [ ] Trong một phiên điều khiển đã duyệt, nhờ XUNA bấm `Enter` (ví dụ gửi tin nhắn hoặc tìm kiếm): điện thoại **phải** hiện hộp ký duyệt R3 mỗi lần. `Space` cũng vậy. `Tab`, `Esc`, mũi tên **không** hỏi.
- [ ] Trang chi tiết máy tính: bật công tắc **input** hoặc **cu** lần đầu → quyền có hạn **30 ngày** (không phải "không giới hạn"). Gói **"Điều khiển máy tính"** cũng ghi "hết hạn sau 30 ngày" trong hộp xác nhận. Đổi sang "không giới hạn" bằng nút thời hạn vẫn được và được giữ khi tắt/bật lại.
- [ ] Chưa bật Consent điều khiển màn hình (U5) rồi nhờ XUNA thao tác trong app máy tính: XUNA nói rõ cần bật quyền, không im lặng hay thử lại.
- [ ] Nhờ XUNA làm một việc dài (trên 20 bước hoặc trên 10 phút): phiên không bị cắt ở mốc cũ, và tự dừng ở 40 bước / 20 phút.
- [ ] macOS: mở phiên với một app có tên hiển thị tiếng Việt (ví dụ Ghi chú): XUNA đọc được cửa sổ, không báo `target_outside_allowlist`.
- [x] Máy tính có `host-policy.json` cũ: sau khi cập nhật, chỉ `cu`/`screen`/`ui`/`input` được thêm; family nào trước đó không có trong file vẫn bị chặn. *(Đã kiểm trên Mac 2026-11-13: `~/Library/Application Support/XUNA/host-policy.json` từ 2026-11-03 vốn có `media`/`app`/`url`/`workflow`, khi mở bản `26debd4` chỉ thêm đúng `cu`/`screen`/`ui`/`input`).*

## 4d. Máy tính tự quyết mức rủi ro (UDC-17 S17.1, thêm 2026-11-12)

Cần máy tính chạy bản desktop mới và backend mới.

- [ ] Trong phiên điều khiển, nhờ XUNA bấm một nút có chữ **Gửi** / **Xoá** / **Thanh toán**: điện thoại hỏi ký R3 và hộp duyệt ghi **đúng chữ trên nút** (không phải tên XUNA tự đặt).
- [ ] Sau khi ký, cú bấm đó **chạy thật** (không báo `approval_required` hay "cần duyệt" lần nữa).
- [ ] Bấm một nút thường (Mở, Tiếp, một mục trong danh sách): không hỏi gì.
- [ ] Nhờ XUNA gõ vào ô mật khẩu: XUNA nói không được phép; điện thoại **không** hiện hộp duyệt.
- [ ] Nhờ XUNA bấm một phần tử sau khi màn hình đã đổi (ví dụ đóng hộp thoại rồi bấm nút cũ): XUNA được báo phần tử đã cũ và đọc lại màn hình, điện thoại không hỏi.
- [ ] Ghi lại: từ lúc XUNA quyết bấm tới lúc điện thoại hiện hộp duyệt có chậm thấy rõ không (preflight thêm một vòng hỏi máy tính, tối đa 2 giây).
- [ ] Máy tính còn chạy bản desktop **cũ** với backend mới: điều khiển vẫn chạy như trước (backend tự nhận ra máy cũ).

## 4e. Gõ nháp và bước chốt (UDC-17 S17.2, thêm 2026-11-12)

- [ ] Nhờ XUNA soạn một tin nhắn trong app nhắn tin: chữ được gõ vào ô soạn **không** hỏi ký.
- [ ] Khi XUNA bấm **Gửi** (hoặc `Enter`): điện thoại hỏi ký, và hộp duyệt có dòng **"Đã gõ: '…'"** đúng nội dung vừa soạn.
- [ ] Sau khi gửi, soạn tin thứ hai rồi gửi: hộp duyệt chỉ có nội dung tin thứ hai.
- [ ] Nhờ XUNA gõ vào ô mật khẩu: bị từ chối, không hỏi gì.
- [ ] Nhờ XUNA dán một đoạn rất dài (trên 2.000 ký tự): phải ký.
- [ ] Soạn tin xong, nhờ XUNA bấm nút Gửi **chỉ có icon** (máy bay giấy, không có chữ): phải ký, hộp duyệt có "Đã gõ: '…'".
- [ ] Nhờ XUNA soạn tin có **nhiều dòng**: phải ký ngay lúc gõ (xuống dòng có thể gửi tin).
- [ ] Trên Facebook/app tiếng Việt, nút **Đăng**: phải ký; nút **Đăng nhập** không bị coi là bước chốt ở backend.
- [ ] `Enter` trong ô tìm kiếm **vẫn hỏi ký** ở bản này, cả trên Mac lẫn Windows (máy chưa đọc được focus đủ chắc). Nếu không hỏi thì là lỗi, báo lại ngay.
- [ ] Windows: nhờ XUNA gõ thẳng vào nội dung một trang web hoặc tài liệu Word: phải ký.

## 4f. Thẻ phiên trực tiếp, dừng một phiên, mở rộng phạm vi, nút bật quyền (UDC-17 S17.3, thêm 2026-11-13)

Cần backend, desktop và app điện thoại bản mới cùng lúc.

- [ ] Bắt đầu một phiên điều khiển: trong khung chat hiện **thẻ phiên** gồm mục tiêu, tên máy ("trên …"), "Bước x/y", "còn N phút", "Phạm vi: …" (app và tên miền).
- [ ] Trong lúc XUNA soạn nháp, thẻ có mục **"Đã gõ:"** hiện **đủ** chữ đã gõ (không bị cắt ở 150 ký tự như hộp duyệt). Sau khi bước gửi chạy xong thì mục này trống.
- [ ] Thoát app rồi mở lại giữa phiên: thẻ vẫn còn và số bước đúng. Mở lại sau khi phiên đã hết giờ: thẻ **biến mất**.
- [ ] Bấm **Dừng phiên**: thẻ biến mất, có thông báo "Đã dừng phiên điều khiển."; trên máy tính phiên cũng kết thúc. Nhờ XUNA làm tiếp thì thao tác kế tiếp lại hỏi duyệt. Các quyền trên trang Máy tính **không** bị khoá (khác Dừng khẩn cấp).
- [ ] Tắt mạng máy tính rồi bấm **Dừng phiên**: báo "máy tính chưa xác nhận", thẻ vẫn biến mất. Bật mạng lại rồi nhờ XUNA làm tiếp: mọi thao tác đều hỏi duyệt lại (phía máy tính, phiên cũ tự hết khi hết giờ).
- [ ] Bấm **Dừng khẩn cấp** trên thẻ: hành vi như nút Dừng khẩn cấp cũ (dừng mọi việc, khoá quyền R2+).
- [ ] Giữa phiên chỉ khai app Ghi chú, nhờ XUNA mở thêm Lịch: điện thoại hỏi ký **"Thêm vào phiên điều khiển: calendar …"** (đủ tên mọi app/tên miền thêm vào), không kết thúc phiên. Sau khi ký, thẻ hiện phạm vi mới, số bước và thời gian **không** được cộng thêm.
- [ ] Nhờ XUNA thêm app bị cấm (Terminal, PowerShell, trình quản lý mật khẩu): bị từ chối, không hỏi ký.
- [ ] Nhờ XUNA thêm một tên miền rất dài (trên 60 ký tự): XUNA **không** hỏi ký mà nói phải thêm ít/ngắn hơn. Hộp duyệt mở rộng không bao giờ có tên miền bị cắt hay dấu "…".
- [ ] Tắt quyền "điều khiển màn hình" (Consent U5) rồi nhờ XUNA điều khiển: chip lỗi trong chat có nút **"Bật quyền điều khiển màn hình"**, bấm vào mở đúng trang quyền riêng tư.
- [ ] Hạ quyền nhóm `input` của máy xuống R2 rồi nhờ XUNA bấm nút Gửi: chip lỗi có nút **"Mở quyền của máy"**, bấm vào mở trang Máy tính **và tự mở đúng máy đó** (phần này chưa có test tự động).
- [ ] Thiếu quyền Trợ năng trên máy tính: chip ghi "Cần bật quyền trên máy tính" (chỉ là chữ, không có nút).
- [ ] Lối tắt **Dừng khẩn cấp** trên màn hình chính (nhấn giữ icon app): khi có mạng thì báo "Đã Dừng khẩn cấp…" và các quyền bị khoá thật; khi mất mạng thì báo **chưa** dừng được.

## 4g. UDC-17 S17.6 (dọn nợ)

- [ ] Mở phiên, để app ở màn hình chính: phiên chạy qua 1 phút (heartbeat).
- [ ] Đưa app xuống nền hơn 15 giây: phiên dừng, máy tính dừng theo, thẻ biến mất khi mở lại app.
- [ ] Khởi động lại backend giữa phiên: thẻ vẫn còn. Gõ nháp rồi bấm Gửi: thẻ chốt hiện "không hiện lại được nội dung".
- [ ] Bấm nút/liên kết "Quên mật khẩu": chạy được. Gõ vào ô mật khẩu: vẫn bị chặn.
- [ ] `url.open` tới một tên miền trỏ về IP LAN/127.0.0.1: bị từ chối.
- [ ] (Mac) Mở phiên với Lịch; app khác cùng tên hiển thị bị từ chối.

## 4h. Tìm phần tử và phần thay đổi (UDC-17 S17.4, thêm 2026-11-13)

- [ ] Trong phiên, nhờ XUNA "bấm nút X" trong một app nhiều nút: log backend cho thấy nó gọi `ui.find` thay vì đọc cả cây, và bấm đúng nút.
- [ ] Có hai nút cùng tên: XUNA hỏi lại hoặc chọn theo ngữ cảnh, không tự bấm nút đầu tiên.
- [ ] Sau một cú bấm mở hộp thoại: XUNA dùng `ref` trong `changes.added` để bấm tiếp, không đọc lại cả cây.
- [ ] Sau một thao tác làm danh sách xô lệch (thêm một dòng lên đầu), XUNA vẫn gõ vào đúng ô đã chọn trước đó. Nếu là nút không tên, nó đọc lại cây (`stale_ref`) chứ không bấm nhầm.
- [ ] Bấm một nút mở app ngoài phạm vi phiên: kết quả không chứa tên phần tử hay tiêu đề hộp thoại của app đó.
- [ ] (Mac, khi có phần native) Nút không tên vẫn giữ được `ref` sau thao tác.

## 4i. Gợi ý duyệt trước (UDC-17 S17.5, thêm 2026-11-13)

- [ ] Nhờ XUNA làm cùng một việc R2 có tham số cố định (ví dụ mở cùng một app) và đồng ý 3 lần: lần thứ 4 thẻ duyệt hiện "đã được duyệt 3 lần…" và nút "Luôn cho phép" nổi lên.
- [ ] Đổi tham số (app khác): không có câu gợi ý.
- [ ] Bấm "Luôn cho phép": điện thoại ký, lần sau việc đó chạy không hỏi; mục Duyệt trước trên trang Máy tính có mục mới.

## 4j. Mẫu chạy lại (UDC-17 S17.5, thêm 2026-11-13; backend phải lên trước app)

- [ ] Nhờ XUNA làm xong một việc trên máy tính: khi XUNA báo xong, khung chat hiện thẻ "Lưu thành mẫu" với mục tiêu điền sẵn. Sửa tên, bấm Lưu: "Mẫu đã lưu (1)" xuất hiện.
- [ ] Bấm Dừng phiên giữa chừng: không có thẻ lưu.
- [ ] Bấm "Chạy lại": khung chat hiện mục tiêu, thẻ duyệt ghi "Chạy lại mẫu '…':" và vẫn phải ký. Ký xong, phiên chạy với đúng app và tên miền của mẫu. Thường không có `template_mismatch` trong log, vì backend đã báo trước phạm vi cho XUNA. Nếu có, ghi lại: XUNA đã không theo dòng hướng dẫn.
- [ ] Trong lúc phiên chạy, nút "Chạy lại" bị tắt.
- [ ] "Xoá" hỏi xác nhận; huỷ thì mẫu còn, xác nhận thì mất.
- [ ] Đăng xuất rồi đăng nhập tài khoản khác: không thấy mẫu của tài khoản trước.

## 4k. Thẻ duyệt mở phiên hiện đủ phạm vi (UDC-17 S17.5 bổ sung, thêm 2026-11-13; cần backend và app bản mới)

- [ ] Nhờ XUNA mở phiên với hơn 4 app và vài tên miền: thẻ duyệt `cu.session_start` liệt kê **mọi** app sau chữ "app" và **mọi** tên miền sau chữ "tên miền", cộng số bước/phút và tên máy. Không có dấu "…" ở phần app/tên miền. Phiên không có tên miền thì thẻ ghi "tên miền không có".
- [ ] Trên điện thoại màn hẹp nhất có (và khi tăng cỡ chữ hệ thống): thẻ dài khoảng 240 ký tự hiện **hết**, không bị cắt sau 4 dòng như trước (cả thẻ `cu.session_extend`).
- [ ] Trên điện thoại nhỏ nhất có, khi bàn phím **đang mở** và khi cỡ chữ hệ thống lớn: vùng dưới khung chat (thẻ phiên, thẻ duyệt, thanh dừng) **cuộn được**; kéo xuống thấy đủ chữ của thẻ và nút Đồng ý/Từ chối, không có vạch vàng-đen báo tràn. Ô soạn tin vẫn nằm dưới cùng (UDC-17 §16).
- [ ] Khi có thẻ duyệt, hoặc khi màn hình thấp (bàn phím mở), phần tiêu đề và hình XUNA ở đầu khung chat **ẩn đi**; nút quay lại và menu vẫn còn. Duyệt xong thì hiện lại.
- [ ] Khi đủ chỗ và không có thẻ duyệt, khung chat trông như trước: không có khoảng trống lạ giữa tin nhắn và ô soạn tin. (Khi gõ chat, bàn phím mở làm tab thấp, nên tiêu đề và hình XUNA ẩn; đây là hành vi mới.)
- [ ] Phiên đã mở rộng tới nhiều app/tên miền rồi XUNA báo xong: thẻ mời lưu **không** có ô nhập hay nút Lưu, chỉ có câu giải thích "quá dài để hiện đủ trên một thẻ duyệt…" và nút Bỏ qua. Phiên phạm vi nhỏ thì vẫn lưu được như trước.
- [ ] Nhờ XUNA mở phiên với rất nhiều app/tên miền dài: XUNA **không** hỏi ký; log có `start_scope_too_long`. XUNA thử lại với ít mục hơn rồi thêm phần còn lại bằng `cu.session_extend`, hoặc nói rõ lý do.
- [ ] Chạy lại một mẫu có phạm vi rất lớn (ví dụ mẫu lưu sau vài lần mở rộng): không hỏi ký; XUNA nói phạm vi của mẫu không vừa một thẻ duyệt và **không** thử lại vòng vòng (`templatePinned`).
- [ ] Chạy lại mẫu bình thường: thẻ vẫn có "Chạy lại mẫu '…':" ở đầu khi còn chỗ. Khi thẻ đã gần đủ 240 ký tự thì không có tiền tố, nhưng phạm vi vẫn đủ.

## 4l. Nhóm quyền "Dòng lệnh" (`exec`, Wave 3 ADR-0018, thêm 2026-11-25; cần backend, desktop và app bản mới)

- [ ] Trang chi tiết máy tính (macOS/Windows) có thêm công tắc **"Dòng lệnh"** kèm mô tả tiếng Việt; máy Android/iOS **không** có công tắc này. Danh sách quyền mở ra không báo lỗi (trước đây nhóm lạ làm app ném `FormatException`).
- [ ] Trang chi tiết máy tính cũng có công tắc **"Tệp tin"** (`files`, cho `fs.*`). Bật lên chỉ cấp tối đa **R2**: XUNA đọc/sửa tệp trong thư mục dự án (`workspaceRoots`) được; ghi ra ngoài thư mục dự án hoặc vào tệp ẩn ở thư mục nhà bị từ chối (`risk_above_grant`), không hiện thẻ duyệt.
- [ ] Bật công tắc: nhóm `exec` được cấp mức **R3 trong 30 ngày** (giống "Điều khiển máy tính"). Tắt rồi bật lại vẫn giữ đúng mức; chọn thời hạn khác vẫn được.
- [ ] Khi trên máy tính **chưa** bật "Dòng lệnh & tệp (exec.*)" trong tab Chính sách: nhờ XUNA chạy một lệnh kiểm thử → XUNA báo không chạy được (`shell_not_enabled`), **không** hiện thẻ duyệt.
- [ ] Bật trên máy tính rồi nhờ chạy lệnh có xóa tệp hoặc tải mạng: thẻ duyệt hiện **đúng câu lệnh và thư mục** (dài thì có "…"), là **R3** và cần ký trên điện thoại kể cả khi gói tin cậy là Tự động.
- [ ] Đổi gói tin cậy (Nghiêm/Chuẩn/Tự động) trên điện thoại sau khi đã bật "Dòng lệnh & tệp" ở máy tính: công tắc trên máy tính **vẫn bật** (điện thoại không thể bật/tắt nó từ xa).

## 4m. App desktop Windows thật (Wave 3, thêm 2026-11-26; bản Debug build trên máy Windows của chủ dự án)

Đã chạy live 2026-11-26 với backend thật + điện thoại giả lập (xem PROCESS.md). Còn lại phần cần người và điện thoại thật:

- [ ] Máy Windows **mới cài** (chưa có `%APPDATA%\XUNA`): app hiện "Cấu hình lỗi", mọi lệnh bị từ chối (`policy_invalid`) cho tới khi bấm **"Khôi phục mặc định"** ở tab Chính sách. Đây là đúng thiết kế, nhưng ghi lại nếu thấy khó hiểu.
- [ ] Sau "Khôi phục mặc định" + bật **"Dòng lệnh & tệp (exec.*)"**: cả `exec.*` lẫn `fs.*` (đọc/sửa tệp) đều chạy được (sửa 2026-11-26: công tắc bật luôn nhóm `files`). Tắt công tắc: cả hai bị chặn lại. Nếu `fs.*` vẫn báo `policy_blocked` khi công tắc đang bật thì là lỗi.
- [ ] Mọi lệnh ghi tệp đều cần ký trên điện thoại (`outside_workspace`) khi chưa có thư mục dự án (`workspaceRoots`); giao diện chưa có chỗ đặt thư mục này (lỗi đã biết).
- [ ] Quét QR ghép nối bằng **iPhone thật** và bấm "Khớp": mã 6 số trên điện thoại trùng với máy tính.
- [ ] Bấm `Ctrl+Alt+Shift+X` bằng tay khi XUNA đang chạy một lệnh dài: lệnh dừng ngay, điện thoại báo máy tính đã bị tạm dừng.
- [ ] Nhờ XUNA chạy `echo xin chào` trên Windows: hiện tại chữ có dấu bị lỗi font (`xin ch�o`); script `node`/`python` in tiếng Việt thì vẫn đúng.
- [ ] Thẻ duyệt R3 cho một lệnh xóa tệp trên Windows hiện trên **iPhone thật**, ký xong lệnh mới chạy.

## 4n. Kiểm tra tệp đầu ra của lệnh (`expectFiles`, kế hoạch nâng cấp P1.1, thêm 2026-11-26; cần backend + desktop bản mới, Windows và Mac)

Đã có unit test (desktop + `xuna_xtp` + backend), **chưa chạy live**:

- [ ] Nhờ XUNA "build và tạo tệp X" bằng một lệnh chạy xong (exit 0) nhưng **không** tạo tệp: XUNA phải báo **chưa xong** (`expected_output_missing`), không được báo thành công.
- [ ] Lệnh tạo đúng tệp: XUNA báo xong, kèm kích thước/sha256 của tệp; sha256 khớp với `Get-FileHash` (Windows) / `shasum -a 256` (Mac).
- [ ] Lệnh chạy lâu (XUNA chờ nền rồi mới thức): khi lệnh xong mà thiếu tệp, lần đọc kết quả sau đó vẫn báo `expected_output_missing`.
- [ ] Thẻ duyệt R3 của lệnh có `expectFiles` ghi thêm "kiểm tra N tệp đầu ra".
- [ ] Chạy lại 3 mục trên trên **Mac** (code dùng chung, chưa chạy trên Mac).

## 4o. Tự khai báo toolchain & thẻ "Sửa 1 chạm" (`toolchains` + `remediation`, kế hoạch nâng cấp P1.2, thêm 2026-11-26; cần backend + desktop + app điện thoại bản mới)

Đã qua unit/widget/pytest trên Windows, **chưa chạy live trên máy + điện thoại thật và chưa chạy trên Mac**:

- [ ] **Khai báo toolchain live (`xuna/resources.toolchains`):** mở app desktop thật kết nối backend → kiểm tra host tự dò và gửi danh sách công cụ hiện có (`id` + `version`, **không** có đường dẫn hay nội dung nhạy cảm); công cụ chưa cài hoặc stub `WindowsApps` (`AppExecutionAlias`) không xuất hiện trong danh sách.
- [ ] **Nút "Sửa 1 chạm" trên chat mobile:** nhờ XUNA chạy một công cụ/IDE thuộc danh sách nhưng **chưa cài** trên máy tính (hoặc gỡ khỏi `PATH` tạm thời) → bong bóng trả lời trên điện thoại hiện nút **"Sửa 1 chạm"** (không hiện khi lệnh thành công `ok`).
- [ ] **`HomeRemediationSheet` chỉ hiển thị & sao chép (1-tap copy, không tự chạy):** bấm **"Sửa 1 chạm"** → mở sheet hiển thị tên máy đích, loại gợi ý (`install`/`config`/`manual`), mô tả, khung lệnh monospace (nếu có) và dòng lưu ý chỉ hiển thị/sao chép; bấm **"Sao chép lệnh"** → hiện thông báo `"Đã sao chép lệnh."`, dán ra ngoài thấy khớp nguyên văn lệnh, và **tuyệt đối không có lệnh nào tự chạy trên máy tính**. Nếu gợi ý không có `command` thì nút sao chép không hiện.
- [ ] **Tự làm mới toolchain sau khi cài / lỗi thiếu công cụ:** sau khi cài công cụ thiếu (hoặc chạy lệnh cài gói qua `exec.run`), host tự dò lại danh sách toolchain mà không cần khởi động lại app desktop.
- [ ] **Kiểm chứng trên Mac & iPhone/Android thật:** chạy lại 4 mục trên với **desktop Mac** (nhánh dò binary & gợi ý `brew` trên macOS chưa từng chạy thật) và **điện thoại thật** (kiểm tra hiển thị & clipboard trên iOS/Android).

## 4p. Nhật ký hoàn tác cục bộ cho `fs.*` (`W4-M1` / U1, `ADR-0019`, thêm 2026-11-26; cần app desktop bản mới)

Đã qua unit test trên Windows (gồm khóa tệp Win32 `FILE_SHARE_READ` thật và thử đột biến), **chưa chạy live end-to-end và chưa chạy trên Mac**:

- [ ] **Hoàn tác sửa/tạo tệp trong workspace:** nhờ XUNA dùng `fs.write_file` hoặc `fs.patch_file` sửa một tệp trong `workspaceRoots`, sau đó nói *"hoàn tác giúp mình"* (`action.undo`) → tệp trở về đúng nội dung/SHA-256 trước đó (hoặc bị xóa nếu mới tạo), toast chỉ hiện `"XUNA: đã hoàn tác thay đổi tệp"`, log/audit không chứa đường dẫn hay nội dung tệp (§3.6).
- [ ] **Bền vững sau khởi động lại app desktop:** để XUNA sửa tệp → tắt và mở lại XUNA Desktop Agent (trong vòng 30 phút TTL) → gọi `action.undo` vẫn khôi phục đúng bản trước đó từ `%LOCALAPPDATA%\XUNA\undo\` (Windows) / `~/Library/Application Support/XUNA/undo/` (Mac).
- [ ] **Chặn ghi đè khi chủ đã tự sửa tay (M1-2 fail-closed):** để XUNA sửa tệp → chủ mở editor sửa thêm nội dung → gọi `action.undo` → XUNA phải từ chối (`undo_conflict_modified_externally`) và **giữ nguyên** nội dung chủ vừa sửa tay.
- [ ] **Kiểm chứng trên Mac:** chạy lại 3 mục trên trên macOS (xác minh quyền thư mục `0700`, giữ bit thực thi `chmod`, và `rename(2)`).

## 4q. Xem trước giới hạn kích thước trên thẻ duyệt R3 (`W4-M2` / U2, `ADR-0019` §2, thêm 2026-11-26; cần backend + desktop + app điện thoại bản mới)

Đã qua unit/widget/pytest trên Windows (`xuna_xtp` `282`, `desktop` `433`, `mobile` `743`, `backend` `1611`, `diff -r` `0`), **chưa chạy live trên máy + điện thoại thật và chưa chạy trên Mac**:

- [ ] **Xem trước diff cho `fs.patch_file` / `fs.write_file`:** ở chế độ Standard (hoặc ghi ngoài workspace), nhờ XUNA sửa/tạo một tệp văn bản → thẻ duyệt trên điện thoại hiện khung **"XEM TRƯỚC THAY ĐỔI"** ngay phía trên nút **Đồng ý / Từ chối**, có dòng `-`/`+` đúng thay đổi, token bí mật trong tệp hiện `[REDACTED]`; nếu thay đổi vượt 40 dòng hoặc 2048 byte thì có thẻ **"Đã rút gọn"** và kết thúc bằng `"…"`.
- [ ] **Xem trước danh sách tệp cho lệnh xóa (`del`/`rm` trong workspace):** nhờ XUNA xóa `logs\*.log` (hoặc `rm logs/*.log`) trong thư mục dự án → thẻ duyệt R3 hiện khung **"TỆP SẼ BỊ TÁC ĐỘNG"** kèm số tổng tệp (`@count tệp`) và tối đa 20 đường dẫn tương đối (có `"…"` khi > 20); khi chưa bấm Đồng ý thì 0 tệp nào bị xóa.
- [ ] **Fail-closed với tệp mật / ngoài workspace:** nhờ XUNA ghi `.env` hoặc chạy lệnh xóa trỏ ra ngoài workspace / khớp `.env` → thẻ duyệt R3 vẫn xuất hiện bình thường nhưng **không** hiện khung xem trước và **không** lộ nội dung hay tên tệp mật; kiểm tra log/audit trên desktop & DB backend không chứa nội dung preview.
- [ ] **Kiểm chứng trên Mac & điện thoại thật:** chạy lại 3 mục trên với **desktop Mac** và **iPhone/Android thật**.

## 5. Số lần bị hỏi (để quyết định D1/D2)

- [ ] Làm một việc 5 bước (ví dụ: mở app → tìm kiếm → chạm kết quả) và **đếm số lần hiện hộp duyệt**. Dự kiến khoảng 6 lần (observe R2 + mỗi `act` R3). Con số thực tế quyết định có cần phiên điều khiển (UDC-16 phần D) hay không.

## 6. Việc còn lại cần ghi nhận khi test

- Tool bị chặn vì thiếu Consent U5 hoặc quyền nhóm của máy: chip lỗi có nút dẫn tới đúng trang (UDC-17 S17.3, §4f). Thiếu quyền hệ thống trên máy tính (Trợ năng, ghi màn hình) chỉ có chữ "Cần bật quyền trên máy tính", chưa có nút.
- Chưa có trang hub riêng; thẻ nằm trên trang hosts.
- S16.3 (duyệt trước R2) và S16.4 (phiên điều khiển) chưa bắt đầu; chờ bản sửa ADR-0012.

## 7. Báo lại

Với mỗi mục sai, gửi: model máy + phiên bản Android, bản `dev` hay `play`, bước đã làm, kết quả thấy, và (nếu có) `adb logcat -d | findstr /i "xuna flutter"` quanh thời điểm lỗi. Nếu một tool trả lỗi, chép nguyên `errorCode`.

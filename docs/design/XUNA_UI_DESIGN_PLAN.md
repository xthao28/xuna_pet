# XUNA — Kế hoạch thiết kế UI app và prompt cho Claude Design

Ngày: 2026-10-14. Trạng thái: **Proposed** — kế hoạch thiết kế, chưa phải phê duyệt tính năng. Mỗi đợt chỉ được code khi session tương ứng trong [XUNA_SESSION_PLAN.md](../roadmap/XUNA_SESSION_PLAN.md) được owner mở.

Nền tảng hiện có: project Claude Design **"XUNA App"** (`XUNA App.dc.html`, project `021e070e-cd28-4c9e-924b-d571616aa42e`) và bản đã code trong `mobile/` (xem [mobile-ui-design-system.md](../roadmap/mobile-ui-design-system.md)): 4 tab Nhà / Trò chuyện / Nhật ký / Thiết bị, token màu, font Anton + Be Vietnam Pro + JetBrains Mono, các base widget `App*`.

---

## 1. Nguyên tắc thiết kế (áp dụng cho mọi đợt)

1. **Giữ ngôn ngữ hình ảnh hiện tại:** nền giấy `#F7F2E4`, thẻ `#FBF7EC`, viền mực `#151515` 2.5–3 px, bóng đổ cứng lệch 3–6 px, accent lime `#D6F43F`, lilac `#C4A9F6`/`#E6DAFB`, lấp lánh pixel xanh `#2B55FF`, tim pixel hồng `#FF6FA8`. Tiêu đề Anton viết hoa, nhãn nhỏ JetBrains Mono viết hoa, thân bài Be Vietnam Pro.
2. **Thiết bị là nguồn sự thật:** app chỉ hiển thị, yêu cầu và xác nhận. Không thiết kế số liệu mà thiết bị không cung cấp (level, XP, ngày giờ khi đồng hồ chưa tin cậy).
3. **Copy trung thực:** không gọi luật cố định là "AI" hay "học". Phân biệt rõ *"bạn đã thích…"* (học từ phản hồi), *"bạn đã kể với mình…"* (bạn nói), *"XUNA đoán…"* (suy luận).
4. **Mọi thứ dạy XUNA đều cần màn xác nhận** ghi rõ sẽ thay đổi gì và nguồn từ đâu. Không có gì tự học từ câu chưa hiểu.
5. **Hành động xoá/riêng tư** luôn có xác nhận và câu "không thể hoàn tác".
6. **Chế độ mô phỏng luôn có nhãn** khi dùng BLE giả.
7. **Phần chưa có** hiển thị mờ + nhãn "SẮP CÓ", không có số liệu giả.
8. **Ràng buộc kỹ thuật cho handoff:** mỗi file ảnh xuất ra **≤ 150 KB** (connector đọc tối đa 256 KiB/file, base64 làm phình ~33%), pixel art xuất ở kích thước gốc, PNG nền trong suốt khi có thể; icon vẽ bằng SVG nét. Mỗi màn hình phải có đủ trạng thái: đang tải, rỗng, lỗi, chưa kết nối, mô phỏng.

---

## 2. Lộ trình thiết kế theo plan phát triển

| Đợt | Milestone / session | Màn hình & trạng thái cần thiết kế | Dữ liệu thật lúc đó | Ưu tiên |
|---|---|---|---|---|
| **D0** — Hoàn thiện nền | Hiện tại (sau S17) | Dialog xác nhận, dialog thông tin, toast/snackbar theo style XUNA; trạng thái loading/rỗng/lỗi chung; xuất lại ảnh gốc ≤ 150 KB (`room`, `avatar`, `book`, `lv1–3`); thông báo khi XUNA từ chối yêu cầu (result 5: đang bận/đang ngủ/hết năng lượng) | v1 hiện có | **Làm ngay** |
| **D1** — Kết nối & Nở | M04: S01, S10, S17 | Màn chào lần đầu (chưa có thiết bị); xin quyền Bluetooth (iOS/Android, bị từ chối, Bluetooth tắt); tìm thiết bị (đang quét, không thấy, nhiều thiết bị, lỗi); thiết bị đang là **Trứng** → nút "Nở" (TimeSync rồi Hatch) + màn nở; hồ sơ XUNA: ngày sinh (chính xác / không rõ → hiển thị "thời gian sống cùng bạn"), chỉ báo chất lượng đồng hồ (đã đồng bộ / gần đúng / chưa rõ), buổi trong ngày | identity, bornAt quality, clockQuality, dayPart, activeLifetime | Cao |
| **D2** — Học & Trò chuyện nền | M05a + M05c-A: S27, S27a, S27b (tuỳ chọn) | Phản hồi gắn với một phản ứng cụ thể; màn **"Vì sao XUNA làm vậy?"** (học từ phản hồi tách khỏi điều bạn kể, theo buổi trong ngày); màn **xác nhận ứng viên** (sẽ ghi gì, nguồn, Đồng ý/Huỷ); trạng thái thiết bị không hỗ trợ "điều bạn kể" (thiếu capability bit 5); *tuỳ chọn:* push-to-talk (quyền micro, đang nghe, không lưu âm thanh) | Explanation{p, nEff, posMass, negMass, statedMass}, candidate event | Cao |
| **D3** — Ghép nối & Riêng tư | M05b: S35, S36, S37 | Ghép nối BLE an toàn (mã passkey hiện trên màn LCD, nhập trên điện thoại, mất ghép nối, khôi phục); xác nhận hành động nguy hiểm bằng **bấm nút trên thiết bị trong 10 s**; **Nhật ký đầy đủ** (loại: học, kỹ năng, lớn lên, kỷ niệm, chỉnh sửa, đã xoá; có ngày khi biết giờ); **Ký ức & Riêng tư** (danh sách điều XUNA nhớ về bạn, xoá từng mục, xoá tất cả, trạng thái đồng bộ) | JournalRecord, FactRecord, provenance, tombstone | Trung bình |
| **D4** — Trò chuyện có trí nhớ | M05c-B: S41 | Xác nhận fact (tên gọi, biệt danh XUNA), câu trả lời có nguồn ("Bạn đã kể với mình…"), nhắc lại, sửa/xoá fact ngay trong chat, chế độ offline | facts đã xác nhận | Trung bình |
| **D5** — Khái niệm phát triển | M05d/M06 sau S42a (D15) | Màn **Kỹ năng** (đang tập / đã có, kèm bằng chứng); cài đặt "XUNA chủ động chờ bạn" (bật/tắt, không gửi thông báo nhắc nhở); hành trình lớn lên Trứng → Sơ sinh → Bé → Thiếu niên → Trưởng thành; nghi thức lên giai đoạn; Nhật ký tiến hoá có lý do | SkillAcquired, stage, GrowthConfig | **Chỉ khám phá**, chưa chốt |
| Backlog | Chưa có trong plan | Độ sáng màn hình (cần opcode mới), giọng nói trực tiếp trên thiết bị (VOICE-01–04), cảm biến M07, cloud/backup | — | Không thiết kế bây giờ |

Thứ tự đề xuất: **D0 → D1 → D2 → D3 → D4**, còn D5 chỉ làm moodboard/khái niệm để không chốt sớm (AGENTS §4).

---

## 3. Cách làm việc với Claude Design

1. Mở project "XUNA App" hiện có, thêm file mới cho mỗi đợt (ví dụ `XUNA D1 Onboarding.dc.html`) thay vì sửa file gốc, để bản đã code vẫn còn làm mốc.
2. Dán **Prompt 0 (bối cảnh chung)** trước, sau đó dán prompt của đợt.
3. Yêu cầu Claude Design dùng lại khung điện thoại, nav dưới, sheet, toast và token có sẵn trong `XUNA App.dc.html`.
4. Xong mỗi đợt: gửi link cho Claude Code import qua connector `claude_design`; mình đối chiếu với dữ liệu thật và quy tắc `mobile/AGENTS.md` trước khi code.
5. Checklist duyệt ở mục 5.

---

## 4. Prompt cho Claude Design

### Prompt 0 — Bối cảnh chung (dán đầu tiên ở mỗi phiên)

```text
Bạn đang tiếp tục thiết kế app companion của XUNA – một pixel pet sống trên thiết bị thật (board LILYGO T-Display-S3, màn LCD 1.9" 170×320, kết nối Bluetooth LE). App Flutter chỉ là bạn đồng hành: thiết bị giữ toàn bộ trạng thái, trí nhớ và việc học của XUNA; app hiển thị, gửi yêu cầu và xác nhận.

Hãy dùng đúng hệ thiết kế trong file "XUNA App.dc.html" của project này:
- Nền giấy #F7F2E4, thẻ #FBF7EC, viền mực #151515 dày 2.5–3px, bóng đổ cứng lệch 3–6px (không blur), bo góc 10–16px.
- Accent lime #D6F43F (hành động chính, mục đang chọn), lilac #C4A9F6 / #E6DAFB / #A98BEA, lấp lánh pixel xanh #2B55FF, tim pixel hồng #FF6FA8, chấm trạng thái xanh #9BE22E / vàng #FFD23F / xám #B8B3A7.
- Font: Anton (tiêu đề lớn viết hoa), JetBrains Mono (nhãn nhỏ viết hoa, giãn chữ), Be Vietnam Pro (thân bài).
- Thành phần có sẵn: khung iPhone 393×852, thanh nav dưới 4 tab (Nhà, Trò chuyện, Nhật ký, Thiết bị), bottom sheet có tay cầm, toast đen viền lime, thẻ viền mực, nút CTA lime, pill gợi ý, tag nhỏ, công tắc pill, nhãn "SẮP CÓ".
- Nút có hiệu ứng nhấn: lún vào bóng đổ.

Quy tắc nội dung (bắt buộc):
- Toàn bộ chữ trong app bằng tiếng Việt, giọng XUNA dễ thương, xưng "mình" – gọi "bạn".
- Không bịa số liệu: không level, XP, ngày giờ nếu thiết bị không cung cấp. Phần chưa có thì hiển thị mờ kèm tag "SẮP CÓ".
- Không gọi luật cố định là "AI" hay "học". Phân biệt: "bạn đã thích…" (học từ phản hồi), "bạn đã kể với mình…" (bạn nói), "XUNA đoán…" (suy luận).
- Mọi thứ dạy XUNA phải qua màn xác nhận ghi rõ sẽ thay đổi gì và nguồn từ đâu.
- Xoá/riêng tư luôn có hộp xác nhận với câu "Thao tác này không thể hoàn tác."
- Khi dùng BLE giả phải có nhãn "MÔ PHỎNG".

Yêu cầu bàn giao:
- Mỗi màn hình có đủ trạng thái: đang tải, rỗng, lỗi, chưa kết nối, mô phỏng (dùng biến điều khiển trạng thái như file gốc).
- Ảnh/pixel art xuất PNG riêng, mỗi file ≤ 150 KB, kích thước gốc, nền trong suốt khi có thể. Icon vẽ SVG nét #151515.
- Thêm một bảng ghi chú cuối file: danh sách màn hình, trạng thái, và dữ liệu mỗi phần tử cần lấy từ thiết bị.
```

### Prompt D0 — Hoàn thiện nền (làm ngay)

```text
Tạo file mới "XUNA D0 Foundations.dc.html" trong project này, dùng lại hệ thiết kế của "XUNA App.dc.html".

Thiết kế bộ thành phần còn thiếu, đặt trong khung điện thoại và một trang "component sheet":
1. Hộp thoại xác nhận (tiêu đề Anton, mô tả, nút Huỷ viền + nút xác nhận lime; biến thể nguy hiểm cho Xoá với câu "Thao tác này không thể hoàn tác.").
2. Hộp thoại thông tin (icon pixel thành công / lỗi / ghi chú).
3. Toast/snackbar 3 loại: thông tin, thành công, lỗi – cùng phong cách toast đen viền lime hiện có.
4. Trạng thái chung: đang tải (3 chấm pixel nhảy), rỗng (XUNA ngồi chờ + câu gợi ý), lỗi (XUNA bối rối + nút Thử lại), chưa kết nối (màn LCD tối "z z z" + nút Kết nối).
5. Thông báo khi XUNA từ chối một yêu cầu, có 4 lý do riêng: "XUNA đang ngủ", "XUNA đang bận phản ứng", "XUNA hơi mệt, cần nghỉ chút", "Đợi một chút rồi thử lại nhé" (chờ hồi chiêu). Thể hiện dạng toast và dạng bong bóng trong phòng.
6. Xuất lại các ảnh pixel: room.png (phòng XUNA, tỉ lệ 417:360), avatar.png (mặt XUNA tròn), book.png (cuốn sách mở), lv1/lv2/lv3.png. Mỗi file PNG ≤ 150 KB, kích thước gốc pixel, không làm mịn.

Giữ nguyên 4 tab và nav hiện có; chỉ bổ sung thành phần. Cuối file thêm bảng ghi chú các thành phần, biến thể và khi nào dùng.
```

### Prompt D1 — Kết nối lần đầu, Nở trứng, hồ sơ XUNA (M04)

```text
Tạo file mới "XUNA D1 Onboarding.dc.html", dùng lại hệ thiết kế và khung của "XUNA App.dc.html".

Luồng cần thiết kế (có biến chọn bước để xem từng màn):
1. Chào lần đầu: chưa có thiết bị. Tiêu đề kiểu "XIN CHÀO." + mô tả XUNA sống trên một thiết bị nhỏ trên bàn bạn. Nút "TÌM XUNA". Link phụ "Dùng chế độ mô phỏng" (có nhãn MÔ PHỎNG).
2. Quyền Bluetooth: giải thích ngắn vì sao cần; trạng thái bị từ chối (nút mở Cài đặt); Bluetooth đang tắt.
3. Tìm thiết bị: đang quét (radar pixel), không tìm thấy (gợi ý cắm nguồn, để gần), tìm thấy 1 hoặc nhiều thiết bị (tên quảng bá hiện tại là "XUNA"; hiển thị kèm 4 ký tự cuối địa chỉ để phân biệt), đang kết nối, lỗi kết nối / thiết bị không hỗ trợ.
4. Thiết bị đang là TRỨNG: màn quả trứng pixel lắc nhẹ, câu "XUNA sắp chào đời", nút lime "NỞ". Giải thích ngắn: app sẽ gửi giờ hiện tại để ghi đúng ngày sinh. Màn đang nở (trứng nứt từng bước) và màn chào XUNA vừa nở.
5. Trường hợp XUNA đã nở từ trước (pet cũ chuyển sang): không hiện nút Nở, chuyển thẳng vào app.
6. Hồ sơ XUNA (mở từ tab Thiết bị hoặc Nhà, dạng trang hoặc sheet):
   - Ngày sinh: hai biến thể – "Sinh ngày 14/10/2026" khi chính xác, hoặc "Chưa rõ ngày sinh" kèm "Đã sống cùng bạn 12 giờ 30 phút" khi không biết.
   - Giai đoạn hiện tại: "Sơ sinh" (các giai đoạn sau để tag SẮP CÓ).
   - Đồng hồ của XUNA: 3 trạng thái – Đã đồng bộ (chấm xanh), Gần đúng (vàng), Chưa rõ giờ (xám), kèm buổi trong ngày nếu biết (Sáng / Chiều / Tối / Đêm).
7. Cập nhật tab Nhà: chip buổi trong ngày cạnh chip hoạt động khi giờ đã đồng bộ; không hiện gì khi chưa rõ.

Không thêm level hay XP. Cuối file liệt kê dữ liệu cần từ thiết bị: trạng thái Trứng/đã nở, bornAt + độ tin cậy, clockQuality, dayPart, activeLifetime.
```

### Prompt D2 — "Vì sao XUNA làm vậy?" và màn xác nhận (M05a + M05c-A)

```text
Tạo file mới "XUNA D2 Learning & Conversation.dc.html", dùng lại hệ thiết kế của "XUNA App.dc.html" (đặc biệt tab Trò chuyện và Nhật ký).

1. Phản hồi gắn với phản ứng: trong chat và trên tab Nhà, khi XUNA vừa phản ứng (ví dụ "vẫy tay"), hiện thẻ nhỏ "XUNA vừa vẫy tay – bạn thấy sao?" với Thích / Không thích. Có trạng thái hết hạn ("Lượt này đã qua") và đã ghi.
2. Màn "VÌ SAO XUNA LÀM VẬY?" (sheet hoặc trang, mở từ thẻ phản ứng và từ Nhật ký):
   - Câu chính dựng từ dữ liệu, ví dụ: "XUNA chọn vẫy tay vì bạn đã thích 12/15 lần vào buổi tối."
   - Hai khối tách biệt: "HỌC TỪ PHẢN HỒI CỦA BẠN" (thanh tỉ lệ thích/không thích cho từng hành động, số lần) và "ĐIỀU BẠN ĐÃ KỂ" ("Bạn đã nói với mình bạn thích yên tĩnh buổi tối").
   - Theo buổi trong ngày: tab nhỏ Sáng / Chiều / Tối / Đêm / Chung; trạng thái chưa đủ dữ liệu.
   - Ghi chú "XUNA vẫn thỉnh thoảng thử điều mới" (khám phá có giới hạn).
3. Màn XÁC NHẬN ỨNG VIÊN (dùng chung cho chat gõ chữ và sau này giọng nói):
   - Hiển thị câu bạn vừa nói, điều XUNA hiểu được (ví dụ "Bạn thích XUNA yên tĩnh vào buổi tối"), loại ("Bạn kể" hoặc "Phản hồi cho phản ứng vừa rồi"), nguồn ("tin nhắn"), và chính xác điều sẽ thay đổi trên thiết bị.
   - Nút "Đúng, ghi lại" (lime) / "Không phải vậy". Trạng thái đang gửi, đã ghi, lỗi (không tự gửi lại – nút "Kiểm tra lại").
   - Trạng thái thiết bị cũ chưa hỗ trợ "điều bạn kể": giải thích ngắn, vẫn cho phản hồi Thích/Không thích.
4. Câu không hiểu: XUNA nói thật là chưa hiểu và không ghi gì; gợi ý các câu mẫu.
5. (Tuỳ chọn, gắn tag "THỬ NGHIỆM") Push-to-talk: màn xin quyền micro rõ ràng, giữ để nói, đang nghe, đang nhận dạng, câu nhận được → đưa vào cùng màn xác nhận. Ghi rõ "Không lưu âm thanh, không gửi lên mạng."

Cuối file ghi chú dữ liệu: Explanation{hành động, tỉ lệ p, số lần nEff, thích, không thích, statedMass, buổi}, candidate{loại, nguồn, giá trị}.
```

### Prompt D3 — Ghép nối an toàn, Nhật ký đầy đủ, Ký ức & Riêng tư (M05b)

```text
Tạo file mới "XUNA D3 Memory & Privacy.dc.html", dùng lại hệ thiết kế của "XUNA App.dc.html".

1. Ghép nối an toàn: màn hướng dẫn "Nhìn màn hình XUNA" với minh hoạ board hiện mã 6 số; ô nhập mã trên điện thoại; đã ghép nối; mã sai; ghép nối bị mất / thiết bị đã quên điện thoại này (hướng dẫn khôi phục). Thẻ trạng thái "Đã ghép nối an toàn" trong tab Thiết bị.
2. Xác nhận nguy hiểm trên thiết bị: khi xoá tất cả hoặc xoá một ký ức, app hiện "Bấm nút trên XUNA trong 10 giây để xác nhận" với vòng đếm ngược pixel; các trạng thái: đang chờ, đã xác nhận, hết giờ, bị huỷ.
3. Nhật ký đầy đủ (nâng cấp tab Nhật ký hiện tại):
   - Loại mục: Học được, Kỹ năng (SẮP CÓ), Lớn lên (SẮP CÓ), Kỷ niệm, Đã chỉnh sửa, Đã xoá (mục mờ "Ký ức này đã được xoá").
   - Có ngày giờ khi thiết bị biết giờ, nếu không thì "Không rõ thời điểm".
   - Mỗi mục mở được sheet bằng chứng: lý do, nguồn (bạn phản hồi / bạn kể / XUNA quan sát / XUNA suy luận), các sự kiện liên quan.
   - Mục được bảo vệ (cột mốc) có dấu ghim.
4. Ký ức & Riêng tư (trang mới, mở từ Nhật ký và Thiết bị):
   - "ĐIỀU XUNA NHỚ VỀ BẠN": danh sách fact (ví dụ "Bạn muốn được gọi là Thảo", "Bạn thích yên tĩnh buổi tối"), mỗi dòng có nguồn "Bạn đã kể với mình" và nút xoá.
   - Bộ nhớ đầy: thông báo XUNA không nhận thêm và cách giải phóng.
   - "Xoá tất cả" (nguy hiểm, dùng xác nhận trên thiết bị), ghi rõ những gì được giữ lại (danh tính, thời gian sống).
   - Trạng thái đồng bộ với thiết bị: đã đồng bộ, đang đồng bộ, có thay đổi chưa đồng bộ.
   - Câu cam kết: "Nội dung tin nhắn không được lưu."

Cuối file ghi chú dữ liệu: JournalRecord{loại, lý do, bằng chứng, thời điểm}, FactRecord{nội dung, nguồn, trạng thái}, provenance, tombstone.
```

### Prompt D4 — Trò chuyện có trí nhớ (M05c-B)

```text
Tạo file mới "XUNA D4 Conversation Memory.dc.html", dùng lại tab Trò chuyện và màn xác nhận ứng viên ở file D2.

1. Dạy XUNA một điều về bạn: "Gọi mình là Thảo nhé" → màn xác nhận fact (sẽ nhớ: tên gọi = Thảo, nguồn: bạn kể) → XUNA trả lời dùng tên mới.
2. Đặt biệt danh cho XUNA và hiển thị biệt danh ở tab Nhà.
3. Câu trả lời có nguồn: bong bóng XUNA có dòng nhỏ "Bạn đã kể với mình ngày 14/10" hoặc "Mình học từ phản hồi của bạn"; chạm vào mở sheet bằng chứng.
4. Nhắc lại: "Bạn có nhớ mình thích gì không?" → XUNA liệt kê đúng những gì đã được xác nhận, không thêm gì.
5. Sửa/xoá ngay trong chat: "Không, mình không thích nữa" → màn xác nhận thay thế fact cũ; "Quên điều đó đi" → xác nhận xoá (có bước bấm nút trên thiết bị nếu cần).
6. Offline/không kết nối: XUNA chỉ trả lời bằng luật cục bộ và nói rõ chưa thể ghi nhớ.
7. Khi XUNA chưa biết: "Mình chưa biết điều đó, bạn kể mình nghe nhé?"
```

### Prompt D5 — Khái niệm phát triển (khám phá, chưa chốt)

```text
Tạo file mới "XUNA D5 Growth Concepts.dc.html" – đây là bản KHÁM PHÁ, chưa phải thiết kế chốt. Đánh dấu mọi màn bằng tag "KHÁI NIỆM".

1. Kỹ năng: danh sách kỹ năng với trạng thái "Đang tập" / "Đã có" / "Chưa mở", mỗi kỹ năng có bằng chứng đo được (ví dụ "Chọn đúng điều bạn thích 7/10 lần gần nhất"). Phân biệt kỹ năng học được với điều chỉ cần bạn kể (ví dụ biết biệt danh).
2. Cài đặt "XUNA chủ động chờ bạn": giải thích XUNA có thể tạo dáng chờ vào giờ bạn hay ghé; bật/tắt; cam kết không gửi thông báo nhắc nhở, không trách móc.
3. Hành trình lớn lên: Trứng → Sơ sinh → Bé → Thiếu niên → Trưởng thành, với điều kiện là trải nghiệm và kỹ năng (không phải chỉ thời gian). Hai lịch sử khác nhau tạo ra hai XUNA khác nhau – minh hoạ ý tưởng bằng 2 phiên bản đặt cạnh nhau.
4. Nghi thức lên giai đoạn: chuỗi 3–4 khung hình, sau đó thẻ Nhật ký "Vì sao XUNA lớn lên" với bằng chứng.
5. 2–3 hướng thay đổi ngoại hình theo trait (không phải cây tiến hoá cố định), vẽ dạng lớp ghép (tai, màu, phụ kiện).
```

---

## 5. Checklist duyệt thiết kế trước khi code

- [ ] Dùng đúng token, font, viền và bóng của hệ hiện tại; tái sử dụng thành phần `App*` thay vì tạo kiểu mới.
- [ ] Mỗi số liệu hiển thị có nguồn dữ liệu thật từ thiết bị ở milestone đó (đối chiếu bảng mục 2).
- [ ] Không có level/XP/ngày giờ bịa; phần chưa có dùng "SẮP CÓ".
- [ ] Copy phân biệt đúng "bạn đã thích" / "bạn đã kể" / "XUNA đoán".
- [ ] Có màn xác nhận cho mọi thao tác dạy XUNA; có xác nhận và câu "không thể hoàn tác" cho xoá.
- [ ] Có đủ trạng thái tải, rỗng, lỗi, chưa kết nối, mô phỏng; nhãn MÔ PHỎNG.
- [ ] Vừa màn hẹp 360×640 và iPhone 393×852; vùng chạm ≥ 44 px.
- [ ] Ảnh xuất ≤ 150 KB mỗi file, icon SVG.
- [ ] Bảng ghi chú dữ liệu ở cuối file khớp với giao thức/plan; phần cần giao thức mới được đánh dấu.

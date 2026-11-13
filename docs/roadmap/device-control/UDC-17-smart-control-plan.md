# UDC-17 — Điều khiển thiết bị thông minh, ít hỏi hơn

Ngày: 2026-11-12. **Trạng thái: Chủ đã duyệt ngày 2026-11-12 với gói "Rộng tay" (xem mục 8); quyết định ghi tại [ADR-0015](../../decisions/ADR-0015-commit-gated-control-and-trusted-scopes.md), sửa [ADR-0012](../../decisions/ADR-0012-host-actions.md) và [ADR-0014](../../decisions/ADR-0014-standing-approvals-and-phone-sessions.md). Đã làm và kiểm trên máy phát triển: E1, E2, S17.1, S17.2 phần Dart/backend, S17.3, S17.6, S17.4 phần Dart/backend (chỉ test tự động, chưa chạy máy thật). Còn lại của S17.2: đọc phần tử đang focus bằng native (cần Q6). Còn lại của S17.4: ref ổn định từ native (cần Mac). S17.5 (gợi ý duyệt trước, mẫu chạy lại lưu trên điện thoại) đã làm 2026-11-13, chỉ test tự động; thẻ duyệt mở phiên hiện đủ phạm vi (§15), chặn lưu mẫu quá lớn và vùng dưới khung chat cuộn được (§16) cũng xong cùng ngày.**

## 1. Mục tiêu

Chủ nói một câu, XUNA làm xong việc trên máy tính với **ít lần ký duyệt nhất mà vẫn không mất quyền kiểm soát**, và khi không làm được thì nói rõ vì sao.

Nguyên tắc đề xuất, thay cho "mỗi thao tác rủi ro hỏi một lần":

> **Chuẩn bị thì tự do, chốt thì hỏi.** Trong một phiên chủ đã ký, XUNA được đọc, bấm điều hướng và gõ nháp. Chủ chỉ phải ký ở **điểm không quay lại được**: gửi, đăng, xoá, thanh toán, xác nhận.

## 2. Hiện trạng (đối chiếu từ code ngày 2026-11-12)

| # | Vấn đề | Nguồn |
|---|---|---|
| P1 | Mỗi lần `input.type_text` phải ký R3, dù chữ mới chỉ nằm trong ô nhập và chưa gửi đi đâu | `tool_arg_validators.dart`, ADR-0014 D2.3 |
| P2 | Mỗi lần `Enter`/`Space` phải ký R3 (sửa 2026-11-12, vì cờ `inForm` do LLM tự khai). An toàn nhưng hỏi cả khi chỉ là Enter trong ô tìm kiếm | `isActivationKeyCombo` |
| P3 | Mức rủi ro được tính ở **hai nơi** (backend và desktop) bằng hai bảng từ khoá riêng. Backend đoán từ bộ nhớ đệm `cached_nodes`; lệch thì desktop từ chối `approval_required` và luồng kẹt | `orchestrator.py` `_effective_tool_risk`, `computer_use_session_manager.dart` |
| P4 | Hộp duyệt trên điện thoại hiện tên phần tử do LLM gửi, không phải tên thật trên màn hình | `action_summary.py` |
| P5 | Cây giao diện giới hạn 60 phần tử, LLM phải đọc cả cây để tìm một nút; ref trên Windows là số thứ tự quét lại, dễ lệch | [kết quả gia cố 2026-11-06](desktop-control-hardening-results-2026-11-06.md) §5 |
| P6 | Cần thêm một app giữa chừng thì phải kết thúc và mở phiên mới | `startSession` |
| P7 | Bị từ chối do thiếu quyền: giờ LLM đã biết lý do, nhưng app chưa có nút dẫn chủ tới đúng chỗ bật | checklist UDC-16 §6 |
| P8 | Phiên phía backend nằm trong RAM (`InMemoryComputerUseSessionStore`): mất khi khởi động lại, sai khi chạy nhiều worker | `wiring.py` |
| P9 | Còn mở từ review: đối chiếu cửa sổ macOS theo tên hiển thị; "public HTTPS" chỉ kiểm cú pháp; tên chứa "mật khẩu" chặn nhầm cả nút "Quên mật khẩu" | PROCESS 2026-11-12 |
| P10 | Chưa đo được một việc thật tốn bao nhiêu lần hỏi | checklist UDC-16 §5 |

Ước tính số lần ký (suy từ luật hiện tại, **chưa đo trên máy thật**):

| Việc | Hiện tại | Sau plan (nếu duyệt Q1b + Q2b) |
|---|---|---|
| Mở Ghi chú, tạo ghi chú, gõ nội dung, lưu | 2 (mở phiên, gõ) | 1 (mở phiên) |
| Tìm một người trong app nhắn tin, soạn tin, gửi | 5 (mở phiên, gõ tên, Enter, gõ tin, gửi) | 2 (mở phiên, gửi) |
| Mở trang web, tìm kiếm, cuộn đọc | 3–4 | 1–2 |

## 3. Thiết kế đề xuất

### A. Host là nơi duy nhất quyết định mức rủi ro (nền móng, không đổi số lần hỏi)

- Thêm bước **preflight** vào XTP: trước khi xin duyệt, backend hỏi host "thao tác này vào đúng phần tử này thì mức nào?". Host trả `effectiveRisk`, lý do (mã, không phải chữ tự do), và nhãn thật của phần tử lấy từ cây giao diện hiện tại.
- Backend bỏ bảng từ khoá và phần đoán từ `cached_nodes` cho `input.*`; chỉ còn làm theo câu trả lời của host. Hết lệch hai phía (P3), hộp duyệt hiện đúng tên nút thật (P4).
- Không trả lời được thì coi là R3 (đóng an toàn). Host vẫn tự kiểm lại lúc thực thi như hiện nay.
- Đổi hợp đồng XTP: cập nhật `XUNA_XTP_V1_CONTRACT.md` và fixture ở cả `backend/` lẫn `desktop/` trong cùng một đợt.

### B. "Chuẩn bị tự do, chốt thì hỏi" (giảm hỏi, cần ADR-0015)

- **Gõ nháp trong phiên (Q1):** `input.type_text` không cần ký từng lần khi đủ cả: đang trong phiên đã ký; cửa sổ thuộc app đã khai; ô đích là ô văn bản thường do host xác định từ cây thật (không phải ô mật khẩu/bảo mật, không phải ô không phân loại được); trong hạn mức ký tự của phiên. Chữ đang gõ hiện trực tiếp trên điện thoại kèm nút Dừng.
- **Enter theo ngữ cảnh (Q2):** host đọc phần tử đang focus. Ô tìm kiếm/thanh địa chỉ/ô một dòng không thuộc biểu mẫu gửi đi → R2. Ô soạn tin, biểu mẫu có nút gửi, hoặc **không xác định được** → R3 như hiện nay.
- **Luôn R3, không đổi:** nút và phím gửi/đăng/xoá/thanh toán/xác nhận; mọi thứ host không phân loại được; ô mật khẩu vẫn bị chặn cứng; app trong danh sách cấm vẫn cấm.
- Phân loại nằm ở adapter của host (đúng H5), mặc định đóng. Bộ kiểm thử chống chèn lệnh (UDC-8 §8) phải chạy lại với luật mới trước khi bật.
- *Giả định cần kiểm chứng:* macOS (`AXFocusedUIElement`) và Windows UIA (`GetFocusedElement`) cho biết phần tử đang focus và loại ô đủ tin cậy. Nếu một nền tảng không cho, nền tảng đó giữ R3.

### C. Nhìn và tìm thông minh hơn (ít vòng lặp, ít token)

- Công cụ `ui.find` (chỉ đọc): tìm phần tử theo chữ/vai trò, trả tối đa vài ứng viên có ref. LLM không phải đọc cả cây (P5).
- `ui.inspect` có chế độ chỉ trả phần tử tương tác được, và sau mỗi thao tác chỉ trả **phần thay đổi**.
- Ref ổn định theo định danh thật của hệ điều hành (UIA RuntimeId, định danh AX), bỏ ref theo số thứ tự. Phần này là native, **phải có máy để biên dịch và chạy**.

### D. Trải nghiệm phiên trên điện thoại

- **Thẻ phiên trực tiếp:** mục tiêu, app đang thao tác, bước x/y, chữ đang gõ, nút Dừng luôn hiện.
- **Mở rộng phạm vi giữa phiên:** cần thêm một app/tên miền thì xin một chữ ký "thêm X vào phiên này", không phải mở lại (P6).
- **Chạy lại một chạm:** phiên thành công lưu được thành mẫu (mục tiêu, app, tên miền, hạn mức). Lần sau một chữ ký là chạy. Dùng lại cơ chế workflow dạy được của UDC-12, không dựng hệ thống song song.
- **Gợi ý duyệt trước:** khi chủ đã duyệt đúng một việc R2 cố định nhiều lần, app gợi ý bật "luôn cho phép" (cơ chế ADR-0014 D1 đã có, chỉ thêm gợi ý).
- **Từ chối có lối đi:** khi thiếu Consent U5 hoặc quyền nhóm, khung chat hiện nút mở đúng trang để bật (P7).

### E. Dọn nợ và đo lường

- Đối chiếu cửa sổ macOS theo Bundle ID là chính; tên hiển thị chỉ dùng khi không có Bundle ID.
- `url.open`: host phân giải tên miền và chặn địa chỉ nội bộ, để "công khai" đúng nghĩa.
- Nhận diện ô mật khẩu theo vai trò/cờ bảo mật từ native; không chặn nút chỉ vì nhãn có chữ "mật khẩu".
- Kho phiên backend lưu bền (bảng PostgreSQL có migration) thay cho RAM (P8).
- Đo số lần hỏi mỗi phiên bằng audit không chứa nội dung, và mở rộng bộ 10 kịch bản mẫu sẵn có để in bảng trước/sau (P10).

### Không làm trong plan này

- Không thêm shell/eval/AppleScript, không chạy quyền admin, không Accessibility trong bản Play.
- Không gộp hay bỏ chữ ký cho thao tác chốt (gửi/xoá/thanh toán).
- Chụp màn hình native + mô hình thị giác: để sau (Q5).
- Phiên điều khiển trên điện thoại Android (S16.4): vẫn chờ số đo trên máy thật như ADR-0014 quy định. Phần A–B được thiết kế để adapter Android dùng lại.

## 4. Các phiên làm việc

| Phiên | Nội dung | Repo | Cần máy thật? | Phụ thuộc |
|---|---|---|---|---|
| S17.0 | ADR-0015 (sửa ADR-0014 D2.3 cho gõ nháp và Enter theo ngữ cảnh), đăng ký UDC-17 | docs | Không | Q1, Q2 |
| S17.1 | Preflight: host quyết mức rủi ro, hộp duyệt hiện nhãn thật | `xuna_xtp`, desktop, backend, mobile | Không (test bằng provider giả) | — |
| S17.2 | Gõ nháp trong phiên + Enter theo ngữ cảnh + chạy lại bộ chống chèn lệnh | `xuna_xtp`, desktop (Dart + native), backend | Phần Dart không; phần native focus **có** (Mac và/hoặc Windows) | S17.0, S17.1 |
| S17.3 | Thẻ phiên trực tiếp, mở rộng phạm vi, nút dẫn tới chỗ bật quyền | mobile, backend | Điện thoại để nghiệm thu | S17.1 |
| S17.4 | `ui.find`, cây chỉ-tương-tác, trả phần thay đổi, ref ổn định | `xuna_xtp`, desktop (native), backend | **Có** cho ref ổn định | — |
| S17.5 | Mẫu chạy lại, gợi ý duyệt trước | backend, mobile | Điện thoại để nghiệm thu | S17.3 |
| S17.6 | Dọn nợ mục E + đo lường | desktop, backend | Mac cho phần Bundle ID | — |

Mỗi phiên là một lát dọc kiểm thử được, kết thúc bằng báo cáo ghi rõ cái gì đã chạy và chưa chạy. Thứ tự đề xuất: **S17.1 → S17.0 → S17.2 → S17.3 → S17.6 → S17.4 → S17.5**. S17.1 đi trước vì không cần quyết định nào và mọi phần sau dựa trên nó.

## 5. Rủi ro chính

- **Gõ nháp vào nhầm chỗ.** Chữ nằm trong ô nhưng chưa gửi; bước gửi vẫn phải ký. Rủi ro còn lại là app tự lưu/tự gửi khi gõ (ví dụ ô tìm kiếm gợi ý trực tiếp). Giảm bằng: chỉ app đã khai, hạn mức ký tự, hiện chữ trực tiếp trên điện thoại, và danh sách loại ô được phép là danh sách đóng.
- **Phân loại sai một phần tử chốt** thành điều hướng. Đây vẫn là rủi ro còn lại lớn nhất, như ADR-0014 đã ghi. Mặc định "không biết thì R3" và bộ kiểm thử chống chèn lệnh là hàng rào.
- **Native không kiểm chứng được** nếu không có máy: code Swift/C++ viết ra mà chưa biên dịch thì không được coi là xong.
- **Đổi hợp đồng XTP**: host cũ và backend mới phải chạy được với nhau trong lúc chuyển (preflight là tuỳ chọn, thiếu thì giữ hành vi cũ).

## 6. Quyết định cần chủ chọn

**Q1 — Gõ chữ trong phiên**
- a. Giữ như hiện tại: mỗi lần gõ ký một lần.
- **b. (khuyến nghị)** Gõ nháp tự do trong phiên theo điều kiện ở mục B; bước gửi/chốt vẫn ký.
- c. Bỏ ký cả bước gửi trong phiên. Không khuyến nghị: mất điểm kiểm soát cuối cùng.

**Q2 — Phím Enter**
- a. Giữ như hiện tại: luôn ký.
- **b. (khuyến nghị)** Host xét phần tử đang focus; ô tìm kiếm thì không hỏi, còn lại và trường hợp không rõ thì ký.

**Q3 — Hạn mức phiên** (hiện tối đa 20 bước, 10 phút)
- **a. (khuyến nghị)** Giữ nguyên cho tới khi có số đo từ S17.6.
- b. Nâng lên 40 bước / 15 phút ngay.

**Q4 — Thứ tự**
- **a. (khuyến nghị)** Như mục 4: nền móng (S17.1) → giảm hỏi (S17.2) → trải nghiệm điện thoại (S17.3) → phần còn lại.
- b. Ưu tiên "nhìn thông minh hơn" (S17.4) trước.
- c. Chỉ làm S17.1 + S17.6 (sửa cho chắc, chưa giảm hỏi).

**Q5 — Chụp màn hình + mô hình thị giác** cho app có cây giao diện nghèo
- **a. (khuyến nghị)** Để sau, khi đã biết app nào thật sự cần.
- b. Đưa vào UDC-17.

**Q6 — Máy để kiểm chứng native:** chủ có thể chạy thử trên Mac, trên Windows, hay cả hai? Câu trả lời quyết định phần native của S17.2 và S17.4 làm trước cho nền tảng nào.

## 7. Mở rộng quyền (bổ sung 2026-11-12 theo yêu cầu của chủ)

Chủ hỏi có thể cho XUNA nhiều quyền hơn không. Bảng dưới xếp từ ít ảnh hưởng tới nhiều. Mối nguy chính không phải XUNA "tự ý", mà là **nội dung trên màn hình (trang web, tin nhắn, email) chèn lệnh vào LLM**; mỗi mục được đánh giá theo câu hỏi "nếu LLM bị dắt mũi thì hậu quả tệ nhất là gì".

| # | Nâng quyền | Bớt được gì | Hậu quả tệ nhất | Mức ảnh hưởng | Khuyến nghị |
|---|---|---|---|---|---|
| E1 | Hạn mức phiên 20 bước/10 phút → 40 bước/20 phút | Việc dài không bị cắt giữa chừng | Phiên bị dắt chạy lâu hơn trước khi tự dừng; bước chốt vẫn phải ký | Thấp | Làm |
| E2 | Hạn quyền nhóm R3 (`cu`, `input`) 1 ngày → 30 ngày | Không phải bật lại mỗi ngày | Không đáng kể: quyền nhóm chỉ làm công cụ đủ điều kiện, từng việc vẫn qua duyệt | Thấp | Làm |
| E3 | **Chế độ tin cậy cho việc R2**: mở app, mở link `https`, quản lý cửa sổ, media tự chạy, chỉ báo trên điện thoại, không hỏi. Bật có thời hạn (ví dụ 8 giờ) | Hết hộp duyệt cho việc vặt, là phần lớn số lần hỏi hằng ngày | Mở một trang web xấu hoặc một app không mong muốn. Không gõ, không bấm, không gửi được gì | Thấp | Làm |
| E4 | **App tin cậy**: chủ ký một lần danh sách app (hạn 30 ngày); phiên chỉ gồm các app đó tự mở, không ký | Bỏ chữ ký mở phiên, lần ký còn lại duy nhất là bước chốt | XUNA đọc và điều hướng trong các app đó bất cứ khi nào được ra lệnh; nội dung trong app có thể dắt nó bấm lung tung, nhưng không chốt được gì | Trung bình | Làm, trình duyệt không nằm trong danh sách mặc định |
| E5 | **Đếm ngược thay cho ký** với bước chốt loại nhẹ (gửi tin nhắn, bấm xác nhận hộp thoại, xoá một mục vào thùng rác): điện thoại hiện nội dung sắp làm kèm nút Huỷ trong vài giây, không bấm thì chạy | Việc nhắn tin, dọn dẹp chạy không cần chạm | Một tin nhắn sai nội dung hoặc sai người được gửi đi khi chủ không nhìn điện thoại. Không thu hồi được | Trung bình–cao | Chỉ bật cho app chủ chọn, mặc định tắt |
| E6 | Trình duyệt vào app tin cậy với mọi tên miền | Lướt web, điền biểu mẫu không cần khai tên miền | Trang web là nguồn chèn lệnh mạnh nhất, và trình duyệt đang đăng nhập sẵn mọi tài khoản của chủ | Cao | Không; giữ danh sách tên miền |
| E7 | Tự lái hoàn toàn: bỏ ký cả thanh toán, chuyển khoản, đăng công khai, xoá tài khoản, gỡ cài đặt | Không còn hỏi gì | Mất tiền, mất dữ liệu, đăng bài thay chủ | Rất cao | Không |

Giữ nguyên ở mọi mức: không shell/eval, không cửa sổ quyền admin, không ô mật khẩu, không terminal/trình quản lý mật khẩu/app ngân hàng/Cài đặt hệ thống, nút Dừng khẩn cấp, và hai lớp kiểm (backend + máy tính).

Ghi chú kỹ thuật:
- E3 không làm yếu hàng rào chống backend bị chiếm: duyệt R2 hiện vốn không có chữ ký điện thoại, chỉ R3 mới có. E4 thì có, nên danh sách app tin cậy phải được **ký bằng khoá điện thoại** và máy tính tự kiểm chữ ký, giống duyệt trước của ADR-0014.
- E3, E4, E5 đều sửa ADR-0012/0014 nên đi chung vào ADR-0015.

**Q7 — Chọn gói quyền**
- a. Thận trọng: chỉ E1 + E2.
- **b. (khuyến nghị) Cân bằng: E1 + E2 + E3 + E4**, cộng Q1b và Q2b. Chủ chỉ còn ký ở bước chốt.
- c. Rộng tay: gói b + E5 cho các app chủ chọn.

## 8. Quyết định của chủ (2026-11-12)

| Câu | Kết quả |
|---|---|
| Q7 | **c. Rộng tay**: E1 + E2 + E3 + E4 + E5 (E5 chỉ cho app chủ chọn, mặc định tắt). E6 và E7 không làm. Nguyên văn: "rộng tay luôn cho máu, không quá nguy hiểm là được". |
| Q1, Q2 | **b** cho cả hai (nằm trong gói đã chọn). |
| Q3 | Thay bằng E1: 40 bước / 20 phút. **Đã làm.** |
| Q4, Q5 | Theo khuyến nghị (thứ tự ở mục 4; chụp màn hình để sau), dựa trên uỷ quyền "bạn có thể tự quyết định nếu thấy nó ổn". Chủ đổi được bất cứ lúc nào. |
| Q6 | **Mac trước** (chủ trả lời 2026-11-12: "tôi thử được trên mac trước"). Phần native macOS của S17.2 (đọc `kAXSubroleAttribute` của phần tử đang focus trong `readActiveWindowContext`, báo role chính xác) làm thành việc riêng, chỉ coi là xong khi biên dịch và chạy trên Mac của chủ. Windows để sau. |

Đã làm trong ngày: E1 (hạn mức phiên, `desktop/` + `backend/`) và E2 (gói "Điều khiển máy tính" và công tắc mở mới R3 có hạn 30 ngày, `mobile/`).

## 9. Kết quả S17.1 (2026-11-12)

- **Hợp đồng:** thêm `xuna/preflight` ([XTP §4.2.8](../../architecture/XUNA_XTP_V1_CONTRACT.md)) và 3 frame mẫu vào cả hai `sample_frames.json` (giống nhau từng byte).
- **`xuna_xtp`:** `classifyInputStepRisk` là chỗ duy nhất quyết mức rủi ro của `input.*`, dùng chung cho preflight và lúc thực thi; `verifyPhoneSignedApproval` tách khỏi `evaluateInvocation`; khung `PreflightParams` và `XtpResponse.preflightResult` có kiểm tra chặt.
- **Desktop:** `ComputerUseSessionManager.preflightInputAction` chỉ đọc (không tạo snapshot, không đếm bước, không ghi chữ ký thao tác, không kết thúc phiên); `HostToolDispatcher.preflight`; `XtpSessionClient` trả lời phương thức mới; máy chủ LAN trả "method not found".
- **Lỗi có sẵn được sửa:** trước đây khi mức R3 đến từ màn hình (nhãn thật là "Xóa" nhưng LLM gọi là "Mở"), máy tính bỏ qua chữ ký trên điện thoại và vẫn báo `approval_required`, nên luồng kẹt dù chủ đã ký. Giờ handler đọc `hasVerifiedR3Approval`, tức chữ ký điện thoại đã kiểm, không đọc mức suy từ tham số.
- **Hành vi chặt hơn:** cú bấm mà máy tính không tìm thấy phần tử trên cây thật (ví dụ bấm theo toạ độ qua driver ngoài) giờ là R3; `input.type_text` bị chặn ngay trong `executeInputAction` nếu thiếu duyệt R3, không chỉ dựa vào bộ đánh giá policy.
- **Backend:** `Orchestrator` hỏi preflight cho `input.click`/`input.type_text`/`input.key` trên host Windows/macOS. Lấy mức cao nhất trong ba: mức khai trong manifest, mức host báo, mức suy từ tham số. Host từ chối thì trả lý do cho LLM mà không hỏi chủ. Hộp duyệt hiện nhãn thật của phần tử; nhãn không vào audit. Host cũ trả `-32601` thì dùng cách ước tính cũ; mọi lỗi khác (quá 2 giây, mất kết nối, trả sai định dạng) là R3.
- **Không đổi:** `mobile/` (hộp duyệt hiện nguyên `summary` backend gửi); `workflow.batch_steps` và đường `ComputerUseSessionRunner` chưa đi qua preflight; host Android chưa được hỏi.
- **Thứ tự triển khai:** backend trước hoặc cùng lúc với desktop. Desktop mới với backend cũ thì cú bấm không thấy phần tử sẽ dừng ở `approval_required`.
- **Kiểm chứng (máy Windows):** `xuna_xtp` 35/35; `desktop` 61/61; `backend` 720 passed. Chưa chạy trên máy thật (checklist UDC-16 §4d).

## 10. Kết quả S17.2 (2026-11-12)

- **Gõ nháp (D1), có hiệu lực:** trong phiên, `input.type_text` vào ô văn bản thường (`textfield`, `searchfield`, `searchbox`, `textarea`; không phải ô mật khẩu, không phải `Document` của Windows) chạy không cần ký, tối đa **2.000 ký tự mỗi phiên**. Con số này tôi tự chọn, chủ đổi được. Ngoài điều kiện đó thì vẫn ký R3.
- **Chặn đường gửi lén:** bản nháp có ký tự xuống dòng, hoặc gõ bằng phím thật (`headed`), phải ký vì cả hai có thể tương đương `Enter`. Khi còn bản nháp chưa ký, bấm vào nút không có tên (ví dụ nút Gửi chỉ có icon máy bay giấy) phải ký; sau một bước chốt đã ký thì nút icon lại bấm tự do. Backend thêm `đăng` vào bộ từ khoá (trừ `đăng nhập`/`đăng ký`).
- **Thẻ chốt cho thấy nội dung:** chữ đã gõ từ lần chốt trước (tối đa 5 đoạn) được nối vào thẻ R3 của cú bấm/phím kế tiếp, ví dụ "Nhấp vào 'Gửi' · Đã gõ: 'Lan / Báo cáo xong rồi'". Danh sách xoá khi bước chốt chạy xong, khi hết phiên và khi bấm Dừng khẩn cấp. Không ghi vào audit hay log. Thẻ phiên trực tiếp có nút Dừng vẫn thuộc S17.3.
- **`Enter`/`Space` theo ngữ cảnh (D2), mới có phần Dart:** `Enter` không có phím bổ trợ được hạ R2 khi phần tử đang focus là ô tìm kiếm; `Space` khi focus ở ô văn bản thường. Có phím bổ trợ, hoặc không biết chắc focus, thì R3. Focus được đọc lại lúc thực thi.
- **Vì sao D2 chưa chạy trên máy thật:** macOS chỉ đọc role (ô tìm kiếm và ô mật khẩu đều là `AXTextField`, khác nhau ở subrole); Windows trả tên loại control đã dịch theo ngôn ngữ máy. Cả hai không đủ chắc, nên adapter native báo "không biết" và `Enter`/`Space` vẫn R3. Cần sửa Swift/C++ và chạy trên máy (Q6).
- **Dời chốt:** bộ đánh giá policy giờ chỉ cho mức sàn R2 với `input.type_text`/`input.key`; bộ phân loại trực tiếp (`classifyInputStepRisk`) là cổng duy nhất, chạy trước khi thao tác. Mọi đường gõ/bấm phím của phiên đều đi qua nó (đã rà).
- **Gia cố:** `isPasswordUiNode` phía Dart nhận thêm `secure`, `subrole` và `inputType`, khớp với backend.
- **Backend:** bỏ việc tự nâng `Enter` lên R3 khi host đã trả lời preflight (host quyết); host cũ vẫn giữ luật cũ.
- **Bộ chống chèn lệnh chạy lại** ở desktop (`test/draft_and_activation_injection_test.dart`, đi qua `dispatcher.dispatch`): gõ nháp rồi `Enter`/`Cmd+Enter`/bấm "Gửi" vẫn phải ký; ô mật khẩu bị từ chối dù có ký; gõ vào nút hay `Document` phải ký; hết hạn mức thì phải ký; focus đổi giữa preflight và thực thi thì phải ký; `Document` Windows không được coi là ô văn bản. Bỏ chốt hoặc bỏ kiểm phím bổ trợ thì test báo đỏ.
- **Ảnh hưởng tới quyền:** máy có quyền nhóm `input` chỉ tới R2 giờ cũng gõ nháp được (trước đây cần R3).
- **Giới hạn còn lại:** thẻ chốt chỉ hiện khoảng 150 ký tự đầu của chữ đã gõ (giới hạn 240 ký tự); danh sách mất nếu backend khởi động lại (kho phiên còn trong RAM, P8).
- **Thứ tự triển khai: backend và desktop phải lên cùng lúc.** Desktop S17.2 với backend S17.1 thì nháp vẫn chạy không ký nhưng thẻ chốt không hiện chữ đã gõ.
- **Kiểm chứng (máy Windows):** `xuna_xtp` 36/36; `desktop` 69/69; `backend` 729 passed.

## 11. Kết quả S17.3 (2026-11-12 – 2026-11-13)

- **Thẻ phiên trực tiếp (mobile + backend):** backend gửi sự kiện `cu_session` (SSE và WebSocket giọng nói) sau mỗi bước của phiên, gồm mục tiêu, tên máy, app và tên miền trong phạm vi, bước x/y, số giây còn lại, trạng thái, lý do kết thúc và **toàn bộ** chữ đã gõ từ lần chốt trước (mỗi đoạn tối đa 500 ký tự). `GET /v1/actions/cu-session` trả cùng nội dung sau khi áp hạn mức bước/thời gian, để app tự đọc lại khi mở, khi quay lại app và sau mỗi lượt chat (sự kiện chỉ tới trong lúc có lượt). Thẻ không còn bị xoá khi hết lượt chat, và không giữ cờ "đang chạy" của lượt. Đọc lỗi thì thẻ giữ nguyên. Thẻ không ghi vào audit.
- **Dừng một phiên:** nút **Dừng phiên** gọi `POST /v1/actions/cu-session/{id}/stop`. Backend kết thúc bản ghi của mình trước (hết miễn hỏi R2, xoá chữ đã gõ), rồi gửi `cu.session_end` (`outcome: stopped`) tới máy tính, chờ tối đa 5 giây, và ghi audit `host.cu_session_stopped` chỉ với `hostConfirmed`. Gọi lại thì trả `alreadyEnded`; phiên của chủ khác trả 404. Nút **Dừng khẩn cấp** vẫn nằm trên thẻ và giữ nguyên hành vi cũ.
- **Mở rộng phạm vi (`cu.session_extend`, R3, ký từng lần):** thêm app/tên miền vào phiên đang chạy thay vì mở phiên mới. Máy tính áp đúng các kiểm tra lúc mở phiên (app bị cấm, app không có trên máy, tên miền không hợp lệ), kiểm `sessionId`, và trả danh sách đầy đủ sau khi thêm; backend lấy danh sách đó, không lấy tham số của LLM. Hạn mức bước và thời gian không đổi. Hộp duyệt liệt kê đủ mọi mục thêm vào, **không cắt**: mục dài quá 60 ký tự, hoặc cả câu dài quá 240 ký tự, thì backend từ chối trước khi hỏi chủ (`extend_scope_too_long`, có gợi ý cho LLM thêm ít mục hơn hoặc chia nhiều lần), vì tên miền bị cắt đuôi có thể trông như một trang khác. (Đính chính ở §15: hộp duyệt trên điện thoại khi đó vẫn cắt sau 4 dòng; đã sửa 2026-11-13.) Tên miền không hợp lệ (`localhost`, `.local`, địa chỉ IP, `http://`, có `user@`, tên một nhãn) bị máy tính từ chối dù đã ký, như lúc mở phiên. Giới hạn (tôi tự chọn, chủ đổi được): tối đa 3 app và 3 tên miền mỗi lần, cả phiên tối đa 8 app và 12 tên miền (`session_scope_limit`). Prompt bảo LLM dùng công cụ này thay vì kết thúc rồi mở lại.
- **Từ chối có lối đi (P7):** `action_result` mang thêm `errorCode` và `hostId` khi việc không chạy. Chip lỗi trong chat có nút **"Bật quyền điều khiển màn hình"** (`u5_consent_required`) hoặc **"Mở quyền của máy"** (`grant_denied`, `risk_above_grant`; mở trang Máy tính và tự mở đúng máy). Thiếu quyền hệ thống trên máy tính chỉ hiện chữ "Cần bật quyền trên máy tính". Ô mật khẩu và các lỗi chủ không bật được thì không có nút.
- **Heartbeat (đính chính ở S17.6):** ghi chú này sai một phần, vì app bản chạy thật chưa hề gửi heartbeat (use case chưa được nối vào DI). Đã sửa ở S17.6. Nội dung cũ: công tắc "mất heartbeat 15 giây thì dừng" chỉ được kiểm trong `ComputerUseSessionRunner` (chạy trong một lượt), còn đường `Orchestrator` mà phiên điều khiển hiện dùng **chưa bao giờ kiểm heartbeat**. Đó là lỗ có sẵn từ UDC-8, chưa sửa; phiên vẫn tự hết theo hạn mức bước/thời gian.
- **Sửa thêm:** lối tắt Dừng khẩn cấp trên màn hình chính trước đây báo "đã dừng" mà không gọi backend; giờ gọi `POST /v1/actions/stop` thật và nói rõ khi chưa dừng được.
- **Kiểm chứng (máy Windows):** `xuna_xtp` analyze sạch, 37/37; `desktop` analyze sạch, 73/73 (thêm `test/session_extend_test.dart`); `backend` `ruff check` + `mypy --strict` sạch, `pytest` 739 passed (PostgreSQL; thêm `tests/unit/test_udc17_session_card.py`), mọi file backend đã sửa đúng `ruff format`; `mobile` analyze sạch, `dart format` các file đã sửa, actions/home/hosts 264/264, toàn bộ 500/501 (thêm nhóm UDC-17 S17.3 trong `test/features/actions/actions_test.dart`). Test đỏ duy nhất là `voice_repository_impl_test.dart` "the next sentence is preloaded…", qua 3/3 lần khi chạy riêng: nghi chập chờn do tải, không liên quan S17.3.
- **Chưa kiểm chứng (H8):** chưa chạy với điện thoại và máy tính thật (checklist UDC-16 §4f). Việc trang Máy tính tự mở đúng máy theo `hostId` chưa có test tự động.
- **Giới hạn:** "còn N phút" chỉ cập nhật khi có sự kiện hoặc khi app đọc lại, không đếm ngược từng giây; thẻ và chữ đã gõ mất khi backend khởi động lại (P8). Driver MCP ngoài nhận danh sách app lúc mở phiên nên có thể từ chối app vừa thêm; khi đó thao tác thất bại chứ không chạy sai.
- **Thứ tự triển khai:** backend, desktop và mobile nên lên cùng lúc. App cũ bỏ qua sự kiện `cu_session`; desktop cũ không có `cu.session_extend`, nên với máy đó vẫn phải kết thúc rồi mở phiên mới như trước.

## 12. Kết quả S17.6 (2026-11-13)

- **Kho phiên bền (P8):**
  - Bảng `cu_sessions` (migration `0019`), mỗi chủ chỉ có một phiên chạy, chặn bằng partial unique index. Bộ đếm bước và số lần hỏi tăng bằng `UPDATE … RETURNING`.
  - Chỉ lưu phần không chứa nội dung, cộng `goal` trong lúc phiên chạy (xoá trống khi phiên kết thúc).
  - Cây giao diện và chữ đã gõ chỉ nằm trong RAM. Sau khi khởi động lại, thẻ chốt hiện "Đã gõ N đoạn trước đó, không hiện lại được nội dung" thay vì im lặng.
  - Trên host cũ, cú bấm theo ref mà backend chưa đọc cây là R3.
- **Lỗ có từ S17.2 được vá:** chữ nháp từng bị lưu vào `action_approvals.summary`. Giờ DB lưu `summary` không có chữ nháp; chỉ thẻ gửi điện thoại có.
- **Heartbeat (dead-man switch):**
  - Mobile giờ thật sự gửi heartbeat 5 giây (nối use case vào DI). Heartbeat bị từ chối thì app đọc lại thẻ.
  - Backend kiểm trên đường `Orchestrator`: mất heartbeat 15 giây thì phiên kết thúc, máy tính nhận `cu.session_end`, audit ghi `heartbeat_timeout`.
  - Heartbeat đến muộn không làm phiên sống lại.
  - **Thay đổi hành vi:** app nằm nền hoặc khoá màn hình quá 15 giây thì phiên dừng.
- **"Quên mật khẩu":** ở cả desktop và backend, tên chỉ được xét khi vai trò là ô nhập sửa được (hoặc không rõ vai trò). Tên do LLM khai chỉ chặn thao tác gõ. Ô mật khẩu thật vẫn bị chặn, kể cả khi đã ký.
- **`url.open`:**
  - Máy tính phân giải tên miền. Từ chối nếu có bất kỳ địa chỉ nào không công khai (`url_not_public`: loopback, mạng riêng, link-local, CGNAT, IPv6 ULA, mapped…), hoặc nếu không phân giải được (`url_unresolvable`).
  - Chỉ thu hẹp DNS rebinding chứ không chặn hẳn.
  - Chưa vá: `desktop_skill_runner` vẫn mở URL lấy từ mục tiêu skill mà không qua kiểm này.
- **Bundle ID (macOS, phần Dart):** cửa sổ có Bundle ID khác Bundle ID đã biết của app được phép thì bị từ chối, dù trùng tên hiển thị. Chưa chạy trên Mac.
- **Đo lường (P10):**
  - Audit `host.cu_session_ended` chỉ chứa `reason`, `steps`, `prompts`, `minutes`.
  - Bảng trước/sau đo qua cổng thật của host (`desktop/test/prompt_count_scenarios_test.dart`, cửa sổ giả lập): tổng 13 kịch bản là **26 → 16 lần ký trên macOS**, **26 → 26 trên Windows** (adapter Windows chưa báo role/focus chính xác). Ví dụ "tìm người, soạn tin, gửi" giảm 5 → 2.
- **Kiểm chứng (máy Windows):**
  - backend: `ruff` sạch, `mypy --strict` sạch, `pytest` 750 passed với PostgreSQL. Test mới viết sau lần chạy đầy đủ đã chạy riêng và xanh.
  - desktop: 80/80, analyze sạch. Một lần chạy có 1 test đỏ không xác định được, chạy lại 2 lần đều xanh.
  - `xuna_xtp`: 38/38.
  - mobile: analyze sạch, nhóm UDC-17 8/8.
- **Chưa kiểm chứng:** máy thật (checklist UDC-16 §4g), Mac.

Việc kế tiếp: **S17.4 phần Dart**, rồi **S17.5**.

## 13. Kết quả S17.4 phần Dart/backend (2026-11-13)

- **`ui.find` (mới, chỉ đọc, R2 trong phiên):**
  - Tìm phần tử trong cửa sổ đang mở theo **tên** (chuỗi con, không phân biệt hoa thường) và/hoặc **vai trò** (`button`, `textfield`…; `AXButton` cũng khớp `button`). Trả tối đa `maxResults` ứng viên (1–10, mặc định 5) kèm `ref`, cùng `total`, `truncated` và `searchedNodes`.
  - Không bao giờ tự chọn một ứng viên (H3). Không tìm trong nội dung ô (`value`), để LLM không dò được thứ `ui.inspect` không cho xem. Ô mật khẩu chỉ tìm được theo vai trò, và luôn hiện `•••`.
  - Ứng viên **nhập vào snapshot hiện tại** (chưa có thì tạo), nên `ref` lấy từ `ui.inspect` trước đó vẫn dùng được. Gọi lại cho cùng phần tử thì nhận lại đúng `ref` cũ.
- **`input.*` trả `changes` (khi phiên đã có snapshot):**
  - Gồm `added` (phần tử mới kèm `ref`), `removed` (`ref` không còn dùng được), `changed` (`ref` đổi `enabled`/`visible`) và `truncated`. Mỗi danh sách tối đa 15 mục.
  - Phần tử trong `added` chỉ giữ `ref`, `id`, `role`, `name`, `enabled`, `visible`, `editable`, `isPassword`, `modal` (không có `bounds`, `depth`, `parentId`…). Nếu giữ đủ trường, một `changes` đầy có thể vượt giới hạn 6.144 byte của kết quả công cụ. Khi đó backend chỉ còn gửi `{"truncated": true}`, và LLM mất cả `effect`. Test backend kiểm `changes` đầy và 10 kết quả `ui.find` đều vừa giới hạn.
  - LLM không phải đọc lại cả cây sau mỗi bước. Prompt bảo chỉ gọi lại `ui.inspect` khi `truncated`, khi gặp `windowOutsideSession`, hoặc khi `stale_ref`.
- **Luật giữ `ref` qua một thao tác** (máy tính quyết):
  - Một `ref` chỉ được giữ khi chứng minh được vẫn là cùng phần tử, theo một trong ba cách: cùng định danh native; hoặc tên khác rỗng và cặp vai trò+tên là duy nhất cả trước lẫn sau thao tác; hoặc cùng vị trí khi cấu trúc cửa sổ không đổi chút nào.
  - Theo cách thứ hai, khi số thứ tự native bị xô lệch, `ref` được gắn lại sang số mới. Đây là phần Dart của "ref ổn định".
  - Ngoài ba cách đó thì `ref` bị bỏ và trả `stale_ref`, **không bao giờ trỏ sang phần tử khác**. Ví dụ: nút không tên, hoặc hai nút trùng tên, khi cấu trúc đã đổi.
  - Phiên bản đầu dùng luật "tiền tố cây không đổi" cho nút không tên. Luật này sai khi một nút y hệt chèn lên trước: `ref` cũ trỏ nhầm sang nút mới. Lỗi được phát hiện trước khi viết test và đã siết lại thành "cả cây không đổi".
- **Không lộ cửa sổ ngoài phiên:** nếu sau thao tác một app ngoài phạm vi lên trước, `changes` chỉ còn `windowOutsideSession: true`. `surfaces` cũng không gửi nữa. Trước đây `surfaces` vẫn gửi tiêu đề hộp thoại của cửa sổ đó, kể cả cửa sổ bị cấm.
- **Nới luật chặn lặp `duplicate_action` (chủ duyệt 2026-11-13, phương án b).** Trước đây LLM đọc lại cây sau mỗi bước nên `ref` luôn mới; giờ `ref` giữ nguyên, nên bấm cùng nút hai lần (trang sau, nút "+") có cùng tham số. Máy tính giờ chỉ dừng phiên khi lần trước của đúng thao tác đó trả `no_change`. Vòng lặp vô ích vẫn bị chặn (cùng luật 3 lần `no_change` liền); bước chốt vẫn phải ký; hạn mức 40 bước giữ nguyên. Đường `ComputerUseSessionRunner` ở backend (không phải đường phiên đang dùng) vẫn giữ luật cũ.
- **`ui.inspect` chỉ phần tử tương tác:** `interactiveOnly` đã có từ UDC-8, không làm lại; prompt giờ gợi ý dùng nó.
- **Backend:**
  - `ui.find` đứng ngay sau `ui.inspect` trong thứ tự danh mục. Hệ quả: một công cụ ưu tiên thấp ở cuối danh sách gửi thẳng chuyển sang nhóm tìm qua `tool_search`; vẫn gọi được.
  - Kết quả `ui.find` (`matches`) và `changes.added` được che mật khẩu thêm một lần ở backend, rồi đưa vào bộ nhớ đệm nút của phiên. `ref` trong `changes.removed` bị xoá khỏi bộ nhớ đệm.
  - Hộp duyệt và tóm tắt của `ui.find` không chứa chữ LLM tìm.
  - Gợi ý khi gặp `stale_ref` nhắc thêm `ui__find`.
- **Chưa làm (cần máy thật):** `ref` theo định danh thật của hệ điều hành (UIA RuntimeId trên Windows, định danh AX trên Mac). Phần Dart đã đọc `nativeId` nếu adapter gửi, nhưng adapter native hiện chưa gửi. Theo Q6, làm Mac trước, và chỉ coi là xong khi biên dịch và chạy trên Mac của chủ. Khi có, nút không tên và nút trùng tên cũng giữ được `ref` qua thao tác.
- **Giới hạn:** adapter native chỉ trả tối đa 60 phần tử (`nativeActionableNodeCap`), nên `ui.find` chỉ tìm trong 60 phần tử đó. `searchedNodes` cho LLM biết con số này.
- **Kiểm chứng (máy Windows):**
  - `xuna_xtp`: analyze sạch, 43/43 (thêm nhóm `UDC-17 S17.4 ui.find`).
  - `desktop`: analyze sạch, 89/89 (thêm `test/ui_find_and_changes_test.dart`, đi qua `dispatcher.dispatch`). Kiểm đột biến: bỏ việc gắn lại `ref` thì 2 test đỏ; nới luật vị trí về "chỉ cần cùng id" thì 1 test đỏ; bỏ việc nới luật chặn lặp thì 2 test đỏ.
  - `backend`: `ruff check` và `mypy --strict` sạch; thêm `tests/unit/test_udc17_ui_find.py`. `pytest` với PostgreSQL: lần cuối **762 passed**. Một lần trước đó có 1 test hội thoại đỏ (`test_conversation_api.py::test_only_own_pet_and_nothing_is_stored`); chạy riêng qua 12/12 và hai lần chạy toàn bộ sau đều qua, nên coi là chập chờn.
  - `ruff format --check` toàn repo vẫn báo 31 file chưa format, đều có từ trước và không do đợt này sửa.
- **Chưa kiểm chứng (H8):** chưa chạy trên máy thật (checklist UDC-16 §4h); chưa thử với model thật xem LLM có dùng `ui.find` và `changes` như prompt hướng dẫn không.
- **Thứ tự triển khai:**
  - Backend cũ với desktop mới: `ui.find` vẫn chạy, nhưng backend cũ không che lại `matches`; host đã che sẵn.
  - Desktop cũ: không có `ui.find` và không trả `changes`; mọi thứ như trước.

Việc kế tiếp: **S17.5** (mẫu chạy lại, gợi ý duyệt trước). Phần native của S17.2 và S17.4 chờ chạy trên Mac.

## 14. Kết quả S17.5 (2026-11-13)

### Phần 1: gợi ý duyệt trước (đã làm)

- **Hành vi:**
  - Thẻ duyệt R2 đã có nút "Luôn cho phép việc này (7 ngày)" khi việc đó đủ điều kiện duyệt trước (ADR-0014 D1).
  - Nếu **đúng việc đó** (cùng máy, cùng công cụ, cùng tham số) đã được duyệt từ **3 lần** trở lên trong **30 ngày** qua, backend gửi kèm số lần (`standing.approvedCount`). App hiện câu "Việc này đã được duyệt N lần trong 30 ngày qua…" và làm nổi nút đó.
  - Không tự bật gì; chủ vẫn phải bấm và ký bằng khoá điện thoại như trước.
- **Đếm gì:** mọi bản ghi duyệt ở trạng thái `approved` của đúng việc đó trong cửa sổ, kể cả lần chạy nhờ duyệt 15 phút hay nhờ duyệt trước cũ. Vì vậy câu chữ là "đã được duyệt", không phải "bạn đã bấm". Phân biệt từng nguồn duyệt cần thêm cột mới; tôi thấy không đáng.
- **Điều kiện không đổi:** chỉ việc R2, không đọc màn hình, không thuộc nhóm `cu`/`ui`/`input`/`screen`, tham số không phải chữ tự do. Không đủ điều kiện thì không có số đếm, dù đã duyệt bao nhiêu lần.
- **Con số tôi tự chọn** (chủ đổi được): 3 lần, 30 ngày (`STANDING_SUGGEST_MIN_APPROVALS`, `STANDING_SUGGEST_WINDOW`).
- **Code:**
  - Backend: `ApprovalRepository.count_approved` (bản SQL và bản trong RAM); `ActionPendingEvent.standing_approved_count` và `standing_payload()` dùng chung cho SSE lẫn WebSocket giọng nói.
  - Mobile: `PendingAction.standingApprovedCount` và `suggestsStanding`; mapper chỉ nhận số nguyên dương đi kèm lời mời; câu gợi ý trên thẻ duyệt (khoá `actions_approveAlwaysSuggested`, vi/en).
- **Kiểm chứng (máy Windows):**
  - Backend: ruff và mypy sạch; thêm `tests/modules/actions/test_standing_suggestion.py` và `test_approval_count_postgres.py` (PostgreSQL), đều qua; toàn bộ không DB 688 passed.
  - Mobile: analyze sạch; toàn bộ `flutter test` 504/504 (thêm test mapper, entity và widget trong `standing_approval_test.dart`).
- **Chưa kiểm chứng:** điện thoại thật (checklist UDC-16 §4i).

### Phần 2: mẫu chạy lại (đã làm)

- **Không dùng lại cơ chế workflow dạy được của UDC-12** như §3D dự tính. Lý do:
  - Kho của nó chỉ nằm trong RAM, và bản chạy thật không có đường nào lưu vào đó.
  - Bước của nó bị giới hạn dưới R3, trong khi mở phiên (`cu.session_start`) luôn là R3. Nới giới hạn này không được, vì workflow đó chạy được từ nút trên board, mà UDC-T15 cấm R3 từ board.
  - Đây là quyết định của người làm; chủ đổi lại được.
- **Nơi lưu (chủ chọn 2026-11-13: "Trên điện thoại"):**
  - Mẫu chỉ nằm trong app (Hive, khoá `xuna_cu_templates_v1`), tách theo tài khoản đang đăng nhập; server không giữ gì mới.
  - Ngoại lệ với quy tắc "app không lưu chữ hội thoại" được ghi vào `mobile/AGENTS.md` §4.4 và §6.4.
  - Đổi điện thoại thì mất mẫu.
- **Lưu:**
  - Khi XUNA kết thúc phiên với `outcome: completed`, khung chat hiện thẻ mời lưu thành mẫu. Câu chữ nói rõ đây là lời XUNA tự báo đã xong, không phải kết quả đã kiểm.
  - Chủ sửa hoặc xác nhận tên mẫu và mục tiêu rồi bấm Lưu.
  - Phạm vi (máy, app, tên miền, số bước, số phút) lấy từ thẻ phiên do backend gửi, không nhập tay.
  - Backend xoá mục tiêu khi phiên kết thúc, nên app nhớ mục tiêu cuối cùng của từng phiên để điền sẵn.
  - Mỗi phiên chỉ được mời lưu một lần. Mỗi tài khoản giữ tối đa 20 mẫu.
- **Xem, xoá, chạy lại:**
  - Nút "Mẫu đã lưu (N)" trong khung chat mở danh sách. "Xoá" hỏi xác nhận trước.
  - "Chạy lại" bị tắt khi đang có phiên chạy, đang chờ duyệt hay đang thực thi, vì một lần mở phiên mới sẽ thay phiên đang chạy.
  - Chạy lại gửi một lượt chat (đường SSE) với nội dung là mục tiêu, kèm `cuTemplate` (tên, `hostId`, app, tên miền, số bước, số phút).
- **Backend ghim lượt đó:**
  - `cu.session_start` của lượt đó phải chạy trên đúng máy của mẫu, cùng tập app và tập tên miền (chuẩn hoá chữ thường, bỏ dấu chấm cuối), số bước và số phút không vượt mẫu.
  - Lệch thì bị từ chối trước khi hỏi chủ, với `template_mismatch`, `mismatch` (`host`/`apps`/`domains`/`budget`), `expected`, và gợi ý cho LLM.
  - Không ghim chữ mục tiêu, vì LLM có thể diễn đạt lại; chủ đọc thẻ duyệt rồi ký.
  - Khớp thì vẫn phải ký R3 trên điện thoại. Thẻ duyệt thêm "Chạy lại mẫu '…':" ở đầu, chỉ khi cả thẻ vẫn vừa 240 ký tự. Bản ghi duyệt trong DB không chứa tên mẫu.
  - Ghim chỉ áp cho lượt đó và chỉ cho `cu.session_start`; `cu.session_extend` vẫn ký riêng từng lần.
  - `cuTemplate` được kiểm như tham số mở phiên: tối đa 8 app và 12 tên miền, 40 bước, 20 phút; tên mẫu tối đa 40 ký tự, không có ký tự điều khiển.
- **Code:**
  - Backend: `actions/application/cu_template.py` (`CuTemplatePin`); `ActionContext.cu_template`; `TurnBody.cuTemplate` (`CuTemplateBody`); kiểm khớp trong `Orchestrator`; `ActionSummary.with_template_name`; gợi ý `template_mismatch` trong `prompts.py`.
  - Mobile, tầng domain: `CuSessionTemplate`, `CuTemplateRepository`, `CuTemplateException`, use case Save/List/Delete.
  - Mobile, tầng data: model kiểm từng trường (mục hỏng bị bỏ khi đọc), nguồn Hive, repository.
  - Mobile, presentation: `ComputerUseProgress.maxMinutes`, `reportedCompleted`, `withGoal`; trạng thái và thao tác trong `HomeActionsService`/`HomeController`; `CloudTurnContext.cuTemplate`; widget `HomeCuTemplateSaveCard`, `HomeCuTemplatesCard`; 20 khoá locale vi/en.
  - Ô nhập kiểu XUNA tách thành base widget `AppTextInput` (quy tắc mobile §5.4); trang quản lý kiến thức dùng lại `AppTextInput.decoration`.
- **Thứ tự triển khai: backend phải lên trước app.** `TurnBody` chặn trường lạ (`extra="forbid"`), nên app mới gửi `cuTemplate` tới backend cũ sẽ bị từ chối cả lượt khi bấm "Chạy lại". Các lượt chat khác không bị ảnh hưởng.
- **Kiểm chứng (máy Windows):**
  - Backend: ruff và mypy sạch; `tests/unit/test_udc17_cu_template.py` 26 test, có một test chứng minh backend gửi sự kiện `ended` + `completed` mà app dựa vào để mời lưu. Tắt việc kiểm khớp thì 7 test đỏ. Toàn bộ với PostgreSQL 793 passed (trước khi thêm test cuối).
  - Mobile: analyze sạch; `test/features/actions/cu_template_test.dart` 15 test, cộng 1 test controller (xoá phải xác nhận, chạy lại bị chặn khi đang có phiên); toàn bộ 520/520.
- **Chưa kiểm chứng:** điện thoại và máy tính thật (checklist UDC-16 §4j); model thật có gọi `cu.session_start` đúng phạm vi ngay lần đầu, hay phải thử lại sau `template_mismatch`.
- **Báo trước phạm vi cho LLM (chủ chọn 2026-11-13, phương án b):**
  - Lượt chạy lại có thêm một dòng trong system prompt, chỉ cho lượt đó và chỉ khi có công cụ. Dòng này nêu tên mẫu, máy, app, tên miền, số bước và số phút tối đa (`CuTemplatePin.prompt_note`, `build_request(turn_note=…)`).
  - Mục đích: lần gọi `cu.session_start` đầu khớp luôn, không phải bị từ chối một lần rồi gọi lại.
  - Tên máy do backend đọc theo `hostId`, chỉ khi máy đó thuộc đúng chủ; nếu không, dòng đó nói máy không còn được ghép.
  - Việc kiểm khớp vẫn giữ nguyên; dòng này chỉ là hướng dẫn, không phải hàng rào.
  - Kiểm chứng: `tests/modules/actions/test_cu_template_turn.py` (3 test, có một test qua API). Bỏ việc truyền dòng này thì test báo đỏ. Backend toàn bộ với PostgreSQL 797 passed.
- **Lỗ có sẵn phát hiện khi làm:** thẻ duyệt của `cu.session_start` chỉ hiện tối đa 4 app và **không hiện tên miền**, nên chủ ký một phạm vi không thấy đủ. **Đã sửa 2026-11-13, xem §15.**

## 15. Kết quả: thẻ mở phiên hiện đủ phạm vi (S17.5 bổ sung, 2026-11-13)

Chủ chọn phương án a ("liệt kê đủ, không cắt; không vừa thì từ chối trước khi hỏi"), giống cách `cu.session_extend` làm ở S17.3.

- **Thẻ mới (`cu.session_start`, VI/EN):**
  - Mẫu thẻ: "Bắt đầu phiên điều khiển '<mục tiêu>' trên <máy>: app <mọi app>; tên miền <mọi tên miền hoặc "không có">; tối đa N bước/M phút".
  - App và tên miền nằm dưới nhãn riêng, không cắt mục nào. Bỏ giới hạn cũ "4 app đầu, mỗi app 24 ký tự".
  - Chỉ mục tiêu (lời LLM diễn đạt lại, không phải phạm vi) bị rút còn 60 ký tự, và có dấu "…" khi bị rút. Trước đây nó bị cắt không báo.
  - Chuỗi thẻ và việc kiểm độ dài dùng chung một hàm (`_session_start_text`), nên không thể lệch nhau. Thẻ `extend` cũng chuyển sang kiểu này (`_extend_text`).
- **Từ chối trước khi hỏi:**
  - Nếu một app hoặc tên miền dài quá 60 ký tự, hoặc cả thẻ quá 240 ký tự, backend từ chối với `start_scope_too_long` (`ActionSummary.start_scope_fits_card`). Không ai bị hỏi, máy tính không nhận lệnh, audit ghi `HOST_TOOL_DENIED` với lý do `start_scope_too_long`.
  - Gợi ý cho LLM: mở phiên với ít mục hơn hoặc mục ngắn hơn, hoặc mục tiêu ngắn hơn, rồi thêm phần còn lại bằng `cu__session_extend`.
  - Hằng số `MAX_EXTEND_ITEM_DISPLAY_CHARS` đổi tên thành `MAX_SCOPE_ITEM_DISPLAY_CHARS` (dùng cho cả hai công cụ).
- **Lượt chạy lại mẫu:**
  - Kiểm khớp mẫu (`template_mismatch`) vẫn chạy trước. Tiền tố "Chạy lại mẫu '…':" vẫn chỉ thêm khi cả thẻ còn vừa 240 ký tự; giờ phần gốc luôn vừa, nên tiền tố không bao giờ đẩy phạm vi ra khỏi thẻ.
  - Phạm vi của mẫu lấy từ thẻ phiên sau các lần mở rộng (tối đa 8 app, 12 tên miền), nên một mẫu lớn có thể không vừa thẻ mở phiên. Khi đó lời từ chối có thêm `templatePinned: true`, và gợi ý bảo LLM **không thử lại** mà báo chủ. Nếu thiếu cờ này, LLM sẽ bớt mục rồi đụng `template_mismatch`, thành vòng lặp.
  - Hệ quả: mẫu có phạm vi quá lớn **không chạy lại được**. Chủ chọn chặn ngay từ lúc lưu (phương án a), xem §16.
- **Điện thoại (`mobile/`):**
  - Hộp duyệt trước đây đặt `maxLines: 4`, mà `AppTextStyle` có sẵn `ellipsis`. Thẻ 240 ký tự trên màn hẹp cần khoảng 7–8 dòng, nên bị cắt kèm "…" sau dòng 4. Lỗi này ảnh hưởng cả thẻ `cu.session_extend` của S17.3, nên ghi chú "liệt kê đủ" ở §11 trước đây chưa đúng trên điện thoại.
  - Giờ phần tóm tắt không giới hạn dòng (`overflow: TextOverflow.visible`, `summaryKey`). Backend giữ thẻ trong 240 ký tự.
- **Kiểm chứng (máy Windows):**
  - Backend:
    - `ruff check` và `mypy --strict` sạch. 4 file đã sửa đúng `ruff format`, chỉ kiểm bằng `--diff`, không chạy format trên thư mục.
    - Thêm `tests/unit/test_udc17_start_card.py` (11 test): thẻ có đủ app và tên miền (VI, EN, và qua orchestrator); không có tên miền thì ghi rõ; chỉ mục tiêu bị rút; thẻ đúng 240 ký tự được hỏi, 241 bị từ chối; quá dài thì bị từ chối, không ai bị hỏi, máy tính không nhận lệnh; mẫu gần đầy thì bỏ tiền tố; mẫu quá lớn thì có `templatePinned` và gợi ý không thử lại.
    - Toàn bộ với PostgreSQL: **808 passed**.
  - Kiểm đột biến backend (6 cái, script tự khôi phục file và kiểm md5): đưa lại `[:4]` (4 test đỏ), bỏ tên miền khỏi thẻ (6), đổi `<=` thành `<` (2), bỏ kiểm từng mục 60 ký tự (1), bỏ kiểm ở orchestrator (3), bỏ `templatePinned` (1).
  - Mobile:
    - Thêm test widget trong `test/features/actions/standing_approval_test.dart`: thẻ 240 ký tự trên màn 320 px hiện đủ chữ, không vượt số dòng, và thật sự cần hơn 4 dòng.
    - Kiểm đột biến: đặt lại `maxLines: 4`, hoặc bỏ `overflow` (khi đó `ellipsis` của `AppTextStyle` cắt còn 1 dòng), thì test đỏ.
    - analyze sạch, **521/521**, `pubspec.lock` không đổi. `dart format` chỉ chạy trên 2 file đã sửa, không file nào đổi.
- **Chưa kiểm chứng (H8):** chưa chạy trên điện thoại và máy tính thật (checklist UDC-16 §4k); chưa thử với model thật xem LLM có theo gợi ý `start_scope_too_long` không.
- **Bố cục trên màn nhỏ (đo bằng test tạm, đã xoá; chưa có test cố định):**
  - Trong tab chat, thẻ duyệt nằm trong một Column không cuộn được, giữa danh sách tin nhắn và ô soạn tin. Thẻ không cắt thì cao hơn, nên trên màn thấp (hoặc khi bàn phím đang mở, cỡ chữ lớn) nút Đồng ý/Từ chối có thể bị đẩy khỏi màn hình.
  - Đo ở bề rộng 320 px với phông giả lập của test (mỗi ký tự là ô vuông 16 px, nên phóng đại nhiều so với máy thật). Chiều cao tối thiểu để không tràn: thẻ ngắn 780 px (cả bản cũ lẫn mới, tức là lỗi có sẵn); thẻ 240 ký tự 820 px với bản cũ, 1090 px với bản mới.
  - Đã chọn giữ bản không cắt, vì nó hỏng theo hướng đóng: nếu nút bị đẩy ra ngoài thì chủ không ký được, chứ không ký khi chưa thấy hết. Chủ chọn sửa tận gốc (vùng dưới của tab chat cuộn được, phương án a), xem §16.
- **Ghi nhận thêm:**
  - Chip kết quả trong chat (`format_result`, thêm "✓ Đã thực hiện:") có thể cắt thẻ mở phiên dài. Đây không phải chỗ ký, nên để nguyên.
  - Lệnh `flutter pub get` gọi tường minh nâng hai gói phụ thuộc gián tiếp trong `pubspec.lock` (`characters` 1.4.0→1.4.1, `intl` 0.20.2→0.20.3) dù SDK đúng là 3.47.9. `flutter test` thì không đổi lock. Đã khôi phục lock về HEAD; chưa tìm nguyên nhân.
- **Thứ tự triển khai:** backend và app độc lập nhau. Backend mới với app cũ: thẻ đủ nhưng điện thoại vẫn cắt sau 4 dòng. App mới với backend cũ: không có gì thay đổi.
- **Chưa commit.**

## 16. Kết quả: chặn lưu mẫu quá lớn, vùng dưới khung chat cuộn được (2026-11-13)

Chủ trả lời "xử lý đi" cho hai lựa chọn ở báo cáo §15. Tôi hiểu là làm theo hai khuyến nghị: 1a (báo cho app lúc mời lưu) và 2a (vùng dưới khung chat cuộn được).

- **1a: không lưu mẫu không chạy lại được.**
  - Backend: `ActionSummary.rerun_scope_fits_card` kiểm thẻ `cu.session_start` của phạm vi đó với **mục tiêu dài nhất thẻ hiện (60 ký tự)** và phải vừa **cả VI lẫn EN**. Lý do: mục tiêu của lượt chạy lại do LLM diễn đạt lại, và ngôn ngữ có thể khác.
  - Mọi sự kiện `cu_session` (SSE, WebSocket, `GET /cu-session`) mang `rerunFitsCard`.
  - Mobile: `ComputerUseProgress.rerunFitsCard` và `rerunnable`. Mapper chỉ nhận giá trị kiểu bool; giá trị khác hoặc thiếu thì coi là `null`.
  - `SaveCuTemplateUseCase` từ chối với loại lỗi mới `scopeTooLarge`. Thẻ mời lưu khi đó bỏ ô nhập và nút Lưu, chỉ còn câu giải thích (khoá `actions_cuTemplateTooLarge`, vi/en) và nút Bỏ qua.
  - Backend cũ không gửi cờ (`null`), nên app vẫn cho lưu như trước. Lúc chạy lại, backend mới vẫn từ chối đúng lý do (`templatePinned`).
  - Giới hạn: kiểm theo tên máy lúc phiên kết thúc. Nếu chủ đổi tên máy dài hơn sau đó, một mẫu đã lưu có thể không còn vừa; khi đó lần chạy lại bị từ chối với `start_scope_too_long` + `templatePinned`, không có gì chạy sai.
- **2a: vùng dưới khung chat cuộn được.**
  - `HomeChatTab` dùng `CustomMultiChildLayout` (`_ChatTabLayout`) thay cho `Column`:
    - Đầu trang và ô soạn tin giữ chiều cao thật.
    - Vùng dưới (thẻ mời lưu, danh sách mẫu, thẻ phiên, thẻ duyệt, thanh dừng) được phần còn lại, và cuộn trong `SingleChildScrollView` (`panelKey`) khi không đủ chỗ.
    - Danh sách tin nhắn lấy phần còn lại, có thể bằng 0. Khi đủ chỗ và không có thẻ duyệt, mọi thứ nằm như trước.
  - Phần trang trí (tiêu đề "Trò chuyện", hình XUNA, hai dòng ghi chú) ẩn khi đang có thẻ duyệt, hoặc khi tab thấp hơn 560 px (`_heroMinTabHeight`, ví dụ khi bàn phím mở). Nút quay lại và menu vẫn còn. Phạm vi thật: trên hầu hết điện thoại, tab thấp hơn 560 px **mỗi khi bàn phím mở**, nên phần này ẩn mỗi lần chủ gõ chat; nó cũng ẩn với mọi thẻ duyệt (cả R2), kể cả khi màn hình rộng. **Chủ duyệt giữ nguyên (2026-11-13, phương án a: "a")**; hai phương án không chọn là chỉ ẩn khi có thẻ duyệt, hoặc không bao giờ ẩn.
  - Thứ tự trong vùng dưới giữ nguyên. Khi thiếu chỗ, vùng dưới bắt đầu từ đầu (thấy đầu thẻ trước, nút ở cuối); chủ phải kéo xuống mới tới nút Đồng ý. Nếu có nhiều thẻ phía trên (mẫu, thẻ phiên), thẻ duyệt có thể nằm dưới cùng phần cuộn.
- **Kiểm chứng (máy Windows):**
  - Backend:
    - `ruff check`, `mypy --strict` sạch; các file đã sửa đúng `ruff format`.
    - `test_udc17_start_card.py` thêm 3 test. Một test chứng minh `rerunFitsCard` khớp với việc lần chạy lại thật bị nhận hay từ chối, ở cả VI và EN. Một test chứng minh phạm vi vừa với mục tiêu ngắn nhưng không vừa với mục tiêu 60 ký tự thì bị coi là không vừa.
    - Toàn bộ với PostgreSQL: **811 passed**.
  - Mobile:
    - analyze sạch, **525/525**, `pubspec.lock` không đổi; 10 file đã sửa đều đúng `dart format`.
    - Thêm test use case, mapper và thẻ mời lưu (`cu_template_test.dart`).
    - Thêm `test/features/home/presentation/widgets/home_chat_tab_layout_test.dart`. Test 1: tab cao 308 px (máy 320×568, bàn phím khoảng 260 px) với thẻ duyệt 240 ký tự và thẻ phiên. Test khẳng định không tràn, thẻ đủ chữ, vùng dưới thật sự phải cuộn, và chủ kéo tới được nút Đồng ý rồi bấm được. Test 2: phần trang trí ẩn khi có thẻ duyệt hoặc khi tab thấp.
  - Kiểm đột biến (8 cái; script khôi phục file theo byte và kiểm md5). Bị bắt hết:
    - Quay về bố cục `Column` cũ.
    - Khoá cuộn vùng dưới. Ban đầu test **không** bắt được, vì `scrollUntilVisible` dừng ngay khi nút đã có trong cây widget. Đã siết test bằng kéo tay và kiểm nút nằm trong vùng nhìn thấy; sau đó bắt được.
    - Hiện phần trang trí khi đang có thẻ duyệt.
    - Bỏ kiểm ở use case, mapper bỏ cờ, thẻ mời lưu bỏ cờ.
    - Backend kiểm với mục tiêu rỗng, backend không gửi cờ.
- **Chưa kiểm chứng (H8):** điện thoại thật (checklist UDC-16 §4k), cỡ chữ hệ thống lớn, bàn phím thật. Phông trong test là phông giả lập, nên số dòng thật trên máy sẽ ít hơn.
- **Thứ tự triển khai:** backend và app độc lập. App mới với backend cũ: không có cờ nên lưu như trước. Backend mới với app cũ: app cũ bỏ qua trường lạ `rerunFitsCard`, vì mapper đọc từng trường.
- **Chưa commit.**

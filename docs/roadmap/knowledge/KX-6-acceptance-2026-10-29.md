# KX-6 — Nghiệm thu M06 Knowledge Expert (2026-10-29)

> **Trạng thái:** Host acceptance **PASS** (Backend `402/402` pytest PASS, Mobile `329/329` flutter test PASS, Firmware `test_knowledge` PASS). Nghiệm thu thực địa trên board ESP32-S3, điện thoại và AI provider thật đang chờ phiên kết nối phần cứng của owner.
> **Kế hoạch gốc:** [knowledge-expert-plan-2026-10-29.md](knowledge-expert-plan-2026-10-29.md) §10 (thay thế KD-6 của [knowledge-domains-plan-2026-10-27.md](knowledge-domains-plan-2026-10-27.md)).
> **Tài liệu liên quan:** [ADR-0011](../../decisions/ADR-0011-owner-knowledge-documents.md) (Tài liệu tham khảo của chủ & U4 `owner_documents`).

---

## 1. Bảng đối chiếu 6 tiêu chí nghiệm thu KX-6 (§10)

| # | Tiêu chí nghiệm thu (§10 KX-6) | Bằng chứng tự động trên máy chủ / host (2026-10-29) | Trạng thái trên Host | Trạng thái trên Board + Điện thoại + Provider thật |
|---|---|---|---|---|
| **1** | **Hai domain (`embedded` từ pack, một domain tự đặt).** Cùng một câu hỏi chuyên môn: `detail` có cấu trúc Markdown đúng; `say` ≤ 200 ký tự, đọc tự nhiên | - **Backend (`test_kx6_acceptance.py`):** Tạo domain 1 từ pack `embedded` (sao chép `expert_brief` chuẩn kỹ sư nhúng, `deviceSlot=0`) và domain 2 tự đặt `Nhà thông minh` (`deviceSlot=1`, gán `expertBrief` riêng). Cùng câu hỏi *"Tại sao cảm biến nhiệt độ I2C thỉnh thoảng bị treo bus?"* ở chế độ `auto`: cả hai đều định tuyến sang `expert` (`reason="domain_task"`), system prompt nạp đúng `expert_brief` của từng domain, phần `say` (`delta`) dài 115 ký tự (`<= 200`), không chứa Markdown, phần `detail` chứa Markdown có cấu trúc (`## Nguyên nhân gốc`, `## Các bước kiểm tra`, khối code `c`) và đến trước `finished`.<br>- **Mobile (`kx6_acceptance_test.dart`):** Tạo 2 domain (`embedded` pack + `Nhà thông minh`), chọn domain khi chat, nhận `CloudReplyMode(expert)` + `say` + `detail`, hiển thị thẻ xem trước Markdown và mở `HomeReplyDetailSheet`. | **PASS** | **Pending** (chạy `backend/scripts/expert_eval.py` khi có khóa AI provider thật) |
| **2** | **Voice với câu hỏi chuyên sâu:** TTS chỉ đọc `say`; p50 thời gian đến âm thanh đầu tiên; board không bao giờ hiện Markdown | - **Backend (`test_kx6_acceptance.py` & `test_voice_websocket.py`):** Qua `/v1/voice` WebSocket (`mode="auto"`, câu hỏi chuyên môn thuộc domain `embedded`), server phát `turn.mode` (`mode="expert"`), tách `reply.delta` (`say`) và `detail.delta` (Markdown). Bộ tổng hợp TTS (`synthesizer.texts`) **chỉ nhận câu `say` ngắn**, không bao giờ nhận nội dung `detail` Markdown.<br>- **Mobile (`kx6_acceptance_test.dart` & `home_controller_test.dart`):** Tất cả khung phụ đề gửi xuống BLE (`transport.boardTexts`) chỉ chứa câu phụ đề đang suy nghĩ (`Để mình xem kỹ nhé…`) và phần `say`, tuyệt đối không chứa `##` hay khối code ```` ``` ````. | **PASS** | **Pending** (đo p50 time-to-first-audio trên điện thoại thật với provider thật) |
| **3** | **Level 0 → 2 qua quy ước và case trong ≥ 3 ngày.** Ở level 2, prompt thực sự làm XUNA áp quy ước mà không cần nhắc | - **Firmware (`test_knowledge`):** Kiểm chứng máy trạng thái `KnowledgeProfile` tăng mức `Level0` (Mới quen) → `Level1` (Bắt nhịp: `>= 3` kinh nghiệm, `>= 1` ngày) → `Level2` (Ăn ý: `>= 10` kinh nghiệm, `>= 3` ngày) → `Level3` (Đồng đội: `>= 25` kinh nghiệm, `>= 5` ngày) và ghi `KnowledgeJournalEntry`.<br>- **Backend (`test_kx6_acceptance.py`):** Khi thiết bị báo `level=0`, prompt gắn hướng dẫn *"(độ ăn ý: Mới quen). Khi câu trả lời phụ thuộc vào bối cảnh riêng của bạn ấy... hãy hỏi lại một câu ngắn thay vì đoán"*. Sau khi chủ dạy quy ước (`kind="convention": ESP-IDF 5.2, driver i2c_master mới`), chốt việc đã giải quyết (`kind="case"`) và nạp tài liệu U4 (`kind="document": Sơ đồ chân Board V2.md`), khi thiết bị báo `level=2`, prompt tự động chuyển sang *"Độ ăn ý của bạn với bạn ấy trong lĩnh vực này: Ăn ý. Chủ động áp dụng quy ước của bạn ấy và nhắc lại cách đã làm trong các việc trước khi phù hợp"* kèm toàn bộ quy ước, case và trích đoạn tài liệu có gắn nguồn `[Sơ đồ chân Board V2.md]`. | **PASS** | **Pending** (thử trên board vật lý + điện thoại) |
| **4** | **Offline:** level vẫn hiện, chat dùng template cục bộ | - **Mobile (`kx6_acceptance_test.dart` & `home_controller_test.dart`):** Khi mất kết nối tài khoản/mạng (`account.value = null`, `cloudChatReady == false`), dữ liệu `knowledgeProfile` đọc từ thiết bị qua BLE (`7a6e000f`) vẫn giữ nguyên trạng thái ô và số kinh nghiệm; gửi câu hỏi chat tự động trả lời bằng template cục bộ (`LocaleKeys.home_replyUnknown.tr`, `generated: false`). | **PASS** | **Pending** (thử tắt Wi-Fi/4G trên điện thoại thật) |
| **5** | **Xoá case → level giảm đúng** và biến mất khỏi bối cảnh prompt | - **Firmware (`test_knowledge`) & Mobile (`kx6_acceptance_test.dart`):** Gỡ bằng chứng (`removeKnowledgeEvidence`, opcode 10 sub-op 6) hoặc xoá lĩnh vực (`keepKnowledge: false`) làm giảm `factCount` và hạ `level` về mức tương ứng theo ngưỡng `F = {3, 10, 25}`, đồng thời ghi nhật ký nguyên nhân hạ mức (`reason = 2`).<br>- **Backend (`test_kx6_acceptance.py`):** Xoá candidate case đã xác nhận (`PATCH /v1/memory-candidates/{id}` với `action="delete"` hoặc `DELETE` kèm tombstone) lập tức loại bỏ case đó khỏi `OwnerContext.cases` ở các lượt hội thoại tiếp theo. | **PASS** | **Pending** (thử trên board vật lý) |
| **6** | **App cũ (bản trước KX-2) vẫn chat được với backend mới** | - **Backend (`test_kx6_acceptance.py` & `test_conversation_api.py`):** Khi request `POST /v1/conversations/{petId}/turns` không gửi trường `mode`, `domainId` hay `knowledge`:<br>  1. Backend xử lý ở chế độ `chat` (`reason="legacy_client"`), giới hạn `max_output_tokens = 400`, kiểm tra độ dài đầu vào `<= 500` ký tự (`422` nếu vượt).<br>  2. Luồng SSE **không** phát sự kiện `mode` hay `detail`, chỉ phát `delta` và `finished` tương thích 100% với app trước KX-2. | **PASS** | **Validated on Host** |

---

## 2. Phát hiện và sửa lỗi trong quá trình nghiệm thu KX-6

1. **Lỗi giải mã `UUID` nghiêm ngặt (`strict=True`) trong Pydantic khi nhận chuỗi JSON qua HTTP (`schemas.py`):**
   - **Hiện tượng:** Trong `TeachKnowledgeRequest`, `ProposeKnowledgeCaseRequest`, `UploadDocumentRequest` (`modules/knowledge/application/schemas.py`) và `CreateCandidateRequest`, `PatchCandidateRequest` (`modules/memory/application/schemas.py`), cấu hình `ConfigDict(..., strict=True)` khiến FastAPI (vốn parse body JSON thành `dict` trước rồi gọi `model_validate` ở chế độ Python) từ chối giá trị chuỗi UUID của `domainId` / `relatedCandidateId` với lỗi `422 Unprocessable Entity` (trong khi các unit test trước đó hoặc truyền `domainId=None` qua HTTP hoặc khởi tạo model trực tiếp bằng đối tượng `uuid.UUID` trong Python).
   - **Khắc phục:** Đặt `strict=False` trên các trường `uuid.UUID | None` (`domain_id`, `domainId`, `relatedCandidateId`), giữ nguyên `strict=True` cho tất cả các trường còn lại và kiểm chứng bằng bài test tích hợp HTTP đầu-cuối `test_kx6_full_acceptance_matrix`.
2. **Tách Coordinator Services khỏi `HomeController` (`mobile/`):**
   - Tách `HomeController` (2.775 dòng) thành 5 service chuyên biệt (`HomeKnowledgeService`, `HomeMemoryCandidateService`, `HomeCloudAccountService`, `HomeDeviceService`, `HomeVoiceService`), giữ nguyên 100% API công khai và vượt qua toàn bộ 329 bài test Flutter.

---

## 3. Kết quả chạy kiểm tra toàn diện (Windows, 2026-10-29)

| Thành phần | Lệnh kiểm tra | Kết quả |
|---|---|---|
| **Backend — Format** | `.venv\Scripts\ruff.exe format --check` (trên các file KX-1..KX-6) | **PASS** (5 file cũ từ 2026-10-27 giữ nguyên theo quy tắc §0.3) |
| **Backend — Lint** | `.venv\Scripts\ruff.exe check src tests migrations scripts` | **PASS** (`All checks passed!`) |
| **Backend — Typecheck** | `.venv\Scripts\mypy.exe --strict src tests/modules/knowledge/test_kx6_acceptance.py` | **PASS** (`0 issues`) |
| **Backend — Migration** | `alembic upgrade head` (PostgreSQL 16 `xuna_test`) | **PASS** (head `0012_knowledge_documents`) |
| **Backend — Test Suite** | `.venv\Scripts\pytest.exe -q` | **PASS (`402/402` passed)** |
| **Backend — Domain & Mode Eval** | `pytest tests/modules/knowledge/test_evaluation.py` (`turn_domain_vi.json`, 40 mẫu) | **PASS** (Mode accuracy: **40/40 = 100%**, Domain accuracy: **40/40 = 100%**) |
| **Mobile — Format** | `fvm dart format --output=none --set-exit-if-changed` (trên các file đã sửa) | **PASS** |
| **Mobile — Analyze** | `fvm flutter analyze` (Flutter `3.32.8`) | **PASS** (`No issues found!`) |
| **Mobile — Test Suite** | `fvm flutter test --no-pub` | **PASS (`329/329` passed)** |

---

## 4. Checklist nghiệm thu thực địa cho Owner (Board + Điện thoại + Provider thật)

Khi kết nối board LILYGO T-Display-S3, điện thoại và cấu hình khóa AI provider thật:

- [ ] **Bước 1 (Eval chất lượng chuyên môn):** Chạy `python scripts/expert_eval.py --output expert_eval_report.md` trong `backend/`, kiểm tra tỷ lệ sinh thẻ `<say>` đạt `>= 95%` và đọc chất lượng Markdown của 7 gói lĩnh vực.
- [ ] **Bước 2 (Hai lĩnh vực trên App):** Tạo lĩnh vực «Lập trình nhúng» từ gói mẫu và một lĩnh vực tự đặt; bật công tắc `Tự động` hoặc `Chuyên sâu`; hỏi một câu kỹ thuật bằng chữ và kiểm tra bong bóng tóm tắt + bấm `Xem chi tiết` mở bảng Markdown.
- [ ] **Bước 3 (Voice & phụ đề trên Board):** Bấm nút mic hỏi một câu chuyên sâu; xác nhận giọng đọc TTS chỉ đọc phần `say` ngắn (đo thời gian phản hồi âm thanh đầu tiên) và màn hình LCD trên mạch chỉ hiện phụ đề ngắn, không hiện ký hiệu Markdown.
- [ ] **Bước 4 (Ghi nhớ quy ước, việc đã giải quyết & tài liệu U4):** Bấm `Đã giải quyết` dưới câu trả lời chuyên sâu → xác nhận lưu vào ô lĩnh vực trên mạch; bật quyền U4 và nạp 1 tài liệu `.md` ngắn; kiểm tra số kinh nghiệm và mức độ ăn ý (`Mới quen` → `Bắt nhịp` → `Ăn ý`) trên thẻ lĩnh vực.
- [ ] **Bước 5 (Xoá kinh nghiệm & kiểm tra Offline):** Xoá một kinh nghiệm đã lưu và kiểm tra số đếm trên mạch giảm tương ứng; tắt mạng trên điện thoại và xác nhận mức độ ăn ý vẫn hiển thị từ dữ liệu BLE của mạch.


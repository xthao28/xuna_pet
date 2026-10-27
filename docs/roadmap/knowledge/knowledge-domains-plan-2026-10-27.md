# XUNA Knowledge Domains — kế hoạch M06 mới (2026-10-27)

> Trạng thái: **hướng đi owner-approved 2026-10-27** (phương án A). Mọi danh sách, ngưỡng và tên trong plan này là **[P] Proposed** cho tới khi owner chốt hoặc Life Lab đo xong. Owner: "có ý tưởng gì thêm thì sửa sau".

## 1. Quyết định

| ID | Quyết định | Trạng thái |
|---|---|---|
| K-D1 | **Bỏ các giai đoạn hình ảnh** Sơ sinh / Khám Phá / Hiểu Bạn. Lý do: mỗi giai đoạn cần sprite và bộ animation riêng (idle, happy, curious, sleep, Track A), quá tốn art và khó giữ style. Chỉ giữ **trứng → nở** (D7, luồng hatch đã có) | Approved 2026-10-27 |
| K-D2 | M06 đổi trọng tâm: XUNA **hiểu biết sâu dần trong những lĩnh vực chủ chọn**, dựa trên kiến thức chủ dạy và xác nhận. Thay cho D13 (ngưỡng lên giai đoạn, tên giai đoạn, art giai đoạn) | Approved 2026-10-27 |
| K-D3 | Device là nơi **duy nhất** quyết định hồ sơ lĩnh vực (lĩnh vực nào, mức nào, vì sao). Cloud giữ nội dung kiến thức đã xác nhận và dùng nó khi trò chuyện. Cùng mô hình với personality (P-D1) | [P] |

## 2. Lời hứa trung thực

- Đúng: "XUNA **nhớ** những lĩnh vực bạn chọn và những gì bạn đã dạy hoặc xác nhận, và dùng chúng khi trò chuyện với bạn."
- Không nói: "XUNA tự thông minh lên", "XUNA tự học trên mạng" hay "IQ của XUNA". LLM không được fine-tune và không tự trưởng thành (AGENTS §6). Mức lĩnh vực là **thước đo bằng chứng**, không phải trí thông minh.
- Mỗi lần lên mức phải giải thích được trong Journal ("vì bạn đã dạy XUNA 12 điều về nấu ăn"). Chủ xem, sửa và xoá được.

## 3. Khái niệm [P]

- **Lĩnh vực (domain):** chủ chọn tối đa **3** lĩnh vực từ một danh mục cố định, có thể đổi. Danh mục ban đầu đề xuất: Tiếng Anh, Nấu ăn, Sức khoẻ & thói quen, Thiên nhiên & khoa học, Âm nhạc, Lịch sử & văn hoá Việt Nam. Danh mục cố định (id `u8`) giúp device lưu gọn và tránh nội dung tự do trên Flash.
- **Mức:** 0 Mới làm quen → 1 Biết sơ → 2 Khá hiểu → 3 Hiểu sâu. Không giảm theo thời gian: không phạt chủ khi vắng (AGENTS §6). Chỉ giảm khi chủ xoá kiến thức hoặc bỏ lĩnh vực.
- **Bằng chứng** (device đếm, có giới hạn theo ngày để không "cày"):
  1. **Kiến thức đã xác nhận** trong lĩnh vực: fact được chủ xác nhận và device đã commit (luồng CLD-14 hiện có, thêm thẻ lĩnh vực). Bằng chứng mạnh.
  2. **Buổi trò chuyện về lĩnh vực:** tín hiệu do cloud hoặc app suy ra, chỉ là bằng chứng yếu và có trần (giống chốt an toàn P-D4). Có tính hay không là câu hỏi Q4.
- **Mức ảnh hưởng hành vi:** mức thấp thì XUNA hỏi lại và tò mò nhiều hơn; mức cao thì XUNA nhắc lại điều đã học, giải thích và gợi ý. Trên device, mức có thể làm XUNA `curious` hoặc `happy` hơn khi chủ mở đúng chủ đề (sau này). Đây là khác biệt hành vi đáp ứng tiêu chí M06.

## 4. Ai giữ gì

| Nơi | Giữ | Ghi chú |
|---|---|---|
| Device (`xuna_core`) | Danh sách ≤ 3 domain id, mức, bộ đếm bằng chứng, journal "lên mức" | Snapshot section mới, bounded; BLE đọc qua capability mới. Offline vẫn đủ |
| Cloud (backend) | Nội dung fact đã xác nhận, gắn `domain` | Đã có bảng candidate; thêm trường domain. Turn context nhận các lĩnh vực, mức và các fact liên quan của lĩnh vực đang nói |
| App | Card "Lĩnh vực của XUNA", chọn hoặc bỏ lĩnh vực, xem bằng chứng, Journal, xoá | Chỉ hiển thị và gửi yêu cầu; không tự tính mức (bài học từ review M06 cũ) |

**Offline:** XUNA vẫn biết mình theo lĩnh vực nào và ở mức nào, vẫn hiển thị được trên app và board. Trả lời chi tiết nội dung cần cloud. App ghi rõ điều này.

## 5. Hình ảnh

- Không vẽ sprite theo giai đoạn. XUNA giữ nguyên hình và mọi animation hiện có.
- Tuỳ chọn sau (KD-6): mỗi lĩnh vực có **một phụ kiện nhỏ phủ lên sprite gốc** (ví dụ kính cho Tiếng Anh, lá cho Thiên nhiên). Một overlay 96×72, dùng lại mọi animation, đúng tinh thần "modular visual traits" (AGENTS §6). Cần art brief riêng.

## 6. Dọn phần M06 cũ (KD-0) — **xong 2026-10-27** (xem PROCESS)

Đã làm: bỏ toàn bộ code giai đoạn và cả ảnh trứng (app chưa có chỗ dùng; generator còn trong lịch sử git `d42ae88`). Badge, bộ lọc và card trong app đổi sang placeholder "Lĩnh vực". Danh sách ban đầu:

- Mobile: thay `HomeGrowthCard` (4 giai đoạn) bằng placeholder "Lĩnh vực của XUNA – SẮP CÓ". Bỏ enum `GrowthStage`, `AppPetStage.newborn/child` và ảnh `xuna_stage_newborn/child`. Giữ `xuna_stage_egg` nếu app cần hiển thị trứng trước khi nở.
- Firmware: bỏ `generate_growth_stages.py` (hoặc chỉ giữ phần trứng) và các PNG newborn/child. `GrowthWireStage` quay về `Egg=0, Newborn=1` (Newborn = "đã nở"); phần mở rộng Child/Mature chưa có ai dùng.
- Tài liệu: AGENTS M06, D13 trong implementation plan, session plan, PROCESS.

## 7. Session [P]

| Session | Nội dung | Board/phone |
|---|---|---|
| KD-0 | Dọn M06 cũ (§6). Owner chốt Q1–Q5 | Không |
| KD-1 | `xuna_core`: danh mục domain, `KnowledgeProfile` (chọn/bỏ, bằng chứng, mức, journal), test native và Life Lab: hai lịch sử → hai hồ sơ khác nhau, giải thích được | Không |
| KD-2 | Snapshot section + BLE capability đọc hồ sơ; codec và test hai phía | Board |
| KD-3 | Backend: fact gắn domain; turn context có lĩnh vực + mức + fact liên quan; tín hiệu "buổi trò chuyện về lĩnh vực" (nếu Q4 = có) | Không |
| KD-4 | App: card và màn chọn lĩnh vực, bằng chứng, Journal, xoá | Phone |
| KD-5 | Board trial + nghiệm thu M06: hai chủ dạy hai kiểu → khác nhau về điều XUNA biết và cách nó trò chuyện/phản ứng, Journal giải thích được | Board + phone |
| KD-6 (tuỳ chọn) | Phụ kiện theo lĩnh vực | Board + phone |

## 8. Câu hỏi cho owner

- **Q1:** Danh mục lĩnh vực ban đầu (§3) có đúng ý không? Thêm hoặc bớt gì?
- **Q2:** Tối đa bao nhiêu lĩnh vực cùng lúc (đề xuất 3)?
- **Q3:** Tên các mức (đề xuất: Mới làm quen / Biết sơ / Khá hiểu / Hiểu sâu) và ngưỡng (đề xuất [P]: 3 / 10 / 25 kiến thức đã xác nhận).
- **Q4:** Trò chuyện về một lĩnh vực mà không dạy gì cụ thể có được tính là bằng chứng (yếu, có trần) không, hay chỉ tính kiến thức đã xác nhận?
- **Q5:** Mức lĩnh vực có hiện trên màn hình board không, hay chỉ trên app?

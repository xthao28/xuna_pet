# PE-4c — Trò chuyện ảnh hưởng tính cách, không cần xác nhận (2026-10-25)

> Plan: [personality-plan-2026-10-23.md](personality-plan-2026-10-23.md) §4 PE-4c, chốt an toàn §6. Owner: "oke bắt đầu làm đi" sau khi chọn **O4 = không** (sở thích vẫn qua xác nhận, D6) và **O5 = dùng consent U3 hiện có**.
> Trạng thái: **Implemented, trên board 2026-10-25 (firmware `8f498a7`); chưa thử trên iPhone**. Mọi tham số **[P]**.

## 1. Luồng

1. Owner chat với XUNA trong app (U3 bật). Backend trả lời như cũ, và sự kiện SSE `finished` mang thêm `signals`: 0–2 tag đóng lấy từ **câu của owner**.
2. App đang nối board có capability thì gửi mỗi tag bằng **BLE opcode 8** (8 byte, arg = tag 1–6, source 0).
3. Board:
   - **cảm xúc ngay** qua `Affect` (mood floor vẫn giữ);
   - **bằng chứng yếu** cho một trait qua `EvidenceLedger`, nguồn `ConversationInferred`.

Learning, sở thích và snapshot learner **không đổi** (O4).

| Tag (wire backend → opcode 8 arg) | Cảm xúc (phần của impulse) | Trait, chiều | Lý do Journal |
|---|---|---|---|
| `praise` → 1 | valence +½, arousal +¼ | sociability + | 9 `ConversationPraise` "bạn khen khi trò chuyện" |
| `scold` → 2 | valence −½, arousal +¼ | sociability − | 10 `ConversationScold` |
| `affection` → 3 | valence +½ | sociability + | **13** `ConversationAffection` (mới) |
| `playful` → 4 | valence +¼, arousal +½ | playfulness + | **14** `ConversationPlay` (mới) |
| `curious_question` → 5 | valence +⅛, arousal +¼ | curiosity + | **15** `ConversationQuestion` (mới) |
| `long_chat` → 6 | valence +¼ | sociability + | **16** `ConversationLong` (mới) |

## 2. Chốt an toàn (plan §6) đã áp

| Chốt | Cách làm |
|---|---|
| 1. Tag đóng | Backend chỉ gửi 6 tên cố định; app bỏ qua tên lạ; board từ chối arg ngoài 1–6 (result 4). Không có text hay giá trị trait nào qua BLE. |
| 2. Trọng số thấp, cap theo ngày | Trọng số 0,1 (bằng device observed). Mỗi phiên tối đa ±0,5 cho mỗi trait (share có sẵn), nên 5 tag/phiên là đầy. `Personality::kConversationDailyCap = 8` tag cho mỗi 24 h uptime. |
| 3. Chỉ temperament | Không đụng learner, preference hay feedback count (test). |
| 4. Nhiều buổi | Ledger như cũ: ≥ 4 phiên, ≥ 2/3 cùng dấu, coherence. Test: 3 ngày khen dồn không dịch gì; ngày thứ 4 dịch ≤ 0,03; khen/mắng xen kẽ 8 ngày thì offset = 0. |
| 5. Chống "nói cho thành" | "mày là con mèo lười" chỉ là một tag `scold` 0,1 như mọi tag. |
| 6. Minh bạch sau | Journal có 4 lý do mới; thẻ "Tính cách" hiện chúng. Nút "Bỏ thay đổi gần nhất" / "Đặt lại" là PE-4d (chưa làm). |
| 7. Riêng tư | Text không lưu (U3 per-call như cũ); tag không lưu ở backend; board giữ bộ đếm trong ledger. |
| 8. Offline | Không cloud thì chỉ mất nguồn bằng chứng này. |

## 3. Bộ phân loại (backend)

- `conversation/domain/signals.py`: từ khoá tiếng Việt trên câu của owner (NFC, chữ thường, ranh giới từ), **không gọi thêm LLM**. Đổi provider thì tag vẫn y hệt, và test được.
- Bỏ phủ định ngay trước từ khoá: "không / chẳng / chả / đừng" (+ tối đa 1 từ).
- Tránh nhầm: "ngủ" ≠ "ngu", "yêu cầu" không phải âu yếm, "nhớ là…" không phải "nhớ bạn".
- Thứ tự ưu tiên: scold > praise > affection > playful > curious_question; tối đa 2 tag.
- `long_chat` khi lịch sử lượt chat vừa chạm 8–9 dòng (một lần mỗi cuộc trò chuyện dài).
- **Giới hạn đã biết:**
  - từ khoá không hiểu mỉa mai hay ngữ cảnh;
  - câu hỏi kiểu "mấy giờ rồi?" không tính là tò mò, chỉ "tại sao / vì sao / là gì / thế nào / ra sao / có biết".

  Vì tag yếu và có cap, sai một câu không đổi được tính cách.

## 4. Đã làm

- **Firmware:**
  - `ConversationTag` + `Personality::conversation()` (cần phiên owner đang mở; cap theo ngày, transient như drives/affect);
  - `Affect::conversation()`;
  - 4 `EvidenceReason` mới (append, `kEvidenceReasonCount` 13 → 17; codec section 5 lưu reason thưa theo id nên snapshot cũ vẫn đọc được, firmware cũ gặp id ≥ 13 thì bỏ section 5, đúng O2 optional);
  - `LifeCoreEventKind::Conversation` + `conversationApplied`;
  - `parseCommand(..., conversation)` opcode 8;
  - adapter case 8 (chỉ enhanced; trả ok cả khi bị cap; replay trả từ cache);
  - capability byte 3 bit 2 (`0x03` → `0x07`);
  - serial `conversation tag=<n> result=<r> applied=<0|1>`.
- **Backend:** `ConversationSignal`, `conversation_signals()`; `finished` có `signals` (cả khi `speak`).
- **Mobile:**
  - `ConversationSignal` (device domain), `ForwardConversationSignalsUseCase`;
  - `DeviceRepository.supportsConversationSignal` / `sendConversationSignal`, codec opcode 8 + capability bit;
  - `CloudReplySignals` từ `finished`;
  - `HomeController` gửi khi đang nối (lỗi BLE chỉ log);
  - 4 lý do Journal mới + locale; `PersonalityModel` nhận reason ≤ 16.

## 5. Kiểm tra (Mac)

| Kiểm tra | Kết quả |
|---|---|
| Firmware native / native_asan | **321/321** mỗi bộ (`test_conversation` 7 test; `test_v1_adapter` +2: enhanced nhận, replay, arg 0/7, source ≠ 0, độ dài 12; baseline trả 3) |
| ESP32 `xuna_t_display_s3` + purity | SUCCESS: RAM 55,000 B (+96), Flash 3,895,917 B (+660) |
| ESP32 `xuna_parity` | build SUCCESS |
| Trace c3/c8/c9, golden S20 | test trace/golden trong bộ native vẫn pass (không có sự kiện conversation) |
| Backend `scripts/check.sh` | **159 passed** (ruff, mypy --strict, alembic, pytest; `test_signals.py` + API `signals`) |
| Mobile | `flutter analyze` sạch; **204/204** (codec, use case, SSE parse, mapper reasons, controller forward/không forward khi ngắt) |

**Chưa chạy:** Life Lab (chưa có kịch bản chat; mọi kịch bản cũ không có sự kiện này), upload board, iPhone, một lượt chat thật đầu-cuối.

## 5b. Board (Mac, 2026-10-25)

- Backup `~/xuna_backups/2026-10-25-pe4c/`: NVS đọc 3 lần liên tiếp trong bootloader, đều `79581a6f…`.
- Parity: 4 × PASS; `step()` p99 c3 273–274 / c8 314–325 / c9 10 µs (không đổi).
- Production firmware `8f498a7` (`65c760ce…`), RAM 55,000 B, Flash 3,895,917 B: `recover=Ok boot=75`, cùng PetId `d945…`, `persona_restored bytes=139 sessions=8 evidence=52`.
- Backend trên Mac đã chạy lại với PE-4c (`0.0.0.0:8000`).
- Chờ owner: build app mới, chat khi nối board, xem serial `conversation tag=…`.

## 6. Tương thích

- **App cũ + firmware mới:** app cũ không gửi opcode 8, nên board không có bằng chứng hội thoại, không sinh reason 13–16. Nếu app mới trên máy khác đã làm sinh reason mới, **app cũ sẽ không đọc được thẻ Tính cách** (mapper cũ ném lỗi với reason ≥ 13). Cần build app mới cho mọi máy dùng.
- **App mới + firmware cũ:** không có bit 2 → không gửi gì.
- **Backend cũ:** `finished` không có `signals` → app không gửi gì.

## 7. Tiếp theo

1. Owner build app mới; chat thử khi nối board và xem serial `conversation tag=…`.
2. PE-4d: nút "Bỏ thay đổi gần nhất" và "Đặt lại tính cách" (lệnh firmware mới).
3. PE-5: sống thật vài tuần; chỉnh cap/ trọng số nếu cần.

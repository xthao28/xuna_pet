# PE-4d — Bỏ thay đổi gần nhất / Đặt lại tính cách (2026-10-25)

> Plan: [personality-plan-2026-10-23.md](personality-plan-2026-10-23.md) §4 PE-4d, §6.6 ("minh bạch sau, thay cho xác nhận trước"). Owner: "làm nốt PE-4d đi".
> Trạng thái: **Implemented, trên board 2026-10-25 (firmware `fba10f7`); chưa thử trên iPhone**. Thẻ chỉ đọc + Journal đã có từ 2026-10-24.

## 1. Hành vi

| Nút (tab Nhật ký → thẻ Tính cách) | BLE opcode 9 | Board làm gì | Giữ nguyên |
|---|---|---|---|
| **Bỏ thay đổi gần nhất** (hỏi xác nhận) | arg 1 | Lấy mục mới nhất ra khỏi Journal và trả trait về như trước mục đó (`offset −= delta`). Bấm lại thì lùi tiếp, tối đa 4 mục. Journal rỗng → result 4, app nói "Không còn thay đổi tính cách nào để bỏ". | Bằng chứng đang tích, khí chất bẩm sinh, learning, ký ức |
| **Đặt lại tính cách** (hỏi xác nhận, "không thể hoàn tác") | arg 2 | `Personality::forget()`: offset về 0, ledger và Journal xoá. | Khí chất bẩm sinh (baseline từ seed), learning, sở thích, ký ức, bộ đếm phiên |

- **Commit-first** (như opcode 4 quên):
  - `LifeCore::controlPersonality` encode section 5 từ bản sao, commit snapshot, rồi mới đổi RAM;
  - commit lỗi → result 7, không đổi gì;
  - ERROR_SAFE → 7.
- Replay cùng request id trả kết quả cũ từ cache, không undo hai lần.
- Chỉ adapter enhanced. Capability **byte 3 bit 3** (`0x07` → `0x0f`).
- Serial: `personality_control arg=<1|2> result=<r>`.
- **App:**
  - nút chỉ hiện khi đang nối board có capability và pet đã có identity;
  - "Bỏ thay đổi" mờ đi khi Journal trống;
  - sau khi thành công app đọc lại `000e` và XUNA nói một câu xác nhận.

## 2. Đã làm

- **Firmware:**
  - `EvidenceLedger::popLatest`, `Personality::undoLatest`;
  - `LifeCore::PersonalityControlResult` / `controlPersonality(reset)`;
  - `parseCommand` opcode 9 (cùng cờ với opcode 8), adapter case 9;
  - capability byte 3 bit 3; serial log.
- **Mobile:**
  - `PersonalityControl` (entity), `ControlPersonalityUseCase`;
  - `DeviceRepository.supportsPersonalityControl` / `controlPersonality`, codec opcode 9 + capability;
  - `HomeController.requestUndoPersonality` / `requestResetPersonality` (hộp xác nhận) / `controlPersonality`, `personalityControlSupported`;
  - `HomePersonalityCard` `onUndo`/`onReset`, `HomeJournalTab` truyền qua; 11 chuỗi tiếng Việt.

## 3. Kiểm tra (Mac)

| Kiểm tra | Kết quả |
|---|---|
| Firmware native / native_asan | **325/325** mỗi bộ (`test_personality_control` 4 test) |
| Firmware test chi tiết | Undo lùi qua Journal; sequence không dùng lại; revision đổi. Mất điện → 7 và không đổi. Reboot **trước** undo giữ thay đổi, reboot **sau** undo không còn (checkpoint như board). Undo hết → 4. Learning, feedbackCount, preferred không đổi. Reset giữ baseline, xoá offset/ledger/Journal, qua reboot vẫn vậy. Arg 0/3 → 4; baseline adapter → 3. |
| ESP32 + purity / parity | SUCCESS: RAM 55,000 B, Flash 3,896,557 B (+640) / build SUCCESS |
| Mobile | `flutter analyze` sạch; **209/209** (codec, use case, controller undo/reset/rejected + capability, widget nút và trạng thái mờ) |

- **Phát hiện khi viết test:** thay đổi tính cách sau consolidation chỉ xuống flash ở checkpoint 5 phút kế tiếp (lazy, PE-3). Mất điện trước checkpoint thì mất thay đổi đó. Undo và reset thì commit ngay.
- **Chưa chạy:** iPhone, bấm thật.

## 3b. Board (Mac, 2026-10-25)

- Backup `~/xuna_backups/2026-10-25-pe4d/`: NVS đọc 3 lần liên tiếp trong bootloader, đều `12bebba4…`.
- Parity: 4 × PASS; `step()` p99 c3 273–274 / c8 315–327 / c9 10 µs (không đổi).
- Production firmware `fba10f7` (`ea64e12c…`): `recover=Ok boot=76`, cùng PetId `d945…`, `persona_restored bytes=139 sessions=8 evidence=52 journal=0`.
- Board hiện **chưa có mục Journal nào** (`journal=0`). Vì vậy nút "Bỏ thay đổi" sẽ mờ cho tới khi một trait dịch. "Đặt lại" thì bấm được: nó xoá bằng chứng đang tích (52 mục).
- Chờ owner: build app mới, bấm thử, xem serial `personality_control`.

## 4. Tương thích

- **App cũ:** không có nút.
- **Firmware cũ:** không có bit 3 nên app không hiện nút. Nếu vẫn gửi, firmware trả 3.

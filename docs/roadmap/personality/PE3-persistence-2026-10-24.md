# PE-3 — Tính cách sống qua reboot (2026-10-24)

> Plan: [personality-plan-2026-10-23.md](personality-plan-2026-10-23.md) §4 PE-3. Owner: "PE-3 đi, còn lại bạn tự quyết, hợp lý là được".
> Trạng thái: **Implemented, đã upload board**. Kiểm tra reboot trên board đang chờ owner thao tác (§5). Mọi tham số vẫn **[P]**.

## 1. Quyết định (uỷ quyền)

| ID | Quyết định | Lý do |
|---|---|---|
| O2 | Section 5 **optional** | Firmware cũ bỏ qua section và vẫn chạy, chỉ mất phần tính cách đã học. Nếu required thì firmware cũ trả TooNew → ERROR_SAFE, khoá cả pet sau rollback |
| PE3-a | Chỉ ghi section khi đã học được gì đó (offset, bằng chứng hoặc journal) | Snapshot và golden cũ giữ byte-identical khi chưa có bằng chứng |
| PE3-b | Section 5 có nội dung không hợp lệ (CRC vẫn đúng) thì **bị bỏ qua**, không làm snapshot Corrupt | Phần phụ không được phép đẩy pet vào ERROR_SAFE |
| PE3-c | Giữ tối đa 3 reason + 2 source nặng nhất mỗi trait | Section ≤ 482 B dù dữ liệu xấu đến đâu. Reason trội (journal dùng) luôn còn; hôm nay mỗi trait có ≤ 2 reason, 1 source nên không mất gì |
| PE3-d | Lưu theo kiểu lazy | Bằng chứng của một lần pet tới flash ở lần commit kế tiếp (reaction sau, stated preference hoặc checkpoint ≤ 5 phút), không phải ở commit của chính lần pet đó |
| PE3-e | Không lưu baseline, drive, affect | Baseline tính lại từ `IdentityRecord.seed`; drive/affect là trạng thái tức thời như needs |

## 2. Đã làm (firmware)

- `xuna/personality/PersonalityCodec.h`: section 5 v1.
  - Gồm: counters (session, evidence, shifts, decays), offset[10], journal ring 4, các trait có bằng chứng (pending, importance, session state, weights rút gọn).
  - `valid()` / `load()`. Encode → decode → encode cho ra byte-identical.
- `SnapshotCodec`: `LifeSnapshotV2::personality` (blob ≤ 482 B), section 5 optional, ghi sau Habit.
- `LifeCore`:
  - `seedPersonality()` đọc section 5 của snapshot đã khôi phục;
  - `syncPersonality()` mã hoá lại khi `Personality::revision()` đổi;
  - ForgetAll commit không có section 5;
  - output `traitsConsolidated`.
- `EventTypes`: `TraitConsolidated` 0x71 (Evolution, SnapshotJournal, critical). Journal sequence là khoá idempotent.
- BLE: characteristic **`7a6e000e`** chỉ đọc, 64 B (`PersonalityProjection`): nhãn, mood word, 10 trait, mood, số buổi, journal 4 mục mới nhất trước.
  - Capability byte 3 bit 1 (`0x03`). Service dùng 22/32 handle.
  - App chưa đọc tới PE-4d.
- `main.cpp`: log `persona_restored …` lúc boot, `persona_shift …` khi trait đổi.

## 3. Kiểm tra (Mac)

| Kiểm tra | Kết quả |
|---|---|
| native / ASan | **294/294** mỗi bên; `test_personality_persist` 9 test |
| Snapshot xấu nhất (clock, needs, habit, 45 ô stated, section 5 tối đa) | ≤ 1536 B |
| Golden S20 `learning_v1.json` | byte-identical |
| Life Lab | byte-identical với PE-2b (md5 `ca3cc133…`) |
| Trace c3 / c8 | hash giữ nguyên |
| Trace c9 (60 ngày có pet/shoo) | `7ca37821…` → **`a5491046…`**: có thêm section 5, chủ đích |
| ESP32 build | RAM 54,872 B (+1,048), Flash 3,008,649 B |

## 4. Board 2026-10-24

- Backup `/Users/xthao28/xuna_backups/2026-10-24-pe3/`: partition `bd0f7954…` không đổi; NVS đọc 2 lần khớp `4a98da87…`.
- Parity: 2 lượt PASS, hash trùng host (gồm `a5491046…`). `step()` p99: c3 276–278, c8 318–327, c9 10 µs, như PE-2.
- Production: app `23e51ec8…`. Boot `recover=Ok slot=0 boot=54 ready=1`, cùng PetId, quiet=1 play=0.
  - `persona_restored bytes=0`, đúng vì bản trước không lưu tính cách.
  - **Stack setup còn trống 6,184 B** (trước 7,192 B) do snapshot lớn thêm ~0,5 KB. Cần theo dõi stack ở đường reaction/commit.

## 5. Còn lại

- Kiểm tra reboot trên board: owner chào và vuốt → chờ checkpoint 5 phút → reset → `persona_restored` phải có dữ liệu khớp với trước reset. **Đang chờ.**
- Gate G3 (owner): golden ✓, reboot/restore bit-identical trên host ✓, parity ESP32 ✓, snapshot ≤ 1536 ✓; reboot trên board đang chờ.
- Mobile đọc `000e` ở PE-4d.

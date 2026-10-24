# PE-2 — Tính cách chạy shadow trên board + biểu hiện đầu tiên (2026-10-24)

> Plan: [personality-plan-2026-10-23.md](personality-plan-2026-10-23.md) §4 PE-2. Báo cáo G1: [PE1-G1-report.md](../../research/PE1-G1-report.md).
> Trạng thái: **Implemented, đã upload board 2026-10-24** (§6); Gate G2 chờ owner quan sát. Mọi tham số vẫn **[P]**.

## 1. Quyết định G1 (owner 2026-10-24: "oke làm tiếp đi" sau khuyến nghị A cho cả bốn)

| ID | Quyết định | Làm trong session này |
|---|---|---|
| G1-a | Ledger cần **≥ 4 buổi** (trước 3), nhất quán 0,5 giữ nguyên | `LedgerConfig::minSessions = 4` |
| G1-b | §5 dòng 1 đổi thành "ảnh hưởng của owner vượt khí chất bẩm sinh sau ≤ 3 tháng và tiếp tục tăng" | Plan §5 cập nhật |
| G1-c | PE-2 biểu hiện chỉ qua nhịp/cảm xúc, theo khoảng thực tế của trait; drive không bao giờ đè learning; Track A song song | Nhịp frame + độ dài reaction + dòng tâm trạng; tần suất hành động tự phát **để PE-2b** (xem §4) |
| G1-d | Sociability chủ yếu bẩm sinh tới PE-4; PE-4 thêm bằng chứng device-observed (số lần chủ chào, độ dài buổi) | Không đổi code |

## 2. Đã làm (firmware, host)

- `xuna/personality/Personality.h`: gom genome + evidence ledger + drives + affect thành một khối, đầu vào là giá trị thuần (không phụ thuộc `LifeCore`). `lab/PersonalityShadow.h` giờ chỉ bọc khối này và giữ phần "shadow world" của Life Lab. Refactor không đổi kết quả: chạy Life Lab với tham số cũ cho output giống hệt `PE1-shadow-output.txt` (md5 `db687275…`).
- `LifeCore` sở hữu `Personality`:
  - mọi event không phải `Spontaneous` là owner input;
  - quyết định XUNA vừa hiện (kèm p̂ của learner) được ghi lại; pet/shoo đã áp dụng được chuyển thành bằng chứng;
  - mọi action được chấp nhận làm giảm drive tương ứng;
  - ForgetAll xoá phần đã học, giữ phần bẩm sinh.
  - Không đổi quyết định, RNG hay snapshot: golden trace, characterization và replay S01 đều pass như cũ.
- `BootSequence`: seed genome từ `IdentityRecord.seed` khi identity Ready; Egg/chưa có identity thì genome trung tính (= nhịp hôm nay).
- `xuna/personality/Expression.h` (G1-c):
  - **nhịp frame** 100 ms ∓ 15 % theo tempo + mood arousal/2;
  - **độ dài reaction** 2400 ms ± 15 % theo sensitivity + |emotion|/2;
  - ±0,3 trait đã là hiệu ứng tối đa, nên khí chất bẩm sinh ±0,15 thấy được nửa hiệu ứng;
  - genome trung tính + mood yên cho đúng 100 ms / 2400 ms.
- `PetVisualAnimation::setInterval` (đổi nhịp không làm nhảy frame), `AnimationManager::setReactionMs`, `DisplayManager::setFramePeriod`; `main.cpp` áp mỗi vòng lặp.
- Status card: dòng **"tâm trạng"** cạnh chữ XUNA. Có 6 từ: bình yên, vui, rất vui, hơi buồn, buồn, hơi chán. Font sinh lại với 3 glyph mới (á, ạ, ồ) bằng Pillow 13.0.0; chạy lại trên chữ cũ cho ra file byte-identical trước khi thêm chữ.
- Serial: mỗi 60 s một dòng `persona t_s=… cur= soc= play= tempo= sens= mood_v= mood_a= emo_v= comp= explore= social= playd= bored= sessions= evidence= shifts= frame_ms= react_ms=` (trait/mood Q1.14, drive 0..65535).
- Sửa phụ: `sim/personality_lab.cpp` bỏ hằng `kDayMs` không dùng (clang `-Werror` trên Mac báo lỗi, GCC Windows thì không).

## 3. Kiểm tra (Mac, 2026-10-24)

| Kiểm tra | Kết quả |
|---|---|
| `pio test -e native` | **282/282** (thêm `test_personality_board` 6, `test_visual` +2; `test_device_cards` thêm assert) |
| `pio test -e native_asan` | **282/282** |
| `pio run -e xuna_t_display_s3` (+ purity) | SUCCESS. RAM 53,784 B (+824), Flash 3,001,829 B (+5,852; font +1,330) so với cùng commit trước thay đổi |
| `pio run -e xuna_parity` | SUCCESS (38,464 B RAM). **Chưa chạy trên board** |
| Life Lab `personality_lab` | 86,6 s, exit 0. Các dòng PE-0 `metric,…` byte-identical. Output: [PE2-shadow-output.txt](../../research/artifacts/PE2-shadow-output.txt) |

Life Lab với G1-a (so với PE-1, cùng kịch bản):

| Chỉ số | PE-1 (3 buổi) | PE-2 (4 buổi) |
|---|---|---|
| Owner ngẫu nhiên, \|offset\| TB ngày 29 | 0,0081 | **0,0033** |
| Owner noisy | 0,0089 | **0,0022** |
| Owner xen kẽ, biên độ ngày 10–29 | 0,0173 | **0,0088** |
| Đảo sở thích: curiosity đổi ngày 14–29 | −0,0032 | **0,0000** |
| P1 curiosity sau 30 ngày | +0,146 | +0,116 |
| Teacher curiosity sau 30 ngày | +0,450 | +0,420 |
| §5 dòng 1 (giữa owner / trong owner) ngày 29 / 59 / 89 | 0,49 / 0,88 / 1,35 | 0,40 / 0,72 / **1,10** |

Dòng 1 theo cách diễn đạt G1-b **đạt sát nút** ở ngày 89 (1,10 > 1). Nó vẫn tăng, nhưng chậm hơn PE-1. Nếu muốn có biên an toàn thì cách rẻ nhất là cho thêm bằng chứng device-observed ở PE-4 (G1-d), không cần nới ledger.

## 4. Chưa làm / giới hạn

- **Tần suất hành động tự phát theo drive** (G1-c): làm ở **PE-2b**. Lý do: nó đổi *khi nào* XUNA tự hành động (LocalBehavior, ngoài LifeCore), tức là đổi hành vi và số liệu Life Lab PE-0. Cần một bước riêng có đo.
- Phần đã học **mất khi reboot** cho tới PE-3 (snapshot section 5). Phần bẩm sinh giữ nguyên vì seed bền.
- Chưa đo `step()` p99 trên ESP32 (Gate G2: tăng < 50 µs). Personality chỉ cập nhật drive/affect theo phút, nên dự kiến chi phí nhỏ. Đây là **giả định**, chưa đo.
- Render: đổi nhịp frame không thêm vẽ mỗi frame, chỉ đổi số frame/giây (85 ms ↔ +18 % frame). Cần xem `draw_max_us`/`loop_gap_max_us` trên board.
- Track A (animation mới) chưa bắt đầu (O3).

## 5. Việc trên board (cần owner, máy Mac có board)

1. Cắm board. Đọc NVS 2 lần, so khớp, lưu vào `~/xuna_backups/2026-10-24-pe2/` như [M04 record](../milestones/M04-foundation.md).
2. Upload `xuna_parity` → ghi bảng `step()` p50/p99 so với 2026-10-22 → upload lại production.
3. Boot phải giữ `recover=Ok`, cùng PetId `d945c770…`, cùng quiet/play.
4. Quan sát vài ngày:
   - nhịp XUNA có tự nhiên không, có giật/flicker không;
   - reaction dài/ngắn có hợp lý không;
   - status card (giữ GPIO0) có dòng tâm trạng;
   - log `persona` mỗi phút.
5. **Gate G2 (owner):** nhịp và tâm trạng khác hợp lý; không flicker; `step()` p99 tăng < 50 µs.

## 6. Board 2026-10-24 (Mac, `/dev/cu.usbmodem14201`)

- **Backup** `/Users/xthao28/xuna_backups/2026-10-24-pe2/` (ngoài Git):
  - partition `bd0f7954…fff6ce`, giống bản 2026-10-22;
  - NVS đọc 2 lần, cả hai `c685f095…c0ccb56e` (giống hệt).
- **Parity** (`xuna_parity`): 2 lượt PASS, snapshot hash trùng 2026-10-22 (`7b06fbf8…`, `add477bf…`, `7ca37821…`). `step()` (µs):

| Trace | p99 2026-10-22 | p99 PE-2 | Tăng |
|---|---|---|---|
| c3 (cắt điện, reboot) | 257–265 | 276–279 | +14 |
| c8 (sync, day part) | 313–317 | 323–332 | +15 |
| c9 (60 ngày) | 7 (mean 6,6) | 10 (mean 9,0) | +3 |

  Tăng ≤ 15 µs, dưới ngưỡng G2 là 50 µs. Log: `parity-board-log.txt`.
- **Production** upload SUCCESS (hash verified), app SHA-256 `aca9820f…98bbc275` (`firmware-uploaded.bin`). Build từ source **chưa commit** ở thời điểm upload.
  - Boot: `recover=Ok slot=0 corrupt_slots=0 boot=41 ready=1`, PetId `d945c770…ed86`, quiet=1 play=0 giữ nguyên, setup stack 7,144 B, device key loaded.
  - Idle 90 s: loop gap ≤ 9,8 ms (lúc boot), sau đó ≤ 4,9 ms; draw ≤ 4,95 ms; heap ổn định 232,964 B.
  - Owner mở status card lúc 12:19:35: scene 28 ms cho lần đẩy toàn màn hình, PSRAM −116 KB cho framebuffer card, như trước.
- **Khí chất bẩm sinh của `d945…`** (dòng `persona` đầu tiên, Q1.14 → số thực):
  - curiosity +0,006, sociability +0,027, playfulness **+0,131**, tempo −0,039, sensitivity +0,018, mood nền +0,025;
  - → `frame_ms=101`, `react_ms=2421`.
  - **Pet này gần trung tính về tempo/sensitivity**, nên lúc mới chạy nhịp gần như không khác (±1 %). Khác biệt nhìn thấy được sẽ đến từ tâm trạng: cảm xúc sau pet/shoo, buồn chán khi lâu không có gì mới.

## 7. Board nóng: cho vòng lặp nghỉ (owner 2026-10-24: "board nóng lắm" → "oke làm đi")

- **Nguyên nhân:** `loop()` chỉ `yield()`, nên CPU 240 MHz quay liên tục khoảng **25,500 vòng/s** chỉ để vẽ khoảng 10 frame/s. Đèn nền GPIO38 luôn 100 % (chưa đổi). PE-2 không phải nguyên nhân (+3 µs/bước).
- **Sửa:**
  - `kLoopPeriodMs = 10` (`src/BoardConfig.h`): mỗi lượt xong thì `delay` phần còn lại của 10 ms, lượt chậm (đẩy card) chỉ `yield()`;
  - dòng diagnostics `power loops=… chip_temp_c=…` mỗi 5 s, dùng cảm biến trong chip, không phải nhiệt bề mặt board.
- **Đo trên board**, mỗi bản 9 phút, idle, cùng phòng. Backup NVS trước mỗi lần upload, đọc 2 lần đều khớp, ở `~/xuna_backups/2026-10-24-pe2/heat/`:

| | A: chỉ thêm log | B: nghỉ 10 ms |
|---|---|---|
| Vòng/5 s | ~127,300 | **495** |
| Nhiệt chip | 50–54 °C, ổn định ~51,8 °C | 48,8 → **46,8 °C**, còn đang giảm |
| draw max | 4,98 ms | 5,59 ms |
| loop gap max | 68 ms (boot) / 4,9 ms | 36 ms (card) / 11 ms |
| Boot | `recover=Ok boot=43`, cùng PetId, quiet=1 play=0 | `recover=Ok slot=1 boot=45`, cùng PetId, quiet=1 play=0 |

- Bản B: heap giảm 3,5 KB một lần ở phút thứ 2 rồi đứng yên ở 229,116 B, không phải leak. Có thể do app trên điện thoại kết nối BLE, nhưng **chưa xác minh**. Owner shoo một lần và mở status card một lần; cả hai đều phản hồi bình thường.
- **Chưa làm:** giảm độ sáng đèn nền (PWM), hạ CPU 160 MHz, light sleep tự động (cần bật power management của ESP-IDF). Nếu board vẫn nóng thì làm tiếp theo thứ tự đó, mỗi bước đều đo.

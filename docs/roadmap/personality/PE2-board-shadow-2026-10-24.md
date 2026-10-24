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

## 8. PE-2b — nhịp tự hành động theo khí chất (owner 2026-10-24: "tiếp tục làm phần tiếp theo")

- **Trước PE-2b:** để một mình, XUNA tự chọn một hành động sau mỗi 60 s yên tĩnh. Đó là khoảng 1,200 lựa chọn/ngày, mọi pet giống nhau.
- **Đã thử ba cách** trong Life Lab (30 ngày, 5 pet mỗi kịch bản; ngày 23–29):

| | 60 s cố định | Drive (75→45 s) | Khí chất + drive (45–75 s) | **Chỉ khí chất (51–69 s)** |
|---|---|---|---|---|
| Tự hành động/ngày (owners) | 1,203 | 1,529 | 1,355 | **1,251** |
| Chênh giữa pet cùng owner | 0 % | 3,5 % | 10,3 % | **10,7 %** |
| Đời giống hệt pet seed 1 (entropy_only) | 4/4 | — | 0/4 | **0/4** |
| Owner ngẫu nhiên, \|offset\| ngày 29 | 0,0033 | — | 0,0079 | **0,0035** |
| Owner xen kẽ, biên độ | 0,0088 | — | 0,0103 | **0,0086** |
| Ngày tệ, mood thấp nhất tuần thường | −0,07 | — | −0,17 | **−0,10** |
| Phút nghỉ/ngày | 240 | 247 | 243 | **≈ 240** |
| §5 dòng 1 ngày 89 (G1-b: > 1) | 1,10 | — | 1,02 | **0,98** |
| Learning đảo sở thích (ngày tới 75 % ô) | 3,6 | — | 2,8 | **5,0** |

  (— = không đo đủ chỉ số này, vì cách đó bị loại ngay ở hai dòng đầu.)
- **Owner chọn "chỉ theo khí chất":** chờ = 60 s × (1 − 0,15·t), t = (curiosity + playfulness)/2, hiệu ứng tối đa ở ±0,3 (`Expression::spontaneousWaitMs`).
  - Bỏ drive vì drive gần như luôn đầy: chúng chỉ làm XUNA bận hơn và làm độ trôi của owner ngẫu nhiên tăng gấp đôi.
  - Learner vẫn quyết *làm gì*.
- **Đánh đổi đã chấp nhận:**
  - §5 dòng 1 ở ngày 89 xuống 0,98, dưới mức G1-b. Lý do là các pet cùng owner giờ khác nhau hơn (gap trong owner 0,104 → 0,117). Với 5 pet thì chênh này nằm trong nhiễu, nhưng cần theo dõi.
  - Learning đảo chậm hơn (3,6 → 5,0 ngày), vẫn nhanh hơn rất nhiều so với tính cách.
- **Đạt dòng PE-0 đề xuất** "cùng owner, khác seed → khác biệt nhìn thấy được (thời điểm/nhịp ≥ 0,1)": chênh 10,7 %. JS của lựa chọn hành động vẫn ≈ 0: khí chất lộ ra ở *khi nào*, chưa ở *chọn gì*.
- **Pet `d945…`:** chờ ≈ 58 s (trước 60 s).
- **Kiểm tra:**
  - native/ASan **284/284** (`test_personality_board` +2; một test cũ chào ở mốc giờ cứng, giờ chờ XUNA rảnh);
  - ESP32 build SUCCESS;
  - golden S20 `learning_v1.json` byte-identical;
  - output: [PE2b-shadow-output.txt](../../research/artifacts/PE2b-shadow-output.txt).
- **Board 2026-10-24:**
  - **Hai lần upload đầu thất bại** ("Failed to connect to ESP32-S3: No serial data received"). Lỗi xảy ra ở bước kết nối nên không ghi gì lên flash. Sau đó board không xuất log, có thể bị kẹt ở chế độ download (chưa xác minh).
  - Owner rút cắm lại: bản cũ boot bình thường (`boot=48`, chip 40,8 °C).
  - Backup NVS lại, đọc 2 lần khớp `a5a2c66a…`. Upload SUCCESS, app `cd559d88…`.
  - Boot `recover=Ok slot=0 boot=50 ready=1`, PetId `d945…`, quiet=1 play=0, stack 7,128 B.
  - Tự hành động ở giây 85 / 143 / 201 sau lần pet cuối ở giây 28: **mỗi 58 s**, đúng như tính toán.
  - Owner chào, vuốt, mở card: mood lên +0,18 ("vui"). Chip 44,8 °C.

## 9. Status card: nhãn tính cách (owner 2026-10-24: "oke thêm vào đi")

- Ô **"Tính cách"** thay "Lúc chơi thích". Ngữ cảnh chơi chỉ dạy được qua app, mà app đã bỏ đánh giá (D6 revised), nên ô đó luôn cũ.
- Nhãn suy ra bằng `Expression::traitWord`: lấy nét rõ nhất trong curiosity / sociability / playfulness / tempo / sensitivity (bẩm sinh + đã học), theo dấu:

| Trait | Dương | Âm |
|---|---|---|
| curiosity | tò mò | điềm tĩnh |
| sociability | quấn chủ | tự lập |
| playfulness | ham chơi | trầm |
| tempo | lanh lợi | thong thả |
| sensitivity | nhạy cảm | vô tư |

  Không nét nào đạt |0,05| thì hiện "cân bằng". PE-4b dùng lại nhãn này cho `PetSelf`. Ngưỡng là [P].
- "Đã sống" đổi thành **"Đã thức"**: đây là thời gian máy chạy, không phải tuổi tính từ lúc nở.
- Font sinh lại, +4 glyph (ô, ậ, ằ, ự), tổng 51,423 B.
- Kiểm tra: native/ASan **285/285**; ESP32 build SUCCESS (Flash 3,006,013 B).
- Board: backup NVS 2 lần khớp `42de3abf…`; upload SUCCESS, app `9880a767…`.
  - Boot `recover=Ok slot=1 boot=52 ready=1`, cùng PetId, quiet=1 play=0, stack 7,192 B.
  - Owner mở card lúc 13:35:10. Pet `d945…` hiện **"ham chơi"** (playfulness +0,13).

## 10. Board vẫn nóng: lượt 2 (owner 2026-10-24: "board đang khá nóng… xử lý triệt để", tự quyết miễn không ảnh hưởng trải nghiệm)

- **Còn lại sau §7:** CPU đã nghỉ khoảng 95 % thời gian, vẽ theo vùng bẩn. Nhiệt còn lại là công suất tĩnh: CPU idle ở 240 MHz, đèn nền 100 %, BLE quảng bá mỗi 20–40 ms, LDO 5 V → 3,3 V tỏa nhiệt theo dòng tổng.
- **Không làm được:** light sleep tự động và DFS. Arduino 2.0.14 build sẵn với `CONFIG_PM_ENABLE` tắt và `CONFIG_BT_CTRL_MODEM_SLEEP` tắt, nên muốn có phải build lại framework (ESP-IDF / arduino-as-component), quá lớn so với lợi ích.
- **Đã làm (firmware):**
  - `kCpuMhz = 80` (`src/BoardConfig.h`, `setCpuFrequencyMhz` đầu `setup()`). Đây là mức thấp nhất còn giữ BLE; APB vẫn 80 MHz. Env parity vẫn chạy 240 MHz để số `step()` còn so được.
  - `CpuBoost` (`include/DeviceKey.h`): nạp khóa và ký ECDSA chạy 240 MHz rồi trở lại 80 MHz, để ký proof không làm animation khựng (ở 80 MHz chậm khoảng 3 lần).
  - Đèn nền: chip LED của T-Display-S3 có 16 mức, chỉnh bằng xung (theo factory example của LilyGO), không phải PWM. `xuna/visual/Backlight.h` (core, thuần) chọn mức: **thức 12** (75 % dòng LED, trông khoảng 90 % độ sáng), **ngủ/nghỉ 7**, **card 16**. Đổi mức 1 bước mỗi 60 ms, nên chuyển mờ dần. `DisplayManager::setBacklight` phát xung 1 µs. Trên board đời cũ không có chip này, xung chỉ là nhiễu µs và đèn giữ 100 %, không hại gì.
  - BLE quảng bá 100–152,5 ms (`0xA0`–`0xF4`) thay vì 20–40 ms. App quét tối đa 12 s.
  - Diagnostics: `power loops=… chip_temp_c=… cpu_mhz=… backlight=…`; boot in `cpu_mhz=`.
- **Commit:** firmware `e4f5fe5` (Track A, đã có trên board từ trước) + `8b4e42b` (lượt nhiệt 2). Bản trên board build đúng từ cây này.
- **Kiểm tra:** native/ASan **304/304** (thêm `test_backlight` 5 case); ESP32 và parity build SUCCESS.
- **Board** (Mac, `/dev/cu.usbmodem14201`, buổi tối). Backup NVS trước mỗi upload, đọc 2 lần đều khớp, ở `~/xuna_backups/2026-10-24-heat2/` (`db77158c…` trước C1, `162234ef…` trước C2):

| | C0: bản đang chạy (240 MHz, đèn 100 %) | C1: 80 MHz + đèn + BLE | C2: C1 + CpuBoost (bản cuối, app `398d475c…`) |
|---|---|---|---|
| Thời gian log | 9 phút | 12 phút | 10 phút |
| Nhiệt chip ổn định | **44,8 °C** | **42,8 °C** | **41,8–42,8 °C** |
| Vòng/5 s | 495 | 495 | 494 |
| draw max | 4,96 ms | 7,56 ms | 7,57 ms |
| card push (scene max) | — | 43,8 ms | 43,8 ms |
| `device_key` lúc boot | 159 ms | 453 ms | 160 ms |
| Boot | — | `recover=Ok slot=1 boot=65`, cùng PetId, quiet=1 play=0 | `recover=Ok slot=0 boot=68`, cùng PetId, quiet=1 play=0 |

- Trong C1/C2 owner bấm nút nhiều lần (pet, shoo, greeting, status card). Mọi phản hồi bình thường; card hiện đèn 16 rồi mờ dần về 12. Heap đứng yên ở khoảng 230,5 KB. Không reset ngoài lần mở cổng, không lỗi.
- **Giới hạn đo:** cảm biến trong chip có bước khoảng 1 °C và không đo bề mặt board, LDO hay đèn nền. Phần lợi lớn nhất của việc giảm đèn và giảm dòng nằm ở LED và LDO, nên cảm biến chip chỉ thấy một phần. Nhiệt phòng buổi tối thấp hơn buổi trưa, nên không so trực tiếp với §7.
- **Chưa xác minh:** (1) mắt owner thấy đèn có mờ thật không (nếu board không có chip LED thì `backlight=12` vẫn in ra nhưng đèn giữ 100 %); (2) mức 7 lúc ngủ/nghỉ chưa gặp trên board trong 3 lần đo (chỉ có unit test); (3) app kết nối/ký proof ở 80 MHz + boost chưa thử bằng điện thoại trong buổi này.
- **Nếu vẫn nóng:** pin LiPo đang sạc qua USB (chip sạc tỏa nhiệt), hoặc đặt board nơi thoáng. Bước firmware tiếp theo là build lại framework có PM (light sleep), việc lớn, cần owner đồng ý.

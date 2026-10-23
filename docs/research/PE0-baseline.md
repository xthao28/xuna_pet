# PE-0 — Đo nền tính cách: XUNA khác nhau tới đâu chỉ nhờ learning (2026-10-23)

> **Trạng thái:** Research / lab-only. Không đổi `xuna_core` production, board, app hay snapshot. Mọi ngưỡng, xác suất owner và đề xuất ở đây là **[P] Proposed**.
>
> **Nhãn:** **[V]** đo trong lab hoặc đọc trong code · **[I]** suy luận · **[P]** đề xuất.
>
> **Plan:** [personality-plan-2026-10-23.md](../roadmap/personality/personality-plan-2026-10-23.md) §4 PE-0. **Số liệu thô:** [artifacts/PE0-baseline-output.txt](artifacts/PE0-baseline-output.txt) (107 dòng, chạy 2 lần giống hệt nhau).

## 1. Tóm tắt

1. **Hiện tại XUNA khác nhau hoàn toàn do owner, và hoàn toàn không do bản thân nó.** Hai owner khác sở thích thì XUNA chọn khác nhau ở 8/8 ô và JS ≈ 0.95 (tối đa 1). Cùng một kiểu owner thì XUNA chọn giống nhau ở 8/8 ô, JS ≈ 0.009. Nếu owner cư xử y hệt, 5 pet có PetId khác nhau cho ra **5 cuộc đời giống nhau tới từng bit**. [V]
2. **Ngưỡng §5 dòng 1 ("khác owner ≥ 3× khác seed") hiện đã đạt 104×**, chỉ nhờ learner. Như vậy ngưỡng này không đo được khí chất; G1 cần thêm tiêu chí về cá tính bẩm sinh (§5 của báo cáo này). [V/P]
3. **XUNA hiện rất "một màu".** Sau ngày đầu, mỗi ô gần như chỉ còn một hành động (hành động phổ biến nhất chiếm 97,6 %, entropy 0,09 / 1,585 bit). XUNA tự hành động khoảng 1.200 lần/ngày, cứ ~70 s một lần, cả ngày lẫn đêm. Theo trục "chọn hành động nào" thì gần như không còn chỗ cho tính cách thể hiện; tính cách phải hiện ra qua *khi nào, bao lâu, nhịp, độ đa dạng*. Điều này khớp rủi ro đã nêu ở plan §8. [V/I]
4. **Learning phản ứng nhanh và đúng như thiết kế.** Learning đổi theo owner trong khoảng 1 ngày (owner thưa thì 6 ngày). Một ngày bị shoo toàn bộ làm mất 25 % ô, rồi hồi lại sau 1 ngày. Owner ngẫu nhiên làm learner trôi khoảng 2 ô/ngày. Đây là nền để đặt mức "tính cách phải chậm hơn" (§4). [V]
5. **Đã có sẵn nguồn cho khí chất bẩm sinh:** `IdentityRecord.seed` (u32, sinh từ entropy khi migrate/nở, được lưu bền) **chưa được dùng ở đâu**. RNG của `LifeCore` trên board và trong lab dùng hằng số `seed = 1`. PE-1a nên seed genome từ `IdentityRecord.seed`, hoặc từ PetId như P-D5. [V/P]

## 2. Cách đo

**Runner:** `firmware/sim/personality_lab.cpp` (host, C++11, `-Werror`). Nó dùng `BoardLab`, bản sao `setup()/loop()` của board với cùng `BootSequence`, `V1LifeCoreAdapter` production, `LocalBehavior` và checkpoint 5 phút. Mỗi lần chạy là một pet mới migrate từ v1 (`fixtures::fresh`), sống 30 ngày địa phương với bước 1 s. Tổng cộng 70 lần chạy mất 7,5 s trên máy Windows (MSYS2 GCC 16.2). Kết quả tất định: hai lần chạy cho output giống từng byte. [V]

**Owner mô phỏng [P]:**
- **Lịch có mặt:** owner có mặt 07:00 trong 30 phút và 19:00 trong 2 giờ, mỗi mốc lệch ±30 phút ngẫu nhiên. Khi đến, app TimeSync. Cứ 15 phút owner bấm GPIO0 để chào (context greeting).
- **Cách phản ứng:** khi owner có mặt và XUNA vừa tự chọn một hành động (context quiet) hoặc vừa đáp lời chào, owner phản ứng với xác suất 30 %. `approves` → pet (GPIO0), ngược lại → shoo (GPIO14), trong vòng 1–4 s, tức là trong cửa sổ reaction 10 s.
- **Ngoài giờ có mặt:** XUNA vẫn tự hành động nhưng không ai phản ứng, đúng D6 revised: im lặng không dạy gì.
- **Mức độ:** cấu hình này tương đương khoảng 33 lần pet/shoo mỗi ngày, tức một owner khá chăm.

**Owner model:** `OwnerModel.h` được thêm 5 loại. Bốn loại đầu nằm trong plan, Alternating thêm để chạy kịch bản "mâu thuẫn xen kẽ" ở §5.

| Kind | Định nghĩa [P] |
|---|---|
| Noisy | Sở thích cố định nhưng yếu: approve 0.6 cho hành động thích / 0.4 cho hành động khác |
| Sparse | Như Oracle nhưng chỉ phản ứng 5 % số lần |
| Random | Không có sở thích thật: approve 0.5 cho mọi hành động |
| Teacher | Luôn phản ứng, luôn nhất quán (1 / 0) |
| Alternating | Đổi qua lại giữa hai bộ sở thích theo chu kỳ `period` |

**Profile sở thích** (quiet, greeting): P0 = idle, happy · P1 = curious, curious · P2 = happy, idle.

**Metric:**
- **Hành vi** là số lần idle/happy/curious được thể hiện trong mỗi ô learner, với ô = quiet hoặc greeting × day part 0–4. Context play cần app nên không đo.
- **Khoảng cách** giữa hai hành vi là trung bình JS divergence (bit, từ 0 đến 1) trên các ô mà cả hai bên có ≥ 10 mẫu (≥ 5 khi so từng ngày).
- **"Ô theo owner"** là tỉ lệ trong 8 ô fine (quiet/greeting × sáng…đêm) có lựa chọn greedy của learner trùng với sở thích owner.
- **"Flip"** là một ô có lựa chọn greedy đổi qua đêm.

## 3. Kết quả theo kịch bản §5

Trung bình 5 seed (riêng kịch bản owners là 15 lần chạy). "Tuần cuối" là ngày 23–29.

| Kịch bản §5 | Đo được hôm nay (learning) [V] | Ý nghĩa cho tính cách |
|---|---|---|
| Cùng seed, owner khác nhau, 30 ngày | JS giữa owner **0,951**; JS cùng owner khác seed **0,009** → tỉ lệ **104×**. Greedy khác nhau: 100 % ô giữa owner, 0 % trong cùng owner | Ngưỡng "≥ 3×" đã đạt sẵn. Khác biệt "cùng owner" bằng 0, tức chưa có cá tính bẩm sinh |
| (thêm) Chỉ đổi PetId/entropy | **4/4 cuộc đời giống seed 1 tới từng bit**, JS 0 | Nguyên nhân: RNG `LifeCore` cố định = 1 trên board và lab |
| Không tương tác dài (owner đi từ ngày 14) | Learner không đổi 5/5; JS tuần 2 so với tuần 5 = **0**. Ô greeting biến mất vì không ai bấm. Day part vẫn giữ: clock chuyển `Approximate` sau 24 h và giữ tới khi reboot | Δ = 0 đạt sẵn ở tầng learning; tính cách phải giữ được điều này (không "buồn dần" vì vắng chủ) |
| Owner ngẫu nhiên | **1,97 flip/ngày**, JS tuần 1 so với tuần 4 **0,44**, theo profile 42 % (mức may rủi) | Learning trôi theo owner ngẫu nhiên; tính cách phải có drift ≈ 0 (chốt nhất quán dấu ≥ 2/3) |
| Owner noisy | **0,51 flip/ngày**, JS tuần 1 so với tuần 4 0,19, vẫn theo profile 92,5 % | Learning vẫn đúng hướng nhưng dao động |
| Một sự kiện cực đoan | *Trait: N/A tới PE-1.* Hành vi: một ngày bị shoo toàn bộ → mất **25 %** ô theo owner, JS 0,12, hồi lại sau **1 ngày** (5/5) | Tính cách: Δ = 0 trước consolidation |
| Owner im lặng (NoFeedback) | Learner bằng lúc boot 5/5; toàn bộ greedy = idle; JS tuần 1 so với tuần 4 0,009 (nhiễu lấy mẫu) | Đạt sẵn |
| Mâu thuẫn xen kẽ (đổi mỗi 2 ngày) | **3,17 flip/ngày** (trên 10 ô), JS giữa các khối 2 ngày 0,08 | Learning dao động theo owner; tính cách phải có biên độ ≈ 0 |
| Preference đảo (ngày 15, P1 → P2) | Nửa số lựa chọn quiet đổi sau **0,6 ngày**; 75 % ô đổi sau **3,6 ngày** | Tính cách ≥ 5× chậm hơn → **≥ 18 ngày** cho mức 75 % [P] |
| Học nhanh tới đâu (thêm) | Oracle 30 %: 75 % ô theo owner ở **ngày 1,3**; Teacher **ngày 1,0**; Sparse 5 % **ngày 6,4**; cả ba đạt 100 % ở ngày 29 | Nền tốc độ |
| Ổn định theo ngày (thêm) | Owner nhất quán: JS ngày-ngày 0,008 (nhiễu lấy mẫu), 0 flip/ngày | Nền độ ổn định |
| Trait không đè learning | N/A tới PE-1d/PE-4a | — |
| Spam chat khen/chê | N/A tới PE-4c | — |
| Reboot / restore / ESP32 bit-identical | N/A cho trait tới PE-3. Learner đã có kịch bản E và S21 parity | — |

**Độ đa dạng [V]:** trong tuần cuối, entropy hành động mỗi ô là 0,091 bit (tối đa 1,585) và hành động nhiều nhất chiếm 97,6 % số lần. Owner P1 thấy XUNA "curious" gần như mọi lúc, khoảng 1.200 lần/ngày.

## 4. Ngưỡng PE-1 / G1 suy ra từ nền [P]

| Tiêu chí | Nền hôm nay | Ngưỡng đề xuất cho tính cách |
|---|---|---|
| Đảo sở thích → tính cách dịch | Learning: 75 % ô trong 3,6 ngày | Trait dịch đủ để gắn nhãn mới ≥ 18 ngày (5×) |
| Owner ngẫu nhiên | Learning: 1,97 flip/ngày | Δ trait sau 30 ngày ≤ 1 bước consolidation (≤ 0,03) |
| Xen kẽ 2 ngày | Learning: 3,17 flip/ngày | Biên độ trait ≈ 0 (không có consolidation nào ngược dấu) |
| Một ngày cực đoan | Learning: −25 % ô, hồi sau 1 ngày | Δ trait = 0 (chưa đủ ≥ 3 buổi khác nhau) |
| Vắng chủ / im lặng | Learning Δ = 0 | Δ trait = 0; mood được phép dao động rồi về baseline |
| Trait không đè learning | Learning đạt 75 % ô trong 1,3 ngày | Với mọi genome: vẫn ≤ 2 ngày và 100 % ô ở ngày 29 |

## 5. Đề xuất sửa §5 / G1 của plan [P]

1. **Giữ dòng "khác owner ≥ 3× cùng owner khác seed"**, vì nó bảo đảm owner vẫn là yếu tố chính. Ghi rõ: hôm nay đã đạt 104× nên dòng này chỉ là **chốt không được làm hỏng**, không phải mục tiêu.
2. **Thêm tiêu chí cá tính bẩm sinh:** cùng owner, khác `IdentityRecord.seed` → khác biệt **nhìn thấy được**, đo bằng JS hành vi hoặc phân bố *thời điểm/nhịp* (không chỉ action) ≥ 0,1, mà vẫn giữ tiêu chí 1. Hôm nay giá trị này là 0.
3. **Thêm tiêu chí đa dạng:** entropy hành động trong một ô > nền 0,09 bit ở chế độ shadow. Hoặc nếu G1 chỉ báo cáo, phải nói thẳng rằng tính cách không thể hiện qua lựa chọn action với 3 animation (rủi ro §8, Track A).
4. **Seed genome từ `IdentityRecord.seed`** (đã bền, đã có cho pet hiện tại `d945…`). Việc này không đổi P-D5: seed vẫn sinh cùng lúc với PetId. Seed RNG của `LifeCore` hiện vẫn để nguyên là 1; đổi nó sẽ làm khác golden vectors và parity, nên cần quyết định riêng ở PE-2.

## 6. Giới hạn của lần đo này

- **Owner đơn giản hoá:** lịch cố định, không có cuối tuần, không dùng app (không có context play, không có câu nói được xác nhận), không reboot, chỉ dùng pet mới migrate. Có 5 seed mỗi kịch bản. Xác suất phản ứng 30 % là một owner chăm; Sparse 5 % gần owner thật hơn [I].
- **Chỉ có trong lab:** chưa đo trên board. `BoardLab` đã được S19b/S21 chứng minh là khớp board về logic, nhưng không có animation hay thời gian render.
- **Nhiễu lấy mẫu:** JS ngày-ngày khoảng 0,008 là sàn nhiễu (ô greeting ít mẫu), không phải thay đổi thật.
- **`native_asan` chưa chạy** (không có trên Windows). Native test 242/242 và ESP32 build + purity đều PASS.

## 7. Thay đổi kèm theo (firmware, host only)

- `lib/xuna_core/include/xuna/lab/OwnerModel.h`: thêm 5 owner kind (lab-only; các kind cũ giữ nguyên hành vi, kể cả số lần rút RNG).
- `test/test_life_lab`: thêm 2 test (định nghĩa các kind, tần suất của Sparse).
- `sim/personality_lab.cpp`: runner mới; cách build ở `sim/README.md`.
- Sửa 3 test vốn chỉ lỗi trên toolchain Windows (GCC 16): `test_habit` so sánh cả byte padding của `HabitState` → đổi sang so từng field; `test_identity` lỗi `-Wmisleading-indentation`; `test_life_lab_scenarios` thiếu `<cstdio>`. Trên Windows trước đây có 1 test fail và 2 suite không compile; nay **242/242**.

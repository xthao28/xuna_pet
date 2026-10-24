# PE-1 — PoC tính cách trong Life Lab: báo cáo Gate G1 (2026-10-23)

> **Trạng thái:** Research / lab-only, chờ owner quyết G1. Không đổi `xuna_core` production, board, app hay snapshot. Mọi tham số là **[P]**.
>
> **Nhãn:** **[V]** đo trong lab hoặc đọc trong code · **[I]** suy luận · **[P]** đề xuất.
>
> **Plan:** [personality-plan-2026-10-23.md](../roadmap/personality/personality-plan-2026-10-23.md) §4 PE-1, §5. **Nền:** [PE0-baseline.md](PE0-baseline.md). **Số liệu thô:** [artifacts/PE1-shadow-output.txt](artifacts/PE1-shadow-output.txt). Runner tất định: hai lần chạy giống từng byte; 33 s trên máy Windows.

## 1. Tóm tắt cho owner

1. **Các chốt an toàn đều đạt.**
   - Tính cách **không đổi chút nào** khi vắng chủ, khi XUNA tự hành động một mình, khi owner im lặng, hay khi có một ngày tệ (Δ = 0).
   - Owner ngẫu nhiên chỉ làm trait trôi 0,008, chưa bằng 1/3 bước. Owner thích XUNA tò mò thì curiosity tăng +0,15 sau 30 ngày và +0,40 sau 90 ngày.
   - Owner đổi sở thích: learning đảo theo trong 3,6 ngày, còn tính cách gần như không đổi trong 15 ngày tiếp theo. Thay đổi tính cách cần nhiều tuần.
   - Vắng chủ không bao giờ làm XUNA buồn: mood quay về mức nền của nó. [V]
2. **Tính cách không bao giờ đè lên điều XUNA đã học.** Ở 100 % các ô, lựa chọn "có tính cách" vẫn trùng với lựa chọn learner đã học từ owner. [V]
3. **Nhưng với 3 animation hiện có, khí chất bẩm sinh không nhìn thấy được qua việc XUNA chọn làm gì.** Năm pet khác khí chất sống với cùng một owner vẫn chọn giống hệt nhau (JS = 0), kể cả khi tăng trọng số drive lên 0,5. Lý do: sở thích đã học mạnh hơn drive, và cho drive thắng sở thích thì lại vi phạm nguyên tắc ở điểm 2. Khí chất chỉ có thể hiện ra qua **nhịp, thời điểm, độ dài và cảm xúc**. Với ánh xạ hiện tại thì các khác biệt này rất nhỏ: tốc độ frame chỉ chênh khoảng 4 điểm %, độ mạnh cảm xúc ±14 %, độ sớm muốn khám phá ±10 %. [V/I]
4. **Ngưỡng §5 dòng 1 ("khác owner ≥ 3× khác seed") chưa đạt:** 0,49 ở ngày 30, 0,88 ở ngày 60, 1,35 ở ngày 90. Tỉ lệ tăng đều theo thời gian. Nghĩa là tháng đầu khí chất bẩm sinh còn lấn át, sau khoảng 2 tháng thì cách owner sống cùng XUNA vượt lên. [V]
5. **Owner cần quyết 4 việc ở G1** (§7). Khuyến nghị: **qua G1**, chọn tham số "4 buổi", đổi cách diễn đạt ngưỡng dòng 1, rồi làm PE-2 tập trung vào **biểu hiện** (nhịp/cảm xúc) và đi song song với Track A (animation mới).

## 2. Đã xây (firmware, lab-only)

| Phần | File | Nội dung |
|---|---|---|
| PE-1a | `xuna/personality/Temperament.h`, `EvidenceLedger.h` | Genome 10 trait (bẩm sinh ±0,15 từ `IdentityRecord.seed`, phần học ±0,6). Ledger có nguồn gốc/trọng số/lý do, gom theo buổi, mỗi buổi đóng góp tối đa ±0,5, chốt nhất quán, mỗi lần dịch ≤ 0,03, nhật ký 4 mục. Ngưỡng nay cấu hình được qua `LedgerConfig` |
| PE-1b | `xuna/life/Drives.h` | explore, social, play, boredom; tốc độ theo genome; social bão hoà trong 2 h rồi tự lắng về 0 |
| PE-1c | `xuna/life/Affect.h` | Emotion ⇄ mood (hai lò xo); cảm xúc từ kỳ vọng (vui bất ngờ / hài lòng / thất vọng / hơi buồn / chào đón); competence; mood có sàn −0,5. **O1: mặc định theo uỷ quyền** (sensitivity chỉ làm cảm xúc mạnh và lâu hơn, không gây dè dặt lâu dài) |
| PE-1d | `xuna/lab/PersonalityShadow.h`, `sim/personality_lab.cpp` | Shadow chạy cạnh BoardLab: nhận input của owner, quyết định XUNA đã hiển thị, pet/shoo → bằng chứng, drive, affect, consolidation khi kết thúc buổi, và lựa chọn "nếu có tính cách". Hành vi thật của XUNA không đổi: các metric PE-0 giữ nguyên từng byte |

**Nguồn bằng chứng [P]** (chỉ từ owner hoặc thế giới thật, không bao giờ từ hành động của chính XUNA):

| Trait | Bằng chứng | Mã lý do |
|---|---|---|
| Curiosity | Owner phản ứng với lựa chọn curious hoặc lựa chọn khám phá, e = kết quả − p̂ | ExploreRewarded / ExploreShooed |
| Playfulness | Như trên, với lựa chọn happy | PlayRewarded / PlayShooed |
| Sociability | Như trên, với câu trả lời khi được chào | GreetingPetted / GreetingShooed |
| Tempo | Mật độ input trong một buổi (≥ 8 → lively, ≤ 2 → calm), device-observed | LivelySession / CalmSession |
| 6 trait còn lại | Không có (chỉ có phần bẩm sinh, theo mặc định O1) | — |

**Sửa trong lúc làm:** ban đầu sociability nhận ±1 cố định cho mỗi lần pet/shoo câu chào. Với cách đó, mọi owner nhất quán đều đẩy sociability lên trần +0,6 trong khoảng 3 tháng: tự phình, vi phạm research §8.2.2. Giờ sociability dùng sai số dự đoán như hai trait kia, nên P0 chỉ còn +0,018 sau 90 ngày.

## 3. Kết quả theo §5

Mỗi kịch bản 5 seed; owner và lịch có mặt như PE-0. Tham số mặc định: 3 buổi, nhất quán 0,5.

| Kịch bản §5 | Ngưỡng | PE-1 (shadow) [V] | Kết quả |
|---|---|---|---|
| Cùng seed, khác owner, 30 ngày | ≥ 3× so với cùng owner khác seed | Khoảng cách trait 0,050 so với 0,102 → **0,49**; ngày 60: 0,88; ngày 90: 1,35 | **Chưa đạt** (§7 G1-b) |
| Không tương tác dài | Δ = 0 | Δ trait ngày 13→29 = **0**; mood − mức nền = 0,003 | Đạt |
| Owner ngẫu nhiên / noisy | Drift ≈ 0 | \|offset\| của trait do phản ứng: **0,008 / 0,009**; dao động 0,006 / 0,005 | Đạt (< 1/3 bước) |
| Một sự kiện cực đoan | Δ = 0 trước consolidation | Δ trait ngày 19→21 = **0**; mood chạm sàn −0,5 rồi hồi về 0,093 (trước đó 0,095) | Đạt |
| Owner im lặng | Δ = 0 | 3 trait do phản ứng: **0**; tempo −0,007 (mật độ buổi là hành vi thật của owner) | Đạt |
| Mâu thuẫn xen kẽ (2 ngày) | Biên độ ≈ 0 | Dao động 0,017 (khoảng nửa bước) | Gần đạt; "4 buổi" còn 0,009 |
| Preference đảo | Tính cách chậm hơn ≥ 5× | Learning đảo trong 3,6 ngày; curiosity chỉ −0,003 trong 15 ngày sau đó (trước đó +0,066 trong 15 ngày) | Đạt (chậm hơn rất nhiều) |
| Trait không đè learning | Lựa chọn giống nhau ở mọi genome | Lựa chọn shadow = greedy của learner ở **100 %** ô; test: drive đầy vẫn chọn đúng điều owner đã dạy | Đạt |
| Spam chat | ≤ cap ngày | N/A tới PE-4c. Ledger đã giới hạn ±0,5 mỗi buổi (có test) | — |
| Reboot / ESP32 | Bit-identical | N/A tới PE-2/PE-3. Mọi update tách nhỏ cho kết quả giống một lần update gộp, kể cả khi `millis()` quay vòng (có test) | — |
| *(PE-0 đề xuất)* Cùng owner, khác seed: nhìn thấy được | JS ≥ 0,1 | JS hành vi shadow = **0**. Chênh lệch giữa 5 pet: frame 3,8 điểm %, độ mạnh cảm xúc 0,14 (mức trung tính 0,5), tốc độ muốn khám phá 19 %, mood trung bình 0,06 | **Không đạt** qua action; chỉ thấy qua nhịp/cảm xúc |
| *(PE-0 đề xuất)* Đa dạng trong một ô | > 0,09 bit | 0,053 (learner một mình: 0,091; shadow bỏ phần thăm dò UCB) | **Không đạt** |

**Tốc độ [V]** (offset học được sau 30 ngày, trung bình 5 pet):
- Owner P1 (thích tò mò): curiosity +0,146.
- Owner P2 (thích vui): playfulness +0,136.
- Teacher (luôn phản ứng): curiosity +0,45.
- Sparse (5 %): curiosity +0,019.
- Mọi owner: tempo +0,09, do cùng một lịch có mặt.

Sau 90 ngày: P1 curiosity +0,40, P2 playfulness +0,39.

## 4. Nhìn thấy được gì với 3 action (yêu cầu của G1)

| Khác biệt | Thấy được với 3 action hiện có? | Cần gì |
|---|---|---|
| Owner A và owner B nuôi khác nhau | **Có, rất rõ.** Learning đã lo phần này (PE-0: 8/8 ô khác nhau) | — |
| Tính cách học được (curiosity, playfulness) | Gián tiếp: trait đi theo đúng hướng owner, nhưng lựa chọn action vốn đã đi theo owner | Biểu hiện riêng: nhịp/độ dài/cảm xúc, câu chữ trong chat (PE-4b) |
| Khí chất bẩm sinh dưới cùng một owner | **Không**, nếu chỉ dựa vào việc chọn action | PE-2: frame/độ dài reaction/tần suất hành động tự phát theo trait, ánh xạ đủ mạnh (§7 G1-c); Track A: action riêng cho drive `play`/`explore` |
| Mood và cảm xúc tức thời | Chưa: chưa có kênh hiển thị (màn hình chưa dùng mood) | PE-2: mood/tempo → frame ±15 %, dòng tâm trạng trên status card |

## 5. Quét tham số ledger [V]

Trait do phản ứng gồm curiosity, sociability, playfulness. "Tín hiệu" là curiosity của owner P1 sau 30 ngày.

| Số buổi tối thiểu | Ngưỡng nhất quán | Drift owner ngẫu nhiên | Dao động owner ngẫu nhiên | Tín hiệu P1 | Biên độ xen kẽ |
|---|---|---|---|---|---|
| 3 | 0,50 *(hiện tại)* | 0,0081 | 0,0060 | 0,146 | 0,0173 |
| 3 | 0,60 | 0,0028 | 0,0028 | 0,087 | 0,0104 |
| 3 | 0,75 | 0 | 0 | 0,028 | 0 |
| **4** | **0,50** | **0,0033** | **0,0022** | **0,116** | **0,0088** |
| 4 | 0,60 | 0 | 0 | 0,072 | 0,0067 |
| 5 | 0,50 | 0 | 0 | 0,076 | 0,0044 |
| 5 | 0,75 | 0 | 0 | 0,009 | 0 |

Trọng số drive trong lựa chọn shadow (0 → 0,5) cho độ đa dạng 0 → 0,044 bit. Khác biệt giữa các pet cùng owner vẫn ≈ 0, và lựa chọn vẫn luôn trùng learner.

## 6. Giới hạn

- **Owner đơn giản hoá** như PE-0: lịch có mặt cố định, 5 seed, không có app/chat, không reboot. Tempo vì thế nhận cùng một tín hiệu ở mọi kịch bản.
- **Lựa chọn shadow là một chính sách đề xuất** (p̂ + trọng số × drive − boredom khi lặp lại). `BehaviorSelector` có sẵn không phù hợp. Trong thang điểm của nó, novelty góp tối đa khoảng 2 điểm so với `bias` kiểu int16, và các số hạng needs/mood giống nhau cho mọi ứng viên, nên không phân biệt được action nào [V, đọc code]. Vì vậy chưa dùng nó; ở PE-4a cần viết lại hoặc bỏ [P].
- **Chưa kiểm:** `native_asan` (Mac/WSL), compile xtensa cho các header mới (chúng không nằm trong image), board.
- Mức trung tính và ngưỡng trong Drives/Affect chưa được quét, chỉ có ledger và trọng số drive được quét.

## 7. Quyết định G1 cho owner

**G1-a — Tham số ledger**
- **(A, khuyến nghị) 4 buổi, nhất quán 0,5:** drift owner ngẫu nhiên 0,003, biên độ xen kẽ 0,009, tín hiệu +0,12 mỗi tháng.
- (B) Giữ 3 buổi, nhất quán 0,5: tín hiệu mạnh nhất (+0,15), nhưng xen kẽ dao động khoảng nửa bước.
- (C) 5 buổi, nhất quán 0,5: gần như không trôi, nhưng tín hiệu chỉ +0,08 mỗi tháng (thay đổi chậm, có thể khó cảm nhận).

**G1-b — Ngưỡng §5 dòng 1**
- **(A, khuyến nghị) Đổi cách diễn đạt:** "ảnh hưởng của owner vượt khí chất bẩm sinh sau ≤ 3 tháng và tiếp tục tăng". Hôm nay đạt 1,35 ở ngày 90. Cách này khớp câu chuyện sản phẩm: XUNA mới nở có khí chất riêng, rồi dần thành cá thể do owner nuôi.
- (B) Giảm khí chất bẩm sinh xuống ±0,10 để đạt 3× sớm hơn. Đổi lại, cá tính bẩm sinh càng khó thấy.
- (C) Tăng bước dịch (0,03 → 0,05). Đổi lại, trait trôi nhiều hơn với owner ngẫu nhiên.

**G1-c — PE-2 phải làm cho cá tính nhìn thấy được**
- **(A, khuyến nghị) Biểu hiện mạnh hơn và chỉ qua nhịp/cảm xúc:**
  - Đo ±15 % tốc độ frame theo **khoảng thực tế của trait** (±0,3 → ±15 %), không theo ±1.
  - Độ dài reaction theo sensitivity.
  - Tần suất hành động tự phát theo drive.
  - Track A (2–4 animation mới) chạy song song.
  - Không bao giờ để drive đè lên điều đã học.
- (B) Cho drive thắng sở thích khi chênh lệch nhỏ. Đổi lại, vi phạm "trait không đè learning", nên mình không khuyến nghị.

**G1-d — Nguồn bằng chứng cho sociability**
- **(A, khuyến nghị)** Đến PE-4 thêm bằng chứng device-observed: owner chủ động chào bao nhiêu lần, buổi dài hay ngắn. Tới lúc đó sociability chủ yếu là bẩm sinh.
- (B) Quay lại ±1 cố định. Không khuyến nghị: đã thấy nó tự phình.

**Go / no-go:** khuyến nghị **qua G1 sang PE-2** (shadow trên board + biểu hiện), áp dụng (A) cho cả bốn quyết định trên.

**Owner quyết định (2026-10-24):** qua G1, áp dụng (A) cho cả bốn. Kết quả áp dụng: [PE-2 record](../roadmap/personality/PE2-board-shadow-2026-10-24.md).

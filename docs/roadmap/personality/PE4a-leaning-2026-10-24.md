# PE-4a — Tính cách nghiêng lựa chọn của XUNA (2026-10-24)

> Plan: [personality-plan-2026-10-23.md](personality-plan-2026-10-23.md) §4 PE-4a. Owner: "oke làm PE-4a thôi".
> Trạng thái: **Implemented (host, Windows), chưa upload board**. Mọi tham số vẫn **[P]**; owner chọn mức trước khi upload (§6).
> Máy: Windows (MSYS2 UCRT64 g++, PlatformIO). `native_asan` chưa chạy (chỉ có trên Mac/WSL).

## 1. Ý tưởng

Trước PE-4a, tính cách chỉ đổi *nhịp* (frame, độ dài reaction, khi nào XUNA tự làm gì). Từ PE-4a nó đổi cả *chọn gì*, nhưng **chỉ ở chỗ learning chưa có câu trả lời**:

- Khi các hành động **hoà điểm** (chưa ai dạy ô đó, hoặc các hành động chưa được phân biệt), XUNA không bốc đều nữa mà bốc theo trọng số:
  - curious ← curiosity;
  - happy ← playfulness (quiet/play) hoặc sociability (khi được chào bằng GPIO0);
  - idle giữ 1, làm mốc "điềm tĩnh". Pet bị owner làm bớt tò mò và bớt ham chơi thì tự khắc idle nhiều hơn.
- Trọng số = 1 ± gain × trait/0,3 (đủ hiệu lực ở |trait| 0,3, như Expression), sàn 0,125: tính cách không bao giờ loại hẳn một hành động.
- Không đụng p̂, UCB bonus, bằng chứng hay snapshot. Owner dạy (dù chỉ một lần pet/shoo) là điểm số lệch nhau, hết hoà, và tính cách không còn tác dụng ở ô đó.
- Genome trung tính (chưa có identity) thì mọi trọng số bằng nhau: chọn y hệt learning một mình, kể cả số lần rút RNG.

## 2. Đã làm (firmware)

- `learning/PreferenceLearnerV3.h`: `V3Leaning` (trọng số + `marginQ16`), `choose(..., leaning)`; `pick` bốc theo trọng số khi các hành động hoà có trọng số khác nhau, ngược lại đi đường cũ từng bit. Margin > 0 (tắt trên board) cho phép tính cách quyết cả các ô "gần hoà"; chỉ có hiệu lực khi trọng số khác nhau.
- `learning/ProductLearner.h`: chuyển `leaning` xuống learner (mặc định = không nghiêng).
- `personality/Leaning.h` (mới): `LeaningConfig` (`tieGainQ8 = 256` tức ±1, `marginQ16 = 0`), `Leaning::forChoice(genome, interaction, config)`.
- `life/LifeCore.h`: `decide()` tính lean từ genome của chính pet; `setLeaning()` cho Life Lab.
- `lab/BoardLab.h`: `setLeaning()` áp cho mọi lần boot (chỉ lab).
- `sim/personality_lab.cpp`: `Run::leaning`, metric `pe4` (chuyển giao sang ô chưa dạy), `sweepLeaning()` (`./personality_lab leaning`).
- `test/test_leaning/` (6 test): genome trung tính = learning một mình (900 lựa chọn, cùng fingerprint, cùng RNG); ô chưa dạy theo trọng số; **3 bài học thắng mọi khí chất** (rating và reaction, genome cực đại cả hai dấu, cả 3 ngữ cảnh, kể cả margin 0,03); margin chỉ quyết khi gần hoà; ánh xạ trait; BoardLab một ngày: pet sinh ra tò mò chọn curious nhiều hơn hẳn khi bật.

## 3. Thử và bỏ (Life Lab, [output](../../research/artifacts/PE4a-sweep-levers.txt))

Lần quét đầu (lúc đó idle còn gắn với −tempo, và còn hai đòn bẩy dưới đây trong code):

| Đòn bẩy | Kết quả | Quyết định |
|---|---|---|
| Curiosity nhân UCB bonus ×(1 ± 0,5) (đề xuất của research) | Không đổi gì nhìn thấy được: ô đã dạy hội tụ mạnh (p̂ ≈ 0,9), bonus ×1,5 không bao giờ thắng; ô chưa dạy thì mọi bonus bằng nhau | Bỏ |
| Drive (explore → curious, play → happy) trong trọng số | Owner noisy: 4/21 đời không bao giờ đạt 75 % ô; ngày 29 chỉ 0,815 ô theo owner (tắt: 0,881) | Bỏ (giống PE-2b) |
| Idle ← −tempo | Mọi owner trong lab đều có buổi dày nên tempo tăng ở tất cả; idle ở ô chưa dạy còn 6–9 % cho mọi pet, kể cả owner thích idle | Bỏ: tempo chỉ đổi nhịp, idle giữ 1 |

`BehaviorSelector` vẫn không được wire (G1 report §6: thang điểm của nó không phân biệt được action).

## 4. Kiểm tra (Windows)

| Kiểm tra | Kết quả |
|---|---|
| native | **312/312** (306 + 6 `test_leaning`) |
| native_asan | **chưa chạy** (Mac/WSL) |
| ESP32 `xuna_t_display_s3` + purity | SUCCESS: RAM 54,904 B (+8), Flash 3,895,233 B (+528) |
| ESP32 `xuna_parity` | build SUCCESS (38,464 B RAM); chưa chạy trên board |
| Trace c3 / c8 / c9 (host) | **giữ nguyên** `7b06fbf8` / `add477bf` / `a5491046` (trace không có identity: genome trung tính) |
| Golden S20 `learning_v1.json` | **đổi, chủ đích**: pet trong golden có identity nên các lựa chọn chưa dạy nghiêng theo khí chất. Đã tạo lại và chép sang `mobile/test/fixtures/firmware/`; mobile `firmware_golden_test.dart` 5/5 (Flutter 3.32.8) |
| Life Lab baseline trên Windows | md5 (LF) `ca3cc133…` = Mac PE-2b, nên so sánh được |
| Life Lab PE-4a | md5 (LF) `3c59a49b…`, [output](../../research/artifacts/PE4a-leaning-output.txt), 230 s |
| sim khác | đều biên dịch; `card_preview`/`migration_check` cần cờ riêng và GCC báo comment nhiều dòng (có từ trước). `lifecore_lab` cần `-Wl,--stack,67108864` trên Windows (stack mặc định 1 MB → segfault ở c9; có từ trước) |

## 5. Số liệu (Life Lab, mặc định board: trọng số ±1, margin 0)

**Thấy được gì:**

- **Tính cách học được chuyển sang tình huống chưa ai dạy** (ngữ cảnh play, lab không dùng; genome ngày 89, trung bình 5 pet; không nghiêng = 1/3):

  | Owner | idle | happy | curious |
  |---|---|---|---|
  | P0 (quiet idle, greeting happy) | 0,32 | 0,34 | 0,33 |
  | P1 (thích tò mò) | 0,25 | 0,27 | **0,48** |
  | P2 (thích vui) | 0,26 | **0,47** | 0,27 |

- **Khí chất bẩm sinh** (cùng owner im lặng, khác PetId): JS giữa các pet 0,003 → 0,014–0,022. Vẫn nhỏ: baseline ±0,15 chỉ lệch xác suất vài phần trăm. Phần "pet mới nở khác nhau" vẫn chủ yếu thấy qua nhịp (PE-2b: 10,7 %).
- Owner nhất quán dạy hết các ô trong khoảng 1 ngày, nên ở tuần cuối các pet cùng owner gần như giống nhau. Đúng nguyên tắc "không đè learning".

**An toàn (baseline PE-2b → PE-4a):**

| Kịch bản | Trước | Sau |
|---|---|---|
| Owner ngẫu nhiên: \|offset\| học được | 0,0035 | 0,0037 |
| Noisy: ô theo owner ngày 29 | 0,825 | 0,925 |
| Ngày tệ: trait đổi ngày 19→21 | 0,0011 | 0,0008 |
| Vắng chủ: trait đổi | 0 | 0 |
| Xen kẽ: biên độ trait | 0,0086 | 0,0064 |
| Đảo sở thích: số ngày tới 75 % ô | 5,0 | 3,8 |
| Oracle: ngày đầu 75 % ô | 1,07 | 1,20 |
| Sparse: ngày đầu 75 % ô (5 đời) | 5,0 | 2,2 |

- Tốc độ học với owner sparse/noisy **rất nhiễu**. Với 60 đời mỗi biến thể, độ lệch giữa các biến thể (kể cả giữa "tắt" ở hai lần chạy khác owner) vẫn tới ±2 ngày, và không có chiều rõ ràng. Ngày 29 mọi biến thể đều theo owner như nhau.
- **Theo dõi:** §5 dòng 1 (G1-b) ở ngày 29 / 59 / 89 = 0,34 / 0,61 / **0,86** (PE-2b: 0,36 / 0,67 / 0,98). Vẫn tăng đều nhưng dưới 1 ở ngày 89. Với cách ánh xạ cũ (idle ← −tempo) nó là 1,04, nên chỉ số này dao động khoảng ±0,1 theo thiết kế. Nếu owner muốn biên an toàn: thêm bằng chứng device-observed cho sociability (G1-d) ở PE-4, không nới ledger.

**Quét gain** (cột đầy đủ trong output, dòng `leaning`):

| Biến thể | JS pet im lặng | Sparse ngày 75 % | Noisy ngày 75 % (không đạt /60) | Noisy ngày 29 | Owner ngẫu nhiên | Đảo |
|---|---|---|---|---|---|---|
| tắt | 0,003 | 2,9 | 4,2 (0) | 0,875 | 0,0030 | 4,5 |
| ±0,5 | 0,022 | 4,7 | 4,3 (2) | 0,877 | 0,0027 | 3,8 |
| **±1 (mặc định)** | 0,014 | 4,8 | 4,4 (1) | 0,892 | 0,0031 | 4,0 |
| ±0,5 + margin 0,03 | 0,022 | 4,1 | 3,7 (1) | 0,925 | 0,0021 | 4,5 |
| ±1 + margin 0,03 | 0,014 | 4,9 | 4,3 (0) | 0,840 | 0,0028 | 2,8 |

## 6. Quyết định cho owner (trước khi upload)

- **(A, khuyến nghị) ±1, chỉ hoà tuyệt đối:** chuyển giao tính cách rõ nhất (khoảng 48 % so với 33 %), không bao giờ đè lên điều owner đã dạy dù chỉ một lần.
- (B) ±0,5: nhẹ hơn; với cùng genome ngày 89, chuyển giao khoảng 43 % (tính từ trọng số, chưa chạy riêng).
- (C) Thêm margin 0,03: tính cách quyết cả khi bài học của owner "huề nhau". Số liệu không cho thấy lợi rõ, và nó nới nguyên tắc §5.
- (D) Tắt: tính cách chỉ ở nhịp như PE-2.

**Pet trên board (`d945…`):** khí chất gần trung tính (PE-2 record: tempo −0,04, sensitivity +0,02, playfulness +0,13). Ô nào owner đã dạy thì giữ nguyên; thay đổi chỉ ở các ô chưa dạy (ví dụ ngữ cảnh play từ app, các buổi trong ngày ít gặp). Chưa đọc NVS để biết bao nhiêu ô còn trống.

## 7. Chưa làm

- Upload board: NVS backup → parity (`step()` p99) → production → owner quan sát.
- `native_asan`.
- Journal / "Vì sao?" chưa nói "XUNA chọn vì tính cách". Nhãn explore trong explanation vẫn như cũ.
- PE-4b (PetSelf + giọng LLM), PE-4c (cần O4/O5), PE-4d (nút đặt lại / bỏ thay đổi).

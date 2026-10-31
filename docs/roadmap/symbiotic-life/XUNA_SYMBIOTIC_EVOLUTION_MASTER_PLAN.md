# XUNA Symbiotic Evolution Master Plan (`SYM-1` → `SYM-4`)

> **Date:** 2026-10-31
> **Status:** `SYM-1` → `SYM-4` & `SYM-UI` Implemented & Host-Verified (2026-10-31)
> **Scope:** Unifies **Track H (Embodied Human Augmentation — `H1`..`H6`)** and **Track L (Living Digital Organism — `Pillars 1`..`6`)** into a 4-Milestone + Visual UI (`SYM-UI`) execution roadmap across `desktop/`, `backend/`, `mobile/`, and `firmware/`.
> **Prerequisite:** `UDC-15` (Completed 2026-10-31, 38 XTP tools) and [XUNA_NEXT_FRONTIER_RESEARCH_2026-10-31.md](../../research/XUNA_NEXT_FRONTIER_RESEARCH_2026-10-31.md).

---

## 1. Tầm nhìn & Nguyên lý Thiết kế Cốt lõi (Core Synthesis Principles)

Mục tiêu của kế hoạch này là xóa bỏ hoàn toàn ranh giới giữa **"Một con Pet ảo đứng yên trên mạch"** và **"Một AI Agent chạy lệnh khô khan"** để tạo ra **Sinh vật số cộng sinh đầu tiên (`Symbiotic Digital Organism`)**:

1. **Mọi năng lực hỗ trợ con người đều gắn liền với đời sống sinh học của XUNA (`Symbiotic Coupling`):**
   - Khi XUNA đóng băng/khôi phục mạch làm việc (`H1`), canh lệnh build (`H3`), hay gỡ rối khi chủ quá tải (`H5`), XUNA trên màn hình mạch thể hiện **hành vi, cảm xúc, căn phòng và giấc mơ** tương ứng (vẫn giữ nguyên bảo mật `UDC-D7`: không bao giờ tự ý chạy tool nguy hiểm và không từ chối lệnh khẩn cấp của chủ).
2. **Bảo toàn tuyệt đối ngân sách phần cứng ESP32-S3 (`Zero-Bloat Firmware Budget`):**
   - Mọi tác vụ nặng (nén trạng thái dự án, phân tích log, tổng hợp giấc mơ NREM/REM, khai phá thói quen) chạy trên `desktop/` và `backend/`.
   - `firmware/` chỉ nhận các gói tín hiệu siêu nhẹ (qua BLE/MQTT sẵn có) và vẽ ghép lớp (`Micro-Layer Compositing`) ngay trên vùng đệm `region_`, `window_`, `effect_buf_` và `speechBuf_` sẵn có trong [`DisplayManager.cpp`](../../../firmware/src/DisplayManager.cpp).
3. **Đa nền tảng 100% (`Windows + macOS` & `Android + iOS`):**
   - Mọi công cụ mới trong `desktop/` đều hỗ trợ song song Windows (PowerShell / Win32) và macOS (`osascript` / POSIX) với kiểm thử tự động.

---

## 2. Tổng quan 4 Cột mốc Triển khai (`SYM-1` → `SYM-4`)

| Milestone | Tên gọi | Sự kết hợp giữa **Hỗ trợ Con người (`Track H`)** & **Chất Sống Độc Bản (`Track L`)** | Tác động RAM/Flash `firmware/` |
| --- | --- | --- | --- |
| **`SYM-1`** | **Time-Travel Workspace, Universal Pocket & Dream Engine** | • **H1:** Đóng băng & Rã đông mạch làm việc (`Workspace Time-Travel Capsule`)<br/>• **H2:** Túi đồ & Clipboard thông minh xuyên thiết bị (`Universal Pocket`)<br/>• **L2 + L3:** Cơ chế Ngủ Mơ `NREM/REM Dream Consolidator` + Đồng cảm nhịp làm việc & ăn mừng khi xong việc (`Co-Regulation`) | **0 Byte** (Tận dụng `SpeechBubble` & `VariantPlayer` sẵn có) |
| **`SYM-2`** | **Autonomous Watchdogs, Executive Coach & Self-Evolving Workflows** | • **H3:** Đội tuần tra canh lệnh build/log/server/port ngầm (`Background Watchdogs`)<br/>• **H4 + H5:** Trợ lý cuộc họp thầm lặng (`Desk Whisper`) & Gỡ rối chống quá tải (`Micro-Step Decomposer`)<br/>• **H6 + L4:** Tự học thói quen tạo Workflow 1 chạm (`Workflow Miner`) + Đời sống nội tâm & *Mảnh giấy nhớ Serendipity* khi vắng chủ | **0 Byte** |
| **`SYM-3`** | **Symbiotic Room, Epigenetic Phenotype & 2-Button Rhythm Tricks** | • **L1:** Căn phòng cộng sinh (`Symbiotic Room`: đèn bàn bật khi code, báo pin yếu, thời tiết/đêm) + Biến đổi bảng màu & phụ kiện pixel theo thói quen chủ (`Epigenetic Palette & Motifs`)<br/>• **L5:** Nhịp bấm 2 nút `GPIO0`/`GPIO14` (`Rhythm Gesture Decoder`) + Dạy chiêu trò (`L-D3 Teachable Tricks` với đường cong nhớ `FSRS`) + Mini-game giải lao 20s | **~2.2 KB Flash, < 256 B RAM** (Nằm gọn trong `Section 8` Snapshot) |
| **`SYM-4`** | **XUNA-to-XUNA Social Ecology & Ambient Hardware Sensing** | • **L6:** Hai mạch XUNA đặt cạnh nhau tự nhận diện qua BLE Advertisement / ESP-NOW, vẫy chào theo tính cách (`Temperament`), lưu kỷ niệm tình bạn có chữ ký `DeviceId` và trao đổi `Workflow/Domain Postcard` | **~1.8 KB Flash, < 128 B RAM** |

---

## 3. Thiết kế Chi tiết Từng Cột mốc & Phiên làm việc (Session-by-Session Plan)

---

### CỘT MỐC 1 (`SYM-1`): Time-Travel Workspace, Universal Pocket & Dream Engine
> **Mục tiêu:** Giải quyết ngay 2 nỗi đau lớn nhất hàng ngày (mất mạch làm việc khi chuyển dự án & chuyển dữ liệu/clipboard giữa điện thoại–máy tính), đồng thời thổi hồn vào XUNA bằng **Sổ Mơ đêm (`NREM/REM Dream`)** và **Đồng điều hòa cảm xúc khi làm việc (`Co-Regulation`)**.

#### `S1.1` — `desktop/packages/xuna_xtp` & `desktop/`: Workspace Capsule & Universal Pocket Tools
- **Công cụ XTP mới (6 tools, nâng tổng số từ 38 → 44 tools):**
  1. `workspace.capture_capsule`: Thu thập trạng thái làm việc hiện tại (thư mục repo, nhánh Git, danh sách file đang sửa dở, danh sách cửa sổ/ứng dụng đang mở, 3 mục clipboard gần nhất đã khử nhạy cảm, ghi chú bước tiếp theo) và lưu thành gói JSON `WorkspaceCapsule` tại `~/.xuna_desktop/capsules/<capsule_id>.json`.
  2. `workspace.restore_capsule`: Khôi phục lại không gian làm việc từ `capsule_id` hoặc tên dự án (mở lại IDE tại thư mục repo, mở các URL/tài liệu liên quan, nạp lại gợi ý bước tiếp theo vào clipboard nếu chọn).
  3. `workspace.list_capsules`: Liệt kê các mạch làm việc đã đóng băng kèm thời gian và tóm tắt.
  4. `pocket.push_item`: Đẩy một mảnh thông tin (text, code snippet, URL, lệnh terminal, ghi chú nhanh) vào **Túi đồ chung (`Universal Pocket`)** có khử nhạy cảm tự động (`redactSensitiveSelectionText`) và tự phân loại (`url`, `json`, `code`, `command`, `schedule_note`).
  5. `pocket.list_items`: Lấy danh sách 20 mảnh thông tin gần nhất trong `Universal Pocket` (hỗ trợ lọc theo loại hoặc từ khóa).
  6. `pocket.transform_item`: Biến đổi thông minh mục vừa copy (định dạng JSON, rút trích danh sách việc cần làm, hoặc chuẩn bị lưu vào `Knowledge Domain`).

#### `S1.2` — `backend/`: Dream Consolidator (NREM/REM) & Co-Regulation Engine
- **Module mới `src/xuna_backend/modules/symbiotic/`:**
  1. **`DreamConsolidatorService`:**
     - Kết hợp dữ liệu hoạt động trong ngày (`SymbioticHostContext` lịch sử làm việc, các `WorkspaceCapsule` đã lưu, và các `Confirmed Facts` / `KX Cases` mới) để sinh ra:
       - **Dream Vignette ("Giấc mơ đêm của XUNA"):** Một đoạn kể chuyện ngắn ấm áp ngôi thứ nhất (*"mình – bạn"*) lưu vào nhật ký tiến hóa.
       - **Morning Curiosity Hook:** Một câu hỏi thăm chủ động vào buổi sáng bám sát việc dang dở hôm qua (ví dụ hỏi thăm tiến độ nhánh Git hoặc dự án lưu trong `WorkspaceCapsule` tối qua).
  2. **`CoRegulationEvaluator`:**
     - Đánh giá nhịp sinh học chung giữa chủ và XUNA:
       - **Overwork Empathy:** Khi `continuousWorkMinutes >= 120` hoặc làm việc sau `00:30` đêm → kích hoạt trạng thái `drowsy_care` (XUNA ngáp ngủ + nhắc chủ đóng băng mạch làm việc bằng `workspace.capture_capsule` rồi đi nghỉ).
       - **Shared Breakthrough Boost:** Khi `gitDirtyCount` giảm từ `>= 5` về `0` hoặc một `KX Case` được giải quyết → kích hoạt hiệu ứng ăn mừng (`happy` + lời khen).
       - **Reunion Arc:** Khi chủ quay lại sau `>= 48 giờ` vắng bóng → phản ứng xúc động khi gặp lại.

#### `S1.3` — `backend/`: Tích hợp 6 Tools `SYM-1` & Chuỗi Workflow Đóng Băng / Rã Đông Mạch Làm Việc
- Đăng ký 6 tools mới vào `tool_names.py`, `entities.py`, `catalog.py`.
- Thêm 2 chuỗi workflow tự động trong `workflows.py`:
  - **`freeze_for_tonight` ("Cất việc đi ngủ"):** Chạy `workspace.capture_capsule` → lưu vào `Universal Pocket` → bật chế độ nghỉ ngơi và tạo sẵn hạt giống giấc mơ đêm cho XUNA.
  - **`rehydrate_project` ("Khôi phục mạch làm việc"):** Tìm `WorkspaceCapsule` gần nhất → chạy `workspace.restore_capsule` → kiểm tra `git.status_summary` → gửi phụ đề tóm tắt 15 giây lên mạch XUNA.

#### `S1.4` — `mobile/`: Giao diện Universal Pocket, Sổ Mơ ("Dream Journal") & Nút Bấm Mạch
- Cập nhật `board_workflow_slot.dart` và `home_actions_service.dart` để hỗ trợ:
  - Nút **"Đóng băng Mạch làm việc (`Freeze Workspace`)"** và **"Khôi phục Mạch làm việc (`Resume Capsule`)"**.
  - Hiển thị thẻ **Giấc mơ đêm qua của XUNA (`Dream Card`)** kèm nút trả lời nhanh câu hỏi sáng sớm.

---

### CỘT MỐC 2 (`SYM-2`): Autonomous Watchdogs, Executive Coach & Self-Evolving Workflows — **HOÀN TẤT TRÊN HOST (2026-10-31, `0 B` Firmware Delta)**
> **Mục tiêu:** Biến XUNA thành người canh gác tin cậy chạy ngầm (`Watchdogs`), trợ lý cuộc họp & gỡ rối khi bạn quá tải (`Executive Scaffolding`), và tự phát hiện thói quen lặp lại để đúc thành công cụ mới (`Workflow Miner`).

#### `S2.1` — `desktop/packages/xuna_xtp` & `desktop/`: Background Watchdogs & Executive Coach Tools (`22/22` & `27/27` PASS)
- **Công cụ XTP mới (6 tools, nâng tổng số từ 44 → 50 tools):**
  1. `watchdog.watch_process_or_port`: Canh một tiến trình (theo tên/PID) hoặc một cổng mạng (`localhost:port`) cho đến khi hoàn tất hoặc bị sập; tự động thu thập 20 dòng log cuối nếu lỗi.
  2. `watchdog.watch_resource_threshold`: Canh ngưỡng tài nguyên hệ thống (RAM, đĩa trống, pin, hoặc dung lượng thư mục build) và phát sự kiện cảnh báo tức thì.
  3. `watchdog.list_and_clear`: Liệt kê và hủy các đội tuần tra đang chạy ngầm.
  4. `coach.decompose_overwhelm`: Nhận một mục tiêu lớn/rối rắm + trạng thái repo hiện tại → trả về **đúng 1 bước khởi động 5 phút (`Micro-Step`)** + danh sách các bước ẩn tiếp theo để giảm áp lực não bộ.
  5. `meeting.desk_whisper_digest`: Chuẩn bị bản nhắc bài siêu ngắn (`<= 120` ký tự) từ `Knowledge Expert` gửi thẳng lên màn hình mạch XUNA (`SpeechBubble`) trong lúc họp mà không hiện popup trên màn hình máy tính đang share.
  6. `habit.propose_workflow`: Phân tích lịch sử chuỗi thao tác lặp lại của chủ để đề xuất đóng gói thành 1 Macro/Workflow 1 chạm (`<= R2`).

#### `S2.2` & `S2.3` — `backend/` & `mobile/`: Watchdog Alert Pipeline, Serendipity Postcard & Habit Approval UI (`6/6` & `27/27` PASS)
- **Backend (`S2.2`):** Bổ sung `SerendipityNote`, `HabitMacroProposal`, `SerendipityEngine`, `HabitWorkflowMiner` và 3 quy trình composite mới (`unstuck_coach` `R1`, `watch_and_alert` `R1`, `desk_whisper` `R1`).
- **Mobile (`S2.3`):** Bổ sung `WatchdogAlertSummary`, `MicroStepCoachSummary`, `SerendipityNoteSummary`, `HabitMacroProposalSummary`, `BoardWorkflowSlotConfig.symbioticSentinelPresets` (`unstuck_coach`, `watch_and_alert`, `desk_whisper`) và các trạng thái tương ứng trong `HomeActionsService`.

---

### CỘT MỐC 3 (`SYM-3`): Symbiotic Room, Epigenetic Phenotype & 2-Button Rhythm Tricks (`firmware/` + `mobile/`) — **HOÀN TẤT TRÊN HOST (2026-10-31)**
> **Mục tiêu:** Đột phá hoàn toàn phần nhìn và phần chạm vật lý trên mạch ESP32-S3 T-Display-S3 với ngân sách bộ nhớ siêu nhỏ (`< 2.5 KB` Flash, `< 256 B` RAM).

#### `S3.1` — `firmware/`: Epigenetic Palette Tint & Symbiotic Room Micro-Overlays (`xuna/visual/SymbioticRoom.h` + `DisplayManager`)
- Nâng cấp nhẹ [`DisplayManager.cpp`](../../../firmware/src/DisplayManager.cpp) và [`SymbioticRoom.h`](../../../firmware/lib/xuna_core/include/xuna/visual/SymbioticRoom.h):
  1. **Epigenetic Palette Modifier (`EpigeneticPalette`):** Dịch nhẹ sắc độ màu chủ đạo của XUNA (`CyanMint`, `WarmCoral`, `GoldenAmber`, `CalmViolet`, `EmeraldGlow`) dựa trên hạt giống `PetId` + chiều tính cách nổi trội nhất (`Temperament`) mà vẫn giữ nguyên đường viền đen và ánh sáng mắt trắng, không nhân bản bộ khung hình gốc `scene::kFrames`.
  2. **Symbiotic Room Props (`SymbioticRoomProps`):** Bổ sung các micro-prop `8×8` vẽ trực tiếp lên góc kính cửa sổ khi:
     - Chủ đang `Playing` / `Observing` → hiện biểu tượng **Đèn bàn học (`FocusLamp`)**.
     - XUNA đang ngủ (`PetState::Sleep`) → hiện **Bong bóng giấc mơ (`DreamBubble`)**.
     - Đồng cảm vui vẻ (`PetState::Happy`) → hiện **Trái tim cộng sinh (`CoRegHeart`)**.
     - Cảnh báo từ đội tuần tra (`WatchdogBeacon`).

#### `S3.2` & `S3.3` — `firmware/` & `mobile/`: 2-Button Rhythm Gesture Decoder, `L-D3` Teachable Tricks & Mobile Summaries
- **Firmware (`S3.2`):** Bổ sung `RhythmTrickDecoder` nhận diện chuỗi nhịp bấm 3 bước (`A-B-A` → `SpinDance`, `B-A-B` → `CuriousPeek`, `A-A-B` → `CozyNuzzle`) trong cửa sổ `<= 1500 ms` mà không làm trễ thao tác bấm đơn, kết hợp `TrickMasteryTracker` (`L-D3` thành thục sau `>= 3` lần tập và tăng độ bền trí nhớ `stabilityDaysQ4`).
- **Mobile (`S3.3`):** Bổ sung `SymbioticRoomStateSummary` và `RhythmTrickSummary` trong `board_workflow_slot.dart` và `HomeActionsService`.

---

### CỘT MỐC 4 (`SYM-4`): XUNA-to-XUNA Social Ecology — **HOÀN TẤT TRÊN HOST (2026-10-31)**
> **Mục tiêu:** Khi hai chiếc mạch XUNA đặt cạnh nhau, chúng tự phát hiện nhau, giao lưu theo tính cách và ghi lại kỷ niệm vào `Evolution Journal`.

#### `S4.1` — `firmware/`: BLE Proximity Encounter & Temperament-Driven Greeting (`xuna/social/SocialEcology.h`)
- Mã hóa & giải mã gói tin 8 byte `SocialBeaconPacket` (`0x58`, `0x53`, `shortPetId[4]`, `dominantTrait`, `epigeneticTint`, `sharedTrick`, `moodCode`) hoàn toàn không chứa PII của chủ (`U0`-safe).
- Khi phát hiện một bạn XUNA khác ở gần (`RSSI >= -65 dBm`, ngoài thời gian chờ 5 phút `kPeerCooldownMs = 300000 ms`), `SocialEncounterEngine` tự động kích hoạt hoạt cảnh chào hỏi theo tính cách (`HarmoniousSpark`, `WarmNuzzle`, `ShyPeek`) và lưu vào sổ gặp gỡ.

#### `S4.2` & `S4.3` — `backend/` & `mobile/`: Signed Friendship Journal & Postcard Exchange
- **Backend (`S4.2`):** Bổ sung `SocialEncounterNote`, `SocialPostcard` (kèm chữ ký `SHA-256` 64 ký tự hex) và `SocialEcologyService.record_encounter` tạo nhật ký gặp gỡ ngôi thứ nhất (*«mình – bạn»*) cùng bưu thiếp chiêu trò (`spin_dance`, `curious_peek`, `cozy_nuzzle`, `daily_standup`, `unstuck_coach`).
- **Mobile (`S4.3`):** Bổ sung `SocialEncounterSummary`, `SocialPostcardSummary` và các trạng thái `socialEncounters` / `socialPostcards` trong `HomeActionsService`.

---

### CỘT MỐC GIAO DIỆN (`SYM-UI`): Symbiotic Life Hub (`mobile/`) & Symbiotic Dashboard Tab (`desktop/`) — **HOÀN TẤT TRÊN HOST (2026-10-31, `0 B` Firmware Delta)**
> **Mục tiêu:** Hiển thị trực quan toàn bộ hệ sinh thái cộng sinh `SYM-1` → `SYM-4` trên ứng dụng di động và cửa sổ máy tính với chuẩn thiết kế Pixel/Ink của XUNA.

#### `S-UI.1` — `mobile/`: `HomeSymbioticLifeCard` (`home_symbiotic_life_card.dart`)
- Hiển thị hợp nhất 4 khu vực trực quan:
  1. **Giấc mơ đêm qua & Đồng điệu cảm xúc (`SYM-1` + `SYM-2`):** Thẻ `DreamVignetteSummary` kèm câu hỏi chào buổi sáng & nút trả lời 1 chạm (`Kể tiếp`), huy hiệu `CoRegulationStateSummary` và **Mảnh giấy nhớ của XUNA (`SerendipityNoteSummary`)**.
  2. **Hộp thời gian dự án & Túi đồ xuyên thiết bị (`SYM-1`):** Nút `Đóng băng tối nay`, danh sách `WorkspaceCapsuleSummary` kèm nút `Khôi phục`, và danh sách `PocketItemSummary` kèm nút `Biến đổi`.
  3. **Trợ lực vi bước 5 phút, Đội tuần tra & Quy trình tự học (`SYM-2`):** Bước khởi động 5 phút (`MicroStepCoachSummary`), danh sách cổng/tiến trình đang canh (`WatchdogAlertSummary`) kèm nút `Dừng canh`, và đề xuất macro thói quen (`HabitMacroProposalSummary`) kèm nút `Ghim Macro`.
  4. **Phòng cộng sinh, Nhịp nút & Kết bạn XUNA (`SYM-3` + `SYM-4`):** Huy hiệu màu biểu sinh & vật phẩm phòng (`SymbioticRoomStateSummary`), các chiêu trò nhịp nút (`RhythmTrickSummary` kèm dấu `★` khi thành thục `L-D3`), cùng Nhật ký Kết bạn (`SocialEncounterSummary`) và Thiệp kỹ năng (`SocialPostcardSummary`).

#### `S-UI.2` — `desktop/`: Tab `Cộng sinh` (`AgentWindowTab.symbiotic`) trên `DesktopAgentWindow`
- Bổ sung tab **«Cộng sinh»** trên cửa sổ `DesktopAgentWindow` kết nối trực tiếp với `AutoSymbioticService` thông qua `DesktopAgentController.refreshSymbioticState()` và `clearAllWatchdogs()`, hiển thị trực tiếp **Hộp thời gian dự án**, **Túi đồ xuyên thiết bị**, **Đội tuần tra đang chạy** và **Quy trình tự học từ thói quen**.

---

### CỘT MỐC KẾT NỐI TRỰC TIẾP (`SYM-LIVE` S-LIVE.1 → S-LIVE.4): Live End-to-End Symbiotic Wiring, Local Hive Persistence, Simulator Seeding & REST API (`/v1/symbiotic/*`) — **HOÀN TẤT TRÊN HOST (2026-10-31, `0 B` Firmware Delta)**
> **Mục tiêu:** Biến toàn bộ các nút tương tác trên `HomeSymbioticLifeCard` (`mobile/`), tab `Cộng sinh` (`desktop/`) và dịch vụ cộng sinh (`backend/`) thành luồng hoạt động hai chiều thực sự, lưu bền vững qua các lần mở lại app và sẵn sàng trải nghiệm ngay trong Simulator Mode không cần mạch vật lý.

#### `S-LIVE.1` & `S-LIVE.4` — `mobile/`: Interactive Action Wiring, `AppHive` Persistence & Simulator Mode Seeding (`home_actions_service.dart`, `home_controller.dart`, `home_page.dart`)
- Nối đầy đủ 5 callback hành động trên `HomeSymbioticLifeCard`:
  1. `freezeWorkspaceForTonight`: tạo ngay `WorkspaceCapsuleSummary` mới, đẩy gợi ý bước tiếp theo vào `pocketItems`, cập nhật giấc mơ `latestDreamVignette` + `symbioticRoomState` (`dream_bubble`) và lưu xuống `AppHive` (`xuna_symbiotic_state_v1`).
  2. `restoreWorkspaceCapsule`: đưa gói ngữ cảnh lên đầu danh sách, cập nhật tóm tắt 15 giây đầu ngày vào `latestCoRegulationState`, chuyển vật phẩm phòng sang `focus_lamp` và lưu bền vững.
  3. `transformPocketItem`: biến đổi trực tiếp mục trong túi đồ theo hành động gợi ý (`format_json`, `extract_urls`, `extract_todos`, `summarize`) và lưu bền vững.
  4. `clearActiveWatchdogs`: xóa toàn bộ đội tuần tra đang chạy và hạ cảnh báo `watchdog_beacon` về `focus_lamp`.
  5. `acceptHabitMacroProposal`: chuyển đề xuất quy trình từ thói quen thành `CustomWorkflowPreset` bền vững (`saveCustomWorkflow`) và gỡ đề xuất khỏi danh sách chờ.
- Trong chế độ Simulator (`isSimulator == true`), `seedSimulatorSymbioticStateIfEmpty()` tự động khởi tạo dữ liệu mẫu chân thực để kiểm thử trực quan toàn bộ 4 khu vực trên thẻ Cộng sinh.

#### `S-LIVE.2` — `desktop/`: Shared `AutoSymbioticService` Instance & Quick Actions (`main.dart`, `desktop_agent_controller.dart`, `desktop_agent_window.dart`)
- Chia sẻ chung thực thể `dispatcher.symbioticService` giữa `HostToolDispatcher` và `DesktopAgentController` trong `desktop/lib/main.dart`, bổ sung 2 nút thao tác nhanh **«Đóng băng nhanh»** (`captureQuickWorkspaceCapsule`) và **«Thêm ghi chú»** (`pushQuickPocketSnippet`) ngay trên tab `Cộng sinh`.

#### `S-LIVE.3` — `backend/`: `/v1/symbiotic/*` REST Endpoints (`routes.py`, `schemas.py`, `main.py`)
- Bổ sung 3 endpoint chuẩn hóa:
  - `POST /v1/symbiotic/dream-consolidate`: tổng hợp `DreamVignette` NREM/REM kèm đánh giá đồng cảm `CoRegulationState`.
  - `POST /v1/symbiotic/unstuck-coach`: trả về bước khởi động 5 phút đầu tiên, 2 bước tiếp theo, mảnh giấy nhớ `SerendipityNote` và các đề xuất `HabitMacroProposal` từ lịch sử công cụ.
  - `POST /v1/symbiotic/social-encounters`: ghi nhận cuộc gặp gỡ giữa hai cá thể XUNA và tạo `SocialPostcard` có chữ ký `SHA-256`.

---

## 4. Thứ tự Thực thi Khuyến nghị & Cam kết Chất lượng

1. **Triển khai `SYM-1` trước tiên** (vì `SYM-1` mang lại ngay **Time-Travel Workspace**, **Universal Pocket xuyên thiết bị**, **Sổ Mơ NREM/REM** và **Đồng cảm nhịp làm việc** với **0 Byte ảnh hưởng tới Firmware**).
2. Tiếp nối ngay bằng **`SYM-2`** (Đội tuần tra `Background Watchdogs`, Trợ lý cuộc họp `Desk Whisper`, Gỡ rối chống quá tải & Tự học thói quen).
3. Sau đó tiến vào **`SYM-3`** (Nâng cấp đồ họa Căn phòng Cộng sinh & Nhịp bấm 2 nút trên mạch ESP32-S3) và **`SYM-4`** (Giao lưu giữa các mạch XUNA).

Mỗi cột mốc đều phải vượt qua đầy đủ bộ kiểm thử tự động:
- `desktop/packages/xuna_xtp`: `fvm dart analyze` & `fvm dart test`
- `desktop/`: `fvm flutter analyze --no-pub` & `fvm flutter test --no-pub`
- `backend/`: `ruff check src tests`, `mypy src`, `pytest`
- `mobile/`: `fvm flutter analyze --no-pub` & `fvm flutter test --no-pub`
- `firmware/` (từ `SYM-3`): `pio test -e native` & `pio run` kiểm tra chính xác dung lượng RAM/Flash.


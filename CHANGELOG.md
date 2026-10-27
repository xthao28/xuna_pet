# XUNA — Change and Session History

Last updated: **2026-10-27** (Asia/Ho_Chi_Minh).

## 2026-10-27 — Giao diện song ngữ Anh - Việt, Cài đặt giọng đọc XUNA và Hiệu ứng Micro sống động

- **Giao diện song ngữ 1:1 mượt mà:** Ứng dụng hỗ trợ chuyển đổi linh hoạt giữa Tiếng Việt và Tiếng Anh trong phần Cài đặt thiết bị với hơn 500 mục giao diện được dịch và đồng bộ chuẩn xác.
- **Tùy chọn giọng đọc XUNA (Edge TTS):** Bạn có thể dễ dàng chọn giọng đọc cho XUNA trong Cài đặt hoặc ngay trong màn hình trò chuyện:
  - Tiếng Việt: Giọng nữ ngọt ngào (Hoài My) hoặc giọng nam ấm áp (Nam Minh).
  - Tiếng Anh: Giọng nữ trong trẻo chuẩn bản xứ (Aria) hoặc giọng nam tự nhiên (Guy).
  - Tích hợp nút **Nghe thử (Preview)** trực tiếp để trải nghiệm ngay chất giọng trước khi chọn.
- **Nói tiếng Anh chuẩn xác:** Sửa lỗi micro bị ép nhận diện tiếng Việt khi nói tiếng Anh. Ứng dụng tự động truyền ngôn ngữ phù hợp lên Cloud Whisper, giúp XUNA lắng nghe và hiểu đúng từng câu chữ tiếng Anh bạn nói.
- **Hiệu ứng sóng âm Micro động:** Khi bạn nhấn giữ hoặc kích hoạt micro để nói, các vòng sóng âm dịu nhẹ sẽ lan tỏa quanh nút mic, mang lại cảm giác sống động và phản hồi trực quan tức thì.
- Toàn bộ 273/273 bài kiểm thử tự động trên ứng dụng di động đều đạt kết quả tốt (100% PASS), mã nguồn sạch hoàn toàn.

## 2026-10-27 — Hỗ trợ giọng nói và trò chuyện song ngữ Anh - Việt mượt mà (Backend)

- **Nói tiếng Anh tự nhiên qua micro:** Tính năng nhận diện giọng nói (Whisper) được chuyển sang cơ chế tự động nhận diện ngôn ngữ. Giờ đây bạn có thể nói tiếng Anh hoặc tiếng Việt vào micro điện thoại mà không bị ép dịch hay phiên âm sai sang tiếng Việt nữa.
- **Phát âm chuẩn tiếng Anh bản ngữ:** Khi XUNA trả lời bằng tiếng Anh, hệ thống tự động phát hiện và chuyển sang giọng đọc tiếng Anh bản ngữ chuẩn Mỹ (`en-US-AriaNeural`), giúp phát âm rõ ràng, đúng trọng âm và ngữ điệu tự nhiên, không còn bị đọc bằng giọng tiếng Việt ngắc ngứ.
- **Tính cách thú cưng song ngữ:** XUNA tự động trò chuyện bằng ngôn ngữ bạn dùng (nói tiếng Việt thì xưng "mình" gọi "bạn", nói tiếng Anh thì xưng "XUNA" hoặc "I" và gọi "you"), vẫn giữ trọn nét ấm áp, thông minh và tinh nghịch của một bé pixel pet.
- Toàn bộ 231 bài kiểm thử tự động của backend đều đạt kết quả tốt, mã nguồn sạch hoàn toàn.

- **Gợi ý chủ đề tự động:** Khi bạn chia sẻ các kiến thức chưa phân loại (từ 4 điều trở lên), hệ thống tự động gom nhóm và đề xuất tạo một lĩnh vực mới với tên gọi và mô tả tiếng Việt phù hợp, hoặc đề xuất thêm vào lĩnh vực bạn đã có nếu nội dung tương đồng để tránh trùng lặp.
- **Trích xuất kiến thức khi trò chuyện:** Trong các cuộc trò chuyện hàng ngày với XUNA, hệ thống có thể tự nhận biết những câu nói mang tính kiến thức thực tế (loại bỏ câu hỏi, chào hỏi hay thông tin nhạy cảm), tự động tìm chủ đề phù hợp và đưa ra đề xuất để bạn xác nhận trước khi lưu.
- **Tự động dọn dẹp:** Các gợi ý không được bạn quyết định sau 14 ngày sẽ tự động hết hạn để không làm phiền màn hình của bạn.
- **Hỗ trợ công nghệ nhúng ngữ nghĩa (Embedding):** Bổ sung kết nối embedding tùy chọn theo chuẩn OpenAI để sẵn sàng hỗ trợ tìm kiếm và phân loại ngữ nghĩa sâu hơn khi cần.
- **Đánh giá chuẩn xác trên dữ liệu tiếng Việt:** Đã xây dựng bộ kiểm thử chuẩn gồm 60 kiến thức tiếng Việt thuộc 6 chủ đề đời sống và 10 nội dung nhiễu. Thuật toán so khớp từ vựng đạt độ chính xác **88.33%** và loại bỏ nhiễu tuyệt đối **100%**.
- Toàn bộ 211 bài kiểm thử tự động của backend đều đạt kết quả tốt, mã nguồn chuẩn chỉnh và không có lỗi kiểu dữ liệu.

- Thêm thẻ "Lĩnh vực của XUNA" trên màn hình chính: hiển thị 5 ô lĩnh vực với cấp độ hiểu biết tương ứng qua các chấm tròn (từ Mới nghe qua đến Biết nhiều) và số kiến thức/số ngày đã học lấy trực tiếp từ thiết bị.
- Màn hình quản lý lĩnh vực: tự tạo chủ đề mới (kèm gợi ý nhanh), đổi tên, cho chủ đề tạm nghỉ (giải phóng ô trên thiết bị) hoặc xoá khi không còn muốn XUNA nhớ.
- Tính năng "Dạy kiến thức": nhập nội dung ngắn (tối đa 280 ký tự), tự động hoặc chọn tay chủ đề phù hợp, kiểm tra câu trả lời xem có trùng hoặc bổ sung cho điều XUNA đã biết hay không trước khi lưu vào thiết bị.
- Tự động gợi ý chủ đề mới khi phát hiện bạn và XUNA trò chuyện nhiều về một chủ đề chưa có trong danh mục.
- Toàn bộ giao diện hoạt động mượt mà ngay cả khi không có mạng (hiển thị trạng thái offline dựa vào thông tin thiết bị đã lưu).
- Đã kiểm tra tự động 269/269 test trên máy tính, mã nguồn sạch hoàn toàn.

## 2026-10-27 — Backend core for knowledge domains, matching, and memory integration (KD-3)

- Implemented backend module `knowledge`: domain entities, Vietnamese text normalizer (pure stdlib, handling diacritics and đ/Đ), and lexical overlap matcher combining n-grams containment and Jaccard similarity.
- Added full domain lifecycle management: creating up to 5 non-deleted domains with unique device slots 0..4, device acknowledgement, rename, description update, rest (freeing hardware slot), activation, and deletion.
- Integrated `CandidateType.KNOWLEDGE` into the memory system with deterministic uint32 `fact_key`, relation detection (`refines` vs `new`), and domain association.
- Extended conversation chat prompt (`chat_turn.py`) to recall up to 5 confirmed knowledge facts in `TurnContext` so XUNA's answers naturally utilize learned domain knowledge.
- Created Alembic database migration `0009_knowledge_domains` for tables `knowledge_domains`, `knowledge_suggestions`, `knowledge_summaries` and candidate columns.
- All 196 backend tests pass, clean architecture boundaries verified, 0 linter/mypy issues.

## 2026-10-27 — Knowledge commands connected to board storage and companion app (KD-2)

- Firmware now supports Bluetooth Opcode 10 with 7 operations: open a subject slot, set active, set resting, clear, add a confirmed fact, remove a fact, and move a fact between slots.
- Every knowledge change is committed to the device's persistent storage before acknowledging the command (commit-first rule). Knowledge profile reloads cleanly across reboots.
- The device announces knowledge capability in its Bluetooth flags and broadcasts its 64-byte knowledge projection on characteristic `7a6e000f`.
- The Flutter companion app now has complete entities, use cases, protocol codecs, repository methods, and simulator support for all knowledge operations.
- Verified on computer with golden fixtures generated directly from firmware: 343/343 firmware tests pass, 258/258 Flutter tests pass, and code analysis is completely clean. Ready for backend integration (KD-3).

## 2026-10-27 — XUNA's device core learns to remember knowledge by subject (KD-1)

- The device core now has 5 slots to track what you teach XUNA about subjects you choose (such as cooking or English).
- Each slot tracks confirmed facts and distinct teaching days. XUNA's level in a subject (from 0 to 3) is decided strictly by the device: higher levels require both enough facts (3, 10, 25) and enough different days of teaching (1, 3, 5), so cramming all facts in one sitting will not jump to high levels.
- Removing a fact lowers the evidence count but preserves the history of days taught.
- Memory and reboot persistence for knowledge (snapshot section 13) and a 64-byte Bluetooth projection are built and verified with tests on the computer. Not yet wired to the board hardware or phone app (KD-2).

## 2026-10-27 — XUNA will grow in what it knows, not in how it looks

- XUNA no longer has growth stages after hatching. It keeps its look and all its animations.
- Instead, you will pick a few subjects (for example cooking or English), and XUNA will get to know them better the more you teach it and confirm. The plan is written; nothing of it is built yet.
- In the app, "LỚN LÊN" became "LĨNH VỰC" (the room badge, the Journal filter and a new "LĨNH VỰC CỦA XUNA" card), all marked "SẮP CÓ". The stage pictures from yesterday were removed.
- Only tested on the computer.

## 2026-10-26 — XUNA's growth journey waits for the board

- The Journal's growth card now shows XUNA's four stages: egg, first days, exploring and understanding you.
- The pictures were redrawn from XUNA itself instead of being made by AI: a cream egg with a small crack, then a small XUNA with a square head and no gold, then a bigger square-headed XUNA with a first touch of gold on top, and finally today's XUNA as the grown-up stage.
- The app no longer guesses XUNA's stage from how many times you gave feedback. The stage will only light up once the board itself decides and reports it, so until then the card stays dimmed with "SẮP CÓ".
- When and why XUNA grows up is still the owner's decision, and the board does not track it yet. Only tested on the computer.

## 2026-10-26 — XUNA's spoken replies should break off less

- When you press the microphone while XUNA is talking, it now goes quiet for good: the rest of that answer no longer plays into your recording, and what you say next is always answered (before, it could be lost).
- If the free voice service fails on one sentence, XUNA skips just that sentence and keeps talking (before, it went silent for the rest of the answer).
- The next sentence is loaded while the current one plays, so the pauses between sentences should be shorter.
- A notification or Siri that interrupts XUNA now pauses the sentence, which continues afterwards, instead of jumping to the next one.
- Only tested on the computer so far; it needs a new app build and the server restarted before you can hear it on the phone.

## 2026-10-24 — XUNA's character starts to show in what it chooses

- Where you have not taught XUNA anything yet, its character now tips the choice: a curious XUNA is curious more often, a playful one gets happy more often, and one you made calmer simply idles more. Before, XUNA picked at random in those moments.
- Anything you taught it, even with a single pet or shoo, still wins. A XUNA you rewarded for being curious for three months chose curious about half the time in situations it was never taught, against a third before (simulation).
- Only tried in the simulator so far. The strength of the effect is the owner's choice before it goes on the board.

## 2026-10-24 — Try XUNA's new animations from the app

- The app's device tab gets four buttons under "Xem thử động tác": look around, yawn and stretch, bounce, and greet. Tapping one makes XUNA play it on the board right away.
- It is only a show: XUNA does not get tired, learn anything or change its character from it. The buttons appear only when the board supports them. Not yet on the board or the phone; it needs an upload and a new app build.

## 2026-10-24 — The board runs cooler, second pass

- The processor now runs at a third of its speed, which is still plenty: XUNA draws each frame in under 8 ms of its 100 ms. It speeds up for a moment only when it signs something for the app, so nothing stalls.
- The screen is a little less bright while XUNA is awake (about 90 % to the eye), dims gently when XUNA sleeps or rests, and goes full bright for the status and pairing cards. Changes fade over a fraction of a second.
- XUNA announces itself over Bluetooth about 4 times less often (every 0.1–0.15 s); the app searches for up to 12 s, so it should still find XUNA quickly (not yet tried with the phone).
- The chip went from about 45 °C to about 42 °C in the same room. XUNA kept everything it had learned, and buttons and cards respond the same.

## 2026-10-24 — The app shows XUNA's personality

- In the app's Journal there is now a "Tính cách" card: XUNA's personality word (for example "Lanh lợi" or "Ham chơi"), its mood, how many times it has spent time with you, five traits as bars, and its latest character changes with the reason ("bạn hay vuốt khi XUNA tò mò, qua 4 buổi").
- Everything is read from the board; the app does not change it. Older boards and the demo mode show that the information is not available. A new app build on the phone is needed to see it.

## 2026-10-24 — XUNA has four new animations

- XUNA now greets you warmly when you come back, bounces when it is happy right after being petted, looks around when it feels like exploring or is waiting for you, and yawns and stretches before resting and after waking up.
- What XUNA chooses to do is unchanged; these only change how it looks while doing it. A greeting and the bouncing were already seen on the board. The new animations are drawn from XUNA's own sprite, with the same face, colours and crisp pixels as its existing animations; the owner's drawings served as the guide for the movements.

## 2026-10-24 — XUNA remembers its character after a restart

- Until now, what XUNA learned about its own character was lost every time the board restarted; only its inborn temperament came back. Now it is saved with everything else it learned, so its character keeps growing across restarts and power cuts. A pet that has learned nothing yet saves nothing extra.
- If the board is ever put back on an older firmware, XUNA keeps working and only forgets this new part. Forgetting everything (reset) also clears it.
- The app can now read XUNA's personality, mood and its last changes from the board. The app screen for it comes later.

## 2026-10-24 — The status card shows XUNA's personality

- Holding GPIO0 now shows a "Tính cách" line with a word for XUNA's clearest tendency, such as "ham chơi" (playful), "tò mò" (curious) or "thong thả" (unhurried). It reads "cân bằng" (balanced) when nothing stands out. This XUNA shows "ham chơi". The word can change slowly as XUNA's character changes.
- It replaces the "Lúc chơi thích" line, which no longer changed because play is only taught through the app. "Đã sống" is now "Đã thức", because it counts the time the board has been on, not XUNA's age.

## 2026-10-24 — Each XUNA keeps its own rhythm

- When left alone, XUNA used to do something on its own every 60 seconds, exactly like every other XUNA. Now an eager, curious or playful XUNA acts a little sooner and a placid one a little later (51–69 seconds). What it chooses to do still comes from what it learned. In the simulation, XUNAs with the same owner now live noticeably different days. This one acts about every 58 seconds. It is on the board.

## 2026-10-24 — The board runs cooler

- The board got hot because the firmware kept the processor busy all the time, checking for work about 25,000 times a second. Now it checks 100 times a second and rests in between. The chip went from about 52 °C to under 47 °C, and it was still cooling when the test ended. XUNA looks and responds the same.

## 2026-10-24 — Personality step 4: XUNA's temperament starts to show

- The owner approved going on. A trait now changes only after at least four separate sessions point the same way (before: three). In the simulation, an owner who reacts at random now changes XUNA's character less than half as much, and a caring owner still shapes it clearly over a few months.
- The personality now runs inside XUNA's real firmware. It only watches and never changes what XUNA chooses. Its inborn temperament and current mood show in how it moves: a lively XUNA animates up to 15 % faster, a calm one slower, and a sensitive one keeps its reaction on screen a little longer. Holding GPIO0 shows the status card, which now also says XUNA's mood (for example "vui" or "hơi chán").
- What XUNA learns about its own character is not kept after a restart yet; that comes in a later step. Computer tests pass. The new firmware is now on the board: XUNA kept everything it had learned, and the extra work per step is tiny. This XUNA was born with an almost neutral pace, so at first its movement looks nearly the same; its mood is what will change it.

## 2026-10-23 — XUNA's voice no longer breaks off in long answers

- In a long spoken answer, each sentence used to be cut off by the next one, so XUNA seemed to stop mid-sentence and jump ahead. The app now lets every sentence finish before the next one starts.
- The free voice service sometimes fails or is slow for one sentence. XUNA now tries that sentence again instead of going silent for the rest of the answer, and never plays half a sentence.
- Needs a new app build on the phone to take effect.

## 2026-10-23 — Personality step 3: wants, feelings, and a first full test

- XUNA's planned personality now also has wants (to explore, to play, to be with its owner, boredom) and feelings. Feelings come from what XUNA expected: a pet it did not expect is a happy surprise, a shoo after a pet it expected is a disappointment. Feelings fade, and its mood always returns to its usual level. Missing its owner settles down after a while and never turns into sadness.
- In the computer simulation, everything runs next to XUNA without changing what it does. The safety checks pass: XUNA's personality does not change when the owner is away, after one bad day or with an owner who reacts at random, and it never overrides what the owner taught. An owner who loves XUNA's curiosity makes it noticeably more curious over a month or more. With only three animations, though, a pet's inborn temperament is hard to see. The owner now decides how to continue. [Report](docs/research/PE1-G1-report.md).

## 2026-10-23 — Personality step 2: an inborn temperament and how it may change

- Each XUNA can now get its own temperament at birth (ten traits such as curiosity, sociability and tempo), drawn from a number every pet already stores, so the same pet always gets the same temperament. What the owner does is collected as evidence, and a trait moves only a little at a time, only after several separate sessions that point the same way. One extreme day, an owner who keeps changing their mind and XUNA's own actions do not change who it is. Each change is written down with its reason for a future Journal. Computer tests only; the board does not use it yet.

## 2026-10-23 — Personality step 1: measuring how XUNAs differ today

- A computer simulation now lets many XUNAs live 30 days each with different kinds of owners (consistent, unsure, random, rarely reacting, always teaching, changing their mind). It shows that today every XUNA becomes exactly what its owner teaches, quickly and reliably, but two XUNAs with the same owner end up identical: they have no character of their own yet, and each mostly repeats one action. These numbers are the yardstick for the personality work that comes next. Simulation only; the board and the app are unchanged. [Report](docs/research/PE0-baseline.md).
- Three firmware tests that failed only on the Windows computer now pass there too.

## 2026-10-23 — Roadmap documents sorted into folders

- The roadmap documents are now grouped by topic (milestones, sessions, learning, cloud, voice, UI, personality) with a short index page. All links were updated and checked; nothing else changed.

## 2026-10-23 — Research: how XUNA could grow a personality

- A research report looks at XUNA's code and at the open-source JPAF personality framework. XUNA does not have a personality yet; what makes each XUNA different today is what it learned from its owner. JPAF is not a good fit to plug in (it needs an AI model for every step and changes personality too fast), but a few of its ideas can be reused in XUNA's own small, offline design. Nothing is built; the owner decides next steps. [Report](docs/research/personality-evolution-assessment-2026-10-23.md).
- More projects were studied (Creatures, desktop pets, emotion engines), and the owner approved a plan: each XUNA gets its own temperament at birth and grows into its own character from what happens with its owner, including how the owner talks to it, without asking for confirmation. Work starts with simulations on the computer; the board and the app come later. [Plan](docs/roadmap/personality/personality-plan-2026-10-23.md).

## 2026-10-23 — XUNA starts speaking sooner; plan for hands-free voice

- XUNA's spoken replies no longer wait sentence by sentence: the text keeps coming while the next sentences are turned into speech, and the first piece can stop at a comma so the first sound comes sooner. Sentences are still spoken in order, and the server now reports how long the first sound took. Tested on the computer only; it still needs a phone measurement.
- A design for a single always-open voice connection (talk without tapping twice, interrupt XUNA, the same connection for the board later) is written for the owner to review. Nothing of it is built yet.

## 2026-10-23 — The app reconnects to XUNA by itself

- Opening the app now finds and connects the XUNA it was connected to last time, and checks that it is still the same pet. The "Tự động kết nối khi mở app" setting works (on by default) and can be turned off. If XUNA is not nearby, the status line says so without a pop-up. Tested on the computer only; it still needs a phone and the board.
- After "TÌM XUNA" finds the pet, the same big button becomes "KẾT NỐI XUNA", so a new owner knows what to tap next. With several XUNA nearby, each one gets its own connect button.
- The chat microphone button is smaller and sits in the middle of the screen.

## 2026-10-23 — Phone and board checks done; M04 approved

- The owner finished the phone and board checks: the rebuilt iPhone app, spoken turns, QR camera, speaker route, microphone with the board connected, local export with the hash check, and the board's window scenes, status card and pairing QR. This meets the last Cloud gate condition (c). Timings were not written down in the repository.
- The owner approved M04 (the life-core foundation) as proposed. The real power-cut test and the render-speed comparison move to M05b.
- Spending: AI and voice stay on free services with the owner's own test data. Board audio hardware (D18) waits until phone voice is finished.

## 2026-10-23 — XUNA knows the time, the conversation and itself

- AI replies now know the current time and day, remember the last few lines of the chat, and know XUNA's own age, what it is doing and what it has learned to like. XUNA answers knowledge questions properly, in short spoken-friendly sentences. Nothing is stored. Needs the iPhone app rebuilt.

## 2026-10-23 — XUNA's AI replies reach the phone; iOS rebuilt

- The owner found that voice transcription worked but AI replies fell back to the local template. The test pet was rebound from the old test issuer to the owner's Google account. The app's SSE decoder also failed on Dio's Uint8List stream; mobile 006cf5b fixed it. The recorded app validation is 152/152.
- Rebuilt and directly installed the release app on iPhone 15 with Flutter 3.32.8 / Dart 3.8.1 and Xcode 27.1; backend /readyz was ready. No package or lockfile changes in this rebuild.
- Backend probe showed spoken Edge turns at 4.9–11 s, so phone measurements remain open. Still needed: five send-to-first-audio timings, QR camera confirmation, speaker/earpiece route, and microphone while BLE is connected. See [V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md).

## 2026-10-22 — iOS V1 app installed on iPhone 15; phone measurements open

- Flutter 3.32.8 / Dart 3.8.1, Xcode 27.1, CocoaPods 1.16.2. pubspec.lock stayed unchanged; Podfile.lock gained iOS records for audio_session, just_audio, mobile_scanner, and record_ios. Backend /readyz returned ready.
- The release app built and launched directly on the owner's iPhone 15. A QR navigation type error seen on the first launch was fixed in AppNavigatorImpl; the corrected build was installed and launched. Manual camera scan confirmation remains open. Google URL scheme already matched REVERSED_CLIENT_ID; no Info.plist change was needed.
- b60e396 and 7c32c33 pushed in mobile. Firebase plist is now ignored and untracked in the current tree, kept locally for builds. It was already present in older commit 7ebd06d; history cleanup/key rotation has not been performed. No key was included in these new commits.
- Not run: five-turn latency measurement, speaker/earpiece route check, microphone while BLE is connected, board validation, Flutter tests/analyze. See [V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md).

## 2026-10-22 — Board runs the window scenes, status card and pairing QR

- Firmware 0a392c5 uploaded after a verified NVS backup; XUNA booted with the same identity and learned preferences. Visual check still to do.
## 2026-10-22 — Ready for the phone voice test; LLM speed re-checked

- Backend database upgraded for the voice consent, voice settings filled in and the server runs on the home network for the phone. Gemini's free tier was still slow (about 6.4 s to the first word, 3 failures in 14); models on Groq answered in 0.4–0.9 s with no failures, and the owner chose Groq gpt-oss-120b for the phone test. Emojis are no longer read aloud.
- The Android app had stopped building after the voice and QR packages were added; the Android build tools were upgraded (AGP 8.9.1, Kotlin 2.2.20, Gradle 8.11.1, minimum Android 7.0) and the test app now builds on this Mac. The iPhone build needs the newer Mac. [V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md).

## 2026-10-22 — Talk to XUNA from the app (phone voice V1, slice 2)

- The chat microphone works: tap to talk, tap again to send. After turning on the new "Giọng nói" consent, speech becomes text that XUNA handles like typed text, and AI replies are read aloud sentence by sentence. Recordings are never kept. Host tests only so far. [V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md).

## 2026-10-22 — Backend can hear and speak (phone voice V1, slice 1)

- New consent "voice" (separate from text), speech-to-text endpoint using Groq Whisper, and spoken replies sentence by sentence (Edge voices, optional local Piper). Audio is never stored. The app part comes next. [V1 record](docs/roadmap/voice/V1-phone-voice-2026-10-22.md).

## 2026-10-22 — Voice parity plan and first V0 measurements

- [Plan](docs/roadmap/voice/voice-parity-plan-2026-10-22.md) to match Xiaozhi on spoken conversation while stabilising XUNA's core; [Xiaozhi stack research](docs/roadmap/voice/xiaozhi-stack-research-2026-10-22.md). Benchmark tools in `backend/scripts/voice_bench/`. First small runs: local Whisper too slow on this Mac, Gemini audio accurate but far too slow, Edge TTS fast but flaky.

## 2026-10-22 — The app connects by scanning XUNA's pairing QR

- Device tab → "Quét mã QR trên XUNA" opens the camera; the app reads `xuna://pair?…`, finds the nearby XUNA with that PetId and connects. New dependency `mobile_scanner` 7.4.2 (BSD-3, owner-approved). Not yet tried on a phone.

## 2026-10-22 — Status card and pairing QR on the device

- Hold GPIO0 to see XUNA's status card (age, energy, mood, what it learned, when the owner usually comes); hold both buttons for 3 s to show a pairing QR. Vietnamese text renders with Be Vietnam Pro glyphs; QR by the vendored Nayuki library (MIT). Both buttons now act on release. Host tests 240/240, ESP32 build PASS; not yet on the board.

## 2026-10-22 — XUNA's window changes with the time of day; reactions show a heart or a puff

- Device: a heart rises above XUNA when a pet teaches it, a puff when a shoo does. The window shows day, sunset, a starry night or animated rain; Auto follows the phone-synced day part, and holding GPIO14 (≥ 0.8 s) cycles the scene (saved in `xuna_ui`). GPIO14's short press now acts on release. Host tests 232/232, ESP32 build PASS; not yet on the board. [Record](docs/roadmap/ui/device-scenes-2026-10-22.md).

## 2026-10-22 — Board runs the new firmware; S21 target parity bit-identical

- Board upload (owner connected the board): NVS backup verified (pet keys byte-identical across two reads, partition unchanged), firmware `d1b17b8` uploaded; boot `recover=Ok … ready=1`, same PetId and preferences. The board now has S19b `BootSequence`, S20, reaction learning and routine learning.
- S21: new `[env:xuna_parity]` replays three Life Lab traces on the ESP32 with an in-RAM store (no BLE/display/NVS). All 24 output lines (counters, snapshot SHA-256, explanation) are **bit-identical** to the host. `step()` p99 7 µs quiet, ≤ 313 µs with events. Production re-uploaded afterwards. Optional `LifeCoreStepProbe` timing hook (+1 test): native and ASan 225/225. [M04 record](docs/roadmap/milestones/M04-foundation.md) written; owner review pending.

## 2026-10-20 — Routine learning: XUNA waits for the owner

- Firmware `HabitPredictor` (plan §9.7): sessions with trusted time fill 48 decayed hour slots (weekday/weekend) plus the mean arrival minute; a prequential Brier gate keeps a random owner from "teaching" a routine. About 20 min before the usual arrival an idle XUNA shows curious once (never woken from sleep, no reminders). Snapshot section 7 (optional), cleared by forget. Found during build: ESP-IDF's `likely()` macro broke a function named `likely`. [Record](docs/roadmap/learning/routine-learning-2026-10-20.md).
- Life Lab: routine owner anticipated on 4–6 of 7 last-week days with 0 false alarms; random owner never. Native and ASan 224/224, ESP32 build + purity PASS (RAM 52,848 B). App display not built yet.

## 2026-10-19 — XUNA learns from the owner's reactions; app ratings removed

- Owner decision (D6 revised): a pet (top button) within 10 s after XUNA acts teaches "thích", a shoo (bottom button) "không thích", weight 0.3 of a rating; silence teaches nothing. Greeting learning is on and XUNA chooses on its own when idle. [Record](docs/roadmap/learning/reaction-learning-2026-10-19.md).
- Firmware: weighted learner feedback, reaction window, `Reaction`/`Spontaneous` core events, adapter button handling, episode source 3 with a versioned episodes section (found: the old decoder rejected it as corrupt). Life Lab proves the learned choice follows the owner from reactions alone (40/40 runs with ~13 reactions in a day). Native and ASan 216/216, ESP32 build + purity PASS.
- Mobile: rating chips, confirmation and journal rating buttons removed; rating words in chat explain how to react on XUNA; greeting (context 2) and reaction (source 3) episodes decode, show and export. 124/124. Backend export schema accepts them (99/99).

## 2026-10-19 — S20 golden vectors; app accepts curious

- Firmware `sim/golden.cpp` writes 27 BLE v1 steps (frame, real adapter result, life and memory values) from `BoardLab`; copied to `mobile/test/fixtures/firmware/` with an update procedure.
- **Bug found:** firmware learner v3 shows curious (ActionId 3), but the app's `ProtocolCodec` rejected life/memory values above happy, so the first curious choice would have been treated as a malformed notification and the app would mark the device disconnected. Fixed (accept up to curious); the golden test fails without the fix.
- The simulator no longer contains a Dart learner (G17): suggestions show idle, the firmware's no-evidence choice. Results, decision IDs, rating rules, feedback counts and episodes match the firmware vectors; a stated preference no longer counts as a rating (firmware semantics). Four tests that asserted simulator learning were rewritten; a lazy-list widget test now scrolls. Mobile 125/125, analyze clean, lock unchanged.

## 2026-10-19 — S19b Life Lab scenarios; boot policy shared with the board

- Firmware: `main.cpp` setup() boot policy moved unchanged into `xuna_core` `BootSequence` (port `IBootStore`, implemented by `NvsSnapshotStore`), so Life Lab replays the board's exact boot. New `BoardLab` (setup/loop replica with the production adapter flags) and scenarios D (100 days without rating → learner identical to fresh), E (10 reboots + 5 power cuts: no lost or duplicated feedback, stable PetId, age loss ≤ 295 s) and 100-day stability. All pass, repeatable, about 1 s each. Native 210/210, ASan scenario suite 6/6, ESP32 build + purity PASS (RAM unchanged, Flash +220 B). Not uploaded to the board.
- Found and fixed: a never-migrated, unhatched (Egg) device saved v2 snapshots, then booted read-only ("snapshot Ok + identity Missing" = damage). Snapshot writes are now refused until the pet has an identity (`IdentityGatedCommit`); an Egg device lives but learns only after hatching. The current board (migrated pet) was never affected.

## 2026-10-19 — Correct XUNA icon orientation and add Android icons

- Corrected the iOS AppIcon render so the curious XUNA sprite is upright, and added Android density-specific launcher icons plus the Android 8+ adaptive icon/background resources.
- Rebuilt the Development IPA, verified the app's deep code signature, installed it on the connected iPhone 15 (iOS 26.4.2), and launched XUNA successfully.
- Validated Android icon PNG dimensions and adaptive-icon XML. Android APK build/install was not run because this Mac has no JDK or Android SDK.

## 2026-10-19 — XUNA pixel-art iOS app icon

- Replaced every iPhone/iPad/marketing AppIcon image with the curious XUNA sprite from `mobile/assets/images/xuna_pet_curious.png`, centered over an opaque dark background and rendered at each catalog size. This uses nearest-neighbor scaling to preserve the pixel-art style and avoids transparency in the 1024 px marketing icon.
- Rebuilt the Development IPA with Flutter 3.32.8 / CocoaPods 1.16.2 / Xcode 27.1. Asset catalog compilation verified the icon renditions as opaque; Flutter no longer reports a placeholder app-icon warning (launch-image and placeholder bundle-ID warnings remain). All embedded framework signatures verified.
- Installed the IPA and launched XUNA on the connected iPhone 15 (iOS 26.4.2). `pubspec.lock` is unchanged.

## 2026-10-19 — Build signed iOS Development IPA

- Owner requested an iOS device build. Installed the repository-pinned Flutter 3.32.8/FVM and CocoaPods 1.16.2 toolchain; `pubspec.lock` stayed unchanged.
- Firebase Auth required iOS 13, and the installed Xcode 27.1 SDK requires iOS 15. Owner approved the iOS 15 minimum. Updated the iOS project/Pod deployment settings and mobile README; recorded the approved minimum in AGENTS.md.
- `fvm flutter build ipa --release --export-method development` succeeded. First device install exposed an unsigned embedded `FirebaseAuthInterop.framework` despite the archive's valid app signature. Signed that embedded framework with the configured development identity, resealed the app, rebuilt the IPA at [mobile/build/ios/ipa/xuna_mobile.ipa](mobile/build/ios/ipa/xuna_mobile.ipa), and verified the deep signature/profile. The owner trusted the developer on iPhone 15 (iOS 26.4.2); install succeeded and the app launched with its process observed running. Investigate why the CocoaPods embed phase omitted this framework signature in a fresh archive.
- Bundle ID remains `com.example.xunaMobile`. App Store ID/icon warnings remain.
- Existing owner edits in `Runner.xcodeproj/project.pbxproj` and `Runner/Info.plist` were preserved.

## 2026-10-19 — S19a Life Lab completed

- Firmware: the LifeCore trace runner now runs `day <n>` (one step per simulated minute, past the `millis()` wrap) and `expect <path> <op> <value>`; `reboot` restarts the core clock at 0 as on the board. `lifecore_lab` prints the snapshot SHA-256 and the last decision's explanation and exits 1 on a failed expectation. Grammar frozen in `firmware/sim/README.md`. A 60-day trace runs in 0.05 s with identical output twice. Native and ASan 204/204, ESP32 build + purity PASS. Next: S19b scenarios.

## 2026-10-19 — Locale sync, teaching confirmation text, journal counts

- Mobile: four `home_*` keys existed only in `locales.g.dart`, so `get generate locales` would have dropped them. Added the three used keys to `vi_VN.json` with proper Vietnamese, removed the unused `home_replyTeachingApplied`. `home_replyConfirmTeaching` lacked its `@details` placeholder, so the chat bubble omitted the candidate (the review row under the chat already showed it); fixed and seen on the Android emulator. New test keeps JSON and generated keys/texts identical. Journal "Học được" cards no longer cite the device-wide feedback total for each context; they count only that context's retained episodes. 121/121 tests, analyze clean, lock unchanged; checked on the Android emulator in simulator mode.

## 2026-10-19 — Phone-free device E2E script

- Backend `scripts/device_e2e.py`: starts a real uvicorn server with a throwaway local OIDC issuer, simulates the board's Identity V2 frames (40 B request / 141 B READ, software P-256 key) and sends the same JSON bodies as the mobile app. Bind, re-bind, `pet_already_bound`, owner isolation, `consent_required`, U3 on, SSE turn, unknown pet 404 and audit trail: 15/15 PASS with `echo` and with Gemini `3.5-flash-lite` (1.5 s). `check.sh` 98/98. BLE, Flutter UI and Firebase are not covered.

## 2026-10-18 — Mobile pet bind, consent sheet and AI chat; persona rule

- Mobile: Identity V2 proof over BLE (`7a6e000d`, capability byte 3 bit 0, long write + poll, no resend), XUNA Cloud client (challenge, bind, pets, consents, SSE turn) with backend problem codes in Vietnamese, `BindPetToCloud` use case, bind button + U1–U3 consent sheet in the Device tab, AI replies in chat only when signed in + bound + U3 (labelled "AI · không ghi nhớ", never learned), local templates on any failure. Found and fixed a consent-conflict reload that was skipped while busy. 119/119 tests, analyze clean, debug APK PASS; not run on a phone or board.
- Backend: persona forbids claims of hearing/seeing (no mic/camera); benchmark gained two sensing prompts and a `noSensingClaim` check. Gemini `3.5-flash-lite` 14/14, TTFT median 0.85 s, all checks 1.00. 98/98 tests with PostgreSQL.

## 2026-10-17 — Gemini benchmark and provider options

- Vietnamese benchmark on Gemini: `3.5-flash-lite` 12/12, 0.92 s TTFT, chosen temporarily; `3.8-flash` needs `reasoning_effort` and hit free-tier limits. Added key-header and reasoning-effort options (Bifrost `x-bf-vk`). 93/93 backend tests.

## 2026-10-17 — Firebase Google sign-in validated

- Real Google sign-in on the Play Store emulator; backend accepted the Firebase ID token (`/v1/me` 200, owner created). Fixed the Google picker being cancelled by a 30 s timeout.

## 2026-10-17 — Mobile Firebase Auth account

- Optional Google sign-in via Firebase (project `xuna-pet`), cloud connection check against `/v1/me`, sign-out; minSdk 23. 77/77 tests, debug APK PASS. Config file gitignored.

## 2026-10-17 — Firebase Auth preset, OpenAI-compatible provider, conversation SSE

- Backend verifies Firebase ID tokens; generic OpenAI-compatible streaming adapter for the owner's internal AI over OpenVPN; U3-guarded conversation turn endpoint that stores nothing; Vietnamese benchmark script and VPN ops guide. 91/91 tests with PostgreSQL.

## 2026-10-17 — Backend CLD-12 consent and audit

- U0-default consent with append-only history and route guard; append-only audit trail with content-free metadata; DB triggers block UPDATE/DELETE. 78/78 tests with PostgreSQL.

## 2026-10-17 — Firmware Identity V2 device proof

- P-256 device key in NVS, BLE `7a6e000d` proof (Bind only), capability byte 3 bit 0; golden message shared with backend. Native/ASan 200/200; uploaded; real pet bound end to end against the local backend (201 then idempotent 200).

## 2026-10-17 — Backend CLD-11 identity

- OIDC owner auth, device challenges, ECDSA P-256 trust-on-first-use pet binding (Pet/Brain/Device), idempotency keys, migration 0002; UTC session fix. 59/59 tests with PostgreSQL. CLD-01 decisions recorded as owner-delegated approvals.

## 2026-10-17 — Backend scaffold and Cloud Phase 0 drafts

- `backend/`: FastAPI/async SQLAlchemy/Alembic modular monolith (health, identity, exports, cognition ports + provider registry), coding rules `backend/AGENTS.md`, architecture test, `scripts/check.sh`, CI. ruff/mypy strict clean; pytest 38/38 with PostgreSQL; uvicorn smoke OK.
- Drafts: CLD-01 threat model, CLD-02 HTTP contract. Xiaozhi server used as an architecture reference only (MIT, no code copied).

## 2026-10-17 — Board upload: Identity V1 live, GATT handle fix

- Backed up partition/NVS, uploaded S10-sync + S26/S27-lite + Identity V1. Fixed `createService` 15-handle default that hid `000b`/`000c`; re-uploaded. Mac BLE: capabilities `0xbf`, PetId/generation match NVS, TimeSync Synced/evening, explanation grounded. Gate (b) met; app export pending a phone.

## 2026-10-17 — Cloud gate A + B: Identity V1 and local JSON export

- Firmware: `IdentityCodec` + READ characteristic `7a6e000c` (24 B: petId, origin, snapshot generation), capability bit 7 (`0xbf`), cached GATT update on change. Native/ASan 195/195, ESP32 build/purity PASS.
- Mobile: identity read path and `xuna.export.v1` export (identity, capabilities, life, memories, explanation, SHA-256) written locally from the Device tab; `crypto` 3.0.7 promoted to a direct dependency. Analyze clean, 72/72 tests PASS.
- Source/host only: no upload, BLE, phone run, commit or push. Gates (b)/(c) close after the combined board session.

## 2026-10-17 — Cloud gate sprint decisions

- Committed S10-sync (firmware `f339fff`, mobile `d34c63b`, parent `b7d71cc`; not pushed).
- Owner approved accelerating toward Cloud: app JSON export for gate (c), backend CLD-01/02/10 in parallel now, one combined board session. Plan and proposed Identity V1 format in [sprint record](docs/roadmap/cloud/cloud-gate-sprint-2026-10-17.md). Documentation only.

## 2026-10-17 — S10-sync production source integration

- Wired opcode 5 TimeSync through the production firmware adapter and 16-byte BLE queue; advertised capability bit 4 and added Serial clock/day-part diagnostics.
- Mobile syncs UTC/timezone after connect and every six hours while connected; simulator does not advertise a clock capability it cannot model.
- Firmware full native and ESP32 build/purity PASS; Flutter analyze clean and 60/60 tests PASS. Updated AGP 8.1.0 → 8.2.2 to resolve the JDK 21 build incompatibility; debug APK build/install/cold launch PASS on `emulator-5554`. ESP32 absent, so no BLE/Serial validation or upload. No commit/push.

## 2026-10-16 — Commit all pending work

- At the owner's request, committed all pending firmware (`b0f4ded`) and mobile (`4976147`) changes, including existing artwork/UI and S13/S18/S26/S27-lite work. Parent commit records documentation, decisions, session records and both submodule pointers.
- Staged whitespace checks PASS; no tests rerun, push, upload or hardware operation. Earlier validation and owner-skipped items remain unchanged.

## 2026-10-16 — S26/S27-lite learning explanation upgrade (source only)

- Enabled opcode 6/bit 5 and 20-byte explanation READ `000b`, added expired result 8. Explanation reflects committed evidence and is ready before command notification; unchanged snapshot schema, GPIO0 direct Happy, TimeSync/hatch deferred.
- Mobile Chat “tại sao” and confirmation reply now use firmware evidence; rated and stated evidence remain separate. Added domain/data/use-case wiring, malformed-frame validation, expired message and timeout evidence read without resend. Old firmware/simulator never fabricate explanations.
- Firmware full native/ASan 192/192 each, final adapter 11/11 each; ESP32/purity PASS (52,088 B RAM / 2,851,677 B Flash). Flutter 3.32.8 analyze clean, tests 59/59, APK PASS; lock unchanged.
- No new upload/board/phone operations after owner requested stopping remaining physical checks; no commit/push. [Record](docs/roadmap/sessions/S26-S27-lite-2026-10-16.md). Compatible app must precede a later enhanced firmware rollout.

## 2026-10-16 — S13/S18 upload and owner-skipped remaining tests

- Authorized upload PASS, hashes verified. First boot Migrated, durable PetId logged, Happy/Idle preserved; one reboot recover Ok with same PetId. Setup stack 8,228/8,036 B; captured feedback result 0, stack 8,036 B. Owner reported display/emotions/buttons/app smoke OK.
- Owner requested skipping remaining board tests and proceeding with upgrades. Stopped capture before five-minute checkpoint. Checkpoint, reboot ×3 completion, measured feedback reboot survival, Forget/reboot and final NVS comparisons **not validated**. No more board actions; [record](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md). No commit/push.

## 2026-10-16 — S13/S18 rollback verification and backup refresh

- USB 64 KiB read PASS; esptool `verify_flash` confirmed the entire 2,840,752-byte rollback image matches the board digest. Saved verified image externally. Fresh device partition/NVS reads are identical to backup; decoder/migration PASS (Happy/Idle, 4 feedback).
- Awaiting explicit upload authorization. No source edits, application upload, NVS write/restore, test rerun, commit or push. Long USB read root cause remains unknown. [Evidence](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md).

## 2026-10-16 — S13/S18 lower-baud read retry

- Owner-authorized prior-application read at 115200 failed with another short USB read (exit 2, received 0xfe0 / expected 0x1000). Board work stopped; no upload or NVS write/restore. Existing verified backup retained; freshness recheck not run. Updated handoff and [switch record](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md); no code change, tests rerun, commit or push.

## 2026-10-16 — S13 + S18 production switch prepared; upload pending

- Production source now uses LifeCore/ProductLearner and LifeSnapshot v2 in NVS, identity migration, adapter-driven BLE/buttons/routine and checkpoint; ERROR_SAFE snapshot writes guarded. Kept 12-byte v1 packets, capability bytes and existing artwork. Loop stack 16 KiB; runtime headroom not measured.
- Native and ASan/UBSan **190/190 PASS**, S01 replay/purity/build PASS; RAM **52,048 B**, Flash **2,850,341 B**. Device table matches build; verified NVS backup and real-pet migration PASS (**Happy/Idle**, 4 feedback).
- Optional old-application read failed with short USB data; board operations stopped per owner instruction. **No upload**, erase, NVS restore, commit or push. All new-firmware physical checks pending. [Evidence and hashes](docs/roadmap/sessions/S13-S18-switch-2026-10-16.md).

## 2026-10-16 — S08a + S13/S18 integration preparation (host)

- Firmware (uncommitted): `xuna/protocol/V1LifeCoreAdapter.h`, `test/test_v1_adapter` (S01 transcript replay and 6 cases), `include/NvsSnapshotStore.h` (D2a; not linked), `tools/nvs_life_dump.py`, `sim/migration_check.cpp` and a sim README section.
- Results: S01 bytes reproduced through LifeCore; real-timing approval expires under D3; real pet backups migrate identically; idle+happy-disliked edge prefers Curious. Native and ASan 189/189, purity PASS, ESP32 build SUCCESS with production size unchanged. Evidence: [record](docs/roadmap/sessions/S13-S18-integration-prep-2026-10-16.md).
- No board/phone operation, upload, NVS write, commit or push; backups read only.


## 2026-10-16 — Gate simplification decisions and handoff cleanup

- Independent plan review: the session gates were self-blocking after the owner-skipped checks, and several handoffs were stale (including a next action to upload `5d872d3`, which would revert the new artwork).
- Owner approved: S01 closed with owner-skipped items; D2a (LifeSnapshot v2 in NVS A/B `life0/life1`, v1 keys as rollback, LittleFS decision moved to S32); S13 + S18 merged, absorbing S08b/S09 with S08a as regression; Cloud gate revised from M05b/S38 to snapshot v2 on the board + durable `PetId` over BLE + local export (no backend code authorized).
- Status adjustments: S10 split (sync after the integration, hatch deferred); S23/S24 superseded; S17 closed on owner smoke; TRIAL-01 superseded.
- Updated AGENTS.md §3, ADR-0002, ADR-0009, decision index, Cloud plan, implementation plan, session plan, PROCESS.md and PLAN.md. Documentation only: no code, build, test, board/app operation, commit or push.


## 2026-10-16 — Owner smoke acceptance and deferred extended checks

- Owner confirmed pet display, all four expressions, both physical buttons and mobile BLE connection are OK on the current build: owner-observed smoke PASS.
- Owner explicitly chose to skip the 1–2-hour life-feel trial and power-cut matrix for this iteration, favoring incremental improvements. Mark these checks owner-skipped, not passed; do not require them again as prerequisites to routine UI/local feature work. This does not approve a storage architecture choice or clear unrelated S11/D2/S13/S18 gates.
- Cloud architecture plan / Phase 0 documentation is complete and approved. Backend implementation still waits for M05b/S38 under the existing plan; no backend work authorized in this status session. Next local work is S10 runtime/transport integration, then the remaining foundation/learning wiring gates.
- Documentation update only; no tests, board/app operations, commit or push.


## 2026-10-16 — Warm beige chat avatar

- Added the existing `AppColors.xunaCardPressed` warm beige (#EFE8D6) behind the circular XUNA chat avatar in HomeChatBubble. Preserved shared pet widget, geometry and pixel filtering.
- Flutter 3.32.8 analyze clean; formatting/whitespace PASS; debug APK build/install/launch PASS on Redmi. No tests rerun for this color-only change. Previous changes preserved; no commit/push.


## 2026-10-16 — Simple pixel backgrounds on mobile

- Owner requested backgrounds for Home, Chat and Journal, then rejected detailed image drafts in favor of simple pixels. Final implementation uses code-native flat rectangles on an 80×60 grid in `AppXunaPet`: window/plant room, bookshelf/lamp reading nook, fence/cloud garden. Generated detailed drafts were discarded from the workspace and are not bundled.
- Room state adapter supports the background option; Home uses room, Chat header reading, Journal thumbnails garden. Transparent pet GIFs stay separate from backdrops, generated reproducibly by the existing export tool. Existing firmware/board preview remains unchanged. These backdrops are decorative, not physical-location or growth claims.
- Flutter 3.32.8 analyze clean, full test run 49/49 PASS (including small-card background coverage), focused shared widget tests 2/2 PASS; debug APK build/install/launch PASS on Redmi. GIF alpha checked, lock unchanged, whitespace clean. Physical visual review pending owner. No board operation, commit/push; earlier work preserved.


## 2026-10-16 — Shared mobile XUNA artwork base

- Owner requested consistent XUNA art throughout mobile using the base widgets. Added `shared/widgets/AppXunaPet` and UI-only `AppPetExpression`, exported from `widget_src.dart`; shared code has no feature dependencies. `HomePetScene` remains the device-state adapter to this base.
- Replaced old character illustrations in chat header, chat avatar, journal cards and growth placeholder with transparent XUNA portraits. Room and connected board preview reuse the same base in scene/animation mode. Decorative portraits are static, not claims about device emotion or implemented growth. No remaining feature references to legacy HERO/RAIN/LEARN images; old asset files retained.
- Extended deterministic export script for four transparent PNG portraits; README documents usage. Flutter 3.32.8 analyze clean, full tests 48/48 PASS, APK build/install/launch PASS on Redmi. Lock unchanged. Physical visual acceptance pending owner review; no firmware operation, commit/push. Earlier dirty changes retained.


## 2026-10-16 — Mobile pet artwork and animation

- Owner clarified the mobile complaint concerns pet artwork/animation. Added `HomePetScene` for the Home room and connected board-screen preview, driven by the device-reported `AnimationState`. Exported four GIF loops and still PNGs from firmware canonical anchored frames with `mobile/tools/export_pet_animation.py`; mobile builds consume checked-in assets without requiring firmware/Python.
- Offline/reduced-motion/TickerMode-disabled views use still images; no phone-owned pet progression. Loop phase is local presentation, not frame-synchronized with firmware. Existing UI layout retained. README documents regeneration.
- Flutter 3.32.8 analyze clean, 47/47 tests PASS including state/asset and reduced-motion coverage, debug APK build PASS, lock unchanged. `adb install -r` and launch PASS on Redmi 2510DRA23E. Physical BLE/visual acceptance pending owner observation. No firmware operation, commit or push; previous dirty work preserved.


## 2026-10-16 — Mobile build/install for emotion checks

- Owner requested the mobile build to exercise other firmware expressions. Built Android debug APK with pinned Flutter 3.32.8 (`flutter build apk --debug` via the pinned SDK binary); build PASS. Existing Device-tab expression controls cover Idle/Happy/Curious/Sleep; no code changes required.
- `adb install -r` PASS on Redmi 2510DRA23E, then `am start com.example.xuna_mobile/.MainActivity` PASS. Mobile Git and pubspec.lock unchanged. No analyze/test rerun for this build-only session. Physical BLE emotion observations remain owner acceptance work; app launch does not establish BLE/animation acceptance. No commit/push.


## 2026-10-16 — Anchored pet motion revision

- Owner reported sliding/tilting and sparse animation in the first replacement. Reworked `firmware/tools/generate_pet_scene.py` to use one upright reference, redraw expressions on the same body, keep feet byte-identical, and limit upper-body breathing to two pixels. Removed whole-body translation/rotation. Idle blinks, Happy smiles/pulses, Curious moves pupils, Sleep breathes with closed eyes.
- Four 32-sample timelines at 100 ms/sample (128 exported frames; intentional held/repeated poses, not 128 unique drawings). Exported PNG sheet, LCD preview and timed GIF. `PetVisualAnimation.h` selects the corresponding row, resets on state changes and handles unsigned time rollover.
- Validation: native `test_visual` 2/2 PASS (state switches, loop, late calls, rollover); generator fixed-foot/transparent-key assertions PASS; ESP32 build/purity PASS. Static RAM 49,024 B; image 2,840,385 B / 6,553,600 B; fixed render buffer 13,824 B. Other core logic unchanged; full suite was not rerun this revision.
- Upload PASS (hash verified); ~15-second Serial smoke recorded Idle, GPIO0 Happy and return to Idle, no spontaneous error/reset; max draw 5,427 us. Post-upload NVS byte-identical to backup. This is runtime smoke, not visual acceptance.
- Partition table read and matches build byte-for-byte. Pre-upload NVS backup stored outside Git at `/Users/xthao28/xuna_backups/2026-10-16-pet-motion/`; NVS SHA-256 `d7d12a9bebe95738bad48bdee08ce90f7de284bbd928ca24611286c5988ec52d`. Physical motion acceptance remains pending owner observation. No commit/push.


## 2026-10-16 — Owner-requested XUNA pet artwork replacement

- Replaced firmware pet art with the generated reference sheet retained at `firmware/assets/source/xuna-emotion-sheet-v2.png`. Deterministic Pillow conversion preserves alpha, uses nearest-neighbor scaling and exports 16 fixed 96×72 frames (Idle/Happy/Curious/Sleep), RGB565 arrays, PNG/GIF and LCD preview. Existing room background and anchor remain unchanged.
- Updated presentation-only frame selection for four loops; pet-life, learning and storage logic were not edited. Built current firmware production path, which already includes the previously prepared BoardLearner/life-feel trial.
- Validation: native 182/182 PASS; ESP32 build/purity PASS, static RAM 49,024 B, Flash 1,292,101 B. Pixel assets 329,984 B; render buffer stays 13,824 B. Upload to ESP32-S3 at `/dev/cu.usbmodem14101` PASS, hashes verified. Physical visual/button acceptance pending owner observation.
- Post-upload NVS is byte-for-byte identical to the backup (SHA-256 `d7d12a9bebe95738bad48bdee08ce90f7de284bbd928ca24611286c5988ec52d`). Serial smoke ~20 seconds: no spontaneous reset/error, stable heap 251,536 B, max draw 4,815 us; not long-run acceptance.
- Device partition table matches build; NVS offset 0x9000, size 0x5000 backed up before upload outside Git at `/Users/xthao28/xuna_backups/2026-10-16-pet-v2/`. No commit/push or mobile changes.


## 2026-10-16 — Cloud & Brain architecture baseline (documentation only)

- Added the approved [Cloud implementation plan](docs/architecture/XUNA_CLOUD_IMPLEMENTATION_PLAN.md): device authority, four-ID model, FastAPI/PostgreSQL modular-monolith baseline, confirmation lifecycle, privacy defaults, Phase 0–6 gates and CLD-00–60 work breakdown.
- Added [ADR-0008](docs/decisions/ADR-0008-cloud-brain-authority-and-identity.md) and [ADR-0009](docs/decisions/ADR-0009-cloud-platform-sequencing-and-privacy.md); updated ADR-0007 and the decision registry. D23 is partially approved; provider, broker, hosting, launch legal details and D24 remain open.
- No backend code, dependency, provider call, database, board/app operation, build, commit or push.

This file records work actually performed, including uncommitted changes, validation and handoff updates. Entries are not evidence that a Git commit or release exists. Read [PROCESS.md](PROCESS.md) for the current snapshot and [PLAN.md](PLAN.md) for remaining work. AGENTS.md remains canonical for decisions.

## 2026-10-16 — S10 protocol design freeze

- Owner approved the TimeSync opcode 5 and Hatch opcode 7 wire contracts, rollback/trust/sync cadence, GPIO14 hatch gesture, additive 8-byte Lifecycle V1 projection, independent capability bits, explicit unknown-birth confirmation, four day-part ranges, existing result-code mapping and commit-first identity durability.
- Updated the S10 evidence record and root handoffs. This is design approval only: no firmware/mobile implementation or validation was claimed.
- A read-only Windows device scan found only COM1; no ESP32 was detected. No partition/NVS read, backup, build, upload, app operation, commit or push occurred.

## 2026-10-16 — S10 pure protocol codecs

- Added feature-gated firmware parsing for TimeSync/Hatch, 16-byte command-cache support restricted to the approved frame, and a pure C++11 Lifecycle V1 encoder. The legacy parser remains unchanged unless the new feature flags are supplied.
- Added Dart TimeSync/Hatch encoding and decoding, capability queries, strict Lifecycle V1 decoding and wire models. No BLE data-source, repository, UI or production capability was enabled.
- Validation: firmware native 182/182 PASS; ESP32 build/core purity PASS at 49,040 B RAM and 1,347,757 B Flash; Flutter 3.32.8 analyze clean and 45/45 tests PASS; whitespace checks PASS. No board/phone operation, upload, commit or push.

## 2026-10-15 — S24a: stated preference (opcode 6) in the device core

- Opcode 6 parse behind a flag (production unchanged); `PreferenceLearnerV3::state` adds capped, decaying `user_stated` evidence (w_s 0.5, cap 2 ratings, both [P]; latest statement wins); `ProductLearner`/`LifeCore` commit-first handling with validation, in-session dedup and ERROR_SAFE refusal; explanation reports stated mass and reason `Told`; LifeSnapshot v2 section 12.
- 15 new tests; native 179/179 PASS; traces/timeline unchanged; Xtensa smoke PASS. ESP32 RAM 48,976 B (+648, shared learner cells), Flash 1,347,853 B. Evidence: [S24a record](docs/roadmap/sessions/S24a-stated-preference-2026-10-15.md).
## 2026-10-15 — S39: Conversation Layer A extractor (mobile)

- Added the pure Dart Layer A domain in `mobile/lib/features/conversation/domain`: `CandidateEvent`, `ExtractionResult`, `PreferenceContext`, `DayPart` and `ExtractCandidateUseCase` (LocalRuleExtractor from the S22 phrase table: ratings, context requests, stated preferences with follow-up for a missing context, AskWhy; hypotheticals, questions, quotes, injection and Layer B produce nothing). V1 parser unchanged; not wired into the UI (S27a).
- Flutter 3.32.8: lock unchanged, analyze clean, 39/39 tests PASS (10 new). Evidence: [S39 record](docs/roadmap/sessions/S39-layer-a-extractor-2026-10-15.md).
## 2026-10-15 — S22 learning and conversation decisions

- Owner approved, all as recommended: D4 (E10 UCB exploration, labelled in "Why?"), D6 (implicit feedback off), Layer A replies as "mình – bạn", Vietnamese first, one follow-up question when a statement has no context, the Layer A phrase table as the S39 starting set; D16 deferred (text first). Recorded in AGENTS.md §3, plan §11/§18, the decision index and the [S22 packet](docs/roadmap/sessions/S22-decision-packet-2026-10-15.md). Documentation only.
## 2026-10-15 — D3 approved: 120 s feedback window

- Owner approved D3 (AGENTS.md §3, plan §18, decision index): ratings are accepted for 120 s after a reaction is shown; direct input still invalidates. Implemented in `ProductLearner`/`LifeCore` (expiry, `feedbackExpired`, `decisionExpired`). 5 new tests; native 164/164 PASS; traces and ESP32 build unchanged. Production BLE path not yet changed.
## 2026-10-15 — S10 host part: trusted time and day-part learning

- `ClockModel` moved into `LifeCore` (`LifeCore::sync`, the future opcode 5 seam); decisions use day-part cells once time is trusted (coarse cell otherwise); LifeSnapshot v2 Clock section (id 2) persists the rollback watermark and offset; 32 → 64-bit monotonic extension for `millis()` wrap. Trace `sync` verb supported, new `c8_dayparts.trace`, CSV gains sync columns.
- 7 new tests incl. morning/evening greeting preferences diverging. Native 159/159 PASS; ESP32 build unchanged; Xtensa smoke PASS; `life_timeline` identical to HEAD. Protocol/firmware/mobile parts of S10 not done. Evidence: [S10 host record](docs/roadmap/sessions/S10-host-trusted-time-2026-10-15.md).
## 2026-10-15 — S18 preparation: product learner in LifeCore (host)

- Owner chose to replace LifeCore's v1-decides/v3-shadow composition. `LifeCore` now uses `ProductLearner` (new): learner v3 in the D5 shape 3 × 5 × 3 decides, LifeSnapshot v2 is the durable record (commit-first through `ISnapshotCommit`). New `Greeting` event for GPIO0 with device decision IDs; choices limited to actions the FSM accepts; direct requests invalidate the pending decision; forget writes both slots. Snapshot lab and trace runner moved to v2 (`MemorySnapshotStore`). `SnapshotStore::recover`: lone torn v2 slot without v1 → Missing (was Corrupt).
- Native 152/152 PASS; ESP32 build unchanged; Xtensa compile smoke PASS; `life_timeline` output identical to HEAD. Production firmware unchanged. Evidence: [S18 preparation record](docs/roadmap/sessions/S18-prep-product-learner-2026-10-15.md).
## 2026-10-15 — S12a + S12b: LifeSnapshot v2 codec and v1 migration (host)

- Owner chose to run S12a/S12b before S11/D2 (the codec does not depend on the medium). Added `xuna/persist/SnapshotCodec.h` (sectioned v2 layout, CRC-32, typed `LoadResult`, validate-before-mutate), `Migrations.h` (v1 → v2 with the E10-C cap) and `SnapshotStore.h` (`ISnapshotStore`, A/B recovery and commit-first write). Layout frozen in plan §7.5; product snapshot 544 B of 1,536 B.
- 16 new tests incl. every-bit-flip and every-offset torn-write sweeps. Native 143/143 PASS; ESP32 build unchanged; Xtensa compile smoke PASS. Not wired (S13 after D2). Evidence: [S12 record](docs/roadmap/sessions/S12-snapshot-v2-2026-10-15.md).
## 2026-10-15 — Board trial instrumentation

- The LCD shows only the sprite (resting draws idle) and the board does not compute mood, so the life-feel trial was not measurable. `main.cpp` now logs `needs …` every 5 s and `activity_change …` on each change; added `tools/serial_capture.py` and `sim/board_needs_report.py`. Native 127/127 PASS; ESP32 RAM unchanged, Flash 1,347,657 B (+576). Firmware commit `5d872d3`. Not uploaded.
## 2026-10-15 — Learner v3 board-trial shortcut

- Owner chose to skip LifeSnapshot v2 for a first board trial. `BoardLearner` lets v3 decide BLE opcode 2 choices, the quiet routine and the reported preference, while v1 stays the durable 96-byte record (commit-first, §9.5) and v3 is rebuilt from it at boot. `BleManager`/`main.cpp` wired; BLE bytes, snapshot format and NVS keys unchanged.
- 6 new tests; native 127/127 PASS; ESP32 build SUCCESS (RAM 48,328 B, Flash 1,347,081 B). Known limits: recency lost across reboots; 2 × 2 shape only. Not uploaded (board not connected). Evidence: [board trial record](docs/roadmap/learning/learner-v3-board-trial-2026-10-15.md).
## 2026-10-15 — Life-feel configuration enabled for a board trial

- Owner approved the 11 life-feel targets and enabling the candidate configuration for a board trial. Added `xuna/life/LifeFeel.h` (`lifeFeelTuning`, `lifeFeelThresholds`, shared `applyAcceptedAction`); production `main.cpp` and `BleManager` and the `LifeCore` defaults use it. Values stay provisional until the owner board check.
- New test (accepted happy spends 409 energy, adds 4096 stimulation). Native 121/121 PASS; ESP32 build SUCCESS (RAM 46,224 B, Flash 1,343,589 B). Not uploaded: board not connected. No commit or push.
## 2026-10-15 — Life Lab Phase 0 slice 2: needs, rest and mood timeline

- Added `sim/life_timeline.cpp` and `sim/life_sweep.py`; inactive Life Lab knobs (`ActivityThresholds` with `wakeEnergy`/`resumeInterruptedRest`, `LifeTuning.actionCostPercent`/`stimulationPerInteraction`, `Needs::spend/stimulate`, LifeCore tuning parameters) with defaults equal to shipped behaviour; 2 tests. Native 120/120 PASS; ESP32 RAM +16 B, Flash +116 B.
- Findings (shipped values, also on the board): after ~49 min XUNA cycles 8 min awake / 4 min resting with energy 25–38%; actions never spend energy; stimulation never rises (excited/curious/overwhelmed unreachable); interrupted rest is lost; sleep needs explicit wake.
- Proposed life-feel targets and a candidate configuration passing all 11 checks; owner decision needed before board use. Evidence: [needs timeline record](docs/roadmap/learning/life-lab-needs-timeline-2026-10-15.md). No board/mobile operation, commit or push.
## 2026-10-15 — E10 review packet

- Added [E10 review packet](docs/roadmap/learning/E10-review-packet-2026-10-15.md) with decision requests E10-A/B/C, selection evidence, §9.9 status per scenario, owner board checks, gates and risks.
- Added the §9.9 spam test (1,000 feedback attempts → 1 apply, 1 urgent commit). Native 118/118 PASS.
- Owner approved E10-A (v3 + UCB for M05a), E10-B (γ 0.90, k 1, m 1, bonus 0.15) and E10-C (capped v1 migration). Recorded in AGENTS.md §3, plan §7.5/§9.4/§16.2 and the decision index. No board/mobile operation, commit or push.
## 2026-10-15 — D5 decision and product learner vocabulary

- Owner approved D5: learnable actions idle, happy, curious (existing art) and the GPIO0 press as a learnable `button_greeting` context; day parts remain planned with S10. Recorded in AGENTS.md §3, plan §18 and the decision index.
- Added `learning/LearnerVocabulary.h` (interactions, index → ActionId keeping v1 positions, `productLearnerConfig()` 3 × 5 × 3, 458 B payload), a test, and `product_3x3` / `product_3x3_reversal` bench scenarios. Tuned v3: median 14 trials to learn; 96.5% recovery after reversal (v2 20.5%).
- Native 117/117 PASS; ESP32 build unchanged. LifeCore shadow stays 2 × 2 until v3 is authoritative. No board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 5: §9.5 commit-first parity in LifeCore

- Added `ILifeCommit` and `PreferenceLearnerV3::accepts()`; `LearningBridgeV3` now validates, stages v1, commits, then applies v1 and v3 (Applied/Rejected/CommitFailed). `LifeCore::setCommitter()` with `feedbackCommitted`/`feedbackNotReady` outputs; `LifeCoreSnapshotLab` is the committer; trace runner counts urgent commits.
- A failed commit leaves v1, generation and the v3 shadow unchanged and keeps the decision pending for retry (BLE result 7 semantics). Traces c2/c3 now reflect this. Resolves the earlier lab finding for LifeCore.
- Native 116/116 PASS; ESP32 build unchanged. No board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 4: v3 shadow candidate in LifeCore

- Added `LearningBridgeV3` (v1 baseline + v3 candidate, metrics). `LifeCore` now shadows learner v3 with `shadowConfig()` (tuned Proposed values) instead of v2 and exposes `shadowMetrics()`; candidate resets on boot. Host core only; production BLE path unchanged.
- Finding: the v2 bridge credited ratings to v2's own unshown action; the v3 bridge credits the shown action. Earlier v2 shadow agreement numbers are not valid evidence.
- Tests updated plus 2 bridge tests; native 115/115 PASS; ESP32 build unchanged; LifeCore traces replay with identical bookkeeping. No board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 3: learner codec, v1 migration, explanation

- Added `LearnerV3Codec` (LifeSnapshot v2 learner payload: 8-byte header + 10-byte cells, 408 B for 2 × 5 × 4; typed errors; validate before mutating; shape growth/shrink), `migrateFromV1` (ratio kept, mass capped at 1/(1 − γ)), `LearnerV3Explanation` (§9.6 evidence fields and reasons), raw `rated` counts in v3 and `test/test_learner_v3_codec` (7 tests).
- Fixed `tools/check_core_purity.py` to read sources as UTF-8; on Windows it crashed (cp1252) on non-Latin comment text.
- Validation: native 113/113 PASS; ESP32 build unchanged; purity PASS. Proposed amendment to plan §7.5 for the capped migration. Lab only; no production wiring, board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 2: learner v3 parameter sweep

- Added feedback-aware ε scaling (A/D), a late-context schedule with a generalization metric, the `new_daypart` scenario, `sim/learner_sweep.cpp` and `v3_C_tuned`; 1 more unit test. Native 106/106 PASS; ESP32 build unchanged.
- Sweep (137 configurations, 8 scenarios, 200 seeds): C with γ 0.90, k 1, m 1, bonus 0.15 ranks best (1.11 vs 1.27 for plan defaults; best A 2.42, best D 3.18). Tuned v3 reaches the target after reversal in 94% of seeds and under drift in 96%; it loses only to flat v2 when day parts disagree, and generalizes to a new day part 98% of the time.
- Tuned values recorded as Proposed replacements in plan §9.4 and the [learner v3 record](docs/roadmap/learning/learner-v3-phase1-2026-10-15.md). No production wiring, board/mobile operation, commit or push.
## 2026-10-15 — Phase 1 slice 1: learner v3 candidate

- Owner asked to start Phase 1. Added lab/shadow `PreferenceLearnerV3` (plan §9.3 Q16.16 discounted Beta, rated-cell-only discount, hierarchical day-part prior; §9.4 policies Greedy, A ε-greedy, C UCB, D learning progress), `test/test_learning_v3` (10 tests), `V3BenchLearner`, a `dayparts` scenario and `--gamma` in `learning_bench`.
- Validation: native 105/105 PASS; ESP32 build SUCCESS with unchanged RAM 46,208 B / Flash 1,343,337 B (not linked); purity PASS.
- Findings (200 seeds): v3 C recovers after a reversal in 84% of seeds (γ 0.95) or 98% (γ 0.90), against v1 0% and v2 26%; C is the preliminary E10 winner. A and D over-explore when ratings are sparse. The hierarchical prior (k 2, m 3) learns slower than flat contexts when day parts disagree. γ 0.90 adapts faster but flips more under noise.
- Evidence: [learner v3 record](docs/roadmap/learning/learner-v3-phase1-2026-10-15.md); plan §9.4 note. No production wiring, board/mobile operation, commit or push.
## 2026-10-15 — Hybrid offline + online learning plan (documentation only)

- Owner asked to integrate an online layer (cloud, MQTT) combined with the existing offline learning. Recorded as owner-requested direction (AGENTS.md §3); technical choices stay Proposed.
- Added [ADR-0007](docs/decisions/ADR-0007-hybrid-offline-online-learning.md) and plan §22 (contract H1–H8, capabilities O1–O6, phone-gateway then device MQTT/TLS transport, sequencing), experiments E14/E15, decisions D21–D24, decision-index rows and an online-layer table per learning phase. Cites the Moxie (2025-01-30) and Vector server shutdowns as the reason for the offline-complete rule.
- Owner then approved D21 and D22 (broker/provider, D23, D24 still open). No code, build or board/mobile operation.
## 2026-10-15 — Life Lab Phase 0 slice 1: closed-loop learner bench

- Owner approved L-D1–L-D5 (recorded in AGENTS.md §3, plan §18; L-D5 = research on touch, IMU and microphone only) and chose the closed-loop Life Lab next.
- Added host-only `xuna/lab/OwnerModel.h` (oracle, reversal, drift, no-feedback, sparse rating) and `xuna/lab/LearnerBench.h` (random/static/v1/v2 adapters, regret, greedy-correct, trials to target, flips, Brier, no-feedback invariance), `test/test_life_lab` (8 tests) and `sim/learning_bench.cpp` (200 seeds, bootstrap CIs, `--curves`).
- Validation: native 95/95 PASS; ESP32 build SUCCESS with unchanged RAM 46,208 B / Flash 1,343,337 B; purity PASS.
- Findings: v1 and v2 learn a stable preference in a median of 7 trials and beat baselines (§9.9 B holds). Neither handles change: after a reversal v1 never recovers in 60 trials (0% of seeds, worse than random) and v2 recovers in 26%; under drift v1 is worse than both baselines. No feedback leaves every learner unchanged (§9.9 D). Measured case for the §9.3 discounted estimator in Phase 1.
- Evidence: [Phase 0 record](docs/roadmap/learning/life-lab-phase0-2026-10-15.md). No production code change, board/mobile operation, commit or push.
## 2026-10-15 — Learning competitive upgrade plan (documentation only)

- Owner requested a review of large projects for strong learning algorithms suited to XUNA and an upgrade plan, and allowed revising the plan where needed.
- Added [XUNA_LEARNING_COMPETITIVE_UPGRADE.md](docs/architecture/XUNA_LEARNING_COMPETITIVE_UPGRADE.md) (Proposed): competitor review (public/marketing claims), algorithm fit table, six gaps, phases 0–6, decisions and sources.
- Amended the implementation plan ([P]): §9.4 Alternative D learning-progress curiosity and a note on what v2 actually implements; §9.9 drift and noisy/sparse scenarios; §9.10 teachable tricks; §18 L-D1–L-D5. Linked from the learning roadmap; PLAN rows LRN-01/02.
- Corrected the lab-run finding: plan §9.5 already defines the commit-failure model, so it is a parity task, not an open choice.
- No code, build, board/mobile operation, commit or push.
## 2026-10-15 — Host lab runs (LifeCore and learning)

- Owner chose host experiments. Built `sim/lifelab` and `sim/lifecore_lab` with g++ 16 `-Werror` (clean). Added 12 annotated traces in `firmware/sim/traces/`; results are deterministic across reruns.
- LifeCore: commit, power cut, reboot, pending-after-reboot, duplicate and window cases behave as designed. Finding: commit-failure semantics differ from production (BLE opcode 3 saves a copy and keeps the decision pending for retry; `LifeCore` applies first, clears pending, and in the lab cannot report or retry a failed commit). Plan §9.5 already defines the production model; bring `LifeCore` in line with a parity test before it replaces the BLE path (S18).
- Learning: with consistent scripted feedback v2 Brier is 0.052 vs 0.25 uniform; with no signal it is 0.279 (slightly worse than uniform). Traces are open-loop, so this is not evidence of preference learning, and v1/v2 agreement is not meaningful.
- Limits: runners are open-loop, print one summary row and cap traces at 64 events, so they cannot tune the Proposed needs/energy/FSM values. A closed-loop time-series lab is proposed, not started.
- Evidence: [lab runs record](docs/roadmap/learning/lifecore-lab-runs-2026-10-15.md). No production code change, board/mobile operation, commit or push.
## 2026-10-15 — Windows toolchain and gcc warning fix

- Owner installed the PlatformIO IDE extension (Core 6.2.0, not on PATH) and asked the agent to install the rest. Installed MSYS2 via winget and UCRT64 gcc/g++ 16.2.0 via pacman; added `C:\msys64\ucrt64\bin` to the user PATH. No admin rights used.
- First Windows native run: 15/17 suites; `test_life` and `test_v1_characterization` failed to compile because gcc 16 reports `-Wmisleading-indentation` (as error) on `BleProtocol.h` `remember()`. Fixed by splitting the line; no behavior change.
- Validation on Windows: native 87/87 PASS (17 suites); ESP32 build SUCCESS (RAM 46,208 B, Flash 1,343,337 B, 20 B below the Mac figure); `git diff --check` PASS. `native_asan` not run: MinGW lacks usable ASan/UBSan (needs WSL or the Mac). No board/mobile/backend operation, commit or push.
- Editor diagnostics: the Problems panel (clangd in Antigravity) showed false errors (`cstdint` not found, unknown `uint8_t`) because clangd had no compile flags and defaulted to missing MSVC headers. Added `firmware/.clangd` (strip xtensa-only flags; host tests and `sim/` use native C++11 flags with Unity instead of the ESP32 database) and ignored `compile_commands.json`/`.cache/`. Machine-local only: generated `compile_commands.json` via `pio run -e xuna_t_display_s3 -t compiledb`, added `clangd.arguments --query-driver` for the xtensa toolchain to Antigravity settings, and `%LOCALAPPDATA%\clangd\config.yaml` pointing host files at MSYS2. `clangd --check` reports no diagnostics on 65 tracked firmware sources.
## 2026-10-14 — Mobile UI: XUNA design system and four-tab home

- Owner-requested UI from Claude Design "XUNA App": XUNA tokens, bundled OFL fonts (Anton, Be Vietnam Pro, JetBrains Mono), 11 base widgets, 24 SVG icons, and a four-tab home (Nhà, Trò chuyện, Nhật ký, Thiết bị) on the existing controller and device repository.
- Real data only; growth, brightness, voice, image attach and device settings are shown locked as "SẮP CÓ". Chat transcript is in-memory only. No protocol, firmware, dependency or SDK change.
- Validation: analyze clean; 29/29 tests; `pubspec.lock` unchanged. Image stand-ins used where the design export was truncated. No real phone/board run, commit or push.
- Owner review: display headings no longer wrap/truncate and have looser line height for Vietnamese diacritics; UI design roadmap with Claude Design prompts added ([plan](docs/design/XUNA_UI_DESIGN_PLAN.md), Proposed).
- Evidence: [mobile UI record](docs/roadmap/ui/mobile-ui-design-system.md).
## 2026-10-14 — M04 firmware review fixes (first compiled validation)

- Owner-requested review of firmware `a518ede`/`f784626`/`6b1110e`, then fixes. First compilation of these slices: 5 of 16 native suites failed before the fixes.
- Production fixes: energy now recovers while Resting/Sleeping (owner-chosen; `energyRecoveryPerMinute` Proposed) so the pet no longer stays in Resting forever after ~48 min; BLE opcode 2 commits `context_` only with an accepted decision; a new reaction restarts the Reacting timer.
- Added pure `ActionGate` shared by `BleManager` and `LifeCore`; LifeCore visual expiry and accepted-only decisions; `GuardReboot` reason; C++11 compile fixes; corrected FSM/Needs tests; new `test_action_gate` regressions.
- Validation on Mac: native and ASan/UBSan 87/87 PASS (17 suites); ESP32 build SUCCESS (RAM 46,208 B, Flash 1,343,357 B, purity PASS); both `sim/` programs build. No board/mobile/backend operation, commit or push.
- Evidence: [review fixes record](docs/roadmap/milestones/M04-review-fixes-2026-10-14.md).
## 2026-10-14 — S16 action policy and visual boundary

- Added pure C++11 action registry, deny-by-default request validator, visual-intent fallback map and deterministic behavior selector for M04.5c.
- Added tests for action descriptors, validator rejection paths, stage fallback and seeded selector filtering/tie-breaks.
- Native/sanitizer/ESP32 validation is pending because this Windows environment has no PlatformIO or C++ compiler executable. No board/mobile/backend operation, commit or push.
- Evidence: [S16 record](docs/roadmap/sessions/S16-action-policy.md).
## 2026-10-14 — S15 Needs/Mood implementation

- Added pure C++11 `Needs` and transient `Mood` models for M04.5b, with bounded Q0.16 needs, monotonic catch-up decay, cold-boot reset and hysteresis labels.
- Added tests for partition-invariant catch-up, wrap/clamping and mood threshold behavior.
- Native/sanitizer/ESP32 validation is pending because this Windows environment has no PlatformIO or C++ compiler executable. No board/mobile/backend operation, commit or push.
- Evidence: [S15 record](docs/roadmap/sessions/S15-needs-mood.md).
## 2026-10-14 — S14 ActivityFsm implementation

- Implemented the pure C++11 ActivityFsm slice for M04.5a with nine states, table-driven legal transitions, explicit guard/rejection reasons and monotonic timeout handling.
- Added exhaustive-pair, guard, reboot-only safe-mode, explicit-wake, energy and uint32 wrap tests.
- Validation is pending: this Windows environment has no PlatformIO or C++ compiler executable. No board/mobile/backend operation, commit or push.
- Evidence: [S14 record](docs/roadmap/sessions/S14-activity-fsm.md).

## 2026-10-13 — Mobile toolchain fix and Clean Architecture refactor

- Owner approved restoring the lock with the pinned SDK and a refactor session, after adding a base widget rule (`mobile/AGENTS.md` §5.4: mandatory when UI repeats across screens, mandatory to use when one exists; none exist yet).
- Installed Flutter 3.32.8 via fvm; machine-local VS Code setting points to it (ignored via `.git/info/exclude`). Restored `mobile/pubspec.lock`; `fvm flutter pub get` keeps it unchanged.
- Refactored mobile `device`, `conversation` and `home` to the rules without protocol change: domain entities/contract/exceptions/use cases, wire models and explicit mappers, BLE data source contract with real and simulator implementations, repository error translation, use-case-only controller with `buildState`, localized strings via get_cli, feature widgets and `nav` confirm dialog. Rules gained clarifications found while applying them (cross-feature UI vocabulary, `codec/`, `AppTextStyle` maxLines, inline loading, test helper imports) and an updated §11 of known gaps.
- Validation on 3.32.8: analyze clean; 16/16 tests (10 ported, 6 new). No native build, app run, phone or board operation. No commit or push.

## 2026-10-13 — Mobile coding rules (documentation only)

- Owner requested Clean Architecture coding rules for `mobile/`, derived from the existing GetX base, that agents read before writing any feature.
- Added `mobile/AGENTS.md` (layer dependency rule, folder/naming conventions, domain/data/presentation rules, DI scopes, XUNA invariants, testing, toolchain, Definition of Done, and an inventory of current code that predates the rules), `mobile/docs/FEATURE_TEMPLATE.md` (feature skeleton) and `mobile/CLAUDE.md`. Linked from `mobile/README.md`, root `CLAUDE.md` and AGENTS.md §9.
- Template validation: the skeleton code, added to a scratch copy of mobile outside the repository, passed `flutter analyze` with no new issues, 14/14 tests (10 existing + 4 template) and `dart format`. Run on Flutter 3.41.1, the only SDK on this machine, not the pinned 3.32.8.
- No change to mobile source, tests or dependencies. Existing legacy deviations are documented, not refactored. No commit or push.
- Found `mobile/pubspec.lock` modified at 11:28 by pub from Flutter 3.41.1 / Dart 3.11.0 (`.dart_tool/package_config.json`), outside this session's commands, most likely an automatic IDE `pub get` (3.32.8 is not installed here). Changes include `analyzer` 6.11.0 → 6.4.1 and removal of `_macros`. Not committed; restored in the next entry.

## 2026-10-12 — Device-first Conversation direction (documentation only)

- Recorded owner's requested long-term device-first / Flutter-assisted direction; preserved accepted local MVP and D1/D7/D12/D14/D17. Voice implementation and D15 ordering remain unapproved.
- Added device voice architecture, feasibility/trust/failure contracts, Proposed ADR-0006 and decision index (ADR-0001 remains pending S02).
- Plan 0.1.2/session rev. 3: source-independent Foundation alongside M05a; S39 remains Foundation, S40–S42 extend it; separate Proposed VOICE-01–04 and D18–D20. No current session reorder: S02 → S00 → S01.
- Updated product spec, audit follow-up, canonical instructions and handoffs. Preserved historical implementation and hardware acceptance evidence.
- Validation PASS: `git diff --check`, local Markdown paths, 54 unchanged session-map rows/dependencies, no duplicate detailed session IDs, Markdown-only changed paths and clean submodules/unchanged gitlinks. No build/runtime test, source, dependency, hardware operations, commit or push.

## 2026-10-12 — Owner decisions D1, D7, D12, D14, D17

- The owner chose among the presented options and picked the recommended option for all five.
- D7: the local-first hatch variant (on the device or via the app) instead of app-only hatch.
- Recorded in AGENTS.md §3 (Approved) and plan §18.
- Amended plan §12 (Egg state, device gesture, opcode 7 `Hatch`, same-boot `bornAt` rule), §8.2 and §14.1.
- Session plan: S02 reduced to ADR-0001 and a decisions index; S06 (Egg/hatch logic, test-only fresh-device namespace); S10 (opcodes 5 and 7, app hatch flow).
- Audit report section D notes the update.
- No code, build, commit or push.

## 2026-10-12 — Plan audit (documentation only)

- Owner forwarded an external review checklist and asked for a re-check, adopting points only where they are technically and product-wise sound.
- Added [docs/architecture/XUNA_PLAN_AUDIT.md](docs/architecture/XUNA_PLAN_AUDIT.md): 17 findings (no Critical), milestone flow, decision register and over-engineering review.
- Plan updated to 0.1.1:
  - Conversation Layer A/B with the opcode 6 contract (§11.6);
  - AI technique taxonomy (§5.6);
  - instructed vs learned evidence;
  - D2/D10/D11 timing, D11a and new D14–D17;
  - E13 and risks R13/R14;
  - corrected A9 scope and T18 rollback facts, verified against Arduino-ESP32 2.0.14 sources.
- Session plan updated to rev. 2:
  - dependency fixes (S13, S17, S18, S02, S22, S29) and splits S08a/b, S12a/b, S19a/b;
  - new S24a, S27a, S27b (optional) and S42a;
  - verified NVS backup procedure;
  - S01 observed-byte baseline and write-storm power-cut method.
- Verification: cross-reference check of session/decision/experiment IDs and relative links; `git diff --check`. Submodules unchanged (firmware `be58099`, mobile `3846880`, backend `0032828`, clean). No build, test, flash, commit or push.

## 2026-10-12 — Technical implementation plan (planning only)

- Request: the owner asked to clone all submodules, then to produce a technical implementation plan from AGENTS.md and spec v0.3.0 (§23 Cognitive Development, §24 ePet/Xiaozhi references), without implementing code.
- Submodules: `git submodule update --init --recursive` checked out the recorded gitlinks: backend `0032828`, firmware `be58099`, mobile `3846880`. No gitlink or child changes.
- Plan: added [docs/architecture/XUNA_IMPLEMENTATION_PLAN.md](docs/architecture/XUNA_IMPLEMENTATION_PLAN.md), status **Proposed**. It contains:
  - repository inventory and gap analysis G1–G23;
  - target architecture;
  - 19 technique cards (ePet T1–T9, Xiaozhi T10–T19);
  - data model, state machines, and the learning, memory, conversation and time designs;
  - independently testable slices M04.0–M07;
  - experiments E1–E12, a resource budget, risks R1–R12 and owner decisions D1–D13.
- Upstream sources were read only from shallow clones in the session scratchpad; nothing was built or executed:
  - ePet `347ceaf` (MIT);
  - xiaozhi-esp32 `aef2ab0` (MIT);
  - xiaozhi-esp32-server `4576e39` (MIT).
- Verified the Arduino-ESP32 2.0.14 `default_16MB.csv`: NVS 20 KiB; unused `spiffs` partition 3.375 MiB.
- No build, test or upload was run. This Windows session has no `pio` or host C++ compiler in its PATH. No commit or push. The product spec remains untracked.
- Follow-up: added the session breakdown [docs/roadmap/XUNA_SESSION_PLAN.md](docs/roadmap/XUNA_SESSION_PLAN.md) (S00–S46, readiness assessment). Plan amendments: own `bootc` key, sectioned snapshot v2, TimeSync after the core command handler. Observed: Flutter 3.41.1 via fvm (recorded 3.32.8); WSL has no distribution.
- Owner requested committing the new documents. The spec, plan and session plan are now tracked in the root repository. Submodules are unchanged and nothing was pushed.

## 2026-10-11 — Publish local MVP checkpoint

- Owner requested commit/push of current code. Firmware `be58099` (`feat: implement local XUNA MVP life and BLE runtime`) and mobile `3846880` (`feat: add BLE learning and local text MVP companion`) pushed successfully to origin/dev, child working trees clean.
- Parent commit containing this entry records both gitlinks, owner-approved scope, simulator/software evidence and LILYGO corrected build/upload/startup/LCD/buttons evidence. Backend pointer/code unchanged.
- Final verification: Flutter analyzer and 10 tests PASS; host core tests PASS; life tests with ASan/UBSan PASS; staged whitespace checks PASS. Firmware build/upload evidence recorded in [local MVP](docs/roadmap/milestones/MVP-local.md).
- Physical iPhone BLE, board learning/reboot/power-loss/forget and long-run stability remain pending. M01 PCB revision/P07 still open. Next: real-phone acceptance, not a milestone-validation claim based on Git publication.

## 2026-10-11 — Local MVP implementation and LILYGO smoke

- Owner selected MVP through M05, approving device-owned local state/memory/preference and local text V1 without LLM. Kept Clean/GetX and pinned firmware baseline; no backend/voice/evolution/sensors.
- Firmware: BLE queue/versioned commands/status/capabilities/dedup; four sprite reactions; LifeEngine Beta/Bernoulli preference learning; bounded source-tagged feedback; two-slot checksummed snapshots and learned quiet routine. Mobile: physical BLE transport, result correlation/timeouts, simulator define, preference/memory/text consent UI and tests.
- Software verification: analyzer/10 mobile tests/simulator native build/run PASS; core host tests and life ASan/UBSan tests PASS. Preserve pending physical acceptance; see [MVP record](docs/roadmap/milestones/MVP-local.md).
- LILYGO requested build/upload PASS; observed first-boot missing NVS keys reported as errors, fixed with isKey checks; rebuild/reupload/22-second corrected startup PASS. Owner confirmed LCD and two buttons. Final linker RAM47504/327680, firmware964333/6553600; runtime details/limitations recorded separately.
- No physical iPhone BLE, learned board behavior, power-loss/reboot recovery or long MVP soak validation claimed. M01 PCB revision/P07 remain open.
- Owner subsequently requested publishing current code; child commits precede root docs/gitlinks. Git delivery record follows once child hashes are known.

## 2026-10-11 — Mobile simulator checkpoint committed and pushed

- Owner approved M02 proposal, then requested simulator-first mobile delivery with commit/push.
- Added DeviceRepository/RequestAnimation contracts, fake simulator data implementation, command/status codec and Home Clean/GetX UI for scan/connect/idle/happy/expiry/disconnect. Existing base/dependencies preserved; no physical BLE adapter/plugin yet.
- Validation: flutter analyze PASS; flutter test --reporter expanded PASS (4 tests including UI interaction flow); simulator debug build PASS; flutter run on iPhone 13/iOS 16.2 succeeded, rendered Home screenshot inspected. CocoaPods initially failed on locale; command-local UTF-8 rerun fixed it. Staged whitespace check PASS after trimming imported README whitespace.
- Mobile commit `24026b2` pushed successfully to origin/dev; child working tree clean. Includes previously uncommitted approved mobile base. Root/firmware changes preserved and uncommitted; parent mobile gitlink still 310e69f. Backend unchanged.
- Updated PROCESS/PLAN/M02 evidence; physical BLE and Android validation pending. M01 PCB revision/P07 remain open. Next: approved real BLE transport/firmware experiment, real iPhone validation.

## 2026-10-11 — M02 priority and BLE proposal

- Owner requested M02 while retaining M01 PCB revision/P07 limits; selected iOS with iPhone 13 simulator.
- Inspected requested handoff/source files and Git in all four repositories; branches/HEADs match handoff, existing changes preserved.
- Prepared [M02 proposal](docs/roadmap/milestones/M02-ble.md): UUIDs, versioned bounded binary messages, capabilities, correlation/errors, connection-local idempotency, timeout/reconnect, Clean/GetX integration and acceptance matrix. Library choices remain Proposed.
- Checked official library documentation and published archives/SDK constraints/licenses. No dependency or implementation changes; no build/tests/upload or physical BLE validation this session.
- Tooling: Flutter 3.32.8/Dart 3.8.1, Xcode 14.2, booted iPhone 13/iOS 16.2 simulator, PlatformIO Core 6.2.0, ESP32 USB present. Real-phone BLE pending.
- Updated AGENTS/PROCESS/PLAN priority and handoff; no commit/push/gitlink changes. Next: owner review, then scoped implementation and actual validation.

## 2026-10-11 — Scoped mobile cleanup preserving Clean/GetX

- Request/decision: owner clarified removal of unrelated feature screens/constants/prior branding, while retaining Clean architecture for future coding. AGENTS.md and PLAN.md updated to record the confirmed imported Clean/GetX direction.
- Changes: removed login/product-detail demos and related routes, province/login mappers and empty login test; startup opens Home XUNA. Retained generic core/shared base classes, dependencies, local/network infrastructure and generation tooling. Removed old endpoint; API clients now require explicit baseUrl and are not registered at startup. Removed old business-specific translations and unused response/Hive constants. Renamed Dart package and Android/iOS development identity/labels to XUNA; added mobile ignore rules/README.
- Validation: Flutter 3.32.8/Dart 3.8.1 pub get PASS, analyzer PASS; changed files formatted after sandbox Dart startup failure was resolved by outside-sandbox retry. iOS Info.plist syntax PASS. No final native build/device test or BLE implementation claimed.
- Git: mobile remains uncommitted/untracked imported work, child HEAD/gitlinks unchanged; firmware preserved, no commit/push. Original base archive remains in /private/tmp for recovery.

## 2026-10-11 — Restore owner's Flutter base

- Request: owner rejected the overly broad mobile cleanup and explicitly requested restoration.
- Result: restored all 165 files in the pre-cleanup archive `/private/tmp/xuna-mobile-template-20261011.tar.gz` and verified each file byte-for-byte against it; restored the original tracked mobile README from HEAD. Removed cleanup-only files/generated artifacts from the working tree by preserving them separately in `/private/tmp/xuna-mobile-cleanup-reverted-pdtikgl4`.
- Mobile status again matches the initial imported base: original GetX/core/shared layers, features, dependencies, assets, tests and Android/iOS settings retained as untracked additions. Earlier minimal-scaffold analysis/build attempts do not validate this restored base. No further cleanup authorized by this restoration.
- Git: firmware and other prior work preserved; no commit/push or submodule pointer change.

## 2026-10-11 — Inspect IDE Problems setup

- Request: investigate VS Code Problems before further work.
- Validation: normal IDE CLI `pio run -d firmware -e xuna_t_display_s3` PASS (2.95 seconds); no compiler errors in the incremental build. Direct VS Code Problems access unavailable; exact diagnostic messages requested from owner.
- Local IDE setup: `pio project init -d firmware --ide vscode --environment xuna_t_display_s3` generated previously absent, Git-ignored `firmware/.vscode` metadata with ESP32-S3 compiler, gnu++11 and forced Setup206 include. `platformio.ini` and source unchanged by this inspection. Root-folder VS Code may require opening firmware as its workspace to apply this metadata.
- Limits: no claim that visible Problems have cleared; awaiting actual messages/UI recheck. No upload, commit or push.

## 2026-10-11 — M01 upload and initial physical checks

- Request / tasks: owner confirmed continuation after connection checkpoint; P01/P03 done, basic P04 owner-confirmed; P05 and scoped P06 done; P02 revision/P07 remain open.
- Validation: normal IDE Core 6.2.0 build PASS, host C++ tests PASS, upload at 921600 baud PASS with hashes verified. Corrected image linker RAM 21,840 bytes, firmware 319,737 bytes. Startup confirms Flash 16 MiB and PSRAM chip 8 MiB.
- Fix / P06: actual startup exposed a false PSRAM capacity warning because Arduino `getPsramSize()` reports heap bytes. Use pinned ESP-IDF chip-size API for capacity and rename heap diagnostic; rebuild/upload PASS. No animation/input changes.
- Physical evidence: owner read model T-Display-S3 and confirmed LCD, idle/happy, timeout, GPIO14 and held-button behavior. [Detailed run](docs/roadmap/milestones/M01-bring-up.md#build-upload-and-physical-run--2026-10-11). >10-minute stability PASS (125 windows, no resets/errors, settled heap unchanged); owner confirmed reset/reconnect boot and buttons with Monitor closed. PCB revision unknown; M01 not Validated.
- Git: uncommitted firmware main.cpp/README and root handoff updates; HEADs/gitlinks unchanged, mobile/backend untouched; no commit/push.
- Next: record exact PCB revision and review final acceptance before P07. Monitor closed; no later milestone started.

## 2026-10-11 — USB and ROM connection checkpoint

- Request / tasks: inspect tooling and board connection before upload; P01/P02 partial, P03 awaiting owner confirmation.
- Results: IDE extension 3.3.4 present; normal IDE Core 6.2.0 CLI runs by absolute path. USB serial `/dev/cu.usbmodem14101`, VID:PID `303A:1001`; esptool 4.5.1 ROM-only `chip_id` succeeded, detected ESP32-S3 revision v0.2 and 40 MHz crystal.
- Evidence and limitations: [M01 connection record](docs/roadmap/milestones/M01-bring-up.md#connection-checkpoint--2026-10-11). Initial sandbox scans missed the USB port; retry outside sandbox succeeded. No Flash write/erase, stub upload, firmware build or host-test rerun. Esptool reset the device; PCB revision, memory and physical behavior remain unverified.
- Changes: PROCESS.md, PLAN.md, CHANGELOG.md and M01 record only. Root `3dda411`, firmware `be5829d`; all four repositories initially clean on dev. No submodule changes, commit or push.
- Next: report connection checkpoint; await owner confirmation, then rebuild/upload and physical M01 validation. M01 remains Implemented.

## 2026-10-11 — Commit current work

- Request: owner authorized committing current changes; related task P08.
- Git: firmware commit `be5829d` (`feat: implement XUNA M01 T-Display-S3 hardware bring-up`); parent documentation and firmware pointer committed together in the commit containing this entry. No push requested or performed. Mobile/backend unchanged.
- Changes: refreshed PROCESS.md Git snapshot and marked P08 Done. Earlier uncommitted-state entries describe the state at their recorded time.
- Validation: whitespace checks passed; existing build/host-test evidence retained. No new firmware build or hardware validation performed for this Git handoff.
- Next: P01–P05; M01 remains Implemented, physical validation pending.

## 2026-10-11 — Separate context, plan and history

- Request: split the session handoff into separate plan and change-history files.
- Changes: created PLAN.md with stable P01–P08 task IDs/statuses and the Proposed M02 plan; created CHANGELOG.md; replaced the duplicated plan/history in PROCESS.md with links; updated agent entry instructions.
- Validation: documentation links checked locally; Git whitespace checks passed. Firmware build/tests were not rerun for this documentation-only change.
- Git: no commit/push; existing firmware changes preserved; mobile/backend unchanged.
- Next: P01, then board identification/upload/physical checks in P02–P05.

## 2026-10-11 — Establish the session handoff

- Changes: created PROCESS.md with product context, repository snapshot, M01 implementation/evidence, ordered next tasks and a prompt for the next AI; added handoff links in AGENTS.md and CLAUDE.md.
- Validation: inspected Git and existing source/records; whitespace checks passed. No new firmware compilation or physical verification performed.
- Git: changes remain uncommitted; no commit/push.
- Next: complete normal IDE tooling and validate M01 on the actual board.

## 2026-10-10 — Implement M01 hardware bring-up

- Changes: inspected initialized submodules and official LILYGO documentation; implemented modular firmware, LCD branding/original sprite, idle/happy animation, debounced buttons and diagnostics; added host tests, setup/validation documentation, ignore rules and CLAUDE.md.
- Fix: first build failed because Setup206 was not in the global include path for framework-library compilation; corrected platformio.ini and rebuilt successfully.
- Validation: firmware build PASS; host tests and ASan/UBSan PASS; configuration parsing and whitespace checks PASS. Linker static RAM 21,840 bytes; firmware 319,709 bytes. Detailed evidence: [M01 record](docs/roadmap/milestones/M01-bring-up.md).
- Limits: no board USB serial device detected in that session; no upload, physical LCD/button test, runtime measurement or PCB revision verification. M01 is Implemented, not Validated.
- Git: firmware and parent docs left uncommitted; no commit/push; mobile/backend unchanged.
- Next: build in normal IDE environment, then flash and physically validate.

## Entry template for future sessions

Add new entries above older entries. For multiple entries on the same date, include a descriptive title. Preserve earlier results; add a correction entry when evidence changes rather than silently rewriting history.

```markdown
## YYYY-MM-DD — Concrete change title

- Request / related task IDs:
- Changes: files and observable behavior changed.
- Decisions: status and reference; omit if none.
- Validation: exact commands/results or link to evidence; say what was not run.
- Limits / blockers:
- Git: commit hashes/pointer changes/push status, or uncommitted.
- Next: remaining task IDs and immediate action.
```

Do not store secrets or long raw logs here. Link to milestone records for detailed hardware/build evidence. Every meaningful implementation, fix, validation result or plan change should leave an entry.

## S02 documentation delivery — 2026-10-12

Owner requested incremental execution. Decision index and Proposed ADR-0001 now exist; S02 documentation done criteria are met. ADR acceptance remains pending, no decision silently approved. Preserved prior uncommitted documentation. Corrected T14 table to match separately gated voice research; no implementation/dependency/hardware changes or commit/push. Next: S00 environment and baseline verification on the current Mac.

## S00 baseline verification — 2026-10-12

- Existing Mac tools verified: PlatformIO IDE/Core 6.2.0, Apple Clang 14.0.0, FVM 3.2.1, Flutter 3.32.8/Dart 3.8.1. No installation/upgrade needed.
- Added mobile/.fvmrc under approved D14. pub get PASS and pubspec.lock unchanged.
- Host core/life tests PASS; firmware build PASS at 47,504 B RAM / 964,333 B image; Flutter analyze and 10 tests PASS.
- S01 prerequisites checked read-only: no ESP32 USB or real iPhone detected. No backup/flash/physical acceptance. Updated PROCESS/PLAN; no M04 source change, commit/push or gitlink update.

## S01 ESP32 preparation — 2026-10-12

- Owner deferred real-phone work. ESP32 connected, serial baseline inspected; chip revision v0.2 is not PCB revision.
- Read/decode actual partition table and compare with build: PASS. NVS backup 20,480 B with SHA-256 manifest stored outside repo; restore not tested.
- No firmware flash/erase/write, BLE command or code change. USB/serial and flash reads reset the board. S01 remains partial; phone acceptance gates retained.

## S03 — Firmware characterization baseline (2026-10-12)

- Owner chose Android for later app acceptance; firmware-first work continued with S03.
- Added firmware test/fixtures/v1_snapshots.h (fresh/scripted/saturated 96-byte snapshots) and test/test_v1_characterization.cpp; documented generation recipe and commands in firmware README.
- New suite covers both-context choice combinations, parser length/opcode/argument/source/error priority, cache results/conflicts/eviction, generation wrap/recovery and routine rollover. Fixtures are host-derived, not observed BLE bytes.
- C++11/-Werror PASS; all three host suites ASan/UBSan PASS; ESP32 build PASS, unchanged 47,504 B RAM / 964,333 B image. Production code/config unchanged.
- Added S03 evidence record, updated PROCESS/PLAN. Next S04; no upload, commit/push or gitlink update.

## S04 — Portable core + PlatformIO native tests (2026-10-12)

- Moved five pure headers into xuna_core; split board/timing config and updated adapter includes, preserving production behavior.
- Converted core/life/S03 assertions to three Unity suites; added C++11 native and ASan/UBSan environments, with no Arduino source compilation on host.
- Added pre-build hardware-include purity guard; updated README and handoffs.
- Native and sanitizer tests PASS (8/8 each); ESP32 build PASS at unchanged 47,504 B RAM / 964,333 B image. PlatformIO installed native 1.2.1/Unity 2.6.1; firmware dependencies remain pinned.
- No firmware upload, app work, commit/push or gitlink update. Next S05; S01 remains pending Android physical acceptance.

S04 negative guard check: PASS in native, native_asan and ESP32; temporary Arduino.h include removed. Clean build after restoration PASS.

## S05 — Fixed point, RNG and ClockModel (2026-10-12)

- Added xuna/base/Fixed.h, Random.h and xuna/time/ClockModel.h plus test_foundation suite; no firmware wiring or TimeSync opcode implementation.
- Tests-first compile failed for missing header; then native/ASan/UBSan regression PASS (12/12 each), ESP32 cross-compile smoke PASS and target build/purity PASS (47,504 B RAM / 964,333 B image unchanged).
- Official PCG vectors/source verified; Apache-2.0 notice/full license and source SHA documented. Fixed-point rounding/zero division and clock rollback/day-part/overflow contracts frozen for this slice; tuning thresholds remain Proposed.
- Added evidence record and updated handoffs. Next S07 as eligible host-only work; S06 board steps/S01 and Android acceptance remain deferred. No thermal measurement, board operation, commit/push or gitlink update.

## S07 — In-memory event foundation (2026-10-12)

- Added EventTypes/Event/EventQueue and RingBuffer plus six event tests; registry covers 25 planned kinds, compile-time unique codes, typed provenance/source and memory-only envelope.
- FIFO and drain budgets enforced; critical updates reject when full, best-effort drops counted; IDs stop on sequence exhaustion.
- Tests-first missing-header failure observed, then native/sanitizer 18/18 PASS; target compile smoke and ESP32 build/purity PASS, unchanged 47,504 B RAM / 964,333 B image.
- Recorded requested session-opening overview rule in AGENTS. Documented S05 time-epoch mismatch for focused S05-fix-01 before integration. No upload/app work, commit/push or gitlink update.

## S05-fix-01 — Compact time epoch correction (2026-10-12)

- Corrected ClockModel minute output, accepted-sync watermark and imported watermark reconstruction to minutes since 2020-01-01; Unix millisecond API retained.
- Added lower/reserved-zero/upper-minute/overflow and persisted watermark tests; updated existing test UTC inputs/expectations. Tests-first failure confirmed old mismatch.
- Native and ASan/UBSan 19/19 PASS; Xtensa compile smoke PASS; ESP32 build/purity PASS at unchanged RAM/image. Updated README, session evidence and handoffs; S07 finding resolved.
- No deployed state/protocol change, board operations, upload, app work, commit/push or gitlink update. Next S06 pure logic; S01 physical gate retained.

## S06 partial — Identity core (2026-10-12)

- Added pure CRC32, 64-byte identity codec and staged IdentityService, plus four identity test cases. Unknown/corrupt/too-new handling, migration, immutable identity, same-boot birth and failed-persistence staging tested.
- Tests-first missing-header failure observed; native/sanitizer 23/23 PASS, Xtensa compile smoke and ESP32 build/purity PASS; RAM/image unchanged.
- Recorded explicit codec layout, caller entropy/boot-counter/commit contracts and deferred GPIO/NVS steps. Full S06 remains In progress; next S14 pure ActivityFsm, Android/S01 deferred.
- No board operations, upload, app changes, commit/push or gitlink update.

## S11 — Isolated storage experiment preparation (2026-10-12)

- Prepared external benchmark from committed MVP display/config; includes NVS A/B, LittleFS appends/rename, rendering/timing, controlled storms/recovery and benchmark-only cleanup. No merge into firmware.
- Benchmark build PASS 159,840 B RAM / 365,053 B image; original MVP restoration project build PASS 47,504 B RAM / 964,333 B image. Sources/artifacts hashed outside repo.
- Added E4/E5 preparation record and Proposed ADR-0002, no measured results or D2 decision.
- Corrected earlier S11 readiness statement: global S01 upload gate still applies; current USB listing also has no board. Runtime waits for connection/backups and S01 or explicit isolated-benchmark exception.
- No board read/write/upload/format/cut/measurement, commit/push or gitlink update; prior edits retained.

## Static pet LCD scene — 2026-10-12

- Owner paused S11 and requested UI implementation/upload from xuna_and_bg.png. Added original source, nearest-neighbor RGB565 converter, generated Flash asset/preview/metadata.
- DisplayManager now draws full 320×170 scene once at boot; removed placeholder sprite/framebuffer and loop redraw. Existing life/input/BLE/storage logic and pinned board configuration retained.
- Deterministic generation and Flash placement PASS; build/native 23/23 PASS. RAM 46,072 B (−1,432), image 1,062,793 B (+98,460), asset 108,800 B in Flash.
- Fresh table/NVS backup, upload and NVS equality readback PASS. Actual startup draw 31,663 us; no spontaneous reset/error during 25-second log observation. Owner confirmed correct image/colors/stability on LCD.
- Source/build/physical evidence in UI-static-scene.md; S11 stays paused, S01 Android acceptance/full S06 pending. No commit/push/gitlink change.

## Animated room/pet and authorized commits — 2026-10-12

- Added reference/palette config and generator, separate room/background and authored pet frames, sprite sheet/LCD/GIF previews and RGB565 Flash exports; old static exports archived.
- Added pure presentation timing plus tests; display composites fixed region buffer, background restore and transparent masks. Idle/blink/wiggle and clear Happy/Idle expressions retain existing pet/button/BLE/state paths.
- Owner feedback led to closer reference silhouette, more visible foot motion, distinct Happy expression, overlapping torso/feet seam fix and explicit dark tips. Final owner reply provisionally accepts the result.
- Final build/upload PASS (46,144 B static RAM / 1,340,569 B image); native and ASan/UBSan 25/25 PASS; 385,280 B Flash pixels and 13,824 B runtime region buffer. Final short diagnostics no spontaneous reset/error; not long-run/thermal validation.
- Fresh backups retained outside Git. NVS newest snapshot only advanced active-lifetime/generation; learning/episode bytes unchanged. S11 stayed paused; prepared benchmark source archive saved in root docs for reproducibility.
- Owner requested all today's changes committed. Firmware c84d4e3, mobile 77d27ec; parent commit records docs/gitlinks. No push. Proposed ADRs remain Proposed; S01/full S06 pending.

## S01 Android acceptance — 2026-10-13 (in progress)

Android 15 phone and ESP32 connected; fresh NVS backup/hash and idle serial smoke PASS. Owner approved S01-fix-01 for missing Android BLE permissions; manifest updated. Flutter 3.32.8 analyze clean, 16/16 tests PASS. Native debug APK build PASS; install blocked by phone (INSTALL_FAILED_USER_RESTRICTED), awaiting owner USB-install setting/prompt. Physical BLE/learning/persistence acceptance pending. Evidence and external backup paths: PROCESS latest S01 entry. Permission/docs edits uncommitted; no firmware upload/erase, commit/push; S11 stays paused. Actual existing mobile HEAD is cebaf1c (earlier uncommitted handoff superseded).

## S01 Android BLE smoke — 2026-10-13

APK install/launch, runtime Nearby devices permission, physical scan/connect/GATT reads PASS. Four animation requests reflected in status; owner confirms LCD/buttons. Quiet Idle → reject → learned Happy; feedback 1, memory 1/8 with button provenance. USB-UART reboot/reconnect retained preference/memory and expired pending suggestion. Detailed evidence: PROCESS latest S01 entry and MVP-local.md. Physical power cuts, forget/text/error matrix and raw-byte transcript remain pending; S01 In progress. No firmware change/upload, commit/push; S11 paused.

S01 continuation: one owner-operated power cut retained learned preference/memory. Active-time rollback recorded and attributed to existing five-minute checkpoint contract. Forget plus USB-UART reboot/reconnect PASS (memory/feedback 0, preferences Idle, lifetime preserved). Text confirmation, raw bytes/error matrix and full cut matrix pending; S01 remains In progress. Evidence: PROCESS / MVP-local latest entries.

S01 text follow-up: owner confirmed like; device reads feedback/memory 1 with text-confirmed provenance. Pre-confirmation counter not observed, still pending. Requested nRF Connect installation for required raw-byte transcript; S01 remains In progress. One test-created text episode remains on device. No firmware change, commit/push.

## S01 observed read baseline — 2026-10-13

nRF Connect installed and connected. Five physical characteristic reads captured as raw hex: capabilities 8 B, status 16 B, life and both memory pages 20 B each. Life feedback 1/memory 1/pending 0; confirmed-text episode observed. Evidence: [S01 observed transcript](docs/roadmap/sessions/S01-v1-observed-transcript.md) (root-relative path); raw XMLs outside Git. No writes/upload in this read step. Scripted writes/error matrix and power-cut matrix remain pending; S01 In progress, S11 paused. Docs uncommitted; no commit/push.

S01 raw command follow-up: Notify enabled; observed 7-byte Suggest Quiet attempt returned invalid_length (2), request 1; no pending suggestion or memory/feedback changes. Recorded actual transmitted bytes/status/life in S01-v1-observed-transcript.md. Valid 8-byte command with fresh request 2 pending. No firmware/code changes, commit/push.

S01 raw Suggest Quiet request 2: actual 8-byte write accepted (OK), choice Idle, pending ID 2/canFeedback 1. Feedback/memory remain 1; both memory pages unchanged. Raw hex and capture copies recorded in S01-v1-observed-transcript.md. Approval request 3 targeting 2 remains next; no firmware upload, code change, commit/push.

## S01 automated inspector cases — 2026-10-13

Owner requested direct operation. ADB drove nRF Connect Byte Array writes after verifying entered hex. Approval request 3/target 2 PASS: feedback/memory 1→2, episode source 1. Exact duplicate request 3 PASS: OK, counters remain 2. Reused ID 3 with rejection payload PASS: conflict 6, no learning. New feedback request 4 without active pending PASS: invalid_argument 4, no learning. Raw status/life/both memory pages for each case in S01-v1-observed-transcript.md and external case JSON/XML captures. Pending suggestion 5 created (OK/canFeedback 1); awaiting owner GPIO0 press before feedback invalidation test. No firmware upload, source change, commit/push; S01 In progress, S11 paused.

## S01 raw inspector script complete — 2026-10-13

Pending request 5 accepted. Owner pressed GPIO0; feedback request 6 targeting 5 rejected (invalid_argument 4), pending cleared and counters unchanged at 2. Forget request 7 OK; memory/feedback 0, both preferences Idle, active lifetime 5991 retained. Full required inspector script now captured as actual writes + status/life/both memory pages in S01-v1-observed-transcript.md. These satisfy the observed transcript portion, not full S01. Remaining: ten-cut matrix, feedback/connected diagnostics, pre-confirmation text observation, off/deny/timeout and standalone/routine checks. Device now cleared of test episodes. No firmware upload/source change, commit/push; S11 paused.

Owner deferred remaining S01 physical matrix to a later session. Stop current device actions; next resume: fresh device/backup verification, controlled five-idle/five-post-feedback cut checks, BLE/feedback diagnostics and text pre-confirmation evidence. Required raw inspector sequence complete; S01 remains In progress, not Validated. Device has feedback 0/memory 0, preferences Idle after Forget; nRF connection may remain open. No commit/push requested.

## S01 commit checkpoint — 2026-10-13

Owner requested committing current changes. Mobile f756225 commits Android Bluetooth permissions; the parent commit containing this entry records its gitlink plus S01 validation/handoff and observed transcript. Firmware c84d4e3 and backend unchanged. Prior uncommitted descriptions are historical; no push. S01 remains In progress with remaining physical checks deferred by owner; S11 stays paused. Existing Flutter analyze/16 tests, native APK build/install and physical smoke/inspector evidence retained; commit checks: whitespace PASS. No new device operations or tests during commit-only delivery.

## S17 — FSM and visual boundary wiring (2026-10-14)

- Wired BLE opcode 1/2 plus local button/quiet actions through the shared RequestValidator and ActivityFsm; denied actions no longer call AnimationManager directly.
- Added Needs energy context, cooldown tracking, Sleep wake routing and safe Sleep/ErrorSafe/unknown VisualIntent mapping into the existing four PetState renderer states.
- Added visual bridge regression coverage. Native/sanitizer/ESP32 validation is pending because this Windows session has no PlatformIO/C++ toolchain; no board/mobile/backend operation or commit/push.

## Learning Engine L1 scaffold — 2026-10-14

- Added an independent bounded contextual learner with posterior-based preference, uncertainty-aware exploration, decision/propensity records, source-tagged idempotent feedback, bounded evidence/history, metrics and deterministic replay fingerprint.
- Added host-test preparation for exploration, context isolation, feedback deduplication, policy adaptation and bounded replay.
- Kept production learner v1 and its BLE/snapshot contract unchanged. Persistence v2, migration and shadow integration are the next gate; no neural network, cloud dependency or board/mobile change was introduced.
- Toolchain limitation: no PlatformIO/C++ compiler available, so native/sanitizer/ESP32 tests and learning-quality claims remain pending. No commit/push.

## Learning Engine L1.5 evaluation primitive — 2026-10-14

- Added fixed-point prequential evaluator for Brier loss, accuracy and improvement over a uniform baseline.
- Added learner tests for score-before-feedback behavior and invalid decision rejection.
- Kept this as an isolated measurement primitive; no persistence, BLE contract or production learner switch was introduced. Native/ESP32 validation remains pending.

## Learning Engine L1.6 shadow harness — 2026-10-14

- Added a pure v1/v2 shadow comparison harness for future Life Lab use.
- Candidate decisions and baseline decisions are recorded together; accepted feedback updates both once, while duplicate/invalid candidate feedback does not update v1.
- Added deterministic replay and synchronization tests. No production wiring, storage format or BLE change.

## Learning Engine L1.7 trace runner — 2026-10-14

- Added a bounded Choose/Feedback trace runner for shadow replay and prequential metrics.
- Added unknown-feedback, duplicate-feedback and deterministic fingerprint coverage.
- Kept it host/test-only; full Life Lab DSL and production integration remain pending.

## Learning Engine L1.8 explanations — 2026-10-14

- Added bounded numeric explanations for learner choices: posterior cells, counts, margin, policy version and exploration/winner reason.
- Added tests for exploration, posterior winner and invalid decisions.
- No mobile UI, BLE payload or production wiring was changed.
## Commit checkpoint — 2026-10-14

- Firmware submodule committed at a518ede: `feat(firmware): add bounded digital life and learning layers`.
- Parent documentation commit is complete; no push. Validation limits and next toolchain/Life Lab steps are recorded in PROCESS.md and PLAN.md.
## Learning Engine L1.9 trace DSL/runner preparation — 2026-10-14

- Added bounded learning trace DSL parsing and typed errors for deterministic Choose/Feedback traces plus reserved future S19a verbs.
- Added a host-only `sim/lifelab.cpp` metrics runner and README; it emits prequential/shadow CSV output without persistence or board access.
- Added parser and parser-to-runner tests. Full S19a LifeCore simulation remains gated by S18 and the native toolchain.

## Learning Engine L1.9 commit checkpoint — 2026-10-14

- Firmware child committed at `f784626`: `feat(firmware): add learning trace DSL and host runner`.
- Parent handoff records the gitlink and remaining S18/S19a gates. No push.

## M04 LifeCore composition and snapshot lab — 2026-10-14

- Added pure C++11 `LifeCore`/`LifeCoreSession` composition, bounded trace replay and the `lifecore_lab` host CSV runner.
- Added an in-memory A/B snapshot lab covering committed restore, simulated power cut and corrupt-latest fallback; V2 learner state remains shadow-only and resets on reboot.
- Reset ActivityFsm/cooldown state on `LifeCore::begin()` and added a reboot regression test.
- Static whitespace/include checks pass. Native, sanitizer, ESP32 and board/mobile validation remain unavailable because this session has no C++/PlatformIO toolchain. No commit or push.
## M04 trace persistence experiment — 2026-10-14

- Fact: `LifeCoreTraceRunner` now drives `LifeCoreSnapshotLab`; `reboot` recovers the newest valid slot, `powercut` fails the next requested commit, and feedback persistence requests are auto-committed in the host experiment.
- Fact: CSV output and Unity coverage now include persist failures, reboot count, final event count and generation. `sync/day/expect` remain explicit unsupported verbs.
- Validation limit unchanged: whitespace and include-resolution checks pass; no C++/PlatformIO toolchain, simulator execution or board/mobile operation was available. No production persistence decision was made.
## 2026-10-14 — S18 readiness source audit

- Owner requested the first suggested step: compare current LifeCore with S18 criteria and S10/S13/S17 dependencies. Added [readiness review](docs/roadmap/sessions/S18-readiness-review.md).
- Confirmed partial host preparation, missing production composition/persistence contracts and unmet prerequisite acceptance; documented pending-feedback and durable-commit parity gaps.
- Documentation only; no source edits, runtime tests, board/app operation, commit or push. Earlier review validation is retained with its original scope.

## S17 board upload smoke — 2026-10-14

- Owner explicitly authorized backup and upload after connecting ESP32. Detected ESP32-S3 rev v0.2, MAC 98:C3:77:A6:6F:D8 at /dev/cu.usbmodem14101; chip revision does not establish PCB revision.
- Device and target partition tables match: NVS 0x9000/0x5000. Backup outside Git: /Users/xthao28/xuna_backups/2026-10-14-s17/ (table, NVS, manifest, pre/post-upload Serial). NVS size 20,480 B, SHA-256 d7d12a9bebe95738bad48bdee08ce90f7de284bbd928ca24611286c5988ec52d; partition table SHA-256 bd0f7954aca2ef7d925ee21aaa1f3dc8822d1d6ce5cbbd26a135e5886bfff6ce. Restore not tested.
- Target aa2dbca build PASS (RAM 46,208 B, Flash 1,343,357 B, purity PASS); upload PASS with hash verification. Upload ranges exclude NVS; no erase-all or restore requested.
- Serial boot smoke PASS: version 0.2.0-mvp (does not expose commit), Flash 16 MB, PSRAM chip 8 MB, display initialized; no storage/BLE init error in captured log. Opening USB Serial caused USB_UART_CHIP_RESET. Initial idle draw max 4,754 us and loop gap max 4,767 us; no mean timing logged, so S17 +20% render acceptance is not established.
- Pending: owner LCD/buttons observation, sleep/wake and result 5 through BLE, rest/recovery, pet-state preservation through decoded reads, render baseline comparison. Full S17/S01 remain In progress. No source change, mobile operation, commit or push.

- S17 owner visual confirmation (2026-10-14): owner confirmed normal XUNA/Idle LCD, GPIO0 Happy and return to Idle, followed by GPIO14 Idle on firmware aa2dbca. Combined with captured button Serial logs, LCD/button smoke PASS. Full S17 remains In progress: BLE sleep/wake/result 5, rest/recovery and render timing acceptance still pending.

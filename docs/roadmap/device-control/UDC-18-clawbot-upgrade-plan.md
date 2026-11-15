# UDC-18 — Kế hoạch nâng cấp lớn: Đưa XUNA lên tầm tự động hóa ngang Clawbot

> **Trạng thái:** Wave A, Wave B, Wave C & Wave D đã triển khai & kiểm định tự động (**2026-11-15**, xem [UDC-18-wave-b-results-2026-11-15.md](UDC-18-wave-b-results-2026-11-15.md), [UDC-18-wave-c-results-2026-11-15.md](UDC-18-wave-c-results-2026-11-15.md) & [UDC-18-wave-d-results-2026-11-15.md](UDC-18-wave-d-results-2026-11-15.md)); Wave E sẵn sàng triển khai tiếp.
>
> **Mục tiêu:** Biến XUNA từ mô hình điều khiển từng bước nhiều rào cản thành một **Autonomous Desktop Agent thực thụ** (mở & thao tác mượt trên mọi app, ít hỏi lại, tự lập kế hoạch, tự nhìn màn hình/DOM/API, chạy dài hơi ngay cả khi khóa màn hình iPhone), nhưng vẫn giữ nguyên ranh giới an toàn cốt lõi của XUNA (**device/owner authority, zero secret leakage, hard-deny vùng tài chính/mật khẩu/xóa hủy**).

---

## 1. Chẩn đoán thực tế từ phiên chạy trên iPhone + Mac (`2026-11-14`)

Dữ liệu quan sát trực tiếp từ `action_approvals`, `cu_sessions`, desktop `audit-2026-11-14.jsonl` và mã nguồn cho thấy **4 nút thắt gốc**:

1. **Duyệt quyền quá vụn ngay cả trong một phiên đã ký R3 (đã giải quyết ở Wave A):**
   - Trước Wave A, `exempt_by_cu_session` chỉ miễn duyệt cho `ToolFamily.SCREEN | UI | INPUT` ở mức `R2`; mọi `input.type_text` có xuống dòng (`\n`), phím tắt `Cmd+N`/`Cmd+V`, và `app.launch` đều bật lại hỏi duyệt trên iPhone.
   - Đồng thời `ActionPendingEvent` từng gửi `"risk": "R3"` viết hoa khiến bản mobile cũ rơi nhầm về `R2` (đã sửa qua `ActionPendingEvent.wire_payload()` gửi chữ thường `r1`..`r3` + mobile parse không phân biệt hoa/thường).
2. **Mù giao diện ngoài AX Tree & thiếu động cơ Web/Native chuyên biệt (mục tiêu Wave B & C):**
   - Desktop hiện dựa chính vào AX Tree (`ui.inspect`, giới hạn `MAX_TOOL_OUTPUT_BYTES = 6144`), chưa có **Vision + Screenshot coordinate loop**, chưa có **Playwright/CDP Browser engine** cho web app, và chưa có **macOS Native App Bridges** (AppleScript/JXA/EventKit cho Notes, Calendar, Mail, Reminders, Finder).
3. **Runtime bị trói vào 1 lượt chat ngắn và phụ thuộc giữ màn hình iPhone (mục tiêu Wave D):**
   - `MAX_TOOL_ROUNDS = 12` và `HEARTBEAT_TIMEOUT_S = 15.0` ép dừng phiên CU nếu điện thoại tắt màn hình/mất nhịp tim 15 giây.
4. **Hạ tầng LLM & Tool Routing cho tác vụ dài (nền tảng đã giải quyết ở Wave A, mở rộng ở Wave D):**
   - Lỗi mất `thought_signature` khi chuyển sang `code_generator` và vòng lặp `tool_describe` dư thừa đã được giải quyết ở Wave A.

---

## 2. Kiến trúc đích: "XUNA Claw Engine"

Nguyên tắc thực thi để **mạnh như Clawbot mà không mất an toàn**:
- **Đảo thứ tự ưu tiên thực thi (`Native/API -> Browser DOM -> Forge Script -> Hybrid Vision/AX GUI`):** Gặp Notes/Calendar/Mail dùng Native JXA/API (1 bước, không trượt focus); gặp Web app dùng Browser CDP; chỉ dùng GUI Vision/AX khi app không có API/DOM.
- **Duyệt quyền theo "Mission Envelope" (1 lần đầu phiên) thay vì duyệt từng phím bấm:** Khi chủ nhân đã ký `R3` mở nhiệm vụ với phạm vi `{apps, domains, maxSteps, maxMinutes}`, mọi thao tác **mở app trong phạm vi + tạo/sửa nháp nội bộ** chạy tự động; **chỉ chặn hỏi R3 lại** khi chạm ngưỡng **không thể đảo ngược / bên thứ 3** (gửi ra ngoài, xóa vĩnh viễn, thanh toán, quản lý mật khẩu/quyền hệ thống, rời khỏi app đã cấp).

---

## 3. Lộ trình 5 Wave & Trạng thái

### Wave A — "Dứt điểm ức chế hiện tại" (**ĐÃ HOÀN THÀNH — 2026-11-15**)

1. **R1 — LLM Tool Routing & `thought_signature` (`backend/`):**
   - Bảo toàn `thought_signature` (`ToolCall.extra` + `_GLOBAL_SIGNATURE_CACHE`) xuyên suốt `chat_turn.py` và `openai_compatible.py` (kể cả khi chuyển sang `code_generator` hoặc stream chia chunk).
   - `tool_discovery.py` trả trực tiếp compact `args` schema ngay trong `tool_search`, bỏ vòng `tool_describe` dư thừa.
   - Fast-fail khi chạm quota ngày `429`/`400`; che kín khóa Gemini (`AIzaSy...`), OpenAI (`sk-proj-...`), Bearer token, Groq (`gsk_...`) thành `[REDACTED_API_KEY]`.
2. **R2 — `CU Session Trust Envelope` & Lưu trữ PostgreSQL (`backend/`, `desktop/`):**
   - Miễn hỏi lại trong phiên CU đã ký `R3` đối với `app.launch` (khi app nằm trong `active_cu.apps`), gõ văn bản nhiều dòng (`\n`), `Enter`/`Shift+Enter` tạo dòng, và phím tắt soạn thảo an toàn (`Cmd+N`, `Cmd+A`, `Cmd+C`, `Cmd+V`, điều hướng).
   - Giữ nguyên chặn R3 cho hành động phá hủy/gửi ra ngoài hoặc mở app ngoài phạm vi phiên.
   - Migration Alembic `0020_approval_scopes.py`, `ApprovalScopeModel` và `SqlApprovalScopeStore` lưu bền vững phạm vi cấp quyền xuống PostgreSQL.
3. **R3 — Zero-Config App Discovery & `Standard` Trust Preset (`desktop/`):**
   - Tích hợp `AutoAppScanner` làm nguồn app mặc định với preset `Standard`; khóa chặt điều kiện `&&` cho `TrustPreset.strict` trong `policy.dart`.
4. **R4 — Ranh giới bảo mật & Tương thích dây truyền tải (`backend/`, `desktop/`, `mobile/`):**
   - Chặn đóng (fail-closed) 15 trình Terminal GUI (`Terminal`, `iTerm`, `iTerm2`, `Warp`, `Alacritty`, `Kitty`, `WezTerm`, `wezterm-gui`, `Ghostty`, `Hyper`, `cmd`, `powershell`, `wt`, `bash`, `zsh`) và input rỗng/khoảng trắng.
   - Giữ wire format `action_pending.risk` chữ thường (`r1`..`r3`) tương thích ngược với bản iPhone hiện hành; parser mobile nhận cả hoa/thường.

---

### Wave B — "Đôi tay bản địa macOS/OS & Trình duyệt thực thụ" (**ĐÃ HOÀN THÀNH — 2026-11-15**)
> Mục tiêu: Thoát khỏi giới hạn app & sự chậm chạp của click chuột từng bước. Kết quả kiểm định: [UDC-18-wave-b-results-2026-11-15.md](UDC-18-wave-b-results-2026-11-15.md).

1. **OS Native App Bridge (`native.*` — JXA / AppleScript / Shortcuts trên macOS; PowerShell/COM có kiểm soát trên Windows):**
   - Đã hiện thực bộ 9 tool có cấu trúc trên `desktop/packages/xuna_xtp`, `desktop/` và tích hợp điều phối tổng quát (tuân thủ H5) ở `backend/`: `notes.create`, `notes.append` (`missing_target` khi thiếu đích theo H3), `notes.search`, `reminders.create`, `calendar.list_events`, `calendar.create_event`, `finder.reveal`, `shortcuts.run`, `mail.create_draft` (chỉ tạo nháp R2, không tự gửi R3 nếu chưa ký).
   - Chống command/script injection qua mảng `argv`, phân cách `--`, lọc null-byte/CRLF/CLI flags; fail-closed (`platform_unsupported`) theo H1.
2. **Playwright / Chrome CDP Browser Engine (`web.*`):**
   - Đã hiện thực bộ 7 primitive trình duyệt tổng quát: `web.navigate`, `web.snapshot` (DOM + ARIA ref gọn trong giới hạn `MAX_TOOL_OUTPUT_BYTES = 6144`, che mật khẩu/token), `web.click`, `web.fill`, `web.select`, `web.extract`, `web.wait_for`.
   - Áp dụng đồng bộ bộ lọc SSRF đa tầng (chặn IP private/loopback/metadata/hex/Unicode smuggling/percent-encoded netloc) và tự động nâng quyền `R3` trước hành động thanh toán/xóa/submit/điền dữ liệu nhạy cảm.

---

### Wave C — "Đôi mắt Vision + Điều khiển mọi app không cần AX chuẩn" (**ĐÃ HOÀN THÀNH — 2026-11-15**)
> Mục tiêu: App nào hiện lên màn hình được là XUNA dùng được (kể cả Electron, Figma, App chat, UI tùy biến). Kết quả kiểm định: [UDC-18-wave-c-results-2026-11-15.md](UDC-18-wave-c-results-2026-11-15.md).

1. **Hybrid Observe Engine (`ui.observe_hybrid` = AX Tree + Compressed Screenshot + Bounding Box):**
   - Desktop chụp vùng cửa sổ đích (nén JPEG ~1280px, không lưu đĩa/DB — giữ cam kết zero retention của U5), gắn nhãn phần tử từ AX Tree nếu có và gửi multimodal tới Vision LLM.
   - Hỗ trợ fallback click/drag theo tọa độ chuẩn hóa `(x_norm, y_norm)` tự quy đổi HiDPI Retina (`devicePixelRatio`).
2. **UI Settle & Self-Healing Verification:**
   - Tự chờ UI ổn định ngắn (`<= 1.5s`) bằng diff nhẹ trên host trước khi trả kết quả để không tốn thêm vòng gọi LLM vô ích.
3. **Reverse Hit-Test & Anti-Circumvention (ADR-0015):**
   - Tự động đối soát tọa độ click/drag với cây AX đã cache: chặn ngay `password_field_forbidden` nếu chạm ô mật khẩu, nâng quyền `R3` yêu cầu chữ ký điện thoại nếu chạm nút thanh toán/xóa/hủy hoặc khi phiên có văn bản nháp chưa commit.
   - Kiểm tra ranh giới tọa độ fail-closed (`[0.0, 1.0]`), bảo toàn payload tool JSON `<= 6144 B`, và đảm bảo 0 hardcoded app name (Rule H5).

---

### Wave D — "Runtime tự hành dài hơi & Bộ não đa bước như Clawbot" (**ĐÃ HOÀN THÀNH — 2026-11-15**)
> Mục tiêu: Chạy được chuỗi 20–50 bước phức tạp, không đứt gánh khi người dùng khóa màn hình điện thoại. Kết quả kiểm định: [UDC-18-wave-d-results-2026-11-15.md](UDC-18-wave-d-results-2026-11-15.md).

1. **Async Autonomous Task Runner (`AutonomousJob` Queue trên PostgreSQL `0021_autonomous_jobs.py`):**
   - Đã tách vòng lặp thực thi dài ra khỏi HTTP SSE request đơn lẻ: lưu trạng thái `AutonomousJob` bền vững (`queued -> running -> awaiting_r3_checkpoint -> completed/failed`), hỗ trợ ngân sách 40–50 bước mỗi job.
   - Khi điện thoại tắt màn hình: Job tiếp tục chạy các bước nằm trong `CU Session Trust Envelope` đã ký nhờ cơ chế chạm nhịp tim định kỳ (`touch_heartbeat`), không bị chết sau 15s mất kết nối UI.
   - Tạm dừng an toàn (`awaiting_r3_checkpoint`) khi gặp hành động R3 cần chữ ký P-256 mới hoặc hết ngân sách phiên; tự động tiếp tục khi chủ nhân phê duyệt.
   - Cung cấp đầy đủ REST API quản lý job (`/v1/actions/jobs`, `pause`, `resume`, `steer`, `cancel`).
2. **Planner-Executor + Sub-goal Compaction:**
   - Sinh Execution Plan có cấu trúc ngắn (3–7 chặng), thực thi Quy tắc H1 (chỉ đánh dấu xong khi công cụ trả về `status == "ok"` thật).
   - Nén lịch sử các chặng đã xong thành bản tóm tắt gọn (>90% token saving), bảo toàn tuyệt đối `thought_signature` Wave A và triệt tiêu 100% ảnh base64 Vision (Consent U5 Zero-Retention).
3. **Nâng cấp `Forge` Skill Library + `MCP` Client Hub:**
   - `auto_mcp_bridge.dart`: JSON-RPC 2.0 stdio/HTTP chuẩn mực, bộ lọc Anti-SSRF 3 tầng (27 vector), fail-closed không canned text, giới hạn output `<= 6144` bytes.
   - `ForgeRunSkillTool`: thực thi chuỗi bước tham số hóa thật qua `HostToolDispatcher`, loại bỏ hoàn toàn synthetic approvals (kiểm tra chữ ký P-256 tươi cho bước R3), chặn 15 Terminal GUI (`policy_blocked`), lan truyền lỗi chuẩn xác theo Quy tắc H4.

---

### Wave E — "Nâng cấp Mobile Approval & Mission UX"
> Triển khai và build khi làm việc trên máy có môi trường build mobile tương ứng (`macOS 14+` / `Xcode` mới cho iOS `Flutter 3.47.9`, hoặc Android).

1. **Mission Card thay cho chuỗi Popup rời rạc:** Hiển thị kế hoạch tổng thể + phạm vi app/domain, ký P-256 1 lần.
2. **Live Job Progress + Pause / Steer / Takeover:** Theo dõi chặng đang chạy từ `AutonomousJob`, tạm dừng hoặc đổi hướng ngay giữa chừng.
3. **Quản lý Trust Preset (`Strict` / `Standard` / `Autopilot`) & App Policy trực tiếp trên điện thoại.**

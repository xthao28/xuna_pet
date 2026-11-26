# Nghiên cứu: tích hợp HKUDS/CLI-Anything vào XUNA

Ngày: **2026-11-26** (Asia/Ho_Chi_Minh). Trạng thái: **Research — chưa có quyết định, chưa viết code.**
Nguồn: <https://github.com/HKUDS/CLI-Anything> (đọc `SECURITY.md`, `cli-anything-plugin/HARNESS.md`, `repl_skin.py`, `guides/mcp-backend.md`, `cli-hub/cli_hub/{installer,registry,cli}.py`, `cli-hub-meta-skill/SKILL.md`, `public_registry.json`, một phần `registry.json`, harness LibreOffice đầy đủ, tài liệu SOP của Obsidian/Zotero/Ollama/draw.io/Mermaid/OBS) và mã XUNA hiện tại (`desktop/`, `backend/`).

> **Quy ước độ tin cậy (H8):** ✅ = đã đọc nguyên văn mã/tài liệu; ⚠️ = chỉ có ở phần trang bị cắt/tóm tắt hoặc tự mâu thuẫn — **chưa kiểm chứng**.

---

## 1. Tóm tắt một trang

- **CLI-Anything là gì:** một "nhà máy" dùng LLM (plugin Claude Code `/cli-anything <repo>`) để đọc mã nguồn một ứng dụng GUI mã nguồn mở rồi sinh ra **một CLI Python (Click) riêng cho ứng dụng đó**: `cli-anything-<app>`, có `--json`, REPL, file trạng thái phiên, undo/redo và một `SKILL.md` mô tả lệnh. CLI **gọi phần mềm thật** ở chế độ headless (`soffice --headless --convert-to`, `blender --background`, `gimp -i -b`, `inkscape --actions`, `melt`, REST API cục bộ…), không viết lại phần mềm. ✅
- **Giá trị cho XUNA:** đúng vào **Tier 0 "Headless / 1 bước"** của thang thực thi 4 tầng (`backend/.../prompts.py:107-112`): thay vì điều khiển GUI bằng `cu.*`/`ui.*` (chậm, dễ vỡ), XUNA có thể gọi một lệnh xác định và nhận JSON. Ví dụ đáng giá nhất: "xuất file Word/Excel này sang PDF", "tạo sơ đồ draw.io", "tra thư viện Zotero".
- **Nhưng:** dự án **không có mô hình bảo mật thực thi** (CLI chạy với toàn quyền người dùng), cài đặt kéo thẳng từ nhánh `main` trên GitHub (không ghim phiên bản), chất lượng harness không đồng đều, và **hỗ trợ Windows chưa được kiểm chứng**. CLI-Hub (chợ cài đặt) trùng đúng loại rủi ro mà chủ dự án đã bác bỏ ở nghiên cứu OpenClaw (ClawHub).
- **Khuyến nghị:** **không** nhận CLI-Hub hay plugin; **làm spike 1 harness (LibreOffice)** ghim theo commit, chạy qua `exec.run` hiện có trên máy Windows này để đo độ trung thực JSON và hành vi Windows; sau đó mới chọn giữa **cầu nối MCP nhỏ (C)** hoặc **loại harness `cli_json` có ADR (D)** — xem §6.

---

## 2. CLI-Anything hoạt động thế nào (sự thật kỹ thuật)

### 2.1 Quy trình sinh harness ✅ (`HARNESS.md`)
Phase 1 phân tích mã → 2 thiết kế CLI → 3 hiện thực → 4 lập kế hoạch test (`TEST.md` phần 1, viết trước code test) → 5 viết test → 6 ghi kết quả test → 6.5 sinh `SKILL.md` (`skill_generator.py`, `templates/SKILL.md.template`) → 7 đóng gói PyPI (namespace package `cli_anything/`). Quy tắc số 1: *"Use the Real Software — Don't Reimplement It"*; *"Do NOT gracefully degrade to a fallback library. If the software is not installed, error with clear install instructions."*

### 2.2 Cấu trúc một CLI sinh ra ✅ (đã đọc harness LibreOffice)
- `cli_anything/<app>/<app>_cli.py` (Click group, `invoke_without_command=True` → chạy trần là vào REPL; gọi subcommand là chế độ không tương tác), `core/` (project, export, session có undo/redo, khóa file khi lưu), `utils/<app>_backend.py`, `utils/repl_skin.py`.
- **`--json`:** in thẳng dict dữ liệu, **không có phong bì** `ok/error/data`. Lỗi ở chế độ JSON: `{"error": "<msg>", "type": "file_not_found" | "<ExcType>" | "file_exists"}` in ra **stdout** và `exit 1`; lỗi Click dùng mã 2 mặc định; ngoại lệ khác không bắt.
- **Tìm phần mềm (LibreOffice):** `shutil.which("libreoffice")` → `which("soffice")` → trên Windows thử `%PROGRAMFILES%\LibreOffice\program\soffice.exe`, `%PROGRAMFILES(X86)%…`, rồi đường dẫn cứng; macOS `/Applications/LibreOffice.app/...`; không thấy → `RuntimeError` kèm gợi ý apt/brew/winget. Chuyển đổi: `soffice --headless --nologo --norestore … -env:UserInstallation=<profile tạm> --convert-to <fmt> --outdir <dir> <file>`, timeout 120 s.
- REPL không đòi TTY (chỉ dùng `isatty()` cho màu).

### 2.3 Cách tác tử dùng ✅/⚠️
- **Claude Code plugin** `cli-anything-plugin/` (`commands/cli-anything.md`, `refine.md`, `test.md`, `validate.md`) — đây là công cụ **sinh** harness lúc phát triển, **không liên quan runtime của XUNA** (bộ não XUNA là LLM ở backend). ✅
- Plugin README: *"Claude Code runs shell commands via `bash`"* → Windows cần Git for Windows/WSL. ✅
- Lệnh cài cho từng agent (OpenCode, Cursor, Codex, Copilot CLI…) ⚠️ chỉ thấy ở phần tóm tắt.
- **MCP:** CLI-Anything chỉ **tiêu thụ** MCP làm backend (`guides/mcp-backend.md`: `StdioServerParameters(command="npx", args=["@apireno/domshell"])`), **không** xuất harness thành MCP server. ✅ Gói Zotero bên thứ ba tự nhận "CLI & MCP server… 52 MCP tools" ⚠️.

### 2.4 CLI-Hub & registry ✅
- `pip install cli-anything-hub` → `cli-hub list|search [--json]` (in mảng JSON trần), `cli-hub install <name>`, `launch` (`os.execvp`), `matrix …` (có hợp đồng mã thoát 0/1/2/3).
- Registry lấy từ `https://hkuds.github.io/CLI-Anything/registry.json` (cache `~/.cli-hub/registry_cache.json`, TTL 3600 s). Harness cài bằng `pip install git+https://github.com/HKUDS/CLI-Anything.git#subdirectory=<app>/agent-harness` — **từ nhánh `main`, không ghim commit/phiên bản**.
- Lược đồ entry harness: `name, display_name, version, description, requires, homepage, source_url, install_cmd, entry_point, skill_md, category, contributors` — **không có trường nền tảng (platform)**; một số entry `public_registry.json` có `"platform": "windows"` dạng chuỗi; `qgis` dùng `contributor` số ít (lược đồ không nhất quán).
- Meta-skill `cli-hub-meta-skill/SKILL.md` khuyên `cli-hub matrix preflight <name> --json`, cài có phạm vi (`--capability/--recipe/--only`), `--dry-run`; trỏ thêm tới một catalog trên CDN bên thứ ba (chưa đọc).
- Thu thập dữ liệu: README nói gửi sự kiện ẩn danh tới PostHog **mặc định bật**, tắt bằng `CLI_HUB_NO_ANALYTICS=1` ⚠️ (chưa đọc `analytics.py`).

### 2.5 Harness có sẵn & mức độ chín
- Thư mục `<app>/agent-harness/` ở gốc repo: ~67 theo danh sách cây đã đọc (LibreOffice, GIMP, Blender, Inkscape, Krita, Kdenlive, Shotcut, Audacity, MuseScore, OBS, draw.io, Mermaid, Obsidian, Zotero, Joplin, Calibre, FreeCAD, Godot, QGIS, Ollama, ComfyUI, n8n, Dify, Zoom, iTerm2, Safari…). Con số tổng **mâu thuẫn**: ~40 / ~67 / ~79 ⚠️.
- Apache-2.0 ✅; ~65,8k sao, ~893 commit, 110 issue + 208 PR mở ✅; commit mới nhất nhìn thấy 2026-09-22 ⚠️ (trang có thể là cache cũ); số test tự quảng cáo mâu thuẫn (2.280+ / 2.461 / 2.464) ⚠️.
- SOP từng harness (chưa đọc mã):
  | Harness | Điều khiển gì | Ghi chú cho XUNA |
  | --- | --- | --- |
  | LibreOffice | Tạo/sửa ODF, xuất PDF/DOCX/XLSX qua `soffice --headless` | Ứng viên spike tốt nhất (có dò `soffice.exe`) |
  | Obsidian | Plugin Local REST API `localhost:27124`, Bearer token, `verify=False` | Cần cài plugin + token; HTTPS tự ký |
  | Zotero | Đọc `zotero.sqlite` (read-only), connector `:23119`, Local API | Ghi SQLite trực tiếp "thử nghiệm", cần đóng Zotero |
  | Ollama | REST `localhost:11434` | Ollama phải đang chạy |
  | draw.io | Sửa XML mxGraph, xuất qua draw.io CLI | **Tự lùi về lưu `.drawio` khi thiếu CLI** — vi phạm chính quy tắc no-fallback của dự án |
  | Mermaid | Render qua dịch vụ **`mermaid.ink` (mạng ngoài)** | **Gửi nội dung ra ngoài** — xung đột lập trường riêng tư của XUNA |
  | OBS | Sửa file JSON scene collection; "tests run without OBS installed" | Không điều khiển live qua obs-websocket |
  Hỗ trợ Windows của cả 6 harness: **chưa kiểm chứng ở mức mã** ⚠️.

---

## 3. Rủi ro & lỗ hổng đã kiểm chứng ✅

1. **Không có sandbox / mô hình phân quyền khi chạy.** `SECURITY.md` có mô tả mối đe dọa ("an AI agent may autonomously construct and execute commands") và quy tắc cho người viết harness (không `shell=True`, allowlist tham số, escape, `realpath`), nhưng tự ghi là *"NOT part of the CLI generation methodology"*. CLI chạy với toàn quyền người dùng.
2. **Mâu thuẫn ngay trong CLI-Hub:** `installer.py::_run_command` bật `shell=True` khi lệnh cài chứa `|`, `&&`, `||`, `;`, `$(`, backtick (docstring: *"Commands come from the trusted registry"*) — trái quy tắc số 1 của `SECURITY.md`; ví dụ entry `sketch`: `"cd sketch/agent-harness && npm install && npm link"`.
3. **Chuỗi cung ứng không ghim:** cài từ `main` qua `pip install git+…`; registry tải từ GitHub Pages mỗi giờ.
4. **Chất lượng tài liệu ≠ mã (đọc harness LibreOffice):** `SKILL.md` dùng nhóm lệnh `project …` nhưng mã chỉ có `document`; SKILL.md nói chạy *"without a GUI or LibreOffice installation"* trong khi mục cài đặt bắt buộc LibreOffice; SKILL.md bảo *"Parse stderr for error messages"* nhưng mã in lỗi JSON ra stdout. → LLM đọc SKILL.md để gọi lệnh sẽ gọi sai.
5. **Vi phạm nguyên tắc của chính họ:** draw.io lùi im lặng; Mermaid đẩy nội dung ra `mermaid.ink`.
6. **JSON không phong bì:** muốn tuân H1 ("thành công thật"), XUNA phải tự coi `exit != 0` là thất bại và tự kiểm chứng kết quả (file tồn tại, magic bytes như `%PDF-`) — không thể tin dict trả về.

---

## 4. Đối chiếu với XUNA hiện tại

| Điểm của XUNA | Hiện trạng (đã kiểm chứng) | Hệ quả với CLI-Anything |
| --- | --- | --- |
| Thang thực thi | Tier 0 headless ưu tiên cao nhất (`prompts.py:107-112`) gồm `mcp__*`… | Harness CLI là ứng viên Tier 0 tự nhiên |
| `exec.run` (ADR-0018) | R2 là **allowlist dương**; lệnh lạ → **R3 `unclassified_command`** (`exec_command_classifier.dart:181`, `:314`); chỉ chạy khi bật "Dòng lệnh & tệp" | Gọi `cli-anything-*` hôm nay **được**, nhưng **mỗi lần phải ký trên điện thoại** và chỉ dành cho power-user. **Không nên** nới allowlist R2 cho CLI bên thứ ba (phá thiết kế allowlist dương) |
| MCP | `AutoMcpBridge` tự dò `~/.claude.json`, Cursor, Antigravity, Claude Desktop + `protocolHarnesses` khai báo local (`mcp_stdio`/`acp_stdio`, `policy_models.dart:164-172`); LLM dùng qua `mcp.list_servers` / `mcp.call` (nhóm `app`, R2); đã live-verify trên Windows hôm nay với shim npm `.cmd` | Một MCP server nhỏ bọc harness sẽ dùng được **không cần đổi wire** |
| Nhập `SKILL.md` | `SkillWorkshopService.bridgeSkillMarkdown` chỉ đọc `name`/`description`, tổng hợp một kỹ năng chung chung và vẫn trả `securityVerified: true` | **Không phải cầu nối**: nhập SKILL.md của CLI-Anything sẽ báo thành công mà không nối được lệnh nào |
| H5 (không gắn tên app trong lớp chung) | `XUNA_HONEST_CODE_RULES.md:66-71`: năng lực do producer khai báo; đường riêng cho app chỉ nằm trong host adapter | Mọi tích hợp chung không được liệt kê tên app trong catalog/prompt; danh sách harness phải đến từ khai báo local của chủ máy hoặc từ chính harness |
| Ngân sách catalog | `MAX_CATALOG_TOOLS = 36` (`catalog.py:56`), MCP không tách thành tool riêng | Thêm họ tool mới (`cli.*`) phải chen slot hoặc nằm sau meta-tool |
| Tiền lệ của chủ dự án | Nghiên cứu OpenClaw (`XUNA_OPENCLAW_DEEP_RESEARCH_2026-11-03.md:56, 96-98`) bác bỏ chợ plugin vì rủi ro mã độc ClawHub, chọn "Verified Skill Packs" nội bộ | **CLI-Hub là cùng loại chợ** → không nhận |

**Phát hiện phụ (có từ trước, chưa sửa):** `bridgeSkillMarkdown` trả `securityVerified: true` dù không kiểm chứng gì (H1/H6), và khi `skillId` không khớp thì lấy `skills.first` (đoán mục tiêu — H3) (`skill_workshop_service.dart:83-92`).

---

## 5. Các hướng tích hợp

### A. Chỉ tham khảo phương pháp (0 phụ thuộc)
Học `HARNESS.md` cho host adapter của chính XUNA: "dùng phần mềm thật", 4 lớp test (unit → E2E định dạng → E2E backend thật → subprocess), kiểm chứng đầu ra bằng magic bytes, "fail loudly". Có thể dùng plugin `/cli-anything` **lúc phát triển** để phác adapter rồi viết lại theo chuẩn XUNA (Apache-2.0 cho phép, giữ NOTICE).
- Chi phí: thấp. Giá trị: chất lượng adapter tốt hơn, không thêm bề mặt tấn công.

### B. Chủ máy tự cài harness, XUNA gọi qua `exec.run` (làm được ngay hôm nay)
- Không cần code. Mỗi lệnh là R3 → ký trên điện thoại; LLM không biết harness tồn tại trừ khi tự chạy `--help`; phải bật "Dòng lệnh & tệp".
- Hợp làm **spike đo đạc**, không hợp làm trải nghiệm chính.

### C. MCP server nhỏ bọc các harness đã cài
- Một tiến trình MCP stdio cục bộ đọc danh sách harness do chủ máy khai báo, xuất mỗi subcommand thành một MCP tool (argv mảng, không shell, timeout, coi `exit != 0` là lỗi), đăng ký qua `protocolHarnesses` (`mcp_stdio`) hoặc cấu hình Claude Code.
- XUNA dùng ngay qua `mcp.list_servers` / `mcp.call` — **không đổi hợp đồng XTP**.
- Nhược điểm: rủi ro tính theo cả server (R2, nhóm `app`), không phân biệt "xuất PDF" (an toàn) với "ghi đè file" (nên R3); thêm một tiến trình Python phải bảo trì; cần quyết định nơi đặt mã (repo riêng/`tools/`).

### D. Loại harness `cli_json` hạng nhất (cần ADR mới)
- Thêm `protocol: "cli_json"` vào `protocolHarnesses` + họ tool chung `cli.list` / `cli.describe` / `cli.call`: argv-only qua runtime exec sẵn có (CreateProcessW/Job Object, lọc env, E-Stop), **ghim phiên bản**, rủi ro do chủ máy khai báo theo từng subcommand (đọc = R1/R2, ghi/ghi đè/mạng = R3), kiểm chứng file đầu ra trước khi báo `ok`.
- **Quy mô thật:** đây là bề mặt thực thi mới (chạm `desktop/AGENTS.md` §3.1, ADR-0018 mới chỉ mở `exec`), đổi **hợp đồng XTP + 2 thư mục fixture**, catalog backend + ngân sách 36 slot, nhóm quyền trên mobile, L10n, test bảo mật đối kháng. Ước lượng cỡ một Wave nhỏ, không phải chỉnh sửa vặt.

### E. Nhận CLI-Hub / plugin nguyên trạng — **không khuyến nghị**
Chợ cài từ `main`, `shell=True` trong installer, analytics mặc định ⚠️, trái tiền lệ OpenClaw.

---

## 6. Khuyến nghị & bước tiếp theo

1. **Spike (khuyến nghị làm trước, ~nửa ngày):** trên máy Windows này, cài LibreOffice + `cli-anything-libreoffice` **ghim theo commit** trong venv riêng; gọi qua `exec.run` (ký R3) từ app desktop thật như phiên live hôm nay. Đo: (a) lệnh nào chạy đúng trên Windows, (b) JSON thành công/lỗi có đúng như mã đọc được, (c) `exit code`, (d) file PDF thật (magic bytes), (e) tiến trình `soffice` có bị diệt sạch khi cancel/E-Stop, (f) env con không lộ bí mật. **Cần chủ dự án đồng ý cài LibreOffice và `pip install` từ GitHub** — máy hiện chưa có ứng dụng mục tiêu nào.
2. Sau spike: nếu chất lượng ổn và chỉ cần vài app → chọn **C**; nếu muốn biến thành năng lực lõi có phân quyền theo lệnh → viết **ADR cho D**.
3. Song song, bất kể chọn gì: áp dụng **A** cho các host adapter hiện có; ghi nhận và lên lịch sửa phát hiện phụ ở `bridgeSkillMarkdown`.

---

## 7. Bài học đem về XUNA (không cần tích hợp CLI-Anything)

Những ý hay của CLI-Anything có thể làm theo cách riêng của XUNA, đúng H1–H8:

| # | Ý tưởng học được | Hiện trạng XUNA (đã kiểm chứng) | Nâng cấp đề xuất | Giá trị / Công sức |
| --- | --- | --- | --- | --- |
| U1 | Session có **undo/redo** cho mọi thay đổi (`core/session.py`) | `ReversibleActionLedger` chỉ trong RAM, 5 mục/10 phút, cho media/âm lượng (`host_tool_dispatcher.dart:101-115`); `fs.write_file`/`patch_file` khai báo `reversible: false` | **Nhật ký hoàn tác cho tệp:** trước khi `fs.*` ghi, lưu bản cũ (giới hạn dung lượng/thời gian, chỉ trong workspace, không lưu file mật) → `action.undo` khôi phục được thao tác sửa tệp; khai báo `reversible: true` khi có bản lưu | Cao / Vừa |
| U2 | `--dry-run` ở mọi lệnh | `xuna/preflight` chỉ trả mức rủi ro + lý do | **Xem trước trước khi ký R3:** thẻ duyệt trên điện thoại hiện diff của `fs.patch_file`/`write_file`, danh sách tệp mà `del`/`rm` sẽ xóa (host tự mở rộng glob ở chế độ chỉ đọc) — chủ ký khi biết chính xác điều gì sẽ thay đổi | Cao / Vừa |
| U3 | Test "backend thật" kiểm chứng **đầu ra bằng magic bytes**, không tin lời CLI | `fs.write_file` đã trả `sha256`; `exec.run` chỉ có `exitCode` | **Hậu điều kiện khai báo trước:** `exec.run` nhận `expectFiles` tùy chọn; host chỉ báo `completed` khi file tồn tại, kích thước > 0, (tùy chọn) đúng magic/sha256 — chặn "báo xong nhưng chưa xong" (H1) | Cao / Thấp |
| U4 | `cli-hub matrix preflight --json`: kiểm tra phụ thuộc **trước** khi làm | Resource digest chỉ có `apps`, `workspaces` (`resource_digest_builder.dart:77-78`) | **Báo toolchain trong digest:** host tự khai báo `node`/`python`/`git`/`soffice`… có sẵn + phiên bản (producer khai báo, đúng H5) → LLM chọn đúng tầng ngay, bớt gọi thất bại; lỗi thiếu phụ thuộc trả `remediation` do host adapter khai báo, mobile hiện thẻ "sửa 1 chạm" | Vừa / Thấp |
| U5 | Sinh `SKILL.md` **từ mã + test**; bài học ngược: SKILL.md tay của họ lệch mã | `prompts.py` gắn cứng tiền tố tool (`media__*`, `mcp__*`…) | **Test chống lệch prompt↔catalog:** CI fail nếu prompt nhắc tên tool/tham số không còn trong catalog hoặc schema; mô tả tool sinh từ descriptor XTP thay vì viết tay | Vừa / Thấp |
| U6 | Quy trình 7 pha, **TEST.md viết trước**, test fail chứ không skip khi thiếu phần mềm | `bridgeSkillMarkdown` trả `securityVerified: true` không kiểm chứng; `skills.first` khi không khớp id | **Forge có kiểm chứng:** kỹ năng OmniForge/SKILL.md chỉ lên trạng thái "đã kiểm chứng" sau khi tự-test chạy pass trong sandbox; trạng thái `draft` hiển thị rõ; bỏ `skills.first` (trả lỗi + danh sách ứng viên, H3) | Vừa / Vừa |
| U7 | "Dùng phần mềm thật ở chế độ headless" | Thang 4 tầng có Tier 0 headless nhưng thao tác văn phòng vẫn phải đi qua giao diện | **Capability Adapter khai báo:** engine chung + adapter là manifest dữ liệu (năng lực, mẫu argv cố định có kiểu, `detect`, `verify`); chuyển đổi tài liệu chỉ là **adapter seed đầu tiên**, không phải tool viết tay (sửa theo góp ý chủ dự án — xem kế hoạch P4) | Cao / Cao |

Thứ tự gợi ý: **U3 → U2 → U1** (cùng chủ đề "an toàn & trung thực cho Wave 3 exec/fs", chồng lên nhau tự nhiên), rồi U4, U5; U6/U7 khi quay lại mảng kỹ năng/văn phòng.

---

## 8. Đề xuất "đẳng cấp" — dựa trên lợi thế chỉ XUNA có

U1–U7 là cải tiến dần. Bốn đề xuất dưới đây tạo khác biệt thật, vì dựa trên thứ đối thủ không có: **chữ ký phần cứng trên điện thoại (P-256), khóa TPM của máy tính, pet vật lý có khóa riêng (`firmware/include/DeviceKey.h`, `lib/xuna_core/include/xuna/identity/DeviceProof.h`) + nút bấm + BLE, lưới nhiều máy, Async Watch, và bộ quy tắc trung thực H1–H8.**

### F1. Bản nháp song song + "Ký đúng cái bạn thấy" (Speculative Execution & Effect-bound Approval) — đề xuất chủ lực
- **Hiện trạng:** chữ ký R3 ràng buộc **câu lệnh** — `approval_proof_message(approvalId, argsSha256, hostId, expiresAt)` (`backend/.../hosts/domain/crypto.py:119-131`). Chủ ký `del *.log` mà không biết chính xác tệp nào bị xóa; giữa lúc xem và lúc chạy, trạng thái đĩa có thể đổi (TOCTOU).
- **Đề xuất:** cả nhiệm vụ (`fs.*` + `exec.run` test/build) chạy trước trong **bản sao workspace** (git worktree khi là repo; bản sao tạm/clone copy-on-write khi hệ điều hành hỗ trợ — cần spike), mạng bị chặn trong bản nháp. Host tạo **effect manifest**: danh sách tệp đổi (sha256 trước/sau), diff, kết quả test, đích mạng định gọi. Điện thoại hiện: *"Đã thử trong bản nháp: 3 tệp đổi, test 10/10 — Áp dụng?"* Chữ ký mới ký **`effectSha256`** (thông điệp `xuna.approval.v2`). Host áp dụng **nguyên khối** chỉ khi sha256 "trước" của từng tệp vẫn khớp (chống TOCTOU), lệch là từ chối; ghi nhật ký để **hoàn tác cả nhiệm vụ**.
- **Vì sao đẳng cấp:** các agent lập trình phổ biến hỏi duyệt theo **chữ của lệnh**; sandbox đám mây thì có nhưng không có chữ ký phần cứng gắn với **hậu quả thật** và áp dụng nguyên tử trên máy cá nhân. F1 gộp và vượt U1+U2+U3.
- **Quy mô:** cần ADR (approval v2, effect manifest, chính sách mạng trong bản nháp), đổi hợp đồng XTP + fixture, thẻ duyệt mobile mới. Cỡ một Wave.

### F2. "Học một lần, lần sau tức thì" — Trình biên dịch quỹ đạo thành adapter (Adapter Foundry)
- **Ý cốt lõi học từ CLI-Anything:** LLM đọc phần mềm và sinh ra harness **có test**. XUNA làm việc đó **tại máy chủ nhân, lúc chạy**: khi XUNA hoàn thành một việc bằng GUI (Tier 3, chậm), Foundry tìm đường headless cho **cùng hiệu ứng** (cờ CLI của chính app, REST/MCP cục bộ, COM type library trên Windows, từ điển AppleScript trên macOS, hoặc thao tác thẳng định dạng tệp), sinh adapter ứng viên + **test vàng từ lần chạy thật** (cùng tệp đầu ra), chạy trong sandbox; chỉ lên Tier 0 sau khi test pass và chủ ký một lần.
- **Kết quả với người dùng:** lần đầu "xuất PDF" mất ~40 s bấm giao diện, các lần sau ~1 s chạy ngầm — XUNA "thông minh dần" theo cách đo được.
- **Hiện trạng để bám vào:** thang 4 tầng (`prompts.py:107-135`), vòng đời CU, OmniForge/`SandboxedToolRunner`; Habit Learner hiện chỉ học **định tuyến máy** (`mesh_routes.py:57-126`), chưa học **cách làm**.
- **Rủi ro:** thực thi mã sinh ra → sandbox, ký, fail-closed; H5: adapter chỉ nằm ở lớp host adapter, đường chung vẫn phải chạy.

### F3. Pet là "chìa khóa hiện diện" (Presence-bound approval & E-Stop vật lý)
- **Đề xuất:** dùng khóa P-256 của pet làm **yếu tố thứ hai vật lý**: thao tác nguy hiểm nhất (vd. R3 ngoài workspace, đẩy mã, xóa hàng loạt) cần **điện thoại ký + pet đồng ký** sau khi chủ **bấm nút trên pet** (pet ký challenge qua BLE, điện thoại chuyển tiếp) → kẻ chiếm điện thoại từ xa không đủ. **Nút pet = E-Stop toàn lưới** (dừng mọi máy cùng lúc). Màn hình/cảm xúc pet hiện trạng thái thật ("đang sửa 3 tệp trên PC", "chờ bạn ký") → minh bạch xung quanh.
- **Vì sao đẳng cấp:** không sản phẩm agent nào có **token hiện diện vật lý có mật mã** đồng thời là bạn đồng hành — đây là hào lũy khó sao chép nhất của XUNA.
- **Quy mô:** chạm firmware (mục đích proof mới — bộ xử lý hiện chỉ nhận `Bind`, `DeviceProof.h:67`), BLE pet↔điện thoại, backend (chính sách "cần đồng ký"), mobile.
- **Đính chính (kiểm chứng sau):** nút pet **đã có** duyệt R2 (UDC-12 S12.1) và E-Stop (`RemoteEventCode::Stop` → `stopPendingActions(reason: 'owner_board')`, `mobile/.../home_controller.dart:1969-1970`), nhưng chỉ là sự kiện nút bấm không ký và chưa thử trên board thật. F3 vì vậy tập trung vào **ký mật mã + đồng ký**, không làm lại E-Stop. Kế hoạch chi tiết: [XUNA_UPGRADE_PLAN_2026-11-26.md](../roadmap/XUNA_UPGRADE_PLAN_2026-11-26.md) §5.

### F4. Hộp đen & phòng thí nghiệm cá nhân (Personal regression eval)
- **Đề xuất:** mỗi nhiệm vụ thật được ghi thành kịch bản phát lại (không nội dung, đã che bí mật, kèm kết quả đã kiểm chứng). Khi backend đổi model/prompt (việc đổi model Gemini và failover xảy ra thường xuyên — `FallbackTextGenerator`), hệ thống tự phát lại trong bản nháp (F1) và công bố **tỉ lệ thành công trung thực theo từng loại việc của chính chủ nhân**; chặn nâng cấp làm tụt điểm.
- **Vì sao đáng giá:** áp kỷ luật test 4 lớp của CLI-Anything **lên chính agent**; biến "XUNA có giỏi lên không" thành con số.

**Thứ tự gợi ý:** xem kế hoạch tổng hợp [XUNA_UPGRADE_PLAN_2026-11-26.md](../roadmap/XUNA_UPGRADE_PLAN_2026-11-26.md) (P0 nợ Wave 3 → P1 U3–U5 → P2 F1 → P3 F3 → P4 U7/U6/F2 → P5 F4).

**Chưa kiểm chứng (H8):** số harness thực tế; hỗ trợ Windows từng harness; `analytics.py`; `matrix.py`; thư mục test của harness; ngày commit mới nhất; mọi lệnh cài theo từng agent. Chưa cài hay chạy bất kỳ thứ gì từ CLI-Anything.

# XUNA — Kế hoạch nâng cấp sau Wave 3 (Trust & Fluency)

Ngày: **2026-11-26** (Asia/Ho_Chi_Minh). Trạng thái: **Proposed — chờ chủ dự án duyệt từng giai đoạn.** Chưa có code cho các mục dưới đây.

Nguồn ý tưởng: kết quả live Windows Wave 3 ([PROCESS.md](../../PROCESS.md) 2026-11-26), nghiên cứu [XUNA_CLI_ANYTHING_RESEARCH_2026-11-26.md](../research/XUNA_CLI_ANYTHING_RESEARCH_2026-11-26.md) (§7 U1–U7, §8 F1–F4). Quy tắc áp dụng: [AGENTS.md](../../AGENTS.md), [desktop/AGENTS.md](../../desktop/AGENTS.md) §3, [XUNA_HONEST_CODE_RULES.md](../architecture/XUNA_HONEST_CODE_RULES.md) H1–H10.

## 0. Mục tiêu & nguyên tắc

- **Mục tiêu:** biến XUNA từ "agent làm được việc trên máy tính" thành **agent đáng tin nhất để giao việc thật**: chủ nhân biết chính xác điều gì sẽ xảy ra, ký đúng điều đó, hoàn tác được, và XUNA nhanh dần theo cách đo được.
- **Nguyên tắc:** sửa vi phạm quy tắc trước tính năng mới; mỗi milestone tự mang giá trị; thay đổi wire luôn kèm hợp đồng XTP + 2 thư mục fixture byte-identical (desktop AGENTS §5); không hứa điều kiến trúc cấm (không chạy elevated §3.7, không ghi nội dung vào log §3.6).
- **Kích cỡ:** S (≤ 1 phiên), M (2–3 phiên), L (một Wave), "cần spike" = chưa ước lượng được trước khi thử.

## 1. Tổng quan lộ trình

| Giai đoạn | Tên | Nội dung | ADR / đổi hợp đồng | Máy cần | Cỡ |
| --- | --- | --- | --- | --- | --- |
| **P0** | Đóng nợ Wave 3 | Live re-test, lỗi H1/H3 có sẵn, P2 từ live Windows, 2 test Windows fail, bản Release | Không | Windows (+ iPhone khi có) | M |
| **P1** | Trung thực & thông minh "rẻ" | U3 `expectFiles`, U4 toolchain + remediation, U5 test chống lệch prompt↔catalog | U3, U4: đổi hợp đồng XTP | Windows/Mac | M |
| **P2** | **Wave 4 — Bản nháp & Ký đúng cái bạn thấy (F1)** | U1 nhật ký hoàn tác → U2 xem trước trên thẻ duyệt → bản nháp workspace → chữ ký `xuna.approval.v2` gắn hậu quả | **ADR-0019** + XTP + golden vectors | Windows + Mac + iPhone | L |
| **P3** | Pet ký thật (F3) | Biến duyệt/dừng bằng nút pet thành **chữ ký mật mã** + đồng ký R3 | **ADR-0020**, firmware + BLE | Board + điện thoại | M–L |
| **P4** | Capability Adapter khai báo & Foundry (U7, U6, F2) | Engine chung + adapter là **manifest dữ liệu** (không tool riêng từng app) → adapter seed đầu tiên → kỹ năng có kiểm chứng → Foundry **sinh manifest** | **ADR-0021** + XTP | Windows/Mac | L, cần spike |
| **P5** | Phòng thí nghiệm cá nhân (F4) | Đánh giá hồi quy trên kịch bản thật của chủ nhân khi đổi model/prompt | Chỉ khi chọn ghi kịch bản tự động: ADR | Backend | M |

Phụ thuộc: P0 → P1 → P2; P3 song song được với P2 khi có board + điện thoại; P4.1 cần P1.1 (`verify`) và P1.2 (remediation); P4.4 (Foundry) cần bản nháp của P2; P5 tận dụng bản nháp của P2 nếu có.

---

## 2. P0 — Đóng nợ Wave 3 (không ADR)

| ID | Việc | Lớp / tệp chính | Cổng kiểm chứng (H8) | Cỡ |
| --- | --- | --- | --- | --- |
| P0.1 | Live re-test công tắc "Dòng lệnh & tệp" bật `files` trên **máy mới cài** (`645ae76`) | `desktop/` (đã code) | Build Windows; "Khôi phục mặc định" → bật → `fs.list_files` `ok`, tắt → `policy_blocked` | S |
| P0.2 | Lần gọi live đầu tiên của `media.*` + presence digest sau bản sửa MTA (`1877cc1`) | `desktop/windows/runner` | Có nhạc đang phát: `media.now_playing` trả đúng, `media.play_pause` đổi trạng thái thật; presence `mediaPlaying` đúng | S |
| P0.3 | **Sửa lỗi H1/H3 có sẵn:** `bridgeSkillMarkdown` trả `securityVerified: true` không kiểm chứng; `skills.first` khi không khớp id | `desktop/.../skill_workshop_service.dart:42-92` | Test: import trả `securityVerified: false` (hoặc bỏ trường) cho tới khi có kiểm chứng thật; id sai → lỗi + danh sách ứng viên giới hạn | S |
| P0.4 | `_gitRule` bỏ qua option toàn cục trước subcommand (`--no-pager`, `--version`, `-c` vẫn R3) | `xuna_xtp/.../exec_command_rules.dart:171-228` | Test hồi quy: `git --no-pager log` R2, `git --version` R2, `git -c x=y log` vẫn R3 | S |
| P0.5 | Output builtin `cmd.exe` bị lỗi code page OEM (`echo xin chào` → `xin ch�o`) | `desktop/lib/features/exec` | **Cần spike nhỏ:** giải mã theo OEM CP vs ép UTF-8; live: `echo xin chào` đúng, output `node` UTF-8 vẫn đúng | S |
| P0.6 | Tự nạp lại `host-policy.json` khi tệp đổi (hiện phải khởi động lại) | `desktop/lib/features/policy/host_policy_store.dart` | Test: sửa tệp → evaluator đổi + `list_changed`; tệp hỏng → fail-closed `policy_invalid` | S |
| P0.7 | UI đặt `shellControl.workspaceRoots` (chọn thư mục, local-only) | `desktop` tab Chính sách | Test controller + live: thêm thư mục → `fs.write_file` trong đó R2 `workspace` | S–M |
| P0.8 | Sửa 2 test chỉ fail trên Windows (`mesh_discovery_and_tools_e2e_test` tên thư mục đặc biệt; `wave_c_desktop_test` `resolveHomeOpenTarget` macOS) | `desktop/test` | `fvm flutter test` trên Windows: 0 fail (hoặc skip có lý do nền tảng rõ ràng) | S |
| P0.9 | Bản Release Windows + đóng gói + khởi động cùng máy (`HKCU Run`) | `desktop/windows` | `flutter build windows --release`, cài trên máy sạch, chạy từ Explorer, không elevated | M |
| P0.10 | Mục UDC-16 §4m cần iPhone thật | `mobile` | Theo checklist khi có iPhone | — |

**Tiến độ 2026-11-26 (chưa commit, xem PROCESS.md):** P0.3, P0.4, P0.6, P0.7, P0.8 — code + unit test xong (desktop 380/380, `xuna_xtp` 261/261); P0.1, P0.2, P0.7 — chờ phiên live; P0.5 — **hoãn, cần ConPTY** (`chcp` không tác dụng; `AttachConsole` lên tiến trình suspended lỗi 6) → thêm hạng mục **"ConPTY launcher cho Windows"** (sửa font cmd + mở `pty: true`); P0.9 — công tắc opt-in "Khởi động cùng máy" (`HKCU Run` có bọc nháy) xong, còn đóng gói trình cài (chủ chọn MSIX/Inno/zip); thêm: `cmd.exe` tạo `CREATE_SUSPENDED` + gắn Job Object trước khi chạy; P0.10 — chờ iPhone.

Ghi chú: E-Stop không treo grant `media` (R1) **khớp** desktop AGENTS §3.5 ("suspends new R2+ tool calls") — không phải lỗi; đổi hay không là quyết định D2.

---

## 3. P1 — Trung thực & thông minh "rẻ"

| ID | Việc | Thiết kế | Cổng kiểm chứng | Cỡ |
| --- | --- | --- | --- | --- |
| P1.1 (U3) | **Hậu điều kiện đầu ra cho `exec.run`** | Tham số tùy chọn `expectFiles: [{path, minBytes?, magic?, sha256?}]` (đường dẫn qua `FsPathGuard`); host chỉ trả `completed` khi tất cả khớp, ngược lại `failed` + `errorCode: expected_output_missing\|mismatch`. Kết quả `artifacts: [{path, sizeBytes, sha256, magicOk}]` — **định dạng này F1 dùng lại** cho effect manifest | Hợp đồng XTP §8 + fixtures 2 nơi (`diff -r` 0); test: lệnh exit 0 nhưng không tạo tệp → `failed`; tệp đúng → `completed` + sha256 khớp đĩa | M |
| P1.2 (U4) | **Máy tự khai báo toolchain + gợi ý sửa** | Resource digest thêm `toolchains: [{id, version}]` do host dò (node/python/git/… — danh sách nằm trong host adapter, không ở backend/prompt, H5); lỗi thiếu phụ thuộc mang `remediation` do host khai báo; mobile hiện thẻ "sửa 1 chạm" (chỉ hiển thị lệnh, không tự chạy) | Hợp đồng XTP (`xuna/resources`) + fixtures; test digest không chứa đường dẫn; backend đọc trường chung, không gắn tên công cụ | M |
| P1.3 (U5) | **Test chống lệch prompt ↔ catalog** | Test backend: mọi tên tool/tiền tố được nhắc trong `prompts.py` phải tồn tại trong catalog/descriptor; ví dụ tham số trong prompt phải qua schema validator | `pytest` fail khi đổi tên tool mà quên prompt (thử đột biến) | S |

---

## 4. P2 — Wave 4: Bản nháp & "Ký đúng cái bạn thấy" (F1) — ADR-0019

**Vấn đề:** chữ ký R3 hiện ràng buộc **câu lệnh** — `approval_proof_message(approvalId, argsSha256, hostId, expiresAt)` (`backend/.../hosts/domain/crypto.py:119-131`); chủ ký `del *.log` mà không thấy tệp nào bị xóa; trạng thái đĩa có thể đổi giữa lúc xem và lúc chạy.

**Giới hạn trung thực (ghi thẳng vào ADR, H6):**
- Bản nháp chỉ bao phủ **tệp trong workspace**. Tác động ngoài workspace (cache toàn cục, registry, tiến trình khác) **không** chụp được → manifest phải ghi rõ phạm vi.
- **Không giả định chặn mạng** trong bản nháp: agent không được chạy elevated (§3.7) và chưa có cách chặn mạng theo tiến trình đơn giản không cần quyền admin trên Windows → là **cổng spike**. Mặc định: bản nháp chỉ chạy `fs.*` + `exec` R2; mọi thứ khác giữ R3 từng lệnh như hiện nay.
- Áp dụng nhiều tệp trên Windows **không nguyên tử tự nhiên** → cần nhật ký + rollback (dùng lại W4-M1).

| Milestone | Nội dung | Tự mang giá trị | Cổng kiểm chứng |
| --- | --- | --- | --- |
| W4-M0 | ADR-0019 + 3 spike: (a) cơ chế bản sao (git worktree — thiếu tệp untracked/ignored, chỉ cho repo; sao chép thường; APFS `clonefile` trên Mac; CoW NTFS — chưa chắc), (b) cách ly mạng không cần admin, (c) áp dụng nhất quán khi crash trên Windows | Quyết định có số liệu | Báo cáo spike, chủ duyệt ADR |
| W4-M1 (U1) | **Nhật ký hoàn tác cho `fs.*`:** lưu bản cũ trước khi ghi (giới hạn dung lượng/thời gian, chỉ trong workspace, không lưu tệp mật, lưu cục bộ), `action.undo` khôi phục; descriptor đổi `reversible: true` chỉ khi có bản lưu | "Hoàn tác giúp mình" chạy được ngay | Test: ghi → undo → sha256 về như cũ; tệp mật không bao giờ vào nhật ký; hết hạn bị dọn |
| W4-M2 (U2) | **Xem trước trên thẻ duyệt R3** (vẫn chữ ký v1): diff cho `fs.patch_file`/`write_file`; danh sách mục tiêu cho lệnh xóa (host mở rộng glob ở chế độ chỉ đọc) | Chủ ký khi biết chính xác thay đổi | XTP (preflight trả preview giới hạn kích thước) + mobile card; test: preview không lộ tệp mật, bị cắt có "…" |
| W4-M3 | **Bản nháp workspace:** chạy chuỗi `fs.*` + `exec` R2 trong bản sao, tạo effect manifest (`artifacts` của P1.1 + sha256 trước/sau + kết quả test + phạm vi) | Thử an toàn trước khi đụng tệp thật | Test: bản gốc không đổi byte nào trong lúc chạy nháp; manifest khớp diff thật |
| W4-M4 | **`xuna.approval.v2`:** điện thoại ký `effectSha256`; host áp dụng chỉ khi sha256 "trước" của từng tệp còn khớp (chống TOCTOU), lệch → từ chối, lỗi giữa chừng → rollback bằng nhật ký; **v1 và v2 cùng tồn tại** khi chuyển đổi | Chữ ký gắn với hậu quả thật | Golden vectors mới (backend + desktop + mobile), test đối kháng: sửa tệp giữa preview và apply → bị từ chối, 0 tệp đổi |
| W4-M5 | Kiểm chứng live Windows + Mac (+ iPhone khi có) | — | Kịch bản: sửa 3 tệp + chạy test trong nháp → ký → áp dụng → hoàn tác cả nhiệm vụ; `false_success = 0` |

---

## 5. P3 — Pet ký thật (F3) — ADR-0020

**Hiện trạng (đã kiểm chứng):** nút pet đã có **duyệt R2** (UDC-12 S12.1: `GPIO0` duyệt / `GPIO14` từ chối, R3 chỉ ký trên điện thoại) và **E-Stop** (`RemoteEventCode::Stop` → điện thoại `stopPendingActions(reason: 'owner_board')`, `mobile/.../home_controller.dart:1969-1970`) — nhưng đều là **sự kiện nút bấm qua BLE, không có chữ ký**, và chưa thử trên phần cứng thật (`HW-BOARD-1`). Pet có khóa P-256 riêng (`DeviceKey.h`, `DeviceProof.h`) nhưng bộ xử lý chỉ chấp nhận mục đích `Bind` (`DeviceProof.h:67`).

| Milestone | Nội dung | Cổng kiểm chứng |
| --- | --- | --- |
| F3-M0 | Live-verify phần đã có trên board thật: duyệt R2 bằng nút, E-Stop bằng nút; xác minh E-Stop từ pet có **treo grant mọi máy** hay chỉ dừng hành động đang chờ | Board + điện thoại; ghi rõ hành vi thật |
| F3-M1 | ADR-0020 + mục đích proof mới (vd. `Approve`) trong firmware: pet ký `nonce ‖ effectSha256/argsSha256 ‖ mã ngắn` sau khi chủ bấm nút; **màn hình pet hiện mã ngắn trùng với điện thoại** (không có bước này thì pet chỉ ký mù cái điện thoại chuyển tới) | Unit test firmware + golden vector; upload board cần chủ xác nhận |
| F3-M2 | Backend: chính sách "cần đồng ký" cho nhóm thao tác chủ chọn (D6); điện thoại chuyển tiếp chữ ký pet; host/backend xác minh cả hai | Test: thiếu chữ ký pet → từ chối; pet ký mã khác → từ chối |
| F3-M3 | E-Stop có ký (pet ký sự kiện dừng → chống giả mạo BLE); ghi rõ giới hạn: E-Stop từ pet cần app điện thoại đang kết nối | Live board + điện thoại |

---

## 6. P4 — Capability Adapter khai báo & Foundry (U7, U6, F2) — ADR-0021

**Nguyên tắc (sửa 2026-11-26 theo góp ý chủ dự án):** không viết tool riêng cho từng việc/từng app (vd. `doc.convert` gọi `soffice`) — cách đó gắn engine vào một app, tốn slot catalog (`MAX_CATALOG_TOOLS = 36`) và không cho Foundry một định dạng chung để sinh. Thay vào đó: **một engine chung + adapter là dữ liệu khai báo**. Engine, backend và prompt không chứa tên app (H5); năng lực do adapter khai báo, host quảng bá, LLM đọc.

**Adapter manifest (dữ liệu, không phải mã):**
- `capability` (động từ chung + kiểu vào/ra, vd. `convert {from: [docx, xlsx], to: [pdf]}`), `inputsSchema` (JSON Schema strict).
- `detect`: cách host xác nhận adapter dùng được trên máy này (tên binary + vị trí dò, phiên bản tối thiểu) → không có thì adapter không xuất hiện.
- `invoke`: **mẫu argv cố định** với chỗ trống có kiểu (`{inputPath}`, `{outDir}`) — không shell, không nối chuỗi lệnh, không cờ eval; đường dẫn đi qua `FsPathGuard`.
- `risk` theo năng lực (đọc/chuyển đổi ra tệp mới = R2; ghi đè/xóa/mạng = R3) — engine vẫn chạy `ExecCommandClassifier` và lấy mức **cao hơn** giữa khai báo và phân loại.
- `verify`: hậu điều kiện đầu ra theo P1.1 (`expectFiles`, magic, kích thước) → không qua là `failed`.
- `provenance`: `seed` (chủ dự án viết/duyệt) / `foundry` (sinh tự động) + sha256 manifest + sha256 binary lúc duyệt; manifest đổi hoặc binary đổi → phải duyệt lại.

| ID | Việc | Ghi chú | Cổng kiểm chứng | Cỡ |
| --- | --- | --- | --- | --- |
| P4.1 | **Engine Capability Adapter chung** + ADR-0021: lược đồ manifest, tool chung `capability.list` / `capability.run` (2 slot cố định cho mọi adapter, thay vì 1 slot/việc), host chỉ quảng bá adapter có `detect` đạt; chạy qua runtime exec sẵn có (CreateProcessW/Job Object, lọc env, E-Stop) | Thực thi binary theo mẫu argv do manifest khai báo = bề mặt thực thi mới → ADR bắt buộc (desktop AGENTS §3.1; ADR-0018 mới mở `exec`). CLI-Anything harness, nếu sau này muốn, cũng chỉ là **một manifest** — không cần loại `cli_json` riêng | XTP + fixtures; test đối kháng: manifest có shell/eval/chỗ trống không kiểu → bị từ chối khi nạp; tham số chèn `&`/`;` không thoát ra ngoài argv | L |
| P4.2 (U7) | **Adapter seed đầu tiên = một tệp manifest**, không phải mã (vd. chuyển đổi tài liệu qua bộ office headless có trên máy) — dùng để chứng minh hợp đồng | Không có dòng mã nào nhắc app trong engine; gỡ manifest = năng lực biến mất. **Thay thế spike CLI-Anything LibreOffice** | Live Windows/Mac: tệp đầu ra thật (magic), máy không có binary → adapter không được quảng bá + remediation (P1.2) | S |
| P4.3 (U6) | **Kỹ năng có kiểm chứng:** OmniForge/SKILL.md có trạng thái `draft` → `verified` chỉ sau khi tự-test chạy pass trong `SandboxedToolRunner` | Nối tiếp P0.3 | Test: kỹ năng không có test pass không bao giờ `verified` | M |
| P4.4 (F2) | **Adapter Foundry sinh manifest, không sinh mã:** sau khi XUNA làm xong một việc bằng GUI, tìm đường headless cho cùng hiệu ứng (cờ CLI/`--help` của app, REST/MCP cục bộ), đề xuất **manifest** + test vàng từ lần chạy thật, chạy trong bản nháp (P2), chỉ dùng được sau khi test pass + chủ ký (`provenance: foundry`) | Vì đầu ra bị ràng buộc vào lược đồ manifest (argv cố định, có kiểu, có verify), bề mặt rủi ro nhỏ hơn nhiều so với sinh mã tùy ý. COM/AppleScript (cần mã) để ngoài phạm vi trừ khi có quyết định riêng | Đo: thời gian lần 2 so với lần 1; manifest không qua test không bao giờ được quảng bá | L, cần spike |

---

## 7. P5 — Phòng thí nghiệm cá nhân (F4)

| ID | Việc | Ghi chú | Cỡ |
| --- | --- | --- | --- |
| P5.1 | Bộ kịch bản **được chủ duyệt** (không tự ghi), xây trên `backend/scripts/eval_host_control.py`; chạy lại khi đổi model/prompt/`FallbackTextGenerator`; báo tỉ lệ thành công theo loại việc | Không đụng §3.6 | M |
| P5.2 | (Tùy chọn) Ghi nhiệm vụ thật thành kịch bản phát lại | **Xung đột desktop AGENTS §3.6** (cấm ghi tham số/URL/đường dẫn vào log/audit) → chỉ làm nếu có ADR: kho riêng, opt-in, mã hóa cục bộ, chủ đồng ý | M + ADR |

---

## 8. Quyết định cần chủ dự án (D1–D10)

| ID | Câu hỏi | Lựa chọn | Khuyến nghị |
| --- | --- | --- | --- |
| D1 | Thứ tự lộ trình | P0 → P1 → P2 (P3 song song khi có board) / khác | **P0 → P1 → P2** |
| D2 | E-Stop có treo cả `media` (R1)? | Giữ như §3.5 / treo tất cả | **Giữ** (khớp quy tắc; E-Stop nhắm việc có rủi ro) |
| D3 | `workspaceRoots` lấy từ đâu | Chọn thư mục trong tab Chính sách / tự lấy từ workspace đã quét | **Chọn tay** (chủ quyết, local-only) |
| D4 | Phạm vi chữ ký hậu quả (F1) | Chỉ tệp trong workspace / cố chặn mạng (spike) | **Chỉ workspace**, mạng giữ R3 từng lệnh |
| D5 | Cơ chế bản nháp | Sau spike W4-M0 | Chờ số liệu |
| D6 | Thao tác nào cần pet đồng ký | R3 ngoài workspace + xóa hàng loạt + đẩy mã / chỉ khi chủ bật | **Chủ bật theo nhóm**, mặc định tắt |
| D7 | Cho phép Foundry sinh adapter (F2)? | Chỉ sinh **manifest** theo lược đồ (sau P4.1 + P2, có ADR) / cho sinh cả mã / không | **Chỉ manifest**, sau P4.1 + P2 |
| D10 | Hình thức adapter | Manifest khai báo + engine chung / tool viết tay cho từng việc | **Manifest + engine chung** (không hard-code app) |
| D8 | Dữ liệu cho phòng thí nghiệm (F4) | Kịch bản chủ duyệt / ghi tự động mã hóa | **Kịch bản chủ duyệt** trước |
| D9 | CLI-Anything | Không dùng hub/plugin; spike LibreOffice bỏ (thay bằng P4.1) | **Đồng ý** |

## 9. Không làm

- Không dùng CLI-Hub hay bất kỳ chợ plugin/skill nào (tiền lệ ClawHub trong nghiên cứu OpenClaw 2026-11-03).
- Không nới allowlist R2 của `ExecCommandClassifier` cho CLI bên thứ ba (phá thiết kế allowlist dương).
- Không chạy agent elevated để đạt tính năng (vd. chặn mạng) — §3.7.
- Không ghi nội dung nhiệm vụ vào log/audit ngoài ADR được duyệt — §3.6.

## 10. Bước đầu tiên đề xuất

Duyệt D1 + D9, rồi làm **P0** (bắt đầu từ P0.3 — lỗi H1/H3 — và P0.1/P0.2 live trên Windows), song song soạn **ADR-0019 (F1)** để duyệt trước khi vào P2.

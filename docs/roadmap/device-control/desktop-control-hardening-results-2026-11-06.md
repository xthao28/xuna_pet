# Gia cố điều khiển desktop — kết quả 2026-11-06

> Không phải một milestone UDC mới (chưa đăng ký ID trong [README](README.md) §2). Đây là đợt rà soát và vá phần điều khiển UI của `desktop/` sau khi đối chiếu với OpenClaw ([nghiên cứu 2026-11-03](../../research/XUNA_OPENCLAW_DEEP_RESEARCH_2026-11-03.md), chỉ nói về UX mobile). Nếu muốn đặt tên milestone (ví dụ UDC-17) thì đăng ký ID trước.

Luật áp dụng: [desktop/AGENTS.md](../../../desktop/AGENTS.md) — bất biến §3 và honest-code H1–H8.

## 1. Đã làm (tất cả trong `desktop/`)

| Commit | Nội dung |
|---|---|
| `2d8e690` | `ui.accessibility_tree` chỉ còn `inspect_window` (R1, chỉ đọc). Trước đó mọi action (`invoke_ref`, `set_value_ref`, `close_window`, `drag`, `shortcut`…) cùng R1 và nằm ngoài cổng duyệt R2, nên chạy không cần chủ duyệt. Manifest không còn quảng cáo `refId`/`valueText`. Provider computer-use không còn đổi click chỉ-có-tọa-độ thành `ui_1` hay đoán `ui_N` từ chữ số cuối (H3). |
| `7709f5b` | `lockScreen`/`displayWake` không còn tự bịa `true` khi native không trả kết quả. Fallback Linux trả `unsupported` cho method chưa cài, permission `not_determined`, không tự cấp "granted". Manifest khi đọc permission lỗi báo `not_determined`. |
| `2327bca` | `forge.synthesize_skill` chỉ báo số tệp và mẫu đo được trên đĩa; bỏ toàn bộ số đếm/mẫu dựng sẵn theo danh mục. Không quét được thì báo 0 và nói rõ lý do. |
| `248f402` | Inspect UI giới hạn 60 phần tử, bằng cap dựng lại của `invokeWindowUiControl` (trước đó 80, nên ref 61–80 đưa cho model nhưng không bấm được). |
| `f038e43` | `UiAccessibilityTreeService` chỉ mô tả cây đã quét thật: bỏ 4 control giả `ui_1..ui_4`, bỏ nhánh `invoke_ref`/`set_value_ref` tự dựng node và báo "đã bấm", bỏ ref mặc định, bỏ "tiết kiệm 92% token" (không đo). Xoá 2 hàm chết (`runZeroScreenshotUiAutomationFromUi`, wrapper `executeUiAccessibilityTree`). |

## 2. Quyết định đã chốt

- Thu hẹp `ui.accessibility_tree` về chỉ đọc (khuyến nghị đã được owner đồng ý). Click/gõ/cuộn/phím/menu/đóng cửa sổ đi qua `input.*` trong phiên `cu.session_start` đã duyệt.
- Lý do không chỉ nâng `effectiveRisk` theo action: backend quyết định có xin duyệt hay không từ `descriptor.risk` trong manifest ([orchestrator.py:642](../../../backend/src/xuna_backend/modules/actions/application/orchestrator.py#L642)), không từ `effectiveRisk` của host. Nâng ở host một mình làm host từ chối `approval_required` mà điện thoại không được hỏi.
- Backend và mobile không gọi các action ghi này (chỉ dùng tên tool; Android có manifest riêng), nên không cần đổi.

## 3. Đã kiểm chứng

- `packages/xuna_xtp`: `dart analyze --fatal-infos` 0 lỗi; `dart test` 29 qua (package không đổi sau commit `2d8e690`).
- App desktop: `flutter analyze` 0 lỗi; `flutter test` 49 qua.
- Test mới: action ghi bị từ chối ở schema; provider không đoán mục tiêu; cap 60; `lockScreen`/`displayWake`; manifest khi permission lỗi; `synthesize_skill` cho thư mục rỗng; service chỉ mô tả cây đã quét. Hai test cũ đang khẳng định hành vi sai (`invoke_ref` chạy không duyệt; "xử lý 15 mục" cho thư mục không tồn tại) đã đảo lại (H7).

## 4. Chưa chạy

- Không chạy được native Windows (C++ UIA), macOS (Swift), Linux; không có phiên computer-use thật với điện thoại duyệt.
- `dart format` ở chế độ kiểm tra báo 7 file `xuna_xtp` lệch format từ trước (gồm file đã sửa); không format lại để diff khỏi phình.

## 5. Còn lại (chưa sửa)

Nhóm cần máy hoặc quyết định:

- **macOS (Swift):** theo báo cáo quét, `AppsAndContext.swift:209` ép accessibility luôn "granted" (`|| true`) và `requestPermission` luôn trả granted. Tôi chưa tự đọc/sửa vì không có Mac để biên dịch.
- **Windows (C++, `xuna_win_uia_engine.h`):** `set_value_ref` gõ vào ô nhập đầu tiên khi mất đích và coi là thành công; ref chỉ là số thứ tự quét lại (không có RuntimeId), có độ trễ giữa lúc inspect và lúc invoke; `nativeId` không được xuất nên nhánh khử trùng lặp luôn ra `ambiguous_target`. Đây là nhóm "snapshot có ref ổn định" cần máy Windows để nghiệm thu.
- **Manifest:** `ui.accessibility_tree` vẫn khai báo R1 + `observes: true` (đúng cho chỉ-đọc). Mô hình rủi ro theo action thật sự (nếu sau này cần) phải đổi contract XTP và fixture ở nhiều repo.
- `host.status` trên Windows báo permission cố định "granted" (Windows UIA không cần quyền, nhưng phần thông báo chưa xác minh).

Nhóm làm được không cần máy (chưa làm):

- Fallback Linux chạy `playerctl`/`pactl`/`notify-send`/`xdg-open` không kiểm exit code; `window.active_context` trên Linux ghi cứng `processName: 'x11'`; `linux/runner/xuna_host_plugin.cc` chưa được đăng ký nên code C đó là code chết. Linux không phải nền tảng mục tiêu (UDC-3: Windows → macOS).
- `selection.read` thực chất đọc clipboard, tên và mô tả chưa khớp (H6).
- `applyNativeWindowUiTree` vẫn dùng `ui_$idx` khi native không trả `refId` (một dạng đoán).
- Dispatcher dùng approval tổng hợp cho sub-step của `workflow.batch_steps`. Đã kiểm: batch là R2, cần duyệt gắn hash toàn bộ tham số và từ chối step `ui.*`/`input.*`/`cu.*`/R3, nên không phải lỗ hổng; báo cáo quét ban đầu nói sai chỗ này.

## 6. Việc kế tiếp đề xuất

1. Chạy bản `desktop/` này trên Windows thật: `host.status`, `ui.accessibility_tree` (`inspect_window` trên 2–3 ứng dụng), một phiên `cu.session_start` với `input.click`/`input.type_text` có duyệt từ điện thoại.
2. Snapshot có ref ổn định (UIA RuntimeId, giữ cây phân cấp, invoke theo định danh, thống nhất cap) kèm test native — cần máy Windows.
3. Phần macOS Swift ở trên — cần Mac.

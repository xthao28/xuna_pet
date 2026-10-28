# XUNA — Kế hoạch Nâng cấp Quản lý Năng lượng, Giảm nhiệt & Ngủ Tiết kiệm Pin

> **Ngày lập:** 2026-10-28
> **Trạng thái:** Proposed (đã lưu kế hoạch theo yêu cầu của Owner, chờ triển khai sau khi ổn định bản build Mobile/Cloud hiện tại)
> **Phạm vi:** `firmware/` (`DisplayManager`, `BacklightDimmer`, `BleManager`, `main.cpp`) và `mobile/` (`HomeDeviceSettingsCard`, `HomeDeviceTab`, `HomeController`)

---

## 1. Hiện trạng & Chẩn đoán nhiệt độ trên mạch (`LILYGO T-Display-S3`)

Số liệu đo thực tế từ cổng Serial sau ~19 phút hoạt động liên tục (`t_s = 1142s`, firmware `86ba2e6`):

```text
scene=animated state=idle loop_gap_max_us=11015 draws=11216 draw_max_us=7798 scene_max_us=43817
power loops=495 chip_temp_c=47.8 cpu_mhz=80 backlight=12
needs t_s=1137 activity=idle energy=37968 energy_pct=57 stim=49386 stim_pct=75
heap_free=220828 heap_min=218812 psram_heap_total=8386215 psram_free=8239487
```

### Nguyên nhân gây nóng (~47.8°C tại cảm biến nội tâm chip, ~40–42°C bề mặt):

1. **Màn hình LCD & đèn nền sáng 100% thời gian + đẩy 10 FPS liên tục:**
   - Trong 19 phút ở trạng thái đứng yên (`state=idle`), mạch vẫn đẩy `11,265` khung hình (`37,800 byte/khung` qua bus 8-bit song song) mà không có chế độ giảm nhịp vẽ hay tự tắt màn hình khi không có người tương tác.
2. **Thứ tự khởi tạo đèn nền trong `DisplayManager::begin()` và độ rộng xung `1 µs`:**
   - Trong `DisplayManager::begin()`, chân `kBacklightPin` (`GPIO38`) được kéo `LOW` suốt quá trình khởi tạo (> 100 ms), gọi `update()` (phát xung giảm sáng khi đèn nền chưa bật), rồi cuối hàm mới gọi `digitalWrite(kBacklightPin, HIGH)`.
   - Khi `kBacklightPin` chuyển từ `LOW` sang `HIGH`, IC điều khiển đèn nền 1-wire **AW9364** khởi động lại ở mức **16/16 (100% dòng LED tối đa)**, trong khi biến `backlightHw_` trong phần mềm đã giảm xuống `12/16`. Hệ quả là đèn nền thực tế chạy gần 100% công suất tối đa, gây nóng trực tiếp mặt trước màn hình.
3. **Công suất phát sóng BLE (`TX Power`) ở mức mặc định cao:**
   - Khi kết nối liên tục với App để truyền phụ đề (`7a6e0010`), trạng thái và tín hiệu hội thoại, bộ phát RF hoạt động ở mức mặc định (`+3 dBm` / `+9 dBm`) làm tăng nhiệt vùng ăng-ten ESP32-S3.
4. **Chưa có chế độ ngủ màn hình (Screen Sleep / Doze) khi không tương tác.**

---

## 2. Kiến trúc Nâng cấp (2 Giai đoạn)

### Nguyên tắc bất biến (Product & Architecture Invariants)
- **Local-first life (`AGENTS.md` §1):** Khi màn hình giảm sáng hoặc tắt hoàn toàn (`ST7789_SLPIN`), sự sống của XUNA (`LifeCore`, năng lượng, tâm trạng, thói quen, tính cách) và kết nối BLE **vẫn hoạt động ngầm 100%** theo đồng hồ thực.
- **Đánh thức tức thì (Instant Wake):** Bất kỳ nút bấm vật lý nào (`GPIO0`, `GPIO14`) hoặc tương tác từ App đều đánh thức màn hình ngay lập tức.

---

### Giai đoạn 1: Sửa lỗi nhiệt & Tối ưu tiêu thụ khi đang thức (Firmware)

1. **Chuẩn hoá điều khiển xung đèn nền `AW9364` (`DisplayManager.cpp`):**
   - Trong `DisplayManager::begin()`: bật `digitalWrite(kBacklightPin, HIGH)` và chờ ổn định `delayMicroseconds(35)` (`t_on` theo datasheet AW9364) **trước** khi gọi `setBacklight()`, đồng bộ chính xác `backlightHw_ = BacklightDimmer::kMax` với trạng thái phần cứng.
   - Trong `DisplayManager::setBacklight()`: tăng độ rộng xung `LOW` / `HIGH` từ `1 µs` lên `3 µs` và khoá ngắt ngắn (`noInterrupts()` / `portENTER_CRITICAL`) trong vài chục micro-giây phát xung để không bị ngắt BLE làm trượt bậc sáng.
2. **Hạ công suất phát sóng BLE (`BleManager.h`):**
   - Gọi `esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_DEFAULT, ESP_PWR_LVL_N0)` (`0 dBm`) và `ESP_BLE_PWR_TYPE_ADV` / `CONN` sau `BLEDevice::init("XUNA")`, đảm bảo kết nối ổn định trong phạm vi phòng (5–10m) nhưng giảm đáng kể nhiệt RF.
3. **Adaptive Frame Rate & Loop Pacing khi rảnh (`main.cpp`, `DisplayManager.cpp`):**
   - **Khi đang tương tác** (vừa bấm nút, nhận lệnh BLE, đang phát động tác Track A, có hiệu ứng tim/khói, có bong bóng phụ đề, hoặc ở trạng thái `Happy` / `Curious`): giữ nguyên tốc độ vẽ `10 FPS` (`100 ms/frame`) và vòng lặp `10 ms`.
   - **Sau 20 giây không có tương tác mới** ở trạng thái `Idle` hoặc `Sleep`: tự động hạ tốc độ khung hình xuống `5 FPS` (`200 ms/frame`) và giãn chu kỳ ngủ của vòng lặp (`delay`) từ `10 ms` lên `25 ms` (giảm ~50% số lần đẩy DMA/bus màn hình và thời gian thức của CPU).

---

### Giai đoạn 2: Chế độ Ngủ Màn Hình (Screen Sleep / Doze) & Điều khiển từ App (Firmware + Mobile)

1. **Máy trạng thái năng lượng màn hình 3 tầng (`Active` → `Dim` → `ScreenOff`):**
   - **`Active` (0 – 30 giây từ lần tương tác cuối):** Độ sáng theo mức cài đặt của người dùng (mặc định `10/16` khi thức, `6/16` khi XUNA ngủ, `15/16` khi mở thẻ QR/Status).
   - **`Dim` (30 – 120 giây không tương tác):** Hạ mượt đèn nền xuống mức dịu (`4/16`).
   - **`ScreenOff / Doze` (sau 120 giây không tương tác, khi bật chế độ tiết kiệm pin):**
     - Kéo `kBacklightPin` xuống `LOW` (> 3 ms) để tắt hoàn toàn IC nguồn đèn nền AW9364 (`0 mA`).
     - Gửi lệnh `ST7789_SLPIN (0x10)` qua `lcd_.writecommand(0x10)` để đưa bộ điều khiển LCD vào chế độ ngủ.
     - Bỏ qua toàn bộ việc vẽ sprite/cửa sổ (`draws = 0`) và giãn vòng lặp `loop()` lên `50 ms`.
2. **Cơ chế Đánh thức (Wake Triggers):**
   - **Nút bấm trên mạch (`GPIO0` / `GPIO14`):** Nếu màn hình đang ở `ScreenOff`, lần bấm đầu tiên sẽ gọi `lcd_.writecommand(0x11)` (`ST7789_SLPOUT`), chờ ổn định và bật lại đèn nền (đồng thời nuốt sự kiện bấm đó giống như khi đóng thẻ Status để không vô tình dạy nhầm phản ứng).
   - **Tương tác từ App qua BLE:** Khi nhận lệnh đổi biểu cảm, xem động tác, gợi ý hành động, hoặc nhận bong bóng phụ đề (`7a6e0010`), màn hình tự động thức dậy để hiển thị.
3. **Đồng bộ Cài đặt trên App (`mobile/`):**
   - Mở khoá 2 mục đang gắn nhãn `SẮP CÓ` trên màn hình **Thiết bị** (`HomeDeviceTab` & `HomeDeviceSettingsCard`):
     - **Độ sáng màn hình (`home_brightness` / `home_settingBrightness`):** Cho phép chọn mức độ sáng (Thấp / Vừa / Cao) và lưu bền vững.
     - **Đánh thức màn hình / Ngủ tiết kiệm pin (`home_settingWake`):** Công tắc bật/tắt chế độ tự động tắt màn hình tiết kiệm pin và tự đánh thức khi mở App / tương tác.


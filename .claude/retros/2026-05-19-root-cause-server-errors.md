## [2026-05-19] Root Cause Analysis — Server Errors, Patient Reload Bug, Review Queue Mojibake

### Root Causes Đã Xác Định

#### 1. Bệnh nhân "Không tải được" (ảnh 2)
- **Root cause**: `clinic_patient_bloc.dart` hardcode timeout 15s nhưng Render cold start ~30s → timeout sớm trước khi server phản hồi
- **Fix**: Tăng timeout từ 15s → 55s (nhất quán với Dio connectTimeout = 60s)
- **Bonus**: Thêm server error detection (`'timeout'`, `'connection'`, `'socket'`) → emit token `'server_cold_start'` thay vì generic message

#### 2. Nút reload không hoạt động (ảnh 5)
- **Root cause**: `_Header` chỉ render nút refresh `if (state is ClinicPatientsLoaded)` — khi error state thì không có nút nào
- **Fix**: Tách `loadedState = state is ClinicPatientsLoaded ? state : null`, nút refresh luôn hiện. Khi error → `ClinicPatientsFetchRequested()`, khi loaded → `ClinicPatientsRefreshRequested()`
- **Bonus**: Spinner CircularProgressIndicator thay thế nút khi đang refresh (isRefreshing = true)
- **Bonus**: Subtitle header phản ánh đúng state: loaded/error/loading

#### 3. _ErrorView upgrade (Stateful)
- **Root cause**: Stateless, nút "Thử lại" không có visual feedback
- **Fix**: Chuyển sang Stateful với `_retrying` state → spinner trong button + text "Đang kết nối..." + `FilledButton` full-width thay OutlinedButton nhỏ

#### 4. Tài Chính "Máy chủ không phản hồi" (ảnh 3)
- **Root cause**: `Future.wait()` không có timeout → phụ thuộc Dio timeout 60s nhưng không catch exception
- **Fix**: Thêm `.timeout(const Duration(seconds: 55))` + try-catch với error detection

#### 5. Review Queue mojibake (ảnh 4)
- **Root cause**: File được lưu với encoding Windows-1252 nhưng editor đọc UTF-8 → Dart string literals bị double-encode
- **Fix**: Rewrite hoàn toàn file với tất cả text UTF-8 thuần túy

#### 6. Thông báo empty (ảnh 1) — ĐÂY LÀ ĐÚNG
- **Phân tích**: Backend tạo notification với `userId = patient.userId` (bệnh nhân). Admin/Doctor login thì không có notification nào vì notification được gửi cho bệnh nhân
- **Kết luận**: Đây là thiết kế đúng theo nghiệp vụ. Notification là "inbox của bệnh nhân", không phải admin
- **Nếu muốn**: Cần tạo thêm "system notifications" cho admin (appointment count, daily summary) — đây là feature mới, không phải bug

### Phải nhớ buổi sau
- Timeout trong bloc phải ≤ Dio timeout (60s). Hiện set 55s để có 5s buffer cho Dio tự xử lý
- `Future.wait()` cần `.timeout()` riêng vì không inherit timeout từ Dio
- Khi dùng `state is SomeType ? state : null` thì Dart tự infer non-nullable type trong condition arm → không cần `!` hay `?.`
- Mojibake chỉ fix được bằng rewrite file, không paste qua editor

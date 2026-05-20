## [2026-05-19] UI Encoding Fix + Error State Upgrade

### Đã làm
- **Fix mojibake encoding** trong `clinic_shell.dart`:
  - Tab labels bị double-encoded UTF-8 (Lịch hẹn → Lịch hẹn, v.v.)
  - Bottom nav label `'Thông báo'` dùng để detect badge index cũng bị sai → badge không hiển thị đúng
- **Fix mojibake encoding** trong `notifications_screen.dart`:
  - `'Thông báo'` → `'Thông báo'`
  - `'Äã Ä'á»c tất cả'` → `'Đã đọc tất cả'`
  - `_relativeTime()` function cũng bị sai encoding
- **Fix mojibake encoding** trong `appointment_list_screen.dart`:
  - `'Có kết quả'` → `'Có kết quả'` (dùng Python byte-level replacement vì double-encoded)
  - `'âœ" Đã TT'` → `'✔ Đã TT'`
  - `'Hủy lịch'` → `'Hủy lịch'`
  - `'Chưa TT'` → `'Chưa TT'`
  - `'Thanh toán'` → `'Thanh toán'`
- **Upgrade Error State UI** — `clinic_appointments_screen.dart` và `admin_payment_screen.dart`:
  - `_ErrorView` đổi từ `StatelessWidget` → `StatefulWidget` với loading state khi retry
  - Smart messaging: phát hiện "server error" / "500" / "connect" → hiển thị "Backend đang khởi động (Render free tier ~30s)"
  - Button full-width `FilledButton` thay vì `OutlinedButton` — dễ nhìn hơn
  - Animated loading spinner trong button khi đang retry
- `flutter analyze` → `No issues found!`

### Vấn đề gặp phải & cách giải quyết
- **Double-encoded UTF-8**: Một số strings trong `appointment_list_screen.dart` bị encoding 2 lần (UTF-8 bytes bị đọc như Latin-1 rồi re-encode lại). PowerShell không xử lý được các byte đặc biệt → dùng Python script tạm thời để replace ở byte level
- **view_file tool hiển thị sai**: Tool hiển thị file với encoding sai → không thể copy-paste exact target content → phải dùng byte-level inspection
- Pattern matching trở nên phức tạp khi content bị corrupt ở tầng byte

### Còn dang dở
- Notification screen của PATIENT (non-clinic) nếu có cũng cần kiểm tra encoding
- Backend Render free tier cold start ~30s → đã thêm thông báo user-friendly nhưng chưa implement auto-retry sau N giây

### Phải nhớ buổi sau
- **KHÔNG dùng view_file để copy-paste strings bị mojibake** — tool hiển thị characters sai. Dùng PowerShell hex inspection hoặc Python
- **Double-encoded UTF-8 symptoms**: chars như `ó`, `¿`, `Å"`, `â€"` — đây là UTF-8 bytes bị đọc như Latin-1
- **clinic_shell.dart label matching**: `tabs.indexWhere((t) => t.label == 'Thông báo')` — label phải match CHÍNH XÁC với string trong `_tabs()`
- Smart error state pattern: detect `server/500/connect` in message → show Render cold-start explanation

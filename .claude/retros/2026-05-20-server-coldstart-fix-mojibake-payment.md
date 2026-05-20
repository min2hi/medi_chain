## [2026-05-20] Server Cold-Start Fix, Dashboard/Appointment Error State Upgrade, Mojibake Payment Screens

### Đã làm
- **Fix DashboardBloc**: `_onFetchRequested` và `_onRefreshRequested` thiếu timeout và try-catch → thêm `.timeout(55s)` + detect `timeout/connection/socket` → emit `'server_cold_start'` token
- **Fix AppointmentBloc**: tương tự DashboardBloc — cùng pattern timeout + smart error detection
- **Upgrade Dashboard Error UI**: tạo `_DashboardErrorView` StatefulWidget
  - Detect `server_cold_start` token → hiển thị "Backend đang khởi động (Render free tier ~30s)"
  - Auto-retry sau 10s khi cold-start
  - Icon `LucideIcons.serverCrash` thay `alertCircle` khi là cold-start
  - ElevatedButton teal full-width thay TextButton nhỏ
- **Upgrade Appointment Error UI**: detect `server_cold_start` token, icon server crash, button teal full-width
- **Fix Register button**: `disabledBackgroundColor: Color(0xFF93C5FD)` (xanh dương) → `Color(0xFF14B8A6).withOpacity(0.5)` (teal mờ) — đồng bộ design system
- **Fix Mojibake payment_success_screen.dart**: rewrite hoàn toàn UTF-8 (double-encoded nặng)
- **Fix Mojibake payment_webview_screen.dart**: rewrite hoàn toàn UTF-8 (double-encoded nặng)
- `flutter analyze` → `No issues found!`

### Vấn đề gặp phải & cách giải quyết
- **Root cause server error**: `UserRepository.getDashboard()` đã catch exception nội bộ và trả về `success: false` — nhưng DashboardBloc **không wrap thêm try-catch** và **không có timeout** → khi Render cold-start ~30s, Dio throw `DioException` nhưng repository catch → return generic message "Không thể tải dữ liệu dashboard" → bloc nhận `success=false` → emit error ngay
- **Pattern đúng**: Bloc phải wrap thêm try-catch độc lập với timeout riêng (55s) vì repository catch không re-throw
- **Dashboard _DashboardErrorView**: đặt ngoài `DashboardScreen` class (private widget ở file scope) vì nó cần `StatefulWidget` nhưng không thể là inner class của `StatelessWidget`

### Còn dang dở
- Nếu user có log backend từ Render → có thể biết chính xác endpoint nào đang fail (500 hay timeout)
- Backend `getStats()` dùng `Promise.all` với 8 Prisma queries — nếu DB cold start → tất cả fail cùng lúc
- Cần hỏi user về backend logs để debug sâu hơn nếu vẫn còn lỗi sau fix

### Phải nhớ buổi sau
- **Repository pattern catch thì Bloc phải thêm try-catch riêng** — catch trong repository không re-throw, bloc cần bảo vệ chính mình
- **Timeout 55s** cho tất cả bloc fetch (nhất quán với Dio 60s, 5s buffer)
- **Token `server_cold_start`**: UI check `message == 'server_cold_start'` để detect cold-start, không phải check chứa string
- **Mojibake rewrite**: 2 payment files đã sạch — không edit lại bằng view_file/copy-paste mà phải dùng write_to_file trực tiếp với UTF-8

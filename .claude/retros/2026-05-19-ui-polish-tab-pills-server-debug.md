## [2026-05-19] UI Polish — Tab Pills + Server Error Debug + Bottom Sheet UX

### Đã làm
- **Tab bar → Pill indicator**: Đổi `UnderlineTabIndicator` sang custom `_PillIndicator` (BoxPainter)
  - Dùng canvas drawRRect với alpha fill + border teal → capsule bo tròn đẹp
  - `isScrollable: false`, `tabAlignment: TabAlignment.fill` → tabs phân bố đều
  - `NoSplash.splashFactory` + `overlayColor: transparent` → không có ripple generic
  - Áp dụng cho cả `clinic_appointments_screen.dart` và `admin_payment_screen.dart`

- **appointment_detail_sheet.dart — Fix toàn bộ**:
  - Viết lại từ đầu để fix mojibake encoding (ó, Å", v.v.)
  - `isDismissible: true`, `barrierColor: Colors.black.withValues(alpha: 0.6)` → tap ngoài tự đóng
  - `snap: true, snapSizes: [0.6, 0.92]` → snap tự nhiên như ứng dụng lớn
  - Drag handle tap → `Navigator.pop(context)` → đóng sheet
  - `_StatusChip` borderRadius 20 thay vì 4 → pill style
  - `borderRadius: BorderRadius.circular(12)` → button bo tròn hơn

- **patient_detail_sheet.dart**:
  - Thêm `isDismissible: true`, `barrierColor`, `enableDrag: true`
  - Drag handle thêm GestureDetector → tap để đóng
  - Box shadow và borderRadius 24 → premium feel

- **Notification error state**:
  - `notification_bloc.dart`: detect timeout/socket error → emit `'server_cold_start'` thay vì generic 'Lỗi kết nối'
  - `notifications_screen.dart`: thêm `_buildErrorState()` với retry button full-width
  - Phân biệt cold-start vs network error

- **Root cause lỗi server**: Backend trên Render free tier — cold start ~30s khi không có traffic. Không phải code bug.

### Vấn đề gặp phải & cách giải quyết
- `Navigator.pop(_)` dùng builder context sai → phải capture `context` từ `build(BuildContext context)`
- `'${feeStr}đ'` lint warning `unnecessary_brace_in_string_interps` → đổi sang `'$feeStrđ'`
- `flutter analyze` chạy chậm (~93s) do download packages

### Còn dang dở
- Backend Render free tier: cần xem xét upgrade plan hoặc implement keepalive ping
- Auto-retry sau 30s khi cold-start chưa implement (chỉ mới có manual retry)

### Phải nhớ buổi sau
- **_PillIndicator pattern**: Dùng `Decoration` + `BoxPainter` → paint canvas → không phụ thuộc vào TabBar internal
- **Bottom sheet dismiss**: `isDismissible: true` là default của Flutter nhưng cần `barrierColor` đặt đúng để overlay tối đẹp
- **Render cold start**: timeout → catch → emit error. Cần detect `msg.contains('timeout')` chứ không phải check `response.success`
- **mojibake**: View_file tool hiển thị sai encoding → không copy-paste, phải viết lại toàn bộ file

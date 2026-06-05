## [2026-05-13] Admin Portal UI Redesign — Design System + Component Library

### Đã làm
- Thêm `AdminColors` class vào `app_theme.dart` — 45 design tokens thay thế toàn bộ hardcode hex
- Tạo `lib/presentation/widgets/admin/` với 5 shared widgets:
  - `admin_pressable_card.dart` — scale 0.97 + haptic + accent border khi nhấn
  - `admin_app_bar.dart` — AppBar chuẩn thay thế 7 lần viết lại
  - `admin_badge.dart` — Status badge với 8 type (pending/approved/rejected/roles...)
  - `admin_section_header.dart` — Label + optional icon + count badge
  - `admin_empty_state.dart` — EmptyState + ErrorState chuẩn
- Rebuild `admin_dashboard_screen.dart`:
  - Gradient header (navy → indigo) kiểu Linear — user avatar + role badge
  - KPI stats: AnimatedSwitcher skeleton loading + highlight khi có pending
  - Navigation cards dùng `AdminPressableCard` + `AdminSectionHeader`
- Rebuild `review_queue_screen.dart`:
  - Swipe-to-approve (→) / swipe-to-reject (←) với `Dismissible` built-in
  - AI confidence: `LinearProgressIndicator` với màu theo ngưỡng (green/amber/red)
  - Swipe hint banner tự hiện khi có items
- Apply shared components cho 5 screens còn lại:
  users, telemetry, keywords, combos, access_logs
- `flutter analyze` → `No issues found!`

### Vấn đề gặp phải & cách giải quyết
- Edit bị merge sai → old `_buildAppBar` method kẹt trong builder closure của users_screen → fix thủ công bằng cách xác định đúng range rồi replace
- `_Chip` widget cần rename thành `_buildStatChip` vì lint coi method name bắt đầu bằng underscore như local variable
- `(_, __)` trong separatorBuilder bị flag `unnecessary_underscores` → đổi thành `(_, _)`

### Còn dang dở
- Không có gì dang dở — tất cả 7 screens + 5 widgets + 1 theme đã hoàn thành và analyze clean

### Phải nhớ buổi sau
- `AdminColors` là single source of truth — KHÔNG hardcode `Color(0xFF...)` trong bất kỳ admin screen nào
- Widget library nằm tại `lib/presentation/widgets/admin/` — check trước khi tạo widget mới
- `AdminPressableCard` thay thế mọi GestureDetector card trong admin portal
- Swipe action dùng `Dismissible` (built-in, zero dependency) — KHÔNG thêm `flutter_slidable`
- Dashboard dùng `ListView` bình thường (KHÔNG dùng `CustomScrollView`) để đơn giản hóa layout

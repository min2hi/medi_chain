## [2026-05-25] UI Upgrade — Design System Foundation + Patient Portal High-Impact

### Đã làm
- **Phase 1 — Design System Foundation:**
  - Mở rộng `AppTheme` với semantic colors: `kSuccess`, `kWarning`, `kDanger`, `kPrimaryLight`, surface tints (`kSuccessSurface`, `kWarningSurface`, `kDangerSurface`, `kInfoSurface`)
  - Tạo `AppSpacing`, `AppRadius`, `AppShadow` constants (8-point grid, 3-level elevation)
  - Tạo `StatusBadge` shared widget — pill-shaped, color-coded, với `urgencyColor()` và `fromMedicineEnd()` helpers
  - Tạo `AppCard` shared widget — unified card với left accent bar, InkWell ripple, dark mode, AppShadow

- **Phase 2 — Dashboard widgets:**
  - `AlertSection`: 3 red banners → compact amber pills, dismiss-able, max 2 hiện, type-specific icons
  - `QuickActions`: horizontal scroll → 4-item 2×2 icon grid, color-coded per action, press-scale animation
  - `HealthOverviewCard`: priority waterfall hero metric (appointment → vitals → medicine count), compact info rows

- **Phase 2 — List screens:**
  - `medicine_list_screen.dart`: urgency-aware card (teal/amber/red/gray bar), `_DaysBar` progress, `StatusBadge`, pill icon với tinted bg, expired cards strikethrough
  - `records_list_screen.dart`: icon system per type (stethoscope/flask/file/hotel/syringe), type label chip, AppTheme tokens throughout
  - `appointment_list_screen.dart`: `StatusBadge` unified, AppTheme accent colors

### Vấn đề gặp phải & cách giải quyết
- `_buildBadge` unused warning sau khi migrate sang StatusBadge → đã xóa
- Overwrite thay vì edit khi TargetContent trống (records_list_screen) → dùng `Overwrite: true`

### Còn dang dở
- Doctor portal screens (clinic_patients, clinic_appointments) chưa upgrade
- Admin portal sparkline charts chưa làm
- Settings profile hero redesign chưa làm
- Bottom nav polish chưa làm

### Phải nhớ buổi sau
- `StatusBadge.urgencyColor(endDate)` và `StatusBadge.fromMedicineEnd(endDate)` là helpers tái dùng cho bất kỳ screen nào có medicine expiry
- `AppCard` widget ở `lib/presentation/widgets/shared/app_card.dart` — dùng thay cho mọi Container decoration pattern
- `AppSpacing`, `AppRadius`, `AppShadow` đã có trong `app_theme.dart` — KHÔNG hardcode giá trị số nữa
- Design philosophy: urgency bar color → teal (>7d), amber (3-7d), red (<3d), gray (expired)

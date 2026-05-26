## [2026-05-25] Mobile QA Audit — Final Pass

### Đã làm
- Fix tất cả GestureDetector → Material+InkWell trên toàn codebase
- Giữ GestureDetector hợp lý: ai_hub_screen (press-scale), keywords_screen (custom toggle), ht_checkin_sheet (press-scale)
- Fix pre-existing bugs: dashboard_screen `_showAlertsSheet` bracket structure, `(_, _)` wildcard  
- Thêm `AdminColors.darkSurface/darkBg/darkBorder` aliases vào app_theme.dart
- Xóa duplicate local `AdminColors` class trong appointment_detail_sheet.dart
- Fix app_router.dart ambiguous_import với `show ReviewQueueScreen`
- Fix review_queue_screen.dart GestureDetector → Material+InkWell (expandable panel)
- Fix register_screen.dart GestureDetector text link → InkWell
- Thêm staggered entrance animation (FadeTransition + SlideTransition, easeOutCubic) vào:
  - health_metrics_screen.dart — `_StaggeredItem` (index*60ms delay, max 300ms)
  - health_timeline_screen.dart — `_StaggeredTimelineItem` (index*50ms delay, max 250ms)
- flutter analyze: **No issues found!**

### Vấn đề gặp phải & cách giải quyết
- review_queue_screen.dart bị corrupt khi recreate bằng PowerShell Get-Content -Raw → WriteAllText (newline scramble). Fix: git checkout HEAD để restore
- Dart analyzer báo `uri_does_not_exist` cho review_queue_screen khi analyze full project dù file tồn tại → do stale Dart analyzer cache + namespace collision. Fix: thêm `show ReviewQueueScreen` vào import directive
- dashboard_screen.dart `_showAlertsSheet` có 2 pre-existing bugs: `(_, _)` duplicate wildcard và thiếu closing bracket cho builder body. Fix: `(_, _)` valid trong Dart 3+, thêm `},` để đóng builder

### Còn dang dở
- Scan Colors.white/black trong Admin screens (intentional, không phải AI-slop)
- Không cần thêm animation vào Admin portal — Admin là data-dense UI, motion ít hơn

### Phải nhớ buổi sau
- PowerShell Get-Content -Raw + WriteAllText có thể scramble file content với Vietnamese chars (multibyte). Luôn dùng git checkout hoặc write_to_file tool
- `(_, _)` trong Dart 3+ là valid wildcard — KHÔNG cần đổi thành `(_, __)`
- `show ClassName` trong import directive để prevent namespace pollution khi file có nhiều imports
- Staggered animation pattern: `index * 60ms` capped at `300ms`, duration `380ms`, curve `easeOutCubic` + `easeOut`

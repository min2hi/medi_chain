# [2026-05-11] Architecture Gap Remediation — 6 Gaps Fixed

## Đã làm

### Commit 1 — G1: Fix DOCTOR router guard (Critical)
- File: `frontend-mobile/lib/presentation/routes/app_router.dart`
- Thay `role != 'ADMIN'` → `role != 'ADMIN' && role != 'DOCTOR'`
- 3 dòng thay đổi, tác động lớn nhất: DOCTOR giờ có thể vào Admin Portal

### Commit 2 — G6: Wire Disease Predictor vào AI pipeline
- File: `backend/src/services/ai.service.ts`
- Import `DiseasePredictorService`, inject vào `getMedicineRecommendation()` sau safety check
- Babylon Health fail-open pattern: `Promise.race` 3s timeout → nếu timeout/lỗi → predictedDiseases = []
- Inject disease context vào system prompt (chỉ khi có kết quả)

### Commit 3 — G3 + G4: Admin Stats + Review Context
- [Backend] NEW: `admin-stats.controller.ts` — parallel Prisma queries, 60s in-memory cache
- [Backend] NEW: `admin-stats.routes.ts` + mount trong `index.ts`
- [Backend] G4 Fix: `_queuePendingKeyword()` enrich `changeNote` với trigger text `[AUTO]` format
- [Flutter] `admin_dashboard_screen.dart` — thêm `_AdminStatsRow` widget + `_fetchStats()` method
  - 4 KPI chips: Users, Pending Review (highlight amber nếu > 0), AI/24h, Blocked/24h
- [Flutter] `review_queue_screen.dart` — thêm `_TriggerContextBox` widget
  - Expandable amber box hiển thị trigger text gốc + score + matched keyword
- [Flutter] `admin_models.dart` — thêm `changeNote` field + cải thiện `fromJson` fallback logic

### Commit 4 — G2 + G5: UX Discovery + Audit Export
- G2: `settings_screen.dart` — mở rộng `isAdmin` cho DOCTOR
- G5: `access_logs_screen.dart` — date picker trong AppBar (Epic Systems pattern)
- G5: CSV export via `Clipboard.setData` (zero dependencies, no share_plus needed)
- G5: Export button hiển thị khi có data, copy clipboard ngay lập tức

## Vấn đề gặp phải & cách giải quyết

1. **G2 (quick_actions.dart)**: Đọc file phát hiện tiles "Chỉ số mới" và "Chia sẻ" đã có sẵn → không cần thêm, chỉ cần fix discoverability từ Settings
2. **G5 (share_plus)**: `share_plus` không có trong pubspec.yaml → dùng `Clipboard.setData` thay thế — zero dependency, instant UX, user paste sang Google Sheets
3. **LoadAccessLogs date type**: Nhận `String?` (YYYY-MM-DD) không phải `DateTime` → format manual trước khi dispatch
4. **_queuePendingKeyword signature**: Thêm optional `triggerText?` parameter để backward compatible với caller
5. **Flutter analyze exit code 1 lần đầu**: Do package resolution warnings, không phải lỗi thật — lần analyze thứ 2 clear

## Còn dang dở

- **G5 full backend support**: Hiện tại date picker chỉ filter từ backend nếu `getApiAccessLogs(date: str)` support. Check admin_repository.dart để đảm bảo date param được truyền đúng xuống HTTP call
- **Admin Stats integration test**: Chưa có test end-to-end cho `/api/admin/stats` endpoint
- **G4 Backend changeNote migration**: Keyword cũ trong DB sẽ không có `[AUTO]` prefix → `_TriggerContextBox` chỉ show cho keywords mới (correct behavior — đúng ý định)

## Phải nhớ buổi sau

- **DOCTOR = ADMIN scope** đã được confirm: Full access, không phải read-only (ADR nên được tạo nếu project escalate)
- **[AUTO] changeNote format**: Flutter parse prefix `[AUTO]` để detect trigger context — không thay đổi format này
- **Admin Stats 60s cache**: Single-instance in-memory. Khi scale multi-instance → swap sang Redis (code đã có comment hướng dẫn)
- **Disease Predictor fail-open 3s**: Timeout này calibrate cho Gemini embedding latency. Nếu model chậm hơn → có thể tăng lên 5s
- **flutter analyze "No issues"**: Cần verify sau mỗi Flutter change vì analyzer detect type issues tốt
- **TypeScript clean**: `tsc --noEmit` → 0 errors sau tất cả backend changes

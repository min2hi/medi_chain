# MEMORY.md — Project Knowledge Index

> File này lưu lại CÁC QUYẾT ĐỊNH ĐÃ CHỐT của dự án.
> AI phải đọc file này vào đầu mỗi buổi làm việc.
> Cập nhật mỗi khi có quyết định kỹ thuật mới.

---

## Tech Stack

- **Frontend Web:** Next.js 14 App Router + TypeScript
- **Mobile:** Flutter + BLoC pattern + GoRouter
- **Backend:** Node.js + Express + Prisma + PostgreSQL
- **AI/LLM:** Google Gemini API
- **Deploy:** Render (backend), Firebase (mobile)

---

## Các Quyết Định Đã Chốt

| Ngày | Quyết định | Lý do |
|------|-----------|-------|
| 2026-05-20 | Dùng BLoC (flutter_bloc) cho mobile state | Separation of concerns, testable, scale tốt |
| 2026-05-20 | GoRouter cho mobile navigation | Declarative, deep-link support, type-safe |
| 2026-05-20 | getIt (service locator) cho dependency injection | Không cần InheritedWidget phức tạp |
| 2026-05-26 | AppTheme tập trung hóa toàn bộ design tokens | Một thay đổi propagate toàn app, dark mode nhất quán |
| 2026-05-26 | ValueNotifier trigger thay vì bool flag cho IndexedStack | Bool chỉ đọc 1 lần trong initState, không hoạt động khi screen đã mount |
| 2026-05-26 | Xóa route /appointment-new, dùng context.go('/') + extra | Route cũ tạo screen ngoài IndexedStack, không share BLoC state |
| 2026-05-26 | Atomic commits theo dependency order (foundation → feature → cleanup) | Dễ revert, dễ review, git bisect hoạt động đúng |

---

## Vùng Code Nhạy Cảm — Phải Cẩn Thận

| File / Module | Tại sao nhạy cảm |
|---------------|-----------------|
| `lib/presentation/screens/home/home_screen.dart` | IndexedStack + ValueNotifier trigger — sửa sai sẽ break Quick Actions |
| `lib/presentation/routes/app_router.dart` | Routing toàn app — thêm/xóa route ảnh hưởng navigation |
| `lib/core/theme/app_theme.dart` | Design token foundation — thay đổi ảnh hưởng toàn bộ UI |
| `lib/core/di/injection.dart` | Dependency injection setup — sai là crash khi launch |
| `backend/src/middleware/auth.middleware.ts` | Xác thực toàn bộ API — sai là security hole |
| `backend/prisma/schema.prisma` | Database schema — migration sai là mất data |

---

## Design System — AppTheme Tokens

```dart
// Màu chính
AppTheme.kPrimary        // teal #14B8A6
AppTheme.kPrimaryDark    // teal đậm #0F766E
AppTheme.kPrimaryLight   // teal nhạt (background icon)

// Typography
AppTheme.kTextPrimary    // text chính (light mode)
AppTheme.kTextSecondary  // text phụ
AppTheme.kTextMuted      // placeholder, hint

// Semantic
AppTheme.kDanger         // đỏ lỗi
AppTheme.kWarning        // vàng cảnh báo

// Dark mode surfaces (hardcode vì cần precision)
// Card: Color(0xFF182030)
// Background: Color(0xFF0D1520)
// Elevated: Color(0xFF1E2C3D)
// Border: Color(0xFF2A3A50)
```

---

## Flutter Patterns Đã Dùng

### ValueNotifier Dialog Trigger (IndexedStack)
```dart
// HomeScreen owns the notifier:
final _openDialogNotifier = ValueNotifier<int>(0);

// Trigger from didUpdateWidget:
_openDialogNotifier.value++;

// Screen listens:
widget.openDialogTrigger?.addListener(_onDialogTrigger);
void _onDialogTrigger() => if (mounted) _showDialog(context);

// ALWAYS dispose:
widget.openDialogTrigger?.removeListener(_onDialogTrigger);
```

### Shared Widget Library
```
lib/presentation/widgets/shared/
├── app_card.dart           ← Card container chuẩn
├── section_header.dart     ← Section title + trailing action
├── staggered_list_item.dart ← Fade+slide animation wrapper
└── status_badge.dart       ← Badge 5 variants
```

---

## Quy Tắc An Toàn Khi Sửa File

1. **Verify ngay** sau mỗi lần edit: `flutter analyze lib/path/file.dart`
2. **File bị corrupt** → `git checkout HEAD -- file.dart` → rewrite sạch
3. **Không patch** lên file đã bị broken (cascade failure)
4. **Kiểm tra diff output** sau multi_replace — nếu thấy "inaccuracies" → dừng ngay
5. **Commit ngay** sau mỗi feature hoàn chỉnh — không để > 15 files uncommitted

---

## Blockers & Vấn Đề Đang Mở

- 52 packages có version mới không compatible với constraints hiện tại (`flutter pub outdated`)
- Backend .env chưa được commit (đúng — nằm trong .gitignore)
- Backend generated Prisma client có thay đổi chưa commit (cần commit riêng ở backend)

---

*Cập nhật lần cuối: 2026-05-26*

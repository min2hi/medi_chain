# ADR-007: Google Fonts — Inter Font cho Flutter Mobile

## Status
Accepted — 2026-04-22

## Context

Web frontend (`globals.css`) đã dùng font **Inter** từ Google Fonts từ đầu dự án.  
Flutter mobile đang dùng Roboto mặc định của Material Design.

Điều này tạo ra sự không nhất quán visual giữa 2 platform:
- Web: Inter (geometry sans-serif, weight 300–700)
- Mobile: Roboto (system font, khác về spacing và rendering)

Khi user chuyển qua lại giữa web và mobile, trải nghiệm cảm thấy như 2 sản phẩm khác nhau dù cùng design system màu sắc.

## Options Considered

### Option A — Download `.ttf` thủ công vào `assets/fonts/`
- **Pro:** 100% offline, không phụ thuộc network, bundle size predictable
- **Con:** 5 file font (~2MB), phải quản lý version manually, thêm phức tạp vào pubspec

### Option B — `google_fonts` package (đã chọn)
- **Pro:** Caching tự động sau lần đầu, cập nhật font dễ, developer experience tốt
- **Con:** Lần đầu mở app cần mạng để tải font

### Option C — Giữ Roboto mặc định
- **Pro:** Zero cost
- **Con:** Không đồng bộ với web, cảm giác khác nhau giữa 2 platform

## Decision

Chọn **Option B** (`google_fonts` package) với cấu hình offline-safe:

```dart
// main.dart — Tắt runtime fetching sau lần đầu cache
GoogleFonts.config.allowRuntimeFetching = false;
```

- Font được cache trên device sau lần tải đầu tiên.
- Offline users không bị crash — Flutter sẽ fallback về font mặc định.
- Apply toàn cục qua `AppTheme.lightTheme` dùng `GoogleFonts.interTextTheme()`.

## Consequences

- **Positive:** Cross-platform visual consistency — web và mobile cùng Inter.
- **Positive:** `AppTheme` là single source of truth cho font.
- **Negative:** Lần đầu mở app phải có mạng để tải font (~100KB).
- **Mitigation:** `allowRuntimeFetching = false` sau lần đầu, cache permanent.

## References
- [google_fonts pub.dev](https://pub.dev/packages/google_fonts)
- `frontend-mobile/pubspec.yaml` — dependency `google_fonts: ^6.3.3`
- `frontend-mobile/lib/core/theme/app_theme.dart` — implementation
- Web: `frontend/src/app/globals.css` — `@import url('Inter')` reference

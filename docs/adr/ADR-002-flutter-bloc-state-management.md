# ADR-002: Chọn BLoC Pattern cho Flutter Mobile thay vì Riverpod / Provider

**Ngày:** 2026-04-01  
**Trạng thái:** Accepted  
**Người quyết định:** MediChain Team

---

## Bối cảnh (Context)

MediChain có ứng dụng Flutter mobile cần quản lý state phức tạp:
- Auth state (login, logout, token refresh)
- Medical records state (loading, pagination, CRUD)
- AI Chat state (streaming messages, history)
- Health metrics state (real-time updates)

Cần chọn một state management solution phù hợp cho team có kinh nghiệm Flutter vừa phải.

## Các lựa chọn đã cân nhắc (Options Considered)

### Lựa chọn A: BLoC (Business Logic Component)
- **Ưu:**
  - Separation of concerns rõ ràng: Event → BLoC → State
  - Testable cao — BLoC là pure Dart class, không phụ thuộc UI
  - `flutter_bloc` package mature, stable, được Google recommend
  - Pattern nhất quán cho toàn bộ team
  - Dễ debug với BlocObserver (log toàn bộ event/state transitions)
- **Nhược:**
  - Boilerplate nhiều hơn (3 file: event, state, bloc cho mỗi feature)
  - Học curve cao hơn so với Provider

### Lựa chọn B: Riverpod
- **Ưu:** Ít boilerplate hơn BLoC, type-safe, compile-time check
- **Nhược:**
  - Còn tương đối mới, API thay đổi nhiều giữa các version lớn
  - Team chưa có kinh nghiệm, ít tài liệu tiếng Việt

### Lựa chọn C: Provider (built-in)
- **Ưu:** Đơn giản, ít code nhất
- **Nhược:**
  - Không scale tốt khi app phức tạp
  - Khó test, khó debug khi state lồng nhau nhiều

### Lựa chọn D: GetX
- **Ưu:** Ít code nhất, tất cả trong 1 package
- **Nhược:**
  - Anti-pattern: trộn lẫn routing, state, DI → khó maintain
  - Không được Flutter team khuyến khích
  - Khó test

## Quyết định (Decision)

**Chọn:** Lựa chọn A — BLoC Pattern

**Lý do chính:**
1. Testability: Medical app cần unit test nghiêm túc — BLoC dễ test nhất
2. Predictability: Mỗi state transition đều explicit, không có "magic"
3. Scale: Pattern nhất quán khi thêm nhiều feature

## Hệ quả (Consequences)

### Tích cực
- Mỗi feature có cấu trúc chuẩn → onboard member mới nhanh
- BlocObserver log toàn bộ state transitions → debug dễ
- Unit test BLoC độc lập với UI

### Tiêu cực / Trade-off
- Mỗi feature cần tạo 3 file (event, state, bloc) → nhiều file hơn
- Cần discipline để không viết business logic trong Widget

### Rủi ro cần theo dõi
- Nếu team scale lên và cần ít boilerplate hơn → cân nhắc migrate sang Riverpod sau

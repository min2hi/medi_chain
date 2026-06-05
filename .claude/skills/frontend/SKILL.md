# SKILL: Frontend & Mobile Development — MediChain

> Đọc file này khi làm việc với `frontend/` hoặc `frontend-mobile/`.

---

## PHẦN 1: NEXT.JS WEB (frontend/)

### App Router — Cấu Trúc Bắt Buộc

```
frontend/src/
├── app/           ← Next.js 14 App Router (pages, layouts, loading, error)
├── components/    ← Reusable UI components
├── services/      ← API calls (PHẢI dùng api.client.ts)
├── hooks/         ← Custom React hooks
├── types/         ← TypeScript interfaces & types
├── lib/           ← Utilities, helpers
└── actions/       ← Next.js Server Actions (nếu có)
```

> ⚠️ MediChain dùng **App Router**, KHÔNG dùng Pages Router.  
> Mọi page mới tạo trong `app/`, KHÔNG trong `pages/`.

### API Call Pattern — BẮT BUỘC dùng api.client.ts

```typescript
// ✅ ĐÚNG — Luôn import từ api.client.ts
import { MedicinesApi, AIApi } from '@/services/api.client';

const result = await MedicinesApi.list();
if (!result.success) {
    console.error(result.message);
    return;
}
// Dùng result.data

// ❌ SAI — KHÔNG gọi fetch trực tiếp từ component
const res = await fetch('http://localhost:5000/api/user/medicines'); // ← Sai
```

### API Client đã có sẵn — Dùng lại, KHÔNG tạo mới

| API Object | Chức năng |
|-----------|-----------|
| `ProfileApi` | Profile, Dashboard |
| `RecordsApi` | Hồ sơ bệnh án |
| `MedicinesApi` | Quản lý thuốc |
| `AppointmentsApi` | Lịch hẹn |
| `MetricsApi` | Chỉ số sức khỏe |
| `AIApi` | Chat AI, conversations |
| `RecommendationApi` | Tư vấn thuốc, feedback |

### Error Handling ở Frontend

```typescript
// Response luôn có format: { success, data?, message?, errorCode? }
const result = await AIApi.chat(message);

if (!result.success) {
    if (result.errorCode === 'CLIENT_TIMEOUT') {
        // Xử lý timeout riêng
    } else if (result.errorCode === 'AUTH_EXPIRED') {
        // api.client.ts tự động redirect về /auth/login
    } else {
        toast.error(result.message);
    }
    return;
}
```

### Auth Token Storage (Web)

```typescript
// Token lưu trong localStorage
localStorage.getItem('token')
localStorage.getItem('user')

// api.client.ts TỰ ĐỘNG đính kèm token vào mọi request
// KHÔNG cần thêm Authorization header thủ công
```

---

## PHẦN 2: FLUTTER MOBILE (frontend-mobile/)

### BLoC Pattern — Cấu Trúc Bắt Buộc

```
frontend-mobile/lib/
├── core/           ← Constants, utils, theme, secure storage
├── data/
│   ├── models/     ← Data classes (fromJson, toJson)
│   └── repositories/ ← API calls + data transformation
├── logic/          ← BLoC files (events, states, bloc)
│   ├── auth/       → auth_event.dart, auth_state.dart, auth_bloc.dart
│   ├── medical/    → ...
│   └── ...
└── presentation/
    ├── screens/    ← Full page screens
    └── widgets/    ← Reusable UI components
```

### BLoC Pattern — Phân tách rõ ràng

```dart
// ✅ ĐÚNG — 3 file tách biệt trong mỗi feature folder
// auth_event.dart  → abstract class AuthEvent {}
// auth_state.dart  → abstract class AuthState {}
// auth_bloc.dart   → class AuthBloc extends Bloc<AuthEvent, AuthState>

// ✅ ĐÚNG — Bloc xử lý logic
on<LoginRequested>((event, emit) async {
    emit(AuthLoading());
    final response = await _repository.login(event.email, event.password);
    if (response.success) {
        emit(Authenticated(response.data!.user));
    } else {
        emit(AuthError(response.message ?? 'Đăng nhập thất bại'));
    }
});

// ❌ SAI — KHÔNG viết business logic trực tiếp trong Widget/Screen
class LoginScreen extends StatelessWidget {
    void _login() async {
        final res = await http.post(...); // ← Sai: logic trong UI
    }
}
```

### Repository Pattern (Mobile)

```dart
// Repository là cầu nối giữa BLoC và API
// KHÔNG gọi http trực tiếp từ BLoC — phải qua Repository

class AuthRepository {
    Future<ApiResponse<AuthData>> login(String email, String password) async {
        // Gọi API, parse response, return typed result
    }
}
```

### Secure Storage (Mobile)

```dart
// ✅ ĐÚNG — Token lưu trong SecureStorageService (flutter_secure_storage)
await _storage.saveToken(token);
final token = await _storage.getToken();

// ❌ SAI — KHÔNG dùng SharedPreferences hay biến in-memory cho token
SharedPreferences.getInstance().then((prefs) => prefs.setString('token', token));
```

### Mobile Kết Nối Backend

```dart
// Android Emulator: http://10.0.2.2:5000/api
// iOS Simulator:    http://localhost:5000/api
// Physical device:  http://<LAN_IP>:5000/api
// Production:       https://api.medichain.app/api

// Cấu hình trong: frontend-mobile/lib/core/constants/app_constants.dart
```

## Always Do ✅

**Next.js:**
- Dùng `'use client'` cho components cần state/hooks
- Dùng Server Components (mặc định) cho static/data-fetching pages
- Tạo `loading.tsx` và `error.tsx` kèm mọi route mới

**Flutter:**
- Luôn có State: Loading → Success/Error pattern trong mọi BLoC
- Dùng `BlocProvider` để inject BLoC, `BlocBuilder` để render UI
- Mọi API model phải có `fromJson` factory constructor

## Never Do ❌

**Next.js:**
- KHÔNG dùng `pages/` directory (dự án dùng App Router)
- KHÔNG hardcode `localhost:5000` — dùng `NEXT_PUBLIC_API_URL`
- KHÔNG duplicate type definitions — kiểm tra `src/types/` trước

**Flutter:**
- KHÔNG dùng `setState` cho global state — dùng BLoC
- KHÔNG gọi API trực tiếp từ Widget — phải qua BLoC → Repository
- KHÔNG import `dart:io` cho web builds

---

## PHẦN 3: QUY TẮC CHỈNH SỬA FILE AN TOÀN (Flutter)

> Học từ thực tế: patch sai → file corrupt → cascade failure.
> Đây là quy trình BẮT BUỘC khi sửa bất kỳ `.dart` file nào.

### Rule 1 — Verify sau MỖI lần sửa (không tích lũy)

```bash
# Sau mỗi lần edit 1 file → chạy ngay:
flutter analyze lib/path/to/changed_file.dart

# Không chờ sửa 5-10 file rồi mới analyze
# Mỗi lần analyze phải return: "No issues found!"
```

### Rule 2 — File bị corrupt → Reset ngay, KHÔNG patch thêm

```bash
# Phát hiện file bị broken (syntax error, cascade lỗi):

# Bước 1: Reset file về bản sạch cuối cùng
git checkout HEAD -- lib/path/to/broken_file.dart

# Bước 2: Hiểu rõ TOÀN BỘ thay đổi cần làm
# Bước 3: Apply đúng 1 lần duy nhất với write_to_file (full rewrite)
# Bước 4: flutter analyze ngay lập tức
```

> ❌ KHÔNG được: patch thêm lên file đã bị lỗi  
> ❌ KHÔNG được: dùng multi_replace trên file đã corrupt  
> ✅ PHẢI: reset → hiểu rõ → rewrite sạch → verify

### Rule 3 — Chọn đúng tool khi edit

| Tình huống | Tool đúng |
|-----------|----------|
| Sửa 1 đoạn liên tục | `replace_file_content` |
| Sửa nhiều đoạn không liền nhau | `multi_replace_file_content` |
| File bị corrupt / cần thay đổi lớn | `write_to_file` (Overwrite: true) — full rewrite |
| Không chắc file còn nguyên vẹn | `view_file` toàn bộ trước, kiểm tra cấu trúc |

> ⚠️ `multi_replace_file_content` CÓ THỂ apply sai vị trí nếu file đã bị lỗi.
> Luôn kiểm tra diff output sau khi tool chạy xong.

### Rule 4 — Luôn kiểm tra cấu trúc file trước khi patch

```bash
# Trước khi multi_replace → xem toàn bộ file để biết chính xác số dòng
view_file(StartLine: 1, EndLine: 50)  # header
view_file(StartLine: <vùng cần sửa>)  # target area
view_file(StartLine: <cuối file>)     # kiểm tra không có rác ở cuối
```

### Rule 5 — Nếu thấy "inaccuracies" trong tool output → DỪNG NGAY

> Khi tool báo: "applied with inaccuracies" hoặc diff khác với intent  
> → Dừng lại, view_file để kiểm tra thực trạng  
> → Nếu file đã sai → git checkout reset, không tiếp tục patch

---

## PHẦN 4: FLUTTER STATE PATTERNS ĐÃ DÙNG TRONG DỰ ÁN

### ValueNotifier trigger pattern — cho IndexedStack dialog

> Vấn đề: `bool openAddDialog` chỉ được đọc 1 lần trong `initState`.
> Nếu Screen đã mount trong IndexedStack, bool thay đổi không trigger lại.

```dart
// ✅ ĐÚNG — ValueNotifier<int> counter pattern
// HomeScreen tạo notifier:
final _openDialogNotifier = ValueNotifier<int>(0);

// Khi muốn trigger:
_openDialogNotifier.value++;  // tăng counter → listener được gọi

// Screen lắng nghe trong initState:
widget.openDialogTrigger?.addListener(_onDialogTrigger);

void _onDialogTrigger() {
  if (mounted) _showDialog(context);
}

// Dispose bắt buộc:
@override
void dispose() {
  widget.openDialogTrigger?.removeListener(_onDialogTrigger);
  super.dispose();
}

// ❌ SAI — bool flag không hoạt động với IndexedStack
AppointmentListScreen(openAddDialog: true)  // chỉ đọc lần đầu
```

### didUpdateWidget — xử lý props thay đổi

```dart
@override
void didUpdateWidget(MyWidget old) {
  super.didUpdateWidget(old);
  // So sánh old.prop với widget.prop để detect change
  if (widget.openAddDialog && !old.openAddDialog) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _doSomething();
    });
  }
}
```

---

## PHẦN 5: APPTHEME DESIGN TOKENS (MediChain)

> Mọi màu sắc PHẢI dùng token từ `AppTheme`. KHÔNG hardcode `Color(0xFF...)` trong widget.

```dart
// ✅ ĐÚNG — dùng tokens
color: AppTheme.kPrimary           // teal chính
color: AppTheme.kPrimaryDark       // teal đậm
color: AppTheme.kPrimaryLight      // teal nhạt (background icon)
color: AppTheme.kTextPrimary       // text chính (light mode)
color: AppTheme.kTextSecondary     // text phụ
color: AppTheme.kTextMuted         // placeholder, hint
color: AppTheme.kDanger            // đỏ lỗi
color: AppTheme.kWarning           // vàng cảnh báo

// Dark mode — check trước khi dùng hardcode:
final isDark = Theme.of(context).brightness == Brightness.dark;
color: isDark ? const Color(0xFF182030) : Colors.white  // surface card

// ❌ SAI
color: const Color(0xFF0F766E)  // hardcode, không sync với theme
```

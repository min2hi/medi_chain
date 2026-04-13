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

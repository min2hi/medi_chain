---
name: flutter-dart-rules
description: >
  Core Flutter & Dart coding standards for MediChain mobile (frontend-mobile/).
  Enforces widget composition, BLoC state management, Clean Architecture, and
  Dart language best practices. Use when writing any Dart code in the mobile app.
---

# Flutter & Dart Development Rules — MediChain

> Adapted from agentpedia.codes Flutter & Dart Development rule +
> MediChain-specific architectural constraints.

---

## Core Principles

- **Everything is a Widget** — Compose small, focused widgets
- **Composition over inheritance** — Favor widget composition
- **Declarative UI** — UI = f(state), never imperative mutations
- **State management is BLoC** — No setState for business logic
- **Hot Reload friendly** — Keep build() methods pure and fast

---

## Dart Language

```dart
// ✅ Strong typing — ALWAYS type everything
List<AppointmentModel> appointments = [];   // NOT var
Map<String, dynamic> get toJson => {...};   // Return type explicit

// ✅ Null safety — handle nulls at boundaries
final String name = user?.name ?? 'Bệnh nhân'; // NOT user!.name

// ✅ const constructors — reduces rebuilds
const SizedBox(height: 16);
const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

// ✅ Named parameters for readability
AppCard(
  padding: EdgeInsets.all(AppSpacing.md),
  onTap: _onCardTap,
  child: content,
)

// ✅ Extension methods for clean code
extension StringExtension on String {
  String get capitalizeFirst =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// ❌ NEVER use dynamic unless absolutely necessary
dynamic data = response['data']; // ← Always parse to typed model
```

---

## Widget Architecture

```dart
// ✅ StatelessWidget by default
// Use StatefulWidget ONLY when local ephemeral UI state needed
// (e.g., text field focus, animation controller)

// ✅ Extract widgets instead of nesting
// BAD:
Column(children: [
  Container(
    decoration: ...,
    child: Row(children: [
      Icon(...),
      Column(children: [
        Text(title),
        Text(subtitle),
      ]),
    ]),
  ),
])

// GOOD:
Column(children: [
  _DoctorCard(doctor: doctor),
])

class _DoctorCard extends StatelessWidget { ... }

// ✅ Private widgets (underscore prefix) for screen-specific widgets
// ✅ Public widgets in lib/presentation/widgets/ for reusable ones

// ✅ const keyword on widgets that don't depend on runtime data
const AppHeader(title: 'Lịch hẹn'),
```

---

## BLoC Rules (MediChain specific)

```dart
// ✅ Event naming: verb + noun
class LoadAppointments extends AppointmentEvent {}
class BookAppointment extends AppointmentEvent {
  final String clinicId;
  final DateTime date;
  const BookAppointment({required this.clinicId, required this.date});
}

// ✅ State naming: noun + status
class AppointmentInitial extends AppointmentState {}
class AppointmentLoading extends AppointmentState {}
class AppointmentsLoaded extends AppointmentState {
  final List<AppointmentModel> appointments;
  const AppointmentsLoaded(this.appointments);
}
class AppointmentError extends AppointmentState {
  final String message;
  const AppointmentError(this.message);
}

// ✅ Bloc: thin — only orchestrates, NO business logic
on<LoadAppointments>((event, emit) async {
  emit(AppointmentLoading());
  final result = await _repository.getAppointments();
  result.fold(
    (error) => emit(AppointmentError(error.message)),
    (data) => emit(AppointmentsLoaded(data)),
  );
});

// ❌ NEVER call dio/http directly from Bloc
// ❌ NEVER put if/else business logic in Bloc — belongs in Repository/Service
```

---

## Performance Rules

```dart
// ✅ Use ListView.builder for lists > 10 items
ListView.builder(
  itemCount: appointments.length,
  itemBuilder: (context, index) => AppointmentCard(
    appointment: appointments[index],
  ),
)

// ✅ RepaintBoundary for expensive sub-trees
RepaintBoundary(
  child: ComplexChart(...),
)

// ✅ Memoize expensive computations
late final sortedDoctors = doctors.sorted((a, b) => a.name.compareTo(b.name));

// ✅ Use cached_network_image for all remote images
CachedNetworkImage(
  imageUrl: doctor.avatarUrl,
  placeholder: (_, __) => CircleAvatar(child: Icon(Icons.person)),
  errorWidget: (_, __, ___) => CircleAvatar(child: Icon(Icons.person)),
)

// ❌ NEVER use Image.network directly (no caching)
// ❌ NEVER call setState in build() method
// ❌ NEVER create objects inside build() — use class variables or const
```

---

## GoRouter Navigation Rules

```dart
// ✅ Use context.push / context.go — NEVER Navigator directly
context.push('/appointment/book');   // Push (back button exists)
context.go('/home');                  // Replace (no back)
context.pop();                        // Go back

// ✅ Pass data via extra or path params, NOT shared state
context.push('/doctor/$doctorId', extra: doctor);

// ✅ In receiving screen — read from GoRouterState
final doctor = state.extra as DoctorModel?;

// ❌ NEVER use Navigator.push — bypasses GoRouter guards
Navigator.push(context, ...); // ← breaks auth guards
```

---

## Error Handling

```dart
// ✅ Always show user-friendly errors, log technical ones
on<LoadData>((event, emit) async {
  try {
    emit(Loading());
    final data = await _repository.fetchData();
    emit(Loaded(data));
  } on DioException catch (e) {
    debugPrint('[DataBloc] DioException: ${e.message}');
    emit(Error(e.response?.statusCode == 401
        ? 'Phiên đăng nhập hết hạn'
        : 'Không thể tải dữ liệu. Vui lòng thử lại.'));
  } catch (e, stack) {
    debugPrint('[DataBloc] Unexpected: $e\n$stack');
    emit(const Error('Đã xảy ra lỗi không mong đợi'));
  }
});

// ✅ Show SnackBar for transient errors, NOT dialog (unless critical)
ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(
    content: Text(state.message),
    backgroundColor: AppTheme.kError,
    behavior: SnackBarBehavior.floating,
  ));
```

---

## File Organization

```
lib/
├── core/
│   ├── constants/     ← app_constants.dart, api_endpoints.dart
│   ├── theme/         ← app_theme.dart (SINGLE SOURCE OF TRUTH)
│   ├── utils/         ← date_utils.dart, validators.dart
│   └── services/      ← secure_storage_service.dart, biometric_service.dart
├── data/
│   ├── models/        ← *.model.dart (KHÔNG logic trong model)
│   └── repositories/  ← *.repository.dart (API calls + parsing)
├── logic/             ← BLoC (events, states, bloc files)
└── presentation/
    ├── screens/       ← feature folder, mỗi screen 1 folder riêng
    │   └── <feature>/
    │       ├── <feature>_screen.dart   ← Orchestrator (BLoC wiring + layout)
    │       └── widgets/                ← Sub-widgets có thể reuse hoặc có concern riêng
    └── widgets/       ← Shared widgets dùng được toàn app
```

**Khi nào tách widget ra file riêng? (SRP — Single Responsibility Principle)**

```dart
// Tách khi ít nhất 1 trong các điều dưới đúng:
// 1. Widget có thể REUSE ở màn hình / feature khác
// 2. Widget có state / AnimationController riêng biệt
// 3. File chứa quá nhiều concern khác nhau (mix cả logic và UI)
// 4. Widget đủ phức tạp để viết unit test riêng

// Giữ trong cùng file khi:
// - Widget chỉ dùng ở 1 chỗ duy nhất, không có state riêng
// - Việc tách ra làm code KHÓ ĐỌC HƠN (over-engineering)
// - Tách ra không mang lại testability hơn

// Ví dụ đúng: Google’s cupertino/text_field.dart = 1600+ dòng, 1 class, 1 concern
// => Đó là đúng vì 1 lý do thay đổi duy nhất
```

---

## Platform Considerations

```dart
// ✅ Platform-aware UI khi cần
import 'dart:io' show Platform;

// NHƯNG: chỉ dùng cho platform-specific behavior, KHÔNG cho design
// MediChain dùng Material 3 cho cả iOS và Android

// ✅ Biometric auth (HIPAA requirement)
// Dùng local_auth package — đã setup trong AppLockOverlay

// ✅ Admin dark mode — always dark
// AdminColors là constant, không theo system theme

// ✅ Patient portal — theo system theme
ThemeMode.system // (configured in MaterialApp)
```

---

## Sources
- Flutter & Dart Development Rule: [agentpedia.codes](https://agentpedia.codes/rules/mobile-development/flutter-dart-development)
- Mobile Performance: [agentpedia.codes](https://agentpedia.codes/rules/mobile-development/mobile-performance-optimization)
- Cross-Platform Strategies: [agentpedia.codes](https://agentpedia.codes/rules/mobile-development/cross-platform-development-strategies)
- MediChain AGENTS.md architecture constraints

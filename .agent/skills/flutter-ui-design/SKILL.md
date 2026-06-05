---
name: flutter-ui-design
description: >
  Guides creation of distinctive, production-grade Flutter UI for MediChain that avoids
  generic "AI slop" aesthetics. Use when designing any screen, widget, or component in
  frontend-mobile/. Enforces AppTheme design tokens, BLoC separation, and intentional
  visual design for Patient/Doctor/Admin portals.
---

# Flutter UI Design — MediChain

> **Source:** Synthesized from agentpedia.codes `frontend-design` (anti-AI-slop),
> `mobile-android-design` (Material 3), `visual-design-foundations` (design tokens),
> and `mobile-ui-ux-best-practices`. Adapted for Flutter + BLoC + AppTheme.

---

## 1. Anti-AI-Slop Manifesto

Before writing any widget, answer these questions:
- **Is this visually distinct** from a generic medical app? If not, redesign.
- **Does every spacing/color value come from `AppTheme`?** If not, replace.
- **Is there an existing widget** in `lib/presentation/widgets/` that does this? If yes, reuse it.
- **Does each interaction have feedback** (ripple, haptic, animation)? If not, add it.

### 🚫 AI-Slop Patterns — NEVER produce these

```dart
// ❌ Generic blue button
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  child: Text('Submit'),
)

// ❌ Hardcoded hex colors
Container(color: Color(0xFF14B8A6)) // ← Use AppTheme.kPrimary

// ❌ Hardcoded padding everywhere
Padding(padding: EdgeInsets.all(16)) // ← Use AppSpacing.md

// ❌ Generic Card + ListTile stack with no visual identity
Card(child: ListTile(title: Text(name), subtitle: Text(email)))

// ❌ Lorem ipsum / placeholder text
Text('Doctor Name Here')

// ❌ Flat white background, no depth
Scaffold(backgroundColor: Colors.white, body: Column(...))

// ❌ Blueprint icons without context
Icon(Icons.person) // ← Meaningless without label/context
```

### ✅ Intentional Design Patterns — ALWAYS produce these

```dart
// ✅ Token-based button with brand identity
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: AppTheme.kPrimary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    minimumSize: const Size(double.infinity, 52),
  ),
  onPressed: onPressed,
  child: Text('Đặt lịch khám', style: AppTheme.labelLarge),
)

// ✅ Layered surface with subtle depth
Container(
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadow.card,
  ),
  child: ...,
)

// ✅ Semantic color pairing
Text(
  'Đang hoạt động',
  style: TextStyle(
    color: AppTheme.kSuccess,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  ),
)
```

---

## 2. MediChain Design System Tokens

### Colors (từ `AppTheme` — KHÔNG hardcode)

```dart
// Patient Portal (Light Mode)
AppTheme.kPrimary       // #14B8A6 — teal, brand identity
AppTheme.kPrimaryLight  // #CCFBF1 — teal tinted surface
AppTheme.kBg            // #F8FAFC — near-white background
AppTheme.kSurface       // #FFFFFF — card surfaces
AppTheme.kTextPrimary   // #0F172A — primary text
AppTheme.kTextSecondary // #64748B — secondary/label text
AppTheme.kBorder        // #E2E8F0 — dividers, borders
AppTheme.kSuccess       // #10B981 — positive states
AppTheme.kWarning       // #F59E0B — warning states
AppTheme.kError         // #EF4444 — error states

// Admin Portal (Dark Mode)
AdminColors.kBg         // #0D1117 — GitHub-dark background
AdminColors.kSurface    // #161B22 — card surface
AdminColors.kBorder     // #30363D — subtle borders
AdminColors.kAccent     // #58A6FF — futuristic blue accent
```

### Typography (Inter font — luôn dùng TextTheme hoặc AppTheme style)

```dart
// ✅ Dùng TextTheme của context (tự scale theo accessibility)
Theme.of(context).textTheme.headlineMedium  // Page titles
Theme.of(context).textTheme.titleLarge       // Section headers
Theme.of(context).textTheme.bodyMedium       // Body content
Theme.of(context).textTheme.labelSmall       // Tags, badges

// ✅ Hoặc AppTheme styles nếu đã define
AppTheme.headlineLarge
AppTheme.bodyMedium
AppTheme.labelMedium
```

### Spacing (AppSpacing — không hardcode số)

```dart
// Nếu AppSpacing chưa exist, tạo trong AppTheme:
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;  // default padding
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;  // pill shape
}

class AppShadow {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
```

---

## 3. Touch & Interaction Rules (Material 3 / Mobile HIG)

```dart
// ✅ Minimum touch target: 48x48 dp
// Dùng InkWell với customBorder cho tap area rộng hơn visual size
InkWell(
  customBorder: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  onTap: onTap,
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Icon(Icons.chevron_right, size: 20),
  ),
)

// ✅ Use cached_network_image for all remote images
CachedNetworkImage(
  imageUrl: doctor.avatarUrl,
  placeholder: (context, url) => CircleAvatar(child: Icon(Icons.person)),
  errorWidget: (context, url, error) => CircleAvatar(child: Icon(Icons.person)),
)

// ✅ Haptic feedback cho destructive actions
import 'package:flutter/services.dart';
HapticFeedback.mediumImpact(); // before delete/confirm dialogs

// ✅ Loading state — KHÔNG dùng CircularProgressIndicator mặc định
// Dùng skeleton loading hoặc shimmer:
if (isLoading) return _buildSkeleton();

// ✅ Empty state — có illustration hoặc icon + message + action
if (items.isEmpty) return _buildEmptyState(
  icon: Icons.calendar_today_outlined,
  message: 'Chưa có lịch hẹn nào',
  actionLabel: 'Đặt lịch ngay',
  onAction: () => context.push('/appointment/book'),
);

// ✅ Error state — có retry button
if (hasError) return _buildErrorState(
  message: error,
  onRetry: () => context.read<AppointmentBloc>().add(LoadAppointments()),
);
```

---

## 4. Portal-Specific Design Rules

### Patient Portal (Light, Minimal, Warm)
- **Tone:** Clean, reassuring, accessible
- **Background:** Layered — `kBg` → `kSurface` (slight elevation)
- **Cards:** Rounded lg (`16dp`), soft shadow, teal left-border accent for active states
- **CTAs:** Filled teal buttons, full-width for primary actions
- **Icons:** `outlined` style (not filled) — `Icons.favorite_border`, NOT `Icons.favorite`
- **Illustrations:** Use SVG health icons, NOT generic person silhouettes

```dart
// Patient card pattern
Container(
  decoration: BoxDecoration(
    color: AppTheme.kSurface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadow.card,
    border: Border(
      left: BorderSide(color: AppTheme.kPrimary, width: 3),
    ),
  ),
  child: ...,
)
```

### Admin Portal (Dark, Futuristic, Data-Dense)
- **Tone:** Professional, power-user, information-rich
- **Background:** `AdminColors.kBg` — deep dark, NOT generic grey
- **Cards:** Border `AdminColors.kBorder`, hover glow `AdminColors.kAccent.withOpacity(0.1)`
- **Typography:** Monospace for IDs/codes (`fontFamily: 'JetBrains Mono'` or `RobotoMono`)
- **Charts:** `fl_chart` — dark theme, accent color lines
- **Badges:** Glowing status dots for real-time indicators

```dart
// Admin status badge pattern
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AdminColors.kAccent.withOpacity(0.15),
    borderRadius: BorderRadius.circular(AppRadius.full),
    border: Border.all(color: AdminColors.kAccent.withOpacity(0.4)),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          color: AdminColors.kAccent,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
            color: AdminColors.kAccent.withOpacity(0.5),
            blurRadius: 4,
          )],
        ),
      ),
      const SizedBox(width: 6),
      Text('Online', style: TextStyle(color: AdminColors.kAccent, fontSize: 11)),
    ],
  ),
)
```

### Doctor/Clinic Portal
- **Tone:** Efficient, clinical, trust-inspiring
- **Color:** Primary teal with deeper shade for headers
- **Layout:** Information density medium — optimize for quick scanning
- **Schedule view:** Timeline/calendar, NOT generic list

---

## 5. Animation & Motion Rules

```dart
// ✅ Page transitions — use SlideTransition, NOT default fade
// Trong GoRouter CustomTransitionPage:
CustomTransitionPage(
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic, // NOT linear, NOT bounce
      )),
      child: child,
    );
  },
)

// ✅ List item appear animation
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOut,
  child: child,
)

// ✅ Button press feedback (scale)
GestureDetector(
  onTapDown: (_) => setState(() => _isPressed = true),
  onTapUp: (_) => setState(() => _isPressed = false),
  child: AnimatedScale(
    scale: _isPressed ? 0.96 : 1.0,
    duration: Duration(milliseconds: 100),
    child: button,
  ),
)

// ❌ NEVER use duration > 400ms for UI transitions
// ❌ NEVER use Curves.bounceOut for medical/professional UI
// ❌ NEVER animate everything — motion must have purpose
```

---

## 6. Widget Splitting — SRP Checklist

**Trước khi tạo widget mới, kiểm tra thứ tự:**

```
Bước 1 — Reuse first:
[ ] AppButton / PrimaryButton đã có trong lib/presentation/widgets/?
[ ] AppCard / InfoCard đã có?
[ ] StatusBadge / EmptyStateWidget / ErrorStateWidget đã có?
↳ Nếu có → REUSE, không tạo trùng

Bước 2 — Nếu tạo mới, đặt ở đâu?
[ ] Widget chỉ dùng trong 1 screen, không có state riêng
    ↳ Private widget (prefix _) trong cùng file screen
[ ] Widget có thể reuse hoặc có AnimationController riêng
    ↳ Tách ra screens/<feature>/widgets/<name>.dart
[ ] Widget dùng được toàn app (button, card, badge...)
    ↳ Đặt vào lib/presentation/widgets/shared/
```

```dart
// Cấu trúc widget mới chuẩn
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.accentColor, // Optional left-border accent
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.kSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: accentColor != null
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: accentColor!, width: 3),
                  ),
                )
              : null,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
```

---

## 7. Screen Layout Template

```dart
// Template chuẩn cho Patient screens
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: AppBar(
        backgroundColor: AppTheme.kSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Tiêu đề', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: false, // Left-align for modern feel
      ),
      body: BlocConsumer<ExampleBloc, ExampleState>(
        listener: (context, state) {
          if (state is ExampleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ExampleLoading) return const _Skeleton();
          if (state is ExampleLoaded) return _Content(data: state.data);
          return const _EmptyState();
        },
      ),
    );
  }
}
```

---

## Sources

| Skill/Rule | Source | Applied |
|-----------|--------|---------|
| `frontend-design` | [agentpedia.codes](https://agentpedia.codes/agent-skills/ui-design/frontend-design) | Anti-slop principles, intentionality |
| `mobile-android-design` | [agentpedia.codes](https://agentpedia.codes/agent-skills/mobile/mobile-android-design) | Material 3, touch targets, motion |
| `visual-design-foundations` | [agentpedia.codes](https://agentpedia.codes/agent-skills/ui-design/visual-design-foundations) | Design tokens, typography, spacing |
| `mobile-ui-ux-best-practices` | [agentpedia.codes](https://agentpedia.codes/rules/mobile-development/mobile-ui-ux-best-practices) | Touch, feedback, accessibility |
| Flutter & Dart Development | [agentpedia.codes](https://agentpedia.codes/rules/mobile-development/flutter-dart-development) | Widget composition, Dart patterns |

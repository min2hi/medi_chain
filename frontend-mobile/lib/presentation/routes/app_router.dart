import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/login_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/register_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/forgot_password_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/reset_password_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/home/home_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/profile/profile_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medical/record_form_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/medicine_form_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/sharing/sharing_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/logic/medical/medical_bloc.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/metric/health_metrics_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/timeline/health_timeline_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/splash/splash_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/access_logs_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/combos_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/keywords_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/review_queue_screen.dart' show ReviewQueueScreen;
import 'package:medi_chain_mobile/presentation/screens/admin/telemetry_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/users_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_shell.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/presentation/screens/payment/payment_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/payment/payment_webview_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/payment/payment_success_screen.dart';
import 'package:medi_chain_mobile/logic/payment/payment_bloc.dart';
import 'package:medi_chain_mobile/presentation/routes/payment_routes.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/notifications_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/health_twin/health_twin_screen.dart';
import 'package:medi_chain_mobile/logic/health_twin/health_twin_bloc.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          // Token đến từ query parameter: medichain://reset-password?token=xxx
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialTab = extra?['initialTab'] as int? ?? 0;
          final openAddDialog = extra?['openAddDialog'] as bool? ?? false;
          return HomeScreen(initialTab: initialTab, openAddDialog: openAddDialog);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/record-form',
        builder: (context, state) => BlocProvider.value(
          value: getIt<MedicalBloc>(),
          child: MedicalRecordFormScreen(record: state.extra as MedicalRecordModel?),
        ),
      ),
      GoRoute(
        path: '/medicine-form',
        builder: (context, state) => BlocProvider.value(
          value: getIt<MedicineBloc>(),
          child: MedicineFormScreen(medicine: state.extra as MedicineModel?),
        ),
      ),
      // ── Appointments (tab trong HomeScreen, giữ route cho deep linking) ───
      GoRoute(
        path: '/appointments',
        builder: (context, state) => HomeScreen(initialTab: 3),
      ),
      // ── Medicines tab (deep linking) ─────────────────────────────────────────
      GoRoute(
        path: '/medicines',
        builder: (context, state) => HomeScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/metrics',
        builder: (context, state) => const HealthMetricsScreen(),
      ),
      GoRoute(
        path: '/sharing',
        builder: (context, state) => const SharingScreen(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const HealthTimelineScreen(),
      ),

      // ── Patient Notifications (appointment updates) ────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<NotificationBloc>()..add(NotificationFetchRequested()),
          child: const NotificationsScreen(),
        ),
      ),

      // ── Payment Flow ───────────────────────────────────────────────────────
      // Typed extras (PaymentArgs, CheckoutArgs, PaymentSuccessArgs) thay vì
      // Map<String, String> — compile-time safe, không có silent empty string.
      // BlocProvider được tạo mới mỗi screen vì payment flow không cần shared state:
      //   • PaymentScreen   → chỉ cần load fee + tạo order
      //   • WebViewScreen   → chỉ cần check status
      //   • SuccessScreen   → không cần BLoC
      GoRoute(
        path: PaymentRoutes.payment,
        builder: (context, state) {
          final args = state.extra as PaymentArgs;
          return BlocProvider(
            create: (_) => getIt<PaymentBloc>(),
            child: PaymentScreen(args: args),
          );
        },
      ),
      GoRoute(
        path: PaymentRoutes.checkout,
        builder: (context, state) {
          final args = state.extra as CheckoutArgs;
          return BlocProvider(
            create: (_) => getIt<PaymentBloc>(),
            child: PaymentWebViewScreen(args: args),
          );
        },
      ),
      GoRoute(
        path: PaymentRoutes.success,
        builder: (context, state) {
          final args = state.extra as PaymentSuccessArgs;
          return PaymentSuccessScreen(orderCode: args.orderCode);
        },
      ),
      // ── Clinic Shell — DOCTOR / ADMIN entry point ────────────────────────
      // ClinicShell menggantikan AdminDashboardScreen sebagai home untuk staff.
      // Patient (USER) tidak pernah melihat route ini.
      GoRoute(
        path: '/clinic',
        redirect: (context, state) {
          final authState = getIt<AuthBloc>().state;
          if (authState is! Authenticated) return '/login';
          final role = authState.user.role?.toUpperCase() ?? '';
          if (role != 'ADMIN' && role != 'DOCTOR') return '/';
          return null;
        },
        builder: (context, state) => const ClinicShell(),
      ),

      // ── Admin sub-screens — push navigation từ ClinicSystemScreen ────────
      // /admin/* chỉ dành cho ADMIN. DOCTOR được redirect về /clinic.
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          final authState = getIt<AuthBloc>().state;
          if (authState is! Authenticated) return '/login';
          final role = authState.user.role?.toUpperCase() ?? '';
          // DOCTOR không có quyền vào admin sub-screens
          if (role != 'ADMIN') return '/clinic';
          // /admin root → redirect sang /clinic (ClinicShell là home cho staff)
          if (state.uri.path == '/admin') return '/clinic';
          return null;
        },
        builder: (context, state) => const ClinicShell(),
        routes: [
          GoRoute(
            path: 'review-queue',
            builder: (context, state) => const ReviewQueueScreen(),
          ),
          GoRoute(
            path: 'keywords',
            builder: (context, state) => const KeywordsScreen(),
          ),
          GoRoute(
            path: 'combos',
            builder: (context, state) => const CombosScreen(),
          ),
          GoRoute(
            path: 'telemetry',
            builder: (context, state) => const TelemetryScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: 'access-logs',
            builder: (context, state) => const AccessLogsScreen(),
          ),
        ],
      ),

      // ── Bóng Sức Khỏe — Health Twin ──────────────────────────────────────
      GoRoute(
        path: '/health-twin',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<HealthTwinBloc>(),
          child: const HealthTwinScreen(),
        ),
      ),
    ],
    // Khi GoRouter không tìm thấy route, điều hướng về /clinic nếu là staff,
    // tránh việc nút Home trên trang lỗi dẫn về patient portal.
    errorBuilder: (context, state) => _AdminAwareErrorPage(error: state.error),
  );
}

/// Trang lỗi tùy chỉnh: phân biệt admin vs patient để nút Home đúng đích.
class _AdminAwareErrorPage extends StatelessWidget {
  const _AdminAwareErrorPage({required this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final isStaff = authState is Authenticated &&
        (['ADMIN', 'DOCTOR'].contains(authState.user.role?.toUpperCase()));
    final homeRoute = isStaff ? '/clinic' : '/';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        title: const Text('Page Not Found', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(homeRoute);
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error?.toString() ?? 'Không tìm thấy trang',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go(homeRoute),
              child: Text(
                'Home',
                style: TextStyle(
                  color: const Color(0xFF6366F1),
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


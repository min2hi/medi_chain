import 'package:go_router/go_router.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/login_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/register_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/forgot_password_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/auth/reset_password_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/home/home_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/profile/profile_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medical/record_form_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/medicine_form_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/appointment/appointment_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/sharing/sharing_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/logic/medical/medical_bloc.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/metric/health_metrics_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/splash/splash_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';

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
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentListScreen(),
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
        path: '/admin',
        redirect: (context, state) {
          // Guard: chỉ ADMIN mới được vào /admin
          final authState = getIt<AuthBloc>().state;
          if (authState is! Authenticated) return '/login';
          if (authState.user.role?.toUpperCase() != 'ADMIN') return '/';
          return null; // Cho qua
        },
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}

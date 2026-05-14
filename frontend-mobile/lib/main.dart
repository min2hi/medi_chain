import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/services/app_lock_service.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/routes/app_router.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/app_lock_overlay.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Tắt runtime fetching để fonts cache sau lần đầu, không cần mạng
  GoogleFonts.config.allowRuntimeFetching = false;

  // Setup Dependency Injection
  await setupInjection();

  // Khởi tạo HIPAA Auto-Lock (đọc setting từ SharedPreferences)
  await AppLockService().initialize();

  // Khởi tạo theme mode từ SharedPreferences (dark/light)
  await AppThemeNotifier.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('vi'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('vi'),
      startLocale: const Locale('vi'),
      child: const MediChainApp(),
    ),
  );
}

class MediChainApp extends StatelessWidget {
  const MediChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // ── HIPAA Cold-Launch Protection ──────────────────────────────────
            // Phân biệt cold launch vs fresh login qua flag isColdLaunch:
            //   - AuthCheckRequested → token restore → coldLaunch = true
            //     → startMonitoring(coldLaunch: true) → lock ngay, biometric gate
            //   - LoginRequested → email+password → coldLaunch = false
            //     → startMonitoring(coldLaunch: false) → bắt đầu inactivity timer
            //
            // QUAN TRỌNG: dùng context.read<AuthBloc>() (cùng instance với
            // BlocProvider), KHÔNG dùng getIt<AuthBloc>() (sẽ tạo instance mới
            // với _isColdLaunch = false mặc định → cold launch không bao giờ lock).
            final isColdLaunch = context.read<AuthBloc>().isColdLaunch;
            AppLockService().startMonitoring(coldLaunch: isColdLaunch);
          } else if (state is Unauthenticated) {
            AppLockService().stopMonitoring();
            AppRouter.router.go('/login');
          }
        },
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeNotifier.mode,
          builder: (_, themeMode, child) => MaterialApp.router(
            title: 'MediChain',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            // Layer 2: AppLockOverlay bọc ngoài toàn bộ Navigator
            builder: (context, child) => AppLockOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

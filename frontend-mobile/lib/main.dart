import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/services/appointment_reminder_service.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/routes/app_router.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Inter chưa được bundle trong assets; cho phép google_fonts tải và cache runtime.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Setup Dependency Injection
  await setupInjection();

  // Khởi tạo Appointment Reminder Service (local notifications)
  await AppointmentReminderService.instance.initialize();

  // Khởi tạo theme mode từ SharedPreferences (dark/light)
  await AppThemeNotifier.initialize();

  runApp(
    EasyLocalization(
      // App hướng tới người dùng Việt Nam → chỉ support tiếng Việt.
      // Không có Locale('en') → easy_localization không thể follow device English.
      supportedLocales: const [Locale('vi')],
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
          if (state is Unauthenticated) {
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
          ),
        ),
      ),
    );
  }
}

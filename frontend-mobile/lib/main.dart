import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/routes/app_router.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tắt runtime fetching — fonts cache sau lần đầu, không cần mạng
  GoogleFonts.config.allowRuntimeFetching = false;

  // Setup Dependency Injection
  await setupInjection();

  runApp(const MediChainApp());
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
        child: MaterialApp.router(
          title: 'MediChain',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}

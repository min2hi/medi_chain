import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/services/biometric_service.dart';
import 'package:medi_chain_mobile/data/repositories/auth_repository.dart';
import 'package:medi_chain_mobile/logic/dashboard/dashboard_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/home/home_screen.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/activity_card.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/alert_section.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/health_overview_card.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/quick_actions.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/today_schedule_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<DashboardBloc>()..add(DashboardFetchRequested()),
      child: Scaffold(
        
        body: SafeArea(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {

              // ── Loading: shimmer skeleton thay CircularProgressIndicator ──
              if (state is DashboardLoading) {
                return const DashboardSkeleton();
              }

              // ── Error state ──
              if (state is DashboardError) {
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<DashboardBloc>()
                      .add(DashboardRefreshRequested()),
                  child: ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Icon(LucideIcons.alertCircle,
                                  size: 44, color: Color(0xFFDC2626)),
                              SizedBox(height: 16),
                              Text(
                                state.message,
                                style: GoogleFonts.inter(
                                    color: Color(0xFF64748B)),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              TextButton(
                                onPressed: () => context
                                    .read<DashboardBloc>()
                                    .add(DashboardFetchRequested()),
                                child: Text(
                                  'dashboard.retry'.tr(),
                                  style: GoogleFonts.inter(
                                      color: Color(0xFF0D9488),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ── Loaded ──
              if (state is DashboardLoaded) {
                final stats  = state.data.stats;
                final user   = state.data.user;
                final alerts = stats?.alerts ?? [];
                final userRole = user?.role?.toUpperCase() ?? '';

                return RefreshIndicator(
                  color: Color(0xFF0D9488),
                  onRefresh: () async => context
                      .read<DashboardBloc>()
                      .add(DashboardRefreshRequested()),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Header sticky ──
                      SliverToBoxAdapter(
                        child: _buildHeader(
                          context,
                          name: user?.name,
                          alertCount: alerts.length,
                          isAdmin: userRole == 'ADMIN' || userRole == 'DOCTOR',
                          onBellTap: () => _showAlertsSheet(context, alerts),
                        ),
                      ),

                      // ── Body content ──
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (alerts.isNotEmpty) ...[
                              AlertSection(alerts: alerts),
                              SizedBox(height: 20),
                            ],
                            Text(
                              'dashboard.quick_actions'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 12),
                            const QuickActions(),
                            SizedBox(height: 20),
                            HealthOverviewCard(stats: stats),
                            SizedBox(height: 20),
                            TodayScheduleCard(stats: stats),
                            SizedBox(height: 20),
                            ActivityCard(activities: stats?.recentActivities),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox();
            },
          ),
        ),
      ),
    );
  }

  // ─── Step-up Authentication — Layer 1 Security ─────────────────────────────────────────
  // Gọi BiometricService trước khi cho vào Admin Portal.
  // Fallback: nếu thiết bị không có Biometric → dùng Password Confirm dialog.
  Future<void> _goToAdminWithAuth(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final biometric = BiometricService();
    // BiometricService.authenticate() đã check isAvailable() nội bộ — không cần gọi thêm
    final result = await biometric.authenticate(
      reason: 'Xác thực để vào Admin Portal — MediChain',
    );

    if (!context.mounted) return;

    switch (result) {
      case BiometricResult.success:
        context.push('/admin');

      case BiometricResult.notEnrolled:
        // Có hardware nhưng chưa đăng ký vân tay → fallback password
        _showPasswordFallback(context);

      case BiometricResult.notAvailable:
        // Không có biometric hardware (emulator, thiết bị cũ) → fallback password
        _showPasswordFallback(context);

      case BiometricResult.lockedOut:
        _showAuthSnackBar(
          context,
          'Xác thực bị khóa tạm thời do thử quá nhiều lần. Vui lòng thử lại sau.',
          isError: true,
        );

      case BiometricResult.permanentlyLockedOut:
        _showAuthSnackBar(
          context,
          'Xác thực bị khóa. Vui lòng mở khóa điện thoại bằng PIN để tiếp tục.',
          isError: true,
        );

      case BiometricResult.failed:
      case BiometricResult.cancelled:
        break;
    }
  }

  // Fallback: xác nhận password qua backend khi không có biometric
  void _showPasswordFallback(BuildContext context) {
    final controller = TextEditingController();
    bool obscure = true;
    String? errorText;
    bool isLoading = false;
    final authRepo = getIt<AuthRepository>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(Icons.lock_outline, size: 20, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Xác nhận danh tính', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập mật khẩu để vào Admin Portal.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                autofocus: true,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  errorText: errorText,
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setDlgState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (controller.text.isEmpty) {
                        setDlgState(() => errorText = 'Vui lòng nhập mật khẩu');
                        return;
                      }
                      setDlgState(() {
                        isLoading = true;
                        errorText = null;
                      });
                      // Gọi backend để xác minh password thực sự
                      final result = await authRepo.adminElevate(controller.text);
                      if (!ctx.mounted) return;
                      if (result['success'] == true) {
                        Navigator.pop(ctx);
                        if (context.mounted) context.push('/admin');
                      } else {
                        setDlgState(() {
                          isLoading = false;
                          errorText = result['message'] as String? ?? 'Mật khẩu không đúng';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: Size.zero,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFDC2626) : Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context, {
    required String? name,
    required int alertCount,
    required VoidCallback onBellTap,
    bool isAdmin = false,
  }) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : 'M';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          // ── Avatar: double-tap để vào Admin (chỉ admin) ──────────────────
          GestureDetector(
            onDoubleTap: isAdmin
                ? () => _goToAdminWithAuth(context)
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAdmin
                          ? const Color(0xFF6366F1).withOpacity(0.5)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ),
                // Badge nhỏ góc phải dưới cho ADMIN
                if (isAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                      child: const Icon(Icons.shield, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   'dashboard.greeting'.tr(namedArgs: {'name': name ?? 'MediChain'}),
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'dashboard.online'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Notification bell ──────────────────────────────────────────
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.bell,
                      size: 18, color: isDark ? Colors.white : const Color(0xFF475569)),
                ),
                if (alertCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        alertCount > 9 ? '9+' : '$alertCount',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Share button ───────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.push('/sharing'),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.share2,
                  size: 18, color: isDark ? Colors.white : const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Alerts bottom sheet ──────────────────────────────────────────────────────
  void _showAlertsSheet(BuildContext context, List<dynamic> alerts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'dashboard.alerts'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => SizedBox(height: 8),
              itemBuilder: (_, i) {
                final alert = alerts[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertTriangle,
                          size: 16, color: Color(0xFFEA580C)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alert.message as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

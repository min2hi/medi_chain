import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';
import 'package:medi_chain_mobile/logic/dashboard/dashboard_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/home/home_screen.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/activity_card.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/health_overview_card.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/quick_actions.dart';
import 'package:medi_chain_mobile/presentation/widgets/dashboard/today_schedule_card.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Chào buổi sáng';
  if (h < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

String _greetingEmoji() {
  final h = DateTime.now().hour;
  if (h < 12) return '🌅';
  if (h < 18) return '☀️';
  return '🌙';
}

String _todayLabel() {
  final now = DateTime.now();
  const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  return '${weekdays[now.weekday % 7]}, ${now.day}/${now.month}';
}

// ════════════════════════════════════════════════════════════════════════════
// DashboardScreen
// ════════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  // Stagger: mỗi section cách nhau 60ms, slide nhẹ 4%
  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(
          (i * 0.10).clamp(0.0, 0.9),
          ((i * 0.10) + 0.35).clamp(0.1, 1.0),
          curve: Curves.easeOut,
        ),
      );

  Animation<Offset> _slide(int i) => Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(
          (i * 0.10).clamp(0.0, 0.9),
          ((i * 0.10) + 0.35).clamp(0.1, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ));

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fade(i),
        child: SlideTransition(position: _slide(i), child: child),
      );

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<DashboardBloc>()..add(DashboardFetchRequested()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<NotificationBloc>()..add(NotificationFetchRequested()),
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0D1520)
            : AppTheme.kBg,
        body: SafeArea(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) return const DashboardSkeleton();
              if (state is DashboardError) {
                return _DashboardErrorView(
                  message: state.message,
                  onRetry: () => context
                      .read<DashboardBloc>()
                      .add(DashboardFetchRequested()),
                );
              }
              if (state is DashboardLoaded) {
                _animCtrl.forward(from: 0);

                final stats   = state.data.stats;
                final user    = state.data.user;
                final alerts  = stats?.alerts ?? [];

                return RefreshIndicator(
                  color: AppTheme.kPrimary,
                  onRefresh: () async {
                    _animCtrl.forward(from: 0);
                    context
                        .read<DashboardBloc>()
                        .add(DashboardRefreshRequested());
                    context
                        .read<NotificationBloc>()
                        .add(NotificationFetchRequested());
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Header ─────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: BlocBuilder<NotificationBloc, NotificationState>(
                          builder: (context, notifState) {
                            final unread = notifState is NotificationLoaded
                                ? notifState.unreadCount
                                : 0;
                            return _animated(
                              0,
                              _DashboardHeader(
                                name: user?.name,
                                // Merge alert + unread badge — user thấy
                                // số tổng hợp dù từ nguồn nào
                                badgeCount: max(unread, alerts.length),
                                alerts: alerts,
                                onBellTap: () =>
                                    _showAlertsSheet(context, alerts),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Body ───────────────────────────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // 1. Quick Actions — action-first layout
                            _animated(
                              1,
                              const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: QuickActions(),
                              ),
                            ),

                            // 2. Health Overview — thông tin quan trọng
                            _animated(
                              2,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: HealthOverviewCard(stats: stats),
                              ),
                            ),

                            // 3. Today Schedule
                            _animated(
                              3,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TodayScheduleCard(stats: stats),
                              ),
                            ),

                            // 4. Activity
                            _animated(
                              4,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ActivityCard(
                                    activities: stats?.recentActivities),
                              ),
                            ),

                            // 5. Timeline entry point
                            _animated(5, const _TimelineBanner()),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // ── Alerts bottom sheet ──────────────────────────────────────────────────
  void _showAlertsSheet(BuildContext context, List<dynamic> alerts) {
    if (alerts.isEmpty) {
      // Không có alert → mở notifications route
      HapticFeedback.lightImpact();
      context.push('/notifications');
      return;
    }
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AlertsBottomSheet(alerts: alerts),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _DashboardHeader — Flat, typography-led. No avatar, no wave clip.
//
// Design rationale:
//   - Greeting text (small, muted) + Name (large, bold) → hierarchy clear
//   - Flat solid teal background → professional, không consumer-app
//   - Bell badge → tổng hợp alerts + unread notifications
//   - Share icon → data sharing feature
//   - Không có letter avatar → generic, không có thông tin value
// ════════════════════════════════════════════════════════════════════════════
class _DashboardHeader extends StatelessWidget {
  final String? name;
  final int badgeCount;
  final List<dynamic> alerts;
  final VoidCallback onBellTap;

  const _DashboardHeader({
    required this.name,
    required this.badgeCount,
    required this.alerts,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'bạn';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      color: const Color(0xFF0D9488), // solid teal — không gradient, không wave
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: greeting + name + date ─────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting nhỏ + emoji
                Text(
                  '${_greeting()} ${_greetingEmoji()}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.72),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                // Tên — to, bold, prominent
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                // Date pill
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _todayLabel(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Right: icon buttons ───────────────────────────────────────
          Row(
            children: [
              // Bell — tap → alerts/notifications
              _HeaderIconButton(
                icon: LucideIcons.bell,
                onTap: onBellTap,
                badge: badgeCount > 0 ? badgeCount : null,
              ),
              const SizedBox(width: 8),
              // Share — data sharing
              _HeaderIconButton(
                icon: LucideIcons.share2,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/sharing');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Header icon button — tái sử dụng cho Bell + Share ────────────────────
// Badge nằm NGOÀI Material.clipBehavior để không bị clip.
// Structure: Stack[Material[InkWell[Icon]], Positioned[Badge]]
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final hasBadge = badge != null && badge! > 0;

    return Stack(
      clipBehavior: Clip.none, // badge được phép render ra ngoài bound
      children: [
        // Button circle
        ScaleOnTap(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
        // Badge — nằm ngoài clip, không bị cắt
        if (hasBadge)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppTheme.kError,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0D9488),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                badge! > 9 ? '9+' : '$badge',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _AlertsBottomSheet — hiển thị khi tap Bell và có alerts
// ════════════════════════════════════════════════════════════════════════════
class _AlertsBottomSheet extends StatelessWidget {
  final List<dynamic> alerts;
  const _AlertsBottomSheet({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182030) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A3A50)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Icon(LucideIcons.triangleAlert,
                    size: 15,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text(
                  'Cảnh báo (${alerts.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0D1520),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Alert list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final msg = alerts[i].message as String? ?? '';
                return Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A1A00).withOpacity(0.6)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF92400E).withOpacity(0.4)
                          : const Color(0xFFFCD34D).withOpacity(0.7),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.pill,
                          size: 14,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _TimelineBanner — entry point cho health timeline
// ════════════════════════════════════════════════════════════════════════════
class _TimelineBanner extends StatelessWidget {
  const _TimelineBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleOnTap(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/timeline');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppTheme.kPrimaryDark.withOpacity(0.25)
                : AppTheme.kPrimaryDark.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryDark.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.timeline_rounded,
                  size: 18, color: AppTheme.kPrimaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hành trình sức khỏe',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFEFF3FF)
                          : AppTheme.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lịch hẹn · Hồ sơ bệnh · Đơn thuốc',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? const Color(0xFF7A90B0) : AppTheme.kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFF7A90B0)
                    : AppTheme.kTextMuted),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _DashboardErrorView — cold-start aware, auto-retry sau 10s
// ════════════════════════════════════════════════════════════════════════════
class _DashboardErrorView extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  const _DashboardErrorView(
      {required this.message, required this.onRetry});

  @override
  State<_DashboardErrorView> createState() => _DashboardErrorViewState();
}

class _DashboardErrorViewState extends State<_DashboardErrorView> {
  bool _isRetrying = false;

  bool get _isColdStart => widget.message == 'server_cold_start';

  String get _displayMessage => _isColdStart
      ? 'Backend đang khởi động\n(Render free tier ~30s). Vui lòng thử lại.'
      : widget.message;

  @override
  void initState() {
    super.initState();
    if (_isColdStart) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && !_isRetrying) _retry();
      });
    }
  }

  void _retry() {
    setState(() => _isRetrying = true);
    widget.onRetry();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isRetrying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isColdStart
                  ? LucideIcons.serverCrash
                  : LucideIcons.alertCircle,
              size: 44,
              color: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            Text(
              _displayMessage,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isRetrying ? null : _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppTheme.kPrimaryDark.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRetrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'dashboard.retry'.tr(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/admin_stat_tile.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/role_boundary_note.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

/// AdminDashboardScreen — Platform Operations Command Center.
class AdminDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;
  const AdminDashboardScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadAdminDashboard()),
      child: _DashboardView(onSwitchTab: onSwitchTab),
    );
  }
}

class _DashboardView extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const _DashboardView({this.onSwitchTab});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final Set<String> _reviewedIds = {};

  @override
  void initState() {
    super.initState();
    _loadReviewedIds();
  }

  Future<void> _loadReviewedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('admin_reviewed_user_ids') ?? [];
    if (mounted) {
      setState(() {
        _reviewedIds.clear();
        _reviewedIds.addAll(list);
      });
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _shortDate() {
    final now = DateTime.now();
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${days[now.weekday % 7]}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final name = authState is Authenticated
        ? (authState.user.name ?? 'Admin')
        : 'Admin';

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const _AdminDashboardSkeleton();
          }
          if (state is AdminError) {
            return AdminErrorState(
              message: state.message,
              onRetry: () => context.read<AdminBloc>().add(LoadAdminDashboard()),
            );
          }
          if (state is AdminDashboardLoaded) {
            return RefreshIndicator(
              color: AppTheme.kPrimary,
              backgroundColor: AdminColors.surface,
              onRefresh: () async {
                context.read<AdminBloc>().add(LoadAdminDashboard());
                context.read<NotificationBloc>().add(NotificationFetchRequested());
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context, name)),
                  SliverToBoxAdapter(
                    child: _FadeSlideTransition(
                      child: _buildStatGrid(state),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FadeSlideTransition(
                      child: _buildAdminTools(context, state),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  const SliverToBoxAdapter(child: RoleBoundaryNote()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AdminColors.textPrimary,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản quản trị?',
          style: GoogleFonts.inter(color: AdminColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: AdminColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              getIt<AuthBloc>().add(LogoutRequested());
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String name) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090E1A),
        border: Border(bottom: BorderSide(color: AdminColors.border, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Profile & Action
            Row(
              children: [
                // Avatar with online status dot overlapping
                Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: AdminColors.border, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // active green
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF090E1A), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Identity details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'admin@medichain.com',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Subtle Logout Circle
                ScaleOnTap(
                  onTap: () => _showLogoutConfirmation(context),
                  scaleDownFactor: 0.95,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: AdminColors.border.withValues(alpha: 0.6)),
                    ),
                    child: const Icon(
                      LucideIcons.logOut,
                      size: 15,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Row 2: Greeting & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hệ thống MediChain',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                // Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 10.5, color: AdminColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _shortDate(),
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Stat grid (2x2 key metrics) ─────────────────────────────────────────
  Widget _buildStatGrid(AdminDashboardLoaded data) {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    
    // Patient stats details
    final newPatients = data.users.where((u) => u.role.toUpperCase() != 'DOCTOR' && u.role.toUpperCase() != 'ADMIN' && u.createdAt.isAfter(last24h)).length;
    final patientDetail = newPatients > 0 ? '+$newPatients 24h' : 'Không đổi';

    // Doctor stats details
    final pendingDoctors = data.users.where((u) => u.role.toUpperCase() == 'DOCTOR' && !u.licenseVerified).length;
    final doctorDetail = pendingDoctors > 0 ? '$pendingDoctors chờ duyệt' : 'Đã xác minh';

    // Total accounts stats details
    final newAccounts = data.users.where((u) => u.createdAt.isAfter(last24h)).length;
    final accountsDetail = newAccounts > 0 ? '+$newAccounts 24h' : 'Không đổi';


    final items = [
      AdminStatTile(
        label: 'Bệnh nhân',
        value: '${data.userCount - data.doctorCount}',
        icon: LucideIcons.users,
        accent: AdminColors.success,
        isReadOnly: true,
        detail: patientDetail,
      ),
      AdminStatTile(
        label: 'Bác sĩ',
        value: '${data.doctorCount}',
        icon: LucideIcons.userCog,
        accent: AdminColors.roleDoctor,
        isReadOnly: true,
        detail: doctorDetail,
      ),
      AdminStatTile(
        label: 'Tổng tài khoản',
        value: '${data.userCount}',
        icon: LucideIcons.database,
        accent: AdminColors.warning,
        isReadOnly: true,
        detail: accountsDetail,
      ),
      AdminStatTile(
        label: 'Tổng lịch hẹn',
        value: '${data.totalAppointmentCount}',
        icon: LucideIcons.calendarDays,
        accent: AdminColors.rolePatient,
        isReadOnly: true,
        detail: data.pendingAppointmentCount > 0
            ? '${data.pendingAppointmentCount} chờ duyệt'
            : 'Không đổi',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Row(
            children: [
              Icon(LucideIcons.barChart2,
                  size: 13, color: AdminColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'THỐNG KÊ HỆ THỐNG',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => AdminStatTileWidget(
              tile: items[i],
              onTap: null,
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. Admin Tools Section ────────────────────────────────────────────────
  Widget _buildAdminTools(BuildContext context, AdminDashboardLoaded state) {
    final now = DateTime.now();
    final last3days = now.subtract(const Duration(days: 3));
    final unreviewedNewUsersCount = state.users.where((u) {
      if (u.role.toUpperCase() == 'ADMIN') return false;
      final isNew = u.createdAt.isAfter(last3days);
      final isUnreviewed = !_reviewedIds.contains(u.id);
      return isNew && isUnreviewed;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('DUYỆT & KIỂM SOÁT'),
        _GroupedActionCard(
          children: [
            _NavRow(
              label: 'Duyệt đề xuất AI',
              subtitle: 'Keyword chờ phê duyệt',
              icon: LucideIcons.checkSquare,
              badgeCount: state.pendingReviewCount,
              onTap: () => context.push('/admin/review-queue'),
            ),
            const Divider(height: 1, color: AdminColors.border, indent: 54),
            _NavRow(
              label: 'Nhật ký hoạt động',
              subtitle: 'Nhật ký truy cập hệ thống',
              icon: LucideIcons.history,
              onTap: () => context.push('/admin/access-logs'),
            ),
          ],
        ),
        const _SectionLabel('TRI THỨC LÂM SÀNG'),
        _GroupedActionCard(
          children: [
            _NavRow(
              label: 'Từ khóa an toàn',
              subtitle: 'Keyword cảnh báo khẩn cấp',
              icon: LucideIcons.shieldAlert,
              onTap: () => context.push('/admin/keywords'),
            ),
            const Divider(height: 1, color: AdminColors.border, indent: 54),
            _NavRow(
              label: 'Quy tắc tổ hợp',
              subtitle: 'Combo rules phát hiện bệnh lý',
              icon: LucideIcons.gitFork,
              onTap: () => context.push('/admin/combos'),
            ),
          ],
        ),
        const _SectionLabel('NGƯỜI DÙNG & HỆ THỐNG'),
        _GroupedActionCard(
          children: [
            _NavRow(
              label: 'Quản lý người dùng',
              subtitle: 'Xem, phân quyền, khóa tài khoản',
              icon: LucideIcons.userCog,
              badgeCount: unreviewedNewUsersCount > 0 ? unreviewedNewUsersCount : null,
              onTap: () => context.push('/admin/users').then((_) => _loadReviewedIds()),
            ),
            const Divider(height: 1, color: AdminColors.border, indent: 54),
            _NavRow(
              label: 'Giám sát hệ thống',
              subtitle: 'Giám sát AI & mức dùng token',
              icon: LucideIcons.activity,
              onTap: () => context.push('/admin/telemetry'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Grouped Action Card Container ───────────────────────────────────────────
class _GroupedActionCard extends StatelessWidget {
  const _GroupedActionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ─── Section label — uppercased muted text ────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AdminColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Nav row — settings style, monochrome icon ────────────────────────────────
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.badgeCount,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      scaleDownFactor: 0.98,
      child: Ink(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Monochrome icon — no color background
              Icon(icon, size: 20, color: AdminColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        if (badgeCount != null && badgeCount! > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$badgeCount',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AdminColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Organic Slide & Fade Entry Transition ─────────────────────────────────────
class _FadeSlideTransition extends StatelessWidget {
  const _FadeSlideTransition({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}


// ─── Admin Dashboard Skeleton Loader (matching new 2x2 layout) ─────────────────
class _AdminDashboardSkeleton extends StatelessWidget {
  const _AdminDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: AdminColors.surface,
          highlightColor: AdminColors.elevated,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header skeleton
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(height: 24),
                // Stat grid skeleton (2x2)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, _) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Group title skeleton
                Container(height: 12, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),
                // Action items skeletons
                Column(
                  children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 14, width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 6),
                              Container(height: 10, width: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                            ],
                          ),
                        ),
                        Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

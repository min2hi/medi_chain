import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

/// AdminDashboardScreen — Platform Operations Command Center.
///
/// Design philosophy (Vercel/Linear/Stripe):
///  · Header: identity + live status, minimal noise
///  · Stat grid: 2×3 tiles, equal proportion, number-first density
///  · Pending alert: amber signal — only shown when actionable
///  · Nav groups: iOS Settings-style grouped rows with role separation
///  · Role boundaries: Admin CANNOT approve appointments — Doctor owns that.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadAdminDashboard()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

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
        ? (authState.user.name?.split(' ').last ?? 'Admin')
        : 'Admin';

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.kPrimary, strokeWidth: 1.5,
              ),
            );
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
              onRefresh: () async => context.read<AdminBloc>().add(LoadAdminDashboard()),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(name)),
                  if (state.pendingReviewCount > 0)
                    SliverToBoxAdapter(
                      child: _buildPendingAlert(context, state.pendingReviewCount),
                    ),
                  SliverToBoxAdapter(child: _buildStatGrid(state)),
                  SliverToBoxAdapter(child: _buildNav(context, state)),
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

  // ── 1. Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080E1A), Color(0xFF0C1428)],
        ),
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: role pill + status
              Row(
                children: [
                  _RolePill(),
                  const Spacer(),
                  _StatusDot(),
                ],
              ),
              const SizedBox(height: 18),
              // Greeting + name
              Text(
                _greeting(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AdminColors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _shortDate(),
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: AdminColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Pending alert (amber signal) ────────────────────────────────────────
  Widget _buildPendingAlert(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => context.push('/admin/review-queue'),
          splashColor: AdminColors.warning.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AdminColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AdminColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AdminColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(LucideIcons.alertTriangle,
                      size: 14, color: AdminColors.warning),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count đề xuất AI chờ duyệt',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.warning,
                        ),
                      ),
                      Text(
                        'Nhấn để xem danh sách',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AdminColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight,
                    size: 14, color: AdminColors.warning),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 3. Stat grid (2×3 equal tiles) ─────────────────────────────────────────
  // Design: Stripe Dashboard — number first, label below, accent top border
  // Role note: "Lịch hẹn hôm nay" là CHỈ ĐỌC — không có tap action
  Widget _buildStatGrid(AdminDashboardLoaded data) {
    final items = [
      _StatTile(
        label: 'Người dùng',
        value: '${data.userCount}',
        icon: LucideIcons.users,
        accent: AppTheme.kPrimary,
      ),
      _StatTile(
        label: 'Bác sĩ',
        value: '${data.doctorCount}',
        icon: LucideIcons.stethoscope,
        accent: AdminColors.info,
      ),
      _StatTile(
        label: 'Từ khóa AI',
        value: '${data.activeKeywordCount}',
        icon: LucideIcons.shield,
        accent: AdminColors.success,
      ),
      _StatTile(
        label: 'Combo rules',
        value: '${data.activeComboCount}',
        icon: LucideIcons.layers,
        accent: AdminColors.purple,
      ),
      _StatTile(
        label: 'Chờ duyệt AI',
        value: '${data.pendingReviewCount}',
        icon: LucideIcons.clipboardCheck,
        accent: data.pendingReviewCount > 0 ? AdminColors.warning : AdminColors.textMuted,
        hasBadge: data.pendingReviewCount > 0,
      ),
      // Lịch hẹn hôm nay: read-only stat — Doctor sở hữu workflow này
      _StatTile(
        label: 'Lịch hẹn hôm nay',
        value: '${data.todayAppointmentCount}',
        icon: LucideIcons.calendarDays,
        accent: AdminColors.rolePatient,
        isReadOnly: true,
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
                  size: 13, color: AdminColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'THỐNG KÊ HỆ THỐNG',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textMuted,
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
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // Tỷ lệ 1:1 — chiều cao = chiều rộng, đồng nhất tất cả tiles
              childAspectRatio: 1.0,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _StatTileWidget(tile: items[i]),
          ),
        ),
      ],
    );
  }

  // ── 4. Nav groups (iOS Settings pattern) ──────────────────────────────────
  Widget _buildNav(BuildContext context, AdminDashboardLoaded data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group 1: Người dùng
          _SectionLabel(label: 'NGƯỜI DÙNG', icon: LucideIcons.users),
          const SizedBox(height: 8),
          _NavGroup(items: [
            _NavItem(
              icon: LucideIcons.userCog,
              iconColor: AdminColors.rolePatient,
              label: 'Quản lý tài khoản',
              meta: '${data.userCount} thành viên · ${data.doctorCount} bác sĩ',
              onTap: () => context.push('/admin/users'),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Group 2: Tri thức AI
          _SectionLabel(
            label: 'TRI THỨC AI',
            icon: LucideIcons.brain,
            iconColor: AdminColors.aiPrimary,
            badge: data.pendingReviewCount > 0 ? data.pendingReviewCount : null,
          ),
          const SizedBox(height: 8),
          _NavGroup(items: [
            _NavItem(
              icon: LucideIcons.clipboardCheck,
              iconColor: data.pendingReviewCount > 0
                  ? AdminColors.warning
                  : AdminColors.textSecondary,
              label: 'Duyệt đề xuất AI',
              meta: data.pendingReviewCount > 0
                  ? '${data.pendingReviewCount} chờ duyệt'
                  : 'Hàng đợi trống',
              badge: data.pendingReviewCount > 0 ? data.pendingReviewCount : null,
              onTap: () => context.push('/admin/review-queue'),
            ),
            _NavItem(
              icon: LucideIcons.shield,
              iconColor: AdminColors.success,
              label: 'Từ khóa an toàn',
              meta: '${data.activeKeywordCount} đang hoạt động',
              onTap: () => context.push('/admin/keywords'),
            ),
            _NavItem(
              icon: LucideIcons.layers,
              iconColor: AdminColors.purple,
              label: 'Quy tắc tổ hợp',
              meta: '${data.activeComboCount} rules',
              onTap: () => context.push('/admin/combos'),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Group 3: Tài chính
          _SectionLabel(label: 'TÀI CHÍNH', icon: LucideIcons.dollarSign),
          const SizedBox(height: 8),
          _NavGroup(items: [
            _NavItem(
              icon: LucideIcons.creditCard,
              iconColor: AppTheme.kPrimary,
              label: 'Thống kê & Giao dịch',
              meta: 'Doanh thu · Phí khám · Lịch sử',
              onTap: () => context.push('/admin/payment'),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Group 4: Hệ thống
          _SectionLabel(label: 'HỆ THỐNG', icon: LucideIcons.server),
          const SizedBox(height: 8),
          _NavGroup(items: [
            _NavItem(
              icon: LucideIcons.database,
              iconColor: AdminColors.textSecondary,
              label: 'Giám sát hệ thống',
              meta: 'Cache · Telemetry · Audit log',
              onTap: () => context.push('/admin/telemetry'),
            ),
            _NavItem(
              icon: LucideIcons.scrollText,
              iconColor: AdminColors.textSecondary,
              label: 'Nhật ký truy cập',
              meta: 'API logs theo ngày',
              onTap: () => context.push('/admin/access-logs'),
            ),
          ]),

          // ── Footnote: role boundary explanation
          const SizedBox(height: 20),
          _RoleBoundaryNote(),
        ],
      ),
    );
  }
}

// ─── Role Pill ─────────────────────────────────────────────────────────────────
class _RolePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.kPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.25)),
      ),
      child: Text(
        'ADMIN',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.kPrimary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Status dot ────────────────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: AdminColors.success,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: AdminColors.success.withValues(alpha: 0.5),
              blurRadius: 4,
            )],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Trực tuyến',
          style: GoogleFonts.inter(fontSize: 11, color: AdminColors.success),
        ),
      ],
    );
  }
}

// ─── Stat tile data model ──────────────────────────────────────────────────────
class _StatTile {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool hasBadge;
  final bool isReadOnly;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.hasBadge = false,
    this.isReadOnly = false,
  });
}

// ─── Stat tile widget ──────────────────────────────────────────────────────────
// Equal aspect ratio 1:1 — mọi tile cùng tỷ lệ, không có tile nào cao hơn
class _StatTileWidget extends StatelessWidget {
  final _StatTile tile;
  const _StatTileWidget({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          top: BorderSide(color: tile.accent, width: 1.5),
          left: BorderSide(color: AdminColors.border),
          right: BorderSide(color: AdminColors.border),
          bottom: BorderSide(color: AdminColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon + optional read-only dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(tile.icon, size: 13, color: tile.accent),
                if (tile.isReadOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AdminColors.elevated,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'CHỈ ĐỌC',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                else if (tile.hasBadge)
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: tile.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            // Value (large number)
            Text(
              tile.value,
              style: GoogleFonts.robotoMono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: tile.accent,
                height: 1.0,
              ),
            ),
            // Label (small, muted)
            Text(
              tile.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AdminColors.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final int? badge;
  const _SectionLabel({
    required this.label,
    required this.icon,
    this.iconColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor ?? AdminColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AdminColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AdminColors.warning,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Nav group container ────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String meta;
  final int? badge;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.meta,
    required this.onTap,
    this.badge,
  });
}

class _NavGroup extends StatelessWidget {
  final List<_NavItem> items;
  const _NavGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AdminColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              if (i > 0)
                Container(
                  height: 0.5,
                  color: AdminColors.border,
                  margin: const EdgeInsets.only(left: 50),
                ),
              _NavRowTile(item: item),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NavRowTile extends StatelessWidget {
  final _NavItem item;
  const _NavRowTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: AppTheme.kPrimary.withValues(alpha: 0.05),
        highlightColor: AppTheme.kPrimary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              // Icon container — consistent 34×34 tap target
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(item.icon, size: 15, color: item.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        color: AdminColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.meta,
                      style: GoogleFonts.inter(
                        color: AdminColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminColors.warning,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AdminColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role boundary footnote ────────────────────────────────────────────────────
// Giải thích rõ ràng cho admin: lịch hẹn do bác sĩ quản lý, không phải admin
class _RoleBoundaryNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 12, color: AdminColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lịch hẹn do Bác sĩ quản lý trực tiếp. Admin chỉ xem thống kê tổng hợp.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AdminColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

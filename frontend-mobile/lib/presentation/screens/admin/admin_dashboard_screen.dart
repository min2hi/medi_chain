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
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_section_header.dart';

/// AdminDashboardScreen — Tổng quan hệ thống.
/// Design: Linear / Vercel dashboard — gradient header, horizontal stat rail,
/// grouped nav với section labels, amber alert khi có pending reviews.
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
    return '${days[now.weekday % 7]}  ${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final name  = authState is Authenticated ? (authState.user.name?.split(' ').last ?? 'Admin') : 'Admin';

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator(
              color: AppTheme.kPrimary, strokeWidth: 1.5,
            ));
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
                  // ── Gradient header ─────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader(name)),

                  // ── Pending alert (chỉ hiện khi có item) ──────────────
                  if (state.pendingReviewCount > 0)
                    SliverToBoxAdapter(child: _buildPendingAlert(context, state.pendingReviewCount)),

                  // ── Stats rail (horizontal scroll) ─────────────────────
                  SliverToBoxAdapter(child: _buildStatsRail(state)),

                  // ── Nav grouped ────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildNav(context, state)),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── 1. Gradient header ──────────────────────────────────────────────────────
  Widget _buildHeader(String name) {
    return Container(
      decoration: const BoxDecoration(gradient: AdminColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: role badge + status dot
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Text('ADMIN', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.kPrimary, letterSpacing: 1.2,
                  )),
                ),
                const Spacer(),
                // Online status dot
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
                const SizedBox(width: 6),
                Text('Trực tuyến', style: GoogleFonts.inter(
                  fontSize: 11, color: AdminColors.success,
                )),
              ]),
              const SizedBox(height: 16),
              // Greeting
              Text(_greeting(), style: GoogleFonts.inter(
                fontSize: 13, color: AdminColors.textSecondary,
              )),
              const SizedBox(height: 2),
              Text(name, style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary, height: 1.1,
              )),
              const SizedBox(height: 10),
              // Date
              Text(_shortDate(), style: GoogleFonts.robotoMono(
                fontSize: 12, color: AdminColors.textMuted,
                letterSpacing: 0.5,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Pending alert banner ─────────────────────────────────────────────────
  Widget _buildPendingAlert(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => context.push('/admin/review-queue'),
          splashColor: AdminColors.warning.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AdminColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AdminColors.warning.withValues(alpha: 0.35)),
              // Subtle left accent
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AdminColors.warning.withValues(alpha: 0.12),
                  AdminColors.warning.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, size: 16, color: AdminColors.warning),
              const SizedBox(width: 10),
              Expanded(child: RichText(text: TextSpan(children: [
                TextSpan(
                  text: '$count ',
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.warning,
                  ),
                ),
                TextSpan(
                  text: 'đề xuất AI đang chờ duyệt',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: AdminColors.textSecondary,
                  ),
                ),
              ]))),
              const SizedBox(width: 8),
              Text('Xem →', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.warning,
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ── 3. Horizontal stat rail ─────────────────────────────────────────────────
  Widget _buildStatsRail(AdminDashboardLoaded data) {
    final stats = [
      _Stat(label: 'Người dùng', value: '${data.userCount}',   color: AppTheme.kPrimary),
      _Stat(label: 'Bác sĩ',     value: '${data.doctorCount}', color: AdminColors.info),
      _Stat(label: 'Từ khóa',    value: '${data.activeKeywordCount}', color: AdminColors.success),
      _Stat(label: 'Combos',     value: '${data.activeComboCount}',   color: AdminColors.purple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: AdminSectionHeader(label: 'THỐNG KÊ', icon: LucideIcons.barChart2),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stats.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _StatChip(stat: stats[i]),
          ),
        ),
      ],
    );
  }

  // ── 4. Grouped nav ──────────────────────────────────────────────────────────
  Widget _buildNav(BuildContext context, AdminDashboardLoaded data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group 1: Người dùng
          AdminSectionHeader(label: 'NGƯỜI DÙNG', icon: LucideIcons.users, count: data.userCount),
          const SizedBox(height: 8),
          _NavGroup(items: [
            _NavItem(
              icon: LucideIcons.userCog,
              iconColor: AdminColors.rolePatient,
              label: 'Quản lý tài khoản',
              meta: '${data.userCount} · ${data.doctorCount} bác sĩ',
              onTap: () => context.push('/admin/users'),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Group 2: Tri thức AI
          AdminSectionHeader(
            label: 'TRI THỨC AI',
            icon: LucideIcons.brain,
            iconColor: AdminColors.aiPrimary,
            count: data.pendingReviewCount > 0 ? data.pendingReviewCount : null,
          ),
          const SizedBox(height: 8),
          _NavGroup(items: [
            _NavItem(
              icon: LucideIcons.clipboardCheck,
              iconColor: data.pendingReviewCount > 0 ? AdminColors.warning : AdminColors.textSecondary,
              label: 'Duyệt đề xuất AI',
              meta: data.pendingReviewCount > 0 ? '${data.pendingReviewCount} chờ duyệt' : 'Không có mục nào chờ',
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

          // ── Group 3: Hệ thống
          AdminSectionHeader(label: 'HỆ THỐNG', icon: LucideIcons.server),
          const SizedBox(height: 8),
          _NavGroup(items: [
            _NavItem(
              icon: LucideIcons.database,
              iconColor: AdminColors.textSecondary,
              label: 'Giám sát hệ thống',
              meta: 'Cache · Audit log · Telemetry',
              onTap: () => context.push('/admin/telemetry'),
            ),
            _NavItem(
              icon: LucideIcons.scrollText,
              iconColor: AdminColors.textSecondary,
              label: 'Nhật ký truy cập',
              meta: 'API access logs theo ngày',
              onTap: () => context.push('/admin/access-logs'),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Stat chip — horizontal scroll item ────────────────────────────────────────
class _Stat {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
}

class _StatChip extends StatelessWidget {
  final _Stat stat;
  const _StatChip({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          top: BorderSide(color: stat.color, width: 2),
          left: BorderSide(color: AdminColors.border),
          right: BorderSide(color: AdminColors.border),
          bottom: BorderSide(color: AdminColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            stat.value,
            style: GoogleFonts.robotoMono(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: stat.color,
            ),
          ),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 10, color: AdminColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Nav group container ────────────────────────────────────────────────────────
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
          final i    = e.key;
          final item = e.value;
          return Column(
            children: [
              if (i > 0)
                Container(height: 0.5, color: AdminColors.border,
                    margin: const EdgeInsets.only(left: 48)),
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
        splashColor: AppTheme.kPrimary.withValues(alpha: 0.06),
        highlightColor: AppTheme.kPrimary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // Icon with subtle surface bg
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(item.icon, size: 15, color: item.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: const TextStyle(
                  color: AdminColors.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 1),
                Text(item.meta, style: const TextStyle(
                  color: AdminColors.textMuted, fontSize: 11,
                )),
              ],
            )),
            if (item.badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.warning,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('${item.badge}', style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700,
                )),
              ),
            ] else
              const Icon(LucideIcons.chevronRight, size: 14, color: AdminColors.textMuted),
          ]),
        ),
      ),
    );
  }
}

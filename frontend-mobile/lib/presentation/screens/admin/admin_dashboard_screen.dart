import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

/// AdminDashboardScreen — Tổng quan hệ thống dành cho Admin.
/// KPI tiles (users, doctors, pending reviews, keywords, combos)
/// + quick-nav shortcuts tới các màn hình quản trị.
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

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final name  = authState is Authenticated ? (authState.user.name  ?? 'Admin') : 'Admin';
    final email = authState is Authenticated ? (authState.user.email ?? '')       : '';

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
            return _buildContent(context, state, name, email);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AdminDashboardLoaded data,
    String name,
    String email,
  ) {
    return RefreshIndicator(
      color: AppTheme.kPrimary,
      onRefresh: () async => context.read<AdminBloc>().add(LoadAdminDashboard()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // ── Profile header ─────────────────────────────────────────────────
          _buildHeader(name, email),
          const SizedBox(height: 24),

          // ── KPI grid ───────────────────────────────────────────────────────
          _sectionTitle('TỔNG QUAN HỆ THỐNG', LucideIcons.layoutDashboard),
          const SizedBox(height: 10),
          _buildKpiGrid(data),
          const SizedBox(height: 28),

          // ── Quick nav ──────────────────────────────────────────────────────
          _sectionTitle('TRUY CẬP NHANH', LucideIcons.zap),
          const SizedBox(height: 10),
          _buildNavSection(context, data),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: TextStyle(
                    color: AppTheme.kPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                    color: AdminColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
                  if (email.isNotEmpty)
                    Text(email, style: const TextStyle(
                      color: AdminColors.textMuted, fontSize: 12,
                    )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.25)),
              ),
              child: Text('ADMIN', style: TextStyle(
                color: AppTheme.kPrimary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Icon(icon, size: 11, color: AdminColors.textMuted),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(
      color: AdminColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    )),
  ]);

  Widget _buildKpiGrid(AdminDashboardLoaded data) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.65,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _KpiTile(
          label: 'Người dùng',
          value: '${data.userCount}',
          icon: LucideIcons.users,
          color: AppTheme.kPrimary,
        ),
        _KpiTile(
          label: 'Bác sĩ',
          value: '${data.doctorCount}',
          icon: LucideIcons.stethoscope,
          color: AppTheme.kPrimary,
        ),
        _KpiTile(
          label: 'Chờ duyệt AI',
          value: '${data.pendingReviewCount}',
          icon: LucideIcons.clipboardCheck,
          color: data.pendingReviewCount > 0 ? AdminColors.warning : AppTheme.kPrimary,
          highlight: data.pendingReviewCount > 0,
        ),
        _KpiTile(
          label: 'Từ khóa an toàn',
          value: '${data.activeKeywordCount}',
          icon: LucideIcons.shield,
          color: AppTheme.kPrimary,
        ),
        _KpiTile(
          label: 'Combo rules',
          value: '${data.activeComboCount}',
          icon: LucideIcons.layers,
          color: AppTheme.kPrimary,
        ),
      ],
    );
  }

  Widget _buildNavSection(BuildContext context, AdminDashboardLoaded data) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _NavRow(
            icon: LucideIcons.users,
            label: 'Quản lý người dùng',
            subtitle: '${data.userCount} tài khoản · ${data.doctorCount} bác sĩ',
            onTap: () => context.push('/admin/users'),
          ),
          _divider(),
          _NavRow(
            icon: LucideIcons.clipboardCheck,
            label: 'Duyệt đề xuất AI',
            subtitle: data.pendingReviewCount > 0
                ? '${data.pendingReviewCount} chờ duyệt'
                : 'Không có mục nào chờ',
            badge: data.pendingReviewCount > 0 ? data.pendingReviewCount : null,
            onTap: () => context.push('/admin/review-queue'),
          ),
          _divider(),
          _NavRow(
            icon: LucideIcons.shield,
            label: 'Từ khóa an toàn',
            subtitle: '${data.activeKeywordCount} đang hoạt động',
            onTap: () => context.push('/admin/keywords'),
          ),
          _divider(),
          _NavRow(
            icon: LucideIcons.layers,
            label: 'Quy tắc tổ hợp',
            subtitle: '${data.activeComboCount} rules',
            onTap: () => context.push('/admin/combos'),
          ),
          _divider(),
          _NavRow(
            icon: LucideIcons.database,
            label: 'Giám sát hệ thống',
            subtitle: 'Cache · Audit log',
            onTap: () => context.push('/admin/telemetry'),
          ),
          _divider(),
          _NavRow(
            icon: LucideIcons.history,
            label: 'Nhật ký truy cập',
            subtitle: 'API access logs',
            onTap: () => context.push('/admin/access-logs'),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 0.5, color: AdminColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16));
}

// ── KPI tile ──────────────────────────────────────────────────────────────────
class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AdminColors.warning.withValues(alpha: 0.08)
            : AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AdminColors.warning.withValues(alpha: 0.4)
              : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 16, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
              Text(label, style: const TextStyle(
                color: AdminColors.textMuted, fontSize: 11,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav row ───────────────────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final int? badge;
  final VoidCallback onTap;
  const _NavRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.kPrimary.withValues(alpha: 0.06),
      highlightColor: AppTheme.kPrimary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 18, color: AdminColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                color: AdminColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500,
              )),
              Text(subtitle, style: const TextStyle(
                color: AdminColors.textMuted, fontSize: 11,
              )),
            ],
          )),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AdminColors.warning,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$badge', style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
              )),
            ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, size: 16, color: AdminColors.textMuted),
        ]),
      ),
    );
  }
}

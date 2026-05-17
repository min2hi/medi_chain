import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

/// ClinicSystemScreen — Hệ thống & Quản trị (chỉ ADMIN).
/// Gom toàn bộ admin sub-screens vào 1 màn hình có card navigation.
class ClinicSystemScreen extends StatelessWidget {
  const ClinicSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final name = authState is Authenticated
        ? (authState.user.name ?? 'Admin')
        : 'Admin';

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(name)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSection(
                    context,
                    title: 'DUYỆT & KIỂM SOÁT',
                    items: [
                      _SystemNavItem(
                        icon: Icons.rate_review_rounded,
                        label: 'Duyệt Đề Xuất AI',
                        subtitle: 'Keyword chờ phê duyệt từ Semantic Discovery',
                        color: AdminColors.warning,
                        onTap: () => context.push('/admin/review-queue'),
                        badge: '1',
                      ),
                      _SystemNavItem(
                        icon: Icons.history_rounded,
                        label: 'Nhật Ký Hoạt Động',
                        subtitle: 'Audit log toàn bộ API access',
                        color: AdminColors.info,
                        onTap: () => context.push('/admin/access-logs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSection(
                    context,
                    title: 'TRI THỨC LÂM SÀNG',
                    items: [
                      _SystemNavItem(
                        icon: Icons.shield_rounded,
                        label: 'Từ Khóa An Toàn',
                        subtitle: 'Quản lý keyword cảnh báo khẩn cấp',
                        color: AdminColors.danger,
                        onTap: () => context.push('/admin/keywords'),
                      ),
                      _SystemNavItem(
                        icon: Icons.alt_route_rounded,
                        label: 'Quy Tắc Tổ Hợp',
                        subtitle: 'Combo rules phát hiện bệnh lý phức hợp',
                        color: AdminColors.purple,
                        onTap: () => context.push('/admin/combos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSection(
                    context,
                    title: 'NGƯỜI DÙNG & HỆ THỐNG',
                    items: [
                      _SystemNavItem(
                        icon: Icons.manage_accounts_rounded,
                        label: 'Quản Lý Người Dùng',
                        subtitle: 'Xem, phân quyền, khóa tài khoản',
                        color: AdminColors.aiPrimary,
                        onTap: () => context.push('/admin/users'),
                      ),
                      _SystemNavItem(
                        icon: Icons.monitor_heart_rounded,
                        label: 'Giám Sát Hệ Thống',
                        subtitle: 'AI telemetry, token usage, performance',
                        color: AdminColors.success,
                        onTap: () => context.push('/admin/telemetry'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLogoutButton(context),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hệ Thống',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              Text(
                'Cấu hình & quản trị nền tảng',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_SystemNavItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdminColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildNavRow(context, item),
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      color: AdminColors.border,
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavRow(BuildContext context, _SystemNavItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (item.badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.badge!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AdminColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: AdminColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          getIt<AuthBloc>().add(LogoutRequested());
          context.go('/login');
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AdminColors.danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded,
                  color: AdminColors.danger, size: 18),
              const SizedBox(width: 8),
              Text(
                'Đăng xuất',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemNavItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _SystemNavItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

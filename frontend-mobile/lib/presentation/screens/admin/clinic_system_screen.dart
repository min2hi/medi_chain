import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

/// ClinicSystemScreen — redesigned.
/// Settings-style list: monochrome icons, no rainbow colors, clean grouped rows.
class ClinicSystemScreen extends StatelessWidget {
  const ClinicSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final name = authState is Authenticated ? (authState.user.name ?? 'Admin') : 'Admin';
    final email = authState is Authenticated ? (authState.user.email ?? '') : '';

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildProfile(name, email),
            Expanded(
              child: ListView(
                children: [
                  _SectionLabel('DUYỆT & KIỂM SOÁT'),
                  _NavRow(
                    label: 'Duyệt đề xuất AI',
                    subtitle: 'Keyword chờ phê duyệt',
                    icon: Icons.rate_review_outlined,
                    onTap: () => context.push('/admin/review-queue'),
                  ),
                  _NavRow(
                    label: 'Nhật ký hoạt động',
                    subtitle: 'Nhật ký truy cập hệ thống',
                    icon: Icons.history_rounded,
                    onTap: () => context.push('/admin/access-logs'),
                  ),
                  _SectionLabel('TRI THỨC LÂM SÀNG'),
                  _NavRow(
                    label: 'Từ khóa an toàn',
                    subtitle: 'Keyword cảnh báo khẩn cấp',
                    icon: Icons.shield_outlined,
                    onTap: () => context.push('/admin/keywords'),
                  ),
                  _NavRow(
                    label: 'Quy tắc tổ hợp',
                    subtitle: 'Combo rules phát hiện bệnh lý',
                    icon: Icons.device_hub_outlined,
                    onTap: () => context.push('/admin/combos'),
                  ),
                  _SectionLabel('NGƯỜI DÙNG & HỆ THỐNG'),
                  _NavRow(
                    label: 'Quản lý người dùng',
                    subtitle: 'Xem, phân quyền, khóa tài khoản',
                    icon: Icons.manage_accounts_outlined,
                    onTap: () => context.push('/admin/users'),
                  ),
                  _NavRow(
                    label: 'Giám sát hệ thống',
                    subtitle: 'Giám sát AI & mức dùng token',
                    icon: Icons.monitor_outlined,
                    onTap: () => context.push('/admin/telemetry'),
                  ),
                  const SizedBox(height: 8),
                  _buildLogout(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(String name, String email) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          // Clean monochrome avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminColors.elevated,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AdminColors.border),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                  ),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'ADMIN',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.kPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: () {
          getIt<AuthBloc>().add(LogoutRequested());
          context.go('/login');
        },
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 0),
          side: BorderSide(color: AdminColors.danger.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 16),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
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
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Monochrome icon — no color background
                  Icon(icon, size: 20, color: AdminColors.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AdminColors.textMuted),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AdminColors.border, indent: 54),
      ],
    );
  }
}

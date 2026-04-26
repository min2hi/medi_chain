import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final userName  = authState is Authenticated ? authState.user.name ?? 'Admin' : 'Admin';
    final userRole  = authState is Authenticated ? (authState.user.role ?? 'ADMIN') : 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Admin Portal',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1E293B), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── User info banner ──────────────────────────────────────────────
          _buildUserBanner(context, userName, userRole),
          const SizedBox(height: 24),

          // ── Phê duyệt AI ─────────────────────────────────────────────────
          _buildSectionLabel('PHÊ DUYỆT AI'),
          const SizedBox(height: 10),
          _buildAdminCard(
            title: 'Review Queue',
            subtitle: 'Từ khóa chờ phê duyệt',
            icon: LucideIcons.layers,
            color: const Color(0xFF3B82F6),
            onTap: () => context.push('/admin/review-queue'),
          ),

          const SizedBox(height: 24),

          // ── Tri thức lâm sàng ─────────────────────────────────────────────
          _buildSectionLabel('TRI THỨC LÂM SÀNG'),
          const SizedBox(height: 10),
          _buildAdminCard(
            title: 'Safety Keywords',
            subtitle: 'Từ điển khẩn cấp',
            icon: LucideIcons.book,
            color: const Color(0xFF10B981),
            onTap: () => context.push('/admin/keywords'),
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            title: 'Combo Rules',
            subtitle: 'Luật tổ hợp triệu chứng',
            icon: LucideIcons.zap,
            color: const Color(0xFFF59E0B),
            onTap: () => context.push('/admin/combos'),
          ),

          const SizedBox(height: 24),

          // ── Hệ thống & Quản trị ───────────────────────────────────────────
          _buildSectionLabel('HỆ THỐNG & QUẢN TRỊ'),
          const SizedBox(height: 10),
          _buildAdminCard(
            title: 'Telemetry',
            subtitle: 'Logs & Hiệu suất hệ thống',
            icon: LucideIcons.barChart3,
            color: const Color(0xFF8B5CF6),
            onTap: () => context.push('/admin/telemetry'),
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            title: 'Quản lý người dùng',
            subtitle: 'Phân quyền tài khoản',
            icon: LucideIcons.users,
            color: const Color(0xFFEC4899),
            onTap: () => context.push('/admin/users'),
          ),

          const SizedBox(height: 32),

          // ── Về Patient Portal — 1 link text, clean và không phô trương ───
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(LucideIcons.arrowLeft, size: 13, color: Color(0xFF475569)),
                SizedBox(width: 6),
                Text(
                  'Về Patient Portal',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── User info banner (chỉ hiển thị, không có nút switch thừa) ────────────
  Widget _buildUserBanner(BuildContext context, String name, String role) {
    final isAdmin = role.toUpperCase() == 'ADMIN';
    final roleColor = isAdmin ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final roleLabel = isAdmin ? 'ADMIN' : 'DOCTOR';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(children: [
        // Avatar với shield badge
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: roleColor.withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          Positioned(
            bottom: -2, right: -2,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: roleColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              ),
              child: const Icon(Icons.shield, size: 8, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        // Name + role badge
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: roleColor.withOpacity(0.25)),
              ),
              child: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        // Đường phân tách
        Container(width: 1, height: 36, color: const Color(0xFF334155)),
        const SizedBox(width: 14),
        // Icon shield — visual indicator, không thêm nút thừa
        const Icon(LucideIcons.shieldCheck, color: Color(0xFF475569), size: 18),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    ),
  );

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF334155), size: 13),
          ]),
        ),
      ),
    );
  }
}

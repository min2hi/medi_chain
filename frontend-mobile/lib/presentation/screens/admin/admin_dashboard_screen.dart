import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          // ── Header badge ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF312E81).withOpacity(0.5)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF818CF8), size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Admin Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('MediChain Clinical Rules Engine', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ]),
              ),
            ]),
          ),

          // ── Phê duyệt AI ─────────────────────────────────────────────────
          const Text(
            'PHÊ DUYỆT AI',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Review Queue',
            subtitle: 'Từ khóa chờ phê duyệt',
            icon: LucideIcons.layers,
            color: const Color(0xFF3B82F6),
            onTap: () => context.push('/admin/review-queue'),
          ),

          const SizedBox(height: 24),

          // ── Tri thức lâm sàng ─────────────────────────────────────────────
          const Text(
            'TRI THỨC LÂM SÀNG',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Safety Keywords',
            subtitle: 'Từ điển khẩn cấp',
            icon: LucideIcons.book,
            color: const Color(0xFF10B981),
            onTap: () => context.push('/admin/keywords'),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Combo Rules',
            subtitle: 'Luật tổ hợp triệu chứng',
            icon: LucideIcons.zap,
            color: const Color(0xFFF59E0B),
            onTap: () => context.push('/admin/combos'),
          ),

          const SizedBox(height: 24),

          // ── Hệ thống & Quản trị ───────────────────────────────────────────
          const Text(
            'HỆ THỐNG & QUẢN TRỊ',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Telemetry',
            subtitle: 'Logs & Hiệu suất hệ thống',
            icon: LucideIcons.barChart3,
            color: const Color(0xFF8B5CF6),
            onTap: () => context.push('/admin/telemetry'),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Quản lý người dùng',
            subtitle: 'Phân quyền tài khoản',
            icon: LucideIcons.users,
            color: const Color(0xFFEC4899),
            onTap: () => context.push('/admin/users'),
          ),
        ],
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF475569), size: 14),
          ]),
        ),
      ),
    );
  }
}

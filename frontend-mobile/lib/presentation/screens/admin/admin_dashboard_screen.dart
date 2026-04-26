import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _openWebPortal(String path) async {
    // Production URL (tương tự như cấu hình _kProductionUrl)
    final uri = Uri.parse('https://medichain-frontend.vercel.app/admin$path');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900 (theme web)
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617), // Slate 950
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
          child: Container(color: const Color(0xFF1E293B), height: 1), // Slate 800
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'PHÊ DUYỆT AI',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Review Queue',
            subtitle: 'Từ khóa chờ phê duyệt',
            icon: LucideIcons.layers,
            color: const Color(0xFF3B82F6), // Blue
            onTap: () => _openWebPortal('/clinical-rules'),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'TRI THỨC LÂM SÀNG',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Safety Keywords',
            subtitle: 'Từ điển khẩn cấp',
            icon: LucideIcons.book,
            color: const Color(0xFF10B981), // Emerald
            onTap: () => _openWebPortal('/clinical-rules/keywords'),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Combo Rules',
            subtitle: 'Luật tổ hợp triệu chứng',
            icon: LucideIcons.zap,
            color: const Color(0xFFF59E0B), // Amber
            onTap: () => _openWebPortal('/clinical-rules/combos'),
          ),

          const SizedBox(height: 24),
          const Text(
            'HỆ THỐNG & QUẢN TRỊ',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Telemetry',
            subtitle: 'Logs & Hiệu suất hệ thống',
            icon: LucideIcons.barChart3,
            color: const Color(0xFF8B5CF6), // Violet
            onTap: () => _openWebPortal('/telemetry'),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Quản lý người dùng',
            subtitle: 'Phân quyền tài khoản',
            icon: LucideIcons.users,
            color: const Color(0xFFEC4899), // Pink
            onTap: () => _openWebPortal('/users'),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: 'Cấu hình',
            subtitle: 'Ngưỡng an toàn & Rate limit',
            icon: LucideIcons.settings2,
            color: const Color(0xFF06B6D4), // Cyan
            onTap: () => _openWebPortal('/config'),
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
            color: const Color(0xFF1E293B), // Slate 800
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)), // Slate 700
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF475569), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

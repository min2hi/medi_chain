import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionItem(
            context,
            'Thêm hồ sơ',
            LucideIcons.filePlus,
            const Color(0xFF14B8A6),
            onTap: () => context.push('/record-form'),
          ),
          const SizedBox(width: 12),
          _buildActionItem(
            context,
            'Thêm thuốc',
            LucideIcons.pill,
            const Color(0xFF10B981),
            onTap: () => context.push('/medicine-form'),
          ),
          const SizedBox(width: 12),
          _buildActionItem(
            context,
            'Đặt lịch hẹn',
            LucideIcons.calendarPlus,
            const Color(0xFF8B5CF6),
            onTap: () => context.push('/appointments'),
          ),
          const SizedBox(width: 12),
          _buildActionItem(
            context,
            'Chỉ số mới',
            LucideIcons.activity,
            const Color(0xFFF59E0B),
            onTap: () => context.push('/metrics'),
          ),
          const SizedBox(width: 12),
          _buildActionItem(
            context,
            'Chia sẻ',
            LucideIcons.share2,
            const Color(0xFF0EA5E9),
            onTap: () => context.push('/sharing'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

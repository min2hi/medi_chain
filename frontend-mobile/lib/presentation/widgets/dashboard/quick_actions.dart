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
            Color(0xFF14B8A6),
            onTap: () => context.push('/record-form'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'Thêm thuốc',
            LucideIcons.pill,
            Color(0xFF10B981),
            onTap: () => context.push('/medicine-form'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'Đặt lịch hẹn',
            LucideIcons.calendarPlus,
            Color(0xFF8B5CF6),
            onTap: () => context.push('/appointments'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'Chỉ số mới',
            LucideIcons.activity,
            Color(0xFFF59E0B),
            onTap: () => context.push('/metrics'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'Chia sẻ',
            LucideIcons.share2,
            Color(0xFF0EA5E9),
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
    Color unusedColor, {
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(100), // Pill shape
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF0D9488), // Unified primary color
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

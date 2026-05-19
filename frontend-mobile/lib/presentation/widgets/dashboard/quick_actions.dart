import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
            'ThÃªm há»“ sÆ¡',
            LucideIcons.filePlus,
            onTap: () => context.push('/record-form'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'ThÃªm thuá»‘c',
            LucideIcons.pill,
            onTap: () => context.push('/medicine-form'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'Äáº·t lá»‹ch háº¹n',
            LucideIcons.calendarPlus,
            onTap: () => context.go('/appointments'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'Chá»‰ sá»‘ má»›i',
            LucideIcons.activity,
            onTap: () => context.push('/metrics'),
          ),
          SizedBox(width: 12),
          _buildActionItem(
            context,
            'Chia sáº»',
            LucideIcons.share2,
            onTap: () => context.push('/sharing'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF0D9488), size: 18),
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

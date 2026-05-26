import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

class ActivityCard extends StatelessWidget {
  final List<ActivityItem>? activities;

  const ActivityCard({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder để rebuild ngay khi theme toggle — không cần reload trang
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeNotifier.mode,
      builder: (context, mode, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconBg = isDark ? const Color(0xFF182030) : const Color(0xFFF1F5F9);
        final iconColor = isDark ? const Color(0xFF8A9BB5) : const Color(0xFF64748B);
        final connectorColor = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);
        final cardBg = isDark ? const Color(0xFF182030) : Colors.white;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.history,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Hoạt động gần đây',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0D1520),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (activities == null || activities!.isEmpty)
                Text(
                  'Chưa có hoạt động nào được ghi nhận.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF4E6280) : AppTheme.kTextMuted,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Column(
                  children: activities!
                      .take(5)
                      .map((activity) => _buildActivityTile(
                            context,
                            activity,
                            isDark: isDark,
                            connectorColor: connectorColor,
                          ))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // Lấy icon theo type hoạt động
  IconData _iconForType(String? type) {
    switch (type) {
      case 'medicine':
        return LucideIcons.pill;
      case 'appointment':
        return LucideIcons.calendarCheck;
      case 'record':
      default:
        return LucideIcons.fileText;
    }
  }

  // Lấy màu accent theo type — một màu brand duy nhất, phân biệt bằng icon
  Color _accentForType(String? type, bool isDark) {
    return isDark ? AppTheme.kPrimary : AppTheme.kPrimaryDark;
  }

  Widget _buildActivityTile(
    BuildContext context,
    ActivityItem activity, {
    required bool isDark,
    required Color connectorColor,
  }) {
    final accent = _accentForType(activity.type, isDark);
    final icon = _iconForType(activity.type);
    final isLast = activities!.indexOf(activity) == (activities!.length > 5 ? 4 : activities!.length - 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column: dot + connector line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.15 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 24,
                    color: connectorColor,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF182030),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF8A9BB5) : AppTheme.kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


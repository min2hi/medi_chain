import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

class AdminNavItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String meta;
  final int? badge;
  final VoidCallback onTap;

  const AdminNavItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.meta,
    required this.onTap,
    this.badge,
  });
}

class AdminNavGroup extends StatelessWidget {
  final List<AdminNavItem> items;

  const AdminNavGroup({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AdminColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              if (i > 0)
                Container(
                  height: 0.5,
                  color: AdminColors.border,
                  margin: const EdgeInsets.only(left: 50),
                ),
              _NavRowTile(item: item),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NavRowTile extends StatelessWidget {
  final AdminNavItem item;

  const _NavRowTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            // Icon container — consistent 34×34 tap target
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(item.icon, size: 15, color: item.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      color: AdminColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.meta,
                    style: GoogleFonts.inter(
                      color: AdminColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.warning,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.badge}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: AdminColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

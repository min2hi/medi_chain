import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

class AdminStatTile {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool hasBadge;
  final bool isReadOnly;
  final String? detail;

  const AdminStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.hasBadge = false,
    this.isReadOnly = false,
    this.detail,
  });
}

class AdminStatTileWidget extends StatelessWidget {
  final AdminStatTile tile;
  final VoidCallback? onTap;

  const AdminStatTileWidget({
    super.key,
    required this.tile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Indicator/Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(tile.icon, size: 16, color: tile.accent),
                if (tile.hasBadge)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tile.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Large Value
            Text(
              tile.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tile.accent,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            // Label + Detail
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tile.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tile.detail != null)
                  Text(
                    tile.detail!,
                    style: TextStyle(
                      fontSize: 9,
                      color: tile.accent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (tile.isReadOnly || onTap == null) {
      return cardContent;
    }

    return ScaleOnTap(
      onTap: onTap,
      child: cardContent,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminColors.surface,
            tile.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Styled Icon Box + Indicator/Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: tile.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tile.accent.withValues(alpha: 0.25), width: 0.8),
                  ),
                  child: Icon(tile.icon, size: 14, color: tile.accent),
                ),
                if (tile.hasBadge)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tile.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tile.accent.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Large Telemetry Value
            Text(
              tile.value,
              style: GoogleFonts.robotoMono(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: tile.accent,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            // Label + Detail Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tile.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AdminColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tile.detail != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tile.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: tile.accent.withValues(alpha: 0.2), width: 0.5),
                    ),
                    child: Text(
                      tile.detail!,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: tile.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
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
      scaleDownFactor: 0.95,
      child: cardContent,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

class ClinicButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final bool compact;
  final IconData? icon;
  final VoidCallback onTap;
  final bool expanded;

  const ClinicButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.compact = false,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: expanded ? double.infinity : null,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: filled
              ? null
              : Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 5 : 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: filled ? Colors.white : color),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

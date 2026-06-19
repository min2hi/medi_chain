import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// Một ActionTile chuyên nghiệp dùng chung cho các màn hình quét (OCR, QR, Scanner).
class ScannerActionTile extends StatelessWidget {
  const ScannerActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primaryColor,
    this.backgroundColor,
    this.borderColor,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Phân giải màu sắc linh hoạt (fallback về hệ màu AppTheme nếu trống)
    final resolvedPrimary = primaryColor ?? AppTheme.kPrimary;
    final resolvedBg = backgroundColor ?? (isDark ? const Color(0xFF182030) : Colors.white);
    final resolvedBorder = borderColor ?? (isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7));

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: isPrimary
            ? Colors.white.withOpacity(0.15)
            : resolvedPrimary.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary ? resolvedPrimary : resolvedBg,
            borderRadius: BorderRadius.circular(10),
            border: isPrimary ? null : Border.all(color: resolvedBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : resolvedPrimary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? Colors.white : resolvedPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget dòng mẹo/hướng dẫn quét dùng chung.
class ScannerTip extends StatelessWidget {
  const ScannerTip({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

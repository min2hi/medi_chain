import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// Section label chuẩn dùng xuyên suốt Admin Portal.
/// Optional: icon bên trái, count badge bên phải.
class AdminSectionHeader extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final int? count;

  const AdminSectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AdminColors.textMuted;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon!, color: color, size: 14),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: const TextStyle(
            color: AdminColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AdminColors.elevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminColors.border),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

enum AdminBadgeType { pending, approved, rejected, info, admin, doctor, patient, system }

/// Status badge chuẩn dùng cho: role, review status, cảnh báo...
/// Vercel-style badge: filled background + colored text + subtle border.
class AdminBadge extends StatelessWidget {
  final String label;
  final AdminBadgeType type;
  final double fontSize;

  const AdminBadge({
    super.key,
    required this.label,
    required this.type,
    this.fontSize = 10,
  });

  Color get _color => switch (type) {
        AdminBadgeType.pending  => AdminColors.warning,
        AdminBadgeType.approved => AdminColors.success,
        AdminBadgeType.rejected => AdminColors.danger,
        AdminBadgeType.info     => AdminColors.info,
        AdminBadgeType.admin    => AdminColors.roleAdmin,
        AdminBadgeType.doctor   => AdminColors.roleDoctor,
        AdminBadgeType.patient  => AdminColors.rolePatient,
        AdminBadgeType.system   => AdminColors.purple,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

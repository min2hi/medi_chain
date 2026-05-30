import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

class RoleBoundaryNote extends StatelessWidget {
  const RoleBoundaryNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 12, color: AdminColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lịch hẹn do Bác sĩ quản lý trực tiếp. Admin chỉ xem thống kê tổng hợp.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AdminColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

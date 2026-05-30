import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

class DoctorQuickActions extends StatelessWidget {
  final int pendingCount;
  final int confirmedCount;
  final VoidCallback onTapNext;
  final VoidCallback onTapPending;
  final VoidCallback onWriteRx;
  final VoidCallback onScanQr;

  const DoctorQuickActions({
    super.key,
    required this.pendingCount,
    required this.confirmedCount,
    required this.onTapNext,
    required this.onTapPending,
    required this.onWriteRx,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              'THAO TÁC NHANH',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.kTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Row(
            children: [
              _QuickActionBtn(
                icon: LucideIcons.stethoscope,
                label: 'Khám tiếp',
                color: AppTheme.kPrimary,
                onTap: onTapNext,
              ),
              const SizedBox(width: 8),
              _QuickActionBtn(
                icon: LucideIcons.checkCircle,
                label: 'Xác nhận',
                color: AppTheme.kPrimary,
                badge: pendingCount > 0 ? '$pendingCount' : null,
                onTap: onTapPending,
              ),
              const SizedBox(width: 8),
              _QuickActionBtn(
                icon: LucideIcons.clipboardCheck,
                label: 'Kê đơn',
                color: AppTheme.kPrimary,
                badge: confirmedCount > 0 ? '$confirmedCount' : null,
                onTap: onWriteRx,
              ),
              const SizedBox(width: 8),
              _QuickActionBtn(
                icon: LucideIcons.scanLine,
                label: 'Scan QR',
                color: AppTheme.kPrimary,
                onTap: onScanQr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleOnTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppTheme.kBorder,
              width: 1,
            ),
            boxShadow: AppShadow.card,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.kError,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kError.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kTextPrimary,
                      letterSpacing: -0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

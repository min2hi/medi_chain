import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/pulsing_dot.dart';

class NextPatientCard extends StatelessWidget {
  final Map<String, dynamic> apt;
  final VoidCallback onStart;

  const NextPatientCard({
    super.key,
    required this.apt,
    required this.onStart,
  });

  String _countdown(DateTime t) {
    final diff = t.difference(DateTime.now());
    if (diff.isNegative) {
      return diff.inMinutes > -45 ? 'Đang diễn ra' : 'Đã qua';
    }
    if (diff.inHours >= 1) {
      final m = diff.inMinutes % 60;
      return 'Còn ${diff.inHours}g${m.toString().padLeft(2, '0')}p';
    }
    return 'Còn ${diff.inMinutes} phút';
  }

  Color _cColor(DateTime t) {
    final diff = t.difference(DateTime.now());
    if (diff.isNegative) return AppTheme.kSuccess;
    if (diff.inMinutes <= 15) return AppTheme.kDanger;
    if (diff.inMinutes <= 30) return AppTheme.kWarning;
    return AppTheme.kInfo;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title = apt['title'] as String? ?? 'Khám dịch vụ';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final countdown = _countdown(date);
    final cColor = _cColor(date);
    final inProgress = date.difference(DateTime.now()).isNegative &&
        date.difference(DateTime.now()).inMinutes > -45;

    final parts = patientName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : patientName.substring(0, patientName.length.clamp(0, 2)).toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.kSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: const BorderSide(color: AppTheme.kPrimary, width: 3),
            top: const BorderSide(color: AppTheme.kBorder),
            right: const BorderSide(color: AppTheme.kBorder),
            bottom: const BorderSide(color: AppTheme.kBorder),
          ),
          boxShadow: AppShadow.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: label + countdown badge
              Row(
                children: [
                  const Icon(LucideIcons.userRound, size: 11, color: AppTheme.kPrimary),
                  const SizedBox(width: 5),
                  Text(
                    'BỆNH NHÂN TIẾP THEO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kPrimary,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: cColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (inProgress)
                          PulsingDot(color: cColor, size: 5)
                        else
                          Icon(LucideIcons.clock, size: 9, color: cColor),
                        const SizedBox(width: 4),
                        Text(
                          countdown,
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Patient info row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.kPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.kTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: SizedBox(
                                width: 3,
                                height: 3,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppTheme.kTextMuted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // CTA button with scale transition on press
              ScaleOnTap(
                onTap: onStart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: AppShadow.primaryGlow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        inProgress ? 'Tiếp tục khám' : 'Bắt đầu khám',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/pulsing_dot.dart';

class DoctorHeader extends StatelessWidget {
  final String greeting;
  final String shortDate;
  final String doctorName;
  final int todayCount;
  final int pendingCount;
  final int confirmedCount;
  final int doneCount;

  const DoctorHeader({
    super.key,
    required this.greeting,
    required this.shortDate,
    required this.doctorName,
    required this.todayCount,
    required this.pendingCount,
    required this.confirmedCount,
    required this.doneCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      DoctorHeaderStat('Hôm nay', todayCount, AppTheme.kPrimary),
      DoctorHeaderStat('Chờ duyệt', pendingCount, AppTheme.kPrimary),
      DoctorHeaderStat('Xác nhận', confirmedCount, AppTheme.kPrimary),
      DoctorHeaderStat('Xong', doneCount, AppTheme.kPrimary),
    ];

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role badge + online status + settings button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'BÁC SĨ',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const PulsingDot(color: AppTheme.kSuccess, size: 6),
                  const SizedBox(width: 6),
                  Text(
                    'Trực tuyến',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kSuccess,
                    ),
                  ),
                  const SizedBox(width: 14),
                  ScaleOnTap(
                    onTap: () => context.push('/settings'),
                    child: Material(
                      color: AppTheme.kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      clipBehavior: Clip.antiAlias,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          LucideIcons.settings,
                          size: 20,
                          color: AppTheme.kPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                greeting,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.kTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Dr. $doctorName',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.kTextPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                shortDate,
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: AppTheme.kTextMuted,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: StatChip(stat: stats[0])),
                  const SizedBox(width: 8),
                  Expanded(child: StatChip(stat: stats[1])),
                  const SizedBox(width: 8),
                  Expanded(child: StatChip(stat: stats[2])),
                  const SizedBox(width: 8),
                  Expanded(child: StatChip(stat: stats[3])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorHeaderStat {
  final String label;
  final int value;
  final Color color;
  const DoctorHeaderStat(this.label, this.value, this.color);
}

class StatChip extends StatelessWidget {
  final DoctorHeaderStat stat;
  const StatChip({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppTheme.kBorder,
        ),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${stat.value}',
            style: GoogleFonts.robotoMono(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.kPrimary,
            ),
          ),
          Text(
            stat.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.kTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

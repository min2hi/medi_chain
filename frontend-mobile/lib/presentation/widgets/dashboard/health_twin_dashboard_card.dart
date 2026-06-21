import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/health_twin/health_twin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

class HealthTwinDashboardCard extends StatelessWidget {
  const HealthTwinDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final border  = isDark ? const Color(0xFF2D3F55) : AppTheme.kBorder;

    return BlocBuilder<HealthTwinBloc, HealthTwinState>(
      builder: (context, state) {
        if (state is HealthTwinLoading) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: border),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kPrimary),
              ),
            ),
          );
        }

        if (state is HealthTwinLoaded) {
          final status = state.status;
          final hasScore = status.recentScore != null;
          final score = status.recentScore ?? 0.0;
          final trend = status.trendPercent ?? 0.0;
          final anomaliesCount = status.recentAnomalies.length;

          // Color palette dựa trên score
          Color scoreColor = const Color(0xFF10B981); // Emerald
          if (score < 50) {
            scoreColor = const Color(0xFFEF4444); // Red
          } else if (score < 75) {
            scoreColor = const Color(0xFFF59E0B); // Amber
          }

          return Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: border),
              boxShadow: isDark ? null : AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.kPrimaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          size: 15,
                          color: AppTheme.kPrimaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Bóng Sức Khỏe AI',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE2E8F0) : AppTheme.kTextPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const Spacer(),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: status.isStable
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.isStable ? 'Ổn định' : 'Đang học baseline',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: status.isStable
                                ? const Color(0xFF065F46)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: border),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Vòng tròn điểm hoặc Avatar AI minh họa
                      if (hasScore)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: scoreColor.withOpacity(0.2), width: 6),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                score.toStringAsFixed(0),
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                              Text(
                                'Điểm',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.kPrimaryLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.fingerprint,
                            size: 28,
                            color: AppTheme.kPrimaryDark,
                          ),
                        ),
                      const SizedBox(width: 16),

                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasScore) ...[
                              Text(
                                trend >= 0
                                    ? 'Cải thiện +${trend.toStringAsFixed(1)}% baseline'
                                    : 'Giảm nhẹ ${trend.toStringAsFixed(1)}% baseline',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: trend >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                anomaliesCount > 0
                                    ? 'Phát hiện $anomaliesCount dị thường cần lưu ý'
                                    : 'Chưa phát hiện dị thường nào',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: anomaliesCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Bóng AI đang học baseline',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFE2E8F0) : AppTheme.kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hãy tiếp tục đo chỉ số và check-in mỗi ngày.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Nút đi tiếp
                      ScaleOnTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('/health-twin');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.kPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Xem Bóng',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

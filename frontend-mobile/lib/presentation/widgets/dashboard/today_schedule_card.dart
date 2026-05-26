import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

class TodayScheduleCard extends StatelessWidget {
  final DashboardStats? stats;
  const TodayScheduleCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final upcomingAppointment = stats?.upcomingAppointment;
    final medicines = stats?.medicines ?? [];
    final medicineCount = stats?.medicineCount ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surface = isDark ? const Color(0xFF182030) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3A50) : AppTheme.kBorder;
    final textPrimary = isDark ? const Color(0xFFE2E8F0) : AppTheme.kTextPrimary;
    final textMuted = isDark ? const Color(0xFF64748B) : AppTheme.kTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.kPrimary.withValues(alpha: 0.12)
                      : AppTheme.kPrimaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  LucideIcons.calendar,
                  color: AppTheme.kPrimaryDark,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lịch trình hôm nay',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),

          // ── Upcoming appointment ──
          if (upcomingAppointment != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.kPrimaryDark.withValues(alpha: 0.08)
                    : AppTheme.kPrimaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark
                      ? AppTheme.kPrimaryDark.withValues(alpha: 0.20)
                      : AppTheme.kPrimaryDark.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 15,
                    color: AppTheme.kPrimaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tái khám sắp tới',
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${upcomingAppointment.title} — ${DateFormat('dd/MM/yyyy').format(DateTime.parse(upcomingAppointment.date))}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Medicine list ──
          if (medicineCount > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Đang theo dõi $medicineCount loại thuốc điều trị',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: medicines.map((m) => _buildMedicineTile(m, textPrimary, isDark)).toList(),
            ),
          ] else if (upcomingAppointment == null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'Không có lịch hẹn hay đơn thuốc nào hôm nay.',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicineTile(MedicineSummary med, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.kPrimary : AppTheme.kPrimaryDark,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${med.name}${med.dosage != null ? ' · ${med.dosage}' : ''}${med.frequency != null ? ' · ${med.frequency}' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

class DoctorWeeklyLoad extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;

  const DoctorWeeklyLoad({
    super.key,
    required this.appointments,
  });

  // Help calculate load count for a specific date
  int _getLoadForDate(DateTime targetDate) {
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return appointments.where((apt) {
      final aptDateRaw = apt['date'] as String?;
      if (aptDateRaw == null) return false;
      final parsed = DateTime.tryParse(aptDateRaw)?.toLocal();
      if (parsed == null) return false;
      final aptDate = DateTime(parsed.year, parsed.month, parsed.day);
      // Only count active appointments (PENDING or CONFIRMED)
      final status = apt['status'] as String? ?? '';
      final isActive = status == 'PENDING' || status == 'CONFIRMED';
      return aptDate == target && isActive;
    }).length;
  }

  String _getWeekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'T2',
      DateTime.tuesday => 'T3',
      DateTime.wednesday => 'T4',
      DateTime.thursday => 'T5',
      DateTime.friday => 'T6',
      DateTime.saturday => 'T7',
      _ => 'CN',
    };
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Generate next 6 days (including today)
    final days = List.generate(6, (index) => today.add(Duration(days: index)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_view_week_rounded,
                  size: 13,
                  color: AppTheme.kTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'LỊCH TRÌNH TUẦN NÀY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.kSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppTheme.kBorder),
              boxShadow: AppShadow.card,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final isCurrentDay = DateTime(day.year, day.month, day.day) == todayDate;
                final count = _getLoadForDate(day);
                final isBusy = count >= 8;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrentDay
                          ? AppTheme.kPrimary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: isCurrentDay
                          ? null
                          : Border.all(
                              color: isBusy
                                  ? AppTheme.kWarning.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getWeekdayLabel(day.weekday),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCurrentDay
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppTheme.kTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isCurrentDay
                                ? Colors.white
                                : AppTheme.kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isCurrentDay
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : isBusy
                                        ? AppTheme.kWarning.withValues(alpha: 0.1)
                                        : AppTheme.kPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrentDay
                                      ? Colors.white
                                      : isBusy
                                          ? AppTheme.kWarning
                                          : AppTheme.kPrimary,
                                ),
                              ),
                            ),
                            if (isBusy && !isCurrentDay)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.kWarning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

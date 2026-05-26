import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

enum BadgeVariant { success, warning, danger, info, neutral }

/// Pill-shaped semantic badge — tất cả status labels dùng widget này,
/// KHÔNG hardcode color inline trong screen.
///
/// Usage:
///   StatusBadge(label: 'Active', variant: BadgeVariant.success)
///   StatusBadge(label: 'Sắp hết', variant: BadgeVariant.warning)
///   StatusBadge(label: 'Đã hủy', variant: BadgeVariant.danger)
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.variant,
    this.dot = false,
    this.small = false,
  });

  final String label;
  final BadgeVariant variant;

  /// Hiện dot (●) trước label — dùng cho realtime indicators
  final bool dot;

  /// Nhỏ hơn bình thường (fontSize 10) — dùng trong list rows
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(variant);
    final fs = small ? 10.0 : 11.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colors.$2.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: colors.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w600,
              color: colors.$2,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns (bgColor, textColor)
  static (Color, Color) _colors(BadgeVariant v) => switch (v) {
        BadgeVariant.success => (AppTheme.kSuccessSurface, AppTheme.kSuccess),
        BadgeVariant.warning => (AppTheme.kWarningSurface, const Color(0xFFD97706)),
        BadgeVariant.danger  => (AppTheme.kDangerSurface,  AppTheme.kDanger),
        BadgeVariant.info    => (AppTheme.kInfoSurface,    AppTheme.kInfo),
        BadgeVariant.neutral => (const Color(0xFFF1F5F9),  AppTheme.kTextSecondary),
      };

  /// Helper: tính variant từ medicine endDate
  static BadgeVariant fromMedicineEnd(String? endDate) {
    if (endDate == null) return BadgeVariant.success;
    final end = DateTime.tryParse(endDate);
    if (end == null) return BadgeVariant.neutral;
    final now = DateTime.now();
    final diff = end.difference(now).inDays;
    if (diff < 0) return BadgeVariant.neutral;   // expired
    if (diff <= 3) return BadgeVariant.danger;    // critical — ≤3 ngày
    if (diff <= 7) return BadgeVariant.warning;   // caution — ≤7 ngày
    return BadgeVariant.success;                  // healthy
  }

  /// Helper: urgency bar color từ medicine endDate
  static Color urgencyColor(String? endDate) {
    final v = fromMedicineEnd(endDate);
    return switch (v) {
      BadgeVariant.danger  => AppTheme.kDanger,
      BadgeVariant.warning => AppTheme.kWarning,
      BadgeVariant.neutral => AppTheme.kTextMuted,
      _                    => AppTheme.kPrimary,
    };
  }
}

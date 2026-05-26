import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

/// Compact alert section — tối đa 2 alerts hiển thị,
/// có "Xem thêm" nếu còn nhiều hơn.
/// Thay thế 3 full-width red banners liên tiếp.
class AlertSection extends StatefulWidget {
  final List<AlertItem> alerts;
  const AlertSection({super.key, required this.alerts});

  @override
  State<AlertSection> createState() => _AlertSectionState();
}

class _AlertSectionState extends State<AlertSection> {
  static const _maxVisible = 2;
  final Set<String> _dismissed = {};

  List<AlertItem> get _visible =>
      widget.alerts.where((a) => !_dismissed.contains(a.id)).toList();

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    if (visible.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shown  = visible.take(_maxVisible).toList();
    final extra  = visible.length - _maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(
              LucideIcons.triangleAlert,
              size: 13,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
            ),
            const SizedBox(width: 6),
            Text(
              'Cảnh báo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Alert pills
        ...shown.map((alert) => _AlertPill(
              alert: alert,
              isDark: isDark,
              onDismiss: () {
                HapticFeedback.lightImpact();
                setState(() => _dismissed.add(alert.id));
              },
            )),

        // "Xem thêm X cảnh báo" nếu còn
        if (extra > 0) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showAllAlerts(context, visible),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '+ $extra cảnh báo khác',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFD97706),
                  decoration: TextDecoration.underline,
                  decorationColor: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFD97706),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAllAlerts(BuildContext context, List<AlertItem> alerts) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AlertBottomSheet(alerts: alerts),
    );
  }
}

class _AlertPill extends StatelessWidget {
  final AlertItem alert;
  final bool isDark;
  final VoidCallback onDismiss;

  const _AlertPill({
    required this.alert,
    required this.isDark,
    required this.onDismiss,
  });

  IconData get _icon {
    final type = alert.type.toUpperCase();
    if (type.contains('MEDICINE') || type.contains('DRUG')) return LucideIcons.pill;
    if (type.contains('APPOINTMENT')) return LucideIcons.calendarClock;
    if (type.contains('LAB') || type.contains('RESULT')) return LucideIcons.flaskConical;
    return LucideIcons.triangleAlert;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A1A00).withOpacity(0.6)
            : AppTheme.kWarningSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? const Color(0xFF92400E).withOpacity(0.4)
              : const Color(0xFFFCD34D).withOpacity(0.6),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            margin: const EdgeInsets.all(10),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF92400E).withOpacity(0.25)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              _icon,
              size: 15,
              color: isDark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFFD97706),
            ),
          ),
          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                alert.message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFF92400E),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Dismiss button
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              LucideIcons.x,
              size: 14,
              color: isDark
                  ? const Color(0xFFFBBF24).withOpacity(0.6)
                  : const Color(0xFFD97706).withOpacity(0.6),
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── All Alerts Bottom Sheet ────────────────────────────────────────────────────
class _AlertBottomSheet extends StatelessWidget {
  final List<AlertItem> alerts;
  const _AlertBottomSheet({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182030) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Icon(LucideIcons.triangleAlert, size: 16,
                    color: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text(
                  'Tất cả cảnh báo (${alerts.length})',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0D1520),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Alert list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final alert = alerts[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A1A00).withOpacity(0.6)
                        : AppTheme.kWarningSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF92400E).withOpacity(0.4)
                          : const Color(0xFFFCD34D).withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF92400E).withOpacity(0.25)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(LucideIcons.pill, size: 15,
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alert.message,
                          style: TextStyle(
                            fontSize: 13, height: 1.5,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


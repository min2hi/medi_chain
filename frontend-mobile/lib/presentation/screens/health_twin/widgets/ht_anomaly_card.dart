import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';

// ══════════════════════════════════════════════════════════════
// HtAnomalySection — Section bất thường + Card chi tiết
// ══════════════════════════════════════════════════════════════

class HtAnomalySection extends StatefulWidget {
  final List<HealthAnomaly> anomalies;
  final bool isDark;
  final void Function(String id) onDismiss;
  final void Function(HealthAnomaly anomaly) onAction;

  const HtAnomalySection({
    super.key,
    required this.anomalies,
    required this.isDark,
    required this.onDismiss,
    required this.onAction,
  });

  @override
  State<HtAnomalySection> createState() => _HtAnomalySectionState();
}

class _HtAnomalySectionState extends State<HtAnomalySection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.anomalies.where((a) => !a.isDismissed).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HtSectionHeader(
            label: 'Phát hiện bất thường',
            icon: LucideIcons.alertTriangle,
            iconColor: AdminColors.warning,
          ),
          const SizedBox(height: 12),
          ...active.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            // Stagger: card i starts at i*0.15 of 500ms
            final start = (i * 0.15).clamp(0.0, 0.7);
            final end = (start + 0.6).clamp(0.0, 1.0);
            final fade = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: _ctrl,
                  curve: Interval(start, end, curve: Curves.easeOut)),
            );
            final slide = Tween<double>(begin: 20, end: 0).animate(
              CurvedAnimation(parent: _ctrl,
                  curve: Interval(start, end, curve: Curves.easeOutCubic)),
            );
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => Opacity(
                opacity: fade.value,
                child: Transform.translate(
                  offset: Offset(0, slide.value),
                  child: HtAnomalyCard(
                    anomaly: a,
                    isDark: widget.isDark,
                    onDismiss: () {
                      HapticFeedback.lightImpact();
                      widget.onDismiss(a.id);
                    },
                    onAction: () {
                      HapticFeedback.lightImpact();
                      widget.onAction(a);
                    },
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Individual Anomaly Card ───────────────────────────────────

class HtAnomalyCard extends StatelessWidget {
  final HealthAnomaly anomaly;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  const HtAnomalyCard({
    super.key,
    required this.anomaly,
    required this.isDark,
    required this.onDismiss,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A0F00)
            : AdminColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AdminColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(LucideIcons.alertTriangle,
              size: 15, color: AdminColors.warning),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            anomaly.explanation,
            style: TextStyle(
              fontSize: 13, height: 1.6,
              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (anomaly.actionType != null)
          Expanded(
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: AdminColors.warning.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                anomaly.actionType == 'SUGGEST_APPOINTMENT'
                    ? 'Đặt lịch khám' : 'Tư vấn AI',
                style: TextStyle(
                  fontSize: 12,
                  color: AdminColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onDismiss,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Đã hiểu',
            style: TextStyle(fontSize: 12, color: AppTheme.kTextMuted)),
        ),
      ],
    );
  }
}

// ── Shared Section Header (dùng chung toàn feature) ───────────

class HtSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  const HtSectionHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Text(label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5,
            color: Theme.of(context).textTheme.labelSmall?.color
                ?? AppTheme.kTextMuted,
          )),
      ],
    );
  }
}

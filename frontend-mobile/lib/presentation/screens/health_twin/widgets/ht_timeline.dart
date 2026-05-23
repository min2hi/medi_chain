import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';
import 'package:medi_chain_mobile/presentation/screens/health_twin/widgets/ht_anomaly_card.dart';

// ══════════════════════════════════════════════════════════════
// HtTimeline — Timeline sức khỏe grouped theo tháng
// HtPatternsSection — Patterns AI nhận ra
// ══════════════════════════════════════════════════════════════

class HtTimeline extends StatelessWidget {
  final List<HealthTimelineMonth> timeline;
  final bool isDark;
  const HtTimeline({super.key, required this.timeline, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HtSectionHeader(
            label: 'Timeline sức khỏe',
            icon: LucideIcons.gitBranch,
            iconColor: Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          ...timeline.map((month) =>
              HtMonthBlock(month: month, isDark: isDark)),
        ],
      ),
    );
  }
}

// ── Month Block ───────────────────────────────────────────────

class HtMonthBlock extends StatelessWidget {
  final HealthTimelineMonth month;
  final bool isDark;
  const HtMonthBlock({super.key, required this.month, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final score = month.healthScore;
    return Row(
      children: [
        Text(month.label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          )),
        const Spacer(),
        if (score != null) ...[
          HtMiniScoreBar(score: score),
          const SizedBox(width: 8),
          Text('${score.round()}%',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: _scoreColor(score),
            )),
        ],
      ],
    );
  }

  Widget _buildEventsList() {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: month.events.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Không có sự kiện nào',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                )),
            )
          : Column(
              children: month.events.asMap().entries.map((entry) {
                final idx = entry.key;
                final event = entry.value;
                return Column(
                  children: [
                    HtEventRow(event: event, isDark: isDark),
                    if (idx < month.events.length - 1)
                      Divider(
                        height: 1, indent: 44,
                        color: isDark
                            ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ── Event Row ─────────────────────────────────────────────────

class HtEventRow extends StatelessWidget {
  final HealthEvent event;
  final bool isDark;
  const HtEventRow({super.key, required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.sourceIcon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.sourceLabel,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  )),
                const SizedBox(height: 2),
                Text(
                  event.rawContent.length > 80
                      ? '${event.rawContent.substring(0, 80)}...'
                      : event.rawContent,
                  style: TextStyle(
                    fontSize: 12.5, height: 1.4,
                    color: isDark
                        ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Score Bar ────────────────────────────────────────────

class HtMiniScoreBar extends StatelessWidget {
  final double score;
  const HtMiniScoreBar({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = score / 100;
    final color = score >= 75
        ? const Color(0xFF10B981)
        : score >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 60, height: 4,
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: const Color(0xFF1E293B),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

// ── Patterns Section ──────────────────────────────────────────

class HtPatternsSection extends StatelessWidget {
  final List<HealthPattern> patterns;
  final bool isDark;
  const HtPatternsSection({
    super.key, required this.patterns, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HtSectionHeader(
            label: 'Patterns AI nhận ra',
            icon: LucideIcons.brain,
            iconColor: Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: patterns.asMap().entries.map((entry) {
                final idx = entry.key;
                final pattern = entry.value;
                return Column(
                  children: [
                    _PatternTile(pattern: pattern, isDark: isDark),
                    if (idx < patterns.length - 1)
                      Divider(height: 1,
                          color: isDark
                              ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternTile extends StatelessWidget {
  final HealthPattern pattern;
  final bool isDark;
  const _PatternTile({required this.pattern, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(pattern.icon ?? _defaultIcon(pattern.type),
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(pattern.description,
              style: TextStyle(fontSize: 13, height: 1.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_typeLabel(pattern.type),
              style: const TextStyle(fontSize: 10,
                  color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _defaultIcon(String type) => switch (type) {
    'SEASONAL'      => '🌧️',
    'BEHAVIORAL'    => '🧠',
    'DRUG_RESPONSE' => '💊',
    'RECURRING'     => '🔄',
    _               => '📌',
  };

  String _typeLabel(String type) => switch (type) {
    'SEASONAL'      => 'Theo mùa',
    'BEHAVIORAL'    => 'Hành vi',
    'DRUG_RESPONSE' => 'Phản ứng thuốc',
    'RECURRING'     => 'Lặp lại',
    _               => 'Pattern',
  };
}

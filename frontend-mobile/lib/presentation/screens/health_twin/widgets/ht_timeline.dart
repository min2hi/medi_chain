import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';
import 'package:medi_chain_mobile/presentation/screens/health_twin/widgets/ht_anomaly_card.dart';

// ══════════════════════════════════════════════════════════════
// HtTimeline — Timeline sức khỏe grouped theo tháng
// HtPatternsSection — Patterns AI nhận ra
// ══════════════════════════════════════════════════════════════

// Dark mode color constants (mirror AppTheme.darkTheme local consts)
const _darkSurface = Color(0xFF182030);
const _darkBorder  = Color(0xFF2A3A50);

class HtTimeline extends StatefulWidget {
  final List<HealthTimelineMonth> timeline;
  final bool isDark;
  const HtTimeline({super.key, required this.timeline, required this.isDark});

  @override
  State<HtTimeline> createState() => _HtTimelineState();
}

class _HtTimelineState extends State<HtTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HtSectionHeader(
            label: 'Timeline sức khỏe',
            icon: LucideIcons.gitBranch,
            iconColor: AppTheme.kAccent,
          ),
          const SizedBox(height: 12),
          ...widget.timeline.asMap().entries.map((entry) {
            final i = entry.key;
            // Each month block fades+slides in with 100ms stagger
            final start = (i * 0.12).clamp(0.0, 0.6);
            final end = (start + 0.55).clamp(0.0, 1.0);
            final fade = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: _ctrl,
                  curve: Interval(start, end, curve: Curves.easeOut)),
            );
            final slide = Tween<double>(begin: 16, end: 0).animate(
              CurvedAnimation(parent: _ctrl,
                  curve: Interval(start, end, curve: Curves.easeOutCubic)),
            );
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => Opacity(
                opacity: fade.value,
                child: Transform.translate(
                  offset: Offset(0, slide.value),
                  child: HtMonthBlock(
                    month: entry.value,
                    isDark: widget.isDark,
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
          _buildEventsList(context),
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
            color: isDark ? AppTheme.kTextMuted : AppTheme.kTextSecondary,
          )),
        const Spacer(),
        if (score != null) ...[
          HtMiniScoreBar(score: score, isDark: isDark),
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

  Widget _buildEventsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _darkBorder : AppTheme.kBorder,
        ),
      ),
      child: month.events.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Không có sự kiện nào',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.kTextSecondary : AppTheme.kTextMuted,
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
                        color: isDark ? _darkBorder : AppTheme.kBorder,
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 75) return AdminColors.success;
    if (score >= 50) return AdminColors.warning;
    return AdminColors.danger;
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
                    color: AppTheme.kTextMuted,
                  )),
                const SizedBox(height: 2),
                Text(
                  event.rawContent.length > 80
                      ? '${event.rawContent.substring(0, 80)}...'
                      : event.rawContent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12.5, height: 1.4,
                    color: isDark
                        ? const Color(0xFFCBD5E1) : const Color(0xFF2A3A50),
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
  final bool isDark;
  const HtMiniScoreBar({super.key, required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final targetPct = score / 100;
    final color = score >= 75
        ? AdminColors.success
        : score >= 50 ? AdminColors.warning : AdminColors.danger;
    // Animate bar from 0 → targetPct on first build
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: targetPct),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 60, height: 4,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: isDark ? _darkSurface : AppTheme.kBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
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
          HtSectionHeader(
            label: 'Patterns AI nhận ra',
            icon: LucideIcons.brain,
            iconColor: AdminColors.purple,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? _darkSurface : AppTheme.kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? _darkBorder : AppTheme.kBorder,
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
                          color: isDark ? _darkBorder : AppTheme.kBorder),
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
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF2A3A50))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AdminColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_typeLabel(pattern.type),
              style: TextStyle(
                fontSize: 10,
                color: AdminColors.purple,
                fontWeight: FontWeight.w600,
              )),
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


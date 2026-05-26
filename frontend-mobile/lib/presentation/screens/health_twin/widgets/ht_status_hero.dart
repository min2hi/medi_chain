import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';

// ══════════════════════════════════════════════════════════════
// HtStatusHero — Hero card trạng thái sức khỏe
// Hiển thị: điểm số lớn + radial indicator (animated) + stat chips + progress
// ══════════════════════════════════════════════════════════════

// Dark mode color constants (mirror AppTheme.darkTheme local consts)
const _darkSurface = Color(0xFF182030);
const _darkBorder  = Color(0xFF2A3A50);

class HtStatusHero extends StatefulWidget {
  final HealthTwinStatus status;
  final bool isDark;
  const HtStatusHero({super.key, required this.status, required this.isDark});

  @override
  State<HtStatusHero> createState() => _HtStatusHeroState();
}

class _HtStatusHeroState extends State<HtStatusHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scoreAnim;   // 0 → recentScore (count-up)
  late final Animation<double> _radialAnim;  // 0 → score/100 (arc sweep)
  late final Animation<double> _progressAnim; // 0 → totalLogs/8 (bar sweep)

  // Stagger offsets for stat chips: chip i starts at i*0.08 of the 600ms
  late final List<Animation<double>> _chipFades;
  late final List<Animation<double>> _chipSlides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final target = (widget.status.recentScore ?? 0).toDouble();
    _scoreAnim = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );
    _radialAnim = Tween<double>(begin: 0, end: target / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic)),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: (widget.status.totalLogs / 8.0).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // 3 chips, each starts 80ms apart
    _chipFades = List.generate(3, (i) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.3 + i * 0.1, 0.7 + i * 0.1, curve: Curves.easeOut),
      )),
    );
    _chipSlides = List.generate(3, (i) =>
      Tween<double>(begin: 10, end: 0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.3 + i * 0.1, 0.7 + i * 0.1, curve: Curves.easeOutCubic),
      )),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F2027), Color(0xFF1A2A3A), Color(0xFF0D1B2A)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.kPrimary.withValues(alpha: 0.08),
                    AppTheme.kBg,
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kPrimary.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScoreRow(context, s, isDark),
                const SizedBox(height: 16),
                _buildStatusBadgeRow(s, isDark),
                const SizedBox(height: 20),
                _buildStatsRow(s, isDark),
                if (!s.isStable) ...[
                  const SizedBox(height: 16),
                  HtLearningProgress(
                    status: s,
                    isDark: isDark,
                    progressOverride: _progressAnim.value,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(BuildContext context, HealthTwinStatus s, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (s.recentScore != null) ...[
          // Animated count-up score
          Text(
            '${_scoreAnim.value.round()}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.kTextPrimary,
              height: 1.0,
              letterSpacing: -4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('/100',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.kTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ] else
          Text('--',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: _darkBorder,
              height: 1.0,
            ),
          ),
        const Spacer(),
        // Animated radial arc
        HtHealthRadial(
          progressOverride: _radialAnim.value,
          score: s.recentScore,
          size: 72,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatusBadgeRow(HealthTwinStatus s, bool isDark) {
    final color = _statusColor(s);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon(s), size: 12, color: color),
              const SizedBox(width: 5),
              Text(_statusLabel(s),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
        if (s.trendPercent != null) ...[
          const SizedBox(width: 10),
          Icon(
            s.trendPercent! >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 14,
            color: s.trendPercent! >= 0 ? AdminColors.success : AdminColors.danger,
          ),
          const SizedBox(width: 4),
          Text(
            '${s.trendPercent! >= 0 ? '+' : ''}${s.trendPercent!.toStringAsFixed(0)}% so tuần trước',
            style: TextStyle(
              fontSize: 12,
              color: s.trendPercent! >= 0 ? AdminColors.success : AdminColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(HealthTwinStatus s, bool isDark) {
    final chips = [
      (label: 'Tuần theo dõi',  value: '${s.weeksTracked}', icon: LucideIcons.calendar,    highlight: false),
      (label: 'Sự kiện ghi lại', value: '${s.totalLogs}',   icon: LucideIcons.activity,    highlight: false),
      (label: 'Trạng thái AI',  value: s.isStable ? 'Ổn định' : 'Học...',
       icon: s.isStable ? LucideIcons.checkCircle : LucideIcons.brain, highlight: s.isStable),
    ];
    return Row(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          // Staggered fade + slide-up per chip
          Expanded(
            child: Opacity(
              opacity: _chipFades[i].value,
              child: Transform.translate(
                offset: Offset(0, _chipSlides[i].value),
                child: HtStatChip(
                  label: chips[i].label,
                  value: chips[i].value,
                  icon: chips[i].icon,
                  highlight: chips[i].highlight,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _statusColor(HealthTwinStatus s) {
    if (!s.isStable) return AppTheme.kTextMuted;
    final score = s.recentScore ?? 50;
    if (score >= 75) return AdminColors.success;
    if (score >= 50) return AdminColors.warning;
    return AdminColors.danger;
  }

  IconData _statusIcon(HealthTwinStatus s) {
    if (!s.isStable) return LucideIcons.loader;
    final score = s.recentScore ?? 50;
    if (score >= 75) return LucideIcons.checkCircle;
    if (score >= 50) return LucideIcons.alertCircle;
    return LucideIcons.alertTriangle;
  }

  String _statusLabel(HealthTwinStatus s) {
    if (!s.isStable) return 'Đang học';
    final score = s.recentScore ?? 50;
    if (score >= 75) return 'Ổn định';
    if (score >= 50) return 'Cần theo dõi';
    return 'Cần chú ý';
  }
}

// ── Radial Health Indicator ───────────────────────────────────

/// Radial health indicator — accepts [progressOverride] from parent AnimationController
/// so the arc sweeps in sync with the count-up score.
class HtHealthRadial extends StatelessWidget {
  final double? score;
  final double size;
  final bool isDark;
  /// When non-null, bypasses score/100 and uses this directly (0.0–1.0).
  final double? progressOverride;

  const HtHealthRadial({
    super.key,
    this.score,
    required this.size,
    required this.isDark,
    this.progressOverride,
  });

  @override
  Widget build(BuildContext context) {
    final pct = progressOverride ?? ((score ?? 0) / 100);
    final iconColor = _color(pct);
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _RadialPainter(progress: pct, isDark: isDark),
        child: Center(
          child: Icon(LucideIcons.heartPulse,
              size: size * 0.35, color: iconColor),
        ),
      ),
    );
  }

  Color _color(double pct) {
    if (pct >= 0.75) return AdminColors.success;
    if (pct >= 0.50) return AdminColors.warning;
    return AdminColors.danger;
  }
}

class _RadialPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _RadialPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;

    // Background track — uses theme-aware border color
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = isDark ? _darkSurface : AppTheme.kBorder,
    );

    final color = progress >= 0.75
        ? AdminColors.success
        : progress >= 0.50 ? AdminColors.warning : AdminColors.danger;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RadialPainter old) =>
      old.progress != progress || old.isDark != isDark;
}

// ── Stat Chip ─────────────────────────────────────────────────

class HtStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final bool isDark;
  const HtStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: Expanded removed — parent _buildStatsRow wraps each in Expanded
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3))
            : Border.all(color: isDark ? _darkBorder : AppTheme.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14,
              color: highlight ? AppTheme.kPrimary : AppTheme.kTextSecondary),
          const SizedBox(height: 6),
          Text(value,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: highlight
                  ? AppTheme.kPrimary
                  : isDark ? Colors.white : AppTheme.kTextPrimary,
            )),
          const SizedBox(height: 2),
          Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.kTextSecondary)),
        ],
      ),
    );
  }
}

// ── Learning Progress ─────────────────────────────────────────

class HtLearningProgress extends StatelessWidget {
  final HealthTwinStatus status;
  final bool isDark;
  /// Animated progress value from parent AnimationController (0.0–1.0).
  final double progressOverride;

  const HtLearningProgress({
    super.key,
    required this.status,
    required this.isDark,
    required this.progressOverride,
  });

  @override
  Widget build(BuildContext context) {
    final displayPct = progressOverride;
    final remaining = (3 - status.totalLogs).clamp(0, 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AI đang học về bạn...',
              style: TextStyle(
                fontSize: 12, color: AppTheme.kTextMuted,
                fontWeight: FontWeight.w500,
              )),
            Text('${(displayPct * 100).round()}%',
              style: const TextStyle(
                fontSize: 12, color: AppTheme.kPrimary,
                fontWeight: FontWeight.w600,
              )),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: displayPct,
            backgroundColor: isDark ? _darkSurface : AppTheme.kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.kPrimary),
            minHeight: 5, // 1px thicker → more visible
          ),
        ),
        const SizedBox(height: 6),
        Text(
          remaining > 0
              ? 'Cần thêm $remaining sự kiện nữa để kích hoạt phân tích'
              : 'Đủ dữ liệu — AI đang phân tích baseline của bạn',
          style: const TextStyle(fontSize: 11, color: AppTheme.kTextMuted),
        ),
      ],
    );
  }
}


import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';

// ══════════════════════════════════════════════════════════════
// HtStatusHero — Hero card trạng thái sức khỏe
// Hiển thị: điểm số lớn + radial indicator + stat chips + progress
// ══════════════════════════════════════════════════════════════

// Dark mode color constants (mirror AppTheme.darkTheme local consts)
const _darkSurface = Color(0xFF1E293B);
const _darkBorder  = Color(0xFF334155);

class HtStatusHero extends StatelessWidget {
  final HealthTwinStatus status;
  final bool isDark;
  const HtStatusHero({super.key, required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScoreRow(context),
              const SizedBox(height: 16),
              _buildStatusBadgeRow(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              if (!status.isStable) ...[
                const SizedBox(height: 16),
                HtLearningProgress(status: status, isDark: isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (status.recentScore != null) ...[
          Text(
            '${status.recentScore!.round()}',
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
              style: TextStyle(
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
        HtHealthRadial(score: status.recentScore, size: 72, isDark: isDark),
      ],
    );
  }

  Widget _buildStatusBadgeRow() {
    final color = _statusColor();
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
              Icon(_statusIcon(), size: 12, color: color),
              const SizedBox(width: 5),
              Text(_statusLabel(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
        if (status.trendPercent != null) ...[
          const SizedBox(width: 10),
          Icon(
            status.trendPercent! >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 14,
            color: status.trendPercent! >= 0
                ? AdminColors.success : AdminColors.danger,
          ),
          const SizedBox(width: 4),
          Text(
            '${status.trendPercent! >= 0 ? '+' : ''}${status.trendPercent!.toStringAsFixed(0)}% so tuần trước',
            style: TextStyle(
              fontSize: 12,
              color: status.trendPercent! >= 0
                  ? AdminColors.success : AdminColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        HtStatChip(label: 'Tuần theo dõi', value: '${status.weeksTracked}',
            icon: LucideIcons.calendar, isDark: isDark),
        const SizedBox(width: 12),
        HtStatChip(label: 'Sự kiện ghi lại', value: '${status.totalLogs}',
            icon: LucideIcons.activity, isDark: isDark),
        const SizedBox(width: 12),
        HtStatChip(
          label: 'Trạng thái AI',
          value: status.isStable ? 'Ổn định' : 'Học...',
          icon: status.isStable ? LucideIcons.checkCircle : LucideIcons.brain,
          highlight: status.isStable,
          isDark: isDark,
        ),
      ],
    );
  }

  Color _statusColor() {
    if (!status.isStable) return AppTheme.kTextMuted;
    final score = status.recentScore ?? 50;
    if (score >= 75) return AdminColors.success;
    if (score >= 50) return AdminColors.warning;
    return AdminColors.danger;
  }

  IconData _statusIcon() {
    if (!status.isStable) return LucideIcons.loader;
    final score = status.recentScore ?? 50;
    if (score >= 75) return LucideIcons.checkCircle;
    if (score >= 50) return LucideIcons.alertCircle;
    return LucideIcons.alertTriangle;
  }

  String _statusLabel() {
    if (!status.isStable) return 'Đang học';
    final score = status.recentScore ?? 50;
    if (score >= 75) return 'Ổn định';
    if (score >= 50) return 'Cần theo dõi';
    return 'Cần chú ý';
  }
}

// ── Radial Health Indicator ───────────────────────────────────

class HtHealthRadial extends StatelessWidget {
  final double? score;
  final double size;
  final bool isDark;
  const HtHealthRadial({super.key, this.score, required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = (score ?? 0) / 100;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _RadialPainter(progress: pct, isDark: isDark),
        child: Center(
          child: Icon(LucideIcons.heartPulse,
              size: size * 0.35, color: _color(pct)),
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
    return Expanded(
      child: Container(
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
              style: TextStyle(fontSize: 10, color: AppTheme.kTextSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Learning Progress ─────────────────────────────────────────

class HtLearningProgress extends StatelessWidget {
  final HealthTwinStatus status;
  final bool isDark;
  const HtLearningProgress({super.key, required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = (status.totalLogs / 8.0).clamp(0.0, 1.0);
    final remaining = (3 - status.totalLogs).clamp(0, 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AI đang học về bạn...',
              style: TextStyle(
                fontSize: 12, color: AppTheme.kTextMuted,
                fontWeight: FontWeight.w500,
              )),
            Text('${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12, color: AppTheme.kPrimary,
                fontWeight: FontWeight.w600,
              )),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? _darkSurface : AppTheme.kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.kPrimary),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text('Cần thêm $remaining sự kiện nữa để kích hoạt phân tích',
          style: TextStyle(fontSize: 11, color: AppTheme.kTextMuted)),
      ],
    );
  }
}

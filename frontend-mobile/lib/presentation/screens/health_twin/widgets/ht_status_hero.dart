import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';

// ══════════════════════════════════════════════════════════════
// HtStatusHero — Hero card trạng thái sức khỏe
// Hiển thị: điểm số lớn + radial indicator + stat chips + progress
// ══════════════════════════════════════════════════════════════

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
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF0C4A6E)],
                ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
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
              _buildScoreRow(),
              const SizedBox(height: 16),
              _buildStatusBadgeRow(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              if (!status.isStable) ...[
                const SizedBox(height: 16),
                HtLearningProgress(status: status),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (status.recentScore != null) ...[
          Text(
            '${status.recentScore!.round()}',
            style: const TextStyle(
              fontSize: 72, fontWeight: FontWeight.w800,
              color: Colors.white, height: 1.0, letterSpacing: -4,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('/100',
              style: TextStyle(fontSize: 18, color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ] else
          const Text('--',
            style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800,
                color: Color(0xFF334155), height: 1.0),
          ),
        const Spacer(),
        HtHealthRadial(score: status.recentScore, size: 72),
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
                ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          Text(
            '${status.trendPercent! >= 0 ? '+' : ''}${status.trendPercent!.toStringAsFixed(0)}% so tuần trước',
            style: TextStyle(
              fontSize: 12,
              color: status.trendPercent! >= 0
                  ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
            icon: LucideIcons.calendar),
        const SizedBox(width: 12),
        HtStatChip(label: 'Sự kiện ghi lại', value: '${status.totalLogs}',
            icon: LucideIcons.activity),
        const SizedBox(width: 12),
        HtStatChip(
          label: 'Trạng thái AI',
          value: status.isStable ? 'Ổn định' : 'Học...',
          icon: status.isStable ? LucideIcons.checkCircle : LucideIcons.brain,
          highlight: status.isStable,
        ),
      ],
    );
  }

  Color _statusColor() {
    if (!status.isStable) return const Color(0xFF64748B);
    final score = status.recentScore ?? 50;
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
  const HtHealthRadial({super.key, this.score, required this.size});

  @override
  Widget build(BuildContext context) {
    final pct = (score ?? 0) / 100;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _RadialPainter(progress: pct),
        child: Center(
          child: Icon(LucideIcons.heartPulse,
              size: size * 0.35, color: _color(pct)),
        ),
      ),
    );
  }

  Color _color(double pct) {
    if (pct >= 0.75) return const Color(0xFF10B981);
    if (pct >= 0.50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _RadialPainter extends CustomPainter {
  final double progress;
  _RadialPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = const Color(0xFF1E293B),
    );

    final color = progress >= 0.75
        ? const Color(0xFF10B981)
        : progress >= 0.50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

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
  bool shouldRepaint(_RadialPainter old) => old.progress != progress;
}

// ── Stat Chip ─────────────────────────────────────────────────

class HtStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const HtStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: highlight
              ? Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14,
                color: highlight ? const Color(0xFF14B8A6) : const Color(0xFF475569)),
            const SizedBox(height: 6),
            Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: highlight ? const Color(0xFF14B8A6) : Colors.white)),
            const SizedBox(height: 2),
            Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }
}

// ── Learning Progress ─────────────────────────────────────────

class HtLearningProgress extends StatelessWidget {
  final HealthTwinStatus status;
  const HtLearningProgress({super.key, required this.status});

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
            const Text('AI đang học về bạn...',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500)),
            Text('${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 12, color: Color(0xFF14B8A6),
                  fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text('Cần thêm $remaining sự kiện nữa để kích hoạt phân tích',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}

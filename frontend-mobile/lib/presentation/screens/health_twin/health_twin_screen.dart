import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';
import 'package:medi_chain_mobile/logic/health_twin/health_twin_bloc.dart';

// ══════════════════════════════════════════════════════════════
// HEALTH TWIN SCREEN — Bóng Sức Khỏe
// Design: Surgical minimalism — data-dense without feeling crowded
// ══════════════════════════════════════════════════════════════

class HealthTwinScreen extends StatefulWidget {
  const HealthTwinScreen({super.key});

  @override
  State<HealthTwinScreen> createState() => _HealthTwinScreenState();
}

class _HealthTwinScreenState extends State<HealthTwinScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _entryController;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();

    context.read<HealthTwinBloc>().add(HealthTwinFetchRequested());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF5F7FA),
      body: BlocConsumer<HealthTwinBloc, HealthTwinState>(
        listener: (context, state) {
          if (state is HealthTwinCheckinSuccess) {
            _showCheckinConfirmation(context);
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, isDark),
              if (state is HealthTwinLoading)
                const SliverFillRemaining(
                  child: Center(child: _LoadingPulse()),
                )
              else if (state is HealthTwinError)
                SliverFillRemaining(
                  child: _buildErrorState(context, state.message),
                )
              else if (state is HealthTwinLoaded) ...[
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _entryAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(_entryAnim),
                      child: Column(
                        children: [
                          _buildStatusHero(context, state.status, isDark),
                          const SizedBox(height: 20),
                          if (state.status.recentAnomalies.isNotEmpty)
                            _buildAnomalySection(context, state.status.recentAnomalies, isDark),
                          if (state.status.patterns.isNotEmpty)
                            _buildPatternsSection(context, state.status.patterns, isDark),
                          _buildCheckinPrompt(context, isDark),
                          const SizedBox(height: 20),
                          if (state.timeline.isNotEmpty)
                            _buildTimeline(context, state.timeline, isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else
                SliverFillRemaining(
                  child: _buildEmptyState(context, isDark),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF5F7FA),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowLeft,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFF14B8A6),
                  const Color(0xFF06B6D4),
                  _pulseController.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withValues(
                        alpha: 0.4 + _pulseController.value * 0.3),
                    blurRadius: 6 + _pulseController.value * 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Bóng Sức Khỏe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            LucideIcons.refreshCw,
            size: 18,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          onPressed: () =>
              context.read<HealthTwinBloc>().add(HealthTwinFetchRequested()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Status Hero ──────────────────────────────────────────────

  Widget _buildStatusHero(
      BuildContext context, HealthTwinStatus status, bool isDark) {
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
              // Score + trend row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status.recentScore != null) ...[
                    Text(
                      '${status.recentScore!.round()}',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -4,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '--',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                        height: 1.0,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Radial health indicator
                  _HealthRadial(
                    score: status.recentScore,
                    size: 72,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status label
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 12,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status.trendPercent != null) ...[
                    const SizedBox(width: 10),
                    Icon(
                      status.trendPercent! >= 0
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 14,
                      color: status.trendPercent! >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${status.trendPercent! >= 0 ? '+' : ''}${status.trendPercent!.toStringAsFixed(0)}% so tuần trước',
                      style: TextStyle(
                        fontSize: 12,
                        color: status.trendPercent! >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _StatChip(
                    label: 'Tuần theo dõi',
                    value: '${status.weeksTracked}',
                    icon: LucideIcons.calendar,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Sự kiện ghi lại',
                    value: '${status.totalLogs}',
                    icon: LucideIcons.activity,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Trạng thái AI',
                    value: status.isStable ? 'Ổn định' : 'Học...',
                    icon: status.isStable
                        ? LucideIcons.checkCircle
                        : LucideIcons.brain,
                    highlight: status.isStable,
                  ),
                ],
              ),

              if (!status.isStable) ...[
                const SizedBox(height: 16),
                _buildLearningProgress(status),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningProgress(HealthTwinStatus status) {
    final progress = math.min(1.0, status.totalLogs / 8.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI đang học về bạn...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF14B8A6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E293B),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cần thêm ${math.max(0, 3 - status.totalLogs)} sự kiện nữa để kích hoạt phân tích',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ── Anomaly Section ──────────────────────────────────────────

  Widget _buildAnomalySection(
      BuildContext context, List<HealthAnomaly> anomalies, bool isDark) {
    final active = anomalies.where((a) => !a.isDismissed).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            label: 'Phát hiện bất thường',
            icon: LucideIcons.alertTriangle,
            iconColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          ...active.map((a) => _AnomalyCard(
                anomaly: a,
                isDark: isDark,
                onDismiss: () => context
                    .read<HealthTwinBloc>()
                    .add(HealthTwinAnomalyDismissed(a.id)),
                onAction: () => _handleAnomalyAction(context, a),
              )),
        ],
      ),
    );
  }

  // ── Patterns Section ─────────────────────────────────────────

  Widget _buildPatternsSection(
      BuildContext context, List<HealthPattern> patterns, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            label: 'Patterns AI nhận ra',
            icon: LucideIcons.brain,
            iconColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
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
                      Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly Check-in Prompt ────────────────────────────────────

  Widget _buildCheckinPrompt(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => _showCheckinSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.clipboardList,
                  size: 18,
                  color: Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuần này bạn thế nào?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check-in tuần · Không bắt buộc · 10 giây',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Timeline ─────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context,
      List<HealthTimelineMonth> timeline, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            label: 'Timeline sức khỏe',
            icon: LucideIcons.gitBranch,
            iconColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          ...timeline.map((month) => _MonthBlock(month: month, isDark: isDark)),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.heartPulse,
                size: 36,
                color: Color(0xFF14B8A6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bóng Sức Khỏe đang khởi động',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Dùng tư vấn AI, thêm thuốc, hoặc đặt lịch khám — AI sẽ tự học từ những hành động đó.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.push('/ai-consult'),
              icon: const Icon(LucideIcons.messageCircle, size: 16),
              label: const Text('Bắt đầu tư vấn AI'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF14B8A6),
                side: const BorderSide(color: Color(0xFF14B8A6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 40, color: Color(0xFF64748B)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  context.read<HealthTwinBloc>().add(HealthTwinFetchRequested()),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Color _getStatusColor(HealthTwinStatus status) {
    if (!status.isStable) return const Color(0xFF64748B);
    final score = status.recentScore ?? 50;
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _getStatusIcon(HealthTwinStatus status) {
    if (!status.isStable) return LucideIcons.loader;
    final score = status.recentScore ?? 50;
    if (score >= 75) return LucideIcons.checkCircle;
    if (score >= 50) return LucideIcons.alertCircle;
    return LucideIcons.alertTriangle;
  }

  String _getStatusLabel(HealthTwinStatus status) {
    if (!status.isStable) return 'Đang học';
    final score = status.recentScore ?? 50;
    if (score >= 75) return 'Ổn định';
    if (score >= 50) return 'Cần theo dõi';
    return 'Cần chú ý';
  }

  void _handleAnomalyAction(BuildContext context, HealthAnomaly anomaly) {
    if (anomaly.actionType == 'SUGGEST_APPOINTMENT') {
      context.push('/', extra: {'initialTab': 2});
    } else {
      context.push('/ai-consult');
    }
  }

  void _showCheckinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HealthTwinBloc>(),
        child: const _CheckinBottomSheet(),
      ),
    );
  }

  void _showCheckinConfirmation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.white, size: 16),
            SizedBox(width: 10),
            Text('Đã ghi nhận — cảm ơn bạn!'),
          ],
        ),
        backgroundColor: const Color(0xFF14B8A6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════

class _HealthRadial extends StatelessWidget {
  final double? score;
  final double size;
  const _HealthRadial({this.score, required this.size});

  @override
  Widget build(BuildContext context) {
    final pct = (score ?? 0) / 100;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadialPainter(progress: pct),
        child: Center(
          child: Icon(
            LucideIcons.heartPulse,
            size: size * 0.35,
            color: _getColor(pct),
          ),
        ),
      ),
    );
  }

  Color _getColor(double pct) {
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
    final strokeWidth = 4.0;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = const Color(0xFF1E293B),
    );

    // Progress arc
    final color = progress >= 0.75
        ? const Color(0xFF10B981)
        : progress >= 0.50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _StatChip({
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
              ? Border.all(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlight
                  ? const Color(0xFF14B8A6)
                  : const Color(0xFF475569),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? const Color(0xFF14B8A6)
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  final HealthAnomaly anomaly;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onAction;
  const _AnomalyCard({
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
        color: isDark ? const Color(0xFF1A0F00) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  size: 15,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  anomaly.explanation,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (anomaly.actionType != null)
                Expanded(
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      anomaly.actionType == 'SUGGEST_APPOINTMENT'
                          ? 'Đặt lịch khám'
                          : 'Tư vấn AI',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Đã hiểu',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
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
          Text(
            pattern.icon ?? _defaultIcon(pattern.type),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              pattern.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _typeLabel(pattern.type),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultIcon(String type) {
    switch (type) {
      case 'SEASONAL': return '🌧️';
      case 'BEHAVIORAL': return '🧠';
      case 'DRUG_RESPONSE': return '💊';
      case 'RECURRING': return '🔄';
      default: return '📌';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'SEASONAL': return 'Theo mùa';
      case 'BEHAVIORAL': return 'Hành vi';
      case 'DRUG_RESPONSE': return 'Phản ứng thuốc';
      case 'RECURRING': return 'Lặp lại';
      default: return 'Pattern';
    }
  }
}

class _MonthBlock extends StatelessWidget {
  final HealthTimelineMonth month;
  final bool isDark;
  const _MonthBlock({required this.month, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final score = month.healthScore;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header with score bar
          Row(
            children: [
              Text(
                month.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              if (score != null)
                Row(
                  children: [
                    _MiniScoreBar(score: score),
                    const SizedBox(width: 8),
                    Text(
                      '${score.round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _scoreColor(score),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: month.events.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Không có sự kiện nào',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : Column(
                    children: month.events.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final event = entry.value;
                      return Column(
                        children: [
                          _EventRow(event: event, isDark: isDark),
                          if (idx < month.events.length - 1)
                            Divider(
                              height: 1,
                              indent: 44,
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _MiniScoreBar extends StatelessWidget {
  final double score;
  const _MiniScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = score / 100;
    final color = score >= 75
        ? const Color(0xFF10B981)
        : score >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 60,
        height: 4,
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: const Color(0xFF1E293B),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final HealthEvent event;
  final bool isDark;
  const _EventRow({required this.event, required this.isDark});

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
                Text(
                  event.sourceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.rawContent.length > 80
                      ? '${event.rawContent.substring(0, 80)}...'
                      : event.rawContent,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                    height: 1.4,
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

// ── Check-in Bottom Sheet ─────────────────────────────────────

class _CheckinBottomSheet extends StatefulWidget {
  const _CheckinBottomSheet();

  @override
  State<_CheckinBottomSheet> createState() => _CheckinBottomSheetState();
}

class _CheckinBottomSheetState extends State<_CheckinBottomSheet> {
  String? _selected;

  static const _options = [
    ('good', '😊', 'Rất khỏe', Color(0xFF10B981)),
    ('normal', '😐', 'Bình thường', Color(0xFF3B82F6)),
    ('tired', '😔', 'Mệt mỏi', Color(0xFFF59E0B)),
    ('bad', '😫', 'Không khỏe', Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tuần qua bạn cảm thấy thế nào?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI sẽ học từ phản hồi của bạn để hiểu baseline tốt hơn',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: _options.map((opt) {
              final (value, emoji, label, color) = opt;
              final isSelected = _selected == value;
              return GestureDetector(
                onTap: () => setState(() => _selected = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.5)
                          : isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? color
                              : isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      context.read<HealthTwinBloc>().add(
                            HealthTwinCheckinSubmitted(_selected!),
                          );
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                disabledBackgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                _selected == null ? 'Chọn một lựa chọn' : 'Ghi nhận',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _selected == null
                      ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                      : Colors.white,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Bỏ qua — không bắt buộc',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────

class _LoadingPulse extends StatefulWidget {
  const _LoadingPulse();

  @override
  State<_LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<_LoadingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.heartPulse,
            size: 40,
            color: Color.lerp(
              const Color(0xFF14B8A6),
              const Color(0xFF06B6D4),
              _anim.value,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đang tải dữ liệu sức khỏe...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

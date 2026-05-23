import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';
import 'package:medi_chain_mobile/logic/health_twin/health_twin_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/health_twin/widgets/ht_anomaly_card.dart';
import 'package:medi_chain_mobile/presentation/screens/health_twin/widgets/ht_checkin_sheet.dart';
import 'package:medi_chain_mobile/presentation/screens/health_twin/widgets/ht_status_hero.dart';
import 'package:medi_chain_mobile/presentation/screens/health_twin/widgets/ht_timeline.dart';

// ══════════════════════════════════════════════════════════════
// HealthTwinScreen — Orchestrator (Bóng Sức Khỏe)
// Trách nhiệm: BLoC wiring + layout + navigation
// Logic UI nằm trong widgets/ riêng từng file
// ══════════════════════════════════════════════════════════════

class HealthTwinScreen extends StatefulWidget {
  const HealthTwinScreen({super.key});

  @override
  State<HealthTwinScreen> createState() => _HealthTwinScreenState();
}

class _HealthTwinScreenState extends State<HealthTwinScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();

    context.read<HealthTwinBloc>().add(HealthTwinFetchRequested());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF5F7FA),
      body: BlocConsumer<HealthTwinBloc, HealthTwinState>(
        listener: _onStateChange,
        builder: (context, state) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(isDark),
            ..._buildBody(context, state, isDark),
          ],
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 0, floating: true, pinned: true, elevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF5F7FA),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft,
            color: isDark ? Colors.white : const Color(0xFF0F172A)),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          _PulseDot(controller: _pulseCtrl),
          const SizedBox(width: 10),
          Text('Bóng Sức Khỏe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(LucideIcons.refreshCw, size: 18,
              color: isDark
                  ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          onPressed: () =>
              context.read<HealthTwinBloc>().add(HealthTwinFetchRequested()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Body Builder ────────────────────────────────────────────

  List<Widget> _buildBody(
      BuildContext context, HealthTwinState state, bool isDark) {
    if (state is HealthTwinLoading) {
      return [
        const SliverFillRemaining(
            child: Center(child: _LoadingPulse())),
      ];
    }
    if (state is HealthTwinError) {
      return [
        SliverFillRemaining(
            child: _buildErrorState(context, state.message)),
      ];
    }
    if (state is HealthTwinLoaded) {
      return [
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _entryAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, 0.05), end: Offset.zero)
                  .animate(_entryAnim),
              child: _buildContent(context, state, isDark),
            ),
          ),
        ),
      ];
    }
    return [
      SliverFillRemaining(child: _buildEmptyState(context, isDark)),
    ];
  }

  Widget _buildContent(
      BuildContext context, HealthTwinLoaded state, bool isDark) {
    return Column(
      children: [
        HtStatusHero(status: state.status, isDark: isDark),
        const SizedBox(height: 20),
        if (state.status.recentAnomalies.isNotEmpty)
          HtAnomalySection(
            anomalies: state.status.recentAnomalies,
            isDark: isDark,
            onDismiss: (id) => context
                .read<HealthTwinBloc>()
                .add(HealthTwinAnomalyDismissed(id)),
            onAction: _handleAnomalyAction,
          ),
        HtPatternsSection(patterns: state.status.patterns, isDark: isDark),
        HtCheckinPrompt(onTap: () => _showCheckinSheet(context)),
        const SizedBox(height: 20),
        if (state.timeline.isNotEmpty)
          HtTimeline(timeline: state.timeline, isDark: isDark),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Empty / Error States ────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.heartPulse,
                  size: 36, color: Color(0xFF14B8A6)),
            ),
            const SizedBox(height: 20),
            Text('Bóng Sức Khỏe đang khởi động',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Dùng tư vấn AI, thêm thuốc, hoặc đặt lịch khám — AI sẽ tự học từ những hành động đó.',
              style: TextStyle(fontSize: 14, height: 1.6,
                  color: isDark
                      ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.push('/ai-consult'),
              icon: const Icon(LucideIcons.messageCircle, size: 16),
              label: const Text('Bắt đầu tư vấn AI'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF14B8A6),
                side: const BorderSide(color: Color(0xFF14B8A6)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
            Text(message,
                style: const TextStyle(color: Color(0xFF64748B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context
                  .read<HealthTwinBloc>()
                  .add(HealthTwinFetchRequested()),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  void _onStateChange(BuildContext context, HealthTwinState state) {
    if (state is HealthTwinCheckinSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(LucideIcons.checkCircle, color: Colors.white, size: 16),
          SizedBox(width: 10),
          Text('Đã ghi nhận — cảm ơn bạn!'),
        ]),
        backgroundColor: const Color(0xFF14B8A6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  void _handleAnomalyAction(HealthAnomaly anomaly) {
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
        child: const HtCheckinSheet(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Private micro-widgets (chỉ dùng trong file này)
// ══════════════════════════════════════════════════════════════

class _PulseDot extends StatelessWidget {
  final AnimationController controller;
  const _PulseDot({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
              const Color(0xFF14B8A6), const Color(0xFF06B6D4), controller.value),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6)
                  .withValues(alpha: 0.4 + controller.value * 0.3),
              blurRadius: 6 + controller.value * 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

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
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
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
          Icon(LucideIcons.heartPulse, size: 40,
            color: Color.lerp(
                const Color(0xFF14B8A6), const Color(0xFF06B6D4), _anim.value)),
          const SizedBox(height: 16),
          const Text('Đang tải dữ liệu sức khỏe...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        ],
      ),
    );
  }
}

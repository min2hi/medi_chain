import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/ai/ai_bloc.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/ai_repository.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';

// Design tokens — đồng nhất với ChatScreen
// AppTheme.kPrimaryDark replaced by AppTheme.kPrimaryDark

Color _getSurface(BuildContext context) => Theme.of(context).colorScheme.surface;
Color _getBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
Color _getBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);
Color _getTextPrimary(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF0D1520);
Color _getTextSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
Color _getTextMuted(BuildContext context) => const Color(0xFF94A3B8);

class ConsultationScreen extends StatefulWidget {
  final String? initialSymptom;
  const ConsultationScreen({super.key, this.initialSymptom});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _inputFocused = false;
  bool _diagnosticsExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSymptom != null) {
      _controller.text = widget.initialSymptom!;
    }
    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSend(BuildContext blocContext) {
    if (_controller.text.trim().length < 5) return;
    HapticFeedback.mediumImpact();
    blocContext.read<AIBloc>().add(ConsultRequested(_controller.text));
    _controller.clear();
    _focusNode.unfocus();
    setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AIBloc>(),
      child: Scaffold(
        backgroundColor: _getBg(context),
        endDrawer: const _ConsultationHistoryDrawer(),
        appBar: AppBar(
          backgroundColor: _getSurface(context),
          elevation: 0,
          title: Row(
            children: [
              // "M" gradient avatar — đồng nhất với ChatScreen
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'M',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tư vấn AI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _getTextPrimary(context),
                    ),
                  ),
                  Text(
                    'Phân tích chuyên sâu',
                    style: TextStyle(
                      fontSize: 11,
                      color: _getTextMuted(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (innerContext) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.history, size: 20,
                        color: _getTextMuted(innerContext)),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Scaffold.of(innerContext).openEndDrawer();
                    },
                    tooltip: 'Lịch sử tư vấn',
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.rotateCcw, size: 20,
                        color: _getTextMuted(innerContext)),
                    onPressed: () =>
                        innerContext.read<AIBloc>().add(SessionResetRequested()),
                    tooltip: 'Tư vấn mới',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _getBorder(context)),
          ),
        ),
        body: BlocListener<AIBloc, AIState>(
          listener: (context, state) {
            if (state is ConsultSuccess) {
              if (state.data.symptoms != null && state.data.symptoms!.isNotEmpty) {
                _controller.text = state.data.symptoms!;
              }
            } else if (state is AIInitial) {
              _controller.clear();
            }
          },
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<AIBloc, AIState>(
                  builder: (context, state) {
                    if (state is AIInitial) return _buildInitialState();
                    if (state is AILoading) {
                      // Skeleton thay CircularProgressIndicator
                      return _buildLoadingSkeleton();
                    }
                    if (state is ConsultSuccess) {
                      return _buildConsultResult(state.data);
                    }
                    if (state is AIError) return _buildErrorState(context, state.message);
                    return const SizedBox();
                  },
                ),
              ),
              Builder(builder: (blocContext) => _buildInputArea(blocContext)),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Initial / empty state
  // ──────────────────────────────────────────────

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          // "M" gradient box — đồng nhất với ChatScreen
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.kPrimary, AppTheme.kPrimaryDark],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kPrimaryDark.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'M',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tư vấn Chuyên sâu AI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _getTextPrimary(context),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.kPrimaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.25)),
            ),
            child: const Text(
              'Phân tích dựa trên hồ sơ sức khỏe của bạn',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.kPrimaryDark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mô tả triệu chứng chi tiết (đau ở đâu, từ khi nào, mức độ...). AI sẽ phân tích và gợi ý thuốc phù hợp dựa trên lịch sử của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: _getTextSecondary(context),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer loading khi AI đang xử lý
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // AI đang phân tích indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppTheme.kPrimaryDark,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI đang phân tích hồ sơ của bạn...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.kPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Skeleton cards
          ...List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: AppSkeleton(
                height: 90 - i * 10,
                radius: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ──────────────────────────────────────────────
  // Consult result layout
  // ──────────────────────────────────────────────

  Widget _buildConsultResult(RecommendationData data) {
    // Route tới Emergency UI nếu có critical alert
    final bool isEmergency =
        data.criticalAlerts != null && data.criticalAlerts!.isNotEmpty;
    if (isEmergency) {
      return _EmergencyCard(
        alerts: data.criticalAlerts!,
        aiMessage: data.message.content,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // [NLU Disease predictions removed from UI for clinical compliance and safety]

        // ── Engine Stats ──
        if (data.engineStats != null)
          _buildEngineStats(data.engineStats!),

        // ── Diagnostics Panel ──
        _buildDiagnosticsPanel(data),

        // ── Engine Stats ──
        if (data.engineStats != null)
          _buildEngineStats(data.engineStats!),

        // ── Diagnostics Panel ──
        _buildDiagnosticsPanel(data),

        // ── AI Answer card ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.kBorder),
            boxShadow: AppShadow.card,
          ),
          child: MarkdownBody(
            data: data.message.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 14.5,
                height: 1.65,
                color: AppTheme.kTextPrimary,
              ),
              h2: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.kTextPrimary,
              ),
              h3: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.kTextSecondary,
              ),
              strong: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // ── Safety warnings ──
        if (data.safetyWarnings != null && data.safetyWarnings!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildWarnings(data.safetyWarnings!),
        ],

        // ── Medicine list header ──
        if (data.recommendedMedicines != null &&
            data.recommendedMedicines!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kPrimary, AppTheme.kPrimaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text(
                  'Thuốc phù hợp với bạn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${data.recommendedMedicines!.length} lựa chọn',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.kTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...data.recommendedMedicines!.asMap().entries.map(
            (entry) => _buildMedicineCard(entry.value, entry.key),
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(LucideIcons.info, size: 12, color: AppTheme.kTextMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Kết quả chỉ mang tính tham khảo. Hỏi ý kiến bác sĩ trước khi dùng thuốc.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.kTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Medicine card — ranked, no ingredients, add button
  // ──────────────────────────────────────────────

  Widget _buildMedicineCard(RecommendedMedicine med, int index) {
    final rank   = med.rank ?? (index + 1);
    final isTop  = rank == 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final subtleBg = isDark ? const Color(0xFF0D1520) : AppTheme.kBg;
    final subtleBorder = isDark ? const Color(0xFF2A3A50) : AppTheme.kBorder;
    final textBody = isDark ? const Color(0xFF94A3B8) : AppTheme.kTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isTop
              ? AppTheme.kPrimary.withValues(alpha: 0.35)
              : subtleBorder,
          width: isTop ? 1.5 : 1.0,
        ),
        boxShadow: isTop ? AppShadow.primaryGlow : AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (gradient for #1, plain for others) ──
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: isTop
                  ? LinearGradient(
                      colors: isDark
                          ? [AppTheme.kPrimaryDark.withValues(alpha: 0.15), const Color(0xFF1E293B)]
                          : const [Color(0xFFF0FDFA), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isTop ? null : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isTop) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.kPrimary, AppTheme.kPrimaryDark],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text(
                          '★ #1 KHUYẾN NGHỊ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if ((med.finalScore ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppTheme.kPrimary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                                color: AppTheme.kPrimary.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            '${med.finalScore!.round()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.kPrimaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary,
                        ),
                      ),
                      if (med.genericName != null && med.genericName!.isNotEmpty)
                        Text(
                          med.genericName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.kTextMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: subtleBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: subtleBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kTextMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary,
                              ),
                            ),
                            if (med.genericName != null && med.genericName!.isNotEmpty)
                              Text(
                                med.genericName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.kTextMuted,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if ((med.finalScore ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: subtleBg,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${med.finalScore!.round()}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.kTextMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Divider line ──
          Container(height: 1, color: subtleBorder),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indications
                if ((med.indications ?? med.summary ?? '').isNotEmpty) ...[
                  Text(
                    (med.indications ?? med.summary ?? '').length > 130
                        ? '${(med.indications ?? med.summary ?? '').substring(0, 130)}...'
                        : (med.indications ?? med.summary ?? ''),
                    style: TextStyle(
                      fontSize: 13,
                      color: textBody,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Score bars
                if (med.scores != null) ...[
                  _buildScoreBars(med.scores!, isDark),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Dosage row
                if (med.dosage != null || med.frequency != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.kPrimaryDark.withValues(alpha: 0.15)
                          : AppTheme.kPrimaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.pill,
                            size: 13, color: isDark ? AppTheme.kPrimary : AppTheme.kPrimaryDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (med.dosage != null) med.dosage!,
                              if (med.frequency != null) '· ${med.frequency!}',
                              if (med.instruction != null) '· ${med.instruction!}',
                            ].join(' '),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.kPrimary : AppTheme.kPrimaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Safety and Warnings Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Safety Status: Personalized Alerts OR Compatibility Badge
                    if (med.interactionWarnings != null &&
                        med.interactionWarnings!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A1C1C) : const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppTheme.kDanger.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.alertTriangle,
                                  size: 13, color: AppTheme.kDanger),
                              const SizedBox(width: 6),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? const Color(0xFFFCA5A5)
                                          : const Color(0xFF991B1B),
                                      height: 1.4,
                                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Cảnh báo cá nhân: ',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: med.interactionWarnings!.join('\n'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF062F21) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.shieldCheck,
                                  size: 13, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tương thích với hồ sơ sức khỏe của bạn',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF047857),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 2. General Drug Cautions (Low/Medium Priority)
                    if (med.warnings != null && med.warnings!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.info,
                                size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                    height: 1.4,
                                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Chống chỉ định chung từ NSX: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    TextSpan(
                                      text: med.warnings!.length > 90
                                          ? '${med.warnings!.substring(0, 90)}...'
                                          : med.warnings!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _addMedicineToList(context, med);
                    },
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Thêm vào tủ thuốc'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.kPrimary,
                      side: BorderSide(
                          color: AppTheme.kPrimary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




  /// Score bars — 3 mét LinearProgressIndicator stack
  Widget _buildScoreBars(Map<String, double> scores, bool isDark) {
    final bars = <_ScoreBar>[];

    if (scores.containsKey('safety') && (scores['safety']! > 0)) {
      final v = scores['safety']!.clamp(0.0, 1.0);
      final pct = (v * 100).round();
      bars.add(_ScoreBar(
        icon: LucideIcons.shieldCheck,
        label: 'An toàn',
        value: v,
        pct: pct,
        color: pct >= 80
            ? AppTheme.kSuccess
            : pct >= 60
                ? AppTheme.kWarning
                : AppTheme.kDanger,
      ));
    }
    if (scores.containsKey('evidence') && (scores['evidence']! > 0.2)) {
      final v = scores['evidence']!.clamp(0.0, 1.0);
      bars.add(_ScoreBar(
        icon: LucideIcons.stethoscope,
        label: 'Phù hợp bệnh',
        value: v,
        pct: (v * 100).round(),
        color: AppTheme.kAccent,
      ));
    }
    if (scores.containsKey('history')) {
      final v = scores['history']!.clamp(0.0, 1.0);
      final pct = (v * 100).round();
      if (pct != 50 && pct > 0) {
        bars.add(_ScoreBar(
          icon: LucideIcons.users,
          label: 'Cộng đồng',
          value: v,
          pct: pct,
          color: pct >= 70
              ? const Color(0xFF8B5CF6)
              : AppTheme.kTextMuted,
        ));
      }
    }

    if (bars.isEmpty) return const SizedBox.shrink();

    return Column(
      children: bars.map((bar) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(bar.icon, size: 12,
                color: isDark ? const Color(0xFF94A3B8) : AppTheme.kTextMuted),
            const SizedBox(width: 6),
            SizedBox(
              width: 72,
              child: Text(
                bar.label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : AppTheme.kTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: bar.value,
                  minHeight: 5,
                  backgroundColor: isDark
                      ? const Color(0xFF2A3A50)
                      : AppTheme.kBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(bar.color),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 32,
              child: Text(
                '${bar.pct}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: bar.color,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }



  /// Navigate tới MedicineForm với tên thuốc pre-filled.
  /// Truyền drugCandidateId để backend có thể link về RS session (data lineage).
  /// Truyền dosage/frequency/instruction từ AI để tiết kiệm thao tác cho user.
  void _addMedicineToList(BuildContext context, RecommendedMedicine med) {
    final prefilled = MedicineModel(
      id: '',
      name: med.name,
      startDate: DateTime.now().toIso8601String(),
      // AI-generated dosage — pre-fill để user không phải nhập lại
      dosage:      med.dosage,
      frequency:   med.frequency,
      instruction: med.instruction,
      // Data lineage — drugId từ RS engine → drugCandidateId trong DB
      drugCandidateId: med.drugId,
    );
    context.push('/medicine-form', extra: prefilled);
  }

  // ──────────────────────────────────────────────
  // Warnings
  // ──────────────────────────────────────────────

  Widget _buildWarnings(List<String> warnings) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.kWarningSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(
          left: BorderSide(color: AppTheme.kWarning, width: 3),
          top: BorderSide(color: AppTheme.kWarning.withValues(alpha: 0.25)),
          right: BorderSide(color: AppTheme.kWarning.withValues(alpha: 0.25)),
          bottom: BorderSide(color: AppTheme.kWarning.withValues(alpha: 0.25)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.kWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    LucideIcons.alertTriangle,
                    size: 16,
                    color: AppTheme.kWarning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Lưu ý an toàn',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppTheme.kWarning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Error state
  // ──────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.kDangerSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.kDanger.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                LucideIcons.wifiOff,
                size: 30,
                color: AppTheme.kDanger,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Không thể kết nối',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.kTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.kTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<AIBloc>().add(SessionResetRequested());
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text('Thử lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.kPrimary,
                  side: const BorderSide(color: AppTheme.kPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Input area
  // ──────────────────────────────────────────────

  Widget _buildInputArea(BuildContext blocContext) {
    final state = blocContext.watch<AIBloc>().state;
    final bool isEmergency = state is ConsultSuccess &&
        state.data.criticalAlerts != null &&
        state.data.criticalAlerts!.isNotEmpty;
    if (isEmergency) return const SizedBox.shrink();

    final hasText = _controller.text.trim().length >= 5;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12, 10, 12,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: _getSurface(context),
        border: Border(top: BorderSide(color: _getBorder(context))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _inputFocused ? _getSurface(context) : _getBg(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _inputFocused ? AppTheme.kPrimaryDark : _getBorder(context),
                  width: _inputFocused ? 2 : 1.5,
                ),
                boxShadow: _inputFocused
                    ? [
                        BoxShadow(
                          color: AppTheme.kPrimaryDark.withValues(alpha: 0.12),
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Mô tả triệu chứng của bạn...',
                        hintStyle:
                            TextStyle(color: _getTextMuted(context), fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            EdgeInsets.fromLTRB(18, 12, 8, 12),
                        filled: false,
                      ),
                      style: TextStyle(
                          fontSize: 15, color: _getTextPrimary(context)),
                      onSubmitted: (_) => _onSend(blocContext),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hasText ? AppTheme.kPrimaryDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                  color: AppTheme.kPrimaryDark.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: hasText ? () => _onSend(blocContext) : null,
                          child: const Center(
                            child: Icon(LucideIcons.send,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kết quả chỉ mang tính tham khảo. Hỏi ý kiến bác sĩ khi cần.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: _getTextMuted(context).withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineStats(Map<String, dynamic> stats) {
    final total = stats['totalCandidates'] ?? 0;
    final filtered = stats['filteredOut'] ?? 0;
    final recommended = stats['finalRanked'] ?? stats['recommendedCount'] ?? 0;
    final latency = stats['processingMs'] ?? stats['latencyMs'] ?? stats['responseTimeMs'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildStatPill('Ứng viên: $total'),
          _buildStatPill('Lọc ra: $filtered', isWarning: filtered > 0),
          _buildStatPill('Kết quả: $recommended', isSuccess: true),
          _buildStatPill('Thời gian: ${latency}ms'),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, {bool isWarning = false, bool isSuccess = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isWarning
        ? (isDark ? const Color(0xFF2A1C1C) : const Color(0xFFFFF5F5))
        : isSuccess
            ? (isDark ? const Color(0xFF062F21) : const Color(0xFFECFDF5))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
            
    final Color border = isWarning
        ? AppTheme.kDanger.withValues(alpha: 0.25)
        : isSuccess
            ? const Color(0xFF10B981).withValues(alpha: 0.25)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final Color text = isWarning
        ? AppTheme.kDanger
        : isSuccess
            ? const Color(0xFF10B981)
            : (isDark ? const Color(0xFF94A3B8) : AppTheme.kTextSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildDiagnosticsPanel(RecommendationData data) {
    final stats = data.engineStats ?? {};
    final total = stats['totalCandidates'] ?? 0;
    final filtered = stats['filteredOut'] ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tealBg = AppTheme.kPrimary.withValues(alpha: isDark ? 0.05 : 0.02);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomPaint(
            painter: DashedRectPainter(
              color: AppTheme.kPrimary.withValues(alpha: 0.5),
              strokeWidth: 1.2,
              gap: 4.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: tealBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  key: const PageStorageKey('diagnostics_expansion_tile'),
                  title: Row(
                    children: [
                      const Icon(
                        LucideIcons.binary,
                        size: 16,
                        color: AppTheme.kPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Xem chẩn đoán thuật toán (Hybrid RS)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.kPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    _diagnosticsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: AppTheme.kPrimary,
                  ),
                  onExpansionChanged: (expanded) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _diagnosticsExpanded = expanded;
                    });
                  },
                  childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  children: [
                    Container(
                      height: 1,
                      color: AppTheme.kPrimary.withValues(alpha: 0.15),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    ),
                    _buildLayerItem(
                      step: '1',
                      title: 'Lớp 1: Khớp sản phẩm (Knowledge Base)',
                      description: 'Khớp thành công $total thuốc OTC từ cơ sở dữ liệu y tế của hệ thống.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildLayerItem(
                      step: '2',
                      title: 'Lớp 2: Bộ lọc an toàn (Deterministic Filter)',
                      description: 'Áp dụng bộ lọc bệnh nền, thai kỳ, độ tuổi, loại bỏ $filtered thuốc không an toàn. Bộ lọc kiểm tra: ĐẠT.',
                      badgeWidget: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'PASS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildLayerItem(
                      step: '3',
                      title: 'Lớp 3: Xếp hạng tối ưu (Weighted-Sum Scorer)',
                      description: 'Tính toán điểm số ưu tiên cho từng hoạt chất theo phân bổ trọng số tiêu chuẩn.',
                      extraWidget: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildWeightRow('Đặc trưng lâm sàng (Profile)', '35%'),
                            _buildWeightRow('Độ an toàn sinh học (Safety)', '45%'),
                            _buildWeightRow('Phản hồi cộng đồng (History)', '20%'),
                            Container(
                              height: 1,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            _buildWeightRow('Công thức tính', 'Score = P*35% + S*45% + H*20%'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildLayerItem(
                      step: '4',
                      title: 'Lớp 4: Biên soạn tự động (Explanation)',
                      description: 'Trợ lý dược sĩ Generative AI biên soạn hướng dẫn liều dùng tối ưu và các lưu ý lâm sàng.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerItem({
    required String step,
    required String title,
    required String description,
    Widget? badgeWidget,
    Widget? extraWidget,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary;
    final Color textSecColor = isDark ? const Color(0xFF94A3B8) : AppTheme.kTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.kPrimary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppTheme.kPrimaryDark,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecColor,
                  height: 1.45,
                ),
              ),
              if (badgeWidget != null) badgeWidget,
              if (extraWidget != null) extraWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : AppTheme.kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(AppRadius.lg),
      ));

    // Draw dashed path
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    
    for (final PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        const double len = dashWidth;
        canvas.drawPath(
          measurePath.extractPath(distance, distance + len),
          paint,
        );
        distance += len + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}

class _ScoreBar {
  final IconData icon;
  final String label;
  final double value;
  final int pct;
  final Color color;

  const _ScoreBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
  });
}

class _EmergencyCard extends StatefulWidget {
  final List<String> alerts;
  final String aiMessage;

  const _EmergencyCard({
    required this.alerts,
    required this.aiMessage,
  });

  @override
  State<_EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<_EmergencyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _makeEmergencyCall() async {
    final Uri url = Uri.parse('tel:115');
    if (await canLaunchUrl(url)) {
      HapticFeedback.heavyImpact();
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulse Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.kDangerSurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kDanger.withValues(alpha: 0.3),
                        blurRadius: 16 * _pulseAnimation.value,
                        spreadRadius: 8 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: const Icon(
                LucideIcons.alertOctagon,
                size: 38,
                color: AppTheme.kDanger,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'TÌNH TRẠNG NGUY KỊCH',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.kDanger,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hệ thống MediChain phát hiện các triệu chứng báo động đỏ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.kTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Warnings list
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1C1C) : const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppTheme.kDanger.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.alerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          LucideIcons.alertTriangle,
                          size: 14,
                          color: AppTheme.kDanger,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          alert,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // AI guidance text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182030) : AppTheme.kBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppTheme.kBorder),
              ),
              child: MarkdownBody(
                data: widget.aiMessage,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: AppTheme.kTextPrimary,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.w700),
                  h2: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kTextPrimary,
                    height: 1.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Action buttons
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _makeEmergencyCall,
                icon: const Icon(LucideIcons.phoneCall, color: Colors.white, size: 20),
                label: const Text(
                  'GỌI CẤP CỨU (115)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kDanger,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<AIBloc>().add(SessionResetRequested());
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.kTextSecondary,
                  side: BorderSide(color: AppTheme.kBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text(
                  'Nhập lại triệu chứng khác',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsultationHistoryDrawer extends StatefulWidget {
  const _ConsultationHistoryDrawer();

  @override
  State<_ConsultationHistoryDrawer> createState() => _ConsultationHistoryDrawerState();
}

class _ConsultationHistoryDrawerState extends State<_ConsultationHistoryDrawer> {
  final TextEditingController _searchController = TextEditingController();
  List<RecommendationSession> _sessions = [];
  List<RecommendationSession> _filteredSessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = getIt<AIRepository>();
      final res = await repository.getRecommendationSessions(page: 1, limit: 50);
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          _sessions = res.data!;
          _filteredSessions = res.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.message ?? 'Không thể tải lịch sử';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi khi kết nối';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredSessions = _sessions;
      } else {
        _filteredSessions = _sessions
            .where((s) => s.symptoms.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? const Color(0xFF0D1520) : AppTheme.kBg;
    final headerBg = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final borderCol = isDark ? const Color(0xFF2A3A50) : AppTheme.kBorder;
    final txtPrimary = isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary;
    final txtSecondary = isDark ? const Color(0xFF94A3B8) : AppTheme.kTextSecondary;

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: headerBg,
              child: Row(
                children: [
                  Icon(LucideIcons.history, size: 20, color: AppTheme.kPrimaryDark),
                  const SizedBox(width: 10),
                  Text(
                    'Lịch sử tư vấn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: txtPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: borderCol),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF182030) : AppTheme.kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm triệu chứng...',
                    hintStyle: TextStyle(color: txtSecondary.withOpacity(0.6), fontSize: 13.5),
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: txtSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: TextStyle(fontSize: 13.5, color: txtPrimary),
                ),
              ),
            ),

            // History List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.kPrimary,
                        ),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: txtSecondary),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: _loadHistory,
                                  child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filteredSessions.isEmpty
                          ? Center(
                              child: Text(
                                'Không có lịch sử tư vấn',
                                style: TextStyle(fontSize: 13, color: txtSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _filteredSessions.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final session = _filteredSessions[index];
                                return _HistoryItemCard(
                                  session: session,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.read<AIBloc>().add(SessionSelected(session.id));
                                    Scaffold.of(context).closeEndDrawer();
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final RecommendationSession session;
  final VoidCallback onTap;

  const _HistoryItemCard({
    required this.session,
    required this.onTap,
  });

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      
      // If today, show time
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return 'Hôm nay, $hour:$minute';
      }
      
      // Else, show date
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      return '$d/$m/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final borderCol = isDark ? const Color(0xFF2A3A50) : AppTheme.kBorder;
    final txtPrimary = isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary;

    final medCount = session.medicines?.length ?? 0;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderCol),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(session.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kPrimaryDark,
                    ),
                  ),
                  if (medCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$medCount loại thuốc',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.kPrimaryDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                session.symptoms,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: txtPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

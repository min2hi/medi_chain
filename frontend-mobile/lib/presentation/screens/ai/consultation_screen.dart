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

  /// Trích xuất chỉ phần giới thiệu bệnh từ nội dung markdown AI trả về.
  /// Dừng lại khi gặp section thuốc (heading chứa từ khoá thuốc/medicine/lựa chọn…)
  String _extractIntroOnly(String rawContent) {
    final lines = rawContent.split('\n');
    final buffer = StringBuffer();
    final stopKeywords = [
      'oresol', 'vitamin', 'smecta', 'gastropulgite', 'paracetamol',
      'ibuprofen', 'amoxicillin', 'cetirizine', 'loratadine',
      'thuốc được lựa chọn', 'thuốc gợi ý', 'các thuốc',
      'thành phần:', 'chỉ định:', 'cách dùng:', 'tác dụng phụ',
      'lý do phù hợp', '## thuốc', '# thuốc', '**1.', '**2.', '**3.',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (stopKeywords.any((kw) => lower.contains(kw))) break;
      buffer.writeln(line);
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? rawContent : result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AIBloc>(),
      child: Scaffold(
        backgroundColor: _getBg(context),
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
            IconButton(
              icon: Icon(LucideIcons.rotateCcw, size: 20,
                  color: _getTextMuted(context)),
              onPressed: () =>
                  context.read<AIBloc>().add(SessionResetRequested()),
              tooltip: 'Tư vấn mới',
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _getBorder(context)),
          ),
        ),
        body: Column(
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
                  if (state is AIError) return _buildErrorState(state.message);
                  return const SizedBox();
                },
              ),
            ),
            Builder(builder: (blocContext) => _buildInputArea(blocContext)),
          ],
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
            data: _extractIntroOnly(data.message.content),
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

  Widget _buildErrorState(String message) {
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

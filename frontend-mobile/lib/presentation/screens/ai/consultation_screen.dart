import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/ai/ai_bloc.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';

// Design tokens â€” Ä‘á»“ng nháº¥t vá»›i ChatScreen
const _kPrimary = Color(0xFF0D9488);








Color _getSurface(BuildContext context) => Theme.of(context).colorScheme.surface;
Color _getBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
Color _getBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
Color _getTextPrimary(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF0F172A);
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
    blocContext.read<AIBloc>().add(ConsultRequested(_controller.text));
    _controller.clear();
    _focusNode.unfocus();
    setState(() {});
  }

  /// TrÃ­ch xuáº¥t chá»‰ pháº§n giá»›i thiá»‡u bá»‡nh tá»« ná»™i dung markdown AI tráº£ vá».
  /// Dá»«ng láº¡i khi gáº·p section thuá»‘c (heading chá»©a tá»« khoÃ¡ thuá»‘c/medicine/lá»±a chá»nâ€¦)
  String _extractIntroOnly(String rawContent) {
    final lines = rawContent.split('\n');
    final buffer = StringBuffer();
    final stopKeywords = [
      'oresol', 'vitamin', 'smecta', 'gastropulgite', 'paracetamol',
      'ibuprofen', 'amoxicillin', 'cetirizine', 'loratadine',
      'thuá»‘c Ä‘Æ°á»£c lá»±a chá»n', 'thuá»‘c gá»£i Ã½', 'cÃ¡c thuá»‘c',
      'thÃ nh pháº§n:', 'chá»‰ Ä‘á»‹nh:', 'cÃ¡ch dÃ¹ng:', 'tÃ¡c dá»¥ng phá»¥',
      'lÃ½ do phÃ¹ há»£p', '## thuá»‘c', '# thuá»‘c', '**1.', '**2.', '**3.',
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
              // "M" gradient avatar â€” Ä‘á»“ng nháº¥t vá»›i ChatScreen
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
                    'TÆ° váº¥n AI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _getTextPrimary(context),
                    ),
                  ),
                  Text(
                    'PhÃ¢n tÃ­ch chuyÃªn sÃ¢u',
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
              tooltip: 'TÆ° váº¥n má»›i',
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Initial / empty state
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          // "M" gradient box â€” Ä‘á»“ng nháº¥t vá»›i ChatScreen
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
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
            'TÆ° váº¥n ChuyÃªn sÃ¢u AI',
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
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: const Text(
              'PhÃ¢n tÃ­ch dá»±a trÃªn há»“ sÆ¡ sá»©c khá»e cá»§a báº¡n',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'MÃ´ táº£ triá»‡u chá»©ng chi tiáº¿t (Ä‘au á»Ÿ Ä‘Ã¢u, tá»« khi nÃ o, má»©c Ä‘á»™...). AI sáº½ phÃ¢n tÃ­ch vÃ  gá»£i Ã½ thuá»‘c phÃ¹ há»£p dá»±a trÃªn lá»‹ch sá»­ cá»§a báº¡n.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: _getTextSecondary(context),
              height: 1.65,
            ),
          ),
          const SizedBox(height: 28),
          // Divider label
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, _getBorder(context)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Gá»¢I Ã TRIá»†U CHá»¨NG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getTextMuted(context),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getBorder(context), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSuggestionTile('TÃ´i bá»‹ Ä‘au Ä‘áº§u vÃ  sá»‘t nháº¹ tá»« tá»‘i qua'),
          _buildSuggestionTile('TÃ´i bá»‹ ho khan vÃ  Ä‘au há»ng, khÃ´ng sá»‘t'),
          _buildSuggestionTile('CÃ¡ch dÃ¹ng thuá»‘c Paracetamol hiá»‡u quáº£?'),
        ],
      ),
    );
  }

  /// Shimmer loading khi AI Ä‘ang xá»­ lÃ½
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // AI Ä‘ang phÃ¢n tÃ­ch indicator
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
                    color: _kPrimary,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Ä‘ang phÃ¢n tÃ­ch há»“ sÆ¡ cá»§a báº¡n...',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kPrimary,
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

  Widget _buildSuggestionTile(String text) {
    return Builder(builder: (blocContext) {
      return GestureDetector(
        onTap: () {
          _controller.text = text;
          _onSend(blocContext);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: _getSurface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _getBorder(context), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 14, color: _getTextPrimary(context)),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 15, color: _getTextMuted(context)),
            ],
          ),
        ),
      );
    });
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Consult result layout
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildConsultResult(RecommendationData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // â”€â”€ AI Answer: chá»‰ pháº§n giá»›i thiá»‡u bá»‡nh â”€â”€
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
            ],
          ),
          child: MarkdownBody(
            data: _extractIntroOnly(data.message.content),
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                  fontSize: 15, height: 1.6, color: Color(0xFF334155)),
              h2: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
          ),
        ),

        // â”€â”€ Safety warnings â”€â”€
        if (data.safetyWarnings != null &&
            data.safetyWarnings!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildWarnings(data.safetyWarnings!),
        ],

        // â”€â”€ Ranked medicine recommendations â”€â”€
        if (data.recommendedMedicines != null &&
            data.recommendedMedicines!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Thuá»‘c gá»£i Ã½ tá»« chuyÃªn gia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...data.recommendedMedicines!.asMap().entries.map(
                (entry) => _buildMedicineCard(entry.value, entry.key),
              ),
        ],

        const SizedBox(height: 16),
        const Text(
          '* LÆ°u Ã½: Káº¿t quáº£ tá»« AI chá»‰ mang tÃ­nh cháº¥t tham kháº£o. Vui lÃ²ng há»i Ã½ kiáº¿n bÃ¡c sÄ© trÆ°á»›c khi sá»­ dá»¥ng thuá»‘c.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Medicine card â€” ranked, no ingredients, add button
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMedicineCard(RecommendedMedicine med, int index) {
    final rank = med.rank ?? (index + 1);
    final isTop = rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop
              ? const Color(0xFF14B8A6).withValues(alpha: 0.40)
              : const Color(0xFFE2E8F0),
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Header: rank badge + name + top badge â”€â”€
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank number circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isTop
                        ? const Color(0xFF14B8A6)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isTop ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Medicine name
                Expanded(
                  child: Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                // Top badge
                if (isTop)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PhÃ¹ há»£p nháº¥t',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ),
              ],
            ),

            // â”€â”€ Score chips (compact) â”€â”€
            if (med.scores != null) ...[
              const SizedBox(height: 10),
              _buildScoreRow(med.scores!),
            ],

            // â”€â”€ Add to my medicines button â”€â”€
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addMedicineToList(context, med),
                icon: const Icon(LucideIcons.plus, size: 15),
                label: const Text('ThÃªm vÃ o tá»§ thuá»‘c'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF14B8A6),
                  side: const BorderSide(color: Color(0xFF14B8A6)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
    );
  }

  /// Hiá»ƒn thá»‹ Ä‘iá»ƒm an toÃ n & phÃ¹ há»£p há»“ sÆ¡ dáº¡ng compact chip
  Widget _buildScoreRow(Map<String, double> scores) {
    final items = <Widget>[];
    if (scores.containsKey('safety')) {
      items.add(_scoreChip(
        LucideIcons.shieldCheck,
        'An toÃ n',
        scores['safety']!,
        const Color(0xFF059669),
        const Color(0xFFF0FDF4),
      ));
    }
    if (scores.containsKey('profile')) {
      items.add(_scoreChip(
        LucideIcons.userCheck,
        'Há»“ sÆ¡',
        scores['profile']!,
        const Color(0xFF3B82F6),
        const Color(0xFFEFF6FF),
      ));
    }
    if (scores.containsKey('effectiveness')) {
      items.add(_scoreChip(
        LucideIcons.trendingUp,
        'Hiá»‡u quáº£',
        scores['effectiveness']!,
        const Color(0xFFF59E0B),
        const Color(0xFFFFFBEB),
      ));
    }
    return Wrap(spacing: 8, runSpacing: 6, children: items);
  }

  Widget _scoreChip(
    IconData icon,
    String label,
    double score,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$label ${(score * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate tá»›i MedicineForm vá»›i tÃªn thuá»‘c pre-filled
  void _addMedicineToList(BuildContext context, RecommendedMedicine med) {
    final prefilled = MedicineModel(
      id: '',
      name: med.name,
      startDate: DateTime.now().toIso8601String(),
    );
    context.push('/medicine-form', extra: prefilled);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Warnings
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildWarnings(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertTriangle,
                  size: 20, color: Color(0xFFEA580C)),
              const SizedBox(width: 8),
              const Text(
                'LÆ°u Ã½ quan trá»ng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9A3412),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'â€¢ ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      w,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF9A3412)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Error state
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.read<AIBloc>().add(SessionResetRequested()),
              child: const Text('Thá»­ láº¡i'),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Input area
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildInputArea(BuildContext blocContext) {
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
                  color: _inputFocused ? _kPrimary : _getBorder(context),
                  width: _inputFocused ? 2 : 1.5,
                ),
                boxShadow: _inputFocused
                    ? [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.12),
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
                        hintText: 'MÃ´ táº£ triá»‡u chá»©ng cá»§a báº¡n...',
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
                        color: hasText ? _kPrimary : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                  color: _kPrimary.withValues(alpha: 0.35),
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
              'Káº¿t quáº£ chá»‰ mang tÃ­nh tham kháº£o. Há»i Ã½ kiáº¿n bÃ¡c sÄ© khi cáº§n.',
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

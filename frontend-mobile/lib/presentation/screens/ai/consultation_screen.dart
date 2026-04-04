import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/ai/ai_bloc.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';

class ConsultationScreen extends StatefulWidget {
  final String? initialSymptom;
  const ConsultationScreen({super.key, this.initialSymptom});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSymptom != null) {
      _controller.text = widget.initialSymptom!;
    }
  }

  void _onSend(BuildContext blocContext) {
    if (_controller.text.trim().length < 5) return;
    blocContext.read<AIBloc>().add(ConsultRequested(_controller.text));
    _controller.clear();
    FocusScope.of(context).unfocus();
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Tư vấn chuyên gia AI',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.rotateCcw, size: 20),
              onPressed: () =>
                  context.read<AIBloc>().add(SessionResetRequested()),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<AIBloc, AIState>(
                builder: (context, state) {
                  if (state is AIInitial) return _buildInitialState();
                  if (state is AILoading) {
                    return const Center(child: CircularProgressIndicator());
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDFA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.activity,
              size: 64,
              color: Color(0xFF14B8A6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hệ thống Tư vấn Thông minh',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hãy mô tả triệu chứng của bạn (đau ở đâu, từ khi nào, mức độ...). AI sẽ phân tích dựa trên hồ sơ sức khỏe và lịch sử dùng thuốc của bạn để đưa ra gợi ý phù hợp nhất.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.6),
          ),
          const SizedBox(height: 32),
          _buildSuggestionTile('Tôi bị đau đầu và sốt nhẹ từ tối qua'),
          _buildSuggestionTile('Tôi bị ho khan và đau họng, không sốt'),
          _buildSuggestionTile('Cách dùng thuốc Paracetamol hiệu quả?'),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.messageSquare,
                  size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      );
    });
  }

  // ──────────────────────────────────────────────
  // Consult result layout
  // ──────────────────────────────────────────────

  Widget _buildConsultResult(RecommendationData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── AI Answer: chỉ phần giới thiệu bệnh ──
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

        // ── Safety warnings ──
        if (data.safetyWarnings != null &&
            data.safetyWarnings!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildWarnings(data.safetyWarnings!),
        ],

        // ── Ranked medicine recommendations ──
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
                  'Thuốc gợi ý từ chuyên gia',
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
          '* Lưu ý: Kết quả từ AI chỉ mang tính chất tham khảo. Vui lòng hỏi ý kiến bác sĩ trước khi sử dụng thuốc.',
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

  // ──────────────────────────────────────────────
  // Medicine card — ranked, no ingredients, add button
  // ──────────────────────────────────────────────

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
            // ── Header: rank badge + name + top badge ──
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
                      'Phù hợp nhất',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Score chips (compact) ──
            if (med.scores != null) ...[
              const SizedBox(height: 10),
              _buildScoreRow(med.scores!),
            ],

            // ── Add to my medicines button ──
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addMedicineToList(context, med),
                icon: const Icon(LucideIcons.plus, size: 15),
                label: const Text('Thêm vào tủ thuốc'),
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

  /// Hiển thị điểm an toàn & phù hợp hồ sơ dạng compact chip
  Widget _buildScoreRow(Map<String, double> scores) {
    final items = <Widget>[];
    if (scores.containsKey('safety')) {
      items.add(_scoreChip(
        LucideIcons.shieldCheck,
        'An toàn',
        scores['safety']!,
        const Color(0xFF059669),
        const Color(0xFFF0FDF4),
      ));
    }
    if (scores.containsKey('profile')) {
      items.add(_scoreChip(
        LucideIcons.userCheck,
        'Hồ sơ',
        scores['profile']!,
        const Color(0xFF3B82F6),
        const Color(0xFFEFF6FF),
      ));
    }
    if (scores.containsKey('effectiveness')) {
      items.add(_scoreChip(
        LucideIcons.trendingUp,
        'Hiệu quả',
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

  /// Navigate tới MedicineForm với tên thuốc pre-filled
  void _addMedicineToList(BuildContext context, RecommendedMedicine med) {
    final prefilled = MedicineModel(
      id: '',
      name: med.name,
      startDate: DateTime.now().toIso8601String(),
    );
    context.push('/medicine-form', extra: prefilled);
  }

  // ──────────────────────────────────────────────
  // Warnings
  // ──────────────────────────────────────────────

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
                'Lưu ý quan trọng',
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
                    '• ',
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

  // ──────────────────────────────────────────────
  // Error state
  // ──────────────────────────────────────────────

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
              child: const Text('Thử lại'),
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Mô tả triệu chứng của bạn...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _onSend(blocContext),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _onSend(blocContext),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF14B8A6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.send,
                    size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

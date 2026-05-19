import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_app_bar.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

// â”€â”€â”€ Review Queue â€” Clinical Review Workflow â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Architecture reference:
//   Â· Epic Systems: Left accent bar = severity indicator (no need to read number)
//   Â· Linear/Datadog: Smart context â€” fields adapt to data type, never show N/A
//   Â· Google Material 3: Explicit affordance â€” swipe hint shown, not hidden
//
// Discovery sources:
//   Â· SYSTEM_LLM_TRIAGE   â†’ isLLMTriage = true  â†’ show: trigger text + type
//   Â· SYSTEM_SEMANTIC_V1  â†’ isLLMTriage = false â†’ show: matched keyword + score
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadPendingReview()),
      child: const _ReviewQueueView(),
    );
  }
}

class _ReviewQueueView extends StatelessWidget {
  const _ReviewQueueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AdminAppBar(
        title: 'Duyá»‡t Äá» Xuáº¥t AI',
        showRefresh: true,
        onRefresh: () => context.read<AdminBloc>().add(LoadPendingReview()),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AdminColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, maxLines: 3, overflow: TextOverflow.ellipsis),
              backgroundColor: AdminColors.danger,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator(
              color: AdminColors.info, strokeWidth: 1.5,
            ));
          }
          if (state is AdminError) {
            return AdminErrorState(
              message: state.message,
              onRetry: () => context.read<AdminBloc>().add(LoadPendingReview()),
            );
          }
          if (state is PendingReviewLoaded) {
            return _buildList(context, state.items);
          }
          return const Center(child: CircularProgressIndicator(
            color: AdminColors.info, strokeWidth: 1.5,
          ));
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PendingReviewModel> items) {
    if (items.isEmpty) {
      return const AdminEmptyState(
        icon: LucideIcons.checkCircle2,
        message: 'KhÃ´ng cÃ³ tá»« khÃ³a chá» duyá»‡t',
        description: 'AI chÆ°a phÃ¡t hiá»‡n tá»« khÃ³a má»›i nÃ o cáº§n xem xÃ©t.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadPendingReview()),
      color: AdminColors.info,
      backgroundColor: AdminColors.surface,
      child: Column(
        children: [
          // â”€â”€ Swipe affordance hint (Google Material â€” explicit, not hidden) â”€â”€
          // Reference: Gmail swipe-to-archive always shows hint the first time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(LucideIcons.chevronRight,
                    size: 12, color: AdminColors.danger.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text('Vuá»‘t pháº£i Ä‘á»ƒ duyá»‡t Â· Vuá»‘t trÃ¡i Ä‘á»ƒ tá»« chá»‘i',
                    style: TextStyle(
                      color: AdminColors.textMuted.withOpacity(0.8),
                      fontSize: 11,
                    )),
                const Spacer(),
                Text('${items.length} chá» duyá»‡t',
                    style: const TextStyle(
                      color: AdminColors.textMuted, fontSize: 11,
                    )),
              ],
            ),
          ),
          // â”€â”€ Card list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDismissibleCard(context, items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(BuildContext context, PendingReviewModel item) {
    return Dismissible(
      key: Key('review_${item.id}'),
      background: _swipeBg(AdminColors.success, LucideIcons.check, 'DUYá»†T', Alignment.centerLeft),
      secondaryBackground: _swipeBg(AdminColors.danger, LucideIcons.x, 'Tá»ª CHá»I', Alignment.centerRight),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          context.read<AdminBloc>().add(ApproveKeyword(item.id));
        } else {
          context.read<AdminBloc>().add(RejectKeyword(item.id));
        }
        return true;
      },
      child: _ReviewCard(item: item),
    );
  }

  Widget _swipeBg(Color color, IconData icon, String label, Alignment align) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Align(
        alignment: align,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 11,
            letterSpacing: 0.5,
          )),
        ]),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Review Card â€” Epic Systems clinical density pattern
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Design decisions:
//   Â· Left 3px accent bar (Epic) = instant severity reading without numbers
//   Â· Source chip: LLM | SEM â€” tells admin HOW it was discovered
//   Â· Keyword capped at 2 lines (Cerner) â€” prevents layout explosion
//   Â· groupLabel subtitle = clinical context, always present
//   Â· Confidence: large number, color matches accent bar (consistent system)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ReviewCard extends StatelessWidget {
  final PendingReviewModel item;
  const _ReviewCard({required this.item});

  // Accent bar color = clinical severity (Epic pattern)
  // >= 85%: HIGH confidence = danger red â†’ admin must act
  // >= 65%: MEDIUM confidence = warning amber â†’ admin should review
  // < 65%:  LOW confidence = muted â†’ possibly false positive
  Color get _accentColor {
    final pct = item.confidence ?? 0;
    if (pct >= 0.85) return AdminColors.danger;
    if (pct >= 0.65) return AdminColors.warning;
    return AdminColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final pct    = item.confidence ?? 0.0;
    final pctStr = item.confidence != null ? '${(pct * 100).round()}%' : null;

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ Left accent bar (Epic Systems severity indicator) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            // Width 3px: thin enough to not dominate, thick enough to read
            // immediately when scrolling a dense list
            Container(width: 3, color: _accentColor),

            // â”€â”€ Main content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: status chips + time + confidence
                        Row(
                          children: [
                            _Chip('PENDING', AdminColors.info),
                            const SizedBox(width: 5),
                            // Source chip: LLM = AI language model, SEM = vector search
                            _Chip(
                              item.isLLMTriage ? 'LLM' : 'SEM',
                              AdminColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(item.discoveredAt),
                              style: const TextStyle(
                                color: AdminColors.textMuted, fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            if (pctStr != null) ...[
                              Text(pctStr, style: TextStyle(
                                color: _accentColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              )),
                              const SizedBox(width: 3),
                              // "conf" label aligned to baseline of number
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('conf', style: const TextStyle(
                                  color: AdminColors.textMuted, fontSize: 9,
                                )),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Row 2: Keyword text (main clinical focus)
                        // maxLines: 2 â€” Cerner pattern, prevents card explosion
                        Text(
                          item.keyword,
                          style: const TextStyle(
                            color: AdminColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Row 3: Group/category (clinical context)
                        if (item.groupLabel != null &&
                            item.groupLabel!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.groupLabel!,
                            style: const TextStyle(
                              color: AdminColors.textMuted, fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // â”€â”€ Trigger context (collapsible) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  if (item.changeNote != null &&
                      item.changeNote!.startsWith('[AUTO]'))
                    _TriggerContextBox(
                      changeNote: item.changeNote!,
                      isLLMTriage: item.isLLMTriage,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1)  return 'vá»«a phÃ¡t hiá»‡n';
    if (d.inHours < 1)    return '${d.inMinutes}ph trÆ°á»›c';
    if (d.inDays < 1)     return '${d.inHours}h trÆ°á»›c';
    return '${dt.day}/${dt.month}';
  }
}

// â”€â”€â”€ Chip widget â€” reusable status/source badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label, style: TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    )),
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TriggerContextBox â€” Smart context, zero N/A (Datadog pattern)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Design decision (Datadog): Fields adapt to the data type available.
//   LLM Triage    â†’ show: trigger text + emergency type (no similarity score)
//   Semantic       â†’ show: trigger text + matched keyword + similarity score
// This is why we never show "N/A" â€” we only show fields that have real data.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TriggerContextBox extends StatefulWidget {
  const _TriggerContextBox({
    required this.changeNote,
    required this.isLLMTriage,
  });
  final String changeNote;
  final bool   isLLMTriage;

  @override
  State<_TriggerContextBox> createState() => _TriggerContextBoxState();
}

class _TriggerContextBoxState extends State<_TriggerContextBox> {
  bool _expanded = false;

  // Parse changeNote into structured fields based on discovery method
  // LLM format:      [AUTO] Trigger: "..." | Type: ... | Confidence: ...%
  // Semantic format: [AUTO] Trigger: "..." | Score: ...% | Matched: "..."
  Map<String, String> _parse() {
    final note         = widget.changeNote;
    final triggerMatch = RegExp(r'Trigger: "([^"]*)"').firstMatch(note);
    final trigger      = triggerMatch?.group(1) ?? note.replaceAll('[AUTO] ', '');

    if (widget.isLLMTriage) {
      final typeMatch = RegExp(r'Type: ([^|]+)').firstMatch(note);
      final confMatch = RegExp(r'Confidence: ([\d.]+%)').firstMatch(note);
      return {
        'trigger': trigger,
        'type':    typeMatch?.group(1)?.trim() ?? 'â€”',
        'conf':    confMatch?.group(1)          ?? 'â€”',
      };
    } else {
      final scoreMatch   = RegExp(r'Score: ([\d.]+%)').firstMatch(note);
      final matchedMatch = RegExp(r'Matched: "([^"]*)"').firstMatch(note);
      return {
        'trigger': trigger,
        'score':   scoreMatch?.group(1)   ?? 'â€”',
        'matched': matchedMatch?.group(1) ?? 'â€”',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parse();
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: AdminColors.bg,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
          border: Border(top: BorderSide(color: AdminColors.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row â€” always visible
            Row(children: [
              Icon(LucideIcons.alertTriangle,
                  color: AdminColors.textMuted, size: 11),
              const SizedBox(width: 6),
              Text(
                widget.isLLMTriage ? 'LLM Triage Â· Chi tiáº¿t' : 'Semantic Â· Chi tiáº¿t',
                style: const TextStyle(
                  color: AdminColors.textMuted, fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                color: AdminColors.textMuted, size: 12,
              ),
            ]),

            // Expanded content â€” smart fields per discovery method
            if (_expanded) ...[
              const SizedBox(height: 10),
              // Trigger text (shared between both methods)
              _row('Ná»™i dung chat', '"${parsed['trigger']}"'),
              const SizedBox(height: 5),

              // LLM-specific fields
              if (widget.isLLMTriage) ...[
                _row('PhÃ¢n loáº¡i',    parsed['type']!),
                const SizedBox(height: 5),
                _row('PhÃ¡t hiá»‡n bá»Ÿi', 'LLM Triage (Groq)'),
              ]
              // Semantic-specific fields
              else ...[
                _row('Tá»« khÃ³a tÆ°Æ¡ng tá»±', parsed['matched']!),
                const SizedBox(height: 5),
                _row('Äá»™ tÆ°Æ¡ng Ä‘á»“ng',    parsed['score']!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 108,
        child: Text('$label:', style: const TextStyle(
          color: AdminColors.textMuted, fontSize: 11,
        )),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(
          color: AdminColors.textSecondary, fontSize: 11,
        ), maxLines: 3, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}


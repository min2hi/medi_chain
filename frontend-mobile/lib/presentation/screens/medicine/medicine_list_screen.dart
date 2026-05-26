import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/status_badge.dart';
import 'package:medi_chain_mobile/presentation/screens/ai/consultation_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/prescription_scanner_screen.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';

class MedicineListScreen extends StatelessWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<MedicineBloc>()..add(MedicinesFetchRequested()),
      child: Scaffold(
        
        appBar: AppBar(
          title: Text(
            'medicine.title'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: ctx.read<MedicineBloc>(),
                      child: const PrescriptionScannerScreen(),
                    ),
                  ),
                ).then((_) =>
                    ctx.read<MedicineBloc>().add(MedicinesFetchRequested())),
                tooltip: 'Scan đơn thuốc',
                icon: const Icon(LucideIcons.scanLine, size: 20),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _MediAIBanner(),
            Expanded(
              child: BlocBuilder<MedicineBloc, MedicineState>(
                builder: (context, state) {
                  if (state is MedicineLoading)
                    return const AppSkeletonList(count: 5);
                  if (state is MedicineError)
                    return Center(child: Text(state.message));
                  if (state is MedicinesLoaded) {
                    if (state.medicines.isEmpty) return _buildEmptyState(context);
                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<MedicineBloc>().add(MedicinesFetchRequested()),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.medicines.length,
                        itemBuilder: (context, index) => StaggeredListItem(
                          index: index,
                          child: _buildMedicineCard(context, state.medicines[index]),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/medicine-form').then(
            (_) => context.read<MedicineBloc>().add(MedicinesFetchRequested()),
          ),
          backgroundColor: const Color(0xFF14B8A6),
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Reference: Ada Health, Oscar Health — minimal icon, no background container
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.pill,
              size: 36,
              color: isDark ? const Color(0xFF2D4A6A) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 20),
            Text(
              'medicine.empty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'medicine.empty_sub'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => context.push('/medicine-form').then(
                (_) => context.read<MedicineBloc>().add(MedicinesFetchRequested()),
              ),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('medicine.add'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF14B8A6),
                side: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMedicineCard(BuildContext context, MedicineModel med) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final border  = isDark ? const Color(0xFF2D3F55) : AppTheme.kBorder;

    // ── Urgency logic ──
    final urgencyColor = StatusBadge.urgencyColor(med.endDate);
    final variant      = StatusBadge.fromMedicineEnd(med.endDate);
    final daysLeft     = med.endDate != null
        ? DateTime.tryParse(med.endDate!)?.difference(DateTime.now()).inDays
        : null;
    final isExpired    = daysLeft != null && daysLeft < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
        boxShadow: isDark ? null : AppShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/medicine-form', extra: med).then(
              (_) => context.read<MedicineBloc>().add(MedicinesFetchRequested()),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left urgency bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: isExpired ? AppTheme.kTextMuted : urgencyColor,
                      borderRadius: const BorderRadius.only(
                        topLeft:    Radius.circular(AppRadius.lg),
                        bottomLeft: Radius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + badge row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pill icon with tinted bg
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? AppTheme.kBorder.withOpacity(0.5)
                                      : urgencyColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Icon(
                                  LucideIcons.pill,
                                  size: 16,
                                  color: isExpired ? AppTheme.kTextMuted : urgencyColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      med.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isExpired
                                            ? AppTheme.kTextMuted
                                            : (isDark ? const Color(0xFFE2E8F0) : AppTheme.kTextPrimary),
                                        decoration: isExpired ? TextDecoration.lineThrough : null,
                                        decorationColor: AppTheme.kTextMuted,
                                      ),
                                    ),
                                    if (med.dosage != null || med.frequency != null) ...[  
                                      const SizedBox(height: 2),
                                      Text(
                                        [med.dosage, med.frequency]
                                            .where((e) => e != null && e.isNotEmpty)
                                            .join(' · '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Semantic status badge
                              if (isExpired)
                                StatusBadge(
                                  label: 'Hết hạn',
                                  variant: BadgeVariant.neutral,
                                  small: true,
                                )
                              else
                                StatusBadge(
                                  label: med.endDate == null
                                      ? 'Đang dùng'
                                      : variant == BadgeVariant.danger
                                          ? 'Sắp hết'
                                          : variant == BadgeVariant.warning
                                              ? 'Còn ít'
                                              : 'Active',
                                  variant: med.endDate == null ? BadgeVariant.success : variant,
                                  small: true,
                                ),
                            ],
                          ),

                          // Dates row
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 12,
                                color: isDark ? const Color(0xFF4A6080) : const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                DateFormat('dd/MM/yyyy').format(DateTime.parse(med.startDate)),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.kTextMuted,
                                ),
                              ),
                              if (med.endDate != null) ...[
                                Text(
                                  '  →  ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF2D3F55) : AppTheme.kBorder,
                                  ),
                                ),
                                Icon(
                                  LucideIcons.calendarClock,
                                  size: 12,
                                  color: isExpired
                                      ? AppTheme.kTextMuted
                                      : urgencyColor.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(DateTime.parse(med.endDate!)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isExpired ? AppTheme.kTextMuted : urgencyColor,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Days remaining bar
                          if (daysLeft != null && daysLeft >= 0) ...[
                            const SizedBox(height: 10),
                            _DaysBar(daysLeft: daysLeft, urgencyColor: urgencyColor, isDark: isDark),
                          ],

                          // Instruction
                          if (med.instruction != null && med.instruction!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D1520)
                                    : AppTheme.kBg,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.info,
                                    size: 11,
                                    color: AppTheme.kTextMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      med.instruction!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.kTextSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin progress bar showing days remaining vs total duration
class _DaysBar extends StatelessWidget {
  final int daysLeft;
  final Color urgencyColor;
  final bool isDark;
  const _DaysBar({required this.daysLeft, required this.urgencyColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Cap display at 30 days for visual clarity
    final fraction = (daysLeft / 30.0).clamp(0.0, 1.0);
    final label = daysLeft == 0
        ? 'Hết hôm nay'
        : daysLeft == 1
            ? 'Còn 1 ngày'
            : 'Còn $daysLeft ngày';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: urgencyColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 3,
            backgroundColor: isDark
                ? urgencyColor.withOpacity(0.1)
                : urgencyColor.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// mediAI Banner — AI consultation quick-access
// ──────────────────────────────────────────────

class _MediAIBanner extends StatelessWidget {
  const _MediAIBanner();

  void _openConsultation(BuildContext context, {String? symptom}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationScreen(initialSymptom: symptom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182030) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConsultation(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 20,
                      color: AppTheme.kPrimaryDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'medicine.ai_banner_title'.tr(),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'medicine.ai_banner_sub'.tr(),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFFCBD5E1)),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Quick suggestion chips
                Text(
                  'medicine.common_symptoms'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(context, 'Tôi bị đau đầu và sốt nhẹ từ tối qua'),
                    _chip(context, 'Tôi bị ho khan và đau họng, không sốt'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openConsultation(context, symptom: label),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}




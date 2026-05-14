import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/presentation/screens/ai/consultation_screen.dart';
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
          actions: [],

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
                        itemBuilder: (context, index) =>
                            _buildMedicineCard(context, state.medicines[index]),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/medicine-form', extra: med).then(
          (_) => context.read<MedicineBloc>().add(MedicinesFetchRequested()),
        ),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 6, color: Color(0xFF14B8A6)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                med.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                            ),
                            _buildStatusBadge(med),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (med.dosage != null || med.frequency != null)
                          _buildInfoRow(
                            LucideIcons.clock,
                            '${med.dosage ?? ''} · ${med.frequency ?? ''}',
                          ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          LucideIcons.calendar,
                          'medicine.start_date'.tr(namedArgs: {'date': DateFormat('dd/MM/yyyy').format(DateTime.parse(med.startDate))}),
                        ),
                        if (med.endDate != null) ...[
                          SizedBox(height: 4),
                          _buildInfoRow(
                            LucideIcons.calendar,
                            'medicine.end_date'.tr(namedArgs: {'date': DateFormat('dd/MM/yyyy').format(DateTime.parse(med.endDate!))}),
                            color: Color(0xFFDC2626).withOpacity(0.8),
                          ),
                        ],
                        if (med.instruction != null) ...[
                          Divider(height: 24),
                          Text(
                            med.instruction!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontStyle: FontStyle.italic,
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
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Color(0xFF94A3B8)),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color ?? Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(MedicineModel med) {
    bool isActive = true;
    if (med.endDate != null)
      isActive = DateTime.parse(med.endDate!).isAfter(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Color(0xFFF0FDF4) : Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'medicine.status_active'.tr() : 'medicine.status_inactive'.tr(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Color(0xFF16A34A) : Color(0xFFDC2626),
        ),
      ),
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
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                      color: const Color(0xFF0D9488),
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
    return GestureDetector(
      onTap: () => _openConsultation(context, symptom: label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
    );
  }
}

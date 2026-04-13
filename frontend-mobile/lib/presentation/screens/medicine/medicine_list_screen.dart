import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Quản lý thuốc',
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
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.pill,
                size: 64,
                color: Colors.blue.shade200,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có thuốc nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm thuốc bạn đang sử dụng để được nhắc nhở và theo dõi liều dùng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/medicine-form').then(
                (_) => context.read<MedicineBloc>().add(MedicinesFetchRequested()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Thêm thuốc ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(BuildContext context, MedicineModel med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                Container(width: 6, color: const Color(0xFF14B8A6)),
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            _buildStatusBadge(med),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (med.dosage != null || med.frequency != null)
                          _buildInfoRow(
                            LucideIcons.clock,
                            '${med.dosage ?? ''} · ${med.frequency ?? ''}',
                          ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          LucideIcons.calendar,
                          'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(med.startDate))}',
                        ),
                        if (med.endDate != null) ...[
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            LucideIcons.calendar,
                            'Hết hạn: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(med.endDate!))}',
                            color: const Color(0xFFDC2626).withOpacity(0.8),
                          ),
                        ],
                        if (med.instruction != null) ...[
                          const Divider(height: 24),
                          Text(
                            med.instruction!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
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
        Icon(icon, size: 14, color: color ?? const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color ?? const Color(0xFF64748B),
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
        color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Đang dùng' : 'Đã dừng',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConsultation(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.activity,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tư vấn thuốc AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Dựa trên hồ sơ sức khỏe của bạn',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Tư vấn ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(LucideIcons.arrowRight,
                              size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),

                // Quick suggestion chips
                const Text(
                  'Triệu chứng phổ biến:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(context, LucideIcons.thermometer,
                        'Tôi bị đau đầu và sốt nhẹ từ tối qua'),
                    _chip(context, LucideIcons.wind,
                        'Tôi bị ho khan và đau họng, không sốt'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () => _openConsultation(context, symptom: label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

Future<void> showDoctorNotesModal(
  BuildContext context,
  String appointmentId,
  String patientName, {
  ClinicAppointmentBloc? existingBloc,
}) {
  final bloc = existingBloc ?? context.read<ClinicAppointmentBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _DoctorNotesSheet(
        appointmentId: appointmentId,
        patientName: patientName,
      ),
    ),
  );
}

// ─── Medication entry model ────────────────────────────────────────────────────

class _MedEntry {
  final TextEditingController name   = TextEditingController();
  final TextEditingController dosage = TextEditingController();
  String frequency = '2 lần/ngày';
  int    days      = 5;

  void dispose() {
    name.dispose();
    dosage.dispose();
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

class _DoctorNotesSheet extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  const _DoctorNotesSheet({required this.appointmentId, required this.patientName});

  @override
  State<_DoctorNotesSheet> createState() => _DoctorNotesSheetState();
}

class _DoctorNotesSheetState extends State<_DoctorNotesSheet> {
  final _diagnosisCtrl   = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _medications      = <_MedEntry>[];
  bool _isSubmitting      = false;
  Timer? _debounceTimer;

  double _childWeight     = 10.0;
  String _selectedDosingDrug = 'Paracetamol';
  bool _showDosingHelper  = false;

  static const _freqOptions = [
    '1 lần/ngày',
    '2 lần/ngày',
    '3 lần/ngày',
    'Sáng - Chiều',
    'Sáng - Tối',
    'Sáng - Trưa - Tối',
    'Khi cần',
  ];

  void _onMedicationChangedDebounced() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _diagnosisCtrl.dispose();
    _instructionsCtrl.dispose();
    for (final m in _medications) { m.dispose(); }
    super.dispose();
  }

  void _addMedication() {
    HapticFeedback.lightImpact();
    setState(() => _medications.add(_MedEntry()));
  }

  void _removeMedication(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  String? _buildPayload() {
    final parts = <String>[];

    final diagnosis = _diagnosisCtrl.text.trim();
    if (diagnosis.isNotEmpty) parts.add('CHẨN ĐOÁN: $diagnosis');

    final validMeds = _medications.where((m) => m.name.text.trim().isNotEmpty).toList();
    if (validMeds.isNotEmpty) {
      if (parts.isNotEmpty) parts.add('───────────────────────────');
      parts.add('THUỐC KÊ:');
      for (final m in validMeds) {
        final name   = m.name.text.trim();
        final dosage = m.dosage.text.trim();
        final dose   = dosage.isNotEmpty ? ' $dosage' : '';
        parts.add('• $name$dose — ${m.frequency} — ${m.days} ngày');
      }
    }

    final instructions = _instructionsCtrl.text.trim();
    if (instructions.isNotEmpty) {
      if (parts.isNotEmpty) parts.add('───────────────────────────');
      parts.add('LỜI DẶN: $instructions');
    }

    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  void _submit(BuildContext ctx) {
    final warnings = _checkClinicalSafety();
    if (warnings.isNotEmpty) {
      showDialog(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              const Text('Cảnh báo lâm sàng'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hệ thống phát hiện một số cảnh báo an toàn trong đơn thuốc:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(w, style: const TextStyle(fontSize: 12, height: 1.4)),
                )),
                const SizedBox(height: 12),
                const Text('Bạn có chắc chắn muốn tiếp tục lưu đơn thuốc này không?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Quay lại sửa'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kError,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _executeSubmit(ctx);
              },
              child: const Text('Vẫn lưu đơn'),
            ),
          ],
        ),
      );
    } else {
      _executeSubmit(ctx);
    }
  }

  void _executeSubmit(BuildContext ctx) {
    final payload = _buildPayload();
    setState(() => _isSubmitting = true);
    ctx.read<ClinicAppointmentBloc>().add(
      ClinicAppointmentCompleteRequested(widget.appointmentId, doctorNotes: payload),
    );
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg          = isDark ? const Color(0xFF182030) : Colors.white;
    final surface     = isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC);
    final surface2    = isDark ? const Color(0xFF1E2C3D) : Colors.white;
    final textColor   = isDark ? Colors.white               : const Color(0xFF0D1520);
    final subColor    = isDark ? const Color(0xFF94A3B8)   : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2A3A50)   : const Color(0xFFE2E8F0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle ──────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 0),
                  width: 32, height: 3,
                  decoration: BoxDecoration(
                    color: borderColor, borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ── Teal accent header strip ─────────────────────────────
                _buildHeader(textColor, subColor, bg),

                // ── Step indicators ──────────────────────────────────────
                _buildStepRail(subColor, borderColor),
                const SizedBox(height: 4),

                // ── Section 1: Chẩn đoán ────────────────────────────────
                _buildDiagnosisSection(surface, surface2, textColor, subColor, borderColor, isDark),

                // ── Section 2: Thuốc kê ──────────────────────────────────
                _buildMedicationSection(surface, surface2, textColor, subColor, borderColor, isDark),

                // ── Safety warnings panel ──
                _buildSafetyWarningsPanel(borderColor, isDark),

                // ── Dosing Helper Panel ──
                _buildDosingHelperPanel(surface, borderColor, textColor, subColor, isDark),

                // ── Section 3: Lời dặn ──────────────────────────────────
                _buildInstructionsSection(surface, surface2, textColor, subColor, borderColor),

                // ── Footer hint ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(children: [
                    Icon(LucideIcons.send, size: 12, color: subColor),
                    const SizedBox(width: 6),
                    Text(
                      'Phiếu khám sẽ gửi đến bệnh nhân ngay sau khi lưu',
                      style: GoogleFonts.inter(fontSize: 11, color: subColor),
                    ),
                  ]),
                ),

                // ── Actions ─────────────────────────────────────────────
                _buildActions(context, textColor, subColor, borderColor),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  // ── Header with teal top strip ─────────────────────────────────────────────
  Widget _buildHeader(Color textColor, Color subColor, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.kPrimary, width: 3),
        ),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppTheme.kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(LucideIcons.stethoscope, size: 18, color: AppTheme.kPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiếu khám điện tử', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, color: textColor,
            )),
            Text(widget.patientName, style: GoogleFonts.inter(
              fontSize: 12, color: AppTheme.kPrimary, fontWeight: FontWeight.w500,
            )),
          ],
        )),
        // Today date badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.kPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.2)),
          ),
          child: Text(
            () {
              final now = DateTime.now();
              return '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}';
            }(),
            style: GoogleFonts.robotoMono(fontSize: 11, color: AppTheme.kPrimary),
          ),
        ),
      ]),
    );
  }

  // ── 3-step progress rail ───────────────────────────────────────────────────
  Widget _buildStepRail(Color subColor, Color borderColor) {
    const steps = ['Chẩn đoán', 'Thuốc kê', 'Lời dặn'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: steps.asMap().entries.expand((e) {
          final i    = e.key;
          final step = e.value;
          return [
            _StepBadge(index: i + 1, label: step),
            if (i < steps.length - 1)
              Expanded(child: Container(height: 1, color: AppTheme.kPrimary.withValues(alpha: 0.2))),
          ];
        }).toList(),
      ),
    );
  }

  // ── Section 1: Chẩn đoán ──────────────────────────────────────────────────
  Widget _buildDiagnosisSection(
    Color surface, Color surface2, Color textColor, Color subColor, Color borderColor, bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label inside card
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(children: [
                _StepBadge(index: 1, label: 'CHẨN ĐOÁN', mini: true),
              ]),
            ),
            Container(height: 0.5, color: borderColor),
            TextField(
              controller: _diagnosisCtrl,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14, color: textColor, height: 1.6),
              decoration: InputDecoration(
                hintText: 'VD: Viêm họng cấp, cúm A...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: subColor.withValues(alpha: 0.55)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 2: Thuốc kê ───────────────────────────────────────────────────
  Widget _buildMedicationSection(
    Color surface, Color surface2, Color textColor, Color subColor, Color borderColor, bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            _StepBadge(index: 2, label: 'THUỐC KÊ', mini: true),
            const Spacer(),
            TextButton.icon(
              onPressed: _addMedication,
              icon: Icon(LucideIcons.plus, size: 13, color: AppTheme.kPrimary),
              label: Text('Thêm thuốc', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.kPrimary,
              )),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ]),
          const SizedBox(height: 6),

          // Empty state — dashed border button
          if (_medications.isEmpty)
            GestureDetector(
              onTap: _addMedication,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppTheme.kPrimary.withValues(alpha: 0.3),
                    strokeAlign: BorderSide.strokeAlignInside,
                    // Dashed border via CustomPaint — simulate với opacity pattern
                  ),
                  color: AppTheme.kPrimary.withValues(alpha: 0.03),
                ),
                child: Column(children: [
                  Icon(LucideIcons.pill, size: 20, color: AppTheme.kPrimary.withValues(alpha: 0.4)),
                  const SizedBox(height: 6),
                  Text('Nhấn để thêm thuốc vào phiếu kê đơn',
                    style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.kPrimary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    )),
                ]),
              ),
            )
          else
            ..._medications.asMap().entries.map((e) => _MedicationCard(
              key: ValueKey(e.value),
              med: e.value,
              index: e.key,
              isDark: isDark,
              textColor: textColor,
              subColor: subColor,
              borderColor: borderColor,
              surface2: surface2,
              freqOptions: _freqOptions,
              onRemove: () => _removeMedication(e.key),
              onChanged: _onMedicationChangedDebounced,
            )),
        ],
      ),
    );
  }

  // ── Section 3: Lời dặn ────────────────────────────────────────────────────
  Widget _buildInstructionsSection(
    Color surface, Color surface2, Color textColor, Color subColor, Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: _StepBadge(index: 3, label: 'LỜI DẶN', mini: true),
            ),
            Container(height: 0.5, color: borderColor),
            TextField(
              controller: _instructionsCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14, color: textColor, height: 1.6),
              decoration: InputDecoration(
                hintText: 'VD: Uống nhiều nước, nghỉ ngơi, tái khám sau 5 ngày...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: subColor.withValues(alpha: 0.55)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  // ── Safety Warnings Panel ──────────────────────────────────────────────────
  Widget _buildSafetyWarningsPanel(Color borderColor, bool isDark) {
    final warnings = _checkClinicalSafety();
    if (warnings.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C1C1D) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? const Color(0xFF60282C) : const Color(0xFFFCA5A5),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 15,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Text(
                  'CẢNH BÁO AN TOÀN LÂM SÀNG',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  warning,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _checkClinicalSafety() {
    final warnings = <String>[];
    final activeMeds = _medications
        .map((m) => m.name.text.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();

    if (activeMeds.isEmpty) return warnings;

    // 1. Drug-Drug Interactions
    final knownInteractions = {
      'warfarin': ['aspirin', 'ibuprofen', 'paracetamol'],
      'aspirin': ['warfarin', 'ibuprofen', 'corticosteroid'],
      'metformin': ['rượu', 'corticosteroid'],
      'digoxin': ['thuốc lợi tiểu', 'corticosteroid'],
      'ibuprofen': ['aspirin', 'warfarin', 'corticosteroid']
    };

    for (int i = 0; i < activeMeds.length; i++) {
      final med1 = activeMeds[i];
      knownInteractions.forEach((drugName, interactsWith) {
        if (med1.contains(drugName)) {
          for (int j = 0; j < activeMeds.length; j++) {
            if (i == j) continue;
            final med2 = activeMeds[j];
            for (final interactDrug in interactsWith) {
              if (med2.contains(interactDrug)) {
                warnings.add(
                  '⚠️ Tương tác: "${_capitalize(med1)}" và "${_capitalize(med2)}" có thể gây phản ứng phụ nguy hiểm. Cân nhắc đổi thuốc hoặc điều chỉnh liều.',
                );
              }
            }
          }
        }
      });
    }

    // 2. Duplicate therapy check (ví dụ: dùng nhiều loại NSAID hoặc paracetamol)
    int nsaidCount = 0;
    int paracetamolCount = 0;
    for (final med in activeMeds) {
      if (med.contains('ibuprofen') || med.contains('aspirin') || med.contains('diclofenac') || med.contains('meloxicam')) {
        nsaidCount++;
      }
      if (med.contains('paracetamol') || med.contains('acetaminophen') || med.contains('panadol') || med.contains('hapacol')) {
        paracetamolCount++;
      }
    }
    if (nsaidCount > 1) {
      warnings.add('⚠️ Trùng lặp điều trị: Phát hiện nhiều loại thuốc kháng viêm NSAID được kê cùng lúc. Có nguy cơ cao gây viêm loét dạ dày.');
    }
    if (paracetamolCount > 1) {
      warnings.add('⚠️ Trùng lặp điều trị: Kê nhiều thuốc chứa Paracetamol/Acetaminophen. Nguy cơ ngộ độc gan cấp tính.');
    }

    return warnings.toSet().toList(); // Remove duplicates
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ── Dosing Helper Panel ────────────────────────────────────────────────────
  Widget _buildDosingHelperPanel(
    Color surface, Color borderColor, Color textColor, Color subColor, bool isDark
  ) {
    final primaryColor = const Color(0xFF14B8A6);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _showDosingHelper ? AppTheme.kPrimary.withOpacity(0.5) : borderColor),
        ),
        child: Column(
          children: [
            // Header button to expand/collapse
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _showDosingHelper = !_showDosingHelper);
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calculator,
                      size: 16,
                      color: _showDosingHelper ? primaryColor : subColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tính liều nhi khoa (Pediatric Dosing Helper)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _showDosingHelper ? primaryColor : textColor,
                        ),
                      ),
                    ),
                    Icon(
                      _showDosingHelper ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                      color: subColor,
                    ),
                  ],
                ),
              ),
            ),

            if (_showDosingHelper) ...[
              Container(height: 0.5, color: borderColor),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weight slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cân nặng trẻ em:',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                        ),
                        Text(
                          '${_childWeight.toStringAsFixed(1)} kg',
                          style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _childWeight,
                      min: 3.0,
                      max: 40.0,
                      divisions: 37,
                      activeColor: primaryColor,
                      onChanged: (val) {
                        if (val.toInt() != _childWeight.toInt()) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() => _childWeight = val);
                      },
                    ),

                    // Drug Selection
                    Row(
                      children: [
                        Text(
                          'Hoạt chất:',
                          style: GoogleFonts.inter(fontSize: 12, color: textColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDosingDrug,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF182030) : Colors.white,
                                icon: Icon(LucideIcons.chevronDown, size: 13, color: subColor),
                                style: GoogleFonts.inter(fontSize: 12, color: textColor),
                                items: ['Paracetamol', 'Ibuprofen'].map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d, style: GoogleFonts.inter(fontSize: 12, color: textColor)),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    HapticFeedback.lightImpact();
                                    setState(() => _selectedDosingDrug = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Result box
                    _buildDosingCalculationResult(isDark),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDosingCalculationResult(bool isDark) {
    double minDose = 0;
    double maxDose = 0;
    double maxDayDose = 0;
    String interval = '';
    String note = '';

    if (_selectedDosingDrug == 'Paracetamol') {
      // 10-15 mg/kg per dose, max 75 mg/kg/day
      minDose = _childWeight * 10;
      maxDose = _childWeight * 15;
      maxDayDose = _childWeight * 75;
      interval = 'mỗi 4 - 6 giờ (tối đa 5 lần/ngày)';
      note = 'Không dùng cho trẻ suy gan nặng hoặc mẫn cảm với paracetamol.';
    } else if (_selectedDosingDrug == 'Ibuprofen') {
      // 5-10 mg/kg per dose, max 40 mg/kg/day
      minDose = _childWeight * 5;
      maxDose = _childWeight * 10;
      maxDayDose = _childWeight * 40;
      interval = 'mỗi 6 - 8 giờ';
      note = 'Dùng sau khi ăn no. Thận trọng ở trẻ có tiền sử hen suyễn hoặc xuất huyết.';
    }

    final cardBg = isDark ? const Color(0xFF121B27) : const Color(0xFFF1F5F9);
    final border = isDark ? const Color(0xFF203248) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                'Liều lượng khuyến cáo:',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : Colors.black),
              children: [
                const TextSpan(text: 'Liều mỗi lần: '),
                TextSpan(
                  text: '${minDose.toStringAsFixed(0)}mg - ${maxDose.toStringAsFixed(0)}mg',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF14B8A6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tần suất: $interval',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Tối đa/24 giờ: ${maxDayDose.toStringAsFixed(0)}mg',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '💡 Lưu ý lâm sàng: $note',
            style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context, Color textColor, Color subColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: subColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text('Huỷ', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
            builder: (ctx, _) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadow.primaryGlow,
              ),
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _submit(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.checkCircle, size: 17),
                label: Text('Lưu & Hoàn thành', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 14,
                )),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Step badge widget ─────────────────────────────────────────────────────────
class _StepBadge extends StatelessWidget {
  final int index;
  final String label;
  final bool mini;
  const _StepBadge({required this.index, required this.label, this.mini = false});

  @override
  Widget build(BuildContext context) {
    if (mini) {
      // Inside card — compact label with number dot
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: AppTheme.kPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text('$index', style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
          ))),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppTheme.kPrimary, letterSpacing: 0.8,
        )),
      ]);
    }
    // Full step indicator for the rail
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: AppTheme.kPrimary,
          shape: BoxShape.circle,
        ),
        child: Center(child: Text('$index', style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800,
        ))),
      ),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.inter(
        fontSize: 9, color: AppTheme.kPrimary,
        fontWeight: FontWeight.w600, letterSpacing: 0.3,
      )),
    ]);
  }
}

// ─── Medication card ───────────────────────────────────────────────────────────
class _MedicationCard extends StatefulWidget {
  final _MedEntry med;
  final int index;
  final bool isDark;
  final Color textColor, subColor, borderColor, surface2;
  final List<String> freqOptions;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _MedicationCard({
    super.key,
    required this.med,
    required this.index,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.borderColor,
    required this.surface2,
    required this.freqOptions,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard> {
  bool _hasName = false;

  @override
  void initState() {
    super.initState();
    _hasName = widget.med.name.text.trim().isNotEmpty;
    widget.med.name.addListener(_onNameChanged);
  }

  @override
  void didUpdateWidget(covariant _MedicationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.med.name != widget.med.name) {
      oldWidget.med.name.removeListener(_onNameChanged);
      _hasName = widget.med.name.text.trim().isNotEmpty;
      widget.med.name.addListener(_onNameChanged);
    }
  }

  @override
  void dispose() {
    widget.med.name.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    final currentHasName = widget.med.name.text.trim().isNotEmpty;
    if (currentHasName != _hasName) {
      setState(() {
        _hasName = currentHasName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final med        = widget.med;
    // Teal left-border accent khi card có data — visual anchor
    final accentColor = _hasName ? AppTheme.kPrimary : widget.borderColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: widget.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
            top:    BorderSide(color: widget.borderColor),
            right:  BorderSide(color: widget.borderColor),
            bottom: BorderSide(color: widget.borderColor),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Row(children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${widget.index + 1}', style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.kPrimary,
                  ))),
                ),
                const SizedBox(width: 6),
                Text('Thuốc ${widget.index + 1}', style: GoogleFonts.inter(
                  fontSize: 11, color: widget.subColor, fontWeight: FontWeight.w500,
                )),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.kError.withValues(alpha: 0.08),
                    ),
                    child: Icon(LucideIcons.x, size: 12, color: AppTheme.kError.withValues(alpha: 0.7)),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // Name + dosage
              Row(children: [
                Expanded(flex: 3, child: _miniInput(
                  med.name, 'Tên thuốc *', widget.textColor, widget.subColor, widget.borderColor,
                  onChanged: (_) => widget.onChanged(),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _miniInput(
                  med.dosage, '500mg', widget.textColor, widget.subColor, widget.borderColor,
                  onChanged: (_) => widget.onChanged(),
                )),
              ]),
              const SizedBox(height: 8),

              // Frequency + days stepper
              Row(children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: med.frequency,
                        isExpanded: true,
                        dropdownColor: widget.isDark ? const Color(0xFF182030) : Colors.white,
                        icon: Icon(LucideIcons.chevronDown, size: 13, color: widget.subColor),
                        style: GoogleFonts.inter(fontSize: 12, color: widget.textColor),
                        items: widget.freqOptions.map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, style: GoogleFonts.inter(fontSize: 12, color: widget.textColor)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => med.frequency = val);
                          widget.onChanged();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Days stepper
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: widget.borderColor),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _stepBtn(LucideIcons.minus, () => setState(() {
                      if (med.days > 1) med.days--;
                      widget.onChanged();
                    }), widget.subColor),
                    SizedBox(
                      width: 38,
                      child: Center(child: Text(
                        '${med.days}d',
                        style: GoogleFonts.robotoMono(
                          fontSize: 12, color: widget.textColor, fontWeight: FontWeight.w600,
                        ),
                      )),
                    ),
                    _stepBtn(LucideIcons.plus, () => setState(() {
                      if (med.days < 90) med.days++;
                      widget.onChanged();
                    }), widget.subColor),
                  ]),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInput(
    TextEditingController ctrl,
    String hint,
    Color textColor,
    Color subColor,
    Color borderColor, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 12, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 11, color: subColor.withValues(alpha: 0.5)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppTheme.kPrimary.withValues(alpha: 0.7)),
        ),
        fillColor: Colors.transparent,
        filled: true,
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 30, height: 36,
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}

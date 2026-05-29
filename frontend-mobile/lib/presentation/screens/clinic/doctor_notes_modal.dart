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

  static const _freqOptions = [
    '1 lần/ngày',
    '2 lần/ngày',
    '3 lần/ngày',
    'Sáng - Chiều',
    'Sáng - Tối',
    'Sáng - Trưa - Tối',
    'Khi cần',
  ];

  @override
  void dispose() {
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
              autofocus: true,
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
              med: e.value,
              index: e.key,
              isDark: isDark,
              textColor: textColor,
              subColor: subColor,
              borderColor: borderColor,
              surface2: surface2,
              freqOptions: _freqOptions,
              onRemove: () => _removeMedication(e.key),
              onChanged: () => setState(() {}),
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
  @override
  Widget build(BuildContext context) {
    final med        = widget.med;
    final hasName    = med.name.text.trim().isNotEmpty;
    // Teal left-border accent khi card có data — visual anchor
    final accentColor = hasName ? AppTheme.kPrimary : widget.borderColor;

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
                  onChanged: (_) { setState(() {}); widget.onChanged(); },
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

/// Mở modal ghi chú sau khám + phiếu thuốc điện tử.
///
/// [existingBloc]: Truyền vào khi caller đã pop trước khi gọi hàm này —
/// context sau pop() bị unmount và không thể dùng context.read<> an toàn.
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

// ─── Internal medication entry model ─────────────────────────────────────────

class _MedEntry {
  final TextEditingController name    = TextEditingController();
  final TextEditingController dosage  = TextEditingController();
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
  final _diagnosisController = TextEditingController();
  final _instructionsCtrl    = TextEditingController();
  final _medications         = <_MedEntry>[];
  bool _isSubmitting         = false;

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
    _diagnosisController.dispose();
    _instructionsCtrl.dispose();
    for (final m in _medications) { m.dispose(); }
    super.dispose();
  }

  void _addMedication() {
    setState(() => _medications.add(_MedEntry()));
  }

  void _removeMedication(int index) {
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  /// Format tất cả trường thành structured string để gửi lên server.
  /// Backend lưu free-text → patient thấy đúng format này trong PatientResultSheet.
  String? _buildPayload() {
    final parts = <String>[];

    final diagnosis = _diagnosisController.text.trim();
    if (diagnosis.isNotEmpty) {
      parts.add('CHẨN ĐOÁN: $diagnosis');
    }

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
      ClinicAppointmentCompleteRequested(
        widget.appointmentId,
        doctorNotes: payload,
      ),
    );
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg          = isDark ? const Color(0xFF182030) : Colors.white;
    final surface     = isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle bar ──────────────────────────────────────
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: borderColor, borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.clipboardList, size: 18, color: AppTheme.kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phiếu khám sau khám', style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700, color: textColor,
                        )),
                        Text('Bệnh nhân: ${widget.patientName}',
                            style: GoogleFonts.inter(fontSize: 13, color: subColor)),
                      ],
                    )),
                  ]),
                ),

                const SizedBox(height: 20),

                // ══════════════════════════════════════════════════════
                // SECTION 1: Chẩn đoán
                // ══════════════════════════════════════════════════════
                _sectionLabel('CHẨN ĐOÁN', subColor),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _textField(
                    controller: _diagnosisController,
                    hint: 'VD: Viêm họng cấp, Cảm cúm thông thường...',
                    surface: surface,
                    textColor: textColor,
                    subColor: subColor,
                    borderColor: borderColor,
                    maxLines: 2,
                    autofocus: true,
                  ),
                ),

                const SizedBox(height: 20),

                // ══════════════════════════════════════════════════════
                // SECTION 2: Thuốc kê
                // ══════════════════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    _labelText('THUỐC KÊ', subColor),
                    const Spacer(),
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); _addMedication(); },
                      child: Row(children: [
                        Icon(LucideIcons.plus, size: 13, color: AppTheme.kPrimary),
                        const SizedBox(width: 4),
                        Text('Thêm thuốc', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.kPrimary,
                        )),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),

                if (_medications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(children: [
                        Icon(LucideIcons.pill, size: 16, color: subColor),
                        const SizedBox(width: 8),
                        Text('Chưa có thuốc kê. Nhấn "Thêm thuốc" để thêm.',
                            style: GoogleFonts.inter(fontSize: 12, color: subColor)),
                      ]),
                    ),
                  )
                else
                  ..._medications.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final med = entry.value;
                    return _MedicationRow(
                      med: med,
                      index: idx,
                      isDark: isDark,
                      textColor: textColor,
                      subColor: subColor,
                      borderColor: borderColor,
                      surface: surface,
                      freqOptions: _freqOptions,
                      onRemove: () => _removeMedication(idx),
                      onChanged: () => setState(() {}),
                    );
                  }),

                const SizedBox(height: 20),

                // ══════════════════════════════════════════════════════
                // SECTION 3: Lời dặn / Ghi chú
                // ══════════════════════════════════════════════════════
                _sectionLabel('LỜI DẶN / GHI CHÚ', subColor),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _textField(
                    controller: _instructionsCtrl,
                    hint: 'VD: Uống nhiều nước, nghỉ ngơi, tái khám sau 5 ngày nếu không khỏi...',
                    surface: surface,
                    textColor: textColor,
                    subColor: subColor,
                    borderColor: borderColor,
                    maxLines: 4,
                  ),
                ),

                const SizedBox(height: 8),
                // Hint
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Icon(LucideIcons.info, size: 13, color: subColor),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      'Phiếu khám sẽ hiển thị cho bệnh nhân sau khi hoàn thành',
                      style: GoogleFonts.inter(fontSize: 12, color: subColor),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),

                // ══════════════════════════════════════════════════════
                // BUTTONS
                // ══════════════════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: subColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Huỷ', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
                        builder: (ctx, _) => FilledButton.icon(
                          onPressed: _isSubmitting ? null : () => _submit(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.checkCircle, size: 17),
                          label: Text('Lưu & Hoàn thành', style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 14,
                          )),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: _labelText(text, color),
  );

  Widget _labelText(String text, Color color) => Text(text,
    style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.8,
    ));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required Color surface,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        autofocus: autofocus,
        style: GoogleFonts.inter(fontSize: 14, color: textColor, height: 1.6),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: subColor.withValues(alpha: 0.6), height: 1.6),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

// ─── Medication row widget ─────────────────────────────────────────────────────
class _MedicationRow extends StatefulWidget {
  final _MedEntry med;
  final int index;
  final bool isDark;
  final Color textColor, subColor, borderColor, surface;
  final List<String> freqOptions;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _MedicationRow({
    required this.med,
    required this.index,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.borderColor,
    required this.surface,
    required this.freqOptions,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_MedicationRow> createState() => _MedicationRowState();
}

class _MedicationRowState extends State<_MedicationRow> {
  @override
  Widget build(BuildContext context) {
    final med = widget.med;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row header: số thứ tự + nút xóa
            Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(child: Text('${widget.index + 1}', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.kPrimary,
                ))),
              ),
              const SizedBox(width: 8),
              Text('Thuốc ${widget.index + 1}', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w500, color: widget.subColor,
              )),
              const Spacer(),
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(LucideIcons.x, size: 16, color: widget.subColor),
              ),
            ]),
            const SizedBox(height: 8),

            // Tên thuốc + hàm lượng (cùng 1 hàng)
            Row(children: [
              Expanded(
                flex: 3,
                child: _miniField(med.name, 'Tên thuốc *', widget.textColor, widget.subColor, widget.borderColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _miniField(med.dosage, 'Hàm lượng', widget.textColor, widget.subColor, widget.borderColor,
                    hint2: 'VD: 500mg'),
              ),
            ]),
            const SizedBox(height: 8),

            // Tần suất + số ngày
            Row(children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: widget.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: med.frequency,
                      isExpanded: true,
                      dropdownColor: widget.isDark ? const Color(0xFF182030) : Colors.white,
                      icon: Icon(LucideIcons.chevronDown, size: 14, color: widget.subColor),
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
              // Số ngày: stepper
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: widget.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.borderColor),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _stepBtn(LucideIcons.minus, () => setState(() {
                    if (med.days > 1) med.days--;
                    widget.onChanged();
                  }), widget.subColor),
                  SizedBox(width: 36, child: Center(child: Text('${med.days}d',
                    style: GoogleFonts.inter(fontSize: 12, color: widget.textColor, fontWeight: FontWeight.w600),
                  ))),
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
    );
  }

  Widget _miniField(
    TextEditingController ctrl,
    String label,
    Color textColor,
    Color subColor,
    Color borderColor, {
    String? hint2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(fontSize: 12, color: textColor),
          decoration: InputDecoration(
            hintText: hint2 ?? label,
            hintStyle: GoogleFonts.inter(fontSize: 11, color: subColor.withValues(alpha: 0.6)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.kPrimary.withValues(alpha: 0.6)),
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
          onChanged: (_) => widget.onChanged(),
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 32, height: 36,
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

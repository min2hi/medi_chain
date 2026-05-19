import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';

/// DoctorNotesModal â€” bottom sheet bÃ¡c sÄ© ghi chÃº sau khÃ¡m
/// Thiáº¿t káº¿ tham kháº£o Epic MyChart / Doximity: tráº¯ng-xanh, typography rÃµ rÃ ng
///
/// QUAN TRá»ŒNG: DÃ¹ng [existingBloc] khi caller Ä‘Ã£ pop trÆ°á»›c khi gá»i hÃ m nÃ y,
/// vÃ¬ context sau pop() bá»‹ unmount vÃ  khÃ´ng thá»ƒ dÃ¹ng context.read<>() an toÃ n.
Future<void> showDoctorNotesModal(
  BuildContext context,
  String appointmentId,
  String patientName, {
  ClinicAppointmentBloc? existingBloc,
}) {
  // Æ¯u tiÃªn bloc Ä‘Æ°á»£c truyá»n vÃ o (an toÃ n sau pop),
  // fallback: láº¥y tá»« context náº¿u váº«n cÃ²n trong tree (e.g. gá»i trá»±c tiáº¿p)
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

class _DoctorNotesSheet extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  const _DoctorNotesSheet({required this.appointmentId, required this.patientName});

  @override
  State<_DoctorNotesSheet> createState() => _DoctorNotesSheetState();
}

class _DoctorNotesSheetState extends State<_DoctorNotesSheet> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    final notes = _notesController.text.trim();
    setState(() => _isSubmitting = true);
    ctx.read<ClinicAppointmentBloc>().add(
      ClinicAppointmentCompleteRequested(
        widget.appointmentId,
        doctorNotes: notes.isEmpty ? null : notes,
      ),
    );
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Handle bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.clipboardList, size: 18, color: AppTheme.kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi chÃº sau khÃ¡m',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Bá»‡nh nhÃ¢n: ${widget.patientName}',
                            style: GoogleFonts.inter(fontSize: 13, color: subColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // â”€â”€ Label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'CHáº¨N ÄOÃN / GHI CHÃš LÃ‚M SÃ€NG',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // â”€â”€ Text area â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 6,
                    style: GoogleFonts.inter(fontSize: 14, color: textColor, height: 1.6),
                    decoration: InputDecoration(
                      hintText:
                          'VD:\nCháº©n Ä‘oÃ¡n: ViÃªm há»ng cáº¥p\n'
                          'Thuá»‘c: Amoxicillin 500mg x 2 láº§n/ngÃ y x 5 ngÃ y\n'
                          'LÆ°u Ã½: Uá»‘ng nhiá»u nÆ°á»›c, tÃ¡i khÃ¡m náº¿u sá»‘t trÃªn 39Â°C',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: subColor.withOpacity(0.6),
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // â”€â”€ Note phá»¥ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 13, color: subColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ghi chÃº sáº½ hiá»ƒn thá»‹ cho bá»‡nh nhÃ¢n trong lá»‹ch sá»­ khÃ¡m',
                        style: GoogleFonts.inter(fontSize: 12, color: subColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // â”€â”€ Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: subColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Há»§y', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
                        builder: (ctx, state) {
                          return FilledButton.icon(
                            onPressed: _isSubmitting ? null : () => _submit(ctx),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(LucideIcons.checkCircle, size: 17),
                            label: Text(
                              'LÆ°u & HoÃ n thÃ nh',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

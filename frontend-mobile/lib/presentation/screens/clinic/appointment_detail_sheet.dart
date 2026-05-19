import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/doctor_notes_modal.dart';

/// AppointmentDetailSheet â€” slide-up detail view theo chuáº©n Practo/ZocDoc.
/// Hiá»ƒn thá»‹ Ä‘áº§y Ä‘á»§ thÃ´ng tin vÃ  action buttons (chá»‰ khi PENDING).
void showAppointmentDetail(BuildContext context, Map<String, dynamic> apt) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider.value(
      value: context.read<ClinicAppointmentBloc>(),
      child: _AppointmentDetailSheet(apt: apt),
    ),
  );
}

class _AppointmentDetailSheet extends StatelessWidget {
  const _AppointmentDetailSheet({required this.apt});
  final Map<String, dynamic> apt;

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';
    final isConfirmed = status == 'CONFIRMED';
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final weekdays = ['Thá»© 2', 'Thá»© 3', 'Thá»© 4', 'Thá»© 5', 'Thá»© 6', 'Thá»© 7', 'CN'];
    final dayLabel = weekdays[date.weekday - 1];
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateStr = '$dayLabel, ${date.day}/${date.month}/${date.year}';

    final patientName = apt['user']?['name'] ?? 'áº¨n danh';
    final phone = apt['user']?['profile']?['phone'] ?? 'KhÃ´ng cÃ³ SÄT';
    final title = apt['title'] ?? 'KhÃ¡m dá»‹ch vá»¥';
    final patientNotes = apt['notes'] as String?;       // ghi chÃº cá»§a bá»‡nh nhÃ¢n
    final doctorNotes = apt['doctorNotes'] as String?;  // ghi chÃº lÃ¢m sÃ ng cá»§a bÃ¡c sÄ©
    final fee = (apt['consultFee'] as num?)?.toInt() ?? 200000;
    final payStatus = apt['paymentStatus'] as String? ?? 'UNPAID';
    final isPaid = payStatus == 'PAID';
    final isCompleted = status == 'COMPLETED';

    // Format fee
    final parts = fee.toString().split('').reversed.toList();
    final feeStr = List.generate(
      parts.length,
      (i) => (i > 0 && i % 3 == 0) ? '${parts[i]}.' : parts[i],
    ).reversed.join();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: const Border(top: BorderSide(color: AdminColors.border)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AdminColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  // â”€â”€ Header: time + date â”€â”€
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          dateStr,
                          style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(status: status),
                  const SizedBox(height: 24),
                  const Divider(color: AdminColors.border, height: 1),
                  const SizedBox(height: 20),

                  // â”€â”€ Patient â”€â”€
                  _SectionLabel('Bá»†NH NHÃ‚N'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AdminColors.elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Center(
                          child: Text(
                            patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName, style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600, color: AdminColors.textPrimary,
                          )),
                          Text(phone, style: GoogleFonts.inter(
                            fontSize: 13, color: AdminColors.textSecondary,
                          )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AdminColors.border, height: 1),
                  const SizedBox(height: 20),

                  // â”€â”€ Payment â”€â”€
                  _SectionLabel('THANH TOÃN'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '$feeStrÄ‘',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPaid ? AdminColors.success : AdminColors.warning).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPaid ? 'ÄÃ£ thanh toÃ¡n' : 'ChÆ°a thanh toÃ¡n',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPaid ? AdminColors.success : AdminColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AdminColors.border, height: 1),
                  const SizedBox(height: 20),

                  // â”€â”€ Ghi chÃº bá»‡nh nhÃ¢n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionLabel('GHI CHÃš Bá»†NH NHÃ‚N'),
                  const SizedBox(height: 10),
                  Text(
                    (patientNotes != null && patientNotes.isNotEmpty)
                        ? patientNotes
                        : 'KhÃ´ng cÃ³ ghi chÃº',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: (patientNotes != null && patientNotes.isNotEmpty)
                          ? AdminColors.textPrimary
                          : AdminColors.textMuted,
                      fontStyle: (patientNotes != null && patientNotes.isNotEmpty)
                          ? FontStyle.normal
                          : FontStyle.italic,
                      height: 1.6,
                    ),
                  ),

                  // â”€â”€ Káº¿t quáº£ lÃ¢m sÃ ng (chá»‰ hiá»‡n khi COMPLETED) â”€â”€â”€â”€â”€â”€â”€â”€
                  if (isCompleted) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AdminColors.border, height: 1),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 3, height: 14,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.kPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'Káº¾T QUáº¢ KHÃM LÃ‚M SÃ€NG',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    (doctorNotes != null && doctorNotes.isNotEmpty)
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.kPrimary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              doctorNotes,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AdminColors.textPrimary,
                                height: 1.7,
                              ),
                            ),
                          )
                        : Text(
                            'BÃ¡c sÄ© chÆ°a ghi chÃº',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AdminColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ],

                  // â”€â”€ Actions: PENDING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  if (isPending) ...[
                    const SizedBox(height: 28),
                    const Divider(color: AdminColors.border, height: 1),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _onReject(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminColors.danger,
                              side: BorderSide(color: AdminColors.danger.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('âœ•  Há»§y lá»‹ch'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _onConfirm(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('âœ“  XÃ¡c nháº­n'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // â”€â”€ Actions: CONFIRMED â€” BÃ¡c sÄ© hoÃ n thÃ nh khÃ¡m â”€â”€
                  if (isConfirmed) ...[
                    const SizedBox(height: 28),
                    const Divider(color: AdminColors.border, height: 1),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // âš ï¸ Capture bloc TRÆ¯á»šC khi pop â€” sau pop context bá»‹ unmount
                          final bloc = context.read<ClinicAppointmentBloc>();
                          final appointmentId = apt['id'] as String;
                          final patientDisplayName =
                              apt['user']?['name'] as String? ?? 'Bá»‡nh nhÃ¢n';
                          Navigator.pop(context);
                          // Truyá»n bloc Ä‘Ã£ capture vÃ o modal â€” khÃ´ng dÃ¹ng context sau pop
                          showDoctorNotesModal(
                            context,
                            appointmentId,
                            patientDisplayName,
                            existingBloc: bloc,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                        label: const Text('Ghi chÃº & HoÃ n thÃ nh khÃ¡m'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirm(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<ClinicAppointmentBloc>().add(
      ClinicAppointmentStatusUpdateRequested(apt['id'] as String, 'CONFIRMED'),
    );
    Navigator.pop(context);
  }

  void _onReject(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.read<ClinicAppointmentBloc>().add(
      ClinicAppointmentStatusUpdateRequested(apt['id'] as String, 'CANCELLED'),
    );
    Navigator.pop(context);
  }
}

// â”€â”€ Shared widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AdminColors.textMuted,
          letterSpacing: 0.8,
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case 'CONFIRMED':
        color = AdminColors.success;
        label = 'ÄÃ£ xÃ¡c nháº­n';
      case 'CANCELLED':
        color = AdminColors.danger;
        label = 'ÄÃ£ há»§y';
      case 'COMPLETED':
        color = AppTheme.kPrimary;
        label = 'HoÃ n thÃ nh';
      default:
        color = AdminColors.warning;
        label = 'Chá» duyá»‡t';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

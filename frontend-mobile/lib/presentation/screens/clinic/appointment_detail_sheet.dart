import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';

/// AppointmentDetailSheet — slide-up detail view theo chuẩn Practo/ZocDoc.
/// Hiển thị đầy đủ thông tin và action buttons (chỉ khi PENDING).
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
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    final dayLabel = weekdays[date.weekday - 1];
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateStr = '$dayLabel, ${date.day}/${date.month}/${date.year}';

    final patientName = apt['user']?['name'] ?? 'Ẩn danh';
    final phone = apt['user']?['profile']?['phone'] ?? 'Không có SĐT';
    final title = apt['title'] ?? 'Khám dịch vụ';
    final notes = apt['notes'] as String?;
    final fee = (apt['consultFee'] as num?)?.toInt() ?? 200000;
    final payStatus = apt['paymentStatus'] as String? ?? 'UNPAID';
    final isPaid = payStatus == 'PAID';

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
                  // ── Header: time + date ──
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

                  // ── Patient ──
                  _SectionLabel('BỆNH NHÂN'),
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

                  // ── Payment ──
                  _SectionLabel('THANH TOÁN'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '$feeStrđ',
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
                          isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
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

                  // ── Notes ──
                  _SectionLabel('GHI CHÚ BÁC SĨ'),
                  const SizedBox(height: 10),
                  Text(
                    (notes != null && notes.isNotEmpty) ? notes : 'Không có ghi chú',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: (notes != null && notes.isNotEmpty)
                          ? AdminColors.textPrimary
                          : AdminColors.textMuted,
                      fontStyle: (notes != null && notes.isNotEmpty)
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),

                  // ── Actions (chỉ khi PENDING) ──
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
                            child: const Text('✕  Hủy lịch'),
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
                            child: const Text('✓  Xác nhận'),
                          ),
                        ),
                      ],
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

// ── Shared widgets ────────────────────────────────────────────────────────────

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
        label = 'Đã xác nhận';
      case 'CANCELLED':
        color = AdminColors.danger;
        label = 'Đã hủy';
      case 'COMPLETED':
        color = AppTheme.kPrimary;
        label = 'Hoàn thành';
      default:
        color = AdminColors.warning;
        label = 'Chờ duyệt';
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

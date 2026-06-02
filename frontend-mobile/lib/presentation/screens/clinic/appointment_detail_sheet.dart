import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/doctor_notes_modal.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

/// AppointmentDetailSheet — slide-up detail view theo chuẩn Practo/ZocDoc.
/// Hiển thị đầy đủ thông tin và action buttons (chỉ khi PENDING).
/// Tap vào vùng tối bên ngoài để đóng (chuẩn mobile health-tech).
void showAppointmentDetail(BuildContext context, Map<String, dynamic> apt) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    enableDrag: true,
    isDismissible: true,
    builder: (ctx) => BlocProvider.value(
      value: context.read<ClinicAppointmentBloc>(),
      child: _AppointmentDetailSheet(apt: apt),
    ),
  );
}

class _AppointmentDetailSheet extends StatelessWidget {
  const _AppointmentDetailSheet({required this.apt});
  final Map<String, dynamic> apt;

  bool _isAdmin(BuildContext context) {
    try {
      final authState = context.read<AuthBloc>().state;
      return authState is Authenticated &&
          authState.user.role?.toUpperCase() == 'ADMIN';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';
    final isConfirmed = status == 'CONFIRMED';
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    final dayLabel = weekdays[date.weekday - 1];
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateStr = '$dayLabel, ${date.day}/${date.month}/${date.year}';

    final patientName = apt['user']?['name'] as String? ?? 'Ẩn danh';
    final phone = apt['user']?['profile']?['phone'] as String? ?? 'Không có SĐT';
    final title = apt['title'] as String? ?? 'Khám dịch vụ';
    final patientNotes = apt['notes'] as String?;
    final doctorNotes = apt['doctorNotes'] as String?;
    final fee = (apt['consultFee'] as num?)?.toInt() ?? 200000;
    final payStatus = apt['paymentStatus'] as String? ?? 'UNPAID';
    final isPaid = payStatus == 'PAID';
    final isCompleted = status == 'COMPLETED';

    // Format fee: 200000 → 200.000đ
    final parts = fee.toString().split('').reversed.toList();
    final feeStr = List.generate(
      parts.length,
      (i) => (i > 0 && i % 3 == 0) ? '${parts[i]}.' : parts[i],
    ).reversed.join();

    final isAdmin = _isAdmin(context);
    final surface = isAdmin ? AdminColors.surface : AppTheme.kSurface;
    final border = isAdmin ? AdminColors.border : AppTheme.kBorder;
    final textPrimary = isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary;
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;
    final textMuted = isAdmin ? AdminColors.textMuted : AppTheme.kTextMuted;
    final danger = isAdmin ? AdminColors.danger : AppTheme.kDanger;
    final success = isAdmin ? AdminColors.success : AppTheme.kSuccess;
    final warning = isAdmin ? AdminColors.warning : AppTheme.kWarning;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.6, 0.92],
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: border, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isAdmin ? 0.4 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            InkWell(
              onTap: () => Navigator.pop(context),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                          color: textPrimary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textSecondary,
                          ),
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
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(status: status, isAdmin: isAdmin),
                  const SizedBox(height: 24),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 20),

                  // ── Bệnh nhân ──
                  _SectionLabel('BỆNH NHÂN', isAdmin: isAdmin),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isAdmin ? AdminColors.elevated : AppTheme.kBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Center(
                          child: Text(
                            patientName.isNotEmpty
                                ? patientName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            phone,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 20),

                  // ── Thanh toán ──
                  _SectionLabel('THANH TOÁN', isAdmin: isAdmin),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '$feeStrđ',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPaid ? success : warning).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPaid ? success : warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 20),

                  // ── Ghi chú bệnh nhân ──
                  _SectionLabel('GHI CHÚ BỆNH NHÂN', isAdmin: isAdmin),
                  const SizedBox(height: 10),
                  Text(
                    (patientNotes != null && patientNotes.isNotEmpty)
                        ? patientNotes
                        : 'Không có ghi chú',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: (patientNotes != null && patientNotes.isNotEmpty)
                          ? textPrimary
                          : textMuted,
                      fontStyle: (patientNotes != null && patientNotes.isNotEmpty)
                          ? FontStyle.normal
                          : FontStyle.italic,
                      height: 1.6,
                    ),
                  ),

                  // ── Kết quả lâm sàng (chỉ hiện khi COMPLETED) ──
                  if (isCompleted) ...[
                    const SizedBox(height: 20),
                    Divider(color: border, height: 1),
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
                          'KẾT QUẢ KHÁM LÂM SÀNG',
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
                                color: textPrimary,
                                height: 1.7,
                              ),
                            ),
                          )
                        : Text(
                            'Bác sĩ chưa ghi chú',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ],

                  // ── Actions: PENDING ──
                  if (isPending) ...[
                    const SizedBox(height: 28),
                    Divider(color: border, height: 1),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onReject(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: danger,
                              side: BorderSide(
                                  color: danger.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            icon: const Icon(LucideIcons.x, size: 16),
                            label: const Text('Hủy lịch'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              if (isPaid) {
                                _onConfirm(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Bệnh nhân chưa thanh toán. Không thể xác nhận vào khám.',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                    ),
                                    backgroundColor: AppTheme.kError,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: isPaid ? AppTheme.kPrimary : AppTheme.kTextMuted,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            icon: const Icon(LucideIcons.check, size: 16),
                            label: Text(isPaid ? 'Xác nhận' : 'Chờ thanh toán'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Actions: CONFIRMED — Bác sĩ hoàn thành khám ──
                  if (isConfirmed) ...[
                    const SizedBox(height: 28),
                    Divider(color: border, height: 1),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Capture bloc TRƯỚC khi pop — sau pop context bị unmount
                          final bloc = context.read<ClinicAppointmentBloc>();
                          final appointmentId = apt['id'] as String;
                          final patientDisplayName =
                              apt['user']?['name'] as String? ?? 'Bệnh nhân';
                          Navigator.pop(context);
                          // Truyền bloc đã capture vào modal
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                        label: const Text('Ghi chú & Hoàn thành khám'),
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
          ClinicAppointmentStatusUpdateRequested(
              apt['id'] as String, 'CONFIRMED'),
        );
    Navigator.pop(context);
  }

  void _onReject(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.read<ClinicAppointmentBloc>().add(
          ClinicAppointmentStatusUpdateRequested(
              apt['id'] as String, 'CANCELLED'),
        );
    Navigator.pop(context);
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isAdmin});
  final String text;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAdmin ? AdminColors.textMuted : AppTheme.kTextMuted,
          letterSpacing: 0.8,
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isAdmin});
  final String status;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final success = isAdmin ? AdminColors.success : AppTheme.kSuccess;
    final danger = isAdmin ? AdminColors.danger : AppTheme.kDanger;
    final warning = isAdmin ? AdminColors.warning : AppTheme.kWarning;

    final Color color;
    final String label;
    switch (status) {
      case 'CONFIRMED':
        color = success;
        label = 'Đã xác nhận';
      case 'CANCELLED':
        color = danger;
        label = 'Đã hủy';
      case 'COMPLETED':
        color = AppTheme.kPrimary;
        label = 'Hoàn thành';
      default:
        color = warning;
        label = 'Chờ duyệt';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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

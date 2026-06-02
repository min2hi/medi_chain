import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/pulsing_dot.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/widgets/clinic_button.dart';

class UrgentCard extends StatelessWidget {
  final Map<String, dynamic> apt;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const UrgentCard({
    super.key,
    required this.apt,
    required this.onTap,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title = apt['title'] as String? ?? 'Khám dịch vụ';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final isPaid = apt['paymentStatus'] == 'PAID';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppTheme.kBorder),
            boxShadow: AppShadow.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md - 1),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              splashColor: AppTheme.kWarning.withValues(alpha: 0.06),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Accent Indicator
                    Container(
                      width: 4,
                      color: AppTheme.kWarning,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.kWarning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: AppTheme.kWarning.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    timeStr,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.kWarning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.kTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        title,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppTheme.kTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const PulsingDot(color: AppTheme.kWarning, size: 5),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ClinicButton(
                                    label: 'Hủy',
                                    color: AppTheme.kTextSecondary,
                                    onTap: onCancel,
                                    expanded: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClinicButton(
                                    label: isPaid ? 'Xác nhận' : 'Chờ thanh toán',
                                    color: isPaid ? AppTheme.kPrimary : AppTheme.kTextMuted,
                                    filled: true,
                                    onTap: () {
                                      if (isPaid) {
                                        onConfirm();
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
                                    expanded: true,
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

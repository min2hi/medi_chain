import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/widgets/clinic_button.dart';

class TodayTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> apts;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(Map<String, dynamic>) onWriteRx;

  const TodayTimeline({
    super.key,
    required this.apts,
    required this.onTap,
    required this.onWriteRx,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.kSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppTheme.kBorder),
          boxShadow: AppShadow.card,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: List.generate(apts.length, (i) {
            return Column(
              children: [
                if (i > 0) Container(height: 0.5, color: AppTheme.kBorder),
                _TimelineItem(
                  apt: apts[i],
                  isLast: i == apts.length - 1,
                  onTap: () => onTap(apts[i]),
                  onWriteRx: () => onWriteRx(apts[i]),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> apt;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onWriteRx;

  const _TimelineItem({
    required this.apt,
    required this.isLast,
    required this.onTap,
    required this.onWriteRx,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final status = apt['status'] as String? ?? 'PENDING';
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title = apt['title'] as String? ?? 'Khám dịch vụ';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final dotColor = switch (status) {
      'CONFIRMED' => AppTheme.kPrimary,
      'CANCELLED' => AppTheme.kDanger,
      'COMPLETED' => AppTheme.kSuccess,
      _ => AppTheme.kWarning,
    };

    final statusLabel = switch (status) {
      'CONFIRMED' => 'Xác nhận',
      'CANCELLED' => 'Đã hủy',
      'COMPLETED' => 'Xong',
      _ => 'Chờ',
    };

    final isConfirmed = status == 'CONFIRMED';
    final isCompleted = status == 'COMPLETED';
    final isPending = status == 'PENDING';
    final hasRx = (apt['doctorNotes'] as String?)?.isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.kPrimary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time column
                SizedBox(
                  width: 44,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      timeStr,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.kTextSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),

                // Dot + line
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.kPrimary
                              : dotColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 2),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.only(top: 2),
                            color: AppTheme.kBorder,
                          ),
                        ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patientName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.kTextPrimary,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: AppTheme.kTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: dotColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.kTextMuted,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Contextual action per status
                      if (isConfirmed)
                        ClinicButton(
                          label: 'Kê đơn & Hoàn thành',
                          color: AppTheme.kPrimary,
                          icon: LucideIcons.clipboardCheck,
                          filled: true,
                          compact: true,
                          onTap: onWriteRx,
                        ),
                      if (isPending)
                        Text(
                          '↳ Cần xác nhận trước khi khám',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.kWarning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (isCompleted)
                        Row(
                          children: [
                            Icon(
                              hasRx ? LucideIcons.send : LucideIcons.checkCircle,
                              size: 10,
                              color: hasRx ? AppTheme.kPrimary : AppTheme.kSuccess,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasRx
                                  ? 'Phiếu khám đã gửi bệnh nhân'
                                  : 'Hoàn thành · chưa kê đơn',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: hasRx ? AppTheme.kPrimary : AppTheme.kTextMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';

/// PatientResultSheet — "After Visit Summary" cho bệnh nhân.
/// Thiết kế theo Epic MyChart: clinical, trắng sạch, typography rõ ràng.
void showPatientResultSheet(BuildContext context, AppointmentModel apt) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PatientResultSheet(apt: apt),
  );
}

class _PatientResultSheet extends StatelessWidget {
  final AppointmentModel apt;
  const _PatientResultSheet({required this.apt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final date = DateTime.tryParse(apt.date)?.toLocal();
    final completedDate = apt.completedAt != null
        ? DateTime.tryParse(apt.completedAt!)?.toLocal()
        : null;
    final hasDoctorNotes = apt.doctorNotes != null && apt.doctorNotes!.isNotEmpty;

    String fmt(DateTime? d) {
      if (d == null) return '--';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    String fee(int? f) {
      if (f == null) return 'Không có';
      final parts = f.toString().split('').reversed.toList();
      return '${List.generate(parts.length, (i) => (i > 0 && i % 3 == 0) ? '${parts[i]}.' : parts[i]).reversed.join()}Ä'';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: border, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header với status badge ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.clipboardList, size: 20, color: AppTheme.kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả sau khám',
                          style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: textColor,
                          ),
                        ),
                        Text(
                          apt.title,
                          style: GoogleFonts.inter(fontSize: 13, color: subColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.kPrimary.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Hoàn thành',
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: border),

            // ── Scrollable content ────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [

                  // ── Ghi chú bác sĩ (Most important — top) ───────
                  _SectionLabel(
                    icon: LucideIcons.stethoscope,
                    text: 'GHI CHÚ CỦA BÁC SĨ',
                    color: AppTheme.kPrimary,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasDoctorNotes
                          ? (isDark ? const Color(0xFF0F2A2A) : const Color(0xFFF0FDFA))
                          : surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasDoctorNotes
                            ? AppTheme.kPrimary.withOpacity(0.2)
                            : border,
                      ),
                    ),
                    child: hasDoctorNotes
                        ? Text(
                            apt.doctorNotes!,
                            style: GoogleFonts.inter(
                              fontSize: 14, color: textColor, height: 1.7,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(LucideIcons.info, size: 16, color: subColor),
                              const SizedBox(width: 8),
                              Text(
                                'Bác sĩ chưa để lại ghi chú',
                                style: GoogleFonts.inter(
                                  fontSize: 13, color: subColor, fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // ── Thông tin buổi khám ───────────────────────────
                  _SectionLabel(
                    icon: LucideIcons.calendar,
                    text: 'THÔNG TIN BUỔI KHÁM',
                    color: subColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Lý do khám',
                          value: apt.title,
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Ngày khám',
                          value: fmt(date),
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Hoàn thành lúc',
                          value: fmt(completedDate),
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Phí khám',
                          value: fee(apt.consultFee),
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Thanh toán',
                          value: _paymentLabel(apt.paymentStatus),
                          valueColor: _paymentColor(apt.paymentStatus),
                          isDark: isDark,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  // ── Ghi chú bệnh nhân (nếu có) ──────────────────
                  if (apt.notes != null && apt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(
                      icon: LucideIcons.messageSquare,
                      text: 'GHI CHÚ KHI ĐẶT LỊCH',
                      color: subColor,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        apt.notes!,
                        style: GoogleFonts.inter(
                          fontSize: 13, color: subColor, height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String? status) {
    switch (status) {
      case 'PAID': return 'Đã thanh toán';
      case 'PENDING': return 'Đang xử lý';
      case 'FAILED': return 'Thất bại';
      case 'REFUNDED': return 'Đã hoàn tiền';
      default: return 'Chưa thanh toán';
    }
  }

  Color _paymentColor(String? status) {
    switch (status) {
      case 'PAID': return const Color(0xFF10B981);
      case 'PENDING': return const Color(0xFFF59E0B);
      case 'FAILED': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _SectionLabel({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool showDivider;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 13, color: subColor),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? textColor,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: border, indent: 16, endIndent: 16),
      ],
    );
  }
}

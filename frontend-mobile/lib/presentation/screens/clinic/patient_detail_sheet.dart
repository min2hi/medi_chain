import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// PatientDetailSheet — slide-up patient profile theo chuẩn Practo.
/// Hiển thị: avatar, thông tin liên lạc, lịch sử khám.
void showPatientDetail(BuildContext context, Map<String, dynamic> patient) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PatientDetailSheet(patient: patient),
  );
}

class _PatientDetailSheet extends StatelessWidget {
  const _PatientDetailSheet({required this.patient});
  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Ẩn danh';
    final email = patient['email'] as String? ?? '';
    final phone = patient['phone'] as String? ?? 'Không có SĐT';
    final appointments = (patient['appointments'] as List?)
        ?.map((a) => a as Map<String, dynamic>)
        .toList() ?? [];

    // Initials — max 2 ký tự
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'
        : (name.length >= 2 ? name.substring(0, 2) : name);

    // Stats
    final confirmedCount = appointments.where((a) => a['status'] == 'CONFIRMED').length;
    final completedCount = appointments.where((a) => a['status'] == 'COMPLETED').length;
    final pendingCount = appointments.where((a) => a['status'] == 'PENDING').length;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                children: [
                  // ── Patient Header ──
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.kPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            initials.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.kPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(email, style: GoogleFonts.inter(
                                fontSize: 13, color: AdminColors.textSecondary,
                              )),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 13, color: AdminColors.textMuted),
                                const SizedBox(width: 4),
                                Text(phone, style: GoogleFonts.inter(
                                  fontSize: 13, color: AdminColors.textSecondary,
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stats row ──
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AdminColors.elevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Row(
                      children: [
                        _StatCell(label: 'Tổng lịch', value: '${appointments.length}'),
                        _VertDivider(),
                        _StatCell(label: 'Chờ duyệt', value: '$pendingCount', valueColor: AdminColors.warning),
                        _VertDivider(),
                        _StatCell(label: 'Xác nhận', value: '$confirmedCount', valueColor: AdminColors.success),
                        _VertDivider(),
                        _StatCell(label: 'Hoàn thành', value: '$completedCount', valueColor: AppTheme.kPrimary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Appointment history ──
                  _SectionLabel('LỊCH SỬ KHÁM'),
                  const SizedBox(height: 12),
                  if (appointments.isEmpty)
                    _EmptyState(
                      icon: Icons.calendar_today_outlined,
                      message: 'Chưa có lịch hẹn nào',
                    )
                  else
                    ...appointments.map((apt) => _AptHistoryRow(apt: apt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appointment history row ───────────────────────────────────────────────────
class _AptHistoryRow extends StatelessWidget {
  const _AptHistoryRow({required this.apt});
  final Map<String, dynamic> apt;

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] as String? ?? 'PENDING';
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final dateStr = '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}';

    final Color statusColor;
    switch (status) {
      case 'CONFIRMED': statusColor = AdminColors.success;
      case 'CANCELLED': statusColor = AdminColors.danger;
      case 'COMPLETED': statusColor = AppTheme.kPrimary;
      default: statusColor = AdminColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apt['title'] ?? 'Khám dịch vụ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _statusLabel(status),
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
    'CONFIRMED' => 'Xác nhận',
    'CANCELLED' => 'Đã hủy',
    'COMPLETED' => 'Hoàn thành',
    _ => 'Chờ duyệt',
  };
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AdminColors.textMuted, letterSpacing: 0.8,
        ),
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: valueColor ?? AdminColors.textPrimary,
              fontFeatures: [const FontFeature.tabularFigures()],
            )),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(
              fontSize: 10, color: AdminColors.textMuted,
            )),
          ],
        ),
      );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 36,
        color: AdminColors.border,
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AdminColors.textMuted),
            const SizedBox(height: 10),
            Text(message, style: GoogleFonts.inter(
              fontSize: 14, color: AdminColors.textMuted,
            )),
          ],
        ),
      );
}

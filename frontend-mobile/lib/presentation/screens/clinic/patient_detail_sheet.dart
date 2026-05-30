import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

void showPatientDetail(BuildContext context, Map<String, dynamic> patient) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    builder: (ctx) => _PatientDetailSheet(patient: patient),
  );
}

class _PatientDetailSheet extends StatelessWidget {
  const _PatientDetailSheet({required this.patient});
  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    final name = patient['name'] as String? ?? 'Ẩn danh';
    final email = patient['email'] as String? ?? '';
    final phone = patient['phone'] as String? ?? '';
    final appointments = (patient['appointments'] as List?)
            ?.map((a) => a as Map<String, dynamic>)
            .toList() ??
        [];

    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();

    final pending   = appointments.where((a) => a['status'] == 'PENDING').length;
    final confirmed = appointments.where((a) => a['status'] == 'CONFIRMED').length;
    final completed = appointments.where((a) => a['status'] == 'COMPLETED').length;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.93,
      snap: true,
      snapSizes: const [0.62, 0.93],
      builder: (sheetCtx, sc) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Drag handle — tap to close ──
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
                      color: colors.handle, borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                controller: sc,
                padding: EdgeInsets.zero,
                children: [
                  // ── Header band ──
                  _HeaderBand(initials: initials, name: name, email: email, phone: phone),
                  // ── Stats ──
                  _StatsRow(
                    total: appointments.length,
                    pending: pending,
                    confirmed: confirmed,
                    completed: completed,
                  ),
                  // ── History ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                    child: _SectionLabel('LỊCH SỬ KHÁM'),
                  ),
                  if (appointments.isEmpty)
                    const _HistoryEmpty()
                  else
                    ...appointments.map((a) => _HistoryItem(apt: a)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header band ───────────────────────────────────────────────────────────────
class _HeaderBand extends StatelessWidget {
  const _HeaderBand({
    required this.initials,
    required this.name,
    required this.email,
    required this.phone,
  });
  final String initials, name, email, phone;

  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppTheme.kPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700,
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
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                if (email.isNotEmpty)
                  Text(email, style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Row(children: [
                    Icon(Icons.phone_outlined, size: 12, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(phone, style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                  ]),
                ] else ...[
                  const SizedBox(height: 1),
                  Text('Không có SĐT', style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.completed,
  });
  final int total, pending, confirmed, completed;

  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _StatCell('Tổng lịch', '$total', null),
          _SDivider(),
          _StatCell('Chờ duyệt', '$pending', const Color(0xFFF59E0B)),
          _SDivider(),
          _StatCell('Xác nhận', '$confirmed', const Color(0xFF10B981)),
          _SDivider(),
          _StatCell('Hoàn thành', '$completed', AppTheme.kPrimary),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value, this.color);
  final String label, value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    return Expanded(
      child: Column(children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: color ?? colors.textPrimary,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
      ]),
    );
  }
}

class _SDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    return Container(width: 1, height: 32, color: colors.divider);
  }
}

// ── History item — timeline style ─────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.apt});
  final Map<String, dynamic> apt;

  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    final status = apt['status'] as String? ?? 'PENDING';
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final Color dot = switch (status) {
      'CONFIRMED' => const Color(0xFF10B981),
      'CANCELLED' => const Color(0xFFEF4444),
      'COMPLETED' => AppTheme.kPrimary,
      _ => const Color(0xFFF59E0B),
    };

    final String label = switch (status) {
      'CONFIRMED' => 'Xác nhận',
      'CANCELLED' => 'Đã hủy',
      'COMPLETED' => 'Hoàn thành',
      _ => 'Chờ duyệt',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          Column(children: [
            Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            Container(width: 1, height: 50, color: colors.divider),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
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
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$timeStr  ·  $dateStr',
                          style: GoogleFonts.inter(
                            fontSize: 11, color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: dot.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w600, color: dot,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty history ─────────────────────────────────────────────────────────────
class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.history_outlined, size: 36, color: colors.textMuted),
          const SizedBox(height: 10),
          Text('Chưa có lịch sử khám',
              style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = _SheetColors.of(context);
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: colors.textMuted, letterSpacing: 1.0,
      ),
    );
  }
}

// ── Sheet color palette configuration ─────────────────────────────────────────
class _SheetColors {
  final Color surface;
  final Color elevated;
  final Color divider;
  final Color handle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  _SheetColors({
    required this.surface,
    required this.elevated,
    required this.divider,
    required this.handle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  factory _SheetColors.of(BuildContext context) {
    bool isAdmin = false;
    try {
      final authState = context.read<AuthBloc>().state;
      isAdmin = authState is Authenticated &&
          authState.user.role?.toUpperCase() == 'ADMIN';
    } catch (_) {}

    if (isAdmin) {
      return _SheetColors(
        surface: const Color(0xFF111827),
        elevated: const Color(0xFF1A2438),
        divider: const Color(0xFF1F2E42),
        handle: const Color(0xFF2D3F56),
        textPrimary: const Color(0xFFEFF3FF),
        textSecondary: const Color(0xFF8096B4),
        textMuted: const Color(0xFF445566),
      );
    } else {
      return _SheetColors(
        surface: AppTheme.kSurface,
        elevated: AppTheme.kBg,
        divider: AppTheme.kBorder,
        handle: AppTheme.kTextMuted.withValues(alpha: 0.3),
        textPrimary: AppTheme.kTextPrimary,
        textSecondary: AppTheme.kTextSecondary,
        textMuted: AppTheme.kTextMuted,
      );
    }
  }
}

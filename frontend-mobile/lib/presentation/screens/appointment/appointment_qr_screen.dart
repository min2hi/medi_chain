import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';

/// AppointmentQRScreen — Bệnh nhân xuất trình QR code khi đến khám.
///
/// QR data = JSON bao gồm:
///   - appointmentId, patientName, date, title, status
/// Bác sĩ / lễ tân scan → đọc appointmentId → tra cứu trong hệ thống.
///
/// Design: Dark elegant — giống Apple Wallet / hospital check-in system.
void showAppointmentQR(BuildContext context, AppointmentModel appointment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QRSheet(appointment: appointment),
  );
}

class _QRSheet extends StatelessWidget {
  const _QRSheet({required this.appointment});
  final AppointmentModel appointment;

  String _buildQRData() {
    final date = DateTime.tryParse(appointment.date);
    // exp = end of appointment day (23:59:59) — Unix timestamp seconds
    // Backend sẽ reject QR quá hạn (dùng ngày khám, không phải ngày tạo QR)
    final expDate = date != null
        ? DateTime(date.toLocal().year, date.toLocal().month, date.toLocal().day, 23, 59, 59)
        : DateTime.now().add(const Duration(hours: 24));
    final exp = expDate.millisecondsSinceEpoch ~/ 1000;

    final payload = {
      'type': 'medichain_checkin',
      'appointmentId': appointment.id,
      'title': appointment.title,
      'date': appointment.date,
      'status': appointment.status ?? 'PENDING',
      'exp': exp,
      if (date != null) 'readableDate': DateFormat('dd/MM/yyyy HH:mm').format(date),
    };
    return jsonEncode(payload);
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(appointment.date);
    final qrData = _buildQRData();
    final isConfirmed = appointment.status == 'CONFIRMED';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1520),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3A50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryDark.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.qrCode,
                color: AppTheme.kPrimaryDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mã Check-in',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
                Text('Xuất trình khi đến phòng khám',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ]),
            ),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isConfirmed
                    ? AppTheme.kPrimaryDark.withOpacity(0.15)
                    : const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isConfirmed
                      ? AppTheme.kPrimaryDark.withOpacity(0.4)
                      : const Color(0xFFF59E0B).withOpacity(0.4),
                ),
              ),
              child: Text(
                isConfirmed ? '✓ Đã xác nhận' : 'Chờ duyệt',
                style: TextStyle(
                  color: isConfirmed ? AppTheme.kPrimaryDark : const Color(0xFFF59E0B),
                  fontSize: 11, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 28),

          // QR Code container — white background để scan được
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kPrimaryDark.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0D1520),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0D1520),
                ),
              ),
              const SizedBox(height: 12),
              // Appointment ID (rút gọn)
              Text(
                '#${appointment.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 12,
                  fontFamily: 'monospace', letterSpacing: 1,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Appointment info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF182030),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3A50)),
            ),
            child: Column(children: [
              _InfoRow(
                icon: LucideIcons.stethoscope,
                label: 'Lý do khám',
                value: appointment.title,
              ),
              if (date != null) ...[
                const Divider(color: Color(0xFF2A3A50), height: 16),
                _InfoRow(
                  icon: LucideIcons.calendar,
                  label: 'Ngày giờ',
                  value: DateFormat('EEEE, dd/MM/yyyy – HH:mm', 'vi').format(date),
                ),
              ],
              if (appointment.paymentStatus == 'PAID') ...[
                const Divider(color: Color(0xFF2A3A50), height: 16),
                _InfoRow(
                  icon: LucideIcons.checkCircle,
                  label: 'Thanh toán',
                  value: 'Đã thanh toán ✓',
                  valueColor: const Color(0xFF10B981),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 16),

          // Hint text
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.info, size: 12, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 6),
            Text(
              'Đưa mã này cho bác sĩ hoặc lễ tân scan',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF64748B)),
      const SizedBox(width: 10),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}




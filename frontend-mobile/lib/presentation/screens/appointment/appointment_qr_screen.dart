import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';

/// AppointmentQRScreen — Bệnh nhân xuất trình QR code khi đến khám.
///
/// QR data = JSON bao gồm:
///   - appointmentId, patientName, date, title, status
/// Bác sĩ / lễ tân scan → đọc appointmentId → tra cứu trong hệ thống.
void showAppointmentQR(BuildContext context, AppointmentModel appointment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QRSheet(appointment: appointment),
  );
}

class _QRSheet extends StatefulWidget {
  const _QRSheet({required this.appointment});
  final AppointmentModel appointment;

  @override
  State<_QRSheet> createState() => _QRSheetState();
}

class _QRSheetState extends State<_QRSheet> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  String _buildQRData() {
    final date = DateTime.tryParse(widget.appointment.date);
    // exp = end of appointment day (23:59:59) — Unix timestamp seconds
    // Backend sẽ reject QR quá hạn (dùng ngày khám, không phải ngày tạo QR)
    final expDate = date != null
        ? DateTime(date.toLocal().year, date.toLocal().month, date.toLocal().day, 23, 59, 59)
        : DateTime.now().add(const Duration(hours: 24));
    final exp = expDate.millisecondsSinceEpoch ~/ 1000;

    final payload = {
      'type': 'medichain_checkin',
      'appointmentId': widget.appointment.id,
      'title': widget.appointment.title,
      'date': widget.appointment.date,
      'status': widget.appointment.status ?? 'PENDING',
      'exp': exp,
      if (date != null) 'readableDate': DateFormat('dd/MM/yyyy HH:mm').format(date),
    };
    return jsonEncode(payload);
  }

  Future<void> _saveQR() async {
    setState(() {
      _isSaving = true;
    });
    try {
      // Yêu cầu quyền lưu trữ hình ảnh
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng cấp quyền truy cập thư viện ảnh để lưu mã QR.'),
                backgroundColor: AppTheme.kError,
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Lấy boundary và render ảnh từ widget
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Không thể tạo file ảnh');
      final pngBytes = byteData.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: "medichain_qr_${widget.appointment.id.substring(0, 8)}",
      );

      if (result != null && (result['isSuccess'] == true || result['isSuccess'] == 'true' || result['filePath'] != null)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu mã QR thành công vào thư viện ảnh!'),
              backgroundColor: AppTheme.kSuccess,
            ),
          );
        }
      } else {
        throw Exception('Không thể lưu ảnh vào thư viện');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu mã QR: $e'),
            backgroundColor: AppTheme.kError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Giao diện thích ứng Light/Dark Mode của hệ thống
    final bgSheet = isDark ? const Color(0xFF0D1520) : Colors.white;
    final handleColor = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);
    final textHeaderColor = isDark ? Colors.white : AppTheme.kTextPrimary;
    final textSubColor = isDark ? Colors.white.withOpacity(0.5) : AppTheme.kTextSecondary;
    final infoCardBg = isDark ? const Color(0xFF182030) : const Color(0xFFF8FAFC);
    final infoCardBorder = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);
    final hintColor = isDark ? Colors.white.withOpacity(0.3) : AppTheme.kTextMuted;

    final date = DateTime.tryParse(widget.appointment.date);
    final qrData = _buildQRData();
    final isConfirmed = widget.appointment.status == 'CONFIRMED';

    return Container(
      decoration: BoxDecoration(
        color: bgSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0)),
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
              color: handleColor,
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
                Text('Mã Check-in',
                  style: TextStyle(color: textHeaderColor, fontSize: 18,
                      fontWeight: FontWeight.bold)),
                Text('Xuất trình khi đến phòng khám',
                  style: TextStyle(color: textSubColor, fontSize: 12)),
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

          // QR Code container — white background để scan được (RepaintBoundary bọc ngoài để lưu ảnh)
          RepaintBoundary(
            key: _qrKey,
            child: Container(
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
                  '#${widget.appointment.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 12,
                    fontFamily: 'monospace', letterSpacing: 1,
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // Appointment info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: infoCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: infoCardBorder),
            ),
            child: Column(children: [
              _InfoRow(
                icon: LucideIcons.stethoscope,
                label: 'Lý do khám',
                value: widget.appointment.title,
                isDark: isDark,
              ),
              if (date != null) ...[
                Divider(color: dividerColor, height: 16),
                _InfoRow(
                  icon: LucideIcons.calendar,
                  label: 'Ngày giờ',
                  value: DateFormat('EEEE, dd/MM/yyyy – HH:mm', 'vi').format(date),
                  isDark: isDark,
                ),
              ],
              if (widget.appointment.paymentStatus == 'PAID') ...[
                Divider(color: dividerColor, height: 16),
                _InfoRow(
                  icon: LucideIcons.checkCircle,
                  label: 'Thanh toán',
                  value: 'Đã thanh toán ✓',
                  valueColor: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // Save QR Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _saveQR,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.kPrimaryDark,
                      ),
                    )
                  : const Icon(LucideIcons.download, size: 16),
              label: Text(
                _isSaving ? 'Đang lưu...' : 'Lưu mã QR về máy',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kPrimaryDark,
                side: const BorderSide(color: AppTheme.kPrimaryDark),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Hint text
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.info, size: 12, color: hintColor),
            const SizedBox(width: 6),
            Text(
              'Đưa mã này cho bác sĩ hoặc lễ tân scan',
              style: TextStyle(
                color: hintColor,
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
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

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
                  color: valueColor ?? (isDark ? Colors.white : AppTheme.kTextPrimary),
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

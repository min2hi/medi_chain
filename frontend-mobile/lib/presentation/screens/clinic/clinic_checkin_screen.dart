import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

// ─── Check-in result model ────────────────────────────────────────────────────
enum _CheckInState { idle, scanning, loading, success, error }

class _CheckInResult {
  final String patientName;
  final String appointmentTitle;
  final String date;
  const _CheckInResult({
    required this.patientName,
    required this.appointmentTitle,
    required this.date,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
/// Màn hình scan QR check-in — dành cho ADMIN/DOCTOR.
/// Workflow:
///   1. Camera scan QR của bệnh nhân
///   2. Parse JSON payload → extract appointmentId
///   3. POST /admin/appointments/checkin → backend validate + cập nhật CHECKED_IN
///   4. Hiển thị kết quả (thành công / lỗi) → có thể scan tiếp
class ClinicCheckinScreen extends StatefulWidget {
  const ClinicCheckinScreen({super.key});

  @override
  State<ClinicCheckinScreen> createState() => _ClinicCheckinScreenState();
}

class _ClinicCheckinScreenState extends State<ClinicCheckinScreen>
    with WidgetsBindingObserver {
  final _api = getIt<ApiClient>();
  late final MobileScannerController _controller;

  _CheckInState _state = _CheckInState.scanning;
  _CheckInResult? _result;
  String? _errorMsg;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dừng camera khi app vào background — tiết kiệm pin, tránh conflict
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed &&
        _state == _CheckInState.scanning) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // ── Xử lý khi scan được QR (camera) ─────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state != _CheckInState.scanning) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    await _processQR(raw);
  }

  // ── Parse QR payload + gọi API check-in (shared logic) ──────────────────
  Future<void> _processQR(String raw) async {
    // Parse JSON payload
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _setError('QR không đúng định dạng MediChain', 'INVALID_QR');
      return;
    }

    // Validate type
    if (payload['type'] != 'medichain_checkin') {
      _setError('Không phải mã QR check-in MediChain', 'INVALID_QR');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _state = _CheckInState.loading);

    try {
      final response = await _api.post('/admin/appointments/checkin', data: {
        'appointmentId': payload['appointmentId'],
        'type': payload['type'],
        'exp': payload['exp'],
      });

      final data = response.data;
      if (data['success'] == true) {
        final apt = data['data'];
        if (mounted) {
          setState(() {
            _state = _CheckInState.success;
            _result = _CheckInResult(
              patientName: apt['user']?['name'] ?? 'Bệnh nhân',
              appointmentTitle: apt['title'] ?? '',
              date: apt['date'] ?? '',
            );
          });
        }
      } else {
        _setError(
          data['message'] ?? 'Check-in thất bại',
          data['errorCode'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      // Parse error response từ Dio
      String msg = 'Không thể kết nối server';
      String code = 'NETWORK_ERROR';
      try {
        final dioErr = e as dynamic;
        final errData = dioErr.response?.data as Map?;
        if (errData != null) {
          msg = errData['message'] ?? msg;
          code = errData['errorCode'] ?? code;
        }
      } catch (_) {}
      _setError(msg, code);
    }
  }

  // ── Pick ảnh từ thư viện → decode QR ─────────────────────────────────
  // Hữu ích khi dùng emulator hoặc bệnh nhân gửi screenshot QR qua chat
  Future<void> _pickAndScanImage() async {
    if (_state != _CheckInState.scanning) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() => _state = _CheckInState.loading);

    try {
      final BarcodeCapture? result =
          await _controller.analyzeImage(image.path);
      if (!mounted) return;

      if (result == null || result.barcodes.isEmpty) {
        _setError('Không tìm thấy mã QR trong ảnh', 'NO_QR_FOUND');
        return;
      }

      final raw = result.barcodes.firstOrNull?.rawValue;
      if (raw == null) {
        _setError('Không đọc được nội dung mã QR', 'INVALID_QR');
        return;
      }

      // Reset về scanning để _processQR không bị guard block
      setState(() => _state = _CheckInState.scanning);
      await _processQR(raw);
    } catch (e) {
      if (mounted) _setError('Không thể đọc ảnh', 'IMAGE_ERROR');
    }
  }

  void _setError(String msg, String code) {
    HapticFeedback.heavyImpact();
    setState(() {
      _state = _CheckInState.error;
      _errorMsg = msg;
      _errorCode = code;
    });
  }

  void _reset() {
    setState(() {
      _state = _CheckInState.scanning;
      _result = null;
      _errorMsg = null;
      _errorCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Scan Check-in',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'CLINIC',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.kPrimary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _CheckInState.scanning || _CheckInState.loading => _buildScanner(),
      _CheckInState.success => _buildSuccess(),
      _CheckInState.error   => _buildError(),
      _CheckInState.idle    => const SizedBox(),
    };
  }

  // ── Camera scanner view ────────────────────────────────────────────────────
  Widget _buildScanner() {
    return Stack(
      children: [
        // Camera feed
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),

        // Overlay — darkened border, clear center frame
        CustomPaint(
          painter: _ScanOverlayPainter(),
          child: const SizedBox.expand(),
        ),

        // Guide text top
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Đưa mã QR của bệnh nhân vào khung',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // Loading overlay khi đang gọi API
        if (_state == _CheckInState.loading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.kPrimary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang xác thực...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Nút chọn ảnh từ thư viện — hữu ích khi dùng emulator / screenshot QR
        if (_state == _CheckInState.scanning)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickAndScanImage,
                  splashColor: Colors.white.withValues(alpha: 0.12),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.image,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Chọn ảnh từ thư viện',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Success result ────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    final r = _result!;
    final date = DateTime.tryParse(r.date)?.toLocal();
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle,
                size: 32,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Check-in thành công',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bệnh nhân đã vào danh sách chờ khám',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Patient info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(
                    icon: LucideIcons.user,
                    label: 'Bệnh nhân',
                    value: r.patientName,
                    highlight: true,
                  ),
                  const SizedBox(height: 12),
                  _InfoLine(
                    icon: LucideIcons.stethoscope,
                    label: 'Lý do khám',
                    value: r.appointmentTitle,
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoLine(
                      icon: LucideIcons.clock,
                      label: 'Giờ hẹn',
                      value: dateStr,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _reset,
                icon: const Icon(LucideIcons.scanLine, size: 16),
                label: Text(
                  'Scan bệnh nhân tiếp theo',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error result ─────────────────────────────────────────────────────────
  Widget _buildError() {
    final isAlreadyDone = _errorCode == 'ALREADY_CHECKED_IN';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isAlreadyDone
                    ? const Color(0xFFF59E0B).withOpacity(0.12)
                    : const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAlreadyDone
                    ? LucideIcons.alertTriangle
                    : LucideIcons.xCircle,
                size: 28,
                color: isAlreadyDone
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAlreadyDone ? 'Đã check-in trước đó' : 'Check-in thất bại',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AdminColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _reset,
                icon: const Icon(LucideIcons.scanLine, size: 16),
                label: Text(
                  'Scan lại',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info line trong result card ──────────────────────────────────────────────
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AdminColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AdminColors.textSecondary,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: highlight
                        ? AdminColors.textPrimary
                        : AdminColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Scanner overlay painter ──────────────────────────────────────────────────
// Dark vignette + clear rect ở giữa — giống các app POS/y tế chuyên nghiệp
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 240.0;
    const cornerLen = 28.0;
    const cornerW = 3.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: frameSize,
      height: frameSize,
    );

    // Dark overlay — exclude center
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withOpacity(0.65),
    );

    // Corner brackets — teal
    final paint = Paint()
      ..color = AppTheme.kPrimary
      ..strokeWidth = cornerW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + cornerLen), Offset(rect.left, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLen, rect.top), paint);
    // Top-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.top), Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLen), paint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLen), Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLen, rect.bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.bottom), Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

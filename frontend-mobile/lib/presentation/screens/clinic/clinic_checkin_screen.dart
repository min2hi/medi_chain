import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scanner_widgets.dart';

// ─── Check-in result model ────────────────────────────────────────────────────
enum _CheckInState { idle, scanning, loading, success, error }

class _CheckInResult {
  final String patientName;
  final String appointmentTitle;
  final String date;
  // null = đã thanh toán online OK, non-null = cần xử lý tại quầy
  final String? paymentWarning;
  const _CheckInResult({
    required this.patientName,
    required this.appointmentTitle,
    required this.date,
    this.paymentWarning,
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
  MobileScannerController? _controller;

  _CheckInState _state = _CheckInState.idle;
  _CheckInResult? _result;
  String? _errorMsg;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _startScanning() {
    setState(() {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      );
      _state = _CheckInState.scanning;
    });
  }

  void _stopScanning() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dừng camera khi app vào background — tiết kiệm pin, tránh conflict
    if (state == AppLifecycleState.paused) {
      _controller?.stop();
    } else if (state == AppLifecycleState.resumed &&
        _state == _CheckInState.scanning) {
      _controller?.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScanning();
    super.dispose();
  }

  // ── Xử lý khi scan được QR (camera) ─────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state != _CheckInState.scanning) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    
    // Stop scanning first before calling _processQR to avoid duplicate scans
    setState(() {
      _stopScanning();
    });
    
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
        // Soft Warning: đọc cờ cảnh báo từ backend
        // null = bệnh nhân đã đặt cọc online → bình thường
        // non-null = chưa đặt cọc → hiển thị cảnh báo cho bác sĩ
        final String? paymentWarning = data['warning'] as String?;

        if (mounted) {
          setState(() {
            _state = _CheckInState.success;
            _result = _CheckInResult(
              patientName: apt['user']?['name'] ?? 'Bệnh nhân',
              appointmentTitle: apt['title'] ?? '',
              date: apt['date'] ?? '',
              paymentWarning: paymentWarning,
            );
          });

          // Nếu backend báo chưa đặt cọc → hiển dialog thông báo cho bác sĩ
          // (Informational Modal — không block, chỉ yêu cầu xác nhận đã biết)
          if (paymentWarning != null) {
            await _showPaymentWarningDialog(paymentWarning);
          }
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
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() {
      _stopScanning();
      _state = _CheckInState.loading;
    });

    final tempController = _controller ?? MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );

    try {
      final BarcodeCapture? result =
          await tempController.analyzeImage(image.path);
      if (!mounted) {
        if (_controller == null) tempController.dispose();
        return;
      }

      if (result == null || result.barcodes.isEmpty) {
        _setError('Không tìm thấy mã QR trong ảnh', 'NO_QR_FOUND');
        if (_controller == null) tempController.dispose();
        return;
      }

      final raw = result.barcodes.firstOrNull?.rawValue;
      if (raw == null) {
        _setError('Không đọc được nội dung mã QR', 'INVALID_QR');
        if (_controller == null) tempController.dispose();
        return;
      }

      if (_controller == null) tempController.dispose();
      await _processQR(raw);
    } catch (e) {
      if (_controller == null) tempController.dispose();
      if (mounted) _setError('Không thể đọc ảnh', 'IMAGE_ERROR');
    }
  }

  void _setError(String msg, String code) {
    HapticFeedback.heavyImpact();
    setState(() {
      _stopScanning();
      _state = _CheckInState.error;
      _errorMsg = msg;
      _errorCode = code;
    });
  }

  // ── Payment Warning Dialog ───────────────────────────────────────────────
  // Bác sĩ THẤY cảnh báo này sau khi quét QR thành công.
  // Vì tab Scan chỉ dành cho DOCTOR (xem clinic_shell.dart),
  // đây là thông báo để bác sĩ nhắc nhở bệnh nhân cần đặt cọc,
  // không phải "thu tiền" trực tiếp.
  // Pattern: Informational Acknowledgment (không có nút "Bỏ qua").
  Future<void> _showPaymentWarningDialog(String warningMessage) async {
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.circleAlert,
                size: 24,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa đặt cọc online',
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppTheme.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bệnh nhân này chưa thanh toán đặt cọc qua ứng dụng. Vui lòng nhắc bệnh nhân hoàn tất thanh toán hoặc liên hệ bộ phận hành chính.',
              style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.kTextSecondary, height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.badgeDollarSign, size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(
                    'Đặt cọc: 50% phí khám (chưa thanh toán)',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(LucideIcons.checkCircle, size: 16),
              label: Text(
                'Đã hiểu, tiếp tục',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _stopScanning();
      _state = _CheckInState.idle;
      _result = null;
      _errorMsg = null;
      _errorCode = null;
    });
  }

  bool _isAdmin() {
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
    final isCameraActive = _state == _CheckInState.scanning || _state == _CheckInState.loading;
    final isAdmin = _isAdmin();

    if (isCameraActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _buildBody(isAdmin),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: SafeArea(
                      bottom: false,
                      child: _buildHeader(isLight: true, isAdmin: isAdmin),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: isAdmin ? AdminColors.bg : AppTheme.kBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isLight: false, isAdmin: isAdmin),
              Expanded(child: _buildBody(isAdmin)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader({required bool isLight, required bool isAdmin}) {
    final canPop = context.canPop();
    return Container(
      padding: EdgeInsets.fromLTRB(canPop ? 8 : 20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? Colors.white.withValues(alpha: 0.08)
                : (isAdmin ? AdminColors.border : AppTheme.kBorder),
          ),
        ),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                size: 20,
                color: isLight ? Colors.white : (isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary),
              ),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            'Scan Check-in',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isLight ? Colors.white : (isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.kPrimary.withValues(alpha: 0.16),
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
          const Spacer(),
          if (isLight)
            IconButton(
              icon: const Icon(
                LucideIcons.x,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _stopScanning();
                  _state = _CheckInState.idle;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isAdmin) {
    return switch (_state) {
      _CheckInState.scanning || _CheckInState.loading => _buildScanner(),
      _CheckInState.success => _buildSuccess(isAdmin),
      _CheckInState.error   => _buildError(isAdmin),
      _CheckInState.idle    => _buildIdle(isAdmin),
    };
  }

  // ── Camera scanner view ────────────────────────────────────────────────────
  Widget _buildScanner() {
    if (_controller == null) return const SizedBox();
    return Stack(
      children: [
        // Camera feed
        MobileScanner(
          controller: _controller!,
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
                  const CircularProgressIndicator(
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
  Widget _buildSuccess(bool isAdmin) {
    final r = _result!;
    final date = DateTime.tryParse(r.date)?.toLocal();
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';
    final textPrimary = isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary;
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;
    final surface = isAdmin ? AdminColors.surface : AppTheme.kSurface;
    final border = isAdmin ? AdminColors.border : AppTheme.kBorder;

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
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bệnh nhân đã vào danh sách chờ khám',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Patient info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                boxShadow: isAdmin ? null : AppShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(
                    icon: LucideIcons.user,
                    label: 'Bệnh nhân',
                    value: r.patientName,
                    highlight: true,
                    isAdmin: isAdmin,
                  ),
                  const SizedBox(height: 12),
                  _InfoLine(
                    icon: LucideIcons.stethoscope,
                    label: 'Lý do khám',
                    value: r.appointmentTitle,
                    isAdmin: isAdmin,
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoLine(
                      icon: LucideIcons.clock,
                      label: 'Giờ hẹn',
                      value: dateStr,
                      isAdmin: isAdmin,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // BUG-01 FIX: Hiển thị cảnh báo thanh toán nếu chưa đặt cọc
            // (persistent badge — bất kể dialog đã tắt)
            if (r.paymentWarning != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.circleAlert, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chưa đặt cọc online — nhắc bệnh nhân hoàn tất thanh toán',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
  Widget _buildError(bool isAdmin) {
    final isAlreadyDone = _errorCode == 'ALREADY_CHECKED_IN';
    final textPrimary = isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary;
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;

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
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textSecondary,
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

  Widget _buildIdle(bool isAdmin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isAdmin
        ? AdminColors.surface
        : (isDark ? const Color(0xFF182030) : Colors.white);
    final border = isAdmin
        ? AdminColors.border
        : (isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7));
    final textSecondary = isAdmin
        ? AdminColors.textSecondary
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final textPrimary = isAdmin
        ? AdminColors.textPrimary
        : (isDark ? Colors.white : const Color(0xFF0D1520));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Illustration card ──
          Container(
            height: 200,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.qrCode,
                    size: 40,
                    color: AppTheme.kPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Sẵn sàng check-in',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn phương thức quét mã QR để tiếp tục',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Guidelines ──
          Text(
            'Để check-in nhanh chóng',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScannerTip(text: 'Đưa mã QR check-in của bệnh nhân trước camera', color: textSecondary),
                ScannerTip(text: 'Đảm bảo mã QR rõ nét, không bị che khuất hoặc quá tối', color: textSecondary),
                ScannerTip(text: 'Hệ thống tự động xác thực lịch hẹn & đưa vào phòng chờ', color: textSecondary),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Select source ──
          Text(
            'Chọn nguồn quét',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ScannerActionTile(
                  icon: LucideIcons.scanLine,
                  label: 'Quét trực tiếp',
                  onTap: _startScanning,
                  primaryColor: isAdmin ? AdminColors.textPrimary : AppTheme.kPrimary,
                  backgroundColor: isAdmin ? AdminColors.surface : null,
                  borderColor: isAdmin ? AdminColors.border : null,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ScannerActionTile(
                  icon: LucideIcons.image,
                  label: 'Từ thư viện',
                  onTap: _pickAndScanImage,
                  primaryColor: isAdmin ? AdminColors.textPrimary : AppTheme.kPrimary,
                  backgroundColor: isAdmin ? AdminColors.surface : null,
                  borderColor: isAdmin ? AdminColors.border : null,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
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
  final bool isAdmin;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.isAdmin,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary;
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;

    return Row(
      children: [
        Icon(icon, size: 13, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: textSecondary,
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
                        ? textPrimary
                        : textSecondary,
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



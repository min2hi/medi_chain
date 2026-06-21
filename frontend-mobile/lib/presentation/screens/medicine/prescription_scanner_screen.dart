import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/core/utils/prescription_parser.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/prescription_review_screen.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scanner_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

enum _ScanState { idle, processing, error }

/// Màn hình scan đơn thuốc giấy.
/// OCR hoàn toàn on-device (Google ML Kit) — không cần internet.
///
/// Flow: Chọn ảnh → OCR → Parse → chuyển sang [PrescriptionReviewScreen]
class PrescriptionScannerScreen extends StatefulWidget {
  const PrescriptionScannerScreen({super.key});

  @override
  State<PrescriptionScannerScreen> createState() =>
      _PrescriptionScannerScreenState();
}

class _PrescriptionScannerScreenState
    extends State<PrescriptionScannerScreen> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  _ScanState _state = _ScanState.idle;
  File? _previewImage;
  String _errorMsg = '';

  String _normalizeName(String s) {
    var str = s.toLowerCase().trim();
    const vietnamese = 'aáàảãạâấầẩẫậăắằẳẵặeéèẻẽẹêếềểễệiíìỉĩịoóòỏõọôốồổỗộơớờởỡợuúùủũụưứừửữựyýỳỷỹỵdđ';
    const ascii =      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeeiiiiiiioooooooooooooooooouuuuuuuuuuuuyyyyyydd';
    for (int i = 0; i < vietnamese.length; i++) {
      str = str.replaceAll(vietnamese[i], ascii[i]);
    }
    str = str.replaceAll(RegExp(r'[^a-z ]'), '');
    str = str.replaceAll(RegExp(r'\s+'), ' ');
    return str.trim();
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  // ── Pick & OCR ─────────────────────────────────────────────────────────────

  Future<void> _scan(ImageSource source) async {
    // ── Request runtime permission trước khi mở picker ──
    final granted = await _requestPermission(source);
    if (!granted) return;

    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
    );
    if (xFile == null) return;

    setState(() {
      _previewImage = File(xFile.path);
      _state = _ScanState.processing;
      _errorMsg = '';
    });

    HapticFeedback.lightImpact();

    try {
      // OCR — on-device
      final result =
          await _recognizer.processImage(InputImage.fromFile(_previewImage!));
      final rawText = result.text.trim();

      if (rawText.isEmpty) {
        _setError(
            'Không nhận dạng được văn bản.\nThử chụp thẳng góc, đủ ánh sáng.');
        return;
      }

      // Parse
      final medicines = PrescriptionParser.parse(rawText);

      if (!mounted) return;

      if (medicines.isEmpty) {
        _setError(
            'Không tìm thấy thuốc trong đơn.\nKiểm tra lại ảnh hoặc nhập thủ công.');
        return;
      }

      // ── Đối chiếu Họ tên trên đơn thuốc và tài khoản (Name Validation) ──
      final patientName = PrescriptionParser.parsePatientName(rawText);
      if (patientName == null) {
        _setError(
            'Không tìm thấy thông tin "Họ và tên" của bệnh nhân trên đơn thuốc.\n'
            'Để đảm bảo an toàn, vui lòng chụp đơn thuốc rõ ràng, có đầy đủ Họ tên bệnh nhân.');
        return;
      }

      try {
        final profileRes = await getIt<MedicalRepository>().getProfile();
        if (profileRes.success && profileRes.data != null) {
          final userFullName = profileRes.data!.name;
          if (userFullName != null && userFullName.isNotEmpty) {
            final normUser = _normalizeName(userFullName);
            final normPatient = _normalizeName(patientName);
            if (normUser != normPatient) {
              _setError(
                  'Đơn thuốc này không thuộc về bạn!\n'
                  '• Bệnh nhân trên đơn: $patientName\n'
                  '• Tài khoản của bạn: $userFullName\n\n'
                  'Hệ thống không chấp nhận nhập đơn thuốc của người khác để đảm bảo an toàn điều trị.');
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('DEBUG: Error checking name validation: $e');
      }

      HapticFeedback.mediumImpact();

      // Chuyển sang review — truyền BLoC hiện tại, không tạo instance mới
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<MedicineBloc>(),
            child: PrescriptionReviewScreen(
              medicines: medicines,
              rawText: rawText,
            ),
          ),
        ),
      );

      if (mounted) setState(() => _state = _ScanState.idle);
    } catch (e) {
      _setError('Lỗi xử lý ảnh. Vui lòng thử lại.');
    }
  }

  // ── Permission request ────────────────────────────────────────────────────
  /// Xin quyền runtime trước khi mở picker.
  /// Android 13+ dùng READ_MEDIA_IMAGES (Permission.photos)
  /// Android ≤12 dùng READ_EXTERNAL_STORAGE (Permission.storage)
  Future<bool> _requestPermission(ImageSource source) async {
    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      // Thử photos trước (Android 13+), fallback storage (Android ≤12)
      status = await Permission.photos.request();
      if (status.isDenied || status.isRestricted) {
        // Một số emulator/thiết bị cũ không có Permission.photos → thử storage
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) return true;
      }
    }

    if (status.isGranted) return true;

    if ((status.isPermanentlyDenied) && mounted) {
      _showPermissionDialog(source);
    }

    return false;
  }

  void _showPermissionDialog(ImageSource source) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Cần quyền truy cập',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          source == ImageSource.camera
              ? 'Vui lòng cấp quyền Camera trong Cài đặt để chụp ảnh đơn thuốc.'
              : 'Vui lòng cấp quyền Photos trong Cài đặt để chọn ảnh từ thư viện.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Để sau',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.kPrimaryDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Mở Cài đặt',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _setError(String msg) {
    HapticFeedback.heavyImpact();
    setState(() {
      _state = _ScanState.error;
      _errorMsg = msg;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nhập đơn thuốc ngoài hệ thống'),
        backgroundColor:
            isDark ? const Color(0xFF182030) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0D1520),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7),
          ),
        ),
      ),
      body: _state == _ScanState.processing
          ? _ProcessingView()
          : _IdleView(
              previewImage: _previewImage,
              errorMsg: _state == _ScanState.error ? _errorMsg : null,
              onCamera: () => _scan(ImageSource.camera),
              onGallery: () => _scan(ImageSource.gallery),
              isDark: isDark,
            ),
    );
  }
}

// ─── Idle / Error View ────────────────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.previewImage,
    required this.errorMsg,
    required this.onCamera,
    required this.onGallery,
    required this.isDark,
  });

  final File? previewImage;
  final String? errorMsg;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF182030) : Colors.white;
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final hasError = errorMsg != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner for external prescription scan
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13252E) : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF1B4D3E) : const Color(0xFFB7E1CD),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  size: 16,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF137333),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dùng để nhập đơn thuốc giấy từ bệnh viện công hoặc phòng khám bên ngoài nhằm thiết lập nhắc nhở và phân tích an toàn tương tác thuốc bằng AI.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF137333),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Image preview / placeholder ──
          Container(
            height: 200,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444).withOpacity(0.5)
                    : border,
              ),
            ),
            child: previewImage != null
                ? Image.file(previewImage!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.fileText,
                        size: 36,
                        color: isDark
                            ? const Color(0xFF2A3A50)
                            : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Chưa chọn ảnh',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
          ),

          // ── Error message ──
          _buildErrorWidget(context),

          const SizedBox(height: 24),

          // ── Tips ──
          Text(
            'Để nhận dạng chính xác',
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
                ScannerTip(text: 'Đặt đơn thuốc trên nền phẳng, đủ ánh sáng', color: textSecondary),
                ScannerTip(text: 'Chụp thẳng góc, không bị nghiêng hoặc nhòe', color: textSecondary),
                ScannerTip(text: 'Nhận dạng cả đơn in lẫn đơn viết tay', color: textSecondary),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Action buttons ──
          Text(
            'Chọn nguồn ảnh',
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
                  icon: LucideIcons.camera,
                  label: 'Chụp ảnh',
                  onTap: onCamera,
                  primaryColor: AppTheme.kPrimaryDark,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ScannerActionTile(
                  icon: LucideIcons.image,
                  label: 'Thư viện',
                  onTap: onGallery,
                  primaryColor: AppTheme.kPrimaryDark,
                  isPrimary: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Xử lý hoàn toàn trên thiết bị — không cần internet',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: textSecondary.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorMsg == null) return const SizedBox();

    final isMismatch = errorMsg!.contains('Đơn thuốc này không thuộc về bạn');
    
    // Parse patient name and user name if mismatch
    String? patientName;
    String? userFullName;
    
    if (isMismatch) {
      final lines = errorMsg!.split('\n');
      for (final line in lines) {
        if (line.contains('Bệnh nhân trên đơn:')) {
          patientName = line.replaceAll('• Bệnh nhân trên đơn:', '').trim();
        } else if (line.contains('Tài khoản của bạn:')) {
          userFullName = line.replaceAll('• Tài khoản của bạn:', '').trim();
        }
      }
    }

    if (isMismatch && patientName != null && userFullName != null) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF241415) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF5A1E22) : const Color(0xFFFCA5A5),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08EF4444),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.alertTriangle,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Lỗi bảo mật đơn thuốc',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x22EF4444)),
            // Body comparison
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn thuốc được quét không trùng khớp với chủ tài khoản hiện tại. Vui lòng đối chiếu thông tin bên dưới:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Comparison Layout
                  Row(
                    children: [
                      // Patient on prescription
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF3B2527) : const Color(0xFFFCA5A5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.fileText, size: 13, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Trên Đơn Thuốc',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                patientName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(LucideIcons.arrowRightLeft, size: 14, color: Color(0xFFEF4444)),
                      ),
                      
                      // Logged-in User
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF223533) : const Color(0xFF99F6E4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.user, size: 13, color: Color(0xFF0D9488)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tài Khoản Bạn',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userFullName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.shieldAlert, size: 13, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Hệ thống không cho phép nhập chéo đơn thuốc của người khác để đảm bảo an toàn y tế, tránh nguy cơ dùng sai thuốc hoặc tương tác thuốc nguy hại.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            color: isDark ? const Color(0xFFFCA5A5).withOpacity(0.8) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default error display container
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241415) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF5A1E22) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMsg!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Processing View ──────────────────────────────────────────────────────────
class _ProcessingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppTheme.kPrimaryDark,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang nhận dạng đơn thuốc...',
              style: GoogleFonts.inter(fontSize: 14, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}






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
import 'package:permission_handler/permission_handler.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';

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
        title: const Text('Scan đơn thuốc'),
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
          if (hasError) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.alertCircle,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorMsg!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFEF4444),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

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
                _Tip('Đặt đơn thuốc trên nền phẳng, đủ ánh sáng', textSecondary),
                _Tip('Chụp thẳng góc, không bị nghiêng hoặc nhòe', textSecondary),
                _Tip('Nhận dạng cả đơn in lẫn đơn viết tay', textSecondary),
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
                child: _ActionTile(
                  icon: LucideIcons.camera,
                  label: 'Chụp ảnh',
                  onTap: onCamera,
                  isDark: isDark,
                  primary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: LucideIcons.image,
                  label: 'Thư viện',
                  onTap: onGallery,
                  isDark: isDark,
                  primary: false,
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────
class _Tip extends StatelessWidget {
  const _Tip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('· ', style: TextStyle(color: color, fontSize: 13)),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(fontSize: 12, color: color, height: 1.5)),
            ),
          ],
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF182030) : Colors.white;
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: primary
            ? Colors.white.withOpacity(0.15)
            : AppTheme.kPrimaryDark.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: primary ? AppTheme.kPrimaryDark : surface,
            borderRadius: BorderRadius.circular(10),
            border: primary ? null : Border.all(color: border),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: primary ? Colors.white : AppTheme.kPrimaryDark,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primary ? Colors.white : AppTheme.kPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/services/biometric_service.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// EnableBiometricSheet
//
// Xuất hiện một lần duy nhất sau khi user đăng nhập bằng email + password
// và chưa bật Biometric Quick Unlock.
//
// Chỉ hiện khi thiết bị CÓ hỗ trợ biometric (được kiểm tra trong initState).
// Nếu thiết bị không hỗ trợ → dismiss ngay, không hiện UI.
//
// Sau khi user bấm "Bật ngay":
//   1. Lưu email + password vào SecureStorage (Android Keystore / iOS Keychain)
//   2. Ghi flag isBiometricLoginEnabled = true
//   3. Đóng sheet → LoginScreen navigate vào app
// ════════════════════════════════════════════════════════════════════════════
class EnableBiometricSheet extends StatefulWidget {
  final String email;
  final String password;

  const EnableBiometricSheet({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<EnableBiometricSheet> createState() => _EnableBiometricSheetState();
}

class _EnableBiometricSheetState extends State<EnableBiometricSheet>
    with SingleTickerProviderStateMixin {
  final _bio     = BiometricService();
  final _storage = SecureStorageService();

  bool _isLoading   = true;
  bool _isAvailable = false;
  bool _isSaving    = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _checkAvailability();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final available = await _bio.isAvailable();
    final enrolled  = await _bio.isBiometricEnrolled();
    if (!mounted) return;

    if (!available || !enrolled) {
      // Thiết bị không hỗ trợ → đóng sheet ngay, không block user
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isAvailable = true;
      _isLoading   = false;
    });
  }

  Future<void> _enableBiometric() async {
    setState(() => _isSaving = true);
    await _storage.saveQuickLoginCredentials(
      email:    widget.email,
      password: widget.password,
    );
    await _storage.setBiometricLoginEnabled(true);
    if (mounted) Navigator.of(context).pop();
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAvailable) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 28, right: 28, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Animated fingerprint icon
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.kPrimary.withValues(alpha: 0.12),
                    AppTheme.kPrimary.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.kPrimary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.fingerprint,
                size: 44,
                color: AppTheme.kPrimary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Headline
          Text(
            'Đăng nhập nhanh hơn',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            'Bật vân tay hoặc Face ID để đăng nhập\nmà không cần nhập mật khẩu mỗi lần.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Benefits list
          ..._benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(b.$1, size: 14, color: AppTheme.kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    b.$2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              )),

          const SizedBox(height: 28),

          // CTA buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _enableBiometric,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kPrimary,
                disabledBackgroundColor: AppTheme.kPrimary.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: AppTheme.kPrimary.withValues(alpha: 0.4),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fingerprint, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Bật ngay',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: _skip,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF94A3B8),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Text(
              'Để sau',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _benefits = [
    (LucideIcons.zap,     'Đăng nhập trong 1 chạm'),
    (LucideIcons.shield,  'Bảo mật bởi phần cứng thiết bị'),
    (LucideIcons.lock,    'Mật khẩu không bao giờ được đọc'),
  ];
}

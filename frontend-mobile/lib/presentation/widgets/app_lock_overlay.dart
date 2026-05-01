import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medi_chain_mobile/core/services/app_lock_service.dart';
import 'package:medi_chain_mobile/core/services/biometric_service.dart';

// ── HIPAA Lock Overlay ────────────────────────────────────────────────────────
// Che toàn bộ nội dung PHI khi app bị lock do inactivity.
// Đặt BÊN NGOÀI Navigator — hiện trên tất cả màn hình, kể cả Admin Portal.
//
// Pattern: giống màn hình bảo mật của Chase Bank, Apple Health khi background lâu.
class AppLockOverlay extends StatefulWidget {
  final Widget child;
  const AppLockOverlay({super.key, required this.child});

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay>
    with WidgetsBindingObserver {
  final _lockService = AppLockService();
  final _biometric = BiometricService();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Lock ngay khi app vào background (giống banking app)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lockService.lockNow();
    }
  }

  Future<void> _unlock() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    HapticFeedback.mediumImpact();
    final result = await _biometric.authenticate(
      reason: 'Mở khóa MediChain để tiếp tục',
    );

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (result == BiometricResult.success) {
      _lockService.unlock();
    } else if (result == BiometricResult.notAvailable ||
        result == BiometricResult.notEnrolled) {
      // Thiết bị không có Biometric → cho qua (không nên block hoàn toàn)
      _lockService.unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Reset inactivity timer trên MỌI pointer event (tap, scroll, drag)
      onPointerDown: (_) => _lockService.resetTimer(),
      child: ValueListenableBuilder<bool>(
        valueListenable: _lockService.isLocked,
        builder: (context, isLocked, child) {
          return Stack(
            // expand → child (app content) và overlay đều fill toàn bộ parent
            fit: StackFit.expand,
            children: [
              // Nội dung thật của app
              child!,
              // Overlay che TOÀN MÀN HÌNH khi bị lock
              // Positioned.fill đảm bảo overlay luôn 100% width × 100% height
              // kể cả khi content bên trong (Column) không tự mở rộng hết màn hình
              if (isLocked)
                Positioned.fill(
                  child: _buildLockScreen(context),
                ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }

  Widget _buildLockScreen(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0F1E), Color(0xFF0F172A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'MediChain đã khoá',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kh\u00f4ng ho\u1ea1t \u0111\u1ed9ng trong ${_lockService.timeoutMinutes} ph\u00fat.\nX\u00e1c th\u1ef1c \u0111\u1ec3 ti\u1ebfp t\u1ee5c.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Nút mở khoá
                GestureDetector(
                  onTap: _isAuthenticating ? null : _unlock,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: _isAuthenticating
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isAuthenticating)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        else
                          const Icon(Icons.fingerprint,
                              color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _isAuthenticating
                              ? 'Đang xác thực...'
                              : 'Mở khoá',
                          style: TextStyle(
                            color: _isAuthenticating
                                ? const Color(0xFF64748B)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

// ── Kết quả xác thực sinh trắc học ────────────────────────────────────────────
enum BiometricResult {
  success,          // Xác thực thành công
  failed,           // Sai vân tay / khuôn mặt
  notAvailable,     // Thiết bị không có Biometric
  notEnrolled,      // Thiết bị có nhưng chưa đăng ký vân tay
  lockedOut,        // Đã sai quá nhiều lần, bị khóa tạm thời
  permanentlyLockedOut, // Bị khóa vĩnh viễn, cần PIN thiết bị
  cancelled,        // User tự hủy
}

// ── Service wrapper quanh local_auth ──────────────────────────────────────────
// Không lưu bất kỳ dữ liệu sinh trắc học nào.
// Toàn bộ xử lý diễn ra trong Secure Enclave (iOS) / TEE (Android).
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Kiểm tra thiết bị có hỗ trợ Biometric không
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // Kiểm tra user đã đăng ký Biometric (vân tay / FaceID) chưa
  Future<bool> isBiometricEnrolled() async {
    try {
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Thực hiện xác thực — reason hiển thị trên dialog hệ thống
  // Fallback: nếu biometric fail quá nhiều, dùng PIN thiết bị (deviceCredentials)
  Future<BiometricResult> authenticate({
    required String reason,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) return BiometricResult.notAvailable;

      final success = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,   // false = cho phép fallback sang PIN thiết bị
          stickyAuth: true,       // Giữ dialog khi user chuyển app rồi quay lại
          sensitiveTransaction: true, // Hiện thêm cảnh báo "Hành động nhạy cảm"
        ),
      );

      return success ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      return _mapException(e);
    }
  }

  // Map exception code của local_auth → BiometricResult rõ ràng
  BiometricResult _mapException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return BiometricResult.notAvailable;
      case auth_error.notEnrolled:
        return BiometricResult.notEnrolled;
      case auth_error.lockedOut:
        return BiometricResult.lockedOut;
      case auth_error.permanentlyLockedOut:
        return BiometricResult.permanentlyLockedOut;
      case auth_error.passcodeNotSet:
        return BiometricResult.notEnrolled;
      default:
        return BiometricResult.cancelled;
    }
  }
}

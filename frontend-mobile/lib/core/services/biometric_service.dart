import 'package:local_auth/local_auth.dart';

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
        biometricOnly: false,   // false = cho phép fallback sang PIN thiết bị
        persistAcrossBackgrounding: true, // Giữ dialog khi user chuyển app rồi quay lại
        sensitiveTransaction: true, // Hiện thêm cảnh báo "Hành động nhạy cảm"
      );

      return success ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (e) {
      return _mapException(e);
    } catch (e) {
      return BiometricResult.cancelled;
    }
  }

  // Map exception code của local_auth → BiometricResult rõ ràng
  BiometricResult _mapException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return BiometricResult.notAvailable;
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return BiometricResult.notEnrolled;
      case LocalAuthExceptionCode.temporaryLockout:
        return BiometricResult.lockedOut;
      case LocalAuthExceptionCode.biometricLockout:
        return BiometricResult.permanentlyLockedOut;
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
        return BiometricResult.cancelled;
      default:
        return BiometricResult.failed;
    }
  }
}

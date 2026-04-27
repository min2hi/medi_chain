import 'dart:async';

// ── Admin Session TTL Service ──────────────────────────────────────────────────
// Khi Admin leo thang đặc quyền vào Admin Portal, phiên này có TTL riêng.
// Sau 30 phút (tính từ lần xác thực cuối), yêu cầu Biometric lại để gia hạn.
//
// Tham khảo: AWS Console (1h), Google Cloud Console (1h), ngân hàng (30 phút).
// Chọn 30 phút vì đây là app y tế — PHI nhạy cảm hơn cloud infra.
//
// Khác với Layer 2 (lock toàn app): Layer 3 chỉ expire phiên ADMIN.
// User portal vẫn hoạt động bình thường sau khi Admin session hết hạn.
class AdminSessionService {
  static final AdminSessionService _instance = AdminSessionService._internal();
  factory AdminSessionService() => _instance;
  AdminSessionService._internal();

  static const _ttlMinutes = 30;

  DateTime? _sessionStart;
  Timer? _warningTimer;

  // Callback để Admin Portal biết session sắp hết hạn (báo trước 2 phút)
  VoidCallback? onSessionExpiring;

  // Callback khi session đã hết hạn hoàn toàn
  VoidCallback? onSessionExpired;

  // ── Bắt đầu phiên Admin (gọi sau khi Biometric thành công) ───────────────
  void startSession() {
    _sessionStart = DateTime.now();
    _scheduleExpiry();
  }

  // ── Gia hạn session (gọi sau khi Biometric thành công lần 2) ─────────────
  void renewSession() {
    _sessionStart = DateTime.now();
    _warningTimer?.cancel();
    _scheduleExpiry();
  }

  // ── Kết thúc session (gọi khi Admin rời khỏi Admin Portal) ───────────────
  void endSession() {
    _sessionStart = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    onSessionExpiring = null;
    onSessionExpired = null;
  }

  // ── Kiểm tra session còn hợp lệ không ────────────────────────────────────
  bool get isSessionValid {
    if (_sessionStart == null) return false;
    final elapsed = DateTime.now().difference(_sessionStart!);
    return elapsed.inMinutes < _ttlMinutes;
  }

  // ── Thời gian còn lại (tính bằng phút) ───────────────────────────────────
  int get remainingMinutes {
    if (_sessionStart == null) return 0;
    final elapsed = DateTime.now().difference(_sessionStart!);
    final remaining = _ttlMinutes - elapsed.inMinutes;
    return remaining < 0 ? 0 : remaining;
  }

  int get ttlMinutes => _ttlMinutes;

  void _scheduleExpiry() {
    _warningTimer?.cancel();

    // Cảnh báo 2 phút trước khi hết
    final warningDelay = Duration(minutes: _ttlMinutes - 2);
    _warningTimer = Timer(warningDelay, () {
      onSessionExpiring?.call();

      // Hết hạn thực sự sau 2 phút nữa
      Timer(const Duration(minutes: 2), () {
        if (!isSessionValid) {
          onSessionExpired?.call();
        }
      });
    });
  }
}

// Alias để dễ dùng trong widget
typedef VoidCallback = void Function();

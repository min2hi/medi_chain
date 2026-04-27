import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── HIPAA Auto-Lock Service ────────────────────────────────────────────────────
// Theo HIPAA § 164.312(a)(2)(iii): terminate session sau N phút không tương tác.
// Default: 10 phút (cân bằng UX vs Security — HIPAA cho phép tối đa 15 phút).
//
// Kiến trúc: Singleton — toàn bộ app dùng chung 1 instance.
// main.dart khởi tạo 1 lần, Listener bên ngoài gọi resetTimer() mỗi khi user chạm.
class AppLockService {
  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  static const _prefKey = 'auto_lock_minutes';
  static const _defaultMinutes = 10;

  Timer? _timer;
  int _timeoutMinutes = _defaultMinutes;

  // ValueNotifier để widget tree reactive không cần BLoC
  final ValueNotifier<bool> isLocked = ValueNotifier(false);

  // ── Khởi tạo: đọc setting từ SharedPreferences ───────────────────────────
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _timeoutMinutes = prefs.getInt(_prefKey) ?? _defaultMinutes;
  }

  // ── Lưu setting timeout mới ───────────────────────────────────────────────
  Future<void> setTimeoutMinutes(int minutes) async {
    _timeoutMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, minutes);
    resetTimer(); // áp dụng timeout mới ngay
  }

  int get timeoutMinutes => _timeoutMinutes;

  // ── Bắt đầu theo dõi — gọi sau khi user đăng nhập thành công ─────────────
  void startMonitoring() {
    isLocked.value = false;
    resetTimer();
  }

  // ── Dừng theo dõi — gọi khi user đăng xuất ───────────────────────────────
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    isLocked.value = false;
  }

  // ── Reset timer — gọi mỗi khi có tương tác ───────────────────────────────
  void resetTimer() {
    _timer?.cancel();
    if (isLocked.value) return; // đang bị lock → không reset
    _timer = Timer(
      Duration(minutes: _timeoutMinutes),
      _onTimeout,
    );
  }

  // ── Mở khóa sau khi Biometric thành công ─────────────────────────────────
  void unlock() {
    isLocked.value = false;
    resetTimer();
  }

  // ── Khóa thủ công (dùng cho testing hoặc khi app vào background) ─────────
  void lockNow() => _onTimeout();

  void _onTimeout() {
    _timer?.cancel();
    isLocked.value = true;
  }
}

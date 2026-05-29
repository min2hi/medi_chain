import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

// ── SecureStorageService ───────────────────────────────────────────────────────
// Tất cả data được bảo vệ bởi:
//   Android → Android Keystore (hardware-backed TEE)
//   iOS     → Keychain (Secure Enclave)
// Không có giá trị nào được persist trong SharedPreferences plain-text.
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Auth token ────────────────────────────────────────────────────────────
  Future<void> saveToken(String token) async =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  Future<void> deleteToken() => _storage.delete(key: AppConstants.tokenKey);

  // ── User profile (JSON) ───────────────────────────────────────────────────
  Future<void> saveUser(String userJson) async =>
      _storage.write(key: AppConstants.userKey, value: userJson);

  Future<String?> getUser() => _storage.read(key: AppConstants.userKey);

  // ── Quick-Unlock credentials (Biometric Login) ────────────────────────────
  // Lưu email + password để silent re-login sau khi Biometric xác thực thành công.
  // Được bảo vệ bởi Keystore/Keychain — không thể đọc nếu không qua hardware auth.
  static const _emailKey    = 'ql_email';
  static const _passwordKey = 'ql_password';
  static const _bioEnabledKey = 'ql_biometric_enabled';

  Future<void> saveQuickLoginCredentials({
    required String email,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(key: _emailKey,    value: email),
      _storage.write(key: _passwordKey, value: password),
    ]);
  }

  Future<({String email, String password})?> getQuickLoginCredentials() async {
    final results = await Future.wait([
      _storage.read(key: _emailKey),
      _storage.read(key: _passwordKey),
    ]);
    final email    = results[0];
    final password = results[1];
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  Future<void> clearQuickLoginCredentials() async {
    await Future.wait([
      _storage.delete(key: _emailKey),
      _storage.delete(key: _passwordKey),
      _storage.delete(key: _bioEnabledKey),
    ]);
  }

  // ── Biometric login preference ────────────────────────────────────────────
  Future<void> setBiometricLoginEnabled(bool enabled) async =>
      _storage.write(key: _bioEnabledKey, value: enabled ? '1' : '0');

  Future<bool> isBiometricLoginEnabled() async {
    final val = await _storage.read(key: _bioEnabledKey);
    return val == '1';
  }

  // ── Saved email (pre-fill form nếu user chọn "dùng password") ────────────
  Future<String?> getSavedEmail() => _storage.read(key: _emailKey);

  // ── Admin viewing-as ──────────────────────────────────────────────────────
  Future<void> setViewingAs(String userId) async =>
      _storage.write(key: AppConstants.viewingAsKey, value: userId);

  Future<String?> getViewingAs() => _storage.read(key: AppConstants.viewingAsKey);

  // ── Full clear (logout) ───────────────────────────────────────────────────
  // Xóa token + user nhưng GIỮ quick-login credentials & biometric preference
  // để user có thể dùng biometric để đăng nhập lại.
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: AppConstants.tokenKey),
      _storage.delete(key: AppConstants.userKey),
    ]);
  }

  // Xóa TOÀN BỘ — dùng khi user tắt biometric hoặc đổi account.
  Future<void> clearAll() async => _storage.deleteAll();
}

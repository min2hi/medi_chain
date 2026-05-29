import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/services/biometric_service.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';
import 'package:medi_chain_mobile/data/models/auth_models.dart';
import 'package:medi_chain_mobile/data/repositories/auth_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class AuthEvent {}

/// Khởi động app — kiểm tra token còn hay không.
class AuthCheckRequested extends AuthEvent {}

/// Đăng nhập bằng email + password (lần đầu hoặc fallback).
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

/// Đăng nhập nhanh bằng Biometric (vân tay / Face ID).
/// Flow: Hardware biometric → lấy creds từ SecureStorage → silent /auth/login.
class BiometricLoginRequested extends AuthEvent {}

/// Đăng xuất — GIỮ lại credentials để user dùng biometric đăng nhập lại.
class LogoutRequested extends AuthEvent {}

/// Đăng xuất hoàn toàn + xóa credentials (đổi tài khoản / tắt biometric).
class FullLogoutRequested extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  RegisterRequested(this.email, this.password, this.name);
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  ForgotPasswordRequested(this.email);
}

class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;
  ResetPasswordRequested(this.token, this.newPassword);
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  /// true nếu đây là lần đầu user đăng nhập bằng password và chưa bật biometric.
  /// LoginScreen dùng flag này để quyết định có hiện EnableBiometricSheet không.
  final bool isFirstLogin;
  Authenticated(this.user, {this.isFirstLogin = false});
}

class RegisterSuccess extends AuthState {
  final String message;
  RegisterSuccess(this.message);
}

class ForgotPasswordSuccess extends AuthState {
  final String message;
  ForgotPasswordSuccess(this.message);
}

class ResetPasswordSuccess extends AuthState {
  final String message;
  ResetPasswordSuccess(this.message);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Biometric hardware không pass (user cancel / fail / thiết bị không hỗ trợ).
/// Signal để LoginScreen switch sang form password — không phải lỗi server.
class BiometricAuthFailed extends AuthState {
  /// Email đã lưu — dùng để pre-fill form password khi fallback.
  final String? savedEmail;
  BiometricAuthFailed({this.savedEmail});
}

// ── Bloc ──────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storage;
  final BiometricService _biometric;

  // true  → Authenticated từ AuthCheckRequested (restore token, cold launch)
  // false → Authenticated từ LoginRequested / BiometricLoginRequested
  bool _isColdLaunch = false;
  bool get isColdLaunch => _isColdLaunch;

  AuthBloc(this._repository, this._storage, this._biometric)
      : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<BiometricLoginRequested>(_onBiometricLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<FullLogoutRequested>(_onFullLogoutRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  // ── AuthCheck — restore session từ token đã lưu ───────────────────────────
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token    = await _storage.getToken();
      final userJson = await _storage.getUser();
      if (token != null && userJson != null) {
        _isColdLaunch = true;
        final user = UserModel.fromJson(jsonDecode(userJson));
        emit(Authenticated(user));
      } else {
        _isColdLaunch = false;
        emit(Unauthenticated());
      }
    } catch (_) {
      _isColdLaunch = false;
      emit(Unauthenticated());
    }
  }

  // ── Email + Password login ─────────────────────────────────────────────────
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final response = await _repository.login(event.email, event.password);
    if (response.success && response.data != null) {
      final data = response.data!;
      
      // Kiểm tra đổi tài khoản: Nếu email đăng nhập mới khác email đã lưu Quick Login,
      // xóa credentials cũ để tránh đăng nhập nhầm tài khoản của người khác.
      final savedEmail = await _storage.getSavedEmail();
      if (savedEmail != null && savedEmail.trim().toLowerCase() != event.email.trim().toLowerCase()) {
        await _storage.clearQuickLoginCredentials();
      }

      await _storage.saveToken(data.token);
      await _storage.saveUser(jsonEncode(data.user.toJson()));
      _isColdLaunch = false;

      // Kiểm tra xem user đã bật biometric chưa để LoginScreen quyết định
      // có hiện EnableBiometricSheet không.
      final biometricEnabled = await _storage.isBiometricLoginEnabled();
      emit(Authenticated(data.user, isFirstLogin: !biometricEnabled));
    } else {
      emit(AuthError(response.message ?? 'Đăng nhập thất bại'));
      emit(Unauthenticated());
    }
  }

  // ── Biometric login — hardware auth → silent re-login ─────────────────────
  Future<void> _onBiometricLoginRequested(
    BiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Bước 1: Kiểm tra credentials đã lưu
    final creds = await _storage.getQuickLoginCredentials();
    if (creds == null) {
      emit(BiometricAuthFailed());
      return;
    }

    // Bước 2: Xác thực phần cứng (Fingerprint / Face ID / PIN thiết bị)
    final result = await _biometric.authenticate(
      reason: 'Xác thực để đăng nhập MediChain',
    );

    switch (result) {
      case BiometricResult.success:
        // Bước 3: Silent re-login với credentials đã lưu
        final response = await _repository.login(creds.email, creds.password);
        if (response.success && response.data != null) {
          final data = response.data!;
          await _storage.saveToken(data.token);
          await _storage.saveUser(jsonEncode(data.user.toJson()));
          _isColdLaunch = false;
          emit(Authenticated(data.user));
        } else {
          // Credentials hết hạn / sai → xóa & yêu cầu đăng nhập lại bằng password
          await _storage.clearQuickLoginCredentials();
          emit(AuthError('Phiên đăng nhập nhanh đã hết hạn. Vui lòng đăng nhập lại.'));
          emit(Unauthenticated());
        }

      case BiometricResult.notAvailable:
      case BiometricResult.notEnrolled:
        // Thiết bị không hỗ trợ → fallback về form password, pre-fill email
        emit(BiometricAuthFailed(savedEmail: creds.email));

      case BiometricResult.cancelled:
        // User tự hủy → fallback về form nhưng giữ hiển thị bình thường
        emit(BiometricAuthFailed(savedEmail: creds.email));

      case BiometricResult.failed:
      case BiometricResult.lockedOut:
      case BiometricResult.permanentlyLockedOut:
        // Sai quá nhiều → fallback về form password
        emit(BiometricAuthFailed(savedEmail: creds.email));
    }
  }

  // ── Logout — GIỮ credentials cho lần đăng nhập tiếp theo ─────────────────
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // clearSession() chỉ xóa token + user JSON, GIỮ quick-login credentials
    await _storage.clearSession();
    emit(Unauthenticated());
  }

  // ── Full logout — xóa toàn bộ (đổi account / tắt biometric) ──────────────
  Future<void> _onFullLogoutRequested(
    FullLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _storage.clearAll();
    emit(Unauthenticated());
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final response = await _repository.register(
      event.email,
      event.password,
      event.name,
    );
    if (response.success) {
      emit(RegisterSuccess(response.message ?? 'Đăng ký thành công'));
    } else {
      emit(AuthError(response.message ?? 'Đăng ký thất bại'));
      emit(Unauthenticated());
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final response = await _repository.forgotPassword(event.email);
    if (response.success) {
      emit(ForgotPasswordSuccess(
        response.message ?? 'Email đặt lại mật khẩu đã được gửi.',
      ));
    } else {
      emit(AuthError(response.message ?? 'Không thể gửi email.'));
      emit(Unauthenticated());
    }
  }

  // ── Reset password ────────────────────────────────────────────────────────
  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final response =
        await _repository.resetPassword(event.token, event.newPassword);
    if (response.success) {
      emit(ResetPasswordSuccess(
        response.message ?? 'Mật khẩu đã được đặt lại thành công.',
      ));
    } else {
      emit(AuthError(response.message ?? 'Không thể đặt lại mật khẩu.'));
    }
  }
}

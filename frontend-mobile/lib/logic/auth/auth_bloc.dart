import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';
import 'package:medi_chain_mobile/data/models/auth_models.dart';
import 'package:medi_chain_mobile/data/repositories/auth_repository.dart';

// ── Events ────────────────────────────────────────────────
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class LogoutRequested extends AuthEvent {}

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

// ── States ────────────────────────────────────────────────
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  Authenticated(this.user);
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

// ── Bloc ──────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storage;

  AuthBloc(this._repository, this._storage) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _storage.getToken();
      final userJson = await _storage.getUser();
      if (token != null && userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final response = await _repository.login(event.email, event.password);
    if (response.success && response.data != null) {
      final data = response.data!;
      await _storage.saveToken(data.token);
      await _storage.saveUser(jsonEncode(data.user.toJson()));
      emit(Authenticated(data.user));
    } else {
      emit(AuthError(response.message ?? 'Đăng nhập thất bại'));
      emit(Unauthenticated());
    }
  }

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

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _storage.clearAll();
    emit(Unauthenticated());
  }

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

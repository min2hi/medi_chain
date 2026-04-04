import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Lỗi kết nối hoặc thông tin không chính xác',
      );
    }
  }

  Future<RegisterResponse> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      return RegisterResponse.fromJson(response.data);
    } catch (e) {
      return RegisterResponse(success: false, message: 'Lỗi đăng ký tài khoản');
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return ForgotPasswordResponse.fromJson(response.data);
    } catch (e) {
      return ForgotPasswordResponse(
        success: false,
        message: 'Không thể gửi email. Vui lòng thử lại.',
      );
    }
  }

  Future<ResetPasswordResponse> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.post(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
      return ResetPasswordResponse.fromJson(response.data);
    } catch (e) {
      return ResetPasswordResponse(
        success: false,
        message: 'Không thể đặt lại mật khẩu. Link có thể đã hết hạn.',
      );
    }
  }
}

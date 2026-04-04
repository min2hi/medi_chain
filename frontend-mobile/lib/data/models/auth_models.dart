import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? role;

  UserModel({required this.id, this.email, this.name, this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class LoginData {
  final UserModel user;
  final String token;

  LoginData({required this.user, required this.token});

  factory LoginData.fromJson(Map<String, dynamic> json) =>
      _$LoginDataFromJson(json);
  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final bool success;
  final String? message;
  final LoginData? data;

  LoginResponse({required this.success, this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class RegisterResponse {
  final bool success;
  final String? message;
  final UserModel? data;

  RegisterResponse({required this.success, this.message, this.data});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}

/// Generic simple response cho forgot/reset password (không cần code-gen)
class _SimpleResponse {
  final bool success;
  final String? message;
  _SimpleResponse({required this.success, this.message});
  factory _SimpleResponse.fromJson(Map<String, dynamic> json) =>
      _SimpleResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String?,
      );
}

class ForgotPasswordResponse extends _SimpleResponse {
  ForgotPasswordResponse({required super.success, super.message});
  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    final base = _SimpleResponse.fromJson(json);
    return ForgotPasswordResponse(success: base.success, message: base.message);
  }
}

class ResetPasswordResponse extends _SimpleResponse {
  ResetPasswordResponse({required super.success, super.message});
  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    final base = _SimpleResponse.fromJson(json);
    return ResetPasswordResponse(success: base.success, message: base.message);
  }
}

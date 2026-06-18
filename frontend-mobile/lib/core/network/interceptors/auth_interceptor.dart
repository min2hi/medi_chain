import 'package:dio/dio.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    final viewAsId = await _storage.getViewingAs();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (viewAsId != null) {
      options.headers['X-Viewing-As'] = viewAsId;
    }

    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Đăng xuất hoàn toàn qua AuthBloc để tránh vòng lặp chuyển hướng vô hạn (ANR)
      getIt<AuthBloc>().add(FullLogoutRequested());
    }
    return handler.next(err);
  }
}

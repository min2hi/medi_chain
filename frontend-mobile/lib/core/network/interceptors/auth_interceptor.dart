import 'package:dio/dio.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';
import 'package:medi_chain_mobile/presentation/routes/app_router.dart';

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
      // Clear session and redirect to login immediately
      _storage.clearAll();
      AppRouter.router.go('/login');
    }
    return handler.next(err);
  }
}

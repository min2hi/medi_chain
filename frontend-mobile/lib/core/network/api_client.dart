import 'package:dio/dio.dart';
import 'package:medi_chain_mobile/core/constants/app_constants.dart';
import 'package:medi_chain_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(SecureStorageService storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(storage),
      LogInterceptor(requestBody: true, responseBody: true), // For debugging
    ]);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

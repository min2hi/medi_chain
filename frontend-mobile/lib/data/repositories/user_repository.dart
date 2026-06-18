import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<DashboardResponse> getDashboard() async {
    try {
      final response = await _apiClient.get('/user/dashboard');
      return DashboardResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('DEBUG: getDashboard failed with error: $e');
      if (e is DioException) {
        debugPrint('DEBUG: DioException type: ${e.type}');
        debugPrint('DEBUG: DioException message: ${e.message}');
        debugPrint('DEBUG: DioException response data: ${e.response?.data}');
        debugPrint('DEBUG: DioException response status: ${e.response?.statusCode}');
      }
      return DashboardResponse(
        success: false,
        message: 'Không thể tải dữ liệu dashboard',
      );
    }
  }
}

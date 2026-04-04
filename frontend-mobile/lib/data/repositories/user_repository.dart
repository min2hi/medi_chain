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
      return DashboardResponse(
        success: false,
        message: 'Không thể tải dữ liệu dashboard',
      );
    }
  }
}

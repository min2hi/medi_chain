import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';

/// Repository cho Bóng Sức Khỏe — tất cả calls tới /health-twin/*
class HealthTwinRepository {
  final ApiClient _apiClient;
  HealthTwinRepository(this._apiClient);

  /// Lấy trạng thái tổng quan: isStable, điểm, anomalies, patterns
  Future<HealthTwinStatusResponse> getStatus() async {
    try {
      final response = await _apiClient.get('/health-twin/status');
      return HealthTwinStatusResponse.fromJson(response.data);
    } catch (e) {
      return const HealthTwinStatusResponse(
        success: false,
        message: 'Không thể tải dữ liệu Bóng Sức Khỏe',
      );
    }
  }

  /// Lấy timeline grouped by month (6 tháng gần nhất)
  Future<HealthTimelineResponse> getTimeline() async {
    try {
      final response = await _apiClient.get('/health-twin/timeline');
      return HealthTimelineResponse.fromJson(response.data);
    } catch (e) {
      return const HealthTimelineResponse(
        success: false,
        message: 'Không thể tải timeline',
      );
    }
  }

  /// Submit weekly check-in (optional, không bắt buộc)
  Future<bool> submitCheckin(String feeling) async {
    try {
      final response = await _apiClient.post(
        '/health-twin/checkin',
        data: {'feeling': feeling},
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Dismiss một anomaly (user đã xem)
  Future<bool> dismissAnomaly(String anomalyId) async {
    try {
      final response = await _apiClient.post(
        '/health-twin/anomalies/$anomalyId/dismiss',
        data: {},
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

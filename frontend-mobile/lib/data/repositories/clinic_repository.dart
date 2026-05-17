import 'package:dio/dio.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/api_response.dart';

class ClinicRepository {
  final ApiClient _apiClient;

  ClinicRepository(this._apiClient);

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message']?.toString() ?? 'Lỗi kết nối';
    return 'Lỗi kết nối (${e.response?.statusCode})';
  }

  // ─── Lịch hẹn (Appointments) ────────────────────────────────────────────────
  Future<ApiResponse<List<Map<String, dynamic>>>> getAppointments({String filter = 'ALL'}) async {
    try {
      final response = await _apiClient.get('/admin/appointments', queryParameters: {'status': filter});
      final data = List<Map<String, dynamic>>.from(response.data['data']);
      return ApiResponse.success(data);
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<void>> updateAppointmentStatus(String id, String status) async {
    try {
      await _apiClient.patch('/admin/appointments/$id/status', data: {'status': status});
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ─── Bệnh nhân (Patients) ───────────────────────────────────────────────────
  Future<ApiResponse<List<Map<String, dynamic>>>> getPatients() async {
    try {
      final response = await _apiClient.get('/admin/patients');
      return ApiResponse.success(List<Map<String, dynamic>>.from(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ─── Tài chính (Payments) ───────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> getPaymentOverview() async {
    try {
      final response = await _apiClient.get('/admin/payments/overview');
      return ApiResponse.success(Map<String, dynamic>.from(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getPaymentTransactions() async {
    try {
      final response = await _apiClient.get('/admin/payments/transactions');
      return ApiResponse.success(List<Map<String, dynamic>>.from(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<void>> updateConsultationFee(int fee) async {
    try {
      await _apiClient.patch('/admin/payments/fee', data: {'fee': fee});
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

import 'package:dio/dio.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/payment_models.dart';

class PaymentRepository {
  final ApiClient _api;
  PaymentRepository(this._api);

  // Helper: extract backend error message từ DioException response body
  Exception _handleError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'] as String?;
        if (msg != null && msg.isNotEmpty) return Exception(msg);
      }
    }
    return Exception(fallback);
  }

  // Tạo đơn thanh toán cho appointment
  Future<CreateOrderResponse> createOrder(String appointmentId) async {
    try {
      final res = await _api.post(
        '/payment/create-order',
        data: {'appointmentId': appointmentId},
      );
      final body = CreateOrderApiResponse.fromJson(
        res.data as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw Exception(body.message ?? 'Không thể tạo đơn thanh toán');
      }
      return body.data!;
    } catch (e) {
      if (e is Exception && e is! DioException) rethrow;
      throw _handleError(e, 'Không thể tạo đơn thanh toán');
    }
  }

  // Lấy phí khám hiện tại từ server
  Future<int> getConsultationFee() async {
    try {
      final res = await _api.get('/payment/settings/fee');
      final body = ConsultationFeeResponse.fromJson(
        res.data as Map<String, dynamic>,
      );
      return body.data?.consultationFee ?? 200000;
    } catch (e) {
      if (e is DioException) throw _handleError(e, 'Lỗi tải phí khám');
      rethrow;
    }
  }

  // Lịch sử thanh toán
  Future<List<PaymentTransactionModel>> getHistory() async {
    try {
      final res = await _api.get('/payment/history');
      final body = PaymentHistoryResponse.fromJson(
        res.data as Map<String, dynamic>,
      );
      return body.data ?? [];
    } catch (e) {
      if (e is DioException) throw _handleError(e, 'Lỗi tải lịch sử thanh toán');
      rethrow;
    }
  }

  // Kiểm tra trạng thái 1 đơn (polling sau khi quay về từ PayOS)
  Future<String> checkOrderStatus(String orderCode) async {
    try {
      final res = await _api.get('/payment/status/$orderCode');
      final data = (res.data as Map<String, dynamic>);
      final txData = data['data'] as Map<String, dynamic>? ?? {};
      return txData['status'] as String? ?? 'FAILED';
    } catch (e) {
      if (e is DioException) throw _handleError(e, 'Lỗi kiểm tra trạng thái');
      rethrow;
    }
  }

  // Admin: cập nhật phí khám
  Future<void> updateConsultationFee(int fee) async {
    try {
      await _api.put('/payment/settings/fee', data: {'fee': fee});
    } catch (e) {
      throw _handleError(e, 'Lỗi cập nhật phí khám');
    }
  }
}

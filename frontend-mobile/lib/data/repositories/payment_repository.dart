import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/payment_models.dart';

class PaymentRepository {
  final ApiClient _api;
  PaymentRepository(this._api);

  // Tạo đơn thanh toán cho appointment
  Future<CreateOrderResponse> createOrder(String appointmentId) async {
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
  }

  // Lấy phí khám hiện tại từ server
  Future<int> getConsultationFee() async {
    final res = await _api.get('/payment/settings/fee');
    final body = ConsultationFeeResponse.fromJson(
      res.data as Map<String, dynamic>,
    );
    return body.data?.consultationFee ?? 200000;
  }

  // Lịch sử thanh toán
  Future<List<PaymentTransactionModel>> getHistory() async {
    final res = await _api.get('/payment/history');
    final body = PaymentHistoryResponse.fromJson(
      res.data as Map<String, dynamic>,
    );
    return body.data ?? [];
  }

  // Kiểm tra trạng thái 1 đơn (polling sau khi quay về từ PayOS)
  Future<String> checkOrderStatus(String orderCode) async {
    final res = await _api.get('/payment/status/$orderCode');
    final data = (res.data as Map<String, dynamic>);
    final txData = data['data'] as Map<String, dynamic>? ?? {};
    return txData['status'] as String? ?? 'FAILED';
  }

  // Admin: cập nhật phí khám
  Future<void> updateConsultationFee(int fee) async {
    await _api.put('/payment/settings/fee', data: {'fee': fee});
  }
}

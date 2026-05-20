import 'package:json_annotation/json_annotation.dart';

part 'payment_models.g.dart';

// ─── PaymentTransaction ───────────────────────────────────────────────────────

@JsonSerializable()
class PaymentTransactionModel {
  final String id;
  final String orderCode;
  final int amount;
  final String status; // UNPAID | PENDING | PAID | FAILED | REFUNDED
  final String createdAt;
  final PaymentAppointmentRef? appointment;

  const PaymentTransactionModel({
    required this.id,
    required this.orderCode,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.appointment,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentTransactionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTransactionModelToJson(this);
}

@JsonSerializable()
class PaymentAppointmentRef {
  final String id;
  final String title;
  final String date;

  const PaymentAppointmentRef({
    required this.id,
    required this.title,
    required this.date,
  });

  factory PaymentAppointmentRef.fromJson(Map<String, dynamic> json) =>
      _$PaymentAppointmentRefFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentAppointmentRefToJson(this);
}

// ─── Create Order Response ────────────────────────────────────────────────────

@JsonSerializable()
class CreateOrderResponse {
  final String checkoutUrl;
  final String orderCode;
  final String paymentLinkId;
  final int amount; // Giá đã xác nhận từ backend — dùng cái này để hiển thị và khớp với PayOS

  const CreateOrderResponse({
    required this.checkoutUrl,
    required this.orderCode,
    required this.paymentLinkId,
    required this.amount,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderResponseFromJson(json);
}

// ─── API Wrappers ─────────────────────────────────────────────────────────────

@JsonSerializable()
class CreateOrderApiResponse {
  final bool success;
  final String? message;
  final CreateOrderResponse? data;

  const CreateOrderApiResponse({required this.success, this.message, this.data});

  factory CreateOrderApiResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderApiResponseFromJson(json);
}

@JsonSerializable()
class PaymentHistoryResponse {
  final bool success;
  final String? message;
  final List<PaymentTransactionModel>? data;

  const PaymentHistoryResponse({required this.success, this.message, this.data});

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryResponseFromJson(json);
}

@JsonSerializable()
class ConsultationFeeResponse {
  final bool success;
  final ConsultationFeeData? data;

  const ConsultationFeeResponse({required this.success, this.data});

  factory ConsultationFeeResponse.fromJson(Map<String, dynamic> json) =>
      _$ConsultationFeeResponseFromJson(json);
}

@JsonSerializable()
class ConsultationFeeData {
  final int consultationFee;

  const ConsultationFeeData({required this.consultationFee});

  factory ConsultationFeeData.fromJson(Map<String, dynamic> json) =>
      _$ConsultationFeeDataFromJson(json);
}

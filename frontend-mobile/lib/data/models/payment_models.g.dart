// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentTransactionModel _$PaymentTransactionModelFromJson(
        Map<String, dynamic> json) =>
    PaymentTransactionModel(
      id: json['id'] as String,
      orderCode: json['orderCode'] as String,
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      appointment: json['appointment'] == null
          ? null
          : PaymentAppointmentRef.fromJson(
              json['appointment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PaymentTransactionModelToJson(
        PaymentTransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderCode': instance.orderCode,
      'amount': instance.amount,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'appointment': instance.appointment,
    };

PaymentAppointmentRef _$PaymentAppointmentRefFromJson(
        Map<String, dynamic> json) =>
    PaymentAppointmentRef(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
    );

Map<String, dynamic> _$PaymentAppointmentRefToJson(
        PaymentAppointmentRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'date': instance.date,
    };

CreateOrderResponse _$CreateOrderResponseFromJson(Map<String, dynamic> json) =>
    CreateOrderResponse(
      checkoutUrl: json['checkoutUrl'] as String,
      orderCode: json['orderCode'] as String,
      paymentLinkId: json['paymentLinkId'] as String,
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$CreateOrderResponseToJson(
        CreateOrderResponse instance) =>
    <String, dynamic>{
      'checkoutUrl': instance.checkoutUrl,
      'orderCode': instance.orderCode,
      'paymentLinkId': instance.paymentLinkId,
      'amount': instance.amount,
    };

CreateOrderApiResponse _$CreateOrderApiResponseFromJson(
        Map<String, dynamic> json) =>
    CreateOrderApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : CreateOrderResponse.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateOrderApiResponseToJson(
        CreateOrderApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

PaymentHistoryResponse _$PaymentHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    PaymentHistoryResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) =>
              PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaymentHistoryResponseToJson(
        PaymentHistoryResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

ConsultationFeeResponse _$ConsultationFeeResponseFromJson(
        Map<String, dynamic> json) =>
    ConsultationFeeResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : ConsultationFeeData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConsultationFeeResponseToJson(
        ConsultationFeeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

ConsultationFeeData _$ConsultationFeeDataFromJson(Map<String, dynamic> json) =>
    ConsultationFeeData(
      consultationFee: (json['consultationFee'] as num).toInt(),
    );

Map<String, dynamic> _$ConsultationFeeDataToJson(
        ConsultationFeeData instance) =>
    <String, dynamic>{
      'consultationFee': instance.consultationFee,
    };

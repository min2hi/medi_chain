// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicalRecordModel _$MedicalRecordModelFromJson(Map<String, dynamic> json) =>
    MedicalRecordModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatment: json['treatment'] as String?,
      hospital: json['hospital'] as String?,
      date: json['date'] as String,
    );

Map<String, dynamic> _$MedicalRecordModelToJson(MedicalRecordModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'diagnosis': instance.diagnosis,
      'treatment': instance.treatment,
      'hospital': instance.hospital,
      'date': instance.date,
    };

MedicalRecordsResponse _$MedicalRecordsResponseFromJson(
        Map<String, dynamic> json) =>
    MedicalRecordsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MedicalRecordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MedicalRecordsResponseToJson(
        MedicalRecordsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

MedicineModel _$MedicineModelFromJson(Map<String, dynamic> json) =>
    MedicineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      instruction: json['instruction'] as String?,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
    );

Map<String, dynamic> _$MedicineModelToJson(MedicineModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'dosage': instance.dosage,
      'frequency': instance.frequency,
      'instruction': instance.instruction,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

MedicinesResponse _$MedicinesResponseFromJson(Map<String, dynamic> json) =>
    MedicinesResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MedicineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MedicinesResponseToJson(MedicinesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
      bloodType: json['bloodType'] as String?,
      allergies: json['allergies'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      birthday: json['birthday'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'bloodType': instance.bloodType,
      'allergies': instance.allergies,
      'weight': instance.weight,
      'height': instance.height,
      'gender': instance.gender,
      'birthday': instance.birthday,
      'address': instance.address,
      'phone': instance.phone,
    };

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    ProfileResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : ProfileModel.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfileResponseToJson(ProfileResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AppointmentModel _$AppointmentModelFromJson(Map<String, dynamic> json) =>
    AppointmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$AppointmentModelToJson(AppointmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'date': instance.date,
      'status': instance.status,
      'notes': instance.notes,
    };

AppointmentsResponse _$AppointmentsResponseFromJson(
        Map<String, dynamic> json) =>
    AppointmentsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AppointmentsResponseToJson(
        AppointmentsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

HealthMetricModel _$HealthMetricModelFromJson(Map<String, dynamic> json) =>
    HealthMetricModel(
      id: json['id'] as String?,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      date: json['date'] as String,
    );

Map<String, dynamic> _$HealthMetricModelToJson(HealthMetricModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'value': instance.value,
      'unit': instance.unit,
      'date': instance.date,
    };

MetricsResponse _$MetricsResponseFromJson(Map<String, dynamic> json) =>
    MetricsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => HealthMetricModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MetricsResponseToJson(MetricsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

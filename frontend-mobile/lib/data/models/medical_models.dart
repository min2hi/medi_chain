import 'package:json_annotation/json_annotation.dart';

part 'medical_models.g.dart';

@JsonSerializable()
class MedicalRecordModel {
  final String id;
  final String title;
  final String? content;
  final String? diagnosis;
  final String? treatment;
  final String? hospital;
  final String date;

  MedicalRecordModel({
    required this.id,
    required this.title,
    this.content,
    this.diagnosis,
    this.treatment,
    this.hospital,
    required this.date,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) =>
      _$MedicalRecordModelFromJson(json);
  Map<String, dynamic> toJson() => _$MedicalRecordModelToJson(this);
}

@JsonSerializable()
class MedicalRecordsResponse {
  final bool success;
  final String? message;
  final List<MedicalRecordModel>? data;

  MedicalRecordsResponse({required this.success, this.message, this.data});

  factory MedicalRecordsResponse.fromJson(Map<String, dynamic> json) =>
      _$MedicalRecordsResponseFromJson(json);
}

@JsonSerializable()
class MedicineModel {
  final String id;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? instruction;
  final String startDate;
  final String? endDate;

  MedicineModel({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.instruction,
    required this.startDate,
    this.endDate,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) =>
      _$MedicineModelFromJson(json);
  Map<String, dynamic> toJson() => _$MedicineModelToJson(this);
}

@JsonSerializable()
class MedicinesResponse {
  final bool success;
  final String? message;
  final List<MedicineModel>? data;

  MedicinesResponse({required this.success, this.message, this.data});

  factory MedicinesResponse.fromJson(Map<String, dynamic> json) =>
      _$MedicinesResponseFromJson(json);
}

@JsonSerializable()
class ProfileModel {
  final String? bloodType;
  final String? allergies;
  final double? weight;
  final double? height;
  final String? gender;
  final String? birthday;
  final String? address;
  final String? phone;

  ProfileModel({
    this.bloodType,
    this.allergies,
    this.weight,
    this.height,
    this.gender,
    this.birthday,
    this.address,
    this.phone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}

@JsonSerializable()
class ProfileResponse {
  final bool success;
  final String? message;
  final ProfileModel? data;

  ProfileResponse({required this.success, this.message, this.data});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}

@JsonSerializable()
class AppointmentModel {
  final String id;
  final String title;
  final String date;
  final String? status;
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.title,
    required this.date,
    this.status,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      _$AppointmentModelFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentModelToJson(this);
}

@JsonSerializable()
class AppointmentsResponse {
  final bool success;
  final String? message;
  final List<AppointmentModel>? data;

  AppointmentsResponse({required this.success, this.message, this.data});

  factory AppointmentsResponse.fromJson(Map<String, dynamic> json) =>
      _$AppointmentsResponseFromJson(json);
}

@JsonSerializable()
class HealthMetricModel {
  final String? id;
  final String type;
  final double value;
  final String unit;
  final String date;

  HealthMetricModel({
    this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.date,
  });

  factory HealthMetricModel.fromJson(Map<String, dynamic> json) =>
      _$HealthMetricModelFromJson(json);
  Map<String, dynamic> toJson() => _$HealthMetricModelToJson(this);
}

@JsonSerializable()
class MetricsResponse {
  final bool success;
  final String? message;
  final List<HealthMetricModel>? data;

  MetricsResponse({required this.success, this.message, this.data});

  factory MetricsResponse.fromJson(Map<String, dynamic> json) =>
      _$MetricsResponseFromJson(json);
}

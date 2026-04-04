import 'package:json_annotation/json_annotation.dart';
import 'auth_models.dart';

part 'dashboard_models.g.dart';

@JsonSerializable()
class DashboardResponse {
  final bool success;
  final String? message;
  final DashboardData? data;

  DashboardResponse({required this.success, this.message, this.data});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardResponseToJson(this);
}

@JsonSerializable()
class DashboardData {
  final UserModel? user;
  final DashboardStats? stats;

  DashboardData({this.user, this.stats});

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardDataToJson(this);
}

@JsonSerializable()
class DashboardStats {
  final String? status;
  final int? medicineCount;
  final List<MedicineSummary>? medicines;
  final List<ActivityItem>? recentActivities;
  final ProfileSummary? profile;
  final String? latestDiagnosis;
  final String? latestVitalsText;
  final String? latestVitalDate;
  final UpcomingAppointment? upcomingAppointment;
  final List<AlertItem>? alerts;

  DashboardStats({
    this.status,
    this.medicineCount,
    this.medicines,
    this.recentActivities,
    this.profile,
    this.latestDiagnosis,
    this.latestVitalsText,
    this.latestVitalDate,
    this.upcomingAppointment,
    this.alerts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}

@JsonSerializable()
class MedicineSummary {
  final String id;
  final String name;
  final String? dosage;
  final String? frequency;

  MedicineSummary({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
  });

  factory MedicineSummary.fromJson(Map<String, dynamic> json) =>
      _$MedicineSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MedicineSummaryToJson(this);
}

@JsonSerializable()
class ActivityItem {
  final String id;
  final String title;
  final String time;
  final String? type;

  ActivityItem({
    required this.id,
    required this.title,
    required this.time,
    this.type,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) =>
      _$ActivityItemFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityItemToJson(this);
}

@JsonSerializable()
class ProfileSummary {
  final String? bloodType;
  final String? allergies;
  final String? lastRecordUpdated;
  final String? gender;
  final double? weight;
  final double? height;
  final String? birthday;

  ProfileSummary({
    this.bloodType,
    this.allergies,
    this.lastRecordUpdated,
    this.gender,
    this.weight,
    this.height,
    this.birthday,
  });

  factory ProfileSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSummaryToJson(this);
}

@JsonSerializable()
class UpcomingAppointment {
  final String title;
  final String date;

  UpcomingAppointment({required this.title, required this.date});

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) =>
      _$UpcomingAppointmentFromJson(json);
  Map<String, dynamic> toJson() => _$UpcomingAppointmentToJson(this);
}

@JsonSerializable()
class AlertItem {
  final String id;
  final String message;
  final String type;

  AlertItem({required this.id, required this.message, required this.type});

  factory AlertItem.fromJson(Map<String, dynamic> json) =>
      _$AlertItemFromJson(json);
  Map<String, dynamic> toJson() => _$AlertItemToJson(this);
}

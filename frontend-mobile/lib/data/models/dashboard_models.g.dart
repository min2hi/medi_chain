// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardResponse _$DashboardResponseFromJson(Map<String, dynamic> json) =>
    DashboardResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : DashboardData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DashboardResponseToJson(DashboardResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

DashboardData _$DashboardDataFromJson(Map<String, dynamic> json) =>
    DashboardData(
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      stats: json['stats'] == null
          ? null
          : DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DashboardDataToJson(DashboardData instance) =>
    <String, dynamic>{
      'user': instance.user,
      'stats': instance.stats,
    };

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      status: json['status'] as String?,
      medicineCount: (json['medicineCount'] as num?)?.toInt(),
      medicines: (json['medicines'] as List<dynamic>?)
          ?.map((e) => MedicineSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivities: (json['recentActivities'] as List<dynamic>?)
          ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      profile: json['profile'] == null
          ? null
          : ProfileSummary.fromJson(json['profile'] as Map<String, dynamic>),
      latestDiagnosis: json['latestDiagnosis'] as String?,
      latestVitalsText: json['latestVitalsText'] as String?,
      latestVitalDate: json['latestVitalDate'] as String?,
      upcomingAppointment: json['upcomingAppointment'] == null
          ? null
          : UpcomingAppointment.fromJson(
              json['upcomingAppointment'] as Map<String, dynamic>),
      alerts: (json['alerts'] as List<dynamic>?)
          ?.map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardStatsToJson(DashboardStats instance) =>
    <String, dynamic>{
      'status': instance.status,
      'medicineCount': instance.medicineCount,
      'medicines': instance.medicines,
      'recentActivities': instance.recentActivities,
      'profile': instance.profile,
      'latestDiagnosis': instance.latestDiagnosis,
      'latestVitalsText': instance.latestVitalsText,
      'latestVitalDate': instance.latestVitalDate,
      'upcomingAppointment': instance.upcomingAppointment,
      'alerts': instance.alerts,
    };

MedicineSummary _$MedicineSummaryFromJson(Map<String, dynamic> json) =>
    MedicineSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
    );

Map<String, dynamic> _$MedicineSummaryToJson(MedicineSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'dosage': instance.dosage,
      'frequency': instance.frequency,
    };

ActivityItem _$ActivityItemFromJson(Map<String, dynamic> json) => ActivityItem(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$ActivityItemToJson(ActivityItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'time': instance.time,
      'type': instance.type,
    };

ProfileSummary _$ProfileSummaryFromJson(Map<String, dynamic> json) =>
    ProfileSummary(
      bloodType: json['bloodType'] as String?,
      allergies: json['allergies'] as String?,
      lastRecordUpdated: json['lastRecordUpdated'] as String?,
      gender: json['gender'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      birthday: json['birthday'] as String?,
    );

Map<String, dynamic> _$ProfileSummaryToJson(ProfileSummary instance) =>
    <String, dynamic>{
      'bloodType': instance.bloodType,
      'allergies': instance.allergies,
      'lastRecordUpdated': instance.lastRecordUpdated,
      'gender': instance.gender,
      'weight': instance.weight,
      'height': instance.height,
      'birthday': instance.birthday,
    };

UpcomingAppointment _$UpcomingAppointmentFromJson(Map<String, dynamic> json) =>
    UpcomingAppointment(
      title: json['title'] as String,
      date: json['date'] as String,
    );

Map<String, dynamic> _$UpcomingAppointmentToJson(
        UpcomingAppointment instance) =>
    <String, dynamic>{
      'title': instance.title,
      'date': instance.date,
    };

AlertItem _$AlertItemFromJson(Map<String, dynamic> json) => AlertItem(
      id: json['id'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$AlertItemToJson(AlertItem instance) => <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'type': instance.type,
    };

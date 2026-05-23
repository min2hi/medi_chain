// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_twin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthTwinStatus _$HealthTwinStatusFromJson(Map<String, dynamic> json) =>
    HealthTwinStatus(
      isStable: json['isStable'] as bool,
      weeksTracked: (json['weeksTracked'] as num).toInt(),
      totalLogs: (json['totalLogs'] as num).toInt(),
      recentScore: (json['recentScore'] as num?)?.toDouble(),
      trendPercent: (json['trendPercent'] as num?)?.toDouble(),
      recentAnomalies: (json['recentAnomalies'] as List<dynamic>?)
              ?.map((e) => HealthAnomaly.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map((e) => HealthPattern.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$HealthTwinStatusToJson(HealthTwinStatus instance) =>
    <String, dynamic>{
      'isStable': instance.isStable,
      'weeksTracked': instance.weeksTracked,
      'totalLogs': instance.totalLogs,
      'recentScore': instance.recentScore,
      'trendPercent': instance.trendPercent,
      'recentAnomalies': instance.recentAnomalies,
      'patterns': instance.patterns,
    };

HealthAnomaly _$HealthAnomalyFromJson(Map<String, dynamic> json) =>
    HealthAnomaly(
      id: json['id'] as String,
      explanation: json['explanation'] as String,
      actionType: json['actionType'] as String?,
      isDismissed: json['isDismissed'] as bool,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      anomalyScore: (json['anomalyScore'] as num).toDouble(),
    );

Map<String, dynamic> _$HealthAnomalyToJson(HealthAnomaly instance) =>
    <String, dynamic>{
      'id': instance.id,
      'explanation': instance.explanation,
      'actionType': instance.actionType,
      'isDismissed': instance.isDismissed,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'anomalyScore': instance.anomalyScore,
    };

HealthPattern _$HealthPatternFromJson(Map<String, dynamic> json) =>
    HealthPattern(
      description: json['description'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$HealthPatternToJson(HealthPattern instance) =>
    <String, dynamic>{
      'description': instance.description,
      'type': instance.type,
      'icon': instance.icon,
    };

HealthTimelineMonth _$HealthTimelineMonthFromJson(Map<String, dynamic> json) =>
    HealthTimelineMonth(
      monthKey: json['monthKey'] as String,
      label: json['label'] as String,
      healthScore: (json['healthScore'] as num?)?.toDouble(),
      events: (json['events'] as List<dynamic>)
          .map((e) => HealthEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HealthTimelineMonthToJson(
        HealthTimelineMonth instance) =>
    <String, dynamic>{
      'monthKey': instance.monthKey,
      'label': instance.label,
      'healthScore': instance.healthScore,
      'events': instance.events,
    };

HealthEvent _$HealthEventFromJson(Map<String, dynamic> json) => HealthEvent(
      id: json['id'] as String,
      source: json['source'] as String,
      rawContent: json['rawContent'] as String,
      severity: (json['severity'] as num?)?.toInt(),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );

Map<String, dynamic> _$HealthEventToJson(HealthEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'rawContent': instance.rawContent,
      'severity': instance.severity,
      'loggedAt': instance.loggedAt.toIso8601String(),
    };

HealthTwinStatusResponse _$HealthTwinStatusResponseFromJson(
        Map<String, dynamic> json) =>
    HealthTwinStatusResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : HealthTwinStatus.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$HealthTwinStatusResponseToJson(
        HealthTwinStatusResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
    };

HealthTimelineResponse _$HealthTimelineResponseFromJson(
        Map<String, dynamic> json) =>
    HealthTimelineResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>?)
          ?.map(
              (e) => HealthTimelineMonth.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$HealthTimelineResponseToJson(
        HealthTimelineResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
    };

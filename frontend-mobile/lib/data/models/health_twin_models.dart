import 'package:json_annotation/json_annotation.dart';

part 'health_twin_models.g.dart';

// ══════════════════════════════════════════════════════════════
// HEALTH TWIN MODELS — Bóng Sức Khỏe
// ══════════════════════════════════════════════════════════════

/// Trạng thái tổng quan của Bóng Sức Khỏe
@JsonSerializable()
class HealthTwinStatus {
  /// Đã đủ dữ liệu để phân tích chưa (>= 3 logs + >= 14 ngày)
  final bool isStable;
  final int weeksTracked;
  final int totalLogs;
  /// Điểm sức khỏe tổng quan 0-100 (null nếu chưa đủ data)
  final double? recentScore;
  /// Phần trăm so với baseline (dương = tốt hơn, âm = kém hơn)
  final double? trendPercent;
  final List<HealthAnomaly> recentAnomalies;
  final List<HealthPattern> patterns;

  const HealthTwinStatus({
    required this.isStable,
    required this.weeksTracked,
    required this.totalLogs,
    this.recentScore,
    this.trendPercent,
    this.recentAnomalies = const [],
    this.patterns = const [],
  });

  factory HealthTwinStatus.fromJson(Map<String, dynamic> json) =>
      _$HealthTwinStatusFromJson(json);
  Map<String, dynamic> toJson() => _$HealthTwinStatusToJson(this);

  /// Empty state khi chưa có dữ liệu
  static HealthTwinStatus empty() => const HealthTwinStatus(
        isStable: false,
        weeksTracked: 0,
        totalLogs: 0,
      );
}

/// Một điểm bất thường AI phát hiện
@JsonSerializable()
class HealthAnomaly {
  final String id;
  final String explanation;
  /// SUGGEST_CONSULT | SUGGEST_APPOINTMENT | INFO
  final String? actionType;
  final bool isDismissed;
  final DateTime detectedAt;
  final double anomalyScore;

  const HealthAnomaly({
    required this.id,
    required this.explanation,
    this.actionType,
    required this.isDismissed,
    required this.detectedAt,
    required this.anomalyScore,
  });

  factory HealthAnomaly.fromJson(Map<String, dynamic> json) =>
      _$HealthAnomalyFromJson(json);
  Map<String, dynamic> toJson() => _$HealthAnomalyToJson(this);
}

/// Pattern AI nhận ra theo thời gian
@JsonSerializable()
class HealthPattern {
  final String description;
  /// SEASONAL | BEHAVIORAL | DRUG_RESPONSE | RECURRING
  final String type;
  final String? icon;

  const HealthPattern({
    required this.description,
    required this.type,
    this.icon,
  });

  factory HealthPattern.fromJson(Map<String, dynamic> json) =>
      _$HealthPatternFromJson(json);
  Map<String, dynamic> toJson() => _$HealthPatternToJson(this);
}

/// Timeline grouped by month
@JsonSerializable()
class HealthTimelineMonth {
  /// "2025-04" format
  final String monthKey;
  /// "Tháng 4, 2025"
  final String label;
  /// Điểm sức khỏe tháng đó 0-100 (null = chưa đủ data)
  final double? healthScore;
  final List<HealthEvent> events;

  const HealthTimelineMonth({
    required this.monthKey,
    required this.label,
    this.healthScore,
    required this.events,
  });

  factory HealthTimelineMonth.fromJson(Map<String, dynamic> json) =>
      _$HealthTimelineMonthFromJson(json);
  Map<String, dynamic> toJson() => _$HealthTimelineMonthToJson(this);
}

/// Một sự kiện sức khỏe trong timeline
@JsonSerializable()
class HealthEvent {
  final String id;
  /// AI_CONSULT | MEDICINE_ADDED | APPOINTMENT | WEEKLY_CHECKIN
  final String source;
  final String rawContent;
  final int? severity;
  final DateTime loggedAt;

  const HealthEvent({
    required this.id,
    required this.source,
    required this.rawContent,
    this.severity,
    required this.loggedAt,
  });

  factory HealthEvent.fromJson(Map<String, dynamic> json) =>
      _$HealthEventFromJson(json);
  Map<String, dynamic> toJson() => _$HealthEventToJson(this);

  /// Icon cho từng loại source
  String get sourceIcon {
    switch (source) {
      case 'AI_CONSULT':       return '🤖';
      case 'MEDICINE_ADDED':   return '💊';
      case 'APPOINTMENT':      return '🏥';
      case 'WEEKLY_CHECKIN':   return '📝';
      case 'RS_FEEDBACK':      return '⭐';
      default:                 return '📌';
    }
  }

  String get sourceLabel {
    switch (source) {
      case 'AI_CONSULT':       return 'Tư vấn AI';
      case 'MEDICINE_ADDED':   return 'Thêm thuốc';
      case 'APPOINTMENT':      return 'Lịch khám';
      case 'WEEKLY_CHECKIN':   return 'Check-in tuần';
      case 'RS_FEEDBACK':      return 'Đánh giá thuốc';
      default:                 return 'Sự kiện';
    }
  }
}

/// Response từ API status
@JsonSerializable()
class HealthTwinStatusResponse {
  final bool success;
  final HealthTwinStatus? data;
  final String? message;

  const HealthTwinStatusResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory HealthTwinStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthTwinStatusResponseFromJson(json);
}

/// Response timeline
@JsonSerializable()
class HealthTimelineResponse {
  final bool success;
  final List<HealthTimelineMonth>? data;
  final String? message;

  const HealthTimelineResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory HealthTimelineResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthTimelineResponseFromJson(json);
}

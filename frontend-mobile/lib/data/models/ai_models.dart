import 'package:json_annotation/json_annotation.dart';

part 'ai_models.g.dart';

// ──────────────────────────────────────────────
// AI Message / Recommendation Models (existing)
// ──────────────────────────────────────────────

@JsonSerializable()
class AIMessageModel {
  final String? id;
  final String role; // USER, ASSISTANT, SYSTEM
  final String content;
  final String? createdAt;
  final String? safetyCheckResult;
  final String? medicalContext;

  AIMessageModel({
    this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.safetyCheckResult,
    this.medicalContext,
  });

  factory AIMessageModel.fromJson(Map<String, dynamic> json) =>
      _$AIMessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$AIMessageModelToJson(this);
}

@JsonSerializable()
class RecommendedMedicine {
  final String name;
  final String? genericName;
  final String? ingredients;
  final String? category;
  final int? rank;
  final double? finalScore;
  final String? sideEffects;
  final Map<String, double>? scores;

  RecommendedMedicine({
    required this.name,
    this.genericName,
    this.ingredients,
    this.category,
    this.rank,
    this.finalScore,
    this.sideEffects,
    this.scores,
  });

  factory RecommendedMedicine.fromJson(Map<String, dynamic> json) =>
      _$RecommendedMedicineFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendedMedicineToJson(this);
}

@JsonSerializable()
class RecommendationData {
  final String sessionId;
  final String? conversationId;
  final AIMessageModel message;
  final List<RecommendedMedicine>? recommendedMedicines;
  final List<String>? safetyWarnings;
  final Map<String, dynamic>? engineStats;
  final String? source;

  RecommendationData({
    required this.sessionId,
    this.conversationId,
    required this.message,
    this.recommendedMedicines,
    this.safetyWarnings,
    this.engineStats,
    this.source,
  });

  factory RecommendationData.fromJson(Map<String, dynamic> json) =>
      _$RecommendationDataFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationDataToJson(this);
}

@JsonSerializable()
class RecommendationResponse {
  final bool success;
  final String? message;
  final RecommendationData? data;

  RecommendationResponse({required this.success, this.message, this.data});

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationResponseFromJson(json);
}

@JsonSerializable()
class AIConversationModel {
  final String id;
  final String type; // CHAT, CONSULT
  final String? title;
  final String createdAt;
  final String? lastMessageAt;

  AIConversationModel({
    required this.id,
    required this.type,
    this.title,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory AIConversationModel.fromJson(Map<String, dynamic> json) =>
      _$AIConversationModelFromJson(json);
  Map<String, dynamic> toJson() => _$AIConversationModelToJson(this);
}

// ──────────────────────────────────────────────
// Chat Models — dùng cho POST /ai/chat
// ──────────────────────────────────────────────

/// Local model: đại diện 1 tin nhắn trong UI (không dùng json_annotation)
class ChatMessage {
  final String id;
  final String role; // USER or ASSISTANT
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'USER';
}

/// Response của POST /ai/chat: { success, data: { conversationId, message } }
@JsonSerializable()
class ChatApiData {
  final String conversationId;
  final AIMessageModel message;

  ChatApiData({required this.conversationId, required this.message});

  factory ChatApiData.fromJson(Map<String, dynamic> json) =>
      _$ChatApiDataFromJson(json);
}

@JsonSerializable()
class ChatApiResponse {
  final bool success;
  final String? message;
  final ChatApiData? data;

  ChatApiResponse({required this.success, this.message, this.data});

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatApiResponseFromJson(json);
}

// ──────────────────────────────────────────────
// Sharing Models — dùng cho /sharing endpoints
// ──────────────────────────────────────────────

@JsonSerializable()
class SharingUserModel {
  final String id;
  final String? name;
  final String? email;
  final String? image;

  SharingUserModel({required this.id, this.name, this.email, this.image});

  factory SharingUserModel.fromJson(Map<String, dynamic> json) =>
      _$SharingUserModelFromJson(json);
  Map<String, dynamic> toJson() => _$SharingUserModelToJson(this);
}

@JsonSerializable()
class SharingModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String type; // VIEW or MANAGE
  final String? expiresAt;
  final String createdAt;
  final SharingUserModel? toUser;
  final SharingUserModel? fromUser;

  SharingModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    this.expiresAt,
    required this.createdAt,
    this.toUser,
    this.fromUser,
  });

  factory SharingModel.fromJson(Map<String, dynamic> json) =>
      _$SharingModelFromJson(json);
  Map<String, dynamic> toJson() => _$SharingModelToJson(this);
}

@JsonSerializable()
class SharingListResponse {
  final bool success;
  final String? message;
  final List<SharingModel>? data;

  SharingListResponse({required this.success, this.message, this.data});

  factory SharingListResponse.fromJson(Map<String, dynamic> json) =>
      _$SharingListResponseFromJson(json);
}

@JsonSerializable()
class SharingCreateResponse {
  final bool success;
  final String? message;
  final SharingModel? data;

  SharingCreateResponse({required this.success, this.message, this.data});

  factory SharingCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$SharingCreateResponseFromJson(json);
}

// ──────────────────────────────────────────────
// History Models — Conversations & Sessions
// ──────────────────────────────────────────────

/// 1 conversation trong lịch sử chat AI
class ConversationModel {
  final String id;
  final String type; // CHAT, CONSULT
  final String? title;
  final String createdAt;
  final String? lastMessageAt;

  ConversationModel({
    required this.id,
    required this.type,
    this.title,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String?,
        createdAt: json['createdAt'] as String,
        lastMessageAt: json['lastMessageAt'] as String?,
      );
}

/// Response GET /ai/conversations
class ConversationListResponse {
  final bool success;
  final String? message;
  final List<ConversationModel>? data;

  ConversationListResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ConversationListResponse.fromJson(Map<String, dynamic> json) =>
      ConversationListResponse(
        success: json['success'] as bool,
        message: json['message'] as String?,
        data: (json['data'] as List<dynamic>?)
            ?.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response GET /ai/conversations/:id/messages
class MessageListResponse {
  final bool success;
  final String? message;
  final List<AIMessageModel>? data;

  MessageListResponse({required this.success, this.message, this.data});

  factory MessageListResponse.fromJson(Map<String, dynamic> json) =>
      MessageListResponse(
        success: json['success'] as bool,
        message: json['message'] as String?,
        data: (json['data'] as List<dynamic>?)
            ?.map((e) => AIMessageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 1 phiên tư vấn thuốc trong lịch sử recommendation
class RecommendationSession {
  final String id;
  final String symptoms;
  final String createdAt;
  final List<RecommendedMedicine>? medicines;

  RecommendationSession({
    required this.id,
    required this.symptoms,
    required this.createdAt,
    this.medicines,
  });

  factory RecommendationSession.fromJson(Map<String, dynamic> json) =>
      RecommendationSession(
        id: json['id'] as String,
        symptoms: json['symptoms'] as String? ?? '',
        createdAt: json['createdAt'] as String,
        medicines: (json['rankedDrugs'] as List<dynamic>? ??
                json['medicines'] as List<dynamic>? ??
                [])
            .map((e) => RecommendedMedicine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response GET /recommendation/sessions
class RecommendationSessionListResponse {
  final bool success;
  final String? message;
  final List<RecommendationSession>? data;

  RecommendationSessionListResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory RecommendationSessionListResponse.fromJson(
      Map<String, dynamic> json) {
    // Backend trả về { success, data: { sessions: [...], total, page } }
    // hoặc { success, data: [...] }
    final raw = json['data'];
    List<dynamic>? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      list = raw['sessions'] as List<dynamic>?;
    }
    return RecommendationSessionListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: list
          ?.map((e) =>
              RecommendationSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIMessageModel _$AIMessageModelFromJson(Map<String, dynamic> json) =>
    AIMessageModel(
      id: json['id'] as String?,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as String?,
      safetyCheckResult: json['safetyCheckResult'] as String?,
      medicalContext: json['medicalContext'] as String?,
    );

Map<String, dynamic> _$AIMessageModelToJson(AIMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'createdAt': instance.createdAt,
      'safetyCheckResult': instance.safetyCheckResult,
      'medicalContext': instance.medicalContext,
    };

RecommendedMedicine _$RecommendedMedicineFromJson(Map<String, dynamic> json) =>
    RecommendedMedicine(
      name: json['name'] as String,
      genericName: json['genericName'] as String?,
      ingredients: json['ingredients'] as String?,
      category: json['category'] as String?,
      rank: (json['rank'] as num?)?.toInt(),
      finalScore: (json['finalScore'] as num?)?.toDouble(),
      sideEffects: json['sideEffects'] as String?,
      scores: (json['scores'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$RecommendedMedicineToJson(
        RecommendedMedicine instance) =>
    <String, dynamic>{
      'name': instance.name,
      'genericName': instance.genericName,
      'ingredients': instance.ingredients,
      'category': instance.category,
      'rank': instance.rank,
      'finalScore': instance.finalScore,
      'sideEffects': instance.sideEffects,
      'scores': instance.scores,
    };

RecommendationData _$RecommendationDataFromJson(Map<String, dynamic> json) =>
    RecommendationData(
      sessionId: json['sessionId'] as String,
      conversationId: json['conversationId'] as String?,
      message: AIMessageModel.fromJson(json['message'] as Map<String, dynamic>),
      recommendedMedicines: (json['recommendedMedicines'] as List<dynamic>?)
          ?.map((e) => RecommendedMedicine.fromJson(e as Map<String, dynamic>))
          .toList(),
      safetyWarnings: (json['safetyWarnings'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      engineStats: json['engineStats'] as Map<String, dynamic>?,
      source: json['source'] as String?,
    );

Map<String, dynamic> _$RecommendationDataToJson(RecommendationData instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'conversationId': instance.conversationId,
      'message': instance.message,
      'recommendedMedicines': instance.recommendedMedicines,
      'safetyWarnings': instance.safetyWarnings,
      'engineStats': instance.engineStats,
      'source': instance.source,
    };

RecommendationResponse _$RecommendationResponseFromJson(
        Map<String, dynamic> json) =>
    RecommendationResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : RecommendationData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RecommendationResponseToJson(
        RecommendationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AIConversationModel _$AIConversationModelFromJson(Map<String, dynamic> json) =>
    AIConversationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      createdAt: json['createdAt'] as String,
      lastMessageAt: json['lastMessageAt'] as String?,
    );

Map<String, dynamic> _$AIConversationModelToJson(
        AIConversationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'createdAt': instance.createdAt,
      'lastMessageAt': instance.lastMessageAt,
    };

ChatApiData _$ChatApiDataFromJson(Map<String, dynamic> json) => ChatApiData(
      conversationId: json['conversationId'] as String,
      message: AIMessageModel.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatApiDataToJson(ChatApiData instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'message': instance.message,
    };

ChatApiResponse _$ChatApiResponseFromJson(Map<String, dynamic> json) =>
    ChatApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : ChatApiData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatApiResponseToJson(ChatApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

SharingUserModel _$SharingUserModelFromJson(Map<String, dynamic> json) =>
    SharingUserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$SharingUserModelToJson(SharingUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'image': instance.image,
    };

SharingModel _$SharingModelFromJson(Map<String, dynamic> json) => SharingModel(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      type: json['type'] as String,
      expiresAt: json['expiresAt'] as String?,
      createdAt: json['createdAt'] as String,
      toUser: json['toUser'] == null
          ? null
          : SharingUserModel.fromJson(json['toUser'] as Map<String, dynamic>),
      fromUser: json['fromUser'] == null
          ? null
          : SharingUserModel.fromJson(json['fromUser'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SharingModelToJson(SharingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'type': instance.type,
      'expiresAt': instance.expiresAt,
      'createdAt': instance.createdAt,
      'toUser': instance.toUser,
      'fromUser': instance.fromUser,
    };

SharingListResponse _$SharingListResponseFromJson(Map<String, dynamic> json) =>
    SharingListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => SharingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SharingListResponseToJson(
        SharingListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

SharingCreateResponse _$SharingCreateResponseFromJson(
        Map<String, dynamic> json) =>
    SharingCreateResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : SharingModel.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SharingCreateResponseToJson(
        SharingCreateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

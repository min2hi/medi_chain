import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';

class AIRepository {
  final ApiClient _apiClient;

  AIRepository(this._apiClient);

  // ──────────────────────────────────────────────
  // Consultation (Recommendation Engine)
  // ──────────────────────────────────────────────

  Future<RecommendationResponse> consult(
    String symptoms, {
    String? conversationId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/recommendation/consult',
        data: {
          'symptoms': symptoms,
          if (conversationId != null) 'conversationId': conversationId,
        },
      );
      return RecommendationResponse.fromJson(response.data);
    } catch (e) {
      // Ưu tiên hiển thị message thực từ backend (VD: "Hồ sơ y tế chưa hoàn thiện")
      // thay vì lỗi chung chung "Lỗi kết nối" gây khó hiểu cho user
      String msg = 'Lỗi khi kết nối với máy chủ AI';
      try {
        final dioErr = e as dynamic;
        final data = dioErr.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'] as String;
        }
      } catch (_) {}
      return RecommendationResponse(success: false, message: msg);
    }
  }

  Future<RecommendationResponse> getSessionDetail(String id) async {
    try {
      final response = await _apiClient.get('/recommendation/sessions/$id');
      return RecommendationResponse.fromJson(response.data);
    } catch (e) {
      return RecommendationResponse(
        success: false,
        message: 'Lỗi tải phiên tư vấn',
      );
    }
  }

  // ──────────────────────────────────────────────
  // AI Chatbot
  // ──────────────────────────────────────────────

  Future<ChatApiResponse> chat(String message, {String? conversationId}) async {
    try {
      final response = await _apiClient.post(
        '/ai/chat',
        data: {
          'message': message,
          if (conversationId != null) 'conversationId': conversationId,
        },
      );
      return ChatApiResponse.fromJson(response.data);
    } catch (e) {
      return ChatApiResponse(
        success: false,
        message: 'Không thể kết nối đến AI chat.',
      );
    }
  }

  // ──────────────────────────────────────────────
  // History
  // ──────────────────────────────────────────────

  /// Lấy danh sách conversations; [type]: 'CHAT' | 'CONSULT' | null (all)
  Future<ConversationListResponse> getConversations({String? type}) async {
    try {
      final response = await _apiClient.get(
        '/ai/conversations',
        queryParameters: type != null ? {'type': type} : null,
      );
      return ConversationListResponse.fromJson(response.data);
    } catch (e) {
      return ConversationListResponse(
          success: false, message: 'Không thể tải lịch sử chat');
    }
  }

  /// Lấy messages của 1 conversation cụ thể
  Future<MessageListResponse> getConversationMessages(
      String conversationId) async {
    try {
      final response =
          await _apiClient.get('/ai/conversations/$conversationId/messages');
      return MessageListResponse.fromJson(response.data);
    } catch (e) {
      return MessageListResponse(
          success: false, message: 'Không thể tải tin nhắn');
    }
  }

  /// Lấy lịch sử các phiên tư vấn thuốc
  Future<RecommendationSessionListResponse> getRecommendationSessions(
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/recommendation/sessions',
        queryParameters: {'page': page, 'limit': limit},
      );
      return RecommendationSessionListResponse.fromJson(response.data);
    } catch (e) {
      return RecommendationSessionListResponse(
          success: false, message: 'Không thể tải lịch sử tư vấn');
    }
  }

  // ──────────────────────────────────────────────
  // Feedback
  // ──────────────────────────────────────────────

  /// Gửi đánh giá hiệu quả thuốc đã dùng
  Future<bool> submitFeedback({
    required String sessionId,
    required String drugId,
    required int rating,
    required String outcome,
    int? usedDays,
    String? sideEffect,
    String? note,
  }) async {
    try {
      final response = await _apiClient.post(
        '/recommendation/feedback',
        data: {
          'sessionId': sessionId,
          'drugId': drugId,
          'rating': rating,
          'outcome': outcome,
          if (usedDays != null) 'usedDays': usedDays,
          if (sideEffect != null) 'sideEffect': sideEffect,
          if (note != null) 'note': note,
        },
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Lấy đánh giá hiện tại của user cho 1 thuốc trong 1 session
  Future<Map<String, dynamic>?> getFeedback({
    required String sessionId,
    required String drugId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/recommendation/feedback',
        queryParameters: {
          'sessionId': sessionId,
          'drugId': drugId,
        },
      );
      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

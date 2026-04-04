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
      return RecommendationResponse(
        success: false,
        message: 'Lỗi khi kết nối với máy chủ AI',
      );
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
}

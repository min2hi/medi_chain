import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';

class SharingRepository {
  final ApiClient _apiClient;

  SharingRepository(this._apiClient);

  /// [GET] /api/sharing/me — lấy danh sách chia sẻ mà tôi đã tạo
  Future<SharingListResponse> getMySharings() async {
    try {
      final response = await _apiClient.get('/sharing/me');
      return SharingListResponse.fromJson(response.data);
    } catch (e) {
      return SharingListResponse(
        success: false,
        message: 'Không thể tải danh sách chia sẻ của bạn.',
      );
    }
  }

  /// [GET] /api/sharing/shared-with-me — lấy danh sách được chia sẻ cho tôi
  Future<SharingListResponse> getSharedWithMe() async {
    try {
      final response = await _apiClient.get('/sharing/shared-with-me');
      return SharingListResponse.fromJson(response.data);
    } catch (e) {
      return SharingListResponse(
        success: false,
        message: 'Không thể tải danh sách nhận chia sẻ.',
      );
    }
  }

  /// [POST] /api/sharing — tạo chia sẻ mới
  /// [body] email: string, type: 'VIEW' | 'MANAGE', expiresAt?: string (ISO date)
  Future<SharingCreateResponse> createSharing({
    required String email,
    required String type,
    String? expiresAt,
  }) async {
    try {
      final response = await _apiClient.post(
        '/sharing',
        data: {
          'email': email,
          'type': type,
          if (expiresAt != null && expiresAt.isNotEmpty) 'expiresAt': expiresAt,
        },
      );
      return SharingCreateResponse.fromJson(response.data);
    } catch (e) {
      return SharingCreateResponse(
        success: false,
        message: 'Không tìm thấy người dùng với email này.',
      );
    }
  }

  /// [DELETE] /api/sharing/:id — thu hồi quyền chia sẻ
  Future<Map<String, dynamic>> revokeSharing(String id) async {
    try {
      final response = await _apiClient.delete('/sharing/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Không thể thu hồi quyền truy cập.'};
    }
  }
}

import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';

class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  // ─── Safety Keywords ────────────────────────────────────────────────────────

  Future<List<SafetyKeywordModel>> getKeywords() async {
    final res = await _api.get('/admin/clinical-rules/keywords');
    final data = res.data;
    final list = (data['data'] ?? data['keywords'] ?? data) as List<dynamic>;
    return list
        .map((e) => SafetyKeywordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SafetyKeywordModel> createKeyword({
    required String keyword,
    String? category,
    String? guideline,
  }) async {
    final res = await _api.post(
      '/admin/clinical-rules/keywords',
      data: {'keyword': keyword, 'category': category, 'guideline': guideline},
    );
    final d = res.data['data'] ?? res.data;
    return SafetyKeywordModel.fromJson(d as Map<String, dynamic>);
  }

  Future<void> activateKeyword(String id) async {
    await _api.patch('/admin/clinical-rules/keywords/$id/activate');
  }

  Future<void> deactivateKeyword(String id) async {
    await _api.patch('/admin/clinical-rules/keywords/$id/deactivate');
  }

  Future<void> updateKeyword(String id, {String? keyword, String? guideline}) async {
    await _api.patch(
      '/admin/clinical-rules/keywords/$id',
      data: {
        if (keyword != null) 'keyword': keyword,
        if (guideline != null) 'guideline': guideline,
      },
    );
  }

  // ─── Combo Rules ────────────────────────────────────────────────────────────

  Future<List<ComboRuleModel>> getCombos() async {
    final res = await _api.get('/admin/clinical-rules/combos');
    final data = res.data;
    final list = (data['data'] ?? data['combos'] ?? data) as List<dynamic>;
    return list
        .map((e) => ComboRuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ComboRuleModel> createCombo({
    required List<String> symptoms,
    required String action,
    String? description,
  }) async {
    final res = await _api.post(
      '/admin/clinical-rules/combos',
      data: {
        'symptoms': symptoms,
        'action': action,
        'description': description,
      },
    );
    final d = res.data['data'] ?? res.data;
    return ComboRuleModel.fromJson(d as Map<String, dynamic>);
  }

  Future<void> activateCombo(String id) async {
    await _api.patch('/admin/clinical-rules/combos/$id/activate');
  }

  // ─── Review Queue ───────────────────────────────────────────────────────────

  Future<List<PendingReviewModel>> getPendingReview() async {
    final res = await _api.get('/admin/clinical-rules/pending-review');
    final data = res.data;
    final list = (data['data'] ?? data['items'] ?? data) as List<dynamic>;
    return list
        .map((e) => PendingReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveKeyword(String id) async {
    await _api.post('/admin/clinical-rules/pending-review/$id/approve');
  }

  Future<void> rejectKeyword(String id) async {
    await _api.post('/admin/clinical-rules/pending-review/$id/reject');
  }

  // ─── Cache / Telemetry ──────────────────────────────────────────────────────

  Future<CacheStatsModel> getCacheStats() async {
    final res = await _api.get('/admin/clinical-rules/cache/stats');
    final d = res.data['data'] ?? res.data;
    return CacheStatsModel.fromJson(d as Map<String, dynamic>);
  }

  Future<void> invalidateCache() async {
    await _api.post('/admin/clinical-rules/cache/invalidate');
  }

  Future<List<AuditLogModel>> getAuditLog() async {
    final res = await _api.get('/admin/clinical-rules/audit-log');
    final data = res.data;
    final list = (data['data'] ?? data['logs'] ?? data) as List<dynamic>;
    return list
        .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── User Management ────────────────────────────────────────────────────────

  Future<List<AdminUserModel>> getUsers() async {
    final res = await _api.get('/admin/users');
    final data = res.data;
    // Backend trả về { data: { users: [...], pagination: {...} } }
    final inner = data['data'];
    final list = (inner is Map ? (inner['users'] ?? []) : (inner ?? data['users'] ?? data)) as List<dynamic>;
    return list
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _api.patch('/admin/users/$userId/role', data: {'role': role});
  }

  // ─── API Access Logs ─────────────────────────────────────────────────────────

  Future<AccessLogData> getApiAccessLogs({String? date}) async {
    final query = date != null ? '?date=$date' : '';
    final res = await _api.get('/admin/access-logs$query');
    final d = res.data['data'] ?? res.data;
    return AccessLogData.fromJson(d as Map<String, dynamic>);
  }
}

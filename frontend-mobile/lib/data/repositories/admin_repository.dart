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
    // Backend bắt buộc groupId + groupLabel. Map từ 'category' của UI.
    final groupId    = (category?.isNotEmpty == true)
        ? category!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')
        : 'general';
    final groupLabel = (category?.isNotEmpty == true) ? category! : 'Tổng hợp';
    final res = await _api.post(
      '/admin/clinical-rules/keywords',
      data: {
        'keyword':      keyword,
        'groupId':      groupId,
        'groupLabel':   groupLabel,
        if (guideline != null) 'guidelineRef': guideline,
      },
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
        if (keyword != null)  'keyword':     keyword,
        // Backend field là 'guidelineRef', không phải 'guideline'
        if (guideline != null) 'guidelineRef': guideline,
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
    // Backend cần: { name, label, symptomGroups: String[][], minMatch }
    // Mỗi symptom thành 1 group riêng, name tự sinh unique
    final safeName = action
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final res = await _api.post(
      '/admin/clinical-rules/combos',
      data: {
        'name':         '${safeName}_${DateTime.now().millisecondsSinceEpoch}',
        'label':        action,
        'symptomGroups': symptoms.map((s) => [s]).toList(),
        'minMatch':     symptoms.length > 1 ? 2 : 1,
        if (description != null) 'changeNote': description,
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
    // Backend trả về: { success, data: { cache: { hits, misses, hitRate, ... }, db: { activeKeywords, activeCombos, pendingReview } } }
    final outer = (res.data['data'] ?? res.data) as Map<String, dynamic>;
    final db    = (outer['db']    as Map<String, dynamic>?) ?? {};
    final cache = (outer['cache'] as Map<String, dynamic>?) ?? {};
    // hitRate từ backend là String dạng "66.7%" hoặc "N/A"
    final hitRaw = cache['hitRate'];
    double? hitRate;
    if (hitRaw is num) {
      hitRate = hitRaw.toDouble() / 100;
    } else if (hitRaw is String && hitRaw.endsWith('%')) {
      hitRate = (double.tryParse(hitRaw.replaceAll('%', '')) ?? 0) / 100;
    }
    return CacheStatsModel(
      keywordCount: (db['activeKeywords'] as num?)?.toInt() ?? 0,
      comboCount:   (db['activeCombos']   as num?)?.toInt() ?? 0,
      hitRate:      hitRate,
      lastInvalidated: null, // backend không trả về trường này
    );
  }

  Future<void> invalidateCache() async {
    await _api.post('/admin/clinical-rules/cache/invalidate');
  }

  Future<List<AuditLogModel>> getAuditLog() async {
    final res = await _api.get('/admin/clinical-rules/audit-log');
    final data = res.data;
    // Backend trả về SafetyKeyword records (ai tạo/activate keyword nào)
    final list = (data['data'] ?? data['logs'] ?? data) as List<dynamic>;
    return list.map((e) {
      final j = e as Map<String, dynamic>;
      final changeNote = j['changeNote'] as String?;
      final keyword    = j['keyword']    as String? ?? '';
      final isActive   = j['isActive']   as bool?   ?? false;
      // Reconstruct action từ trạng thái keyword
      final String action;
      if (changeNote != null && changeNote.isNotEmpty) {
        action = changeNote.startsWith('[AUTO]') ? 'AI phát hiện: "$keyword"' : changeNote;
      } else if (isActive) {
        action = 'Kích hoạt từ khóa: "$keyword"';
      } else {
        action = 'Thêm từ khóa: "$keyword"';
      }
      return AuditLogModel(
        id:         j['id'].toString(),
        action:     action,
        adminEmail: j['createdBy'] as String?,
        targetId:   j['groupId']  as String?,
        metadata:   null,
        timestamp:  DateTime.tryParse(j['updatedAt'] as String? ?? j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
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

  // ─── Appointment Stats (read-only, admin chỉ xem tổng — không duyệt) ────────
  // Doctor là người duy nhất có quyền xác nhận / hủy / hoàn thành lịch hẹn.
  // Admin chỉ thấy con số thống kê tổng hợp để giám sát hoạt động platform.

  Future<int> getTodayAppointmentCount() async {
    try {
      final res = await _api.get('/admin/appointments', queryParameters: {'status': 'ALL'});
      final body = res.data;
      // Backend có thể trả về { data: [...] } hoặc { data: { items: [...] } } — handle cả hai
      final raw = body['data'] ?? body;
      final List<dynamic> list = raw is List ? raw : [];

      final today = DateTime.now();
      int count = 0;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final rawDate = item['scheduledDate'] as String? ?? item['date'] as String? ?? '';
        if (rawDate.isNotEmpty) {
          final dt = DateTime.tryParse(rawDate)?.toLocal();
          if (dt != null) {
            if (dt.year == today.year && dt.month == today.month && dt.day == today.day) {
              count++;
            }
          }
        }
      }
      return count;
    } catch (_) {
      return 0; // Dashboard không bao giờ bị block vì stat thứ yếu này
    }
  }

  // ─── API Access Logs ─────────────────────────────────────────────────────────

  Future<AccessLogData> getApiAccessLogs({String? date}) async {
    final query = date != null ? '?date=$date' : '';
    final res = await _api.get('/admin/access-logs$query');
    final d = res.data['data'] ?? res.data;
    return AccessLogData.fromJson(d as Map<String, dynamic>);
  }

  Future<String> verifyDoctorLicense(String userId) async {
    final res = await _api.patch('/admin/users/$userId/verify-license');
    return res.data['message'] as String? ?? 'Đã cập nhật trạng thái xác nhận';
  }
}

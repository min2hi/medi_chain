// ─── Admin Data Models ────────────────────────────────────────────────────────
// Tất cả entities dùng cho Admin Portal native screens.

class SafetyKeywordModel {
  final String id;
  final String keyword;
  final String? category;
  final String? guideline;
  final bool isActive;
  final DateTime createdAt;

  const SafetyKeywordModel({
    required this.id,
    required this.keyword,
    this.category,
    this.guideline,
    required this.isActive,
    required this.createdAt,
  });

  factory SafetyKeywordModel.fromJson(Map<String, dynamic> j) =>
      SafetyKeywordModel(
        id: j['id'] as String,
        keyword: j['keyword'] as String,
        category: j['category'] as String?,
        guideline: j['guideline'] as String?,
        isActive: j['isActive'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ComboRuleModel {
  final String id;
  final List<String> symptoms;
  final String action;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const ComboRuleModel({
    required this.id,
    required this.symptoms,
    required this.action,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory ComboRuleModel.fromJson(Map<String, dynamic> j) => ComboRuleModel(
        id: j['id'] as String,
        symptoms: (j['symptoms'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        action: j['action'] as String? ?? '',
        description: j['description'] as String?,
        isActive: j['isActive'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class PendingReviewModel {
  final String id;
  final String keyword;
  final String? source;
  final double? confidence;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final DateTime discoveredAt;

  const PendingReviewModel({
    required this.id,
    required this.keyword,
    this.source,
    this.confidence,
    required this.status,
    required this.discoveredAt,
  });

  factory PendingReviewModel.fromJson(Map<String, dynamic> j) =>
      PendingReviewModel(
        id: j['id'] as String,
        keyword: j['keyword'] as String? ?? '',
        source: j['source'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'PENDING',
        discoveredAt:
            DateTime.tryParse(j['discoveredAt'] as String? ?? '') ??
                DateTime.now(),
      );
}

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'PATIENT' | 'DOCTOR' | 'ADMIN'
  final DateTime createdAt;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> j) => AdminUserModel(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'PATIENT',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class CacheStatsModel {
  final int keywordCount;
  final int comboCount;
  final double? hitRate;
  final DateTime? lastInvalidated;

  const CacheStatsModel({
    required this.keywordCount,
    required this.comboCount,
    this.hitRate,
    this.lastInvalidated,
  });

  factory CacheStatsModel.fromJson(Map<String, dynamic> j) => CacheStatsModel(
        keywordCount: j['keywordCount'] as int? ?? 0,
        comboCount: j['comboCount'] as int? ?? 0,
        hitRate: (j['hitRate'] as num?)?.toDouble(),
        lastInvalidated: j['lastInvalidated'] != null
            ? DateTime.tryParse(j['lastInvalidated'] as String)
            : null,
      );
}

class AuditLogModel {
  final String id;
  final String action;
  final String? adminEmail;
  final String? targetId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const AuditLogModel({
    required this.id,
    required this.action,
    this.adminEmail,
    this.targetId,
    this.metadata,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> j) => AuditLogModel(
        id: j['id'] as String,
        action: j['action'] as String? ?? '',
        adminEmail: j['admin']?['email'] as String?,
        targetId: j['targetId'] as String?,
        metadata: j['metadata'] as Map<String, dynamic>?,
        timestamp: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

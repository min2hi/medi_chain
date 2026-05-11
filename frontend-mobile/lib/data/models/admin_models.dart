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
        id:        j['id'].toString(), // SafetyKeyword.id = Int @autoincrement
        keyword:   j['keyword'] as String,
        category:  j['category'] as String?,
        guideline: j['guideline'] ?? j['guidelineRef'] as String?,
        isActive:  j['isActive'] as bool? ?? false,
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
        id:          j['id'].toString(), // ComboRule.id = Int @autoincrement
        symptoms:    (j['symptoms'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        action:      j['action'] as String? ?? '',
        description: j['description'] as String?,
        isActive:    j['isActive'] as bool? ?? false,
        createdAt:   DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class PendingReviewModel {
  final String id;
  final String keyword;
  final String? source;
  final double? confidence;
  final String  status;       // 'PENDING' | 'APPROVED' | 'REJECTED'
  final DateTime discoveredAt;
  final String? changeNote;   // [AUTO] Trigger context từ semantic discovery

  const PendingReviewModel({
    required this.id,
    required this.keyword,
    this.source,
    this.confidence,
    required this.status,
    required this.discoveredAt,
    this.changeNote,
  });

  factory PendingReviewModel.fromJson(Map<String, dynamic> j) =>
      PendingReviewModel(
        // SafetyKeyword.id là Int @autoincrement trong Prisma — convert toString()
        id:           j['id'].toString(),
        keyword:      j['keyword'] as String? ?? '',
        source:       j['source'] as String?,
        confidence:   (j['similarityScore'] as num?)?.toDouble() ?? (j['confidence'] as num?)?.toDouble(),
        status:       j['reviewStatus'] as String? ?? j['status'] as String? ?? 'PENDING',
        discoveredAt: DateTime.tryParse(j['createdAt'] as String? ?? j['discoveredAt'] as String? ?? '') ?? DateTime.now(),
        changeNote:   j['changeNote'] as String?,
      );
}

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'USER' | 'DOCTOR' | 'ADMIN'
  final DateTime createdAt;
  // Doctor credential fields (null khi user không phải DOCTOR)
  final String? licenseNumber;
  final String? specialty;
  final bool licenseVerified;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.licenseNumber,
    this.specialty,
    this.licenseVerified = false,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> j) {
    final profile = j['profile'] as Map<String, dynamic>?;
    return AdminUserModel(
      id:              j['id']    as String,
      name:            j['name']  as String? ?? '',
      email:           j['email'] as String? ?? '',
      role:            j['role']  as String? ?? 'USER',
      createdAt:       DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      licenseNumber:   profile?['licenseNumber']  as String?,
      specialty:       profile?['specialty']       as String?,
      licenseVerified: profile?['licenseVerified'] as bool? ?? false,
    );
  }
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
        id: j['id'].toString(), // SafetyKeyword.id can be Int, convert safely
        action: j['action'] as String? ?? '',
        adminEmail: j['admin']?['email'] as String?,
        targetId: j['targetId'] as String?,
        metadata: j['metadata'] as Map<String, dynamic>?,
        timestamp: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

// ─── API Access Log (audit trail) ─────────────────────────────────────────────

class AccessLogEntry {
  final String timestamp;
  final String userId;    // Hashed (u_xxxxxx)
  final String method;    // GET, POST...
  final String path;      // /api/user/profile
  final int status;       // 200, 403, 500...
  final String ip;
  final int durationMs;

  const AccessLogEntry({
    required this.timestamp,
    required this.userId,
    required this.method,
    required this.path,
    required this.status,
    required this.ip,
    required this.durationMs,
  });

  factory AccessLogEntry.fromJson(Map<String, dynamic> j) => AccessLogEntry(
        timestamp:  j['timestamp']  as String? ?? '',
        userId:     j['userId']     as String? ?? 'anonymous',
        method:     j['method']     as String? ?? '',
        path:       j['path']       as String? ?? '',
        status:     (j['status']    as num?)?.toInt() ?? 0,
        ip:         j['ip']         as String? ?? '',
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
      );
}

class AccessLogStats {
  final int total;
  final int errors4xx;
  final int errors5xx;
  final int avgMs;

  const AccessLogStats({
    required this.total,
    required this.errors4xx,
    required this.errors5xx,
    required this.avgMs,
  });

  factory AccessLogStats.fromJson(Map<String, dynamic> j) => AccessLogStats(
        total:     (j['total']     as num?)?.toInt() ?? 0,
        errors4xx: (j['errors4xx'] as num?)?.toInt() ?? 0,
        errors5xx: (j['errors5xx'] as num?)?.toInt() ?? 0,
        avgMs:     (j['avgMs']     as num?)?.toInt() ?? 0,
      );
}

class AccessLogData {
  final String date;
  final AccessLogStats stats;
  final List<AccessLogEntry> entries;

  const AccessLogData({
    required this.date,
    required this.stats,
    required this.entries,
  });

  factory AccessLogData.fromJson(Map<String, dynamic> j) => AccessLogData(
        date: j['date'] as String? ?? '',
        stats: AccessLogStats.fromJson(j['stats'] as Map<String, dynamic>? ?? {}),
        entries: ((j['entries'] as List<dynamic>?) ?? [])
            .map((e) => AccessLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

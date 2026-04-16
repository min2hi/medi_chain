/**
 * =================================================================
 * TRIAGE AUDIT LOGGER — Quick Win 2
 * =================================================================
 *
 * Tại sao cần:
 *   Google Health, Microsoft Azure Health Bot yêu cầu mọi quyết định
 *   triage phải có audit trail để forensic investigation nếu system
 *   miss 1 emergency (false negative).
 *
 * Thiết kế:
 *   1. Structured JSON log → file (không cần DB migration)
 *   2. Log rotation hàng ngày (giữ 30 ngày)
 *   3. Ghi: timestamp, userId, symptoms, decision, layer, triggeredBy
 *   4. Có thể upgrade lên DB sau bằng cách swap writeAuditLog()
 *
 * Compliance note:
 *   Theo HIPAA: phi (protected health information) phải được encrypt.
 *   Log này chỉ ghi userId (không tên/dob), symptoms text.
 *   Production: cần encrypt at rest + access control.
 * =================================================================
 */

import fs   from 'fs';
import path from 'path';

export type TriageDecision =
    | 'EMERGENCY_BLOCKED'      // Keyword/Combo gate blocked
    | 'LLM_TRIAGE_BLOCKED'     // LLM Oracle blocked
    | 'DOWNGRADED_TO_WARNING'  // Past/hypothetical context → soft warning
    | 'CLEARED_TO_ENGINE'      // Passed all gates → engine runs
    | 'AGE_SPECIFIC_BLOCKED'   // Pediatric/geriatric threshold
    | 'BLOCKED'                // NLU Semantic Gate blocked (v3.0)
    | 'NLU_SEMANTIC_BLOCKED';  // Alias for NLU Semantic Gate

export interface TriageAuditEntry {
    timestamp:      string;  // ISO 8601
    requestId:      string;  // Random ID per request (NOT userId — privacy)
    userId?:        string;  // Opaque hash của userId (không phải plaintext ID theo HIPAA-lite)
    symptomsHash:   string;  // Length hash của symptoms text (không log raw text trong production)
    symptomsPreview: string; // Chỉ 50 ký tự đầu (đủ để debug, không lộ full PII)
    decision:       TriageDecision;
    layer:          string;  // 'LAYER_1_KEYWORD' | 'LAYER_2_NEGATION' | 'LAYER_3_COMBO' | 'LAYER_4_LLM' | 'LAYER_0_AGE'
    triggeredBy:    string | null;  // Keyword hoặc combo label gây ra decision
    confidence?:    number;  // Chỉ có khi LLM triage (0.0-1.0)
    ageGroup?:      string;  // 'infant' | 'toddler' | 'adult' | 'elderly'
    durationMs:     number;  // Thời gian xử lý (ms)
}

export class TriageAuditLogger {

    // ─── Config ────────────────────────────────────────────────────────────
    private static readonly LOG_DIR     = path.join(process.cwd(), 'logs', 'triage');
    private static readonly MAX_DAYS    = 30;    // Giữ log 30 ngày
    private static readonly MAX_MB      = 50;    // Tối đa 50MB mỗi file

    // ─── Public API ────────────────────────────────────────────────────────

    /**
     * Ghi audit log cho 1 triage event.
     * Fire-and-forget async — KHÔNG bao giờ throw để tránh ảnh hưởng pipeline.
     */
    static log(entry: Omit<TriageAuditEntry, 'timestamp' | 'requestId'>): void {
        const full: TriageAuditEntry = {
            timestamp:  new Date().toISOString(),
            requestId:  Math.random().toString(36).substring(2, 10).toUpperCase(),
            ...entry,
        };

        // Fire and forget — không await, không throw
        this.writeAuditLog(full).catch(err => {
            // Chỉ log warning — không crash pipeline
            console.warn('[TriageAudit] Write failed (non-critical):', err.message);
        });

        // Cũng log ra console (structured) để dev dễ debug + có thể ship lên CloudWatch/Datadog
        console.log('[TriageAudit]', JSON.stringify({
            ts:      full.timestamp,
            reqId:   full.requestId,
            dec:     full.decision,
            layer:   full.layer,
            trigger: full.triggeredBy,
            ms:      full.durationMs,
        }));
    }

    /**
     * Report summary cho monitoring dashboard.
     * Đọc log file hôm nay, trả về statistics.
     */
    static async getDailySummary(): Promise<{
        date:           string;
        totalRequests:  number;
        emergencyBlocked: number;
        llmBlocked:     number;
        cleared:        number;
        avgDurationMs:  number;
    }> {
        try {
            const today   = this.getTodayFilename();
            const content = fs.readFileSync(today, 'utf-8');
            const entries = content
                .split('\n')
                .filter(Boolean)
                .map(line => JSON.parse(line) as TriageAuditEntry);

            return {
                date:           new Date().toISOString().split('T')[0],
                totalRequests:  entries.length,
                emergencyBlocked: entries.filter(e => e.decision === 'EMERGENCY_BLOCKED' || e.decision === 'AGE_SPECIFIC_BLOCKED').length,
                llmBlocked:     entries.filter(e => e.decision === 'LLM_TRIAGE_BLOCKED').length,
                cleared:        entries.filter(e => e.decision === 'CLEARED_TO_ENGINE').length,
                avgDurationMs:  entries.length > 0
                    ? Math.round(entries.reduce((sum, e) => sum + e.durationMs, 0) / entries.length)
                    : 0,
            };
        } catch {
            return { date: '', totalRequests: 0, emergencyBlocked: 0, llmBlocked: 0, cleared: 0, avgDurationMs: 0 };
        }
    }

    // ─── Private Helpers ───────────────────────────────────────────────────

    private static async writeAuditLog(entry: TriageAuditEntry): Promise<void> {
        // Đảm bảo thư mục tồn tại
        if (!fs.existsSync(this.LOG_DIR)) {
            fs.mkdirSync(this.LOG_DIR, { recursive: true });
        }

        const filename = this.getTodayFilename();

        // Check file size rotation
        if (fs.existsSync(filename)) {
            const stats = fs.statSync(filename);
            if (stats.size > this.MAX_MB * 1024 * 1024) {
                // Rotate: rename file rồi tạo mới
                const rotated = filename.replace('.jsonl', `.${Date.now()}.jsonl`);
                fs.renameSync(filename, rotated);
            }
        }

        // Append JSONL (1 JSON object per line) — efficient, easily streamable
        fs.appendFileSync(filename, JSON.stringify(entry) + '\n', 'utf-8');

        // Clean old logs (async, không blocking)
        this.cleanOldLogs();
    }

    private static getTodayFilename(): string {
        const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
        return path.join(this.LOG_DIR, `triage-${date}.jsonl`);
    }

    private static cleanOldLogs(): void {
        try {
            if (!fs.existsSync(this.LOG_DIR)) return;
            const files   = fs.readdirSync(this.LOG_DIR).filter(f => f.endsWith('.jsonl'));
            const cutoff  = Date.now() - this.MAX_DAYS * 24 * 60 * 60 * 1000;
            files.forEach(file => {
                const filePath = path.join(this.LOG_DIR, file);
                const mtime    = fs.statSync(filePath).mtimeMs;
                if (mtime < cutoff) {
                    fs.unlinkSync(filePath);
                }
            });
        } catch {
            // Silent — cleanup failure không ảnh hưởng pipeline
        }
    }

    /**
     * Tính tuổi group để log (không log exact age — privacy)
     */
    static getAgeGroup(age?: number | null): string {
        if (age === undefined || age === null) return 'unknown';
        if (age < 0.25)  return 'infant (<3m)';
        if (age < 2)     return 'toddler (<2y)';
        if (age < 12)    return 'child';
        if (age < 18)    return 'teen';
        if (age < 65)    return 'adult';
        return 'elderly (65+)';
    }

    /**
     * Hash cơ bản để che PII (không phải cryptographic hash)
     * Production: dùng SHA256 + salt
     */
    static hashUserId(userId: string): string {
        let hash = 0;
        for (let i = 0; i < userId.length; i++) {
            hash = ((hash << 5) - hash) + userId.charCodeAt(i);
            hash |= 0;
        }
        return `u_${Math.abs(hash).toString(16)}`;
    }
}

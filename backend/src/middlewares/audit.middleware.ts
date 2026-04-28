/**
 * API Access Audit Middleware
 * ─────────────────────────────────────────────────────────────────────────────
 * Ghi lại mọi API call: ai làm gì, lúc nào, từ đâu.
 *
 * Tại sao cần:
 *   - Bệnh viện / partner hỏi "ai đã xem hồ sơ bệnh nhân X lúc 3 giờ sáng?"
 *   - HIPAA-lite yêu cầu access log cho PHI (Protected Health Information)
 *   - Detect bất thường: 1 user query 1000 hồ sơ trong 1 phút
 *
 * Thiết kế (copy pattern từ triage-audit.service.ts):
 *   - Ghi JSONL file (1 JSON / dòng) → dễ parse, dễ ship lên CloudWatch
 *   - Fire-and-forget: KHÔNG bao giờ làm chậm API response
 *   - Không log request body (chứa PHI như triệu chứng, thuốc)
 *   - Normalize path: /api/user/cm123abc → /api/user/:id (tránh log PII trong URL)
 *   - Rotate log mỗi ngày, giữ 30 ngày
 */

import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware.js';
import fs   from 'fs';
import path from 'path';

interface ApiAuditEntry {
    timestamp:  string;
    userId:     string;   // Hashed userId hoặc 'anonymous'
    method:     string;   // GET, POST, PATCH...
    path:       string;   // Normalized path (không có ID)
    status:     number;   // HTTP status code
    ip:         string;
    durationMs: number;
}

const LOG_DIR  = path.join(process.cwd(), 'logs', 'api-access');
const MAX_DAYS = 30;

/** /api/user/cm3xz9abc123... → /api/user/:id */
function normalizePath(p: string): string {
    return p
        .replace(/\/c[a-z0-9]{20,}/g, '/:cuid') // Prisma cuid
        .replace(/\/[0-9a-f]{24,}/g,  '/:hex')  // Mongo-style hex id
        .replace(/\/\d+/g,            '/:n');    // Numeric ID
}

/** Hash nhanh userId (không phải crypto — chỉ để tránh log plaintext ID) */
function hashId(id: string): string {
    let h = 0;
    for (let i = 0; i < id.length; i++) {
        h = ((h << 5) - h) + id.charCodeAt(i);
        h |= 0;
    }
    return `u_${Math.abs(h).toString(16)}`;
}

function getTodayFile(): string {
    const date = new Date().toISOString().split('T')[0];
    return path.join(LOG_DIR, `access-${date}.jsonl`);
}

function writeLog(entry: ApiAuditEntry): void {
    try {
        if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });
        fs.appendFileSync(getTodayFile(), JSON.stringify(entry) + '\n', 'utf-8');
        cleanOldLogs();
    } catch {
        // Silent — audit failure KHÔNG được crash API
    }
}

function cleanOldLogs(): void {
    try {
        if (!fs.existsSync(LOG_DIR)) return;
        const cutoff = Date.now() - MAX_DAYS * 86_400_000;
        fs.readdirSync(LOG_DIR)
          .filter(f => f.endsWith('.jsonl'))
          .forEach(f => {
              const fp = path.join(LOG_DIR, f);
              if (fs.statSync(fp).mtimeMs < cutoff) fs.unlinkSync(fp);
          });
    } catch { /* silent */ }
}

/**
 * auditMiddleware — đăng ký GLOBAL (trước routes).
 * Chỉ ghi log sau khi response finish → không ảnh hưởng latency.
 */
export const auditMiddleware = (req: AuthRequest, res: Response, next: NextFunction): void => {
    const start = Date.now();

    res.on('finish', () => {
        // Bỏ qua health check và static
        if (req.path === '/' || req.path === '/health') return;

        const entry: ApiAuditEntry = {
            timestamp:  new Date().toISOString(),
            userId:     req.user?.id ? hashId(req.user.id) : 'anonymous',
            method:     req.method,
            path:       normalizePath(req.path),
            status:     res.statusCode,
            ip:         (req.headers['x-forwarded-for'] as string)?.split(',')[0] ?? req.ip ?? 'unknown',
            durationMs: Date.now() - start,
        };

        writeLog(entry);
    });

    next();
};

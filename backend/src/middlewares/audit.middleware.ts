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
 * Thiết kế:
 *   - Ghi JSONL file (1 JSON / dòng) → dễ parse, dễ ship lên CloudWatch
 *   - Fire-and-forget THỰC SỰ: dùng fs.appendFile ASYNC (không block event loop)
 *   - Không log request body (chứa PHI như triệu chứng, thuốc)
 *   - Normalize path: /api/user/cm123abc → /api/user/:id (tránh log PII trong URL)
 *   - cleanOldLogs chỉ chạy 1 lần/ngày (không chạy mỗi request)
 *   - Rotate log mỗi ngày, giữ 30 ngày
 *
 * ⚠️  Giới hạn môi trường production (Render):
 *   Render dùng ephemeral disk — logs bị xóa mỗi lần redeploy.
 *   Để persist: ship log lên CloudWatch / Datadog / Logtail bằng cách
 *   thay writeLog() gọi HTTP sink thay vì fs.appendFile.
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

/**
 * Normalize path — loại bỏ tất cả dạng ID khỏi URL.
 * Thứ tự quan trọng: UUID trước, rồi cuid, rồi hex, rồi số.
 *
 * Ví dụ:
 *   /api/user/550e8400-e29b-41d4-a716-446655440000 → /api/user/:uuid
 *   /api/user/cm3xz9abc123efgh456ijkl              → /api/user/:cuid
 *   /api/admin/users/507f1f77bcf86cd799439011       → /api/admin/users/:hex
 *   /api/medicines/42                              → /api/medicines/:n
 */
function normalizePath(p: string): string {
    return p
        // UUID: 8-4-4-4-12 hex digits với dấu gạch ngang
        .replace(/\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '/:uuid')
        // Prisma CUID: bắt đầu bằng c, 24+ ký tự alphanumeric
        .replace(/\/c[a-z0-9]{20,}/g, '/:cuid')
        // Hex ID dài (MongoDB-style): 24+ ký tự hex
        .replace(/\/[0-9a-f]{24,}/gi, '/:hex')
        // Numeric ID
        .replace(/\/\d+/g, '/:n');
}

/** Hash nhanh userId — chỉ để tránh log plaintext ID.
 *  Không phải cryptographic hash. Có thể collision nhưng chấp nhận được
 *  vì mục đích chỉ là obfuscation, không phải unique key. */
function hashId(id: string): string {
    let h = 0;
    for (let i = 0; i < id.length; i++) {
        h = ((h << 5) - h) + id.charCodeAt(i);
        h |= 0;
    }
    return `u_${Math.abs(h).toString(16)}`;
}

function getTodayFile(): string {
    const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    return path.join(LOG_DIR, `access-${date}.jsonl`);
}

/**
 * Ghi log ASYNC — không block event loop.
 * fs.appendFile callback → bất đồng bộ hoàn toàn.
 */
function writeLog(entry: ApiAuditEntry): void {
    try {
        if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });
    } catch { return; } // Không tạo được thư mục → bỏ qua

    const line = JSON.stringify(entry) + '\n';
    // ASYNC: không dùng appendFileSync để tránh block event loop
    fs.appendFile(getTodayFile(), line, 'utf-8', (err) => {
        if (err) {
            // Chỉ warn — audit failure KHÔNG được crash API
            console.warn('[Audit] Write failed (non-critical):', err.message);
        }
    });
}

// ─── cleanOldLogs: chỉ chạy 1 lần/ngày, không chạy mỗi request ──────────────
let lastCleanDate = '';

function maybeCleanOldLogs(): void {
    const today = new Date().toISOString().split('T')[0];
    if (lastCleanDate === today) return; // Đã clean hôm nay rồi
    lastCleanDate = today;

    // Chạy async để không block
    setImmediate(() => {
        try {
            if (!fs.existsSync(LOG_DIR)) return;
            const cutoff = Date.now() - MAX_DAYS * 86_400_000;
            fs.readdirSync(LOG_DIR)
              .filter(f => f.endsWith('.jsonl'))
              .forEach(f => {
                  const fp = path.join(LOG_DIR, f);
                  try {
                      if (fs.statSync(fp).mtimeMs < cutoff) fs.unlinkSync(fp);
                  } catch { /* bỏ qua lỗi từng file */ }
              });
        } catch { /* silent — cleanup failure không ảnh hưởng API */ }
    });
}

/**
 * auditMiddleware — đăng ký GLOBAL (trước routes).
 * Ghi log sau khi response finish → không ảnh hưởng latency client.
 */
export const auditMiddleware = (req: AuthRequest, res: Response, next: NextFunction): void => {
    const start = Date.now();

    res.on('finish', () => {
        // Bỏ qua health check và root (không cần track)
        if (req.path === '/' || req.path === '/health') return;

        const entry: ApiAuditEntry = {
            timestamp:  new Date().toISOString(),
            userId:     req.user?.id ? hashId(req.user.id) : 'anonymous',
            method:     req.method,
            path:       normalizePath(req.path),
            status:     res.statusCode,
            // X-Forwarded-For: lấy IP thật khi đứng sau reverse proxy (Render/nginx)
            ip: (req.headers['x-forwarded-for'] as string | undefined)
                    ?.split(',')[0]?.trim()
                ?? req.socket?.remoteAddress
                ?? 'unknown',
            durationMs: Date.now() - start,
        };

        writeLog(entry);
        maybeCleanOldLogs(); // Chỉ thực sự clean 1 lần/ngày
    });

    next();
};

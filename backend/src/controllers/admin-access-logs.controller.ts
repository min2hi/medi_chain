/**
 * GET /api/admin/access-logs
 * ─────────────────────────────────────────────────────────────────────────────
 * Đọc API Access Audit Log và trả về cho Admin Portal.
 * Chỉ ADMIN mới gọi được (protected bởi authMiddleware + requireAdmin).
 *
 * Query params:
 *   ?date=2026-04-28   → log ngày cụ thể (mặc định: hôm nay)
 *   ?method=GET        → lọc theo HTTP method
 *   ?status=403        → lọc theo status code (phải là số nguyên hợp lệ)
 *   ?limit=100         → tối đa số dòng trả về (mặc định 200, tối đa 500)
 *
 * Response:
 *   { success, data: { date, stats (tổng cả ngày), entries (đã filter+limit) } }
 *
 * Lưu ý thiết kế:
 *   - stats được tính từ TOÀN BỘ log của ngày (trước filter/limit)
 *     → admin thấy được bức tranh tổng ngày, không bị mislead bởi filter
 *   - entries là subset đã filter+limit (mới nhất trước)
 */

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import fs   from 'fs';
import path from 'path';

const LOG_DIR = path.join(process.cwd(), 'logs', 'api-access');

interface LogEntry {
    timestamp:  string;
    userId:     string;
    method:     string;
    path:       string;
    status:     number;
    ip:         string;
    durationMs: number;
}

/** Tính stats từ danh sách entries đầy đủ (không bị ảnh hưởng bởi filter/limit) */
function computeStats(all: LogEntry[]) {
    return {
        total:     all.length,
        errors4xx: all.filter(e => e.status >= 400 && e.status < 500).length,
        errors5xx: all.filter(e => e.status >= 500).length,
        avgMs:     all.length > 0
            ? Math.round(all.reduce((s, e) => s + e.durationMs, 0) / all.length)
            : 0,
    };
}

export const getAccessLogs = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        // ── Params ──────────────────────────────────────────────────────────
        const dateParam = typeof req.query['date'] === 'string'
            ? req.query['date']
            : new Date().toISOString().split('T')[0];

        const methodParam = typeof req.query['method'] === 'string'
            ? req.query['method'].toUpperCase()
            : null;

        // Validate status là số nguyên hợp lệ (tránh NaN từ parseInt)
        let statusParam: number | null = null;
        if (typeof req.query['status'] === 'string') {
            const parsed = parseInt(req.query['status'], 10);
            if (isNaN(parsed) || parsed < 100 || parsed > 599) {
                res.status(400).json({ success: false, message: 'status phải là số HTTP hợp lệ (100-599)' });
                return;
            }
            statusParam = parsed;
        }

        const limitRaw = typeof req.query['limit'] === 'string' ? parseInt(req.query['limit'], 10) : 200;
        const limit = Math.min(500, isNaN(limitRaw) ? 200 : limitRaw);

        // Validate date format YYYY-MM-DD
        if (!/^\d{4}-\d{2}-\d{2}$/.test(dateParam)) {
            res.status(400).json({ success: false, message: 'date phải có dạng YYYY-MM-DD' });
            return;
        }

        // ── Đọc file ─────────────────────────────────────────────────────────
        const filePath = path.join(LOG_DIR, `access-${dateParam}.jsonl`);

        if (!fs.existsSync(filePath)) {
            res.json({
                success: true,
                data: {
                    date: dateParam,
                    // Trả về stats rỗng với đầy đủ fields (tránh null trong Flutter)
                    stats: { total: 0, errors4xx: 0, errors5xx: 0, avgMs: 0 },
                    entries: [],
                },
                message: `Không có log nào cho ngày ${dateParam}`,
            });
            return;
        }

        const raw = fs.readFileSync(filePath, 'utf-8');
        const allEntries: LogEntry[] = raw
            .split('\n')
            .filter(Boolean)
            .map(line => {
                try { return JSON.parse(line) as LogEntry; }
                catch { return null; }
            })
            .filter((e): e is LogEntry => e !== null);

        // ── Stats từ TOÀN BỘ log ngày (trước filter) ─────────────────────────
        // QUAN TRỌNG: tính stats trước khi filter/limit
        // → admin thấy bức tranh cả ngày, không bị mislead bởi filter đang active
        const stats = computeStats(allEntries);

        // ── Lọc theo filter ───────────────────────────────────────────────────
        let filtered = allEntries;
        if (methodParam) filtered = filtered.filter(e => e.method === methodParam);
        if (statusParam) filtered = filtered.filter(e => e.status === statusParam);

        // Trả về mới nhất trước, giới hạn limit
        const entries = filtered.reverse().slice(0, limit);

        res.json({ success: true, data: { date: dateParam, stats, entries } });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Không thể đọc access log' });
    }
};

/**
 * GET /api/admin/access-logs/dates
 * Trả về danh sách ngày có log (để admin chọn ngày trong UI).
 */
export const getAvailableLogDates = (_req: AuthRequest, res: Response): void => {
    try {
        if (!fs.existsSync(LOG_DIR)) {
            res.json({ success: true, data: [] });
            return;
        }

        const dates = fs.readdirSync(LOG_DIR)
            .filter(f => f.startsWith('access-') && f.endsWith('.jsonl'))
            .map(f => f.replace('access-', '').replace('.jsonl', ''))
            .sort()
            .reverse(); // Mới nhất trước

        res.json({ success: true, data: dates });
    } catch {
        res.status(500).json({ success: false, message: 'Không thể đọc danh sách log' });
    }
};

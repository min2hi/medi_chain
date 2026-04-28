/**
 * GET /api/admin/access-logs
 * ─────────────────────────────────────────────────────────────────────────────
 * Đọc API Access Audit Log và trả về cho Admin Portal.
 * Chỉ ADMIN mới gọi được (protected bởi authMiddleware + requireAdmin).
 *
 * Query params:
 *   ?date=2026-04-28   → log ngày cụ thể (mặc định: hôm nay)
 *   ?method=GET        → lọc theo HTTP method
 *   ?status=403        → lọc theo status code
 *   ?limit=100         → tối đa số dòng trả về (mặc định 200)
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

export const getAccessLogs = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        // ── Params ──────────────────────────────────────────────────────────
        const dateParam   = typeof req.query['date']   === 'string' ? req.query['date']   : new Date().toISOString().split('T')[0];
        const methodParam = typeof req.query['method'] === 'string' ? req.query['method'].toUpperCase() : null;
        const statusParam = typeof req.query['status'] === 'string' ? parseInt(req.query['status'], 10)  : null;
        const limit       = Math.min(500, parseInt(typeof req.query['limit'] === 'string' ? req.query['limit'] : '200', 10) || 200);

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
                data: { date: dateParam, total: 0, entries: [] },
                message: `Không có log nào cho ngày ${dateParam}`,
            });
            return;
        }

        const raw = fs.readFileSync(filePath, 'utf-8');
        let entries: LogEntry[] = raw
            .split('\n')
            .filter(Boolean)
            .map(line => {
                try { return JSON.parse(line) as LogEntry; }
                catch { return null; }
            })
            .filter((e): e is LogEntry => e !== null);

        // ── Lọc ──────────────────────────────────────────────────────────────
        if (methodParam) entries = entries.filter(e => e.method === methodParam);
        if (statusParam) entries = entries.filter(e => e.status === statusParam);

        // Trả về mới nhất trước, giới hạn limit
        entries = entries.reverse().slice(0, limit);

        // ── Stats tổng hợp ────────────────────────────────────────────────────
        const stats = {
            total:      entries.length,
            errors4xx:  entries.filter(e => e.status >= 400 && e.status < 500).length,
            errors5xx:  entries.filter(e => e.status >= 500).length,
            avgMs:      entries.length > 0
                ? Math.round(entries.reduce((s, e) => s + e.durationMs, 0) / entries.length)
                : 0,
        };

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

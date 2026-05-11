/**
 * Admin Stats Controller
 * ─────────────────────────────────────────────────────────────────────────────
 * GET /api/admin/stats — Dashboard KPIs cho Admin Portal.
 *
 * Pattern: AWS CloudWatch / Datadog "Service Health" summary widget.
 * All queries chạy song song (Promise.all) — response < 50ms trên DB warm.
 *
 * Cache: 60s TTL in-memory để tránh spam DB khi nhiều admin reload.
 * Invalidate tự động sau 60s, hoặc manual khi có write operation quan trọng.
 */

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { ClinicalRulesEngine } from '../services/clinical-rules.engine.js';

// ─── 60s In-memory cache (single-instance) ────────────────────────────────────
// Khi scale multi-instance → swap sang Redis, logic không đổi.
let statsCache: { data: AdminStats; expiredAt: number } | null = null;
const CACHE_TTL_MS = 60_000; // 60 giây

interface AdminStats {
    users: {
        total:    number;
        admins:   number;
        doctors:  number;
        patients: number;
    };
    system: {
        pendingReview:   number;
        activeKeywords:  number;
        activeCombos:    number;
    };
    activity: {
        aiQueriesLast24h:     number;
        blockedAlertsLast24h: number;
    };
    cache: {
        hitRate: string;
    };
    fetchedAt: string;
}

/**
 * GET /api/admin/stats
 * Trả về dashboard KPIs cho Admin Portal.
 * Protected: authMiddleware + requireAdmin (đăng ký trong route file).
 */
export const getAdminStats = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        // ── Cache hit ────────────────────────────────────────────────────────
        if (statsCache && Date.now() < statsCache.expiredAt) {
            res.json({ success: true, data: statsCache.data, cached: true });
            return;
        }

        // ── Parallel queries (Promise.all — không sequential) ─────────────────
        const since24h = new Date(Date.now() - 24 * 60 * 60 * 1000);

        const [
            totalUsers,
            adminCount,
            doctorCount,
            pendingReview,
            activeKeywords,
            activeCombos,
            aiQueriesLast24h,
            // blockedAlerts: đếm AIMessage có safetyCheckResult chứa criticalAlerts > 0
            // Dùng raw count trên JSON field — Prisma chưa support JSON array length natively
            allRecentMessages,
        ] = await Promise.all([
            prisma.user.count(),
            prisma.user.count({ where: { role: 'ADMIN' } }),
            prisma.user.count({ where: { role: 'DOCTOR' } }),
            prisma.safetyKeyword.count({ where: { reviewStatus: 'PENDING' } }),
            prisma.safetyKeyword.count({ where: { isActive: true } }),
            prisma.comboRule.count({ where: { isActive: true } }),
            prisma.aIMessage.count({
                where: { role: 'USER', createdAt: { gte: since24h } },
            }),
            // Lấy safetyCheckResult của các AI response trong 24h để đếm blocked
            prisma.aIMessage.findMany({
                where: {
                    role:      'ASSISTANT',
                    createdAt: { gte: since24h },
                    safetyCheckResult: { not: null },
                },
                select: { safetyCheckResult: true },
            }),
        ]);

        // Đếm blocked alerts từ safetyCheckResult JSON
        const blockedAlertsLast24h = allRecentMessages.reduce((count, msg) => {
            try {
                const parsed = JSON.parse(msg.safetyCheckResult as string);
                return count + (Array.isArray(parsed.criticalAlerts) && parsed.criticalAlerts.length > 0 ? 1 : 0);
            } catch {
                return count;
            }
        }, 0);

        // Cache stats từ ClinicalRulesEngine
        const cacheStats = ClinicalRulesEngine.getCacheStats();

        const data: AdminStats = {
            users: {
                total:    totalUsers,
                admins:   adminCount,
                doctors:  doctorCount,
                patients: totalUsers - adminCount - doctorCount,
            },
            system: {
                pendingReview,
                activeKeywords,
                activeCombos,
            },
            activity: {
                aiQueriesLast24h,
                blockedAlertsLast24h,
            },
            cache: {
                hitRate: cacheStats.hitRate,
            },
            fetchedAt: new Date().toISOString(),
        };

        // ── Cache kết quả ─────────────────────────────────────────────────────
        statsCache = { data, expiredAt: Date.now() + CACHE_TTL_MS };

        res.json({ success: true, data, cached: false });
    } catch (err) {
        res.status(500).json({
            success:   false,
            message:   'Không thể lấy admin stats',
            errorCode: 'ADMIN_STATS_ERROR',
        });
    }
};

/** Invalidate stats cache (gọi sau write operations quan trọng nếu cần) */
export const invalidateStatsCache = (): void => {
    statsCache = null;
};

/**
 * ClinicalRules Admin Controller
 * â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 * Pattern: Ada Health Admin Portal REST API style
 * Response: { success, data? } | { success, message }
 * Business logic: KHÃ”NG cÃ³ á»Ÿ Ä‘Ã¢y â€” delegate sang Prisma + ClinicalRulesEngine
 */

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { ClinicalRulesEngine } from '../services/clinical-rules.engine.js';
import prisma from '../config/prisma.js';

// Helper: normalize query param (Express can return string | string[])
const qStr = (v: unknown, fallback = ''): string =>
    Array.isArray(v) ? String(v[0] ?? fallback) : String(v ?? fallback);

// â”€â”€â”€ SAFETY KEYWORDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/** GET /api/admin/clinical-rules/keywords */
export const listKeywords = async (req: AuthRequest, res: Response) => {
    try {
        const { groupId, isActive, language } = req.query;
        const lang = qStr(language, 'vi');

        const keywords = await prisma.safetyKeyword.findMany({
            where: {
                ...(groupId  ? { groupId: qStr(groupId) }   : {}),
                ...(isActive !== undefined ? { isActive: isActive === 'true' } : {}),
                language: lang,
            },
            orderBy: [{ groupId: 'asc' }, { keyword: 'asc' }],
        });

        res.json({ success: true, data: keywords, total: keywords.length });
    } catch (error) {
        const message = error instanceof Error ? error.message : 'Loi server';
        res.status(500).json({ success: false, message });
    }
};

/** POST /api/admin/clinical-rules/keywords â€” Tao keyword moi (isActive=false) */
export const createKeyword = async (req: AuthRequest, res: Response) => {
    try {
        const { groupId, groupLabel, keyword, language = 'vi', guidelineRef, changeNote } = req.body as Record<string, string>;

        if (!groupId || !groupLabel || !keyword) {
            return res.status(400).json({
                success: false,
                message: 'Thieu truong bat buoc: groupId, groupLabel, keyword',
            });
        }

        const keywordNorm = keyword
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/\u0111/g, 'd').replace(/\u0110/g, 'D');

        const created = await prisma.safetyKeyword.create({
            data: {
                groupId,
                groupLabel,
                keyword:      keyword.toLowerCase(),
                keywordNorm,
                language:     language || 'vi',
                guidelineRef: guidelineRef || null,
                isActive:     false,
                createdBy:    req.user!.id,
                changeNote:   changeNote || null,
            },
        });

        res.status(201).json({
            success: true,
            data:    created,
            message: `Keyword "${keyword}" da tao. Can ADMIN activate truoc khi co hieu luc.`,
        });
    } catch (error) {
        const message = error instanceof Error ? error.message : 'Loi server';
        if (message.includes('Unique')) {
            return res.status(409).json({ success: false, message: 'Keyword nay da ton tai trong group.' });
        }
        res.status(400).json({ success: false, message });
    }
};

/** PATCH /api/admin/clinical-rules/keywords/:id */
export const updateKeyword = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params['id'] as string);
        const { keyword, groupLabel, guidelineRef, changeNote } = req.body as Record<string, string>;

        const updateData: Record<string, unknown> = { changeNote: changeNote || null };
        if (keyword) {
            updateData.keyword     = keyword.toLowerCase();
            updateData.keywordNorm = keyword.toLowerCase()
                .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
                .replace(/\u0111/g, 'd').replace(/\u0110/g, 'D');
        }
        if (groupLabel)   updateData.groupLabel   = groupLabel;
        if (guidelineRef) updateData.guidelineRef = guidelineRef;

        const updated = await prisma.safetyKeyword.update({ where: { id }, data: updateData });
        ClinicalRulesEngine.invalidateCache();

        res.json({ success: true, data: updated, message: 'Da cap nhat keyword va invalidate cache.' });
    } catch (error) {
        const message = error instanceof Error ? error.message : 'Loi server';
        const status  = message.includes('Record to update not found') ? 404 : 400;
        res.status(status).json({ success: false, message });
    }
};

/** PATCH /api/admin/clinical-rules/keywords/:id/activate â€” Step 2: activate */
export const activateKeyword = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params['id'] as string);
        const updated = await prisma.safetyKeyword.update({
            where: { id },
            data:  { isActive: true, activatedBy: req.user!.id, activatedAt: new Date() },
        });
        ClinicalRulesEngine.invalidateCache();
        res.json({ success: true, data: updated, message: `Keyword "${updated.keyword}" da active. Cache invalidated.` });
    } catch (error) {
        const message = error instanceof Error ? error.message : 'Loi server';
        res.status(400).json({ success: false, message });
    }
};

/** PATCH /api/admin/clinical-rules/keywords/:id/deactivate */
export const deactivateKeyword = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params['id'] as string);
        const { changeNote } = req.body as Record<string, string>;
        const updated = await prisma.safetyKeyword.update({
            where: { id },
            data:  { isActive: false, changeNote: changeNote || 'Deactivated by admin' },
        });
        ClinicalRulesEngine.invalidateCache();
        res.json({ success: true, data: updated, message: `Keyword "${updated.keyword}" da deactivated.` });
    } catch (error) {
        const message = error instanceof Error ? error.message : 'Loi server';
        res.status(400).json({ success: false, message });
    }
};

// â”€â”€â”€ COMBO RULES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

export const listCombos = async (req: AuthRequest, res: Response) => {
    try {
        const { isActive } = req.query;
        const combos = await prisma.comboRule.findMany({
            where: isActive !== undefined ? { isActive: isActive === 'true' } : {},
            orderBy: { name: 'asc' },
        });
        res.json({ success: true, data: combos, total: combos.length });
    } catch (error) {
        res.status(500).json({ success: false, message: error instanceof Error ? error.message : 'Loi server' });
    }
};

export const createCombo = async (req: AuthRequest, res: Response) => {
    try {
        const { name, label, symptomGroups, minMatch = 2, guidelineRef, changeNote } = req.body;
        if (!name || !label || !symptomGroups) {
            return res.status(400).json({ success: false, message: 'Thieu truong bat buoc: name, label, symptomGroups' });
        }
        const created = await prisma.comboRule.create({
            data: {
                name, label, symptomGroups,
                minMatch:     Number(minMatch),
                guidelineRef: guidelineRef || null,
                isActive:     false,
                createdBy:    req.user!.id,
                changeNote:   changeNote || null,
            },
        });
        res.status(201).json({ success: true, data: created, message: 'Combo rule da tao. Can activate truoc khi co hieu luc.' });
    } catch (error) {
        res.status(400).json({ success: false, message: error instanceof Error ? error.message : 'Loi server' });
    }
};

export const activateCombo = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params['id'] as string);
        const updated = await prisma.comboRule.update({
            where: { id },
            data:  { isActive: true, activatedBy: req.user!.id, activatedAt: new Date() },
        });
        ClinicalRulesEngine.invalidateCache();
        res.json({ success: true, data: updated, message: 'Combo rule activated.' });
    } catch (error) {
        res.status(400).json({ success: false, message: error instanceof Error ? error.message : 'Loi server' });
    }
};

// â”€â”€â”€ CACHE MANAGEMENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

export const invalidateCache = async (req: AuthRequest, res: Response) => {
    try {
        ClinicalRulesEngine.invalidateCache();
        res.json({ success: true, message: 'Cache invalidated. Rules se reload tu DB <1 giay.' });
    } catch (error) {
        res.status(500).json({ success: false, message: error instanceof Error ? error.message : 'Loi server' });
    }
};

export const getCacheStats = async (req: AuthRequest, res: Response) => {
    try {
        const cacheStats    = ClinicalRulesEngine.getCacheStats();
        const totalKeywords = await prisma.safetyKeyword.count({ where: { isActive: true } });
        const totalCombos   = await prisma.comboRule.count({ where: { isActive: true } });
        const pendingReview = await prisma.safetyKeyword.count({ where: { isActive: false } });

        res.json({
            success: true,
            data: { cache: cacheStats, db: { activeKeywords: totalKeywords, activeCombos: totalCombos, pendingReview } },
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error instanceof Error ? error.message : 'Loi server' });
    }
};

export const getAuditLog = async (req: AuthRequest, res: Response) => {
    try {
        const limit   = Number(req.query.limit  ?? 50);
        const offset  = Number(req.query.offset ?? 0);
        const groupId = req.query.groupId ? qStr(req.query.groupId) : undefined;

        const keywords = await prisma.safetyKeyword.findMany({
            where:   groupId ? { groupId } : {},
            select:  {
                id: true, groupId: true, keyword: true, isActive: true,
                createdBy: true, createdAt: true,
                activatedBy: true, activatedAt: true,
                changeNote: true, versionTag: true, guidelineRef: true,
            },
            orderBy: { updatedAt: 'desc' },
            take:    limit,
            skip:    offset,
        });

        res.json({ success: true, data: keywords, total: keywords.length });
    } catch (error) {
        res.status(500).json({ success: false, message: error instanceof Error ? error.message : 'Loi server' });
    }
};

// --- PHASE 2: SEMANTIC DISCOVERY - Pending Review Queue ---

export const listPendingReview = async (req: AuthRequest, res: Response) => {
    try {
        const groupId = req.query.groupId ? String(req.query.groupId) : undefined;
        const page    = Math.max(1, parseInt(String(req.query.page  ?? '1')));
        const limit   = Math.min(50, parseInt(String(req.query.limit ?? '20')));
        const offset  = (page - 1) * limit;
        const { prisma: _p, ...rest } = { prisma: null };
        void rest;

        const [keywords, total] = await Promise.all([
            prisma.safetyKeyword.findMany({
                where: { reviewStatus: 'PENDING', discoveredBy: 'SEMANTIC_DISCOVERY', ...(groupId ? { groupId } : {}) },
                select: { id: true, keyword: true, groupId: true, groupLabel: true, similarityScore: true, sourceKeyword: { select: { keyword: true, groupId: true } }, changeNote: true, createdAt: true },
                orderBy: [{ similarityScore: 'desc' }, { createdAt: 'desc' }],
                take: limit, skip: offset,
            }),
            prisma.safetyKeyword.count({ where: { reviewStatus: 'PENDING', discoveredBy: 'SEMANTIC_DISCOVERY' } }),
        ]);

        res.json({ success: true, data: keywords, pagination: { page, limit, total, pages: Math.ceil(total / limit) } });
    } catch (error) {
        res.status(500).json({ success: false, message: error instanceof Error ? error.message : 'Server error' });
    }
};

export const approvePendingKeyword = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id));
        if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID khong hop le' });
        const kw = await prisma.safetyKeyword.findUnique({ where: { id } });
        if (!kw) return res.status(404).json({ success: false, message: 'Keyword khong ton tai' });
        if (kw.reviewStatus !== 'PENDING') return res.status(409).json({ success: false, message: `Da o trang thai: ${kw.reviewStatus}` });

        const { guidelineRef, changeNote } = req.body ?? {};
        const updated = await prisma.safetyKeyword.update({
            where: { id },
            data: { isActive: true, reviewStatus: 'ACTIVE', activatedBy: req.user?.id ?? 'admin', activatedAt: new Date(), guidelineRef: guidelineRef ?? kw.guidelineRef, changeNote: changeNote ?? `Approved from SEMANTIC_DISCOVERY queue` },
        });
        ClinicalRulesEngine.invalidateCache();
        res.json({ success: true, data: updated, message: `Keyword "${updated.keyword}" da ACTIVATE. Cache invalidate — rule live ngay.` });
    } catch (error) {
        res.status(500).json({ success: false, message: error instanceof Error ? error.message : 'Server error' });
    }
};

export const rejectPendingKeyword = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id));
        if (isNaN(id)) return res.status(400).json({ success: false, message: 'ID khong hop le' });
        const kw = await prisma.safetyKeyword.findUnique({ where: { id } });
        if (!kw) return res.status(404).json({ success: false, message: 'Keyword khong ton tai' });
        if (kw.reviewStatus !== 'PENDING') return res.status(409).json({ success: false, message: `Da o trang thai: ${kw.reviewStatus}` });

        const { changeNote } = req.body ?? {};
        const updated = await prisma.safetyKeyword.update({
            where: { id },
            data: { isActive: false, reviewStatus: 'REJECTED', changeNote: changeNote ?? 'Rejected by admin', activatedBy: req.user?.id ?? 'admin', activatedAt: new Date() },
        });
        res.json({ success: true, data: updated, message: `Keyword "${updated.keyword}" da bi REJECTED.` });
    } catch (error) {
        res.status(500).json({ success: false, message: error instanceof Error ? error.message : 'Server error' });
    }
};

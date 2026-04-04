/**
 * Recommendation Routes - MediChain
 */

import { Router } from 'express';
import { RecommendationController } from '../controllers/recommendation.controller.js';
import { authMiddleware, AuthRequest } from '../middlewares/auth.middleware.js';
import { Response } from 'express';
import { getDrugViContent } from '../services/drug-enrichment.service.js';
import prisma from '../config/prisma.js';

const router = Router();

// Tất cả routes đều yêu cầu authentication
router.use(authMiddleware);

/**
 * POST /api/recommendation/consult
 * Endpoint chính: Nhận triệu chứng → Engine ranking → AI giải thích
 * Thay thế /api/ai/consult cũ
 */
router.post('/consult', (req, res) =>
    RecommendationController.consult(req as AuthRequest, res as Response)
);

/**
 * POST /api/recommendation/feedback
 * User feedback về hiệu quả thuốc đã dùng (upsert - tạo mới hoặc cập nhật)
 * Body: { sessionId, drugId, rating (1-5), outcome, usedDays?, sideEffect?, note? }
 */
router.post('/feedback', (req, res) =>
    RecommendationController.submitFeedback(req as AuthRequest, res as Response)
);

/**
 * GET /api/recommendation/feedback?sessionId=&drugId=
 * Lấy feedback hiện tại của user cho 1 thuốc trong 1 session
 * Trả về null nếu chưa đánh giá lần nào
 */
router.get('/feedback', (req, res) =>
    RecommendationController.getFeedback(req as AuthRequest, res as Response)
);

/**
 * GET /api/recommendation/sessions
 * Lịch sử các phiên tư vấn của user
 * Query: ?page=1&limit=10
 */
router.get('/sessions', (req, res) =>
    RecommendationController.getSessions(req as AuthRequest, res as Response)
);

/**
 * GET /api/recommendation/sessions/:id
 * Chi tiết 1 phiên tư vấn
 */
router.get('/sessions/:id', (req, res) =>
    RecommendationController.getSessionDetail(req as AuthRequest, res as Response)
);

/**
 * GET /api/recommendation/drugs/:id
 * Lấy chi tiết thuốc + nội dung tiếng Việt (Lazy Enrichment)
 * Pattern: Cache-aside - Nếu chưa dịch thì gọi AI ngay lúc này, cache lại DB.
 */
router.get('/drugs/:id', async (req, res: Response) => {
    try {
        // Lấy thông tin cơ bản từ DB
        const drug = await prisma.drugCandidate.findUnique({
            where: { id: req.params.id },
            select: {
                id: true, name: true, genericName: true,
                ingredients: true, category: true,
                indications: true, contraindications: true,
                sideEffects: true, baseSafetyScore: true,
                notForPregnant: true, notForNursing: true,
                minAge: true, maxAge: true,
            }
        });

        if (!drug) {
            res.status(404).json({ success: false, error: 'Không tìm thấy thuốc' });
            return;
        }

        // Lazy Enrichment: Lấy nội dung tiếng Việt (cache hoặc sinh mới)
        const viContent = await getDrugViContent(req.params.id);

        res.json({
            success: true,
            data: {
                ...drug,
                // Nội dung tiếng Việt (AI-generated, cached)
                viSummary: viContent?.viSummary || null,
                viIndications: viContent?.viIndications || null,
                viWarnings: viContent?.viWarnings || null,
            }
        });
    } catch (err: any) {
        res.status(500).json({ success: false, error: err.message });
    }
});

export default router;

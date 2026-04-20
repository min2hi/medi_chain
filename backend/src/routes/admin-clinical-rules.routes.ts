/**
 * Admin: Clinical Rules Engine Routes
 * ─────────────────────────────────────────────────────────────────────────────
 * Tất cả routes đều protected bởi authMiddleware + requireAdmin.
 *
 * Design: API-first admin (Stripe/Twilio pattern)
 * → Không cần frontend riêng, dùng ngay qua Postman/curl
 * → Khi cần → mount UI vào /admin trong Next.js hiện tại
 */

import { Router } from 'express';
import { authMiddleware, requireAdmin } from '../middlewares/auth.middleware.js';
import {
    listKeywords,
    createKeyword,
    updateKeyword,
    activateKeyword,
    deactivateKeyword,
    listCombos,
    createCombo,
    activateCombo,
    invalidateCache,
    getCacheStats,
    getAuditLog,
    listPendingReview,
    approvePendingKeyword,
    rejectPendingKeyword,
} from '../controllers/admin-clinical-rules.controller.js';

const router = Router();

// Bảo vệ TẤT CẢ routes trong file này bởi auth + ADMIN role
router.use(authMiddleware, requireAdmin);

// ─── Safety Keywords ──────────────────────────────────────────────────────────
router.get   ('/keywords',                listKeywords);      // List + filter
router.post  ('/keywords',                createKeyword);     // Tạo (isActive=false)
router.patch ('/keywords/:id',            updateKeyword);     // Update text/guideline
router.patch ('/keywords/:id/activate',   activateKeyword);   // Step 2: activate
router.patch ('/keywords/:id/deactivate', deactivateKeyword); // Soft-disable

// ─── Combo Rules ──────────────────────────────────────────────────────────────
router.get   ('/combos',               listCombos);    // List combo rules
router.post  ('/combos',               createCombo);   // Tạo combo rule
router.patch ('/combos/:id/activate',  activateCombo); // Activate combo

// ─── Cache Management (Hot-reload) ───────────────────────────────────────────
router.post  ('/cache/invalidate', invalidateCache); // Force reload từ DB
router.get   ('/cache/stats',      getCacheStats);   // Cache hit rate + DB counts

// ─── Audit Log ────────────────────────────────────────────────────────────────
router.get   ('/audit-log', getAuditLog); // Who changed what when

// ─── Phase 2: Semantic Discovery — Pending Review Queue ───────────────────────
// Keyword được Layer 4 tự phát hiện → chờ Admin/Bác sĩ review
router.get   ('/pending-review',             listPendingReview);     // Xem hàng chờ
router.post  ('/pending-review/:id/approve', approvePendingKeyword); // Approve → live
router.post  ('/pending-review/:id/reject',  rejectPendingKeyword);  // Reject → archived

export default router;

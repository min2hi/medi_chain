/**
 * Admin Stats Routes
 * GET /api/admin/stats — Dashboard KPIs
 * Protected: authMiddleware + requireAdmin
 */

import { Router } from 'express';
import { authMiddleware, requireAdmin } from '../middlewares/auth.middleware.js';
import { getAdminStats } from '../controllers/admin-stats.controller.js';

const router = Router();

router.use(authMiddleware, requireAdmin);

router.get('/', getAdminStats);

export default router;

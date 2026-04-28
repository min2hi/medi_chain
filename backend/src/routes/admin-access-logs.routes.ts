/**
 * Admin: Access Logs Routes
 * GET /api/admin/access-logs        → Log ngày hôm nay (hoặc theo ?date=)
 * GET /api/admin/access-logs/dates  → Danh sách ngày có log
 *
 * Protected: authMiddleware + requireAdmin
 */

import { Router } from 'express';
import { authMiddleware, requireAdmin } from '../middlewares/auth.middleware.js';
import { getAccessLogs, getAvailableLogDates } from '../controllers/admin-access-logs.controller.js';

const router = Router();

router.use(authMiddleware, requireAdmin);

router.get('/',       getAccessLogs);        // ?date=YYYY-MM-DD &method= &status= &limit=
router.get('/dates',  getAvailableLogDates); // Danh sách ngày có log

export default router;

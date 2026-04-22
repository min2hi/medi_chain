/**
 * Admin: User Management Routes
 * ─────────────────────────────────────────────────────────────────────────────
 * Cho phép ADMIN xem danh sách user và cập nhật role.
 * Protected bởi authMiddleware + requireAdmin.
 */

import { Router } from 'express';
import { authMiddleware, requireAdmin } from '../middlewares/auth.middleware.js';
import { listUsers, updateUserRole } from '../controllers/admin-users.controller.js';

const router = Router();

// Bảo vệ tất cả routes bởi auth + ADMIN role
router.use(authMiddleware, requireAdmin);

// GET  /api/admin/users        — Danh sách tất cả users
// PATCH /api/admin/users/:id/role — Cập nhật role (PATIENT ↔ DOCTOR)
router.get  ('/',           listUsers);
router.patch('/:id/role',   updateUserRole);

export default router;

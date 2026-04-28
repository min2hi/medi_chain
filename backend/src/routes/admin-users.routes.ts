/**
 * Admin: User Management Routes
 * ─────────────────────────────────────────────────────────────────────────────
 * Cho phép ADMIN xem danh sách user và cập nhật role.
 * Protected bởi authMiddleware + requireAdmin.
 */

import { Router } from 'express';
import { authMiddleware, requireAdmin } from '../middlewares/auth.middleware.js';
import { listUsers, updateUserRole, verifyDoctorLicense } from '../controllers/admin-users.controller.js';

const router = Router();

// Bảo vệ tất cả routes bởi auth + ADMIN role
router.use(authMiddleware, requireAdmin);

// GET  /api/admin/users              — Danh sách tất cả users (kèm profile bác sĩ)
// PATCH /api/admin/users/:id/role    — Cập nhật role (USER ↔ DOCTOR ↔ ADMIN)
// PATCH /api/admin/users/:id/verify-license — Xác nhận chứng chỉ bác sĩ
router.get  ('/',                    listUsers);
router.patch('/:id/role',            updateUserRole);
router.patch('/:id/verify-license',  verifyDoctorLicense);

export default router;

// @ts-nocheck — File này là TEMPLATE (code mẫu), không được biên dịch trực tiếp.
// Copy sang backend/src/ và thay thế placeholder trước khi dùng.
/**
 * TEMPLATE: MediChain Route
 * ============================================================
 * HƯỚNG DẪN SỬ DỤNG:
 *   1. Copy file này → đổi tên thành `<tên>.routes.ts`
 *   2. Tìm-Thay import controller + tên functions cho phù hợp
 *   3. Đăng ký route mới trong `backend/src/index.ts`:
 *        app.use('/api/example', exampleRoutes);
 *   4. Xóa các comment hướng dẫn
 * ============================================================
 * NGUYÊN TẮC:
 *   ✅ authMiddleware PHẢI có trên mọi protected route
 *   ✅ Route definitions ngắn gọn — không có logic ở đây
 *   ✅ Đặt middleware theo thứ tự: auth → validation → controller
 *   ❌ KHÔNG có business logic trong route file
 * ============================================================
 */

import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware'; //* Đường dẫn chuẩn
import {
  createExample,
  getAllExamples,
  getExampleById,
  updateExample,
  deleteExample,
} from '../controllers/example.controller'; //* Đổi sang controller của bạn

const router = Router();

// ============================================================
// Routes — tất cả đều protected bởi authMiddleware
// ============================================================

// POST   /api/example          → Tạo mới
router.post('/', authMiddleware, createExample);

// GET    /api/example          → Lấy tất cả của user
router.get('/', authMiddleware, getAllExamples);

// GET    /api/example/:id      → Lấy theo ID
router.get('/:id', authMiddleware, getExampleById);

// PATCH  /api/example/:id      → Cập nhật (dùng PATCH thay vì PUT cho partial update)
router.patch('/:id', authMiddleware, updateExample);

// DELETE /api/example/:id      → Xóa
router.delete('/:id', authMiddleware, deleteExample);

//* Thêm routes đặc thù bên dưới nếu cần
//* Ví dụ: router.post('/:id/share', authMiddleware, shareExample);

export default router;

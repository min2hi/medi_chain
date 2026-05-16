import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

const router = Router();

// ─── Public Endpoints (no auth) ───────────────────────────────────────────────
// Webhook KHÔNG có authMiddleware — PayOS gọi trực tiếp từ server của họ.
// Security được đảm bảo bằng HMAC-SHA256 signature verification trong controller.
router.post('/webhook', PaymentController.handleWebhook);

// ─── Protected Endpoints (JWT required) ──────────────────────────────────────
router.use(authMiddleware);

// Patient: tạo đơn thanh toán
router.post('/create-order', PaymentController.createOrder);

// Patient: lịch sử thanh toán
router.get('/history', PaymentController.getHistory);

// Patient + Admin: kiểm tra trạng thái 1 đơn
router.get('/status/:orderCode', PaymentController.getStatus);

// Patient: lấy phí khám hiện tại
router.get('/settings/fee', PaymentController.getFee);

// Admin only: cập nhật phí khám
// Note: Middleware role check đơn giản — không cần tách AdminController riêng cho 1 endpoint
router.put('/settings/fee', (req, res, next) => {
  const user = (req as any).user;
  if (user?.role !== 'ADMIN') {
    return res.status(403).json({ success: false, message: 'Chỉ Admin mới có quyền thực hiện thao tác này' });
  }
  return next();
}, PaymentController.updateFee);

export default router;

import { Router } from 'express';
import { AIController } from '../controllers/ai.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { safetyInterceptor } from '../middlewares/safety-interceptor.middleware.js';

const router = Router();

// Chat với AI
// safetyInterceptor: fire-and-forget, không block response, báo về Admin queue
router.post('/chat', authMiddleware, safetyInterceptor, AIController.chat);

// Tư vấn thuốc
// safetyInterceptor tự động bảo vệ — không cần thêm logic vào service layer
router.post('/consult', authMiddleware, safetyInterceptor, AIController.consult);

// Lấy danh sách conversations
router.get('/conversations', authMiddleware, AIController.getConversations);

// Lấy messages trong conversation
router.get('/conversations/:id/messages', authMiddleware, AIController.getMessages);

// Xóa conversation
router.delete('/conversations/:id', authMiddleware, AIController.deleteConversation);

// Phân tích dữ liệu y tế
router.post('/analyze', authMiddleware, AIController.analyzeMedicalData);

export default router;

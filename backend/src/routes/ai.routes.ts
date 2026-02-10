import { Router } from 'express';
import { AIController } from '../controllers/ai.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

const router = Router();

// Chat với AI
router.post('/chat', authMiddleware, AIController.chat);

// Tư vấn thuốc (New)
router.post('/consult', authMiddleware, AIController.consult);

// Lấy danh sách conversations
router.get('/conversations', authMiddleware, AIController.getConversations);

// Lấy messages trong conversation
router.get('/conversations/:id/messages', authMiddleware, AIController.getMessages);

// Xóa conversation
router.delete('/conversations/:id', authMiddleware, AIController.deleteConversation);

// Phân tích dữ liệu y tế
router.post('/analyze', authMiddleware, AIController.analyzeMedicalData);

export default router;

import { Request, Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { AIService } from '../services/ai.service.js';

export class AIController {
    /**
     * POST /api/ai/chat
     * Chat với AI
     */
    static async chat(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const { message, conversationId } = req.body;

            if (!message) {
                return res.status(400).json({ success: false, message: 'Message is required' });
            }

            const result = await AIService.chat(userId, message, conversationId);
            res.json({ success: true, data: result });
        } catch (error: any) {
            res.status(500).json({ success: false, message: error.message });
        }
    }

    /**
     * GET /api/ai/conversations
     * Lấy danh sách conversations
     */
    static async getConversations(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const conversations = await AIService.getConversations(userId);
            res.json({ success: true, data: conversations });
        } catch (error: any) {
            res.status(500).json({ success: false, message: error.message });
        }
    }

    /**
     * GET /api/ai/conversations/:id/messages
     * Lấy messages trong conversation
     */
    static async getMessages(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const id = req.params.id as string;
            const messages = await AIService.getMessages(userId, id);
            res.json({ success: true, data: messages });
        } catch (error: any) {
            res.status(404).json({ success: false, message: error.message });
        }
    }

    /**
     * DELETE /api/ai/conversations/:id
     * Xóa conversation
     */
    static async deleteConversation(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const id = req.params.id as string;
            await AIService.deleteConversation(userId, id);
            res.json({ success: true, message: 'Conversation deleted' });
        } catch (error: any) {
            res.status(404).json({ success: false, message: error.message });
        }
    }

    /**
     * POST /api/ai/analyze
     * Phân tích dữ liệu y tế bằng AI
     */
    static async analyzeMedicalData(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const analysis = await AIService.analyzeMedicalData(userId);
            res.json({ success: true, data: { analysis } });
        } catch (error: any) {
            res.status(500).json({ success: false, message: error.message });
        }
    }

    /**
     * POST /api/ai/consult
     * Tư vấn thuốc dựa trên triệu chứng
     */
    static async consult(req: Request, res: Response) {
        console.log("POST /api/ai/consult - Request body:", req.body);
        try {
            const userId = (req as AuthRequest).user.id;
            const { symptoms } = req.body;
            console.log("UserID from token:", userId);

            if (!symptoms) {
                console.warn("Symptoms missing in request");
                return res.status(400).json({ success: false, message: 'Vui lòng mô tả triệu chứng' });
            }

            const result = await AIService.getMedicineRecommendation(userId, symptoms);
            console.log("Recommendation result generated successfully");
            res.json({ success: true, data: result });
        } catch (error: any) {
            console.error("Error in AIController.consult:", error);
            res.status(500).json({ success: false, message: error.message });
        }
    }
}

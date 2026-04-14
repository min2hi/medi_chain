import { Request, Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { AIService } from '../services/ai.service.js';

/**
 * Map error message (từ AIService) sang errorCode chuẩn để Frontend phân loại
 */
function resolveErrorCode(errorMessage: string): { code: string; statusCode: number } {
    if (errorMessage === 'AI_TIMEOUT')
        return { code: 'AI_TIMEOUT', statusCode: 504 };
    if (errorMessage === 'AI_RATE_LIMITED')
        return { code: 'AI_RATE_LIMITED', statusCode: 429 };
    if (errorMessage === 'AI_EMPTY_RESPONSE')
        return { code: 'AI_EMPTY_RESPONSE', statusCode: 502 };
    if (errorMessage === 'Conversation not found')
        return { code: 'CONVERSATION_NOT_FOUND', statusCode: 404 };
    if (errorMessage === 'GROQ_API_KEY is missing')
        return { code: 'SERVER_CONFIG_ERROR', statusCode: 500 };
    return { code: 'INTERNAL_ERROR', statusCode: 500 };
}

export class AIController {
    /**
     * POST /api/ai/chat
     * Chat với AI
     */
    static async chat(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const { message, conversationId } = req.body;

            if (!message || !message.trim()) {
                return res.status(400).json({
                    success: false,
                    errorCode: 'MISSING_MESSAGE',
                    message: 'Vui lòng nhập nội dung tin nhắn'
                });
            }

            const locale = (req.headers['accept-language'] || 'vi') as string;
            const result = await AIService.chat(userId, message.trim(), conversationId, locale);
            res.json({ success: true, data: result });
        } catch (error: any) {
            const { code, statusCode } = resolveErrorCode(error.message);
            console.error(`[AI Chat] Error [${code}]:`, error.message);
            res.status(statusCode).json({
                success: false,
                errorCode: code,
                message: error.message
            });
        }
    }

    /**
     * GET /api/ai/conversations
     * Lấy danh sách conversations
     */
    static async getConversations(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const type = req.query.type as any;
            const conversations = await AIService.getConversations(userId, type);
            res.json({ success: true, data: conversations });
        } catch (error: any) {
            res.status(500).json({ success: false, errorCode: 'INTERNAL_ERROR', message: error.message });
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
            const { code, statusCode } = resolveErrorCode(error.message);
            res.status(statusCode).json({ success: false, errorCode: code, message: error.message });
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
            res.status(404).json({ success: false, errorCode: 'NOT_FOUND', message: error.message });
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
            const { code, statusCode } = resolveErrorCode(error.message);
            res.status(statusCode).json({ success: false, errorCode: code, message: error.message });
        }
    }

    /**
     * POST /api/ai/consult
     * Tư vấn thuốc dựa trên triệu chứng
     */
    static async consult(req: Request, res: Response) {
        try {
            const userId = (req as AuthRequest).user.id;
            const { symptoms, conversationId } = req.body;

            if (!symptoms || !symptoms.trim()) {
                return res.status(400).json({
                    success: false,
                    errorCode: 'MISSING_SYMPTOMS',
                    message: 'Vui lòng mô tả triệu chứng'
                });
            }

            const locale = (req.headers['accept-language'] || 'vi') as string;
            const result = await AIService.getMedicineRecommendation(userId, symptoms.trim(), conversationId, locale);
            res.json({ success: true, data: result });
        } catch (error: any) {
            const { code, statusCode } = resolveErrorCode(error.message);
            console.error(`[AI Consult] Error [${code}]:`, error.message);
            res.status(statusCode).json({ success: false, errorCode: code, message: error.message });
        }
    }
}

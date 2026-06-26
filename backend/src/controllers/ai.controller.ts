import { Request, Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { AIService } from '../services/ai.service.js';

/**
 * Map error message (từ AIService) sang errorCode chuẩn để Frontend phân loại
 */
function resolveErrorCode(errorMessage: string): { code: string; statusCode: number; clientMessage: string } {
    const msg = errorMessage || '';
    let code = 'INTERNAL_ERROR';
    let statusCode = 500;
    let clientMessage = msg;

    if (msg === 'AI_TIMEOUT') {
        code = 'AI_TIMEOUT';
        statusCode = 504;
        clientMessage = 'AI phản hồi quá lâu, vui lòng thử lại sau.';
    } else if (msg === 'AI_RATE_LIMITED') {
        code = 'AI_RATE_LIMITED';
        statusCode = 429;
        clientMessage = 'Bạn đã gửi quá nhiều yêu cầu, vui lòng thử lại sau vài phút.';
    } else if (msg === 'AI_EMPTY_RESPONSE') {
        code = 'AI_EMPTY_RESPONSE';
        statusCode = 502;
        clientMessage = 'AI phản hồi rỗng, vui lòng thử lại.';
    } else if (msg === 'Conversation not found') {
        code = 'CONVERSATION_NOT_FOUND';
        statusCode = 404;
        clientMessage = 'Không tìm thấy cuộc hội thoại.';
    } else if (msg === 'GROQ_API_KEY is missing') {
        code = 'SERVER_CONFIG_ERROR';
        statusCode = 500;
        clientMessage = 'Thiếu cấu hình GROQ_API_KEY trên hệ thống.';
    } else if (
        msg.toLowerCase().includes('api key') || 
        msg.toLowerCase().includes('api_key') || 
        msg.toLowerCase().includes('leaked') ||
        msg.toLowerCase().includes('unauthorized') ||
        msg.toLowerCase().includes('401')
    ) {
        code = 'INVALID_API_KEY';
        statusCode = 401;
        clientMessage = 'API Key của hệ thống không hợp lệ, hết hạn hoặc đã bị rò rỉ. Vui lòng cập nhật GROQ_API_KEY / GEMINI_API_KEY trong file .env.';
    }

    return { code, statusCode, clientMessage };
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
            const { code, statusCode, clientMessage } = resolveErrorCode(error.message || '');
            console.error(`[AI Chat] Error [${code}]:`, error.message);
            res.status(statusCode).json({
                success: false,
                errorCode: code,
                message: clientMessage
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
            const { code, statusCode, clientMessage } = resolveErrorCode(error.message || '');
            res.status(statusCode).json({ success: false, errorCode: code, message: clientMessage });
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
            const { code, statusCode, clientMessage } = resolveErrorCode(error.message || '');
            res.status(statusCode).json({ success: false, errorCode: code, message: clientMessage });
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
            const { code, statusCode, clientMessage } = resolveErrorCode(error.message || '');
            console.error(`[AI Consult] Error [${code}]:`, error.message);
            res.status(statusCode).json({ success: false, errorCode: code, message: clientMessage });
        }
    }
}

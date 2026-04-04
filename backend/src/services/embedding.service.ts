import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

// ============================================================
// EMBEDDING SERVICE - với Retry + Exponential Backoff
// ============================================================
// Vấn đề: Gemini free tier giới hạn 1500 req/ngày và 15 req/phút.
// Khi bị rate limit (HTTP 429), nếu throw thẳng thì toàn bộ
// Recommendation Engine sẽ crash và người dùng không thấy gì.
//
// Giải pháp: Exponential Backoff Retry
// - Thử lại tối đa 3 lần
// - Lần 1 thất bại → chờ 2s → thử lại
// - Lần 2 thất bại → chờ 4s → thử lại  
// - Lần 3 thất bại → chờ 8s → thử lại
// - Nếu vẫn fail → throw (để tầng trên xử lý fallback)
// ============================================================

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Tạo vector embedding cho văn bản với retry tự động.
 */
export async function generateEmbedding(text: string): Promise<number[]> {
    const MAX_RETRIES = 3;
    const BASE_DELAY_MS = 2000; // 2 giây

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
        try {
            const model = genAI.getGenerativeModel({ model: 'gemini-embedding-001' });
            const result = await model.embedContent(text.replace(/\n/g, ' '));
            return result.embedding.values;

        } catch (error: any) {
            const isRateLimit = error?.status === 429 
                || error?.message?.includes('429')
                || error?.message?.includes('quota')
                || error?.message?.includes('rate limit');

            if (isRateLimit && attempt < MAX_RETRIES) {
                const delay = BASE_DELAY_MS * Math.pow(2, attempt - 1); // 2s, 4s, 8s
                console.warn(`[Embedding] Rate limit lần ${attempt}/${MAX_RETRIES}. Chờ ${delay}ms rồi thử lại...`);
                await sleep(delay);
                continue; // Thử lại
            }

            // Lỗi khác (không phải rate limit), hoặc đã hết retry
            console.error('[Embedding] Lỗi sau', attempt, 'lần thử:', error?.message || error);
            throw new Error(`Không thể tạo embedding: ${error?.message || 'Unknown error'}`);
        }
    }

    // Không bao giờ tới đây (TypeScript cần return)
    throw new Error('Embedding thất bại sau tất cả retry');
}

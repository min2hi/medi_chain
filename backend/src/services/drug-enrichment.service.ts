import prisma from '../config/prisma.js';
import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-lite' });

// ============================================================
// LAZY ENRICHMENT SERVICE - Optimized với 2 tầng Cache
// ============================================================
//
// TẦNG 1: In-Memory Cache (RAM của Node.js process)
//   → Lookup tốc độ 0ms (không cần gọi DB)
//   → TTL 30 phút (sau đó tự xóa, tránh stale data)
//   → Phù hợp cho thuốc được nhiều người xem cùng lúc
//
// TẦNG 2: PostgreSQL DB Cache (viSummary, viIndications, viWarnings)
//   → Lookup ~5-10ms (roundtrip DB)
//   → Persistent: Không mất khi restart server
//   → Đây là "nguồn sự thật" lâu dài
//
// NẾU cả 2 tầng đều miss → Gọi Gemini AI (~1-2s) → Lưu vào cả 2 tầng
//
// Rate Limiter (Sliding Window):
//   → Tối đa 10 lần gọi Gemini mỗi phút
//   → Nếu vượt quá → Trả về fallback tiếng Anh, không gọi AI
//   → Bảo vệ API quota Gemini (free tier: 15 req/phút)
// ============================================================

interface ViDrugContent {
    viSummary: string;
    viIndications: string;
    viWarnings: string;
}

// ─── TẦNG 1: In-Memory Cache với TTL ───
// Tại sao dùng Map thay vì object thường?
// Map có hiệu năng tốt hơn cho việc thêm/xóa/lookup động.
const memoryCache = new Map<string, {
    content: ViDrugContent;
    expiredAt: number;
}>();

const CACHE_TTL_MS = 30 * 60 * 1000; // 30 phút

function getFromMemCache(drugId: string): ViDrugContent | null {
    const cached = memoryCache.get(drugId);
    if (!cached) return null;
    if (Date.now() > cached.expiredAt) {
        memoryCache.delete(drugId); // Dọn rác entry hết hạn
        return null;
    }
    return cached.content;
}

function setToMemCache(drugId: string, content: ViDrugContent): void {
    memoryCache.set(drugId, {
        content,
        expiredAt: Date.now() + CACHE_TTL_MS,
    });
    // Tự động dọn rác nếu cache quá 500 entries → tránh memory leak
    if (memoryCache.size > 500) {
        const now = Date.now();
        for (const [key, val] of memoryCache.entries()) {
            if (now > val.expiredAt) memoryCache.delete(key);
        }
    }
}

// ─── Rate Limiter: Sliding Window Counter ───
// Lưu timestamp của mỗi lần gọi AI.
// Mỗi lần check: đếm số lần trong 60 giây gần nhất.
const geminiCallLog: number[] = [];
const MAX_CALLS_PER_MINUTE = 10; // Giới hạn an toàn (Gemini free: 15/phút)

function isRateLimited(): boolean {
    const oneMinuteAgo = Date.now() - 60_000;
    // Dọn entries cũ hơn 1 phút (sliding window)
    while (geminiCallLog.length > 0 && geminiCallLog[0] < oneMinuteAgo) {
        geminiCallLog.shift();
    }
    return geminiCallLog.length >= MAX_CALLS_PER_MINUTE;
}

function recordGeminiCall(): void {
    geminiCallLog.push(Date.now());
}

// ─── MAIN FUNCTION ───
/**
 * Lấy nội dung tiếng Việt của thuốc với 2 tầng cache + rate limiter.
 */
export async function getDrugViContent(drugId: string): Promise<ViDrugContent | null> {

    // ── CHECK TẦNG 1: In-Memory (0ms) ──
    const memHit = getFromMemCache(drugId);
    if (memHit) return memHit;

    // ── CHECK TẦNG 2: DB (~5-10ms) ──
    const existing = await prisma.$queryRaw<Array<{
        id: string;
        name: string;
        genericName: string;
        category: string;
        ingredients: string;
        indications: string;
        contraindications: string;
        sideEffects: string;
        viSummary: string | null;
        viIndications: string | null;
        viWarnings: string | null;
    }>>`
        SELECT id, name, "genericName", category, ingredients,
               indications, contraindications, "sideEffects",
               "viSummary", "viIndications", "viWarnings"
        FROM "DrugCandidate"
        WHERE id = ${drugId}
        LIMIT 1
    `;

    if (existing.length === 0) return null;
    const drug = existing[0];

    // DB Cache HIT
    if (drug.viSummary && !drug.viSummary.startsWith('Thuốc ')) {
        const content: ViDrugContent = {
            viSummary: drug.viSummary,
            viIndications: drug.viIndications || drug.indications,
            viWarnings: drug.viWarnings || drug.contraindications,
        };
        setToMemCache(drugId, content); // Warm up tầng 1 cho request sau
        return content;
    }

    // ── TẦNG 3: Gọi Gemini AI (1-2s) ──
    if (isRateLimited()) {
        // Trả về fallback thay vì báo lỗi → UX không bị gián đoạn
        return {
            viSummary: `${drug.genericName} - Thuốc OTC không cần kê đơn`,
            viIndications: drug.indications?.substring(0, 300) || 'Xem nhãn thuốc',
            viWarnings: drug.contraindications?.substring(0, 200) || 'Đọc kỹ hướng dẫn',
        };
    }

    try {
        recordGeminiCall();

        const prompt = `Bạn là dược sĩ. Đọc thông tin thuốc sau, trả lời JSON tiếng Việt ngắn gọn cho người dùng bình thường.

Tên: ${drug.name}
Hoạt chất: ${drug.genericName}
Nhóm: ${drug.category}
Công dụng: ${drug.indications?.substring(0, 600)}
Chống chỉ định: ${drug.contraindications?.substring(0, 400)}
Tác dụng phụ: ${drug.sideEffects?.substring(0, 400)}

Trả về JSON (không thêm text thừa):
{
  "viSummary": "Mô tả 1-2 câu thuốc này là gì và dùng để làm gì",
  "viIndications": "Công dụng 1; Công dụng 2; Công dụng 3",
  "viWarnings": "Lưu ý 1; Lưu ý 2; Lưu ý 3"
}`;

        const result = await model.generateContent(prompt);
        const text = result.response.text().trim();
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (!jsonMatch) throw new Error('Không parse được JSON từ Gemini');

        const parsed = JSON.parse(jsonMatch[0]) as ViDrugContent;

        // Lưu vào cả 2 tầng cache
        setToMemCache(drugId, parsed);
        prisma.$executeRawUnsafe(
            `UPDATE "DrugCandidate"
             SET "viSummary" = $1, "viIndications" = $2, "viWarnings" = $3, "updatedAt" = now()
             WHERE id = $4`,
            parsed.viSummary, parsed.viIndications, parsed.viWarnings, drugId
        ).catch(() => {}); // fire-and-forget, không block response

        return parsed;

    } catch {
        return {
            viSummary: `${drug.name} - ${drug.genericName}`,
            viIndications: drug.indications?.substring(0, 300) || '',
            viWarnings: drug.contraindications?.substring(0, 200) || '',
        };
    }
}

/**
 * Thống kê cache (dùng cho monitoring/debug khi cần)
 */
export function getCacheStats() {
    const now = Date.now();
    return {
        memoryCacheEntries: [...memoryCache.values()].filter(v => now < v.expiredAt).length,
        geminiCallsLastMinute: geminiCallLog.filter(t => t > now - 60_000).length,
        maxCallsPerMinute: MAX_CALLS_PER_MINUTE,
    };
}

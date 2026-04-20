/**
 * =============================================================
 * DISEASE PREDICTOR SERVICE - MediChain Phase 2
 * =============================================================
 *
 * Mục tiêu: Thêm "Disease Layer" trung gian vào pipeline,
 * giải quyết vấn đề cốt lõi: Triệu chứng → Bệnh → Thuốc
 * thay vì Triệu chứng → Thuốc trực tiếp (thiếu ngữ cảnh lâm sàng).
 *
 * ─── Kiến trúc 3 tầng ──────────────────────────────────────
 *  Tầng 1: Groq LLM (JSON mode) — Chính xác nhất
 *    → Prompt với danh sách bệnh hợp lệ + probability
 *    → Timeout 5s để không block main pipeline
 *
 *  Tầng 2: Keyword Mapping — Fallback nhanh, offline
 *    → Map từ khóa tiếng Việt phổ biến → bệnh
 *    → Luôn hoạt động dù Groq down hay rate limited
 *
 *  Tầng 3: Cache TTL 10 phút
 *    → Mỗi symptom string chỉ predict 1 lần/session
 *    → 0ms cho request trùng lặp
 *
 * ─── Output ────────────────────────────────────────────────
 *  PredictedDisease[] — mỗi bệnh có ATC codes tương ứng
 *  → ATC codes được dùng để tính evidenceScore trong scoring engine
 *  → Vitamin (ATC: A11) sẽ KHÔNG khớp với "sốt, đau đầu" (ATC: N02B)
 * =============================================================
 */

import type { PredictedDisease } from './recommendation/scoring.engine.js';

// ─── Groq Config ─────────────────────────────────────────────
const GROQ_URL   = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.3-70b-versatile';

// ─── TTL Cache ───────────────────────────────────────────────
const predictionCache = new Map<string, { result: PredictedDisease[]; expiredAt: number }>();
const CACHE_TTL_MS    = 10 * 60 * 1000; // 10 phút
const TIMEOUT_MS      = 5_000;           // 5s — không được block recommendation pipeline

// =============================================================
// DISEASE DATABASE — ATC codes per disease
// ATC (Anatomical Therapeutic Chemical) là chuẩn WHO.
// Drug's category → CATEGORY_TO_ATC (trong scoring.engine) → match tại đây.
// =============================================================
export const DISEASE_DATABASE: Record<string, { nameVi: string; atcCodes: string[] }> = {
    // ─── Hô hấp ────────────────────────────────────────────
    'common_cold':        { nameVi: 'Cảm lạnh thông thường',       atcCodes: ['R05', 'R01', 'N02B'] },
    'influenza':          { nameVi: 'Cúm / Cảm cúm',               atcCodes: ['N02B', 'R05', 'R01'] },
    'allergic_rhinitis':  { nameVi: 'Viêm mũi dị ứng',             atcCodes: ['R06A', 'R01A']       },
    'sore_throat':        { nameVi: 'Đau họng / Viêm họng',        atcCodes: ['R02', 'N02B']        },
    'cough':              { nameVi: 'Ho (không rõ nguyên nhân)',    atcCodes: ['R05C', 'R05D', 'R05'] },
    'nasal_congestion':   { nameVi: 'Nghẹt mũi / Sổ mũi',          atcCodes: ['R01A', 'R01B', 'R06A'] },
    // ─── Đau / Sốt ─────────────────────────────────────────
    'headache':           { nameVi: 'Đau đầu',                     atcCodes: ['N02B']               },
    'fever':              { nameVi: 'Sốt',                          atcCodes: ['N02B']               },
    'muscle_joint_pain':  { nameVi: 'Đau cơ / Đau khớp',           atcCodes: ['M01A', 'N02B']       },
    'toothache':          { nameVi: 'Đau răng',                     atcCodes: ['N02B', 'N01B']       },
    // ─── Tiêu hóa ──────────────────────────────────────────
    'gastroenteritis':    { nameVi: 'Viêm dạ dày ruột / Tiêu chảy', atcCodes: ['A07', 'A02']        },
    'acid_reflux':        { nameVi: 'Trào ngược dạ dày / Ợ chua',  atcCodes: ['A02A', 'A02B']       },
    'constipation':       { nameVi: 'Táo bón',                     atcCodes: ['A06']                },
    'nausea_vomiting':    { nameVi: 'Buồn nôn / Nôn mửa',          atcCodes: ['A04']                },
    'motion_sickness':    { nameVi: 'Say xe',                       atcCodes: ['A04', 'R06A']        },
    // ─── Da liễu ───────────────────────────────────────────
    'skin_fungal':        { nameVi: 'Nấm da / Nấm chân',           atcCodes: ['D01']                },
    'eczema_dermatitis':  { nameVi: 'Eczema / Viêm da dị ứng',     atcCodes: ['D07', 'D04']         },
    'minor_wound':        { nameVi: 'Vết thương nhỏ / Trầy xước',  atcCodes: ['D08', 'D06']         },
    'allergic_reaction':  { nameVi: 'Phản ứng dị ứng da',           atcCodes: ['R06A', 'D07']        },
    // ─── Mắt ───────────────────────────────────────────────
    'conjunctivitis':     { nameVi: 'Đau mắt đỏ / Viêm kết mạc',  atcCodes: ['S01']                },
    'eye_dryness':        { nameVi: 'Khô mắt',                     atcCodes: ['S01X', 'S01']        },
    // ─── Thần kinh / Giấc ngủ ──────────────────────────────
    'insomnia':           { nameVi: 'Mất ngủ / Khó ngủ',           atcCodes: ['N05C']               },
    // ─── Dinh dưỡng ────────────────────────────────────────
    'vitamin_deficiency': { nameVi: 'Thiếu vitamin / Khoáng chất', atcCodes: ['A11', 'B03', 'A12'] },
};

// =============================================================
// KEYWORD → DISEASE MAPPING (Tiếng Việt)
// Fallback khi Groq không khả dụng.
// Mỗi entry: { keywords, diseaseKeys, weight }
//   weight = confidence baseline khi 1 keyword khớp
//   Math.min(weight, weight * (0.6 + matchCount * 0.2)) tăng dần
// =============================================================
const KEYWORD_DISEASE_MAP: Array<{
    keywords: string[];
    diseaseKeys: string[];
    weight: number;
}> = [
    { keywords: ['sốt', 'nóng sốt', 'sốt cao', 'nhiệt độ'],          diseaseKeys: ['fever', 'influenza', 'common_cold'],              weight: 0.85 },
    { keywords: ['ho', 'đờm', 'khạc', 'ho khan', 'ho có đờm'],       diseaseKeys: ['cough', 'common_cold'],                           weight: 0.80 },
    { keywords: ['nghẹt mũi', 'sổ mũi', 'chảy mũi', 'mũi bị'],       diseaseKeys: ['nasal_congestion', 'common_cold'],                weight: 0.80 },
    { keywords: ['hắt hơi', 'ngứa mũi', 'dị ứng', 'allergy'],         diseaseKeys: ['allergic_rhinitis', 'allergic_reaction'],         weight: 0.85 },
    { keywords: ['đau đầu', 'nhức đầu', 'đau nửa đầu', 'đầu nặng'],  diseaseKeys: ['headache', 'influenza'],                          weight: 0.90 },
    { keywords: ['đau họng', 'viêm họng', 'nuốt đau', 'họng rát'],    diseaseKeys: ['sore_throat', 'common_cold'],                     weight: 0.85 },
    { keywords: ['cảm lạnh', 'cảm cúm', 'cảm'],                       diseaseKeys: ['common_cold', 'influenza'],                       weight: 0.85 },
    { keywords: ['tiêu chảy', 'đi ngoài', 'phân lỏng', 'đi tháo'],   diseaseKeys: ['gastroenteritis'],                                weight: 0.90 },
    { keywords: ['đau bụng', 'bụng đau', 'đau dạ dày', 'co thắt'],   diseaseKeys: ['gastroenteritis', 'acid_reflux'],                 weight: 0.75 },
    { keywords: ['ợ chua', 'trào ngược', 'nóng rát ngực', 'ợ hơi'],  diseaseKeys: ['acid_reflux'],                                    weight: 0.90 },
    { keywords: ['táo bón', 'không đi vệ sinh', 'khó đại tiện'],       diseaseKeys: ['constipation'],                                   weight: 0.90 },
    { keywords: ['buồn nôn', 'nôn mửa', 'muốn nôn', 'ói'],           diseaseKeys: ['nausea_vomiting', 'gastroenteritis'],             weight: 0.85 },
    { keywords: ['say xe', 'chóng mặt khi đi', 'buồn nôn xe'],        diseaseKeys: ['motion_sickness'],                                weight: 0.90 },
    { keywords: ['đau cơ', 'đau khớp', 'nhức mình', 'mỏi cơ'],       diseaseKeys: ['muscle_joint_pain'],                              weight: 0.85 },
    { keywords: ['đau răng', 'sâu răng', 'răng đau', 'nướu'],         diseaseKeys: ['toothache'],                                      weight: 0.90 },
    { keywords: ['nấm da', 'nấm chân', 'hắc lào', 'lang ben'],        diseaseKeys: ['skin_fungal'],                                    weight: 0.90 },
    { keywords: ['ngứa da', 'nổi mề đay', 'phát ban', 'eczema'],      diseaseKeys: ['eczema_dermatitis', 'allergic_reaction'],         weight: 0.80 },
    { keywords: ['vết thương', 'cắt đứt', 'trầy xước', 'xây xát'],   diseaseKeys: ['minor_wound'],                                    weight: 0.85 },
    { keywords: ['mắt đỏ', 'đau mắt', 'ngứa mắt', 'mắt tiết ghèn'], diseaseKeys: ['conjunctivitis'],                                 weight: 0.90 },
    { keywords: ['khô mắt', 'mắt khô', 'mắt mỏi'],                   diseaseKeys: ['eye_dryness'],                                    weight: 0.88 },
    { keywords: ['mất ngủ', 'khó ngủ', 'ngủ không được', 'trằn trọc'], diseaseKeys: ['insomnia'],                                     weight: 0.90 },
    { keywords: ['thiếu vitamin', 'bổ sung', 'mệt mỏi', 'thiếu sức'], diseaseKeys: ['vitamin_deficiency'],                             weight: 0.65 },
];

// =============================================================
// MAIN SERVICE CLASS
// =============================================================
export class DiseasePredictorService {

    /**
     * Điểm vào chính: Triệu chứng → Danh sách bệnh dự đoán + ATC codes.
     *
     * Chiến lược: Groq LLM → fail → Keyword fallback (luôn có kết quả).
     * Cache TTL 10 phút để tái dùng khi user gửi lại cùng triệu chứng.
     */
    static async predict(symptoms: string): Promise<PredictedDisease[]> {
        const cacheKey = symptoms.toLowerCase().trim().replace(/\s+/g, ' ');

        // Tầng 3: Cache hit
        const cached = predictionCache.get(cacheKey);
        if (cached && Date.now() < cached.expiredAt) {
            return cached.result;
        }

        let result: PredictedDisease[];
        try {
            // Tầng 1: Groq LLM (JSON mode, 5s timeout)
            result = await this.predictWithGroq(symptoms);
            console.log(`[DiseasePredictor] LLM predicted: ${result.map(d => `${d.nameVi}(${(d.probability * 100).toFixed(0)}%)`).join(', ')}`);
        } catch (err: any) {
            // Tầng 2: Keyword fallback
            console.warn(`[DiseasePredictor] LLM unavailable (${err.message}) → Keyword fallback`);
            result = this.predictWithKeywords(symptoms);
        }

        // Cache kết quả
        predictionCache.set(cacheKey, { result, expiredAt: Date.now() + CACHE_TTL_MS });

        // Dọn cache nếu quá lớn
        if (predictionCache.size > 300) {
            const now = Date.now();
            for (const [key, val] of predictionCache.entries()) {
                if (now > val.expiredAt) predictionCache.delete(key);
            }
        }

        return result;
    }

    // ─── Private: LLM Prediction ─────────────────────────────

    private static async predictWithGroq(symptoms: string): Promise<PredictedDisease[]> {
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) throw new Error('GROQ_API_KEY missing');

        const controller = new AbortController();
        const timeoutId  = setTimeout(() => controller.abort(), TIMEOUT_MS);

        const validKeys = Object.keys(DISEASE_DATABASE).join(', ');

        try {
            const response = await fetch(GROQ_URL, {
                method: 'POST',
                headers: {
                    'Content-Type':  'application/json',
                    'Authorization': `Bearer ${apiKey.replace(/['"]/g, '').trim()}`,
                },
                body: JSON.stringify({
                    model: GROQ_MODEL,
                    messages: [
                        {
                            role: 'system',
                            content: `Bạn là hệ thống phân loại y tế tự động.
Phân tích triệu chứng và dự đoán tối đa 3 bệnh phổ biến có thể điều trị bằng thuốc OTC.

Danh sách KEY hợp lệ: ${validKeys}

Quy tắc nghiêm ngặt:
- Chỉ dùng key từ danh sách trên, KHÔNG tự chế key mới
- probability: 0.0-1.0
- Sắp xếp theo probability giảm dần
- Chỉ output JSON, không giải thích

Format: {"predictions":[{"key":"disease_key","probability":0.85}]}`,
                        },
                        {
                            role: 'user',
                            content: `Triệu chứng: "${symptoms}"`,
                        },
                    ],
                    temperature:     0.1,  // Gần như deterministic
                    max_tokens:      150,  // Nhỏ, chỉ cần JSON ngắn
                    response_format: { type: 'json_object' },
                }),
                signal: controller.signal,
            });

            if (!response.ok) throw new Error(`Groq HTTP ${response.status}`);

            const data    = await response.json();
            const content = data.choices[0]?.message?.content ?? '{}';
            const parsed  = JSON.parse(content);

            const predictions: PredictedDisease[] = (parsed.predictions || [])
                .filter((p: any) => p.key && DISEASE_DATABASE[p.key])
                .slice(0, 3)
                .map((p: any) => ({
                    name:        p.key,
                    nameVi:      DISEASE_DATABASE[p.key].nameVi,
                    atcCodes:    DISEASE_DATABASE[p.key].atcCodes,
                    probability: Math.max(0, Math.min(1, Number(p.probability) || 0)),
                }));

            return predictions;

        } finally {
            clearTimeout(timeoutId);
        }
    }

    // ─── Private: Keyword Fallback ────────────────────────────

    /**
     * Fallback thuần TypeScript — không cần network.
     * Phân tích từ khóa tiếng Việt trong triệu chứng.
     *
     * Scoring: confidence = min(weight, weight × (0.6 + matchCount × 0.2))
     * Nghĩa là: càng nhiều keyword khớp → càng tự tin hơn.
     */
    static predictWithKeywords(symptoms: string): PredictedDisease[] {
        const lower         = symptoms.toLowerCase();
        const diseaseScores = new Map<string, number>();

        for (const { keywords, diseaseKeys, weight } of KEYWORD_DISEASE_MAP) {
            const matchCount = keywords.filter(kw => lower.includes(kw)).length;
            if (matchCount === 0) continue;

            const confidence = Math.min(weight, weight * (0.6 + matchCount * 0.2));

            for (const key of diseaseKeys) {
                diseaseScores.set(key, Math.max(diseaseScores.get(key) ?? 0, confidence));
            }
        }

        if (diseaseScores.size === 0) return [];

        return [...diseaseScores.entries()]
            .sort((a, b) => b[1] - a[1])
            .slice(0, 3)
            .filter(([, score]) => score >= 0.5)
            .map(([key, prob]) => ({
                name:        key,
                nameVi:      DISEASE_DATABASE[key]?.nameVi ?? key,
                atcCodes:    DISEASE_DATABASE[key]?.atcCodes ?? [],
                probability: prob,
            }));
    }
}

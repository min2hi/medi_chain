/**
 * ============================================================================
 * MEDICAL NLU SERVICE — Clinical Intelligence Layer v1.0
 * ============================================================================
 *
 * Thay thế toàn bộ keyword matching bằng một Groq call duy nhất làm được:
 *  1. Clinical Named Entity Recognition (NER)
 *     - Trích xuất symptom entities với severity, onset, duration, modifiers
 *  2. Context Classification
 *     - NORMAL_OTC | UNDER_MEDICAL_CARE | PAST_HISTORY | HYPOTHETICAL
 *  3. Clinical Pattern Detection (Bayesian-style)
 *     - FAST_STROKE, ACS, SEPSIS, MENINGITIS, DENGUE_RISK, ANAPHYLAXIS...
 *  4. Disease Prediction (gộp vào đây, tránh Groq call thứ 2)
 *  5. Urgency Scoring (0-10)
 *
 * ─── Tại sao tốt hơn keyword matching ─────────────────────────────────────
 *  Keyword: "đi cấp cứu" ≠ "nhờ xe cứu thương" ≠ "chở vào phòng mổ"
 *  NLU: cả 3 đoạn trên đều → contextType: "UNDER_MEDICAL_CARE"
 *
 *  Keyword: "đau ngực" → luôn block (false positive)
 *  NLU: "đau ngực nhẹ khi ăn no" → severity:mild, context:NORMAL_OTC, urgency:2
 *       "đau ngực dữ dội + khó thở + vã mồ hôi" → ACS pattern, urgency:10
 *
 * ─── Thiết kế Hybrid (industry standard 2024-2025) ─────────────────────────
 *  Tier 1: Crystal-clear fast-fail keywords (5 signals, <1ms, sync)
 *  Tier 2: LLM Semantic Gate (Groq, async, 2s timeout, cached)
 *  Tier 3: Keyword fallback (if all async fails)
 *
 * ─── References ────────────────────────────────────────────────────────────
 *  - Infermedica API: symptom entity extraction + probabilistic diagnosis
 *  - Ada Health: NLU → Bayesian differential → triage
 *  - Microsoft Azure Health Bot: LUIS intent + entity recognition
 *  - Google MedPalm 2: LLM-first clinical NLU approach
 * ============================================================================
 */

import type { PredictedDisease } from '../recommendation/scoring.engine.js';
import { DISEASE_DATABASE } from './disease-predictor.service.js';

// ─── Config ──────────────────────────────────────────────────────────────────
const GROQ_URL   = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.3-70b-versatile';
const NLU_TIMEOUT_MS  = 3_000;     // Hard limit — safety pipeline must be fast
const CACHE_TTL_MS    = 10 * 60 * 1000; // 10 phút
const CACHE_MAX_SIZE  = 500;

// ─── Types ───────────────────────────────────────────────────────────────────

export interface SymptomEntity {
    symptom:   string;                                           // Tên triệu chứng chuẩn hóa
    severity:  'mild' | 'moderate' | 'severe' | 'critical';     // Mức độ
    onset:     'sudden' | 'gradual' | 'unknown';                // Kiểu khởi phát
    duration:  string;                                          // "2 giờ", "3 ngày", "unknown"
    modifiers: string[];                                        // ["sau khi ăn", "kèm sốt"]
    isActive:  boolean;                                         // Đang xảy ra hay quá khứ
}

export type ContextType =
    | 'NORMAL_OTC'          // Triệu chứng thông thường → tư vấn OTC
    | 'UNDER_MEDICAL_CARE'  // Đang được điều trị y tế → KHÔNG tư vấn thêm OTC
    | 'PAST_HISTORY'        // Mô tả quá khứ → soft warning
    | 'HYPOTHETICAL';       // Lo sợ / giả định → soft warning

export type TemporalityType = 'CURRENT' | 'RECENT' | 'PAST' | 'HYPOTHETICAL';
export type IntentType      = 'SELF_MEDICATE' | 'INFORMATION' | 'EMERGENCY_CHECK' | 'ALREADY_TREATED';

/**
 * Kết quả phân tích NLU + Disease Prediction — dùng cho cả safety gate
 * và recommendation engine để tránh 2 Groq calls riêng biệt.
 */
export interface NLUResult {
    // ── Clinical Entities ──
    entities:          SymptomEntity[];

    // ── Context & Intent ──
    contextType:       ContextType;
    temporality:       TemporalityType;
    intent:            IntentType;

    // ── Safety Signals ──
    isEmergency:       boolean;
    urgencyScore:      number;          // 0-10 (0=thông thường, 8+=cấp cứu)
    clinicalPatterns:  ClinicalPattern[]; // Patterns phát hiện được

    // ── Disease Prediction (merged — tránh Groq call thứ 2) ──
    predictedDiseases: PredictedDisease[];

    // ── Explanation ──
    reason:            string;          // Lý do ngắn gọn
    confidence:        number;          // 0-1

    // ── Meta ──
    cached:            boolean;
    fromFallback:      boolean;
    processingMs:      number;
}

/**
 * Clinical patterns — mỗi pattern có thể trigger auto-exclusion của nhóm thuốc.
 * Thay thế "combo detection" cũ bằng semantic pattern recognition.
 */
export type ClinicalPattern =
    | 'FAST_STROKE'       // Face Arm Speech Time → đột quỵ
    | 'ACS'               // Acute Coronary Syndrome → hội chứng vành cấp
    | 'SEPSIS'            // Nhiễm khuẩn huyết
    | 'MENINGITIS'        // Viêm màng não
    | 'ANAPHYLAXIS'       // Sốc phản vệ
    | 'DENGUE_RISK'       // Nguy cơ sốt xuất huyết
    | 'THUNDERCLAP_HEAD'  // Đau đầu sấm sét → SAH
    | 'HOSPITAL_CONTEXT'  // Đang trong bệnh viện/cấp cứu
    | 'RESPIRATORY_FAIL'  // Suy hô hấp
    | 'HYPERTENSIVE_CRISIS'; // Tăng huyết áp ác tính

/**
 * Auto-exclusion map: Nếu pattern được phát hiện → exclude nhóm thuốc này
 * khỏi recommendation. Thay thế hardcoded exclusion logic cũ.
 */
export const PATTERN_DRUG_EXCLUSIONS: Record<string, {
    excludeIngredients: string[];   // Tên hoạt chất (lowercase) cần loại
    excludeCategories:  string[];   // Category code cần loại
    reason:             string;     // Hiển thị cho user
}> = {
    'DENGUE_RISK': {
        excludeIngredients: ['ibuprofen', 'aspirin', 'naproxen', 'diclofenac', 'mefenamic'],
        excludeCategories:  [],
        reason: '🦟 Nguy cơ sốt xuất huyết: NSAIDs/Aspirin có thể gây xuất huyết nặng',
    },
    'ACS': {
        excludeIngredients: ['pseudoephedrine', 'phenylephrine', 'ephedrine'],
        excludeCategories:  ['DECONGESTANT'],
        reason: '❤️ Nghi ACS: Thuốc co mạch chống chỉ định',
    },
    'HYPERTENSIVE_CRISIS': {
        excludeIngredients: ['pseudoephedrine', 'phenylephrine', 'ibuprofen', 'naproxen'],
        excludeCategories:  ['DECONGESTANT'],
        reason: '🩸 Tăng huyết áp: NSAIDs và thuốc co mạch làm tăng BP',
    },
    'RESPIRATORY_FAIL': {
        excludeIngredients: ['antihistamine', 'diphenhydramine', 'promethazine'],
        excludeCategories:  [],
        reason: '🫁 Suy hô hấp: Kháng histamine gây ức chế hô hấp thêm',
    },
};

// ─── LRU Cache (TTL-based, text-normalized key) ────────────────────────────

interface CacheEntry {
    result:    NLUResult;
    expiredAt: number;
}

const nluCache = new Map<string, CacheEntry>();

/** Normalize text để làm cache key — không cần embedding */
function normalizeCacheKey(text: string): string {
    return text
        .toLowerCase()
        .trim()
        .replace(/\s+/g, ' ')
        .replace(/[.,!?]+$/, ''); // Bỏ dấu câu cuối
}

function cleanCache() {
    if (nluCache.size <= CACHE_MAX_SIZE) return;
    const now = Date.now();
    for (const [k, v] of nluCache.entries()) {
        if (now > v.expiredAt) nluCache.delete(k);
    }
    // Nếu vẫn còn quá lớn → xóa entry cũ nhất
    if (nluCache.size > CACHE_MAX_SIZE) {
        const firstKey = nluCache.keys().next().value;
        if (firstKey !== undefined) nluCache.delete(firstKey);
    }
}

// ─── Groq NLU Prompt ──────────────────────────────────────────────────────
// Đây là "trái tim" của hệ thống — một Groq call làm được tất cả:
// entity extraction, context classification, disease prediction, safety patterns.
// Inspired by: Infermedica NER + Ada Health clinical protocol + MedPalm reasoning.

const VALID_DISEASE_KEYS = Object.keys(DISEASE_DATABASE).join(', ');

const NLU_SYSTEM_PROMPT = `Bạn là hệ thống Medical NLU cho nền tảng tư vấn thuốc OTC tại Việt Nam.
Phân tích mô tả triệu chứng và trả JSON với cấu trúc CHÍNH XÁC sau. KHÔNG thêm text giải thích.

════ CLINICAL PATTERNS cần phát hiện ════
"FAST_STROKE":        Mặt méo + tay yếu/tê + nói khó + khởi phát ĐỘT NGỘT
"ACS":                Đau ngực + khó thở + vã mồ hôi + khởi phát đột ngột
"SEPSIS":             Sốt/hạ thân nhiệt + lơ mơ + thở nhanh + nghi nhiễm khuẩn  
"MENINGITIS":         Đau đầu dữ DỒNG THỜI cứng gáy + sốt cao + sợ ánh sáng
"ANAPHYLAXIS":        Dị ứng nặng + sưng họng/lưỡi + khó thở + đột ngột
"DENGUE_RISK":        Sốt ≥2 ngày + đau đầu + mệt nhiều + đau cơ-khớp + KHÔNG có triệu chứng hô hấp
"THUNDERCLAP_HEAD":   "Đau đầu dữ dội nhất từ trước đến nay" khởi phát đột ngột
"HOSPITAL_CONTEXT":   Đang ở/vừa được đưa đến bệnh viện/cấp cứu/đang truyền dịch/đang được bác sĩ điều trị
"RESPIRATORY_FAIL":   SpO2 < 90 hoặc không thể thở dù đang nghỉ
"HYPERTENSIVE_CRISIS":Huyết áp ≥ 180/120 mmHg

════ CONTEXT TYPES ════
"NORMAL_OTC":         Triệu chứng thông thường phù hợp tư vấn thuốc OTC
"UNDER_MEDICAL_CARE": Đang được điều trị y tế (nhập viện, truyền dịch, bác sĩ đang điều trị, đi cấp cứu, nhờ xe cứu thương, phòng mổ, phẫu thuật...)
"PAST_HISTORY":       Mô tả sự kiện trong quá khứ ("hôm qua","tuần trước","trước đây","ngày xưa","từng bị")
"HYPOTHETICAL":       Lo lắng hoặc giả định ("lo sợ","sợ bị","nếu","có thể bị","tôi nghĩ mình")

════ SEVERITY ════
mild = chịu được, không ảnh hưởng sinh hoạt
moderate = ảnh hưởng sinh hoạt nhưng có thể chịu
severe = rất đau/khó chịu, ảnh hưởng nặng
critical = không thể chịu được / đe dọa tính mạng

════ DISEASE KEYS hợp lệ ════
${VALID_DISEASE_KEYS}

════ OUTPUT FORMAT (JSON, không có text khác) ════
{
  "entities": [
    {
      "symptom": "tên triệu chứng chuẩn hóa tiếng Việt",
      "severity": "mild|moderate|severe|critical",
      "onset": "sudden|gradual|unknown",
      "duration": "ví dụ: '2 ngày', 'từ sáng', 'unknown'",
      "modifiers": ["ngữ cảnh như 'sau khi ăn', 'kèm sốt'"],
      "isActive": true
    }
  ],
  "contextType": "NORMAL_OTC|UNDER_MEDICAL_CARE|PAST_HISTORY|HYPOTHETICAL",
  "isEmergency": false,
  "urgencyScore": 0,
  "clinicalPatterns": [],
  "temporality": "CURRENT|RECENT|PAST|HYPOTHETICAL",
  "intent": "SELF_MEDICATE|INFORMATION|EMERGENCY_CHECK|ALREADY_TREATED",
  "predictedDiseases": [
    {"key": "disease_key_hợp_lệ", "probability": 0.85}
  ],
  "reason": "lý do ngắn gọn bằng tiếng Việt",
  "confidence": 0.90
}

QUY TẮC QUAN TRỌNG:
- urgencyScore: 0-10 (0=bình thường, 7=cần bác sĩ, 9+=cấp cứu ngay)
- isEmergency: true CHỈ KHI urgencyScore >= 8 HOẶC có clinicalPattern nguy hiểm
- predictedDiseases: tối đa 3, chỉ dùng key từ danh sách disease keys ở trên
- Nếu contextType=UNDER_MEDICAL_CARE → predictedDiseases=[], isEmergency=true
- Nếu contextType=PAST_HISTORY hoặc HYPOTHETICAL → isEmergency=false
- confidence: mức độ chắc chắn của toàn bộ phân tích (0-1)`;

// ─── Main Service ─────────────────────────────────────────────────────────

export class MedicalNLUService {

    /**
     * Điểm vào chính — phân tích toàn diện triệu chứng.
     * Cache-first, Groq-second, keyword fallback-third.
     */
    static async analyze(symptoms: string): Promise<NLUResult> {
        const start    = Date.now();
        const cacheKey = normalizeCacheKey(symptoms);

        // ── Tier 0: Cache hit ──
        const cached = nluCache.get(cacheKey);
        if (cached && Date.now() < cached.expiredAt) {
            return { ...cached.result, cached: true, processingMs: Date.now() - start };
        }

        // ── Tier 1: Groq NLU ──
        try {
            const result = await this.callGroqNLU(symptoms);
            const final: NLUResult = { ...result, cached: false, fromFallback: false, processingMs: Date.now() - start };

            nluCache.set(cacheKey, { result: final, expiredAt: Date.now() + CACHE_TTL_MS });
            cleanCache();

            return final;
        } catch (err: any) {
            // ── Tier 2: Keyword fallback (luôn hoạt động, không cần network) ──
            console.warn(`[MedicalNLU] Groq unavailable (${err.message}) → keyword fallback`);
            const fallback = this.keywordFallback(symptoms);
            return { ...fallback, cached: false, fromFallback: true, processingMs: Date.now() - start };
        }
    }

    // ─── Private: Groq NLU Call ──────────────────────────────────────────────

    private static async callGroqNLU(symptoms: string): Promise<NLUResult> {
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) throw new Error('GROQ_API_KEY missing');

        const controller = new AbortController();
        const timeoutId  = setTimeout(() => controller.abort(), NLU_TIMEOUT_MS);

        try {
            const response = await fetch(GROQ_URL, {
                method:  'POST',
                headers: {
                    'Content-Type':  'application/json',
                    'Authorization': `Bearer ${apiKey.replace(/['"]/g, '').trim()}`,
                },
                body: JSON.stringify({
                    model:           GROQ_MODEL,
                    temperature:     0.0,  // Deterministic — medical triage must be consistent
                    max_tokens:      500,  // Đủ cho JSON có entities + diseases
                    response_format: { type: 'json_object' },
                    messages: [
                        { role: 'system', content: NLU_SYSTEM_PROMPT },
                        { role: 'user',   content: `Phân tích: "${symptoms}"` },
                    ],
                }),
                signal: controller.signal,
            });

            if (!response.ok) throw new Error(`Groq HTTP ${response.status}`);

            const data    = await response.json();
            const content = data.choices?.[0]?.message?.content ?? '{}';
            const parsed  = JSON.parse(content);

            return this.parseGroqResponse(parsed, symptoms);

        } finally {
            clearTimeout(timeoutId);
        }
    }

    // ─── Parse + Validate Groq Response ──────────────────────────────────────

    private static parseGroqResponse(parsed: any, _symptoms: string): NLUResult {
        // ── Entities ──
        const entities: SymptomEntity[] = (Array.isArray(parsed.entities) ? parsed.entities : [])
            .map((e: any): SymptomEntity => ({
                symptom:   String(e.symptom  || ''),
                severity:  (['mild','moderate','severe','critical'].includes(e.severity) ? e.severity : 'mild') as any,
                onset:     (['sudden','gradual','unknown'].includes(e.onset) ? e.onset : 'unknown') as any,
                duration:  String(e.duration  || 'unknown'),
                modifiers: Array.isArray(e.modifiers) ? e.modifiers.map(String) : [],
                isActive:  e.isActive !== false,
            }))
            .filter((e: SymptomEntity) => e.symptom.length > 0);

        // ── Context ──
        const validContexts: ContextType[] = ['NORMAL_OTC','UNDER_MEDICAL_CARE','PAST_HISTORY','HYPOTHETICAL'];
        const contextType = validContexts.includes(parsed.contextType) ? parsed.contextType as ContextType : 'NORMAL_OTC';

        // ── Clinical Patterns ──
        const validPatterns: ClinicalPattern[] = [
            'FAST_STROKE','ACS','SEPSIS','MENINGITIS','ANAPHYLAXIS',
            'DENGUE_RISK','THUNDERCLAP_HEAD','HOSPITAL_CONTEXT',
            'RESPIRATORY_FAIL','HYPERTENSIVE_CRISIS',
        ];
        const clinicalPatterns = (Array.isArray(parsed.clinicalPatterns) ? parsed.clinicalPatterns : [])
            .filter((p: any) => validPatterns.includes(p)) as ClinicalPattern[];

        // ── Emergency logic (validate LLM's decision + our own rules) ──
        const urgencyScore  = Math.max(0, Math.min(10, Number(parsed.urgencyScore) || 0));
        const hasCriticalPattern = clinicalPatterns.some(p =>
            ['FAST_STROKE','ACS','SEPSIS','ANAPHYLAXIS','RESPIRATORY_FAIL','THUNDERCLAP_HEAD'].includes(p)
        );
        const isHospitalContext = contextType === 'UNDER_MEDICAL_CARE' || clinicalPatterns.includes('HOSPITAL_CONTEXT');
        const isEmergency = Boolean(parsed.isEmergency) || urgencyScore >= 8 || hasCriticalPattern || isHospitalContext;

        // ── Predicted Diseases (merge with disease predictor) ──
        const predictedDiseases: PredictedDisease[] = (contextType === 'UNDER_MEDICAL_CARE')
            ? []  // Đang được điều trị → không cần dự đoán bệnh OTC
            : (Array.isArray(parsed.predictedDiseases) ? parsed.predictedDiseases : [])
                .filter((d: any) => d.key && DISEASE_DATABASE[d.key])
                .slice(0, 3)
                .map((d: any): PredictedDisease => ({
                    name:        d.key,
                    nameVi:      DISEASE_DATABASE[d.key].nameVi,
                    atcCodes:    DISEASE_DATABASE[d.key].atcCodes,
                    probability: Math.max(0, Math.min(1, Number(d.probability) || 0)),
                }));

        // ── Temporality & Intent ──
        const validTemporality: TemporalityType[] = ['CURRENT','RECENT','PAST','HYPOTHETICAL'];
        const temporality = validTemporality.includes(parsed.temporality) ? parsed.temporality as TemporalityType : 'CURRENT';
        const validIntents: IntentType[] = ['SELF_MEDICATE','INFORMATION','EMERGENCY_CHECK','ALREADY_TREATED'];
        const intent = validIntents.includes(parsed.intent) ? parsed.intent as IntentType : 'SELF_MEDICATE';

        return {
            entities,
            contextType,
            temporality,
            intent,
            isEmergency,
            urgencyScore,
            clinicalPatterns,
            predictedDiseases,
            reason:     String(parsed.reason    || ''),
            confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0.5)),
            cached:     false,
            fromFallback: false,
            processingMs: 0, // filled by caller
        };
    }

    // ─── Keyword Fallback ────────────────────────────────────────────────────
    /**
     * Chạy khi Groq không khả dụng. Dùng rule đơn giản để đảm bảo
     * hệ thống vẫn hoạt động. Chỉ phát hiện được pattern rõ ràng nhất.
     *
     * Đây là "safety net" — không thay thế NLU nhưng đảm bảo
     * các case nguy hiểm rõ ràng vẫn được block.
     */
    private static keywordFallback(symptoms: string): NLUResult {
        const lower = symptoms.toLowerCase();

        // ── Crystal-clear emergency signals ──
        const HARD_EMERGENCY = [
            'ngừng tim', 'ngừng thở', 'hôn mê', 'bất tỉnh', 'co giật',
            'liệt nửa người', 'mù đột ngột', 'câm đột ngột',
            'sốc phản vệ', 'sưng họng nghẹt thở',
        ];
        const HOSPITAL_SIGNALS = [
            'cấp cứu', 'nhập viện', 'truyền dịch', 'truyền nước',
            'phẫu thuật', 'nằm viện', 'đang ở bệnh viện', 'bác sĩ đang điều trị',
        ];
        const DENGUE_SIGNALS = ['sốt xuất huyết', 'dengue'];

        const isHardEmergency = HARD_EMERGENCY.some(kw => lower.includes(kw));
        const isHospital      = HOSPITAL_SIGNALS.some(kw => lower.includes(kw));
        const isDengue        = DENGUE_SIGNALS.some(kw => lower.includes(kw));

        const clinicalPatterns: ClinicalPattern[] = [];
        if (isHospital) clinicalPatterns.push('HOSPITAL_CONTEXT');
        if (isDengue)   clinicalPatterns.push('DENGUE_RISK');

        // Import từ disease-predictor để có keyword fallback cho diseases
        const { DiseasePredictorService } = require('./disease-predictor.service.js');
        const predictedDiseases: PredictedDisease[] = (isHardEmergency || isHospital)
            ? []
            : DiseasePredictorService.predictWithKeywords(symptoms);

        return {
            entities:          [],  // Keyword fallback không có entity extraction
            contextType:       isHospital      ? 'UNDER_MEDICAL_CARE'
                             : 'NORMAL_OTC',
            temporality:       'CURRENT',
            intent:            isHospital ? 'ALREADY_TREATED' : 'SELF_MEDICATE',
            isEmergency:       isHardEmergency || isHospital,
            urgencyScore:      isHardEmergency ? 10 : isHospital ? 9 : 2,
            clinicalPatterns,
            predictedDiseases,
            reason:            isHardEmergency ? 'Phát hiện dấu hiệu cấp cứu rõ ràng'
                             : isHospital      ? 'Đang trong môi trường y tế'
                             : 'Keyword fallback — Groq không khả dụng',
            confidence:        isHardEmergency || isHospital ? 0.95 : 0.4,
            cached:            false,
            fromFallback:      true,
            processingMs:      0,
        };
    }

    // ─── Utility: Build Emergency Response Message ────────────────────────────
    /**
     * Tạo message cấp cứu dựa trên NLU result — chi tiết hơn, context-aware.
     */
    static buildEmergencyMessage(nlu: NLUResult): string {
        const patterns = nlu.clinicalPatterns;

        if (nlu.contextType === 'UNDER_MEDICAL_CARE') {
            return [
                '# 🏥 ĐANG ĐƯỢC ĐIỀU TRỊ Y TẾ',
                '',
                'MediChain phát hiện bạn đang hoặc vừa nhận chăm sóc y tế.',
                '',
                '**Lý do không tư vấn thêm thuốc:**',
                '- Bạn đang trong sự quản lý của bác sĩ/y tá',
                '- Thuốc OTC có thể tương tác với thuốc đang được dùng tại viện',
                '- Chỉ định thuốc thuộc về bác sĩ đang điều trị cho bạn',
                '',
                '> ⚕️ Vui lòng hỏi trực tiếp bác sĩ hoặc dược sĩ đang phụ trách.',
            ].join('\n');
        }

        const lines = ['# 🚨 PHÁT HIỆN TRIỆU CHỨNG CẦN CẤP CỨU', ''];

        if (patterns.includes('FAST_STROKE')) {
            lines.push('**⚠️ DẤU HIỆU ĐỘT QUỴ (F.A.S.T)** — Cần cấp cứu trong 4.5 giờ đầu!');
        }
        if (patterns.includes('ACS')) {
            lines.push('**❤️ NGHI NGỜ NHỒI MÁU CƠ TIM** — Mỗi phút đều quý giá!');
        }
        if (patterns.includes('MENINGITIS')) {
            lines.push('**🧠 NGHI NGỜ VIÊM MÀNG NÃO** — Cần điều trị kháng sinh khẩn cấp!');
        }
        if (patterns.includes('ANAPHYLAXIS')) {
            lines.push('**💉 SỐC PHẢN VỆ** — Cần epinephrine ngay lập tức!');
        }
        if (patterns.includes('RESPIRATORY_FAIL')) {
            lines.push('**🫁 SUY HÔ HẤP** — Cần thở oxy hỗ trợ ngay!');
        }

        lines.push('', `*Đánh giá AI: ${nlu.reason}*`);
        lines.push('', '**MediChain KHÔNG THỂ tư vấn OTC cho tình trạng này.**');
        lines.push('## ☎️ GỌI NGAY: 115');

        return lines.join('\n');
    }

    /** Cache stats — dùng cho monitoring/debugging */
    static getCacheStats(): { size: number; maxSize: number } {
        return { size: nluCache.size, maxSize: CACHE_MAX_SIZE };
    }
}

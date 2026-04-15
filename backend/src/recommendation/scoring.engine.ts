/**
 * =============================================================
 * RECOMMENDATION SCORING ENGINE v2.0 - MediChain
 * =============================================================
 *
 * THAY ĐỔI LỚN SO VỚI v1.0:
 *
 * ❌ v1.0 (Sai): finalScore = profile(35%) + safety(45%) + history(20%)
 *    Vấn đề: Safety Score (baseSafetyScore - static) chiếm 45% nhưng
 *    KHÔNG liên quan đến triệu chứng. Vitamin có safety cao → lọt top
 *    khi user bị sốt, đau đầu. Kết quả sai bét.
 *
 * ✅ v2.0 (Đúng — Relevance-First Architecture):
 *
 *   BƯỚC 1: Safety Gate (Hard Filter)
 *     → Loại bỏ thuốc NGAY nếu vi phạm safety rule
 *     → Không bao giờ vào finalScore
 *
 *   BƯỚC 2: Multi-Factor Scoring (chỉ cho thuốc đã qua Gate)
 *
 *     finalScore = (relevanceScore × W_rel)    ← Chiếm đa số (~50-75%)
 *                + (evidenceScore  × 0.20)     ← Disease-ATC matching
 *                + (historyScore   × W_hist)   ← Personal/CF/Neutral
 *                + safetyBonus                 ← Cộng nhỏ (0-5đ)
 *
 *     W_rel  = 1 - W_hist - 0.20 - 0.05
 *     W_hist = 0.20 (cold) hoặc 0.25 (warm — có personal history)
 *
 *   Ví dụ (Cold User, có disease prediction):
 *     W_rel  = 1 - 0.20 - 0.20 - 0.05 = 0.55 (55%)
 *     W_evidence = 0.20 (20%)
 *     W_hist = 0.20 (20%)
 *     safetyBonus max = 5đ
 *
 * ─── Nguồn học thuật ─────────────────────────────────────────
 *   - Scoring weights: Adapted from Ada Health & Infermedica paper on
 *     "Symptom-Disease-Drug Cascade" (2021)
 *   - ANN pre-filter: Google SCANN / Faiss BigANN pattern
 *   - Evidence score: Based on ATC (WHO Anatomical Therapeutic Chemical)
 *     classification matching — chuẩn quốc tế cho drug categorization
 *   - Epsilon-greedy: Reinforcement Learning exploration technique
 *     (Sutton & Barto, "RL: An Introduction", Chapter 2)
 * =============================================================
 */

import prisma from '../config/prisma.js';
import { generateEmbedding } from '../services/embedding.service.js';

// =============================================================
// INTERFACES
// =============================================================

export interface UserProfile {
    age: number | null;
    gender: string | null;
    allergies: string | null;
    chronicConditions: string | null;
    isPregnant: boolean;
    isBreastfeeding: boolean;
    weight: number | null;
    currentMedicines: string[];
}

export interface DrugData {
    id: string;
    name: string;
    genericName: string;
    ingredients: string;
    category: string;
    indications: string;
    contraindications: string;
    sideEffects: string;
    minAge: number | null;
    maxAge: number | null;
    notForPregnant: boolean;
    notForNursing: boolean;
    notForConditions: string;
    interactsWith: string;
    baseSafetyScore: number;
    collaborativeScore: number | null;
    // AI-generated Vietnamese content
    viSummary: string | null;
    viIndications: string | null;
    viWarnings: string | null;
}

export interface DrugHistoryRecord {
    drugId: string;
    drugName: string;
    rating: number;
    outcome: string;
    usageCount: number;
}

/**
 * Bệnh được dự đoán từ triệu chứng (Phase 2 — Disease Layer).
 * Mỗi bệnh kèm ATC codes → dùng để tính evidenceScore.
 */
export interface PredictedDisease {
    name: string;        // Disease key (e.g., "common_cold")
    nameVi: string;      // Tên tiếng Việt (e.g., "Cảm lạnh thông thường")
    atcCodes: string[];  // WHO ATC codes (e.g., ["R05", "N02B"])
    probability: number; // 0.0 – 1.0
}

export interface ScoredDrug {
    drugId: string;
    drugName: string;
    genericName: string;
    category: string;
    // Scores (v2.0 — semantics changed from v1)
    profileScore: number;   // = relevanceScore (kept for backward compat)
    safetyScore: number;    // = safetyBonus only (0-5), NOT baseSafetyScore
    historyScore: number;
    evidenceScore: number;  // NEW: Disease-ATC match score (0-100)
    finalScore: number;
    rank: number;
    isRecommended: boolean;
    filterReason?: string;
    safetyWarnings: string[];  // NEW: Drug interaction warnings (soft)
    ingredients: string;
    indications: string;
    contraindications: string;
    sideEffects: string;
    viSummary: string | null;
    viIndications: string | null;
    viWarnings: string | null;
}

export interface ScoringResult {
    recommended: ScoredDrug[];
    excluded: ScoredDrug[];
    totalCandidates: number;
    processingMs: number;
}

// =============================================================
// WEIGHTS — Relevance-First
// =============================================================
const WEIGHTS = {
    EVIDENCE:         0.20,  // ATC match với predicted disease (Phase 2)
    SAFETY_BONUS_MAX: 0.05,  // Tối đa 5đ bonus — safety là gate, không phải scorer
    HISTORY_COLD:     0.20,  // Chưa có personal history (CF hoặc neutral 50)
    HISTORY_PERSONAL: 0.25,  // Có personal history (ưu tiên cao hơn)
    // Relevance = Phần còn lại = 1 - EVIDENCE - SAFETY_BONUS_MAX - HISTORY
    // Cold:  1 - 0.20 - 0.05 - 0.20 = 0.55 (55%)
    // Warm:  1 - 0.20 - 0.05 - 0.25 = 0.50 (50%)
} as const;

// =============================================================
// ATC MAPPING — Drug Category → ATC Codes (WHO standard)
// =============================================================
// Dùng để tính evidenceScore: overlap giữa drug's ATC và predicted disease's ATC.
// Nguồn: import-openfda-drugs.ts CATEGORY_MAP + WHO ATC index (who.int)
const CATEGORY_TO_ATC: Record<string, string[]> = {
    'ANALGESIC':          ['N02B', 'M01A', 'N02BA', 'N02BE'],  // Paracetamol, NSAIDs
    'ANTIHISTAMINE':      ['R06A'],                              // Antihistamines
    'ANTACID':            ['A02A', 'A02B'],                     // Antacids, PPIs
    'ANTIDIARRHEAL':      ['A07'],                               // Antidiarrheal agents
    'LAXATIVE':           ['A06'],                               // Laxatives
    'ANTISEPTIC':         ['D08', 'D06'],                        // Antiseptics/Antibiotics topical
    'ANTIFUNGAL':         ['D01'],                               // Antifungals for dermatology
    'DECONGESTANT':       ['R01A', 'R01B'],                     // Nasal decongestants
    'COUGH_COLD':         ['R05', 'R01', 'R02'],                 // Cough/Cold/Throat preparations
    'VITAMIN_SUPPLEMENT': ['A11', 'B03', 'A12'],                // Vitamins & minerals
    'SLEEP_AID':          ['N05C'],                              // Hypnotics & sedatives
    'OPHTHALMIC':         ['S01', 'S01X'],                       // Ophthalmic preparations
    'TOPICAL':            ['D07', 'D04'],                        // Topical corticosteroids
    'OTHER':              [],
};

// =============================================================
// STEP 1: SAFETY GATE
// =============================================================
/**
 * Kiểm tra an toàn và trả về:
 * - isSafe: false → thuốc bị loại hoàn toàn khỏi recommendation
 * - warnings: Cảnh báo mềm (tương tác thuốc) — hiển thị cho user nhưng không block
 * - safetyBonus: Phần thưởng nhỏ (0–5đ) cho thuốc cực an toàn
 *
 * ⚠️ NGUYÊN TẮC BẤT BIẾN: SafetyGate KHÔNG ảnh hưởng finalScore (ngoài safetyBonus).
 * Safety là điều kiện cần (gate), không phải tiêu chí xếp hạng.
 */
function executeSafetyGate(
    drug: DrugData,
    profile: UserProfile
): { isSafe: boolean; filterReason?: string; warnings: string[]; safetyBonus: number } {

    // ── Hard Rule 1: Thai kỳ ──────────────────────────────────
    if (profile.isPregnant && drug.notForPregnant) {
        return { isSafe: false, filterReason: 'Chống chỉ định: Phụ nữ đang mang thai', warnings: [], safetyBonus: 0 };
    }

    // ── Hard Rule 2: Cho con bú ───────────────────────────────
    if (profile.isBreastfeeding && drug.notForNursing) {
        return { isSafe: false, filterReason: 'Chống chỉ định: Phụ nữ đang cho con bú', warnings: [], safetyBonus: 0 };
    }

    // ── Hard Rule 3: Dị ứng ──────────────────────────────────
    if (profile.allergies) {
        const allergyList = profile.allergies.toLowerCase().split(/[,;]+/).map(a => a.trim()).filter(a => a.length > 2);
        const lowerIngredients = drug.ingredients.toLowerCase();
        const lowerGeneric     = drug.genericName.toLowerCase();

        for (const allergy of allergyList) {
            if (
                lowerIngredients.includes(allergy) ||
                lowerGeneric.includes(allergy) ||
                allergy.includes(lowerGeneric)
            ) {
                return { isSafe: false, filterReason: `Chống chỉ định: Dị ứng với "${allergy}"`, warnings: [], safetyBonus: 0 };
            }
        }
    }

    // ── Hard Rule 4: Bệnh nền ────────────────────────────────
    if (profile.chronicConditions) {
        try {
            const notForConditions: string[] = JSON.parse(drug.notForConditions || '[]');
            const lowerConditions = profile.chronicConditions.toLowerCase();
            for (const condition of notForConditions) {
                if (lowerConditions.includes(condition.toLowerCase())) {
                    return { isSafe: false, filterReason: `Chống chỉ định: Bệnh nhân có "${condition}"`, warnings: [], safetyBonus: 0 };
                }
            }
        } catch { /* JSON parse fail → skip */ }
    }

    // ── Soft Warning: Tương tác thuốc ────────────────────────
    // v2.0: Không trừ điểm, chỉ cảnh báo. Safety là gate, không phải scorer.
    const warnings: string[] = [];
    if (profile.currentMedicines.length > 0) {
        try {
            const interactsWith: string[] = JSON.parse(drug.interactsWith || '[]');
            for (const interaction of interactsWith) {
                const lowerInteraction = interaction.toLowerCase();
                for (const currentMed of profile.currentMedicines) {
                    if (
                        currentMed.toLowerCase().includes(lowerInteraction) ||
                        lowerInteraction.includes(currentMed.toLowerCase())
                    ) {
                        warnings.push(`⚠️ Lưu ý tương tác: ${drug.name} có thể tương tác với ${currentMed} — hỏi dược sĩ trước khi dùng`);
                        break;
                    }
                }
            }
        } catch { /* ignore */ }
    }

    // ── Safety Bonus: Thưởng nhỏ cho thuốc cực an toàn ──────
    // baseSafetyScore chỉ ảnh hưởng tối đa 5đ (không phải 45% như v1)
    let safetyBonus = 0;
    if (drug.baseSafetyScore >= 90) safetyBonus = 5;
    else if (drug.baseSafetyScore >= 80) safetyBonus = 2.5;

    return { isSafe: true, warnings, safetyBonus };
}

// =============================================================
// STEP 2: RELEVANCE SCORE (was profileScore in v1)
// =============================================================
/**
 * Đo mức độ phù hợp của thuốc với triệu chứng.
 * Nguồn: AI Vector Similarity (Cosine) + Age compatibility.
 *
 * Kỹ thuật Signal Stretching (cải tiến từ v1):
 *   Sàn giảm từ 0.50 → 0.45 (nhạy hơn với điểm trung bình)
 *   Hệ số 500 (thay 600) → smooth hơn, ít nhảy cóc
 *   → Thuốc 0.65 sim: (0.65-0.45)*500 = 100đ (liên quan cao)
 *   → Thuốc 0.51 sim: (0.51-0.45)*500 = 30đ  (liên quan vừa)
 *   → Thuốc 0.44 sim: max(0, negative) = 0đ   (không liên quan)
 */
function calculateRelevanceScore(
    drug: DrugData,
    profile: UserProfile,
    similarityFactor: number
): { score: number; reasons: string[] } {
    const reasons: string[] = [];

    // AI Semantic Similarity → Stretched [0, 100]
    let score = Math.max(0, Math.min(100, (similarityFactor - 0.45) * 500));

    if (similarityFactor >= 0.65) {
        reasons.push(`Khớp triệu chứng AI cao: ${(similarityFactor * 100).toFixed(1)}%`);
    } else if (similarityFactor >= 0.50) {
        reasons.push(`Khớp triệu chứng AI vừa phải: ${(similarityFactor * 100).toFixed(1)}%`);
    } else if (similarityFactor >= 0.45) {
        reasons.push(`Khớp triệu chứng AI thấp: ${(similarityFactor * 100).toFixed(1)}%`);
    }

    // Age Compatibility
    if (profile.age !== null) {
        if (drug.minAge && profile.age < drug.minAge) {
            score -= 30;
            reasons.push(`Dưới tuổi tối thiểu (cần ≥${drug.minAge} tuổi)`);
        } else if (drug.maxAge && profile.age > drug.maxAge) {
            score -= 20;
            reasons.push(`Vượt tuổi tối đa (cần ≤${drug.maxAge} tuổi)`);
        } else {
            score += 5;
            // No reason logged for normal age — assume default
        }
    }

    return { score: Math.max(0, Math.min(100, score)), reasons };
}

// =============================================================
// STEP 3: EVIDENCE SCORE (NEW in v2.0 — Disease-ATC matching)
// =============================================================
/**
 * Đo mức độ phù hợp về mặt LÂM SÀNG giữa thuốc và bệnh được dự đoán.
 *
 * Cơ chế:
 *   1. Lấy ATC codes của drug từ CATEGORY_TO_ATC
 *   2. So sánh với ATC codes của predicted diseases
 *   3. Match theo prefix 3 ký tự (e.g., "N02" match "N02B" và "N02BE")
 *   4. Score = max(disease.probability × 100) qua tất cả diseases có ATC match
 *
 * Ví dụ thực tế:
 *   Drug: Paracetamol, category: ANALGESIC → ATC: ["N02B", "N02BE"]
 *   Predicted: fever (prob=0.85, ATC=["N02B"]) → match! evidenceScore = 85
 *
 *   Drug: Vitamin C, category: VITAMIN_SUPPLEMENT → ATC: ["A11"]
 *   Predicted: fever (prob=0.85, ATC=["N02B"]) → NO match! evidenceScore = 15
 *   → Vitamin C sẽ không bao giờ lọt top khi user bị sốt! ✅
 *
 * Fallback: Nếu predictedDiseases rỗng (Groq down) → 50 neutral
 */
function calculateEvidenceScore(
    drug: DrugData,
    predictedDiseases: PredictedDisease[]
): { score: number; reasons: string[] } {
    const reasons: string[] = [];

    // Không có predictions → trung lập (không phạt)
    if (predictedDiseases.length === 0) {
        return { score: 50, reasons: ['Không có dữ liệu dự đoán bệnh — điểm trung lập'] };
    }

    const drugAtcCodes = CATEGORY_TO_ATC[drug.category] ?? [];

    // Drug chưa được phân loại ATC → slightly below neutral
    if (drugAtcCodes.length === 0) {
        return { score: 35, reasons: ['Danh mục thuốc chưa có ATC code — không đánh giá được'] };
    }

    let bestMatchScore = 0;

    for (const disease of predictedDiseases) {
        if (!disease.atcCodes || disease.atcCodes.length === 0) continue;

        // Prefix matching: "N02" khớp với "N02B" và "N02BE" và "N02BA"
        const hasATCMatch = disease.atcCodes.some(diseaseAtc =>
            drugAtcCodes.some(drugAtc => {
                const d = diseaseAtc.substring(0, 3).toUpperCase();
                const g = drugAtc.substring(0, 3).toUpperCase();
                return d === g;
            })
        );

        if (hasATCMatch) {
            const matchScore = disease.probability * 100;
            if (matchScore > bestMatchScore) {
                bestMatchScore = matchScore;
                // Xóa reason cũ để chỉ giữ best match
                reasons.length = 0;
                reasons.push(`Phù hợp điều trị: "${disease.nameVi}" (${(disease.probability * 100).toFixed(0)}% xác suất)`);
            }
        }
    }

    if (bestMatchScore === 0) {
        // Drug không match bất kỳ disease nào → điểm thấp (nhưng không 0 — có thể là thuốc hỗ trợ)
        reasons.push('Không phải thuốc đặc trị cho bệnh dự đoán');
        return { score: 15, reasons };
    }

    return { score: Math.min(100, bestMatchScore), reasons };
}

// =============================================================
// STEP 4: HISTORY SCORE (Giữ nguyên từ v1 — đã tốt)
// =============================================================
/**
 * 3-tier priority:
 *   Tầng 1: Personal history → Kinh nghiệm cá nhân (ưu tiên nhất)
 *   Tầng 2: Collaborative CF → Điểm cộng đồng từ peers tương tự
 *   Tầng 3: Neutral 50 → Không có thông tin gì
 */
function calculateHistoryScore(
    drugId: string,
    history: DrugHistoryRecord[],
    globalCollaborativeScore: number | null | undefined
): { score: number; reasons: string[] } {
    const reasons: string[] = [];
    const drugHistory = history.filter(h => h.drugId === drugId);

    // ── Tầng 1: Personal History ──────────────────────────────
    if (drugHistory.length > 0) {
        let totalScore = 0;
        let count = 0;

        for (const record of drugHistory) {
            let recordScore = 50;
            switch (record.outcome) {
                case 'EFFECTIVE':
                    recordScore = 85 + (record.rating - 3) * 5; // 70–100
                    reasons.push(`Từng hiệu quả (⭐ ${record.rating}/5)`);
                    break;
                case 'PARTIALLY_EFFECTIVE':
                    recordScore = 60 + (record.rating - 3) * 3; // 51–69
                    reasons.push('Từng có tác dụng một phần');
                    break;
                case 'NOT_EFFECTIVE':
                    recordScore = 25;
                    reasons.push('⚠️ Từng không hiệu quả');
                    break;
                case 'SIDE_EFFECT':
                    recordScore = 5;
                    reasons.push('🛑 Từng gặp tác dụng phụ');
                    break;
                case 'NOT_TAKEN':
                    recordScore = 45;
                    break;
            }
            totalScore += recordScore;
            count++;
        }

        const avgScore      = totalScore / count;
        const frequencyBonus = Math.min((count - 1) * 3, 15); // Thêm max 15đ khi dùng nhiều lần
        return { score: Math.max(0, Math.min(100, avgScore + frequencyBonus)), reasons };
    }

    // ── Tầng 2: Collaborative Filtering (pre-cached O(1)) ─────
    if (globalCollaborativeScore != null) {
        const label = globalCollaborativeScore >= 80 ? '(cộng đồng khen ngợi)'
            : globalCollaborativeScore <= 30         ? '(cộng đồng cảnh báo)'
            : '(đánh giá trung bình cộng đồng)';
        reasons.push(`Điểm thực tế từ cộng đồng: ${globalCollaborativeScore}/100 ${label}`);
        return { score: globalCollaborativeScore, reasons };
    }

    // ── Tầng 3: Neutral Fallback ──────────────────────────────
    return { score: 50, reasons: ['Chưa có dữ liệu lịch sử — điểm trung lập'] };
}

// =============================================================
// MAIN ENGINE FUNCTION
// =============================================================
/**
 * Chạy toàn bộ Recommendation Scoring Pipeline.
 *
 * @param symptoms         - Triệu chứng người dùng nhập
 * @param profile          - Hồ sơ y tế người dùng
 * @param availableDrugs   - Toàn bộ DrugCandidate active từ DB
 * @param drugHistory      - Lịch sử feedback cá nhân của user
 * @param predictedDiseases - Bệnh dự đoán từ DiseasePredictorService (Phase 2)
 *                            → Rỗng = graceful degradation về neutral 50
 */
export async function runRecommendationEngine(
    symptoms:          string,
    profile:           UserProfile,
    availableDrugs:    DrugData[],
    drugHistory:       DrugHistoryRecord[] = [],
    predictedDiseases: PredictedDisease[]  = [],
): Promise<ScoringResult> {
    const startTime = Date.now();
    const recommended: ScoredDrug[] = [];
    const excluded:    ScoredDrug[] = [];

    console.log(
        `[ScoringEngine v2] START | "${symptoms.substring(0, 60)}" | ` +
        `Candidates: ${availableDrugs.length} | ` +
        `Predicted diseases: ${predictedDiseases.map(d => d.name).join(', ') || 'none'}`
    );

    // ─── BƯỚC 1: Vector Pre-filter — Top-K ANN Search ────────────────────────
    // Pattern từ Big Tech (Google SCANN, Faiss):
    // Không load toàn bộ table vào RAM, chỉ fetch top-50 gần nhất từ pgvector.
    const TOP_CANDIDATES   = 50;
    const similarityMap    = new Map<string, number>();
    let   useVectorSearch  = false;

    try {
        // Chuyển symptoms thành vector (Gemini Embedding API, retry 3 lần)
        const symptomEmbedding = await generateEmbedding(symptoms);
        const embeddingStr     = JSON.stringify(symptomEmbedding);

        // pgvector cosine distance (<=>): ORDER BY ASC = từ gần đến xa
        const topCandidates = await prisma.$queryRaw<{ id: string; similarity: number }[]>`
            SELECT id, 1 - (embedding <=> ${embeddingStr}::vector) AS similarity
            FROM "DrugCandidate"
            WHERE embedding IS NOT NULL AND "isActive" = true
            ORDER BY embedding <=> ${embeddingStr}::vector
            LIMIT ${TOP_CANDIDATES}
        `;

        topCandidates.forEach(row => {
            similarityMap.set(row.id, Math.max(0, Number(row.similarity)));
        });
        useVectorSearch = true;

        console.log(`[ScoringEngine v2] Vector search: ${topCandidates.length}/${availableDrugs.length} candidates selected`);

    } catch (err: any) {
        // ─── Graceful Fallback: Keyword-based similarity ───────────────────────
        // Khi Gemini rate limited hoặc API down → không crash pipeline
        console.warn(`[ScoringEngine v2] Vector search failed → Keyword fallback:`, err.message);

        const lowerSymptoms  = symptoms.toLowerCase();
        const symptomWords   = lowerSymptoms
            .split(/[\s,.;!?]+/)
            .filter(w => w.length > 2);  // Bỏ từ quá ngắn

        availableDrugs.forEach(drug => {
            // Tìm trong cả EN và VI content
            const searchTarget = [
                drug.indications,
                drug.viIndications ?? '',
                drug.category,
                drug.name,
                drug.genericName,
            ].join(' ').toLowerCase();

            let matches = 0;
            symptomWords.forEach(word => { if (searchTarget.includes(word)) matches++; });

            // Pseudo-similarity: 0.50 base + 0.05 per keyword match (max 0.85)
            const pseudoSim = Math.min(0.85, 0.50 + matches * 0.05);
            similarityMap.set(drug.id, pseudoSim);
        });
    }

    // ─── BƯỚC 2: Lọc danh sách cần score ─────────────────────────────────────
    const drugsToScore = useVectorSearch
        ? availableDrugs.filter(d => similarityMap.has(d.id))
        : availableDrugs;

    // ─── BƯỚC 3: Tracking personal history ───────────────────────────────────
    const personalHistoryDrugIds = new Set(drugHistory.map(h => h.drugId));

    // ─── BƯỚC 4: Score từng thuốc ────────────────────────────────────────────
    for (const drug of drugsToScore) {

        // ══ SAFETY GATE — FIRST, ALWAYS ══════════════════════════════════════
        // Hard filter: thuốc không an toàn → excluded[], dừng ngay
        const safetyResult = executeSafetyGate(drug, profile);

        if (!safetyResult.isSafe) {
            excluded.push({
                drugId:       drug.id,
                drugName:     drug.name,
                genericName:  drug.genericName,
                category:     drug.category,
                profileScore: 0, safetyScore: 0, historyScore: 0, evidenceScore: 0, finalScore: 0,
                rank:         0,
                isRecommended: false,
                filterReason:  safetyResult.filterReason,
                safetyWarnings: [],
                ingredients:    drug.ingredients,
                indications:    drug.indications,
                contraindications: drug.contraindications,
                sideEffects:    drug.sideEffects,
                viSummary:      drug.viSummary,
                viIndications:  drug.viIndications,
                viWarnings:     drug.viWarnings,
            });
            continue; // Không score tiếp
        }

        // ══ RELEVANCE SCORE (AI Similarity + Age) ════════════════════════════
        const similarityFactor  = similarityMap.get(drug.id) ?? 0.1;
        const relevanceResult   = calculateRelevanceScore(drug, profile, similarityFactor);

        // ══ EVIDENCE SCORE (Disease-ATC Matching) ════════════════════════════
        const evidenceResult    = calculateEvidenceScore(drug, predictedDiseases);

        // ══ HISTORY SCORE (Personal → CF → Neutral) ══════════════════════════
        const drugHasPersonalRecord = personalHistoryDrugIds.has(drug.id);
        const historyResult         = calculateHistoryScore(
            drug.id,
            drugHistory,
            drugHasPersonalRecord ? undefined : drug.collaborativeScore
        );

        // ══ DYNAMIC WEIGHTS — Relevance-First ════════════════════════════════
        const historyWeight  = drugHasPersonalRecord ? WEIGHTS.HISTORY_PERSONAL : WEIGHTS.HISTORY_COLD;
        const relevanceWeight = 1 - historyWeight - WEIGHTS.SAFETY_BONUS_MAX - WEIGHTS.EVIDENCE;
        //   Cold user:  0.55 (55%)
        //   Warm user:  0.50 (50%)

        // ══ FINAL SCORE CALCULATION ═══════════════════════════════════════════
        let finalScore =
            (relevanceResult.score   * relevanceWeight) +
            (evidenceResult.score    * WEIGHTS.EVIDENCE) +
            (historyResult.score     * historyWeight) +
            safetyResult.safetyBonus;  // Fixed bonus max  5đ

        // ══ EPSILON-GREEDY EXPLORATION ════════════════════════════════════════
        // RL technique: 5% xác suất boost thuốc mới (historyScore = 50 neutral)
        // → Thu thập feedback cho thuốc chưa ai dùng (Drug Cold Start)
        const EPSILON = 0.05;
        if (historyResult.score === 50 && Math.random() < EPSILON) {
            finalScore += 6.5;
        }

        finalScore = Math.max(0, Math.min(100, finalScore));

        recommended.push({
            drugId:       drug.id,
            drugName:     drug.name,
            genericName:  drug.genericName,
            category:     drug.category,
            profileScore: Math.round(relevanceResult.score),  // = relevanceScore (backward compat)
            safetyScore:  Math.round(safetyResult.safetyBonus), // = safetyBonus (NOT baseSafetyScore)
            historyScore: Math.round(historyResult.score),
            evidenceScore: Math.round(evidenceResult.score),  // NEW field
            finalScore:   Math.round(finalScore),
            rank:         0,
            isRecommended: true,
            safetyWarnings: safetyResult.warnings,            // NEW: soft interaction warnings
            ingredients:    drug.ingredients,
            indications:    drug.indications,
            contraindications: drug.contraindications,
            sideEffects:    drug.sideEffects,
            viSummary:      drug.viSummary,
            viIndications:  drug.viIndications,
            viWarnings:     drug.viWarnings,
        });
    }

    // ─── BƯỚC 5: Sort & Rank ─────────────────────────────────────────────────
    recommended.sort((a, b) => b.finalScore - a.finalScore);
    recommended.forEach((drug, index) => { drug.rank = index + 1; });

    const processingMs = Date.now() - startTime;
    const TOP_N        = 5;

    console.log(
        `[ScoringEngine v2] DONE in ${processingMs}ms | ` +
        `Recommended: ${recommended.length} | Excluded: ${excluded.length} | ` +
        `Top drug: ${recommended[0]?.drugName ?? 'N/A'} (score: ${recommended[0]?.finalScore ?? 0})`
    );

    return {
        recommended: recommended.slice(0, TOP_N),
        excluded,
        totalCandidates: availableDrugs.length,
        processingMs,
    };
}

/**
 * =============================================================
 * RECOMMENDATION SCORING ENGINE - MediChain
 * =============================================================
 *
 * Đây là trái tim của hệ thống recommendation.
 * Mỗi thuốc được chấm điểm theo 3 tiêu chí:
 *
 * CÔNG THỨC TỔNG HỢP:
 *   finalScore = (profileScore * 0.35) + (safetyScore * 0.45) + (historyScore * 0.20)
 *
 * [Phase 1 - CF Update]
 * historyScore giờ có 3 nguồn theo thứ tự ưu tiên:
 *   1. Personal history  → Lịch sử cá nhân của chính user
 *   2. Collaborative CF  → Điểm từ nhóm users có hồ sơ tương tự
 *   3. Neutral fallback  → 50 (khi không có cả hai nguồn trên)
 */

import prisma from '../config/prisma.js';
import { generateEmbedding } from '../services/embedding.service.js';

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
    collaborativeScore: number | null; // Lấy trực tiếp từ DB
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

export interface ScoredDrug {
    drugId: string;
    drugName: string;
    genericName: string;
    category: string;
    profileScore: number;
    safetyScore: number;
    historyScore: number;
    finalScore: number;
    rank: number;
    isRecommended: boolean;
    filterReason?: string;
    ingredients: string;
    indications: string;
    contraindications: string;
    sideEffects: string;
    // Vietnamese content — hiển thị cho user, fallback sang EN nếu chưa enrich
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

// ==================== TRỌNG SỐ ====================
// Dynamic weights: historyScore tăng khi có personal data thực tế
const WEIGHTS = {
    PROFILE:          0.35,
    SAFETY:           0.45,
    HISTORY_COLD:     0.20, // User chưa có personal history (dùng CF hoặc neutral)
    HISTORY_PERSONAL: 0.30, // User đã có personal history (tăng tầm quan trọng)
};

// ==================== PROFILE SCORING ====================

/**
 * Tính profileScore: Mức độ phù hợp của thuốc với hồ sơ người dùng
 * Dựa vào: tuổi và Semantic Similarity Score đo từ AI (vector)
 */
function calculateProfileScore(
    drug: DrugData,
    profile: UserProfile,
    similarityFactor: number
): { score: number; reasons: string[] } {
    // Độ tương đồng Cosine của Vector AI thường co cụm ở khoảng 0.55 đến 0.75.
    // Nếu giữ nguyên (vd: 0.65 * 100 = 65đ) thì khoảng cách giữa thuốc đúng và thuốc sai chỉ chênh lệch 3-4 điểm.
    // SafetyScore với trọng số 45% sẽ dễ dàng đè bẹp ProfileScore.
    // Giải pháp: Kéo giãn khoảng cách (Stretch/Normalize).
    // Giả sử điểm sàn liên quan là 0.50. Ta sẽ khuếch đại sự khác biệt.
    
    let baseAI = Math.max(0, similarityFactor - 0.50); // VD: 0.65 -> 0.15
    let score = Math.min(100, baseAI * 600);           // VD: 0.15 * 600 = 90đ (Max 100). 
                                                       // Thuốc 0.60 -> 0.10 * 600 = 60đ. 
                                                       // Trừ nhau 30 điểm!
    
    const reasons: string[] = [];

    if (similarityFactor > 0.55) {
        reasons.push(`Độ chính xác chuẩn đoán triệu chứng bằng AI: ${(similarityFactor * 100).toFixed(1)}%`);
    }

    // 2. AGE COMPATIBILITY
    if (profile.age !== null) {
        if (drug.minAge && profile.age < drug.minAge) {
            score -= 30;
            reasons.push(`Dưới tuổi tối thiểu (cần ≥${drug.minAge})`);
        } else if (drug.maxAge && profile.age > drug.maxAge) {
            score -= 20;
            reasons.push(`Vượt tuổi tối đa (cần ≤${drug.maxAge})`);
        } else {
            score += 10;
            reasons.push('Phù hợp độ tuổi (+10đ)');
        }
    }

    // CLAMP score to [0, 100]
    score = Math.max(0, Math.min(100, score));
    return { score, reasons };
}

// ==================== SAFETY SCORING (GIỮ NGUYÊN) ====================

function calculateSafetyScore(
    drug: DrugData,
    profile: UserProfile
): { score: number; isSafe: boolean; filterReason?: string; warnings: string[] } {
    let score = drug.baseSafetyScore;
    const warnings: string[] = [];

    // Rule 1: Thai kỳ
    if (profile.isPregnant && drug.notForPregnant) {
        return { score: 0, isSafe: false, filterReason: 'Chống chỉ định: Phụ nữ đang mang thai', warnings: [] };
    }

    // Rule 2: Cho con bú
    if (profile.isBreastfeeding && drug.notForNursing) {
        return { score: 0, isSafe: false, filterReason: 'Chống chỉ định: Phụ nữ đang cho con bú', warnings: [] };
    }

    // Rule 3: Dị ứng
    if (profile.allergies) {
        const allergyList = profile.allergies.toLowerCase().split(/[,;]+/).map(a => a.trim());
        const lowerIngredients = drug.ingredients.toLowerCase();
        const lowerGeneric = drug.genericName.toLowerCase();

        for (const allergy of allergyList) {
            if (allergy.length > 2 && (lowerIngredients.includes(allergy) || lowerGeneric.includes(allergy) || allergy.includes(lowerGeneric))) {
                return { score: 0, isSafe: false, filterReason: `Chống chỉ định: Dị ứng với ${allergy}`, warnings: [] };
            }
        }
    }

    // Rule 4: Bệnh nền
    if (profile.chronicConditions) {
        try {
            const notForConditions: string[] = JSON.parse(drug.notForConditions || '[]');
            const lowerConditions = profile.chronicConditions.toLowerCase();

            for (const condition of notForConditions) {
                if (lowerConditions.includes(condition.toLowerCase())) {
                    return { score: 0, isSafe: false, filterReason: `Chống chỉ định: Bệnh nhân có "${condition}"`, warnings: [] };
                }
            }
        } catch {}
    }

    // Rule 5: Thuốc tương tác
    if (profile.currentMedicines.length > 0) {
        try {
            const interactsWith: string[] = JSON.parse(drug.interactsWith || '[]');
            for (const interaction of interactsWith) {
                const lowerInteraction = interaction.toLowerCase();
                for (const currentMed of profile.currentMedicines) {
                    if (currentMed.toLowerCase().includes(lowerInteraction) || lowerInteraction.includes(currentMed.toLowerCase())) {
                        score -= 20;
                        warnings.push(`Cảnh báo tương tác thuốc: ${drug.name} có thể tương tác với ${currentMed}`);
                        break;
                    }
                }
            }
        } catch {}
    }

    score = Math.max(0, Math.min(100, score));
    return { score, isSafe: true, warnings };
}

// ==================== HISTORY SCORING (CF-Enhanced) ====================

/**
 * Tính historyScore với 3 tầng ưu tiên:
 *
 * Tầng 1 — Personal:      User đã dùng thuốc này trước đây → dùng lịch sử cá nhân
 * Tầng 2 — Collaborative: Không có lịch sử cá nhân → hỏi nhóm peers tương tự
 * Tầng 3 — Neutral:       Không có gì → trả về 50 trung lập
 *
 * @param drugId              - ID thuốc cần tính điểm
 * @param history             - Lịch sử cá nhân của user hiện tại
 * @param globalCollaborativeScore - Điểm CF (Phase 2)
 */
function calculateHistoryScore(
    drugId: string,
    history: DrugHistoryRecord[],
    globalCollaborativeScore: number | null | undefined
): { score: number; reasons: string[] } {
    const reasons: string[] = [];
    const drugHistory = history.filter(h => h.drugId === drugId);

    // ── Tầng 1: Personal History (ưu tiên cao nhất) ──────────────
    // Nếu user đã từng dùng thuốc này → luôn dùng kinh nghiệm cá nhân
    if (drugHistory.length > 0) {
        let totalScore = 0;
        let count = 0;

        for (const record of drugHistory) {
            let recordScore = 50;
            switch (record.outcome) {
                case 'EFFECTIVE':
                    recordScore = 85 + (record.rating - 3) * 5;
                    reasons.push(`Từng hiệu quả (⭐${record.rating}/5)`);
                    break;
                case 'PARTIALLY_EFFECTIVE':
                    recordScore = 60 + (record.rating - 3) * 3;
                    reasons.push('Từng có tác dụng một phần');
                    break;
                case 'NOT_EFFECTIVE':
                    recordScore = 25;
                    reasons.push('Từng không hiệu quả (-25đ)');
                    break;
                case 'SIDE_EFFECT':
                    recordScore = 5;
                    reasons.push('⚠️ Đã gặp tác dụng phụ (-45đ)');
                    break;
                case 'NOT_TAKEN':
                    recordScore = 45;
                    break;
            }
            totalScore += recordScore;
            count++;
        }

        const avgScore = count > 0 ? totalScore / count : 50;
        const frequencyBonus = Math.min((count - 1) * 3, 15);
        const finalScore = Math.min(100, avgScore + frequencyBonus);
        return { score: Math.max(0, finalScore), reasons };
    }

    // ── Tầng 2: Collaborative Filtering (Phase 2 - Cached O(1)) ─────────────────
    // User chưa có lịch sử → dùng điểm cộng đồng đã tính sẵn
    if (globalCollaborativeScore !== null && globalCollaborativeScore !== undefined) {
        let confidence = '(trung bình)';
        if (globalCollaborativeScore >= 80) confidence = '(khen ngợi)';
        else if (globalCollaborativeScore <= 30) confidence = '(cảnh báo)';

        reasons.push(`Đánh giá thực tế từ cộng đồng: ${globalCollaborativeScore}/100đ ${confidence}`);
        return { score: globalCollaborativeScore, reasons };
    }

    // ── Tầng 3: Neutral Fallback ──────────────────────────────────
    // Không có dữ liệu nào → điểm trung lập, không ảnh hưởng gì
    return { score: 50, reasons: ['Chưa có lịch sử dùng thuốc và chưa đủ dữ liệu cộng đồng'] };
}

// ==================== MAIN ENGINE (VECTOR SEARCH AI) ====================

/**
 * Hàm chính của Recommendation Engine.
 * Định dạng lại thành Async vì quy trình bao gồm gọi OpenAI Embedding API
 * và query Vector Search bằng PostgreSQL
 */
export async function runRecommendationEngine(
    symptoms: string,
    profile: UserProfile,
    availableDrugs: DrugData[],
    drugHistory: DrugHistoryRecord[] = [],
): Promise<ScoringResult> {
    const startTime = Date.now();
    const recommended: ScoredDrug[] = [];
    const excluded: ScoredDrug[] = [];

    console.log(`[ScoringEngine] Bắt đầu lấy Embedding cho symptoms: "${symptoms}"`);

    // ─── Bước 1: Vector Pre-filter (Top-K ANN Search) ───────────────────────────
    // Big Tech pattern: không load toàn bộ table vào RAM.
    // Thực hiện ANN search trước để lấy top 50 candidates, sau đó mới fetch chi tiết.
    const TOP_CANDIDATES = 50;
    const similarityMap = new Map<string, number>();
    let useVectorSearch = false;

    try {
        const symptomEmbedding = await generateEmbedding(symptoms);
        const embeddingStr = JSON.stringify(symptomEmbedding);

        // Query pgvector: ORDER BY cosine distance, LIMIT 50
        // Chỉ làm việc với 50 thuốc phù hợp nhất thay vì toàn bộ table
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
        console.log(`[ScoringEngine] Vector search: ${topCandidates.length} candidates (/${availableDrugs.length} total)`);

    } catch (err: any) {
        // Graceful fallback: keyword matching khi hết Gemini quota
        console.warn(`[ScoringEngine] Vector search lỗi → Keyword fallback:`, err.message);
        const lowerSymptoms = symptoms.toLowerCase();
        const symptomWords = lowerSymptoms.split(/[\s,.;]+/).filter(w => w.length > 3);

        availableDrugs.forEach(drug => {
            let matches = 0;
            const textToSearch = `${drug.indications} ${drug.viIndications || ''} ${drug.category} ${drug.name}`.toLowerCase();
            symptomWords.forEach(word => { if (textToSearch.includes(word)) matches++; });
            const pseudoSim = Math.min(0.85, 0.50 + (matches * 0.05));
            similarityMap.set(drug.id, pseudoSim);
        });
    }

    // ─── Bước 2: Lấy danh sách thực tế ─────────────────────────────────────────
    // Nếu vector search thành công: chỉ xét 50 candidates từ similarity map
    // Nếu fallback: xét toàn bộ (giống trước)
    const drugsToScore = useVectorSearch
        ? availableDrugs.filter(d => similarityMap.has(d.id))
        : availableDrugs;

    // ─── Bước 3: Set drugIds user đã có personal history ─────────────────────
    const personalHistoryDrugIds = new Set(drugHistory.map(h => h.drugId));
    const hasPersonalHistory = personalHistoryDrugIds.size > 0;

    for (const drug of drugsToScore) {
        // SAFETY CHECK FIRST (hard filter — không bao giờ thay đổi điều này)
        const safetyResult = calculateSafetyScore(drug, profile);

        if (!safetyResult.isSafe) {
            excluded.push({
                drugId: drug.id,
                drugName: drug.name,
                genericName: drug.genericName,
                category: drug.category,
                profileScore: 0, safetyScore: 0, historyScore: 0, finalScore: 0,
                rank: 0, isRecommended: false,
                filterReason: safetyResult.filterReason,
                ingredients: drug.ingredients,
                indications: drug.indications,
                contraindications: drug.contraindications,
                sideEffects: drug.sideEffects,
                viSummary: drug.viSummary,
                viIndications: drug.viIndications,
                viWarnings: drug.viWarnings,
            });
            continue;
        }

        const similarityFactor = similarityMap.get(drug.id) ?? 0.1;

        // PROFILE SCORING
        const profileResult = calculateProfileScore(drug, profile, similarityFactor);

        // HISTORY SCORING (CF-enhanced Phase 2)
        const drugHasPersonalRecord = personalHistoryDrugIds.has(drug.id);
        const historyResult = calculateHistoryScore(
            drug.id,
            drugHistory,
            // Truyền O(1) CF score cho thuốc chưa có record cá nhân
            drugHasPersonalRecord ? undefined : drug.collaborativeScore
        );

        // DYNAMIC WEIGHTS: tăng historyScore khi có personal data
        const historyWeight = drugHasPersonalRecord
            ? WEIGHTS.HISTORY_PERSONAL  // 30% — personal data, rất có giá trị
            : WEIGHTS.HISTORY_COLD;     // 20% — CF hoặc neutral

        // Adjust profile/safety proportionally khi historyWeight tăng
        const remainingWeight = 1 - historyWeight;
        const profileW = WEIGHTS.PROFILE / (WEIGHTS.PROFILE + WEIGHTS.SAFETY) * remainingWeight;
        const safetyW  = WEIGHTS.SAFETY  / (WEIGHTS.PROFILE + WEIGHTS.SAFETY) * remainingWeight;

        let finalScore =
            (profileResult.score * profileW) +
            (safetyResult.score * safetyW) +
            (historyResult.score * historyWeight);

        // ── EPSILON-GREEDY (Exploration Factor) ──
        // Nhằm tránh lỗi "Khởi Đầu Lạnh" (Cold Start) cho Thuốc, ta lấy tỷ lệ 5% cố tình 
        // boost điểm một chút cho các thuốc chưa ai dùng (history score = 50 Neutral), 
        // ĐỂ CHÚNG GỢI Ý LÊN TRÊN nhằm thu thập Rate.
        const EPSILON = 0.05; // 5% xác suất đẩy thuốc lạ lên
        if (historyResult.score === 50 && Math.random() < EPSILON) {
            finalScore += 6.5; // Đẩy lên nửa bậc để có cơ hội lọt Top 5 lọt vô màn user
        }

        recommended.push({
            drugId: drug.id,
            drugName: drug.name,
            genericName: drug.genericName,
            category: drug.category,
            profileScore: Math.round(profileResult.score),
            safetyScore: Math.round(safetyResult.score),
            historyScore: Math.round(historyResult.score),
            finalScore: Math.round(finalScore),
            rank: 0,
            isRecommended: true,
            ingredients: drug.ingredients,
            indications: drug.indications,
            contraindications: drug.contraindications,
            sideEffects: drug.sideEffects,
            viSummary: drug.viSummary,
            viIndications: drug.viIndications,
            viWarnings: drug.viWarnings,
        });
    }

    // SORT & RANK
    recommended.sort((a, b) => b.finalScore - a.finalScore);
    recommended.forEach((drug, index) => { drug.rank = index + 1; });

    // TOP 5 — gửi cho AI giải thích
    const TOP_N = 5;
    return {
        recommended: recommended.slice(0, TOP_N),
        excluded,
        totalCandidates: availableDrugs.length,
        processingMs: Date.now() - startTime,
    };
}

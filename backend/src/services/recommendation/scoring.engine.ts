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

import prisma from '../../config/prisma.js';
import { generateEmbedding } from '../embedding.service.js';

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
    profileScore: number;    // = relevanceScore 0-100 (AI symptom similarity)
    safetyScore: number;     // = safetyBonus only (0-5) — dùng nội bộ
    baseSafetyScore: number; // raw DB safety 0-100 — dùng để display UI
    historyScore: number;    // personal/CF/neutral 0-100
    evidenceScore: number;   // Disease-ATC match 0-100
    finalScore: number;      // weighted composite 0-100
    rank: number;
    isRecommended: boolean;
    filterReason?: string;
    safetyWarnings: string[];
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
// =============================================================
// PATTERN → DRUG EXCLUSION MAP (dùng trong SafetyGate v2.1)
// =============================================================
// Khi NLU detect một clinical pattern, map này xác định:
//   - excludeIngredients: Tên hoạt chất (lowercase) bị block hoàn toàn
//   - excludeCategories:  Drug category bị block hoàn toàn
//
// Nguồn copy từ PATTERN_DRUG_EXCLUSIONS trong medical-nlu.service.ts
// để giữ scoring engine tự đủ (không circular import).
// Đồng bộ tay khi cập nhật PATTERN_DRUG_EXCLUSIONS.
// ─────────────────────────────────────────────────────────────
const SCORING_PATTERN_EXCLUSIONS: Record<string, {
    excludeIngredients: string[];
    excludeCategories:  string[];
    filterReason:       string;
}> = {
    'DENGUE_RISK': {
        excludeIngredients: ['ibuprofen', 'aspirin', 'naproxen', 'diclofenac', 'mefenamic'],
        excludeCategories:  [],
        filterReason: 'Chống chỉ định: NSAID/Aspirin khi nghi ngờ Sốt Xuất Huyết Dengue — có thể gây xuất huyết nặng (WHO guideline)',
    },
    'ACS': {
        excludeIngredients: ['pseudoephedrine', 'phenylephrine', 'ephedrine'],
        excludeCategories:  ['DECONGESTANT'],
        filterReason: 'Chống chỉ định: Thuốc co mạch khi nghi ngờ Hội chứng vành cấp',
    },
    'HYPERTENSIVE_CRISIS': {
        excludeIngredients: ['pseudoephedrine', 'phenylephrine', 'ibuprofen', 'naproxen'],
        excludeCategories:  ['DECONGESTANT'],
        filterReason: 'Chống chỉ định: NSAIDs và thuốc co mạch làm tăng huyết áp thêm',
    },
    'RESPIRATORY_FAIL': {
        excludeIngredients: ['antihistamine', 'diphenhydramine', 'promethazine'],
        excludeCategories:  [],
        filterReason: 'Chống chỉ định: Kháng histamine ức chế thêm trung tâm hô hấp',
    },
};

// Bộ từ điển ánh xạ đồng nghĩa hoạt chất & nhóm chéo
const DRUG_SYNONYMS: Record<string, string[]> = {
    'paracetamol': ['acetaminophen', 'panadol', 'hapacol', 'efferalgan', 'tiffy', 'decolgen', 'pamin', 'acetominophen'],
    'acetaminophen': ['paracetamol', 'panadol', 'hapacol', 'efferalgan', 'tiffy', 'decolgen', 'pamin', 'acetominophen'],
    'aspirin': ['acetylsalicylic acid', 'asa', 'aspirine'],
    'acetylsalicylic acid': ['aspirin', 'asa', 'aspirine'],
    'ibuprofen': ['advil', 'motrin', 'brufen', 'gofen'],
    'naproxen': ['aleve', 'anaprox'],
    'diclofenac': ['voltaren', 'cataflam'],
    'mefenamic acid': ['ponstan'],
    'mefenamic': ['ponstan'],
    'chlorpheniramine': ['tadarit', 'allergy'],
    'diphenhydramine': ['benadryl'],
    'promethazine': ['phenergan'],
    'loratadine': ['claritin'],
    'cetirizine': ['zyrtec'],
    'fexofenadine': ['telfast'],
    'ranitidine': ['zantac'],
    'cimetidine': ['tagamet'],
    'famotidine': ['pepcid'],
    'omeprazole': ['prilosec', 'losec'],
    'esomeprazole': ['nexium'],
    'lansoprazole': ['prevacid'],
    'pantoprazole': ['protonix'],
    'simethicone': ['gas-x', 'gasx', 'mylanta'],
    'loperamide': ['imodiuum', 'imodium'],
    'bisacodyl': ['dulcolax'],
    'pseudoephedrine': ['sudafed'],
    'phenylephrine': ['neophryn'],
    'vitamin c': ['ascorbic acid', 'ceelin'],
    'ascorbic acid': ['vitamin c', 'ceelin'],
    'nsaid': ['ibuprofen', 'naproxen', 'diclofenac', 'mefenamic', 'ketoprofen', 'aspirin', 'meloxicam', 'celecoxib']
};

// Ánh xạ bệnh nền Việt - Anh để kiểm tra chống chỉ định
const CHRONIC_CONDITION_MAP: Record<string, string[]> = {
    'suy than': ['kidney disease', 'renal impairment', 'renal failure', 'nephropathy', 'kidney failure', 'renal'],
    'than': ['kidney', 'renal', 'nephro'],
    'suy gan': ['liver disease', 'hepatic impairment', 'hepatic failure', 'cirrhosis', 'liver failure', 'liver', 'hepatic'],
    'gan': ['liver', 'hepatic'],
    'hen': ['asthma', 'bronchospasm'],
    'suyen': ['asthma', 'bronchospasm'],
    'hen phe quan': ['asthma', 'bronchospasm'],
    'da day': ['ulcer', 'stomach', 'gastric', 'gerd', 'peptic', 'stomach ulcer', 'gastritis'],
    'viem loet da day': ['ulcer', 'stomach', 'gastric', 'gerd', 'peptic', 'stomach ulcer', 'gastritis'],
    'dau da day': ['ulcer', 'stomach', 'gastric', 'gerd', 'peptic', 'stomach ulcer', 'gastritis'],
    'tieu duong': ['diabetes', 'diabetic', 'hyperglycemia'],
    'dai thao duong': ['diabetes', 'diabetic', 'hyperglycemia'],
    'huyet ap': ['hypertension', 'blood pressure', 'hypertensive'],
    'cao huyet ap': ['hypertension', 'blood pressure', 'hypertensive'],
    'tang huyet ap': ['hypertension', 'blood pressure', 'hypertensive'],
    'tim mach': ['heart', 'cardiac', 'coronary', 'heart failure', 'cardiovascular'],
    'suy tim': ['heart failure', 'cardiac', 'cardiovascular'],
    'benh tim': ['heart', 'cardiac', 'coronary', 'heart failure', 'cardiovascular']
};

function removeVietnameseTones(str: string): string {
    return str
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/đ/g, 'd')
        .replace(/Đ/g, 'D')
        .toLowerCase();
}

export function executeSafetyGate(
    drug: DrugData,
    profile: UserProfile,
    patternWarnings: string[] = [],   // [v2.1] Clinical pattern keys từ NLU (e.g. ['DENGUE_RISK'])
): { isSafe: boolean; filterReason?: string; warnings: string[]; safetyBonus: number } {

    // 1. Phụ nữ mang thai
    if (profile.isPregnant && drug.notForPregnant) {
        return { isSafe: false, filterReason: 'Chống chỉ định: Phụ nữ đang mang thai', warnings: [], safetyBonus: 0 };
    }

    // 2. Phụ nữ cho con bú
    if (profile.isBreastfeeding && drug.notForNursing) {
        return { isSafe: false, filterReason: 'Chống chỉ định: Phụ nữ đang cho con bú', warnings: [], safetyBonus: 0 };
    }

    // 3. Dị ứng (có tra cứu đồng nghĩa & dị ứng chéo)
    if (profile.allergies) {
        const allergyList = profile.allergies.toLowerCase().split(/[,;]+/).map(a => a.trim()).filter(a => a.length > 2);
        const lowerIngredients = drug.ingredients.toLowerCase();
        const lowerGeneric     = drug.genericName.toLowerCase();

        for (const allergy of allergyList) {
            const expandedAllergies = [allergy];
            
            Object.entries(DRUG_SYNONYMS).forEach(([key, synonyms]) => {
                if (allergy.includes(key) || key.includes(allergy)) {
                    expandedAllergies.push(key, ...synonyms);
                }
                synonyms.forEach(syn => {
                    if (allergy.includes(syn) || syn.includes(allergy)) {
                        expandedAllergies.push(key, ...synonyms);
                    }
                });
            });

            const uniqueAllergies = Array.from(new Set(expandedAllergies))
                .map(a => a.toLowerCase().trim())
                .filter(a => a.length > 2);

            for (const expandedAllergy of uniqueAllergies) {
                if (
                    lowerIngredients.includes(expandedAllergy) ||
                    lowerGeneric.includes(expandedAllergy) ||
                    expandedAllergy.includes(lowerGeneric)
                ) {
                    return { 
                        isSafe: false, 
                        filterReason: `Chống chỉ định: Dị ứng với "${allergy}" (phát hiện hoạt chất tương đương: ${expandedAllergy})`, 
                        warnings: [], 
                        safetyBonus: 0 
                    };
                }
            }
        }
    }

    // 4. Bệnh lý nền (hỗ trợ dịch song ngữ)
    if (profile.chronicConditions) {
        try {
            const notForConditions: string[] = JSON.parse(drug.notForConditions || '[]');
            const rawConditions = profile.chronicConditions.toLowerCase();
            const normalizedConditions = removeVietnameseTones(profile.chronicConditions);

            const expandedConditionKeywords = [rawConditions, normalizedConditions];
            
            Object.entries(CHRONIC_CONDITION_MAP).forEach(([viKey, enSyns]) => {
                if (normalizedConditions.includes(viKey)) {
                    expandedConditionKeywords.push(...enSyns);
                }
            });

            for (const condition of notForConditions) {
                const lowerCond = condition.toLowerCase();
                const isMatched = expandedConditionKeywords.some(kw => 
                    kw.includes(lowerCond) || lowerCond.includes(kw)
                );

                if (isMatched) {
                    return { 
                        isSafe: false, 
                        filterReason: `Chống chỉ định: Bệnh nhân có tiền sử bệnh lý "${condition}"`, 
                        warnings: [], 
                        safetyBonus: 0 
                    };
                }
            }
        } catch { /* JSON parse fail → skip */ }
    }

    // 5. Độ tuổi tối thiểu
    if (drug.minAge !== null && profile.age !== null && profile.age < drug.minAge) {
        return {
            isSafe: false,
            filterReason: `Chống chỉ định: Thuốc chỉ dùng cho trẻ ≥${drug.minAge} tuổi (bệnh nhân: ${profile.age % 1 === 0 ? profile.age : (profile.age * 12).toFixed(0) + ' tháng'})`,
            warnings: [],
            safetyBonus: 0,
        };
    }

    // 6. Độ tuổi tối đa
    if (drug.maxAge !== null && profile.age !== null && profile.age > drug.maxAge) {
        return {
            isSafe: false,
            filterReason: `Chống chỉ định: Thuốc chỉ dùng cho bệnh nhân ≤${drug.maxAge} tuổi`,
            warnings: [],
            safetyBonus: 0,
        };
    }

    // 7. Nhóm thuốc nguy hiểm theo bối cảnh lâm sàng (v dụ: Nghi ngờ sốt xuất huyết loại trừ NSAIDs)
    if (patternWarnings.length > 0) {
        const lowerIngredients = drug.ingredients.toLowerCase();
        const lowerGeneric     = drug.genericName.toLowerCase();

        for (const patternKey of patternWarnings) {
            const exclusion = SCORING_PATTERN_EXCLUSIONS[patternKey];
            if (!exclusion) continue;

            // Kiểm tra theo hoạt chất
            const matchedIngredient = exclusion.excludeIngredients.find(excl =>
                lowerIngredients.includes(excl) || lowerGeneric.includes(excl)
            );
            if (matchedIngredient) {
                return { isSafe: false, filterReason: exclusion.filterReason, warnings: [], safetyBonus: 0 };
            }

            // Kiểm tra theo danh mục thuốc
            if (exclusion.excludeCategories.includes(drug.category)) {
                return { isSafe: false, filterReason: exclusion.filterReason, warnings: [], safetyBonus: 0 };
            }
        }
    }

    // 8. Loại trừ mỹ phẩm, kem dưỡng ẩm và kem chống nắng thông thường
    const drugNameLower = drug.name.toLowerCase();
    const genericLower  = drug.genericName.toLowerCase();
    const indicationsLower = drug.indications.toLowerCase();
    
    const isCosmeticOrSunscreen = 
        drugNameLower.includes('sunscreen') || 
        drugNameLower.includes('moisturizer') || 
        drugNameLower.includes('makeup') || 
        drugNameLower.includes('foundation') || 
        drugNameLower.includes('beauty balm') || 
        drugNameLower.includes('tinted') ||
        genericLower.includes('octinoxate') || 
        genericLower.includes('avobenzone') || 
        genericLower.includes('homosalate') || 
        genericLower.includes('octisalate') || 
        genericLower.includes('octocrylene') ||
        genericLower.includes('oxybenzone') ||
        indicationsLower.includes('helps prevent sunburn') ||
        indicationsLower.includes('sun protection');

    if (isCosmeticOrSunscreen) {
        return {
            isSafe: false,
            filterReason: 'Sản phẩm chống nắng/mỹ phẩm không có chỉ định điều trị cho các triệu chứng lâm sàng hiện tại.',
            warnings: [],
            safetyBonus: 0,
        };
    }

    // Cảnh báo tương tác thuốc
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

    // Cảnh báo dị ứng chéo (Aspirin dị ứng chéo với các NSAID khác)
    if (profile.allergies) {
        const allergyLower = profile.allergies.toLowerCase();
        const hasAspirinAllergy = allergyLower.includes('aspirin') || allergyLower.includes('acetylsalicylic');
        const isNSAIDDrug = ['ibuprofen', 'naproxen', 'diclofenac', 'mefenamic', 'ketoprofen']
            .some(nsaid => drug.ingredients.toLowerCase().includes(nsaid) || drug.genericName.toLowerCase().includes(nsaid));
        if (hasAspirinAllergy && isNSAIDDrug) {
            warnings.push(`⚠️ Lưu ý cross-reactivity: Bệnh nhân dị ứng Aspirin có ~10-15% nguy cơ phản ứng với ${drug.name} (NSAID) — Hỏi bác sĩ/dược sĩ trước khi dùng`);
        }
    }

    // Điểm thưởng an toàn (tối đa +5 điểm)
    let safetyBonus = 0;
    if (drug.baseSafetyScore >= 90) safetyBonus = 5;
    else if (drug.baseSafetyScore >= 80) safetyBonus = 2.5;

    return { isSafe: true, warnings, safetyBonus };
}

// =============================================================
// STEP 2: RELEVANCE SCORE (Khớp triệu chứng)
// =============================================================
/**
 * Đo mức độ phù hợp của thuốc với triệu chứng của bệnh nhân.
 * Sử dụng hàm Sigmoid Stretch để ánh xạ độ tương đồng Cosine sang thang điểm 0-100,
 * giúp tối ưu hóa khoảng cách phân biệt giữa các ứng viên thuốc.
 */

/** Sigmoid helper — normalize về [0,1] trong khoảng [SIM_MIN, SIM_MAX] */
const SIM_MIN = 0.40;  // Dưới ngưỡng này → 0đ
const SIM_MAX = 0.95;  // Trên ngưỡng này → 100đ
const SIG_K   = 12;    // Độ dốc (steepness)
const SIG_X0  = 0.55;  // Inflection point (50đ)

function sigmoidStretch(sim: number): number {
    const sig    = (x: number) => 1 / (1 + Math.exp(-SIG_K * (x - SIG_X0)));
    const sigMin = sig(SIM_MIN); // ~0.164
    const sigMax = sig(SIM_MAX); // ~0.992
    const normalized = (sig(sim) - sigMin) / (sigMax - sigMin);
    return Math.max(0, Math.min(100, normalized * 100));
}

function calculateRelevanceScore(
    drug: DrugData,
    profile: UserProfile,
    similarityFactor: number
): { score: number; reasons: string[] } {
    const reasons: string[] = [];

    // [v2.1] Sigmoid stretch — giữ signal phân biệt tốt hơn linear
    let score = sigmoidStretch(similarityFactor);

    if (similarityFactor >= 0.75) {
        reasons.push(`Khớp triệu chứng AI rất cao: ${(similarityFactor * 100).toFixed(1)}%`);
    } else if (similarityFactor >= 0.60) {
        reasons.push(`Khớp triệu chứng AI khá: ${(similarityFactor * 100).toFixed(1)}%`);
    } else if (similarityFactor >= 0.45) {
        reasons.push(`Khớp triệu chứng AI vừa phải: ${(similarityFactor * 100).toFixed(1)}%`);
    }

    // Age-compatible bonus (+5đ khi user có nhập tuổi và drug phù hợp)
    // [v2.1] Xóa age penalty — SafetyGate đã handle cứng, penalty là dead code
    if (profile.age !== null && drug.minAge === null && drug.maxAge === null) {
        score = Math.min(100, score + 3); // nhỏ hơn v2.0 (5→3) để tránh inflate
    }

    return { score: Math.max(0, Math.min(100, score)), reasons };
}

// =============================================================
// STEP 3: EVIDENCE SCORE (Khớp mã ATC điều trị bệnh dự đoán)
// =============================================================
/**
 * So khớp tiền tố 3 ký tự của mã ATC của thuốc và bệnh dự đoán từ NLU.
 * Điểm số tương ứng với xác suất dự đoán bệnh lý của bệnh nhân (0 - 100).
 */
function calculateEvidenceScore(
    drug: DrugData,
    predictedDiseases: PredictedDisease[]
): { score: number; reasons: string[] } {
    const reasons: string[] = [];

    // Không có dự đoán bệnh -> trung lập
    if (predictedDiseases.length === 0) {
        return { score: 50, reasons: ['Không có dữ liệu dự đoán bệnh — điểm trung lập'] };
    }

    const drugAtcCodes = CATEGORY_TO_ATC[drug.category] ?? [];

    if (drugAtcCodes.length === 0) {
        return { score: 35, reasons: ['Danh mục thuốc chưa có ATC code — không đánh giá được'] };
    }

    let bestMatchScore = 0;

    for (const disease of predictedDiseases) {
        if (!disease.atcCodes || disease.atcCodes.length === 0) continue;

        // Khớp 3 ký tự đầu mã ATC (ví dụ: N02 khớp N02B)
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
                reasons.length = 0;
                reasons.push(`Phù hợp điều trị: "${disease.nameVi}" (${(disease.probability * 100).toFixed(0)}% xác suất)`);
            }
        }
    }

    if (bestMatchScore === 0) {
        reasons.push('Không phải thuốc đặc trị cho bệnh dự đoán');
        return { score: 15, reasons };
    }

    return { score: Math.min(100, bestMatchScore), reasons };
}

// =============================================================
// STEP 4: HISTORY SCORE (Lịch sử sử dụng & Đánh giá cộng đồng)
// =============================================================
/**
 * Phân tầng chấm điểm lịch sử:
 * 1. Lịch sử cá nhân (nếu có, ưu tiên cao nhất)
 * 2. Đánh giá cộng đồng (Collaborative Filtering fallback)
 * 3. Điểm trung lập (50 điểm)
 */
function calculateHistoryScore(
    drugId: string,
    history: DrugHistoryRecord[],
    globalCollaborativeScore: number | null | undefined
): { score: number; reasons: string[] } {
    const reasons: string[] = [];
    const drugHistory = history.filter(h => h.drugId === drugId);

    // 1. Lịch sử sử dụng cá nhân
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
    patternWarnings:   string[]            = [],  // [v2.1] NLU clinical pattern keys (e.g. ['DENGUE_RISK'])
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
        // [v2.1] patternWarnings được truyền vào để block NSAID khi DENGUE_RISK, v.v.
        const safetyResult = executeSafetyGate(drug, profile, patternWarnings);

        if (!safetyResult.isSafe) {
            excluded.push({
                drugId:       drug.id,
                drugName:     drug.name,
                genericName:  drug.genericName,
                category:     drug.category,
                profileScore: 0, safetyScore: 0, baseSafetyScore: drug.baseSafetyScore,
                historyScore: 0, evidenceScore: 0, finalScore: 0,
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
        // [v2.1 GUARD] Giảm EPSILON 0.05→0.02 và boost 6.5→3.0 để an toàn hơn
        // trong bối cảnh y tế (medical context cần consistency, không cần exploration mạnh).
        // Chỉ boost drug chưa có personal history (score=50 neutral).
        // Đây là thu thập cold-start feedback, không ảnh hưởng top-2 đáng kể.
        const EPSILON = 0.02;
        if (historyResult.score === 50 && Math.random() < EPSILON) {
            finalScore += 3.0;
        }

        finalScore = Math.max(0, Math.min(100, finalScore));

        recommended.push({
            drugId:        drug.id,
            drugName:      drug.name,
            genericName:   drug.genericName,
            category:      drug.category,
            profileScore:  Math.round(relevanceResult.score),    // relevance 0-100
            safetyScore:   Math.round(safetyResult.safetyBonus), // bonus 0-5 (internal)
            baseSafetyScore: drug.baseSafetyScore,               // raw DB safety 0-100 (for UI)
            historyScore:  Math.round(historyResult.score),
            evidenceScore: Math.round(evidenceResult.score),
            finalScore:    Math.round(finalScore),
            rank:          0,
            isRecommended: true,
            safetyWarnings: safetyResult.warnings,
            ingredients:    drug.ingredients,
            indications:    drug.indications,
            contraindications: drug.contraindications,
            sideEffects:    drug.sideEffects,
            viSummary:      drug.viSummary,
            viIndications:  drug.viIndications,
            viWarnings:     drug.viWarnings,
        });
    }

    // ─── BƯỚC 5: Sort ban đầu ─────────────────────────────────────────────────
    recommended.sort((a, b) => b.finalScore - a.finalScore);

    // ─── BƯỚC 6: Diversity Reranking ──────────────────────────────────────────
    // [v2.1 NEW] Nếu top-N có nhiều drug cùng category (e.g., 3 ANALGESIC),
    // trừ 12đ cho drug cùng category đứng sau drug đầu tiên của category đó.
    // Đảm bảo top-5 đa dạng hơn về nhóm thuốc — UX tốt hơn cho user.
    //
    // Nguồn: GoodRx Diversity Algorithm (post-rank category deduplication),
    //        Amazon Product Recommendation MMR (Maximal Marginal Relevance).
    //
    // ⚠️ Chỉ áp dụng sau rank >= 2 để KHÔNG đụng đến thuốc phù hợp nhất (#1).
    const seenCategories = new Map<string, number>(); // category → count
    for (const drug of recommended) {
        const count = seenCategories.get(drug.category) ?? 0;
        if (count >= 1) {
            // Penalize: giảm score, nhưng không xuống dưới 0
            drug.finalScore = Math.max(0, drug.finalScore - 12);
        }
        seenCategories.set(drug.category, count + 1);
    }

    // Re-sort sau diversity penalty
    recommended.sort((a, b) => b.finalScore - a.finalScore);
    recommended.forEach((drug, index) => { drug.rank = index + 1; });

    const processingMs = Date.now() - startTime;
    const TOP_N        = 5;
    const finalRecommended = recommended.slice(0, TOP_N);

    // ─── BƯỚC 7: Multi-drug Interaction Cross-Check (Top N) ──────────────────
    // [v3.0 NEW] Phân tích tương tác chéo giữa các thuốc trong danh sách Top N được đề xuất.
    // Nếu hai thuốc có tương tác chéo, bổ sung cảnh báo trực tiếp vào `safetyWarnings` của cả hai.
    const checkMatch = (interactList: string[], otherDrug: ScoredDrug) => {
        const otherGeneric = otherDrug.genericName.toLowerCase();
        const otherIngredients = otherDrug.ingredients.toLowerCase();
        return interactList.some(item => {
            const itemLower = item.toLowerCase();
            return otherGeneric.includes(itemLower) ||
                   otherIngredients.includes(itemLower) ||
                   itemLower.includes(otherGeneric);
        });
    };

    // Pre-parse interactsWith lists to avoid O(N^2) JSON parsing and database queries
    const interactsWithMap = new Map<string, string[]>();
    for (const drug of finalRecommended) {
        const rawDrug = availableDrugs.find(d => d.id === drug.drugId);
        if (rawDrug?.interactsWith) {
            try {
                interactsWithMap.set(drug.drugId, JSON.parse(rawDrug.interactsWith));
            } catch {
                interactsWithMap.set(drug.drugId, []);
            }
        } else {
            interactsWithMap.set(drug.drugId, []);
        }
    }

    for (let i = 0; i < finalRecommended.length; i++) {
        const drugA = finalRecommended[i];
        const interactsWithA = interactsWithMap.get(drugA.drugId) ?? [];

        for (let j = i + 1; j < finalRecommended.length; j++) {
            const drugB = finalRecommended[j];
            const interactsWithB = interactsWithMap.get(drugB.drugId) ?? [];

            const hasInteraction = checkMatch(interactsWithA, drugB) || checkMatch(interactsWithB, drugA);

            if (hasInteraction) {
                const msg = `⚠️ Lưu ý tương tác: ${drugA.drugName} có thể tương tác với thuốc đề xuất khác là ${drugB.drugName} — Tránh dùng đồng thời hoặc tham khảo ý kiến dược sĩ`;
                
                drugA.safetyWarnings = drugA.safetyWarnings ?? [];
                if (!drugA.safetyWarnings.includes(msg)) {
                    drugA.safetyWarnings.push(msg);
                }

                drugB.safetyWarnings = drugB.safetyWarnings ?? [];
                if (!drugB.safetyWarnings.includes(msg)) {
                    drugB.safetyWarnings.push(msg);
                }
            }
        }
    }

    console.log(
        `[ScoringEngine v2] DONE in ${processingMs}ms | ` +
        `Recommended: ${recommended.length} | Excluded: ${excluded.length} | ` +
        `Top drug: ${recommended[0]?.drugName ?? 'N/A'} (score: ${recommended[0]?.finalScore ?? 0})`
    );

    return {
        recommended: finalRecommended,
        excluded,
        totalCandidates: availableDrugs.length,
        processingMs,
    };
}

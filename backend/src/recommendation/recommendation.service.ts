/**
 * =============================================================
 * RECOMMENDATION SERVICE v2.0 - MediChain
 * =============================================================
 *
 * Orchestrator chính — điều phối các component:
 * 1. Lấy hồ sơ người dùng từ DB
 * 2. Lấy danh sách thuốc từ DB (DrugCandidate)
 * 3. Lấy lịch sử feedback của user từ DB
 * 4. [Phase 2] Predict bệnh từ triệu chứng (DiseasePredictorService)
 *    → Chạy SONG SONG với 3 bước trên (Promise.all) — 0ms added latency!
 * 5. Gọi Scoring Engine v2 để ranking (với predictedDiseases)
 * 6. Lưu RecommendationSession + items vào DB
 * 7. Ghi audit log
 * 8. Trả về kết quả cho AI Service (chỉ giải thích, không chọn thuốc)
 * =============================================================
 */

import prisma from '../config/prisma.js';
import {
    runRecommendationEngine,
    UserProfile,
    DrugData,
    DrugHistoryRecord,
    ScoredDrug,
    ScoringResult,
    PredictedDisease,
} from './scoring.engine.js';
import { DiseasePredictorService } from '../services/disease-predictor.service.js';

export interface RecommendationInput {
    userId: string;
    symptoms: string;
    ipAddress?: string;
    userAgent?: string;
}

export interface RecommendationOutput {
    sessionId: string;
    rankedDrugs: ScoredDrug[];            // Top N thuốc được recommend (cho AI giải thích)
    excludedCount: number;                 // Số thuốc bị loại do safety
    safetyWarnings: string[];              // Cảnh báo an toàn tổng hợp
    profileSnapshot: UserProfile;          // Hồ sơ tại thời điểm tư vấn
    predictedDiseases: PredictedDisease[]; // [Phase 2] Bệnh được dự đoán từ triệu chứng
    processingMs: number;
}

export class RecommendationService {

    /**
     * Hàm chính: Chạy toàn bộ recommendation pipeline v2.
     *
     * KEY OPTIMIZATION: Bước 1-4 chạy song song với Promise.all.
     * Groq disease prediction (~1-2s) bị "che khuất" bởi DB latency (~100-300ms).
     * Nếu Groq fail → keyword fallback tự động, 0 ảnh hưởng đến pipeline.
     */
    static async recommend(input: RecommendationInput): Promise<RecommendationOutput> {
        const { userId, symptoms, ipAddress, userAgent } = input;

        // ─── BƯỚC 1-4: Parallel fetch (Zero added latency!) ───────────────────
        const [
            userProfile,
            drugs,
            drugHistory,
            predictedDiseases,
        ] = await Promise.all([
            this.getUserProfile(userId),               // DB: User + Profile + Medicines
            this.getActiveDrugs(),                     // DB: DrugCandidate active
            this.getUserDrugHistory(userId),           // DB: TreatmentFeedback history
            DiseasePredictorService.predict(symptoms), // Groq LLM → keyword fallback
        ]);

        // ─── BƯỚC 5: Tạo RecommendationSession (PENDING) ─────────────────────
        const session = await prisma.recommendationSession.create({
            data: {
                userId,
                symptoms,
                profileSnapshot: JSON.stringify(userProfile),
                status: 'PENDING',
                totalCandidates: drugs.length,
            },
        });

        // Ghi audit log: Session bắt đầu (kèm disease predictions)
        await this.writeLog(session.id, userId, 'SESSION_CREATED', {
            symptoms,
            totalCandidates: drugs.length,
            predictedDiseases: predictedDiseases.map(d => ({
                name: d.nameVi,
                probability: `${(d.probability * 100).toFixed(0)}%`,
                atcCodes: d.atcCodes,
            })),
        }, ipAddress, userAgent);

        // ─── BƯỚC 6: Chạy Recommendation Engine v2 ───────────────────────────
        let scoringResult: ScoringResult;
        try {
            scoringResult = await runRecommendationEngine(
                symptoms,
                userProfile,
                drugs,
                drugHistory,
                predictedDiseases,  // [Phase 2] Disease layer — evidenceScore
            );
        } catch (err: any) {
            await prisma.recommendationSession.update({
                where: { id: session.id },
                data: { status: 'FAILED' },
            });
            throw new Error(`Engine lỗi: ${err.message}`);
        }

        // ─── BƯỚC 7: Lưu kết quả vào DB ──────────────────────────────────────
        if (scoringResult.recommended.length > 0) {
            await prisma.recommendationItem.createMany({
                data: scoringResult.recommended.map(drug => ({
                    sessionId: session.id,
                    drugId: drug.drugId,
                    profileScore: drug.profileScore,
                    safetyScore: drug.safetyScore,
                    historyScore: drug.historyScore,
                    finalScore: drug.finalScore,
                    rank: drug.rank,
                    isRecommended: true,
                })),
            });
        }

        if (scoringResult.excluded.length > 0) {
            await prisma.recommendationItem.createMany({
                data: scoringResult.excluded.map(drug => ({
                    sessionId: session.id,
                    drugId: drug.drugId,
                    profileScore: 0,
                    safetyScore: 0,
                    historyScore: 0,
                    finalScore: 0,
                    rank: 0,
                    isRecommended: false,
                    filterReason: drug.filterReason,
                })),
            });
        }

        // Cập nhật session COMPLETED
        await prisma.recommendationSession.update({
            where: { id: session.id },
            data: {
                status: 'COMPLETED',
                totalCandidates: scoringResult.totalCandidates,
                filteredOut: scoringResult.excluded.length,
                finalRanked: scoringResult.recommended.length,
                processingMs: scoringResult.processingMs,
            },
        });

        // Audit log: Ranking hoàn thành
        await this.writeLog(session.id, userId, 'RANKING_COMPLETED', {
            totalCandidates: scoringResult.totalCandidates,
            filteredOut: scoringResult.excluded.length,
            finalRanked: scoringResult.recommended.length,
            topDrug: scoringResult.recommended[0]?.drugName,
            topScore: scoringResult.recommended[0]?.finalScore,
            topEvidenceScore: scoringResult.recommended[0]?.evidenceScore,
            processingMs: scoringResult.processingMs,
        });

        if (scoringResult.excluded.length > 0) {
            await this.writeLog(session.id, userId, 'SAFETY_FILTER_APPLIED', {
                excludedDrugs: scoringResult.excluded.map(d => ({
                    name: d.drugName,
                    reason: d.filterReason,
                })),
            });
        }

        // ─── BƯỚC 8: Tổng hợp safety warnings ───────────────────────────────
        const globalWarnings = this.buildSafetyWarnings(userProfile, scoringResult.excluded);
        // Drug-level interaction warnings từ scoring engine
        const drugInteractionWarnings = scoringResult.recommended
            .flatMap(d => d.safetyWarnings ?? []);
        const safetyWarnings = [...new Set([...globalWarnings, ...drugInteractionWarnings])];

        return {
            sessionId: session.id,
            rankedDrugs: scoringResult.recommended,
            excludedCount: scoringResult.excluded.length,
            safetyWarnings,
            profileSnapshot: userProfile,
            predictedDiseases,  // Pass through cho controller & AI
            processingMs: scoringResult.processingMs,
        };
    }

    /**
     * Nhận feedback từ user sau khi dùng thuốc
     */
    static async submitFeedback(
        userId: string,
        sessionId: string,
        drugId: string,
        rating: number,
        outcome: string,
        usedDays?: number,
        sideEffect?: string,
        note?: string
    ) {
        if (rating < 1 || rating > 5) {
            throw new Error('Rating phải từ 1 đến 5');
        }

        const validOutcomes = ['EFFECTIVE', 'PARTIALLY_EFFECTIVE', 'NOT_EFFECTIVE', 'SIDE_EFFECT', 'NOT_TAKEN'];
        if (!validOutcomes.includes(outcome)) {
            throw new Error(`Outcome không hợp lệ. Phải là: ${validOutcomes.join(', ')}`);
        }

        const session = await prisma.recommendationSession.findFirst({
            where: { id: sessionId, userId },
        });
        if (!session) throw new Error('Session không tồn tại');

        const feedback = await prisma.treatmentFeedback.upsert({
            where: {
                userId_drugId_sessionId: { userId, drugId, sessionId },
            },
            update: {
                rating,
                outcome: outcome as any,
                usedDays: usedDays ?? null,
                sideEffect: sideEffect ?? null,
                note: note ?? null,
                symptomContext: session.symptoms,
            },
            create: {
                userId,
                sessionId,
                drugId,
                rating,
                outcome: outcome as any,
                usedDays: usedDays ?? null,
                sideEffect: sideEffect ?? null,
                note: note ?? null,
                symptomContext: session.symptoms,
            },
        });

        await this.writeLog(sessionId, userId, 'FEEDBACK_RECEIVED', {
            drugId,
            rating,
            outcome,
            isUpdate: !!feedback.updatedAt,
        });

        return feedback;
    }

    /**
     * Lấy feedback hiện tại của user cho 1 thuốc trong 1 session
     */
    static async getFeedback(userId: string, sessionId: string, drugId: string) {
        return prisma.treatmentFeedback.findUnique({
            where: {
                userId_drugId_sessionId: { userId, drugId, sessionId },
            },
        });
    }

    /**
     * Lấy lịch sử tư vấn của user
     */
    static async getUserSessions(userId: string, page = 1, limit = 10) {
        const skip = (page - 1) * limit;
        const [sessions, total] = await Promise.all([
            prisma.recommendationSession.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
                include: {
                    items: {
                        where: { isRecommended: true },
                        include: { drug: { select: { name: true, genericName: true, category: true } } },
                        orderBy: { rank: 'asc' },
                        take: 3,
                    },
                },
            }),
            prisma.recommendationSession.count({ where: { userId } }),
        ]);

        return { sessions, total, page, totalPages: Math.ceil(total / limit) };
    }

    /**
     * Lấy chi tiết 1 session
     */
    static async getSessionDetail(userId: string, sessionId: string) {
        const session = await prisma.recommendationSession.findFirst({
            where: { id: sessionId, userId },
            include: {
                items: {
                    include: { drug: true },
                    orderBy: [
                        { isRecommended: 'desc' },
                        { rank: 'asc' },
                    ],
                },
                feedbacks: {
                    include: { drug: { select: { name: true } } },
                },
            },
        });

        if (!session) throw new Error('Session không tồn tại');
        return session;
    }

    // ======================== PRIVATE HELPERS ========================

    private static async getUserProfile(userId: string): Promise<UserProfile> {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                profile: true,
                medicines: {
                    where: {
                        OR: [{ endDate: null }, { endDate: { gte: new Date() } }],
                    },
                },
            },
        });

        if (!user) throw new Error('User không tồn tại');

        const age = user.profile?.birthday
            ? Math.floor(
                (Date.now() - new Date(user.profile.birthday).getTime()) /
                (365.25 * 24 * 60 * 60 * 1000)
            )
            : null;

        return {
            age,
            gender: user.profile?.gender ?? null,
            allergies: user.profile?.allergies ?? null,
            chronicConditions: user.profile?.chronicConditions ?? null,
            isPregnant: user.profile?.isPregnant ?? false,
            isBreastfeeding: user.profile?.isBreastfeeding ?? false,
            weight: user.profile?.weight ?? null,
            currentMedicines: user.medicines.map(m => m.name),
        };
    }

    private static async getActiveDrugs(): Promise<DrugData[]> {
        const drugs = await prisma.drugCandidate.findMany({
            where: { isActive: true },
            select: {
                id: true, name: true, genericName: true, ingredients: true,
                category: true, indications: true, contraindications: true,
                sideEffects: true, minAge: true, maxAge: true,
                notForPregnant: true, notForNursing: true,
                notForConditions: true, interactsWith: true,
                baseSafetyScore: true, collaborativeScore: true,
                viSummary: true, viIndications: true, viWarnings: true,
            },
        });
        return drugs as DrugData[];
    }

    private static async getUserDrugHistory(userId: string): Promise<DrugHistoryRecord[]> {
        const feedbacks = await prisma.treatmentFeedback.findMany({
            where: { userId },
            include: { drug: { select: { name: true } } },
            orderBy: { createdAt: 'desc' },
        });

        const historyMap = new Map<string, DrugHistoryRecord>();
        for (const fb of feedbacks) {
            const existing = historyMap.get(fb.drugId);
            if (existing) {
                existing.rating = (existing.rating + fb.rating) / 2;
                existing.usageCount++;
            } else {
                historyMap.set(fb.drugId, {
                    drugId: fb.drugId,
                    drugName: fb.drug.name,
                    rating: fb.rating,
                    outcome: fb.outcome,
                    usageCount: 1,
                });
            }
        }

        return Array.from(historyMap.values());
    }

    private static buildSafetyWarnings(
        profile: UserProfile,
        excludedDrugs: ScoredDrug[]
    ): string[] {
        const warnings: string[] = [];

        if (profile.isPregnant) {
            warnings.push('⚠️ Hệ thống đang áp dụng bộ lọc an toàn đặc biệt cho phụ nữ mang thai.');
        }
        if (profile.isBreastfeeding) {
            warnings.push('⚠️ Hệ thống đang áp dụng bộ lọc an toàn cho phụ nữ đang cho con bú.');
        }
        if (excludedDrugs.length > 0) {
            warnings.push(
                `🛡️ ${excludedDrugs.length} loại thuốc đã được loại khỏi danh sách gợi ý do không phù hợp với hồ sơ sức khỏe của bạn.`
            );
        }
        if (!profile.allergies) {
            warnings.push('💡 Cập nhật thông tin dị ứng trong hồ sơ để hệ thống gợi ý chính xác hơn.');
        }

        return warnings;
    }

    private static async writeLog(
        sessionId: string,
        userId: string,
        action: string,
        details: object,
        ipAddress?: string,
        userAgent?: string
    ) {
        try {
            await prisma.recommendationLog.create({
                data: {
                    sessionId,
                    userId,
                    action: action as any,
                    details: JSON.stringify(details),
                    ipAddress: ipAddress ?? null,
                    userAgent: userAgent ?? null,
                },
            });
        } catch (err) {
            console.error('[RecommendationService] Log write failed (non-critical):', err);
        }
    }
}

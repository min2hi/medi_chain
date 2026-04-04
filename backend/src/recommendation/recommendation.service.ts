/**
 * =============================================================
 * RECOMMENDATION SERVICE - MediChain
 * =============================================================
 * 
 * Service này là "điều phối viên" giữa các component:
 * 1. Lấy hồ sơ người dùng từ DB
 * 2. Lấy danh sách thuốc từ DB (DrugCandidate)
 * 3. Lấy lịch sử feedback của user từ DB
 * 4. Gọi Scoring Engine để ranking
 * 5. Lưu RecommendationSession + items vào DB
 * 6. Ghi audit log
 * 7. Trả về kết quả cho AI Service (để giải thích)
 */

import prisma from '../config/prisma.js';
import {
    runRecommendationEngine,
    UserProfile,
    DrugData,
    DrugHistoryRecord,
    ScoredDrug,
    ScoringResult
} from './scoring.engine.js';

export interface RecommendationInput {
    userId: string;
    symptoms: string;
    ipAddress?: string;
    userAgent?: string;
}

export interface RecommendationOutput {
    sessionId: string;
    rankedDrugs: ScoredDrug[];          // Top N thuốc được recommend (cho AI giải thích)
    excludedCount: number;               // Số thuốc bị loại do safety
    safetyWarnings: string[];            // Cảnh báo an toàn tổng hợp
    profileSnapshot: UserProfile;        // Hồ sơ tại thời điểm tư vấn
    processingMs: number;
}

export class RecommendationService {

    /**
     * Hàm chính: Chạy toàn bộ recommendation pipeline
     */
    static async recommend(input: RecommendationInput): Promise<RecommendationOutput> {
        const { userId, symptoms, ipAddress, userAgent } = input;

        // ─── BƯỚC 1: Lấy hồ sơ y tế người dùng ───
        const userProfile = await this.getUserProfile(userId);

        // ─── BƯỚC 2: Lấy danh sách thuốc từ DB ───
        const drugs = await this.getActiveDrugs();

        // ─── BƯỚC 3: Lấy lịch sử feedback ───
        const drugHistory = await this.getUserDrugHistory(userId);

        // ─── BƯỚC 3.5: Collaborative Filtering (Phase 2 - Cache Cached O(1)) ───
        // Không còn query toàn bộ User Matrix ở đây nữa. CF Score (Global Quality)
        // đã được cache sẵn bên trong DrugData (từ cron job) và truyền trực tiếp vào engine!

        // ─── BƯỚC 4: Tạo RecommendationSession (PENDING) ───
        const session = await prisma.recommendationSession.create({
            data: {
                userId,
                symptoms,
                profileSnapshot: JSON.stringify(userProfile),
                status: 'PENDING',
                totalCandidates: drugs.length,
            },
        });

        // Ghi audit log: Session bắt đầu
        await this.writeLog(session.id, userId, 'SESSION_CREATED', {
            symptoms,
            totalCandidates: drugs.length,
        }, ipAddress, userAgent);

        // ─── BƯỚC 5: Chạy Recommendation Engine ───
        let scoringResult: ScoringResult;
        try {
            scoringResult = await runRecommendationEngine(
                symptoms,
                userProfile,
                drugs,
                drugHistory
            );
        } catch (err: any) {
            // Cập nhật session thành FAILED
            await prisma.recommendationSession.update({
                where: { id: session.id },
                data: { status: 'FAILED' },
            });
            throw new Error(`Engine lỗi: ${err.message}`);
        }

        // ─── BƯỚC 6: Lưu kết quả vào DB ───
        // Lưu các RecommendationItem (thuốc được rank)
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

        // Lưu các thuốc bị loại (để audit)
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
            processingMs: scoringResult.processingMs,
        });

        // Nếu có safety filter → log riêng
        if (scoringResult.excluded.length > 0) {
            await this.writeLog(session.id, userId, 'SAFETY_FILTER_APPLIED', {
                excludedDrugs: scoringResult.excluded.map(d => ({
                    name: d.drugName,
                    reason: d.filterReason,
                })),
            });
        }

        // ─── BƯỚC 7: Tổng hợp safety warnings ───
        const safetyWarnings = this.buildSafetyWarnings(userProfile, scoringResult.excluded);

        return {
            sessionId: session.id,
            rankedDrugs: scoringResult.recommended,
            excludedCount: scoringResult.excluded.length,
            safetyWarnings,
            profileSnapshot: userProfile,
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
        // Validate
        if (rating < 1 || rating > 5) {
            throw new Error('Rating phải từ 1 đến 5');
        }

        const validOutcomes = ['EFFECTIVE', 'PARTIALLY_EFFECTIVE', 'NOT_EFFECTIVE', 'SIDE_EFFECT', 'NOT_TAKEN'];
        if (!validOutcomes.includes(outcome)) {
            throw new Error(`Outcome không hợp lệ. Phải là: ${validOutcomes.join(', ')}`);
        }

        // Kiểm tra session thuộc về user này
        const session = await prisma.recommendationSession.findFirst({
            where: { id: sessionId, userId },
        });
        if (!session) throw new Error('Session không tồn tại');

        // Upsert feedback: tạo mới hoặc cập nhật nếu đã tồn tại
        // Unique key: (userId, drugId, sessionId)
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
                symptomContext: session.symptoms, // [PHASE 2] Gắn context
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
                symptomContext: session.symptoms, // [PHASE 2] Gắn context
            },
        });

        // Audit log
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
                        take: 3, // Chỉ lấy top 3 để xem nhanh
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
                    include: {
                        drug: true,
                    },
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

    /**
     * Lấy và map hồ sơ user sang UserProfile
     */
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

    /**
     * Lấy tất cả thuốc active từ DB
     * NOTE: Không select embedding — đó là vector nặng, chỉ dùng trong SQL query thuần.
     * Prisma không cần biết embedding value; pgvector xử lý trực tiếp trong raw SQL.
     */
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

    /**
     * Lấy lịch sử feedback của user (để tính historyScore)
     */
    private static async getUserDrugHistory(userId: string): Promise<DrugHistoryRecord[]> {
        const feedbacks = await prisma.treatmentFeedback.findMany({
            where: { userId },
            include: { drug: { select: { name: true } } },
            orderBy: { createdAt: 'desc' },
        });

        // Group by drugId, tổng hợp thống kê
        const historyMap = new Map<string, DrugHistoryRecord>();
        for (const fb of feedbacks) {
            const existing = historyMap.get(fb.drugId);
            if (existing) {
                // Average rating khi có nhiều lần feedback
                existing.rating = (existing.rating + fb.rating) / 2;
                existing.usageCount++;
                // Lấy outcome mới nhất (đã orderBy desc)
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

    /**
     * Tổng hợp cảnh báo an toàn để hiển thị cho user
     */
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

    /**
     * Ghi audit log (best-effort, không throw)
     */
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

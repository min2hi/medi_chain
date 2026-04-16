/**
 * Recommendation Controller - MediChain
 * Xử lý các HTTP request liên quan đến recommendation engine
 */

import { Response } from 'express';
import prisma from '../config/prisma.js';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { RecommendationService } from '../recommendation/recommendation.service.js';
import { getDrugViContent } from '../services/drug-enrichment.service.js';
import { TriageAuditLogger } from '../services/triage-audit.service.js';

export class RecommendationController {

    /**
     * POST /api/recommendation/consult
     * 
     * Điểm vào CHÍNH của toàn bộ hệ thống recommendation.
     * Thay thế /api/ai/consult cũ.
     * 
     * Flow:
     * 1. Nhận symptoms từ user
     * 2. Recommendation Engine ranking thuốc
     * 3. Gửi kết quả ranked drugs lên AI để giải thích
     * 4. Trả về cả recommendation data + AI explanation
     */
    static async consult(req: AuthRequest, res: Response) {
        try {
            const userId = req.user.id;
            const { symptoms, conversationId } = req.body;
            const triageStart = Date.now(); // Audit timing

            if (!symptoms || symptoms.trim().length < 5) {
                return res.status(400).json({
                    success: false,
                    message: 'Vui lòng mô tả triệu chứng chi tiết hơn (tối thiểu 5 ký tự)',
                });
            }

            // 0. Ràng buộc an toàn: Hồ sơ y tế phải có tối thiểu Dị ứng và Bệnh nền
            const userProfile = await prisma.profile.findUnique({
                where: { userId }
            });

            if (!userProfile || !userProfile.allergies?.trim() || !userProfile.chronicConditions?.trim()) {
                return res.status(403).json({
                    success: false,
                    message: "Hồ sơ y tế chưa hoàn thiện.\n\nVui lòng cập nhật thông tin 'Dị ứng' và 'Bệnh nền' trong phần Hồ sơ để hệ thống đảm bảo tiêu chuẩn an toàn trước khi kê đơn (Nếu không có bệnh hãy điền 'Không')."
                });
            }

            // ═══ EMERGENCY SYMPTOM GATE ════════════════════════════════════════
            // Phát hiện triệu chứng cấp cứu TRƯỚC KHI chạy engine.
            // MedicalSafetyService đã có list: "khó thở", "đau ngực", "ho ra máu", etc.
            // Nếu phát hiện → từ chối tư vấn OTC, yêu cầu đến cấp cứu NGAY.
            //
            // Lý do bắt buộc: Thuốc cấp cứu (Furosemide IV, Nitroglycerin IV, Morphine)
            // là thuốc Rx, KHÔNG có trong DB OTC. Tư vấn OTC cho cấp cứu = nguy hiểm.
            const { MedicalSafetyService } = await import('../services/medical-safety.service.js');
            const ageInYears = userProfile?.birthday
                ? (Date.now() - new Date(userProfile.birthday).getTime()) / (1000 * 60 * 60 * 24 * 365.25)
                : null;
            const emergencyProfile = {
                allergies:         userProfile?.allergies ?? null,
                chronicConditions: userProfile?.chronicConditions ?? null,
                currentMedicines:  [],
                isPregnant:        userProfile?.isPregnant ?? false,
                isBreastfeeding:   userProfile?.isBreastfeeding ?? false,
                age:               ageInYears,     // ← phục vụ pediatric/geriatric rules
            };
            const safetyCheck = MedicalSafetyService.checkContraindications(
                symptoms.trim(),
                emergencyProfile
            );

            if (safetyCheck.criticalAlerts.length > 0) {
                return res.status(200).json({
                    success: true,
                    data: {
                        sessionId: null,
                        message: {
                            role: 'ASSISTANT',
                            content: `# 🚨 PHÁT HIỆN TRIỆU CHỨNG CẤP CỨU\n\n${safetyCheck.criticalAlerts.join('\n\n')}\n\n---\n\n**MediChain KHÔNG THỂ tư vấn thuốc OTC cho tình trạng này.** Các triệu chứng bạn mô tả có thể cần:\n- Xử trí cấp cứu y tế ngay lập tức\n- Thuốc đặc trị theo chỉ định bác sĩ (không phải OTC)\n- Theo dõi tại cơ sở y tế có đủ trang thiết bị\n\n## ☎️ GỌI NGAY: 115 (Cấp cứu) hoặc đến Phòng cấp cứu gần nhất\n\n> ⚕️ *Hệ thống chỉ hỗ trợ gợi ý thuốc không kê đơn (OTC) cho các triệu chứng thông thường. Tình trạng của bạn vượt quá phạm vi an toàn của hệ thống.*`,
                        },
                        recommendedMedicines: [],
                        criticalAlerts: safetyCheck.criticalAlerts,   // NEW: for red UI
                        safetyWarnings: safetyCheck.warnings ?? [],    // soft warnings
                        predictedDiseases: [],
                        engineStats: { algorithmVersion: 'v2.0-emergency-gate' },
                        // Distinguish hospital context from symptom emergency
                        source: safetyCheck.criticalAlerts.some(a => a.includes('🏥')) 
                            ? 'HOSPITAL_CONTEXT' 
                            : 'EMERGENCY_GATE',
                    },
                });
            }
            // ═══════════════════════════════════════════════════════════════════

            // ─── PHASE 4: LLM SEMANTIC TRIAGE ────────────────────────────────────
            // Chỉ chạy khi keyword gate đã PASS → không tốn token cho case đã block.
            // Bắt các case bypass keyword: "đang nằm không dậy được, người xanh lét..."
            // Timeout cứng 3s → KHÔNG bao giờ làm chậm pipeline quá ngưỡng này.
            // Confidence ≥ 0.85 → chỉ block khi AI rất chắc chắn (tránh false positive).
            const llmTriage = await MedicalSafetyService.triageSymptomsWithLLM(symptoms.trim());
            if (llmTriage.isEmergency && llmTriage.confidence >= 0.85) {
                const emergencyDetail = [
                    llmTriage.emergencyType ? `**Loại cấp cứu:** ${llmTriage.emergencyType}` : null,
                    `**Đánh giá AI:** ${llmTriage.reason}`,
                    `**Độ tin cậy:** ${Math.round(llmTriage.confidence * 100)}%`,
                ].filter(Boolean).join('\n');

                return res.status(200).json({
                    success: true,
                    data: {
                        sessionId: null,
                        message: {
                            role: 'ASSISTANT',
                            content: `# 🚨 CẢNH BÁO CẤP CỨU — AI Safety Oracle\n\n${emergencyDetail}\n\n---\n\n**MediChain KHÔNG THỂ tư vấn thuốc OTC cho tình trạng này.**\n\nTriệu chứng bạn mô tả được AI phát hiện là tình trạng có thể nguy hiểm tính mạng. Cần:\n- Gọi cấp cứu **ngay lập tức**\n- Không tự mua thuốc điều trị tại nhà\n- Đến phòng cấp cứu gần nhất trong thời gian ngắn nhất có thể\n\n## ☎️ GỌI NGAY: 115 (Cấp cứu)\n\n> ⚕️ *Đây là cảnh báo từ AI Safety Oracle — tầng bảo vệ ngữ nghĩa của MediChain. Hệ thống chỉ hỗ trợ thuốc OTC cho triệu chứng thông thường.*`,
                        },
                        recommendedMedicines: [],
                        safetyWarnings: [
                            `🤖 AI Safety Oracle: ${llmTriage.reason} (tin cậy ${Math.round(llmTriage.confidence * 100)}%)`,
                        ],
                        predictedDiseases: [],
                        engineStats: { algorithmVersion: 'v2.0-llm-triage' },
                        source: 'LLM_EMERGENCY_TRIAGE',
                    },
                });
            }
            // ─────────────────────────────────────────────────────────────────────

            // ── Audit: Cleared to engine ──────────────────────────────────────
            const profileAgeYears = userProfile?.birthday
                ? (Date.now() - new Date(userProfile.birthday).getTime()) / (1000 * 60 * 60 * 24 * 365.25)
                : null;
            TriageAuditLogger.log({
                userId:          TriageAuditLogger.hashUserId(userId),
                symptomsHash:    String(symptoms.length),
                symptomsPreview: symptoms.trim().substring(0, 50),
                decision:        'CLEARED_TO_ENGINE',
                layer:           'ALL_GATES_PASSED',
                triggeredBy:     null,
                ageGroup:        TriageAuditLogger.getAgeGroup(profileAgeYears),
                durationMs:      Date.now() - triageStart,
            });

            // 1. Chạy Recommendation Engine
            const recommendationResult = await RecommendationService.recommend({
                userId,
                symptoms: symptoms.trim(),
                ipAddress: typeof req.ip === 'string' ? req.ip : req.ip?.[0],
                userAgent: req.headers['user-agent'],
            });

            // 2. Nếu không có thuốc nào được gợi ý → Từ chối tư vấn
            if (recommendationResult.rankedDrugs.length === 0) {
                return res.json({
                    success: true,
                    data: {
                        sessionId: recommendationResult.sessionId,
                        message: {
                            role: 'ASSISTANT',
                            content: `# ⚠️ Không thể gợi ý thuốc\n\nDựa trên hồ sơ sức khỏe của bạn, hệ thống không tìm thấy thuốc OTC phù hợp và an toàn cho các triệu chứng: "${symptoms}".\n\n**Lý do:** ${recommendationResult.excludedCount} loại thuốc đã bị loại khỏi danh sách do vi phạm quy tắc an toàn với hồ sơ của bạn.\n\n**Khuyến nghị:** Vui lòng đến cơ sở y tế để được bác sĩ khám và chỉ định thuốc phù hợp.`,
                        },
                        recommendedMedicines: [],
                        safetyWarnings: recommendationResult.safetyWarnings,
                        source: 'RECOMMENDATION_ENGINE',
                    },
                });
            }

            // 3. Gọi AI để giải thích (AI không được phép chọn thuốc - chỉ giải thích)
            const { AIService } = await import('../services/ai.service.js');
            const aiResult = await AIService.getMedicineRecommendationWithContext(
                userId,
                symptoms,
                recommendationResult,
                conversationId
            );

            // 4. Enrich nội dung tiếng Việt qua Gemini (parallel, có cache 2 tầng + rate limiter)
            const enrichedDrugs = await Promise.all(
                recommendationResult.rankedDrugs.map(async (drug) => {
                    const vi = await getDrugViContent(drug.drugId).catch(() => null);
                    return { drug, vi };
                })
            );

            // 5. Trả về kết quả tổng hợp
            res.json({
                success: true,
                data: {
                    sessionId: recommendationResult.sessionId,
                    conversationId: aiResult.conversationId,
                    message: aiResult.message,
                    recommendedMedicines: enrichedDrugs.map(({ drug, vi }) => {
                        const aiDosage = (aiResult.dosages as any)?.[drug.drugId] || {};
                        const hasViContent = Boolean(vi?.viSummary);
                        return {
                            drugId: drug.drugId,        // Bắt buộc để submit feedback
                            name: drug.drugName,
                            genericName: drug.genericName,
                            ingredients: drug.ingredients,
                            category: drug.category,
                            rank: drug.rank,
                            finalScore: drug.finalScore,
                            // v2.0: scores updated — evidenceScore mới, safetyScore chỉ là bonus nhỏ
                            scores: {
                                profile:  drug.profileScore,   // AI relevance score (0-100)
                                safety:   drug.safetyScore,    // Safety bonus (0-5) — NOT baseSafetyScore
                                history:  drug.historyScore,   // Personal/CF/Neutral (0-100)
                                evidence: drug.evidenceScore,  // [NEW v2] Disease-ATC match (0-100)
                            },
                            // Drug-level interaction warnings (from safety gate soft check)
                            interactionWarnings: drug.safetyWarnings ?? [],
                            dosage: aiDosage.dosage,
                            frequency: aiDosage.frequency,
                            instruction: aiDosage.instruction,
                            // Vietnamese content — ưu tiên Gemini, fallback sang FDA raw data
                            summary:    vi?.viSummary    || drug.viSummary    || drug.indications?.substring(0, 300) || '',
                            indications: vi?.viIndications || drug.viIndications || drug.indications || '',
                            warnings:   vi?.viWarnings   || drug.viWarnings   || drug.sideEffects || '',
                            sideEffects: drug.sideEffects,   // giữ lại cho backward compat
                            hasViContent,                    // FE dùng để hiện/ẩn "(FDA raw data)" badge
                        };
                    }),
                    safetyWarnings: recommendationResult.safetyWarnings,
                    // [NEW v2] Disease prediction context
                    predictedDiseases: recommendationResult.predictedDiseases.map(d => ({
                        name: d.nameVi,
                        probability: Math.round(d.probability * 100),
                    })),
                    engineStats: {
                        totalCandidates: recommendationResult.rankedDrugs.length + recommendationResult.excludedCount,
                        filteredOut: recommendationResult.excludedCount,
                        finalRanked: recommendationResult.rankedDrugs.length,
                        processingMs: recommendationResult.processingMs,
                        algorithmVersion: 'v2.0-relevance-first',
                    },
                    source: 'RECOMMENDATION_ENGINE',
                },
            });

        } catch (error: any) {
            console.error('[RecommendationController.consult]', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi hệ thống. Vui lòng thử lại.',
            });
        }
    }

    /**
     * POST /api/recommendation/feedback
     * User gửi feedback về hiệu quả thuốc đã dùng (upsert - tạo mới hoặc cập nhật)
     */
    static async submitFeedback(req: AuthRequest, res: Response) {
        try {
            const userId = req.user.id;
            const { sessionId, drugId, rating, outcome, usedDays, sideEffect, note } = req.body;

            if (!sessionId || !drugId || !rating || !outcome) {
                return res.status(400).json({
                    success: false,
                    message: 'Thiếu thông tin: sessionId, drugId, rating, outcome là bắt buộc',
                });
            }

            const feedback = await RecommendationService.submitFeedback(
                userId,
                sessionId,
                drugId,
                Number(rating),
                outcome,
                usedDays ? Number(usedDays) : undefined,
                sideEffect,
                note
            );

            const isUpdate = feedback.createdAt.getTime() !== feedback.updatedAt.getTime();
            res.json({
                success: true,
                message: isUpdate
                    ? 'Đánh giá đã được cập nhật thành công!'
                    : 'Cảm ơn bạn đã phản hồi! Hệ thống sẽ cải thiện gợi ý dựa trên trải nghiệm của bạn.',
                data: feedback,
                isUpdate,
            });

        } catch (error: any) {
            res.status(400).json({ success: false, message: error.message });
        }
    }

    /**
     * GET /api/recommendation/feedback?sessionId=&drugId=
     * Lấy feedback hiện tại của user cho 1 thuốc trong 1 session
     */
    static async getFeedback(req: AuthRequest, res: Response) {
        try {
            const userId = req.user.id;
            const { sessionId, drugId } = req.query as { sessionId: string; drugId: string };

            if (!sessionId || !drugId) {
                return res.status(400).json({
                    success: false,
                    message: 'Thiếu sessionId hoặc drugId',
                });
            }

            const feedback = await RecommendationService.getFeedback(userId, sessionId, drugId);

            res.json({
                success: true,
                data: feedback ?? null, // null = chưa đánh giá lần nào
            });

        } catch (error: any) {
            res.status(500).json({ success: false, message: error.message });
        }
    }


    /**
     * GET /api/recommendation/sessions
     * Lấy lịch sử các phiên tư vấn
     */
    static async getSessions(req: AuthRequest, res: Response) {
        try {
            const userId = req.user.id;
            const page = parseInt(req.query.page as string) || 1;
            const limit = parseInt(req.query.limit as string) || 10;

            const result = await RecommendationService.getUserSessions(userId, page, limit);
            res.json({ success: true, data: result });

        } catch (error: any) {
            res.status(500).json({ success: false, message: error.message });
        }
    }

    /**
     * GET /api/recommendation/sessions/:id
     * Xem chi tiết 1 phiên tư vấn
     */
    static async getSessionDetail(req: AuthRequest, res: Response) {
        try {
            const userId = req.user.id;
            const sessionId = String(req.params.id);

            const session = await RecommendationService.getSessionDetail(userId, sessionId);
            res.json({ success: true, data: session });

        } catch (error: any) {
            res.status(404).json({ success: false, message: error.message });
        }
    }
}

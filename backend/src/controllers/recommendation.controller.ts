/**
 * Recommendation Controller - MediChain
 * Xử lý các HTTP request liên quan đến recommendation engine
 */

import { Response } from 'express';
import prisma from '../config/prisma.js';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { RecommendationService } from '../services/recommendation/recommendation.service.js';
import { getDrugViContent } from '../services/drug-enrichment.service.js';
import { TriageAuditLogger } from '../services/triage-audit.service.js';
import { MedicalNLUService, PATTERN_DRUG_EXCLUSIONS } from '../services/medical-nlu.service.js';
import { HealthTwinService } from '../services/health-twin.service.js';

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
            let userId = req.user.id;
            const { symptoms, conversationId, patientId } = req.body;
            const isDoctorOrAdmin = req.user?.role === 'DOCTOR' || req.user?.role === 'ADMIN';

            if (isDoctorOrAdmin && patientId) {
                userId = patientId;
            }

            const triageStart = Date.now(); // Audit timing

            if (!symptoms || symptoms.trim().length < 5) {
                return res.status(400).json({
                    success: false,
                    message: 'Vui lòng mô tả triệu chứng chi tiết hơn (tối thiểu 5 ký tự)',
                });
            }

            // 0. Ràng buộc an toàn: Hồ sơ y tế phải có thông tin Dị ứng
            // chronicConditions có thể null/rỗng hợp lệ (user không có bệnh nền)
            // → không block, fallback sang 'Không' để safety engine xử lý đúng
            let userProfile = await prisma.profile.findUnique({
                where: { userId }
            });

            if (!userProfile || !userProfile.allergies?.trim()) {
                if (isDoctorOrAdmin) {
                    if (!userProfile) {
                        userProfile = {
                            id: 'temp_profile',
                            userId,
                            bloodType: null,
                            allergies: 'Không',
                            weight: null,
                            height: null,
                            gender: null,
                            birthday: null,
                            address: null,
                            phone: null,
                            chronicConditions: null,
                            isPregnant: false,
                            isBreastfeeding: false,
                            lastUpdated: new Date(),
                            licenseNumber: null,
                            specialty: null,
                            clinicAddress: null,
                            licenseVerified: false
                        };
                    } else {
                        userProfile.allergies = 'Không';
                    }
                } else {
                    return res.status(403).json({
                        success: false,
                        message: "Vui lòng cập nhật thông tin 'Dị ứng' trong phần Hồ sơ trước khi sử dụng tư vấn AI (Nếu không có dị ứng hãy điền 'Không')."
                    });
                }
            }

            // ═══ PHASE 1: UNIFIED SEMANTIC GATE (NLU) + Profile Fetch (PARALLEL) ════════
            // Medical NLU runs PARALLEL with profile fetch = zero added latency.
            // NLU replaces:
            //   → Old keyword matching (hospital signals, emergency keywords, combo detection)
            //   → Old LLM triage (now merged into ONE smarter Groq call)
            //   → Disease predictor (now included in NLU output)
            //   → Temporal/negation/qualifier filters (now handled by LLM context awareness)
            const [nlu] = await Promise.all([
                MedicalNLUService.analyze(symptoms.trim()),
                // Profile fetch happens here but was already done above for validation
            ]);

            console.log(`[NLU] context=${nlu.contextType} urgency=${nlu.urgencyScore} emergency=${nlu.isEmergency} patterns=${nlu.clinicalPatterns.join(',') || 'none'} fallback=${nlu.fromFallback} cached=${nlu.cached} ${nlu.processingMs}ms`);

            // ═══ PHASE 2: NLU-BASED EMERGENCY GATE ══════════════════════
            // Block if: under medical care OR active emergency detected
            if (nlu.isEmergency || nlu.contextType === 'UNDER_MEDICAL_CARE') {
                const emergencyMsg = MedicalNLUService.buildEmergencyMessage(nlu);
                const source = nlu.contextType === 'UNDER_MEDICAL_CARE' ? 'HOSPITAL_CONTEXT' : 'EMERGENCY_GATE';

                TriageAuditLogger.log({
                    userId: TriageAuditLogger.hashUserId(userId),
                    symptomsHash: String(symptoms.length),
                    symptomsPreview: symptoms.trim().substring(0, 50),
                    decision: 'BLOCKED',
                    layer: 'NLU_SEMANTIC_GATE',
                    triggeredBy: nlu.clinicalPatterns.join(',') || nlu.contextType,
                    ageGroup: undefined,
                    durationMs: nlu.processingMs,
                });

                return res.status(200).json({
                    success: true,
                    data: {
                        sessionId: null,
                        message: { role: 'ASSISTANT', content: emergencyMsg },
                        recommendedMedicines: [],
                        criticalAlerts: [nlu.reason],
                        safetyWarnings: [],
                        predictedDiseases: [],
                        engineStats: {
                            algorithmVersion: 'v3.0-nlu-semantic-gate',
                            urgencyScore: nlu.urgencyScore,
                            clinicalPatterns: nlu.clinicalPatterns,
                            nluConfidence: nlu.confidence,
                        },
                        source,
                    },
                });
            }
            // ══════════════════════════════════════════════════

            // ═══ PHASE 3: RULE-BASED SAFETY (Age, Pregnancy, Vital Signs) ═══════
            // Kept as deterministic safety net — NLU handles semantic/context,
            // rules handle measurable thresholds (SpO2, BP, pediatric age, pregnancy).
            const { MedicalSafetyService } = await import('../services/medical-safety.service.js');
            const ageInYears = userProfile?.birthday
                ? (Date.now() - new Date(userProfile.birthday).getTime()) / (1000 * 60 * 60 * 24 * 365.25)
                : null;
            const emergencyProfile = {
                allergies: userProfile?.allergies ?? null,
                chronicConditions: userProfile?.chronicConditions ?? null,
                currentMedicines: [],
                isPregnant: userProfile?.isPregnant ?? false,
                isBreastfeeding: userProfile?.isBreastfeeding ?? false,
                age: ageInYears,
            };
            const safetyCheck = await MedicalSafetyService.checkContraindications(
                symptoms.trim(),
                emergencyProfile
            );

            if (safetyCheck.criticalAlerts.length > 0) {
                TriageAuditLogger.log({
                    userId: TriageAuditLogger.hashUserId(userId),
                    symptomsHash: String(symptoms.length),
                    symptomsPreview: symptoms.trim().substring(0, 50),
                    decision: 'BLOCKED',
                    layer: 'RULE_BASED_SAFETY',
                    triggeredBy: safetyCheck.criticalAlerts[0].substring(0, 60),
                    ageGroup: TriageAuditLogger.getAgeGroup(ageInYears),
                    durationMs: Date.now() - triageStart,
                });
                return res.status(200).json({
                    success: true,
                    data: {
                        sessionId: null,
                        message: {
                            role: 'ASSISTANT',
                            content: `# 🚨 CẢNH BÁO AN TOÀN\n\n${safetyCheck.criticalAlerts.join('\n\n')}\n\n---\n\n**MediChain KHÔNG THỂ tư vấn thuốc OTC cho tình trạng này.**\n\n## ☎️ GỌI NGAY: 115`,
                        },
                        recommendedMedicines: [],
                        criticalAlerts: safetyCheck.criticalAlerts,
                        safetyWarnings: safetyCheck.warnings ?? [],
                        predictedDiseases: [],
                        engineStats: { algorithmVersion: 'v3.0-rule-safety' },
                        source: 'EMERGENCY_GATE',
                    },
                });
            }

            // Context-aware soft warnings
            const contextWarnings: string[] = [...(safetyCheck.warnings ?? [])];
            if (nlu.contextType === 'PAST_HISTORY') {
                contextWarnings.push('⏰ Triệu chứng được phân tích là đã xảy ra trong quá khứ. Nếu hiện tại vẫn còn → hãy cập nhật mô tả thêm.');
            }
            if (nlu.contextType === 'HYPOTHETICAL') {
                contextWarnings.push('💭 Phân tích dựa trên mô tả giả định. Nếu triệu chứng thực tế → hãy mô tả cụ thể hơn để được tư vấn chính xác.');
            }

            // Clinical pattern warnings — truyền cả 2: raw key (cho SafetyGate) + reason (cho user display)
            // [v2.1] SafetyGate trong scoring engine cần raw key ('DENGUE_RISK') để tra SCORING_PATTERN_EXCLUSIONS,
            // KHÔNG phải reason string ("🦟 Nguy cơ sốt xuất huyết...").
            // → Thêm raw key vào đầu mảng, reason vẫn có để hiển thị cho user.
            const patternWarnings: string[] = [];
            for (const pattern of nlu.clinicalPatterns) {
                if (PATTERN_DRUG_EXCLUSIONS[pattern]) {
                    patternWarnings.push(pattern);                              // raw key → scoring engine SafetyGate
                    patternWarnings.push(PATTERN_DRUG_EXCLUSIONS[pattern].reason); // reason → user display
                }
            }

            // PHASE 4: AUDIT + RECOMMENDATION ENGINE
            TriageAuditLogger.log({
                userId: TriageAuditLogger.hashUserId(userId),
                symptomsHash: String(symptoms.length),
                symptomsPreview: symptoms.trim().substring(0, 50),
                decision: 'CLEARED_TO_ENGINE',
                layer: 'NLU_CLEARED',
                triggeredBy: null,
                ageGroup: TriageAuditLogger.getAgeGroup(ageInYears),
                durationMs: Date.now() - triageStart,
            });

            // 1. Chạy Recommendation Engine (với NLU data — bỏ qua Groq call thứ 2)
            const recommendationResult = await RecommendationService.recommend({
                userId,
                symptoms: symptoms.trim(),
                ipAddress: typeof req.ip === 'string' ? req.ip : req.ip?.[0],
                userAgent: req.headers['user-agent'],
                precomputedDiseases: nlu.predictedDiseases,  // NLU đã dự đoán rồi
                patternWarnings: [...patternWarnings, ...contextWarnings],
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
                            // [v2.1] Scores normalized 0.0–1.0 for Flutter (Flutter × 100 = %)
                            // safety   = baseSafetyScore/100 → % an toàn thực của thuốc trong DB (0-100)
                            //            KHÔNG dùng safetyBonus/5 (bonus 0-5, không có ý nghĩa display)
                            // profile  = profileScore/100    → % khớp triệu chứng (AI relevance)
                            // evidence = evidenceScore/100   → % phù hợp bệnh dự đoán (ATC match)
                            // history  = historyScore/100    → % từ lịch sử cộng đồng/cá nhân
                            scores: {
                                safety:   Math.min(1, (drug.baseSafetyScore ?? 0) / 100),
                                profile:  Math.min(1, (drug.profileScore    ?? 0) / 100),
                                evidence: Math.min(1, (drug.evidenceScore   ?? 0) / 100),
                                history:  Math.min(1, (drug.historyScore    ?? 0) / 100),
                            },

                            // Drug-level interaction warnings (from safety gate soft check)
                            interactionWarnings: drug.safetyWarnings ?? [],
                            dosage: aiDosage.dosage,
                            frequency: aiDosage.frequency,
                            instruction: aiDosage.instruction,
                            // Vietnamese content — ưu tiên Gemini, fallback sang FDA raw data
                            summary: vi?.viSummary || drug.viSummary || drug.indications?.substring(0, 300) || '',
                            indications: vi?.viIndications || drug.viIndications || drug.indications || '',
                            warnings: vi?.viWarnings || drug.viWarnings || drug.sideEffects || '',
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

            // Cập nhật session với aiExplanation và conversationId thực tế từ AI
            if (recommendationResult.sessionId) {
                await prisma.recommendationSession.update({
                    where: { id: recommendationResult.sessionId },
                    data: {
                        aiExplanation: aiResult.message.content,
                        conversationId: aiResult.conversationId || null,
                    },
                }).catch((e) => console.error('Failed to update session explanation:', e));
            }

            // Passive Health Twin logging — fire-and-forget, không block response
            const topDrugName = recommendationResult.rankedDrugs[0]?.drugName ?? 'N/A';
            void HealthTwinService.logEvent(
                userId,
                'AI_CONSULT',
                `Triệu chứng: ${symptoms.trim()}. Khuyến nghị: ${topDrugName}`,
                recommendationResult.sessionId
            ).catch(() => {}); // Ignore errors silently

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

            // Query corresponding AIMessage for dosages
            const aiMessage = await prisma.aIMessage.findFirst({
                where: {
                    conversationId: session.conversationId || undefined,
                    medicalContext: {
                        contains: session.id,
                    },
                },
            });

            let dosagesMap: Record<string, { dosage?: string; frequency?: string; instruction?: string }> = {};
            if (aiMessage && aiMessage.medicalContext) {
                try {
                    const parsedContext = JSON.parse(aiMessage.medicalContext);
                    if (parsedContext.dosages) {
                        dosagesMap = parsedContext.dosages;
                    }
                } catch (e) {
                    console.error('Failed to parse AIMessage medicalContext:', e);
                }
            }

            // Reconstruct safety warnings dynamically from profile snapshot and excluded items
            const reconstructedWarnings: string[] = [];
            let profileSnap: any = null;
            if (session.profileSnapshot) {
                try {
                    profileSnap = JSON.parse(session.profileSnapshot);
                } catch (e) {
                    console.error('Failed to parse profileSnapshot:', e);
                }
            }
            const excludedItems = session.items.filter(item => !item.isRecommended);

            // Reconstruct clinical pattern warnings from excludedItems reasons
            const clinicalReasons = new Set<string>();
            excludedItems.forEach(item => {
                if (item.filterReason) {
                    if (item.filterReason.includes('Sốt Xuất Huyết Dengue')) {
                        clinicalReasons.add('🦟 Nguy cơ sốt xuất huyết: NSAIDs/Aspirin có thể gây xuất huyết nặng');
                    } else if (item.filterReason.includes('Nghi ACS')) {
                        clinicalReasons.add('❤️ Nghi ACS: Thuốc co mạch chống chỉ định');
                    } else if (item.filterReason.includes('Tăng huyết áp')) {
                        clinicalReasons.add('🩸 Tăng huyết áp: NSAIDs và thuốc co mạch làm tăng BP');
                    } else if (item.filterReason.includes('Suy hô hấp')) {
                        clinicalReasons.add('🫁 Suy hô hấp: Kháng histamine gây ức chế hô hấp thêm');
                    }
                }
            });
            clinicalReasons.forEach(r => reconstructedWarnings.push(r));

            if (profileSnap) {
                if (profileSnap.isPregnant) {
                    reconstructedWarnings.push('⚠️ Hệ thống đang áp dụng bộ lọc an toàn đặc biệt cho phụ nữ mang thai.');
                }
                if (profileSnap.isBreastfeeding) {
                    reconstructedWarnings.push('⚠️ Hệ thống đang áp dụng bộ lọc an toàn cho phụ nữ đang cho con bú.');
                }
                if (excludedItems.length > 0) {
                    reconstructedWarnings.push(
                        `🛡️ ${excludedItems.length} loại thuốc đã được loại khỏi danh sách gợi ý do không phù hợp với hồ sơ sức khỏe của bạn.`
                    );
                }
                if (!profileSnap.allergies || profileSnap.allergies.trim().toLowerCase() === 'không') {
                    // Do not add warning if explicitly set to none
                } else if (!profileSnap.allergies) {
                    reconstructedWarnings.push('💡 Cập nhật thông tin dị ứng trong hồ sơ để hệ thống gợi ý chính xác hơn.');
                }
            }

            // Tương thích ngược: Fallback cho các session cũ
            const mappedMedicines = session.items
                .filter(item => item.isRecommended)
                .map(item => {
                    // 1. Fallback điểm an toàn (safetyScore): 
                    // Nếu dữ liệu cũ lưu safetyScore <= 5 (tức là safetyBonus), ta khôi phục từ drug.baseSafetyScore.
                    // Nếu là dữ liệu mới (đã lưu 0-100), dùng trực tiếp item.safetyScore.
                    const safetyVal = item.safetyScore <= 5 
                        ? (item.drug.baseSafetyScore ?? 0) 
                        : item.safetyScore;

                    // 2. Fallback điểm y văn (evidenceScore):
                    // Nếu là dữ liệu cũ (evidenceScore == 0), tính toán fallback từ finalScore.
                    // Nếu là dữ liệu mới, dùng trực tiếp item.evidenceScore.
                    let evidenceVal = item.evidenceScore;
                    if (evidenceVal === 0) {
                        const calculated = item.finalScore - (item.profileScore + (item.safetyScore <= 5 ? item.safetyScore * 20 : item.safetyScore) + item.historyScore) / 3;
                        evidenceVal = Math.max(0, Math.min(100, Math.round(calculated)));
                    }

                    // Drug interaction check
                    const interactsWithStr = item.drug.interactsWith || '[]';
                    let drugInteracts: string[] = [];
                    try {
                        drugInteracts = JSON.parse(interactsWithStr);
                    } catch {}
                    
                    const itemWarnings: string[] = [];
                    if (profileSnap && profileSnap.currentMedicines) {
                        for (const interaction of drugInteracts) {
                            const lowerInteraction = interaction.toLowerCase();
                            for (const currentMed of profileSnap.currentMedicines) {
                                if (
                                    currentMed.toLowerCase().includes(lowerInteraction) ||
                                    lowerInteraction.includes(currentMed.toLowerCase())
                                ) {
                                    itemWarnings.push(`⚠️ Lưu ý tương tác: ${item.drug.name} có thể tương tác với ${currentMed} — hỏi dược sĩ trước khi dùng`);
                                    break;
                                }
                            }
                        }
                    }

                    // Collect item warnings into global warnings list
                    itemWarnings.forEach(w => {
                        if (!reconstructedWarnings.includes(w)) {
                            reconstructedWarnings.push(w);
                        }
                    });

                    const dosageInfo = dosagesMap[item.drugId] || {};

                    return {
                        drugId: item.drugId,
                        name: item.drug.name,
                        genericName: item.drug.genericName,
                        ingredients: item.drug.ingredients,
                        category: item.drug.category,
                        rank: item.rank,
                        finalScore: item.finalScore,
                        scores: {
                            profile: Math.min(1, (item.profileScore ?? 0) / 100),
                            safety: Math.min(1, safetyVal / 100),
                            history: Math.min(1, (item.historyScore ?? 0) / 100),
                            evidence: Math.min(1, evidenceVal / 100),
                        },
                        interactionWarnings: itemWarnings,
                        dosage: dosageInfo.dosage || "",
                        frequency: dosageInfo.frequency || "",
                        instruction: dosageInfo.instruction || "",
                        summary: item.drug.viSummary || item.drug.indications?.substring(0, 300) || '',
                        indications: item.drug.viIndications || item.drug.indications || '',
                        warnings: item.drug.viWarnings || item.drug.sideEffects || '',
                        sideEffects: item.drug.sideEffects || '',
                        hasViContent: !!item.drug.viSummary,
                    };
                });

            // Parse profileSnapshot để hiển thị thông tin tóm tắt trong tin nhắn lịch sử nếu không có aiExplanation
            let msgContent = session.aiExplanation || '';
            if (!msgContent && session.profileSnapshot) {
                try {
                    const snap = JSON.parse(session.profileSnapshot);
                    const genderStr = snap.gender === 'MALE' ? 'Nam' : snap.gender === 'FEMALE' ? 'Nữ' : 'Không rõ';
                    msgContent = `### Lịch sử tư vấn ngày ${new Date(session.createdAt).toLocaleDateString('vi-VN')}\n\n**Triệu chứng:** ${session.symptoms}\n\n**Hồ sơ bệnh nhân lúc đó:**\n- Tuổi: ${snap.age ?? 'Không rõ'}\n- Giới tính: ${genderStr}\n- Thai kỳ: ${snap.isPregnant ? 'Có' : 'Không'}\n- Cho con bú: ${snap.isBreastfeeding ? 'Có' : 'Không'}\n- Bệnh nền: ${snap.chronicConditions || 'Không có'}\n- Dị ứng: ${snap.allergies || 'Không có'}`;
                } catch {
                    msgContent = `### Lịch sử tư vấn ngày ${new Date(session.createdAt).toLocaleDateString('vi-VN')}\n\n**Triệu chứng:** ${session.symptoms}`;
                }
            }

            const responseData = {
                sessionId: session.id,
                conversationId: session.conversationId || '',
                symptoms: session.symptoms, // Cho Web client render symptoms
                message: {
                    id: session.id,
                    role: 'ASSISTANT',
                    content: msgContent,
                    createdAt: session.createdAt.toISOString(),
                },
                recommendedMedicines: mappedMedicines,
                safetyWarnings: reconstructedWarnings.length > 0 
                    ? reconstructedWarnings 
                    : session.feedbacks.map(f => f.sideEffect).filter((x): x is string => !!x),
                engineStats: {
                    totalCandidates: session.totalCandidates ?? 0,
                    filteredOut: session.filteredOut ?? 0,
                    finalRanked: session.finalRanked ?? 0,
                    processingMs: session.processingMs ?? 0,
                },
                source: 'RECOMMENDATION_ENGINE' as const,
            };

            res.json({ success: true, data: responseData });

        } catch (error: any) {
            res.status(404).json({ success: false, message: error.message || 'Lỗi hệ thống khi lấy chi tiết phiên tư vấn' });
        }
    }
}

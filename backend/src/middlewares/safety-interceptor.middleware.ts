/**
 * Safety Interceptor Middleware
 * ─────────────────────────────────────────────────────────────────────────────
 * Pattern: OpenAI /moderations | Google SafeSearch | Meta Content Guard
 *
 * VỊ TRÍ: Tầng infrastructure (middleware), KHÔNG phải business logic.
 * LÝ DO: Safety là cross-cutting concern — phải áp dụng đồng đều cho MỌI
 *        AI endpoint hiện tại và tương lai, không phụ thuộc vào developer
 *        có nhớ thêm vào từng service hay không.
 *
 * CÁCH HOẠT ĐỘNG (fire-and-forget):
 *   1. Đọc message/symptoms từ request body
 *   2. Gọi triageSymptomsWithLLM() trong background (KHÔNG block response)
 *   3. Nếu isEmergency + confidence >= 0.85 → queueFromLLMTriage() → Admin queue
 *   4. next() được gọi ngay lập tức — user không chịu thêm latency nào
 *
 * FAIL-OPEN: Bất kỳ lỗi nào trong safety check → bỏ qua, không crash request.
 *
 * ĐỂ THÊM ENDPOINT MỚI: Chỉ cần thêm safetyInterceptor vào route handler.
 * Safety sẽ tự động áp dụng, không cần sửa service layer.
 * ─────────────────────────────────────────────────────────────────────────────
 */

import { Request, Response, NextFunction } from 'express';
import { MedicalSafetyService } from '../services/medical-safety.service.js';
import { ClinicalRulesEngine } from '../services/clinical-rules.engine.js';
import { logger } from '../utils/logger.js';

export function safetyInterceptor(req: Request, _res: Response, next: NextFunction): void {
    // Trích xuất text từ bất kỳ AI endpoint nào:
    //   /chat    → req.body.message
    //   /consult → req.body.symptoms
    //   Tương lai: thêm field mới vào đây, không cần sửa service
    const userText: string = (req.body?.message || req.body?.symptoms || '').trim();

    // Không có text → bỏ qua, tiếp tục request bình thường
    if (userText.length < 10) {
        next();
        return;
    }

    // ── Fire-and-forget ────────────────────────────────────────────────────────
    // Gọi next() NGAY ĐÂY để không block response.
    // Safety check chạy hoàn toàn trong background.
    next();

    // Chạy async sau next() — response đã được giao cho controller xử lý
    void (async () => {
        try {
            const triage = await MedicalSafetyService.triageSymptomsWithLLM(userText);

            if (triage.isEmergency && triage.confidence >= 0.85) {
                const queued = await ClinicalRulesEngine.queueFromLLMTriage(
                    userText,
                    triage.emergencyType,
                    triage.confidence,
                );

                if (queued) {
                    logger.info(
                        `[SafetyInterceptor] Queued: "${userText.substring(0, 60)}..." ` +
                        `| Type: ${triage.emergencyType} | Conf: ${(triage.confidence * 100).toFixed(0)}%`
                    );
                }
            }
        } catch (err) {
            // Fail-open: safety check lỗi → chỉ log, không ảnh hưởng request
            logger.warn({ err }, '[SafetyInterceptor] Check failed — fail-open, request unaffected');
        }
    })();
}

import prisma from '../config/prisma.js';

type FeedbackOutcome = 'EFFECTIVE' | 'PARTIALLY_EFFECTIVE' | 'NOT_EFFECTIVE' | 'SIDE_EFFECT' | 'NOT_TAKEN';

const OUTCOME_WEIGHTS: Record<FeedbackOutcome, number> = {
    EFFECTIVE:           +1.0,
    PARTIALLY_EFFECTIVE: +0.4,
    NOT_EFFECTIVE:       -0.5,
    SIDE_EFFECT:         -1.0,
    NOT_TAKEN:            0.0,
};

const MIN_FEEDBACK_THRESHOLD = 3;

/**
 * Xây dựng lại điểm Collaborative (O(N) Offline Calculation)
 * Chạy job này định kỳ (vd: mỗi đêm) để tính toán điểm đánh giá chung của
 * từng nhãn hiệu thuốc từ toàn bộ cộng đồng, sau đó lưu (cache) cứng vào `DrugCandidate`.
 * Nhờ cỗ máy Vector Search đã xử lý "Context" (Triệu chứng), điểm CF này chỉ cần
 * đại diện cho "Quality" (Chất lượng thực tế) của thuốc trên thị trường.
 */
export async function buildCollaborativeMatrix() {
    console.log('[CF-Matrix] Bắt đầu xây dựng Collaborative Score...');
    const start = Date.now();

    try {
        // 1. Lấy toàn bộ feedback hợp lệ
        const allFeedbacks = await prisma.treatmentFeedback.findMany({
            select: { drugId: true, outcome: true, rating: true },
        });

        if (allFeedbacks.length === 0) {
            console.log('[CF-Matrix] Chưa có bất kỳ feedback nào để tính toán.');
            return;
        }

        // 2. Nhóm feedback theo thuốc
        const drugFeedbackMap = new Map<string, typeof allFeedbacks>();
        for (const fb of allFeedbacks) {
            if (!drugFeedbackMap.has(fb.drugId)) {
                drugFeedbackMap.set(fb.drugId, []);
            }
            drugFeedbackMap.get(fb.drugId)!.push(fb);
        }

        // 3. Tính điểm chất lượng từng loại và bulk update (tránh N+1 queries)
        const updates: Array<{ id: string; score: number | null }> = [];

        for (const [drugId, records] of drugFeedbackMap.entries()) {
            if (records.length < MIN_FEEDBACK_THRESHOLD) {
                updates.push({ id: drugId, score: null });
                continue;
            }

            let weightedSum = 0;
            for (const record of records) {
                const outcomeWeight = OUTCOME_WEIGHTS[record.outcome] ?? 0;
                const ratingFactor = (record.rating - 3) * 0.1;
                weightedSum += outcomeWeight + ratingFactor;
            }

            const rawScore = weightedSum / records.length;
            const finalScore = Math.max(0, Math.min(100, 50 + rawScore * 40));
            updates.push({ id: drugId, score: Math.round(finalScore) });
        }

        // Bulk update theo batch 50 để tránh quá tải DB
        const BATCH_SIZE = 50;
        let updatedCount = 0;

        for (let i = 0; i < updates.length; i += BATCH_SIZE) {
            const batch = updates.slice(i, i + BATCH_SIZE);
            await Promise.all(
                batch.map(({ id, score }) =>
                    prisma.drugCandidate.update({
                        where: { id },
                        data: { collaborativeScore: score },
                    })
                )
            );
            updatedCount += batch.filter(u => u.score !== null).length;
        }

        console.log(`[CF-Matrix] Thành công! Đã tính và cache CF score cho ${updatedCount} loại thuốc. Thời gian: ${Date.now() - start}ms`);

    } catch (err: any) {
        console.error('[CF-Matrix] Lỗi nghiêm trọng khi build ma trận:', err.message);
    }
}

// Nếu file được gọi trực tiếp bằng Node/TS-Node thay vì qua Cron orchestrator:
if (import.meta.url === `file://${process.argv[1]}`) {
    buildCollaborativeMatrix().then(() => process.exit(0));
}

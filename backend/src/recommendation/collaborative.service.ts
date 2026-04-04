/**
 * =============================================================
 * COLLABORATIVE FILTERING SERVICE - MediChain (Phase 1)
 * =============================================================
 *
 * Mục tiêu: Giải quyết "Cold Start Problem" — khi user mới chưa
 * có lịch sử dùng thuốc cá nhân, thay điểm 50 cứng bằng điểm
 * được tính từ nhóm user có hồ sơ y tế tương tự (Peer Group).
 *
 * ─── Thuật toán ────────────────────────────────────────────
 *  1. Xây Peer Group: Tìm người dùng khác có cùng:
 *       - Giới tính (bắt buộc nếu có)
 *       - Độ tuổi ±10 năm (nếu có)
 *       - Không có bệnh nền xung đột với thuốc
 *  2. Aggregate feedback của Peer Group theo từng thuốc
 *  3. Tính Weighted Peer Score (0–100) có tính đến:
 *       - Kết quả điều trị (outcome weight)
 *       - Đánh giá sao (rating factor)
 *       - Số lượng peers (confidence level)
 *  4. Trả về Map<drugId, CollaborativePeerScore>
 *
 * ─── Nguyên tắc bất biến ───────────────────────────────────
 *  - Service này KHÔNG thay thế Safety Filter
 *  - Chỉ ảnh hưởng đến historyScore khi user không có personal history
 *  - Khi peerCount < MIN_PEERS → trả về null → engine dùng 50 neutral
 * =============================================================
 */

import prisma from '../config/prisma.js';
import type { UserProfile } from './scoring.engine.js';

// ─── Constants ────────────────────────────────────────────────
/** Số peers tối thiểu để tin tưởng collaborative score */
const MIN_PEERS = 3;

/** Trọng số kết quả điều trị */
const OUTCOME_WEIGHTS: Record<string, number> = {
    EFFECTIVE:           +1.0,
    PARTIALLY_EFFECTIVE: +0.4,
    NOT_EFFECTIVE:       -0.5,
    SIDE_EFFECT:         -1.0,
    NOT_TAKEN:            0.0,
};

/** Khoảng tuổi cho phép lệch so với user hiện tại (năm) */
const AGE_TOLERANCE = 10;

// ─── Types ────────────────────────────────────────────────────

export type ConfidenceLevel = 'HIGH' | 'MEDIUM' | 'LOW';

/**
 * Điểm cộng tác được tính từ nhóm peers.
 * score: 0-100 (50 = trung lập, >50 = tích cực, <50 = tiêu cực)
 * peerCount: số lượng bản ghi feedback đóng góp
 * confidence: mức độ tin cậy dựa trên số peers
 */
export interface CollaborativePeerScore {
    score: number;
    peerCount: number;
    confidence: ConfidenceLevel;
    /** Chuỗi lý do để hiển thị cho user */
    reason: string;
}

/**
 * Kết quả từ collaborative service — Map từ drugId sang score.
 * null nghĩa là không đủ peers → engine tự fallback về 50.
 */
export type CollaborativeScoreMap = Map<string, CollaborativePeerScore>;

// ─── Raw DB row types ─────────────────────────────────────────

interface PeerFeedbackRow {
    drugId: string;
    outcome: string;
    rating: number;
}

interface PeerUserRow {
    userId: string;
    gender: string | null;
    birthday: Date | null;
    chronicConditions: string | null;
}

// ─── Main Service ─────────────────────────────────────────────

export class CollaborativeService {

    /**
     * Điểm vào chính: Tính collaborative scores cho tất cả thuốc.
     *
     * @param currentUserId - ID user hiện tại (để loại trừ chính họ)
     * @param userProfile   - Hồ sơ y tế của user hiện tại
     * @returns Map<drugId, CollaborativePeerScore> — null entries không xuất hiện
     */
    static async getPeerScores(
        currentUserId: string,
        userProfile: UserProfile
    ): Promise<CollaborativeScoreMap> {
        const start = Date.now();
        const result: CollaborativeScoreMap = new Map();

        try {
            // Bước 1: Xây dựng peer group
            const peerIds = await this.findPeerGroup(currentUserId, userProfile);

            if (peerIds.length < MIN_PEERS) {
                console.log(`[CF] Không đủ peers (${peerIds.length}/${MIN_PEERS}) — bỏ qua CF`);
                return result; // Map rỗng → engine dùng fallback 50
            }

            console.log(`[CF] Tìm thấy ${peerIds.length} peers phù hợp`);

            // Bước 2: Lấy feedback của toàn bộ peer group
            const feedbacks = await this.getPeerFeedbacks(peerIds);

            if (feedbacks.length === 0) {
                console.log(`[CF] Peers không có feedback nào — bỏ qua CF`);
                return result;
            }

            // Bước 3: Tổng hợp và tính score theo từng thuốc
            const drugFeedbackMap = this.groupFeedbackByDrug(feedbacks);

            for (const [drugId, records] of drugFeedbackMap.entries()) {
                const peerScore = this.calculatePeerScore(records, peerIds.length);
                if (peerScore !== null) {
                    result.set(drugId, peerScore);
                }
            }

            console.log(
                `[CF] Hoàn thành: ${result.size} thuốc có peer score | ` +
                `${peerIds.length} peers | ${Date.now() - start}ms`
            );

        } catch (err: any) {
            // Lỗi CF không được làm crash recommendation pipeline
            console.error('[CF] Lỗi khi tính collaborative scores (non-critical):', err.message);
        }

        return result;
    }

    // ─── Private Methods ─────────────────────────────────────────

    /**
     * Tìm danh sách userId của nhóm peers phù hợp.
     *
     * Tiêu chí phân nhóm (ưu tiên giảm dần):
     *  1. Loại trừ chính user hiện tại (bắt buộc)
     *  2. Cùng giới tính (nếu user có khai báo giới tính)
     *  3. Cùng nhóm tuổi ±10 năm (nếu user có khai báo năm sinh)
     *
     * Lưu ý: Điều kiện bệnh nền được xử lý ở bước scoring (không lọc peer),
     * vì Safety Filter ở layer trên đã đảm bảo thuốc không qua được nếu
     * user có bệnh nền xung đột. CF chỉ cần nhóm tương đồng nhân khẩu học.
     */
    private static async findPeerGroup(
        currentUserId: string,
        userProfile: UserProfile
    ): Promise<string[]> {
        // Truy vấn profile của các user khác đã có feedback
        const candidatePeers = await prisma.$queryRaw<PeerUserRow[]>`
            SELECT DISTINCT
                p."userId",
                p.gender,
                p.birthday,
                p."chronicConditions"
            FROM "Profile" p
            INNER JOIN "TreatmentFeedback" tf ON tf."userId" = p."userId"
            WHERE p."userId" != ${currentUserId}
        `;

        const matchedPeerIds: string[] = [];

        for (const peer of candidatePeers) {
            // ── Tiêu chí 1: Giới tính ──
            // Chỉ lọc nếu cả hai phía đều có khai báo giới tính
            if (userProfile.gender && peer.gender) {
                if (peer.gender.toLowerCase() !== userProfile.gender.toLowerCase()) {
                    continue; // Khác giới → bỏ qua
                }
            }

            // ── Tiêu chí 2: Độ tuổi ──
            // Chỉ lọc nếu user hiện tại có tuổi
            if (userProfile.age !== null && peer.birthday) {
                const peerAge = Math.floor(
                    (Date.now() - new Date(peer.birthday).getTime()) /
                    (365.25 * 24 * 60 * 60 * 1000)
                );
                if (Math.abs(peerAge - userProfile.age) > AGE_TOLERANCE) {
                    continue; // Chênh tuổi quá nhiều → bỏ qua
                }
            }

            matchedPeerIds.push(peer.userId);
        }

        return matchedPeerIds;
    }

    /**
     * Lấy tất cả feedbacks từ peer group.
     * Chỉ lấy các fields cần thiết để tối ưu băng thông DB.
     */
    private static async getPeerFeedbacks(
        peerIds: string[]
    ): Promise<PeerFeedbackRow[]> {
        if (peerIds.length === 0) return [];

        const feedbacks = await prisma.treatmentFeedback.findMany({
            where: {
                userId: { in: peerIds },
            },
            select: {
                drugId: true,
                outcome: true,
                rating: true,
            },
        });

        return feedbacks as PeerFeedbackRow[];
    }

    /**
     * Nhóm feedback theo drugId để xử lý từng thuốc.
     */
    private static groupFeedbackByDrug(
        feedbacks: PeerFeedbackRow[]
    ): Map<string, PeerFeedbackRow[]> {
        const map = new Map<string, PeerFeedbackRow[]>();

        for (const fb of feedbacks) {
            const existing = map.get(fb.drugId);
            if (existing) {
                existing.push(fb);
            } else {
                map.set(fb.drugId, [fb]);
            }
        }

        return map;
    }

    /**
     * Tính peer score cho một thuốc cụ thể từ danh sách feedbacks.
     *
     * Công thức:
     *   outcomeWeight = OUTCOME_WEIGHTS[outcome]        (từ -1.0 đến +1.0)
     *   ratingFactor  = (rating - 3) × 0.1             (từ -0.2 đến +0.2)
     *   contribution  = outcomeWeight + ratingFactor    (từ -1.2 đến +1.2)
     *
     *   rawScore      = Σ(contribution) / peerCount     (từ -1.2 đến +1.2)
     *   finalScore    = clamp(50 + rawScore × 40, 0, 100)
     *
     * Ví dụ thực tế:
     *   - 10 peers EFFECTIVE rating 5 → rawScore ~1.2 → finalScore ~98
     *   - 10 peers NOT_EFFECTIVE rating 1 → rawScore ~-0.7 → finalScore ~22
     *   - Mix đều → rawScore ~0 → finalScore ~50 (trung lập)
     *
     * @returns null nếu không đủ MIN_PEERS feedbacks
     */
    private static calculatePeerScore(
        records: PeerFeedbackRow[],
        totalPeers: number
    ): CollaborativePeerScore | null {
        if (records.length < MIN_PEERS) {
            return null; // Không đủ mẫu để tin tưởng
        }

        let weightedSum = 0;

        for (const record of records) {
            const outcomeWeight = OUTCOME_WEIGHTS[record.outcome] ?? 0;
            // Rating 1-5 → factor từ -0.2 đến +0.2
            const ratingFactor = (record.rating - 3) * 0.1;
            weightedSum += outcomeWeight + ratingFactor;
        }

        // Normalize: divide by count → range [-1.2, +1.2]
        const rawScore = weightedSum / records.length;

        // Map về [0, 100] với 50 là trung lập
        // Nhân 40 để tạo khoảng phân biệt rõ ràng (max ~98, min ~2)
        const finalScore = Math.max(0, Math.min(100, 50 + rawScore * 40));

        // Xác định mức độ tin cậy
        const confidence = this.getConfidenceLevel(records.length);

        // Tạo reason string thân thiện
        const effectiveCount = records.filter(r => r.outcome === 'EFFECTIVE').length;
        const sideEffectCount = records.filter(r => r.outcome === 'SIDE_EFFECT').length;

        let reason = `Dựa trên ${records.length} người dùng tương tự`;
        if (effectiveCount > 0) {
            reason += ` (${effectiveCount} người hiệu quả`;
            if (sideEffectCount > 0) reason += `, ${sideEffectCount} người có tác dụng phụ`;
            reason += ')';
        }

        return {
            score: Math.round(finalScore),
            peerCount: records.length,
            confidence,
            reason,
        };
    }

    /**
     * Xác định mức độ tin cậy dựa trên số lượng peer feedbacks.
     */
    private static getConfidenceLevel(peerCount: number): ConfidenceLevel {
        if (peerCount >= 20) return 'HIGH';
        if (peerCount >= 5)  return 'MEDIUM';
        return 'LOW';
    }
}

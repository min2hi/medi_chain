/**
 * Health Twin Service — Bóng Sức Khỏe
 * ============================================================
 * Dịch vụ lõi cho tính năng "Bóng Sức Khỏe" của MediChain.
 * Theo dõi sức khỏe thụ động, xây dựng baseline cá nhân và
 * phát hiện bất thường qua cosine similarity.
 * ============================================================
 */

import prisma from '../config/prisma.js';
import { generateEmbedding } from './embedding.service.js';

// ─── Hằng số ngưỡng nghiệp vụ ───────────────────────────────
const MIN_LOGS_FOR_STABLE = 3;    // Tối thiểu 3 logs để baseline tin cậy
const MIN_DAYS_FOR_STABLE = 14;   // Tối thiểu 14 ngày theo dõi
const DEFAULT_ANOMALY_THRESHOLD = 0.35; // Ngưỡng cosine distance mặc định

// ─── Kiểu dữ liệu ────────────────────────────────────────────

interface HealthStatus {
    isStable: boolean;
    weeksTracked: number;
    totalLogs: number;
    recentScore: number | null;      // 0-100 derived from anomaly inverse
    trendPercent: number | null;     // % change vs last period (null if insufficient data)
    recentAnomalies: AnomalySummary[];
    patterns: PatternSummary[];      // AI-detected patterns (empty until stable)
}

interface PatternSummary {
    description: string;
    type: string;   // SEASONAL | BEHAVIORAL | DRUG_RESPONSE | RECURRING
    icon: string | null;
}

interface AnomalySummary {
    id: string;
    anomalyScore: number;
    explanation: string;
    actionType: string | null;
    detectedAt: Date;
    isDismissed: boolean;
}

interface TimelineMonth {
    monthKey: string;        // "2026-05" — matches mobile model
    label: string;           // "Tháng 5, 2026"
    healthScore: number | null; // 0-100, null if no anomaly data for that month
    events: TimelineEvent[];
}

interface TimelineEvent {
    id: string;
    source: string;
    rawContent: string;
    loggedAt: Date;
    hasAnomaly: boolean;
}

// ─── Hàm tính cosine similarity thuần JS ────────────────────

function cosineSimilarity(a: number[], b: number[]): number {
    if (a.length !== b.length || a.length === 0) return 0;
    let dot = 0, normA = 0, normB = 0;
    for (let i = 0; i < a.length; i++) {
        dot   += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }
    if (normA === 0 || normB === 0) return 0;
    return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

// ─── Hàm tính trung bình vector ────────────────────────────

function averageVectors(vectors: number[][]): number[] {
    if (vectors.length === 0) return [];
    const dim = vectors[0].length;
    const avg = new Array(dim).fill(0);
    for (const vec of vectors) {
        for (let i = 0; i < dim; i++) avg[i] += vec[i];
    }
    return avg.map(v => v / vectors.length);
}

// ============================================================
// Health Twin Service
// ============================================================

export class HealthTwinService {

    /**
     * Ghi nhận sự kiện sức khỏe — FIRE AND FORGET.
     * Hàm này không bao giờ throw, không block response.
     * Được gọi từ các controller khác sau khi đã res.json().
     */
    static async logEvent(
        userId: string,
        source: string,
        content: string,
        refId?: string
    ): Promise<void> {
        try {
            // Tạo log record trước, sau đó generate embedding async
            const log = await prisma.healthLog.create({
                data: { userId, source, rawContent: content, sourceRefId: refId ?? null },
                select: { id: true },
            });

            // Tạo embedding trong background — không chờ kết quả
            void HealthTwinService._processEmbeddingAsync(log.id, userId, content);
        } catch (err) {
            // Không throw — đây là fire-and-forget
            console.error('[HealthTwin.logEvent] Lỗi tạo log:', (err as Error).message);
        }
    }

    /**
     * Kiểm tra các chỉ số sinh học nguy hại tuyệt đối.
     * Trả về lý do bất thường nếu có, ngược lại trả về null.
     */
    private static _checkAbsoluteThresholds(content: string): { reason: string; severity: number } | null {
        const text = content.toLowerCase();
        
        // 1. Kiểm tra SpO2
        if (text.includes('spo2')) {
            const match = text.match(/spo2\s*:\s*(\d+)/i) || text.match(/spo2\s+(\d+)/i) || text.match(/(\d+)\s*%/);
            if (match) {
                const val = parseInt(match[1], 10);
                if (val > 0 && val < 93) {
                    return {
                        reason: `🚨 Chỉ số SpO2 ở mức nguy hại: ${val}% (Nguy cơ suy hô hấp, mức bình thường là >= 95%).`,
                        severity: 8
                    };
                }
            }
        }

        // 2. Kiểm tra Huyết áp (HA)
        if (text.includes('huyết áp') || text.includes('ha ') || text.includes('blood_pressure') || text.includes('blood pressure')) {
            const match = text.match(/(\d+)\s*\/\s*(\d+)/);
            if (match) {
                const sys = parseInt(match[1], 10);
                const dia = parseInt(match[2], 10);
                if (sys >= 140 || sys <= 90 || dia >= 90 || dia <= 60) {
                    let desc = '';
                    if (sys >= 140 || dia >= 90) desc = `Huyết áp cao (${sys}/${dia} mmHg)`;
                    else desc = `Huyết áp thấp (${sys}/${dia} mmHg)`;
                    return {
                        reason: `🚨 Chỉ số huyết áp ở mức cảnh báo: ${desc}. Khuyến nghị theo dõi sát sao hoặc hỏi ý kiến bác sĩ.`,
                        severity: 7
                    };
                }
            }
        }

        // 3. Kiểm tra Nhịp tim
        if (text.includes('nhịp tim') || text.includes('heart rate') || text.includes('pulse')) {
            const match = text.match(/(?:nhịp tim|heart rate|pulse)\s*:\s*(\d+)/i) || text.match(/(?:nhịp tim|heart rate|pulse)\s+(\d+)/i) || text.match(/(\d+)\s*bpm/i);
            if (match) {
                const val = parseInt(match[1], 10);
                if (val > 0 && (val > 100 || val < 50)) {
                    const desc = val > 100 ? `nhịp tim nhanh (${val} bpm)` : `nhịp tim chậm (${val} bpm)`;
                    return {
                        reason: `🚨 Nhịp tim bất thường: ${desc}. Mức bình thường khi nghỉ ngơi là 60-100 bpm.`,
                        severity: 6
                    };
                }
            }
        }

        // 4. Kiểm tra Nhiệt độ (Sốt)
        if (text.includes('nhiệt độ') || text.includes('sốt') || text.includes('temperature') || text.includes('độ c')) {
            const match = text.match(/(?:nhiệt độ|temperature|sốt)\s*:\s*(\d+(?:\.\d+)?)/i) || text.match(/(?:nhiệt độ|temperature|sốt)\s+(\d+(?:\.\d+)?)/i) || text.match(/(\d+(?:\.\d+)?)\s*độ/i) || text.match(/(\d+(?:\.\d+)?)\s*°c/i);
            if (match) {
                const val = parseFloat(match[1]);
                if (val > 0 && (val >= 38.5 || val <= 35.0)) {
                    const desc = val >= 38.5 ? `sốt cao (${val}°C)` : `hạ thân nhiệt (${val}°C)`;
                    return {
                        reason: `🚨 Nhiệt độ cơ thể bất thường: ${desc}. Cần theo dõi hoặc xử trí hạ sốt/giữ ấm kịp thời.`,
                        severity: 7
                    };
                }
            }
        }

        return null;
    }

    /**
     * Xử lý embedding async sau khi log đã được tạo.
     * Kiểm tra anomaly và cập nhật nếu baseline đã ổn định.
     */
    private static async _processEmbeddingAsync(
        logId: string,
        userId: string,
        content: string
    ): Promise<void> {
        try {
            // 1. Kiểm tra dị thường lâm sàng tuyệt đối trước (Absolute Thresholds)
            const absoluteCheck = HealthTwinService._checkAbsoluteThresholds(content);
            if (absoluteCheck) {
                // Gán score tương ứng với severity (ví dụ: severity/10)
                const score = absoluteCheck.severity / 10;
                await HealthTwinService._createAnomaly(logId, userId, score, content, absoluteCheck.reason);
                return;
            }

            const embedding = await generateEmbedding(content);
            const baseline  = await prisma.personalBaseline.findUnique({ where: { userId } });

            // Nếu baseline chưa ổn định, bỏ qua kiểm tra anomaly dựa trên vector
            if (!baseline?.isStable) return;

            // Lấy embedding trung bình từ các log gần nhất (đại diện baseline)
            const baselineEmbedding = await HealthTwinService._getBaselineVector(userId);
            if (!baselineEmbedding || baselineEmbedding.length === 0) return;

            const similarity = cosineSimilarity(embedding, baselineEmbedding);
            const distance   = 1 - similarity; // cosine distance

            // Nếu vượt ngưỡng anomaly → ghi nhận
            if (distance > (baseline.anomalyThreshold ?? DEFAULT_ANOMALY_THRESHOLD)) {
                await HealthTwinService._createAnomaly(logId, userId, distance, content);
            }
        } catch (err) {
            console.error('[HealthTwin._processEmbeddingAsync] Lỗi:', (err as Error).message);
        }
    }

    /**
     * Tính vector trung bình từ 20 log gần nhất của user.
     * Đây là "baseline vector" dùng để so sánh anomaly.
     */
    private static async _getBaselineVector(userId: string): Promise<number[] | null> {
        // Lấy 20 log gần nhất có nội dung đủ dài để làm baseline tốt
        const logs = await prisma.healthLog.findMany({
            where:   { userId },
            orderBy: { loggedAt: 'desc' },
            take:    20,
            select:  { rawContent: true },
        });
        if (logs.length < MIN_LOGS_FOR_STABLE) return null;

        // Generate embeddings song song cho hiệu quả
        const embeddings = await Promise.all(
            logs.map(l => generateEmbedding(l.rawContent).catch(() => null))
        );
        const valid = embeddings.filter((e): e is number[] => e !== null);
        if (valid.length === 0) return null;

        return averageVectors(valid);
    }

    /**
     * Tạo bản ghi anomaly với giải thích AI ngắn gọn hoặc custom explanation.
     */
    private static async _createAnomaly(
        logId: string,
        userId: string,
        score: number,
        content: string,
        customExplanation?: string
    ): Promise<void> {
        // Tránh tạo anomaly trùng lặp cho cùng log
        const existing = await prisma.healthAnomaly.findUnique({ where: { logId } });
        if (existing) return;

        // Xác định loại hành động dựa trên mức độ bất thường
        const actionType = score > 0.6 ? 'SUGGEST_APPOINTMENT'
            : score > 0.45              ? 'SUGGEST_CONSULT'
            : 'INFO';

        const explanation = customExplanation || HealthTwinService._buildExplanation(score, content, actionType);

        await prisma.healthAnomaly.create({
            data: { userId, logId, anomalyScore: score, explanation, actionType },
        });
    }

    /** Tạo lời giải thích anomaly bằng tiếng Việt */
    private static _buildExplanation(score: number, content: string, action: string): string {
        const preview = content.substring(0, 80);
        if (action === 'SUGGEST_APPOINTMENT') {
            return `⚠️ Phát hiện bất thường đáng chú ý (điểm: ${score.toFixed(2)}): "${preview}...". Chúng tôi khuyến nghị đặt lịch khám để được tư vấn.`;
        }
        if (action === 'SUGGEST_CONSULT') {
            return `💡 Nhận thấy thay đổi sức khỏe (điểm: ${score.toFixed(2)}): "${preview}...". Hãy dùng tư vấn AI để hiểu rõ hơn.`;
        }
        return `ℹ️ Ghi nhận thay đổi nhỏ trong mô hình sức khỏe (điểm: ${score.toFixed(2)}).`;
    }

    /**
     * Cập nhật baseline cá nhân — được gọi bởi cron job hàng đêm.
     * Tính toán lại weeksTracked, totalLogs, isStable.
     */
    static async updateBaseline(userId: string): Promise<void> {
        try {
            const [totalLogs, oldestLog] = await Promise.all([
                prisma.healthLog.count({ where: { userId } }),
                prisma.healthLog.findFirst({
                    where:   { userId },
                    orderBy: { loggedAt: 'asc' },
                    select:  { loggedAt: true },
                }),
            ]);

            if (totalLogs === 0 || !oldestLog) return;

            // Tính số tuần theo dõi từ log đầu tiên
            const daysTracked  = (Date.now() - oldestLog.loggedAt.getTime()) / 86400000;
            const weeksTracked = Math.floor(daysTracked / 7);

            // Baseline ổn định khi đủ logs và đủ ngày
            const isStable = totalLogs >= MIN_LOGS_FOR_STABLE && daysTracked >= MIN_DAYS_FOR_STABLE;

            // Upsert baseline record
            await prisma.personalBaseline.upsert({
                where:  { userId },
                create: { userId, totalLogs, weeksTracked, isStable },
                update: { totalLogs, weeksTracked, isStable },
            });

            console.log(`[HealthTwin] Baseline cập nhật: userId=${userId} logs=${totalLogs} weeks=${weeksTracked} stable=${isStable}`);
        } catch (err) {
            console.error('[HealthTwin.updateBaseline] Lỗi:', (err as Error).message);
        }
    }

    /**
     * Lấy trạng thái sức khỏe hiện tại của user.
     * Trả về đủ các fields mà mobile expect:
     * recentScore, trendPercent, patterns, recentAnomalies
     */
    static async getStatus(userId: string): Promise<HealthStatus> {
        const [baseline, recentAnomalies] = await Promise.all([
            prisma.personalBaseline.findUnique({ where: { userId } }),
            prisma.healthAnomaly.findMany({
                where:   { userId, isDismissed: false },
                orderBy: { detectedAt: 'desc' },
                take:    5,
                select:  { id: true, anomalyScore: true, explanation: true,
                           actionType: true, detectedAt: true, isDismissed: true },
            }),
        ]);

        // Tính recentScore: inverse của trung bình anomaly score gần nhất (0-100)
        // Nếu có dị thường (kể cả lâm sàng tuyệt đối khi baseline chưa stable), vẫn tính điểm số.
        // Nếu không có anomaly và baseline đã ổn định → mặc định 100
        let recentScore: number | null = null;
        if (recentAnomalies.length > 0) {
            const avgScore = recentAnomalies.reduce((s, a) => s + a.anomalyScore, 0) / recentAnomalies.length;
            recentScore = Math.round((1 - avgScore) * 100);
        } else if (baseline?.isStable) {
            recentScore = 100; // Không có bất thường và baseline đã ổn định → mặc định 100 (Khỏe mạnh tuyệt đối)
        }

        // trendPercent: so sánh tổng anomaly 7 ngày vs 7-14 ngày trước
        let trendPercent: number | null = null;
        if (baseline?.isStable) {
            const now    = new Date();
            const d7ago  = new Date(now.getTime() - 7  * 86400000);
            const d14ago = new Date(now.getTime() - 14 * 86400000);
            const [thisWeek, lastWeek] = await Promise.all([
                prisma.healthAnomaly.count({ where: { userId, detectedAt: { gte: d7ago } } }),
                prisma.healthAnomaly.count({ where: { userId, detectedAt: { gte: d14ago, lt: d7ago } } }),
            ]);
            if (lastWeek > 0) {
                trendPercent = Math.round(((lastWeek - thisWeek) / lastWeek) * 100);
            } else if (thisWeek === 0) {
                trendPercent = 0;
            } else {
                // lastWeek === 0 và thisWeek > 0 (phát sinh dị thường mới trong tuần này)
                // Tránh lỗi chia cho 0 và trả về giá trị âm (ví dụ: -100% nhân với số dị thường)
                trendPercent = -100 * thisWeek;
            }
        }

        return {
            isStable:        baseline?.isStable ?? false,
            weeksTracked:    baseline?.weeksTracked ?? 0,
            totalLogs:       baseline?.totalLogs ?? 0,
            recentScore,
            trendPercent,
            recentAnomalies,
            patterns:        [], // Phase 2: AI pattern extraction
        };
    }

    /**
     * Lấy timeline các sự kiện sức khỏe theo nhóm tháng.
     * Return shape khớp chính xác với HealthTimelineMonth model trên mobile:
     * { monthKey, label, healthScore, events[] }
     */
    static async getTimeline(userId: string): Promise<TimelineMonth[]> {
        const logs = await prisma.healthLog.findMany({
            where:   { userId },
            orderBy: { loggedAt: 'desc' },
            take:    100,
            select:  {
                id: true, source: true, rawContent: true, loggedAt: true, severity: true,
                anomaly: { select: { id: true, anomalyScore: true } },
            },
        });

        // Nhóm theo tháng
        const grouped: Record<string, { events: TimelineEvent[]; scores: number[] }> = {};
        for (const log of logs) {
            const monthKey = log.loggedAt.toISOString().substring(0, 7); // "2026-05"
            if (!grouped[monthKey]) grouped[monthKey] = { events: [], scores: [] };
            grouped[monthKey].events.push({
                id:         log.id,
                source:     log.source,
                rawContent: log.rawContent.substring(0, 200),
                loggedAt:   log.loggedAt,
                hasAnomaly: log.anomaly !== null,
            });
            // Thu thập anomaly score để tính healthScore của tháng
            if (log.anomaly) grouped[monthKey].scores.push(log.anomaly.anomalyScore);
        }

        // Chuyển "2026-05" → "Tháng 5, 2026" (Việt)
        const monthLabel = (key: string): string => {
            const [year, month] = key.split('-');
            return `Tháng ${parseInt(month)}, ${year}`;
        };

        return Object.entries(grouped)
            .sort(([a], [b]) => b.localeCompare(a))
            .map(([monthKey, { events, scores }]) => ({
                monthKey,
                label:       monthLabel(monthKey),
                healthScore: scores.length > 0
                    ? Math.round((1 - scores.reduce((s, v) => s + v, 0) / scores.length) * 100)
                    : null,
                events,
            }));
    }

    /**
     * Lấy danh sách anomaly gần nhất (tối đa 10).
     */
    static async getAnomalies(userId: string) {
        return prisma.healthAnomaly.findMany({
            where:   { userId },
            orderBy: { detectedAt: 'desc' },
            take:    10,
            select:  {
                id: true, anomalyScore: true, explanation: true,
                actionType: true, isNotified: true, isDismissed: true, detectedAt: true,
                log: { select: { source: true, rawContent: true, loggedAt: true } },
            },
        });
    }

    /**
     * Ghi nhận check-in hàng tuần của user.
     * feeling: 'good' | 'normal' | 'tired' | 'bad'
     */
    static async submitWeeklyCheckin(
        userId: string,
        feeling: 'good' | 'normal' | 'tired' | 'bad'
    ): Promise<void> {
        // Ánh xạ feeling sang severity 1-10
        const severityMap = { good: 2, normal: 4, tired: 6, bad: 8 };
        const severity    = severityMap[feeling] ?? 5;

        const content = `Check-in hàng tuần: Cảm giác sức khỏe "${feeling}" (${HealthTwinService._feelingLabel(feeling)})`;

        await prisma.healthLog.create({
            data: { userId, source: 'WEEKLY_CHECKIN', rawContent: content, severity },
        });

        // Cập nhật baseline ngay sau check-in
        await HealthTwinService.updateBaseline(userId);
    }

    /** Chuyển feeling sang nhãn tiếng Việt */
    private static _feelingLabel(feeling: string): string {
        const map: Record<string, string> = {
            good: 'Tốt', normal: 'Bình thường', tired: 'Mệt mỏi', bad: 'Không tốt',
        };
        return map[feeling] ?? feeling;
    }

    /**
     * Đánh dấu anomaly là đã xem (isDismissed = true).
     * Kiểm tra ownership để tránh user dismiss anomaly của người khác.
     */
    static async dismissAnomaly(userId: string, anomalyId: string): Promise<void> {
        await prisma.healthAnomaly.updateMany({
            where:  { id: anomalyId, userId }, // ownership check
            data:   { isDismissed: true },
        });
    }
}

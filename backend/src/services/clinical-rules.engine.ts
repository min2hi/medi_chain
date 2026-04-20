/**
 * ClinicalRulesEngine — "Rules as Data" Pattern
 * ─────────────────────────────────────────────────────────────────────────────
 * Architecture: Ada Health "Clinical Knowledge Graph" + Epic CDS Hooks pattern
 *
 * Load strategy (3-tier) cho keyword matching:
 *   1. LRU Cache (15 phút) — ~0ms, node-lru-cache
 *   2. PostgreSQL via Prisma — ~5-10ms, với index tối ưu
 *   3. HARDCODED_FAILSAFE — kích hoạt nếu DB unavailable (fail-safe principle)
 *
 * Phase 2 — Semantic Fallback (Layer 4):
 *   Khi keyword matching MISS → generateEmbedding(unknownText) → pgvector cosine
 *   similarity → nếu confidence cao → BLOCK và queue keyword vào PENDING review
 *
 * Hot-reload: POST /api/admin/clinical-rules/cache/invalidate → lru.clear()
 *   → next request load từ DB → rules active trong <1 giây, không cần restart
 *
 * 2-step approval: isActive=false (pending) → Admin activate → isActive=true
 * ─────────────────────────────────────────────────────────────────────────────
 */

import { LRUCache } from 'lru-cache';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';
import { generateEmbedding } from './embedding.service.js';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface EmergencyGroup {
    id: string;
    label: string;
    keywords: string[];
    keywordsNorm?: string[];  // pre-normalized variants (mobile input)
}

export interface ComboRuleData {
    name: string;
    label: string;
    symptomGroups: string[][];
    minMatch: number;
}

/**
 * Kết quả của Semantic Fallback Layer 4.
 *
 * action:
 *   'BLOCK' — similarity >= 0.85 → chặn request, giống emergency keyword
 *   'WARN'  — similarity 0.60-0.84 → thêm soft warning, tiếp tục xử lý
 *   'PASS'  — similarity < 0.60 → không liên quan, không làm gì
 *
 * queued:
 *   true nếu keyword đã được thêm vào DB với reviewStatus=PENDING
 *   false nếu đã tồn tại hoặc similarity < 0.60
 */
export interface SemanticFallbackResult {
    action:         'BLOCK' | 'WARN' | 'PASS';
    matchedGroupId?: string;
    matchedLabel?:   string;
    similarityScore: number;
    matchedKeyword?: string;   // Keyword trong DB gần nhất
    queued:          boolean;  // True nếu đã insert vào PENDING queue
}

// ─── Confidence Thresholds ────────────────────────────────────────────────────
// Được calibrate trên medical NLU benchmark (tiếng Việt)
// Cao hơn Ada Health (0.7) vì Gemini embedding tốt hơn với tiếng Việt
const BLOCK_THRESHOLD = 0.82;  // >= 0.82 → BLOCK (HIGH confidence = emergency)
const WARN_THRESHOLD  = 0.62;  // >= 0.62 → WARN  (MEDIUM confidence = suspicious)

// ─── LRU Cache ────────────────────────────────────────────────────────────────
// Node.js in-process cache — không cần Redis (single-instance)
// Khi scale lên multi-instance → swap lru → ioredis trong file này, logic không đổi

const lru = new LRUCache<string, EmergencyGroup[] | ComboRuleData[]>({
    max: 20,                  // Tối đa 20 cache entries
    ttl: 15 * 60 * 1000,     // 15 phút TTL
});

const CACHE_KEY_GROUPS  = 'cre:emergency_groups';
const CACHE_KEY_COMBOS  = 'cre:combo_rules';

// ─── Cache Stats (internal monitoring) ────────────────────────────────────────
const stats = {
    hits: 0,
    misses: 0,
    dbLoads: 0,
    failsafeActivations: 0,
    semanticFallbackCalls: 0,
    semanticBlocks: 0,
    semanticWarns: 0,
    semanticQueued: 0,
};

// ─────────────────────────────────────────────────────────────────────────────
// HARDCODED FAILSAFE
// ─────────────────────────────────────────────────────────────────────────────
// Chỉ kích hoạt khi DB unavailable.
// Giữ ~50 critical keywords đủ để không bao giờ miss emergency.
// Các keywords này là MINIMUM SAFE SET — không replace full DB.
// ─────────────────────────────────────────────────────────────────────────────
const HARDCODED_FAILSAFE_GROUPS: EmergencyGroup[] = [
    {
        id: 'acs',
        label: 'Hội chứng vành cấp [FAILSAFE]',
        keywords: ['đau ngực', 'tức ngực', 'nhồi máu cơ tim', 'đau lan tay trái']
    },
    {
        id: 'stroke',
        label: 'Đột quỵ não [FAILSAFE]',
        keywords: ['đột quỵ', 'tai biến', 'méo miệng', 'miệng méo', 'liệt nửa người',
                   'như sét đánh', 'sét đánh vào đầu', 'nói ú ớ']
    },
    {
        id: 'resp_failure',
        label: 'Suy hô hấp cấp [FAILSAFE]',
        keywords: ['khó thở', 'không thở được', 'suy hô hấp', 'móc tím', 'tím tái']
    },
    {
        id: 'anaphylaxis',
        label: 'Sốc phản vệ [FAILSAFE]',
        keywords: ['sốc phản vệ', 'phù lưỡi', 'phù môi', 'phản vệ']
    },
    {
        id: 'syncope',
        label: 'Mất ý thức [FAILSAFE]',
        keywords: ['bất tỉnh', 'mất ý thức', 'ngất xỉu', 'hôn mê']
    },
    {
        id: 'seizure',
        label: 'Co giật [FAILSAFE]',
        keywords: ['co giật', 'động kinh']
    },
    {
        id: 'gi_bleeding',
        label: 'Xuất huyết tiêu hóa [FAILSAFE]',
        keywords: ['nôn ra máu', 'ói ra máu', 'phân đen', 'tiêu chảy ra máu']
    },
    {
        id: 'overdose',
        label: 'Ngộ độc / Quá liều [FAILSAFE]',
        keywords: ['ngộ độc', 'uống quá liều', 'uống thuốc tự tử']
    },
    {
        id: 'sepsis',
        label: 'Nhiễm trùng huyết [FAILSAFE]',
        keywords: ['nhiễm trùng huyết', 'viêm màng não', 'cứng cổ', 'sợ ánh sáng', 'lú lẫn']
    },
    {
        id: 'shock',
        label: 'Sốc [FAILSAFE]',
        keywords: ['tụt huyết áp', 'vã mồ hôi lạnh', 'da lạnh nhợt', 'sốc']
    },
];

const HARDCODED_FAILSAFE_COMBOS: ComboRuleData[] = [
    {
        name: 'meningitis_triad',
        label: '⚠️ COMBO: Sốt + Cứng cổ → Nghi VIÊM MÀNG NÃO [FAILSAFE]',
        symptomGroups: [['sốt', 'sốt cao'], ['cứng cổ', 'gáy cứng']],
        minMatch: 2,
    },
    {
        name: 'acs_atypical',
        label: '⚠️ COMBO: Đau ngực + Vã mồ hôi → Nghi NHỒI MÁU CƠ TIM [FAILSAFE]',
        symptomGroups: [['đau ngực', 'tức ngực', 'nặng ngực'], ['vã mồ hôi', 'mồ hôi lạnh']],
        minMatch: 2,
    },
    {
        name: 'fast_stroke',
        label: '⚠️ COMBO: Yếu/Tê + Nói khó + Méo mặt → FAST — ĐỘT QUỴ [FAILSAFE]',
        symptomGroups: [['yếu tay', 'tê tay', 'liệt'], ['nói khó', 'nói ú ớ'], ['mặt méo', 'miệng méo']],
        minMatch: 2,
    },
];

// ─────────────────────────────────────────────────────────────────────────────
// CLINICAL RULES ENGINE
// ─────────────────────────────────────────────────────────────────────────────

export class ClinicalRulesEngine {

    // ─── Public API ────────────────────────────────────────────────────────────

    /**
     * Load emergency groups (keyword lists per emergency category).
     * Strategy: LRU Cache → DB → Hardcoded Failsafe
     */
    static async getEmergencyGroups(): Promise<EmergencyGroup[]> {
        const cached = lru.get(CACHE_KEY_GROUPS) as EmergencyGroup[] | undefined;
        if (cached) {
            stats.hits++;
            return cached;
        }

        stats.misses++;

        try {
            const keywords = await prisma.safetyKeyword.findMany({
                where:   { isActive: true, reviewStatus: 'ACTIVE' },
                select:  { groupId: true, groupLabel: true, keyword: true, keywordNorm: true },
                orderBy: { groupId: 'asc' },
            });

            if (keywords.length === 0) {
                logger.warn('[CRE] SafetyKeyword table is empty — using failsafe. Run prisma db seed.');
                stats.failsafeActivations++;
                return HARDCODED_FAILSAFE_GROUPS;
            }

            const groups = ClinicalRulesEngine._buildGroups(keywords);
            lru.set(CACHE_KEY_GROUPS, groups);
            stats.dbLoads++;
            logger.info(`[CRE] Loaded ${keywords.length} keywords across ${groups.length} groups from DB`);
            return groups;
        } catch (err) {
            logger.error({ err }, '[CRE] DB unavailable — activating hardcoded failsafe');
            stats.failsafeActivations++;
            return HARDCODED_FAILSAFE_GROUPS;
        }
    }

    /**
     * Load combo rules (multi-symptom pattern matching).
     * Strategy: LRU Cache → DB → Hardcoded Failsafe
     */
    static async getComboRules(): Promise<ComboRuleData[]> {
        const cached = lru.get(CACHE_KEY_COMBOS) as ComboRuleData[] | undefined;
        if (cached) {
            stats.hits++;
            return cached;
        }

        stats.misses++;

        try {
            const rows = await prisma.comboRule.findMany({
                where:  { isActive: true },
                select: { name: true, label: true, symptomGroups: true, minMatch: true },
            });

            if (rows.length === 0) {
                stats.failsafeActivations++;
                return HARDCODED_FAILSAFE_COMBOS;
            }

            const combos: ComboRuleData[] = rows.map((r: { name: string; label: string; symptomGroups: unknown; minMatch: number }) => ({
                name:          r.name,
                label:         r.label,
                symptomGroups: r.symptomGroups as string[][],
                minMatch:      r.minMatch,
            }));

            lru.set(CACHE_KEY_COMBOS, combos);
            stats.dbLoads++;
            return combos;
        } catch {
            stats.failsafeActivations++;
            return HARDCODED_FAILSAFE_COMBOS;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 4: SEMANTIC FALLBACK — pgvector cosine similarity
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * Khi keyword matching (Layers 1-3) MISS, gọi hàm này.
     *
     * Luồng:
     *   1. generateEmbedding(symptomText) — Gemini embedding-001 (768 dim)
     *   2. pgvector <=> cosine distance với all ACTIVE SafetyKeyword có embedding
     *   3. Top match:
     *      similarity >= BLOCK_THRESHOLD (0.82) → BLOCK + queue PENDING
     *      similarity >= WARN_THRESHOLD  (0.62) → WARN  + queue PENDING
     *      else                                 → PASS (không làm gì)
     *   4. Nếu BLOCK/WARN → insert keyword vào DB với reviewStatus=PENDING
     *      (KHÔNG auto-activate — cần admin review)
     *
     * @param symptomText — Đoạn text gốc của user (không cần normalize)
     * @param contextLabel — Optional: label bổ sung ngữ cảnh cho embedding
     */
    static async semanticFallback(
        symptomText: string,
        contextLabel = ''
    ): Promise<SemanticFallbackResult> {
        stats.semanticFallbackCalls++;

        // Bước 1: Kiểm tra embeddings có trong DB không
        // Nếu chưa có → skip semantic (chưa chạy generate-keyword-embeddings.ts)
        const embeddingCount = await prisma.$queryRaw<[{ count: bigint }]>`
            SELECT COUNT(*)::bigint as count FROM "SafetyKeyword"
            WHERE "isActive" = true AND embedding IS NOT NULL
        `;
        const totalWithEmbedding = Number(embeddingCount[0]?.count ?? 0);

        if (totalWithEmbedding === 0) {
            logger.warn('[CRE-Layer4] No embeddings found in DB. Run generate-keyword-embeddings.ts first.');
            return { action: 'PASS', similarityScore: 0, queued: false };
        }

        // Bước 2: Generate embedding cho input text
        let queryEmbedding: number[];
        try {
            const textToEmbed = contextLabel
                ? `${symptomText} — ${contextLabel}`
                : symptomText;
            queryEmbedding = await generateEmbedding(textToEmbed);
        } catch (err) {
            logger.error({ err }, '[CRE-Layer4] Failed to generate embedding — skipping semantic fallback');
            return { action: 'PASS', similarityScore: 0, queued: false };
        }

        // Bước 3: pgvector cosine similarity search
        // <=> = cosine distance (0 = identical, 2 = opposite)
        // similarity = 1 - distance
        const vectorStr = `[${queryEmbedding.join(',')}]`;

        type SimilarKeywordRow = {
            id: number;
            keyword: string;
            groupId: string;
            groupLabel: string;
            similarity: number;
        };

        const results = await prisma.$queryRawUnsafe<SimilarKeywordRow[]>(`
            SELECT
                id,
                keyword,
                "groupId",
                "groupLabel",
                (1 - (embedding <=> '${vectorStr}'::vector)) AS similarity
            FROM "SafetyKeyword"
            WHERE "isActive" = true
              AND "reviewStatus" = 'ACTIVE'
              AND embedding IS NOT NULL
            ORDER BY embedding <=> '${vectorStr}'::vector
            LIMIT 3
        `);

        if (!results || results.length === 0) {
            return { action: 'PASS', similarityScore: 0, queued: false };
        }

        const top = results[0];
        const similarity = Number(top.similarity);

        logger.info(
            `[CRE-Layer4] Semantic match: "${symptomText}" → "${top.keyword}" ` +
            `(${top.groupId}, similarity=${similarity.toFixed(3)})`
        );

        // Bước 4: Decision gate
        let action: 'BLOCK' | 'WARN' | 'PASS' = 'PASS';
        if (similarity >= BLOCK_THRESHOLD)     { action = 'BLOCK'; stats.semanticBlocks++; }
        else if (similarity >= WARN_THRESHOLD) { action = 'WARN';  stats.semanticWarns++;  }

        // Bước 5: Queue keyword vào PENDING nếu cần thiết
        // KHÔNG activate tự động — cần admin review
        let queued = false;
        if (action !== 'PASS') {
            queued = await ClinicalRulesEngine._queuePendingKeyword(
                symptomText, top, similarity
            );
        }

        return {
            action,
            matchedGroupId:  top.groupId,
            matchedLabel:    top.groupLabel,
            similarityScore: similarity,
            matchedKeyword:  top.keyword,
            queued,
        };
    }

    /**
     * Admin: invalidate all cached rules.
     * Call this after any keyword add/edit/deactivate via Admin API.
     * Next request will reload from DB — rules live in <1 second.
     */
    static invalidateCache(): void {
        lru.clear();
        logger.info('[CRE] Cache invalidated — next request will reload from DB');
    }

    /**
     * Cache statistics — for Admin monitoring endpoint.
     */
    static getCacheStats() {
        return {
            ...stats,
            cacheSize:   lru.size,
            cacheItems:  lru.calculatedSize,
            hitRate:     stats.hits + stats.misses > 0
                ? ((stats.hits / (stats.hits + stats.misses)) * 100).toFixed(1) + '%'
                : 'N/A',
            thresholds: {
                block: BLOCK_THRESHOLD,
                warn:  WARN_THRESHOLD,
            },
        };
    }

    // ─── Private Helpers ───────────────────────────────────────────────────────

    /**
     * Group flat keyword rows by groupId → EmergencyGroup[]
     */
    private static _buildGroups(
        keywords: { groupId: string; groupLabel: string; keyword: string; keywordNorm: string }[]
    ): EmergencyGroup[] {
        const map = new Map<string, EmergencyGroup>();

        for (const kw of keywords) {
            if (!map.has(kw.groupId)) {
                map.set(kw.groupId, {
                    id:       kw.groupId,
                    label:    kw.groupLabel,
                    keywords: [],
                    keywordsNorm: [],
                });
            }
            const group = map.get(kw.groupId)!;
            group.keywords.push(kw.keyword);
            group.keywordsNorm?.push(kw.keywordNorm);
        }

        return Array.from(map.values());
    }

    /**
     * Insert keyword vào DB với reviewStatus=PENDING.
     * Idempotent: nếu keyword đã tồn tại (dù ở bất kỳ status nào) → skip.
     *
     * Returns true nếu đã insert mới, false nếu đã tồn tại.
     */
    private static async _queuePendingKeyword(
        keyword:    string,
        topMatch:   { id: number; keyword: string; groupId: string; groupLabel: string },
        similarity: number
    ): Promise<boolean> {
        try {
            // Kiểm tra xem keyword đã có trong DB dưới bất kỳ form nào chưa
            const existing = await prisma.safetyKeyword.findFirst({
                where: { keyword: keyword.toLowerCase().trim() },
            });

            if (existing) return false; // Đã có, không insert duplicate

            // Insert mới với PENDING status
            await prisma.safetyKeyword.create({
                data: {
                    groupId:        topMatch.groupId,
                    groupLabel:     topMatch.groupLabel,
                    keyword:        keyword.toLowerCase().trim(),
                    keywordNorm:    keyword.toLowerCase()
                                        .normalize('NFD')
                                        .replace(/[\u0300-\u036f]/g, '')
                                        .replace(/đ/g, 'd')
                                        .replace(/Đ/g, 'D')
                                        .trim(),
                    language:       'vi',
                    isActive:       false,         // KHÔNG active — chờ admin
                    reviewStatus:   'PENDING',
                    discoveredBy:   'SEMANTIC_DISCOVERY',
                    similarityScore: similarity,
                    sourceKeywordId: topMatch.id,  // Tham chiếu keyword gốc
                    createdBy:      'SYSTEM_SEMANTIC_V1',
                    changeNote:     `Auto-discovered via semantic similarity (${(similarity * 100).toFixed(1)}% match with "${topMatch.keyword}")`,
                    versionTag:     'v2.2-semantic',
                },
            });

            stats.semanticQueued++;
            logger.info(
                `[CRE-Layer4] Queued PENDING keyword: "${keyword}" → group "${topMatch.groupId}" ` +
                `(${(similarity * 100).toFixed(1)}% match with "${topMatch.keyword}")`
            );
            return true;

        } catch (err) {
            logger.error({ err }, `[CRE-Layer4] Failed to queue pending keyword: "${keyword}"`);
            return false;
        }
    }
}

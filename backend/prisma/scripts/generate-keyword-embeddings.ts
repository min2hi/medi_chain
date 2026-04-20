/**
 * generate-keyword-embeddings.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Script chạy 1 lần để pre-compute embedding cho tất cả SafetyKeyword.
 * Sau khi chạy, ClinicalRulesEngine có thể dùng pgvector cosine similarity
 * để phát hiện keyword mới không có trong DB (Semantic Fallback — Phase 2).
 *
 * Cách chạy:
 *   npx tsx prisma/scripts/generate-keyword-embeddings.ts
 *
 * Rate limit: Gemini free = 15 req/min → script tự throttle 4.5s/request.
 * 151 keywords × 4.5s ≈ ~12 phút. Chỉ cần chạy 1 lần.
 *
 * Idempotent: Chỉ generate cho keyword chưa có embedding (embedding IS NULL).
 * ─────────────────────────────────────────────────────────────────────────────
 */

import { PrismaClient } from '../../src/generated/client/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import { generateEmbedding } from '../../src/services/embedding.service.js';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL!,
    ssl: process.env.DATABASE_URL?.includes('sslmode=require')
        ? { rejectUnauthorized: false } : undefined,
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

// Gemini free tier: 15 req/min → 4.2s per request để an toàn
const RATE_LIMIT_DELAY_MS = 4200;

async function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
    console.log('🧠 SafetyKeyword Embedding Generator v1.0');
    console.log('='.repeat(60));

    // Tạo HNSW index nếu chưa có (pgvector accelerated search)
    // HNSW cho phép approximate nearest neighbor search với độ trễ < 1ms
    console.log('\n📐 Ensuring HNSW index exists...');
    try {
        await prisma.$executeRawUnsafe(`
            CREATE INDEX IF NOT EXISTS safety_keyword_embedding_hnsw_idx
            ON "SafetyKeyword" USING hnsw (embedding vector_cosine_ops)
            WITH (m = 16, ef_construction = 64)
        `);
        console.log('   ✅ HNSW index ready');
    } catch (err: any) {
        // Index có thể đã tồn tại với tên khác, không dừng script
        console.warn('   ⚠️  HNSW index note:', err.message);
    }

    // Lấy tất cả keyword chưa có embedding
    const keywords = await prisma.safetyKeyword.findMany({
        where:  { isActive: true },
        select: { id: true, keyword: true, groupId: true, groupLabel: true },
        orderBy: { id: 'asc' },
    });

    // Filter ra những keyword chưa có embedding (raw query vì Prisma không support vector type)
    const missingEmbeddings = await prisma.$queryRaw<{ id: number }[]>`
        SELECT id FROM "SafetyKeyword"
        WHERE "isActive" = true AND embedding IS NULL
        ORDER BY id ASC
    `;
    const missingIds = new Set(missingEmbeddings.map(r => r.id));
    const toProcess = keywords.filter(k => missingIds.has(k.id));

    console.log(`\n📊 Status:`);
    console.log(`   Total active keywords: ${keywords.length}`);
    console.log(`   Already have embedding: ${keywords.length - toProcess.length}`);
    console.log(`   Need embedding:         ${toProcess.length}`);

    if (toProcess.length === 0) {
        console.log('\n✅ All keywords already have embeddings. Nothing to do.');
        return;
    }

    console.log(`\n⏱  Estimated time: ~${Math.ceil(toProcess.length * RATE_LIMIT_DELAY_MS / 60000)} minutes`);
    console.log(`   (Rate limited to 1 request / ${RATE_LIMIT_DELAY_MS}ms for Gemini free tier)\n`);

    let success = 0, failed = 0;

    for (let i = 0; i < toProcess.length; i++) {
        const kw = toProcess[i];
        const progress = `[${i + 1}/${toProcess.length}]`;

        try {
            // Generate embedding cho keyword (có dấu tiếng Việt)
            // Dùng cả keyword lẫn groupLabel để embedding có ngữ cảnh y tế
            const textForEmbedding = `${kw.keyword} — ${kw.groupLabel}`;
            const vector = await generateEmbedding(textForEmbedding);

            // Lưu vào DB bằng raw query (Prisma không support vector type trực tiếp)
            const vectorStr = `[${vector.join(',')}]`;
            await prisma.$executeRawUnsafe(
                `UPDATE "SafetyKeyword" SET embedding = $1::vector WHERE id = $2`,
                vectorStr, kw.id
            );

            success++;
            console.log(`   ${progress} ✅ [${kw.groupId}] "${kw.keyword}"`);

        } catch (err: any) {
            failed++;
            console.error(`   ${progress} ❌ "${kw.keyword}": ${err.message}`);
        }

        // Rate limit delay (trừ request cuối)
        if (i < toProcess.length - 1) {
            await sleep(RATE_LIMIT_DELAY_MS);
        }
    }

    // Final summary
    const totalWithEmbedding = await prisma.$queryRaw<[{ count: bigint }]>`
        SELECT COUNT(*) as count FROM "SafetyKeyword"
        WHERE "isActive" = true AND embedding IS NOT NULL
    `;

    console.log('\n' + '='.repeat(60));
    console.log('📊 Final Summary:');
    console.log(`   ✅ Succeeded: ${success}`);
    console.log(`   ❌ Failed:    ${failed}`);
    console.log(`   📦 Total keywords with embedding: ${totalWithEmbedding[0]?.count ?? 0}`);
    console.log('\n🚀 Semantic Fallback (Layer 4) is now READY!');
    console.log('   ClinicalRulesEngine.semanticFallback() can now detect');
    console.log('   unknown emergency keywords via cosine similarity.');
    console.log('='.repeat(60));
}

main()
    .catch(err => {
        console.error('❌ Script failed:', err);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
        await pool.end();
    });

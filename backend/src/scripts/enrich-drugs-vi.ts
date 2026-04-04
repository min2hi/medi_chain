import prisma from '../config/prisma.js';
import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';

dotenv.config();

// ============================================================
// AI DRUG ENRICHMENT SCRIPT - MediChain
// ============================================================
// Script này dùng Google Gemini AI để:
// 1. Đọc toàn bộ thuốc trong DB (đặc biệt thuốc nhập từ OpenFDA tiếng Anh)
// 2. Gọi AI "tiêu hóa" dữ liệu thô → Sinh ra nội dung tiếng Việt thân thiện
// 3. Lưu lại vào 3 trường mới: viSummary, viIndications, viWarnings
//
// Kết quả: Người dùng thấy thông tin thuốc bằng tiếng Việt rõ ràng,
// thay vì những đoạn văn FDA tiếng Anh lộn xộn.
//
// HOW TO RUN:
//   npx tsx src/scripts/enrich-drugs-vi.ts
// ============================================================

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-lite' });

const BATCH_SIZE = 10;       // Xử lý 10 thuốc mỗi vòng (giảm để tránh rate limit)
const DELAY_MS = 3000;       // Chờ 3 giây giữa mỗi lần gọi
const BATCH_DELAY_MS = 5000; // Chờ 5 giây giữa các batch

// ─── Prompt template cho Gemini ───
function buildPrompt(drug: {
    name: string;
    genericName: string;
    category: string;
    ingredients: string;
    indications: string;
    contraindications: string;
    sideEffects: string;
}): string {
    return `Bạn là dược sĩ chuyên nghiệp. Hãy đọc thông tin thuốc sau (bằng tiếng Anh) và trả lời theo định dạng JSON yêu cầu, bằng tiếng Việt thân thiện, ngắn gọn, dễ hiểu cho người dùng bình thường (không phải bác sĩ).

THÔNG TIN THUỐC:
Tên: ${drug.name}
Hoạt chất: ${drug.genericName}
Nhóm: ${drug.category}
Thành phần: ${drug.ingredients}
Công dụng (tiếng Anh): ${drug.indications.substring(0, 800)}
Chống chỉ định (tiếng Anh): ${drug.contraindications.substring(0, 500)}
Tác dụng phụ (tiếng Anh): ${drug.sideEffects.substring(0, 500)}

YÊU CẦU: Trả lời ĐÚNG định dạng JSON sau (không thêm bất kỳ text nào khác):
{
  "viSummary": "Mô tả ngắn gọn 1-2 câu về thuốc này là gì và dùng để làm gì (tiếng Việt)",
  "viIndications": "Liệt kê 3-6 công dụng chính bằng tiếng Việt, mỗi công dụng cách nhau bằng dấu chấm phẩy",
  "viWarnings": "Liệt kê 2-4 điều quan trọng cần tránh/lưu ý bằng tiếng Việt, mỗi điều cách nhau bằng dấu chấm phẩy"
}`;
}

// ─── Gọi Gemini và parse JSON response ───
async function enrichWithAI(drug: any): Promise<{
    viSummary: string;
    viIndications: string;
    viWarnings: string;
} | null> {
    try {
        const prompt = buildPrompt(drug);
        const result = await model.generateContent(prompt);
        const text = result.response.text().trim();
        
        // Tìm và extract JSON từ response
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (!jsonMatch) {
            console.warn(`  ⚠️ Không parse được JSON cho ${drug.name}`);
            return null;
        }
        
        const parsed = JSON.parse(jsonMatch[0]);
        
        // Validate các trường cần thiết
        if (!parsed.viSummary || !parsed.viIndications || !parsed.viWarnings) {
            return null;
        }
        
        return {
            viSummary: parsed.viSummary.substring(0, 1000),
            viIndications: parsed.viIndications.substring(0, 1000),
            viWarnings: parsed.viWarnings.substring(0, 1000),
        };
    } catch (err: any) {
        console.warn(`  ⚠️ Lỗi AI cho ${drug.name}: ${err.message?.substring(0, 80)}`);
        return null;
    }
}

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// ─── MAIN ───
async function main() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('🧠 AI DRUG ENRICHMENT - Dịch và làm giàu dữ liệu thuốc');
    console.log('═══════════════════════════════════════════════════════════');

    // Lấy tất cả thuốc, lọc bằng raw query để check viSummary null
    // (viSummary là cột mới thêm raw, Prisma client chưa biết)
    const drugs = await prisma.$queryRaw<Array<{
        id: string; name: string; genericName: string;
        category: string; ingredients: string;
        indications: string; contraindications: string; sideEffects: string;
    }>>`
        SELECT id, name, "genericName", category, ingredients,
               indications, contraindications, "sideEffects"
        FROM "DrugCandidate"
        WHERE "viSummary" IS NULL
        ORDER BY "createdAt" ASC
    `;

    console.log(`📊 Tìm thấy ${drugs.length} thuốc chưa có nội dung tiếng Việt.`);
    
    if (drugs.length === 0) {
        console.log('✅ Tất cả thuốc đã được enrich rồi!');
        return;
    }
    
    console.log(`🚀 Bắt đầu xử lý theo batch ${BATCH_SIZE} thuốc...\n`);

    let success = 0;
    let failed = 0;
    
    // Xử lý theo batch để tránh rate limit
    for (let i = 0; i < drugs.length; i += BATCH_SIZE) {
        const batch = drugs.slice(i, i + BATCH_SIZE);
        const batchNum = Math.floor(i / BATCH_SIZE) + 1;
        const totalBatches = Math.ceil(drugs.length / BATCH_SIZE);
        
        console.log(`📦 [Batch ${batchNum}/${totalBatches}] Xử lý ${batch.length} thuốc...`);
        
        for (const drug of batch) {
            const enriched = await enrichWithAI(drug);
            
            if (enriched) {
                await prisma.$executeRawUnsafe(
                    `UPDATE "DrugCandidate" 
                     SET "viSummary" = $1, "viIndications" = $2, "viWarnings" = $3, "updatedAt" = now()
                     WHERE id = $4`,
                    enriched.viSummary,
                    enriched.viIndications,
                    enriched.viWarnings,
                    drug.id
                );
                success++;
                console.log(`  ✅ [${success}] ${drug.name.substring(0, 50)}`);
                console.log(`     → ${enriched.viSummary.substring(0, 80)}...`);
            } else {
                failed++;
                // Ghi placeholder để không bị lặp lại ở lần sau
                await prisma.$executeRawUnsafe(
                    `UPDATE "DrugCandidate" 
                     SET "viSummary" = $1, "viIndications" = $2, "viWarnings" = $3, "updatedAt" = now()
                     WHERE id = $4`,
                    `Thuốc ${drug.genericName} - Xem thông tin chi tiết từ nhà sản xuất`,
                    drug.indications.substring(0, 200),
                    drug.contraindications.substring(0, 200),
                    drug.id
                );
            }
            
            await sleep(DELAY_MS);
        }
        
        if (i + BATCH_SIZE < drugs.length) {
            console.log(`
⏳ Nghỉ 5 giây trước batch tiếp theo...
`);
            await sleep(BATCH_DELAY_MS);
        }
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('🎉 HOÀN TẤT AI ENRICHMENT!');
    console.log(`   ✅ Thành công: ${success} thuốc`);
    console.log(`   ⚠️  Placeholder: ${failed} thuốc`);
    
    const countResult = await prisma.$queryRaw<[{count: bigint}]>`
        SELECT COUNT(*) FROM "DrugCandidate" WHERE "viSummary" IS NOT NULL
    `;
    const enrichedCount = Number(countResult[0].count);
    console.log(`   📦 Tổng thuốc có nội dung VN: ${enrichedCount}`);
    console.log('═══════════════════════════════════════════════════════════');
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });

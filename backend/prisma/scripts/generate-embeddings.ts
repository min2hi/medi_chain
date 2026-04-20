import prisma from '../../src/config/prisma.js';
import { generateEmbedding } from '../../src/services/embedding.service.js';

async function main() {
    console.log("🚀 Đang khởi chạy quá trình tạo Vector/Embeddings cho các loại thuốc...");
    // 1. Lên danh sách toàn bộ DrugCandidate
    const drugs = await prisma.drugCandidate.findMany({
        select: {
            id: true,
            name: true,
            category: true,
            indications: true,
            sideEffects: true
        }
    });

    console.log(`Tìm thấy ${drugs.length} thuốc cần xử lý.`);

    // 2. Lặp qua từng loại thuốc và tạo embedding
    for (const [index, drug] of drugs.entries()) {
        try {
            // Gom các trường quan trọng để vector giàu ngữ nghĩa
            // "category", "indications", "sideEffects" hoặc "name"
            const textToEmbed = `
              Category: ${drug.category}
              Indications (Chỉ định điều trị): ${drug.indications}
              Side Effects (Tác dụng phụ): ${drug.sideEffects}
            `.trim().replace(/\s+/g, ' ');

            console.log(`[${index + 1}/${drugs.length}] Đang xử lý ${drug.name}...`);
            
            // Gọi OpenAI
            const embedding = await generateEmbedding(textToEmbed);
            
            // 3. Update field "embedding" vào DB
            // Prisma không native support update vector array object type trực tiếp một cách đơn giản, 
            // nên ta dùng $executeRawUnsafe với explicit typecast ::vector
            
            await prisma.$executeRawUnsafe(
                `UPDATE "DrugCandidate" SET embedding = $1::vector WHERE id = $2`,
                JSON.stringify(embedding),
                drug.id
            );

        } catch (err) {
            console.error(`❌ Lỗi khi xử lý thuốc ID ${drug.id} (${drug.name}):`, err);
        }
    }

    console.log("✅ Hoàn tất quá trình cập nhật Vector DB!");
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });

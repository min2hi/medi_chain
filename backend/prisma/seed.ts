/**
 * Prisma Seed Script — Chuẩn nghiệp vụ
 * 
 * 📌 Khái niệm: Seed là script tạo "master data" (dữ liệu hệ thống)
 *    vào database BẤT KỲ môi trường nào (local, staging, production).
 *
 * 📌 Nguyên tắc seed chuẩn:
 *    1. Idempotent: Chạy nhiều lần vẫn cho kết quả như nhau (không duplicate)
 *    2. Chỉ seed "master data": thuốc, danh mục, config... KHÔNG seed user data
 *    3. Dùng upsert: nếu đã có → update, chưa có → insert
 *
 * 💡 Cách chạy: npx prisma db seed
 */

import { PrismaClient } from './src/generated/client/index.js';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...\n');

  // ===== SEED DRUGS (DrugCandidate) =====
  await seedDrugs();

  console.log('\n✅ Seed completed successfully!');
}

async function seedDrugs() {
  // Load dữ liệu từ JSON file (được export từ local DB)
  const drugsPath = resolve(__dirname, 'prisma', 'seed-data', 'drugs.json');
  const drugs = JSON.parse(readFileSync(drugsPath, 'utf-8'));

  console.log(`💊 Seeding ${drugs.length} drugs...`);

  let created = 0;
  let skipped = 0;

  for (const drug of drugs) {
    try {
      await prisma.drugCandidate.upsert({
        where: { id: drug.id },
        // Nếu đã tồn tại → update (keep dữ liệu mới nhất)
        update: {
          name: drug.name,
          genericName: drug.genericName,
          ingredients: drug.ingredients,
          category: drug.category,
          indications: drug.indications,
          contraindications: drug.contraindications,
          sideEffects: drug.sideEffects,
          minAge: drug.minAge,
          maxAge: drug.maxAge,
          notForPregnant: drug.notForPregnant,
          notForNursing: drug.notForNursing,
          notForConditions: drug.notForConditions,
          interactsWith: drug.interactsWith,
          baseSafetyScore: drug.baseSafetyScore,
          isActive: drug.isActive,
          viIndications: drug.viIndications,
          viSummary: drug.viSummary,
          viWarnings: drug.viWarnings,
        },
        // Nếu chưa tồn tại → create mới
        create: {
          id: drug.id,
          name: drug.name,
          genericName: drug.genericName,
          ingredients: drug.ingredients,
          category: drug.category,
          indications: drug.indications,
          contraindications: drug.contraindications,
          sideEffects: drug.sideEffects,
          minAge: drug.minAge,
          maxAge: drug.maxAge,
          notForPregnant: drug.notForPregnant,
          notForNursing: drug.notForNursing,
          notForConditions: drug.notForConditions,
          interactsWith: drug.interactsWith,
          baseSafetyScore: drug.baseSafetyScore,
          isActive: drug.isActive,
          createdAt: new Date(drug.createdAt),
          updatedAt: new Date(drug.updatedAt),
          viIndications: drug.viIndications,
          viSummary: drug.viSummary,
          viWarnings: drug.viWarnings,
        },
      });
      created++;
    } catch (e) {
      console.error(`  ❌ Failed to seed drug: ${drug.name}`, e.message);
      skipped++;
    }

    // Log progress every 100 drugs
    if (created % 100 === 0 && created > 0) {
      const pct = Math.round((created / drugs.length) * 100);
      process.stdout.write(`\r  Progress: ${created}/${drugs.length} (${pct}%)`);
    }
  }

  console.log(`\n  ✅ Done: ${created} upserted, ${skipped} failed`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

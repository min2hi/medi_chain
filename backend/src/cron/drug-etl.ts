/**
 * ============================================================
 * OpenFDA Drug ETL Service — MediChain Data Pipeline
 * ============================================================
 *
 * ETL = Extract → Transform → Load
 *
 * Extract  : Kéo dữ liệu thuốc mới từ OpenFDA API (fda.gov)
 * Transform : Chuẩn hóa sang schema DrugCandidate của MediChain
 * Load      : Upsert vào Neon PostgreSQL (không duplicate)
 *
 * Data source: https://api.fda.gov/drug/label.json
 * - Miễn phí, không cần API key cho 1000 req/day
 * - Có thể đăng ký key để tăng lên 120,000 req/day
 *
 * Chạy: Hàng ngày lúc 3:00 AM (sau CF Matrix Job)
 */

import prisma from '../config/prisma.js';
import { GoogleGenerativeAI } from '@google/generative-ai';

// ─── Config ────────────────────────────────────────────────
const FDA_BASE_URL = 'https://api.fda.gov/drug/label.json';
const FETCH_LIMIT = 100;        // Số thuốc mỗi API call (max 100)
const MAX_NEW_DRUGS = 500;      // Giới hạn số thuốc mới mỗi lần chạy ETL
const EMBEDDING_MODEL = 'text-embedding-004';
const EMBEDDING_BATCH_SIZE = 5; // Gọi Gemini theo batch để tránh rate limit

// Danh mục mapping từ OpenFDA → MediChain
const CATEGORY_MAP: Record<string, string> = {
  'COUGH_COLD': 'COUGH_COLD',
  'PAIN': 'PAIN_FEVER',
  'ANALGESIC': 'PAIN_FEVER',
  'ANTIBIOTIC': 'ANTIBIOTIC',
  'ANTIHISTAMINE': 'ALLERGY',
  'ALLERGY': 'ALLERGY',
  'CARDIOVASCULAR': 'CARDIOVASCULAR',
  'DIABETES': 'DIABETES',
  'VITAMIN': 'SUPPLEMENT',
  'SUPPLEMENT': 'SUPPLEMENT',
  'DERMATOLOGICAL': 'SKIN',
  'OPHTHALMIC': 'EYE_EAR',
  'ANTIFUNGAL': 'ANTIFUNGAL',
  'DEFAULT': 'OTHER',
};

function mapCategory(fdaPharmClass: string[] = []): string {
  const classStr = fdaPharmClass.join(' ').toUpperCase();
  for (const [key, val] of Object.entries(CATEGORY_MAP)) {
    if (classStr.includes(key)) return val;
  }
  return CATEGORY_MAP.DEFAULT;
}

// ─── Extract ───────────────────────────────────────────────
async function fetchFDAPage(skip: number): Promise<any[]> {
  const url = `${FDA_BASE_URL}?limit=${FETCH_LIMIT}&skip=${skip}&_sort=effective_time:desc`;
  const res = await fetch(url, {
    headers: { 'User-Agent': 'MediChain-ETL/1.0 (healthcare data pipeline)' },
    signal: AbortSignal.timeout(15000), // 15s timeout
  });

  if (!res.ok) {
    if (res.status === 404) return []; // No more results
    throw new Error(`FDA API error: ${res.status}`);
  }

  const data = await res.json();
  return data.results || [];
}

// ─── Transform ─────────────────────────────────────────────
function transformFDARecord(fda: any): Omit<any, 'id' | 'embedding' | 'createdAt' | 'updatedAt'> | null {
  // Brand name là required
  const brandName = fda.openfda?.brand_name?.[0];
  const genericName = fda.openfda?.generic_name?.[0];
  if (!brandName && !genericName) return null;

  const name = brandName || genericName;
  const activeIngredients = fda.active_ingredient?.[0] || genericName || name;
  const indications = fda.indications_and_usage?.[0] || '';
  const warnings = fda.warnings?.[0] || fda.warnings_and_cautions?.[0] || '';
  const sideEffects = fda.adverse_reactions?.[0] || '';
  const contraindications = fda.contraindications?.[0] || '';
  const interactions = fda.drug_interactions?.[0] || '';

  if (!indications) return null; // Không đủ data để useful

  return {
    name: name.substring(0, 255),
    genericName: genericName?.substring(0, 255) || null,
    ingredients: activeIngredients.substring(0, 500),
    category: mapCategory(fda.openfda?.pharm_class_epc),
    indications: indications.substring(0, 2000),
    contraindications: contraindications.substring(0, 2000),
    sideEffects: sideEffects.substring(0, 2000),
    interactsWith: interactions.substring(0, 1000),
    notForPregnant: warnings.toLowerCase().includes('pregnan') ||
                    warnings.toLowerCase().includes('fetal'),
    notForNursing: warnings.toLowerCase().includes('nursing') ||
                   warnings.toLowerCase().includes('breast'),
    notForConditions: [],
    minAge: 0,
    maxAge: 120,
    baseSafetyScore: 75, // Sẽ điều chỉnh theo feedback
    isActive: true,
    viIndications: null,  // Sẽ dịch bởi Gemini trong tương lai
    viSummary: null,
    viWarnings: null,
  };
}

// ─── Embedding ─────────────────────────────────────────────
async function generateEmbedding(text: string): Promise<number[] | null> {
  try {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
    const model = genAI.getGenerativeModel({ model: EMBEDDING_MODEL });
    const result = await model.embedContent(text);
    return result.embedding.values;
  } catch {
    return null; // Không có embedding → vẫn lưu, search text-based
  }
}

// ─── Load ──────────────────────────────────────────────────
async function upsertDrug(drug: any, embedding: number[] | null): Promise<'created' | 'updated' | 'skipped'> {
  const existing = await prisma.drugCandidate.findFirst({
    where: { name: { equals: drug.name, mode: 'insensitive' } },
    select: { id: true },
  });

  if (existing) {
    // Cập nhật thông tin mới nhất
    await prisma.drugCandidate.update({
      where: { id: existing.id },
      data: { ...drug, updatedAt: new Date() },
    });
    return 'updated';
  }

  // Tạo mới
  await prisma.$executeRaw`
    INSERT INTO "DrugCandidate" (
      id, name, "genericName", ingredients, category,
      indications, contraindications, "sideEffects", "interactsWith",
      "notForPregnant", "notForNursing", "notForConditions",
      "minAge", "maxAge", "baseSafetyScore", "isActive",
      "viIndications", "viSummary", "viWarnings",
      embedding, "createdAt", "updatedAt"
    ) VALUES (
      gen_random_uuid(), ${drug.name}, ${drug.genericName}, ${drug.ingredients},
      ${drug.category}, ${drug.indications}, ${drug.contraindications},
      ${drug.sideEffects}, ${drug.interactsWith},
      ${drug.notForPregnant}, ${drug.notForNursing}, ${JSON.stringify(drug.notForConditions)}::jsonb,
      ${drug.minAge}, ${drug.maxAge}, ${drug.baseSafetyScore}, ${drug.isActive},
      ${drug.viIndications}, ${drug.viSummary}, ${drug.viWarnings},
      ${embedding ? `[${embedding.join(',')}]` : null}::vector,
      NOW(), NOW()
    )
  `;
  return 'created';
}

// ─── Main ETL Runner ───────────────────────────────────────
export async function runDrugETL(): Promise<void> {
  console.log('\n🚀 [Drug-ETL] Starting OpenFDA pipeline...');
  const startTime = Date.now();

  const stats = { created: 0, updated: 0, skipped: 0, failed: 0, apiCalls: 0 };
  let skip = 0;

  try {
    while (stats.created < MAX_NEW_DRUGS) {
      // Extract
      let fdaRecords: any[];
      try {
        fdaRecords = await fetchFDAPage(skip);
        stats.apiCalls++;
      } catch (err: any) {
        console.error(`[Drug-ETL] FDA API failed at skip=${skip}:`, err.message);
        break;
      }

      if (fdaRecords.length === 0) break;

      // Transform + Load with embedding
      for (let i = 0; i < fdaRecords.length; i += EMBEDDING_BATCH_SIZE) {
        const batchRecords = fdaRecords.slice(i, i + EMBEDDING_BATCH_SIZE);

        await Promise.all(batchRecords.map(async (fda) => {
          try {
            const drug = transformFDARecord(fda);
            if (!drug) { stats.skipped++; return; }

            // Generate embedding từ text quan trọng nhất
            const embeddingText = `${drug.name}. ${drug.indications}`.substring(0, 1000);
            const embedding = await generateEmbedding(embeddingText);

            const result = await upsertDrug(drug, embedding);
            stats[result]++;
          } catch (err: any) {
            stats.failed++;
          }
        }));
      }

      const elapsed = Math.round((Date.now() - startTime) / 1000);
      console.log(
        `[Drug-ETL] skip=${skip} | +${stats.created} new | ${stats.updated} updated | ${elapsed}s`
      );

      skip += FETCH_LIMIT;

      // Rate limit kiềm chế — tránh bị FDA block
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  } catch (err: any) {
    console.error('[Drug-ETL] Fatal error:', err.message);
  }

  const elapsed = Math.round((Date.now() - startTime) / 1000);
  console.log(`\n✅ [Drug-ETL] Done in ${elapsed}s`);
  console.log(`   Created: ${stats.created} | Updated: ${stats.updated} | Skipped: ${stats.skipped} | Failed: ${stats.failed}`);
  console.log(`   API calls: ${stats.apiCalls}`);
}

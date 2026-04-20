import prisma from '../../src/config/prisma.js';
import { generateEmbedding } from '../../src/services/embedding.service.js';

// ============================================================
// OPENFDA DRUG IMPORTER
// ============================================================
// Script này kéo dữ liệu thuốc OTC từ OpenFDA API (Nguồn chính phủ Mỹ - Free, No Auth)
// và nhập vào bảng DrugCandidate, đồng thời tự động tạo embedding AI cho mỗi thuốc.
//
// Tại sao OpenFDA?
// - Dữ liệu chính phủ, miễn phí, không bản quyền, không cần đăng ký
// - Có đầy đủ: indications, contraindications, warnings, adverse_reactions
// - OTC = Over The Counter = thuốc không cần kê đơn (phù hợp với MediChain)
//
// HOW TO RUN:
//   npx tsx src/scripts/import-openfda-drugs.ts
// ============================================================

const FDA_BASE_URL = 'https://api.fda.gov/drug/label.json';
const BATCH_SIZE = 100;       // Lấy 100 thuốc mỗi lần gọi API
const MAX_TOTAL = 3000;       // Giới hạn tổng (tăng lên 5000 nếu muốn full)
const DELAY_MS = 300;         // Delay giữa mỗi batch để tránh bị block
const EMBEDDING_DELAY_MS = 200; // Delay giữa mỗi lần gọi Gemini

// ─── Bộ lọc phân loại thuốc ───
// Map từ OpenFDA pharm_class_epc → category trong schema MediChain
const CATEGORY_MAP: Record<string, string> = {
    'Analgesic [EPC]': 'ANALGESIC',
    'Anti-Inflammatory Agent [EPC]': 'ANALGESIC',
    'Nonsteroidal Anti-inflammatory Drug [EPC]': 'ANALGESIC',
    'Antipyretic [EPC]': 'ANALGESIC',
    'Antihistamine [EPC]': 'ANTIHISTAMINE',
    'H1 Receptor Antagonist [EPC]': 'ANTIHISTAMINE',
    'Antacid [EPC]': 'ANTACID',
    'Proton Pump Inhibitor [EPC]': 'ANTACID',
    'Antidiarrheal [EPC]': 'ANTIDIARRHEAL',
    'Laxative [EPC]': 'LAXATIVE',
    'Antiseptic [EPC]': 'ANTISEPTIC',
    'Antifungal [EPC]': 'ANTIFUNGAL',
    'Decongestant [EPC]': 'DECONGESTANT',
    'Cough Suppressant [EPC]': 'COUGH_COLD',
    'Expectorant [EPC]': 'COUGH_COLD',
    'Antitussive [EPC]': 'COUGH_COLD',
    'Vitamin [EPC]': 'VITAMIN_SUPPLEMENT',
    'Mineral [EPC]': 'VITAMIN_SUPPLEMENT',
    'Nutritional Supplement [EPC]': 'VITAMIN_SUPPLEMENT',
    'Antacid and Calcium Supplement [EPC]': 'VITAMIN_SUPPLEMENT',
    'Sleep Aid [EPC]': 'SLEEP_AID',
    'Ophthalmic Agent [EPC]': 'OPHTHALMIC',
    'Topical Corticosteroid [EPC]': 'TOPICAL',
    'Local Anesthetic [EPC]': 'TOPICAL',
};

function mapCategory(pharmClasses: string[] | undefined): string {
    if (!pharmClasses || pharmClasses.length === 0) return 'OTHER';
    for (const pc of pharmClasses) {
        if (CATEGORY_MAP[pc]) return CATEGORY_MAP[pc];
    }
    return 'OTHER';
}

// ─── Kiểm tra dấu hiệu "không phù hợp cho thai phụ" ───
function checkNotForPregnant(text: string): boolean {
    const lower = text.toLowerCase();
    return lower.includes('pregnant') || lower.includes('pregnancy') 
        || lower.includes('breastfeeding') || lower.includes('nursing');
}

// ─── Tính baseSafetyScore từ các warnings ───
function calcSafetyScore(warnings: string, doNotUse: string): number {
    let score = 88; // OTC nhìn chung khá an toàn, bắt đầu từ 88
    const combined = (warnings + doNotUse).toLowerCase();
    
    if (combined.includes('liver')) score -= 8;
    if (combined.includes('kidney')) score -= 5;
    if (combined.includes('bleeding') || combined.includes('blood thinner')) score -= 7;
    if (combined.includes('diabete') || combined.includes('high blood pressure')) score -= 4;
    if (combined.includes('do not use more than') || combined.includes('overdose')) score -= 5;
    if (combined.includes('seizure') || combined.includes('severe')) score -= 6;
    
    return Math.max(50, score);
}

// ─── Làm sạch text từ API về ───
function cleanText(arr: string[] | undefined): string {
    if (!arr || arr.length === 0) return '';
    return arr.join(' ').replace(/\s+/g, ' ').trim().substring(0, 2000);
}

// ─── Kiểm tra trường bắt buộc có đủ không ───
function isValidDrug(result: any): boolean {
    const brand = result.openfda?.brand_name?.[0];
    const generic = result.openfda?.generic_name?.[0];
    const indications = result.indications_and_usage?.[0];
    return !!(brand && generic && indications && indications.length > 20);
}

// ─── Delay helper ───
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// ─── Fetch 1 batch từ OpenFDA API ───
async function fetchBatch(skip: number): Promise<any[]> {
    const url = `${FDA_BASE_URL}?search=openfda.product_type:"HUMAN+OTC+DRUG"+AND+_exists_:indications_and_usage&limit=${BATCH_SIZE}&skip=${skip}`;
    
    const res = await fetch(url);
    
    if (!res.ok) {
        if (res.status === 404) return []; // Hết kết quả
        throw new Error(`OpenFDA API lỗi: ${res.status} ${res.statusText}`);
    }
    
    const json = await res.json() as any;
    return json.results || [];
}

// ─── MAIN PIPELINE ───
async function main() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('🚀 OPENFDA DRUG IMPORTER - MediChain Database Enrichment');
    console.log('═══════════════════════════════════════════════════════════');
    console.log(`📦 Sẽ import tối đa ${MAX_TOTAL} thuốc OTC từ FDA.gov`);
    console.log(`🧠 Mỗi thuốc sẽ được tạo embedding bằng Google Gemini AI`);
    console.log('');

    // Lấy danh sách tên thuốc đã có để tránh duplicate
    const existingNames = new Set<string>(
        (await prisma.drugCandidate.findMany({ select: { name: true } }))
            .map(d => d.name.toLowerCase())
    );
    console.log(`📊 Hiện DB có ${existingNames.size} thuốc. Sẽ bỏ qua thuốc trùng tên.`);
    console.log('');

    let totalImported = 0;
    let totalSkipped = 0;
    let totalFailed = 0;
    let skip = 0;

    while (totalImported < MAX_TOTAL) {
        console.log(`📡 [Batch ${skip / BATCH_SIZE + 1}] Đang fetch từ FDA.gov (skip=${skip})...`);

        let batch: any[];
        try {
            batch = await fetchBatch(skip);
        } catch (err: any) {
            console.error(`❌ Fetch thất bại: ${err.message}`);
            break;
        }

        if (batch.length === 0) {
            console.log('✅ Đã fetch hết toàn bộ dữ liệu từ OpenFDA.');
            break;
        }

        for (const result of batch) {
            if (totalImported >= MAX_TOTAL) break;

            // ─── Filter dữ liệu không đủ trường ───
            if (!isValidDrug(result)) {
                totalSkipped++;
                continue;
            }

            const brand = result.openfda.brand_name[0];
            const generic = result.openfda.generic_name[0];
            const nameKey = `${brand} (${generic})`;

            // ─── Skip nếu đã có trong DB ───
            if (existingNames.has(nameKey.toLowerCase())) {
                totalSkipped++;
                continue;
            }
            existingNames.add(nameKey.toLowerCase());

            // ─── Map các field từ OpenFDA → Schema MediChain ───
            const indications = cleanText(result.indications_and_usage);
            const contraindications = cleanText(
                result.contraindications || result.do_not_use || result.ask_doctor
            );
            const sideEffects = cleanText(
                result.adverse_reactions || result.warnings || result.stop_use  
            );
            const ingredients = cleanText(result.active_ingredient);
            const warningsText = cleanText(result.warnings);
            const doNotUseText = cleanText(result.do_not_use);
            const category = mapCategory(result.openfda?.pharm_class_epc);

            const notForPregnant = checkNotForPregnant(
                warningsText + doNotUseText + cleanText(result.pregnancy_or_breast_feeding)
            );

            const baseSafetyScore = calcSafetyScore(warningsText, doNotUseText);

            // ─── Tạo chuỗi để embed (giàu ngữ nghĩa) ───
            const textToEmbed = `
                Drug: ${nameKey}. 
                Category: ${category}. 
                Active Ingredients: ${ingredients}.
                Indications (điều trị): ${indications}. 
                Contraindications: ${contraindications}. 
                Side Effects: ${sideEffects}.
            `.replace(/\s+/g, ' ').trim();

            try {
                // ─── Gọi Gemini AI tạo Vector ───
                const embedding = await generateEmbedding(textToEmbed);

                // ─── Insert vào DB ───
                const drugId = crypto.randomUUID();

                await prisma.$executeRawUnsafe(
                    `INSERT INTO "DrugCandidate" (
                        id, name, "genericName", ingredients, category,
                        indications, contraindications, "sideEffects",
                        "notForPregnant", "notForNursing",
                        "baseSafetyScore", "isActive",
                        "createdAt", "updatedAt", embedding
                    ) VALUES (
                        $1, $2, $3, $4, $5,
                        $6, $7, $8,
                        $9, $10,
                        $11, true,
                        now(), now(), $12::vector
                    )`,
                    drugId, nameKey, generic, ingredients || generic, category,
                    indications, contraindications || 'Xem hướng dẫn sử dụng', sideEffects || 'Không rõ',
                    notForPregnant, notForPregnant,
                    baseSafetyScore,
                    JSON.stringify(embedding)
                );

                totalImported++;
                console.log(`  ✅ [${totalImported}/${MAX_TOTAL}] ${nameKey} (${category}) | Safety: ${baseSafetyScore}`);

                await sleep(EMBEDDING_DELAY_MS);

            } catch (err: any) {
                totalFailed++;
                console.error(`  ❌ Lỗi xử lý ${nameKey}: ${err.message?.substring(0, 100)}`);
            }
        }

        skip += BATCH_SIZE;
        await sleep(DELAY_MS);
    }

    // ─── Tổng kết ───
    console.log('');
    console.log('═══════════════════════════════════════════════════════════');
    console.log(`🎉 HOÀN TẤT IMPORT!`);
    console.log(`   ✅ Đã thêm mới:  ${totalImported} thuốc`);
    console.log(`   ⏭️  Bỏ qua:       ${totalSkipped} thuốc (trùng hoặc thiếu dữ liệu)`);
    console.log(`   ❌ Thất bại:     ${totalFailed} thuốc`);
    
    const total = await prisma.drugCandidate.count();
    console.log(`   📦 Tổng kho:     ${total} thuốc (bao gồm cả cũ)`);
    console.log('═══════════════════════════════════════════════════════════');
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });

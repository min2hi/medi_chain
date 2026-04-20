/**
 * Safety Keywords Seeder — Clinical Rules Engine v2.1
 * ─────────────────────────────────────────────────────────────────────────────
 * Migrate toàn bộ EMERGENCY_GROUPS và COMBO_RULES từ hardcoded source
 * vào database SafetyKeyword + ComboRule tables.
 *
 * Nguồn dữ liệu: medical-safety.service.ts (verified qua 27-case benchmark)
 * Tất cả keywords có guidelineRef cụ thể để traceability.
 * ─────────────────────────────────────────────────────────────────────────────
 */

import type { PrismaClient } from '../../src/generated/client/index.js';

// Helper: normalize diacritics (bỏ dấu tiếng Việt)
const removeDiacritics = (str: string): string =>
    str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D');

// ─── Keyword Data ─────────────────────────────────────────────────────────────

interface KeywordSeed {
    groupId:      string;
    groupLabel:   string;
    keyword:      string;
    guidelineRef: string;
}

const KEYWORD_SEEDS: KeywordSeed[] = [

    // ═══ 1. HỘI CHỨNG VÀNH CẤP ═══════════════════════════════════════════════
    ...['đau ngực','tức ngực','nặng ngực','thắt ngực','đau lan tay trái','đau lan vai trái',
        'đau lan cánh tay','đau ngực dữ dội','nhồi máu cơ tim','nhịp tim loạn',
        'tim đập không đều','ngực như bị đè'].map(kw => ({
        groupId: 'acs', groupLabel: 'Hội chứng vành cấp / Nhồi máu cơ tim',
        keyword: kw, guidelineRef: 'AHA/ACC 2022 — Acute Coronary Syndrome Guidelines'
    })),

    // ═══ 2. SUY HÔ HẤP CẤP ══════════════════════════════════════════════════
    ...['khó thở','thở khó','không thở được','thở nặng nề','thở nhanh nông',
        'suy hô hấp','phù phổi','ran ẩm phổi','gõ đục phổi','môi tím','tím tái',
        'thiếu oxy','nghẹt thở','tràn dịch màng phổi'].map(kw => ({
        groupId: 'resp_failure', groupLabel: 'Suy hô hấp cấp / Phù phổi',
        keyword: kw, guidelineRef: 'WHO Emergency Triage + ESC Acute Pulmonary Edema 2021'
    })),

    // ═══ 3. ĐỘT QUỴ NÃO ════════════════════════════════════════════════════
    ...['đột quỵ','tai biến','liệt nửa người','liệt tay','liệt chân',
        'méo miệng','miệng méo','miệng xệ',
        'nói ngọng đột ngột','nói khó','nói ú ớ','nói không ra',
        'tê nửa mặt','tê nửa người','tay yếu không nhấc',
        'mặt méo','mắt lác đột ngột',
        'mất thị lực đột ngột','mù đột ngột',
        'đau đầu dữ dội đột ngột','đầu như sét đánh',
        'như sét đánh','sét đánh vào đầu',
        'đau đầu dữ nhất từ trước đến nay',
        'đau đầu dữ nhất trong đời',
        'đau đầu dữ nhất từ trước giờ'].map(kw => ({
        groupId: 'stroke', groupLabel: 'Đột quỵ não / Tai biến mạch máu não',
        keyword: kw, guidelineRef: 'AHA/ASA 2023 Stroke Guidelines + VN Stroke Association'
    })),

    // ═══ 4. SỐC PHẢN VỆ ════════════════════════════════════════════════════
    ...['sốc phản vệ','phù mặt','phù môi','phù lưỡi','nổi mề đay toàn thân',
        'dị ứng nặng','choáng phản vệ','sưng mặt khó thở','phản vệ'].map(kw => ({
        groupId: 'anaphylaxis', groupLabel: 'Sốc phản vệ / Dị ứng nặng toàn thân',
        keyword: kw, guidelineRef: 'WAO 2020 Anaphylaxis Guidelines'
    })),

    // ═══ 5. NGẤT / MẤT Ý THỨC ═════════════════════════════════════════════
    ...['bất tỉnh','mất ý thức','ngất xỉu','ngất','hôn mê',
        'không tỉnh','không phản ứng','mất phản xạ'].map(kw => ({
        groupId: 'syncope', groupLabel: 'Ngất xỉu / Mất ý thức',
        keyword: kw, guidelineRef: 'ESC 2018 Syncope Guidelines'
    })),

    // ═══ 6. CO GIẬT ════════════════════════════════════════════════════════
    ...['co giật','lên cơn động kinh','giật toàn thân',
        'cứng người co giật','động kinh'].map(kw => ({
        groupId: 'seizure', groupLabel: 'Co giật / Động kinh cấp',
        keyword: kw, guidelineRef: 'ILAE 2021 Epilepsy Classification'
    })),

    // ═══ 7. SỐC ═══════════════════════════════════════════════════════════
    ...['tụt huyết áp','huyết áp tụt','lạnh toát','vã mồ hôi lạnh','mạch yếu',
        'da lạnh nhợt','xanh tái lạnh','sốc','lạnh tay chân','môi nhợt',
        'mạch nhanh yếu'].map(kw => ({
        groupId: 'shock', groupLabel: 'Sốc / Tụt huyết áp nặng',
        keyword: kw, guidelineRef: 'WHO Guidelines for Emergency Care 2020'
    })),

    // ═══ 8. NHIỄM TRÙNG HUYẾT / VIÊM MÀNG NÃO ═══════════════════════════
    ...['nhiễm trùng huyết','nhiễm trùng máu','sốc nhiễm trùng',
        'cứng cổ','gáy cứng','cổ cứng không cúi được',
        'cứng cổ sốt','sốt cao cứng cổ',
        'sợ ánh sáng','sợ tiếng động kèm đau đầu',
        'viêm màng não','ban xuất huyết',
        'sốt cao rét run dữ dội','rét run dữ dội',
        'lú lẫn','không nhận ra người thân','lơ mơ sốt cao'].map(kw => ({
        groupId: 'sepsis', groupLabel: 'Nhiễm trùng huyết / Viêm màng não',
        keyword: kw, guidelineRef: 'Surviving Sepsis Campaign 2021 + NICE Meningitis 2021'
    })),

    // ═══ 9. XUẤT HUYẾT TIÊU HÓA ══════════════════════════════════════════
    ...['nôn ra máu','ói ra máu','đi ngoài ra máu','phân đen như hắc ín',
        'đại tiện ra máu','ho ra máu','tiêu chảy ra máu',
        'phân đen','đi phân đen'].map(kw => ({
        groupId: 'gi_bleeding', groupLabel: 'Xuất huyết tiêu hóa',
        keyword: kw, guidelineRef: 'BSG/ESGE 2021 Upper GI Bleeding Guidelines'
    })),

    // ═══ 10. CHẤN THƯƠNG NGHIÊM TRỌNG ══════════════════════════════════
    ...['chấn thương đầu','chấn thương sọ não','tai nạn giao thông',
        'té ngã từ cao','gãy xương lớn','đâm xuyên ngực',
        'vết thương sâu chảy máu nhiều','máu không cầm được'].map(kw => ({
        groupId: 'trauma', groupLabel: 'Chấn thương nghiêm trọng',
        keyword: kw, guidelineRef: 'WHO Emergency Triage Categories'
    })),

    // ═══ 11. SỐT CỰC CAO ════════════════════════════════════════════════
    ...['sốt 40','sốt 39.5','sốt 41','sốt cao trên 39',
        'cao nhiệt','nhiệt độ 40','nhiệt độ 41'].map(kw => ({
        groupId: 'hyperpyrexia', groupLabel: 'Sốt cực cao (>39.5°C)',
        keyword: kw, guidelineRef: 'WHO Hyperpyrexia Definition + AAP Fever Guidelines 2023'
    })),

    // ═══ 12. VÀNG DA NẶNG / SUY GAN CẤP ═════════════════════════════════
    ...['vàng da vàng mắt','vàng da đột ngột','vàng da kèm đau bụng',
        'suy gan','bụng báng nước'].map(kw => ({
        groupId: 'liver_failure', groupLabel: 'Vàng da nặng / Suy gan cấp',
        keyword: kw, guidelineRef: 'AASLD Acute Liver Failure Guidelines 2022'
    })),

    // ═══ 13. ĐAU BỤNG CẤP NGOẠI KHOA ════════════════════════════════════
    ...['đau bụng dữ dội','đau bụng không chịu được','bụng cứng như gỗ',
        'đau xuyên ra lưng dữ dội','ruột thừa','vỡ ruột'].map(kw => ({
        groupId: 'acute_abdomen', groupLabel: 'Đau bụng cấp / Nghi cấp cứu ngoại',
        keyword: kw, guidelineRef: 'WSES Acute Abdomen Guidelines 2021'
    })),

    // ═══ 14. NGỘ ĐỘC / QUÁ LIỀU ═══════════════════════════════════════
    ...['ngộ độc','uống quá liều','uống nhầm thuốc','nuốt hóa chất',
        'uống thuốc tự tử','quá liều thuốc','poison'].map(kw => ({
        groupId: 'poisoning', groupLabel: 'Ngộ độc / Quá liều thuốc',
        keyword: kw, guidelineRef: 'WHO Poison Control Guidelines + VN Poison Control Center'
    })),

    // ═══ 15. SẢN KHOA CẤP ════════════════════════════════════════════════
    ...['ra máu âm đạo nhiều','chảy máu khi mang thai','đau bụng dữ khi mang thai',
        'sản giật','co giật khi mang thai','sinh non','thai ra máu'].map(kw => ({
        groupId: 'obstetric', groupLabel: 'Cấp cứu sản khoa',
        keyword: kw, guidelineRef: 'RCOG APH Guidelines + ACOG Obstetric Emergency 2023'
    })),
];

// ─── Combo Rule Data ──────────────────────────────────────────────────────────

interface ComboSeed {
    name:          string;
    label:         string;
    symptomGroups: string[][];
    minMatch:      number;
    guidelineRef:  string;
}

const COMBO_SEEDS: ComboSeed[] = [
    {
        name: 'meningitis_triad',
        label: '⚠️ COMBO: Sốt + Cứng cổ + Đau đầu → Nghi VIÊM MÀNG NÃO',
        symptomGroups: [
            ['sốt', 'sốt cao'],
            ['cứng cổ', 'gáy cứng'],
            ['đau đầu', 'nhức đầu', 'sợ ánh sáng', 'buồn nôn'],
        ],
        minMatch: 2,
        guidelineRef: 'NICE Meningitis 2021 — Kernig/Brudzinski triad',
    },
    {
        name: 'acs_atypical',
        label: '⚠️ COMBO: Đau ngực + Vã mồ hôi + Buồn nôn → Nghi NHỒI MÁU CƠ TIM',
        symptomGroups: [
            ['đau ngực', 'tức ngực', 'nặng ngực'],
            ['vã mồ hôi', 'toát mồ hôi', 'mồ hôi lạnh'],
            ['buồn nôn', 'nôn mửa', 'khó thở'],
        ],
        minMatch: 2,
        guidelineRef: 'AHA/ACC 2022 — Atypical ACS presentation',
    },
    {
        name: 'acute_pulmonary_edema',
        label: '⚠️ COMBO: Khó thở + Phù chân → Nghi PHÙ PHỔI / SUY TIM MẤT BÙ',
        symptomGroups: [
            ['khó thở', 'thở nhanh', 'thở khó'],
            ['nằm xuống khó thở', 'phù chân', 'chân phù'],
            ['suy tim', 'tim mạch'],
        ],
        minMatch: 2,
        guidelineRef: 'ESC Heart Failure Guidelines 2021 — ADHF criteria',
    },
    {
        name: 'septic_shock',
        label: '⚠️ COMBO: Sốt + Mạch nhanh + Rối loạn ý thức → Nghi SEPTIC SHOCK',
        symptomGroups: [
            ['sốt cao', 'sốt rét run'],
            ['mạch nhanh', 'tim đập nhanh', 'huyết áp thấp', 'tụt huyết áp'],
            ['lú lẫn', 'ngủ gà', 'mê man', 'không tỉnh táo'],
        ],
        minMatch: 2,
        guidelineRef: 'Surviving Sepsis Campaign 2021 — Sepsis-3 SOFA criteria',
    },
    {
        name: 'fast_stroke',
        label: '⚠️ COMBO: Yếu/Tê + Nói khó + Méo mặt → Dấu hiệu FAST — Nghi ĐỘT QUỴ',
        symptomGroups: [
            ['yếu tay', 'tê tay', 'tê chân', 'yếu chân', 'liệt'],
            ['nói lắp', 'nói khó', 'không nói được', 'nói ngọng'],
            ['mặt méo', 'miệng méo', 'mắt lệch'],
        ],
        minMatch: 2,
        guidelineRef: 'AHA FAST Criteria — Face Arm Speech Time',
    },
    {
        name: 'internal_bleeding',
        label: '⚠️ COMBO: Đau bụng + Da xanh + Mạch nhanh → Nghi XUẤT HUYẾT NỘI',
        symptomGroups: [
            ['đau bụng', 'đau bụng dữ'],
            ['da xanh', 'mặt trắng', 'xanh xao'],
            ['mạch nhanh', 'huyết áp thấp', 'chóng mặt nặng'],
        ],
        minMatch: 2,
        guidelineRef: 'WSES 2021 — Intra-abdominal Hemorrhage Criteria',
    },
];

// ─── Seeder Main ──────────────────────────────────────────────────────────────

async function seedSafetyKeywords(prisma: PrismaClient) {
    console.log('\n🏥 ClinicalRulesEngine — Safety Keywords Seeder v2.1');
    console.log('='.repeat(60));

    // SafetyKeyword: dùng upsert để idempotent (chạy lại không duplicate)
    console.log(`\n📝 Seeding ${KEYWORD_SEEDS.length} safety keywords...`);

    let skipped = 0, created = 0;
    for (const seed of KEYWORD_SEEDS) {
        const result = await prisma.safetyKeyword.upsert({
            where: {
                groupId_keyword_language: {
                    groupId:  seed.groupId,
                    keyword:  seed.keyword,
                    language: 'vi',
                }
            },
            update: {
                groupLabel:   seed.groupLabel,
                keywordNorm:  removeDiacritics(seed.keyword),
                guidelineRef: seed.guidelineRef,
                // Không đổi isActive nếu đã tồn tại — tránh override admin changes
            },
            create: {
                groupId:      seed.groupId,
                groupLabel:   seed.groupLabel,
                keyword:      seed.keyword,
                keywordNorm:  removeDiacritics(seed.keyword),
                language:     'vi',
                guidelineRef: seed.guidelineRef,
                isActive:     true,          // Seed với active=true
                activatedBy:  'SYSTEM_SEED_V2.1',
                activatedAt:  new Date(),
                createdBy:    'SYSTEM_SEED_V2.1',
                versionTag:   'v2.1',
                changeNote:   'Initial seed — migrated from medical-safety.service.ts hardcoded arrays',
            }
        });
        if (result.versionTag === 'v2.1' && result.createdBy === 'SYSTEM_SEED_V2.1') created++;
        else skipped++;
    }

    console.log(`   ✅ ${created} created, ${skipped} already existed (skipped update isActive)`);

    // ComboRule: upsert by unique name
    console.log(`\n📝 Seeding ${COMBO_SEEDS.length} combo rules...`);

    let comboCreated = 0, comboSkipped = 0;
    for (const seed of COMBO_SEEDS) {
        await prisma.comboRule.upsert({
            where:  { name: seed.name },
            update: {
                label:         seed.label,
                symptomGroups: seed.symptomGroups,
                minMatch:      seed.minMatch,
                guidelineRef:  seed.guidelineRef,
            },
            create: {
                name:          seed.name,
                label:         seed.label,
                symptomGroups: seed.symptomGroups,
                minMatch:      seed.minMatch,
                guidelineRef:  seed.guidelineRef,
                isActive:      true,
                activatedBy:   'SYSTEM_SEED_V2.1',
                activatedAt:   new Date(),
                createdBy:     'SYSTEM_SEED_V2.1',
                changeNote:    'Initial seed — migrated from medical-safety.service.ts COMBO_RULES',
            },
        });
        comboCreated++;
    }

    console.log(`   ✅ ${comboCreated} combo rules seeded`);

    // Summary
    const totalKeywords = await prisma.safetyKeyword.count({ where: { isActive: true } });
    const totalCombos   = await prisma.comboRule.count({ where: { isActive: true } });
    const groups        = await prisma.safetyKeyword.findMany({
        where:   { isActive: true },
        select:  { groupId: true },
        distinct: ['groupId'],
    });

    console.log('\n📊 Seeder Summary:');
    console.log(`   Active keywords: ${totalKeywords} across ${groups.length} emergency groups`);
    console.log(`   Active combo rules: ${totalCombos}`);
    console.log('\n✅ Clinical Rules Engine seeding complete!');
    console.log('   Rules are now database-driven with audit trail.');
    console.log('   Hot-reload: POST /api/admin/clinical-rules/cache/invalidate');
    console.log('='.repeat(60));
}

export { seedSafetyKeywords };

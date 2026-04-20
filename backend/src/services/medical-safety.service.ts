/**
 * Medical Safety Check Service (Backend)
 * Logic kiá»ƒm tra an toÃ n y táº¿ TRÆ¯á»šC KHI gá»i AI
 *
 * CRE Integration: EMERGENCY_GROUPS vÃ  COMBO_RULES Ä‘Æ°á»£c load tá»« DB qua ClinicalRulesEngine.
 * KhÃ´ng cÃ²n hardcode trong file nÃ y â€” xem ADR-004-clinical-rules-engine.md.
 */

import { ClinicalRulesEngine } from './clinical-rules.engine.js';

export interface UserMedicalProfile {
    allergies: string | null;
    chronicConditions: string | null;
    currentMedicines: string[]; // Danh sÃ¡ch thuá»‘c Ä‘ang dÃ¹ng
    isPregnant: boolean;
    isBreastfeeding: boolean;
    age?: number | null;
    weight?: number | null;
    gender?: string | null;
}

export interface SafetyCheckResult {
    isSafe: boolean;
    warnings: string[];
    criticalAlerts: string[];
    missingInfo: string[];
}

export class MedicalSafetyService {

    /**
     * Kiá»ƒm tra xem user Ä‘Ã£ cÃ³ Ä‘á»§ thÃ´ng tin Ä‘á»ƒ tÆ° váº¥n chÆ°a
     */
    static validateProfileCompleteness(profile: UserMedicalProfile): SafetyCheckResult {
        const missingInfo: string[] = [];
        const warnings: string[] = [];

        // Kiá»ƒm tra thÃ´ng tin báº¯t buá»™c
        if (!profile.allergies && profile.allergies !== '') {
            missingInfo.push('ThÃ´ng tin dá»‹ á»©ng thuá»‘c');
        }

        if (!profile.chronicConditions && profile.chronicConditions !== '') {
            missingInfo.push('ThÃ´ng tin bá»‡nh ná»n');
        }

        if (!profile.currentMedicines || profile.currentMedicines.length === 0) {
            warnings.push('ChÆ°a cáº­p nháº­t danh sÃ¡ch thuá»‘c Ä‘ang dÃ¹ng.');
        }

        const isSafe = missingInfo.length === 0;

        return {
            isSafe,
            warnings,
            criticalAlerts: [],
            missingInfo
        };
    }

    /**
     * Kiá»ƒm tra cÃ¡c contraindications (chá»‘ng chá»‰ Ä‘á»‹nh) cá»©ng
     */
    static async checkContraindications(
        symptoms: string,
        profile: UserMedicalProfile
    ): Promise<SafetyCheckResult> {
        const criticalAlerts: string[] = [];
        const warnings: string[] = [];

        // Rule 1: Thai ká»³
        if (profile.isPregnant) {
            criticalAlerts.push(
                'âš ï¸ Báº N ÄANG MANG THAI: Tuyá»‡t Ä‘á»‘i khÃ´ng tá»± Ã½ dÃ¹ng thuá»‘c. HÃ£y tham kháº£o bÃ¡c sÄ© sáº£n khoa.'
            );
        }

        // Rule 2: Cho con bÃº
        if (profile.isBreastfeeding) {
            criticalAlerts.push(
                'âš ï¸ Báº N ÄANG CHO CON BÃš: Nhiá»u thuá»‘c cÃ³ thá»ƒ áº£nh hÆ°á»Ÿng Ä‘áº¿n tráº» qua sá»¯a máº¹. Vui lÃ²ng há»i bÃ¡c sÄ©.'
            );
        }

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // RULE 0: HOSPITAL CONTEXT DETECTOR â€” Gap Fix 4 (case bÃªn dÆ°á»›i)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Váº¥n Ä‘á»: User gÃµ "Ä‘i cáº¥p cá»©u Ä‘á»ƒ truyá»n nÆ°á»›c, uá»‘ng thuá»‘c gÃ¬?"
        //   â†’ System recommend Paracetamol + Tiffy = SAI HOÃ€N TOÃ€N
        //   â†’ NgÆ°á»i Ä‘ang á»Ÿ bá»‡nh viá»‡n, Ä‘ang Ä‘Æ°á»£c bÃ¡c sÄ© quáº£n lÃ½
        //   â†’ KHÃ”NG NÃŠN tÆ° váº¥n thÃªm thuá»‘c OTC vÃ o
        //
        // CÆ¡ sá»Ÿ y khoa:
        //   "Truyá»n nÆ°á»›c" (IV fluids) chá»‰ Ä‘Æ°á»£c chá»‰ Ä‘á»‹nh khi:
        //     - Máº¥t nÆ°á»›c náº·ng (khÃ´ng bÃ¹ miá»‡ng Ä‘Æ°á»£c)
        //     - Sá»‘t xuáº¥t huyáº¿t dengue (cáº§n giÃ¡m sÃ¡t cháº·t)
        //     - Rá»‘i loáº¡n Ä‘iá»‡n giáº£i
        //   â†’ Táº¥t cáº£ Ä‘á»u khÃ´ng thÃ­ch há»£p Ä‘á»ƒ tá»± mua thuá»‘c OTC thÃªm vÃ o
        //
        // Google Health / Babylon: "Under care" detection â†’ redirect to physician
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        const lowerSymptomsForHospitalCheck = symptoms.toLowerCase();

        // Dáº¥u hiá»‡u Ä‘ang Ä‘Æ°á»£c Ä‘iá»u trá»‹ y táº¿
        // Gap Fix 4b: ThÃªm 'Ä‘i cáº¥p cá»©u', 'nháº­p viá»‡n', 'vÃ o viá»‡n' vÃ  cÃ¡c biáº¿n thá»ƒ
        // Root cause: 'tÃ´i Ä‘i cáº¥p cá»©u vÃ¬ Ä‘au Ä‘áº§u' â†’ chá»‰ 'Ä‘Ã£ Ä‘i cáº¥p cá»©u' Ä‘Æ°á»£c detect trÆ°á»›c Ä‘Ã¢y
        const HOSPITAL_CARE_SIGNALS = [
            // Äang á»Ÿ viá»‡n
            'Ä‘ang náº±m viá»‡n', 'Ä‘ang Ä‘iá»u trá»‹', 'Ä‘ang nháº­p viá»‡n', 'Ä‘ang á»Ÿ bá»‡nh viá»‡n',
            'Ä‘ang trong bá»‡nh viá»‡n', 'Ä‘ang náº±m Ä‘iá»u trá»‹', 'Ä‘ang á»Ÿ phÃ²ng cáº¥p cá»©u',
            // Truyá»n dá»‹ch (IV)
            'truyá»n nÆ°á»›c', 'truyá»n dá»‹ch', 'Ä‘áº·t kim truyá»n', 'Ä‘ang truyá»n',
            // Cáº¥p cá»©u (quÃ¡ khá»© / hiá»‡n táº¡i / tÆ°Æ¡ng lai gáº§n Ä‘á»u nguy hiá»ƒm)
            'Ä‘i cáº¥p cá»©u',        // BUG: was missing â€” 'tÃ´i Ä‘i cáº¥p cá»©u vÃ¬ Ä‘au Ä‘áº§u'
            'Ä‘Ã£ Ä‘i cáº¥p cá»©u', 'vá»«a cáº¥p cá»©u', 'vá»«a Ä‘i cáº¥p cá»©u',
            'Ä‘áº¿n cáº¥p cá»©u', 'vÃ o cáº¥p cá»©u', 'vÃ o phÃ²ng cáº¥p cá»©u',
            'Ä‘áº¿n bá»‡nh viá»‡n cáº¥p cá»©u', 'Ä‘Æ°a Ä‘i cáº¥p cá»©u',
            // Nháº­p viá»‡n
            'nháº­p viá»‡n', 'vÃ o viá»‡n', 'ra viá»‡n', 'xuáº¥t viá»‡n vá»«a',
            // Äiá»u trá»‹ chuyÃªn biá»‡t
            'bÃ¡c sÄ© Ä‘ang', 'y tÃ¡ Ä‘ang', 'Ä‘ang theo dÃµi táº¡i', 'Ä‘ang thá»Ÿ oxy',
            'Ä‘ang dÃ¹ng thuá»‘c tiÃªm', 'thuá»‘c tiÃªm bá»‡nh viá»‡n',
            'Ä‘ang Ä‘Æ°á»£c bÃ¡c sÄ©', 'theo dÃµi táº¡i bá»‡nh viá»‡n',
        ];

        const hospitalContextMatched = HOSPITAL_CARE_SIGNALS.find(
            signal => lowerSymptomsForHospitalCheck.includes(signal)
        );

        if (hospitalContextMatched) {
            criticalAlerts.push(
                `ðŸ¥ [ÄANG ÄÆ¯á»¢C ÄIá»€U TRá»Š Y Táº¾] PhÃ¡t hiá»‡n báº¡n Ä‘ang hoáº·c vá»«a nháº­n chÄƒm sÃ³c y táº¿ ("${hospitalContextMatched}"). ` +
                `MediChain KHÃ”NG tÆ° váº¥n thÃªm thuá»‘c OTC khi báº¡n Ä‘ang trong quÃ¡ trÃ¬nh Ä‘iá»u trá»‹. ` +
                `Vui lÃ²ng há»i trá»±c tiáº¿p bÃ¡c sÄ© hoáº·c dÆ°á»£c sÄ© Ä‘ang phá»¥ trÃ¡ch Ä‘iá»u trá»‹ cho báº¡n.`
            );
        }

        // Dáº¥u hiá»‡u sá»‘t xuáº¥t huyáº¿t dengue (phá»• biáº¿n táº¡i Viá»‡t Nam) â€” cáº§n cáº£nh bÃ¡o Ä‘áº·c biá»‡t
        // "Ä‘au Ä‘áº§u + má»‡t/má»i + truyá»n nÆ°á»›c" = dengue pattern trong ngá»¯ cáº£nh Viá»‡t Nam
        const DENGUE_RISK_PATTERN = {
            hasIVFluid:  ['truyá»n nÆ°á»›c', 'truyá»n dá»‹ch'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
            hasFatigue:  ['má»‡t', 'má»i ngÆ°á»i', 'má»‡t má»i', 'ngÆ°á»i má»‡t'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
            hasHeadache: ['Ä‘au Ä‘áº§u', 'nhá»©c Ä‘áº§u', 'Ä‘au Ä‘áº§u dá»¯'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
            hasFever:    ['sá»‘t', 'nÃ³ng sá»‘t'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
        };
        const dengueSignalCount = Object.values(DENGUE_RISK_PATTERN).filter(Boolean).length;

        if (dengueSignalCount >= 3 && !hospitalContextMatched) {
            // Soft warning â€” khÃ´ng block nhÆ°ng cáº£nh bÃ¡o quan trá»ng
            warnings.push(
                'ðŸ¦Ÿ [Cáº¢NH BÃO Sá»T XUáº¤T HUYáº¾T] Triá»‡u chá»©ng phÃ¹ há»£p nguy cÆ¡ sá»‘t xuáº¥t huyáº¿t Dengue. ' +
                'Náº¿u sá»‘t kÃ©o dÃ i > 2 ngÃ y: (1) KHÃ”NG dÃ¹ng Ibuprofen/Aspirin â€” cÃ³ thá»ƒ gÃ¢y xuáº¥t huyáº¿t náº·ng. ' +
                '(2) Chá»‰ dÃ¹ng Paracetamol náº¿u sá»‘t cao. (3) Theo dÃµi tiá»ƒu cáº§u. ' +
                '(4) Äáº¿n cÆ¡ sá»Ÿ y táº¿ ngay náº¿u nÃ´n nhiá»u, Ä‘au bá»¥ng, cháº£y mÃ¡u.'
            );
        }

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // QUICK WIN 1: AGE-SPECIFIC THRESHOLDS (Babylon Health / WHO Pediatric)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Váº¥n Ä‘á»: "sá»‘t 38Â°C" vá»›i ngÆ°á»i lá»›n = OTC, nhÆ°ng "sá»‘t 38Â°C" vá»›i bÃ© 2 thÃ¡ng
        // = Cáº¤P Cá»¨U NHI KHOA. Há»‡ thá»‘ng cÅ© khÃ´ng phÃ¢n biá»‡t â†’ nguy hiá»ƒm.
        //
        // CÆ¡ sá»Ÿ y há»c:
        //   - Tráº» < 3 thÃ¡ng: Fever Response kÃ©m phÃ¡t triá»ƒn â†’ báº¥t ká»³ sá»‘t nÃ o = nguy hiá»ƒm
        //   - Tráº» < 2 tuá»•i: Heat stroke risk cao hÆ¡n nhiá»u ngÆ°á»i lá»›n
        //   - NgÆ°á»i > 65t: Immune response suy giáº£m â†’ ngÆ°á»¡ng lo ngáº¡i tháº¥p hÆ¡n
        //   Nguá»“n: American Academy of Pediatrics (AAP) 2023 + WHO IMCI Guidelines
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        if (profile.age !== undefined && profile.age !== null) {
            const lowerSym = symptoms.toLowerCase();
            const hasFeverMention = ['sá»‘t', 'nhiá»‡t Ä‘á»™', 'nÃ³ng sá»‘t', '37.', '38.', '39.', '40.', '41.']
                .some(kw => lowerSym.includes(kw));

            // Tráº» < 3 thÃ¡ng (age tÃ­nh báº±ng nÄƒm: 3 thÃ¡ng â‰ˆ 0.25 nÄƒm)
            if (profile.age < 0.25) {
                if (hasFeverMention || lowerSym.includes('sá»‘t')) {
                    criticalAlerts.push(
                        'ðŸ”´ [NGOáº I Lá»† TRáºº SÆ  SINH] Tráº» < 3 thÃ¡ng tuá»•i cÃ³ báº¥t ká»³ má»©c sá»‘t nÃ o (ká»ƒ cáº£ â‰¥38Â°C) lÃ  tÃ¬nh tráº¡ng Cáº¤P Cá»¨U NHI KHOA. KHÃ”NG tá»± Ã½ Ä‘iá»u trá»‹ â€” Äáº¿n cáº¥p cá»©u nhi NGAY!'
                    );
                }
                // ThÃªm: ngá»§ li bÃ¬ / bá» bÃº á»Ÿ tráº» sÆ¡ sinh cÅ©ng lÃ  emergency
                if (['li bÃ¬', 'bá» bÃº', 'khÃ´ng khÃ³c', 'tÃ­m tÃ¡i'].some(kw => lowerSym.includes(kw))) {
                    criticalAlerts.push(
                        'ðŸ”´ [Cáº¤P Cá»¨U NHI] Tráº» sÆ¡ sinh li bÃ¬ / bá» bÃº / tÃ­m tÃ¡i â€” NGUY HIá»‚M TÃNH Máº NG. Gá»i 115 NGAY!'
                    );
                }
            }
            // Tráº» < 2 tuá»•i (age < 2)
            else if (profile.age < 2) {
                const hasHighFever = ['sá»‘t 39', 'sá»‘t 40', 'sá»‘t 41', '39.', '40.', '41.', 'sá»‘t cao']
                    .some(kw => lowerSym.includes(kw));
                if (hasHighFever) {
                    criticalAlerts.push(
                        'ðŸŸ  [TRáºº NHá»Ž] Sá»‘t > 39Â°C á»Ÿ tráº» < 2 tuá»•i cáº§n Ä‘Æ°á»£c bÃ¡c sÄ© nhi khoa Ä‘Ã¡nh giÃ¡ NGAY. Nguy cÆ¡ co giáº­t do sá»‘t cao. Äá»«ng tá»± mua thuá»‘c â€” Äáº¿n khÃ¡m ngay!'
                    );
                }
            }
            // NgÆ°á»i cao tuá»•i > 65 tuá»•i
            else if (profile.age > 65) {
                // á»ž ngÆ°á»i giÃ , nhiá»u triá»‡u chá»©ng "bÃ¬nh thÆ°á»ng" thá»±c ra nguy hiá»ƒm hÆ¡n
                const elderRiskKeywords = ['ngÃ£', 'tÃ©', 'ngáº¥t', 'lÃº láº«n', 'khÃ³ thá»Ÿ'];
                const elderMatched = elderRiskKeywords.find(kw => lowerSym.includes(kw));
                if (elderMatched) {
                    warnings.push(
                        `ðŸ©º [NGÆ¯á»œI CAO TUá»”I] Triá»‡u chá»©ng "${elderMatched}" á»Ÿ ngÆ°á»i > 65 tuá»•i tiá»m áº©n nguy cÆ¡ cao hÆ¡n (loÃ£ng xÆ°Æ¡ng, suy tim áº©n, TIA). NÃªn Ä‘áº¿n cÆ¡ sá»Ÿ y táº¿ Ä‘á»ƒ kiá»ƒm tra, khÃ´ng nÃªn tá»± Ä‘iá»u trá»‹.`
                    );
                }
            }
        }

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // QUICK WIN 3a: TEMPORAL CONTEXT FILTER (Ada Health Scope Tagger pattern)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Váº¥n Ä‘á»: "TÃ´i lo sá»£ khÃ³ thá»Ÿ" â†’ 'khÃ³ thá»Ÿ' match â†’ BLOCKED = FALSE POSITIVE
        //         "Há»“i trÆ°á»›c tÃ´i bá»‹ Ä‘au ngá»±c" â†’ 'Ä‘au ngá»±c' match â†’ BLOCKED = FALSE POSITIVE
        //
        // Giáº£i phÃ¡p: Detect 2 loáº¡i context "giáº£m nháº¹":
        //   1. PAST TENSE: Triá»‡u chá»©ng Ä‘Ã£ qua â†’ downgrade thÃ nh warning (khÃ´ng block)
        //   2. HYPOTHETICAL: Lo láº¯ng/giáº£ Ä‘á»‹nh â†’ downgrade thÃ nh warning (khÃ´ng block)
        //
        // Ká»¹ thuáº­t: Sentence-level scope (khÃ´ng chá»‰ window quanh keyword)
        //   â†’ Chia cÃ¢u theo dáº¥u cÃ¢u â†’ check tá»«ng cÃ¢u cÃ³ scope chá»‰nh sá»­a khÃ´ng
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        const SCOPE_DOWNGRADE_PATTERNS = {
            past: [
                'trÆ°á»›c Ä‘Ã¢y', 'há»“i trÆ°á»›c', 'ngÃ y trÆ°á»›c', 'trÆ°á»›c kia', 'há»“i nhá»',
                'hÃ´m qua', 'tuáº§n trÆ°á»›c', 'thÃ¡ng trÆ°á»›c', 'nÄƒm ngoÃ¡i',
                'tá»«ng bá»‹', 'Ä‘Ã£ tá»«ng', 'Ä‘Ã£ háº¿t', 'khá»i rá»“i', 'Ä‘Ã£ khá»i',
                'khÃ´ng cÃ²n ná»¯a', 'ngÆ°á»i thÃ¢n bá»‹', 'ba tÃ´i bá»‹', 'máº¹ tÃ´i bá»‹',
            ],
            hypothetical: [
                'lo sá»£', 'lo láº¯ng', 'sá»£ ráº±ng', 'sá»£ bá»‹', 'nhá»¡ bá»‹',
                'náº¿u bá»‹', 'giáº£ sá»­', 'cÃ³ thá»ƒ bá»‹', 'nghÄ© lÃ ', 'khÃ´ng biáº¿t cÃ³ bá»‹',
                'há»i cho biáº¿t', 'há»i thÄƒm', 'há»i Ä‘á»ƒ biáº¿t',
            ],
        };

        // Tokenize thÃ nh cÃ¢u (split bá»Ÿi dáº¥u cÃ¢u + tá»« ná»‘i)
        const sentences = symptoms.split(/[.!?;,]|\bvÃ \b|\bnhÆ°ng\b|\btuy nhiÃªn\b/i)
            .map(s => s.trim().toLowerCase())
            .filter(s => s.length > 2);

        // TÃ¬m nhá»¯ng cÃ¢u cÃ³ scope downgrade
        const downgradedSentences = new Set<string>();
        sentences.forEach(sentence => {
            const hasPast         = SCOPE_DOWNGRADE_PATTERNS.past.some(p => sentence.includes(p));
            const hasHypothetical = SCOPE_DOWNGRADE_PATTERNS.hypothetical.some(p => sentence.includes(p));
            if (hasPast || hasHypothetical) {
                downgradedSentences.add(sentence);
            }
        });

        // Helper: check xem keyword cÃ³ náº±m trong downgraded sentence khÃ´ng
        const isDowngradedContext = (keyword: string): boolean => {
            for (const sent of downgradedSentences) {
                if (sent.includes(keyword)) return true;
            }
            return false;
        };

        // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // EMERGENCY SYMPTOM DETECTION â€” Grouped Pattern Matching
        // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // Kiáº¿n trÃºc: Má»—i nhÃ³m Ä‘áº¡i diá»‡n 1 loáº¡i cáº¥p cá»©u lÃ¢m sÃ ng.
        // Logic: ANY 1 keyword trong nhÃ³m â†’ trigger cáº£nh bÃ¡o nhÃ³m Ä‘Ã³.
        // LÃ½ do dÃ¹ng nhÃ³m: NgÆ°á»i dÃ¹ng diá»…n Ä‘áº¡t cÃ¹ng triá»‡u chá»©ng báº±ng nhiá»u cÃ¡ch khÃ¡c nhau.
        //
        // Nguá»“n: WHO Emergency Triage Categories + HÆ°á»›ng dáº«n xá»­ trÃ­ cáº¥p cá»©u Bá»™ Y táº¿ VN
        //        + ESC/AHA Acute Coronary Syndrome Guidelines
        // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        type EmergencyGroup = {
            id: string;
            label: string;
            keywords: string[];
        };

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // GAP FIX 1: DIACRITICS NORMALIZATION (Mobile input pattern)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Váº¥n Ä‘á» NGHIÃŠM TRá»ŒNG: Pháº§n lá»›n user mobile Viá»‡t Nam nháº­p khÃ´ng dáº¥u.
        // "khÃ³ thá»Ÿ" â†’ "kho tho" | "Ä‘au ngá»±c" â†’ "dau nguc"
        // includes() khÃ´ng match â†’ false negative = user Ä‘ang cáº¥p cá»©u bá»‹ pass qua!
        //
        // Giáº£i phÃ¡p: Normalize both input vÃ  keyword vá» khÃ´ng dáº¥u rá»“i so sÃ¡nh song song.
        // Ká»¹ thuáº­t: NFD normalize + remove combining diacritical marks (Unicode range 0300-036f)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        const removeDiacritics = (str: string): string =>
            str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/Ä‘/g, 'd').replace(/Ä/g, 'D');

        const lowerSymptomsSafe  = symptoms.toLowerCase();              // Original cÃ³ dáº¥u
        const lowerSymptomsNorm  = removeDiacritics(symptoms.toLowerCase()); // KhÃ´ng dáº¥u (mobile)

        // Kiá»ƒm tra keyword â€” thá»­ cáº£ cÃ³ dáº¥u láº«n khÃ´ng dáº¥u
        const kwMatch = (text: string, textNorm: string, keyword: string): boolean => {
            if (text.includes(keyword)) return true;
            const kwNorm = removeDiacritics(keyword);
            return textNorm.includes(kwNorm);
        };

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // GAP FIX 2: VITAL SIGNS THRESHOLD DETECTION (HealthKit / Fitbit Health API)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Váº¥n Ä‘á»: User gÃµ con sá»‘ nhÆ°ng há»‡ thá»‘ng khÃ´ng hiá»ƒu ngÆ°á»¡ng nguy hiá»ƒm:
        //   "huyáº¿t Ã¡p 200" = hypertensive crisis â†’ MISSED
        //   "Ä‘Æ°á»ng huyáº¿t 500" = DKA â†’ MISSED
        //   "SpO2 85%" = respiratory failure â†’ MISSED
        //   "nhá»‹p tim 180" = SVT â†’ MISSED
        //
        // Giáº£i phÃ¡p: Regex extract sá»‘ + ngÆ°á»¡ng lÃ¢m sÃ ng chuáº©n WHO/ACC/AHA
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

        // Blood Pressure â€” Hypertensive Crisis: SBP â‰¥ 180 mmHg (ACC/AHA 2017)
        const bpPattern    = /(?:huyáº¿t Ã¡p|blood pressure|ha|bp)[\s:]*(\d{2,3})\s*(?:\/\s*\d{2,})?/i;
        const bpMatch      = lowerSymptomsNorm.match(bpPattern);
        if (bpMatch && parseInt(bpMatch[1]) >= 180) {
            criticalAlerts.push(
                `ðŸ”´ [CÆ N TÄ‚NG HUYáº¾T ÃP] Huyáº¿t Ã¡p tÃ¢m thu ${bpMatch[1]}mmHg â‰¥ 180 = Hypertensive Crisis. Nguy cÆ¡ Ä‘á»™t quá»µ/nhá»“i mÃ¡u cÆ¡ tim cáº¥p. Gá»ŒI 115 NGAY hoáº·c Ä‘áº¿n cáº¥p cá»©u!`
            );
        }

        // Blood Glucose â€” DKA (>400mg/dL) hoáº·c Hypoglycemia (<50mg/dL)
        const glucPattern  = /(?:Ä‘Æ°á»ng huyáº¿t|blood sugar|glucose|bg)[\s:]*(\d{2,3})/i;
        const glucMatch    = lowerSymptomsNorm.match(glucPattern);
        if (glucMatch) {
            const val = parseInt(glucMatch[1]);
            if (val >= 400) {
                criticalAlerts.push(
                    `ðŸ”´ [TÄ‚NG ÄÆ¯á»œNG HUYáº¾T NGHIÃŠM TRá»ŒNG] ÄÆ°á»ng huyáº¿t ${val}mg/dL â†’ Nguy cÆ¡ DKA/HHS. Cáº§n truyá»n dá»‹ch + insulin IV. Gá»ŒI 115 NGAY!`
                );
            } else if (val <= 50) {
                criticalAlerts.push(
                    `ðŸ”´ [Háº  ÄÆ¯á»œNG HUYáº¾T NGUY HIá»‚M] ÄÆ°á»ng huyáº¿t ${val}mg/dL â‰¤ 50 â†’ HÃ´n mÃª háº¡ Ä‘Æ°á»ng cÃ³ thá»ƒ xáº£y ra trong vÃ i phÃºt. Uá»‘ng Ä‘Æ°á»ng ngay + Gá»ŒI 115!`
                );
            }
        }

        // SpO2 â€” Respiratory Failure: SpO2 < 90% (WHO definition)
        const spo2Pattern  = /(?:spo2|Ä‘á»™ bÃ£o hÃ²a oxy|ná»“ng Ä‘á»™ oxy|oxygen sat)[\s%:]*(\d{2,3})/i;
        const spo2Match    = lowerSymptomsNorm.match(spo2Pattern);
        if (spo2Match && parseInt(spo2Match[1]) < 90) {
            criticalAlerts.push(
                `ðŸ”´ [SUY HÃ” Háº¤P] SpO2 ${spo2Match[1]}% < 90% = Suy hÃ´ háº¥p. Cáº§n oxy ngay láº­p tá»©c. Gá»ŒI 115 NGAY!`
            );
        }

        // Heart Rate â€” Tachycardia >150 (SVT risk) hoáº·c Bradycardia <40
        const hrPattern    = /(?:nhá»‹p tim|heart rate|máº¡ch|pulse)[\s:]*(\d{2,3})/i;
        const hrMatch      = lowerSymptomsNorm.match(hrPattern);
        if (hrMatch) {
            const hr = parseInt(hrMatch[1]);
            if (hr >= 150) {
                criticalAlerts.push(
                    `ðŸ”´ [NHá»ŠP TIM NGUY HIá»‚M] Nhá»‹p tim ${hr}/phÃºt â‰¥ 150 â†’ Nguy cÆ¡ SVT/AF vá»›i RVR. Cáº§n Ä‘Ã¡nh giÃ¡ ECG kháº©n. Gá»ŒI 115!`
                );
            } else if (hr <= 40) {
                criticalAlerts.push(
                    `ðŸ”´ [NHá»ŠP TIM CHáº¬M NGUY HIá»‚M] Nhá»‹p tim ${hr}/phÃºt â‰¤ 40 â†’ Complete heart block hoáº·c SSS. Gá»ŒI 115 NGAY!`
                );
            }
        }

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // GAP FIX 3: EXTENDED INFANT RULES (WHO IMCI 2020 â€” 0-12 months)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Váº¥n Ä‘á»: Quick Win 1 chá»‰ cover < 3 thÃ¡ng. Tráº» 3-12 thÃ¡ng cÅ©ng cÃ³ ngÆ°á»¡ng
        // riÃªng nhÆ°ng Ä‘ang bá»‹ bá» sÃ³t.
        //
        //   Tráº» 3-12 thÃ¡ng: Bá» bÃº, li bÃ¬, sá»‘t > 38.5Â°C = WHO "Danger Signs"
        //   WHO IMCI: 3 danger signs â†’ immediate referral
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        if (profile.age !== undefined && profile.age !== null && profile.age >= 0.25 && profile.age < 1) {
            const lowerSym           = symptoms.toLowerCase();
            const imsicDangerSigns   = ['bá» bÃº', 'li bÃ¬', 'khÃ´ng uá»‘ng Ä‘Æ°á»£c', 'nÃ´n táº¥t cáº£', 'co giáº­t'];
            const hasDangerSign      = imsicDangerSigns.some(ds => lowerSym.includes(ds));
            const hasHighFeverInfant = ['sá»‘t 38', 'sá»‘t 39', 'sá»‘t 40', 'sá»‘t cao'].some(kw => lowerSym.includes(kw));

            if (hasDangerSign || hasHighFeverInfant) {
                criticalAlerts.push(
                    `ðŸ”´ [WHO IMCI â€” TRáºº 3-12 THÃNG] PhÃ¡t hiá»‡n dáº¥u hiá»‡u nguy hiá»ƒm theo chuáº©n WHO IMCI. Tráº» nhÅ© nhi cáº§n Ä‘Æ°á»£c bÃ¡c sÄ© nhi khoa Ä‘Ã¡nh giÃ¡ NGAY. Äáº¿n cÆ¡ sá»Ÿ y táº¿ Cáº¤P THIáº¾T!`
                );
            }
        }

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // LAYER 2.5: DB-DRIVEN EMERGENCY GROUPS (ClinicalRulesEngine)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Load tá»« DB qua 3-tier: LRU cache (15 phÃºt) â†’ PostgreSQL â†’ Hardcoded Failsafe
        // Admin thÃªm keyword má»›i â†’ POST /api/admin/clinical-rules/cache/invalidate â†’ live <1 giÃ¢y
        const EMERGENCY_GROUPS = await ClinicalRulesEngine.getEmergencyGroups();



        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // LAYER 1: NEGATION FILTER (Ada Health / Google Health pattern)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Váº¥n Ä‘á»: "tÃ´i KHÃ”NG khÃ³ thá»Ÿ" â†’ system detect "khÃ³ thá»Ÿ" â†’ FALSE POSITIVE
        // Giáº£i phÃ¡p: Loáº¡i bá» keyword náº¿u xuáº¥t hiá»‡n sau pattern phá»§ Ä‘á»‹nh (trong vÃ²ng 20 kÃ½ tá»±)
        // Ká»¹ thuáº­t: Sliding window negation check
        const NEGATION_PATTERNS = ['khÃ´ng ', 'chÆ°a ', 'háº¿t ', 'Ä‘Ã£ háº¿t ', 'khÃ´ng cÃ²n ', 'khÃ´ng cÃ³ '];


        const isNegated = (text: string, keyword: string): boolean => {
            const idx = text.indexOf(keyword);
            if (idx === -1) return false;
            // Láº¥y window 20 kÃ½ tá»± trÆ°á»›c keyword
            const before = text.substring(Math.max(0, idx - 20), idx);
            return NEGATION_PATTERNS.some(neg => before.includes(neg));
        };

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // LAYER 2: SEVERITY QUALIFIER (Apple HealthKit / Babylon Health pattern)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // "Ä‘au Ä‘áº§u nháº¹" â†’ giáº£m severity â†’ KHÃ”NG block (chá»‰ theo dÃµi)
        // "Ä‘au Ä‘áº§u dá»¯ dá»™i Ä‘á»™t ngá»™t" â†’ tÄƒng severity â†’ BLOCK cá»©ng
        // Ká»¹ thuáº­t: Severity modifier affects decision threshold

        // Mild qualifiers: náº¿u keyword kÃ¨m modifier nÃ y â†’ downgrade (khÃ´ng block ngay)
        const MILD_QUALIFIERS = ['nháº¹', 'thoÃ¡ng', 'nháº¹ nhÃ ng', 'Ã­t', 'hÆ¡i ', 'tÃ­ ', 'chÃºt '];
        // Severe qualifiers: boost severity â†’ luÃ´n block
        const SEVERE_QUALIFIERS = [
            'dá»¯ dá»™i', 'ráº¥t máº¡nh', 'khÃ´ng chá»‹u Ä‘Æ°á»£c', 'Ä‘á»™t ngá»™t', 'cá»±c ká»³',
            'dá»¯', 'náº·ng', 'tráº§m trá»ng', 'cáº¥p', 'tÄƒng nhanh',
        ];

        const isMildContext = (text: string, keyword: string): boolean => {
            const idx = text.indexOf(keyword);
            if (idx === -1) return false;
            const around = text.substring(Math.max(0, idx - 10), idx + keyword.length + 15);
            return MILD_QUALIFIERS.some(q => around.includes(q));
        };

        const isSevereContext = (text: string, keyword: string): boolean => {
            const idx = text.indexOf(keyword);
            if (idx === -1) return false;
            const around = text.substring(Math.max(0, idx - 10), idx + keyword.length + 20);
            return SEVERE_QUALIFIERS.some(q => around.includes(q));
        };

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // LAYER 3: COMBO DETECTION (Infermedica Bayesian pattern)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // LAYER 3: COMBO DETECTION â€” DB-driven (Infermedica Bayesian pattern)
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // Triáº¿t lÃ½: P(Emergency | A+B) >> P(Emergency | A) + P(Emergency | B)
        // CRE dÃ¹ng `symptomGroups` (tiÃªu chuáº©n), adapter map sang `symptoms` cá»§a local type
        const creComboRules = await ClinicalRulesEngine.getComboRules();
        type ComboRule = { symptoms: string[][]; label: string; minMatch: number; };
        const COMBO_RULES: ComboRule[] = creComboRules.map(r => ({
            symptoms: r.symptomGroups,
            label:    r.label,
            minMatch: r.minMatch,
        }));


        // Kiá»ƒm tra combo rules
        const triggeredCombos: string[] = [];
        COMBO_RULES.forEach(rule => {
            let matchCount = 0;
            for (const symptomGroup of rule.symptoms) {
                const groupMatched = symptomGroup.some(
                    kw => lowerSymptomsSafe.includes(kw) && !isNegated(lowerSymptomsSafe, kw)
                );
                if (groupMatched) matchCount++;
            }
            if (matchCount >= rule.minMatch) {
                triggeredCombos.push(rule.label);
            }
        });

        // EXECUTION: Apply all 4 layers to EMERGENCY_GROUPS
        // Layer 1: Keyword match (diacritics-aware via kwMatch) | Layer 2a: Negation
        // Layer 2b: Mild qualifier | Layer 2c: Temporal/Scope | Layer 3: Combo
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        const matchedGroups = EMERGENCY_GROUPS.filter(group =>
            group.keywords.some(kw => {
                if (!kwMatch(lowerSymptomsSafe, lowerSymptomsNorm, kw)) return false;
                if (isNegated(lowerSymptomsSafe, kw)) return false;
                if (isMildContext(lowerSymptomsSafe, kw)) return false;
                return true;
            })
        );
        const downgradedGroups = EMERGENCY_GROUPS.filter(group =>
            !matchedGroups.includes(group) &&
            group.keywords.some(kw =>
                kwMatch(lowerSymptomsSafe, lowerSymptomsNorm, kw) &&
                !isNegated(lowerSymptomsSafe, kw) &&
                isDowngradedContext(kw)
            )
        );

        // Critical alerts
        matchedGroups.forEach(group => {
            const matchedKeyword = group.keywords.find(
                kw => kwMatch(lowerSymptomsSafe, lowerSymptomsNorm, kw) &&
                      !isNegated(lowerSymptomsSafe, kw) &&
                      !isMildContext(lowerSymptomsSafe, kw) &&
                      !isDowngradedContext(kw)
            );
            const isSevere = matchedKeyword ? isSevereContext(lowerSymptomsSafe, matchedKeyword) : false;
            const prefix   = isSevere ? 'ðŸ”´ Cá»°C Ká»² NGHIÃŠM TRá»ŒNG' : 'ðŸš¨';
            criticalAlerts.push(
                `${prefix} [${group.label.toUpperCase()}] PhÃ¡t hiá»‡n: "${matchedKeyword}" â€” Gá»ŒI Cáº¤P Cá»¨U 115 hoáº·c Ä‘áº¿n cÆ¡ sá»Ÿ y táº¿ NGAY!`
            );
        });

        // Soft warnings â€” past/hypothetical downgraded
        downgradedGroups.forEach(group => {
            const kw = group.keywords.find(k => kwMatch(lowerSymptomsSafe, lowerSymptomsNorm, k) && isDowngradedContext(k));
            warnings.push(
                `ðŸ’¬ [${group.label}] PhÃ¡t hiá»‡n Ä‘á» cáº­p "${kw}" trong ngá»¯ cáº£nh quÃ¡ khá»© hoáº·c lo ngáº¡i. Náº¿u triá»‡u chá»©ng Ä‘ang xáº£y ra hiá»‡n táº¡i â†’ Gá»ŒI 115 NGAY.`
            );
        });

        // Combo alerts
        triggeredCombos.forEach(combo => {
            criticalAlerts.push(combo + ' â€” Gá»ŒI Cáº¤P Cá»¨U 115 NGAY!');
        });

        // Bá»‡nh ná»n nguy hiá»ƒm â†’ soft warning (khÃ´ng block)
        if (profile.chronicConditions) {
            const dangerousConditions = ['tim máº¡ch', 'suy tim', 'gan', 'tháº­n', 'tiá»ƒu Ä‘Æ°á»ng', 'ung thÆ°', 'hiv', 'ghÃ©p táº¡ng'];
            const lowerConditions = profile.chronicConditions.toLowerCase();
            dangerousConditions.forEach(condition => {
                if (lowerConditions.includes(condition)) {
                    warnings.push(
                        `ðŸ©º Báº¡n cÃ³ bá»‡nh ná»n "${condition}": Má»i thuá»‘c Ä‘á»u cáº§n Ä‘Æ°á»£c bÃ¡c sÄ© chuyÃªn khoa phÃª duyá»‡t.`
                    );
                }
            });
        }

        // ═══════════════════════════════════════════════════════════════════════
        // LAYER 4: SEMANTIC FALLBACK (Phase 2 — pgvector cosine similarity)
        // ═══════════════════════════════════════════════════════════════════════
        // Chỉ chạy khi Layers 1-3 không phát hiện gì (criticalAlerts rỗng).
        // Bắt keyword khẩn cấp CHƯA có trong DB bằng vector cosine similarity.
        // Threshold: BLOCK >= 0.82 | WARN >= 0.62 | PASS < 0.62
        // PENDING keyword xuất hiện ở GET /api/admin/clinical-rules/pending-review
        if (criticalAlerts.length === 0) {
            try {
                const semantic = await ClinicalRulesEngine.semanticFallback(symptoms);
                if (semantic.action === 'BLOCK') {
                    criticalAlerts.push(
                        `🤖 [AI DETECTION — ${semantic.matchedLabel?.toUpperCase()}] ` +
                        `Phát hiện triệu chứng có thể nghiêm trọng qua AI semantic analysis ` +
                        `(độ tương đồng ${(semantic.similarityScore * 100).toFixed(0)}% với "${semantic.matchedKeyword}"). ` +
                        'GỌI CẤP CỨU 115 hoặc đến cơ sở y tế NGAY!' +
                        (semantic.queued ? ' [Keyword đã được thêm vào hàng chờ Admin review]' : '')
                    );
                } else if (semantic.action === 'WARN') {
                    warnings.push(
                        `⚠️ [AI DETECTION] Triệu chứng có nét tương đồng với nhóm "${semantic.matchedLabel}" ` +
                        `(${(semantic.similarityScore * 100).toFixed(0)}% match). ` +
                        'Nếu cảm thấy nghiêm trọng hơn → gọi 115 ngay.'
                    );
                }
            } catch {
                // Semantic fallback fail → bỏ qua, không ảnh hưởng flow chính
                // (Gemini API down, rate limit...) — fail-open pattern
            }
        }

        return {
            isSafe: criticalAlerts.length === 0,
            warnings,
            criticalAlerts,
            missingInfo: []
        };


    }

    /**
     * Kiá»ƒm tra tÆ°Æ¡ng tÃ¡c thuá»‘c (drug-drug interaction)
     */
    static checkDrugInteractions(currentMedicines: string[]): string[] {
        const warnings: string[] = [];

        const knownInteractions: Record<string, string[]> = {
            'warfarin': ['aspirin', 'ibuprofen', 'paracetamol liá»u cao'],
            'aspirin': ['warfarin', 'ibuprofen', 'corticosteroid'],
            'metformin': ['rÆ°á»£u', 'corticosteroid'],
            'digoxin': ['thuá»‘c lá»£i tiá»ƒu', 'corticosteroid'],
            'ibuprofen': ['aspirin', 'warfarin', 'corticosteroid']
        };

        currentMedicines.forEach(med1 => {
            const lower1 = med1.toLowerCase();
            Object.keys(knownInteractions).forEach(drugName => {
                if (lower1.includes(drugName)) {
                    const interactsWith = knownInteractions[drugName];
                    currentMedicines.forEach(med2 => {
                        const lower2 = med2.toLowerCase();
                        interactsWith.forEach(interactDrug => {
                            if (lower2.includes(interactDrug) && med1 !== med2) {
                                warnings.push(
                                    `âš ï¸ TÆ¯Æ NG TÃC THUá»C: ${med1} cÃ³ thá»ƒ tÆ°Æ¡ng tÃ¡c vá»›i ${med2}. Cáº§n tham kháº£o bÃ¡c sÄ©/dÆ°á»£c sÄ©.`
                                );
                            }
                        });
                    });
                }
            });
        });

        return warnings;
    }

    /**
     * =================================================================
     * PHASE 4: LLM SEMANTIC TRIAGE â€” Microsoft Azure Health Bot Pattern
     * =================================================================
     *
     * Váº¥n Ä‘á»: Keyword matching (dÃ¹ cÃ³ 130+ tá»«) váº«n miss cÃ¡c case diá»…n Ä‘áº¡t
     * khÃ´ng theo khuÃ´n máº«u. VÃ­ dá»¥:
     *   "Ä‘ang náº±m khÃ´ng dáº­y Ä‘Æ°á»£c, ngÆ°á»i xanh lÃ©t, gia Ä‘Ã¬nh hoáº£ng loáº¡n"
     * â†’ KhÃ´ng tá»« nÃ o trong keyword list match â†’ System bá» qua â†’ NGUY HIá»‚M
     *
     * Giáº£i phÃ¡p: Groq LLM lÃ m "Safety Oracle" â€” hiá»ƒu ngá»¯ nghÄ©a, khÃ´ng chá»‰ kÃ½ tá»±.
     *
     * Thiáº¿t káº¿:
     *   1. Hard timeout 3s â†’ khÃ´ng bao giá» block pipeline quÃ¡ lÃ¢u
     *   2. Confidence threshold â‰¥ 0.85 â†’ chá»‰ block khi LLM cháº¯c cháº¯n
     *   3. Error/timeout â†’ graceful degradation (khÃ´ng crash, khÃ´ng block)
     *   4. Chá»‰ gá»i khi keyword check PASS â†’ khÃ´ng tá»‘n token khi Ä‘Ã£ block rá»“i
     *
     * Input format Ä‘á»ƒ LLM classify:
     *   isEmergency: boolean, confidence: 0.0-1.0, reason: string
     * =================================================================
     */
    static async triageSymptomsWithLLM(symptoms: string): Promise<{
        isEmergency: boolean;
        confidence: number;
        reason: string;
        emergencyType: string | null;
    }> {
        const GROQ_URL   = 'https://api.groq.com/openai/v1/chat/completions';
        const GROQ_MODEL = 'llama-3.3-70b-versatile';
        const TIMEOUT_MS = 3000; // Hard 3s â€” khÃ´ng bao giá» block pipeline quÃ¡ lÃ¢u

        const apiKey = process.env.GROQ_API_KEY;
        // KhÃ´ng cÃ³ API key â†’ graceful skip (khÃ´ng crash)
        if (!apiKey) return { isEmergency: false, confidence: 0, reason: 'No API key', emergencyType: null };

        const controller = new AbortController();
        const timeoutId  = setTimeout(() => controller.abort(), TIMEOUT_MS);

        try {
            const response = await fetch(GROQ_URL, {
                method: 'POST',
                headers: {
                    'Content-Type':  'application/json',
                    'Authorization': `Bearer ${apiKey.replace(/['"]/g, '').trim()}`,
                },
                body: JSON.stringify({
                    model: GROQ_MODEL,
                    temperature: 0.0, // Deterministic â€” triage pháº£i nháº¥t quÃ¡n
                    max_tokens:  120, // JSON nhá», nhanh
                    response_format: { type: 'json_object' },
                    messages: [
                        {
                            role: 'system',
                            content: `Báº¡n lÃ  há»‡ thá»‘ng triage y táº¿ kháº©n cáº¥p.
PhÃ¢n tÃ­ch mÃ´ táº£ triá»‡u chá»©ng vÃ  xÃ¡c Ä‘á»‹nh Ä‘Ã¢y cÃ³ pháº£i tÃ¬nh tráº¡ng cáº§n cáº¥p cá»©u khÃ´ng.

Äá»ŠNH NGHÄ¨A Cáº¤P Cá»¨U (TRUE):
- Äe dá»a tÃ­nh máº¡ng ngay láº­p tá»©c (suy hÃ´ háº¥p, ngá»«ng tim, Ä‘á»™t quá»µ)
- TÃ¬nh tráº¡ng cáº§n can thiá»‡p y táº¿ trong vÃ²ng < 1 giá»
- Máº¥t Ã½ thá»©c, co giáº­t, xuáº¥t huyáº¿t náº·ng, ngá»™ Ä‘á»™c

KHÃ”NG PHáº¢I Cáº¤P Cá»¨U (FALSE):
- Triá»‡u chá»©ng thÃ´ng thÆ°á»ng (cáº£m cÃºm, Ä‘au Ä‘áº§u nháº¹, tiÃªu cháº£y nháº¹)
- Bá»‡nh mÃ£n tÃ­nh á»•n Ä‘á»‹nh
- Triá»‡u chá»©ng kÃ©o dÃ i > 1 tuáº§n mÃ  ngÆ°á»i Ä‘ang á»•n

NGÆ¯á» NG QUYáº¾T Äá»ŠNH: Chá»‰ isEmergency=true khi confidence â‰¥ 0.85.
Náº¿u khÃ´ng cháº¯c â†’ false (trÃ¡nh false positive).

Output CHá»ˆ JSON:
{"isEmergency":true/false,"confidence":0.0-1.0,"reason":"lÃ½ do ngáº¯n gá»n","emergencyType":"loáº¡i cáº¥p cá»©u hoáº·c null"}`,
                        },
                        {
                            role: 'user',
                            content: `Triá»‡u chá»©ng: "${symptoms}"`,
                        },
                    ],
                }),
                signal: controller.signal,
            });

            if (!response.ok) {
                throw new Error(`Groq HTTP ${response.status}`);
            }

            const data    = await response.json();
            const content = data.choices?.[0]?.message?.content ?? '{}';
            const parsed  = JSON.parse(content);

            return {
                isEmergency:   Boolean(parsed.isEmergency),
                confidence:    Math.max(0, Math.min(1, Number(parsed.confidence) || 0)),
                reason:        String(parsed.reason || ''),
                emergencyType: parsed.emergencyType || null,
            };

        } catch (err: any) {
            // Timeout hoáº·c lá»—i máº¡ng â†’ KHÃ”NG block (safety degrades gracefully)
            // Keyword matching váº«n lÃ  tuyáº¿n phÃ²ng thá»§ chÃ­nh
            const isTimeout = err.name === 'AbortError';
            console.warn(`[EmergencyTriage LLM] ${isTimeout ? 'Timeout 3s' : err.message} â€” falling back to keyword only`);
            return { isEmergency: false, confidence: 0, reason: 'LLM unavailable', emergencyType: null };

        } finally {
            clearTimeout(timeoutId);
        }
    }

    /**
     * Comprehensive check â€” tá»•ng há»£p táº¥t cáº£ layers
     */
    static async performComprehensiveCheck(
        symptoms: string,
        profile: UserMedicalProfile
    ): Promise<SafetyCheckResult> {
        const completenessCheck      = this.validateProfileCompleteness(profile);
        const contraindicationCheck  = await this.checkContraindications(symptoms, profile);
        const drugInteractionWarnings = this.checkDrugInteractions(profile.currentMedicines);

        return {
            isSafe: contraindicationCheck.isSafe,
            warnings: [
                ...completenessCheck.warnings,
                ...contraindicationCheck.warnings,
                ...drugInteractionWarnings,
            ],
            criticalAlerts: contraindicationCheck.criticalAlerts,
            missingInfo: completenessCheck.missingInfo
        };
    }

    /**
     * Táº¡o context an toÃ n Ä‘á»ƒ gá»­i cho AI
     */
    static buildSafeContextForAI(profile: UserMedicalProfile): string {
        const context: string[] = [];

        if (profile.allergies && profile.allergies !== 'KhÃ´ng') {
            context.push(`- Dá»‹ á»©ng: ${profile.allergies}`);
        }
        if (profile.chronicConditions && profile.chronicConditions !== 'KhÃ´ng') {
            context.push(`- Bá»‡nh ná»n: ${profile.chronicConditions}`);
        }
        if (profile.currentMedicines.length > 0) {
            context.push(`- Äang dÃ¹ng thuá»‘c: ${profile.currentMedicines.join(', ')}`);
        }
        if (profile.isPregnant)     context.push(`- Thai ká»³: CÃ³`);
        if (profile.isBreastfeeding) context.push(`- Cho con bÃº: CÃ³`);
        if (profile.age)    context.push(`- Tuá»•i: ${profile.age}`);
        if (profile.gender) context.push(`- Giá»›i tÃ­nh: ${profile.gender}`);

        return context.length > 0
            ? `\n\n**THÃ”NG TIN Y Táº¾ Cá»¦A NGÆ¯á»œI DÃ™NG:**\n${context.join('\n')}`
            : '';
    }
}

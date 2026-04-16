/**
 * Medical Safety Check Service (Backend)
 * Logic kiểm tra an toàn y tế TRƯỚC KHI gọi AI
 */

export interface UserMedicalProfile {
    allergies: string | null;
    chronicConditions: string | null;
    currentMedicines: string[]; // Danh sách thuốc đang dùng
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
     * Kiểm tra xem user đã có đủ thông tin để tư vấn chưa
     */
    static validateProfileCompleteness(profile: UserMedicalProfile): SafetyCheckResult {
        const missingInfo: string[] = [];
        const warnings: string[] = [];

        // Kiểm tra thông tin bắt buộc
        if (!profile.allergies && profile.allergies !== '') {
            missingInfo.push('Thông tin dị ứng thuốc');
        }

        if (!profile.chronicConditions && profile.chronicConditions !== '') {
            missingInfo.push('Thông tin bệnh nền');
        }

        if (!profile.currentMedicines || profile.currentMedicines.length === 0) {
            warnings.push('Chưa cập nhật danh sách thuốc đang dùng.');
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
     * Kiểm tra các contraindications (chống chỉ định) cứng
     */
    static checkContraindications(
        symptoms: string,
        profile: UserMedicalProfile
    ): SafetyCheckResult {
        const criticalAlerts: string[] = [];
        const warnings: string[] = [];

        // Rule 1: Thai kỳ
        if (profile.isPregnant) {
            criticalAlerts.push(
                '⚠️ BẠN ĐANG MANG THAI: Tuyệt đối không tự ý dùng thuốc. Hãy tham khảo bác sĩ sản khoa.'
            );
        }

        // Rule 2: Cho con bú
        if (profile.isBreastfeeding) {
            criticalAlerts.push(
                '⚠️ BẠN ĐANG CHO CON BÚ: Nhiều thuốc có thể ảnh hưởng đến trẻ qua sữa mẹ. Vui lòng hỏi bác sĩ.'
            );
        }

        // ═══════════════════════════════════════════════════════════════════════
        // RULE 0: HOSPITAL CONTEXT DETECTOR — Gap Fix 4 (case bên dưới)
        // ═══════════════════════════════════════════════════════════════════════
        // Vấn đề: User gõ "đi cấp cứu để truyền nước, uống thuốc gì?"
        //   → System recommend Paracetamol + Tiffy = SAI HOÀN TOÀN
        //   → Người đang ở bệnh viện, đang được bác sĩ quản lý
        //   → KHÔNG NÊN tư vấn thêm thuốc OTC vào
        //
        // Cơ sở y khoa:
        //   "Truyền nước" (IV fluids) chỉ được chỉ định khi:
        //     - Mất nước nặng (không bù miệng được)
        //     - Sốt xuất huyết dengue (cần giám sát chặt)
        //     - Rối loạn điện giải
        //   → Tất cả đều không thích hợp để tự mua thuốc OTC thêm vào
        //
        // Google Health / Babylon: "Under care" detection → redirect to physician
        // ═══════════════════════════════════════════════════════════════════════
        const lowerSymptomsForHospitalCheck = symptoms.toLowerCase();

        // Dấu hiệu đang được điều trị y tế
        // Gap Fix 4b: Thêm 'đi cấp cứu', 'nhập viện', 'vào viện' và các biến thể
        // Root cause: 'tôi đi cấp cứu vì đau đầu' → chỉ 'đã đi cấp cứu' được detect trước đây
        const HOSPITAL_CARE_SIGNALS = [
            // Đang ở viện
            'đang nằm viện', 'đang điều trị', 'đang nhập viện', 'đang ở bệnh viện',
            'đang trong bệnh viện', 'đang nằm điều trị', 'đang ở phòng cấp cứu',
            // Truyền dịch (IV)
            'truyền nước', 'truyền dịch', 'đặt kim truyền', 'đang truyền',
            // Cấp cứu (quá khứ / hiện tại / tương lai gần đều nguy hiểm)
            'đi cấp cứu',        // BUG: was missing — 'tôi đi cấp cứu vì đau đầu'
            'đã đi cấp cứu', 'vừa cấp cứu', 'vừa đi cấp cứu',
            'đến cấp cứu', 'vào cấp cứu', 'vào phòng cấp cứu',
            'đến bệnh viện cấp cứu', 'đưa đi cấp cứu',
            // Nhập viện
            'nhập viện', 'vào viện', 'ra viện', 'xuất viện vừa',
            // Điều trị chuyên biệt
            'bác sĩ đang', 'y tá đang', 'đang theo dõi tại', 'đang thở oxy',
            'đang dùng thuốc tiêm', 'thuốc tiêm bệnh viện',
            'đang được bác sĩ', 'theo dõi tại bệnh viện',
        ];

        const hospitalContextMatched = HOSPITAL_CARE_SIGNALS.find(
            signal => lowerSymptomsForHospitalCheck.includes(signal)
        );

        if (hospitalContextMatched) {
            criticalAlerts.push(
                `🏥 [ĐANG ĐƯỢC ĐIỀU TRỊ Y TẾ] Phát hiện bạn đang hoặc vừa nhận chăm sóc y tế ("${hospitalContextMatched}"). ` +
                `MediChain KHÔNG tư vấn thêm thuốc OTC khi bạn đang trong quá trình điều trị. ` +
                `Vui lòng hỏi trực tiếp bác sĩ hoặc dược sĩ đang phụ trách điều trị cho bạn.`
            );
        }

        // Dấu hiệu sốt xuất huyết dengue (phổ biến tại Việt Nam) — cần cảnh báo đặc biệt
        // "đau đầu + mệt/mỏi + truyền nước" = dengue pattern trong ngữ cảnh Việt Nam
        const DENGUE_RISK_PATTERN = {
            hasIVFluid:  ['truyền nước', 'truyền dịch'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
            hasFatigue:  ['mệt', 'mỏi người', 'mệt mỏi', 'người mệt'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
            hasHeadache: ['đau đầu', 'nhức đầu', 'đau đầu dữ'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
            hasFever:    ['sốt', 'nóng sốt'].some(kw => lowerSymptomsForHospitalCheck.includes(kw)),
        };
        const dengueSignalCount = Object.values(DENGUE_RISK_PATTERN).filter(Boolean).length;

        if (dengueSignalCount >= 3 && !hospitalContextMatched) {
            // Soft warning — không block nhưng cảnh báo quan trọng
            warnings.push(
                '🦟 [CẢNH BÁO SỐT XUẤT HUYẾT] Triệu chứng phù hợp nguy cơ sốt xuất huyết Dengue. ' +
                'Nếu sốt kéo dài > 2 ngày: (1) KHÔNG dùng Ibuprofen/Aspirin — có thể gây xuất huyết nặng. ' +
                '(2) Chỉ dùng Paracetamol nếu sốt cao. (3) Theo dõi tiểu cầu. ' +
                '(4) Đến cơ sở y tế ngay nếu nôn nhiều, đau bụng, chảy máu.'
            );
        }

        // ═══════════════════════════════════════════════════════════════════════
        // QUICK WIN 1: AGE-SPECIFIC THRESHOLDS (Babylon Health / WHO Pediatric)
        // ═══════════════════════════════════════════════════════════════════════
        // Vấn đề: "sốt 38°C" với người lớn = OTC, nhưng "sốt 38°C" với bé 2 tháng
        // = CẤP CỨU NHI KHOA. Hệ thống cũ không phân biệt → nguy hiểm.
        //
        // Cơ sở y học:
        //   - Trẻ < 3 tháng: Fever Response kém phát triển → bất kỳ sốt nào = nguy hiểm
        //   - Trẻ < 2 tuổi: Heat stroke risk cao hơn nhiều người lớn
        //   - Người > 65t: Immune response suy giảm → ngưỡng lo ngại thấp hơn
        //   Nguồn: American Academy of Pediatrics (AAP) 2023 + WHO IMCI Guidelines
        // ═══════════════════════════════════════════════════════════════════════
        if (profile.age !== undefined && profile.age !== null) {
            const lowerSym = symptoms.toLowerCase();
            const hasFeverMention = ['sốt', 'nhiệt độ', 'nóng sốt', '37.', '38.', '39.', '40.', '41.']
                .some(kw => lowerSym.includes(kw));

            // Trẻ < 3 tháng (age tính bằng năm: 3 tháng ≈ 0.25 năm)
            if (profile.age < 0.25) {
                if (hasFeverMention || lowerSym.includes('sốt')) {
                    criticalAlerts.push(
                        '🔴 [NGOẠI LỆ TRẺ SƠ SINH] Trẻ < 3 tháng tuổi có bất kỳ mức sốt nào (kể cả ≥38°C) là tình trạng CẤP CỨU NHI KHOA. KHÔNG tự ý điều trị — Đến cấp cứu nhi NGAY!'
                    );
                }
                // Thêm: ngủ li bì / bỏ bú ở trẻ sơ sinh cũng là emergency
                if (['li bì', 'bỏ bú', 'không khóc', 'tím tái'].some(kw => lowerSym.includes(kw))) {
                    criticalAlerts.push(
                        '🔴 [CẤP CỨU NHI] Trẻ sơ sinh li bì / bỏ bú / tím tái — NGUY HIỂM TÍNH MẠNG. Gọi 115 NGAY!'
                    );
                }
            }
            // Trẻ < 2 tuổi (age < 2)
            else if (profile.age < 2) {
                const hasHighFever = ['sốt 39', 'sốt 40', 'sốt 41', '39.', '40.', '41.', 'sốt cao']
                    .some(kw => lowerSym.includes(kw));
                if (hasHighFever) {
                    criticalAlerts.push(
                        '🟠 [TRẺ NHỎ] Sốt > 39°C ở trẻ < 2 tuổi cần được bác sĩ nhi khoa đánh giá NGAY. Nguy cơ co giật do sốt cao. Đừng tự mua thuốc — Đến khám ngay!'
                    );
                }
            }
            // Người cao tuổi > 65 tuổi
            else if (profile.age > 65) {
                // Ở người già, nhiều triệu chứng "bình thường" thực ra nguy hiểm hơn
                const elderRiskKeywords = ['ngã', 'té', 'ngất', 'lú lẫn', 'khó thở'];
                const elderMatched = elderRiskKeywords.find(kw => lowerSym.includes(kw));
                if (elderMatched) {
                    warnings.push(
                        `🩺 [NGƯỜI CAO TUỔI] Triệu chứng "${elderMatched}" ở người > 65 tuổi tiềm ẩn nguy cơ cao hơn (loãng xương, suy tim ẩn, TIA). Nên đến cơ sở y tế để kiểm tra, không nên tự điều trị.`
                    );
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════════
        // QUICK WIN 3a: TEMPORAL CONTEXT FILTER (Ada Health Scope Tagger pattern)
        // ═══════════════════════════════════════════════════════════════════════
        // Vấn đề: "Tôi lo sợ khó thở" → 'khó thở' match → BLOCKED = FALSE POSITIVE
        //         "Hồi trước tôi bị đau ngực" → 'đau ngực' match → BLOCKED = FALSE POSITIVE
        //
        // Giải pháp: Detect 2 loại context "giảm nhẹ":
        //   1. PAST TENSE: Triệu chứng đã qua → downgrade thành warning (không block)
        //   2. HYPOTHETICAL: Lo lắng/giả định → downgrade thành warning (không block)
        //
        // Kỹ thuật: Sentence-level scope (không chỉ window quanh keyword)
        //   → Chia câu theo dấu câu → check từng câu có scope chỉnh sửa không
        // ═══════════════════════════════════════════════════════════════════════
        const SCOPE_DOWNGRADE_PATTERNS = {
            past: [
                'trước đây', 'hồi trước', 'ngày trước', 'trước kia', 'hồi nhỏ',
                'hôm qua', 'tuần trước', 'tháng trước', 'năm ngoái',
                'từng bị', 'đã từng', 'đã hết', 'khỏi rồi', 'đã khỏi',
                'không còn nữa', 'người thân bị', 'ba tôi bị', 'mẹ tôi bị',
            ],
            hypothetical: [
                'lo sợ', 'lo lắng', 'sợ rằng', 'sợ bị', 'nhỡ bị',
                'nếu bị', 'giả sử', 'có thể bị', 'nghĩ là', 'không biết có bị',
                'hỏi cho biết', 'hỏi thăm', 'hỏi để biết',
            ],
        };

        // Tokenize thành câu (split bởi dấu câu + từ nối)
        const sentences = symptoms.split(/[.!?;,]|\bvà\b|\bnhưng\b|\btuy nhiên\b/i)
            .map(s => s.trim().toLowerCase())
            .filter(s => s.length > 2);

        // Tìm những câu có scope downgrade
        const downgradedSentences = new Set<string>();
        sentences.forEach(sentence => {
            const hasPast         = SCOPE_DOWNGRADE_PATTERNS.past.some(p => sentence.includes(p));
            const hasHypothetical = SCOPE_DOWNGRADE_PATTERNS.hypothetical.some(p => sentence.includes(p));
            if (hasPast || hasHypothetical) {
                downgradedSentences.add(sentence);
            }
        });

        // Helper: check xem keyword có nằm trong downgraded sentence không
        const isDowngradedContext = (keyword: string): boolean => {
            for (const sent of downgradedSentences) {
                if (sent.includes(keyword)) return true;
            }
            return false;
        };

        // ─────────────────────────────────────────────────────────────────────
        // EMERGENCY SYMPTOM DETECTION — Grouped Pattern Matching
        // ─────────────────────────────────────────────────────────────────────
        // Kiến trúc: Mỗi nhóm đại diện 1 loại cấp cứu lâm sàng.
        // Logic: ANY 1 keyword trong nhóm → trigger cảnh báo nhóm đó.
        // Lý do dùng nhóm: Người dùng diễn đạt cùng triệu chứng bằng nhiều cách khác nhau.
        //
        // Nguồn: WHO Emergency Triage Categories + Hướng dẫn xử trí cấp cứu Bộ Y tế VN
        //        + ESC/AHA Acute Coronary Syndrome Guidelines
        // ─────────────────────────────────────────────────────────────────────

        type EmergencyGroup = {
            id: string;
            label: string;
            keywords: string[];
        };

        // ═══════════════════════════════════════════════════════════════════════
        // GAP FIX 1: DIACRITICS NORMALIZATION (Mobile input pattern)
        // ═══════════════════════════════════════════════════════════════════════
        // Vấn đề NGHIÊM TRỌNG: Phần lớn user mobile Việt Nam nhập không dấu.
        // "khó thở" → "kho tho" | "đau ngực" → "dau nguc"
        // includes() không match → false negative = user đang cấp cứu bị pass qua!
        //
        // Giải pháp: Normalize both input và keyword về không dấu rồi so sánh song song.
        // Kỹ thuật: NFD normalize + remove combining diacritical marks (Unicode range 0300-036f)
        // ═══════════════════════════════════════════════════════════════════════
        const removeDiacritics = (str: string): string =>
            str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D');

        const lowerSymptomsSafe  = symptoms.toLowerCase();              // Original có dấu
        const lowerSymptomsNorm  = removeDiacritics(symptoms.toLowerCase()); // Không dấu (mobile)

        // Kiểm tra keyword — thử cả có dấu lẫn không dấu
        const kwMatch = (text: string, textNorm: string, keyword: string): boolean => {
            if (text.includes(keyword)) return true;
            const kwNorm = removeDiacritics(keyword);
            return textNorm.includes(kwNorm);
        };

        // ═══════════════════════════════════════════════════════════════════════
        // GAP FIX 2: VITAL SIGNS THRESHOLD DETECTION (HealthKit / Fitbit Health API)
        // ═══════════════════════════════════════════════════════════════════════
        // Vấn đề: User gõ con số nhưng hệ thống không hiểu ngưỡng nguy hiểm:
        //   "huyết áp 200" = hypertensive crisis → MISSED
        //   "đường huyết 500" = DKA → MISSED
        //   "SpO2 85%" = respiratory failure → MISSED
        //   "nhịp tim 180" = SVT → MISSED
        //
        // Giải pháp: Regex extract số + ngưỡng lâm sàng chuẩn WHO/ACC/AHA
        // ═══════════════════════════════════════════════════════════════════════

        // Blood Pressure — Hypertensive Crisis: SBP ≥ 180 mmHg (ACC/AHA 2017)
        const bpPattern    = /(?:huyết áp|blood pressure|ha|bp)[\s:]*(\d{2,3})\s*(?:\/\s*\d{2,})?/i;
        const bpMatch      = lowerSymptomsNorm.match(bpPattern);
        if (bpMatch && parseInt(bpMatch[1]) >= 180) {
            criticalAlerts.push(
                `🔴 [CƠN TĂNG HUYẾT ÁP] Huyết áp tâm thu ${bpMatch[1]}mmHg ≥ 180 = Hypertensive Crisis. Nguy cơ đột quỵ/nhồi máu cơ tim cấp. GỌI 115 NGAY hoặc đến cấp cứu!`
            );
        }

        // Blood Glucose — DKA (>400mg/dL) hoặc Hypoglycemia (<50mg/dL)
        const glucPattern  = /(?:đường huyết|blood sugar|glucose|bg)[\s:]*(\d{2,3})/i;
        const glucMatch    = lowerSymptomsNorm.match(glucPattern);
        if (glucMatch) {
            const val = parseInt(glucMatch[1]);
            if (val >= 400) {
                criticalAlerts.push(
                    `🔴 [TĂNG ĐƯỜNG HUYẾT NGHIÊM TRỌNG] Đường huyết ${val}mg/dL → Nguy cơ DKA/HHS. Cần truyền dịch + insulin IV. GỌI 115 NGAY!`
                );
            } else if (val <= 50) {
                criticalAlerts.push(
                    `🔴 [HẠ ĐƯỜNG HUYẾT NGUY HIỂM] Đường huyết ${val}mg/dL ≤ 50 → Hôn mê hạ đường có thể xảy ra trong vài phút. Uống đường ngay + GỌI 115!`
                );
            }
        }

        // SpO2 — Respiratory Failure: SpO2 < 90% (WHO definition)
        const spo2Pattern  = /(?:spo2|độ bão hòa oxy|nồng độ oxy|oxygen sat)[\s%:]*(\d{2,3})/i;
        const spo2Match    = lowerSymptomsNorm.match(spo2Pattern);
        if (spo2Match && parseInt(spo2Match[1]) < 90) {
            criticalAlerts.push(
                `🔴 [SUY HÔ HẤP] SpO2 ${spo2Match[1]}% < 90% = Suy hô hấp. Cần oxy ngay lập tức. GỌI 115 NGAY!`
            );
        }

        // Heart Rate — Tachycardia >150 (SVT risk) hoặc Bradycardia <40
        const hrPattern    = /(?:nhịp tim|heart rate|mạch|pulse)[\s:]*(\d{2,3})/i;
        const hrMatch      = lowerSymptomsNorm.match(hrPattern);
        if (hrMatch) {
            const hr = parseInt(hrMatch[1]);
            if (hr >= 150) {
                criticalAlerts.push(
                    `🔴 [NHỊP TIM NGUY HIỂM] Nhịp tim ${hr}/phút ≥ 150 → Nguy cơ SVT/AF với RVR. Cần đánh giá ECG khẩn. GỌI 115!`
                );
            } else if (hr <= 40) {
                criticalAlerts.push(
                    `🔴 [NHỊP TIM CHẬM NGUY HIỂM] Nhịp tim ${hr}/phút ≤ 40 → Complete heart block hoặc SSS. GỌI 115 NGAY!`
                );
            }
        }

        // ═══════════════════════════════════════════════════════════════════════
        // GAP FIX 3: EXTENDED INFANT RULES (WHO IMCI 2020 — 0-12 months)
        // ═══════════════════════════════════════════════════════════════════════
        // Vấn đề: Quick Win 1 chỉ cover < 3 tháng. Trẻ 3-12 tháng cũng có ngưỡng
        // riêng nhưng đang bị bỏ sót.
        //
        //   Trẻ 3-12 tháng: Bỏ bú, li bì, sốt > 38.5°C = WHO "Danger Signs"
        //   WHO IMCI: 3 danger signs → immediate referral
        // ═══════════════════════════════════════════════════════════════════════
        if (profile.age !== undefined && profile.age !== null && profile.age >= 0.25 && profile.age < 1) {
            const lowerSym           = symptoms.toLowerCase();
            const imsicDangerSigns   = ['bỏ bú', 'li bì', 'không uống được', 'nôn tất cả', 'co giật'];
            const hasDangerSign      = imsicDangerSigns.some(ds => lowerSym.includes(ds));
            const hasHighFeverInfant = ['sốt 38', 'sốt 39', 'sốt 40', 'sốt cao'].some(kw => lowerSym.includes(kw));

            if (hasDangerSign || hasHighFeverInfant) {
                criticalAlerts.push(
                    `🔴 [WHO IMCI — TRẺ 3-12 THÁNG] Phát hiện dấu hiệu nguy hiểm theo chuẩn WHO IMCI. Trẻ nhũ nhi cần được bác sĩ nhi khoa đánh giá NGAY. Đến cơ sở y tế CẤP THIẾT!`
                );
            }
        }

        const EMERGENCY_GROUPS: EmergencyGroup[] = [

            // 1. HỘI CHỨNG VÀNH CẤP (ACS — Acute Coronary Syndrome)
            {
                id: 'acs',
                label: 'Hội chứng vành cấp / Nhồi máu cơ tim',
                keywords: [
                    'đau ngực', 'tức ngực', 'nặng ngực', 'thắt ngực', 'đau thắt',
                    'đau lan tay trái', 'đau lan vai trái', 'đau lan cánh tay',
                    'đau ngực dữ dội', 'nhồi máu cơ tim', 'nhịp tim loạn',
                    'tim đập không đều', 'ngực như bị đè',
                ]
            },
            // 2. SUY HÔ HẤP CẤP (Respiratory Failure / Pulmonary Edema)
            {
                id: 'resp_failure',
                label: 'Suy hô hấp cấp / Phù phổi',
                keywords: [
                    'khó thở', 'thở khó', 'không thở được', 'thở nặng nề',
                    'thở nhanh nông', 'suy hô hấp', 'phù phổi', 'ran ẩm phổi',
                    'gõ đục phổi', 'môi tím', 'tím tái', 'thiếu oxy',
                    'không thở được', 'nghẹt thở', 'tràn dịch màng phổi',
                ]
            },
            // 3. ĐỘT QUỴ NÃO (Stroke / TIA)
            {
                id: 'stroke',
                label: 'Đột quỵ não / Tai biến mạch máu não',
                keywords: [
                    'đột quỵ', 'tai biến', 'liệt nửa người', 'liệt tay',
                    'liệt chân', 'méo miệng', 'nói ngọng đột ngột', 'nói khó',
                    'tê nửa mặt', 'tê nửa người', 'mất thị lực đột ngột',
                    'mù đột ngột', 'đau đầu dữ dội đột ngột', 'đầu như sét đánh',
                ]
            },
            // 4. SỐC PHẢN VỆ (Anaphylaxis)
            {
                id: 'anaphylaxis',
                label: 'Sốc phản vệ / Dị ứng nặng toàn thân',
                keywords: [
                    'sốc phản vệ', 'phù mặt', 'phù môi', 'phù lưỡi',
                    'nổi mề đay toàn thân', 'dị ứng nặng', 'choáng phản vệ',
                    'sưng mặt khó thở', 'phản vệ',
                ]
            },
            // 5. NGẤT / MẤT Ý THỨC (Syncope / Loss of Consciousness)
            {
                id: 'syncope',
                label: 'Ngất xỉu / Mất ý thức',
                keywords: [
                    'bất tỉnh', 'mất ý thức', 'ngất xỉu', 'ngất', 'hôn mê',
                    'không tỉnh', 'không phản ứng', 'mất phản xạ',
                ]
            },
            // 6. CO GIẬT (Seizure)
            {
                id: 'seizure',
                label: 'Co giật / Động kinh cấp',
                keywords: [
                    'co giật', 'lên cơn động kinh', 'giật toàn thân',
                    'cứng người co giật', 'động kinh',
                ]
            },
            // 7. SỐC (Shock — Hypovolemic/Septic/Cardiogenic)
            {
                id: 'shock',
                label: 'Sốc / Tụt huyết áp nặng',
                keywords: [
                    'tụt huyết áp', 'huyết áp tụt', 'lạnh toát', 'vã mồ hôi lạnh',
                    'mạch yếu', 'da lạnh nhợt', 'xanh tái lạnh', 'sốc',
                    'lạnh tay chân', 'môi nhợt', 'mạch nhanh yếu',
                ]
            },
            // 8. NHIỄM TRÙNG HUYẾT / VIÊM MÀNG NÃO (Sepsis / Meningitis)
            {
                id: 'sepsis',
                label: 'Nhiễm trùng huyết / Viêm màng não',
                keywords: [
                    'nhiễm trùng huyết', 'nhiễm trùng máu', 'sốc nhiễm trùng',
                    'cứng cổ sốt', 'sốt cao cứng cổ', 'sợ ánh sáng sốt cao',
                    'viêm màng não', 'ban xuất huyết', 'sốt cao rét run dữ dội',
                ]
            },
            // 9. XUẤT HUYẾT TIÊU HÓA (GI Bleeding)
            {
                id: 'gi_bleeding',
                label: 'Xuất huyết tiêu hóa',
                keywords: [
                    'nôn ra máu', 'ói ra máu', 'đi ngoài ra máu', 'phân đen như hắc ín',
                    'đại tiện ra máu', 'ho ra máu', 'tiêu chảy ra máu',
                    'phân đen', 'đi phân đen',
                ]
            },
            // 10. CHẤN THƯƠNG NGHIÊM TRỌNG (Severe Trauma)
            {
                id: 'trauma',
                label: 'Chấn thương nghiêm trọng',
                keywords: [
                    'chấn thương đầu', 'chấn thương sọ não', 'tai nạn giao thông',
                    'té ngã từ cao', 'gãy xương lớn', 'đâm xuyên ngực',
                    'vết thương sâu chảy máu nhiều', 'máu không cầm được',
                ]
            },
            // 11. SỐT > 39.5°C (Hyperpyrexia)
            {
                id: 'hyperpyrexia',
                label: 'Sốt cực cao (>39.5°C)',
                keywords: [
                    'sốt 40', 'sốt 39.5', 'sốt 41', 'sốt cao trên 39',
                    'cao nhiệt', 'nhiệt độ 40', 'nhiệt độ 41',
                ]
            },
            // 12. VÀNG DA NẶNG / SUY GAN CẤP
            {
                id: 'liver_failure',
                label: 'Vàng da nặng / Suy gan cấp',
                keywords: [
                    'vàng da vàng mắt', 'vàng da đột ngột', 'vàng da kèm đau bụng',
                    'suy gan', 'bụng báng nước',
                ]
            },
            // 13. ĐAU BỤNG CẤP NGOẠI KHOA (Acute Abdomen)
            {
                id: 'acute_abdomen',
                label: 'Đau bụng cấp / Nghi cấp cứu ngoại',
                keywords: [
                    'đau bụng dữ dội', 'đau bụng không chịu được',
                    'bụng cứng như gỗ', 'đau xuyên ra lưng dữ dội',
                    'ruột thừa', 'vỡ ruột',
                ]
            },
            // 14. NGỘ ĐỘC / QUÁ LIỀU (Poisoning / Overdose)
            {
                id: 'poisoning',
                label: 'Ngộ độc / Quá liều thuốc',
                keywords: [
                    'ngộ độc', 'uống quá liều', 'uống nhầm thuốc', 'nuốt hóa chất',
                    'uống thuốc tự tử', 'quá liều thuốc', 'poison',
                ]
            },
            // 15. SẢN KHOA CẤP (Obstetric Emergency)
            {
                id: 'obstetric',
                label: 'Cấp cứu sản khoa',
                keywords: [
                    'ra máu âm đạo nhiều', 'chảy máu khi mang thai', 'đau bụng dữ khi mang thai',
                    'sản giật', 'co giật khi mang thai', 'sinh non', 'thai ra máu',
                ]
            },
        ];

        // ─── Chuẩn hóa input ─────────────────────────────────────────────────
        const lowerSymptoms = symptoms.toLowerCase();

        // ═══════════════════════════════════════════════════════════════════════
        // LAYER 1: NEGATION FILTER (Ada Health / Google Health pattern)
        // ═══════════════════════════════════════════════════════════════════════
        // Vấn đề: "tôi KHÔNG khó thở" → system detect "khó thở" → FALSE POSITIVE
        // Giải pháp: Loại bỏ keyword nếu xuất hiện sau pattern phủ định (trong vòng 20 ký tự)
        // Kỹ thuật: Sliding window negation check
        const NEGATION_PATTERNS = ['không ', 'chưa ', 'hết ', 'đã hết ', 'không còn ', 'không có '];


        const isNegated = (text: string, keyword: string): boolean => {
            const idx = text.indexOf(keyword);
            if (idx === -1) return false;
            // Lấy window 20 ký tự trước keyword
            const before = text.substring(Math.max(0, idx - 20), idx);
            return NEGATION_PATTERNS.some(neg => before.includes(neg));
        };

        // ═══════════════════════════════════════════════════════════════════════
        // LAYER 2: SEVERITY QUALIFIER (Apple HealthKit / Babylon Health pattern)
        // ═══════════════════════════════════════════════════════════════════════
        // "đau đầu nhẹ" → giảm severity → KHÔNG block (chỉ theo dõi)
        // "đau đầu dữ dội đột ngột" → tăng severity → BLOCK cứng
        // Kỹ thuật: Severity modifier affects decision threshold

        // Mild qualifiers: nếu keyword kèm modifier này → downgrade (không block ngay)
        const MILD_QUALIFIERS = ['nhẹ', 'thoáng', 'nhẹ nhàng', 'ít', 'hơi ', 'tí ', 'chút '];
        // Severe qualifiers: boost severity → luôn block
        const SEVERE_QUALIFIERS = [
            'dữ dội', 'rất mạnh', 'không chịu được', 'đột ngột', 'cực kỳ',
            'dữ', 'nặng', 'trầm trọng', 'cấp', 'tăng nhanh',
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

        // ═══════════════════════════════════════════════════════════════════════
        // LAYER 3: COMBO DETECTION (Infermedica Bayesian pattern)
        // ═══════════════════════════════════════════════════════════════════════
        // Triết lý: P(Emergency | A+B) >> P(Emergency | A) + P(Emergency | B)
        // Mỗi symptom đơn lẻ có thể bình thường, nhưng kết hợp = emergency
        // Chỉ match combo khi CẢ HAI symptom có mặt (không bị negated)
        type ComboRule = {
            symptoms: string[][];  // Mỗi inner array = variants cho 1 symptom trong combo
            label: string;
            minMatch: number;      // Số symptoms tối thiểu phải match (thường = len(symptoms))
        };

        const COMBO_RULES: ComboRule[] = [
            // Viêm màng não: Kernig/Brudzinski triad
            {
                symptoms: [
                    ['sốt', 'sốt cao'],
                    ['cứng cổ', 'gáy cứng'],
                    ['đau đầu', 'nhức đầu', 'sợ ánh sáng', 'buồn nôn']
                ],
                label: '⚠️ COMBO: Sốt + Cứng cổ + Đau đầu → Nghi VIÊM MÀNG NÃO',
                minMatch: 2,
            },
            // Hội chứng vành cấp không điển hình
            {
                symptoms: [
                    ['đau ngực', 'tức ngực', 'nặng ngực'],
                    ['vã mồ hôi', 'toát mồ hôi', 'mồ hôi lạnh'],
                    ['buồn nôn', 'nôn mửa', 'khó thở']
                ],
                label: '⚠️ COMBO: Đau ngực + Vã mồ hôi + Buồn nôn → Nghi NHỒI MÁU CƠ TIM',
                minMatch: 2,
            },
            // Phù phổi cấp không điển hình
            {
                symptoms: [
                    ['khó thở', 'thở nhanh', 'thở khó'],
                    ['nằm xuống khó thở', 'phù chân', 'chân phù'],
                    ['suy tim', 'tim mạch']
                ],
                label: '⚠️ COMBO: Khó thở + Phù chân → Nghi PHÙ PHỔI / SUY TIM MẤT BÙ',
                minMatch: 2,
            },
            // Septic shock: Sepsis-3 criteria
            {
                symptoms: [
                    ['sốt cao', 'sốt rét run'],
                    ['mạch nhanh', 'tim đập nhanh', 'huyết áp thấp', 'tụt huyết áp'],
                    ['lú lẫn', 'ngủ gà', 'mê man', 'không tỉnh táo']
                ],
                label: '⚠️ COMBO: Sốt + Mạch nhanh + Rối loạn ý thức → Nghi SEPTIC SHOCK',
                minMatch: 2,
            },
            // Đột quỵ không điển hình (FAST criteria)
            {
                symptoms: [
                    ['yếu tay', 'tê tay', 'tê chân', 'yếu chân', 'liệt'],
                    ['nói lắp', 'nói khó', 'không nói được', 'nói ngọng'],
                    ['mặt méo', 'miệng méo', 'mắt lệch']
                ],
                label: '⚠️ COMBO: Yếu/Tê + Nói khó + Méo mặt → Dấu hiệu FAST — Nghi ĐỘT QUỴ',
                minMatch: 2,
            },
            // Chảy máu trong ổ bụng / Vỡ tạng
            {
                symptoms: [
                    ['đau bụng', 'đau bụng dữ'],
                    ['da xanh', 'mặt trắng', 'xanh xao'],
                    ['mạch nhanh', 'huyết áp thấp', 'chóng mặt nặng']
                ],
                label: '⚠️ COMBO: Đau bụng + Da xanh + Mạch nhanh → Nghi XUẤT HUYẾT NỘI',
                minMatch: 2,
            },
        ];

        // Kiểm tra combo rules
        const triggeredCombos: string[] = [];
        COMBO_RULES.forEach(rule => {
            let matchCount = 0;
            for (const symptomGroup of rule.symptoms) {
                const groupMatched = symptomGroup.some(
                    kw => lowerSymptoms.includes(kw) && !isNegated(lowerSymptoms, kw)
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
        // ═══════════════════════════════════════════════════════════════════════
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
            const prefix   = isSevere ? '🔴 CỰC KỲ NGHIÊM TRỌNG' : '🚨';
            criticalAlerts.push(
                `${prefix} [${group.label.toUpperCase()}] Phát hiện: "${matchedKeyword}" — GỌI CẤP CỨU 115 hoặc đến cơ sở y tế NGAY!`
            );
        });

        // Soft warnings — past/hypothetical downgraded
        downgradedGroups.forEach(group => {
            const kw = group.keywords.find(k => kwMatch(lowerSymptomsSafe, lowerSymptomsNorm, k) && isDowngradedContext(k));
            warnings.push(
                `💬 [${group.label}] Phát hiện đề cập "${kw}" trong ngữ cảnh quá khứ hoặc lo ngại. Nếu triệu chứng đang xảy ra hiện tại → GỌI 115 NGAY.`
            );
        });

        // Combo alerts
        triggeredCombos.forEach(combo => {
            criticalAlerts.push(combo + ' — GỌI CẤP CỨU 115 NGAY!');
        });

        // Bệnh nền nguy hiểm → soft warning (không block)
        if (profile.chronicConditions) {
            const dangerousConditions = ['tim mạch', 'suy tim', 'gan', 'thận', 'tiểu đường', 'ung thư', 'hiv', 'ghép tạng'];
            const lowerConditions = profile.chronicConditions.toLowerCase();
            dangerousConditions.forEach(condition => {
                if (lowerConditions.includes(condition)) {
                    warnings.push(
                        `🩺 Bạn có bệnh nền "${condition}": Mọi thuốc đều cần được bác sĩ chuyên khoa phê duyệt.`
                    );
                }
            });
        }

        return {
            isSafe: criticalAlerts.length === 0,
            warnings,
            criticalAlerts,
            missingInfo: []
        };


    }

    /**
     * Kiểm tra tương tác thuốc (drug-drug interaction)
     */
    static checkDrugInteractions(currentMedicines: string[]): string[] {
        const warnings: string[] = [];

        const knownInteractions: Record<string, string[]> = {
            'warfarin': ['aspirin', 'ibuprofen', 'paracetamol liều cao'],
            'aspirin': ['warfarin', 'ibuprofen', 'corticosteroid'],
            'metformin': ['rượu', 'corticosteroid'],
            'digoxin': ['thuốc lợi tiểu', 'corticosteroid'],
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
                                    `⚠️ TƯƠNG TÁC THUỐC: ${med1} có thể tương tác với ${med2}. Cần tham khảo bác sĩ/dược sĩ.`
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
     * PHASE 4: LLM SEMANTIC TRIAGE — Microsoft Azure Health Bot Pattern
     * =================================================================
     *
     * Vấn đề: Keyword matching (dù có 130+ từ) vẫn miss các case diễn đạt
     * không theo khuôn mẫu. Ví dụ:
     *   "đang nằm không dậy được, người xanh lét, gia đình hoảng loạn"
     * → Không từ nào trong keyword list match → System bỏ qua → NGUY HIỂM
     *
     * Giải pháp: Groq LLM làm "Safety Oracle" — hiểu ngữ nghĩa, không chỉ ký tự.
     *
     * Thiết kế:
     *   1. Hard timeout 3s → không bao giờ block pipeline quá lâu
     *   2. Confidence threshold ≥ 0.85 → chỉ block khi LLM chắc chắn
     *   3. Error/timeout → graceful degradation (không crash, không block)
     *   4. Chỉ gọi khi keyword check PASS → không tốn token khi đã block rồi
     *
     * Input format để LLM classify:
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
        const TIMEOUT_MS = 3000; // Hard 3s — không bao giờ block pipeline quá lâu

        const apiKey = process.env.GROQ_API_KEY;
        // Không có API key → graceful skip (không crash)
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
                    temperature: 0.0, // Deterministic — triage phải nhất quán
                    max_tokens:  120, // JSON nhỏ, nhanh
                    response_format: { type: 'json_object' },
                    messages: [
                        {
                            role: 'system',
                            content: `Bạn là hệ thống triage y tế khẩn cấp.
Phân tích mô tả triệu chứng và xác định đây có phải tình trạng cần cấp cứu không.

ĐỊNH NGHĨA CẤP CỨU (TRUE):
- Đe dọa tính mạng ngay lập tức (suy hô hấp, ngừng tim, đột quỵ)
- Tình trạng cần can thiệp y tế trong vòng < 1 giờ
- Mất ý thức, co giật, xuất huyết nặng, ngộ độc

KHÔNG PHẢI CẤP CỨU (FALSE):
- Triệu chứng thông thường (cảm cúm, đau đầu nhẹ, tiêu chảy nhẹ)
- Bệnh mãn tính ổn định
- Triệu chứng kéo dài > 1 tuần mà người đang ổn

NGƯỠNG QUYẾT ĐỊNH: Chỉ isEmergency=true khi confidence ≥ 0.85.
Nếu không chắc → false (tránh false positive).

Output CHỈ JSON:
{"isEmergency":true/false,"confidence":0.0-1.0,"reason":"lý do ngắn gọn","emergencyType":"loại cấp cứu hoặc null"}`,
                        },
                        {
                            role: 'user',
                            content: `Triệu chứng: "${symptoms}"`,
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
            // Timeout hoặc lỗi mạng → KHÔNG block (safety degrades gracefully)
            // Keyword matching vẫn là tuyến phòng thủ chính
            const isTimeout = err.name === 'AbortError';
            console.warn(`[EmergencyTriage LLM] ${isTimeout ? 'Timeout 3s' : err.message} — falling back to keyword only`);
            return { isEmergency: false, confidence: 0, reason: 'LLM unavailable', emergencyType: null };

        } finally {
            clearTimeout(timeoutId);
        }
    }

    /**
     * Comprehensive check — tổng hợp tất cả layers
     */
    static performComprehensiveCheck(
        symptoms: string,
        profile: UserMedicalProfile
    ): SafetyCheckResult {
        const completenessCheck      = this.validateProfileCompleteness(profile);
        const contraindicationCheck  = this.checkContraindications(symptoms, profile);
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
     * Tạo context an toàn để gửi cho AI
     */
    static buildSafeContextForAI(profile: UserMedicalProfile): string {
        const context: string[] = [];

        if (profile.allergies && profile.allergies !== 'Không') {
            context.push(`- Dị ứng: ${profile.allergies}`);
        }
        if (profile.chronicConditions && profile.chronicConditions !== 'Không') {
            context.push(`- Bệnh nền: ${profile.chronicConditions}`);
        }
        if (profile.currentMedicines.length > 0) {
            context.push(`- Đang dùng thuốc: ${profile.currentMedicines.join(', ')}`);
        }
        if (profile.isPregnant)     context.push(`- Thai kỳ: Có`);
        if (profile.isBreastfeeding) context.push(`- Cho con bú: Có`);
        if (profile.age)    context.push(`- Tuổi: ${profile.age}`);
        if (profile.gender) context.push(`- Giới tính: ${profile.gender}`);

        return context.length > 0
            ? `\n\n**THÔNG TIN Y TẾ CỦA NGƯỜI DÙNG:**\n${context.join('\n')}`
            : '';
    }
}

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

        // Rule 3: Triệu chứng nghiêm trọng
        const severeSymptoms = [
            'đau ngực',
            'khó thở',
            'ho ra máu',
            'choáng váng',
            'bất tỉnh',
            'đột quỵ',
            'co giật',
            'sốt cao trên 39',
            'tiêu chảy ra máu',
            'vàng da',
            'đau bụng dữ dội'
        ];

        const lowerSymptoms = symptoms.toLowerCase();
        severeSymptoms.forEach(symptom => {
            if (lowerSymptoms.includes(symptom)) {
                criticalAlerts.push(
                    `⚠️ TRIỆU CHỨNG NGHIÊM TRỌNG PHÁT HIỆN ("${symptom}"): ĐI KHÁM BÁC SĨ NGAY hoặc GỌI CẤP CỨU 115!`
                );
            }
        });

        // Rule 4: Bệnh nền nguy hiểm
        if (profile.chronicConditions) {
            const dangerousConditions = ['tim mạch', 'gan', 'thận', 'tiểu đường', 'ung thư', 'hiv', 'ghép tạng'];
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
     * Simplified version
     */
    static checkDrugInteractions(currentMedicines: string[]): string[] {
        const warnings: string[] = [];

        // Database nhỏ về tương tác phổ biến
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
     * Tổng hợp tất cả kiểm tra an toàn
     */
    static performComprehensiveCheck(
        symptoms: string,
        profile: UserMedicalProfile
    ): SafetyCheckResult {
        // 1. Kiểm tra đầy đủ thông tin
        const completenessCheck = this.validateProfileCompleteness(profile);

        // 2. Kiểm tra chống chỉ định
        const contraindicationCheck = this.checkContraindications(symptoms, profile);

        // 3. Kiểm tra tương tác thuốc
        const drugInteractionWarnings = this.checkDrugInteractions(profile.currentMedicines);

        // Tổng hợp kết quả
        return {
            isSafe: contraindicationCheck.isSafe,
            warnings: [
                ...completenessCheck.warnings, // Chỉ warnings, không block missing info ở đây (logic backend linh hoạt)
                ...contraindicationCheck.warnings,
                ...drugInteractionWarnings
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

        if (profile.isPregnant) {
            context.push(`- Thai kỳ: Có`);
        }

        if (profile.isBreastfeeding) {
            context.push(`- Cho con bú: Có`);
        }

        if (profile.age) {
            context.push(`- Tuổi: ${profile.age}`);
        }

        if (profile.gender) {
            context.push(`- Giới tính: ${profile.gender}`);
        }

        return context.length > 0
            ? `\n\n**THÔNG TIN Y TẾ CỦA NGƯỜI DÙNG:**\n${context.join('\n')}`
            : '';
    }
}

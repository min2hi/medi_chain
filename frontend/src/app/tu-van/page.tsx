'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { ProfileApi, AIApi } from '@/services/api.client';
import { Send, AlertTriangle, CheckCircle, Info, Lock, Loader2 } from 'lucide-react';
import styles from './tu-van.module.css';

type MedicineSuggestion = {
    medicine_name: string;
    dosage: string;
    reason: string;
    note: string;
    safety_check?: string; // Prompt returns this in separate object but let's see logic
};

// Based on Prompt JSON structure
type AIResponse = {
    diagnosis_support?: string;
    analysis?: string; // Fallback
    lifestyle_advice?: string[];
    suggested_medicines?: Array<{
        name: string;
        reason: string;
        safety_check: string;
    }>;
    recommendations?: Array<any>; // Fallback
    warning?: string; // "Cảnh báo quan trọng"
    warnings?: string; // Fallback
};

export default function ConsultationPage() {
    const router = useRouter();
    const [loading, setLoading] = useState(true);
    const [analyzing, setAnalyzing] = useState(false);
    const [showGatekeeper, setShowGatekeeper] = useState(false);
    const [symptoms, setSymptoms] = useState('');
    const [result, setResult] = useState<AIResponse | null>(null);

    // Profile Data for Gatekeeper
    const [profileData, setProfileData] = useState<{
        allergies: string;
        chronicConditions: string;
        isPregnant: boolean;
        isBreastfeeding: boolean;
        birthday: string;
        lastUpdated?: string;
    }>({
        allergies: '',
        chronicConditions: '',
        isPregnant: false,
        isBreastfeeding: false,
        birthday: '',
    });

    useEffect(() => {
        checkProfile();
    }, []);

    const checkProfile = async () => {
        setLoading(true);
        const res = await ProfileApi.get();
        if (res.success && res.data) {
            const p = res.data as any;

            const isMissingInfo =
                !p.allergies ||
                !p.birthday ||
                p.chronicConditions === undefined ||
                p.chronicConditions === null; // Can be empty string if user explicitly says "None"

            // Check last updated (mock logic for now, using updatedAt if available)
            // If lastUpdated > 6 months -> Trigger update
            // For now, simpler logic: If missing critical info -> Gatekeeper

            // If fields are strictly missing from DB (null/undefined), we force update
            // If empty string, we assume user filled it as "None"

            const needsUpdate = !p.birthday || p.chronicConditions == null || p.allergies == null;

            setProfileData({
                allergies: p.allergies || '',
                chronicConditions: p.chronicConditions || '',
                isPregnant: !!p.isPregnant,
                isBreastfeeding: !!p.isBreastfeeding,
                birthday: p.birthday ? new Date(p.birthday).toISOString().slice(0, 10) : '',
                lastUpdated: p.updatedAt,
            });

            if (needsUpdate) {
                setShowGatekeeper(true);
            }
        }
        setLoading(false);
    };

    const handleUpdateProfile = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        const res = await ProfileApi.update({
            allergies: profileData.allergies,
            chronicConditions: profileData.chronicConditions,
            isPregnant: profileData.isPregnant,
            isBreastfeeding: profileData.isBreastfeeding,
            birthday: profileData.birthday,
        });

        if (res.success) {
            setShowGatekeeper(false);
        } else {
            alert(res.message || 'Lỗi cập nhật hồ sơ');
        }
        setLoading(false);
    };

    const handleConsult = async () => {
        window.alert("Bắt đầu tư vấn...");
        console.log("Consultation triggered with symptoms:", symptoms);
        if (!symptoms.trim()) return;
        setAnalyzing(true);
        setResult(null);

        try {
            // Call AI
            console.log("Calling AIApi.consult...");
            const res = await AIApi.consult(symptoms);
            console.log("AI Response received:", res);
            if (res.success) {
                setResult(res.data || res);
            } else {
                alert(res.message || 'Lỗi kết nối AI');
            }
        } catch (err: any) {
            console.error("Error during consultation:", err);
            alert("Lỗi hệ thống: " + err.message);
        } finally {
            setAnalyzing(false);
            console.log("Consultation process finished.");
        }
    };

    if (loading && !showGatekeeper) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <Loader2 className={styles.spinner} size={40} color="#2563eb" />
            </div>
        );
    }

    return (
        <div className={styles.container}>
            <header className={styles.header}>
                <h1 className={styles.title}>Tư vấn thuốc thông minh</h1>
                <p className={styles.subtitle}>Sử dụng AI & Google Search để đưa ra lời khuyên an toàn nhất</p>
            </header>

            <section className={styles.inputSection}>
                <label className={styles.label}>Triệu chứng của bạn là gì?</label>
                <textarea
                    className={styles.textarea}
                    placeholder="Mô tả chi tiết: đau đầu, sốt, ho khan..."
                    value={symptoms}
                    onChange={(e) => setSymptoms(e.target.value)}
                />
                <button
                    className={styles.btnPrimary}
                    onClick={handleConsult}
                    disabled={analyzing || !symptoms.trim()}
                >
                    {analyzing ? (
                        <>
                            <Loader2 className={styles.spinner} size={20} />
                            Đang phân tích...
                        </>
                    ) : (
                        <>
                            <Send size={20} />
                            Phân tích & Tư vấn
                        </>
                    )}
                </button>
            </section>

            {result && (
                <div className={styles.resultSection}>
                    {/* Warning Card (Red) */}
                    {(result.warning || result.warnings) && (
                        <div className={`${styles.card} ${styles.cardRed}`}>
                            <h3 className={styles.cardTitle}>
                                <AlertTriangle size={24} />
                                CẢNH BÁO / LƯU Ý QUAN TRỌNG
                            </h3>
                            <p>{result.warning || result.warnings}</p>
                        </div>
                    )}

                    {/* Lifestyle Advice (Green) */}
                    {(result.lifestyle_advice || []).length > 0 && (
                        <div className={`${styles.card} ${styles.cardGreen}`}>
                            <h3 className={styles.cardTitle}>
                                <CheckCircle size={24} />
                                Lời khuyên lối sống
                            </h3>
                            <ul className={styles.list}>
                                {(result.lifestyle_advice || []).map((ms, idx) => (
                                    <li key={idx} className={styles.listItem}>{ms}</li>
                                ))}
                            </ul>
                        </div>
                    )}

                    {/* Also support 'analysis' field if prompt returns fallback */}
                    {result.analysis && !result.lifestyle_advice && (
                        <div className={`${styles.card} ${styles.cardGreen}`}>
                            <h3 className={styles.cardTitle}>
                                <Info size={24} />
                                Nhận định
                            </h3>
                            <p>{result.analysis}</p>
                        </div>
                    )}

                    {/* Suggested Medicines (Yellow) */}
                    {((result.suggested_medicines && result.suggested_medicines.length > 0) || (result.recommendations && result.recommendations.length > 0)) && (
                        <div className={`${styles.card} ${styles.cardYellow}`}>
                            <h3 className={styles.cardTitle}>
                                <Info size={24} />
                                Gợi ý thuốc OTC (Tham khảo)
                            </h3>

                            {((result.suggested_medicines || result.recommendations) as any[]).map((med, idx) => (
                                <div key={idx} className={styles.medicineItem}>
                                    <span className={styles.medName}>{med.name || med.medicine_name}</span>
                                    <p className={styles.medReason}>{med.reason}</p>
                                    {(med.safety_check || med.note) && (
                                        <span className={styles.medSafety}>
                                            ℹ️ {med.safety_check || med.note}
                                        </span>
                                    )}
                                </div>
                            ))}

                            <p className={styles.disclaimer}>
                                * Dữ liệu được tổng hợp từ Google Search & Hồ sơ y tế của bạn. Vui lòng đọc kỹ hướng dẫn sử dụng trước khi dùng.
                            </p>
                        </div>
                    )}

                    {result.diagnosis_support && (
                        <div className="mt-4 text-gray-600 italic border-t pt-4">
                            <strong>Nhận định sơ bộ:</strong> {result.diagnosis_support}
                        </div>
                    )}
                </div>
            )}

            {/* Gatekeeper Modal */}
            {showGatekeeper && (
                <div className={styles.overlay}>
                    <div className={styles.modal}>
                        <div className={styles.modalHead}>
                            <h2 className={styles.modalTitle}>
                                <Lock className="inline-block mr-2 text-red-500" size={24} />
                                Yêu cầu cập nhật hồ sơ
                            </h2>
                        </div>
                        <div className={styles.modalBody}>
                            <p className={styles.modalDesc}>
                                Để đảm bảo an toàn tuyệt đối khi tư vấn thuốc, chúng tôi cần bạn xác nhận các thông tin y tế quan trọng.
                                Cơ thể bạn có thể đã thay đổi (dị ứng mới, bệnh nền mới...).
                            </p>

                            <form onSubmit={handleUpdateProfile}>
                                <div className={styles.formGroup}>
                                    <label className={styles.formLabel}>Ngày sinh *</label>
                                    <input
                                        type="date"
                                        className={styles.formInput}
                                        required
                                        value={profileData.birthday}
                                        onChange={e => setProfileData({ ...profileData, birthday: e.target.value })}
                                    />
                                </div>

                                <div className={styles.formGroup}>
                                    <label className={styles.formLabel}>Tiền sử dị ứng (Thuốc/Thức ăn) *</label>
                                    <input
                                        type="text"
                                        className={styles.formInput}
                                        placeholder="VD: Penicillin, Tôm... (Ghi 'Không' nếu không có)"
                                        required
                                        value={profileData.allergies}
                                        onChange={e => setProfileData({ ...profileData, allergies: e.target.value })}
                                    />
                                </div>

                                <div className={styles.formGroup}>
                                    <label className={styles.formLabel}>Bệnh mãn tính / Bệnh nền *</label>
                                    <input
                                        type="text"
                                        className={styles.formInput}
                                        placeholder="VD: Dạ dày, Huyết áp... (Ghi 'Không' nếu không có)"
                                        required
                                        value={profileData.chronicConditions}
                                        onChange={e => setProfileData({ ...profileData, chronicConditions: e.target.value })}
                                    />
                                </div>

                                <div className={styles.formGroup}>
                                    <label className={styles.formLabel}>Tình trạng thai sản (Với nữ)</label>
                                    <div className={styles.checkboxGroup}>
                                        <label className="flex items-center gap-2 cursor-pointer">
                                            <input
                                                type="checkbox"
                                                checked={profileData.isPregnant}
                                                onChange={e => setProfileData({ ...profileData, isPregnant: e.target.checked })}
                                            />
                                            <span>Đang mang thai</span>
                                        </label>
                                        <label className="flex items-center gap-2 cursor-pointer ml-4">
                                            <input
                                                type="checkbox"
                                                checked={profileData.isBreastfeeding}
                                                onChange={e => setProfileData({ ...profileData, isBreastfeeding: e.target.checked })}
                                            />
                                            <span>Đang cho con bú</span>
                                        </label>
                                    </div>
                                </div>

                                <button
                                    type="submit"
                                    className={styles.btnPrimary}
                                    disabled={loading}
                                >
                                    {loading ? <Loader2 className={styles.spinner} /> : 'Xác nhận & Tiếp tục'}
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

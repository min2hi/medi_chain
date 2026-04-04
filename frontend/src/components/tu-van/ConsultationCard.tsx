'use client';

import React, { useMemo } from 'react';
import { Pill, AlertTriangle, Activity, CheckCircle2, Info, Star } from 'lucide-react';
import { motion } from 'framer-motion';
import { AIMessage } from '@/services/api.client';

interface RecommendedMedicine {
    name?: string;
    drugName?: string;
    genericName?: string;
    indications?: string;
    sideEffects?: string;
    category?: string;
    finalScore?: number;
    score?: number;
    scores?: { profile: number; safety: number; history: number };
}

interface ConsultationCardProps {
    message: AIMessage;
}

export function ConsultationCard({ message }: ConsultationCardProps) {
    const data = useMemo(() => {
        try {
            // Context từ backend có thể chứa sessionId và rankedDrugs
            const context = message.medicalContext ? JSON.parse(message.medicalContext) : {};

            // Nếu đây là kết quả trực tiếp từ consult API, nó có thể được truyền trực tiếp qua state (xem page.tsx)
            // Hoặc nếu load từ history, medicalContext sẽ chứa tóm tắt.
            return {
                recommendedMedicines: context.rankedDrugs || context.recommendedMedicines || [],
                safetyWarnings: context.safetyWarnings || []
            };
        } catch (e) {
            console.error("Failed to parse consultation data", e);
            return null;
        }
    }, [message]);

    if (!data || (!data.recommendedMedicines.length && !data.safetyWarnings.length)) {
        return null;
    }

    return (
        <div className="mt-6 space-y-6">
            {/* Thuốc gợi ý */}
            {data.recommendedMedicines.length > 0 && (
                <div className="space-y-4">
                    <div className="flex items-center justify-between">
                        <h4 className="flex items-center gap-2 text-[var(--primary)] font-bold text-sm uppercase tracking-widest">
                            <Pill size={18} className="animate-pulse" /> Đề xuất từ MediChain Engine
                        </h4>
                        <span className="text-[10px] font-medium text-[var(--text-muted)] bg-[var(--border)]/30 px-2 py-1 rounded-md">
                            Dựa trên triệu chứng & hồ sơ
                        </span>
                    </div>

                    <div className="grid gap-4">
                        {data.recommendedMedicines.map((med: RecommendedMedicine, idx: number) => (
                            <motion.div
                                key={idx}
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: idx * 0.1 }}
                                className={`group overflow-hidden rounded-2xl border transition-all duration-300 hover:shadow-xl
                                    ${idx === 0
                                        ? 'bg-gradient-to-br from-teal-50/80 to-white dark:from-teal-900/10 dark:to-[var(--surface)] border-teal-200 dark:border-teal-800'
                                        : 'bg-[var(--surface)] border-[var(--border)] hover:border-[var(--primary)]/30'}`}
                            >
                                {/* Rank Ribbon for the winner */}
                                {idx === 0 && (
                                    <div className="bg-teal-500 text-white text-[10px] font-bold px-3 py-1 w-fit rounded-br-xl flex items-center gap-1 shadow-sm">
                                        <Star size={10} fill="white" /> PHÙ HỢP NHẤT
                                    </div>
                                )}

                                <div className="p-5">
                                    <div className="flex items-start justify-between mb-4">
                                        <div>
                                            <h5 className={`text-lg font-bold group-hover:text-[var(--primary)] transition-colors ${idx === 0 ? 'text-teal-700 dark:text-teal-400' : 'text-[var(--text-primary)]'}`}>
                                                {med.name || med.drugName}
                                            </h5>
                                            <p className="text-xs text-[var(--text-muted)] font-medium mt-0.5">
                                                Hoạt chất: {med.genericName}
                                            </p>
                                        </div>
                                        <div className="text-right">
                                            <div className="text-2xl font-black text-[var(--primary)] leading-none italic">
                                                {med.finalScore || med.score}<span className="text-xs font-normal not-italic opacity-60">/100</span>
                                            </div>
                                            <p className="text-[9px] uppercase font-bold tracking-tighter opacity-50 mt-1">Match Score</p>
                                        </div>
                                    </div>

                                    {/* Scores Breakdown */}
                                    {med.scores && (
                                        <div className="grid grid-cols-3 gap-2 mb-4">
                                            {[
                                                { label: 'Hồ sơ', val: med.scores.profile, color: 'bg-blue-500' },
                                                { label: 'An toàn', val: med.scores.safety, color: 'bg-green-500' },
                                                { label: 'Lịch sử', val: med.scores.history, color: 'bg-purple-500' }
                                            ].map((s, i) => (
                                                <div key={i} className="bg-black/5 dark:bg-white/5 p-2 rounded-xl text-center">
                                                    <div className="text-[10px] font-bold text-[var(--text-muted)] uppercase mb-1">{s.label}</div>
                                                    <div className="h-1 w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden mb-1">
                                                        <div className={`h-full ${s.color}`} style={{ width: `${s.val}%` }}></div>
                                                    </div>
                                                    <div className="text-[11px] font-bold text-[var(--text-primary)]">{s.val}</div>
                                                </div>
                                            ))}
                                        </div>
                                    )}

                                    <div className="space-y-2.5 text-sm">
                                        <div className="flex gap-2">
                                            <CheckCircle2 size={14} className="mt-0.5 text-teal-500 flex-shrink-0" />
                                            <p className="text-[var(--text-secondary)]">
                                                <span className="font-semibold text-[var(--text-primary)]">Chỉ định:</span> {med.indications}
                                            </p>
                                        </div>

                                        <div className="flex gap-2">
                                            <Info size={14} className="mt-0.5 text-blue-500 flex-shrink-0" />
                                            <p className="text-[var(--text-secondary)] line-clamp-2 group-hover:line-clamp-none transition-all duration-300">
                                                <span className="font-semibold text-[var(--text-primary)]">Tác dụng phụ:</span> {med.sideEffects}
                                            </p>
                                        </div>
                                    </div>

                                    {/* Action Buttons */}
                                    <div className="mt-5 pt-4 border-t border-[var(--border)] flex justify-between items-center">
                                        <button className="text-[11px] font-bold text-[var(--primary)] hover:underline flex items-center gap-1 uppercase tracking-tight">
                                            Xem chi tiết thuốc
                                        </button>
                                        <div className="flex gap-2">
                                            <span className="px-2 py-1 rounded-lg bg-[var(--primary-light)] text-[var(--primary)] text-[10px] font-bold uppercase">
                                                {med.category}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        ))}
                    </div>
                </div>
            )}

            {/* Cảnh báo an toàn */}
            {data.safetyWarnings && data.safetyWarnings.length > 0 && (
                <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="bg-amber-500/10 border-l-4 border-amber-500 p-5 rounded-r-2xl"
                >
                    <h4 className="flex items-center gap-2 text-amber-600 dark:text-amber-400 font-bold mb-3 text-sm">
                        <AlertTriangle size={18} /> LƯU Ý AN TOÀN QUAN TRỌNG
                    </h4>
                    <div className="space-y-2">
                        {data.safetyWarnings.map((w: string, i: number) => (
                            <div key={i} className="flex gap-2 text-amber-900 dark:text-amber-200/80 text-xs md:text-sm font-medium items-start">
                                <Activity size={14} className="mt-0.5 flex-shrink-0 opacity-50" />
                                <span>{w}</span>
                            </div>
                        ))}
                    </div>
                </motion.div>
            )}

            <div className="px-4 py-3 bg-[var(--surface)] border border-[var(--border)] rounded-xl">
                <p className="text-[11px] text-[var(--text-muted)] leading-relaxed italic text-center">
                    <span className="font-bold underline text-red-500/70">CẢNH BÁO:</span> Kết quả này được tạo bởi thuật toán Recommendation Engine và Dược sĩ AI của MediChain. Chỉ mang tính chất tham khảo. Luôn tham khảo ý kiến bác sĩ chuyên khoa trước khi dùng thuốc.
                </p>
            </div>
        </div>
    );
}


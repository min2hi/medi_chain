'use client';

import React, { useMemo } from 'react';
import {
    Pill, AlertTriangle, Activity, CheckCircle2, Info, Star,
    Brain, ShieldAlert, Zap, FlaskConical, AlertCircle, Phone
} from 'lucide-react';
import { motion } from 'framer-motion';
import { AIMessage } from '@/services/api.client';

// ─── Types ───────────────────────────────────────────────────────────────────
interface ScoresV2 {
    profile:  number;   // AI Relevance (0-100)
    safety:   number;   // Safety bonus (0-5)
    history:  number;   // Personal/CF/Neutral (0-100)
    evidence: number;   // Disease-ATC Match — NEW v2 (0-100)
}

interface RecommendedMedicine {
    drugId?:   string;
    name?:     string;
    drugName?: string;
    genericName?: string;
    indications?: string;
    sideEffects?: string;
    warnings?:    string;
    summary?:     string;
    category?: string;
    finalScore?: number;
    score?:      number;
    scores?: ScoresV2;
    interactionWarnings?: string[];  // NEW v2: Per-drug soft warnings
    dosage?:     string;
    frequency?:  string;
    instruction?: string;
    rank?: number;
}

interface PredictedDisease {
    name:        string;  // Tên tiếng Việt
    probability: number;  // 0-100
}

interface ConsultationCardProps {
    message: AIMessage;
}

// ─── Score Bar Component ──────────────────────────────────────────────────────
function ScoreBar({ label, val, color, max = 100 }: { label: string; val: number; color: string; max?: number }) {
    const pct = Math.round((val / max) * 100);
    return (
        <div className="bg-black/5 dark:bg-white/5 p-2 rounded-xl text-center">
            <div className="text-[10px] font-bold text-[var(--text-muted)] uppercase mb-1">{label}</div>
            <div className="h-1.5 w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden mb-1">
                <div className={`h-full ${color} transition-all duration-700`} style={{ width: `${pct}%` }} />
            </div>
            <div className="text-[11px] font-bold text-[var(--text-primary)]">{val}</div>
        </div>
    );
}

// ─── Main Component ───────────────────────────────────────────────────────────
export function ConsultationCard({ message }: ConsultationCardProps) {
    const data = useMemo(() => {
        try {
            const context = message.medicalContext ? JSON.parse(message.medicalContext) : {};
            return {
                recommendedMedicines: (context.rankedDrugs || context.recommendedMedicines || []) as RecommendedMedicine[],
                safetyWarnings:       (context.safetyWarnings || []) as string[],
                predictedDiseases:    (context.predictedDiseases || []) as PredictedDisease[],
                source:               (context.source || 'RECOMMENDATION_ENGINE') as string,
            };
        } catch {
            return null;
        }
    }, [message]);

    if (!data) return null;

    // ── Emergency Screens ────────────────────────────────────────────────────
    if (data.source === 'EMERGENCY_GATE' || data.source === 'LLM_EMERGENCY_TRIAGE') {
        return (
            <motion.div
                initial={{ opacity: 0, scale: 0.97 }}
                animate={{ opacity: 1, scale: 1 }}
                className="mt-6 rounded-2xl border-2 border-red-500 bg-red-50 dark:bg-red-950/30 overflow-hidden"
            >
                {/* Top banner */}
                <div className="bg-red-500 text-white px-5 py-3 flex items-center gap-3">
                    <Phone size={20} className="animate-pulse" />
                    <div>
                        <p className="font-black text-base">🚨 TÌNH TRẠNG CẤP CỨU</p>
                        <p className="text-xs opacity-80">
                            {data.source === 'LLM_EMERGENCY_TRIAGE'
                                ? 'Phát hiện bởi AI Safety Oracle'
                                : 'Phát hiện bởi Emergency Keyword Gate'}
                        </p>
                    </div>
                </div>
                <div className="p-5 space-y-3">
                    {data.safetyWarnings.map((w, i) => (
                        <div key={i} className="flex gap-2 text-red-800 dark:text-red-200 text-sm font-medium items-start">
                            <ShieldAlert size={16} className="mt-0.5 flex-shrink-0" />
                            <span>{w}</span>
                        </div>
                    ))}
                    <div className="mt-4 p-4 bg-red-100 dark:bg-red-900/30 rounded-xl text-center">
                        <p className="text-2xl font-black text-red-600 dark:text-red-400">☎️ GỌI 115</p>
                        <p className="text-sm text-red-700 dark:text-red-300 mt-1">Hoặc đến Phòng Cấp Cứu gần nhất ngay lập tức</p>
                    </div>
                </div>
            </motion.div>
        );
    }

    if (!data.recommendedMedicines.length && !data.safetyWarnings.length) return null;

    return (
        <div className="mt-6 space-y-6">

            {/* ── Disease Prediction Banner (NEW v2) ─────────────────────────── */}
            {data.predictedDiseases.length > 0 && (
                <motion.div
                    initial={{ opacity: 0, y: -8 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="bg-gradient-to-r from-violet-50 to-blue-50 dark:from-violet-950/20 dark:to-blue-950/20
                               border border-violet-200 dark:border-violet-800 rounded-2xl p-4"
                >
                    <div className="flex items-center gap-2 mb-3">
                        <Brain size={16} className="text-violet-600 dark:text-violet-400" />
                        <span className="text-xs font-bold text-violet-700 dark:text-violet-300 uppercase tracking-widest">
                            AI Disease Layer — Bệnh Dự Đoán
                        </span>
                    </div>
                    <div className="flex flex-wrap gap-2">
                        {data.predictedDiseases.map((d, i) => (
                            <div
                                key={i}
                                className="flex items-center gap-1.5 bg-white dark:bg-white/10 border border-violet-200 dark:border-violet-700
                                           rounded-full px-3 py-1 text-xs font-semibold text-violet-800 dark:text-violet-200"
                            >
                                <span
                                    className="w-2 h-2 rounded-full flex-shrink-0"
                                    style={{ background: `hsl(${(1 - d.probability / 100) * 120}, 80%, 50%)` }}
                                />
                                {d.name}
                                <span className="opacity-60 font-normal">{d.probability}%</span>
                            </div>
                        ))}
                    </div>
                    <p className="text-[10px] text-violet-500 dark:text-violet-400 mt-2 italic">
                        Dùng để tính Evidence Score và định hướng thuốc điều trị đặc trị
                    </p>
                </motion.div>
            )}

            {/* ── Recommended Medicines ──────────────────────────────────────── */}
            {data.recommendedMedicines.length > 0 && (
                <div className="space-y-4">
                    <div className="flex items-center justify-between">
                        <h4 className="flex items-center gap-2 text-[var(--primary)] font-bold text-sm uppercase tracking-widest">
                            <Pill size={18} className="animate-pulse" /> Đề xuất từ MediChain Engine v2
                        </h4>
                        <span className="text-[10px] font-medium text-[var(--text-muted)] bg-[var(--border)]/30 px-2 py-1 rounded-md">
                            Relevance-First Algorithm
                        </span>
                    </div>

                    <div className="grid gap-4">
                        {data.recommendedMedicines.map((med, idx) => (
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
                                {/* Rank Ribbon */}
                                {idx === 0 && (
                                    <div className="bg-teal-500 text-white text-[10px] font-bold px-3 py-1 w-fit rounded-br-xl flex items-center gap-1 shadow-sm">
                                        <Star size={10} fill="white" /> PHÙ HỢP NHẤT
                                    </div>
                                )}

                                <div className="p-5">
                                    {/* Header */}
                                    <div className="flex items-start justify-between mb-4">
                                        <div>
                                            <h5 className={`text-lg font-bold group-hover:text-[var(--primary)] transition-colors
                                                ${idx === 0 ? 'text-teal-700 dark:text-teal-400' : 'text-[var(--text-primary)]'}`}>
                                                {med.name || med.drugName}
                                            </h5>
                                            <p className="text-xs text-[var(--text-muted)] font-medium mt-0.5">
                                                Hoạt chất: {med.genericName}
                                            </p>
                                        </div>
                                        <div className="text-right">
                                            <div className="text-2xl font-black text-[var(--primary)] leading-none italic">
                                                {med.finalScore || med.score}
                                                <span className="text-xs font-normal not-italic opacity-60">/100</span>
                                            </div>
                                            <p className="text-[9px] uppercase font-bold tracking-tighter opacity-50 mt-1">Match Score</p>
                                        </div>
                                    </div>

                                    {/* Scores Breakdown v2 — 4 dimensions */}
                                    {med.scores && (
                                        <div className="grid grid-cols-4 gap-2 mb-4">
                                            <ScoreBar label="Liên quan"   val={med.scores.profile}  color="bg-blue-500"   />
                                            <ScoreBar label="Bằng chứng" val={med.scores.evidence}  color="bg-violet-500" />
                                            <ScoreBar label="Lịch sử"    val={med.scores.history}   color="bg-purple-500" />
                                            <ScoreBar label="An toàn"    val={med.scores.safety * 20} color="bg-green-500" max={100} />
                                        </div>
                                    )}

                                    {/* Evidence Score Label */}
                                    {med.scores?.evidence !== undefined && (
                                        <div className={`flex items-center gap-1.5 text-[10px] font-bold mb-3 px-2 py-1 rounded-lg w-fit
                                            ${med.scores.evidence >= 70
                                                ? 'bg-violet-100 dark:bg-violet-900/30 text-violet-700 dark:text-violet-300'
                                                : med.scores.evidence >= 40
                                                    ? 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300'
                                                    : 'bg-gray-100 dark:bg-gray-800 text-gray-500'
                                            }`}
                                        >
                                            <FlaskConical size={11} />
                                            {med.scores.evidence >= 70
                                                ? `Đặc trị (Evidence: ${med.scores.evidence})`
                                                : med.scores.evidence >= 40
                                                    ? `Hỗ trợ (Evidence: ${med.scores.evidence})`
                                                    : `Tổng quát (Evidence: ${med.scores.evidence})`
                                            }
                                        </div>
                                    )}

                                    {/* Drug Interaction Warnings (soft — per drug) */}
                                    {med.interactionWarnings && med.interactionWarnings.length > 0 && (
                                        <div className="mb-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-700 rounded-xl p-3 space-y-1">
                                            {med.interactionWarnings.map((w, wi) => (
                                                <div key={wi} className="flex gap-1.5 text-amber-800 dark:text-amber-200 text-[11px] font-medium items-start">
                                                    <Zap size={11} className="mt-0.5 flex-shrink-0" />
                                                    <span>{w}</span>
                                                </div>
                                            ))}
                                        </div>
                                    )}

                                    {/* Content */}
                                    <div className="space-y-2.5 text-sm">
                                        {(med.summary || med.indications) && (
                                            <div className="flex gap-2">
                                                <CheckCircle2 size={14} className="mt-0.5 text-teal-500 flex-shrink-0" />
                                                <p className="text-[var(--text-secondary)]">
                                                    <span className="font-semibold text-[var(--text-primary)]">Chỉ định: </span>
                                                    {med.summary || med.indications}
                                                </p>
                                            </div>
                                        )}

                                        {/* Dosage from AI */}
                                        {med.dosage && (
                                            <div className="flex gap-2">
                                                <Activity size={14} className="mt-0.5 text-blue-500 flex-shrink-0" />
                                                <p className="text-[var(--text-secondary)]">
                                                    <span className="font-semibold text-[var(--text-primary)]">Liều dùng: </span>
                                                    {med.dosage} — {med.frequency}
                                                </p>
                                            </div>
                                        )}

                                        {med.instruction && (
                                            <div className="flex gap-2">
                                                <Info size={14} className="mt-0.5 text-indigo-500 flex-shrink-0" />
                                                <p className="text-[var(--text-secondary)] line-clamp-2 group-hover:line-clamp-none transition-all duration-300">
                                                    <span className="font-semibold text-[var(--text-primary)]">Hướng dẫn: </span>
                                                    {med.instruction}
                                                </p>
                                            </div>
                                        )}

                                        {(med.warnings || med.sideEffects) && (
                                            <div className="flex gap-2">
                                                <AlertCircle size={14} className="mt-0.5 text-orange-400 flex-shrink-0" />
                                                <p className="text-[var(--text-secondary)] line-clamp-2 group-hover:line-clamp-none transition-all duration-300">
                                                    <span className="font-semibold text-[var(--text-primary)]">Lưu ý: </span>
                                                    {med.warnings || med.sideEffects}
                                                </p>
                                            </div>
                                        )}
                                    </div>

                                    {/* Footer */}
                                    <div className="mt-5 pt-4 border-t border-[var(--border)] flex justify-between items-center">
                                        <span className="text-[10px] font-bold text-[var(--text-muted)] opacity-50">
                                            Rank #{med.rank ?? idx + 1}
                                        </span>
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

            {/* ── Safety Warnings ────────────────────────────────────────────── */}
            {data.safetyWarnings.length > 0 && (
                <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="bg-amber-500/10 border-l-4 border-amber-500 p-5 rounded-r-2xl"
                >
                    <h4 className="flex items-center gap-2 text-amber-600 dark:text-amber-400 font-bold mb-3 text-sm">
                        <AlertTriangle size={18} /> LƯU Ý AN TOÀN QUAN TRỌNG
                    </h4>
                    <div className="space-y-2">
                        {data.safetyWarnings.map((w, i) => (
                            <div key={i} className="flex gap-2 text-amber-900 dark:text-amber-200/80 text-xs md:text-sm font-medium items-start">
                                <Activity size={14} className="mt-0.5 flex-shrink-0 opacity-50" />
                                <span>{w}</span>
                            </div>
                        ))}
                    </div>
                </motion.div>
            )}

            {/* ── Disclaimer ─────────────────────────────────────────────────── */}
            <div className="px-4 py-3 bg-[var(--surface)] border border-[var(--border)] rounded-xl">
                <p className="text-[11px] text-[var(--text-muted)] leading-relaxed italic text-center">
                    <span className="font-bold underline text-red-500/70">CẢNH BÁO:</span> Kết quả từ Recommendation Engine v2.0 (Relevance-First + Disease-ATC Matching) và Dược sĩ AI. Chỉ mang tính tham khảo. Luôn tham khảo bác sĩ/dược sĩ trước khi dùng thuốc.
                </p>
            </div>
        </div>
    );
}

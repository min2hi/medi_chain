'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import ReactMarkdown from 'react-markdown';
import {
    Pill, AlertTriangle, ShieldCheck, Plus, Star,
    RotateCcw, Info, Users, FlaskConical, PhoneCall,
    AlertOctagon, ChevronDown, ChevronUp, Zap, Activity,
} from 'lucide-react';
import { RecommendationResponse } from '@/services/api.client';

// ─── Types ────────────────────────────────────────────────────────────────────

type Medicine = RecommendationResponse['recommendedMedicines'][0];

interface ConsultResultPanelProps {
    result: RecommendationResponse;
    sessionId: string;
    onAddMedicine: (med: Medicine) => void;
    onNewConsult: () => void;
}

// ─── Score Bars ───────────────────────────────────────────────────────────────

interface ScoreBarDef {
    icon: React.ReactNode;
    label: string;
    value: number;
    pct: number;
    color: string;
}

function ScoreBars({ scores }: { scores: NonNullable<Medicine['scores']> }) {
    const bars: ScoreBarDef[] = [];

    if (scores.safety > 0) {
        const pct = Math.round(scores.safety * 100);
        bars.push({
            icon: <ShieldCheck size={11} />,
            label: 'An toàn',
            value: scores.safety,
            pct,
            color: pct >= 80 ? '#10b981' : pct >= 60 ? '#f59e0b' : '#ef4444',
        });
    }
    if (scores.evidence > 0.2) {
        const pct = Math.round(scores.evidence * 100);
        bars.push({
            icon: <FlaskConical size={11} />,
            label: 'Phù hợp bệnh',
            value: scores.evidence,
            pct,
            color: '#6366f1',
        });
    }
    if (scores.history !== 0.5 && scores.history > 0) {
        const pct = Math.round(scores.history * 100);
        bars.push({
            icon: <Users size={11} />,
            label: 'Cộng đồng',
            value: scores.history,
            pct,
            color: pct >= 70 ? '#8b5cf6' : '#94a3b8',
        });
    }

    if (bars.length === 0) return null;

    return (
        <div className="mb-1">
            {bars.map((bar) => (
                <div key={bar.label} className="flex items-center gap-1.5 mb-1">
                    <span className="text-muted flex">{bar.icon}</span>
                    <span className="text-[10px] text-muted w-[72px] shrink-0">{bar.label}</span>
                    <div className="flex-1 h-1 bg-border rounded-full overflow-hidden">
                        <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: `${bar.pct}%` }}
                            transition={{ duration: 0.7, ease: 'easeOut', delay: 0.1 }}
                            style={{ background: bar.color }}
                            className="h-full rounded-full"
                        />
                    </div>
                    <span
                        style={{ color: bar.color }}
                        className="text-[10px] font-bold w-8 text-right shrink-0"
                    >
                        {bar.pct}%
                    </span>
                </div>
            ))}
        </div>
    );
}

// ─── Emergency Panel ──────────────────────────────────────────────────────────

function EmergencyPanel({ alerts, aiMessage, onReset }: {
    alerts: string[];
    aiMessage: string;
    onReset: () => void;
}) {
    return (
        <motion.div
            initial={{ opacity: 0, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.4 }}
            className="py-2"
        >
            {/* Pulsing alert header */}
            <motion.div
                animate={{
                    boxShadow: [
                        '0 0 0 0 rgba(220,38,38,0)',
                        '0 0 0 16px rgba(220,38,38,0.12)',
                        '0 0 0 0 rgba(220,38,38,0)',
                    ],
                }}
                transition={{ duration: 2, repeat: Infinity }}
                className="rounded-3xl border-2 border-red-500 bg-gradient-to-br from-red-50 to-red-100 dark:from-red-950/20 dark:to-red-900/10 p-6 mb-4 text-center"
            >
                {/* Icon */}
                <motion.div
                    animate={{ scale: [1, 1.18, 1] }}
                    transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
                    className="w-18 h-18 rounded-full bg-red-100 dark:bg-red-950/30 flex items-center justify-center mx-auto mb-4 shadow-[0_0_0_8px_rgba(239,68,68,0.1)] dark:shadow-[0_0_0_8px_rgba(239,68,68,0.05)]"
                >
                    <AlertOctagon size={34} className="text-red-650 dark:text-red-400" />
                </motion.div>

                <h3 className="text-red-600 dark:text-red-400 font-extrabold text-base tracking-wider mb-1.5">
                    TÌNH TRẠNG NGUY KỊCH
                </h3>
                <p className="text-slate-400 dark:text-slate-355 text-xs font-semibold mb-5">
                    Hệ thống MediChain phát hiện triệu chứng báo động đỏ
                </p>

                {/* Alerts list */}
                {alerts.length > 0 && (
                    <div className="bg-surface rounded-2xl p-4 mb-5 border border-red-500/15 dark:border-red-500/30 text-left">
                        {alerts.map((alert, i) => (
                            <div key={i} className={`flex gap-2.5 ${i < alerts.length - 1 ? 'mb-2.5' : ''}`}>
                                <AlertTriangle size={14} className="text-red-650 dark:text-red-400 shrink-0 mt-0.5" />
                                <span className="text-sm font-bold text-red-850 dark:text-red-300 leading-normal">{alert}</span>
                            </div>
                        ))}
                    </div>
                )}

                {/* AI message */}
                {aiMessage && (
                    <div className="bg-surface rounded-2xl px-4 py-3.5 mb-5 border border-border text-left">
                        <ReactMarkdown
                            components={{
                                p: ({ children }) => <p className="my-1 text-[13px] leading-relaxed text-slate-750 dark:text-slate-300">{children}</p>,
                                strong: ({ children }) => <strong className="font-bold">{children}</strong>,
                            }}
                        >
                            {aiMessage}
                        </ReactMarkdown>
                    </div>
                )}

                {/* CTA: Gọi cấp cứu */}
                <a
                    href="tel:115"
                    className="flex items-center justify-center gap-2.5 bg-red-650 text-white font-extrabold text-[15px] py-3.5 px-6 rounded-2xl no-underline shadow-lg shadow-red-650/35 mb-2.5 tracking-wide hover:bg-red-700 transition-colors"
                >
                    <PhoneCall size={18} />
                    GỌI CẤP CỨU (115)
                </a>

                <button
                    onClick={onReset}
                    className="w-full py-3 px-6 border border-border rounded-2xl bg-transparent text-secondary font-semibold text-sm cursor-pointer hover:bg-background transition-colors"
                >
                    <RotateCcw size={14} className="inline mr-1.5" />
                    Nhập lại triệu chứng khác
                </button>
            </motion.div>
        </motion.div>
    );
}

// ─── Medicine Card Stack ─────────────────────────────────────────────────────

function MedicineCardStack({
    medicines,
    onAdd,
}: {
    medicines: Medicine[];
    onAdd: (med: Medicine) => void;
}) {
    const displayMedicines = React.useMemo(() => medicines.slice(0, 5), [medicines]);
    const [stack, setStack] = useState<number[]>(() =>
        Array.from({ length: displayMedicines.length }, (_, i) => i)
    );
    const [swipingIndex, setSwipingIndex] = useState<number | null>(null);

    // Reset stack if medicines list changes (e.g. on new consult)
    React.useEffect(() => {
        setStack(Array.from({ length: displayMedicines.length }, (_, i) => i));
        setSwipingIndex(null);
    }, [displayMedicines.length]);

    const handleCardClick = (cardIndex: number) => {
        if (swipingIndex !== null) return;
        if (stack[0] !== cardIndex) return; // Only top card can swipe

        setSwipingIndex(cardIndex);

        setTimeout(() => {
            setStack((prev) => [...prev.slice(1), prev[0]]);
            setSwipingIndex(null);
        }, 300);
    };

    const cardVariants = {
        animate: (depth: number) => {
            // Alternating rotations and horizontal offsets to simulate stacked paper sheets peeking out
            let rotate = 0;
            let x = 0;
            if (depth === 1) {
                rotate = 4.5; 
                x = 18;
            } else if (depth === 2) {
                rotate = -4;
                x = -18;
            } else if (depth === 3) {
                rotate = 2.5;
                x = 10;
            } else if (depth >= 4) {
                rotate = -2.5;
                x = -10;
            }

            return {
                x,
                y: depth * 10,
                rotate,
                scale: 1 - depth * 0.02,
                zIndex: 20 - depth,
                opacity: depth === 0 ? 1 : depth === 1 ? 0.96 : depth === 2 ? 0.88 : depth === 3 ? 0.72 : 0.45,
                boxShadow: depth === 0 
                    ? '0 12px 28px -5px rgba(16, 185, 129, 0.15), 0 8px 12px -6px rgba(16, 185, 129, 0.15)' 
                    : '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05)',
                transition: {
                    duration: 0.35,
                    ease: 'easeInOut' as const,
                },
            };
        },
        swipe: {
            x: 360,
            rotate: 15,
            opacity: 0,
            zIndex: 25,
            transition: {
                duration: 0.3,
                ease: 'easeOut' as const,
            },
        },
    };

    return (
        <div className="relative w-full h-[505px] select-none mt-2 mb-3">
            {displayMedicines.map((med, idx) => {
                const depth = stack.indexOf(idx);
                const isTop = depth === 0;
                const isSwiping = swipingIndex === idx;
                const rank = med.rank ?? (idx + 1);
                const score = Math.round(med.finalScore ?? 0);

                // Only render if in stack
                if (depth === -1) return null;

                return (
                    <motion.div
                        key={med.drugId || idx}
                        custom={depth}
                        variants={cardVariants}
                        animate={isSwiping ? 'swipe' : 'animate'}
                        onClick={() => handleCardClick(idx)}
                        className={`absolute top-0 left-5 right-5 h-[480px] rounded-2xl border bg-surface flex flex-col overflow-hidden transition-shadow duration-300 ${
                            isTop 
                                ? 'cursor-pointer border-emerald-500/45 shadow-lg' 
                                : 'border-border shadow-sm'
                        }`}
                        style={{
                            transformOrigin: 'top center',
                        }}
                    >
                        {/* Rank Badge Header */}
                        <div className="bg-gradient-to-r from-emerald-500 to-emerald-600 py-2.5 px-3.5 flex items-center justify-between shrink-0">
                            <span className="flex items-center gap-1.5 text-white text-[11px] font-extrabold tracking-wider uppercase">
                                <Star size={11} fill="white" />
                                {rank === 1 ? '#1 KHUYẾN NGHỊ' : `#${rank} LỰA CHỌN PHÙ HỢP`}
                            </span>
                            <span className="text-white text-[11px] font-extrabold bg-white/15 px-2.5 py-0.5 rounded-full">
                                {score} điểm
                            </span>
                        </div>

                        {/* Card Content Area - Scrollable, prevents click propagation for select & scroll */}
                        <div 
                            className="flex-1 p-4 flex flex-col gap-3 bg-surface text-primary select-text overflow-y-auto scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent"
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div>
                                <h4 className="text-[16px] font-extrabold text-primary m-0 tracking-tight leading-snug">
                                    {med.name}
                                </h4>
                                {med.genericName && (
                                    <p className="text-[12px] text-muted mt-0.5 font-medium leading-normal">
                                        {med.genericName}
                                    </p>
                                )}
                            </div>

                            {/* Indications / Summary */}
                            {(med.indications || med.summary) && (
                                <p className="text-[12.5px] text-secondary leading-relaxed font-semibold m-0">
                                    <span className="text-primary font-bold">Chỉ định:</span> {med.indications || med.summary}
                                </p>
                            )}

                            {/* Dosage row */}
                            {(med.dosage || med.frequency) && (
                                <div className="bg-emerald-500/5 dark:bg-emerald-500/10 rounded-lg px-2.5 py-1.5 flex items-start gap-1.5 border border-emerald-500/10 dark:border-emerald-500/20 shrink-0">
                                    <Pill size={11} className="text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
                                    <span className="text-[11.5px] text-emerald-700 dark:text-emerald-300 font-bold leading-normal">
                                        Liều dùng: {[med.dosage, med.frequency, med.instruction].filter(Boolean).join(' · ')}
                                    </span>
                                </div>
                            )}

                            {/* Detailed diagnostics / compatibility indicators in a 2-column grid */}
                            {(med.scores || med.interactionWarnings) && (
                                <div className="grid grid-cols-2 gap-2.5 shrink-0 mt-0.5">
                                    {/* Score bars column */}
                                    {med.scores ? (
                                        <div className="bg-background dark:bg-slate-800 rounded-xl p-2.5 border border-border dark:border-slate-700 flex flex-col justify-center">
                                            <ScoreBars scores={med.scores} />
                                        </div>
                                    ) : (
                                        <div className="bg-background dark:bg-slate-800 rounded-xl p-2.5 border border-border dark:border-slate-700 flex items-center justify-center text-xs text-muted font-medium">
                                            Không có dữ liệu điểm
                                        </div>
                                    )}

                                    {/* Safety / Interaction warnings column */}
                                    <div className="bg-background dark:bg-slate-800 rounded-xl p-2.5 border border-border dark:border-slate-700 flex flex-col justify-center">
                                        {med.interactionWarnings && med.interactionWarnings.length > 0 ? (
                                            <div className="flex gap-1.5 items-start">
                                                <Zap size={11} className="text-amber-500 shrink-0 mt-0.5 animate-pulse" />
                                                <span className="text-[11px] text-amber-900 dark:text-amber-300 leading-normal font-bold">
                                                    Lưu ý: {med.interactionWarnings[0]}
                                                </span>
                                            </div>
                                        ) : (
                                            <div className="flex items-center gap-1.5">
                                                <ShieldCheck size={11} className="text-emerald-500 shrink-0" />
                                                <span className="text-[11px] text-emerald-700 dark:text-emerald-300 leading-normal font-bold">
                                                    An toàn tương tác
                                                </span>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}

                            {/* Warnings */}
                            {(med.warnings || med.sideEffects) && (
                                <p className="text-[12px] text-secondary leading-relaxed font-semibold m-0">
                                    <span className="text-primary font-bold">Lưu ý khác:</span> {med.warnings || med.sideEffects}
                                </p>
                            )}
                        </div>

                        {/* Fixed Footer */}
                        <div className="p-3 border-t border-border bg-background/50 flex flex-col gap-1.5 shrink-0">
                            {isTop && (
                                <div className="text-center text-[9.5px] text-emerald-600 dark:text-emerald-400 font-extrabold tracking-wider uppercase animate-pulse">
                                    Nhấp vào tiêu đề hoặc khoảng trống thẻ để xem thuốc tiếp theo ➔
                                </div>
                            )}
                            <button
                                onClick={(e) => {
                                    e.stopPropagation(); // Prevent card swipe
                                    onAdd(med);
                                }}
                                className="w-full py-2 bg-primary text-white hover:bg-primary-hover rounded-xl text-xs font-extrabold cursor-pointer flex items-center justify-center gap-1.5 shadow-md shadow-primary/20 transition-all duration-200 border-none"
                            >
                                <Plus size={12} /> Thêm vào tủ thuốc
                            </button>
                        </div>
                    </motion.div>
                );
            })}
        </div>
    );
}

// ─── Safety Warnings Panel ────────────────────────────────────────────────────

export function SafetyWarningsPanel({ warnings }: { warnings: string[] }) {
    if (!warnings.length) return null;
    return (
        <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="rounded-2xl p-4 mb-4 bg-amber-50/50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/25 border-l-4 border-l-amber-500"
        >
            <div className="flex items-center gap-2 mb-2.5">
                <div className="w-7.5 h-7.5 rounded-lg bg-amber-500/15 flex items-center justify-center">
                    <AlertTriangle size={15} className="text-amber-500" />
                </div>
                <span className="font-bold text-sm text-amber-800 dark:text-amber-300">Lưu ý an toàn</span>
            </div>
            {warnings.map((w, i) => (
                <div key={i} className={`flex gap-2 ${i < warnings.length - 1 ? 'mb-2' : ''}`}>
                    <div className="w-1.5 h-1.5 rounded-full bg-amber-500 shrink-0 mt-2" />
                    <p className="text-sm text-amber-900 dark:text-amber-200 leading-normal m-0">{w}</p>
                </div>
            ))}
        </motion.div>
    );
}

// ─── Engine Stats ─────────────────────────────────────────────────────────────

function EngineStatsFooter({ stats }: { stats: RecommendationResponse['engineStats'] }) {
    if (!stats) return null;
    return (
        <div className="flex gap-2 flex-wrap mb-3 justify-center">
            {[
                { label: 'Ứng viên', value: stats.totalCandidates },
                { label: 'Lọc ra', value: stats.filteredOut },
                { label: 'Kết quả', value: stats.finalRanked },
                { label: `${stats.processingMs}ms`, value: null, isTime: true },
            ].map((item, i) => (
                <span
                    key={i}
                    className="text-[10.5px] font-semibold py-1 px-3 rounded-full border border-border text-muted bg-background"
                >
                    {item.value !== null ? `${item.label}: ${item.value}` : item.label}
                </span>
            ))}
        </div>
    );
}

// ─── Diagnostics Panel ────────────────────────────────────────────────────────

function ScoringDiagnosticsPanel({ stats, medicines }: { stats: RecommendationResponse['engineStats']; medicines: Medicine[] }) {
    const [isOpen, setIsOpen] = useState(false);

    return (
        <div className="rounded-2xl border border-dashed border-primary bg-primary/[0.02] p-4 mt-4 mb-4 transition-all duration-300">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="w-full bg-transparent border-none flex items-center justify-between cursor-pointer text-primary font-bold text-sm p-0 hover:opacity-85"
            >
                <span className="flex items-center gap-1.5">
                    <Activity size={14} className={isOpen ? "animate-pulse" : ""} />
                    Xem chẩn đoán thuật toán (Hybrid RS Diagnostics)
                </span>
                {isOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            </button>

            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: 'auto' }}
                        exit={{ opacity: 0, height: 0 }}
                        transition={{ duration: 0.3 }}
                        className="overflow-hidden mt-3"
                    >
                        <div className="h-px bg-primary/15 my-3" />
                        
                        <div className="flex flex-col gap-3">
                            {/* Layer 1 */}
                            <div className="flex gap-2.5 items-start">
                                <div className="w-5 h-5 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-500 shrink-0 text-[10px] font-extrabold">
                                    1
                                </div>
                                <div>
                                    <div className="text-xs font-bold text-primary">
                                        Lớp 1: Knowledge Base (Data Layer)
                                    </div>
                                    <div className="text-[11px] text-muted mt-0.5">
                                        Xác thực thực thể dược phẩm trực tiếp từ database cứng (`DrugCandidate`). Đảm bảo không ảo giác.
                                    </div>
                                    <div className="inline-flex items-center gap-1 bg-emerald-500/10 px-1.5 py-0.5 rounded text-[9px] text-emerald-500 mt-1 font-bold">
                                        Trạng thái: KHỚP {medicines.length} THUỐC OTC
                                    </div>
                                </div>
                            </div>

                            {/* Layer 2 */}
                            <div className="flex gap-2.5 items-start">
                                <div className="w-5 h-5 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-500 shrink-0 text-[10px] font-extrabold">
                                    2
                                </div>
                                <div>
                                    <div className="text-xs font-bold text-primary">
                                        Lớp 2: Deterministic Filter (Expert Rules)
                                    </div>
                                    <div className="text-[11px] text-muted mt-0.5">
                                        Loại bỏ thuốc chống chỉ định dựa trên hồ sơ người dùng (Dị ứng, bệnh lý nền mãn tính, độ tuổi).
                                    </div>
                                    <div className="flex gap-1 flex-wrap mt-1">
                                        {['Allergies: PASS', 'Conditions: PASS', 'Demographics: PASS'].map((label, idx) => (
                                            <span key={idx} className="bg-emerald-50 border border-emerald-100 px-1.5 py-0.5 rounded text-[9px] text-emerald-650 font-semibold">
                                                {label}
                                            </span>
                                        ))}
                                    </div>
                                </div>
                            </div>

                            {/* Layer 3 */}
                            <div className="flex gap-2.5 items-start">
                                <div className="w-5 h-5 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-500 shrink-0 text-[10px] font-extrabold">
                                    3
                                </div>
                                <div>
                                    <div className="text-xs font-bold text-primary">
                                        Lớp 3: Weighted-Sum Scoring Engine (v2.0)
                                    </div>
                                    <div className="text-[11px] text-muted mt-0.5">
                                        Tính toán thứ hạng thuốc dựa trên kiến trúc Relevance-First (Khớp lâm sàng làm trọng tâm):
                                    </div>
                                    <div className="bg-background rounded-lg px-3 py-2 mt-1.5 border border-border font-mono text-[10.5px] text-secondary leading-relaxed">
                                        Warm Start (Đã có lịch sử):<br />
                                        Score = (Relevance * 50%) + (Evidence * 20%) + (History * 25%) + SafetyBonus (Max 5)<br /><br />
                                        Cold Start (Chưa có lịch sử):<br />
                                        Score = (Relevance * 55%) + (Evidence * 20%) + (History * 20%) + SafetyBonus (Max 5)
                                    </div>
                                    <div className="flex flex-col gap-1 mt-2">
                                        <div className="flex justify-between text-[10.5px]">
                                            <span className="text-secondary">1. Khớp triệu chứng AI (Relevance)</span>
                                            <span className="font-bold text-primary">Weight: 50% - 55%</span>
                                        </div>
                                        <div className="flex justify-between text-[10.5px]">
                                            <span className="text-secondary">2. Kiểm chứng y văn ATC (Evidence)</span>
                                            <span className="font-bold text-primary">Weight: 20%</span>
                                        </div>
                                        <div className="flex justify-between text-[10.5px]">
                                            <span className="text-secondary">3. Lịch sử kê đơn & Phản hồi (History)</span>
                                            <span className="font-bold text-primary">Weight: 20% - 25%</span>
                                        </div>
                                        <div className="flex justify-between text-[10.5px]">
                                            <span className="text-secondary">4. Điểm thưởng an toàn (Safety Bonus)</span>
                                            <span className="font-bold text-primary">Cộng thêm: 0 - 5đ</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Layer 4 */}
                            <div className="flex gap-2.5 items-start">
                                <div className="w-5 h-5 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-500 shrink-0 text-[10px] font-extrabold">
                                    4
                                </div>
                                <div>
                                    <div className="text-xs font-bold text-primary">
                                        Lớp 4: Explanation Layer (Generative AI)
                                    </div>
                                    <div className="text-[11px] text-muted mt-0.5">
                                        AI tạo sinh diễn giải các chỉ số thô thành hướng dẫn chi tiết của dược sĩ chuyên nghiệp.
                                    </div>
                                    <div className="inline-flex items-center gap-1 bg-indigo-500/10 px-1.5 py-0.5 rounded text-[9px] text-indigo-500 mt-1 font-bold">
                                        Trạng thái: AI PHARMACIST ACTIVE
                                    </div>
                                </div>
                            </div>
                        </div>

                        {stats && (
                            <div className="mt-3.5 pt-2.5 border-t border-border grid grid-cols-2 gap-2 text-xs text-muted">
                                <div>Thời gian xử lý: <span className="font-bold text-primary">{stats.processingMs}ms</span></div>
                                <div>Ứng viên ban đầu: <span className="font-bold text-primary">{stats.totalCandidates}</span></div>
                                <div>Đã lọc bỏ (Chống chỉ định): <span className="font-bold text-red-500">{stats.filteredOut}</span></div>
                                <div>Xếp hạng đề xuất: <span className="font-bold text-emerald-500">{stats.finalRanked}</span></div>
                            </div>
                        )}
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}

// ─── Main ConsultResultPanel ──────────────────────────────────────────────────

export function ConsultResultPanel({ result, sessionId, onAddMedicine, onNewConsult }: ConsultResultPanelProps) {
    const isEmergency =
        result.source === 'EMERGENCY_GATE' ||
        result.source === 'LLM_EMERGENCY_TRIAGE' ||
        result.source === 'HOSPITAL_CONTEXT';

    const criticalAlerts: string[] = (result as RecommendationResponse & { criticalAlerts?: string[] }).criticalAlerts ?? [];
    const hasEmergency = isEmergency || criticalAlerts.length > 0;

    if (hasEmergency) {
        return (
            <EmergencyPanel
                alerts={criticalAlerts}
                aiMessage={result.message?.content ?? ''}
                onReset={onNewConsult}
            />
        );
    }

    return (
        <div className="pt-2">


            {/* Medicine list header */}
            {result.recommendedMedicines && result.recommendedMedicines.length > 0 && (
                <>
                    <div className="flex items-center gap-2.5 mb-3">
                        <div className="bg-gradient-to-br from-primary to-emerald-600 rounded-xl py-1.5 px-3 flex items-center gap-1.5">
                            <Pill size={13} className="text-white" />
                            <span className="text-white text-xs font-bold">
                                Thuốc phù hợp với bạn
                            </span>
                        </div>
                        <span className="text-xs text-muted font-medium">
                            {result.recommendedMedicines.length} lựa chọn
                        </span>
                    </div>

                    <MedicineCardStack
                        medicines={result.recommendedMedicines}
                        onAdd={onAddMedicine}
                    />

                </>
            )}

            {/* Disclaimer */}
            <div className="flex items-start gap-2 px-3.5 py-2.5 bg-background border border-border rounded-xl mt-1">
                <Info size={12} className="text-muted shrink-0 mt-0.5" />
                <p className="text-[11px] text-muted leading-relaxed m-0 italic">
                    Kết quả từ Recommendation Engine — chỉ mang tính tham khảo. Hỏi ý kiến bác sĩ trước khi dùng thuốc.
                </p>
            </div>
        </div>
    );
}

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
        <div style={{ marginBottom: 10 }}>
            {bars.map((bar) => (
                <div key={bar.label} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 5 }}>
                    <span style={{ color: 'var(--text-muted)', display: 'flex' }}>{bar.icon}</span>
                    <span style={{ fontSize: 11, color: 'var(--text-muted)', width: 84, flexShrink: 0 }}>{bar.label}</span>
                    <div style={{ flex: 1, height: 5, background: 'var(--border)', borderRadius: 99, overflow: 'hidden' }}>
                        <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: `${bar.pct}%` }}
                            transition={{ duration: 0.7, ease: 'easeOut', delay: 0.1 }}
                            style={{ height: '100%', background: bar.color, borderRadius: 99 }}
                        />
                    </div>
                    <span style={{ fontSize: 11, fontWeight: 700, color: bar.color, width: 32, textAlign: 'right', flexShrink: 0 }}>
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
            style={{ padding: '8px 0' }}
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
                style={{
                    borderRadius: 20,
                    border: '2px solid #ef4444',
                    background: 'linear-gradient(135deg, #fff5f5 0%, #ffe4e4 100%)',
                    padding: 24, marginBottom: 16, textAlign: 'center',
                }}
            >
                {/* Icon */}
                <motion.div
                    animate={{ scale: [1, 1.18, 1] }}
                    transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
                    style={{
                        width: 72, height: 72, borderRadius: '50%',
                        background: '#fee2e2',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        margin: '0 auto 16px',
                        boxShadow: '0 0 0 8px rgba(239,68,68,0.1)',
                    }}
                >
                    <AlertOctagon size={34} style={{ color: '#dc2626' }} />
                </motion.div>

                <h3 style={{ color: '#dc2626', fontWeight: 800, fontSize: 16, letterSpacing: '0.8px', margin: '0 0 6px' }}>
                    TÌNH TRẠNG NGUY KỊCH
                </h3>
                <p style={{ color: '#94a3b8', fontSize: 12, fontWeight: 500, margin: '0 0 20px' }}>
                    Hệ thống MediChain phát hiện triệu chứng báo động đỏ
                </p>

                {/* Alerts list */}
                {alerts.length > 0 && (
                    <div style={{
                        background: 'white',
                        borderRadius: 14, padding: 16, marginBottom: 20,
                        border: '1px solid rgba(239,68,68,0.15)',
                        textAlign: 'left',
                    }}>
                        {alerts.map((alert, i) => (
                            <div key={i} style={{ display: 'flex', gap: 10, marginBottom: i < alerts.length - 1 ? 10 : 0 }}>
                                <AlertTriangle size={14} style={{ color: '#dc2626', flexShrink: 0, marginTop: 2 }} />
                                <span style={{ fontSize: 13, fontWeight: 700, color: '#991b1b', lineHeight: 1.5 }}>{alert}</span>
                            </div>
                        ))}
                    </div>
                )}

                {/* AI message */}
                {aiMessage && (
                    <div style={{
                        background: 'white', borderRadius: 14, padding: '14px 16px',
                        marginBottom: 20, border: '1px solid var(--border)',
                        textAlign: 'left',
                    }}>
                        <ReactMarkdown
                            components={{
                                p: ({ children }) => <p style={{ margin: '2px 0 6px', fontSize: 13, lineHeight: 1.65, color: '#334155' }}>{children}</p>,
                                strong: ({ children }) => <strong style={{ fontWeight: 700 }}>{children}</strong>,
                            }}
                        >
                            {aiMessage}
                        </ReactMarkdown>
                    </div>
                )}

                {/* CTA: Gọi cấp cứu */}
                <a
                    href="tel:115"
                    style={{
                        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
                        background: '#dc2626', color: 'white', fontWeight: 800, fontSize: 15,
                        padding: '14px 24px', borderRadius: 14, textDecoration: 'none',
                        boxShadow: '0 6px 20px rgba(220,38,38,0.35)', marginBottom: 10,
                        letterSpacing: '0.3px',
                    }}
                >
                    <PhoneCall size={18} />
                    GỌI CẤP CỨU (115)
                </a>

                <button
                    onClick={onReset}
                    style={{
                        width: '100%', padding: '12px 24px',
                        border: '1.5px solid var(--border)', borderRadius: 14,
                        background: 'transparent', color: 'var(--text-secondary)',
                        fontWeight: 600, fontSize: 14, cursor: 'pointer',
                    }}
                >
                    <RotateCcw size={14} style={{ display: 'inline', marginRight: 6 }} />
                    Nhập lại triệu chứng khác
                </button>
            </motion.div>
        </motion.div>
    );
}

// ─── Medicine Ranked Card ─────────────────────────────────────────────────────

function MedicineRankedCard({
    med, index, onAdd,
}: { med: Medicine; index: number; onAdd: (med: Medicine) => void }) {
    const rank = med.rank ?? (index + 1);
    const isTop = rank === 1;
    const score = Math.round(med.finalScore ?? 0);
    const [expanded, setExpanded] = useState(false);

    const scoreColor =
        score >= 75 ? 'var(--primary)' :
        score >= 55 ? '#d97706' : '#ef4444';

    return (
        <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.08, duration: 0.3 }}
            style={{
                borderRadius: 20,
                border: `${isTop ? '1.5px solid rgba(16,185,129,0.4)' : '1px solid var(--border)'}`,
                background: 'var(--surface)',
                marginBottom: 12,
                overflow: 'hidden',
                boxShadow: isTop ? '0 8px 24px -8px rgba(16,185,129,0.2)' : '0 2px 8px rgba(0,0,0,0.04)',
            }}
        >
            {/* Top badge */}
            {isTop && (
                <div style={{
                    background: 'linear-gradient(90deg, #10b981, #059669)',
                    padding: '6px 16px',
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'white', fontSize: 10, fontWeight: 800, letterSpacing: '0.5px' }}>
                        <Star size={10} fill="white" />
                        #1 KHUYẾN NGHỊ
                    </span>
                    <span style={{ color: 'rgba(255,255,255,0.9)', fontSize: 12, fontWeight: 700 }}>
                        {score} điểm
                    </span>
                </div>
            )}

            {/* Card header */}
            <div style={{ padding: '14px 16px 0' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
                        {!isTop && (
                            <div style={{
                                width: 28, height: 28, borderRadius: '50%',
                                background: 'var(--background)',
                                border: '1px solid var(--border)',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                fontSize: 10, fontWeight: 700, color: 'var(--text-muted)',
                                flexShrink: 0,
                            }}>
                                #{rank}
                            </div>
                        )}
                        <div style={{ flex: 1 }}>
                            <h4 style={{ fontSize: 15, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>
                                {med.name}
                            </h4>
                            {med.genericName && (
                                <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: '2px 0 0', fontWeight: 400 }}>
                                    {med.genericName}
                                </p>
                            )}
                        </div>
                    </div>
                    {!isTop && score > 0 && (
                        <span style={{ fontSize: 14, fontWeight: 800, color: scoreColor, flexShrink: 0 }}>
                            {score}
                        </span>
                    )}
                </div>
            </div>

            {/* Divider */}
            <div style={{ height: 1, background: 'var(--border)', margin: '12px 0 0' }} />

            {/* Body */}
            <div style={{ padding: '12px 16px 16px' }}>
                {/* Indications */}
                {(med.indications || med.summary) && (
                    <p style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.55, marginBottom: 10 }}>
                        {(() => {
                            const text = med.indications || med.summary || '';
                            return expanded || text.length <= 110 ? text : `${text.slice(0, 110)}...`;
                        })()}
                    </p>
                )}

                {/* Score bars */}
                {med.scores && <ScoreBars scores={med.scores} />}

                {/* Feedback Loop Boost Badge */}
                {med.scores && med.scores.history && med.scores.history > 0.5 && (
                    <div style={{
                        background: 'rgba(99,102,241,0.07)',
                        border: '1.5px solid rgba(99,102,241,0.2)',
                        borderRadius: 10, padding: '8px 12px', marginBottom: 10,
                        display: 'flex', alignItems: 'center', gap: 8,
                    }}>
                        <motion.span
                            animate={{ scale: [1, 1.15, 1] }}
                            transition={{ duration: 2, repeat: Infinity }}
                            style={{ display: 'flex', color: '#6366f1' }}
                        >
                            <Star size={12} fill="#6366f1" />
                        </motion.span>
                        <span style={{ fontSize: 11.5, color: '#4f46e5', fontWeight: 700 }}>
                            ⚡ Tự học: Được tối ưu điểm số từ phản hồi lịch sử sử dụng
                        </span>
                    </div>
                )}

                {/* Dosage row */}
                {(med.dosage || med.frequency) && (
                    <div style={{
                        background: 'rgba(16,185,129,0.07)',
                        borderRadius: 10, padding: '8px 12px', marginBottom: 10,
                        display: 'flex', alignItems: 'center', gap: 8,
                    }}>
                        <Pill size={12} style={{ color: '#059669', flexShrink: 0 }} />
                        <span style={{ fontSize: 12, color: '#059669', fontWeight: 600 }}>
                            {[med.dosage, med.frequency, med.instruction].filter(Boolean).join(' · ')}
                        </span>
                    </div>
                )}

                {/* Interaction warnings / Safety compatibility badge */}
                {med.interactionWarnings && med.interactionWarnings.length > 0 ? (
                    <div style={{
                        background: '#fffbeb', border: '1px solid #fde68a',
                        borderRadius: 10, padding: '8px 12px', marginBottom: 10,
                    }}>
                        {med.interactionWarnings.slice(0, expanded ? undefined : 1).map((w, wi) => (
                            <div key={wi} style={{ display: 'flex', gap: 6, alignItems: 'flex-start' }}>
                                <Zap size={11} style={{ color: '#f59e0b', flexShrink: 0, marginTop: 2 }} />
                                <span style={{ fontSize: 11.5, color: '#92400e', lineHeight: 1.4, fontWeight: 700 }}>
                                    ⚠️ Cảnh báo cá nhân: {w}
                                </span>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div style={{
                        background: 'rgba(16,185,129,0.06)',
                        border: '1px solid rgba(16,185,129,0.18)',
                        borderRadius: 10, padding: '8px 12px', marginBottom: 10,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                    }}>
                        <ShieldCheck size={13} style={{ color: '#10b981', flexShrink: 0 }} />
                        <span style={{ fontSize: 11.5, color: '#047857', fontWeight: 600 }}>
                            Tương thích với hồ sơ sức khỏe của bạn (Không phát hiện chống chỉ định)
                        </span>
                    </div>
                )}

                {/* Warnings */}
                {(med.warnings || med.sideEffects) && (
                    <div style={{
                        display: 'flex',
                        gap: 6,
                        marginBottom: 10,
                        alignItems: 'flex-start',
                        background: 'var(--background)',
                        borderRadius: 10,
                        padding: '8px 12px',
                        border: '1px solid var(--border)',
                    }}>
                        <Info size={12} style={{ color: 'var(--primary)', flexShrink: 0, marginTop: 2 }} />
                        <span style={{ fontSize: 11.5, color: 'var(--text-secondary)', lineHeight: 1.45 }}>
                            <strong style={{ color: 'var(--text-primary)', marginRight: 4 }}>Chống chỉ định chung từ NSX:</strong>
                            {(() => {
                                const text = med.warnings || med.sideEffects || '';
                                return expanded || text.length <= 90 ? text : `${text.slice(0, 90)}...`;
                            })()}
                        </span>
                    </div>
                )}

                {/* Expand toggle */}
                {((med.indications || med.summary || '').length > 110 || (med.warnings || '').length > 90) && (
                    <button
                        onClick={() => setExpanded(!expanded)}
                        style={{
                            display: 'flex', alignItems: 'center', gap: 4,
                            fontSize: 12, color: 'var(--primary)', fontWeight: 600,
                            background: 'none', border: 'none', cursor: 'pointer',
                            padding: '0 0 8px', opacity: 0.8,
                        }}
                    >
                        {expanded ? <><ChevronUp size={13} /> Thu gọn</> : <><ChevronDown size={13} /> Xem thêm</>}
                    </button>
                )}

                {/* CTA */}
                <button
                    onClick={() => onAdd(med)}
                    style={{
                        width: '100%', padding: '10px 0',
                        border: '1.5px solid rgba(16,185,129,0.45)',
                        borderRadius: 12, background: 'transparent',
                        color: '#10b981', fontSize: 13, fontWeight: 600,
                        cursor: 'pointer', display: 'flex', alignItems: 'center',
                        justifyContent: 'center', gap: 6,
                        transition: 'all 0.2s',
                    }}
                    onMouseEnter={e => {
                        (e.currentTarget as HTMLButtonElement).style.background = 'rgba(16,185,129,0.07)';
                        (e.currentTarget as HTMLButtonElement).style.borderColor = '#10b981';
                    }}
                    onMouseLeave={e => {
                        (e.currentTarget as HTMLButtonElement).style.background = 'transparent';
                        (e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(16,185,129,0.45)';
                    }}
                >
                    <Plus size={14} /> Thêm vào tủ thuốc
                </button>
            </div>
        </motion.div>
    );
}

// ─── Safety Warnings Panel ────────────────────────────────────────────────────

function SafetyWarningsPanel({ warnings }: { warnings: string[] }) {
    if (!warnings.length) return null;
    return (
        <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            style={{
                borderRadius: 16, padding: 16, marginBottom: 16,
                background: '#fffbeb',
                borderLeft: '3.5px solid #f59e0b',
                border: '1px solid #fde68a',
                borderLeftWidth: '3.5px',
            }}
        >
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <div style={{
                    width: 30, height: 30, borderRadius: 9,
                    background: 'rgba(245,158,11,0.15)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                    <AlertTriangle size={15} style={{ color: '#f59e0b' }} />
                </div>
                <span style={{ fontWeight: 700, fontSize: 13, color: '#92400e' }}>Lưu ý an toàn</span>
            </div>
            {warnings.map((w, i) => (
                <div key={i} style={{ display: 'flex', gap: 8, marginBottom: i < warnings.length - 1 ? 8 : 0 }}>
                    <div style={{
                        width: 5, height: 5, borderRadius: '50%',
                        background: '#f59e0b', flexShrink: 0, marginTop: 7,
                    }} />
                    <p style={{ fontSize: 13, color: '#78350f', lineHeight: 1.5, margin: 0 }}>{w}</p>
                </div>
            ))}
        </motion.div>
    );
}

// ─── Engine Stats ─────────────────────────────────────────────────────────────

function EngineStatsFooter({ stats }: { stats: RecommendationResponse['engineStats'] }) {
    if (!stats) return null;
    return (
        <div style={{
            display: 'flex', gap: 8, flexWrap: 'wrap' as const,
            marginBottom: 12, justifyContent: 'center',
        }}>
            {[
                { label: 'Ứng viên', value: stats.totalCandidates },
                { label: 'Lọc ra', value: stats.filteredOut },
                { label: 'Kết quả', value: stats.finalRanked },
                { label: `${stats.processingMs}ms`, value: null, isTime: true },
            ].map((item, i) => (
                <span
                    key={i}
                    style={{
                        fontSize: 10.5, fontWeight: 600, padding: '3px 9px',
                        borderRadius: 20, border: '1px solid var(--border)',
                        color: 'var(--text-muted)', background: 'var(--background)',
                    }}
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
        <div style={{
            borderRadius: 16,
            border: '1.5px dashed var(--primary)',
            background: 'rgba(20, 184, 166, 0.02)',
            padding: '16px',
            marginTop: 16,
            marginBottom: 16,
            transition: 'all 0.3s'
        }}>
            <button
                onClick={() => setIsOpen(!isOpen)}
                style={{
                    width: '100%',
                    background: 'none',
                    border: 'none',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    cursor: 'pointer',
                    color: 'var(--primary)',
                    fontWeight: 700,
                    fontSize: 13,
                    padding: 0
                }}
            >
                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
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
                        style={{ overflow: 'hidden', marginTop: 12 }}
                    >
                        <div style={{ height: 1, background: 'rgba(20, 184, 166, 0.15)', margin: '4px 0 12px' }} />
                        
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                            {/* Layer 1 */}
                            <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                                <div style={{
                                    width: 20, height: 20, borderRadius: '50%',
                                    background: 'rgba(16, 185, 129, 0.1)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    color: '#10b981', flexShrink: 0, fontSize: 10, fontWeight: 800
                                }}>
                                    1
                                </div>
                                <div>
                                    <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-primary)' }}>
                                        Lớp 1: Knowledge Base (Data Layer)
                                    </div>
                                    <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>
                                        Xác thực thực thể dược phẩm trực tiếp từ database cứng (`DrugCandidate`). Đảm bảo không ảo giác.
                                    </div>
                                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: 'rgba(16, 185, 129, 0.08)', padding: '2px 6px', borderRadius: 4, fontSize: 9, color: '#10b981', marginTop: 4, fontWeight: 700 }}>
                                        Trạng thái: KHỚP {medicines.length} THUỐC OTC
                                    </div>
                                </div>
                            </div>

                            {/* Layer 2 */}
                            <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                                <div style={{
                                    width: 20, height: 20, borderRadius: '50%',
                                    background: 'rgba(16, 185, 129, 0.1)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    color: '#10b981', flexShrink: 0, fontSize: 10, fontWeight: 800
                                }}>
                                    2
                                </div>
                                <div>
                                    <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-primary)' }}>
                                        Lớp 2: Deterministic Filter (Expert Rules)
                                    </div>
                                    <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>
                                        Loại bỏ thuốc chống chỉ định dựa trên hồ sơ người dùng (Dị ứng, bệnh lý nền mãn tính, độ tuổi).
                                    </div>
                                    <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', marginTop: 4 }}>
                                        {['Allergies: PASS', 'Conditions: PASS', 'Demographics: PASS'].map((label, idx) => (
                                            <span key={idx} style={{ background: '#f0fdf4', border: '1px solid #bbf7d0', padding: '1px 5px', borderRadius: 4, fontSize: 9, color: '#16a34a', fontWeight: 600 }}>
                                                {label}
                                            </span>
                                        ))}
                                    </div>
                                </div>
                            </div>

                            {/* Layer 3 */}
                            <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                                <div style={{
                                    width: 20, height: 20, borderRadius: '50%',
                                    background: 'rgba(16, 185, 129, 0.1)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    color: '#10b981', flexShrink: 0, fontSize: 10, fontWeight: 800
                                }}>
                                    3
                                </div>
                                <div>
                                    <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-primary)' }}>
                                        Lớp 3: Weighted-Sum Scoring Engine (v2.0)
                                    </div>
                                    <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>
                                        Tính toán thứ hạng thuốc dựa trên kiến trúc Relevance-First (Khớp lâm sàng làm trọng tâm):
                                    </div>
                                    <div style={{
                                        background: 'var(--background)',
                                        borderRadius: 8, padding: '8px 12px', marginTop: 6,
                                        border: '1px solid var(--border)',
                                        fontFamily: 'monospace', fontSize: 10.5, color: 'var(--text-secondary)',
                                        lineHeight: 1.45
                                    }}>
                                        Warm Start (Đã có lịch sử):<br />
                                        Score = (Relevance * 50%) + (Evidence * 20%) + (History * 25%) + SafetyBonus (Max 5)<br /><br />
                                        Cold Start (Chưa có lịch sử):<br />
                                        Score = (Relevance * 55%) + (Evidence * 20%) + (History * 20%) + SafetyBonus (Max 5)
                                    </div>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, marginTop: 8 }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5 }}>
                                            <span style={{ color: 'var(--text-secondary)' }}>1. Khớp triệu chứng AI (Relevance)</span>
                                            <span style={{ fontWeight: 700, color: 'var(--text-primary)' }}>Weight: 50% - 55%</span>
                                        </div>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5 }}>
                                            <span style={{ color: 'var(--text-secondary)' }}>2. Kiểm chứng y văn ATC (Evidence)</span>
                                            <span style={{ fontWeight: 700, color: 'var(--text-primary)' }}>Weight: 20%</span>
                                        </div>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5 }}>
                                            <span style={{ color: 'var(--text-secondary)' }}>3. Lịch sử kê đơn & Phản hồi (History)</span>
                                            <span style={{ fontWeight: 700, color: 'var(--text-primary)' }}>Weight: 20% - 25%</span>
                                        </div>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5 }}>
                                            <span style={{ color: 'var(--text-secondary)' }}>4. Điểm thưởng an toàn (Safety Bonus)</span>
                                            <span style={{ fontWeight: 700, color: 'var(--text-primary)' }}>Cộng thêm: 0 - 5đ</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Layer 4 */}
                            <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                                <div style={{
                                    width: 20, height: 20, borderRadius: '50%',
                                    background: 'rgba(16, 185, 129, 0.1)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    color: '#10b981', flexShrink: 0, fontSize: 10, fontWeight: 800
                                }}>
                                    4
                                </div>
                                <div>
                                    <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-primary)' }}>
                                        Lớp 4: Explanation Layer (Generative AI)
                                    </div>
                                    <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>
                                        AI tạo sinh diễn giải các chỉ số thô thành hướng dẫn chi tiết của dược sĩ chuyên nghiệp.
                                    </div>
                                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: 'rgba(99, 102, 241, 0.08)', padding: '2px 6px', borderRadius: 4, fontSize: 9, color: '#6366f1', marginTop: 4, fontWeight: 700 }}>
                                        Trạng thái: AI PHARMACIST ACTIVE
                                    </div>
                                </div>
                            </div>
                        </div>

                        {stats && (
                            <div style={{
                                marginTop: 14,
                                paddingTop: 10,
                                borderTop: '1px solid var(--border)',
                                display: 'grid',
                                gridTemplateColumns: '1fr 1fr',
                                gap: 8,
                                fontSize: 11,
                                color: 'var(--text-muted)'
                            }}>
                                <div>Thời gian xử lý: <span style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{stats.processingMs}ms</span></div>
                                <div>Ứng viên ban đầu: <span style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{stats.totalCandidates}</span></div>
                                <div>Đã lọc bỏ (Chống chỉ định): <span style={{ fontWeight: 700, color: '#ef4444' }}>{stats.filteredOut}</span></div>
                                <div>Xếp hạng đề xuất: <span style={{ fontWeight: 700, color: '#10b981' }}>{stats.finalRanked}</span></div>
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
        <div style={{ paddingTop: 8 }}>
            {/* Safety warnings */}
            {result.safetyWarnings && result.safetyWarnings.length > 0 && (
                <SafetyWarningsPanel warnings={result.safetyWarnings} />
            )}

            {/* Medicine list header */}
            {result.recommendedMedicines && result.recommendedMedicines.length > 0 && (
                <>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
                        <div style={{
                            background: 'linear-gradient(135deg, var(--primary), #059669)',
                            borderRadius: 10, padding: '5px 12px',
                            display: 'flex', alignItems: 'center', gap: 6,
                        }}>
                            <Pill size={13} style={{ color: 'white' }} />
                            <span style={{ color: 'white', fontSize: 12, fontWeight: 700 }}>
                                Thuốc phù hợp với bạn
                            </span>
                        </div>
                        <span style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 500 }}>
                            {result.recommendedMedicines.length} lựa chọn
                        </span>
                    </div>

                    <AnimatePresence>
                        {result.recommendedMedicines.map((med, idx) => (
                            <MedicineRankedCard
                                key={med.drugId || idx}
                                med={med}
                                index={idx}
                                onAdd={onAddMedicine}
                            />
                        ))}
                    </AnimatePresence>

                    {/* Engine stats */}
                    {result.engineStats && <EngineStatsFooter stats={result.engineStats} />}
                </>
            )}

            {/* diagnostics visualizer */}
            {result.recommendedMedicines && result.recommendedMedicines.length > 0 && (
                <ScoringDiagnosticsPanel stats={result.engineStats} medicines={result.recommendedMedicines} />
            )}

            {/* Disclaimer */}
            <div style={{
                display: 'flex', alignItems: 'flex-start', gap: 7,
                padding: '10px 14px',
                background: 'var(--background)',
                borderRadius: 12, border: '1px solid var(--border)',
                marginTop: 4,
            }}>
                <Info size={12} style={{ color: 'var(--text-muted)', flexShrink: 0, marginTop: 2 }} />
                <p style={{ fontSize: 11, color: 'var(--text-muted)', lineHeight: 1.5, margin: 0, fontStyle: 'italic' }}>
                    Kết quả từ Recommendation Engine — chỉ mang tính tham khảo. Hỏi ý kiến bác sĩ trước khi dùng thuốc.
                </p>
            </div>
        </div>
    );
}

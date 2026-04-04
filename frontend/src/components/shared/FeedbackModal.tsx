'use client';

import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Star, X, Loader2, CheckCircle2, AlertTriangle, ThumbsUp, ThumbsDown, Minus, RefreshCw } from 'lucide-react';
import { RecommendationApi } from '@/services/api.client';

// ─── Types ────────────────────────────────────────────────────────────────────

type FeedbackOutcome =
    | 'EFFECTIVE'
    | 'PARTIALLY_EFFECTIVE'
    | 'NOT_EFFECTIVE'
    | 'SIDE_EFFECT'
    | 'NOT_TAKEN';

export interface FeedbackDrug {
    drugId: string;
    drugName: string;
}

interface FeedbackModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess?: () => void;
    sessionId: string;
    drugs: FeedbackDrug[];
}

// ─── Outcome options ──────────────────────────────────────────────────────────

const OUTCOMES: { value: FeedbackOutcome; label: string; icon: React.ReactNode; color: string; bg: string }[] = [
    { value: 'EFFECTIVE',           label: 'Hiệu quả',               icon: <ThumbsUp size={15} />,    color: '#16a34a', bg: 'rgba(22,163,74,0.08)' },
    { value: 'PARTIALLY_EFFECTIVE', label: 'Có tác dụng một phần',   icon: <Minus size={15} />,       color: '#d97706', bg: 'rgba(217,119,6,0.08)' },
    { value: 'NOT_EFFECTIVE',       label: 'Không hiệu quả',         icon: <ThumbsDown size={15} />,  color: '#dc2626', bg: 'rgba(220,38,38,0.08)' },
    { value: 'SIDE_EFFECT',         label: 'Bị tác dụng phụ',        icon: <AlertTriangle size={15}/>,color: '#7c3aed', bg: 'rgba(124,58,237,0.08)' },
    { value: 'NOT_TAKEN',           label: 'Không dùng thuốc này',   icon: <X size={15} />,           color: '#6b7280', bg: 'rgba(107,114,128,0.08)' },
];

// ─── Component ────────────────────────────────────────────────────────────────

export function FeedbackModal({ isOpen, onClose, onSuccess, sessionId, drugs }: FeedbackModalProps) {
    const [mounted, setMounted] = useState(false);
    const [selectedDrugId, setSelectedDrugId] = useState<string>(drugs[0]?.drugId ?? '');
    const [outcome, setOutcome] = useState<FeedbackOutcome | null>(null);
    const [rating, setRating] = useState(0);
    const [hoverRating, setHoverRating] = useState(0);
    const [note, setNote] = useState('');
    const [sideEffect, setSideEffect] = useState('');
    const [loading, setLoading] = useState(false);
    const [fetchLoading, setFetchLoading] = useState(false);
    const [submitted, setSubmitted] = useState(false);
    const [isUpdate, setIsUpdate] = useState(false); // true = đang cập nhật đánh giá cũ
    const [error, setError] = useState('');

    // Portal cần mounted ở client
    useEffect(() => {
        setMounted(true);
        return () => setMounted(false);
    }, []);

    // Khoá scroll khi mở
    useEffect(() => {
        if (isOpen) document.body.style.overflow = 'hidden';
        else document.body.style.overflow = '';
        return () => { document.body.style.overflow = ''; };
    }, [isOpen]);

    // Khi modal mở (và chưa submit): tự động lấy feedback hiện có (nếu có) để pre-fill
    // Guard: không chạy lại sau khi đã submit (để màn hình Cảm ơn không bị xóa)
    useEffect(() => {
        if (!isOpen || !selectedDrugId || !sessionId || submitted) return;

        const fetchExisting = async () => {
            setFetchLoading(true);
            try {
                const res = await RecommendationApi.getFeedback(sessionId, selectedDrugId);
                if (res.success !== false && res.data) {
                    const existing = res.data;
                    setRating(existing.rating ?? 0);
                    setOutcome((existing.outcome as FeedbackOutcome) ?? null);
                    setSideEffect(existing.sideEffect ?? '');
                    setNote(existing.note ?? '');
                    setIsUpdate(true);
                } else {
                    setRating(0);
                    setOutcome(null);
                    setSideEffect('');
                    setNote('');
                    setIsUpdate(false);
                }
            } catch {
                // Silent fail — không ảnh hưởng UX
            } finally {
                setFetchLoading(false);
            }
        };

        fetchExisting();
    // Chỉ chạy khi modal mở lần đầu hoặc drug thay đổi, tuyệt đối KHÔNG chạy lại sau submitted=true
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [isOpen, selectedDrugId, sessionId]);

    const canSubmit = selectedDrugId && outcome && rating > 0 && !loading;

    const handleSubmit = async () => {
        if (!canSubmit) return;
        setError('');
        setLoading(true);
        try {
            const res = await RecommendationApi.submitFeedback({
                sessionId,
                drugId: selectedDrugId,
                rating,
                outcome: outcome!,
                sideEffect: sideEffect.trim() || undefined,
                note: note.trim() || undefined,
            });

            if (res.success !== false) {
                setSubmitted(true);
                onSuccess?.();
            } else {
                setError(res.message || 'Gửi phản hồi thất bại, vui lòng thử lại.');
            }
        } catch {
            setError('Lỗi kết nối, vui lòng thử lại.');
        } finally {
            setLoading(false);
        }
    };

    const handleClose = () => {
        setSelectedDrugId(drugs[0]?.drugId ?? '');
        setOutcome(null);
        setRating(0);
        setHoverRating(0);
        setNote('');
        setSideEffect('');
        setError('');
        setSubmitted(false);
        setIsUpdate(false);
        onClose();
    };

    if (!mounted || !isOpen) return null;

    return createPortal(
        <div
            onClick={handleClose}
            style={{
                position: 'fixed',
                inset: 0,
                width: '100vw',
                height: '100vh',
                background: 'rgba(0,0,0,0.8)',
                backdropFilter: 'blur(10px)',
                WebkitBackdropFilter: 'blur(10px)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                zIndex: 2147483647,
                padding: 20,
                animation: 'fadeInOverlay 0.25s ease-out',
            }}
        >
            <div
                onClick={(e) => e.stopPropagation()}
                style={{
                    width: '100%',
                    maxWidth: 500,
                    maxHeight: '88vh',
                    overflowY: 'auto',
                    background: 'var(--surface)',
                    border: '1px solid var(--border)',
                    borderRadius: 20,
                    boxShadow: '0 32px 64px -16px rgba(0,0,0,0.5)',
                    animation: 'slideUpPanel 0.25s ease-out',
                }}
            >
                {submitted ? (
                    /* ── Màn hình Cảm ơn ── */
                    <div style={{ padding: '48px 32px', textAlign: 'center', animation: 'fadeIn 0.4s ease-out' }}>
                        <div style={{
                            width: 80, height: 80, borderRadius: '24px',
                            background: 'linear-gradient(135deg, rgba(22,163,74,0.2) 0%, rgba(22,163,74,0.05) 100%)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            margin: '0 auto 24px',
                            boxShadow: '0 8px 16px -4px rgba(22,163,74,0.2)',
                        }}>
                            <CheckCircle2 size={40} color="#16a34a" strokeWidth={2.5} />
                        </div>
                        <h4 style={{ fontSize: 24, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 8px', letterSpacing: '-0.5px' }}>
                            {isUpdate ? 'Đã cập nhật!' : 'Cảm ơn bạn!'}
                        </h4>
                        <p style={{ fontSize: 15, color: 'var(--text-muted)', lineHeight: 1.6, margin: '0 auto 32px', maxWidth: 300 }}>
                            {isUpdate
                                ? 'Đánh giá của bạn đã được cập nhật. Hệ thống sẽ điều chỉnh gợi ý phù hợp hơn.'
                                : 'Phản hồi của bạn đã được ghi nhận thành công. Hệ thống sẽ học hỏi để tư vấn tốt hơn cho bạn.'}
                        </p>
                        <button
                            onClick={handleClose}
                            style={{
                                padding: '14px 48px', borderRadius: 16,
                                background: 'var(--primary)', color: 'white',
                                border: 'none', fontWeight: 700, fontSize: 15,
                                cursor: 'pointer',
                                boxShadow: '0 10px 15px -3px rgba(var(--primary-rgb),0.3)',
                                transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                            }}
                            onMouseEnter={(e) => {
                                e.currentTarget.style.transform = 'translateY(-2px)';
                                e.currentTarget.style.boxShadow = '0 12px 20px -3px rgba(var(--primary-rgb),0.4)';
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.transform = 'translateY(0)';
                                e.currentTarget.style.boxShadow = '0 10px 15px -3px rgba(var(--primary-rgb),0.3)';
                            }}
                        >
                            Hoàn tất
                        </button>
                    </div>
                ) : (
                    <>
                        {/* ── Header ── */}
                        <div style={{
                            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                            padding: '18px 22px',
                            borderBottom: '1px solid var(--border)',
                        }}>
                            <div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                    <h3 style={{ fontSize: 16, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>
                                        {isUpdate ? 'Cập nhật đánh giá' : 'Đánh giá hiệu quả thuốc'}
                                    </h3>
                                    {isUpdate && (
                                        <span style={{
                                            display: 'inline-flex', alignItems: 'center', gap: 4,
                                            padding: '2px 8px', borderRadius: 20,
                                            background: 'rgba(var(--primary-rgb),0.1)',
                                            color: 'var(--primary)', fontSize: 11, fontWeight: 600,
                                        }}>
                                            <RefreshCw size={10} /> Đã đánh giá
                                        </span>
                                    )}
                                </div>
                                <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: '3px 0 0' }}>
                                    {isUpdate
                                        ? 'Bạn có thể điều chỉnh lại đánh giá của mình'
                                        : 'Phản hồi của bạn giúp hệ thống tư vấn tốt hơn'}
                                </p>
                            </div>
                            <button
                                onClick={handleClose}
                                style={{
                                    width: 32, height: 32, borderRadius: 8,
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    background: 'transparent', border: '1px solid var(--border)',
                                    cursor: 'pointer', color: 'var(--text-muted)', flexShrink: 0,
                                }}
                            >
                                <X size={16} />
                            </button>
                        </div>

                        {/* ── Body ── */}
                        <div style={{ padding: '22px' }}>
                            {fetchLoading ? (
                                /* Loading khi đang tải dữ liệu cũ */
                                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '40px 0', gap: 12 }}>
                                    <Loader2 size={28} style={{ animation: 'spin 1s linear infinite', color: 'var(--primary)' }} />
                                    <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: 0 }}>Đang tải đánh giá của bạn...</p>
                                </div>
                            ) : (
                                <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
                                    {/* Banner cảnh báo nếu đang update */}
                                    {isUpdate && (
                                        <div style={{
                                            display: 'flex', alignItems: 'flex-start', gap: 10,
                                            padding: '12px 14px', borderRadius: 12,
                                            background: 'rgba(var(--primary-rgb),0.06)',
                                            border: '1px solid rgba(var(--primary-rgb),0.15)',
                                        }}>
                                            <RefreshCw size={15} style={{ color: 'var(--primary)', flexShrink: 0, marginTop: 1 }} />
                                            <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0, lineHeight: 1.5 }}>
                                                Bạn đã đánh giá thuốc này trước đó. Form đã được điền sẵn — điều chỉnh và nhấn <strong>Cập nhật</strong> để lưu thay đổi.
                                            </p>
                                        </div>
                                    )}

                                    {/* Chọn thuốc (nếu nhiều hơn 1) */}
                                    {drugs.length > 1 && (
                                        <div>
                                            <Label>Thuốc cần đánh giá</Label>
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                                                {drugs.map((d) => (
                                                    <button
                                                        key={d.drugId}
                                                        type="button"
                                                        onClick={() => setSelectedDrugId(d.drugId)}
                                                        style={{
                                                            padding: '10px 14px', borderRadius: 10,
                                                            border: `1.5px solid ${selectedDrugId === d.drugId ? 'var(--primary)' : 'var(--border)'}`,
                                                            background: selectedDrugId === d.drugId ? 'rgba(var(--primary-rgb),0.06)' : 'transparent',
                                                            color: 'var(--text-primary)', textAlign: 'left',
                                                            cursor: 'pointer', fontWeight: selectedDrugId === d.drugId ? 600 : 400,
                                                            fontSize: 14, transition: 'all 0.15s',
                                                        }}
                                                    >
                                                        {d.drugName}
                                                    </button>
                                                ))}
                                            </div>
                                        </div>
                                    )}

                                    {/* Đánh giá sao */}
                                    <div>
                                        <Label>Mức độ hài lòng</Label>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                            {[1, 2, 3, 4, 5].map((s) => (
                                                <button
                                                    key={s}
                                                    type="button"
                                                    onClick={() => setRating(s)}
                                                    onMouseEnter={() => setHoverRating(s)}
                                                    onMouseLeave={() => setHoverRating(0)}
                                                    style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2 }}
                                                >
                                                    <Star
                                                        size={28}
                                                        fill={(hoverRating || rating) >= s ? '#f59e0b' : 'transparent'}
                                                        color={(hoverRating || rating) >= s ? '#f59e0b' : 'var(--border)'}
                                                        strokeWidth={1.5}
                                                        style={{ transition: 'all 0.1s', display: 'block' }}
                                                    />
                                                </button>
                                            ))}
                                            {rating > 0 && (
                                                <span style={{ fontSize: 12, color: 'var(--text-muted)', marginLeft: 4 }}>
                                                    {['', 'Rất tệ', 'Tệ', 'Bình thường', 'Tốt', 'Rất tốt'][rating]}
                                                </span>
                                            )}
                                        </div>
                                    </div>

                                    {/* Kết quả điều trị */}
                                    <div>
                                        <Label>Kết quả điều trị</Label>
                                        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                                            {OUTCOMES.map((o) => (
                                                <button
                                                    key={o.value}
                                                    type="button"
                                                    onClick={() => setOutcome(o.value)}
                                                    style={{
                                                        padding: '10px 14px', borderRadius: 10,
                                                        border: `1.5px solid ${outcome === o.value ? o.color : 'var(--border)'}`,
                                                        background: outcome === o.value ? o.bg : 'transparent',
                                                        color: outcome === o.value ? o.color : 'var(--text-secondary)',
                                                        display: 'flex', alignItems: 'center', gap: 9,
                                                        cursor: 'pointer', fontWeight: outcome === o.value ? 600 : 400,
                                                        fontSize: 14, textAlign: 'left', transition: 'all 0.12s',
                                                    }}
                                                >
                                                    {o.icon} {o.label}
                                                </button>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Tác dụng phụ (chỉ hiện khi chọn SIDE_EFFECT) */}
                                    {outcome === 'SIDE_EFFECT' && (
                                        <div>
                                            <Label>Mô tả tác dụng phụ</Label>
                                            <textarea
                                                rows={2}
                                                value={sideEffect}
                                                onChange={(e) => setSideEffect(e.target.value)}
                                                placeholder="VD: buồn nôn, chóng mặt, phát ban..."
                                                style={textareaStyle}
                                            />
                                        </div>
                                    )}

                                    {/* Ghi chú (optional) */}
                                    <div>
                                        <Label optional>Ghi chú thêm</Label>
                                        <textarea
                                            rows={2}
                                            value={note}
                                            onChange={(e) => setNote(e.target.value)}
                                            placeholder="Chia sẻ thêm kinh nghiệm..."
                                            style={textareaStyle}
                                        />
                                    </div>

                                    {/* Error */}
                                    {error && (
                                        <div style={{
                                            padding: '10px 14px', borderRadius: 10,
                                            background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)',
                                            color: '#dc2626', fontSize: 13,
                                            display: 'flex', alignItems: 'center', gap: 8,
                                        }}>
                                            <AlertTriangle size={15} /> {error}
                                        </div>
                                    )}

                                    {/* Submit */}
                                    <button
                                        type="button"
                                        disabled={!canSubmit}
                                        onClick={handleSubmit}
                                        style={{
                                            padding: '13px', borderRadius: 12,
                                            background: canSubmit ? 'var(--primary)' : 'var(--border)',
                                            color: canSubmit ? 'white' : 'var(--text-muted)',
                                            border: 'none', fontWeight: 600, fontSize: 14,
                                            cursor: canSubmit ? 'pointer' : 'not-allowed',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                                            transition: 'all 0.2s',
                                        }}
                                    >
                                        {loading ? (
                                            <><Loader2 size={16} style={{ animation: 'spin 1s linear infinite' }} /> Đang lưu...</>
                                        ) : isUpdate ? (
                                            <><RefreshCw size={15} /> Cập nhật đánh giá</>
                                        ) : (
                                            'Gửi đánh giá'
                                        )}
                                    </button>
                                </div>
                            )}
                        </div>
                    </>
                )}
            </div>

            <style>{`
                @keyframes fadeInOverlay {
                    from { opacity: 0; }
                    to   { opacity: 1; }
                }
                @keyframes slideUpPanel {
                    from { opacity: 0; transform: translateY(16px); }
                    to   { opacity: 1; transform: translateY(0); }
                }
                @keyframes spin {
                    to { transform: rotate(360deg); }
                }
                @keyframes fadeIn {
                    from { opacity: 0; transform: scale(0.95); }
                    to { opacity: 1; transform: scale(1); }
                }
            `}</style>
        </div>,
        document.body
    );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function Label({ children, optional }: { children: React.ReactNode; optional?: boolean }) {
    return (
        <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.6px', marginBottom: 8 }}>
            {children}
            {optional && <span style={{ fontWeight: 400, textTransform: 'none', letterSpacing: 0, marginLeft: 4 }}>(không bắt buộc)</span>}
        </div>
    );
}

const textareaStyle: React.CSSProperties = {
    width: '100%', padding: '10px 12px',
    borderRadius: 10,
    border: '1.5px solid var(--border)',
    background: 'var(--background)',
    color: 'var(--text-primary)',
    fontSize: 13, resize: 'none',
    fontFamily: 'inherit', outline: 'none', boxSizing: 'border-box',
};

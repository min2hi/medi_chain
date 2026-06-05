'use client';

import React, { useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Pill, Activity, FileText, CheckCircle, Loader2, Info } from 'lucide-react';
import { MedicinesApi, RecommendationResponse } from '@/services/api.client';

// ─── Types ────────────────────────────────────────────────────────────────────

type Medicine = RecommendationResponse['recommendedMedicines'][0];

interface QuickAddMedicineModalProps {
    isOpen: boolean;
    onClose: () => void;
    medicine: Medicine;
    sessionId: string;
    onSuccess: (medicineName: string) => void;
}

interface MedForm {
    name: string;
    genericName: string;
    dosage: string;
    frequency: string;
    instruction: string;
    startDate: string;
}

// ─── Main Component ───────────────────────────────────────────────────────────

export function QuickAddMedicineModal({
    isOpen, onClose, medicine, sessionId, onSuccess
}: QuickAddMedicineModalProps) {
    const today = new Date().toISOString().split('T')[0];

    const [form, setForm] = useState<MedForm>({
        name: medicine.name || '',
        genericName: medicine.genericName || '',
        dosage: medicine.dosage || '',
        frequency: medicine.frequency || '',
        instruction: medicine.instruction || '',
        startDate: today,
    });
    const [isLoading, setIsLoading] = useState(false);
    const [step, setStep] = useState<'form' | 'success'>('form');

    // Reset when medicine changes
    React.useEffect(() => {
        setForm({
            name: medicine.name || '',
            genericName: medicine.genericName || '',
            dosage: medicine.dosage || '',
            frequency: medicine.frequency || '',
            instruction: medicine.instruction || '',
            startDate: today,
        });
        setStep('form');
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [medicine.drugId]);

    const handleSubmit = useCallback(async (e: React.FormEvent) => {
        e.preventDefault();
        if (!form.name.trim()) return;
        setIsLoading(true);

        try {
            const res = await MedicinesApi.addMedicine({
                name: form.name.trim(),
                genericName: form.genericName.trim() || undefined,
                dosage: form.dosage.trim() || undefined,
                frequency: form.frequency.trim() || undefined,
                instruction: form.instruction.trim() || undefined,
                startDate: form.startDate || undefined,
                // Data lineage: track recommendation
                drugCandidateId: medicine.drugId,
                recommendationSessionId: sessionId,
            });

            if (res.success) {
                setStep('success');
                setTimeout(() => {
                    onSuccess(form.name);
                    onClose();
                }, 1500);
            }
        } catch {
            // silently fail — user can retry
        } finally {
            setIsLoading(false);
        }
    }, [form, medicine.drugId, sessionId, onSuccess, onClose]);

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        key="backdrop"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                        style={{
                            position: 'fixed', inset: 0,
                            background: 'rgba(15,23,42,0.5)',
                            backdropFilter: 'blur(6px)',
                            zIndex: 200,
                        }}
                    />

                    {/* Modal */}
                    <motion.div
                        key="modal"
                        initial={{ opacity: 0, y: 60, scale: 0.95 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 60, scale: 0.95 }}
                        transition={{ type: 'spring', damping: 22, stiffness: 220 }}
                        style={{
                            position: 'fixed', left: '50%', bottom: 0,
                            transform: 'translateX(-50%)',
                            width: '100%', maxWidth: 540,
                            background: 'var(--surface)',
                            borderRadius: '28px 28px 0 0',
                            border: '1px solid var(--border)',
                            borderBottom: 'none',
                            boxShadow: '0 -20px 60px rgba(0,0,0,0.15)',
                            zIndex: 201,
                            overflow: 'hidden',
                            // Desktop: center modal
                        }}
                    >
                        {/* Handle bar */}
                        <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 12 }}>
                            <div style={{ width: 40, height: 4, borderRadius: 2, background: 'var(--border)' }} />
                        </div>

                        {/* Header */}
                        <div style={{
                            padding: '16px 24px 0',
                            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                                <div style={{
                                    width: 36, height: 36, borderRadius: 11,
                                    background: 'rgba(16,185,129,0.12)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                }}>
                                    <Pill size={17} style={{ color: 'var(--primary)' }} />
                                </div>
                                <div>
                                    <h3 style={{ fontSize: 15, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>
                                        Thêm vào tủ thuốc
                                    </h3>
                                    <p style={{ fontSize: 11.5, color: 'var(--text-muted)', margin: '2px 0 0' }}>
                                        Đã điền sẵn từ AI Recommendation Engine
                                    </p>
                                </div>
                            </div>
                            <button
                                onClick={onClose}
                                style={{
                                    width: 32, height: 32, borderRadius: '50%',
                                    border: '1px solid var(--border)',
                                    background: 'var(--background)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    cursor: 'pointer', color: 'var(--text-muted)',
                                }}
                            >
                                <X size={16} />
                            </button>
                        </div>

                        {/* AI badge */}
                        <div style={{ padding: '10px 24px 0' }}>
                            <div style={{
                                display: 'flex', alignItems: 'center', gap: 6,
                                background: 'rgba(16,185,129,0.07)',
                                border: '1px solid rgba(16,185,129,0.2)',
                                borderRadius: 10, padding: '7px 12px',
                            }}>
                                <Info size={12} style={{ color: 'var(--primary)', flexShrink: 0 }} />
                                <p style={{ fontSize: 11.5, color: '#059669', margin: 0, fontWeight: 500 }}>
                                    Thông tin được điền sẵn từ kết quả tư vấn AI. Bạn có thể chỉnh sửa trước khi lưu.
                                </p>
                            </div>
                        </div>

                        {/* Content */}
                        <AnimatePresence mode="wait">
                            {step === 'success' ? (
                                <motion.div
                                    key="success"
                                    initial={{ opacity: 0, scale: 0.9 }}
                                    animate={{ opacity: 1, scale: 1 }}
                                    style={{ padding: '32px 24px 40px', textAlign: 'center' }}
                                >
                                    <motion.div
                                        initial={{ scale: 0 }}
                                        animate={{ scale: 1 }}
                                        transition={{ type: 'spring', damping: 15, stiffness: 300 }}
                                        style={{
                                            width: 72, height: 72, borderRadius: '50%',
                                            background: 'rgba(16,185,129,0.12)',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            margin: '0 auto 16px',
                                        }}
                                    >
                                        <CheckCircle size={38} style={{ color: '#10b981' }} />
                                    </motion.div>
                                    <h4 style={{ fontWeight: 700, color: 'var(--text-primary)', marginBottom: 6 }}>
                                        Đã thêm vào tủ thuốc!
                                    </h4>
                                    <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
                                        {form.name} được lưu thành công.
                                    </p>
                                </motion.div>
                            ) : (
                                <motion.form
                                    key="form"
                                    initial={{ opacity: 0 }}
                                    animate={{ opacity: 1 }}
                                    onSubmit={handleSubmit}
                                    style={{ padding: '16px 24px 32px' }}
                                >
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
                                        {/* Tên thuốc */}
                                        <div style={{ gridColumn: '1 / -1' }}>
                                            <label style={labelStyle}>Tên thuốc *</label>
                                            <input
                                                required
                                                value={form.name}
                                                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                                                style={inputStyle}
                                                placeholder="Tên thuốc..."
                                            />
                                        </div>

                                        {/* Hoạt chất */}
                                        <div>
                                            <label style={labelStyle}>Hoạt chất</label>
                                            <input
                                                value={form.genericName}
                                                onChange={e => setForm(f => ({ ...f, genericName: e.target.value }))}
                                                style={inputStyle}
                                                placeholder="Hoạt chất..."
                                            />
                                        </div>

                                        {/* Ngày bắt đầu */}
                                        <div>
                                            <label style={labelStyle}>Ngày bắt đầu</label>
                                            <input
                                                type="date"
                                                value={form.startDate}
                                                onChange={e => setForm(f => ({ ...f, startDate: e.target.value }))}
                                                style={inputStyle}
                                            />
                                        </div>

                                        {/* Liều dùng */}
                                        <div>
                                            <label style={labelStyle}>Liều dùng (AI gợi ý)</label>
                                            <div style={{ position: 'relative' }}>
                                                <Activity size={13} style={{
                                                    position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)',
                                                    color: 'var(--text-muted)',
                                                }} />
                                                <input
                                                    value={form.dosage}
                                                    onChange={e => setForm(f => ({ ...f, dosage: e.target.value }))}
                                                    style={{ ...inputStyle, paddingLeft: 32 }}
                                                    placeholder="Vd: 500mg..."
                                                />
                                            </div>
                                        </div>

                                        {/* Tần suất */}
                                        <div>
                                            <label style={labelStyle}>Tần suất (AI gợi ý)</label>
                                            <input
                                                value={form.frequency}
                                                onChange={e => setForm(f => ({ ...f, frequency: e.target.value }))}
                                                style={inputStyle}
                                                placeholder="Vd: 2 lần/ngày..."
                                            />
                                        </div>

                                        {/* Hướng dẫn */}
                                        <div style={{ gridColumn: '1 / -1' }}>
                                            <label style={labelStyle}>Hướng dẫn sử dụng (AI gợi ý)</label>
                                            <div style={{ position: 'relative' }}>
                                                <FileText size={13} style={{
                                                    position: 'absolute', left: 12, top: 13,
                                                    color: 'var(--text-muted)',
                                                }} />
                                                <textarea
                                                    value={form.instruction}
                                                    onChange={e => setForm(f => ({ ...f, instruction: e.target.value }))}
                                                    rows={2}
                                                    style={{ ...inputStyle, paddingLeft: 32, resize: 'none' }}
                                                    placeholder="Hướng dẫn..."
                                                />
                                            </div>
                                        </div>
                                    </div>

                                    {/* Submit */}
                                    <motion.button
                                        type="submit"
                                        disabled={isLoading || !form.name.trim()}
                                        whileHover={{ y: -1 }}
                                        whileTap={{ scale: 0.98 }}
                                        style={{
                                            width: '100%', padding: '14px',
                                            background: isLoading || !form.name.trim()
                                                ? 'rgba(20,184,166,0.4)'
                                                : 'linear-gradient(135deg, var(--primary), #059669)',
                                            border: 'none', borderRadius: 14,
                                            color: 'white', fontSize: 15, fontWeight: 700,
                                            cursor: isLoading || !form.name.trim() ? 'not-allowed' : 'pointer',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                                            boxShadow: '0 6px 16px -4px rgba(20,184,166,0.35)',
                                        }}
                                    >
                                        {isLoading ? (
                                            <><Loader2 size={16} style={{ animation: 'spin 1s linear infinite' }} /> Đang lưu...</>
                                        ) : (
                                            <><Pill size={16} /> Xác nhận thêm vào tủ thuốc</>
                                        )}
                                    </motion.button>
                                </motion.form>
                            )}
                        </AnimatePresence>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
}

// ─── Style helpers ────────────────────────────────────────────────────────────

const labelStyle: React.CSSProperties = {
    display: 'block',
    fontSize: 11.5,
    fontWeight: 600,
    color: 'var(--text-muted)',
    marginBottom: 5,
    letterSpacing: '0.3px',
};

const inputStyle: React.CSSProperties = {
    width: '100%',
    padding: '10px 12px',
    background: 'var(--background)',
    border: '1.5px solid var(--border)',
    borderRadius: 12,
    fontSize: 13.5,
    color: 'var(--text-primary)',
    outline: 'none',
    fontFamily: 'inherit',
    transition: 'border-color 0.2s',
};

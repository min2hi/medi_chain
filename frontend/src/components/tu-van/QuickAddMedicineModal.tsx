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
                        className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-[200]"
                    />

                    {/* Modal */}
                    <motion.div
                        key="modal"
                        initial={{ opacity: 0, y: 60, scale: 0.95 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 60, scale: 0.95 }}
                        transition={{ type: 'spring', damping: 22, stiffness: 220 }}
                        className="fixed bottom-0 sm:bottom-auto sm:top-1/2 left-1/2 -translate-x-1/2 sm:-translate-y-1/2 w-full max-w-[540px] bg-surface border border-border rounded-t-[28px] sm:rounded-[28px] shadow-2xl z-[201] overflow-hidden"
                    >
                        {/* Handle bar for mobile drawer */}
                        <div className="flex justify-center pt-3 sm:hidden">
                            <div className="w-10 h-1 bg-border rounded-full" />
                        </div>

                        {/* Header */}
                        <div className="px-6 pt-4 pb-0 flex items-center justify-between sm:pt-6">
                            <div className="flex items-center gap-2.5">
                                <div className="w-9 h-9 rounded-xl bg-emerald-500/10 flex items-center justify-center">
                                    <Pill size={17} className="text-primary" />
                                </div>
                                <div>
                                    <h3 className="text-[15px] font-bold text-primary m-0">
                                        Thêm vào tủ thuốc
                                    </h3>
                                    <p className="text-[11.5px] text-muted mt-0.5">
                                        Đã điền sẵn từ AI Recommendation Engine
                                    </p>
                                </div>
                            </div>
                            <button
                                onClick={onClose}
                                className="w-8 h-8 rounded-full border border-border bg-background flex items-center justify-center cursor-pointer text-muted hover:text-primary transition-colors"
                            >
                                <X size={16} />
                            </button>
                        </div>

                        {/* AI badge */}
                        <div className="px-6 pt-2.5 pb-0">
                            <div className="flex items-center gap-1.5 bg-emerald-500/5 border border-emerald-500/20 rounded-xl px-3 py-1.5">
                                <Info size={12} className="text-primary shrink-0" />
                                <p className="text-[11.5px] text-emerald-600 m-0 font-medium">
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
                                    className="px-6 pt-8 pb-10 text-center"
                                >
                                    <motion.div
                                        initial={{ scale: 0 }}
                                        animate={{ scale: 1 }}
                                        transition={{ type: 'spring', damping: 15, stiffness: 300 }}
                                        className="w-18 h-18 rounded-full bg-emerald-500/12 flex items-center justify-center mx-auto mb-4"
                                    >
                                        <CheckCircle size={38} className="text-emerald-500" />
                                    </motion.div>
                                    <h4 className="font-bold text-primary mb-1.5">
                                        Đã thêm vào tủ thuốc!
                                    </h4>
                                    <p className="text-sm text-muted">
                                        {form.name} được lưu thành công.
                                    </p>
                                </motion.div>
                            ) : (
                                <motion.form
                                    key="form"
                                    initial={{ opacity: 0 }}
                                    animate={{ opacity: 1 }}
                                    onSubmit={handleSubmit}
                                    className="px-6 pt-4 pb-8"
                                >
                                    <div className="grid grid-cols-2 gap-3 mb-3">
                                        {/* Tên thuốc */}
                                        <div className="col-span-2">
                                            <label className="block text-[11.5px] font-semibold text-muted mb-1.5 tracking-wide">
                                                Tên thuốc *
                                            </label>
                                            <input
                                                required
                                                value={form.name}
                                                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                                                className="w-full px-3 py-2 bg-background border border-border rounded-xl text-[13.5px] text-primary outline-none transition-colors focus:border-primary"
                                                placeholder="Tên thuốc..."
                                            />
                                        </div>

                                        {/* Hoạt chất */}
                                        <div>
                                            <label className="block text-[11.5px] font-semibold text-muted mb-1.5 tracking-wide">
                                                Hoạt chất
                                            </label>
                                            <input
                                                value={form.genericName}
                                                onChange={e => setForm(f => ({ ...f, genericName: e.target.value }))}
                                                className="w-full px-3 py-2 bg-background border border-border rounded-xl text-[13.5px] text-primary outline-none transition-colors focus:border-primary"
                                                placeholder="Hoạt chất..."
                                            />
                                        </div>

                                        {/* Ngày bắt đầu */}
                                        <div>
                                            <label className="block text-[11.5px] font-semibold text-muted mb-1.5 tracking-wide">
                                                Ngày bắt đầu
                                            </label>
                                            <input
                                                type="date"
                                                value={form.startDate}
                                                onChange={e => setForm(f => ({ ...f, startDate: e.target.value }))}
                                                className="w-full px-3 py-2 bg-background border border-border rounded-xl text-[13.5px] text-primary outline-none transition-colors focus:border-primary"
                                            />
                                        </div>

                                        {/* Liều dùng */}
                                        <div>
                                            <label className="block text-[11.5px] font-semibold text-muted mb-1.5 tracking-wide">
                                                Liều dùng (AI gợi ý)
                                            </label>
                                            <div className="relative">
                                                <Activity size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                                                <input
                                                    value={form.dosage}
                                                    onChange={e => setForm(f => ({ ...f, dosage: e.target.value }))}
                                                    className="w-full pl-8 pr-3 py-2 bg-background border border-border rounded-xl text-[13.5px] text-primary outline-none transition-colors focus:border-primary"
                                                    placeholder="Vd: 500mg..."
                                                />
                                            </div>
                                        </div>

                                        {/* Tần suất */}
                                        <div>
                                            <label className="block text-[11.5px] font-semibold text-muted mb-1.5 tracking-wide">
                                                Tần suất (AI gợi ý)
                                            </label>
                                            <input
                                                value={form.frequency}
                                                onChange={e => setForm(f => ({ ...f, frequency: e.target.value }))}
                                                className="w-full px-3 py-2 bg-background border border-border rounded-xl text-[13.5px] text-primary outline-none transition-colors focus:border-primary"
                                                placeholder="Vd: 2 lần/ngày..."
                                            />
                                        </div>

                                        {/* Hướng dẫn */}
                                        <div className="col-span-2">
                                            <label className="block text-[11.5px] font-semibold text-muted mb-1.5 tracking-wide">
                                                Hướng dẫn sử dụng (AI gợi ý)
                                            </label>
                                            <div className="relative">
                                                <FileText size={13} className="absolute left-3 top-3 text-muted" />
                                                <textarea
                                                    value={form.instruction}
                                                    onChange={e => setForm(f => ({ ...f, instruction: e.target.value }))}
                                                    rows={2}
                                                    className="w-full pl-8 pr-3 py-2 bg-background border border-border rounded-xl text-[13.5px] text-primary outline-none transition-colors focus:border-primary resize-none"
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
                                        className={`w-full py-3.5 rounded-2xl text-[15px] font-bold border-none text-white cursor-pointer flex items-center justify-center gap-2 shadow-lg transition-all ${isLoading || !form.name.trim() ? 'bg-primary/40 cursor-not-allowed shadow-none' : 'bg-gradient-to-br from-primary to-emerald-600 shadow-primary/25 hover:shadow-xl hover:shadow-primary/35'}`}
                                    >
                                        {isLoading ? (
                                            <><Loader2 size={16} className="animate-spin" /> Đang lưu...</>
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

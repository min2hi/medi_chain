'use client';

import React, { useEffect, useState, useCallback } from 'react';
import {
  Pill, Plus, Pencil, Trash2, Loader2, X, Bell,
  AlertTriangle, Activity, Send, BotMessageSquare,
  ChevronRight, Star, ShieldCheck, Info,
} from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { MedicinesApi, AIApi, RecommendationApi, RecommendationResponse } from '@/services/api.client';
import { Modal } from '@/components/shared/Modal';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import { FeedbackModal, FeedbackDrug } from '@/components/shared/FeedbackModal';
import styles from './thuoc.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

// ─── Types ────────────────────────────────────────────────────────────────────

interface RecommendedMedicineItem {
  drugId?: string;
  name?: string;
  genericName?: string;
  rank?: number;
  finalScore?: number;
  ingredients?: string;
  summary?: string;
  indications?: string;
  warnings?: string;
  sideEffects?: string;
  hasViContent?: boolean;
  dosage?: string;
  frequency?: string;
  instruction?: string;
}

interface ConsultResult {
  sessionId?: string;
  message?: { role: string; content: string };
  recommendedMedicines?: RecommendedMedicineItem[];
  safetyChecks?: { warnings: string[] };
}

type Medicine = {
  id: string;
  name: string;
  dosage?: string | null;
  frequency?: string | null;
  instruction?: string | null;
  startDate: string;
  endDate?: string | null;
  drugCandidateId?: string | null;
  recommendationSessionId?: string | null;
};

type FeedbackTarget = {
  sessionId: string;
  drugId: string;
  drugName: string;
};

// ─── Helper ───────────────────────────────────────────────────────────────────

function isMedicineActive(med: Medicine): boolean {
  if (!med.endDate) return true;
  return new Date(med.endDate) > new Date();
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ═══════════════════════════════════════════════════════════════════════════════

export default function ThuocPage() {
  const { t } = useTranslation();
  // ── Medicine list state ──
  const [list, setList] = useState<Medicine[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [showConfirm, setShowConfirm] = useState(false);
  const [submitLoading, setSubmitLoading] = useState(false);
  const [error, setError] = useState('');
  const [lineageCtx, setLineageCtx] = useState<{
    drugCandidateId: string;
    recommendationSessionId: string;
  } | null>(null);

  const [form, setForm] = useState({
    name: '', dosage: '', frequency: '', instruction: '',
    startDate: new Date().toISOString().slice(0, 10), endDate: '',
  });

  // ── Consultation modal state ──
  const [showConsult, setShowConsult] = useState(false);
  const [symptoms, setSymptoms] = useState('');
  const [consultLoading, setConsultLoading] = useState(false);
  const [consultResult, setConsultResult] = useState<ConsultResult | null>(null);

  // ── Feedback state ──
  const [showFeedback, setShowFeedback] = useState(false);
  const [feedbackTarget, setFeedbackTarget] = useState<FeedbackTarget | null>(null);

  // ── Load medicines ──
  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    const res = await MedicinesApi.list();
    if (res.success && res.data) setList(Array.isArray(res.data) ? res.data as Medicine[] : []);
    else setError(res.message || 'Lỗi tải danh sách thuốc');
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  // ── Load last consult result from AI history ──
  useEffect(() => {
    const loadLastConsult = async () => {
      try {
        const convRes = await AIApi.getConversations('CONSULT');
        if (!convRes.success || !convRes.data || convRes.data.length === 0) return;
        const lastConv = convRes.data[0];
        const msgRes = await AIApi.getMessages(lastConv.id);
        if (!msgRes.success || !msgRes.data || msgRes.data.length === 0) return;
        const lastAI = [...msgRes.data].reverse().find(m => m.role === 'ASSISTANT');
        if (!lastAI) return;
        try {
          const ctx = lastAI.medicalContext ? JSON.parse(lastAI.medicalContext) : {};
          const safety = lastAI.safetyCheckResult ? JSON.parse(lastAI.safetyCheckResult) : { warnings: [] };
          setConsultResult({
            message: { role: 'ASSISTANT', content: lastAI.content },
            recommendedMedicines: ctx.recommendedMedicines || [],
            safetyChecks: safety,
          });
        } catch { /* silent */ }
      } catch { /* silent */ }
    };
    loadLastConsult();
  }, []);

  // ── Form helpers ──
  const resetForm = () => {
    setShowForm(false);
    setEditingId(null);
    setLineageCtx(null);
    setError('');
    setForm({ name: '', dosage: '', frequency: '', instruction: '', startDate: new Date().toISOString().slice(0, 10), endDate: '' });
  };

  const openEdit = (m: Medicine) => {
    setEditingId(m.id);
    setForm({
      name: m.name,
      dosage: m.dosage || '',
      frequency: m.frequency || '',
      instruction: m.instruction || '',
      startDate: m.startDate ? new Date(m.startDate).toISOString().slice(0, 10) : '',
      endDate: m.endDate ? new Date(m.endDate).toISOString().slice(0, 10) : '',
    });
    setShowForm(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) return;
    setSubmitLoading(true);
    setError('');
    const body = {
      name: form.name.trim(),
      dosage: form.dosage || undefined,
      frequency: form.frequency || undefined,
      instruction: form.instruction || undefined,
      startDate: form.startDate || undefined,
      endDate: form.endDate || undefined,
      ...(lineageCtx ?? {}),
    };
    if (editingId) {
      const res = await MedicinesApi.update(editingId, body);
      if (res.success) { load(); resetForm(); }
      else setError(res.message || 'Lỗi cập nhật');
    } else {
      const res = await MedicinesApi.create(body);
      if (res.success) { load(); resetForm(); }
      else setError(res.message || 'Lỗi thêm thuốc');
    }
    setSubmitLoading(false);
  };

  const openConfirmDelete = (id: string) => { setDeletingId(id); setShowConfirm(true); };

  const handleDelete = async () => {
    if (!deletingId) return;
    setSubmitLoading(true);
    const res = await MedicinesApi.delete(deletingId);
    if (res.success) { load(); setShowConfirm(false); setDeletingId(null); }
    else setError(res.message || 'Lỗi xóa');
    setSubmitLoading(false);
  };

  // ── Consultation helpers ──
  const closeConsult = () => {
    setShowConsult(false);
    setError('');
  };

  const handleConsult = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!symptoms.trim()) return;
    setError('');
    setConsultLoading(true);
    try {
      const res = await AIApi.consult(symptoms);
      if (res.success && res.data) {
        const data = res.data as RecommendationResponse;
        const mappedMedicines: RecommendedMedicineItem[] = (data.recommendedMedicines ?? []).map((m: any) => ({
          drugId: m.drugId, name: m.name, genericName: m.genericName,
          rank: m.rank, finalScore: m.finalScore, ingredients: m.ingredients,
          summary: m.summary, indications: m.indications, warnings: m.warnings,
          sideEffects: m.sideEffects, hasViContent: m.hasViContent,
          dosage: m.dosage, frequency: m.frequency, instruction: m.instruction,
        }));
        setConsultResult({
          sessionId: data.sessionId,
          message: data.message ? { role: 'ASSISTANT', content: data.message.content } : undefined,
          recommendedMedicines: mappedMedicines,
          safetyChecks: { warnings: data.safetyWarnings ?? [] },
        });
      } else {
        setError(res.message || 'Lỗi kết nối AI. Vui lòng thử lại.');
      }
    } catch (err: unknown) {
      setError('Lỗi kết nối AI: ' + (err instanceof Error ? err.message : ''));
    } finally {
      setConsultLoading(false);
    }
  };

  const addMedFromResult = (med: RecommendedMedicineItem) => {
    if (consultResult?.sessionId && med.drugId) {
      setLineageCtx({ drugCandidateId: med.drugId, recommendationSessionId: consultResult.sessionId });
    }
    setForm({
      name: med.name ?? '',
      dosage: med.dosage || '',
      frequency: med.frequency || '',
      instruction: med.instruction || '',
      startDate: new Date().toISOString().slice(0, 10),
      endDate: '',
    });
    closeConsult();
    setShowForm(true);
  };

  // ── Loading ──
  if (loading) {
    return (
      <div style={{ padding: '0 4px' }}>
        {/* Header skeleton */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 32 }}>
          <div style={{ width: 160, height: 28, borderRadius: 8, background: 'var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ width: 120, height: 40, borderRadius: 12, background: 'var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
            <div style={{ width: 120, height: 40, borderRadius: 12, background: 'var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
          </div>
        </div>
        {/* Card skeletons */}
        {[1, 2, 3].map(i => (
          <div key={i} style={{
            display: 'flex', gap: 16, padding: '20px 24px',
            background: 'var(--surface)', border: '1px solid var(--border)',
            borderRadius: 20, marginBottom: 16, alignItems: 'center',
            opacity: 1 - (i - 1) * 0.2,
          }}>
            <div style={{ width: 4, height: 56, borderRadius: 4, background: 'var(--border)' }} />
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column' as const, gap: 10 }}>
              <div style={{ width: '35%', height: 18, borderRadius: 6, background: 'var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
              <div style={{ width: '55%', height: 14, borderRadius: 4, background: 'var(--border)', animation: 'pulse 1.5s ease-in-out infinite', opacity: 0.7 }} />
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <div style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
              <div style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
            </div>
          </div>
        ))}
        <style>{`@keyframes pulse { 0%,100%{opacity:.4} 50%{opacity:.8} }`}</style>
      </div>
    );
  }


  // ═════════════════════════════════════════════════════════════════════════════
  // RENDER
  // ═════════════════════════════════════════════════════════════════════════════

  return (
    <div>
      {/* ── Header ── */}
      <div className={styles.header}>
        <h1 className={styles.title}>{t('medications.title')}</h1>
        <div className={styles.headerActions}>
          <button
            type="button"
            className={styles.btnConsult}
            onClick={() => { setConsultResult(null); setSymptoms(''); setShowConsult(true); }}
          >
            <BotMessageSquare size={18} />
            {t('medications.consult')}
          </button>
          <button
            type="button"
            className={styles.btnPrimary}
            onClick={() => { resetForm(); setShowForm(true); }}
          >
            <Plus size={18} />
            {t('medications.add')}
          </button>
        </div>
      </div>

      {/* ── Error ── */}
      {error && (
        <div className={styles.alert}>
          <AlertTriangle size={16} />
          <span>{error}</span>
        </div>
      )}

      {/* ── Last consult result banner ── */}
      {!showConsult && consultResult?.recommendedMedicines && consultResult.recommendedMedicines.length > 0 && (
        <div className={styles.lastResultBanner}>
          <div className={styles.lastResultHeader}>
            <div className={styles.lastResultIcon}>
              <Activity size={16} />
            </div>
            <div>
              <p className={styles.lastResultTitle}>{t('medications.last_result_title')}</p>
              <p className={styles.lastResultSub}>{t('medications.last_result_sub', { count: consultResult.recommendedMedicines.length })}</p>
            </div>
            <button
              type="button"
              className={styles.lastResultBtn}
              onClick={() => setShowConsult(true)}
            >
              {t('medications.review')} <ChevronRight size={14} />
            </button>
          </div>
        </div>
      )}

      {/* ── Medicine list ── */}
      {list.length === 0 ? (
        <div className={styles.emptyWrapper}>
          <EmptyState
            icon={Pill}
            title={t('medications.no_medications')}
            description={t('medications.no_medications_desc')}
          />
        </div>
      ) : (
        <ul className={styles.medList}>
          {list.map((m) => {
            const active = isMedicineActive(m);
            const canFeedback = Boolean(m.drugCandidateId && m.recommendationSessionId);
            return (
              <li key={m.id} className={styles.medItem}>
                <div className={styles.medColorBar} style={{ background: active ? 'var(--primary)' : '#dc2626' }} />
                <div className={styles.medContent}>
                  <div className={styles.medTop}>
                    <div className={styles.medNameRow}>
                      <span className={styles.medName}>{m.name}</span>
                      <span className={`${styles.medStatusBadge} ${active ? styles.medStatusActive : styles.medStatusExpired}`}>
                        {active ? t('medications.active') : t('medications.stopped')}
                      </span>
                      {canFeedback && (
                        <span className={styles.medAIBadge}>
                          {t('medications.ai_suggested')}
                        </span>
                      )}
                    </div>

                    <div className={styles.medActions}>
                      {canFeedback && (
                        <button
                          type="button"
                          className={styles.feedbackBtn}
                          title="Đánh giá hiệu quả thuốc"
                          onClick={() => {
                            setFeedbackTarget({
                              sessionId: m.recommendationSessionId!,
                              drugId: m.drugCandidateId!,
                              drugName: m.name,
                            });
                            setShowFeedback(true);
                          }}
                        >
                            {t('medications.evaluate')}
                        </button>
                      )}
                      <button type="button" className={styles.iconBtn} onClick={() => openEdit(m)} title={t('medications.edit')}>
                        <Pencil size={15} />
                      </button>
                      <button
                        type="button"
                        className={`${styles.iconBtn} ${styles.iconBtnDanger}`}
                        onClick={() => openConfirmDelete(m.id)}
                        title={t('medications.delete')}
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </div>

                  <div className={styles.medMeta}>
                    {(m.dosage || m.frequency) && (
                      <span className={styles.medMetaItem}>
                        <Pill size={12} />
                        {[m.dosage, m.frequency].filter(Boolean).join(' · ')}
                      </span>
                    )}
                    <span className={styles.medMetaItem}>
                      <Bell size={12} />
                      {t('medications.start_date')}: {new Date(m.startDate).toLocaleDateString()}
                      {m.endDate && (
                        <> · {t('medications.end_date')}: <span style={{ color: active ? 'inherit' : '#dc2626' }}>
                          {new Date(m.endDate).toLocaleDateString()}
                        </span></>
                      )}
                    </span>
                  </div>

                  {m.instruction && (
                    <p className={styles.medInstruction}>{m.instruction}</p>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {/* ══════════════════════════════════════════════════════════
          CONSULTATION MODAL
          ══════════════════════════════════════════════════════════ */}
      <Modal isOpen={showConsult} onClose={closeConsult}>
        <div className={styles.consultModal}>
          <div className={styles.consultModalHead}>
            <div className={styles.consultModalTitle}>
              <div className={styles.consultTitleIcon}>
                <Activity size={18} />
              </div>
              <div>
                <h3>{t('medications.consult_modal_title')}</h3>
                <p>{t('medications.consult_modal_sub')}</p>
              </div>
            </div>
            <button type="button" className={styles.closeBtn} onClick={closeConsult}>
              <X size={18} />
            </button>
          </div>

          <div className={styles.consultModalBody}>
            {/* Input form */}
            {!consultResult ? (
              <form onSubmit={handleConsult} className={styles.consultForm}>
                <p className={styles.consultDesc}>
                  {t('medications.consult_desc')}
                </p>

                {error && (
                  <div className={styles.consultError}>
                    <AlertTriangle size={14} /> {error}
                  </div>
                )}

                <textarea
                  className={styles.consultInput}
                  rows={4}
                  value={symptoms}
                  onChange={(e) => setSymptoms(e.target.value)}
                  placeholder={t('medications.consult_ph')}
                  disabled={consultLoading}
                  autoFocus
                />

                <div className={styles.quickSymptoms}>
                  <span className={styles.quickSymptomsLabel}>{t('medications.quick_suggestions')}</span>
                  {[
                    'Tôi bị đau đầu và sốt nhẹ từ tối qua',
                    'Tôi bị ho khan và đau họng, không sốt',
                  ].map((s) => (
                    <button
                      key={s}
                      type="button"
                      className={styles.quickSymptomChip}
                      onClick={() => setSymptoms(s)}
                    >
                      {s}
                    </button>
                  ))}
                </div>

                <div className={styles.consultFormActions}>
                  <button type="button" className={styles.btnSecondary} onClick={closeConsult}>
                    {t('medications.cancel')}
                  </button>
                  <button
                    type="submit"
                    className={styles.btnPrimary}
                    disabled={consultLoading || !symptoms.trim()}
                  >
                    {consultLoading ? (
                      <><Loader2 size={16} className={styles.spinner} /> {t('medications.analyzing')}</>
                    ) : (
                      <><Send size={16} /> {t('medications.analyze')}</>
                    )}
                  </button>
                </div>
              </form>
            ) : (
              // ── Results ──
              <div className={styles.consultResults}>
                <div className={styles.consultResultActions}>
                  <button
                    type="button"
                    className={styles.btnSecondary}
                    style={{ fontSize: '0.85rem', padding: '8px 16px' }}
                    onClick={() => { setConsultResult(null); setSymptoms(''); }}
                  >
                    {t('medications.new_consult')}
                  </button>
                </div>

                {/* AI message */}
                {consultResult.message && (
                  <div className={styles.consultAIMsg}>
                    <p className={styles.consultAIMsgLabel}>
                      <BotMessageSquare size={14} /> {t('medications.analysis_label')}
                    </p>
                    <p className={styles.consultAIMsgText}>{consultResult.message.content}</p>
                  </div>
                )}

                {/* Safety warnings */}
                {consultResult.safetyChecks?.warnings && consultResult.safetyChecks.warnings.length > 0 && (
                  <div className={styles.safetyBox}>
                    <div className={styles.safetyBoxHeader}>
                      <AlertTriangle size={16} />
                      {t('medications.safety_warning')}
                    </div>
                    <ul className={styles.safetyList}>
                      {consultResult.safetyChecks.warnings.map((w, i) => (
                        <li key={i}>{w}</li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* Danh sách thuốc gợi ý */}
                {consultResult.recommendedMedicines && consultResult.recommendedMedicines.length > 0 && (
                  <div className={styles.recommendedList}>
                    <p className={styles.recommendedLabel}>
                      <Pill size={13} />
                      {t('medications.suitable_meds', { count: consultResult.recommendedMedicines.length })}
                    </p>

                    {consultResult.recommendedMedicines.map((med, idx) => {
                      const rank   = med.rank ?? (idx + 1);
                      const score  = Math.round(med.finalScore ?? 0);
                      const isTop  = rank === 1;
                      const medAny = med as any;

                      const scoreColor =
                        score >= 75 ? 'var(--primary)' :
                        score >= 55 ? '#d97706' : '#ef4444';

                      return (
                        <div
                          key={idx}
                          className={`${styles.recMedCard} ${isTop ? styles.recMedCardTop : ''}`}
                        >
                          <div className={styles.recMedCardInner}>
                            {/* Header */}
                            <div className={styles.recMedHeader}>
                              <span className={`${styles.rankBadge} ${isTop ? styles.rankBadgeTop : ''}`}>
                                #{rank}
                              </span>
                              <div className={styles.recMedNameBlock}>
                                <span className={styles.recMedName}>{med.name}</span>
                                {med.genericName && (
                                  <span className={styles.recMedGeneric}>{med.genericName}</span>
                                )}
                              </div>
                              <span className={styles.scoreNum} style={{ color: scoreColor }}>
                                {score}<span className={styles.scoreNumSub}> đ</span>
                              </span>
                            </div>

                            {/* Công dụng */}
                            {(med.indications || med.summary) && (
                              <p className={styles.recMedindication}>
                                {med.indications || med.summary}
                              </p>
                            )}

                            {/* Liều dùng */}
                            {(med.dosage || med.frequency) && (
                              <div className={styles.recMedDosageRow}>
                                <Pill size={12} />
                                <span>
                                  {[med.dosage, med.frequency, med.instruction]
                                    .filter(Boolean).join(' · ')}
                                </span>
                              </div>
                            )}

                            {/* Cảnh báo */}
                            {(med.warnings || med.sideEffects) && (
                              <div className={styles.recMedWarningRow}>
                                <AlertTriangle size={13} />
                                <span>
                                  {med.warnings || med.sideEffects}
                                  {!med.hasViContent && (
                                    <span className={styles.rawDataNote}> · FDA</span>
                                  )}
                                </span>
                              </div>
                            )}

                            {/* Action */}
                            <div className={styles.recMedAction}>
                              <button
                                type="button"
                                className={styles.addMedBtn}
                                onClick={() => addMedFromResult(med)}
                              >
                                <Plus size={13} /> {t('medications.add_to_cabinet')}
                              </button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                <p className={styles.disclaimer}>
                  {t('medications.disclaimer')}
                </p>
              </div>
            )}
          </div>
        </div>
      </Modal>

      {/* ── Feedback Modal ── */}
      {feedbackTarget && (
        <FeedbackModal
          key={`${feedbackTarget.sessionId}-${feedbackTarget.drugId}`}
          isOpen={showFeedback}
          onClose={() => { setShowFeedback(false); setFeedbackTarget(null); load(); }}
          onSuccess={() => { /* thank-you screen handled inside FeedbackModal */ }}
          sessionId={feedbackTarget.sessionId}
          drugs={[{ drugId: feedbackTarget.drugId, drugName: feedbackTarget.drugName }] as FeedbackDrug[]}
        />
      )}

      {/* ── Add/Edit Medicine Modal ── */}
      <Modal isOpen={showForm} onClose={resetForm}>
        <div className={styles.formModal}>
          <div className={styles.formModalHead}>
            <h3>{editingId ? t('medications.edit_title') : t('medications.add_title')}</h3>
            <button type="button" className={styles.closeBtn} onClick={resetForm} disabled={submitLoading}>
              <X size={18} />
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className={styles.formBody}>
              {error && <div className={styles.alert}><AlertTriangle size={14} /> {error}</div>}

              {lineageCtx && (
                <div className={styles.lineageBanner}>
                  <BotMessageSquare size={14} />
                  <span>{t('medications.lineage_msg')}</span>
                </div>
              )}

              <div className={styles.formGrid}>
                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.fieldLabel}>
                    {t('medications.name')} <span className={styles.required}>*</span>
                  </label>
                  <input
                    className={styles.input}
                    value={form.name}
                    onChange={(e) => setForm(f => ({ ...f, name: e.target.value }))}
                    required
                    placeholder={t('medications.name_ph')}
                    disabled={submitLoading}
                    autoFocus
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.fieldLabel}>{t('medications.dosage')}</label>
                  <input
                    className={styles.input}
                    value={form.dosage}
                    onChange={(e) => setForm(f => ({ ...f, dosage: e.target.value }))}
                    placeholder={t('medications.dosage_ph')}
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.fieldLabel}>{t('medications.frequency')}</label>
                  <input
                    className={styles.input}
                    value={form.frequency}
                    onChange={(e) => setForm(f => ({ ...f, frequency: e.target.value }))}
                    placeholder={t('medications.frequency_ph')}
                    disabled={submitLoading}
                  />
                </div>

                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.fieldLabel}>{t('medications.instruction')}</label>
                  <textarea
                    className={styles.textarea}
                    rows={2}
                    value={form.instruction}
                    onChange={(e) => setForm(f => ({ ...f, instruction: e.target.value }))}
                    placeholder={t('medications.instruction_ph')}
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.fieldLabel}>{t('medications.start_date_label')}</label>
                  <input
                    type="date"
                    className={styles.input}
                    value={form.startDate}
                    onChange={(e) => setForm(f => ({ ...f, startDate: e.target.value }))}
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.fieldLabel}>{t('medications.end_date_label')}</label>
                  <input
                    type="date"
                    className={styles.input}
                    value={form.endDate}
                    onChange={(e) => setForm(f => ({ ...f, endDate: e.target.value }))}
                    disabled={submitLoading}
                  />
                </div>
              </div>
            </div>

            <div className={styles.formFooter}>
              <button type="button" className={styles.btnSecondary} onClick={resetForm} disabled={submitLoading}>
                {t('medications.cancel')}
              </button>
              <button type="submit" className={styles.btnPrimary} disabled={submitLoading}>
                {submitLoading ? (
                  <><Loader2 size={16} className={styles.spinner} /> {t('medications.save')}</>
                ) : (
                  editingId ? t('medications.update') : t('medications.add_new')
                )}
              </button>
            </div>
          </form>
        </div>
      </Modal>

      {/* ── Confirm Delete ── */}
      <ConfirmModal
        isOpen={showConfirm}
        onClose={() => setShowConfirm(false)}
        onConfirm={handleDelete}
        title={t('medications.delete_title')}
        message={t('medications.delete_message')}
        confirmText={t('medications.confirm_delete')}
        loading={submitLoading}
      />
    </div>
  );
}

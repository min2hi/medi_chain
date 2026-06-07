'use client';

import React, { useEffect, useState, useCallback, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import {
  Pill, Plus, Pencil, Trash2, Loader2, X, Bell,
  AlertTriangle, Activity, Send, BotMessageSquare,
  ChevronRight, Sparkles, Upload,
} from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { MedicinesApi, AIApi, RecommendationResponse, CreateMedicineBody } from '@/services/api.client';
import { Modal } from '@/components/shared/Modal';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import { FeedbackModal, FeedbackDrug } from '@/components/shared/FeedbackModal';
import { ConsultResultPanel } from '@/components/tu-van/ConsultResultPanel';
import styles from './thuoc.module.css';
import { useTranslation } from '@/i18n/I18nProvider';
import Tesseract from 'tesseract.js';
import { PrescriptionParser, ParsedMedicine } from '@/utils/prescription-parser';

// ─── Markdown Parser Helper ───
function MarkdownContent({ content }: { content: string }) {
  return (
    <ReactMarkdown
      components={{
        p: ({ children }) => <p style={{ margin: '2px 0 6px', lineHeight: 1.7 }}>{children}</p>,
        strong: ({ children }) => <strong style={{ fontWeight: 700, color: 'inherit' }}>{children}</strong>,
        em: ({ children }) => <em style={{ fontStyle: 'italic', opacity: 0.9 }}>{children}</em>,
        ul: ({ children }) => <ul style={{ margin: '8px 0 8px', paddingLeft: 22, listStyleType: 'disc' }}>{children}</ul>,
        ol: ({ children }) => <ol style={{ margin: '8px 0 8px', paddingLeft: 22 }}>{children}</ol>,
        li: ({ children }) => <li style={{ margin: '4px 0', lineHeight: 1.6 }}>{children}</li>,
        h1: ({ children }) => <h1 style={{ fontSize: 18, fontWeight: 800, margin: '16px 0 8px', color: 'var(--text-primary)' }}>{children}</h1>,
        h2: ({ children }) => <h2 style={{ fontSize: 16, fontWeight: 700, margin: '14px 0 6px', color: 'var(--text-primary)' }}>{children}</h2>,
        h3: ({ children }) => <h3 style={{ fontSize: 15, fontWeight: 600, margin: '12px 0 4px', opacity: 0.9 }}>{children}</h3>,
        hr: () => <hr style={{ border: 'none', borderTop: '1px solid rgba(0,0,0,0.06)', margin: '12px 0' }} />,
        blockquote: ({ children }) => (
          <blockquote style={{
            borderLeft: '4px solid var(--primary)',
            paddingLeft: 16,
            margin: '12px 0',
            opacity: 0.8,
            fontStyle: 'italic',
            background: 'rgba(20,184,166,0.04)',
            padding: '10px 16px',
            borderRadius: '0 12px 12px 0'
          }}>
            {children}
          </blockquote>
        ),
      }}
    >
      {content}
    </ReactMarkdown>
  );
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
  const [consultResult, setConsultResult] = useState<RecommendationResponse | null>(null);

  // ── Feedback state ──
  const [showFeedback, setShowFeedback] = useState(false);
  const [feedbackTarget, setFeedbackTarget] = useState<FeedbackTarget | null>(null);

  // ── OCR Scanner State ──
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [showOCR, setShowOCR] = useState(false);
  const [ocrFile, setOcrFile] = useState<File | null>(null);
  const [ocrPreviewUrl, setOcrPreviewUrl] = useState<string | null>(null);
  const [ocrLoading, setOcrLoading] = useState(false);
  const [ocrProgress, setOcrProgress] = useState(0);
  const [ocrError, setOcrError] = useState('');
  const [ocrResults, setOcrResults] = useState<ParsedMedicine[]>([]);
  const [checkedResults, setCheckedResults] = useState<boolean[]>([]);
  const [ocrSubmitting, setOcrSubmitting] = useState(false);

  // ── Load medicines ──
  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    const res = await MedicinesApi.list();
    if (res.success && res.data) setList(Array.isArray(res.data) ? res.data as Medicine[] : []);
    else setError(res.message || 'Lỗi tải danh sách thuốc');
    setLoading(false);
  }, []);

  useEffect(() => {
    Promise.resolve().then(() => {
      load();
    });
  }, [load]);

  // ── Load last consult SUMMARY (not result) — chỉ để hiện banner, KHÔNG preload vào modal
  // Fix Bug 1: Trước đây preload consultResult → mở modal thấy ngay kết quả cũ
  // Chỉ đếm số lần tư vấn hoặc check if has history — KHÔNG setConsultResult
  const [hasLastConsult, setHasLastConsult] = useState(false);

  useEffect(() => {
    const checkLastConsult = async () => {
      try {
        const convRes = await AIApi.getConversations('CONSULT');
        if (convRes.success && convRes.data && convRes.data.length > 0) {
          setHasLastConsult(true);
        }
      } catch { /* silent */ }
    };
    checkLastConsult();
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

  // ── OCR Scanner Helpers ──
  const resetOCR = () => {
    setShowOCR(false);
    setOcrFile(null);
    if (ocrPreviewUrl) {
      URL.revokeObjectURL(ocrPreviewUrl);
    }
    setOcrPreviewUrl(null);
    setOcrLoading(false);
    setOcrProgress(0);
    setOcrError('');
    setOcrResults([]);
    setCheckedResults([]);
    setOcrSubmitting(false);
  };

  const handleOCRFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setOcrFile(file);
    const preview = URL.createObjectURL(file);
    setOcrPreviewUrl(preview);
    setOcrError('');
    setOcrResults([]);
    setOcrLoading(true);
    setOcrProgress(0);

    try {
      const ret = await Tesseract.recognize(
        file,
        'vie',
        {
          logger: (m) => {
            if (m.status === 'recognizing text') {
              setOcrProgress(Math.round(m.progress * 100));
            }
          },
        }
      );

      const parsed = PrescriptionParser.parse(ret.data.text);
      if (parsed.length === 0) {
        setOcrError('Không phát hiện được tên thuốc nào trong đơn này. Vui lòng thử lại với ảnh rõ nét hơn.');
      } else {
        setOcrResults(parsed);
        setCheckedResults(new Array(parsed.length).fill(true));
      }
    } catch (err) {
      console.error(err);
      setOcrError('Đã xảy ra lỗi trong quá trình quét OCR. Vui lòng tải lại ảnh.');
    } finally {
      setOcrLoading(false);
    }
  };

  const handleOCRSubmit = async () => {
    const medicinesToAdd = ocrResults.filter((_, idx) => checkedResults[idx]);
    if (medicinesToAdd.length === 0) return;

    setOcrSubmitting(true);
    setOcrError('');

    try {
      // Add each medicine sequentially
      for (const med of medicinesToAdd) {
        const body: CreateMedicineBody = {
          name: med.name,
          dosage: med.dosage || undefined,
          frequency: med.frequency || undefined,
          instruction: med.instruction || undefined,
          startDate: new Date().toISOString().slice(0, 10),
        };

        if (med.durationDays) {
          const end = new Date(Date.now() + med.durationDays * 24 * 3600 * 1000);
          body.endDate = end.toISOString().slice(0, 10);
        }

        await MedicinesApi.create(body);
      }

      await load();
      resetOCR();
    } catch (err) {
      console.error(err);
      setOcrError('Có lỗi xảy ra khi lưu một số loại thuốc. Vui lòng kiểm tra lại.');
    } finally {
      setOcrSubmitting(false);
    }
  };

  const handleToggleChecked = (idx: number) => {
    setCheckedResults(prev => {
      const copy = [...prev];
      copy[idx] = !copy[idx];
      return copy;
    });
  };

  const handleResultChange = (idx: number, field: keyof ParsedMedicine, value: string | number | null | undefined) => {
    setOcrResults(prev => {
      const copy = [...prev];
      copy[idx] = {
        ...copy[idx],
        [field]: value,
      };
      return copy;
    });
  };

  const handleRemoveResultRow = (idx: number) => {
    setOcrResults(prev => prev.filter((_, i) => i !== idx));
    setCheckedResults(prev => prev.filter((_, i) => i !== idx));
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
        const data = res.data;
        setConsultResult(data);

        const source: string = data.source ?? 'RECOMMENDATION_ENGINE';
        const isEmergencySource = source === 'EMERGENCY_GATE' || source === 'LLM_EMERGENCY_TRIAGE' || source === 'HOSPITAL_CONTEXT';
        if (isEmergencySource) setHasLastConsult(true);
      } else {
        setError(res.message || 'Lỗi kết nối AI. Vui lòng thử lại.');
      }
    } catch (err: unknown) {
      setError('Lỗi kết nối AI: ' + (err instanceof Error ? err.message : ''));
    } finally {
      setConsultLoading(false);
    }
  };

  const addMedFromResult = (med: RecommendationResponse['recommendedMedicines'][0]) => {
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
            className={styles.btnOCR}
            onClick={() => setShowOCR(true)}
          >
            <Upload size={18} />
            Quét đơn thuốc
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

      {/* ── Last consult result banner — chỉ hiện khi có lịch sử, KHÔNG chứa stale data ── */}
      {/* Fix Bug 1&4: Trước đây setConsultResult ngay khi load page → modal opened with stale data */}
      {!showConsult && hasLastConsult && !consultResult && (
        <div className={styles.lastResultBanner}>
          <div className={styles.lastResultHeader}>
            <div className={styles.lastResultIcon}>
              <Activity size={16} />
            </div>
            <div>
              <p className={styles.lastResultTitle}>{t('medications.last_result_title')}</p>
              <p className={styles.lastResultSub}>{t('medications.last_result_sub', { count: 0 })}</p>
            </div>
            <button
              type="button"
              className={styles.lastResultBtn}
              onClick={() => { setConsultResult(null); setSymptoms(''); setShowConsult(true); }}
            >
              {t('medications.new_consult')} <ChevronRight size={14} />
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
                    style={{ fontSize: '0.85rem', padding: '8px 16px', marginBottom: 12 }}
                    onClick={() => { setConsultResult(null); setSymptoms(''); }}
                  >
                    {t('medications.new_consult')}
                  </button>
                </div>

                {consultResult.message?.content && (
                  <div style={{
                    background: 'var(--surface)',
                    border: '1.5px solid var(--border)',
                    borderRadius: 20,
                    padding: 20,
                    marginBottom: 16,
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                      <Sparkles size={16} style={{ color: 'var(--primary)' }} />
                      <h3 style={{ fontSize: 15, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                        Phân tích y tế & Giải thích thuốc
                      </h3>
                    </div>
                    <div style={{ fontSize: 13.5, color: 'var(--text-secondary)', lineHeight: 1.65 }}>
                      <MarkdownContent content={consultResult.message.content} />
                    </div>
                  </div>
                )}

                <ConsultResultPanel
                  result={consultResult}
                  sessionId={consultResult.sessionId || ''}
                  onAddMedicine={addMedFromResult}
                  onNewConsult={() => { setConsultResult(null); setSymptoms(''); }}
                />
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

      {/* ── OCR Modal ── */}
      <Modal isOpen={showOCR} onClose={resetOCR}>
        <div className={styles.ocrModal}>
          <div className={styles.ocrModalHead}>
            <h3>Quét đơn thuốc bằng AI</h3>
            <button type="button" className={styles.closeBtn} onClick={resetOCR} disabled={ocrSubmitting}>
              <X size={18} />
            </button>
          </div>

          <div className={styles.ocrModalBody}>
            {ocrError && (
              <div className={styles.alert} style={{ marginBottom: 16 }}>
                <AlertTriangle size={14} />
                <span>{ocrError}</span>
              </div>
            )}

            {!ocrFile ? (
              <div
                className={styles.dragDropArea}
                onClick={() => fileInputRef.current?.click()}
              >
                <Upload size={32} className={styles.dragDropIcon} />
                <p className={styles.dragDropText}>Tải ảnh đơn thuốc lên</p>
                <p className={styles.dragDropSubtext}>Hỗ trợ định dạng JPG, PNG, WEBP. AI tự động tách đơn thuốc Việt Nam.</p>
                <input
                  type="file"
                  ref={fileInputRef}
                  style={{ display: 'none' }}
                  accept="image/*"
                  onChange={handleOCRFileChange}
                />
              </div>
            ) : (
              <div>
                <div className={styles.previewContainer}>
                  <img src={ocrPreviewUrl || ''} alt="Prescription preview" className={styles.previewImage} />
                  {!ocrLoading && !ocrSubmitting && (
                    <button type="button" className={styles.removePreviewBtn} onClick={() => { setOcrFile(null); setOcrPreviewUrl(null); setOcrResults([]); }}>
                      Chọn ảnh khác
                    </button>
                  )}
                </div>

                {ocrLoading && (
                  <div className={styles.progressContainer}>
                    <div className={styles.progressLabel}>Đang nhận diện chữ viết ({ocrProgress}%)</div>
                    <div className={styles.progressBar}>
                      <div className={styles.progressFill} style={{ width: `${ocrProgress}%` }} />
                    </div>
                  </div>
                )}

                {ocrResults.length > 0 && (
                  <div>
                    <h4 style={{ fontSize: '0.9rem', fontWeight: 700, marginBottom: 8, color: 'var(--text-primary)' }}>Kết quả quét đơn thuốc</h4>
                    <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginBottom: 12 }}>Bạn có thể chỉnh sửa lại các trường thông tin trước khi thêm vào tủ thuốc.</p>
                    <div className={styles.tableContainer}>
                      <table className={styles.ocrTable}>
                        <thead>
                          <tr>
                            <th style={{ width: '40px' }} />
                            <th>Tên thuốc</th>
                            <th>Liều dùng</th>
                            <th>Tần suất</th>
                            <th>Thời gian</th>
                            <th>Cách uống</th>
                            <th style={{ width: '40px' }} />
                          </tr>
                        </thead>
                        <tbody>
                          {ocrResults.map((r, idx) => (
                            <tr key={idx} style={{ opacity: checkedResults[idx] ? 1 : 0.5 }}>
                              <td>
                                <input
                                  type="checkbox"
                                  checked={checkedResults[idx]}
                                  onChange={() => handleToggleChecked(idx)}
                                  style={{ cursor: 'pointer' }}
                                />
                              </td>
                              <td>
                                <input
                                  type="text"
                                  className={styles.ocrInput}
                                  value={r.name}
                                  onChange={(e) => handleResultChange(idx, 'name', e.target.value)}
                                  disabled={ocrSubmitting}
                                />
                              </td>
                              <td>
                                <input
                                  type="text"
                                  className={styles.ocrInput}
                                  value={r.dosage}
                                  onChange={(e) => handleResultChange(idx, 'dosage', e.target.value)}
                                  disabled={ocrSubmitting}
                                />
                              </td>
                              <td>
                                <input
                                  type="text"
                                  className={styles.ocrInput}
                                  value={r.frequency}
                                  onChange={(e) => handleResultChange(idx, 'frequency', e.target.value)}
                                  disabled={ocrSubmitting}
                                />
                              </td>
                              <td>
                                <input
                                  type="number"
                                  className={styles.ocrInput}
                                  placeholder="Ngày"
                                  value={r.durationDays || ''}
                                  onChange={(e) => handleResultChange(idx, 'durationDays', parseInt(e.target.value) || null)}
                                  disabled={ocrSubmitting}
                                />
                              </td>
                              <td>
                                <input
                                  type="text"
                                  className={styles.ocrInput}
                                  value={r.instruction}
                                  onChange={(e) => handleResultChange(idx, 'instruction', e.target.value)}
                                  disabled={ocrSubmitting}
                                />
                              </td>
                              <td>
                                <button type="button" className={styles.rowDeleteBtn} onClick={() => handleRemoveResultRow(idx)} disabled={ocrSubmitting}>
                                  <Trash2 size={14} />
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>

          <div className={styles.ocrFooter}>
            <button type="button" className={styles.btnSecondary} onClick={resetOCR} disabled={ocrSubmitting}>
              Đóng
            </button>
            {ocrResults.length > 0 && (
              <button
                type="button"
                className={styles.btnPrimary}
                onClick={handleOCRSubmit}
                disabled={ocrSubmitting || ocrResults.filter((_, idx) => checkedResults[idx]).length === 0}
              >
                {ocrSubmitting ? (
                  <><Loader2 size={16} className={styles.spinner} /> Đang thêm...</>
                ) : (
                  `Thêm ${ocrResults.filter((_, idx) => checkedResults[idx]).length} thuốc`
                )}
              </button>
            )}
          </div>
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

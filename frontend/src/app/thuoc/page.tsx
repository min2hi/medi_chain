'use client';

import React, { useEffect, useState } from 'react';
import { Pill, Plus, Pencil, Trash2, Loader2, X, Bell } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { MedicinesApi } from '@/services/api.client';
import { Modal } from '@/components/shared/Modal';
import styles from './thuoc.module.css';

type Medicine = {
  id: string;
  name: string;
  dosage?: string | null;
  frequency?: string | null;
  instruction?: string | null;
  startDate: string;
  endDate?: string | null;
};

export default function ThuocPage() {
  const [list, setList] = useState<Medicine[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [submitLoading, setSubmitLoading] = useState(false);
  const [error, setError] = useState('');

  const [form, setForm] = useState({
    name: '',
    dosage: '',
    frequency: '',
    instruction: '',
    startDate: new Date().toISOString().slice(0, 10),
    endDate: '',
  });

  const load = async () => {
    setLoading(true);
    setError('');
    const res = await MedicinesApi.list();
    if (res.success && res.data) setList(Array.isArray(res.data) ? res.data as Medicine[] : []);
    else setError(res.message || 'Lỗi tải danh sách thuốc');
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

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

  const resetForm = () => {
    setShowForm(false);
    setEditingId(null);
    setForm({ name: '', dosage: '', frequency: '', instruction: '', startDate: new Date().toISOString().slice(0, 10), endDate: '' });
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
    };
    if (editingId) {
      const res = await MedicinesApi.update(editingId, body);
      if (res.success) { load(); resetForm(); } else setError(res.message || 'Lỗi cập nhật');
    } else {
      const res = await MedicinesApi.create(body);
      if (res.success) { load(); resetForm(); } else setError(res.message || 'Lỗi thêm thuốc');
    }
    setSubmitLoading(false);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Xóa thuốc này khỏi danh sách?')) return;
    setSubmitLoading(true);
    const res = await MedicinesApi.delete(id);
    if (res.success) load(); else setError(res.message || 'Lỗi xóa');
    setSubmitLoading(false);
  };

  const [showConsult, setShowConsult] = useState(false);
  const [symptoms, setSymptoms] = useState('');
  const [consultLoading, setConsultLoading] = useState(false);
  const [consultResult, setConsultResult] = useState<any>(null);

  if (loading) {
    return (
      <div className={styles.loading}>
        <Loader2 size={32} className={styles.spinner} />
        <p>Đang tải...</p>
      </div>
    );
  }

  // ... (previous load, openEdit, resetForm functions)

  const handleConsult = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!symptoms.trim()) return;
    setConsultLoading(true);
    const res = await import('@/services/api.client').then(m => m.AIApi.consult(symptoms));
    if (res.success) {
      setConsultResult(res);
    } else {
      setError(res.message || 'Lỗi tư vấn');
    }
    setConsultLoading(false);
  };

  const closeConsult = () => {
    setShowConsult(false);
    setSymptoms('');
    setConsultResult(null);
  };

  // ... (previous functions)

  return (
    <div>
      <header className={styles.header}>
        <h1 className={styles.title}>Quản lý thuốc</h1>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button type="button" className={styles.btnSecondary} onClick={() => setShowConsult(true)}>
            <img src="/icons/sparkles.svg" alt="AI" width={18} height={18} style={{ marginRight: 8 }} />
            <span>AI Tư vấn</span>
          </button>
          <button type="button" className={styles.btnPrimary} onClick={() => { resetForm(); setShowForm(true); }}>
            <Plus size={20} />
            <span>Thêm thuốc</span>
          </button>
        </div>
      </header>

      {/* ... (Alert and Error sections) */}
      {list.length === 0 && (
        <div className={styles.alert}>
          <Bell size={20} className={styles.alertIcon} />
          <p>Bạn chưa thiết lập lịch uống thuốc. Thêm thuốc để theo dõi và nhắc nhở.</p>
        </div>
      )}

      {error && <div className={styles.errorMsg}>{error}</div>}

      <section className={styles.section}>
        {/* ... (List or Empty State) */}
        <h2 className={styles.sectionTitle}>Thuốc đang uống</h2>
        {list.length === 0 ? (
          <EmptyState
            icon={Pill}
            title="Chưa có thuốc nào"
            description="Thêm thuốc bạn đang sử dụng để theo dõi liều và ngày hết hạn."
            action={
              <button type="button" className={styles.btnPrimary} onClick={() => setShowForm(true)}>
                Thêm thuốc
              </button>
            }
          />
        ) : (
          <ul className={styles.medList}>
            {list.map((m) => (
              <li key={m.id} className={styles.medItem}>
                <div className={styles.medMain}>
                  <h3 className={styles.medName}>{m.name}</h3>
                  {(m.dosage || m.frequency) && (
                    <p className={styles.medMeta}>
                      {m.dosage && <span>Liều: {m.dosage}</span>}
                      {m.frequency && <span> · {m.frequency}</span>}
                    </p>
                  )}
                  <p className={styles.medDates}>
                    Bắt đầu: {new Date(m.startDate).toLocaleDateString('vi-VN')}
                    {m.endDate && ` · Hết hạn: ${new Date(m.endDate).toLocaleDateString('vi-VN')}`}
                  </p>
                  {m.instruction && <p className={styles.medInstruction}>{m.instruction}</p>}
                </div>
                <div className={styles.medActions}>
                  <button type="button" className={styles.iconBtn} onClick={() => openEdit(m)} title="Sửa"><Pencil size={18} /></button>
                  <button type="button" className={styles.iconBtnDanger} onClick={() => handleDelete(m.id)} title="Xóa"><Trash2 size={18} /></button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* Consult Modal */}
      <Modal isOpen={showConsult} onClose={closeConsult}>
        <div className={styles.modal} style={{ maxWidth: '600px' }}>
          <div className={styles.modalHead}>
            <h3>AI Dược sĩ Tư vấn</h3>
            <button type="button" className={styles.closeBtn} onClick={closeConsult}><X size={24} /></button>
          </div>

          {!consultResult ? (
            <form onSubmit={handleConsult} className={styles.form}>
              <label className={styles.labelBlock}>Triệu chứng của bạn là gì?</label>
              <textarea
                className={styles.textarea}
                rows={4}
                value={symptoms}
                onChange={(e) => setSymptoms(e.target.value)}
                placeholder="VD: Tôi bị đau đầu và sốt nhẹ từ chiều qua..."
                autoFocus
              />
              <div className={styles.formFooter}>
                <button type="button" className={styles.btnSecondary} onClick={closeConsult}>Đóng</button>
                <button type="submit" className={styles.btnPrimary} disabled={consultLoading || !symptoms.trim()}>
                  {consultLoading ? <Loader2 size={20} className={styles.spinner} /> : 'Phân tích & Tư vấn'}
                </button>
              </div>
            </form>
          ) : (
            <div className={styles.consultResult}>
              {consultResult.warnings && (
                <div className={styles.alert} style={{ backgroundColor: '#fff4f4', border: '1px solid #ffcaca', color: '#d32f2f' }}>
                  <Bell size={20} className={styles.alertIcon} />
                  <div>
                    <strong>CẢNH BÁO QUAN TRỌNG:</strong>
                    <p>{consultResult.warnings}</p>
                  </div>
                </div>
              )}

              <div style={{ margin: '16px 0' }}>
                <h4 style={{ marginBottom: '8px' }}>🔍 Phân tích:</h4>
                <p style={{ lineHeight: '1.5', color: '#4b5563' }}>{consultResult.analysis}</p>
              </div>

              {consultResult.recommendations && consultResult.recommendations.length > 0 && (
                <div style={{ margin: '16px 0' }}>
                  <h4 style={{ marginBottom: '12px' }}>💊 Thuốc đề xuất:</h4>
                  <div style={{ display: 'grid', gap: '12px' }}>
                    {consultResult.recommendations.map((rec: any, idx: number) => (
                      <div key={idx} style={{ padding: '12px', border: '1px solid #e5e7eb', borderRadius: '8px', background: '#f9fafb' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                          <strong style={{ color: '#111827' }}>{rec.medicine_name}</strong>
                          <span style={{ fontSize: '13px', padding: '2px 8px', borderRadius: '12px', background: '#e0f2fe', color: '#0369a1' }}>OTC</span>
                        </div>
                        <p style={{ fontSize: '14px', margin: '4px 0' }}>dosage: {rec.dosage}</p>
                        <p style={{ fontSize: '14px', color: '#6b7280', fontStyle: 'italic' }}>"{rec.reason}"</p>
                        {rec.note && <p style={{ fontSize: '13px', marginTop: '6px', padding: '6px', background: '#fffbeb', borderRadius: '4px', color: '#92400e' }}>Note: {rec.note}</p>}
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <div className={styles.formFooter} style={{ marginTop: '24px', borderTop: '1px solid #e5e7eb', paddingTop: '16px' }}>
                <p style={{ fontSize: '12px', color: '#9ca3af', flex: 1 }}>
                  *Thông tin chỉ mang tính tham khảo. Vui lòng hỏi ý kiến bác sĩ chuyên khoa.
                </p>
                <button type="button" className={styles.btnPrimary} onClick={() => { setConsultResult(null); }}>Tư vấn khác</button>
              </div>
            </div>
          )}
        </div>
      </Modal>

      <Modal isOpen={showForm} onClose={resetForm}>
        {/* ... (existing form modal content) */}
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>{editingId ? 'Chỉnh sửa thuốc' : 'Thêm thuốc'}</h3>
            <button type="button" className={styles.closeBtn} onClick={resetForm}><X size={24} /></button>
          </div>
          <form onSubmit={handleSubmit} className={styles.form}>
            <label className={styles.labelBlock}>Tên thuốc *</label>
            <input className={styles.input} value={form.name} onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))} required placeholder="VD: Paracetamol" />
            <label className={styles.labelBlock}>Liều dùng</label>
            <input className={styles.input} value={form.dosage} onChange={(e) => setForm((f) => ({ ...f, dosage: e.target.value }))} placeholder="VD: 500mg x 2 viên" />
            <label className={styles.labelBlock}>Tần suất</label>
            <input className={styles.input} value={form.frequency} onChange={(e) => setForm((f) => ({ ...f, frequency: e.target.value }))} placeholder="VD: 3 lần/ngày, sau ăn" />
            <label className={styles.labelBlock}>Hướng dẫn</label>
            <textarea className={styles.textarea} rows={2} value={form.instruction} onChange={(e) => setForm((f) => ({ ...f, instruction: e.target.value }))} placeholder="Ghi chú thêm" />
            <label className={styles.labelBlock}>Ngày bắt đầu</label>
            <input type="date" className={styles.input} value={form.startDate} onChange={(e) => setForm((f) => ({ ...f, startDate: e.target.value }))} />
            <label className={styles.labelBlock}>Ngày hết hạn (tùy chọn)</label>
            <input type="date" className={styles.input} value={form.endDate} onChange={(e) => setForm((f) => ({ ...f, endDate: e.target.value }))} />
            <div className={styles.formFooter}>
              <button type="button" className={styles.btnSecondary} onClick={resetForm}>Hủy</button>
              <button type="submit" className={styles.btnPrimary} disabled={submitLoading}>
                {submitLoading ? <Loader2 size={20} className={styles.spinner} /> : (editingId ? 'Cập nhật' : 'Thêm')}
              </button>
            </div>
          </form>
        </div>
      </Modal>

      <button type="button" className={styles.fabMobile} onClick={() => { resetForm(); setShowForm(true); }} aria-label="Thêm thuốc">
        <Plus size={24} />
      </button>
    </div>
  );
}

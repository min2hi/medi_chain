'use client';

import React, { useEffect, useState } from 'react';
import { Calendar, Plus, Pencil, Trash2, Loader2, X } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { AppointmentsApi } from '@/services/api.client';
import { Modal } from '@/components/shared/Modal';
import styles from './lich-hen.module.css';

type Appointment = {
  id: string;
  title: string;
  date: string;
  status: string;
  notes?: string | null;
};

const STATUS_LABEL: Record<string, string> = {
  PENDING: 'Chờ xác nhận',
  CONFIRMED: 'Đã xác nhận',
  COMPLETED: 'Đã hoàn thành',
  CANCELLED: 'Đã hủy',
};

export default function LichHenPage() {
  const [list, setList] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [submitLoading, setSubmitLoading] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState({
    title: '',
    date: new Date().toISOString().slice(0, 16),
    notes: '',
  });

  const load = async () => {
    setLoading(true);
    setError('');
    const res = await AppointmentsApi.list();
    if (res.success && res.data) setList(Array.isArray(res.data) ? res.data as Appointment[] : []);
    else setError(res.message || 'Lỗi tải lịch hẹn');
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const openEdit = (a: Appointment) => {
    setEditingId(a.id);
    const d = new Date(a.date);
    const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    setForm({ title: a.title, date: local, notes: a.notes || '' });
    setShowForm(true);
  };

  const resetForm = () => {
    setShowForm(false);
    setEditingId(null);
    setForm({ title: '', date: new Date().toISOString().slice(0, 16), notes: '' });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) return;
    setSubmitLoading(true);
    setError('');
    const dateIso = new Date(form.date).toISOString();
    if (editingId) {
      const res = await AppointmentsApi.update(editingId, { title: form.title, date: dateIso, notes: form.notes || undefined });
      if (res.success) { load(); resetForm(); } else setError(res.message || 'Lỗi cập nhật');
    } else {
      const res = await AppointmentsApi.create({ title: form.title, date: dateIso, notes: form.notes || undefined });
      if (res.success) { load(); resetForm(); } else setError(res.message || 'Lỗi tạo lịch hẹn');
    }
    setSubmitLoading(false);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Xóa lịch hẹn này?')) return;
    setSubmitLoading(true);
    const res = await AppointmentsApi.delete(id);
    if (res.success) load(); else setError(res.message || 'Lỗi xóa');
    setSubmitLoading(false);
  };

  const isPast = (dateStr: string) => new Date(dateStr) < new Date();

  if (loading) {
    return (
      <div className={styles.loading}>
        <Loader2 size={32} className={styles.spinner} />
        <p>Đang tải...</p>
      </div>
    );
  }

  return (
    <div>
      <header className={styles.header}>
        <h1 className={styles.title}>Lịch hẹn / Tái khám</h1>
        <button type="button" className={styles.btnPrimary} onClick={() => { resetForm(); setShowForm(true); }}>
          <Plus size={20} />
          <span>Thêm lịch hẹn</span>
        </button>
      </header>
      {error && <div className={styles.errorMsg}>{error}</div>}
      <section className={styles.section}>
        {list.length === 0 ? (
          <EmptyState
            icon={Calendar}
            title="Chưa có lịch hẹn"
            description="Thêm lịch tái khám hoặc hẹn bác sĩ để không bỏ lỡ."
            action={<button type="button" className={styles.btnPrimary} onClick={() => setShowForm(true)}>Thêm lịch hẹn</button>}
          />
        ) : (
          <ul className={styles.list}>
            {list.map((a) => (
              <li key={a.id} className={isPast(a.date) ? `${styles.item} ${styles.itemPast}` : styles.item}>
                <div className={styles.itemMain}>
                  <h3 className={styles.itemTitle}>{a.title}</h3>
                  <p className={styles.itemDate}>{new Date(a.date).toLocaleString('vi-VN', { dateStyle: 'medium', timeStyle: 'short' })}</p>
                  <span className={styles.itemStatus}>{STATUS_LABEL[a.status] || a.status}</span>
                  {a.notes && <p className={styles.itemNotes}>{a.notes}</p>}
                </div>
                <div className={styles.itemActions}>
                  {!isPast(a.date) && <button type="button" className={styles.iconBtn} onClick={() => openEdit(a)} title="Sửa"><Pencil size={18} /></button>}
                  <button type="button" className={styles.iconBtnDanger} onClick={() => handleDelete(a.id)} title="Xóa"><Trash2 size={18} /></button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
      <Modal isOpen={showForm} onClose={resetForm}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>{editingId ? 'Chỉnh sửa lịch hẹn' : 'Thêm lịch hẹn'}</h3>
            <button type="button" className={styles.closeBtn} onClick={resetForm}><X size={24} /></button>
          </div>
          <form onSubmit={handleSubmit} className={styles.form}>
            <label className={styles.labelBlock}>Tiêu đề *</label>
            <input className={styles.input} value={form.title} onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} required placeholder="VD: Tái khám nội tổng quát" />
            <label className={styles.labelBlock}>Ngày giờ *</label>
            <input type="datetime-local" className={styles.input} value={form.date} onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))} required />
            <label className={styles.labelBlock}>Ghi chú</label>
            <textarea className={styles.textarea} rows={3} value={form.notes} onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))} placeholder="Địa chỉ, bác sĩ..." />
            <div className={styles.formFooter}>
              <button type="button" className={styles.btnSecondary} onClick={resetForm}>Hủy</button>
              <button type="submit" className={styles.btnPrimary} disabled={submitLoading}>
                {submitLoading ? <Loader2 size={20} className={styles.spinner} /> : (editingId ? 'Cập nhật' : 'Thêm')}
              </button>
            </div>
          </form>
        </div>
      </Modal>
      <button type="button" className={styles.fabMobile} onClick={() => { resetForm(); setShowForm(true); }} aria-label="Thêm lịch hẹn"><Plus size={24} /></button>
    </div>
  );
}

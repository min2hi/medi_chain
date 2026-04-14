'use client';

import React, { useEffect, useState } from 'react';
import { Calendar, Plus, Pencil, Trash2, Loader2, X } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { AppointmentsApi } from '@/services/api.client';
import { ListSkeleton } from '@/components/shared/PageSkeleton';
import { Modal } from '@/components/shared/Modal';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import styles from './lich-hen.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

type Appointment = {
  id: string;
  title: string;
  date: string;
  status: string;
  notes?: string | null;
};

export default function LichHenPage() {
  const { t } = useTranslation();

  const STATUS_LABEL: Record<string, string> = {
    PENDING: t('appointments.status_pending'),
    CONFIRMED: t('appointments.status_confirmed'),
    COMPLETED: t('appointments.status_completed'),
    CANCELLED: t('appointments.status_cancelled'),
  };

  const [list, setList] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
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

  const confirmDelete = (id: string) => {
    setDeletingId(id);
    setShowConfirm(true);
  };

  const handleDelete = async () => {
    if (!deletingId) return;
    setSubmitLoading(true);
    const res = await AppointmentsApi.delete(deletingId);
    if (res.success) {
      load();
      setShowConfirm(false);
      setDeletingId(null);
    } else {
      setError(res.message || 'Lỗi xóa');
    }
    setSubmitLoading(false);
  };

  const isPast = (dateStr: string) => new Date(dateStr) < new Date();

  if (loading) return <ListSkeleton itemCount={3} btnCount={1} />;

  return (
    <div className="animate-fade-in">
      <header className={styles.header}>
        <h1 className={styles.title}>{t('appointments.title')}</h1>
        <button type="button" className={styles.btnPrimary} onClick={() => { resetForm(); setShowForm(true); }}>
          <Plus size={20} />
          <span>{t('appointments.add_appointment')}</span>
        </button>
      </header>

      {error && <div className={styles.errorMsg}>{error}</div>}

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('appointments.upcoming_schedule')}</h2>
        {list.length === 0 ? (
          <EmptyState
            icon={Calendar}
            title={t('appointments.no_appointments')}
            description={t('appointments.no_appointments_desc')}
            action={<button type="button" className={styles.btnPrimary} onClick={() => setShowForm(true)}>{t('appointments.add_appointment')}</button>}
          />
        ) : (
          <ul className={styles.list}>
            {list.map((a) => (
              <li key={a.id} className={isPast(a.date) ? `${styles.item} ${styles.itemPast}` : styles.item}>
                <div className={styles.itemMain}>
                  <h3 className={styles.itemTitle}>{a.title}</h3>
                  <p className={styles.itemDate}>
                    {new Date(a.date).toLocaleString('vi-VN', { dateStyle: 'medium', timeStyle: 'short' })}
                  </p>
                  <div className="mb-2">
                    <span className={styles.itemStatus}>{STATUS_LABEL[a.status] || a.status}</span>
                  </div>
                  {a.notes && <p className={styles.itemNotes}>{a.notes}</p>}
                </div>
                <div className={styles.itemActions}>
                  {!isPast(a.date) && (
                    <button type="button" className={styles.iconBtn} onClick={() => openEdit(a)} title="Sửa">
                      <Pencil size={18} />
                    </button>
                  )}
                  <button type="button" className={styles.iconBtnDanger} onClick={() => confirmDelete(a.id)} title="Xóa">
                    <Trash2 size={18} />
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      <Modal isOpen={showForm} onClose={resetForm}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>{editingId ? t('appointments.edit_appointment') : t('appointments.add_appointment')}</h3>
            <button type="button" className={styles.closeBtn} onClick={resetForm} disabled={submitLoading}><X size={22} /></button>
          </div>
          <form id="appointment-form" className={styles.formContentWrap} onSubmit={handleSubmit}>
            <div className={styles.formBody}>
              <div className={styles.formGrid}>
                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>
                    {t('appointments.title_req')} <span className={styles.required}>*</span>
                  </label>
                  <input
                    className={styles.input}
                    value={form.title}
                    onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                    required
                    placeholder={t('appointments.title_ph')}
                    disabled={submitLoading}
                    autoFocus
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>
                    {t('appointments.datetime')} <span className={styles.required}>*</span>
                  </label>
                  <input
                    type="datetime-local"
                    className={styles.input}
                    value={form.date}
                    onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))}
                    required
                    disabled={submitLoading}
                  />
                </div>

                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>
                    {t('appointments.notes')}
                  </label>
                  <textarea
                    className={styles.textarea}
                    rows={3}
                    value={form.notes}
                    onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))}
                    placeholder={t('appointments.notes_ph')}
                    disabled={submitLoading}
                  />
                </div>
              </div>
            </div>

            <div className={styles.formFooter}>
              <button
                type="button"
                className={styles.modalBtnSecondary}
                onClick={resetForm}
                disabled={submitLoading}
              >
                {t('appointments.cancel')}
              </button>
              <button
                type="submit"
                className={styles.modalBtnPrimary}
                disabled={submitLoading}
              >
                {submitLoading ? (
                  <>
                    <Loader2 size={20} className={styles.spinner} style={{ marginRight: '8px' }} />
                    {t('appointments.saving')}
                  </>
                ) : (editingId ? t('appointments.update') : t('appointments.confirm_add'))}
              </button>
            </div>
          </form>
        </div>
      </Modal>

      <ConfirmModal
        isOpen={showConfirm}
        onClose={() => setShowConfirm(false)}
        onConfirm={handleDelete}
        title={t('appointments.delete_title')}
        message={t('appointments.delete_message')}
        confirmText={t('appointments.confirm_delete')}
        loading={submitLoading}
      />

      <button type="button" className={styles.fabMobile} onClick={() => { resetForm(); setShowForm(true); }} aria-label="Thêm lịch hẹn"><Plus size={24} /></button>
    </div>
  );
}

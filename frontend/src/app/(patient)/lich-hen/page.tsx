'use client';

import React, { useEffect, useState } from 'react';
import { Calendar, Plus, Pencil, Trash2, Loader2, X } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { AppointmentsApi, PaymentApi, UserApi } from '@/services/api.client';
import { ListSkeleton } from '@/components/shared/PageSkeleton';
import { Modal } from '@/components/shared/Modal';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import styles from './lich-hen.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

type DoctorProfile = {
  specialty?: string | null;
  clinicAddress?: string | null;
  licenseVerified?: boolean;
};

type Doctor = {
  id: string;
  name: string;
  email?: string;
  image?: string | null;
  profile?: DoctorProfile | null;
};

type Appointment = {
  id: string;
  title: string;
  date: string;
  status: string;
  notes?: string | null;
  paymentStatus: string;
  doctorId?: string | null;
  consultFee?: number | null;
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
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [loadingDoctors, setLoadingDoctors] = useState(false);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [submitLoading, setSubmitLoading] = useState(false);
  const [paymentLoadingMap, setPaymentLoadingMap] = useState<Record<string, boolean>>({});
  const [error, setError] = useState('');
  
  const [form, setForm] = useState({
    doctorId: '',
    reason: '',
    date: new Date().toISOString().slice(0, 16),
    notes: '',
  });

  const load = async () => {
    setLoading(true);
    setError('');
    const res = await AppointmentsApi.list();
    if (res.success && res.data) {
      setList(Array.isArray(res.data) ? (res.data as Appointment[]) : []);
    } else {
      setError(res.message || 'Lỗi tải lịch hẹn');
    }
    setLoading(false);
  };

  const loadDoctors = async () => {
    setLoadingDoctors(true);
    const res = await UserApi.getDoctors();
    if (res.success && res.data) {
      setDoctors(Array.isArray(res.data) ? (res.data as Doctor[]) : []);
    }
    setLoadingDoctors(false);
  };

  useEffect(() => {
    Promise.resolve().then(() => {
      load();
      loadDoctors();
    });
  }, []);

  const openEdit = (a: Appointment) => {
    setEditingId(a.id);
    const d = new Date(a.date);
    const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    
    // Extract reason from title if possible: e.g. "Khám với Bác sĩ A — Đau đầu" -> "Đau đầu"
    let extractedReason = a.title;
    const match = a.title.match(/Khám với .*? — (.*)/);
    if (match) {
      extractedReason = match[1];
    }

    setForm({
      doctorId: a.doctorId || '',
      reason: extractedReason,
      date: local,
      notes: a.notes || '',
    });
    setShowForm(true);
  };

  const resetForm = () => {
    setShowForm(false);
    setEditingId(null);
    setForm({
      doctorId: '',
      reason: '',
      date: new Date().toISOString().slice(0, 16),
      notes: '',
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.doctorId) {
      setError('Vui lòng chọn bác sĩ khám');
      return;
    }
    if (!form.reason.trim()) {
      setError('Vui lòng nhập lý do khám');
      return;
    }
    setSubmitLoading(true);
    setError('');
    
    const selectedDoctor = doctors.find((d) => d.id === form.doctorId);
    const doctorName = selectedDoctor ? selectedDoctor.name : 'Bác sĩ';
    const title = `Khám với ${doctorName} — ${form.reason.trim()}`;
    const dateIso = new Date(form.date).toISOString();
    
    const payload = {
      title,
      date: dateIso,
      doctorId: form.doctorId,
      notes: form.notes.trim() || undefined,
    };

    if (editingId) {
      const res = await AppointmentsApi.update(editingId, payload);
      if (res.success) {
        load();
        resetForm();
      } else {
        setError(res.message || 'Lỗi cập nhật');
      }
    } else {
      const res = await AppointmentsApi.create(payload);
      if (res.success) {
        load();
        resetForm();
        // Automatically redirect to PayOS checkout immediately after creation
        const createdApp = res.data as { id?: string } | undefined;
        if (createdApp && createdApp.id) {
          handlePayment(createdApp.id);
        }
      } else {
        setError(res.message || 'Lỗi tạo lịch hẹn');
      }
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

  const handlePayment = async (appointmentId: string) => {
    setPaymentLoadingMap((prev) => ({ ...prev, [appointmentId]: true }));
    setError('');
    try {
      const res = await PaymentApi.createOrder(appointmentId);
      if (res.success && res.data?.checkoutUrl) {
        window.location.href = res.data.checkoutUrl;
      } else {
        setError(res.message || 'Lỗi khi tạo liên kết thanh toán PayOS.');
      }
    } catch (err) {
      console.error(err);
      setError('Không thể tạo liên kết thanh toán. Vui lòng kiểm tra lại kết nối mạng.');
    } finally {
      setPaymentLoadingMap((prev) => ({ ...prev, [appointmentId]: false }));
    }
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
            {list.map((a) => {
              const doc = doctors.find((d) => d.id === a.doctorId);
              return (
                <li key={a.id} className={isPast(a.date) ? `${styles.item} ${styles.itemPast}` : styles.item}>
                  <div className={styles.itemMain}>
                    <h3 className={styles.itemTitle}>{a.title}</h3>
                    <p className={styles.itemDate}>
                      {new Date(a.date).toLocaleString('vi-VN', { dateStyle: 'medium', timeStyle: 'short' })}
                    </p>
                    
                    {doc && (
                      <div className={styles.itemDoctor}>
                        <span>{t('appointments.doctor_label')}: </span>
                        <strong>{doc.name}</strong>
                        {doc.profile?.specialty && ` (${doc.profile.specialty})`}
                      </div>
                    )}

                    <div style={{ display: 'flex', gap: '8px', marginBottom: '12px', flexWrap: 'wrap' }}>
                      <span className={styles.itemStatus}>{STATUS_LABEL[a.status] || a.status}</span>
                      {a.paymentStatus === 'PAID' && (
                        <span className={styles.badgePaid}>{t('appointments.payment_status_paid')}</span>
                      )}
                      {(a.paymentStatus === 'UNPAID' || a.paymentStatus === 'FAILED') && (
                        <span className={styles.badgeUnpaid}>{t('appointments.payment_status_unpaid')}</span>
                      )}
                      {a.paymentStatus === 'PENDING' && (
                        <span className={styles.badgePending}>{t('appointments.payment_status_pending')}</span>
                      )}
                    </div>

                    {a.consultFee && (
                      <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '8px' }}>
                        Phí khám: <strong>{a.consultFee.toLocaleString('vi-VN')} VND</strong>
                      </p>
                    )}

                    {a.notes && <p className={styles.itemNotes}>{a.notes}</p>}
                    
                    {a.status === 'PENDING' && a.paymentStatus !== 'PAID' && !isPast(a.date) && (
                      <div style={{ marginTop: '10px' }}>
                        <button
                          type="button"
                          onClick={() => handlePayment(a.id)}
                          disabled={paymentLoadingMap[a.id]}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                            padding: '6px 14px',
                            borderRadius: 8,
                            background: '#059669',
                            color: 'white',
                            fontWeight: 700,
                            fontSize: '0.8rem',
                            border: 'none',
                            cursor: 'pointer',
                            transition: 'all 0.2s',
                            boxShadow: '0 2px 6px rgba(5, 150, 105, 0.15)',
                          }}
                        >
                          {paymentLoadingMap[a.id] ? (
                            <><Loader2 size={12} className={styles.spinner} style={{ animation: 'spin 1s linear infinite', color: 'white', marginRight: '4px' }} /> Đang kết nối...</>
                          ) : (
                            t('appointments.pay_now')
                          )}
                        </button>
                      </div>
                    )}
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
              );
            })}
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
                    {t('appointments.doctor_label')} <span className={styles.required}>*</span>
                  </label>
                  <select
                    className={styles.input}
                    value={form.doctorId}
                    onChange={(e) => setForm((f) => ({ ...f, doctorId: e.target.value }))}
                    required
                    disabled={submitLoading || loadingDoctors}
                    style={{ appearance: 'auto' }}
                  >
                    <option value="">-- {t('appointments.doctor_select')} --</option>
                    {doctors.map((d) => (
                      <option key={d.id} value={d.id}>
                        {d.name} {d.profile?.specialty ? `(${d.profile.specialty})` : ''}
                      </option>
                    ))}
                  </select>
                </div>

                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>
                    {t('appointments.reason_label')} <span className={styles.required}>*</span>
                  </label>
                  <input
                    className={styles.input}
                    value={form.reason}
                    onChange={(e) => setForm((f) => ({ ...f, reason: e.target.value }))}
                    required
                    placeholder={t('appointments.reason_ph')}
                    disabled={submitLoading}
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

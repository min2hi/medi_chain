'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { History, Plus, Pencil, Trash2, Loader2, X, ClipboardList } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { ProfileSkeleton } from '@/components/shared/PageSkeleton';
import { RecordsApi, ProfileApi, MetricsApi } from '@/services/api.client';
import { Modal } from '@/components/shared/Modal';
import styles from './ho-so.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

type Record = {
  id: string;
  title: string;
  content?: string | null;
  diagnosis?: string | null;
  treatment?: string | null;
  hospital?: string | null;
  date: string;
};

type Profile = {
  id?: string;
  bloodType?: string | null;
  allergies?: string | null;
  chronicConditions?: string | null;
  weight?: number | null;
  height?: number | null;
  gender?: string | null;
  birthday?: string | null;
  address?: string | null;
  phone?: string | null;
};

type Metric = { id: string; type: string; value: number; unit: string; date: string };

export default function HoSoPage() {
  const { t } = useTranslation();
  const [records, setRecords] = useState<Record[]>([]);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [metrics, setMetrics] = useState<Metric[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showProfileForm, setShowProfileForm] = useState(false);
  const [showMetricForm, setShowMetricForm] = useState(false);
  const [submitLoading, setSubmitLoading] = useState(false);
  const [error, setError] = useState('');

  const [form, setForm] = useState({ title: '', content: '', diagnosis: '', treatment: '', hospital: '', date: new Date().toISOString().slice(0, 10) });
  const [profileForm, setProfileForm] = useState<{ [key: string]: string | number }>({ bloodType: '', allergies: '', chronicConditions: '', weight: '', height: '', gender: '', birthday: '', address: '', phone: '' });
  const [metricForm, setMetricForm] = useState({ type: 'huyết áp', value: '', unit: 'mmHg', date: new Date().toISOString().slice(0, 10) });

  const load = async () => {
    setLoading(true);
    setError('');
    const [rRes, pRes, mRes] = await Promise.all([
      RecordsApi.list(),
      ProfileApi.get(),
      MetricsApi.list(30),
    ]);
    if (rRes.success && rRes.data) setRecords(Array.isArray(rRes.data) ? rRes.data as Record[] : []);
    if (pRes.success && pRes.data) setProfile(pRes.data as Profile);
    if (mRes.success && mRes.data) setMetrics(Array.isArray(mRes.data) ? mRes.data as Metric[] : []);
    if (!rRes.success) setError(rRes.message || 'Lỗi tải dữ liệu');
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const openEdit = (r: Record) => {
    setEditingId(r.id);
    setForm({
      title: r.title,
      content: r.content || '',
      diagnosis: r.diagnosis || '',
      treatment: r.treatment || '',
      hospital: r.hospital || '',
      date: r.date ? new Date(r.date).toISOString().slice(0, 10) : '',
    });
    setShowForm(true);
  };

  const openProfileEdit = () => {
    setProfileForm({
      bloodType: profile?.bloodType || '',
      allergies: profile?.allergies || '',
      chronicConditions: profile?.chronicConditions || '',
      weight: profile?.weight ?? '',
      height: profile?.height ?? '',
      gender: profile?.gender || '',
      birthday: profile?.birthday ? new Date(profile.birthday).toISOString().slice(0, 10) : '',
      address: profile?.address || '',
      phone: profile?.phone || '',
    });
    setShowProfileForm(true);
  };

  const resetForm = () => {
    setShowForm(false);
    setEditingId(null);
    setForm({ title: '', content: '', diagnosis: '', treatment: '', hospital: '', date: new Date().toISOString().slice(0, 10) });
  };

  const handleSubmitRecord = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) return;
    setSubmitLoading(true);
    setError('');
    if (editingId) {
      const res = await RecordsApi.update(editingId, { ...form, date: form.date || undefined });
      if (res.success) { load(); resetForm(); } else setError(res.message || 'Lỗi cập nhật');
    } else {
      const res = await RecordsApi.create({ ...form, date: form.date || undefined });
      if (res.success) { load(); resetForm(); } else setError(res.message || 'Lỗi tạo hồ sơ');
    }
    setSubmitLoading(false);
  };

  const handleDeleteRecord = async (id: string) => {
    if (!confirm(t('profile.delete_confirm'))) return;
    setSubmitLoading(true);
    const res = await RecordsApi.delete(id);
    if (res.success) load(); else setError(res.message || 'Lỗi xóa');
    setSubmitLoading(false);
  };

  const calculateAge = (birthday: string) => {
    if (!birthday) return 0;
    const birthDate = new Date(birthday);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  };

  const handleSubmitProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitLoading(true);
    setError('');

    // Validation thông minh
    const weight = profileForm.weight !== '' ? Number(profileForm.weight) : null;
    const height = profileForm.height !== '' ? Number(profileForm.height) : null;
    const birthday = profileForm.birthday as string;

    if (weight !== null && weight <= 0) {
      setError('Cân nặng phải là số dương lớn hơn 0.');
      setSubmitLoading(false);
      return;
    }
    if (height !== null && height <= 0) {
      setError('Chiều cao phải là số dương lớn hơn 0.');
      setSubmitLoading(false);
      return;
    }

    if (birthday) {
      const birthDate = new Date(birthday);
      if (birthDate > new Date()) {
        setError('Ngày sinh không được là ngày trong tương lai.');
        setSubmitLoading(false);
        return;
      }

      const age = calculateAge(birthday);
      // Heuristic checks
      if (age > 15 && weight !== null && weight < 20) {
        setError(`Bạn ${age} tuổi nhưng cân nặng chỉ có ${weight}kg? Vui lòng kiểm tra lại.`);
        setSubmitLoading(false);
        return;
      }
      if (age > 25 && weight !== null && weight < 30) {
        setError(`Bạn ${age} tuổi nhưng cân nặng chỉ có ${weight}kg? Vui lòng kiểm tra lại.`);
        setSubmitLoading(false);
        return;
      }
      if (age > 12 && height !== null && height < 80) {
        setError(`Chiều cao ${height}cm có vẻ quá thấp so với độ tuổi ${age}. Vui lòng kiểm tra lại.`);
        setSubmitLoading(false);
        return;
      }
    }

    const body: { [key: string]: unknown } = {};
    if (profileForm.bloodType !== undefined) body.bloodType = String(profileForm.bloodType);
    if (profileForm.allergies !== undefined) body.allergies = String(profileForm.allergies);
    if (profileForm.chronicConditions !== undefined) body.chronicConditions = String(profileForm.chronicConditions);
    if (profileForm.weight !== '') body.weight = Number(profileForm.weight);
    if (profileForm.height !== '') body.height = Number(profileForm.height);
    if (profileForm.gender !== undefined) body.gender = String(profileForm.gender);
    if (profileForm.birthday) body.birthday = String(profileForm.birthday);
    if (profileForm.address !== undefined) body.address = String(profileForm.address);
    if (profileForm.phone !== undefined) body.phone = String(profileForm.phone);
    const res = await ProfileApi.update(body);
    if (res.success) { load(); setShowProfileForm(false); setProfile(res.data as Profile); } else setError(res.message || 'Lỗi cập nhật');
    setSubmitLoading(false);
  };

  const handleSubmitMetric = async (e: React.FormEvent) => {
    e.preventDefault();
    const value = Number(metricForm.value);
    if (isNaN(value)) return;
    setSubmitLoading(true);
    setError('');
    const res = await MetricsApi.create({
      type: metricForm.type,
      value,
      unit: metricForm.unit,
      date: metricForm.date || undefined,
    });
    if (res.success) { load(); setShowMetricForm(false); setMetricForm({ type: 'huyết áp', value: '', unit: 'mmHg', date: new Date().toISOString().slice(0, 10) }); } else setError(res.message || 'Lỗi thêm chỉ số');
    setSubmitLoading(false);
  };

  if (loading) return <ProfileSkeleton />;

  return (
    <div>
      <header className={styles.header}>
        <h1 className={styles.title}>{t('profile.title')}</h1>
        <div className={styles.headerActions}>
          <button type="button" className={styles.btnSecondary} onClick={() => setShowMetricForm(true)}>
            {t('profile.add_metric')}
          </button>
          <button type="button" className={styles.btnPrimary} onClick={() => { resetForm(); setShowForm(true); }}>
            <Plus size={20} />
            <span>{t('profile.add_record')}</span>
          </button>
        </div>
      </header>

      {error && <div className={styles.error}>{error}</div>}

      {/* Tóm tắt cá nhân */}
      <section className={styles.section}>
        <div className={styles.card}>
          <div className={styles.cardHead}>
            <h2 className={styles.cardTitle}>
              <ClipboardList size={20} />
              {t('profile.personal_info')}
            </h2>
            <button type="button" className={styles.linkBtn} onClick={openProfileEdit}>{t('profile.edit')}</button>
          </div>
          <div className={styles.profileGrid}>
            <div><span className={styles.label}>{t('profile.blood_type')}</span><span>{profile?.bloodType || '—'}</span></div>
            <div><span className={styles.label}>{t('profile.allergies')}</span><span>{profile?.allergies || '—'}</span></div>
            <div><span className={styles.label}>{t('profile.chronic')}</span><span>{profile?.chronicConditions || '—'}</span></div>
            <div><span className={styles.label}>{t('profile.weight')}</span><span>{profile?.weight != null ? `${profile.weight} kg` : '—'}</span></div>
            <div><span className={styles.label}>{t('profile.height')}</span><span>{profile?.height != null ? `${profile.height} cm` : '—'}</span></div>
            <div><span className={styles.label}>{t('profile.gender')}</span><span>{profile?.gender || '—'}</span></div>
            <div><span className={styles.label}>{t('profile.birthday')}</span><span>{profile?.birthday ? new Date(profile.birthday).toLocaleDateString() : '—'}</span></div>
            <div><span className={styles.label}>{t('profile.address')}</span><span>{profile?.address || '—'}</span></div>
            <div><span className={styles.label}>{t('profile.phone')}</span><span>{profile?.phone || '—'}</span></div>
          </div>
        </div>
      </section>

      {/* Chỉ số gần đây */}
      {metrics.length > 0 && (
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>{t('profile.recent_metrics')}</h2>
          <div className={styles.metricsList}>
            {metrics.slice(0, 10).map((m) => (
              <div key={m.id} className={styles.metricItem}>
                <span className={styles.metricType}>{m.type}</span>
                <span className={styles.metricValue}>{m.value} {m.unit}</span>
                <span className={styles.metricDate}>{new Date(m.date).toLocaleDateString('vi-VN')}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Danh sách hồ sơ */}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('profile.medical_history')}</h2>
        {records.length === 0 ? (
          <EmptyState
            icon={History}
            title={t('profile.no_records')}
            description={t('profile.no_records_desc')}
            action={
              <button type="button" className={styles.btnPrimary} onClick={() => setShowForm(true)}>
                {t('profile.add_record')}
              </button>
            }
          />
        ) : (
          <ul className={styles.recordList}>
            {records.map((r) => (
              <li key={r.id} className={styles.recordItem}>
                <div className={styles.recordMain}>
                  <h3 className={styles.recordTitle}>{r.title}</h3>
                  {r.hospital && <span className={styles.recordMeta}>{r.hospital}</span>}
                  <span className={styles.recordDate}>{new Date(r.date).toLocaleDateString('vi-VN')}</span>
                  {r.diagnosis && <p className={styles.recordDesc}>{r.diagnosis}</p>}
                </div>
                <div className={styles.recordActions}>
                  <button type="button" className={styles.iconBtn} onClick={() => openEdit(r)} title="Sửa"><Pencil size={18} /></button>
                  <button type="button" className={styles.iconBtnDanger} onClick={() => handleDeleteRecord(r.id)} title="Xóa"><Trash2 size={18} /></button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* Modal form hồ sơ */}
      <Modal isOpen={showForm} onClose={resetForm}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>{editingId ? t('profile.edit_record') : t('profile.add_record')}</h3>
            <button type="button" className={styles.closeBtn} onClick={resetForm} disabled={submitLoading}>
              <X size={22} />
            </button>
          </div>
          <form id="record-form" className={styles.formContentWrap} onSubmit={handleSubmitRecord}>
            <div className={styles.formBody}>
              <div className={styles.formGrid}>
                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>
                    {t('profile.title_req')} <span className={styles.required}>*</span>
                  </label>
                  <input
                    type="text"
                    className={styles.input}
                    value={form.title}
                    onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                    required
                    disabled={submitLoading}
                    autoFocus
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.date')}</label>
                  <input
                    type="date"
                    className={styles.input}
                    value={form.date}
                    onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))}
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.hospital')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={form.hospital}
                    onChange={(e) => setForm((f) => ({ ...f, hospital: e.target.value }))}
                    placeholder="VD: Bệnh viện ABC, Thành Công"
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.diagnosis')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={form.diagnosis}
                    onChange={(e) => setForm((f) => ({ ...f, diagnosis: e.target.value }))}
                    placeholder="VD: Cao huyết áp, Tiểu đường"
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.treatment')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={form.treatment}
                    onChange={(e) => setForm((f) => ({ ...f, treatment: e.target.value }))}
                    placeholder="VD: Dùng thuốc huyết áp hàng ngày"
                    disabled={submitLoading}
                  />
                </div>

                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>{t('profile.notes')}</label>
                  <textarea
                    className={styles.textarea}
                    value={form.content}
                    onChange={(e) => setForm((f) => ({ ...f, content: e.target.value }))}
                    placeholder="Các ghi chú bổ sung..."
                    rows={3}
                    disabled={submitLoading}
                  />
                </div>
              </div>
            </div>

            <div className={styles.formFooter}>
              <button type="button" className={styles.modalBtnSecondary} onClick={resetForm} disabled={submitLoading}>
                {t('profile.cancel')}
              </button>
              <button type="submit" className={styles.modalBtnPrimary} disabled={submitLoading}>
                {submitLoading ? (
                  <>
                    <Loader2 size={20} className={styles.spinner} style={{ marginRight: '8px' }} />
                    {t('profile.saving')}
                  </>
                ) : (editingId ? t('profile.update') : t('profile.add'))}
              </button>
            </div>
          </form>
        </div>
      </Modal>

      {/* Modal form profile */}
      <Modal isOpen={showProfileForm} onClose={() => setShowProfileForm(false)}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>{t('profile.edit_profile_title')}</h3>
            <button type="button" className={styles.closeBtn} onClick={() => setShowProfileForm(false)} disabled={submitLoading}>
              <X size={22} />
            </button>
          </div>
          <form id="profile-form" className={styles.formContentWrap} onSubmit={handleSubmitProfile}>
            <div className={styles.formBody}>
              <div className={styles.formGrid}>
                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.blood_type')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={profileForm.bloodType}
                    onChange={(e) => setProfileForm((f) => ({ ...f, bloodType: e.target.value }))}
                    placeholder="VD: O+"
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.allergies')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={profileForm.allergies}
                    onChange={(e) => setProfileForm((f) => ({ ...f, allergies: e.target.value }))}
                    placeholder="VD: Penicillin"
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.chronic')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={profileForm.chronicConditions}
                    onChange={(e) => setProfileForm((f) => ({ ...f, chronicConditions: e.target.value }))}
                    placeholder="VD: Không / Dạ dày"
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.weight')} (kg)</label>
                  <input
                    type="number"
                    step="0.1"
                    className={styles.input}
                    value={profileForm.weight}
                    onChange={(e) => setProfileForm((f) => ({ ...f, weight: e.target.value }))}
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.height')} (cm)</label>
                  <input
                    type="number"
                    step="0.1"
                    className={styles.input}
                    value={profileForm.height}
                    onChange={(e) => setProfileForm((f) => ({ ...f, height: e.target.value }))}
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.gender')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={profileForm.gender}
                    onChange={(e) => setProfileForm((f) => ({ ...f, gender: e.target.value }))}
                    placeholder="Nam / Nữ / Khác"
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.birthday')}</label>
                  <input
                    type="date"
                    className={styles.input}
                    value={profileForm.birthday}
                    onChange={(e) => setProfileForm((f) => ({ ...f, birthday: e.target.value }))}
                    disabled={submitLoading}
                  />
                  <p className="text-[10px] text-[var(--text-muted)] mt-1 ml-1">Vui lòng chọn từ lịch hoặc nhập theo định dạng mm/dd/yyyy</p>
                </div>

                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>{t('profile.address')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={profileForm.address}
                    onChange={(e) => setProfileForm((f) => ({ ...f, address: e.target.value }))}
                    disabled={submitLoading}
                  />
                </div>

                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>{t('profile.phone')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={profileForm.phone}
                    onChange={(e) => setProfileForm((f) => ({ ...f, phone: e.target.value }))}
                    disabled={submitLoading}
                  />
                </div>
              </div>
            </div>

            <div className={styles.formFooter}>
              <button type="button" className={styles.modalBtnSecondary} onClick={() => setShowProfileForm(false)} disabled={submitLoading}>
                {t('profile.cancel')}
              </button>
              <button type="submit" className={styles.modalBtnPrimary} disabled={submitLoading}>
                {submitLoading ? (
                  <>
                    <Loader2 size={20} className={styles.spinner} style={{ marginRight: '8px' }} />
                    {t('profile.saving')}
                  </>
                ) : t('profile.save_info')}
              </button>
            </div>
          </form>
        </div>
      </Modal>

      {/* Modal form chỉ số */}
      <Modal isOpen={showMetricForm} onClose={() => setShowMetricForm(false)}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>{t('profile.add_metric_title')}</h3>
            <button type="button" className={styles.closeBtn} onClick={() => setShowMetricForm(false)} disabled={submitLoading}>
              <X size={22} />
            </button>
          </div>
          <form id="metric-form" className={styles.formContentWrap} onSubmit={handleSubmitMetric}>
            <div className={styles.formBody}>
              <div className={styles.formGrid}>
                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>
                    {t('profile.metric_type')} <span className={styles.required}>*</span>
                  </label>
                  <select
                    value={metricForm.type}
                    onChange={(e) => setMetricForm((f) => ({ ...f, type: e.target.value }))}
                    className={styles.select}
                    required
                    disabled={submitLoading}
                  >
                    <option value="huyết áp">Huyết áp</option>
                    <option value="đường huyết">Đường huyết</option>
                    <option value="nhịp tim">Nhịp tim</option>
                    <option value="cân nặng">Cân nặng</option>
                    <option value="khác">Khác</option>
                  </select>
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>
                    {t('profile.metric_value')} <span className={styles.required}>*</span>
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    className={styles.input}
                    value={metricForm.value}
                    onChange={(e) => setMetricForm((f) => ({ ...f, value: e.target.value }))}
                    required
                    disabled={submitLoading}
                  />
                </div>

                <div className={styles.fieldGroup}>
                  <label className={styles.labelBlock}>{t('profile.metric_unit')}</label>
                  <input
                    type="text"
                    className={styles.input}
                    value={metricForm.unit}
                    onChange={(e) => setMetricForm((f) => ({ ...f, unit: e.target.value }))}
                    placeholder="VD: mmHg, mmol/L, bpm, kg"
                    disabled={submitLoading}
                  />
                </div>

                <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                  <label className={styles.labelBlock}>
                    {t('profile.metric_date')} <span className={styles.required}>*</span>
                  </label>
                  <input
                    type="date"
                    className={styles.input}
                    value={metricForm.date}
                    onChange={(e) => setMetricForm((f) => ({ ...f, date: e.target.value }))}
                    required
                    disabled={submitLoading}
                  />
                </div>
              </div>
            </div>

            <div className={styles.formFooter}>
              <button type="button" className={styles.modalBtnSecondary} onClick={() => setShowMetricForm(false)} disabled={submitLoading}>
                {t('profile.cancel')}
              </button>
              <button type="submit" className={styles.modalBtnPrimary} disabled={submitLoading}>
                {submitLoading ? (
                  <>
                    <Loader2 size={20} className={styles.spinner} style={{ marginRight: '8px' }} />
                    {t('profile.saving')}
                  </>
                ) : t('profile.add')}
              </button>
            </div>
          </form>
        </div>
      </Modal>
    </div>
  );
}

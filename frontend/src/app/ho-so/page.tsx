'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { History, Plus, Pencil, Trash2, Loader2, X, ClipboardList } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { RecordsApi, ProfileApi, MetricsApi } from '@/services/api.client';
import { Modal } from '@/components/shared/Modal';
import styles from './ho-so.module.css';

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
  weight?: number | null;
  height?: number | null;
  gender?: string | null;
  birthday?: string | null;
  address?: string | null;
  phone?: string | null;
};

type Metric = { id: string; type: string; value: number; unit: string; date: string };

export default function HoSoPage() {
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
  const [profileForm, setProfileForm] = useState<{ [key: string]: string | number }>({ bloodType: '', allergies: '', weight: '', height: '', gender: '', birthday: '', address: '', phone: '' });
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
    if (!confirm('Xóa hồ sơ này?')) return;
    setSubmitLoading(true);
    const res = await RecordsApi.delete(id);
    if (res.success) load(); else setError(res.message || 'Lỗi xóa');
    setSubmitLoading(false);
  };

  const handleSubmitProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitLoading(true);
    setError('');
    const body: { [key: string]: unknown } = {};
    if (profileForm.bloodType !== undefined) body.bloodType = String(profileForm.bloodType);
    if (profileForm.allergies !== undefined) body.allergies = String(profileForm.allergies);
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
        <h1 className={styles.title}>Hồ sơ bệnh án</h1>
        <div className={styles.headerActions}>
          <button type="button" className={styles.btnSecondary} onClick={() => setShowMetricForm(true)}>
            Thêm chỉ số
          </button>
          <button type="button" className={styles.btnPrimary} onClick={() => { resetForm(); setShowForm(true); }}>
            <Plus size={20} />
            <span>Thêm hồ sơ</span>
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
              Thông tin cá nhân
            </h2>
            <button type="button" className={styles.linkBtn} onClick={openProfileEdit}>Chỉnh sửa</button>
          </div>
          <div className={styles.profileGrid}>
            <div><span className={styles.label}>Nhóm máu</span><span>{profile?.bloodType || '—'}</span></div>
            <div><span className={styles.label}>Dị ứng</span><span>{profile?.allergies || '—'}</span></div>
            <div><span className={styles.label}>Cân nặng</span><span>{profile?.weight != null ? `${profile.weight} kg` : '—'}</span></div>
            <div><span className={styles.label}>Chiều cao</span><span>{profile?.height != null ? `${profile.height} cm` : '—'}</span></div>
            <div><span className={styles.label}>Giới tính</span><span>{profile?.gender || '—'}</span></div>
            <div><span className={styles.label}>Ngày sinh</span><span>{profile?.birthday ? new Date(profile.birthday).toLocaleDateString('vi-VN') : '—'}</span></div>
            <div><span className={styles.label}>Địa chỉ</span><span>{profile?.address || '—'}</span></div>
            <div><span className={styles.label}>Điện thoại</span><span>{profile?.phone || '—'}</span></div>
          </div>
        </div>
      </section>

      {/* Chỉ số gần đây */}
      {metrics.length > 0 && (
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Chỉ số gần đây</h2>
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
        <h2 className={styles.sectionTitle}>Lịch sử khám / bệnh án</h2>
        {records.length === 0 ? (
          <EmptyState
            icon={History}
            title="Chưa có hồ sơ bệnh án"
            description="Thêm hồ sơ để lưu lại lịch sử khám và chẩn đoán."
            action={
              <button type="button" className={styles.btnPrimary} onClick={() => setShowForm(true)}>
                Thêm hồ sơ
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
            <h3>{editingId ? 'Chỉnh sửa hồ sơ' : 'Thêm hồ sơ'}</h3>
            <button type="button" className={styles.closeBtn} onClick={resetForm}>
              <X size={24} />
            </button>
          </div>
          <form onSubmit={handleSubmitRecord} className={styles.form}>
            <label className={styles.labelBlock}>
              <span>Tiêu đề <span className={styles.required}>*</span></span>
              <input
                type="text"
                className={styles.input}
                value={form.title}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                required
              />
            </label>

            <label className={styles.labelBlock}>
              <span>Ngày khám</span>
              <input
                type="date"
                className={styles.input}
                value={form.date}
                onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))}
              />
            </label>

            <label className={styles.labelBlock}>
              <span>Bệnh viện / Phòng khám</span>
              <input
                type="text"
                className={styles.input}
                value={form.hospital}
                onChange={(e) => setForm((f) => ({ ...f, hospital: e.target.value }))}
                placeholder="VD: Bệnh viện ABC, Thành Công"
              />
            </label>

            <label className={styles.labelBlock}>
              <span>Chẩn đoán / Bệnh nền</span>
              <input
                type="text"
                className={styles.input}
                value={form.diagnosis}
                onChange={(e) => setForm((f) => ({ ...f, diagnosis: e.target.value }))}
                placeholder="VD: Cao huyết áp, Tiểu đường"
              />
            </label>

            <label className={styles.labelBlock}>
              <span>Điều trị</span>
              <input
                type="text"
                className={styles.input}
                value={form.treatment}
                onChange={(e) => setForm((f) => ({ ...f, treatment: e.target.value }))}
                placeholder="VD: Dùng thuốc huyết áp hàng ngày"
              />
            </label>

            <label className={styles.labelBlock}>
              <span>Ghi chú</span>
              <textarea
                className={styles.textarea}
                value={form.content}
                onChange={(e) => setForm((f) => ({ ...f, content: e.target.value }))}
                placeholder="Các ghi chú bổ sung..."
                rows={3}
              />
            </label>

            <div className={styles.formFooter}>
              <button type="button" className={styles.btnSecondary} onClick={resetForm}>
                Hủy
              </button>
              <button type="submit" className={styles.btnPrimary} disabled={submitLoading}>
                {submitLoading ? <Loader2 size={20} className={styles.spinner} /> : (editingId ? 'Cập nhật' : 'Thêm')}
              </button>
            </div>
          </form>
        </div>
      </Modal>

      {/* Modal form profile */}
      <Modal isOpen={showProfileForm} onClose={() => setShowProfileForm(false)}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>Chỉnh sửa thông tin cá nhân</h3>
            <button type="button" className={styles.closeBtn} onClick={() => setShowProfileForm(false)}>
              <X size={24} />
            </button>
          </div>
          <form onSubmit={handleSubmitProfile} className={styles.form}>
            <div className={styles.formGrid}>
              <label className={styles.labelBlock}>
                <span>Nhóm máu</span>
                <input
                  type="text"
                  className={styles.input}
                  value={profileForm.bloodType}
                  onChange={(e) => setProfileForm((f) => ({ ...f, bloodType: e.target.value }))}
                  placeholder="VD: O+"
                />
              </label>

              <label className={styles.labelBlock}>
                <span>Dị ứng</span>
                <input
                  type="text"
                  className={styles.input}
                  value={profileForm.allergies}
                  onChange={(e) => setProfileForm((f) => ({ ...f, allergies: e.target.value }))}
                  placeholder="VD: Penicillin"
                />
              </label>

              <label className={styles.labelBlock}>
                <span>Cân nặng (kg)</span>
                <input
                  type="number"
                  step="0.1"
                  className={styles.input}
                  value={profileForm.weight}
                  onChange={(e) => setProfileForm((f) => ({ ...f, weight: e.target.value }))}
                />
              </label>

              <label className={styles.labelBlock}>
                <span>Chiều cao (cm)</span>
                <input
                  type="number"
                  step="0.1"
                  className={styles.input}
                  value={profileForm.height}
                  onChange={(e) => setProfileForm((f) => ({ ...f, height: e.target.value }))}
                />
              </label>

              <label className={styles.labelBlock}>
                <span>Giới tính</span>
                <input
                  type="text"
                  className={styles.input}
                  value={profileForm.gender}
                  onChange={(e) => setProfileForm((f) => ({ ...f, gender: e.target.value }))}
                  placeholder="Nam / Nữ / Khác"
                />
              </label>

              <label className={styles.labelBlock}>
                <span>Ngày sinh</span>
                <input
                  type="date"
                  className={styles.input}
                  value={profileForm.birthday}
                  onChange={(e) => setProfileForm((f) => ({ ...f, birthday: e.target.value }))}
                />
              </label>
            </div>

            <div className={styles.formSection}>
              <label className={styles.labelBlock}>
                <span>Địa chỉ</span>
                <input
                  type="text"
                  className={styles.input}
                  value={profileForm.address}
                  onChange={(e) => setProfileForm((f) => ({ ...f, address: e.target.value }))}
                />
              </label>

              <label className={styles.labelBlock}>
                <span>Điện thoại</span>
                <input
                  type="text"
                  className={styles.input}
                  value={profileForm.phone}
                  onChange={(e) => setProfileForm((f) => ({ ...f, phone: e.target.value }))}
                />
              </label>
            </div>

            <div className={styles.formFooter}>
              <button type="button" className={styles.btnSecondary} onClick={() => setShowProfileForm(false)}>
                Hủy
              </button>
              <button type="submit" className={styles.btnPrimary} disabled={submitLoading}>
                {submitLoading ? <Loader2 size={20} className={styles.spinner} /> : 'Lưu'}
              </button>
            </div>
          </form>
        </div>
      </Modal>

      {/* Modal form chỉ số */}
      <Modal isOpen={showMetricForm} onClose={() => setShowMetricForm(false)}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>Thêm chỉ số sức khỏe</h3>
            <button type="button" className={styles.closeBtn} onClick={() => setShowMetricForm(false)}>
              <X size={24} />
            </button>
          </div>
          <form onSubmit={handleSubmitMetric} className={styles.form}>
            <label className={styles.labelBlock}>
              <span>Loại chỉ số <span className={styles.required}>*</span></span>
              <select
                value={metricForm.type}
                onChange={(e) => setMetricForm((f) => ({ ...f, type: e.target.value }))}
                className={styles.select}
                required
              >
                <option value="huyết áp">Huyết áp</option>
                <option value="đường huyết">Đường huyết</option>
                <option value="nhịp tim">Nhịp tim</option>
                <option value="cân nặng">Cân nặng</option>
                <option value="khác">Khác</option>
              </select>
            </label>

            <label className={styles.labelBlock}>
              <span>Giá trị <span className={styles.required}>*</span></span>
              <input
                type="number"
                step="0.01"
                className={styles.input}
                value={metricForm.value}
                onChange={(e) => setMetricForm((f) => ({ ...f, value: e.target.value }))}
                required
              />
            </label>

            <label className={styles.labelBlock}>
              <span>Đơn vị</span>
              <input
                type="text"
                className={styles.input}
                value={metricForm.unit}
                onChange={(e) => setMetricForm((f) => ({ ...f, unit: e.target.value }))}
                placeholder="VD: mmHg, mmol/L, bpm, kg"
              />
            </label>

            <label className={styles.labelBlock}>
              <span>Ngày đo <span className={styles.required}>*</span></span>
              <input
                type="date"
                className={styles.input}
                value={metricForm.date}
                onChange={(e) => setMetricForm((f) => ({ ...f, date: e.target.value }))}
                required
              />
            </label>

            <div className={styles.formFooter}>
              <button type="button" className={styles.btnSecondary} onClick={() => setShowMetricForm(false)}>
                Hủy
              </button>
              <button type="submit" className={styles.btnPrimary} disabled={submitLoading}>
                {submitLoading ? <Loader2 size={20} className={styles.spinner} /> : 'Thêm'}
              </button>
            </div>
          </form>
        </div>
      </Modal>
    </div>
  );
}

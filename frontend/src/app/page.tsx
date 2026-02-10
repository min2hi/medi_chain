'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  AlertCircle,
  Activity,
  Calendar,
  Loader2,
  FilePlus,
  Pill,
  Upload,
  Share2,
  ClipboardList,
  AlertTriangle,
  X,
} from 'lucide-react';
import { UserService } from '@/services/user.client';
import { EmptyState } from '@/components/shared/EmptyState';
import { Modal } from '@/components/shared/Modal';
import AIChat from '@/components/shared/AIChat';
import styles from './page.module.css';

type DashboardData = {
  user?: { name?: string; role?: string };
  stats?: {
    status?: string;
    medicineCount?: number;
    medicines?: { id: string; name: string; dosage?: string; frequency?: string }[];
    recentActivities?: { id: string; title: string; time: string; type?: string }[];
    profile?: {
      bloodType?: string | null;
      allergies?: string | null;
      lastRecordUpdated?: string;
    };
    latestDiagnosis?: string | null;
    latestVitalsText?: string | null;
    latestVitalDate?: string | null;
    upcomingAppointment?: { title: string; date: string } | null;
    alerts?: { id: string; message: string; type: string }[];
  };
};

export default function Home() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [showActivities, setShowActivities] = useState(false);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const result = await UserService.getDashboard();
        if (result.success) {
          setData(result.data);
          // Cập nhật localStorage để đồng bộ với UserProfile ở Sidebar
          if (result.data.user) {
            localStorage.setItem('user', JSON.stringify(result.data.user));
            // Phát sự kiện để UserProfile có thể cập nhật ngay lập tức
            window.dispatchEvent(new Event('user-updated'));
          }
        } else {
          setError(result.message || 'Lỗi khi tải dữ liệu');
        }
      } catch {
        setError('Không thể kết nối tới máy chủ');
      } finally {
        setLoading(false);
      }
    };

    fetchDashboard();
  }, []);

  if (loading) {
    return (
      <div className={styles.loadingContainer}>
        <Loader2 className={styles.spinner} size={36} />
        <p>Đang tải dữ liệu y tế...</p>
      </div>
    );
  }

  const stats = data?.stats ?? {};
  const user = data?.user ?? {};
  const activities = stats.recentActivities ?? [];
  const alerts = stats.alerts ?? [];
  const profile = stats.profile;
  const medicineCount = stats.medicineCount ?? 0;
  const hasTodayMeds = medicineCount > 0;

  return (
    <div className={styles.wrapper}>
      <header className={styles.header}>
        <div className="animate-fade-in">
          <h1 className={styles.title}>
            Chào {user.name || 'Hội viên'},{' '}
            {user.role === 'DOCTOR' ? 'Bác sĩ chuyên khoa' : 'Sổ Y Bạ Gia Đình'}
          </h1>
          <p className={styles.slogan}>
            Hệ thống Quản trị & Số hóa Thông tin Y tế gia đình tập trung
          </p>
          <div className={styles.statusRow}>
            <span className={styles.statusBadge}>
              <div className={styles.pulse} />
              Hệ thống: Trực tuyến
            </span>
            <span className={styles.statusDivider}>|</span>
            <span className={styles.subtitle}>
              {profile?.lastRecordUpdated
                ? `Dữ liệu cập nhật gần nhất: ${new Date(profile.lastRecordUpdated).toLocaleDateString('vi-VN')}`
                : 'Trạng thái dữ liệu: Toàn vẹn & Đã được xác thực Blockchain'}
            </span>
          </div>
        </div>
      </header>

      {error && (
        <div className={styles.errorCard}>
          <AlertCircle size={20} className={styles.errorIcon} />
          <div>
            <p className={styles.errorTitle}>Lỗi hệ thống</p>
            <p className={styles.errorText}>{error}</p>
          </div>
        </div>
      )}

      {/* Hàng 1: Hành động nhanh */}
      <section className={styles.section}>
        <h2 className={styles.sectionLabel}>Hành động nhanh</h2>
        <div className={styles.quickActions}>
          <Link href="/ho-so" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <FilePlus size={22} />
            </span>
            <span>Thêm hồ sơ</span>
          </Link>
          <Link href="/thuoc" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <Pill size={22} />
            </span>
            <span>Thêm thuốc</span>
          </Link>
          <Link href="/ho-so" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <Upload size={22} />
            </span>
            <span>Tải lên xét nghiệm</span>
          </Link>
          <Link href="/chia-se" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <Share2 size={22} />
            </span>
            <span>Chia sẻ hồ sơ</span>
          </Link>
        </div>
      </section>

      {/* Cảnh báo */}
      {alerts.length > 0 && (
        <section className={styles.section}>
          <h2 className={styles.sectionLabel}>Cảnh báo</h2>
          <div className={styles.alerts}>
            {alerts.map((a) => (
              <div key={a.id} className={styles.alertItem}>
                <AlertTriangle size={18} className={styles.alertIcon} />
                <span>{a.message}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Hàng 2: Tổng quan sức khỏe + Tóm tắt y tế */}
      <section className={styles.section}>
        <div className={styles.overviewGrid}>
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <div className={`${styles.iconBox} ${styles.blue}`}>
                <Activity size={20} />
              </div>
              <h3>Tình trạng sức khỏe</h3>
            </div>
            <p className={styles.cardValue}>{stats.status || 'Bình thường'}</p>
            <p className={styles.cardDesc}>Dựa trên hồ sơ gần nhất</p>
          </div>

          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <div className={`${styles.iconBox} ${styles.teal}`}>
                <ClipboardList size={20} />
              </div>
              <h3>Tóm tắt y tế</h3>
            </div>
            <ul className={styles.summaryList}>
              <li>
                <span className={styles.summaryLabel}>Nhóm máu</span>
                <span className={styles.summaryValue}>{profile?.bloodType || '—'}</span>
              </li>
              <li>
                <span className={styles.summaryLabel}>Dị ứng</span>
                <span className={styles.summaryValue}>{profile?.allergies || '—'}</span>
              </li>
              <li>
                <span className={styles.summaryLabel}>Bệnh nền / Chẩn đoán</span>
                <span className={styles.summaryValue}>
                  {stats.latestDiagnosis ? (stats.latestDiagnosis.length > 40 ? `${stats.latestDiagnosis.slice(0, 40)}…` : stats.latestDiagnosis) : '—'}
                </span>
              </li>
              <li>
                <span className={styles.summaryLabel}>Chỉ số gần nhất</span>
                <span className={styles.summaryValue}>
                  {stats.latestVitalsText || '—'}
                </span>
              </li>
            </ul>
          </div>
        </div>
      </section>

      {/* Hàng 3: Hôm nay + Hoạt động gần đây */}
      <section className={styles.section}>
        <div className={styles.twoCol}>
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <div className={`${styles.iconBox} ${styles.green}`}>
                <Calendar size={20} />
              </div>
              <h3>Hôm nay</h3>
            </div>
            {stats.upcomingAppointment && (
              <div className={styles.appointmentRow}>
                <span className={styles.appointmentLabel}>Lịch tái khám:</span>
                <span className={styles.appointmentValue}>
                  {stats.upcomingAppointment.title} — {new Date(stats.upcomingAppointment.date).toLocaleDateString('vi-VN')}
                </span>
              </div>
            )}
            {hasTodayMeds ? (
              <div className={styles.todayContent}>
                <p className={styles.todayLead}>
                  Bạn đang theo dõi <strong>{medicineCount}</strong> loại thuốc.
                </p>
                <ul className={styles.medList}>
                  {(stats.medicines ?? []).slice(0, 5).map((m) => (
                    <li key={m.id}>
                      {m.name}
                      {m.dosage && ` · ${m.dosage}`}
                      {m.frequency && ` · ${m.frequency}`}
                    </li>
                  ))}
                </ul>
                <Link href="/thuoc" className={styles.cardLink}>
                  Xem lịch nhắc thuốc →
                </Link>
              </div>
            ) : (
              <EmptyState
                icon={Calendar}
                title="Bạn chưa thiết lập nhắc thuốc"
                description="Thiết lập nhắc uống thuốc để không bỏ lỡ liều."
                compact
                action={
                  <div className={styles.emptyActions}>
                    <Link href="/lich-hen" className={styles.btnPrimary}>
                      Tạo lịch nhắc
                    </Link>
                    <Link href="/thuoc" className={styles.btnSecondary}>
                      Thêm thuốc
                    </Link>
                  </div>
                }
              />
            )}
          </div>

          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3>Hoạt động gần đây</h3>
            </div>
            {activities.length > 0 ? (
              <>
                <ul className={styles.activityList}>
                  {activities.slice(0, 3).map((a) => (
                    <li key={a.id} className={styles.activityItem}>
                      <span className={styles.activityDot} />
                      <div>
                        <p className={styles.activityTitle}>{a.title}</p>
                        <p className={styles.activityTime}>{a.time}</p>
                      </div>
                    </li>
                  ))}
                </ul>
                <button onClick={() => setShowActivities(true)} className={styles.viewMoreBtn}>
                  Xem tất cả hoạt động
                </button>
              </>
            ) : (
              <EmptyState
                icon={Activity}
                title="Chưa có hoạt động"
                description="Khi bạn thêm hồ sơ hoặc thuốc, hoạt động sẽ hiển thị tại đây."
                compact
                action={
                  <Link href="/ho-so" className={styles.btnPrimary}>
                    Thêm hồ sơ
                  </Link>
                }
              />
            )}
          </div>
        </div>
      </section>

      {/* Hàng 4: Chỉ số theo dõi / xu hướng */}
      <section className={styles.section}>
        <h2 className={styles.sectionLabel}>Chỉ số theo dõi</h2>
        <div className={styles.trendCard}>
          <p className={styles.trendPlaceholder}>
            Chưa đủ dữ liệu 7 ngày để hiển thị biểu đồ.
          </p>
          <Link href="/ho-so" className={styles.trendLink}>Cập nhật chỉ số tại Hồ sơ →</Link>
        </div>
      </section>

      {/* AI Chat - Global Floating Component */}
      <AIChat />

      {/* Modal: Xem tất cả hoạt động */}
      <Modal isOpen={showActivities} onClose={() => setShowActivities(false)}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>Tất cả hoạt động</h3>
            <button className={styles.closeBtn} onClick={() => setShowActivities(false)}>
              <X size={24} />
            </button>
          </div>
          <div className={styles.modalBody}>
            <ul className={styles.activityList}>
              {activities.map((a) => (
                <li key={a.id} className={styles.activityItem}>
                  <span className={styles.activityDot} />
                  <div>
                    <p className={styles.activityTitle}>{a.title}</p>
                    <p className={styles.activityTime}>{a.time}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </Modal>
    </div>
  );
}

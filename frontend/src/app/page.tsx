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
import { ProfileApi } from '@/services/api.client';
import { EmptyState } from '@/components/shared/EmptyState';
import { Modal } from '@/components/shared/Modal';
import AIChat from '@/components/shared/AIChat';
import styles from './page.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

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
  const { t } = useTranslation();

  const [showActivities, setShowActivities] = useState(false);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const result = await ProfileApi.getDashboard();
        if (result.success) {
          setData(result.data);
          // Cập nhật localStorage để đồng bộ với UserProfile ở Sidebar
          if (result.data.user) {
            localStorage.setItem('user', JSON.stringify(result.data.user));
            // Phát sự kiện để UserProfile có thể cập nhật ngay lập tức
            window.dispatchEvent(new Event('user-updated'));
          }
        } else {
          setError(result.message || t('dashboard.err_load_data'));
        }
      } catch {
        setError(t('dashboard.err_connect'));
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
        <p>{t('dashboard.loading_data')}</p>
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
            {t('dashboard.greeting')} {user.name || t('dashboard.member')},{' '}
            {user.role === 'DOCTOR' ? t('dashboard.doctor') : t('dashboard.role_family')}
          </h1>
          <p className={styles.slogan}>
            {t('dashboard.slogan')}
          </p>
          <div className={styles.statusRow}>
            <span className={styles.statusBadge}>
              <div className={styles.pulse} />
              {t('dashboard.sys_online')}
            </span>
            <span className={styles.statusDivider}>|</span>
            <span className={styles.subtitle}>
              {profile?.lastRecordUpdated
                ? `${t('dashboard.data_updated')}${new Date(profile.lastRecordUpdated).toLocaleDateString('vi-VN')}`
                : t('dashboard.data_verified')}
            </span>
          </div>
        </div>
      </header>

      {error && (
        <div className={styles.errorCard}>
          <AlertCircle size={20} className={styles.errorIcon} />
          <div>
            <p className={styles.errorTitle}>{t('dashboard.sys_error')}</p>
            <p className={styles.errorText}>{error}</p>
          </div>
        </div>
      )}

      {/* Hàng 1: Hành động nhanh */}
      <section className={styles.section}>
        <h2 className={styles.sectionLabel}>{t('dashboard.quick_actions')}</h2>
        <div className={styles.quickActions}>
          <Link href="/ho-so" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <FilePlus size={22} />
            </span>
            <span>{t('dashboard.add_record')}</span>
          </Link>
          <Link href="/thuoc" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <Pill size={22} />
            </span>
            <span>{t('dashboard.add_med')}</span>
          </Link>
          <Link href="/ho-so" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <Upload size={22} />
            </span>
            <span>{t('dashboard.upload_test')}</span>
          </Link>
          <Link href="/chia-se" className={styles.quickAction}>
            <span className={styles.quickActionIcon}>
              <Share2 size={22} />
            </span>
            <span>{t('dashboard.share_record')}</span>
          </Link>
        </div>
      </section>

      {/* Cảnh báo */}
      {alerts.length > 0 && (
        <section className={styles.section}>
          <h2 className={styles.sectionLabel}>{t('dashboard.alerts')}</h2>
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
              <h3>{t('dashboard.health_status')}</h3>
            </div>
            <p className={styles.cardValue}>{stats.status || t('dashboard.normal')}</p>
            <p className={styles.cardDesc}>{t('dashboard.based_on_recent')}</p>
          </div>

          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <div className={`${styles.iconBox} ${styles.teal}`}>
                <ClipboardList size={20} />
              </div>
              <h3>{t('dashboard.medical_summary')}</h3>
            </div>
            <ul className={styles.summaryList}>
              <li>
                <span className={styles.summaryLabel}>{t('dashboard.blood_type')}</span>
                <span className={styles.summaryValue}>{profile?.bloodType || '—'}</span>
              </li>
              <li>
                <span className={styles.summaryLabel}>{t('dashboard.allergies')}</span>
                <span className={styles.summaryValue}>{profile?.allergies || '—'}</span>
              </li>
              <li>
                <span className={styles.summaryLabel}>{t('dashboard.chronic_conditions')}</span>
                <span className={styles.summaryValue}>
                  {stats.latestDiagnosis ? (stats.latestDiagnosis.length > 40 ? `${stats.latestDiagnosis.slice(0, 40)}…` : stats.latestDiagnosis) : '—'}
                </span>
              </li>
              <li>
                <span className={styles.summaryLabel}>{t('dashboard.recent_vitals')}</span>
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
              <h3>{t('dashboard.today')}</h3>
            </div>
            {stats.upcomingAppointment && (
              <div className={styles.appointmentRow}>
                <span className={styles.appointmentLabel}>{t('dashboard.re_exam_schedule')}</span>
                <span className={styles.appointmentValue}>
                  {stats.upcomingAppointment.title} — {new Date(stats.upcomingAppointment.date).toLocaleDateString('vi-VN')}
                </span>
              </div>
            )}
            {hasTodayMeds ? (
              <div className={styles.todayContent}>
                <p className={styles.todayLead}>
                  {t('dashboard.tracking_meds')} <strong>{medicineCount}</strong> {t('dashboard.med_types')}
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
                  {t('dashboard.view_med_schedule')}
                </Link>
              </div>
            ) : (
              <EmptyState
                icon={Calendar}
                title={t('dashboard.no_med_schedule_title')}
                description={t('dashboard.no_med_schedule_desc')}
                compact
                action={
                  <div className={styles.emptyActions}>
                    <Link href="/lich-hen" className={styles.btnPrimary}>
                      {t('dashboard.create_schedule')}
                    </Link>
                    <Link href="/thuoc" className={styles.btnSecondary}>
                      {t('dashboard.add_med')}
                    </Link>
                  </div>
                }
              />
            )}
          </div>

          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3>{t('dashboard.recent_activities')}</h3>
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
                  {t('dashboard.view_all_activities')}
                </button>
              </>
            ) : (
              <EmptyState
                icon={Activity}
                title={t('dashboard.no_activities_title')}
                description={t('dashboard.no_activities_desc')}
                compact
                action={
                  <Link href="/ho-so" className={styles.btnPrimary}>
                    {t('dashboard.add_record')}
                  </Link>
                }
              />
            )}
          </div>
        </div>
      </section>

      {/* Hàng 4: Chỉ số theo dõi / xu hướng */}
      <section className={styles.section}>
        <h2 className={styles.sectionLabel}>{t('dashboard.tracking_metrics')}</h2>
        <div className={styles.trendCard}>
          <p className={styles.trendPlaceholder}>
            {t('dashboard.not_enough_data')}
          </p>
          <Link href="/ho-so" className={styles.trendLink}>{t('dashboard.update_metrics')}</Link>
        </div>
      </section>

      {/* AI Chat - Global Floating Component */}
      <AIChat />

      {/* Modal: Xem tất cả hoạt động */}
      <Modal isOpen={showActivities} onClose={() => setShowActivities(false)}>
        <div className={styles.modal}>
          <div className={styles.modalHead}>
            <h3>{t('dashboard.all_activities')}</h3>
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

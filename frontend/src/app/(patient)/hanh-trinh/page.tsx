'use client';

import React, { useEffect, useState } from 'react';
import {
  Calendar,
  ClipboardList,
  Pill,
  RefreshCw,
  Activity,
  Loader2,
  AlertCircle,
} from 'lucide-react';
import { AppointmentsApi, RecordsApi, MedicinesApi } from '@/services/api.client';
import { useTranslation } from '@/i18n/I18nProvider';
import styles from './hanh-trinh.module.css';

type EventType = 'appointment' | 'record' | 'medicine';

type TimelineEvent = {
  id: string;
  date: Date;
  title: string;
  subtitle?: string | null;
  detail?: string | null;
  type: EventType;
};

interface AppointmentItem {
  id: string;
  date: string;
  title?: string;
  status: string;
  notes?: string;
}

interface RecordItem {
  id: string;
  date: string;
  title?: string;
  diagnosis?: string;
  hospital?: string;
  treatment?: string;
}

interface MedicineItem {
  id: string;
  startDate: string;
  name?: string;
  dosage?: string;
  frequency?: string;
  instruction?: string;
}

export default function HealthTimelinePage() {
  const [events, setEvents] = useState<TimelineEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');

  // Filters
  const [showAppointments, setShowAppointments] = useState(true);
  const [showRecords, setShowRecords] = useState(true);
  const [showMedicines, setShowMedicines] = useState(true);

  const loadData = async (silent = false) => {
    try {
      if (!silent) setLoading(true);
      else setRefreshing(true);
      setError('');

      const [appointmentsRes, recordsRes, medicinesRes] = await Promise.all([
        AppointmentsApi.list(),
        RecordsApi.list(),
        MedicinesApi.list(),
      ]);

      const formattedEvents: TimelineEvent[] = [];

      // Process appointments
      if (appointmentsRes.success && Array.isArray(appointmentsRes.data)) {
        (appointmentsRes.data as unknown as AppointmentItem[]).forEach((a) => {
          const date = new Date(a.date);
          if (isNaN(date.getTime())) return;
          formattedEvents.push({
            id: a.id,
            date,
            title: a.title || 'Lịch hẹn',
            subtitle: getAppointmentStatusLabel(a.status),
            detail: a.notes || null,
            type: 'appointment',
          });
        });
      }

      // Process records
      if (recordsRes.success && Array.isArray(recordsRes.data)) {
        (recordsRes.data as unknown as RecordItem[]).forEach((r) => {
          const date = new Date(r.date);
          if (isNaN(date.getTime())) return;
          formattedEvents.push({
            id: r.id,
            date,
            title: r.title || 'Hồ sơ bệnh án',
            subtitle: r.diagnosis || r.hospital || null,
            detail: r.treatment || null,
            type: 'record',
          });
        });
      }

      // Process medicines
      if (medicinesRes.success && Array.isArray(medicinesRes.data)) {
        (medicinesRes.data as unknown as MedicineItem[]).forEach((m) => {
          const date = new Date(m.startDate);
          if (isNaN(date.getTime())) return;
          const subtitleParts = [m.dosage, m.frequency].filter(Boolean);
          formattedEvents.push({
            id: m.id,
            date,
            title: m.name || 'Thuốc',
            subtitle: subtitleParts.length > 0 ? subtitleParts.join(' · ') : null,
            detail: m.instruction || null,
            type: 'medicine',
          });
        });
      }

      // Sort chronological descending (newest first)
      formattedEvents.sort((a, b) => b.date.getTime() - a.date.getTime());
      setEvents(formattedEvents);
    } catch (err) {
      console.error(err);
      setError('Không thể kết nối máy chủ. Vui lòng thử lại.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const getAppointmentStatusLabel = (status: string) => {
    switch (status) {
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return 'Chờ xác nhận';
    }
  };

  useEffect(() => {
    Promise.resolve().then(() => {
      loadData();
    });
  }, []);

  const filteredEvents = events.filter((e) => {
    if (!showAppointments && e.type === 'appointment') return false;
    if (!showRecords && e.type === 'record') return false;
    if (!showMedicines && e.type === 'medicine') return false;
    return true;
  });

  if (loading) {
    return (
      <div className={styles.loadingBox}>
        <Loader2 className={styles.spinner} size={40} />
        <span>Đang đồng bộ hóa hành trình sức khỏe...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles.emptyBox}>
        <div className={styles.emptyIcon} style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444' }}>
          <AlertCircle size={32} />
        </div>
        <h3 className={styles.emptyTitle}>Lỗi kết nối dữ liệu</h3>
        <p className={styles.emptyDesc}>{error}</p>
        <button onClick={() => loadData()} className={styles.retryBtn}>
          Thử lại
        </button>
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <h1 className={styles.title}>Hành trình sức khỏe</h1>
        <button onClick={() => loadData(true)} className={styles.refreshBtn} disabled={refreshing} title="Làm mới">
          <RefreshCw size={16} className={refreshing ? styles.spinning : ''} />
        </button>
      </header>

      {/* Dynamic filter chips */}
      <section className={styles.filterRow}>
        <button
          onClick={() => setShowAppointments(!showAppointments)}
          className={`${styles.filterChip} ${styles.chipAppointment} ${showAppointments ? styles.active : ''}`}
        >
          <Calendar size={14} />
          <span>Lịch hẹn</span>
        </button>

        <button
          onClick={() => setShowRecords(!showRecords)}
          className={`${styles.filterChip} ${styles.chipRecord} ${showRecords ? styles.active : ''}`}
        >
          <ClipboardList size={14} />
          <span>Hồ sơ bệnh án</span>
        </button>

        <button
          onClick={() => setShowMedicines(!showMedicines)}
          className={`${styles.filterChip} ${styles.chipMedicine} ${showMedicines ? styles.active : ''}`}
        >
          <Pill size={14} />
          <span>Thuốc</span>
        </button>
      </section>

      {/* Event list */}
      {filteredEvents.length === 0 ? (
        <div className={styles.emptyBox}>
          <div className={styles.emptyIcon}>
            <Activity size={32} />
          </div>
          <h3 className={styles.emptyTitle}>Chưa có sự kiện nào</h3>
          <p className={styles.emptyDesc}>
            Lịch hẹn bác sĩ, hồ sơ bệnh án và danh sách thuốc của bạn sẽ được tự động đồng bộ hóa tại đây.
          </p>
        </div>
      ) : (
        <section className={styles.timelineList}>
          {filteredEvents.map((e, idx) => {
            // Check if year changes
            const currentYear = e.date.getFullYear();
            const prevYear = idx > 0 ? filteredEvents[idx - 1].date.getFullYear() : null;
            const showYearDivider = prevYear !== currentYear;

            // Type mappings
            let typeLabel = 'Sự kiện';
            let metaClass = '';
            let dotClass = '';
            let detailClass = '';

            if (e.type === 'appointment') {
              typeLabel = 'Lịch hẹn';
              metaClass = styles.metaAppointment;
              dotClass = styles.dotAppointment;
              detailClass = styles.detailAppointment;
            } else if (e.type === 'record') {
              typeLabel = 'Hồ sơ bệnh án';
              metaClass = styles.metaRecord;
              dotClass = styles.dotRecord;
              detailClass = styles.detailRecord;
            } else if (e.type === 'medicine') {
              typeLabel = 'Thuốc';
              metaClass = styles.metaMedicine;
              dotClass = styles.dotMedicine;
              detailClass = styles.detailMedicine;
            }

            // Localized date formatting
            const dateStr = e.date.toLocaleDateString('vi-VN', {
              day: '2-digit',
              month: '2-digit',
              hour: '2-digit',
              minute: '2-digit',
            });

            return (
              <React.Fragment key={e.id}>
                {showYearDivider && (
                  <div className={styles.yearDivider}>
                    <h2 className={styles.yearText}>{currentYear}</h2>
                    <div className={styles.yearLine} />
                  </div>
                )}

                <div className={styles.timelineItem}>
                  <div className={`${styles.dotPin} ${dotClass}`} />
                  <div className={styles.eventCard}>
                    <div className={styles.cardHeader}>
                      <div className={styles.cardMeta}>
                        <span className={`${styles.metaText} ${metaClass}`}>{typeLabel}</span>
                        <span className={styles.dateText}>{dateStr}</span>
                      </div>
                    </div>
                    <h3 className={styles.cardTitle}>{e.title}</h3>
                    {e.subtitle && <p className={styles.cardSubtitle}>{e.subtitle}</p>}
                    {e.detail && <p className={`${styles.cardDetail} ${detailClass}`}>{e.detail}</p>}
                  </div>
                </div>
              </React.Fragment>
            );
          })}
        </section>
      )}
    </div>
  );
}

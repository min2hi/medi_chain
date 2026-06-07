'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  HeartPulse,
  RefreshCw,
  TrendingUp,
  TrendingDown,
  Calendar,
  Activity,
  Brain,
  CheckCircle,
  AlertCircle,
  AlertTriangle,
  ChevronRight,
  MessageSquare,
  X,
  Smile,
  Meh,
  Frown,
  Loader2,
} from 'lucide-react';
import { HealthTwinApi } from '@/services/api.client';
import { Modal } from '@/components/shared/Modal';
import { useTranslation } from '@/i18n/I18nProvider';
import styles from './bong-suc-khoe.module.css';

type HealthAnomaly = {
  id: string;
  explanation: string;
  actionType: 'SUGGEST_APPOINTMENT' | 'CONSULT_AI' | null;
  isDismissed: boolean;
};

type HealthPattern = {
  id: string;
  type: 'SEASONAL' | 'BEHAVIORAL' | 'DRUG_RESPONSE' | 'RECURRING';
  description: string;
  icon?: string;
};

type HealthTwinStatusData = {
  isStable: boolean;
  weeksTracked: number;
  totalLogs: number;
  recentScore: number | null;
  trendPercent: number | null;
  recentAnomalies: HealthAnomaly[];
  patterns: HealthPattern[];
};

type HealthEvent = {
  id: string;
  sourceIcon: string;
  sourceLabel: string;
  rawContent: string;
  date: string;
};

type HealthTimelineMonth = {
  label: string;
  healthScore: number | null;
  events: HealthEvent[];
};

export default function HealthTwinPage() {
  const router = useRouter();
  const { t } = useTranslation();

  const [status, setStatus] = useState<HealthTwinStatusData | null>(null);
  const [timeline, setTimeline] = useState<HealthTimelineMonth[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');

  // Checkin state
  const [showCheckin, setShowCheckin] = useState(false);
  const [selectedMood, setSelectedMood] = useState<'good' | 'normal' | 'tired' | 'bad' | null>(null);
  const [submittingCheckin, setSubmittingCheckin] = useState(false);

  const fetchData = async (silent = false) => {
    try {
      if (!silent) setLoading(true);
      else setRefreshing(true);
      setError('');

      const [statusRes, timelineRes] = await Promise.all([
        HealthTwinApi.getStatus(),
        HealthTwinApi.getTimeline(),
      ]);

      if (statusRes.success) {
        setStatus(statusRes.data);
      } else {
        setError(statusRes.message || 'Lỗi tải trạng thái Bóng Sức Khỏe.');
      }

      if (timelineRes.success) {
        setTimeline(timelineRes.data || []);
      }
    } catch (err) {
      console.error(err);
      setError('Không thể kết nối máy chủ. Vui lòng thử lại.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleDismissAnomaly = async (id: string) => {
    try {
      const res = await HealthTwinApi.dismissAnomaly(id);
      if (res.success) {
        if (status) {
          setStatus({
            ...status,
            recentAnomalies: status.recentAnomalies.filter((a) => a.id !== id),
          });
        }
      }
    } catch (err) {
      console.error('Lỗi khi bỏ qua dị thường:', err);
    }
  };

  const handleAnomalyAction = (anomaly: HealthAnomaly) => {
    if (anomaly.actionType === 'SUGGEST_APPOINTMENT') {
      router.push('/lich-hen');
    } else {
      router.push('/tu-van');
    }
  };

  const handleCheckinSubmit = async () => {
    if (!selectedMood) return;
    try {
      setSubmittingCheckin(true);
      const res = await HealthTwinApi.submitCheckin(selectedMood);
      if (res.success) {
        setShowCheckin(false);
        setSelectedMood(null);
        // Reload data silently
        fetchData(true);
      }
    } catch (err) {
      console.error('Lỗi khi check-in:', err);
    } finally {
      setSubmittingCheckin(false);
    }
  };

  if (loading) {
    return (
      <div className={styles.loadingBox}>
        <Loader2 className={styles.spinner} size={40} />
        <span>Đang đồng bộ hóa Bóng Sức Khỏe của bạn...</span>
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
        <button onClick={() => fetchData()} className={styles.consultLink} style={{ background: '#ef4444' }}>
          Thử lại
        </button>
      </div>
    );
  }

  if (!status) {
    return (
      <div className={styles.emptyBox}>
        <div className={styles.emptyIcon}>
          <HeartPulse size={32} />
        </div>
        <h3 className={styles.emptyTitle}>Bóng Sức Khỏe đang khởi động</h3>
        <p className={styles.emptyDesc}>
          Bắt đầu thêm lịch sử dùng thuốc, tư vấn với AI hoặc tạo lịch hẹn để AI phân tích trạng thái sinh học của bạn.
        </p>
        <Link href="/tu-van" className={styles.consultLink}>
          Trò chuyện với AI ngay
        </Link>
      </div>
    );
  }

  const activeAnomalies = status.recentAnomalies.filter((a) => !a.isDismissed);

  // Status mapping
  let statusClass = styles.calibrating;
  let statusText = 'Đang hiệu chỉnh';
  let statusIcon = <Loader2 size={12} className={styles.spinner} />;

  if (status.isStable) {
    const score = status.recentScore ?? 50;
    if (score >= 75) {
      statusClass = styles.stable;
      statusText = 'Trạng thái ổn định';
      statusIcon = <CheckCircle size={12} />;
    } else if (score >= 50) {
      statusClass = styles.monitoring;
      statusText = 'Cần theo dõi';
      statusIcon = <AlertTriangle size={12} />;
    } else {
      statusClass = styles.danger;
      statusText = 'Cảnh báo sức khỏe';
      statusIcon = <AlertCircle size={12} />;
    }
  }

  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <div className={styles.titleWrapper}>
          <div className={styles.pulseDot} />
          <h1 className={styles.title}>Bóng Sức Khỏe AI</h1>
        </div>
        <button onClick={() => fetchData(true)} className={styles.refreshBtn} disabled={refreshing} title="Làm mới">
          <RefreshCw size={16} className={refreshing ? styles.spinning : ''} />
        </button>
      </header>

      {/* Hero card */}
      <section className={styles.hero}>
        <div className={styles.scoreRow}>
          <div>
            <div className={styles.scoreDisplay}>
              <span className={styles.scoreBig}>{status.recentScore ?? '--'}</span>
              <span className={styles.scoreLabel}>/100</span>
            </div>
            <div className={styles.badgeRow}>
              <div className={`${styles.statusBadge} ${statusClass}`}>
                {statusIcon}
                <span>{statusText}</span>
              </div>
              {status.trendPercent !== null && (
                <div
                  className={styles.trendText}
                  style={{ color: status.trendPercent >= 0 ? '#16a34a' : '#ef4444' }}
                >
                  {status.trendPercent >= 0 ? (
                    <TrendingUp size={14} />
                  ) : (
                    <TrendingDown size={14} />
                  )}
                  <span>
                    {status.trendPercent >= 0 ? '+' : ''}
                    {status.trendPercent.toFixed(0)}% so với tuần trước
                  </span>
                </div>
              )}
            </div>
          </div>

          <div className={styles.orbWrapper}>
            <div className={styles.orb}>
              <HeartPulse size={32} />
            </div>
          </div>
        </div>

        {/* Stats row */}
        <div className={styles.statsGrid}>
          <div className={styles.statCard}>
            <div className={styles.statCardIcon}>
              <Calendar size={16} />
            </div>
            <p className={styles.statCardVal}>{status.weeksTracked}</p>
            <p className={styles.statCardLbl}>Tuần theo dõi</p>
          </div>

          <div className={styles.statCard}>
            <div className={styles.statCardIcon}>
              <Activity size={16} />
            </div>
            <p className={styles.statCardVal}>{status.totalLogs}</p>
            <p className={styles.statCardLbl}>Tổng sự kiện</p>
          </div>

          <div className={styles.statCard}>
            <div className={`${styles.statCardIcon} ${status.isStable ? styles.highlight : ''}`}>
              <Brain size={16} />
            </div>
            <p className={`${styles.statCardVal} ${status.isStable ? styles.highlight : ''}`}>
              {status.isStable ? 'Hoạt động' : 'Đang học'}
            </p>
            <p className={styles.statCardLbl}>Trạng thái AI</p>
          </div>
        </div>

        {/* Learning progress bar */}
        {!status.isStable && (
          <div className={styles.learningProgress}>
            <div className={styles.progressBarHeader}>
              <span className={styles.progressText}>AI đang ghi nhận baseline sinh học...</span>
              <span className={styles.percentText}>
                {Math.min(100, Math.round((status.totalLogs / 8) * 100))}%
              </span>
            </div>
            <div className={styles.progressBarOuter}>
              <div
                className={styles.progressBarInner}
                style={{ width: `${Math.min(100, (status.totalLogs / 8) * 100)}%` }}
              />
            </div>
            <p className={styles.progressFooter}>
              {status.totalLogs < 8
                ? `Cần thêm ${8 - status.totalLogs} sự kiện/check-in để mở khóa đánh giá sức khỏe.`
                : 'Đã tích lũy đủ dữ liệu. AI đang tổng hợp chỉ số.'}
            </p>
          </div>
        )}
      </section>

      {/* Anomalies section */}
      {activeAnomalies.length > 0 && (
        <section>
          <div className={styles.sectionHeader}>
            <AlertTriangle size={16} style={{ color: '#d97706' }} />
            <h2 className={styles.sectionHeaderTitle}>Phát hiện bất thường</h2>
          </div>
          {activeAnomalies.map((a) => (
            <div key={a.id} className={styles.anomalyCard}>
              <div className={styles.anomalyMain}>
                <div className={styles.anomalyIcon}>
                  <AlertTriangle size={18} />
                </div>
                <p className={styles.anomalyText}>{a.explanation}</p>
              </div>
              <div className={styles.anomalyActions}>
                {a.actionType && (
                  <button onClick={() => handleAnomalyAction(a)} className={styles.anomalyActionBtn}>
                    {a.actionType === 'SUGGEST_APPOINTMENT' ? 'Đặt lịch khám' : 'Hỏi AI ngay'}
                  </button>
                )}
                <button onClick={() => handleDismissAnomaly(a.id)} className={styles.anomalyDismissBtn}>
                  Đã hiểu & Bỏ qua
                </button>
              </div>
            </div>
          ))}
        </section>
      )}

      {/* Active Patterns */}
      {status.patterns.length > 0 && (
        <section>
          <div className={styles.sectionHeader}>
            <Brain size={16} style={{ color: '#8b5cf6' }} />
            <h2 className={styles.sectionHeaderTitle}>Xu hướng AI nhận thấy</h2>
          </div>
          <div className={styles.patternsBox}>
            {status.patterns.map((p) => {
              let typeLabel = 'Nhận định';
              let defaultIcon = '📌';
              if (p.type === 'SEASONAL') {
                typeLabel = 'Thời tiết';
                defaultIcon = '🌧️';
              } else if (p.type === 'BEHAVIORAL') {
                typeLabel = 'Thói quen';
                defaultIcon = '🧠';
              } else if (p.type === 'DRUG_RESPONSE') {
                typeLabel = 'Tác dụng thuốc';
                defaultIcon = '💊';
              } else if (p.type === 'RECURRING') {
                typeLabel = 'Chu kỳ';
                defaultIcon = '🔄';
              }

              return (
                <div key={p.id} className={styles.patternRow}>
                  <span className={styles.patternIcon}>{p.icon || defaultIcon}</span>
                  <p className={styles.patternDesc}>{p.description}</p>
                  <span className={styles.patternTag}>{typeLabel}</span>
                </div>
              );
            })}
          </div>
        </section>
      )}

      {/* Checkin trigger banner */}
      <section className={styles.checkinCard} onClick={() => setShowCheckin(true)}>
        <div className={styles.checkinIcon}>
          <Smile size={20} />
        </div>
        <div className={styles.checkinText}>
          <p className={styles.checkinTitle}>Check-in chỉ số tuần mới</p>
          <p className={styles.checkinSub}>Cập nhật nhanh cảm giác cơ thể của bạn để AI theo dõi tốt hơn</p>
        </div>
        <ChevronRight size={18} className={styles.chevron} />
      </section>

      {/* Health Timeline logs */}
      {timeline.length > 0 && (
        <section style={{ marginTop: '24px' }}>
          <div className={styles.sectionHeader}>
            <Activity size={16} />
            <h2 className={styles.sectionHeaderTitle}>Dòng thời gian sức khỏe</h2>
          </div>
          {timeline.map((month, mIdx) => (
            <div key={mIdx} className={styles.timelineMonth}>
              <div className={styles.monthHeader}>
                <h3 className={styles.monthLabel}>{month.label}</h3>
                {month.healthScore !== null && (
                  <div className={styles.monthScoreRow}>
                    {/* mini bar */}
                    <div
                      style={{
                        width: '50px',
                        height: '4px',
                        borderRadius: '2px',
                        background: 'var(--border)',
                        overflow: 'hidden',
                      }}
                    >
                      <div
                        style={{
                          width: `${month.healthScore}%`,
                          height: '100%',
                          background: month.healthScore >= 75 ? '#16a34a' : month.healthScore >= 50 ? '#d97706' : '#dc2626',
                        }}
                      />
                    </div>
                    <span
                      className={styles.monthScoreText}
                      style={{ color: month.healthScore >= 75 ? '#16a34a' : month.healthScore >= 50 ? '#d97706' : '#dc2626' }}
                    >
                      {month.healthScore.toFixed(0)}%
                    </span>
                  </div>
                )}
              </div>

              <div className={styles.timelineCard}>
                {month.events.map((e) => (
                  <div key={e.id} className={styles.eventRow}>
                    <span className={styles.eventEmoji}>{e.sourceIcon}</span>
                    <div className={styles.eventDetails}>
                      <span className={styles.eventSource}>{e.sourceLabel}</span>
                      <p className={styles.eventText}>{e.rawContent}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </section>
      )}

      {/* Checkin Modal */}
      <Modal isOpen={showCheckin} onClose={() => setShowCheckin(false)}>
        <div className={styles.checkinModal}>
          <h2 className={styles.checkinModalTitle}>Hôm nay bạn thấy thế nào?</h2>
          <p className={styles.checkinModalSub}>Cảm nhận cơ thể của bạn giúp AI định hình baseline sinh học và phát hiện dị thường.</p>

          <div className={styles.moodGrid}>
            <div
              className={`${styles.moodCard} ${selectedMood === 'good' ? styles.selected : ''}`}
              onClick={() => setSelectedMood('good')}
            >
              <Smile className={styles.moodEmoji} style={{ color: '#16a34a' }} />
              <span className={styles.moodLabel}>Rất tốt</span>
            </div>

            <div
              className={`${styles.moodCard} ${selectedMood === 'normal' ? styles.selected : ''}`}
              onClick={() => setSelectedMood('normal')}
            >
              <Meh className={styles.moodEmoji} style={{ color: '#d97706' }} />
              <span className={styles.moodLabel}>Bình thường</span>
            </div>

            <div
              className={`${styles.moodCard} ${selectedMood === 'tired' ? styles.selected : ''}`}
              onClick={() => setSelectedMood('tired')}
            >
              <Frown className={styles.moodEmoji} style={{ color: '#3b82f6' }} />
              <span className={styles.moodLabel}>Mệt mỏi</span>
            </div>

            <div
              className={`${styles.moodCard} ${selectedMood === 'bad' ? styles.selected : ''}`}
              onClick={() => setSelectedMood('bad')}
            >
              <Frown className={styles.moodEmoji} style={{ color: '#dc2626' }} />
              <span className={styles.moodLabel}>Không khỏe</span>
            </div>
          </div>

          <div className={styles.modalActions}>
            <button
              onClick={handleCheckinSubmit}
              disabled={!selectedMood || submittingCheckin}
              className={styles.submitBtn}
            >
              {submittingCheckin ? 'Đang gửi...' : 'Xác nhận check-in'}
            </button>
            <button onClick={() => setShowCheckin(false)} className={styles.skipBtn}>
              Bỏ qua tuần này
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}

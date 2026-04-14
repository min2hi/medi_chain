'use client';

import React, { useState, useEffect } from 'react';
import { Bell, CheckCircle, Loader2 } from 'lucide-react';
import { Modal } from '@/components/shared/Modal';
import { SettingsApi } from '@/services/api.client';
import styles from '@/app/cai-dat/settings.module.css';

interface Prefs {
    notificationEnabled: boolean;
    notificationHour: number;
    notificationMinute: number;
}

interface Props {
    isOpen: boolean;
    onClose: () => void;
}


export const NotificationModal = ({ isOpen, onClose }: Props) => {
    const [prefs, setPrefs] = useState<Prefs>({
        notificationEnabled: false,
        notificationHour: 8,
        notificationMinute: 0,
    });
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const [saved, setSaved] = useState(false);
    const [permDenied, setPermDenied] = useState(false);

    // Load preferences from server on open
    useEffect(() => {
        if (!isOpen) return;
        const load = async () => {
            setLoading(true);
            try {
                const result = await SettingsApi.getPreferences();
                if (result.success && result.data) {
                    const d = result.data;
                    setPrefs((p) => ({
                        ...p,
                        notificationEnabled: (d.notificationEnabled as boolean) ?? false,
                        notificationHour: (d.notificationHour as number) ?? 8,
                        notificationMinute: (d.notificationMinute as number) ?? 0,
                    }));
                }
            } catch { /* fallback to defaults */ }
            finally { setLoading(false); }
        };
        load();
    }, [isOpen]);

    const toggleNotif = async () => {
        const next = !prefs.notificationEnabled;
        if (next && 'Notification' in window) {
            const perm = await Notification.requestPermission();
            if (perm === 'denied') {
                setPermDenied(true);
                return;
            }
        }
        setPermDenied(false);
        setPrefs((p) => ({ ...p, notificationEnabled: next }));
    };

    const handleSave = async () => {
        setSaving(true);
        try {
            await SettingsApi.updatePreferences({
                notificationEnabled: prefs.notificationEnabled,
                notificationHour: prefs.notificationHour,
                notificationMinute: prefs.notificationMinute,
            });
            setSaved(true);
            setTimeout(() => { setSaved(false); onClose(); }, 1500);
        } finally { setSaving(false); }
    };

    const hours = Array.from({ length: 24 }, (_, i) => i);
    const minutes = [0, 15, 30, 45];

    return (
        <Modal isOpen={isOpen} onClose={onClose}>
            <div className={styles.container}>
                <div className={styles.header}>
                    <div className={styles.iconWrap}>
                        <Bell size={20} />
                    </div>
                    <div>
                        <h3 className={styles.title}>Thông báo nhắc nhở</h3>
                        <p className={styles.subtitle}>Nhắc nhở uống thuốc và lịch hẹn hàng ngày</p>
                    </div>
                </div>

                {loading ? (
                    <div style={{ textAlign: 'center', padding: '24px' }}>
                        <Loader2 size={28} className={styles.spinner} style={{ color: 'var(--primary)' }} />
                    </div>
                ) : (
                    <>
                        {saved && (
                            <div className={styles.successMsg}>
                                <CheckCircle size={18} />
                                Đã lưu cài đặt thông báo
                            </div>
                        )}

                        {permDenied && (
                            <p className={styles.errorMsg}>
                                Trình duyệt đã chặn thông báo. Vào Settings → Site Permissions để bật lại.
                            </p>
                        )}

                        {/* Toggle */}
                        <div className={styles.toggleRow}>
                            <div>
                                <div className={styles.toggleLabel}>Bật thông báo</div>
                                <div className={styles.toggleSub}>Nhận nhắc nhở qua trình duyệt</div>
                            </div>
                            <button
                                className={`${styles.toggle} ${prefs.notificationEnabled ? styles.toggleOn : ''}`}
                                onClick={toggleNotif}
                                aria-label="Toggle notification"
                            >
                                <div className={styles.toggleKnob} />
                            </button>
                        </div>

                        {/* Time picker — chỉ show khi bật */}
                        {prefs.notificationEnabled && (
                            <div>
                                <p className={styles.label} style={{ marginTop: '16px' }}>
                                    Giờ nhắc nhở hàng ngày
                                </p>
                                <div className={styles.timePicker}>
                                    <select
                                        className={styles.timeSelect}
                                        value={prefs.notificationHour}
                                        onChange={(e) => setPrefs((p) => ({ ...p, notificationHour: +e.target.value }))}
                                    >
                                        {hours.map((h) => (
                                            <option key={h} value={h}>
                                                {String(h).padStart(2, '0')}
                                            </option>
                                        ))}
                                    </select>
                                    <span className={styles.timeSep}>:</span>
                                    <select
                                        className={styles.timeSelect}
                                        value={prefs.notificationMinute}
                                        onChange={(e) => setPrefs((p) => ({ ...p, notificationMinute: +e.target.value }))}
                                    >
                                        {minutes.map((m) => (
                                            <option key={m} value={m}>
                                                {String(m).padStart(2, '0')}
                                            </option>
                                        ))}
                                    </select>
                                </div>
                            </div>
                        )}

                        <div className={styles.actions}>
                            <button className={styles.btnCancel} onClick={onClose}>Hủy</button>
                            <button
                                className={styles.btnPrimary}
                                onClick={handleSave}
                                disabled={saving}
                            >
                                {saving ? <Loader2 size={16} className={styles.spinner} /> : null}
                                {saving ? 'Đang lưu...' : 'Lưu cài đặt'}
                            </button>
                        </div>
                    </>
                )}
            </div>
        </Modal>
    );
};

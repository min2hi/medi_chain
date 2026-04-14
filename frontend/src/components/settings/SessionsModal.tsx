'use client';

import React, { useState, useEffect } from 'react';
import { Monitor, Smartphone, Loader2, LogOut } from 'lucide-react';
import { Modal } from '@/components/shared/Modal';
import { SettingsApi } from '@/services/api.client';
import styles from '@/app/cai-dat/settings.module.css';

interface Session {
    id: string;
    device: string;
    ip: string;
    lastActive: string;
    isCurrent: boolean;
    userAgent?: string;
}

interface Props {
    isOpen: boolean;
    onClose: () => void;
}



// Detect device type from user-agent string
function getDeviceLabel(ua: string = ''): string {
    if (/mobile|android|iphone/i.test(ua)) return 'Điện thoại di động';
    if (/tablet|ipad/i.test(ua)) return 'Máy tính bảng';
    return 'Máy tính / Trình duyệt';
}

export const SessionsModal = ({ isOpen, onClose }: Props) => {
    const [sessions, setSessions] = useState<Session[]>([]);
    const [loading, setLoading] = useState(false);
    const [revoking, setRevoking] = useState<string | null>(null);

    useEffect(() => {
        if (!isOpen) return;
        const load = async () => {
            setLoading(true);
            try {
                const result = await SettingsApi.getSessions();
                if (result.success && result.data) {
                    setSessions(result.data);
                } else {
                    throw new Error();
                }
            } catch {
                // API not yet live — show current session as placeholder
                setSessions([
                    {
                        id: 'current',
                        device: 'Trình duyệt hiện tại',
                        ip: '—',
                        lastActive: new Date().toISOString(),
                        isCurrent: true,
                    },
                ]);
            } finally {
                setLoading(false);
            }
        };
        load();
    }, [isOpen]);

    const revokeSession = async (sessionId: string) => {
        setRevoking(sessionId);
        try {
            await SettingsApi.revokeSession(sessionId);
            setSessions((prev) => prev.filter((s) => s.id !== sessionId));
        } finally {
            setRevoking(null);
        }
    };

    const formatDate = (iso: string) => {
        try {
            return new Intl.DateTimeFormat('vi-VN', {
                day: '2-digit', month: '2-digit', year: 'numeric',
                hour: '2-digit', minute: '2-digit',
            }).format(new Date(iso));
        } catch { return iso; }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose}>
            <div className={styles.container}>
                <div className={styles.header}>
                    <div className={styles.iconWrap}>
                        <Monitor size={20} />
                    </div>
                    <div>
                        <h3 className={styles.title}>Phiên đăng nhập</h3>
                        <p className={styles.subtitle}>{sessions.length} thiết bị đang đăng nhập</p>
                    </div>
                </div>

                {loading ? (
                    <div style={{ textAlign: 'center', padding: '32px' }}>
                        <Loader2 size={28} className={styles.spinner} style={{ color: 'var(--primary)' }} />
                    </div>
                ) : (
                    <div className={styles.deviceList}>
                        {sessions.map((s) => {
                            const isMobile = /mobile|android|iphone/i.test(s.userAgent ?? '');
                            return (
                                <div key={s.id} className={styles.deviceItem}>
                                    <div className={styles.deviceIcon}>
                                        {isMobile ? <Smartphone size={18} /> : <Monitor size={18} />}
                                    </div>
                                    <div className={styles.deviceInfo} style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1 }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                            <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>
                                                {s.device || getDeviceLabel(s.userAgent)}
                                            </span>
                                            {s.isCurrent && (
                                                <span className={styles.deviceBadge}>Hiện tại</span>
                                            )}
                                        </div>
                                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                                            {s.ip !== '—' && `IP: ${s.ip} · `}
                                            Hoạt động: {formatDate(s.lastActive)}
                                        </div>
                                    </div>
                                    {!s.isCurrent && (
                                        <button
                                            className={styles.btnPrimary}
                                            style={{ flex: 'none', padding: '6px 14px', fontSize: '0.78rem' }}
                                            onClick={() => revokeSession(s.id)}
                                            disabled={revoking === s.id}
                                        >
                                            {revoking === s.id
                                                ? <Loader2 size={14} className={styles.spinner} />
                                                : <LogOut size={14} />}
                                        </button>
                                    )}
                                </div>
                            );
                        })}
                    </div>
                )}

                <button className={styles.btnCancel} style={{ width: '100%' }} onClick={onClose}>
                    Đóng
                </button>
            </div>
        </Modal>
    );
};

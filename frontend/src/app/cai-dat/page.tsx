'use client';

import React, { useState, useEffect } from 'react';
import {
    Key,
    Fingerprint,
    RotateCcw,
    Bell,
    Moon,
    Sun,
    Globe,
    Info,
    LifeBuoy,
    LogOut,
    ChevronRight,
    Shield,
    Smartphone,
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import styles from './settings.module.css';

export default function SettingsPage() {
    const router = useRouter();
    const [theme, setTheme] = useState('light');
    const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

    useEffect(() => {
        const saved = localStorage.getItem('theme') ||
            (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
        setTheme(saved);
        document.documentElement.setAttribute('data-theme', saved);
    }, []);

    const toggleTheme = () => {
        const next = theme === 'light' ? 'dark' : 'light';
        setTheme(next);
        document.documentElement.setAttribute('data-theme', next);
        localStorage.setItem('theme', next);
    };

    const handleLogout = () => {
        AuthService.logout();
        router.push('/auth/login');
        router.refresh();
    };

    // ─── Item renderer ───────────────────────────────────────
    const renderItem = (
        Icon: React.ElementType,
        label: string,
        opts?: {
            onClick?: () => void;
            badge?: string;
            badgeColor?: string;
            rightNode?: React.ReactNode;
            danger?: boolean;
        }
    ) => (
        <div
            key={label}
            className={`${styles.item} ${opts?.danger ? styles.itemDanger : ''}`}
            onClick={opts?.onClick}
            role="button"
            tabIndex={0}
            onKeyDown={e => e.key === 'Enter' && opts?.onClick?.()}
        >
            <div className={styles.itemLeft}>
                <Icon size={20} className={opts?.danger ? styles.itemIconDanger : styles.itemIcon} />
                <span>{label}</span>
                {opts?.badge && (
                    <span className={styles.badge} style={{ background: opts.badgeColor }}>
                        {opts.badge}
                    </span>
                )}
            </div>
            {opts?.rightNode ?? <ChevronRight size={18} className={styles.chevron} />}
        </div>
    );

    return (
        <div>
            <header className={styles.header}>
                <h1 className={styles.title}>Cài đặt</h1>
            </header>

            <div className={styles.sections}>

                {/* ── Tài khoản & Bảo mật ── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Tài khoản &amp; Bảo mật</h2>
                    <div className={styles.itemList}>
                        {renderItem(Key, 'Đổi mật khẩu khóa dữ liệu')}
                        {renderItem(Fingerprint, 'Biometric / Vân tay', {
                            badge: 'Mới',
                            badgeColor: '#10b981',
                        })}
                        {renderItem(RotateCcw, 'Sao lưu Recovery Key')}
                        {renderItem(Shield, 'Phiên đăng nhập', {
                            badge: '1 thiết bị',
                            badgeColor: '#3b82f6',
                        })}
                    </div>
                </div>

                {/* ── Ứng dụng ── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Ứng dụng</h2>
                    <div className={styles.itemList}>
                        {renderItem(Bell, 'Thông báo nhắc nhở')}
                        {renderItem(
                            theme === 'dark' ? Sun : Moon,
                            theme === 'dark' ? 'Chuyển sang Sáng' : 'Chuyển sang Tối',
                            {
                                onClick: toggleTheme,
                                rightNode: (
                                    <div className={`${styles.toggle} ${theme === 'dark' ? styles.toggleOn : ''}`}>
                                        <div className={styles.toggleKnob} />
                                    </div>
                                ),
                            }
                        )}
                        {renderItem(Globe, 'Ngôn ngữ', {
                            rightNode: (
                                <span className={styles.rightLabel}>Tiếng Việt</span>
                            ),
                        })}
                        {renderItem(Smartphone, 'Ứng dụng di động')}
                    </div>
                </div>

                {/* ── Về MediChain ── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Về MediChain</h2>
                    <div className={styles.itemList}>
                        {renderItem(Info, 'Phiên bản 1.0.0', {
                            badge: 'Mới nhất',
                            badgeColor: '#059669',
                        })}
                        {renderItem(LifeBuoy, 'Hỗ trợ & Hướng dẫn')}
                    </div>
                </div>

                {/* ── Đăng xuất — tách riêng, không nằm trong card ── */}
                <div className={styles.section}>
                    <div className={styles.itemList}>
                        {renderItem(LogOut, 'Đăng xuất', {
                            onClick: () => setShowLogoutConfirm(true),
                            danger: true,
                            rightNode: <span />,
                        })}
                    </div>
                </div>

            </div>

            {/* Logout confirm modal */}
            <ConfirmModal
                isOpen={showLogoutConfirm}
                onClose={() => setShowLogoutConfirm(false)}
                onConfirm={handleLogout}
                title="Đăng xuất"
                message="Bạn có chắc chắn muốn đăng xuất khỏi MediChain không?"
                confirmText="Đăng xuất"
            />
        </div>
    );
}

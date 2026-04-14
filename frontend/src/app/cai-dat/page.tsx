'use client';

import React, { useState, useEffect } from 'react';
import {
    Key, Fingerprint, RotateCcw, Bell, Moon, Sun,
    Globe, Info, LifeBuoy, LogOut, ChevronRight,
    Shield, Smartphone,
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import { ChangePasswordModal } from '@/components/settings/ChangePasswordModal';
import { NotificationModal } from '@/components/settings/NotificationModal';
import { LanguageModal } from '@/components/settings/LanguageModal';
import { SessionsModal } from '@/components/settings/SessionsModal';
import { RecoveryKeyModal } from '@/components/settings/RecoveryKeyModal';
import { MobileAppModal } from '@/components/settings/MobileAppModal';
import { SupportModal } from '@/components/settings/SupportModal';
import styles from './settings.module.css';

type ModalKey =
    | 'changePassword' | 'biometric' | 'recovery' | 'sessions'
    | 'notification' | 'language' | 'mobileApp' | 'support' | 'logout'
    | null;

export default function SettingsPage() {
    const router = useRouter();
    const [theme, setTheme] = useState('light');
    const [openModal, setOpenModal] = useState<ModalKey>(null);
    const [locale, setLocale] = useState('vi');

    useEffect(() => {
        const saved = localStorage.getItem('theme') ||
            (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
        setTheme(saved);
        document.documentElement.setAttribute('data-theme', saved);
        setLocale(localStorage.getItem('locale') || 'vi');
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

    // ─── Item renderer ────────────────────────────────────────
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
            onKeyDown={(e) => e.key === 'Enter' && opts?.onClick?.()}
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

                {/* ── Tài khoản & Bảo mật ─────────────────── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Tài khoản &amp; Bảo mật</h2>
                    <div className={styles.itemList}>
                        {renderItem(Key, 'Đổi mật khẩu khóa dữ liệu', {
                            onClick: () => setOpenModal('changePassword'),
                        })}
                        {renderItem(Fingerprint, 'Biometric / Vân tay', {
                            badge: 'Mới',
                            badgeColor: '#10b981',
                            rightNode: (
                                <span className={styles.rightLabel} style={{ color: 'var(--text-muted)', fontSize: '0.78rem' }}>
                                    Chỉ mobile
                                </span>
                            ),
                        })}
                        {renderItem(RotateCcw, 'Sao lưu Recovery Key', {
                            onClick: () => setOpenModal('recovery'),
                        })}
                        {renderItem(Shield, 'Phiên đăng nhập', {
                            badge: '1 thiết bị',
                            badgeColor: '#3b82f6',
                            onClick: () => setOpenModal('sessions'),
                        })}
                    </div>
                </div>

                {/* ── Ứng dụng ────────────────────────────── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Ứng dụng</h2>
                    <div className={styles.itemList}>
                        {renderItem(Bell, 'Thông báo nhắc nhở', {
                            onClick: () => setOpenModal('notification'),
                        })}
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
                            onClick: () => setOpenModal('language'),
                            rightNode: (
                                <span className={styles.rightLabel}>
                                    {locale === 'vi' ? 'Tiếng Việt' : 'English'}
                                </span>
                            ),
                        })}
                        {renderItem(Smartphone, 'Ứng dụng di động', {
                            onClick: () => setOpenModal('mobileApp'),
                        })}
                    </div>
                </div>

                {/* ── Về MediChain ─────────────────────────── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Về MediChain</h2>
                    <div className={styles.itemList}>
                        {renderItem(Info, 'Phiên bản 1.0.0', {
                            badge: 'Mới nhất',
                            badgeColor: '#059669',
                            rightNode: (
                                <span className={styles.badge} style={{ background: '#059669' }}>
                                    Mới nhất
                                </span>
                            ),
                        })}
                        {renderItem(LifeBuoy, 'Hỗ trợ & Hướng dẫn', {
                            onClick: () => setOpenModal('support'),
                        })}
                    </div>
                </div>

                {/* ── Đăng xuất ─────────────────────────────── */}
                <div className={styles.section}>
                    <div className={styles.itemList}>
                        {renderItem(LogOut, 'Đăng xuất', {
                            onClick: () => setOpenModal('logout'),
                            danger: true,
                            rightNode: <span />,
                        })}
                    </div>
                </div>
            </div>

            {/* ── Modals ──────────────────────────────────── */}
            <ChangePasswordModal
                isOpen={openModal === 'changePassword'}
                onClose={() => setOpenModal(null)}
            />
            <NotificationModal
                isOpen={openModal === 'notification'}
                onClose={() => setOpenModal(null)}
            />
            <LanguageModal
                isOpen={openModal === 'language'}
                onClose={() => setOpenModal(null)}
                currentLocale={locale}
            />
            <SessionsModal
                isOpen={openModal === 'sessions'}
                onClose={() => setOpenModal(null)}
            />
            <RecoveryKeyModal
                isOpen={openModal === 'recovery'}
                onClose={() => setOpenModal(null)}
            />
            <MobileAppModal
                isOpen={openModal === 'mobileApp'}
                onClose={() => setOpenModal(null)}
            />
            <SupportModal
                isOpen={openModal === 'support'}
                onClose={() => setOpenModal(null)}
            />
            <ConfirmModal
                isOpen={openModal === 'logout'}
                onClose={() => setOpenModal(null)}
                onConfirm={handleLogout}
                title="Đăng xuất"
                message="Bạn có chắc chắn muốn đăng xuất khỏi MediChain không?"
                confirmText="Đăng xuất"
            />
        </div>
    );
}

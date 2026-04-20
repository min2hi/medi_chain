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
import styles from '@/components/settings/settings.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

type ModalKey =
    | 'changePassword' | 'biometric' | 'recovery' | 'sessions'
    | 'notification' | 'language' | 'mobileApp' | 'support' | 'logout'
    | null;

export default function SettingsPage() {
    const router = useRouter();
    const { t, locale } = useTranslation();
    const [theme, setTheme] = useState('light');
    const [openModal, setOpenModal] = useState<ModalKey>(null);

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
                <h1 className={styles.title}>{t('settings.title')}</h1>
            </header>

            <div className={styles.sections}>

                {/* ── Tài khoản & Bảo mật ─────────────────── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>{t('settings.account_security')}</h2>
                    <div className={styles.itemList}>
                        {renderItem(Key, t('settings.change_password'), {
                            onClick: () => setOpenModal('changePassword'),
                        })}
                        {renderItem(Fingerprint, t('settings.biometric'), {
                            badge: t('settings.latest'),
                            badgeColor: '#10b981',
                            rightNode: (
                                <span className={styles.rightLabel} style={{ color: 'var(--text-muted)', fontSize: '0.78rem' }}>
                                    {t('settings.only_mobile')}
                                </span>
                            ),
                        })}
                        {renderItem(RotateCcw, t('settings.recovery_key'), {
                            onClick: () => setOpenModal('recovery'),
                        })}
                        {renderItem(Shield, t('settings.sessions'), {
                            badge: '1 thiết bị',
                            badgeColor: '#3b82f6',
                            onClick: () => setOpenModal('sessions'),
                        })}
                    </div>
                </div>

                {/* ── Ứng dụng ────────────────────────────── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>{t('settings.app')}</h2>
                    <div className={styles.itemList}>
                        {renderItem(Bell, t('settings.notifications'), {
                            onClick: () => setOpenModal('notification'),
                        })}
                        {renderItem(
                            theme === 'dark' ? Sun : Moon,
                            theme === 'dark' ? t('settings.theme') : t('settings.theme_dark'),
                            {
                                onClick: toggleTheme,
                                rightNode: (
                                    <div className={`${styles.toggle} ${theme === 'dark' ? styles.toggleOn : ''}`}>
                                        <div className={styles.toggleKnob} />
                                    </div>
                                ),
                            }
                        )}
                        {renderItem(Globe, t('settings.language'), {
                            onClick: () => setOpenModal('language'),
                            rightNode: (
                                <span className={styles.rightLabel}>
                                    {locale === 'vi' ? 'Tiếng Việt' : 'English'}
                                </span>
                            ),
                        })}
                        {renderItem(Smartphone, t('settings.mobile_app'), {
                            onClick: () => setOpenModal('mobileApp'),
                        })}
                    </div>
                </div>

                {/* ── Về MediChain ─────────────────────────── */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>{t('settings.about')}</h2>
                    <div className={styles.itemList}>
                        {renderItem(Info, `${t('settings.version')} 1.0.0`, {
                            badge: t('settings.latest'),
                            badgeColor: '#059669',
                            rightNode: (
                                <span className={styles.badge} style={{ background: '#059669' }}>
                                    {t('settings.latest')}
                                </span>
                            ),
                        })}
                        {renderItem(LifeBuoy, t('settings.support'), {
                            onClick: () => setOpenModal('support'),
                        })}
                    </div>
                </div>

                {/* ── Đăng xuất ─────────────────────────────── */}
                <div className={styles.section}>
                    <div className={styles.itemList}>
                        {renderItem(LogOut, t('settings.logout'), {
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
                title={t('settings.logout')}
                message={locale === 'vi' ? 'Bạn có chắc chắn muốn đăng xuất khỏi MediChain không?' : 'Are you sure you want to log out of MediChain?'}
                confirmText={t('settings.logout')}
            />
        </div>
    );
}

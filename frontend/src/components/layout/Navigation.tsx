'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { NAV_ITEMS } from './nav-items';
import { motion, AnimatePresence } from 'framer-motion';
import styles from './Navigation.module.css';
import { UserProfile } from './UserProfile';
import { UserCircle, XCircle, ShieldCheck } from 'lucide-react';
import { useTranslation } from '@/i18n/I18nProvider';
import { AuthService } from '@/services/auth.client';

export const Navigation = () => {
    const { t } = useTranslation();
    const router = useRouter();
    const pathname = usePathname();
    const [viewContext, setViewContext] = React.useState<{ isSharing: boolean; name: string | null }>({
        isSharing: false,
        name: null
    });
    const [isAdmin, setIsAdmin] = React.useState(false);

    React.useEffect(() => {
        const u = AuthService.getCurrentUser();
        setIsAdmin(u?.role === 'ADMIN' || u?.role === 'DOCTOR');
    }, []);

    const isAuthPage = pathname?.startsWith('/auth') || pathname?.startsWith('/reset-password');

    const updateContext = () => {
        const viewingId = localStorage.getItem('viewing_as_userId');
        const viewingName = localStorage.getItem('viewing_as_name');
        setViewContext({
            isSharing: !!viewingId,
            name: viewingName
        });
    };

    React.useEffect(() => {
        updateContext();
        window.addEventListener('view-context-changed', updateContext);
        return () => window.removeEventListener('view-context-changed', updateContext);
    }, []);

    const handleExitContext = () => {
        localStorage.removeItem('viewing_as_userId');
        localStorage.removeItem('viewing_as_name');
        updateContext();
        window.dispatchEvent(new Event('view-context-changed'));
        window.location.href = '/';
    };

    if (isAuthPage) return null;

    return (
        <>
            <aside className={styles.sidebar}>
                <Link href="/" className={styles.sidebarLogo}>
                    <span className={styles.logoText}>MediChain</span>
                </Link>

                <AnimatePresence>
                    {viewContext.isSharing && (
                        <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            className={styles.contextIndicator}
                        >
                            <div className={styles.contextHeader}>
                                <UserCircle size={14} />
                                <span>Đang xem hồ sơ:</span>
                            </div>
                            <div className={styles.contextInfo}>
                                <span className={styles.contextName}>{viewContext.name}</span>
                                <button
                                    className={styles.exitBtn}
                                    onClick={handleExitContext}
                                >
                                    <XCircle size={14} />
                                </button>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>

                <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    <nav className={styles.sidebarNav}>
                        {NAV_ITEMS.map((item) => {
                            const isActive = pathname === item.href;
                            return (
                                <Link key={item.href} href={item.href}>
                                    <div className={`${styles.navItem} ${isActive ? styles.navItemActive : ''}`}>
                                        <item.icon size={22} />
                                        <span>{t(item.label)}</span>
                                        {isActive && (
                                            <motion.div
                                                layoutId="sidebar-active"
                                                className={styles.activeIndicator}
                                                transition={{ type: 'spring', stiffness: 300, damping: 30 }}
                                            />
                                        )}
                                    </div>
                                </Link>
                            );
                        })}
                    </nav>
                </div>

                <div className={styles.sidebarFooter}>
                    {isAdmin && (
                        <button
                            onClick={() => router.push('/admin/clinical-rules')}
                            style={{
                                display: 'flex', alignItems: 'center', gap: '8px',
                                width: '100%', padding: '8px 12px', marginBottom: '8px',
                                background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.2)',
                                borderRadius: '8px', color: '#60a5fa', fontSize: '12px',
                                cursor: 'pointer', fontWeight: 500, transition: 'background 0.2s',
                            }}
                            title="Chuyển sang Admin Portal"
                        >
                            <ShieldCheck size={14} />
                            <span>Admin Portal</span>
                            <span style={{ marginLeft: 'auto', fontSize: '10px', opacity: 0.5 }}>→</span>
                        </button>
                    )}
                    <UserProfile />
                </div>
            </aside>

            <nav className={styles.bottomNav}>
                {NAV_ITEMS.map((item) => {
                    const isActive = pathname === item.href;
                    return (
                        <Link key={item.href} href={item.href}>
                            <div className={`${styles.bottomNavItem} ${isActive ? styles.bottomNavItemActive : ''}`}>
                                <item.icon size={20} />
                                <span>{item.label}</span>
                            </div>
                        </Link>
                    );
                })}
            </nav>
        </>
    );
};

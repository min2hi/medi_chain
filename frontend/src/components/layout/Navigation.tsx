'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { NAV_ITEMS } from './nav-items';
import { motion } from 'framer-motion';
import styles from './Navigation.module.css';
import { UserProfile } from './UserProfile';

export const Navigation = () => {
    const pathname = usePathname();
    const isAuthPage = pathname?.startsWith('/auth');

    if (isAuthPage) return null;

    return (
        <>
            {/* Sidebar for Desktop */}
            <aside className={styles.sidebar}>
                <Link href="/" className={styles.sidebarLogo}>
                    <span className={styles.logoText}>MediChain</span>
                </Link>

                <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    <nav className={styles.sidebarNav}>
                        {NAV_ITEMS.map((item) => {
                            const isActive = pathname === item.href;
                            return (
                                <Link key={item.href} href={item.href}>
                                    <div className={`${styles.navItem} ${isActive ? styles.navItemActive : ''}`}>
                                        <item.icon size={22} />
                                        <span>{item.label}</span>
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
                    <UserProfile />
                </div>
            </aside>

            {/* Bottom Nav for Mobile */}
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

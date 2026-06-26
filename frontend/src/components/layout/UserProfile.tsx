'use client';

import React, { useState, useEffect } from 'react';
import { ChevronUp, User, LogOut } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
import { ProfileApi } from '@/services/api.client';
import styles from './UserProfile.module.css';

interface CurrentUser {
    name?: string;
    email?: string;
    role?: string;
    [key: string]: unknown;
}

export const UserProfile = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [user, setUser] = useState<CurrentUser | null>(null);
    const router = useRouter();
    const wrapperRef = React.useRef<HTMLDivElement>(null);

    useEffect(() => {
        const fetchUser = async () => {
            try {
                const token = localStorage.getItem('token');
                if (token) {
                    const result = await ProfileApi.getDashboard() as { success: boolean; data?: { user?: CurrentUser } };
                    if (result.success && result.data?.user) {
                        setUser(result.data.user);
                        localStorage.setItem('user', JSON.stringify(result.data.user));
                        return;
                    }
                }
            } catch (err) {
                console.error('Failed to fetch user profile:', err);
            }
            const currentUser = AuthService.getCurrentUser();
            setUser(currentUser);
        };

        fetchUser();

        window.addEventListener('user-updated', fetchUser);
        window.addEventListener('storage', fetchUser);

        const handleClickOutside = (event: MouseEvent) => {
            if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);

        return () => {
            window.removeEventListener('user-updated', fetchUser);
            window.removeEventListener('storage', fetchUser);
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, []);

    const handleLogout = () => {
        AuthService.logout();
        router.replace('/auth/login');
    };

    if (!user) return null;

    const initial = user.name ? user.name.charAt(0).toUpperCase() : '?';

    const handleNavigate = (path: string) => {
        setIsOpen(false);
        router.push(path);
    };

    return (
        <div className={styles.wrapper} ref={wrapperRef}>
            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                        className={`${styles.menu} glass`}
                    >
                        {/* User info header */}
                        <div className={styles.menuHeader}>
                            <div className={styles.largeAvatar}>{initial}</div>
                            <div className={styles.userInfo}>
                                <p className={styles.userName}>{user.name || 'Người dùng'}</p>
                                <p className={styles.userRole}>
                                    {user.role === 'DOCTOR' ? 'Bác sĩ chuyên khoa' : 'Hội viên MediChain'}
                                </p>
                            </div>
                        </div>
                        <div className={styles.divider} />

                        {/* Actions */}
                        <button className={styles.menuItem} onClick={() => handleNavigate('/ho-so')}>
                            <User size={16} />
                            <span>Hồ sơ của tôi</span>
                        </button>
                        <div className={styles.divider} />
                        <button className={styles.logoutBtn} onClick={handleLogout}>
                            <LogOut size={16} />
                            <span>Đăng xuất</span>
                        </button>
                    </motion.div>
                )}
            </AnimatePresence>

            <div className="flex items-center gap-2 w-full">
                <motion.div
                    whileTap={{ scale: 0.95 }}
                    onClick={() => setIsOpen(!isOpen)}
                    className={`${styles.profilePill} glass ${isOpen ? styles.active : ''} flex-1`}
                >
                    <div className={styles.avatar}>{initial}</div>
                    <div className={styles.pillText}>
                        <span className={styles.pillName}>{user.name || 'Tài khoản'}</span>
                    </div>
                    <ChevronUp
                        size={16}
                        className={`${styles.chevron} ${isOpen ? styles.rotate : ''}`}
                    />
                </motion.div>
                
                <button
                    onClick={handleLogout}
                    className="flex items-center justify-center gap-1.5 px-3 py-2 bg-red-50 hover:bg-red-100 border border-red-200 text-red-600 text-xs font-bold rounded-xl transition duration-150 cursor-pointer shrink-0"
                    title="Đăng xuất"
                >
                    <LogOut className="w-3.5 h-3.5" />
                    <span>Đăng xuất</span>
                </button>
            </div>
        </div>
    );
};

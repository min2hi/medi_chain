'use client';

import React, { useState, useEffect } from 'react';
import { ChevronUp, User, Settings } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
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
                    const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api'}/user/dashboard`, {
                        headers: { 'Authorization': `Bearer ${token}` }
                    });
                    const result = await res.json();
                    if (result.success && result.data.user) {
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

                        {/* Actions — chỉ điều hướng, không action phức tạp */}
                        <button className={styles.menuItem} onClick={() => handleNavigate('/ho-so')}>
                            <User size={16} />
                            <span>Hồ sơ của tôi</span>
                        </button>
                        <button className={styles.menuItem} onClick={() => handleNavigate('/cai-dat')}>
                            <Settings size={16} />
                            <span>Cài đặt</span>
                        </button>
                    </motion.div>
                )}
            </AnimatePresence>

            <motion.div
                whileTap={{ scale: 0.95 }}
                onClick={() => setIsOpen(!isOpen)}
                className={`${styles.profilePill} glass ${isOpen ? styles.active : ''}`}
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
        </div>
    );
};

'use client';

import React, { useState, useEffect } from 'react';
import { LogOut, ChevronUp, User, Moon, Sun } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
import styles from './UserProfile.module.css';

export const UserProfile = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [user, setUser] = useState<any>(null);
    const [theme, setTheme] = useState('light');
    const router = useRouter();

    useEffect(() => {
        const fetchUser = async () => {
            // Thử lấy từ API trước để đảm bảo "đối chiếu với database"
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
                console.error("Failed to fetch user profile:", err);
            }

            // Fallback lấy từ localStorage nếu API lỗi
            const currentUser = AuthService.getCurrentUser();
            setUser(currentUser);
        };

        // Khởi tạo theme từ localStorage hoặc hệ thống
        const savedTheme = localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
        setTheme(savedTheme);
        document.documentElement.setAttribute('data-theme', savedTheme);

        fetchUser();

        // Lắng nghe sự kiện cập nhật user để đồng bộ UI
        window.addEventListener('user-updated', fetchUser);
        window.addEventListener('storage', fetchUser);

        return () => {
            window.removeEventListener('user-updated', fetchUser);
            window.removeEventListener('storage', fetchUser);
        };
    }, []);

    const toggleTheme = () => {
        const newTheme = theme === 'light' ? 'dark' : 'light';
        setTheme(newTheme);
        document.documentElement.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
    };

    const handleLogout = () => {
        AuthService.logout();
        router.push('/auth/login');
        router.refresh();
    };

    if (!user) return null; // Không hiển thị nếu chưa có user thực tế

    const initial = user.name ? user.name.charAt(0).toUpperCase() : '?';

    return (
        <div className={styles.wrapper}>
            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                        className={`${styles.menu} glass`}
                    >
                        <div className={styles.menuHeader}>
                            <div className={styles.largeAvatar}>{initial}</div>
                            <div className={styles.userInfo}>
                                <p className={styles.userName}>{user.name || 'Người dùng'}</p>
                                <p className={styles.userRole}>{user.role === 'DOCTOR' ? 'Bác sĩ chuyên khoa' : 'Hội viên MediChain'}</p>
                            </div>
                        </div>
                        <div className={styles.divider} />

                        <button className={styles.menuItem} onClick={toggleTheme}>
                            {theme === 'light' ? (
                                <>
                                    <Moon size={18} />
                                    <span>Chế độ tối</span>
                                </>
                            ) : (
                                <>
                                    <Sun size={18} />
                                    <span>Chế độ sáng</span>
                                </>
                            )}
                        </button>

                        <button className={styles.logoutBtn} onClick={handleLogout}>
                            <LogOut size={18} />
                            <span>Đăng xuất</span>
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

'use client';

import React from 'react';
import styles from './auth-layout.module.css';

export default function AuthLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <div className={styles.authContainer}>
            <div className={styles.authBox}>
                <div className={styles.brand}>
                    <div className={styles.logo}>M</div>
                    <span className={styles.brandName}>MediChain</span>
                </div>
                {children}
            </div>
            <div className={styles.authSide}>
                <div className={styles.quoteBox}>
                    <h2 className={styles.quoteTitle}>Quản lý sức khỏe thông minh cho cả gia đình.</h2>
                    <p className={styles.quoteText}>Hệ thống bảo mật tuyệt đối dữ liệu y tế của bạn trên nền tảng Blockchain hiện đại.</p>
                </div>
            </div>
        </div>
    );
}

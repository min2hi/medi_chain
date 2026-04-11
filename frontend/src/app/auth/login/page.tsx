'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Mail, Lock, ArrowRight, Loader2 } from 'lucide-react';
import { AuthService } from '@/services/auth.client';
import styles from './login.module.css';

export default function LoginPage() {
    const router = useRouter();
    const [formData, setFormData] = useState({
        email: '',
        password: '',
    });
    const [loading, setLoading] = useState(false);
    const [loadingMessage, setLoadingMessage] = useState('');
    const [error, setError] = useState('');

    React.useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('expired') === 'true') {
            setError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        }
    }, []);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setLoadingMessage('');
        setError('');

        // Smart UX: Trấn an người dùng nếu backend Cold Start mất > 4s
        const msgTimer1 = setTimeout(() => setLoadingMessage('Đang khởi động hệ thống an toàn...'), 3500);
        const msgTimer2 = setTimeout(() => setLoadingMessage('Đang đồng bộ Sổ y bạ, vui lòng đợi...'), 8000);
        const msgTimer3 = setTimeout(() => setLoadingMessage('Lần đăng nhập đầu trong ngày sẽ mất thêm chút thời gian...'), 15000);

        try {
            const data = await AuthService.login(formData);

            if (!data.success) {
                throw new Error(data.message || 'Email hoặc mật khẩu không đúng');
            }

            // Success
            router.push('/');
            router.refresh();
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Đã có lỗi xảy ra');
        } finally {
            clearTimeout(msgTimer1);
            clearTimeout(msgTimer2);
            clearTimeout(msgTimer3);
            setLoading(false);
            setLoadingMessage('');
        }
    };

    return (
        <div className="animate-fade-in">
            <h1 className={styles.title}>Đăng nhập</h1>
            <p className={styles.subtitle}>Sổ y bạ của bạn, luôn sẵn sàng khi bạn cần.</p>

            <form className={styles.form} onSubmit={handleSubmit}>
                {error && <div className={styles.errorAlert}>{error}</div>}

                <div className={styles.inputGroup}>
                    <label>Email của bạn</label>
                    <div className={styles.inputWrapper}>
                        <Mail size={18} className={styles.inputIcon} />
                        <input
                            type="email"
                            placeholder="example@email.com"
                            required
                            value={formData.email}
                            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                        />
                    </div>
                </div>

                <div className={styles.inputGroup}>
                    <div className={styles.labelRow}>
                        <label>Mật khẩu</label>
                        <Link href="/auth/forgot" className={styles.link}>Quên mật khẩu?</Link>
                    </div>
                    <div className={styles.inputWrapper}>
                        <Lock size={18} className={styles.inputIcon} />
                        <input
                            type="password"
                            placeholder="••••••••"
                            required
                            value={formData.password}
                            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                        />
                    </div>
                </div>

                <button type="submit" className={styles.submitBtn} disabled={loading}>
                    {loading ? (
                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px' }}>
                            <Loader2 className="animate-spin" size={20} />
                            {loadingMessage && <span style={{ fontSize: '12px', opacity: 0.9, marginTop: '2px', fontWeight: 'normal' }}>{loadingMessage}</span>}
                        </div>
                    ) : (
                        <>
                            <span>Tiếp tục</span>
                            <ArrowRight size={18} />
                        </>
                    )}
                </button>
            </form>

            <div className={styles.footer}>
                <span>Chưa có tài khoản?</span>
                <Link href="/auth/register" className={styles.linkBold}>Đăng ký ngay</Link>
            </div>
        </div>
    );
}

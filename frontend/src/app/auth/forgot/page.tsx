'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Mail, ArrowLeft, ArrowRight, Loader2, CheckCircle2 } from 'lucide-react';
import { AuthService } from '@/services/auth.client';
import styles from '../login/login.module.css'; // Tái sử dụng CSS từ trang Login

export default function ForgotPasswordPage() {
    const [email, setEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const data = await AuthService.forgotPassword(email);

            if (!data.success) {
                throw new Error(data.message || 'Có lỗi xảy ra, vui lòng thử lại.');
            }

            // Success
            setSuccess(true);
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Đã có lỗi xảy ra');
        } finally {
            setLoading(false);
        }
    };

    if (success) {
        return (
            <div className="animate-fade-in" style={{ textAlign: 'center' }}>
                <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '24px' }}>
                    <div style={{ width: '80px', height: '80px', borderRadius: '50%', background: '#F0FDFA', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <CheckCircle2 size={40} color="#14B8A6" />
                    </div>
                </div>
                <h1 className={styles.title} style={{ fontSize: '1.5rem', marginBottom: '16px' }}>Kiểm tra hộp thư</h1>
                <p className={styles.subtitle} style={{ marginBottom: '32px' }}>
                    Chúng tôi đã gửi link đặt lại mật khẩu đến <strong>{email}</strong>.<br />
                    Link có hiệu lực trong 1 giờ.
                </p>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    <button
                        onClick={() => setSuccess(false)}
                        style={{ background: 'transparent', border: 'none', color: '#14B8A6', fontWeight: 600, cursor: 'pointer' }}
                    >
                        Gửi lại email
                    </button>
                    <Link href="/auth/login" className={styles.submitBtn} style={{ textDecoration: 'none' }}>
                        <ArrowLeft size={18} />
                        <span>Trở về Đăng nhập</span>
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="animate-fade-in">
            <h1 className={styles.title}>Quên mật khẩu?</h1>
            <p className={styles.subtitle}>Nhập email của bạn, chúng tôi sẽ gửi linh đặt lại mật khẩu.</p>

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
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            disabled={loading}
                        />
                    </div>
                </div>

                <button type="submit" className={styles.submitBtn} disabled={loading}>
                    {loading ? (
                        <Loader2 className="animate-spin" size={20} />
                    ) : (
                        <>
                            <span>Gửi link đặt lại</span>
                            <ArrowRight size={18} />
                        </>
                    )}
                </button>
            </form>

            <div className={styles.footer}  style={{ justifyContent: 'center' }}>
                <Link href="/auth/login" className={styles.linkBold} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <ArrowLeft size={16} /> Quay lại đăng nhập
                </Link>
            </div>
        </div>
    );
}

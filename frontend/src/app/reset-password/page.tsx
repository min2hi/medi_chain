'use client';

import React, { useState, Suspense } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { Lock, ArrowRight, ArrowLeft, Loader2, CheckCircle2, ShieldCheck } from 'lucide-react';
import { AuthService } from '@/services/auth.client';
import styles from '../auth/login/login.module.css';

// Component con xử lý form (Bắt buộc gom vào để bọc Suspense bên ngoài vì dùng useSearchParams - Chuẩn Next.js 14)
function ResetPasswordContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const token = searchParams.get('token') || '';

    const [password, setPassword] = useState('');
    const [confirm, setConfirm] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    if (!token) {
        return (
            <div className="animate-fade-in" style={{ textAlign: 'center' }}>
                <h1 className={styles.title} style={{ fontSize: '1.5rem', color: '#DC2626' }}>Link không hợp lệ</h1>
                <p className={styles.subtitle} style={{ marginBottom: '32px' }}>
                    Link đặt lại mật khẩu của bạn bị thiếu hoặc đã hết hạn.
                </p>
                <Link href="/auth/forgot" className={styles.submitBtn} style={{ textDecoration: 'none' }}>
                    <span>Yêu cầu link mới</span>
                    <ArrowRight size={18} />
                </Link>
            </div>
        );
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (password.length < 6) {
            setError('Mật khẩu phải từ 6 ký tự trở lên.');
            return;
        }

        if (password !== confirm) {
            setError('Mật khẩu xác nhận không khớp.');
            return;
        }

        setLoading(true);

        try {
            const data = await AuthService.resetPassword(token, password);

            if (!data.success) {
                throw new Error(data.message || 'Link đã hết hạn hoặc không hợp lệ.');
            }

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
                <h1 className={styles.title} style={{ fontSize: '1.5rem', marginBottom: '16px' }}>Đặt Lại Thành Công</h1>
                <p className={styles.subtitle} style={{ marginBottom: '32px' }}>
                    Mật khẩu của bạn đã được cập nhật an toàn trên hệ thống.
                </p>
                <Link href="/auth/login" className={styles.submitBtn} style={{ textDecoration: 'none' }}>
                    <span>Đăng nhập ngay</span>
                    <ArrowRight size={18} />
                </Link>
            </div>
        );
    }

    return (
        <div className="animate-fade-in">
            <h1 className={styles.title}>Đặt lại mật khẩu</h1>
            <p className={styles.subtitle}>Thiết lập mật khẩu an toàn mới cho tài khoản của bạn.</p>

            <form className={styles.form} onSubmit={handleSubmit}>
                {error && <div className={styles.errorAlert}>{error}</div>}

                <div className={styles.inputGroup}>
                    <label>Mật khẩu mới</label>
                    <div className={styles.inputWrapper}>
                        <Lock size={18} className={styles.inputIcon} />
                        <input
                            type="password"
                            placeholder="••••••••"
                            required
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            disabled={loading}
                        />
                    </div>
                </div>

                <div className={styles.inputGroup}>
                    <label>Xác nhận mật khẩu</label>
                    <div className={styles.inputWrapper}>
                        <Lock size={18} className={styles.inputIcon} />
                        <input
                            type="password"
                            placeholder="••••••••"
                            required
                            value={confirm}
                            onChange={(e) => setConfirm(e.target.value)}
                            disabled={loading}
                        />
                    </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px', padding: '12px', background: '#F0FDFA', borderRadius: '8px', marginTop: '4px' }}>
                    <ShieldCheck size={16} color="#0F766E" style={{ marginTop: '2px', flexShrink: 0 }} />
                    <span style={{ fontSize: '0.85rem', color: '#0F766E' }}>
                        Mật khẩu nên chứa ít nhất 8 ký tự, kết hợp chữ số và ký tự đặc biệt.
                    </span>
                </div>

                <button type="submit" className={styles.submitBtn} disabled={loading}>
                    {loading ? (
                        <Loader2 className="animate-spin" size={20} />
                    ) : (
                        <>
                            <span>Xác nhận Đặt lại</span>
                            <ArrowRight size={18} />
                        </>
                    )}
                </button>
            </form>

            <div className={styles.footer} align="center" style={{ justifyContent: 'center', marginTop: '24px' }}>
                <Link href="/auth/login" className={styles.linkBold} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <ArrowLeft size={16} /> Về trang đăng nhập
                </Link>
            </div>
        </div>
    );
}

export default function ResetPasswordPage() {
    return (
        <Suspense fallback={<div style={{ display: 'flex', justifyContent: 'center', padding: '2rem' }}><Loader2 className="animate-spin" size={24} color="#14B8A6" /></div>}>
            <ResetPasswordContent />
        </Suspense>
    );
}

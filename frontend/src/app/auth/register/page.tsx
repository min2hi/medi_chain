'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { User, Mail, Lock, ArrowRight, Loader2 } from 'lucide-react';
import styles from '../login/login.module.css'; // Reusing styles
import { AuthService } from '@/services/auth.client';

export default function RegisterPage() {
    const router = useRouter();
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        password: '',
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const data = await AuthService.register(formData);

            if (!data.success) {
                throw new Error(data.message || 'Có lỗi xảy ra');
            }

            // Success
            router.push('/auth/login?registered=true');
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Đã có lỗi xảy ra');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="animate-fade-in">
            <h1 className={styles.title}>Tạo tài khoản</h1>
            <p className={styles.subtitle}>Bắt đầu hành trình chăm sóc sức khỏe cho cả gia đình.</p>

            <form className={styles.form} onSubmit={handleSubmit}>
                {error && <div className={styles.errorAlert}>{error}</div>}

                <div className={styles.inputGroup}>
                    <label>Họ và tên</label>
                    <div className={styles.inputWrapper}>
                        <User size={18} className={styles.inputIcon} />
                        <input
                            type="text"
                            placeholder="Nguyễn Văn A"
                            required
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        />
                    </div>
                </div>

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
                    <label>Mật khẩu</label>
                    <div className={styles.inputWrapper}>
                        <Lock size={18} className={styles.inputIcon} />
                        <input
                            type="password"
                            placeholder="Tối thiểu 8 ký tự"
                            required
                            minLength={8}
                            value={formData.password}
                            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                        />
                    </div>
                </div>

                <button type="submit" className={styles.submitBtn} disabled={loading}>
                    {loading ? (
                        <Loader2 className="animate-spin" size={20} />
                    ) : (
                        <>
                            <span>Đăng ký tham gia</span>
                            <ArrowRight size={18} />
                        </>
                    )}
                </button>
            </form>

            <div className={styles.footer}>
                <span>Đã có tài khoản?</span>
                <Link href="/auth/login" className={styles.linkBold}>Đăng nhập</Link>
            </div>
        </div>
    );
}

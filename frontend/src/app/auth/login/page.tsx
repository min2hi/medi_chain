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
    const [progress, setProgress] = useState(0);
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

        // Smart UX: Tâm lý học "Ông Lớn" (Progress Bar + State Updates)
        let simulatedProgress = 5;
        setProgress(simulatedProgress);
        
        const progressInterval = setInterval(() => {
            simulatedProgress += Math.random() * 8; // Tăng ngẫu nhiên từ 0-8%
            if (simulatedProgress > 95) simulatedProgress = 95; // Kẹt ở 95% nếu backend quá lâu
            setProgress(simulatedProgress);
        }, 1200);

        const msgTimer1 = setTimeout(() => setLoadingMessage('Đang khởi động hệ thống an toàn...'), 3000);
        const msgTimer2 = setTimeout(() => setLoadingMessage('Khởi tạo kết nối mã hóa (256-bit)...'), 6500);
        const msgTimer3 = setTimeout(() => setLoadingMessage('Đang đồng bộ Sổ Y Bạ, vui lòng đợi...'), 12000);
        const msgTimer4 = setTimeout(() => setLoadingMessage('Máy chủ đang thức dậy từ chế độ ngủ...'), 20000);

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
            clearInterval(progressInterval);
            setProgress(0);
            clearTimeout(msgTimer1);
            clearTimeout(msgTimer2);
            clearTimeout(msgTimer3);
            clearTimeout(msgTimer4);
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
                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '100%', gap: '8px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <Loader2 className="animate-spin" size={18} />
                                <span style={{ fontSize: '14px', fontWeight: '500' }}>
                                    {loadingMessage || 'Đang xử lý...'}
                                </span>
                            </div>
                            
                            {/* Fake Progress Bar */}
                            <div style={{ width: '80%', height: '4px', backgroundColor: 'rgba(255,255,255,0.2)', borderRadius: '4px', overflow: 'hidden' }}>
                                <div 
                                    style={{ 
                                        height: '100%', 
                                        backgroundColor: '#fff', 
                                        width: \`\${progress}%\`,
                                        transition: 'width 0.4s ease-out'
                                    }} 
                                />
                            </div>
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

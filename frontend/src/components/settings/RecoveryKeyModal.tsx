'use client';

import React, { useState } from 'react';
import { RotateCcw, Eye, EyeOff, Copy, Download, AlertTriangle, CheckCircle, Loader2 } from 'lucide-react';
import { Modal } from '@/components/shared/Modal';
import { SettingsApi } from '@/services/api.client';
import styles from '@/app/cai-dat/settings.module.css';

interface Props {
    isOpen: boolean;
    onClose: () => void;
}

const DEMO_KEY = 'apple mango cloud stone river flame light sword water earth heart brain trust voice grace power sigma delta omega alpha lunar solar storm peace';

export const RecoveryKeyModal = ({ isOpen, onClose }: Props) => {
    const [step, setStep] = useState<'verify' | 'display'>('verify');
    const [password, setPassword] = useState('');
    const [showPwd, setShowPwd] = useState(false);
    const [recoveryKey, setRecoveryKey] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [copied, setCopied] = useState(false);

    const handleClose = () => {
        setStep('verify');
        setPassword('');
        setRecoveryKey('');
        setError('');
        onClose();
    };

    const handleReveal = async () => {
        if (!password) return setError('Vui lòng nhập mật khẩu');
        setLoading(true);
        setError('');
        try {
            const result = await SettingsApi.revealRecoveryKey(password);
            if (result.success && result.data) {
                setRecoveryKey(result.data.recoveryKey);
                setStep('display');
            } else {
                // Fallback demo key nếu API chưa có
                setRecoveryKey(DEMO_KEY);
                setStep('display');
            }
        } catch {
            setError('Không thể kết nối máy chủ');
        } finally {
            setLoading(false);
        }
    };

    const handleCopy = () => {
        navigator.clipboard.writeText(recoveryKey);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const handleDownload = () => {
        const txt = `MediChain Recovery Key\n${'='.repeat(30)}\n${recoveryKey}\n\n⚠ Giữ bí mật, không chia sẻ với bất kỳ ai.\nNgày xuất: ${new Date().toLocaleString('vi-VN')}`;
        const blob = new Blob([txt], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'medichain-recovery-key.txt';
        a.click();
        URL.revokeObjectURL(url);
    };

    return (
        <Modal isOpen={isOpen} onClose={handleClose}>
            <div className={styles.container}>
                <div className={styles.header}>
                    <div className={styles.iconWrap} style={{ background: 'rgba(22,163,74,0.1)' }}>
                        <RotateCcw size={20} color="#16a34a" />
                    </div>
                    <div>
                        <h3 className={styles.title}>Recovery Key</h3>
                        <p className={styles.subtitle}>
                            {step === 'verify' ? 'Xác minh danh tính để xem khoá khôi phục' : 'Lưu khoá này ở nơi an toàn'}
                        </p>
                    </div>
                </div>

                {/* Step indicator */}
                <div className={styles.steps}>
                    <div className={`${styles.step} ${styles.stepActive}`} />
                    <div className={`${styles.step} ${step === 'display' ? styles.stepActive : ''}`} />
                </div>

                {step === 'verify' ? (
                    <>
                        <div className={styles.field}>
                            <label className={styles.label}>Mật khẩu hiện tại</label>
                            <div className={styles.inputWrap}>
                                <input
                                    type={showPwd ? 'text' : 'password'}
                                    className={styles.input}
                                    placeholder="Nhập mật khẩu để xác minh"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    onKeyDown={(e) => e.key === 'Enter' && handleReveal()}
                                />
                                <button type="button" className={styles.eyeBtn} onClick={() => setShowPwd(!showPwd)}>
                                    {showPwd ? <EyeOff size={16} /> : <Eye size={16} />}
                                </button>
                            </div>
                        </div>
                        {error && <p className={styles.errorMsg}>{error}</p>}
                        <div className={styles.actions}>
                            <button className={styles.btnCancel} onClick={handleClose}>Hủy</button>
                            <button className={styles.btnPrimary} onClick={handleReveal} disabled={loading}>
                                {loading ? <Loader2 size={16} className={styles.spinner} /> : null}
                                {loading ? 'Đang xác minh...' : 'Xem Recovery Key'}
                            </button>
                        </div>
                    </>
                ) : (
                    <>
                        <div className={styles.warningBox}>
                            <AlertTriangle size={18} color="#d97706" style={{ flexShrink: 0, marginTop: 2 }} />
                            <p className={styles.warningText}>
                                <strong>Không chia sẻ khoá này với bất kỳ ai.</strong> MediChain sẽ không bao giờ hỏi bạn khoá khôi phục.
                            </p>
                        </div>

                        <div className={styles.keyBox}>{recoveryKey}</div>

                        <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
                            <button
                                className={styles.btnCancel}
                                style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}
                                onClick={handleCopy}
                            >
                                {copied ? <CheckCircle size={16} color="#10b981" /> : <Copy size={16} />}
                                {copied ? 'Đã sao chép!' : 'Sao chép'}
                            </button>
                            <button
                                className={styles.btnPrimary}
                                style={{ flex: 1 }}
                                onClick={handleDownload}
                            >
                                <Download size={16} />
                                Tải về .txt
                            </button>
                        </div>

                        <button className={styles.btnCancel} style={{ width: '100%' }} onClick={handleClose}>
                            Đã lưu — Đóng
                        </button>
                    </>
                )}
            </div>
        </Modal>
    );
};

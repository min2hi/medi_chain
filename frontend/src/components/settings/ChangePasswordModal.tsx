'use client';

import React, { useState } from 'react';
import { Eye, EyeOff, Loader2, CheckCircle, Lock } from 'lucide-react';
import { Modal } from '@/components/shared/Modal';
import { SettingsApi } from '@/services/api.client';
import styles from '@/app/cai-dat/settings.module.css';

interface Props {
    isOpen: boolean;
    onClose: () => void;
}

function getStrength(pwd: string): 'none' | 'weak' | 'medium' | 'strong' {
    if (!pwd) return 'none';
    const hasUpper = /[A-Z]/.test(pwd);
    const hasNum = /\d/.test(pwd);
    const hasSpecial = /[^A-Za-z0-9]/.test(pwd);
    const len = pwd.length;
    if (len < 8) return 'weak';
    if (len >= 12 && hasUpper && hasNum && hasSpecial) return 'strong';
    if (len >= 8 && (hasNum || hasSpecial)) return 'medium';
    return 'weak';
}

export const ChangePasswordModal = ({ isOpen, onClose }: Props) => {
    const [form, setForm] = useState({ current: '', newPwd: '', confirm: '' });
    const [show, setShow] = useState({ current: false, newPwd: false, confirm: false });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const strength = getStrength(form.newPwd);

    const handleClose = () => {
        setForm({ current: '', newPwd: '', confirm: '' });
        setError('');
        setSuccess(false);
        onClose();
    };

    const handleSubmit = async () => {
        setError('');
        if (!form.current || !form.newPwd || !form.confirm) {
            return setError('Vui lòng nhập đầy đủ thông tin');
        }
        if (form.newPwd.length < 8) {
            return setError('Mật khẩu mới phải từ 8 ký tự trở lên');
        }
        if (form.newPwd !== form.confirm) {
            return setError('Xác nhận mật khẩu không khớp');
        }
        setLoading(true);
        try {
            const result = await SettingsApi.changePassword(form.current, form.newPwd);
            if (!result.success) throw new Error(result.message);
            setSuccess(true);
            setTimeout(handleClose, 2000);
        } catch (err: any) {
            setError(err.message || 'Đã xảy ra lỗi');
        } finally {
            setLoading(false);
        }
    };

    const field = (
        key: 'current' | 'newPwd' | 'confirm',
        label: string,
        placeholder: string
    ) => (
        <div className={styles.field}>
            <label className={styles.label}>{label}</label>
            <div className={styles.inputWrap}>
                <input
                    type={show[key] ? 'text' : 'password'}
                    className={`${styles.input} ${error && !form[key] ? styles.inputError : ''}`}
                    placeholder={placeholder}
                    value={form[key]}
                    onChange={(e) => setForm((p) => ({ ...p, [key]: e.target.value }))}
                    onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
                />
                <button
                    type="button"
                    className={styles.eyeBtn}
                    onClick={() => setShow((p) => ({ ...p, [key]: !p[key] }))}
                >
                    {show[key] ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
            </div>
        </div>
    );

    return (
        <Modal isOpen={isOpen} onClose={handleClose}>
            <div className={styles.container}>
                {/* Header */}
                <div className={styles.header}>
                    <div className={styles.iconWrap}>
                        <Lock size={20} />
                    </div>
                    <div>
                        <h3 className={styles.title}>Đổi mật khẩu</h3>
                        <p className={styles.subtitle}>Tối thiểu 8 ký tự, nên dùng ký tự đặc biệt</p>
                    </div>
                </div>

                {success && (
                    <div className={styles.successMsg}>
                        <CheckCircle size={18} />
                        Đổi mật khẩu thành công! Cửa sổ sẽ tự đóng...
                    </div>
                )}

                {!success && (
                    <>
                        {field('current', 'Mật khẩu hiện tại', '••••••••')}
                        {field('newPwd', 'Mật khẩu mới', 'Tối thiểu 8 ký tự')}

                        {/* Password strength bar */}
                        {form.newPwd && (
                            <>
                                <div className={`${styles.strengthBar} ${styles['strength' + (strength.charAt(0).toUpperCase() + strength.slice(1))]}`}>
                                    {[1, 2, 3].map((i) => (
                                        <div key={i} className={styles.strengthSegment} />
                                    ))}
                                </div>
                                <p className={`${styles.strengthLabel} ${styles[strength]}`}>
                                    {strength === 'weak' && '⚠ Yếu — thêm số và ký tự đặc biệt'}
                                    {strength === 'medium' && '● Trung bình'}
                                    {strength === 'strong' && '✓ Mạnh'}
                                </p>
                            </>
                        )}

                        {field('confirm', 'Xác nhận mật khẩu mới', '••••••••')}

                        {error && <p className={styles.errorMsg}>{error}</p>}

                        <div className={styles.actions}>
                            <button className={styles.btnCancel} onClick={handleClose}>Hủy</button>
                            <button
                                className={styles.btnPrimary}
                                onClick={handleSubmit}
                                disabled={loading}
                            >
                                {loading ? <Loader2 size={16} className={styles.spinner} /> : null}
                                {loading ? 'Đang lưu...' : 'Đổi mật khẩu'}
                            </button>
                        </div>
                    </>
                )}
            </div>
        </Modal>
    );
};

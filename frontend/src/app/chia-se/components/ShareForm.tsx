'use client';

import React, { useState } from 'react';
import { X, Loader2 } from 'lucide-react';
import { SharingPermission, NewShareInput } from '../sharing.types';
import styles from './ShareForm.module.css';

interface ShareFormProps {
    onSubmit: (data: NewShareInput) => void;
    onCancel: () => void;
    isLoading?: boolean;
}

export const ShareForm: React.FC<ShareFormProps> = ({ onSubmit, onCancel, isLoading }) => {
    const [email, setEmail] = useState('');
    const [type, setType] = useState<SharingPermission>(SharingPermission.VIEW);
    const [expiresAt, setExpiresAt] = useState('');

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (!email.trim()) return;

        onSubmit({
            email: email.trim(),
            type,
            expiresAt: expiresAt || undefined
        });
    };

    return (
        <div className={styles.modal}>
            <div className={styles.modalHead}>
                <h3>Chia sẻ hồ sơ mới</h3>
                <button type="button" className={styles.closeBtn} onClick={onCancel} disabled={isLoading}>
                    <X size={22} />
                </button>
            </div>

            {/* Senior/Designer approach: Form wrap everything for consistent submission */}
            <form id="share-form" className={styles.formContentWrap} onSubmit={handleSubmit}>
                <div className={styles.formBody}>
                    <div className={styles.formGrid}>
                        <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                            <label className={styles.labelBlock}>
                                Email người nhận <span className={styles.required}>*</span>
                            </label>
                            <input
                                type="email"
                                className={styles.input}
                                placeholder="Nhập email bác sĩ hoặc người thân để chia sẻ hồ sơ của bạn..."
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                                disabled={isLoading}
                                autoFocus
                            />
                        </div>

                        <div className={styles.fieldGroup}>
                            <label className={styles.labelBlock}>
                                Quyền hạn truy cập <span className={styles.required}>*</span>
                            </label>
                            <select
                                className={styles.select}
                                value={type}
                                onChange={(e) => setType(e.target.value as SharingPermission)}
                                disabled={isLoading}
                            >
                                <option value={SharingPermission.VIEW}>Chỉ xem (View only)</option>
                                <option value={SharingPermission.MANAGE}>Toàn quyền quản lý (Full Manage)</option>
                            </select>
                        </div>

                        <div className={styles.fieldGroup}>
                            <label className={styles.labelBlock}>
                                Ngày hết hạn quyền
                            </label>
                            <input
                                type="date"
                                className={styles.input}
                                value={expiresAt}
                                onChange={(e) => setExpiresAt(e.target.value)}
                                disabled={isLoading}
                                min={new Date().toISOString().split('T')[0]}
                            />
                        </div>
                    </div>
                </div>

                <div className={styles.formFooter}>
                    <button
                        type="button"
                        className={styles.btnSecondary}
                        onClick={onCancel}
                        disabled={isLoading}
                    >
                        Hủy bỏ
                    </button>
                    <button
                        type="submit"
                        className={styles.btnPrimary}
                        disabled={isLoading}
                    >
                        {isLoading ? (
                            <>
                                <Loader2 size={20} className={styles.spinner} style={{ marginRight: '8px' }} />
                                Đang xử lý...
                            </>
                        ) : 'Xác nhận chia sẻ ngay'}
                    </button>
                </div>
            </form>
        </div>
    );
};

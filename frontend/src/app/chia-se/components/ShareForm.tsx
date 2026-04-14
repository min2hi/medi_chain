'use client';

import React, { useState } from 'react';
import { X, Loader2 } from 'lucide-react';
import { SharingPermission, NewShareInput } from '../sharing.types';
import styles from './ShareForm.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

interface ShareFormProps {
    onSubmit: (data: NewShareInput) => void;
    onCancel: () => void;
    isLoading?: boolean;
}

export const ShareForm: React.FC<ShareFormProps> = ({ onSubmit, onCancel, isLoading }) => {
    const { t } = useTranslation();
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
                <h3>{t('sharing.form_title')}</h3>
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
                                {t('sharing.lbl_email')} <span className={styles.required}>*</span>
                            </label>
                            <input
                                type="email"
                                className={styles.input}
                                placeholder={t('sharing.ph_email')}
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                                disabled={isLoading}
                                autoFocus
                            />
                        </div>

                        <div className={styles.fieldGroup}>
                            <label className={styles.labelBlock}>
                                {t('sharing.lbl_permission')} <span className={styles.required}>*</span>
                            </label>
                            <select
                                className={styles.select}
                                value={type}
                                onChange={(e) => setType(e.target.value as SharingPermission)}
                                disabled={isLoading}
                            >
                                <option value={SharingPermission.VIEW}>{t('sharing.perm_view')}</option>
                                <option value={SharingPermission.MANAGE}>{t('sharing.perm_manage')}</option>
                            </select>
                        </div>

                        <div className={styles.fieldGroup}>
                            <label className={styles.labelBlock}>
                                {t('sharing.lbl_expiry')}
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
                        {t('sharing.btn_cancel')}
                    </button>
                    <button
                        type="submit"
                        className={styles.btnPrimary}
                        disabled={isLoading}
                    >
                        {isLoading ? (
                            <>
                                <Loader2 size={20} className={styles.spinner} style={{ marginRight: '8px' }} />
                                {t('sharing.btn_processing')}
                            </>
                        ) : t('sharing.btn_confirm')}
                    </button>
                </div>
            </form>
        </div>
    );
};

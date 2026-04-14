'use client';

import React, { useState } from 'react';
import { Globe, Check, Loader2 } from 'lucide-react';
import { Modal } from '@/components/shared/Modal';
import { SettingsApi } from '@/services/api.client';
import styles from '@/app/cai-dat/settings.module.css';

interface Props {
    isOpen: boolean;
    onClose: () => void;
    currentLocale?: string;
}

const LANGUAGES = [
    { code: 'vi', name: 'Tiếng Việt', flag: '🇻🇳', label: 'Vietnamese' },
    { code: 'en', name: 'English', flag: '🇬🇧', label: 'Tiếng Anh' },
];


export const LanguageModal = ({ isOpen, onClose, currentLocale = 'vi' }: Props) => {
    const [selected, setSelected] = useState(currentLocale);
    const [saving, setSaving] = useState(false);

    const handleSave = async () => {
        setSaving(true);
        try {
            await SettingsApi.updatePreferences({ locale: selected });
            localStorage.setItem('locale', selected);
            onClose();
            // Refresh để áp dụng locale (future: i18n library)
            window.location.reload();
        } finally {
            setSaving(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose}>
            <div className={styles.container}>
                <div className={styles.header}>
                    <div className={styles.iconWrap}>
                        <Globe size={20} />
                    </div>
                    <div>
                        <h3 className={styles.title}>Ngôn ngữ</h3>
                        <p className={styles.subtitle}>Chọn ngôn ngữ hiển thị của ứng dụng</p>
                    </div>
                </div>

                <div className={styles.langList}>
                    {LANGUAGES.map((lang) => (
                        <div
                            key={lang.code}
                            className={`${styles.langItem} ${selected === lang.code ? styles.active : ''}`}
                            onClick={() => setSelected(lang.code)}
                            role="button"
                            tabIndex={0}
                        >
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <span style={{ fontSize: '1.2rem' }}>{lang.flag}</span>
                                <div className={styles.langInfo}>
                                    <div className={styles.langName}>{lang.name}</div>
                                    <div className={styles.langMuted}>{lang.label}</div>
                                </div>
                            </div>
                            {selected === lang.code && (
                                <Check size={18} className={styles.checkIcon} />
                            )}
                        </div>
                    ))}
                </div>

                <div className={styles.actions}>
                    <button className={styles.btnCancel} onClick={onClose}>Hủy</button>
                    <button
                        className={styles.btnPrimary}
                        onClick={handleSave}
                        disabled={saving || selected === currentLocale}
                    >
                        {saving ? <Loader2 size={16} className={styles.spinner} /> : null}
                        {saving ? 'Đang lưu...' : 'Áp dụng'}
                    </button>
                </div>
            </div>
        </Modal>
    );
};

'use client';

import React from 'react';
import { Smartphone, QrCode, ExternalLink } from 'lucide-react';
import { Modal } from '@/components/shared/Modal';
import styles from '@/components/settings/settings.module.css';

interface Props {
    isOpen: boolean;
    onClose: () => void;
}

export const MobileAppModal = ({ isOpen, onClose }: Props) => {
    return (
        <Modal isOpen={isOpen} onClose={onClose}>
            <div className={styles.container}>
                <div className={styles.header}>
                    <div className={styles.iconWrap}>
                        <Smartphone size={20} />
                    </div>
                    <div>
                        <h3 className={styles.title}>Ứng dụng di động</h3>
                        <p className={styles.subtitle}>Mang MediChain theo bên mình mọi lúc mọi nơi</p>
                    </div>
                </div>

                <div className={styles.qrBox}>
                    <div className={styles.qrPlaceholder}>
                        <QrCode size={48} color="var(--primary)" />
                    </div>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', textAlign: 'center', margin: 0 }}>
                        Quét mã QR hoặc tải trực tiếp bên dưới
                    </p>
                </div>

                <div className={styles.downloadBtns}>
                    <a
                        href="https://play.google.com/store"
                        target="_blank"
                        rel="noopener noreferrer"
                        className={styles.downloadBtn}
                    >
                        Tải trên Google Play
                        <ExternalLink size={14} style={{ marginLeft: 'auto', opacity: 0.5 }} />
                    </a>
                    <a
                        href="https://apps.apple.com"
                        target="_blank"
                        rel="noopener noreferrer"
                        className={styles.downloadBtn}
                    >
                        Tải trên App Store
                        <ExternalLink size={14} style={{ marginLeft: 'auto', opacity: 0.5 }} />
                    </a>
                </div>

                <div style={{ marginTop: 12 }}>
                    <button className={styles.btnCancel} style={{ width: '100%' }} onClick={onClose}>
                        Đóng
                    </button>
                </div>
            </div>
        </Modal>
    );
};

'use client';

import React from 'react';
import { LifeBuoy, Mail, BookOpen, MessageCircle, ExternalLink } from 'lucide-react';
import { Modal } from '@/components/shared/Modal';
import styles from './settings.module.css';

interface Props {
    isOpen: boolean;
    onClose: () => void;
}

const FAQ = [
    {
        q: 'Dữ liệu của tôi có được bảo mật không?',
        a: 'Có. Toàn bộ dữ liệu được mã hóa end-to-end. MediChain không bao giờ chia sẻ thông tin của bạn với bên thứ ba.',
    },
    {
        q: 'Tôi có thể xuất dữ liệu sức khỏe của mình không?',
        a: 'Có. Tính năng xuất dữ liệu (PDF/Excel) đang được phát triển và sẽ ra mắt trong phiên bản tới.',
    },
    {
        q: 'MediChain AI có thể thay thế bác sĩ không?',
        a: 'Không. Medi AI chỉ hỗ trợ thông tin tham khảo. Luôn tham khảo ý kiến bác sĩ cho các quyết định y tế.',
    },
];

export const SupportModal = ({ isOpen, onClose }: Props) => {
    return (
        <Modal isOpen={isOpen} onClose={onClose}>
            <div className={styles.container} style={{ maxWidth: 520 }}>
                <div className={styles.header}>
                    <div className={styles.iconWrap} style={{ background: 'rgba(239,68,68,0.1)' }}>
                        <LifeBuoy size={20} color="#dc2626" />
                    </div>
                    <div>
                        <h3 className={styles.title}>Hỗ trợ & Hướng dẫn</h3>
                        <p className={styles.subtitle}>Giải đáp thắc mắc và liên hệ chúng tôi</p>
                    </div>
                </div>

                {/* FAQ */}
                <div style={{ marginBottom: '20px' }}>
                    {FAQ.map((item, i) => (
                        <details key={i} style={{ borderBottom: '1px solid var(--border)', paddingBottom: 12, marginBottom: 12 }}>
                            <summary style={{
                                cursor: 'pointer',
                                fontWeight: 600,
                                fontSize: '0.88rem',
                                color: 'var(--text-primary)',
                                listStyle: 'none',
                                display: 'flex',
                                justifyContent: 'space-between',
                                alignItems: 'center',
                            }}>
                                {item.q}
                                <span style={{ color: 'var(--text-muted)', fontSize: '1.1rem' }}>+</span>
                            </summary>
                            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', marginTop: 8, lineHeight: 1.6 }}>
                                {item.a}
                            </p>
                        </details>
                    ))}
                </div>

                {/* Contact options */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 16 }}>
                    <a href="mailto:support@medichain.vn" className={styles.downloadBtn}>
                        <Mail size={16} color="#3b82f6" />
                        Gửi email hỗ trợ
                        <ExternalLink size={13} style={{ marginLeft: 'auto', opacity: 0.4 }} />
                    </a>
                    <a href="https://docs.medichain.vn" target="_blank" rel="noopener noreferrer" className={styles.downloadBtn}>
                        <BookOpen size={16} color="#10b981" />
                        Tài liệu hướng dẫn
                        <ExternalLink size={13} style={{ marginLeft: 'auto', opacity: 0.4 }} />
                    </a>
                    <a href="https://discord.gg/medichain" target="_blank" rel="noopener noreferrer" className={styles.downloadBtn}>
                        <MessageCircle size={16} color="#7c3aed" />
                        Cộng đồng Discord
                        <ExternalLink size={13} style={{ marginLeft: 'auto', opacity: 0.4 }} />
                    </a>
                </div>

                <button className={styles.btnCancel} style={{ width: '100%' }} onClick={onClose}>
                    Đóng
                </button>
            </div>
        </Modal>
    );
};

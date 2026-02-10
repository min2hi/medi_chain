'use client';

import React from 'react';
import {
    Key,
    Fingerprint,
    RotateCcw,
    Bell,
    Moon,
    Globe,
    Info,
    LifeBuoy,
    LogOut,
    ChevronRight
} from 'lucide-react';
import styles from './settings.module.css';

export default function SettingsPage() {
    const sections = [
        {
            title: 'Tài khoản & Bảo mật',
            items: [
                { icon: Key, label: 'Đổi mật khẩu khóa dữ liệu' },
                { icon: Fingerprint, label: 'Biometric / Vân tay' },
                { icon: RotateCcw, label: 'Sao lưu Recovery Key' },
            ]
        },
        {
            title: 'Ứng dụng',
            items: [
                { icon: Bell, label: 'Thông báo nhắc nhở' },
                { icon: Moon, label: 'Giao diện tối' },
                { icon: Globe, label: 'Ngôn ngữ' },
            ]
        },
        {
            title: 'Về MediChain',
            items: [
                { icon: Info, label: 'Phiên bản 1.0.0' },
                { icon: LifeBuoy, label: 'Hỗ trợ & Hướng dẫn' },
            ]
        }
    ];

    return (
        <div>
            <header className={styles.header}>
                <h1 className={styles.title}>Cài đặt</h1>
            </header>

            <div className={styles.sections}>
                {sections.map((section, idx) => (
                    <div key={idx} className={styles.section}>
                        <h2 className={styles.sectionTitle}>{section.title}</h2>
                        <div className={styles.itemList}>
                            {section.items.map((item, itemIdx) => (
                                <div key={itemIdx} className={styles.item}>
                                    <div className={styles.itemLeft}>
                                        <item.icon size={20} className={styles.itemIcon} />
                                        <span>{item.label}</span>
                                    </div>
                                    <ChevronRight size={18} className={styles.chevron} />
                                </div>
                            ))}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

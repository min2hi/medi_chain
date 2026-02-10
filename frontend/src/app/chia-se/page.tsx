'use client';

import React from 'react';
import { Share2, Plus, ShieldCheck } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import styles from './share.module.css';

export default function SharePage() {
    return (
        <div>
            <header className={styles.header}>
                <h1 className={styles.title}>Chia sẻ quyền truy cập</h1>
                <button className={styles.fabDesktop}>
                    <Plus size={20} />
                    <span>Chia sẻ mới</span>
                </button>
            </header>

            <div className={styles.infoBox}>
                <ShieldCheck size={20} className={styles.infoIcon} />
                <p>Mọi quyền truy cập đều có thể thu hồi bất cứ lúc nào. Dữ liệu vẫn được giữ an toàn bởi khóa của bạn.</p>
            </div>

            <section className={styles.section}>
                <h2 className={styles.sectionTitle}>Đang chia sẻ với</h2>
                <EmptyState
                    icon={Share2}
                    title="Bạn chưa chia sẻ hồ sơ với ai"
                    description="Bắt đầu chia sẻ quyền truy cập cho bác sĩ hoặc người thân để cùng quản lý sức khỏe."
                />
            </section>

            {/* Floating Action Button for Mobile */}
            <button className={styles.fabMobile}>
                <Plus size={24} />
            </button>
        </div>
    );
}

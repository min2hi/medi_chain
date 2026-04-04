'use client';

import React, { useState, useEffect } from 'react';
import { Share2, Plus, ShieldCheck, Loader2, AlertCircle, Inbox, UserCheck } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { ShareForm } from './components/ShareForm';
import { ShareList } from './components/ShareList';
import { SharingRecord, NewShareInput } from './sharing.types';
import { motion, AnimatePresence } from 'framer-motion';
import styles from './share.module.css';
import { useRouter } from 'next/navigation';
import { Modal } from '@/components/shared/Modal';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

export default function SharePage() {
    const [activeTab, setActiveTab] = useState<'sent' | 'received'>('sent');
    const [sentSharings, setSentSharings] = useState<SharingRecord[]>([]);
    const [receivedSharings, setReceivedSharings] = useState<SharingRecord[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [showModal, setShowModal] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const router = useRouter();

    const fetchAllData = async () => {
        setIsLoading(true);
        const token = localStorage.getItem('token');
        try {
            const [sentRes, recvRes] = await Promise.all([
                fetch(`${API_BASE}/sharing/me`, { headers: { 'Authorization': `Bearer ${token}` } }),
                fetch(`${API_BASE}/sharing/shared-with-me`, { headers: { 'Authorization': `Bearer ${token}` } })
            ]);

            const sentResult = await sentRes.json();
            const recvResult = await recvRes.json();

            if (sentResult.success) setSentSharings(sentResult.data);
            if (recvResult.success) setReceivedSharings(recvResult.data);
        } catch (err) {
            setError("Không thể kết nối máy chủ.");
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchAllData();
    }, []);

    const handleCreateShare = async (data: NewShareInput) => {
        try {
            setIsSubmitting(true);
            setError(null);
            const token = localStorage.getItem('token');
            const res = await fetch(`${API_BASE}/sharing`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(data)
            });
            const result = await res.json();

            if (result.success) {
                setShowModal(false);
                fetchAllData();
            } else {
                setError(result.message || "Có lỗi xảy ra khi chia sẻ.");
            }
        } catch (err) {
            setError("Lỗi kết nối server.");
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleRevoke = async (id: string) => {
        if (!confirm("Bạn có chắc chắn muốn thu hồi quyền truy cập này không?")) return;

        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${API_BASE}/sharing/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const result = await res.json();
            if (result.success) {
                setSentSharings(prev => prev.filter(s => s.id !== id));
            } else {
                alert(result.message || "Không thể thu hồi.");
            }
        } catch (err) {
            alert("Lỗi kết nối server.");
        }
    };

    const handleViewSharedProfile = (targetUserId: string, name: string) => {
        localStorage.setItem('viewing_as_userId', targetUserId);
        localStorage.setItem('viewing_as_name', name);
        window.dispatchEvent(new Event('view-context-changed'));
        router.push('/');
    };

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className={styles.container}
        >
            <header className={styles.header}>
                <div>
                    <h1 className={styles.title}>Trung tâm Chia sẻ</h1>
                    <p className={styles.subtitle}>Quản lý quyền truy cập và xem hồ sơ sức khỏe được chia sẻ.</p>
                </div>
                <button
                    className={styles.fabDesktop}
                    onClick={() => setShowModal(true)}
                >
                    <Plus size={20} />
                    <span>Chia sẻ mới</span>
                </button>
            </header>

            <div className={styles.tabContainer}>
                <button
                    className={`${styles.tab} ${activeTab === 'sent' ? styles.tabActive : ''}`}
                    onClick={() => setActiveTab('sent')}
                >
                    <UserCheck size={18} />
                    Đang chia sẻ
                    <span className={styles.tabCount}>{sentSharings.length}</span>
                </button>
                <button
                    className={`${styles.tab} ${activeTab === 'received' ? styles.tabActive : ''}`}
                    onClick={() => setActiveTab('received')}
                >
                    <Inbox size={18} />
                    Được nhận
                    <span className={styles.tabCount}>{receivedSharings.length}</span>
                </button>
            </div>

            <div className={styles.infoBox}>
                <ShieldCheck size={20} className={styles.infoIcon} />
                <p>Mọi dữ liệu được mã hoá End-to-End. Bạn có toàn quyền thu hồi hoặc từ chối truy cập bất cứ lúc nào.</p>
            </div>

            {error && (
                <div className={styles.errorBanner}>
                    <AlertCircle size={20} />
                    <span>{error}</span>
                </div>
            )}

            <section className={styles.section}>
                {isLoading ? (
                    <div className={styles.loaderContainer}>
                        <Loader2 size={40} className={styles.spinner} />
                        <p>Đang tải dữ liệu...</p>
                    </div>
                ) : (
                    <motion.div
                        key={activeTab}
                        initial={{ opacity: 0, x: activeTab === 'sent' ? -10 : 10 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 0.2 }}
                    >
                        {activeTab === 'sent' ? (
                            sentSharings.length > 0 ? (
                                <ShareList items={sentSharings} onRevoke={handleRevoke} type="outbound" />
                            ) : (
                                <EmptyState
                                    icon={Share2}
                                    title="Chưa chia sẻ với ai"
                                    description="Bắt đầu chia sẻ hồ sơ cho bác sĩ hoặc người thân để cùng quản lý sức khỏe."
                                />
                            )
                        ) : (
                            receivedSharings.length > 0 ? (
                                <ShareList
                                    items={receivedSharings}
                                    onView={handleViewSharedProfile}
                                    type="inbound"
                                />
                            ) : (
                                <EmptyState
                                    icon={Inbox}
                                    title="Chưa có ai chia sẻ với bạn"
                                    description="Khi người khác chia sẻ hồ sơ cho bạn, thông tin sẽ xuất hiện tại đây."
                                />
                            )
                        )}
                    </motion.div>
                )}
            </section>

            <button
                className={styles.fabMobile}
                onClick={() => setShowModal(true)}
            >
                <Plus size={24} />
            </button>

            <Modal isOpen={showModal} onClose={() => setShowModal(false)}>
                <ShareForm
                    onSubmit={handleCreateShare}
                    onCancel={() => setShowModal(false)}
                    isLoading={isSubmitting}
                />
            </Modal>
        </motion.div>
    );
}

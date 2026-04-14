'use client';

import React, { useState, useEffect } from 'react';
import { Share2, Plus, ShieldCheck, Loader2, AlertCircle, Inbox, UserCheck } from 'lucide-react';
import { EmptyState } from '@/components/shared/EmptyState';
import { SharingSkeleton } from '@/components/shared/PageSkeleton';
import { ShareForm } from './components/ShareForm';
import { ShareList } from './components/ShareList';
import { SharingRecord, NewShareInput } from './sharing.types';
import { motion, AnimatePresence } from 'framer-motion';
import styles from './share.module.css';
import { useRouter } from 'next/navigation';
import { Modal } from '@/components/shared/Modal';
import { useTranslation } from '@/i18n/I18nProvider';

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
    const { t } = useTranslation();

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
            setError(t('sharing.err_server'));
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
                setError(result.message || t('sharing.err_share'));
            }
        } catch (err) {
            setError(t('sharing.err_server'));
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleRevoke = async (id: string) => {
        if (!confirm(t('sharing.confirm_revoke'))) return;

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
                alert(result.message || t('sharing.err_revoke'));
            }
        } catch (err) {
            alert(t('sharing.err_server'));
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
                    <h1 className={styles.title}>{t('sharing.title')}</h1>
                    <p className={styles.subtitle}>{t('sharing.subtitle')}</p>
                </div>
                <button
                    className={styles.fabDesktop}
                    onClick={() => setShowModal(true)}
                >
                    <Plus size={20} />
                    <span>{t('sharing.btn_new')}</span>
                </button>
            </header>

            <div className={styles.tabContainer}>
                <button
                    className={`${styles.tab} ${activeTab === 'sent' ? styles.tabActive : ''}`}
                    onClick={() => setActiveTab('sent')}
                >
                    <UserCheck size={18} />
                    {t('sharing.tab_sent')}
                    <span className={styles.tabCount}>{sentSharings.length}</span>
                </button>
                <button
                    className={`${styles.tab} ${activeTab === 'received' ? styles.tabActive : ''}`}
                    onClick={() => setActiveTab('received')}
                >
                    <Inbox size={18} />
                    {t('sharing.tab_received')}
                    <span className={styles.tabCount}>{receivedSharings.length}</span>
                </button>
            </div>

            <div className={styles.infoBox}>
                <ShieldCheck size={20} className={styles.infoIcon} />
                <p>{t('sharing.security_note')}</p>
            </div>

            {error && (
                <div className={styles.errorBanner}>
                    <AlertCircle size={20} />
                    <span>{error}</span>
                </div>
            )}

            <section className={styles.section}>
                {isLoading ? (
                    <SharingSkeleton />
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
                                    title={t('sharing.empty_sent_title')}
                                    description={t('sharing.empty_sent_desc')}
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
                                    title={t('sharing.empty_recv_title')}
                                    description={t('sharing.empty_recv_desc')}
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

'use client';

import React from 'react';
import { Trash2, Calendar, ExternalLink, User } from 'lucide-react';
import { SharingRecord } from '../sharing.types';
import styles from './ShareList.module.css';
import { useTranslation } from '@/i18n/I18nProvider';

interface ShareListProps {
    items: SharingRecord[];
    onRevoke?: (id: string) => void;
    onView?: (userId: string, name: string) => void;
    type: 'outbound' | 'inbound';
}

export const ShareList = ({ items, onRevoke, onView, type }: ShareListProps) => {
    const { t } = useTranslation();
    return (
        <div className={styles.container}>
            {items.map((item) => {
                const displayUser = type === 'outbound' ? item.toUser : item.fromUser;
                const initials = displayUser?.name ? displayUser.name.charAt(0).toUpperCase() : '?';

                return (
                    <div key={item.id} className={styles.card}>
                        <div className={styles.userInfo}>
                            <div className={styles.avatar}>
                                {displayUser?.image ? (
                                    <img src={displayUser.image} alt={displayUser.name || 'User'} className={styles.avatarImg} />
                                ) : (
                                    <div className={styles.avatarPlaceholder}>
                                        {initials}
                                    </div>
                                )}
                            </div>
                            <div className={styles.details}>
                                <span className={styles.name}>{displayUser?.name || t('sharing.sys_user')}</span>
                                <span className={styles.email}>{displayUser?.email || ''}</span>
                            </div>
                        </div>

                        <div className={styles.meta}>
                            <span className={`${styles.badge} ${item.type === 'MANAGE' ? styles.badgeManage : styles.badgeView}`}>
                                {item.type === 'MANAGE' ? t('sharing.badge_manage') : t('sharing.badge_view')}
                            </span>
                            {item.expiresAt && (
                                <div className={styles.expiry}>
                                    <Calendar size={14} />
                                    <span>{new Date(item.expiresAt).toLocaleDateString('vi-VN')}</span>
                                </div>
                            )}
                        </div>

                        {type === 'outbound' && onRevoke && (
                            <button
                                className={styles.revokeBtn}
                                onClick={() => onRevoke(item.id)}
                                title={t('sharing.btn_revoke')}
                            >
                                <Trash2 size={18} />
                            </button>
                        )}

                        {type === 'inbound' && onView && (
                            <button
                                className={styles.viewBtn}
                                onClick={() => onView(item.fromUserId, displayUser?.name || '')}
                                title={t('sharing.btn_view_profile')}
                            >
                                <ExternalLink size={16} />
                                <span>{t('sharing.btn_view_profile')}</span>
                            </button>
                        )}
                    </div>
                );
            })}
        </div>
    );
};

import React from 'react';
import { LucideIcon } from 'lucide-react';
import styles from './EmptyState.module.css';

interface EmptyStateProps {
    icon: LucideIcon;
    title: string;
    description?: string;
    action?: React.ReactNode;
    compact?: boolean;
}

export const EmptyState = ({ icon: Icon, title, description, action, compact }: EmptyStateProps) => {
    return (
        <div className={`${styles.emptyState} ${compact ? styles.compact : ''}`}>
            <div className={styles.iconWrapper}>
                <Icon size={40} className={styles.icon} />
            </div>
            <h3 className={styles.title}>{title}</h3>
            {description && <p className={styles.description}>{description}</p>}
            {action && <div className={styles.action}>{action}</div>}
        </div>
    );
};

'use client';

import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import styles from './MainLayout.module.css';
import { PageTransition } from '../shared/PageTransition';


export const MainLayout = ({ children }: { children: React.ReactNode }) => {
    const pathname = usePathname();
    const router = useRouter();
    const [isChecking, setIsChecking] = useState(true);
    const isAuthPage = pathname?.startsWith('/auth') || pathname?.startsWith('/reset-password');

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token && !isAuthPage) {
            router.push('/auth/login');
        } else {
            setIsChecking(false);
        }
    }, [pathname, isAuthPage, router]);

    if (isAuthPage) return <>{children}</>;
    if (isChecking) return null;

    return (
        <div className={styles.layout}>
            <main className={styles.main}>
                <div className={styles.container}>
                    <PageTransition>
                        {children}
                    </PageTransition>
                </div>
            </main>
        </div>
    );
};

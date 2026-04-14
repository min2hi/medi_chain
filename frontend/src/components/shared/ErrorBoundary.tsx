'use client';

import React, { Component, ErrorInfo, ReactNode } from 'react';
import styles from './ErrorBoundary.module.css';

interface Props {
    children: ReactNode;
    fallback?: ReactNode;
}

interface State {
    hasError: boolean;
    error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
    constructor(props: Props) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error: Error): State {
        return { hasError: true, error };
    }

    componentDidCatch(error: Error, info: ErrorInfo) {
        // Log tới monitoring service nếu cần (Sentry, etc.)
        console.error('[ErrorBoundary] Uncaught error:', error, info.componentStack);
    }

    handleReset = () => {
        this.setState({ hasError: false, error: null });
        window.location.href = '/';
    };

    render() {
        if (this.state.hasError) {
            if (this.props.fallback) return this.props.fallback;

            return (
                <div className={styles.container}>
                    <div className={styles.card}>
                        <div className={styles.icon}>⚠️</div>
                        <h1 className={styles.title}>Đã xảy ra lỗi</h1>
                        <p className={styles.message}>
                            Ứng dụng gặp sự cố không mong muốn. Chúng tôi đã ghi nhận lỗi này.
                        </p>
                        {process.env.NODE_ENV === 'development' && this.state.error && (
                            <details className={styles.details}>
                                <summary>Chi tiết lỗi (dev only)</summary>
                                <pre>{this.state.error.message}</pre>
                                <pre>{this.state.error.stack}</pre>
                            </details>
                        )}
                        <button className={styles.btn} onClick={this.handleReset}>
                            Quay về trang chủ
                        </button>
                    </div>
                </div>
            );
        }

        return this.props.children;
    }
}

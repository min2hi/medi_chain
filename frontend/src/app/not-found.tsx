import Link from 'next/link';
import type { Metadata } from 'next';

export const metadata: Metadata = {
    title: '404 — Không tìm thấy trang | MediChain',
};

export default function NotFound() {
    return (
        <div style={{
            minHeight: '80vh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '24px',
            textAlign: 'center',
            gap: '16px',
        }}>
            <div style={{
                fontSize: '5rem',
                fontWeight: 800,
                background: 'linear-gradient(135deg, #0d9488, #134e4a)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                lineHeight: 1,
                letterSpacing: '-0.04em',
            }}>
                404
            </div>

            <h1 style={{ fontSize: '1.4rem', fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>
                Trang không tồn tại
            </h1>

            <p style={{
                fontSize: '0.95rem',
                color: 'var(--text-secondary)',
                maxWidth: 380,
                lineHeight: 1.65,
                margin: 0,
            }}>
                Trang bạn đang tìm kiếm không tồn tại hoặc đã bị di chuyển.
                Hãy thử kiểm tra lại đường dẫn hoặc quay về trang chủ.
            </p>

            <Link
                href="/"
                style={{
                    marginTop: 8,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 8,
                    padding: '12px 28px',
                    borderRadius: 14,
                    background: 'var(--primary, #0d9488)',
                    color: 'white',
                    fontWeight: 700,
                    fontSize: '0.95rem',
                    textDecoration: 'none',
                    transition: 'all 0.2s',
                }}
            >
                ← Về trang chủ
            </Link>
        </div>
    );
}

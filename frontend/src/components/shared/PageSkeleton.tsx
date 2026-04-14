'use client';

import React from 'react';

// Keyframe CSS chỉ inject 1 lần toàn app
const PULSE_STYLE = `@keyframes sk-pulse { 0%,100%{opacity:.35} 50%{opacity:.75} }`;
const sk = (extra?: React.CSSProperties): React.CSSProperties => ({
    background: 'var(--border)',
    borderRadius: 8,
    animation: 'sk-pulse 1.5s ease-in-out infinite',
    ...extra,
});

// ─── Shared Header Skeleton ───────────────────────────────
function SkHeader({ btnCount = 1 }: { btnCount?: number }) {
    return (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 32 }}>
            <div style={sk({ width: 200, height: 28 })} />
            <div style={{ display: 'flex', gap: 12 }}>
                {Array.from({ length: btnCount }).map((_, i) => (
                    <div key={i} style={sk({ width: 130, height: 40, borderRadius: 12, animationDelay: `${i * 0.1}s` })} />
                ))}
            </div>
        </div>
    );
}

// ─── List Item Skeleton ───────────────────────────────────
function SkListItem({ index = 0, showAccent = true }: { index?: number; showAccent?: boolean }) {
    return (
        <div style={{
            display: 'flex', gap: 16, padding: '20px 24px',
            background: 'var(--surface)', border: '1px solid var(--border)',
            borderRadius: 20, marginBottom: 14, alignItems: 'center',
            opacity: Math.max(0.3, 1 - index * 0.2),
        }}>
            {showAccent && <div style={{ width: 4, height: 50, borderRadius: 4, background: 'var(--border)' }} />}
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
                <div style={sk({ width: `${38 - index * 5}%`, height: 18 })} />
                <div style={sk({ width: `${55 - index * 3}%`, height: 13, opacity: 0.7 })} />
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
                <div style={sk({ width: 32, height: 32, borderRadius: 8 })} />
                <div style={sk({ width: 32, height: 32, borderRadius: 8, opacity: 0.6 })} />
            </div>
        </div>
    );
}

// ─── Card Block Skeleton ──────────────────────────────────
function SkCard({ rows = 3, gridCols = 2 }: { rows?: number; cols?: number; gridCols?: number }) {
    return (
        <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 20, padding: 24, marginBottom: 24 }}>
            {/* Card title */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 20 }}>
                <div style={sk({ width: 160, height: 20 })} />
                <div style={sk({ width: 64, height: 20, borderRadius: 6 })} />
            </div>
            {/* Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: `repeat(${gridCols}, 1fr)`, gap: 16 }}>
                {Array.from({ length: rows * gridCols }).map((_, i) => (
                    <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                        <div style={sk({ width: '45%', height: 12, opacity: 0.5 })} />
                        <div style={sk({ width: '70%', height: 16 })} />
                    </div>
                ))}
            </div>
        </div>
    );
}

// ─── Chip Row Skeleton ────────────────────────────────────
function SkChipRow() {
    return (
        <div style={{ display: 'flex', gap: 10, marginBottom: 24, flexWrap: 'wrap' as const }}>
            {[90, 110, 80, 120, 95].map((w, i) => (
                <div key={i} style={sk({ width: w, height: 34, borderRadius: 20, animationDelay: `${i * 0.08}s` })} />
            ))}
        </div>
    );
}

// ════════════════════════════════════════════════════════════
// EXPORTED VARIANTS
// ════════════════════════════════════════════════════════════

/**
 * ListSkeleton — dùng cho Thuốc, Lịch hẹn
 * Header + list of items
 */
export function ListSkeleton({ itemCount = 3, btnCount = 1 }: { itemCount?: number; btnCount?: number }) {
    return (
        <div style={{ padding: '0 2px' }}>
            <style>{PULSE_STYLE}</style>
            <SkHeader btnCount={btnCount} />
            {Array.from({ length: itemCount }).map((_, i) => (
                <SkListItem key={i} index={i} />
            ))}
        </div>
    );
}

/**
 * ProfileSkeleton — dùng cho Hồ Sơ
 * Header → Profile card → Metrics chips → Records list
 */
export function ProfileSkeleton() {
    return (
        <div style={{ padding: '0 2px' }}>
            <style>{PULSE_STYLE}</style>
            <SkHeader btnCount={2} />
            {/* Thông tin cá nhân card */}
            <SkCard rows={3} gridCols={3} />
            {/* Chỉ số gần đây */}
            <div style={sk({ width: 140, height: 18, marginBottom: 14 })} />
            <SkChipRow />
            {/* Records list */}
            <div style={sk({ width: 180, height: 18, marginBottom: 14 })} />
            {[0, 1, 2].map(i => <SkListItem key={i} index={i} showAccent={false} />)}
        </div>
    );
}

/**
 * SharingSkeleton — dùng cho Chia Sẻ
 * Header → Tab pills → Cards grid
 */
export function SharingSkeleton() {
    return (
        <div style={{ padding: '0 2px' }}>
            <style>{PULSE_STYLE}</style>
            <SkHeader btnCount={1} />
            {/* Tab bar */}
            <div style={{ display: 'flex', gap: 10, marginBottom: 28 }}>
                {[100, 110, 130].map((w, i) => (
                    <div key={i} style={sk({ width: w, height: 36, borderRadius: 20 })} />
                ))}
            </div>
            {/* Cards */}
            {[0, 1].map(i => (
                <div key={i} style={{
                    background: 'var(--surface)', border: '1px solid var(--border)',
                    borderRadius: 20, padding: '20px 24px', marginBottom: 16,
                    opacity: 1 - i * 0.25,
                }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 14 }}>
                        <div style={sk({ width: '40%', height: 18 })} />
                        <div style={sk({ width: 70, height: 26, borderRadius: 12 })} />
                    </div>
                    <div style={sk({ width: '65%', height: 13, marginBottom: 10, opacity: 0.6 })} />
                    <div style={sk({ width: '45%', height: 13, opacity: 0.4 })} />
                </div>
            ))}
        </div>
    );
}

/**
 * PageSkeleton — unified entry point for loading.tsx files
 * Usage: <PageSkeleton type="list" /> or <PageSkeleton type="profile" />
 */
type SkeletonType = 'list' | 'profile' | 'sharing';

export function PageSkeleton({ type = 'list' }: { type?: SkeletonType }) {
    switch (type) {
        case 'profile': return <ProfileSkeleton />;
        case 'sharing': return <SharingSkeleton />;
        default: return <ListSkeleton />;
    }
}

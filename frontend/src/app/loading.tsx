'use client';

import React from 'react';
import { motion } from 'framer-motion';

/**
 * Global Loading Skeleton (Next.js Suspense Boundary)
 * File `loading.tsx` ở thư mục root app sẽ được Next.js tự động kích hoạt
 * khi người dùng đổi trang. Giao diện Skeleton sẽ hiện LẬP TỨC 
 * ngăn ngừa hiện tượng "dead clicks" (click xong app đứng yên chờ data).
 */
export default function GlobalLoading() {
    return (
        <div style={{
            padding: '32px 40px',
            width: '100%',
            height: '100%',
        }}>
            {/* Header Skeleton */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 40 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    <motion.div
                        animate={{ opacity: [0.4, 0.7, 0.4] }}
                        transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                        style={{ width: 200, height: 32, borderRadius: 8, background: 'var(--border)' }}
                    />
                    <motion.div
                        animate={{ opacity: [0.3, 0.6, 0.3] }}
                        transition={{ duration: 1.5, repeat: Infinity, delay: 0.2, ease: "easeInOut" }}
                        style={{ width: 350, height: 16, borderRadius: 6, background: 'var(--border)' }}
                    />
                </div>
                
                {/* Button Skeleton */}
                <motion.div
                    animate={{ opacity: [0.4, 0.7, 0.4] }}
                    transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                    style={{ width: 140, height: 42, borderRadius: 12, background: 'var(--border)' }}
                />
            </div>

            {/* List Skeleton */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {[1, 2, 3].map((item) => (
                    <motion.div
                        key={item}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: item * 0.1 }}
                        style={{
                            padding: '24px',
                            background: 'var(--surface)',
                            border: '1px solid var(--border)',
                            borderRadius: '24px',
                            display: 'flex',
                            gap: 20,
                            alignItems: 'center',
                            boxShadow: '0 4px 20px -10px rgba(0,0,0,0.03)'
                        }}
                    >
                        {/* Icon/Avatar Skeleton */}
                        <motion.div
                            animate={{ opacity: [0.3, 0.6, 0.3] }}
                            transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                            style={{ 
                                width: 56, height: 56, borderRadius: '16px', 
                                background: 'linear-gradient(135deg, var(--border), rgba(20,184,166,0.1))' 
                            }}
                        />
                        
                        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
                            <motion.div
                                animate={{ opacity: [0.4, 0.7, 0.4] }}
                                transition={{ duration: 1.5, repeat: Infinity, delay: 0.1, ease: "easeInOut" }}
                                style={{ width: '40%', height: 20, borderRadius: 6, background: 'var(--border)' }}
                            />
                            <motion.div
                                animate={{ opacity: [0.3, 0.6, 0.3] }}
                                transition={{ duration: 1.5, repeat: Infinity, delay: 0.2, ease: "easeInOut" }}
                                style={{ width: '60%', height: 14, borderRadius: 4, background: 'var(--border)' }}
                            />
                        </div>
                    </motion.div>
                ))}
            </div>
        </div>
    );
}

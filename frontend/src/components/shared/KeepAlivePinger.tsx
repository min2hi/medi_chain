'use client';

import { useEffect } from 'react';

const BACKEND_URL = process.env.NEXT_PUBLIC_API_URL?.replace('/api', '') || '';
const PING_INTERVAL = 14 * 60 * 1000; // 14 phút (Render sleep sau 15 phút)

/**
 * Keep-Alive Pinger
 * 
 * Render Free Tier ngủ sau 15 phút không hoạt động → cold start 30-50s.
 * Component này ping backend mỗi 14 phút để giữ server luôn thức.
 * Render ở background, không ảnh hưởng gì đến UI.
 */
export function KeepAlivePinger() {
    useEffect(() => {
        const ping = () => {
            fetch(`${BACKEND_URL}/health`, { method: 'GET', cache: 'no-store' })
                .catch(() => {}); // Bỏ qua lỗi — chỉ ping thôi
        };

        // Ping lần đầu sau 30s (sau khi app load xong)
        const initialTimeout = setTimeout(ping, 30_000);
        
        // Ping định kỳ mỗi 14 phút
        const interval = setInterval(ping, PING_INTERVAL);

        return () => {
            clearTimeout(initialTimeout);
            clearInterval(interval);
        };
    }, []);

    return null; // Không render gì cả
}

import type { NextConfig } from "next";

const securityHeaders = [
  {
    key: 'X-DNS-Prefetch-Control',
    value: 'on',
  },
  {
    key: 'X-Frame-Options',
    value: 'SAMEORIGIN',
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff',
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin',
  },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), payment=()',
  },
  {
    // CSP — cho phép API backend + Vercel analytics
    // 'unsafe-inline' cần cho Next.js inline styles; nâng cấp lên nonce-based sau
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'", // unsafe-eval cần cho Next.js dev
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' https://fonts.gstatic.com",
      "img-src 'self' data: blob: https:",
      `connect-src 'self' ${process.env.NEXT_PUBLIC_API_URL || ''} https://medichain-backend-v4bo.onrender.com http://localhost:5000 https://api.groq.com`,
      "frame-ancestors 'none'",
    ].join('; '),
  },
];

const nextConfig: NextConfig = {
  // Tạo standalone bundle tối ưu cho Docker deployment
  // Output: .next/standalone — chứa mọi thứ để chạy, không cần node_modules đầy đủ
  // Giảm image size từ ~1GB xuống ~150MB
  output: 'standalone',

  // Security headers cho mọi route
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
    ];
  },
};

export default nextConfig;

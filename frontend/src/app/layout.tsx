import type { Metadata } from "next";
import "./globals.css";

// Khôn khéo xử lý để render backend host (bỏ đoạn /api đi)
const apiOrigin = process.env.NEXT_PUBLIC_API_URL 
  ? new URL(process.env.NEXT_PUBLIC_API_URL).origin 
  : 'https://medichain-backend-v4bo.onrender.com';

import { Navigation } from "@/components/layout/Navigation";
import { MainLayout } from "@/components/layout/MainLayout";
import { KeepAlivePinger } from "@/components/shared/KeepAlivePinger";
import { ErrorBoundary } from "@/components/shared/ErrorBoundary";

export const metadata: Metadata = {
  title: "MediChain - Sổ Y Bạ Gia Đình",
  description: "Hệ thống quản lý sức khỏe gia đình hiện đại — theo dõi thuốc, lịch hẹn, hồ sơ bệnh án",
  keywords: ["y tế", "sức khỏe", "lịch hẹn", "thuốc", "hồ sơ bệnh án"],
  icons: {
    icon: '/favicon.svg',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href={apiOrigin} crossOrigin="anonymous" />
        <link rel="dns-prefetch" href={apiOrigin} />
        <script
          dangerouslySetInnerHTML={{
            __html: `
              try {
                let theme = localStorage.getItem('theme');
                if (!theme) {
                  theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
                }
                document.documentElement.setAttribute('data-theme', theme);
              } catch (e) {}
            `,
          }}
        />
      </head>
      <body>
        <KeepAlivePinger />
        <Navigation />
        <MainLayout>
          <ErrorBoundary>
            {children}
          </ErrorBoundary>
        </MainLayout>
      </body>
    </html>
  );
}

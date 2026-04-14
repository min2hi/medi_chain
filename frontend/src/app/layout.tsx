import type { Metadata } from "next";
import "./globals.css";
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
    <html lang="vi">
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

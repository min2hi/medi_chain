import type { Metadata } from "next";
import "./globals.css";
import { Navigation } from "@/components/layout/Navigation";
import { MainLayout } from "@/components/layout/MainLayout";

export const metadata: Metadata = {
  title: "MediChain - Sổ Y Bạ Gia Đình",
  description: "Hệ thống quản lý sức khỏe gia đình hiện đại",
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
        <Navigation />
        <MainLayout>
          {children}
        </MainLayout>
      </body>
    </html>
  );
}

import type { Metadata } from "next";
import "./globals.css";
import { I18nProvider } from "@/i18n/I18nProvider";

// Preconnect to backend for faster API requests
const apiOrigin = process.env.NEXT_PUBLIC_API_URL
  ? new URL(process.env.NEXT_PUBLIC_API_URL).origin
  : 'https://medichain-backend-v4bo.onrender.com';

export const metadata: Metadata = {
  title: "MediChain",
  description: "Hệ thống quản lý sức khỏe gia đình hiện đại",
  icons: { icon: '/favicon.svg' },
};

// Root layout: Bare skeleton only.
// Navigation/Sidebar is injected per-portal:
//   - Patient pages → (patient)/layout.tsx
//   - Admin pages   → admin/layout.tsx
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="vi" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href={apiOrigin} crossOrigin="anonymous" />
        <link rel="dns-prefetch" href={apiOrigin} />
        <script
          dangerouslySetInnerHTML={{
            __html: `try{let t=localStorage.getItem('theme')||( window.matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light');document.documentElement.setAttribute('data-theme',t);}catch(e){}`,
          }}
        />
      </head>
      <body>
        <I18nProvider>
          {children}
        </I18nProvider>
      </body>
    </html>
  );
}

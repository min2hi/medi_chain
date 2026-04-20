'use client';

import React, { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
import {
  ShieldAlert, Layers, BookType, DatabaseZap,
  BarChart3, Settings2, LogOut, ChevronRight
} from 'lucide-react';

const NAV_ITEMS = [
  {
    group: 'Phê duyệt AI',
    items: [
      {
        label: 'Review Queue',
        sublabel: 'Từ khóa chờ phê duyệt',
        icon: Layers,
        href: '/admin/clinical-rules',
      },
    ],
  },
  {
    group: 'Tri thức lâm sàng',
    items: [
      {
        label: 'Safety Keywords',
        sublabel: 'Từ điển khẩn cấp',
        icon: BookType,
        href: '/admin/clinical-rules/keywords',
      },
      {
        label: 'Combo Rules',
        sublabel: 'Luật tổ hợp triệu chứng',
        icon: DatabaseZap,
        href: '/admin/clinical-rules/combos',
      },
    ],
  },
  {
    group: 'Hệ thống',
    items: [
      {
        label: 'Telemetry',
        sublabel: 'Logs & Hiệu suất',
        icon: BarChart3,
        href: '/admin/telemetry',
      },
      {
        label: 'Cấu hình',
        sublabel: 'Ngưỡng an toàn & Rate limit',
        icon: Settings2,
        href: '/admin/config',
      },
    ],
  },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [isAuthorized, setIsAuthorized] = useState<boolean | null>(null);
  const [user, setUser] = useState<{ name?: string; email?: string; role?: string } | null>(null);

  useEffect(() => {
    const u = AuthService.getCurrentUser();
    if (!u) {
      router.replace('/auth/login?redirect=' + pathname);
      return;
    }
    if (u.role !== 'ADMIN' && u.role !== 'DOCTOR') {
      setIsAuthorized(false);
    } else {
      setIsAuthorized(true);
      setUser(u);
    }
  }, [router, pathname]);

  if (isAuthorized === null) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <span className="text-slate-500 text-sm">Đang xác thực...</span>
      </div>
    );
  }

  if (isAuthorized === false) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
        <div className="bg-slate-900 border border-slate-800 p-8 rounded-xl text-center max-w-sm w-full">
          <ShieldAlert className="w-10 h-10 text-red-500 mx-auto mb-4" />
          <h2 className="text-base font-semibold text-white mb-2">Truy cập bị từ chối</h2>
          <p className="text-slate-400 text-sm mb-6">
            Khu vực này chỉ dành cho Bác sĩ và Quản trị viên.
          </p>
          <button
            onClick={() => router.push('/')}
            className="px-5 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition"
          >
            Về trang chủ
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col">

      {/* Top Bar */}
      <header className="h-12 bg-slate-900 border-b border-slate-800 flex items-center justify-between px-5 sticky top-0 z-20 shrink-0">
        <div className="flex items-center gap-3">
          <span className="font-semibold text-white text-sm">MediChain</span>
          <span className="text-slate-700 text-xs">|</span>
          <span className="text-xs text-slate-400">Admin</span>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-xs text-slate-400">
            {user?.name} &middot; <span className="text-slate-600">{user?.role}</span>
          </div>
          <button
            onClick={() => router.push('/')}
            className="flex items-center gap-1.5 text-slate-500 hover:text-slate-300 transition text-xs"
            title="Về trang bệnh nhân"
          >
            <LogOut className="w-3.5 h-3.5" />
            Về Patient Portal
          </button>
        </div>
      </header>

      {/* Body */}
      <div className="flex flex-1 overflow-hidden">

        {/* Sidebar */}
        <nav className="w-56 bg-slate-900 border-r border-slate-800 flex flex-col overflow-y-auto shrink-0">
          <div className="flex-1 px-2 py-4 space-y-5">
            {NAV_ITEMS.map((section) => (
              <div key={section.group}>
                <p className="text-slate-600 text-[10px] font-semibold tracking-widest uppercase px-2 mb-1">
                  {section.group}
                </p>
                <div className="space-y-0.5">
                  {section.items.map((item) => {
                    const active = pathname === item.href || pathname.startsWith(item.href + '/');
                    const Icon = item.icon;
                    return (
                      <button
                        key={item.href}
                        onClick={() => router.push(item.href)}
                        className={`w-full flex items-center gap-2.5 rounded-md px-2 py-2 text-left transition-colors ${
                          active
                            ? 'bg-slate-800 text-white'
                            : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'
                        }`}
                      >
                        <Icon className={`w-4 h-4 shrink-0 ${active ? 'text-blue-400' : 'text-slate-600'}`} />
                        <div className="flex-1 min-w-0">
                          <div className="text-xs font-medium leading-none">{item.label}</div>
                          <div className="text-[10px] text-slate-600 mt-0.5 truncate">{item.sublabel}</div>
                        </div>
                        {active && <ChevronRight className="w-3 h-3 text-slate-500 shrink-0" />}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </nav>

        {/* Main Content */}
        <main className="flex-1 overflow-y-auto bg-slate-950">
          <div className="p-6">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}

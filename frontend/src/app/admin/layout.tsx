'use client';

import React, { createContext, useContext } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { AuthService } from '@/services/auth.client';
import {
  Layers, BookType, DatabaseZap,
  BarChart3, Settings2, ChevronRight,
  LayoutDashboard, Calendar, HeartPulse, CreditCard, Users, LogOut, ShieldAlert
} from 'lucide-react';

// ─── Admin Context — share user/role to child pages ───────────────────────────
interface AdminUser { name?: string; email?: string; role: string; }

const AdminContext = createContext<AdminUser | null>(null);
export const useAdminUser = () => useContext(AdminContext);

// ─── Nav definition — role restrictions removed for public development ─────────
const NAV_ITEMS = [
  {
    group: 'Tổng quan',
    items: [
      {
        label: 'Tổng quan',
        sublabel: 'Bảng điều khiển chính',
        icon: LayoutDashboard,
        href: '/admin',
      },
    ],
  },
  {
    group: 'Khám chữa bệnh',
    items: [
      {
        label: 'Lịch khám',
        sublabel: 'Quản lý lịch hẹn',
        icon: Calendar,
        href: '/admin/appointments',
      },
      {
        label: 'Bệnh nhân',
        sublabel: 'Danh sách bệnh nhân',
        icon: HeartPulse,
        href: '/admin/patients',
      },
    ],
  },
  {
    group: 'Phê duyệt AI',
    items: [
      {
        label: 'Hàng chờ duyệt',
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
        label: 'Từ khóa an toàn',
        sublabel: 'Từ điển khẩn cấp',
        icon: BookType,
        href: '/admin/clinical-rules/keywords',
      },
      {
        label: 'Quy tắc tổ hợp',
        sublabel: 'Luật tổ hợp triệu chứng',
        icon: DatabaseZap,
        href: '/admin/clinical-rules/combos',
      },
    ],
  },
  {
    group: 'Tài chính',
    items: [
      {
        label: 'Doanh thu',
        sublabel: 'Thống kê thanh toán',
        icon: CreditCard,
        href: '/admin/payments',
      },
    ],
  },
  {
    group: 'Hệ thống',
    items: [
      {
        label: 'Hoạt động hệ thống',
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
  {
    group: 'Quản trị',
    items: [
      {
        label: 'Người dùng',
        sublabel: 'Phân quyền tài khoản',
        icon: Users,
        href: '/admin/users',
      },
    ],
  },
];

// ─── Layout ────────────────────────────────────────────────────────────────────
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = React.useState<AdminUser | null>(null);
  const [status, setStatus] = React.useState<'loading' | 'unauthorized' | 'authorized'>('loading');

  React.useEffect(() => {
    const u = AuthService.getCurrentUser();
    if (!u) {
      router.replace('/auth/login?redirect=' + window.location.pathname);
      return;
    }

    if (u.role !== 'ADMIN') {
      setStatus('unauthorized');
      return;
    }

    setUser(u);
    setStatus('authorized');
  }, [router]);

  const handleLogout = () => {
    AuthService.logout();
    router.replace('/auth/login');
  };

  if (status === 'loading') {
    return (
      <div className="min-h-screen bg-[#070c14] flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-slate-700 border-t-emerald-400 rounded-full animate-spin" />
          <span className="text-slate-400 text-xs">Đang xác thực quyền Admin...</span>
        </div>
      </div>
    );
  }

  if (status === 'unauthorized') {
    return (
      <div className="min-h-screen bg-[#070c14] flex items-center justify-center p-4">
        <div className="bg-[#0d1520] border border-[#1e293b]/60 p-8 rounded-xl text-center max-w-sm w-full">
          <ShieldAlert className="w-10 h-10 text-red-500 mx-auto mb-4" />
          <h2 className="text-base font-semibold text-white mb-2">Truy cập bị từ chối</h2>
          <p className="text-slate-400 text-sm mb-6">
            Khu vực này chỉ dành riêng cho Quản trị viên hệ thống.
          </p>
          <button
            onClick={() => router.push('/')}
            className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-sm rounded-lg transition"
          >
            Về trang chủ
          </button>
        </div>
      </div>
    );
  }

  return (
    <AdminContext.Provider value={user}>
      <div className="min-h-screen bg-[#070c14] flex flex-col font-sans antialiased text-slate-200">

        {/* ── Top Bar ── */}
        <header className="h-14 bg-[#0d1520]/80 backdrop-blur-md border-b border-[#1e293b]/60 flex items-center justify-between px-6 sticky top-0 z-20 shrink-0">
          <div className="flex items-center gap-3">
            <span className="font-extrabold text-white text-sm tracking-tight">MediChain</span>
            <span className="text-slate-800 text-xs">|</span>
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-[#8a9bb5] tracking-wide">Admin Console</span>
              <div className="w-2 h-2 rounded-full bg-emerald-500 shadow-[0_0_8px_#10b981] animate-pulse" />
            </div>
          </div>
          <div className="flex items-center gap-4">
            {user && (
              <span className="text-xs text-[#8a9bb5] font-semibold hidden sm:inline-block">
                {user.name || user.email}
              </span>
            )}
            <button
              onClick={handleLogout}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-red-950/20 hover:bg-red-950/30 border border-red-900/25 hover:border-red-900/40 text-red-400 text-xs font-bold rounded-xl transition duration-150 cursor-pointer animate-fade-in"
            >
              <LogOut className="w-3.5 h-3.5 shrink-0" />
              Đăng xuất
            </button>
          </div>
        </header>

        {/* ── Body ── */}
        <div className="flex flex-1 overflow-hidden">

          {/* ── Sidebar ── */}
          <nav className="w-64 bg-[#0d1520] border-r border-[#1e293b]/50 flex flex-col shrink-0 select-none">
            <div className="flex-1 px-3 py-6 space-y-6 overflow-y-auto">
              {NAV_ITEMS.map((section) => (
                <div key={section.group} className="space-y-2">
                  <p className="text-[#3c4a61] text-[9px] font-bold tracking-widest font-mono uppercase px-3">
                    {section.group}
                  </p>
                  <div className="space-y-1">
                    {section.items.map((item) => {
                      const Icon   = item.icon;
                      const allHrefs = NAV_ITEMS.flatMap(s => s.items.map(i => i.href));
                      const hasMoreSpecific = allHrefs.some(
                        h => h !== item.href &&
                             h.startsWith(item.href + '/') &&
                             (pathname === h || pathname.startsWith(h + '/'))
                      );
                      const active = !hasMoreSpecific &&
                        (pathname === item.href || pathname.startsWith(item.href + '/'));
                      return (
                        <Link
                          key={item.href}
                          href={item.href}
                          className="block"
                        >
                          <motion.div
                            whileHover={{ x: 2 }}
                            whileTap={{ scale: 0.98 }}
                            className={`w-full flex items-center gap-3 rounded-xl px-3 py-2 text-left transition-all duration-200 border ${
                              active
                                ? 'bg-emerald-500/10 border-emerald-500/25 text-emerald-400 shadow-[0_0_15px_-3px_rgba(16,185,129,0.12)]'
                                : 'text-slate-400 hover:bg-[#111926] hover:text-slate-200 border border-transparent'
                            }`}
                          >
                            <Icon className={`w-4 h-4 shrink-0 transition-colors ${active ? 'text-emerald-400' : 'text-slate-500'}`} />
                            <div className="flex-1 min-w-0">
                              <div className="text-xs font-semibold leading-tight">{item.label}</div>
                              <div className={`text-[9px] mt-0.5 truncate ${active ? 'text-emerald-500/60' : 'text-slate-500'}`}>{item.sublabel}</div>
                            </div>
                            {active && (
                              <ChevronRight className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                            )}
                          </motion.div>
                        </Link>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </nav>

          {/* ── Main Content ── */}
          <main className="flex-1 overflow-y-auto bg-[#070c14]">
            <div className="p-8">
              {children}
            </div>
          </main>
        </div>
      </div>
    </AdminContext.Provider>
  );
}

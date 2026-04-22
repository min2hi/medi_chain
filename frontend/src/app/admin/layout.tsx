'use client';

import React, { useEffect, useState, createContext, useContext } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
import { PageTransition } from '@/components/shared/PageTransition';
import { canAccess, AdminRole } from '@/config/admin-permissions';
import {
  ShieldAlert, Layers, BookType, DatabaseZap,
  BarChart3, Settings2, LogOut, ChevronRight, Lock,
} from 'lucide-react';

// ─── Admin Context — share user/role to child pages ───────────────────────────
interface AdminUser { name?: string; email?: string; role: string; }

const AdminContext = createContext<AdminUser | null>(null);
export const useAdminUser = () => useContext(AdminContext);

// ─── Nav definition — role restrictions declared inline ────────────────────────
const NAV_ITEMS = [
  {
    group: 'Phê duyệt AI',
    items: [
      {
        label: 'Review Queue',
        sublabel: 'Từ khóa chờ phê duyệt',
        icon: Layers,
        href: '/admin/clinical-rules',
        roles: ['ADMIN', 'DOCTOR'] as AdminRole[],
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
        roles: ['ADMIN', 'DOCTOR'] as AdminRole[],
      },
      {
        label: 'Combo Rules',
        sublabel: 'Luật tổ hợp triệu chứng',
        icon: DatabaseZap,
        href: '/admin/clinical-rules/combos',
        roles: ['ADMIN', 'DOCTOR'] as AdminRole[],
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
        roles: ['ADMIN'] as AdminRole[],
      },
      {
        label: 'Cấu hình',
        sublabel: 'Ngưỡng an toàn & Rate limit',
        icon: Settings2,
        href: '/admin/config',
        roles: ['ADMIN'] as AdminRole[],
      },
    ],
  },
];

// ─── Role badge ────────────────────────────────────────────────────────────────
const ROLE_BADGE: Record<string, string> = {
  ADMIN:  'bg-blue-500/15 text-blue-400 border border-blue-500/25',
  DOCTOR: 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/25',
};

// ─── Layout ────────────────────────────────────────────────────────────────────
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router   = useRouter();
  const pathname = usePathname();
  const [isAuthorized, setIsAuthorized] = useState<boolean | null>(null);
  const [user, setUser] = useState<AdminUser | null>(null);

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
      setUser({ name: u.name, email: u.email, role: u.role });
    }
  }, [router, pathname]);

  // ── Loading / Access Denied guards ──────────────────────────────────────────
  if (isAuthorized === null) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="flex items-center gap-2.5">
          <div className="w-4 h-4 border-2 border-slate-600 border-t-blue-400 rounded-full animate-spin" />
          <span className="text-slate-500 text-sm">Đang xác thực...</span>
        </div>
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

  const userRole = user?.role ?? '';

  return (
    <AdminContext.Provider value={user}>
      <div className="min-h-screen bg-slate-950 flex flex-col">

        {/* ── Top Bar ── */}
        <header className="h-12 bg-slate-900 border-b border-slate-800 flex items-center justify-between px-5 sticky top-0 z-20 shrink-0">
          <div className="flex items-center gap-3">
            <span className="font-semibold text-white text-sm">MediChain</span>
            <span className="text-slate-700 text-xs">|</span>
            <span className="text-xs text-slate-400">Admin Portal</span>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <span>{user?.name}</span>
              <span className={`px-1.5 py-0.5 rounded text-[10px] font-semibold ${ROLE_BADGE[userRole] ?? 'bg-slate-700 text-slate-400'}`}>
                {userRole}
              </span>
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

        {/* ── Body ── */}
        <div className="flex flex-1 overflow-hidden">

          {/* ── Sidebar ── */}
          <nav className="w-56 bg-slate-900 border-r border-slate-800 flex flex-col overflow-y-auto shrink-0">
            <div className="flex-1 px-2 py-4 space-y-5">
              {NAV_ITEMS.map((section) => {
                // Filter items this role cannot access
                const visibleItems = section.items.filter(item =>
                  (item.roles as string[]).includes(userRole)
                );
                // Hide entire section group if no visible items
                if (visibleItems.length === 0) return null;

                // Check if section has locked items (role can't access some in group)
                const lockedItems = section.items.filter(item =>
                  !(item.roles as string[]).includes(userRole)
                );

                return (
                  <div key={section.group}>
                    <p className="text-slate-600 text-[10px] font-semibold tracking-widest uppercase px-2 mb-1">
                      {section.group}
                    </p>
                    <div className="space-y-0.5">
                      {visibleItems.map((item) => {
                        const active = pathname === item.href || pathname.startsWith(item.href + '/');
                        const Icon   = item.icon;
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

                      {/* Locked items — greyed out with lock icon, visible but disabled */}
                      {lockedItems.map((item) => {
                        const Icon = item.icon;
                        return (
                          <div
                            key={item.href}
                            title={`Yêu cầu quyền ADMIN`}
                            className="w-full flex items-center gap-2.5 rounded-md px-2 py-2 opacity-35 cursor-not-allowed select-none"
                          >
                            <Icon className="w-4 h-4 shrink-0 text-slate-700" />
                            <div className="flex-1 min-w-0">
                              <div className="text-xs font-medium leading-none text-slate-600">{item.label}</div>
                              <div className="text-[10px] text-slate-700 mt-0.5 truncate">{item.sublabel}</div>
                            </div>
                            <Lock className="w-3 h-3 text-slate-700 shrink-0" />
                          </div>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Role indicator at bottom of sidebar */}
            <div className="px-3 py-3 border-t border-slate-800">
              <div className="text-[10px] text-slate-700 mb-1 uppercase tracking-wider">Quyền truy cập</div>
              <div className="text-xs text-slate-500">
                {userRole === 'ADMIN'
                  ? 'Toàn quyền hệ thống'
                  : 'Tri thức lâm sàng'}
              </div>
            </div>
          </nav>

          {/* ── Main Content ── */}
          <main className="flex-1 overflow-y-auto bg-slate-950">
            <div className="p-6">
              <PageTransition>
                {/* Page-level permission check — stays in admin context */}
                {canAccess(pathname, userRole)
                  ? children
                  : (
                    <div className="flex flex-col items-center justify-center min-h-[60vh]">
                      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-10 text-center max-w-sm w-full">
                        <div className="w-12 h-12 rounded-full bg-amber-500/10 border border-amber-500/20 flex items-center justify-center mx-auto mb-4">
                          <Lock className="w-6 h-6 text-amber-400" />
                        </div>
                        <h2 className="text-base font-semibold text-white mb-2">
                          Không đủ quyền truy cập
                        </h2>
                        <p className="text-slate-500 text-sm mb-6 leading-relaxed">
                          Trang này yêu cầu quyền{' '}
                          <span className="text-blue-400 font-medium border border-blue-500/25 bg-blue-500/10 px-1.5 py-0.5 rounded text-xs">ADMIN</span>.
                          Liên hệ quản trị viên để được cấp quyền.
                        </p>
                        <button
                          onClick={() => router.push('/admin/clinical-rules')}
                          className="px-5 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 hover:text-white text-sm rounded-lg transition w-full"
                        >
                          Về Review Queue
                        </button>
                      </div>
                    </div>
                  )
                }
              </PageTransition>
            </div>
          </main>
        </div>
      </div>
    </AdminContext.Provider>
  );
}

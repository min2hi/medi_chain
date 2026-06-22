'use client';

import React from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { DoctorAuthGuard } from '@/components/shared/DoctorAuthGuard';
import { AuthService } from '@/services/auth.client';
import {
  LayoutDashboard, Calendar, HeartPulse, Clock, Settings, LogOut, Home
} from 'lucide-react';

const DOCTOR_NAV_ITEMS = [
  {
    group: 'Tổng quan',
    items: [
      {
        label: 'Dashboard',
        sublabel: 'Trang chính bác sĩ',
        icon: LayoutDashboard,
        href: '/doctor',
      },
    ],
  },
  {
    group: 'Khám chữa bệnh',
    items: [
      {
        label: 'Lịch khám bệnh',
        sublabel: 'Hẹn khám hôm nay',
        icon: Calendar,
        href: '/doctor/appointments',
      },
      {
        label: 'Bệnh nhân',
        sublabel: 'Quản lý bệnh án',
        icon: HeartPulse,
        href: '/doctor/patients',
      },
    ],
  },
  {
    group: 'Lịch làm việc',
    items: [
      {
        label: 'Lịch rảnh',
        sublabel: 'Đăng ký ca trực',
        icon: Clock,
        href: '/doctor/slots',
      },
    ],
  },
  {
    group: 'Cài đặt',
    items: [
      {
        label: 'Chuyên môn',
        sublabel: 'Thông tin hành nghề',
        icon: Settings,
        href: '/doctor/cai-dat',
      },
    ],
  },
];

export default function DoctorLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [doctorName, setDoctorName] = React.useState('');

  React.useEffect(() => {
    const u = AuthService.getCurrentUser();
    if (u) {
      setDoctorName(u.name || 'Bác sĩ');
    }
  }, []);

  const handleLogout = () => {
    AuthService.logout();
    router.replace('/auth/login');
  };

  return (
    <DoctorAuthGuard>
      <div className="min-h-screen bg-slate-950 flex flex-col text-slate-200">
        
        {/* Top Header */}
        <header className="h-12 bg-slate-900 border-b border-slate-800 flex items-center justify-between px-5 sticky top-0 z-20 shrink-0">
          <div className="flex items-center gap-3">
            <span className="font-bold text-teal-400 text-sm tracking-wide">MediChain</span>
            <span className="text-slate-700 text-xs">|</span>
            <span className="text-xs text-slate-400 font-medium">Cổng Bác Sĩ</span>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-[11px] text-slate-400">
              <span className="font-semibold text-slate-300">{doctorName}</span>
              <span className="bg-teal-950/40 text-teal-400 border border-teal-900/50 font-mono text-[9px] font-medium tracking-wide px-2 py-0.5 rounded-md">
                DOCTOR
              </span>
            </div>
          </div>
        </header>

        {/* Body */}
        <div className="flex flex-1 overflow-hidden">
          
          {/* Sidebar */}
          <nav className="w-56 bg-slate-900 border-r border-slate-800 flex flex-col overflow-y-auto shrink-0">
            <div className="flex-1 px-2 py-4 space-y-5">
              {DOCTOR_NAV_ITEMS.map((section) => (
                <div key={section.group}>
                  <p className="text-slate-600 text-[10px] font-bold tracking-widest uppercase px-2 mb-1.5">
                    {section.group}
                  </p>
                  <div className="space-y-0.5">
                    {section.items.map((item) => {
                      const Icon = item.icon;
                      const active = pathname === item.href || (item.href !== '/doctor' && pathname?.startsWith(item.href + '/'));
                      return (
                        <Link
                          key={item.href}
                          href={item.href}
                          className={`w-full flex items-center gap-2.5 rounded-lg px-2.5 py-1.5 text-left transition-all duration-200 relative ${
                            active
                              ? 'bg-slate-950 border border-slate-800 text-white shadow-sm'
                              : 'text-slate-400 hover:bg-slate-900/50 hover:text-slate-200 border border-transparent'
                          }`}
                        >
                          {active && (
                            <span className="absolute left-0 top-1.5 bottom-1.5 w-0.5 rounded-r bg-teal-500" />
                          )}
                          <Icon className={`w-4 h-4 shrink-0 transition-colors ${active ? 'text-teal-400' : 'text-slate-500'}`} />
                          <div className="flex-1 min-w-0">
                            <div className="text-xs font-semibold leading-none">{item.label}</div>
                            <div className="text-[9px] text-slate-500 mt-1 truncate">{item.sublabel}</div>
                          </div>
                        </Link>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>

            {/* Bottom buttons */}
            <div className="px-3 py-3 border-t border-slate-800 space-y-2">
              <button
                onClick={() => router.push('/')}
                className="w-full flex items-center gap-2 px-2.5 py-1.5 bg-slate-800 hover:bg-slate-750 border border-slate-700 text-slate-350 text-xs font-medium rounded-lg transition"
              >
                <Home className="w-3.5 h-3.5 shrink-0" />
                Về Patient Portal
              </button>
              <button
                onClick={handleLogout}
                className="w-full flex items-center gap-2 px-2.5 py-1.5 bg-red-955/20 hover:bg-red-955/40 border border-red-900/30 hover:border-red-900/50 text-red-400 text-xs font-semibold rounded-lg transition"
              >
                <LogOut className="w-3.5 h-3.5 shrink-0" />
                Đăng xuất
              </button>
            </div>
          </nav>

          {/* Main Content Area */}
          <main className="flex-1 overflow-y-auto bg-slate-950 p-6">
            {children}
          </main>
        </div>
      </div>
    </DoctorAuthGuard>
  );
}

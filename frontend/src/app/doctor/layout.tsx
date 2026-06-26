'use client';

import React from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { DoctorAuthGuard } from '@/components/shared/DoctorAuthGuard';
import { AuthService } from '@/services/auth.client';
import {
  LayoutDashboard, Calendar, HeartPulse, Clock, Settings, LogOut
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
      <div className="min-h-screen bg-slate-50 flex flex-col text-slate-800 font-sans antialiased">
        
        {/* Top Header */}
        <header className="h-14 bg-white/80 backdrop-blur-md border-b border-slate-200/60 flex items-center justify-between px-6 sticky top-0 z-20 shrink-0">
          <div className="flex items-center gap-3">
            <span className="font-extrabold text-teal-600 text-sm tracking-tight">MediChain</span>
            <span className="text-slate-350 text-xs">|</span>
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-slate-550 uppercase tracking-wider">Cổng Bác Sĩ</span>
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_#10b981] animate-pulse" />
            </div>
          </div>

        </header>

        {/* Body */}
        <div className="flex flex-1 overflow-hidden">
          
          {/* Sidebar */}
          <nav className="w-56 bg-white border-r border-slate-200 flex flex-col overflow-y-auto shrink-0 select-none">
            <div className="flex-1 px-3 py-5 space-y-6">
              {DOCTOR_NAV_ITEMS.map((section) => (
                <div key={section.group} className="space-y-2">
                  <p className="text-slate-400 text-[9px] font-bold tracking-widest uppercase px-2 mb-1.5">
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
                          className={`w-full flex items-center gap-3 rounded-xl px-2.5 py-2 text-left transition-all duration-200 relative ${
                            active
                              ? 'bg-teal-500/10 text-teal-700 font-bold border border-teal-500/10 shadow-[0_0_12px_-3px_rgba(20,184,166,0.12)]'
                              : 'text-slate-550 hover:bg-slate-50 hover:text-slate-900 border border-transparent'
                          }`}
                        >
                          {active && (
                            <span className="absolute left-0 top-2 bottom-2 w-0.75 rounded-r bg-teal-600" />
                          )}
                          <Icon className={`w-4 h-4 shrink-0 transition-colors ${active ? 'text-teal-600' : 'text-slate-400'}`} />
                          <div className="flex-1 min-w-0">
                            <div className="text-xs font-semibold leading-none">{item.label}</div>
                            <div className={`text-[9px] mt-1.5 truncate ${active ? 'text-teal-700/60' : 'text-slate-400'}`}>{item.sublabel}</div>
                          </div>
                        </Link>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>

            {/* Bottom buttons */}
            <div className="px-3 py-3 border-t border-slate-200 space-y-2">
              <button
                onClick={handleLogout}
                className="w-full flex items-center justify-center gap-2 px-2.5 py-2 bg-red-50 hover:bg-red-100 border border-red-200 text-red-600 text-xs font-bold rounded-xl transition duration-150 cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5 shrink-0" />
                Đăng xuất
              </button>
            </div>
          </nav>

          {/* Main Content Area */}
          <main className="flex-1 overflow-y-auto bg-slate-50 p-6">
            {children}
          </main>
        </div>
      </div>
    </DoctorAuthGuard>
  );
}

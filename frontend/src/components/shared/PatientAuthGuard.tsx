'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AuthService } from '@/services/auth.client';

export function PatientAuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    const user = AuthService.getCurrentUser();
    if (user) {
      if (user.role === 'ADMIN') {
        router.replace('/admin');
      } else if (user.role === 'DOCTOR') {
        router.replace('/doctor');
      } else {
        setChecking(false);
      }
    } else {
      setChecking(false);
    }
  }, [router]);

  if (checking) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="flex items-center gap-2.5">
          <div className="w-4 h-4 border-2 border-slate-700 border-t-blue-400 rounded-full animate-spin" />
          <span className="text-slate-500 text-xs">Đang kiểm tra quyền truy cập...</span>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}

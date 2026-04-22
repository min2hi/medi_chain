'use client';

import { ShieldOff } from 'lucide-react';
import { useRouter } from 'next/navigation';

interface Props {
  allowed: boolean;
  children: React.ReactNode;
}

/**
 * Renders children if `allowed` is true.
 * Otherwise renders a professional "Access Denied" UI — stays within admin context.
 */
export function PermissionGate({ allowed, children }: Props) {
  const router = useRouter();

  if (allowed) return <>{children}</>;

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-6">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-10 text-center max-w-sm w-full">
        <div className="w-12 h-12 rounded-full bg-amber-500/10 border border-amber-500/20 flex items-center justify-center mx-auto mb-4">
          <ShieldOff className="w-6 h-6 text-amber-400" />
        </div>
        <h2 className="text-base font-semibold text-white mb-2">
          Không đủ quyền truy cập
        </h2>
        <p className="text-slate-500 text-sm mb-6 leading-relaxed">
          Trang này chỉ dành cho <span className="text-slate-300 font-medium">Quản trị viên hệ thống</span>.
          Liên hệ admin để được cấp quyền.
        </p>
        <button
          onClick={() => router.push('/admin/clinical-rules')}
          className="px-5 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 hover:text-white text-sm rounded-lg transition w-full"
        >
          Về Review Queue
        </button>
      </div>
    </div>
  );
}

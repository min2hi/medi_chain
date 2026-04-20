'use client';

import { useRouter } from 'next/navigation';
import { FileQuestion } from 'lucide-react';

export default function AdminNotFound() {
  const router = useRouter();

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
      <FileQuestion className="w-12 h-12 text-slate-700 mb-4" />
      <h2 className="text-lg font-semibold text-slate-300 mb-2">Trang không tồn tại</h2>
      <p className="text-slate-500 text-sm mb-6 max-w-sm">
        Trang này chưa được xây dựng hoặc đường dẫn không hợp lệ.
      </p>
      <button
        onClick={() => router.push('/admin/clinical-rules')}
        className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-sm rounded-lg transition border border-slate-700"
      >
        Về Review Queue
      </button>
    </div>
  );
}

'use client';

import React, { useEffect, useState } from 'react';
import { AdminApi, CacheStats } from '@/services/admin.service';
import { Settings2, RefreshCw } from 'lucide-react';

export default function ConfigPage() {
  const [stats, setStats] = useState<CacheStats | null>(null);
  const [isInvalidating, setIsInvalidating] = useState(false);
  const [toast, setToast] = useState('');

  // These thresholds are currently in code — surfaced here for visibility
  const THRESHOLDS = [
    { key: 'BLOCK_THRESHOLD', value: '0.82', label: 'Ngưỡng Chặn (Block)', description: 'Từ khóa AI có độ tương đồng ≥ ngưỡng này sẽ bị chặn gợi ý thuốc ngay lập tức. Quá thấp = nhiều false positive. Quá cao = bỏ sót nguy hiểm.' },
    { key: 'WARN_THRESHOLD',  value: '0.62', label: 'Ngưỡng Cảnh báo (Warn)', description: 'Từ khóa trong vùng [Warn, Block) sẽ hiển thị cảnh báo nhưng không chặn. Cho phép bác sĩ quyết định cuối cùng.' },
    { key: 'LRU_CACHE_TTL',   value: '300s', label: 'Cache TTL', description: 'Thời gian lưu cache Rules Engine trong RAM. Sau TTL hệ thống tự reload từ DB. Giảm để áp dụng change nhanh hơn, tăng để tiết kiệm DB query.' },
  ];

  const load = async () => {
    try {
      const res = await AdminApi.getCacheStats();
      if (res.success) setStats(res.data ?? null);
    } finally { /* no-op */ }
  };

  useEffect(() => { load(); }, []);

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000); };

  const handleInvalidate = async () => {
    setIsInvalidating(true);
    try {
      const res = await AdminApi.invalidateCache();
      if (res.success) showToast('✓ Cache đã được xóa — Rules Engine sẽ reload từ DB trong <1 giây');
      load();
    } finally { setIsInvalidating(false); }
  };

  return (
    <div className="space-y-5">
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-slate-800 border border-slate-700 text-slate-200 text-xs px-4 py-2.5 rounded-lg shadow-xl">{toast}</div>
      )}

      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Settings2 className="w-5 h-5 text-slate-400" />
            <h1 className="text-lg font-bold text-white">Cấu hình hệ thống</h1>
          </div>
          <p className="text-slate-500 text-sm">Các tham số kỹ thuật của Clinical Rules Engine. Thay đổi ngưỡng cần restart service để có hiệu lực.</p>
        </div>
        <button onClick={load} className="px-3 py-1.5 text-xs text-slate-400 hover:text-slate-200 bg-slate-800 border border-slate-700 rounded-lg flex items-center gap-1.5">
          <RefreshCw className="w-3.5 h-3.5" /> Tải lại
        </button>
      </div>

      {/* Thresholds — read-only display */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <div className="px-4 py-3 border-b border-slate-800">
          <span className="text-sm font-medium text-slate-300">Tham số AI Engine</span>
          <p className="text-xs text-slate-600 mt-0.5">Hiện tại được cấu hình qua environment variable. UI chỉnh sửa trực tiếp sẽ được triển khai sau.</p>
        </div>
        <div className="divide-y divide-slate-800/60">
          {THRESHOLDS.map(t => (
            <div key={t.key} className="px-4 py-4 flex items-start gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-mono text-slate-300 font-semibold">{t.key}</span>
                  <span className="text-xs text-blue-400 font-mono bg-blue-500/10 border border-blue-500/20 px-2 py-0.5 rounded">{t.value}</span>
                </div>
                <p className="text-xs text-slate-600">{t.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Live stats */}
      {stats && (
        <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
          <div className="px-4 py-3 border-b border-slate-800">
            <span className="text-sm font-medium text-slate-300">Trạng thái hiện tại</span>
          </div>
          <div className="p-4 grid grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-white">{stats?.db?.activeKeywords ?? '—'}</div>
              <div className="text-xs text-slate-500 mt-1">Từ khóa đang hoạt động</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-white">{stats?.db?.activeCombos ?? '—'}</div>
              <div className="text-xs text-slate-500 mt-1">Combo rules đang hoạt động</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-400">{stats?.db?.pendingReview ?? '—'}</div>
              <div className="text-xs text-slate-500 mt-1">Chờ phê duyệt</div>
            </div>
          </div>
        </div>
      )}

      {/* Hot reload */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center justify-between">
        <div>
          <div className="text-sm font-medium text-slate-300 mb-1">Hot-Reload Cache</div>
          <p className="text-xs text-slate-600">Buộc Rules Engine xóa cache và tải lại ngay từ DB — không cần restart server. Dùng sau khi approve keyword hoặc thay đổi thủ công trong DB.</p>
        </div>
        <button
          onClick={handleInvalidate}
          disabled={isInvalidating}
          className="px-4 py-2 text-xs text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition disabled:opacity-50 flex items-center gap-1.5 shrink-0 ml-4"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isInvalidating ? 'animate-spin' : ''}`} />
          Reload ngay
        </button>
      </div>
    </div>
  );
}

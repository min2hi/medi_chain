'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AdminApi, CacheStats } from '@/services/admin.service';
import { Settings2, RefreshCw, CheckCircle, Database } from 'lucide-react';

export default function ConfigPage() {
  const [stats, setStats] = useState<CacheStats | null>(null);
  const [isInvalidating, setIsInvalidating] = useState(false);
  const [toast, setToast] = useState('');

  const THRESHOLDS = [
    { key: 'BLOCK_THRESHOLD', value: '0.82', label: 'Ngưỡng Chặn (Block)', description: 'Từ khóa AI có độ tương đồng ≥ ngưỡng này sẽ bị chặn gợi ý thuốc ngay lập tức. Quá thấp = nhiều false positive. Quá cao = bỏ sót nguy hiểm.' },
    { key: 'WARN_THRESHOLD',  value: '0.62', label: 'Ngưỡng Cảnh báo (Warn)', description: 'Từ khóa trong vùng [Warn, Block) sẽ hiển thị cảnh báo nhưng không chặn. Cho phép bác sĩ quyết định cuối cùng.' },
    { key: 'LRU_CACHE_TTL',   value: '300s', label: 'Cache TTL', description: 'Thời gian lưu cache Rules Engine trong RAM. Sau TTL hệ thống tự reload từ DB. Giảm để áp dụng thay đổi nhanh hơn, tăng để tiết kiệm DB query.' },
  ];

  const load = async () => {
    try {
      const res = await AdminApi.getCacheStats();
      if (res.success) setStats(res.data ?? null);
    } finally { /* no-op */ }
  };

  useEffect(() => { load(); }, []);

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3500); };

  const handleInvalidate = async () => {
    setIsInvalidating(true);
    try {
      const res = await AdminApi.invalidateCache();
      if (res.success) showToast('Cache đã được xóa thành công');
      load();
    } finally { setIsInvalidating(false); }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
      className="space-y-6"
    >
      {/* Toast Notification */}
      <AnimatePresence>
        {toast && (
          <motion.div
            initial={{ opacity: 0, y: -20, x: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, x: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95, transition: { duration: 0.15 } }}
            className="fixed top-6 right-6 z-50 bg-[#0d1520]/85 backdrop-blur-md border border-emerald-500/30 text-emerald-400 text-xs px-4 py-3 rounded-xl shadow-[0_0_20px_rgba(16,185,129,0.1)] flex items-center gap-2"
          >
            <CheckCircle className="w-4 h-4 shrink-0 text-emerald-400" />
            <span className="font-semibold">{toast}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5 mb-1">
            <div className="p-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/25">
              <Settings2 className="w-5 h-5 text-emerald-400" />
            </div>
            <h1 className="text-xl font-bold text-white tracking-tight">Cấu hình hệ thống</h1>
          </div>
          <p className="text-[#8a9bb5] text-xs max-w-2xl mt-1 leading-relaxed">
            Các tham số kỹ thuật hoạt động của Clinical Rules Engine. Thay đổi các ngưỡng cần khởi động lại dịch vụ để có hiệu lực.
          </p>
        </div>
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={load}
          className="px-3.5 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 bg-[#111926]/40 hover:bg-[#111926] border border-[#1e293b]/60 rounded-xl transition duration-200 flex items-center gap-1.5 cursor-pointer self-start md:self-auto shrink-0"
        >
          <RefreshCw className="w-3.5 h-3.5" /> Tải lại
        </motion.button>
      </div>

      {/* Thresholds Display */}
      <div className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl overflow-hidden shadow-lg">
        <div className="px-5 py-4 border-b border-[#1e293b]/60 bg-[#111926]/20">
          <span className="text-xs font-bold text-slate-300 uppercase tracking-widest font-mono">Tham số AI Engine</span>
          <p className="text-[#8a9bb5] text-[11px] mt-1 leading-relaxed">
            Hiện tại được cấu hình qua biến môi trường (.env). Giao diện chỉnh sửa trực tiếp sẽ được kích hoạt ở các phiên bản sau.
          </p>
        </div>
        <div className="divide-y divide-[#1e293b]/40">
          {THRESHOLDS.map(t => (
            <div key={t.key} className="px-5 py-4 flex flex-col md:flex-row md:items-start justify-between gap-3 hover:bg-[#111926]/25 transition duration-150 group">
              <div className="flex-1 min-w-0 space-y-1">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold font-mono text-slate-200">{t.key}</span>
                  <span className="text-[10px] text-slate-400 font-mono bg-slate-900 border border-[#1e293b]/40 px-1.5 py-0.5 rounded-md">
                    {t.label}
                  </span>
                </div>
                <p className="text-xs text-slate-500 max-w-3xl leading-relaxed">{t.description}</p>
              </div>
              <div className="shrink-0 font-mono text-xs font-bold text-emerald-450 bg-emerald-950/20 border border-emerald-900/30 px-3 py-1 rounded-xl self-start md:self-auto shadow-[0_0_8px_rgba(16,185,129,0.05)]">
                {t.value}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Live Stats */}
      {stats && (
        <div className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl overflow-hidden shadow-lg">
          <div className="px-5 py-4 border-b border-[#1e293b]/60 bg-[#111926]/20 flex items-center gap-2">
            <Database className="w-4 h-4 text-emerald-400" />
            <span className="text-xs font-bold text-slate-300 uppercase tracking-widest font-mono">Trạng thái cơ sở dữ liệu</span>
          </div>
          <div className="p-5 grid grid-cols-1 md:grid-cols-3 gap-6 divide-y md:divide-y-0 md:divide-x divide-[#1e293b]/40">
            <div className="text-center md:pb-0 pb-4">
              <div className="text-3xl font-black text-white font-mono">{stats?.db?.activeKeywords ?? '—'}</div>
              <div className="text-xs text-slate-500 mt-1.5">Từ khóa đang hoạt động</div>
            </div>
            <div className="text-center md:pt-0 pt-4 md:pb-0 pb-4">
              <div className="text-3xl font-black text-white font-mono">{stats?.db?.activeCombos ?? '—'}</div>
              <div className="text-xs text-slate-500 mt-1.5">Combo rules đang hoạt động</div>
            </div>
            <div className="text-center md:pt-0 pt-4">
              <div className="text-3xl font-black text-orange-400 font-mono">{stats?.db?.pendingReview ?? '—'}</div>
              <div className="text-xs text-slate-500 mt-1.5">Chờ phê duyệt từ AI</div>
            </div>
          </div>
        </div>
      )}

      {/* Hot Reload Utility Console */}
      <div className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-lg">
        <div className="space-y-1">
          <div className="text-sm font-semibold text-slate-200">Hot-Reload Cache</div>
          <p className="text-xs text-slate-500 max-w-2xl leading-relaxed">
            Buộc Rules Engine xóa bỏ hoàn toàn cache trong bộ nhớ RAM và tải lại lập tức dữ liệu mới nhất từ cơ sở dữ liệu.
            Hệ thống không cần khởi động lại. Cực kỳ hữu dụng sau khi duyệt từ khóa hoặc cập nhật trực tiếp DB.
          </p>
        </div>
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={handleInvalidate}
          disabled={isInvalidating}
          className="px-4 py-2.5 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 border border-emerald-500/25 rounded-xl transition duration-150 flex items-center gap-1.5 shrink-0 cursor-pointer shadow-[0_0_12px_rgba(16,185,129,0.05)]"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isInvalidating ? 'animate-spin' : ''}`} />
          Reload Cache
        </motion.button>
      </div>
    </motion.div>
  );
}

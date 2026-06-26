'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { PendingKeyword, AdminApi } from '@/services/admin.service';
import { CheckCircle2, XCircle, AlertTriangle, Info } from 'lucide-react';

interface Props {
  initialData: PendingKeyword[];
  onActionSuccess: () => void;
}

export default function PendingReviewTable({ initialData, onActionSuccess }: Props) {
  const [data, setData] = useState<PendingKeyword[]>(initialData);
  const [processing, setProcessing] = useState<number | null>(null);
  const [error, setError] = useState('');

  const handleApprove = async (keyword: PendingKeyword) => {
    if (!confirm(`Xác nhận thêm "${keyword.keyword}" vào nhóm "${keyword.groupLabel}"?`)) return;
    setProcessing(keyword.id);
    setError('');
    try {
      const res = await AdminApi.approveKeyword(keyword.id);
      if (res.success) {
        setData(prev => prev.filter(k => k.id !== keyword.id));
        onActionSuccess();
      } else {
        setError(res.message || 'Lỗi duyệt từ khóa');
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Lỗi kết nối');
    } finally {
      setProcessing(null);
    }
  };

  const handleReject = async (keyword: PendingKeyword) => {
    if (!confirm(`Từ chối "${keyword.keyword}"? AI sẽ bỏ qua từ này trong tương lai.`)) return;
    setProcessing(keyword.id);
    setError('');
    try {
      const res = await AdminApi.rejectKeyword(keyword.id);
      if (res.success) {
        setData(prev => prev.filter(k => k.id !== keyword.id));
      } else {
        setError(res.message || 'Lỗi loại bỏ từ khóa');
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Lỗi kết nối');
    } finally {
      setProcessing(null);
    }
  };

  if (data.length === 0) {
    return (
      <div className="py-12 text-center flex flex-col items-center justify-center">
        <div className="w-12 h-12 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mb-3">
          <CheckCircle2 className="w-6 h-6 text-emerald-400" />
        </div>
        <h3 className="text-slate-200 font-bold text-sm">Hàng chờ trống</h3>
        <p className="text-slate-500 text-xs mt-1 max-w-xs">Không có từ khóa nào cần duyệt. AI chưa phát hiện từ mới nào.</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {error && (
        <div className="p-3 bg-red-950/20 border border-red-900/35 text-red-400 text-xs rounded-xl flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 shrink-0" />
          {error}
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-xs">
          <thead>
            <tr className="text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest border-b border-[#1e293b]/45">
              <th className="pb-3 pr-4 font-mono">Từ khóa phát hiện</th>
              <th className="pb-3 pr-4 font-mono">Độ tương đồng</th>
              <th className="pb-3 pr-4 font-mono">Nhóm khẩn cấp</th>
              <th className="pb-3 pr-4 font-mono">Từ gốc tham chiếu</th>
              <th className="pb-3 text-right font-mono">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1e293b]/40">
            <AnimatePresence mode="popLayout">
              {data.map(item => {
                const matchPct = Math.round(item.similarityScore * 100);
                const isHighConf = matchPct >= 82;
                const isProcessing = processing === item.id;

                return (
                  <motion.tr
                    key={item.id}
                    layout
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, x: -20, transition: { duration: 0.2 } }}
                    className="hover:bg-[#111926]/40 transition-colors group"
                  >
                    <td className="py-3.5 pr-4">
                      <div className="font-semibold text-slate-200 text-xs">{item.keyword}</div>
                      <div className="text-slate-500 text-[10px] font-mono mt-1">
                        {new Date(item.createdAt).toLocaleDateString('vi-VN')}
                      </div>
                    </td>

                    <td className="py-3.5 pr-4">
                      <div className="flex items-center gap-2">
                        <span className={`px-1.5 py-0.5 rounded text-[10px] font-mono font-bold border ${
                          isHighConf
                            ? 'bg-red-950/45 text-red-400 border-red-900/40'
                            : 'bg-orange-950/45 text-orange-400 border-orange-900/40'
                        }`}>
                          {matchPct}%
                        </span>
                        <div className="w-16 h-1 bg-[#182030] rounded-full overflow-hidden shrink-0">
                          <div
                            className={`h-full rounded-full transition-all duration-300 ${isHighConf ? 'bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.5)]' : 'bg-orange-500 shadow-[0_0_8px_rgba(249,115,22,0.5)]'}`}
                            style={{ width: `${matchPct}%` }}
                          />
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 pr-4">
                      <span className="bg-[#111926]/60 text-slate-350 text-[10px] font-semibold px-2.5 py-1 rounded-lg border border-[#1e293b]/70 font-mono">
                        {item.groupLabel}
                      </span>
                    </td>

                    <td className="py-3.5 pr-4">
                      {item.sourceKeyword ? (
                        <div className="flex items-center gap-1.5 text-[11px] text-slate-550">
                          <Info className="w-3.5 h-3.5 text-slate-600 shrink-0" />
                          <span className="font-mono bg-slate-900/55 px-1.5 py-0.5 rounded border border-[#1e293b]/30">{item.sourceKeyword.keyword}</span>
                        </div>
                      ) : (
                        <span className="text-slate-650 font-mono text-[10px]">—</span>
                      )}
                    </td>

                    <td className="py-3.5">
                      <div className="flex justify-end gap-2">
                        <motion.button
                          whileHover={{ scale: 1.02 }}
                          whileTap={{ scale: 0.98 }}
                          onClick={() => handleReject(item)}
                          disabled={isProcessing}
                          className="px-2.5 py-1.5 text-[10px] font-bold text-slate-400 hover:text-red-400 bg-red-950/10 hover:bg-red-950/30 border border-[#1e293b]/70 hover:border-red-900/40 rounded-xl transition duration-200 flex items-center gap-1 disabled:opacity-40 cursor-pointer"
                        >
                          <XCircle className="w-3.5 h-3.5" />
                          Từ chối
                        </motion.button>
                        <motion.button
                          whileHover={{ scale: 1.02 }}
                          whileTap={{ scale: 0.98 }}
                          onClick={() => handleApprove(item)}
                          disabled={isProcessing}
                          className="px-2.5 py-1.5 text-[10px] font-bold text-white bg-emerald-600 hover:bg-emerald-500 border border-emerald-500/20 hover:border-emerald-500/45 rounded-xl transition duration-200 flex items-center gap-1 disabled:opacity-40 cursor-pointer shadow-[0_0_12px_rgba(16,185,129,0.05)] hover:shadow-[0_0_15px_rgba(16,185,129,0.15)]"
                        >
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          Approve
                        </motion.button>
                      </div>
                    </td>
                  </motion.tr>
                );
              })}
            </AnimatePresence>
          </tbody>
        </table>
      </div>
    </div>
  );
}

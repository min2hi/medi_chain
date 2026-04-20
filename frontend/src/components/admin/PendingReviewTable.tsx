'use client';

import React, { useState } from 'react';
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
      <div className="py-12 text-center">
        <CheckCircle2 className="w-10 h-10 text-emerald-500 mx-auto mb-3" />
        <h3 className="text-slate-200 font-medium text-sm">Hàng chờ trống</h3>
        <p className="text-slate-500 text-xs mt-1">Không có từ khóa nào cần duyệt. AI chưa phát hiện từ mới nào.</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {error && (
        <div className="p-3 bg-red-500/10 border border-red-500/20 text-red-400 text-xs rounded-lg flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 shrink-0" />
          {error}
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-[10px] font-bold text-slate-600 uppercase tracking-wider">
              <th className="pb-2 pr-4">Từ khóa AI phát hiện</th>
              <th className="pb-2 pr-4">Độ tương đồng</th>
              <th className="pb-2 pr-4">Nhóm khẩn cấp</th>
              <th className="pb-2 pr-4">Từ gốc tham chiếu</th>
              <th className="pb-2 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {data.map(item => {
              const matchPct = Math.round(item.similarityScore * 100);
              const isHighConf = matchPct >= 82;
              const isProcessing = processing === item.id;

              return (
                <tr key={item.id} className="hover:bg-slate-800/50 transition-colors">
                  <td className="py-3 pr-4">
                    <div className="font-medium text-slate-200 text-sm">{item.keyword}</div>
                    <div className="text-slate-600 text-xs mt-0.5">
                      {new Date(item.createdAt).toLocaleDateString('vi-VN')}
                    </div>
                  </td>

                  <td className="py-3 pr-4">
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-0.5 rounded text-xs font-bold ${
                        isHighConf
                          ? 'bg-red-500/15 text-red-400 border border-red-500/20'
                          : 'bg-orange-500/15 text-orange-400 border border-orange-500/20'
                      }`}>
                        {matchPct}%
                      </span>
                      <div className="w-16 h-1 bg-slate-700 rounded-full overflow-hidden">
                        <div
                          className={`h-1 rounded-full ${isHighConf ? 'bg-red-500' : 'bg-orange-500'}`}
                          style={{ width: `${matchPct}%` }}
                        />
                      </div>
                    </div>
                  </td>

                  <td className="py-3 pr-4">
                    <span className="bg-slate-800 text-slate-300 text-xs px-2 py-1 rounded border border-slate-700">
                      {item.groupLabel}
                    </span>
                  </td>

                  <td className="py-3 pr-4">
                    {item.sourceKeyword ? (
                      <div className="flex items-center gap-1 text-xs text-slate-500">
                        <Info className="w-3 h-3 shrink-0" />
                        <span className="font-mono">{item.sourceKeyword.keyword}</span>
                      </div>
                    ) : (
                      <span className="text-slate-700 text-xs">—</span>
                    )}
                  </td>

                  <td className="py-3">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => handleReject(item)}
                        disabled={isProcessing}
                        className="px-3 py-1.5 text-xs font-medium text-slate-400 hover:text-red-400 bg-slate-800 hover:bg-red-500/10 border border-slate-700 hover:border-red-500/30 rounded-lg transition flex items-center gap-1 disabled:opacity-40"
                      >
                        <XCircle className="w-3.5 h-3.5" />
                        Từ chối
                      </button>
                      <button
                        onClick={() => handleApprove(item)}
                        disabled={isProcessing}
                        className="px-3 py-1.5 text-xs font-medium text-white bg-blue-600 hover:bg-blue-500 rounded-lg transition flex items-center gap-1 disabled:opacity-40"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        Approve
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

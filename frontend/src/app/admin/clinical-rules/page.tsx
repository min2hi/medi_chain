'use client';

import React, { useEffect, useState } from 'react';
import { AdminApi, PendingKeyword } from '@/services/admin.service';
import PendingReviewTable from '@/components/admin/PendingReviewTable';
import { RefreshCw, BrainCircuit, Clock, CheckCircle2, AlertTriangle } from 'lucide-react';

export default function SemanticQueuePage() {
  const [queue, setQueue] = useState<PendingKeyword[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isInvalidating, setIsInvalidating] = useState(false);
  const [stats, setStats] = useState({ total: 0, highConfidence: 0, lowConfidence: 0 });

  const loadQueue = async () => {
    setIsLoading(true);
    try {
      const res = await AdminApi.getPendingReviews(1, 50);
      if (res.success && res.data) {
        const data = res.data.data || [];
        setQueue(data);
        setStats({
          total: data.length,
          highConfidence: data.filter((k: PendingKeyword) => k.similarityScore >= 0.82).length,
          lowConfidence: data.filter((k: PendingKeyword) => k.similarityScore < 0.82).length,
        });
      }
    } catch (err) {
      console.error('Failed to load pending queue', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => { loadQueue(); }, []);

  const handleInvalidateCache = async () => {
    setIsInvalidating(true);
    try {
      await AdminApi.invalidateCache();
    } finally {
      setIsInvalidating(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <BrainCircuit className="w-5 h-5 text-blue-400" />
            <h1 className="text-lg font-bold text-white">AI Semantic Review Queue</h1>
          </div>
          <p className="text-slate-500 text-sm">
            Các từ khóa lạ được AI phát hiện tự động qua Vector Cosine Similarity — chờ Bác sĩ phê duyệt.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={loadQueue}
            className="flex items-center gap-1.5 px-3 py-2 text-xs text-slate-400 hover:text-slate-200 bg-slate-800 hover:bg-slate-700 rounded-lg transition border border-slate-700"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            Tải lại
          </button>
          <button
            onClick={handleInvalidateCache}
            disabled={isInvalidating}
            className="flex items-center gap-1.5 px-3 py-2 text-xs text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isInvalidating ? 'animate-spin' : ''}`} />
            Hot-Reload Cache
          </button>
        </div>
      </div>

      {/* Stats strip */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center gap-3">
          <Clock className="w-8 h-8 text-orange-400 bg-orange-400/10 p-1.5 rounded-lg shrink-0" />
          <div>
            <div className="text-2xl font-bold text-white">{stats.total}</div>
            <div className="text-xs text-slate-500">Chờ duyệt</div>
          </div>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center gap-3">
          <AlertTriangle className="w-8 h-8 text-red-400 bg-red-400/10 p-1.5 rounded-lg shrink-0" />
          <div>
            <div className="text-2xl font-bold text-white">{stats.highConfidence}</div>
            <div className="text-xs text-slate-500">Độ tin cậy cao ≥82%</div>
          </div>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center gap-3">
          <CheckCircle2 className="w-8 h-8 text-emerald-400 bg-emerald-400/10 p-1.5 rounded-lg shrink-0" />
          <div>
            <div className="text-2xl font-bold text-white">{stats.lowConfidence}</div>
            <div className="text-xs text-slate-500">Cần xem xét kỹ</div>
          </div>
        </div>
      </div>

      {/* Main Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <div className="px-4 py-3 border-b border-slate-800 flex items-center gap-2">
          <span className="text-sm font-medium text-slate-300">Danh sách từ khóa phát hiện bởi AI</span>
          {queue.length > 0 && (
            <span className="bg-orange-500/20 text-orange-400 text-xs px-2 py-0.5 rounded-full border border-orange-500/20">
              {queue.length} mục
            </span>
          )}
        </div>
        <div className="p-4">
          {isLoading ? (
            <div className="space-y-3">
              {[1, 2, 3].map(i => (
                <div key={i} className="h-12 bg-slate-800 rounded-lg animate-pulse" />
              ))}
            </div>
          ) : (
            <PendingReviewTable initialData={queue} onActionSuccess={loadQueue} />
          )}
        </div>
      </div>
    </div>
  );
}

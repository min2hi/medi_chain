'use client';

import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { AdminApi, PendingKeyword } from '@/services/admin.service';
import PendingReviewTable from '@/components/admin/PendingReviewTable';
import { RefreshCw, BrainCircuit, Clock, CheckCircle2, AlertTriangle } from 'lucide-react';

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.05 }
  }
};

const itemVariants = {
  hidden: { opacity: 0, y: 12 },
  show: { opacity: 1, y: 0, transition: { type: 'spring' as const, stiffness: 300, damping: 24 } }
};

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
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
      className="space-y-6"
    >
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5 mb-1">
            <div className="p-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/25">
              <BrainCircuit className="w-5 h-5 text-emerald-400" />
            </div>
            <h1 className="text-xl font-bold text-white tracking-tight">AI Semantic Review Queue</h1>
          </div>
          <p className="text-[#8a9bb5] text-xs max-w-2xl mt-1 leading-relaxed">
            Các từ khóa mới do AI tự động phát hiện bằng cách đo độ tương đồng ngữ nghĩa (Vector Cosine Similarity). 
            Cần bác sĩ hoặc quản trị viên phê duyệt để bổ sung vào từ điển khẩn cấp.
          </p>
        </div>
        
        <div className="flex items-center gap-2">
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={loadQueue}
            className="flex items-center gap-1.5 px-3 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 bg-[#111926]/40 hover:bg-[#111926] rounded-xl transition duration-200 border border-[#1e293b]/60 cursor-pointer"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            Tải lại
          </motion.button>
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleInvalidateCache}
            disabled={isInvalidating}
            className="flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold text-emerald-400 bg-emerald-950/20 hover:bg-emerald-950/40 border border-emerald-900/35 hover:border-emerald-900/50 rounded-xl transition duration-200 disabled:opacity-50 cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isInvalidating ? 'animate-spin' : ''}`} />
            Hot-Reload Cache
          </motion.button>
        </div>
      </div>

      {/* Stats strip */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="show"
        className="grid grid-cols-1 md:grid-cols-3 gap-4"
      >
        <motion.div
          variants={itemVariants}
          whileHover={{ y: -2 }}
          className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl p-4 flex items-center gap-4 hover:border-[#2a3a50] transition-colors shadow-lg"
        >
          <div className="w-10 h-10 rounded-lg bg-orange-500/10 border border-orange-500/20 flex items-center justify-center shrink-0">
            <Clock className="w-5 h-5 text-orange-400" />
          </div>
          <div>
            <div className="text-2xl font-black text-white font-mono">{stats.total}</div>
            <div className="text-xs text-[#8a9bb5] mt-0.5">Yêu cầu chờ duyệt</div>
          </div>
        </motion.div>

        <motion.div
          variants={itemVariants}
          whileHover={{ y: -2 }}
          className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl p-4 flex items-center gap-4 hover:border-[#2a3a50] transition-colors shadow-lg"
        >
          <div className="w-10 h-10 rounded-lg bg-red-500/10 border border-red-500/20 flex items-center justify-center shrink-0">
            <AlertTriangle className="w-5 h-5 text-red-400" />
          </div>
          <div>
            <div className="text-2xl font-black text-white font-mono">{stats.highConfidence}</div>
            <div className="text-xs text-[#8a9bb5] mt-0.5">Trùng khớp cao (≥ 82%)</div>
          </div>
        </motion.div>

        <motion.div
          variants={itemVariants}
          whileHover={{ y: -2 }}
          className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl p-4 flex items-center gap-4 hover:border-[#2a3a50] transition-colors shadow-lg"
        >
          <div className="w-10 h-10 rounded-lg bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center shrink-0">
            <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          </div>
          <div>
            <div className="text-2xl font-black text-white font-mono">{stats.lowConfidence}</div>
            <div className="text-xs text-[#8a9bb5] mt-0.5">Trùng khớp thấp (&lt; 82%)</div>
          </div>
        </motion.div>
      </motion.div>

      {/* Main Table */}
      <div className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl overflow-hidden shadow-xl">
        <div className="px-5 py-4 border-b border-[#1e293b]/60 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-slate-300 uppercase tracking-wider font-mono">Queue List</span>
            {queue.length > 0 && (
              <span className="bg-orange-500/10 text-orange-400 text-[10px] font-mono px-2 py-0.5 rounded-md border border-orange-500/20">
                {queue.length} items
              </span>
            )}
          </div>
        </div>
        <div className="p-5">
          {isLoading ? (
            <div className="space-y-3">
              {[1, 2, 3].map(i => (
                <div key={i} className="h-14 bg-[#111926]/40 border border-[#1e293b]/30 rounded-xl animate-pulse" />
              ))}
            </div>
          ) : (
            <PendingReviewTable initialData={queue} onActionSuccess={loadQueue} />
          )}
        </div>
      </div>
    </motion.div>
  );
}

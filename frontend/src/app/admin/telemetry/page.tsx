'use client';

import React, { useEffect, useState } from 'react';
import { AdminApi, AuditEntry, CacheStats } from '@/services/admin.service';
import { BarChart3, RefreshCw, Database, Zap, Clock } from 'lucide-react';

export default function TelemetryPage() {
  const [stats, setStats] = useState<CacheStats | null>(null);
  const [auditLog, setAuditLog] = useState<AuditEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const load = async () => {
    setIsLoading(true);
    try {
      const [statsRes, auditRes] = await Promise.all([
        AdminApi.getCacheStats(),
        AdminApi.getAuditLog(30),
      ]);
      if (statsRes.success) setStats(statsRes.data || null);
      if (auditRes.success) setAuditLog(auditRes.data || []);
    } finally { setIsLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const fmt = (d: string | null | undefined) =>
    d ? new Date(d).toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' }) : '—';

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <BarChart3 className="w-5 h-5 text-slate-400" />
            <h1 className="text-lg font-bold text-white">Telemetry</h1>
          </div>
          <p className="text-slate-500 text-sm">Trạng thái hệ thống, hiệu suất Rules Engine và lịch sử thay đổi từ khóa.</p>
        </div>
        <button onClick={load} className="px-3 py-1.5 text-xs text-slate-400 hover:text-slate-200 bg-slate-800 border border-slate-700 rounded-lg flex items-center gap-1.5">
          <RefreshCw className="w-3.5 h-3.5" /> Tải lại
        </button>
      </div>

      {/* Stats cards */}
      {stats && (
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <Database className="w-4 h-4 text-slate-500" />
              <span className="text-xs text-slate-500 font-semibold uppercase tracking-wider">Database</span>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Keywords active</span>
                <span className="text-xs font-mono text-emerald-400">{stats?.db?.activeKeywords ?? '—'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Combo rules active</span>
                <span className="text-xs font-mono text-emerald-400">{stats?.db?.activeCombos ?? '—'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Chờ duyệt</span>
                <span className="text-xs font-mono text-orange-400">{stats?.db?.pendingReview ?? '—'}</span>
              </div>
            </div>
          </div>

          <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <Zap className="w-4 h-4 text-slate-500" />
              <span className="text-xs text-slate-500 font-semibold uppercase tracking-wider">Cache Engine</span>
            </div>
            <div className="space-y-2">
              {stats.cache && Object.entries(stats.cache).slice(0, 4).map(([k, v]) => (
                <div key={k} className="flex justify-between">
                  <span className="text-xs text-slate-500">{k}</span>
                  <span className="text-xs font-mono text-slate-300">{String(v)}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <Clock className="w-4 h-4 text-slate-500" />
              <span className="text-xs text-slate-500 font-semibold uppercase tracking-wider">Audit</span>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Bản ghi gần nhất</span>
                <span className="text-xs font-mono text-slate-300">{auditLog.length}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Active</span>
                <span className="text-xs font-mono text-emerald-400">{auditLog.filter(a => a.isActive).length}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-slate-500">Inactive</span>
                <span className="text-xs font-mono text-slate-500">{auditLog.filter(a => !a.isActive).length}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Audit Log Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <div className="px-4 py-3 border-b border-slate-800 flex items-center justify-between">
          <span className="text-sm font-medium text-slate-300">Change Log — 30 bản ghi gần nhất</span>
          <span className="text-xs text-slate-600">Cập nhật: {new Date().toLocaleTimeString('vi-VN')}</span>
        </div>
        {isLoading ? (
          <div className="p-6 space-y-2">{[1,2,3,4,5].map(i => <div key={i} className="h-10 bg-slate-800 rounded animate-pulse" />)}</div>
        ) : auditLog.length === 0 ? (
          <div className="p-10 text-center text-slate-600 text-sm">Chưa có dữ liệu audit log.</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="text-[10px] font-bold text-slate-600 uppercase tracking-wider border-b border-slate-800">
                <th className="text-left px-4 py-3">Từ khóa</th>
                <th className="text-left px-4 py-3">Nhóm</th>
                <th className="text-left px-4 py-3">Trạng thái</th>
                <th className="text-left px-4 py-3">Tạo lúc</th>
                <th className="text-left px-4 py-3">Kích hoạt lúc</th>
                <th className="text-left px-4 py-3">Ghi chú</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {auditLog.map(entry => (
                <tr key={entry.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-4 py-2.5">
                    <span className="text-xs font-mono text-slate-300">{entry.keyword}</span>
                  </td>
                  <td className="px-4 py-2.5">
                    <span className="text-xs text-slate-500">{entry.groupId}</span>
                  </td>
                  <td className="px-4 py-2.5">
                    <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${entry.isActive ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/20' : 'bg-slate-700/50 text-slate-500 border border-slate-700'}`}>
                      {entry.isActive ? 'ACTIVE' : 'INACTIVE'}
                    </span>
                  </td>
                  <td className="px-4 py-2.5"><span className="text-xs text-slate-600">{fmt(entry.createdAt)}</span></td>
                  <td className="px-4 py-2.5"><span className="text-xs text-slate-600">{fmt(entry.activatedAt)}</span></td>
                  <td className="px-4 py-2.5"><span className="text-xs text-slate-600 truncate max-w-[140px] block">{entry.changeNote || '—'}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

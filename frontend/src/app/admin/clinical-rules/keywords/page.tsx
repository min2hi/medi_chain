'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AdminApi, SafetyKeyword } from '@/services/admin.service';
import { BookType, Plus, RefreshCw, Search, X, CheckCircle } from 'lucide-react';

const GROUP_OPTIONS = [
  { value: '', label: 'Tất cả nhóm' },
  { value: 'acs',           label: 'Hội chứng vành cấp / Nhồi máu cơ tim' },
  { value: 'stroke',        label: 'Đột quỵ não / Tai biến mạch máu não' },
  { value: 'resp_failure',  label: 'Suy hô hấp cấp / Phù phổi' },
  { value: 'anaphylaxis',   label: 'Sốc phản vệ / Dị ứng nặng toàn thân' },
  { value: 'sepsis',        label: 'Nhiễm trùng huyết / Viêm màng não' },
  { value: 'shock',         label: 'Sốc / Tụt huyết áp nặng' },
  { value: 'seizure',       label: 'Co giật / Động kinh cấp' },
  { value: 'syncope',       label: 'Ngất xỉu / Mất ý thức' },
  { value: 'gi_bleeding',   label: 'Xuất huyết tiêu hóa' },
  { value: 'trauma',        label: 'Chấn thương nghiêm trọng' },
  { value: 'hyperpyrexia',  label: 'Sốt cực cao (>39.5°C)' },
  { value: 'liver_failure', label: 'Vàng da nặng / Suy gan cấp' },
  { value: 'acute_abdomen', label: 'Đau bụng cấp / Nghi cấp cứu ngoại' },
  { value: 'poisoning',     label: 'Ngộ độc / Quá liều thuốc' },
  { value: 'obstetric',     label: 'Cấp cứu sản khoa' },
];

const STATUS_BADGE: Record<string, string> = {
  active:   'bg-emerald-950/40 text-emerald-400 border border-emerald-900/50 font-mono text-[9px] font-semibold tracking-wider px-2 py-0.5 rounded-md',
  inactive: 'bg-slate-900/60 text-slate-500 border border-[#1e293b]/70 font-mono text-[9px] font-semibold tracking-wider px-2 py-0.5 rounded-md',
};

export default function SafetyKeywordsPage() {
  const [keywords, setKeywords] = useState<SafetyKeyword[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterGroup, setFilterGroup] = useState('');
  const [filterActive, setFilterActive] = useState<'all' | 'active' | 'inactive'>('all');
  const [processing, setProcessing] = useState<number | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({
    keyword: '', groupId: 'acs', groupLabel: 'Hội chứng vành cấp / Nhồi máu cơ tim',
    guidelineRef: '', changeNote: '',
  });
  const [toast, setToast] = useState('');

  const load = async () => {
    setIsLoading(true);
    try {
      const res = await AdminApi.listKeywords({
        groupId: filterGroup || undefined,
        isActive: filterActive === 'all' ? undefined : filterActive === 'active',
      });
      if (res.success) setKeywords((res.data as SafetyKeyword[]) || []);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => { load(); }, [filterGroup, filterActive]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 3500);
  };

  const handleToggle = async (kw: SafetyKeyword) => {
    if (!confirm(`${kw.isActive ? 'Tắt' : 'Bật'} từ khóa "${kw.keyword}"?`)) return;
    setProcessing(kw.id);
    try {
      const res = kw.isActive
        ? await AdminApi.deactivateKeyword(kw.id, 'Deactivated via Admin UI')
        : await AdminApi.activateKeyword(kw.id);
      if (res.success) { showToast(`Đã ${kw.isActive ? 'tắt' : 'bật'} từ khóa thành công`); load(); }
    } finally { setProcessing(null); }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.keyword.trim()) return;
    const res = await AdminApi.createKeyword({
      keyword: form.keyword.trim(),
      groupId: form.groupId,
      groupLabel: form.groupLabel,
      guidelineRef: form.guidelineRef || undefined,
      changeNote: form.changeNote || undefined,
    });
    if (res.success) {
      showToast(`Đã tạo từ khóa "${form.keyword}"`);
      setForm({ keyword: '', groupId: 'acs', groupLabel: 'Hội chứng vành cấp / Nhồi máu cơ tim', guidelineRef: '', changeNote: '' });
      setShowAdd(false);
      load();
    }
  };

  const filtered = keywords.filter(k =>
    k.keyword.toLowerCase().includes(search.toLowerCase()) ||
    k.groupLabel.toLowerCase().includes(search.toLowerCase())
  );

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
            className="fixed top-6 right-6 z-50 bg-[#0d1520]/80 backdrop-blur-md border border-emerald-500/30 text-emerald-400 text-xs px-4 py-3 rounded-xl shadow-[0_0_20px_rgba(16,185,129,0.1)] flex items-center gap-2"
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
              <BookType className="w-5 h-5 text-emerald-400" />
            </div>
            <h1 className="text-xl font-bold text-white tracking-tight">Safety Keywords</h1>
            <span className="text-[10px] text-slate-400 bg-[#111926]/60 border border-[#1e293b]/70 font-mono px-2 py-0.5 rounded-md">
              {keywords.length} keywords
            </span>
          </div>
          <p className="text-[#8a9bb5] text-xs max-w-2xl mt-1 leading-relaxed">
            Từ điển khẩn cấp lâm sàng — quyết định triệt tiêu gợi ý thuốc khi phát hiện triệu chứng nguy hiểm.
          </p>
        </div>
        <div className="flex gap-2 shrink-0">
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={load}
            className="px-3 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 bg-[#111926]/40 hover:bg-[#111926] border border-[#1e293b]/60 rounded-xl transition duration-200 flex items-center gap-1.5 cursor-pointer"
          >
            <RefreshCw className="w-3.5 h-3.5" /> Tải lại
          </motion.button>
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => setShowAdd(v => !v)}
            className="px-3.5 py-2 text-xs font-bold text-emerald-400 bg-emerald-950/20 hover:bg-emerald-950/40 border border-emerald-900/35 hover:border-emerald-900/50 rounded-xl transition duration-200 flex items-center gap-1.5 cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" /> Thêm từ khóa
          </motion.button>
        </div>
      </div>

      {/* Add Form with slide down */}
      <AnimatePresence>
        {showAdd && (
          <motion.div
            initial={{ opacity: 0, height: 0, y: -10 }}
            animate={{ opacity: 1, height: 'auto', y: 0 }}
            exit={{ opacity: 0, height: 0, y: -10 }}
            className="overflow-hidden"
          >
            <form onSubmit={handleCreate} className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl p-5 space-y-4 shadow-lg">
              <div className="flex items-center justify-between border-b border-[#1e293b]/40 pb-2">
                <p className="text-xs font-bold text-slate-350 uppercase tracking-widest font-mono">Thêm từ khóa mới</p>
                <button type="button" onClick={() => setShowAdd(false)} className="text-slate-500 hover:text-slate-300">
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Từ khóa *</label>
                  <input
                    required
                    value={form.keyword}
                    onChange={e => setForm(v => ({ ...v, keyword: e.target.value }))}
                    placeholder="vd: đột quỵ, nhồi máu cơ tim..."
                    className="w-full bg-[#111926]/40 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50 placeholder:text-slate-650"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Nhóm khẩn cấp *</label>
                  <select
                    value={form.groupId}
                    onChange={e => {
                      const opt = GROUP_OPTIONS.find(g => g.value === e.target.value);
                      setForm(v => ({ ...v, groupId: e.target.value, groupLabel: opt?.label || '' }));
                    }}
                    className="w-full bg-[#111926]/45 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-250 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50"
                  >
                    {GROUP_OPTIONS.filter(g => g.value).map(g => (
                      <option key={g.value} value={g.value} className="bg-[#0d1520]">{g.label}</option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Tài liệu tham chiếu (Guideline ref)</label>
                  <input
                    value={form.guidelineRef}
                    onChange={e => setForm(v => ({ ...v, guidelineRef: e.target.value }))}
                    placeholder="vd: WHO-2023-STROKE"
                    className="w-full bg-[#111926]/40 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50 placeholder:text-slate-650"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Ghi chú thay đổi</label>
                  <input
                    value={form.changeNote}
                    onChange={e => setForm(v => ({ ...v, changeNote: e.target.value }))}
                    placeholder="Lý do bổ sung từ khóa..."
                    className="w-full bg-[#111926]/40 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50 placeholder:text-slate-650"
                  />
                </div>
              </div>

              <div className="flex gap-2 justify-end border-t border-[#1e293b]/30 pt-3">
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  type="button"
                  onClick={() => setShowAdd(false)}
                  className="px-4 py-2 text-xs font-bold text-slate-400 hover:text-slate-200 bg-[#111926]/40 border border-[#1e293b]/60 rounded-xl transition duration-200 cursor-pointer"
                >
                  Hủy
                </motion.button>
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  type="submit"
                  className="px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 border border-emerald-500/25 rounded-xl transition duration-200 cursor-pointer"
                >
                  Tạo từ khóa
                </motion.button>
              </div>
            </form>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Filters & Search */}
      <div className="flex flex-col md:flex-row gap-3 items-center">
        <div className="relative w-full md:max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-650" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Tìm từ khóa..."
            className="w-full bg-[#0d1520] border border-[#1e293b]/60 rounded-xl pl-9 pr-3.5 py-2 text-xs text-slate-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50 placeholder:text-slate-650"
          />
        </div>
        
        <select
          value={filterGroup}
          onChange={e => setFilterGroup(e.target.value)}
          className="w-full md:w-auto bg-[#0d1520] border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-400 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30"
        >
          {GROUP_OPTIONS.map(g => (
            <option key={g.value} value={g.value} className="bg-[#0d1520]">{g.label}</option>
          ))}
        </select>
        
        <select
          value={filterActive}
          onChange={e => setFilterActive(e.target.value as "all" | "active" | "inactive")}
          className="w-full md:w-auto bg-[#0d1520] border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-400 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30"
        >
          <option value="all" className="bg-[#0d1520]">Tất cả trạng thái</option>
          <option value="active" className="bg-[#0d1520]">Đang hoạt động</option>
          <option value="inactive" className="bg-[#0d1520]">Đã tắt</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl overflow-hidden shadow-xl">
        {isLoading ? (
          <div className="p-8 space-y-2">
            {[1, 2, 3, 4, 5].map(i => (
              <div key={i} className="h-12 bg-[#111926]/40 border border-[#1e293b]/30 rounded-xl animate-pulse" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="py-12 text-center text-slate-500 text-xs font-mono">Không tìm thấy từ khóa phù hợp.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="text-[10px] font-bold text-slate-500 uppercase tracking-widest border-b border-[#1e293b]/45 text-left">
                  <th className="px-5 py-3.5 font-mono">Từ khóa</th>
                  <th className="px-5 py-3.5 font-mono">Nhóm</th>
                  <th className="px-5 py-3.5 font-mono">Guideline</th>
                  <th className="px-5 py-3.5 font-mono">Trạng thái</th>
                  <th className="px-5 py-3.5 font-mono">Ghi chú</th>
                  <th className="px-5 py-3.5 text-right font-mono">Trực quan</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1e293b]/40">
                {filtered.map(kw => (
                  <tr key={kw.id} className="hover:bg-[#111926]/40 transition-colors">
                    <td className="px-5 py-3.5">
                      <span className="font-semibold text-slate-200 font-mono text-xs">{kw.keyword}</span>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="text-slate-400 font-medium">{kw.groupLabel}</span>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="text-slate-650 font-mono">{kw.guidelineRef || '—'}</span>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className={kw.isActive ? STATUS_BADGE.active : STATUS_BADGE.inactive}>
                        {kw.isActive ? 'ACTIVE' : 'INACTIVE'}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="text-slate-500 truncate max-w-[180px] block" title={kw.changeNote || undefined}>
                        {kw.changeNote || '—'}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex justify-end">
                        {/* Custom Animated Spring Toggle Switch */}
                        <button
                          type="button"
                          onClick={() => handleToggle(kw)}
                          disabled={processing === kw.id}
                          className={`w-9 h-5.5 flex items-center rounded-full p-1 cursor-pointer transition-all duration-300 disabled:opacity-40 focus:outline-none ${
                            kw.isActive
                              ? 'bg-emerald-500/20 border border-emerald-500/40 shadow-[0_0_8px_rgba(16,185,129,0.15)]'
                              : 'bg-slate-900/60 border border-[#1e293b]/70'
                          }`}
                          title={kw.isActive ? 'Tắt từ khóa' : 'Bật từ khóa'}
                        >
                          <motion.div
                            layout
                            transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                            className={`w-3.5 h-3.5 rounded-full shadow-md ${
                              kw.isActive ? 'bg-emerald-450' : 'bg-slate-500'
                            }`}
                            style={{
                              marginLeft: kw.isActive ? 'auto' : '0px',
                              marginRight: kw.isActive ? '0px' : 'auto'
                            }}
                          />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </motion.div>
  );
}

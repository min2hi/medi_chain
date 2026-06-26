'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AdminApi, ComboRule } from '@/services/admin.service';
import { DatabaseZap, Plus, RefreshCw, ChevronRight, CheckCircle, X } from 'lucide-react';

export default function ComboRulesPage() {
  const [combos, setCombos] = useState<ComboRule[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [processing, setProcessing] = useState<number | null>(null);
  const [expanded, setExpanded] = useState<number | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [toast, setToast] = useState('');
  const [form, setForm] = useState({
    name: '', label: '', symptomGroupsRaw: '', minMatch: '2', guidelineRef: '', changeNote: '',
  });

  const load = async () => {
    setIsLoading(true);
    try {
      const res = await AdminApi.listCombos();
      if (res.success) setCombos((res.data as ComboRule[]) || []);
    } finally { setIsLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3500); };

  const handleActivate = async (combo: ComboRule) => {
    if (combo.isActive) return;
    if (!confirm(`Kích hoạt combo rule "${combo.label}"?`)) return;
    setProcessing(combo.id);
    try {
      const res = await AdminApi.activateCombo(combo.id);
      if (res.success) { showToast(`Đã kích hoạt combo rule "${combo.label}"`); load(); }
    } finally { setProcessing(null); }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    const groups = form.symptomGroupsRaw.split(',').map(s => s.trim()).filter(Boolean);
    if (!form.name || !form.label || groups.length === 0) return;
    const res = await AdminApi.createCombo({
      name: form.name.trim(),
      label: form.label.trim(),
      symptomGroups: groups,
      minMatch: parseInt(form.minMatch) || 2,
      guidelineRef: form.guidelineRef || undefined,
      changeNote: form.changeNote || undefined,
    });
    if (res.success) {
      showToast(`Đã tạo combo "${form.label}" thành công`);
      setForm({ name: '', label: '', symptomGroupsRaw: '', minMatch: '2', guidelineRef: '', changeNote: '' });
      setShowAdd(false);
      load();
    }
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
              <DatabaseZap className="w-5 h-5 text-emerald-400" />
            </div>
            <h1 className="text-xl font-bold text-white tracking-tight">Combo Rules</h1>
            <span className="text-[10px] text-slate-400 bg-[#111926]/60 border border-[#1e293b]/70 font-mono px-2 py-0.5 rounded-md">
              {combos.length} rules
            </span>
          </div>
          <p className="text-[#8a9bb5] text-xs max-w-2xl mt-1 leading-relaxed">
            Luật tổ hợp triệu chứng — kết hợp nhiều nhóm triệu chứng/bệnh để phát hiện các ca bệnh phức tạp có nguy cơ cao.
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
            <Plus className="w-3.5 h-3.5" /> Thêm Combo
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
                <p className="text-xs font-bold text-slate-350 uppercase tracking-widest font-mono">Tạo Combo Rule mới</p>
                <button type="button" onClick={() => setShowAdd(false)} className="text-slate-500 hover:text-slate-300">
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Machine name *</label>
                  <input
                    required
                    value={form.name}
                    onChange={e => setForm(v => ({ ...v, name: e.target.value }))}
                    placeholder="vd: DENGUE_FEVER_COMBO"
                    className="w-full bg-[#111926]/40 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50 placeholder:text-slate-650 font-mono"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Nhãn hiển thị *</label>
                  <input
                    required
                    value={form.label}
                    onChange={e => setForm(v => ({ ...v, label: e.target.value }))}
                    placeholder="vd: Sốt xuất huyết Dengue"
                    className="w-full bg-[#111926]/40 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50 placeholder:text-slate-650"
                  />
                </div>

                <div className="col-span-1 md:col-span-2 flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">
                    Các nhóm triệu chứng * <span className="text-[10px] text-slate-600 font-mono">(phân cách bởi dấu phẩy, vd: acs, shock, sepsis)</span>
                  </label>
                  <input
                    required
                    value={form.symptomGroupsRaw}
                    onChange={e => setForm(v => ({ ...v, symptomGroupsRaw: e.target.value }))}
                    placeholder="vd: acs, shock, sepsis"
                    className="w-full bg-[#111926]/40 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50 placeholder:text-slate-650 font-mono"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Số nhóm khớp tối thiểu (minMatch)</label>
                  <input
                    type="number"
                    min="1"
                    value={form.minMatch}
                    onChange={e => setForm(v => ({ ...v, minMatch: e.target.value }))}
                    className="w-full bg-[#111926]/45 border border-[#1e293b]/60 rounded-xl px-3.5 py-2 text-xs text-slate-250 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 focus:border-emerald-500/50"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-slate-400">Tài liệu tham chiếu (Guideline ref)</label>
                  <input
                    value={form.guidelineRef}
                    onChange={e => setForm(v => ({ ...v, guidelineRef: e.target.value }))}
                    placeholder="vd: MOH-DENGUE-2023"
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
                  Tạo Combo
                </motion.button>
              </div>
            </form>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Cards List */}
      {isLoading ? (
        <div className="space-y-3">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-16 bg-[#111926]/40 border border-[#1e293b]/30 rounded-xl animate-pulse" />
          ))}
        </div>
      ) : combos.length === 0 ? (
        <div className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl p-12 text-center flex flex-col items-center justify-center">
          <p className="text-slate-500 text-xs font-mono">Chưa có combo rule nào. Tạo luật đầu tiên để phân tích các tổ hợp triệu chứng.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {combos.map(combo => (
            <div key={combo.id} className="bg-[#0d1520] border border-[#1e293b]/60 rounded-xl overflow-hidden shadow-md">
              <div
                className="flex items-center gap-3 px-5 py-4 cursor-pointer hover:bg-[#111926]/30 transition duration-150"
                onClick={() => setExpanded(expanded === combo.id ? null : combo.id)}
              >
                <motion.div
                  animate={{ rotate: expanded === combo.id ? 90 : 0 }}
                  transition={{ type: 'spring', stiffness: 200, damping: 18 }}
                  className="shrink-0 text-slate-500"
                >
                  <ChevronRight className="w-4 h-4" />
                </motion.div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold text-slate-200 tracking-tight">{combo.label}</span>
                    <span className={`text-[9px] font-mono font-semibold px-2 py-0.5 rounded-md ${
                      combo.isActive
                        ? 'bg-emerald-950/45 text-emerald-400 border border-emerald-900/50'
                        : 'bg-slate-900/60 text-slate-500 border border-[#1e293b]/70'
                    }`}>
                      {combo.isActive ? 'ACTIVE' : 'INACTIVE'}
                    </span>
                  </div>
                  <div className="text-[10px] text-slate-500 font-mono mt-1">{combo.name}</div>
                </div>

                <div className="text-[10px] text-slate-400 font-semibold font-mono bg-[#111926]/40 border border-[#1e293b]/30 px-2.5 py-1 rounded-lg shrink-0">
                  Khớp ≥ {combo.minMatch} nhóm
                </div>

                <motion.button
                  whileHover={combo.isActive ? {} : { scale: 1.02 }}
                  whileTap={combo.isActive ? {} : { scale: 0.98 }}
                  onClick={e => { e.stopPropagation(); handleActivate(combo); }}
                  disabled={combo.isActive || processing === combo.id}
                  className={`px-3 py-1.5 text-xs font-bold rounded-xl transition duration-150 ml-2 shrink-0 cursor-pointer ${
                    combo.isActive
                      ? 'text-slate-600 bg-slate-950/20 border border-slate-900/30 cursor-not-allowed select-none'
                      : 'text-emerald-400 bg-emerald-955/20 hover:bg-emerald-955/40 border border-emerald-900/30 hover:border-emerald-900/55'
                  }`}
                >
                  {combo.isActive ? 'Đang active' : 'Kích hoạt'}
                </motion.button>
              </div>

              {/* Collapsible Content with AnimatePresence */}
              <AnimatePresence initial={false}>
                {expanded === combo.id && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.25, ease: 'easeInOut' }}
                    className="overflow-hidden"
                  >
                    <div className="border-t border-[#1e293b]/50 bg-[#111926]/20 px-5 py-4 space-y-3.5">
                      <div>
                        <p className="text-[9px] text-slate-500 uppercase tracking-widest font-mono font-bold mb-1.5">Các nhóm triệu chứng</p>
                        <div className="flex flex-wrap gap-1.5">
                          {combo.symptomGroups.map((g: string) => (
                            <span key={g} className="text-xs font-mono text-slate-300 bg-slate-900/80 border border-[#1e293b]/85 px-2.5 py-0.5 rounded-lg">
                              {g}
                            </span>
                          ))}
                        </div>
                      </div>
                      
                      {combo.guidelineRef && (
                        <div className="flex items-center gap-1.5 text-xs text-slate-400">
                          <span className="text-[9px] text-slate-500 uppercase tracking-widest font-mono font-bold">Guideline:</span>
                          <span className="font-mono text-slate-300 bg-slate-900/50 px-2 py-0.5 rounded border border-[#1e293b]/30">{combo.guidelineRef}</span>
                        </div>
                      )}

                      {combo.changeNote && (
                        <div className="text-xs text-slate-400">
                          <span className="text-[9px] text-slate-500 uppercase tracking-widest font-mono font-bold block mb-1">Ghi chú</span>
                          <span className="text-slate-350">{combo.changeNote}</span>
                        </div>
                      )}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          ))}
        </div>
      )}
    </motion.div>
  );
}

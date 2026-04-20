'use client';

import React, { useEffect, useState } from 'react';
import { AdminApi, ComboRule } from '@/services/admin.service';
import { DatabaseZap, Plus, RefreshCw, ChevronDown, ChevronRight } from 'lucide-react';

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

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000); };

  const handleActivate = async (combo: ComboRule) => {
    if (combo.isActive) return;
    if (!confirm(`Kích hoạt combo rule "${combo.label}"?`)) return;
    setProcessing(combo.id);
    try {
      const res = await AdminApi.activateCombo(combo.id);
      if (res.success) { showToast(`✓ Đã kích hoạt: ${combo.label}`); load(); }
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
      showToast(`✓ Đã tạo combo "${form.label}" (cần kích hoạt để có hiệu lực)`);
      setForm({ name: '', label: '', symptomGroupsRaw: '', minMatch: '2', guidelineRef: '', changeNote: '' });
      setShowAdd(false);
      load();
    }
  };

  return (
    <div className="space-y-5">
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-slate-800 border border-slate-700 text-slate-200 text-xs px-4 py-2.5 rounded-lg shadow-xl">{toast}</div>
      )}

      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <DatabaseZap className="w-5 h-5 text-slate-400" />
            <h1 className="text-lg font-bold text-white">Combo Rules</h1>
            <span className="text-xs text-slate-500 bg-slate-800 border border-slate-700 px-2 py-0.5 rounded">{combos.length} luật</span>
          </div>
          <p className="text-slate-500 text-sm">Luật tổ hợp triệu chứng — kết hợp nhiều nhóm để phát hiện bệnh phức tạp.</p>
        </div>
        <div className="flex gap-2">
          <button onClick={load} className="px-3 py-1.5 text-xs text-slate-400 hover:text-slate-200 bg-slate-800 border border-slate-700 rounded-lg flex items-center gap-1.5">
            <RefreshCw className="w-3.5 h-3.5" /> Tải lại
          </button>
          <button onClick={() => setShowAdd(v => !v)} className="px-3 py-1.5 text-xs text-white bg-blue-600 hover:bg-blue-700 rounded-lg flex items-center gap-1.5">
            <Plus className="w-3.5 h-3.5" /> Thêm Combo
          </button>
        </div>
      </div>

      {/* Add Form */}
      {showAdd && (
        <form onSubmit={handleCreate} className="bg-slate-900 border border-slate-700 rounded-xl p-4 space-y-3">
          <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Tạo Combo Rule mới</p>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Machine name *</label>
              <input required value={form.name} onChange={e => setForm(v => ({ ...v, name: e.target.value }))}
                placeholder="vd: DENGUE_FEVER_COMBO"
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500 font-mono" />
            </div>
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Nhãn hiển thị *</label>
              <input required value={form.label} onChange={e => setForm(v => ({ ...v, label: e.target.value }))}
                placeholder="vd: Sốt xuất huyết Dengue"
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500" />
            </div>
            <div className="col-span-2">
              <label className="text-xs text-slate-500 mb-1 block">Các nhóm triệu chứng * <span className="text-slate-700">(phân cách bởi dấu phẩy)</span></label>
              <input required value={form.symptomGroupsRaw} onChange={e => setForm(v => ({ ...v, symptomGroupsRaw: e.target.value }))}
                placeholder="vd: acs, shock, sepsis"
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500 font-mono" />
            </div>
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Số nhóm khớp tối thiểu</label>
              <input type="number" min="1" value={form.minMatch} onChange={e => setForm(v => ({ ...v, minMatch: e.target.value }))}
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500" />
            </div>
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Guideline ref</label>
              <input value={form.guidelineRef} onChange={e => setForm(v => ({ ...v, guidelineRef: e.target.value }))}
                placeholder="vd: MOH-DENGUE-2023"
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500" />
            </div>
          </div>
          <div className="flex gap-2 justify-end">
            <button type="button" onClick={() => setShowAdd(false)} className="px-4 py-1.5 text-xs text-slate-400 bg-slate-800 border border-slate-700 rounded-lg hover:bg-slate-700">Hủy</button>
            <button type="submit" className="px-4 py-1.5 text-xs text-white bg-blue-600 hover:bg-blue-700 rounded-lg">Tạo Combo</button>
          </div>
        </form>
      )}

      {/* Cards */}
      {isLoading ? (
        <div className="space-y-2">{[1,2,3].map(i => <div key={i} className="h-16 bg-slate-900 border border-slate-800 rounded-xl animate-pulse" />)}</div>
      ) : combos.length === 0 ? (
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-10 text-center text-slate-600 text-sm">Chưa có combo rule nào. Tạo combo đầu tiên để phát hiện bệnh phức tạp.</div>
      ) : (
        <div className="space-y-2">
          {combos.map(combo => (
            <div key={combo.id} className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
              <div
                className="flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-slate-800/40 transition"
                onClick={() => setExpanded(expanded === combo.id ? null : combo.id)}
              >
                {expanded === combo.id ? <ChevronDown className="w-4 h-4 text-slate-500 shrink-0" /> : <ChevronRight className="w-4 h-4 text-slate-500 shrink-0" />}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-slate-200">{combo.label}</span>
                    <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${combo.isActive ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/20' : 'bg-slate-700/50 text-slate-500 border border-slate-700'}`}>
                      {combo.isActive ? 'ACTIVE' : 'INACTIVE'}
                    </span>
                  </div>
                  <div className="text-[10px] text-slate-600 font-mono mt-0.5">{combo.name}</div>
                </div>
                <div className="text-xs text-slate-600 shrink-0">Khớp ≥ {combo.minMatch} nhóm</div>
                <button
                  onClick={e => { e.stopPropagation(); handleActivate(combo); }}
                  disabled={combo.isActive || processing === combo.id}
                  className={`px-3 py-1 text-xs rounded-lg transition ml-2 shrink-0 ${combo.isActive ? 'text-slate-700 cursor-not-allowed' : 'text-blue-400 border border-blue-500/30 hover:bg-blue-500/10'}`}
                >
                  {combo.isActive ? 'Đang active' : 'Kích hoạt'}
                </button>
              </div>
              {expanded === combo.id && (
                <div className="border-t border-slate-800 px-4 py-3 space-y-2">
                  <div>
                    <p className="text-[10px] text-slate-600 uppercase tracking-wider mb-1">Các nhóm triệu chứng</p>
                    <div className="flex flex-wrap gap-1.5">
                      {combo.symptomGroups.map((g: string) => (
                        <span key={g} className="text-xs font-mono text-slate-400 bg-slate-800 border border-slate-700 px-2 py-0.5 rounded">{g}</span>
                      ))}
                    </div>
                  </div>
                  {combo.guidelineRef && (
                    <div><span className="text-[10px] text-slate-600 uppercase tracking-wider">Guideline: </span><span className="text-xs text-slate-500 font-mono">{combo.guidelineRef}</span></div>
                  )}
                  {combo.changeNote && (
                    <div><span className="text-[10px] text-slate-600 uppercase tracking-wider">Ghi chú: </span><span className="text-xs text-slate-500">{combo.changeNote}</span></div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

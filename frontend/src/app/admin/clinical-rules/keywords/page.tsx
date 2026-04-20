'use client';

import React, { useEffect, useState } from 'react';
import { AdminApi, SafetyKeyword } from '@/services/admin.service';
import { BookType, Plus, ToggleLeft, ToggleRight, RefreshCw, Search } from 'lucide-react';

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
  active:   'bg-emerald-500/15 text-emerald-400 border border-emerald-500/20',
  inactive: 'bg-slate-700/50 text-slate-500 border border-slate-700',
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
    setTimeout(() => setToast(''), 3000);
  };

  const handleToggle = async (kw: SafetyKeyword) => {
    if (!confirm(`${kw.isActive ? 'Tắt' : 'Bật'} từ khóa "${kw.keyword}"?`)) return;
    setProcessing(kw.id);
    try {
      const res = kw.isActive
        ? await AdminApi.deactivateKeyword(kw.id, 'Deactivated via Admin UI')
        : await AdminApi.activateKeyword(kw.id);
      if (res.success) { showToast(`✓ ${kw.isActive ? 'Đã tắt' : 'Đã bật'}: ${kw.keyword}`); load(); }
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
      showToast(`✓ Đã tạo "${form.keyword}" (chưa active, cần bật thủ công)`);
      setForm({ keyword: '', groupId: 'L1_CRITICAL', groupLabel: 'Khẩn cấp tuyệt đối', guidelineRef: '', changeNote: '' });
      setShowAdd(false);
      load();
    }
  };

  const filtered = keywords.filter(k =>
    k.keyword.toLowerCase().includes(search.toLowerCase()) ||
    k.groupLabel.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-5">
      {/* Toast */}
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-slate-800 border border-slate-700 text-slate-200 text-xs px-4 py-2.5 rounded-lg shadow-xl">
          {toast}
        </div>
      )}

      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <BookType className="w-5 h-5 text-slate-400" />
            <h1 className="text-lg font-bold text-white">Safety Keywords</h1>
            <span className="text-xs text-slate-500 bg-slate-800 border border-slate-700 px-2 py-0.5 rounded">
              {keywords.length} từ khóa
            </span>
          </div>
          <p className="text-slate-500 text-sm">Từ điển khẩn cấp lâm sàng — quyết định triệt tiêu gợi ý thuốc nguy hiểm.</p>
        </div>
        <div className="flex gap-2">
          <button onClick={load} className="px-3 py-1.5 text-xs text-slate-400 hover:text-slate-200 bg-slate-800 border border-slate-700 rounded-lg transition flex items-center gap-1.5">
            <RefreshCw className="w-3.5 h-3.5" /> Tải lại
          </button>
          <button onClick={() => setShowAdd(v => !v)} className="px-3 py-1.5 text-xs text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition flex items-center gap-1.5">
            <Plus className="w-3.5 h-3.5" /> Thêm từ khóa
          </button>
        </div>
      </div>

      {/* Add Form */}
      {showAdd && (
        <form onSubmit={handleCreate} className="bg-slate-900 border border-slate-700 rounded-xl p-4 space-y-3">
          <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Thêm từ khóa mới</p>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Từ khóa *</label>
              <input
                required value={form.keyword} onChange={e => setForm(v => ({ ...v, keyword: e.target.value }))}
                placeholder="vd: đột quỵ, nhồi máu..."
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Nhóm khẩn cấp *</label>
              <select
                value={form.groupId}
                onChange={e => {
                  const opt = GROUP_OPTIONS.find(g => g.value === e.target.value);
                  setForm(v => ({ ...v, groupId: e.target.value, groupLabel: opt?.label || '' }));
                }}
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500"
              >
                {GROUP_OPTIONS.filter(g => g.value).map(g => (
                  <option key={g.value} value={g.value}>{g.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Guideline ref</label>
              <input
                value={form.guidelineRef} onChange={e => setForm(v => ({ ...v, guidelineRef: e.target.value }))}
                placeholder="vd: WHO-2023-STROKE"
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="text-xs text-slate-500 mb-1 block">Ghi chú</label>
              <input
                value={form.changeNote} onChange={e => setForm(v => ({ ...v, changeNote: e.target.value }))}
                placeholder="Lý do thêm..."
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>
          <div className="flex gap-2 justify-end">
            <button type="button" onClick={() => setShowAdd(false)} className="px-4 py-1.5 text-xs text-slate-400 bg-slate-800 border border-slate-700 rounded-lg hover:bg-slate-700 transition">Hủy</button>
            <button type="submit" className="px-4 py-1.5 text-xs text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition">Tạo từ khóa</button>
          </div>
        </form>
      )}

      {/* Filters */}
      <div className="flex gap-3 items-center">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-600" />
          <input
            value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Tìm từ khóa..."
            className="w-full bg-slate-900 border border-slate-800 rounded-lg pl-8 pr-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-slate-600 placeholder:text-slate-700"
          />
        </div>
        <select value={filterGroup} onChange={e => setFilterGroup(e.target.value)}
          className="bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-xs text-slate-400 focus:outline-none">
          {GROUP_OPTIONS.map(g => <option key={g.value} value={g.value}>{g.label}</option>)}
        </select>
        <select value={filterActive} onChange={e => setFilterActive(e.target.value as "all" | "active" | "inactive")}
          className="bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-xs text-slate-400 focus:outline-none">
          <option value="all">Tất cả trạng thái</option>
          <option value="active">Đang hoạt động</option>
          <option value="inactive">Đã tắt</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        {isLoading ? (
          <div className="p-8 space-y-2">
            {[1,2,3,4,5].map(i => <div key={i} className="h-10 bg-slate-800 rounded animate-pulse" />)}
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-10 text-center text-slate-600 text-sm">Không tìm thấy từ khóa nào.</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="text-[10px] font-bold text-slate-600 uppercase tracking-wider border-b border-slate-800">
                <th className="text-left px-4 py-3">Từ khóa</th>
                <th className="text-left px-4 py-3">Nhóm</th>
                <th className="text-left px-4 py-3">Guideline</th>
                <th className="text-left px-4 py-3">Trạng thái</th>
                <th className="text-left px-4 py-3">Ghi chú</th>
                <th className="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {filtered.map(kw => (
                <tr key={kw.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-4 py-3">
                    <span className="font-medium text-slate-200 font-mono text-xs">{kw.keyword}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-xs text-slate-400">{kw.groupLabel}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-xs text-slate-600 font-mono">{kw.guidelineRef || '—'}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${kw.isActive ? STATUS_BADGE.active : STATUS_BADGE.inactive}`}>
                      {kw.isActive ? 'ACTIVE' : 'INACTIVE'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-xs text-slate-600 truncate max-w-[160px] block">{kw.changeNote || '—'}</span>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => handleToggle(kw)}
                      disabled={processing === kw.id}
                      className="text-slate-500 hover:text-slate-200 transition disabled:opacity-40"
                      title={kw.isActive ? 'Tắt' : 'Bật'}
                    >
                      {kw.isActive
                        ? <ToggleRight className="w-5 h-5 text-emerald-500" />
                        : <ToggleLeft className="w-5 h-5" />}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

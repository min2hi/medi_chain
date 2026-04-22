'use client';

import { useState, useEffect, useCallback } from 'react';
import { Search, Users, ShieldCheck, UserCheck, UserX, ChevronLeft, ChevronRight } from 'lucide-react';
import { AdminApi, AdminUser } from '@/services/admin.service';

const ROLE_CONFIG = {
  ADMIN:  { label: 'ADMIN',  color: 'bg-blue-500/15 text-blue-400 border border-blue-500/25' },
  DOCTOR: { label: 'DOCTOR', color: 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/25' },
  USER:   { label: 'USER',   color: 'bg-slate-700/60 text-slate-400 border border-slate-600/30' },
} as const;

export default function UsersPage() {
  const [users, setUsers]         = useState<AdminUser[]>([]);
  const [total, setTotal]         = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [page, setPage]           = useState(1);
  const [search, setSearch]       = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError]         = useState<string | null>(null);
  const [updating, setUpdating]   = useState<string | null>(null);
  const [toast, setToast]         = useState<string | null>(null);

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await AdminApi.listUsers({ search, role: roleFilter, page, limit: 15 });
      if (res.success && res.data) {
        setUsers(res.data.users);
        setTotal(res.data.pagination.total);
        setTotalPages(res.data.pagination.totalPages);
      }
    } catch {
      setError('Không thể tải danh sách người dùng');
    } finally {
      setIsLoading(false);
    }
  }, [search, roleFilter, page]);

  useEffect(() => { void load(); }, [load]);

  const handleRoleChange = async (user: AdminUser, newRole: 'USER' | 'DOCTOR') => {
    setUpdating(user.id);
    try {
      const res = await AdminApi.updateUserRole(user.id, newRole);
      if (res.success) {
        setUsers(prev => prev.map(u => u.id === user.id ? { ...u, role: newRole } : u));
        setToast(`Đã cập nhật ${user.name} → ${newRole}`);
        setTimeout(() => setToast(null), 3000);
      } else {
        setError(res.message ?? 'Lỗi cập nhật role');
      }
    } catch {
      setError('Lỗi kết nối');
    } finally {
      setUpdating(null);
    }
  };

  return (
    <div className="space-y-5">

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Users className="w-5 h-5 text-slate-400" />
            <h1 className="text-base font-semibold text-white">Quản lý người dùng</h1>
            <span className="text-[11px] bg-slate-800 text-slate-400 border border-slate-700 px-2 py-0.5 rounded-full">
              {total} tài khoản
            </span>
          </div>
          <p className="text-xs text-slate-500">
            Phân quyền tài khoản — chỉ ADMIN mới có thể thay đổi role.
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-3">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-500" />
          <input
            type="text"
            placeholder="Tìm tên, email..."
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
            className="w-full bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-md pl-8 pr-3 py-2 focus:outline-none focus:border-slate-600"
          />
        </div>
        <select
          value={roleFilter}
          onChange={e => { setRoleFilter(e.target.value); setPage(1); }}
          className="bg-slate-900 border border-slate-800 text-slate-300 text-xs rounded-md px-3 py-2 focus:outline-none focus:border-slate-600"
        >
          <option value="">Tất cả roles</option>
          <option value="ADMIN">ADMIN</option>
          <option value="DOCTOR">DOCTOR</option>
          <option value="USER">USER</option>
        </select>
      </div>

      {/* Toast */}
      {toast && (
        <div className="flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2.5 rounded-lg">
          <ShieldCheck className="w-3.5 h-3.5 shrink-0" />
          {toast}
        </div>
      )}

      {error && (
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs px-4 py-2.5 rounded-lg">
          {error}
        </div>
      )}

      {/* Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center py-16 gap-2 text-slate-500 text-xs">
            <div className="w-4 h-4 border-2 border-slate-700 border-t-blue-400 rounded-full animate-spin" />
            Đang tải...
          </div>
        ) : users.length === 0 ? (
          <div className="text-center py-16 text-slate-600 text-xs">Không tìm thấy người dùng nào.</div>
        ) : (
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-slate-800">
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Người dùng</th>
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Email</th>
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Role hiện tại</th>
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Ngày tham gia</th>
                <th className="text-right px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {users.map(user => {
                const cfg = ROLE_CONFIG[user.role];
                return (
                  <tr key={user.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-4 py-3">
                      <div className="font-medium text-slate-200">{user.name}</div>
                    </td>
                    <td className="px-4 py-3 text-slate-500 font-mono text-[11px]">{user.email}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${cfg.color}`}>
                        {cfg.label}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {new Date(user.createdAt).toLocaleDateString('vi-VN')}
                    </td>
                    <td className="px-4 py-3">
                      {user.role === 'ADMIN' ? (
                        <span className="text-slate-700 text-[11px] text-right block">Không thể thay đổi</span>
                      ) : (
                        <div className="flex items-center justify-end gap-2">
                          {user.role === 'USER' ? (
                            <button
                              onClick={() => handleRoleChange(user, 'DOCTOR')}
                              disabled={updating === user.id}
                              className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/25 text-emerald-400 rounded-md transition text-[11px] disabled:opacity-50 disabled:cursor-wait"
                            >
                              <UserCheck className="w-3 h-3" />
                              {updating === user.id ? 'Đang cập nhật...' : 'Cấp quyền Doctor'}
                            </button>
                          ) : (
                            <button
                              onClick={() => handleRoleChange(user, 'USER')}
                              disabled={updating === user.id}
                              className="flex items-center gap-1.5 px-3 py-1.5 bg-amber-500/10 hover:bg-amber-500/20 border border-amber-500/25 text-amber-400 rounded-md transition text-[11px] disabled:opacity-50 disabled:cursor-wait"
                            >
                              <UserX className="w-3 h-3" />
                              {updating === user.id ? 'Đang cập nhật...' : 'Thu hồi Doctor'}
                            </button>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between text-xs text-slate-500">
          <span>Trang {page} / {totalPages} · {total} người dùng</span>
          <div className="flex gap-2">
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              className="p-1.5 rounded border border-slate-800 hover:border-slate-700 disabled:opacity-30 transition"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="p-1.5 rounded border border-slate-800 hover:border-slate-700 disabled:opacity-30 transition"
            >
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

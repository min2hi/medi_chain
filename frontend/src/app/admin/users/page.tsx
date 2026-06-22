'use client';

import { useState, useEffect, useCallback } from 'react';
import { Search, Users, ShieldCheck, ShieldAlert, UserCheck, UserX, ChevronLeft, ChevronRight, UserPlus } from 'lucide-react';
import { AdminApi, AdminUser } from '@/services/admin.service';
import { StaffApi } from '@/services/staff.service';

const ROLE_CONFIG = {
  ADMIN:  { label: 'ADMIN',  color: 'bg-pink-500/15 text-pink-400 border border-pink-500/25' },
  DOCTOR: { label: 'DOCTOR', color: 'bg-blue-500/15 text-blue-400 border border-blue-500/25' },
  USER:   { label: 'USER',   color: 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/25' },
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

  const admins = users.filter(u => u.role === 'ADMIN');
  const doctors = users.filter(u => u.role === 'DOCTOR');
  const patients = users.filter(u => u.role === 'USER');

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

  const handleVerifyLicense = async (user: AdminUser) => {
    setUpdating(user.id);
    try {
      const res = await StaffApi.verifyDoctorLicense(user.id);
      if (res.success) {
        setUsers(prev => prev.map(u => {
          if (u.id === user.id) {
            const currentVerified = u.profile?.licenseVerified ?? false;
            return {
              ...u,
              profile: {
                ...u.profile,
                licenseVerified: !currentVerified,
              }
            };
          }
          return u;
        }));
        const action = !(user.profile?.licenseVerified) ? 'Xác thực' : 'Hủy xác thực';
        setToast(`Đã ${action} chứng chỉ cho Bác sĩ ${user.name}`);
        setTimeout(() => setToast(null), 3000);
      } else {
        setError(res.message ?? 'Lỗi cập nhật trạng thái xác thực');
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

      {/* Grouped User Cards */}
      {isLoading ? (
        <div className="bg-slate-900 border border-slate-800 rounded-xl flex items-center justify-center py-16 gap-2 text-slate-500 text-xs">
          <div className="w-4 h-4 border-2 border-slate-700 border-t-blue-400 rounded-full animate-spin" />
          Đang tải danh sách người dùng...
        </div>
      ) : users.length === 0 ? (
        <div className="bg-slate-900 border border-slate-800 rounded-xl text-center py-16 text-slate-600 text-xs">
          Không tìm thấy người dùng nào.
        </div>
      ) : (
        <div className="space-y-6">
          {/* Stats Bar */}
          <div className="flex flex-wrap items-center gap-x-5 gap-y-1.5 text-xs text-slate-400 bg-slate-900/60 border border-slate-800/80 px-4 py-3 rounded-lg">
            <span className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-pink-500" />
              <span className="font-semibold text-slate-200">{admins.length}</span> Admin
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-blue-500" />
              <span className="font-semibold text-slate-200">{doctors.length}</span> Bác sĩ
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              <span className="font-semibold text-slate-200">{patients.length}</span> Bệnh nhân
            </span>
          </div>

          {/* Section: QUẢN TRỊ */}
          {admins.length > 0 && (
            <div className="space-y-3">
              <h2 className="text-[10px] font-bold text-slate-500 uppercase tracking-widest flex items-center gap-1.5">
                Quản trị ({admins.length})
              </h2>
              <div className="flex flex-col gap-3">
                {admins.map(user => (
                  <div key={user.id} className="bg-slate-900 border border-slate-800/85 rounded-xl p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-l-4 border-l-pink-500 transition-all hover:bg-slate-900/80">
                    <div className="space-y-1">
                      <div className="font-semibold text-slate-200 text-sm flex items-center gap-2">
                        {user.name}
                      </div>
                      <div className="text-xs text-slate-400 font-mono">{user.email}</div>
                      <div className="text-[10px] text-slate-500">
                        Ngày tham gia: {new Date(user.createdAt).toLocaleDateString('vi-VN')}
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-3 self-end sm:self-auto">
                      <span className="bg-pink-500/10 text-pink-400 border border-pink-500/20 px-2.5 py-0.5 rounded text-[10px] font-semibold">
                        Admin
                      </span>
                      <span className="text-slate-500 text-[11px]">Không thể thay đổi</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Section: BÁC SĨ */}
          {doctors.length > 0 && (
            <div className="space-y-3">
              <h2 className="text-[10px] font-bold text-slate-500 uppercase tracking-widest flex items-center gap-1.5">
                Bác sĩ ({doctors.length})
              </h2>
              <div className="flex flex-col gap-3">
                {doctors.map(user => (
                  <div key={user.id} className="bg-slate-900 border border-slate-800/85 rounded-xl p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-l-4 border-l-blue-500 transition-all hover:bg-slate-900/80">
                    <div className="space-y-1.5 flex-1 min-w-0">
                      <div className="font-semibold text-slate-200 text-sm flex items-center gap-2">
                        {user.name}
                      </div>
                      <div className="text-xs text-slate-400 font-mono">{user.email}</div>
                      <div className="text-[11px] text-slate-400 flex flex-wrap gap-x-3 gap-y-0.5">
                        <span>Chuyên khoa: <span className="text-slate-300 font-medium">{user.profile?.specialty || 'Chưa cập nhật'}</span></span>
                        <span className="text-slate-650">•</span>
                        <span>Chứng chỉ: <span className="text-slate-300 font-medium font-mono">{user.profile?.licenseNumber || 'Chưa cập nhật'}</span></span>
                      </div>
                      <div className="text-[10px] text-slate-500">
                        Ngày tham gia: {new Date(user.createdAt).toLocaleDateString('vi-VN')}
                      </div>
                    </div>
                    
                    <div className="flex flex-wrap items-center gap-2.5 self-end sm:self-auto shrink-0">
                      <div className="flex items-center gap-2">
                        {user.profile?.licenseVerified ? (
                          <span className="flex items-center gap-1 text-[10px] text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 rounded font-medium">
                            <ShieldCheck className="w-3 h-3" />
                            Đã xác nhận
                          </span>
                        ) : (
                          <span className="flex items-center gap-1 text-[10px] text-amber-400 bg-amber-500/10 border border-amber-500/20 px-2 py-0.5 rounded font-medium">
                            <ShieldAlert className="w-3 h-3" />
                            Chưa xác thực
                          </span>
                        )}
                        <span className="bg-blue-500/10 text-blue-400 border border-blue-500/20 px-2.5 py-0.5 rounded text-[10px] font-semibold">
                          Bác sĩ
                        </span>
                      </div>

                      <div className="flex items-center gap-2 border-l border-slate-800 pl-2.5">
                        <button
                          onClick={() => handleVerifyLicense(user)}
                          disabled={updating === user.id}
                          className={`flex items-center gap-1 px-2.5 py-1 rounded border transition text-[11px] font-semibold disabled:opacity-50 disabled:cursor-wait ${
                            user.profile?.licenseVerified
                              ? 'bg-red-500/10 hover:bg-red-500/20 border-red-500/25 text-red-400'
                              : 'bg-emerald-500/10 hover:bg-emerald-500/20 border-emerald-500/25 text-emerald-400'
                          }`}
                        >
                          {updating === user.id ? '...' : user.profile?.licenseVerified ? 'Hủy xác thực' : 'Xác thực'}
                        </button>
                        <button
                          onClick={() => handleRoleChange(user, 'USER')}
                          disabled={updating === user.id}
                          className="flex items-center gap-1 px-2.5 py-1 bg-amber-500/10 hover:bg-amber-500/20 border border-amber-500/25 text-amber-400 rounded transition text-[11px] font-semibold disabled:opacity-50 disabled:cursor-wait"
                        >
                          <UserX className="w-3 h-3" />
                          {updating === user.id ? '...' : 'Thu hồi'}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Section: BỆNH NHÂN */}
          {patients.length > 0 && (
            <div className="space-y-3">
              <h2 className="text-[10px] font-bold text-slate-500 uppercase tracking-widest flex items-center gap-1.5">
                Bệnh nhân ({patients.length})
              </h2>
              <div className="flex flex-col gap-3">
                {patients.map(user => (
                  <div key={user.id} className="bg-slate-900 border border-slate-800/85 rounded-xl p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-l-4 border-l-emerald-500 transition-all hover:bg-slate-900/80">
                    <div className="space-y-1">
                      <div className="font-semibold text-slate-200 text-sm flex items-center gap-2">
                        {user.name}
                      </div>
                      <div className="text-xs text-slate-400 font-mono">{user.email}</div>
                      <div className="text-[10px] text-slate-500">
                        Ngày tham gia: {new Date(user.createdAt).toLocaleDateString('vi-VN')}
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-2.5 self-end sm:self-auto shrink-0">
                      <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2.5 py-0.5 rounded text-[10px] font-semibold">
                        Bệnh nhân
                      </span>
                      
                      <div className="flex items-center gap-2 border-l border-slate-800 pl-2.5">
                        <button
                          onClick={() => alert('Gán bác sĩ cho bệnh nhân (Mock Action)')}
                          className="flex items-center gap-1 px-2.5 py-1 bg-blue-500/10 hover:bg-blue-500/20 border border-blue-500/25 text-blue-400 rounded transition text-[11px] font-semibold"
                        >
                          <UserPlus className="w-3 h-3" />
                          Gán Bác sĩ
                        </button>
                        <button
                          onClick={() => handleRoleChange(user, 'DOCTOR')}
                          disabled={updating === user.id}
                          className="flex items-center gap-1 px-2.5 py-1 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/25 text-emerald-400 rounded transition text-[11px] font-semibold disabled:opacity-50 disabled:cursor-wait"
                        >
                          <UserCheck className="w-3 h-3" />
                          {updating === user.id ? '...' : 'Cấp Bác sĩ'}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

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

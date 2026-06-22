'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { StaffApi, Appointment } from '@/services/staff.service';
import {
  Calendar, Search, Filter, ShieldAlert, Loader2, CheckCircle2, XCircle, ArrowLeft, Stethoscope, RefreshCw
} from 'lucide-react';

const STATUS_CONFIG = {
  PENDING: { label: 'Chờ duyệt', color: 'bg-amber-500/15 text-amber-405 border border-amber-500/25' },
  CONFIRMED: { label: 'Đã xác nhận', color: 'bg-blue-500/15 text-blue-400 border border-blue-500/25' },
  CHECKED_IN: { label: 'Đã check-in', color: 'bg-indigo-500/15 text-indigo-405 border border-indigo-500/25' },
  COMPLETED: { label: 'Đã khám xong', color: 'bg-teal-500/15 text-teal-400 border border-teal-500/25' },
  CANCELLED: { label: 'Đã hủy', color: 'bg-red-500/15 text-red-400 border border-red-500/25' },
} as const;

export default function DoctorAppointments() {
  const router = useRouter();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'PENDING' | 'CONFIRMED' | 'CHECKED_IN' | 'COMPLETED' | 'CANCELLED'>('ALL');
  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await StaffApi.getAppointments();
      if (res.success && res.data) {
        setAppointments(res.data);
      } else {
        setError(res.message || 'Lỗi khi tải lịch hẹn.');
      }
    } catch {
      setError('Đã xảy ra lỗi kết nối.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadData();
  }, []);

  const handleUpdateStatus = async (id: string, status: 'CONFIRMED' | 'CANCELLED') => {
    setUpdatingId(id);
    try {
      const res = await StaffApi.updateAppointmentStatus(id, status);
      if (res.success) {
        setAppointments(prev => prev.map(a => a.id === id ? { ...a, status } : a));
      } else {
        alert(res.message || 'Lỗi khi cập nhật trạng thái');
      }
    } catch {
      alert('Lỗi kết nối');
    } finally {
      setUpdatingId(null);
    }
  };

  // Filter logic
  const filtered = appointments.filter(a => {
    const matchesSearch = a.user?.name?.toLowerCase().includes(search.toLowerCase()) || a.title?.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' || a.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-5">
      
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Calendar className="w-5 h-5 text-slate-400" />
            <h1 className="text-base font-semibold text-white">Quản lý lịch hẹn khám</h1>
            <span className="text-[11px] bg-slate-800 text-slate-400 border border-slate-700 px-2 py-0.5 rounded-full">
              {filtered.length} ca khám
            </span>
          </div>
          <p className="text-xs text-slate-500">
            Duyệt lịch hẹn khám của bệnh nhân, tiếp nhận khám và lập đơn thuốc điện tử.
          </p>
        </div>
      </div>

      {/* Action Bar (Filters + Search) */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-500" />
          <input
            type="text"
            placeholder="Tìm tên bệnh nhân..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg pl-8 pr-3 py-2 focus:outline-none focus:border-slate-700"
          />
        </div>
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value as any)}
          className="bg-slate-900 border border-slate-800 text-slate-355 text-xs rounded-lg px-3 py-2 focus:outline-none focus:border-slate-700"
        >
          <option value="ALL">Tất cả trạng thái</option>
          <option value="PENDING">Chờ duyệt</option>
          <option value="CONFIRMED">Đã xác nhận</option>
          <option value="CHECKED_IN">Đã check-in</option>
          <option value="COMPLETED">Đã khám xong</option>
          <option value="CANCELLED">Đã hủy</option>
        </select>
        <button
          onClick={loadData}
          className="p-2 bg-slate-900 hover:bg-slate-850 border border-slate-800 text-slate-400 hover:text-white rounded-lg transition"
          title="Tải lại danh sách"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs px-4 py-2.5 rounded-lg">
          {error}
        </div>
      )}

      {/* Appointments List */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-sm">
        {loading ? (
          <div className="flex items-center justify-center py-16 gap-2 text-slate-500 text-xs">
            <Loader2 className="w-4 h-4 text-teal-400 animate-spin" />
            Đang tải danh sách cuộc hẹn...
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 text-slate-600 text-xs">Không có cuộc hẹn nào được tìm thấy.</div>
        ) : (
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-slate-850">
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-bold tracking-wider uppercase">Bệnh nhân</th>
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-bold tracking-wider uppercase">Nội dung khám</th>
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-bold tracking-wider uppercase">Thời gian</th>
                <th className="text-left px-4 py-3 text-[10px] text-slate-600 font-bold tracking-wider uppercase">Trạng thái</th>
                <th className="text-right px-4 py-3 text-[10px] text-slate-600 font-bold tracking-wider uppercase">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-850">
              {filtered.map(appt => {
                const isPending = appt.status === 'PENDING';
                const isConfirmed = appt.status === 'CONFIRMED';
                const isCheckin = appt.status === 'CHECKED_IN';
                const cfg = STATUS_CONFIG[appt.status];

                return (
                  <tr key={appt.id} className="hover:bg-slate-800/20 transition-colors">
                    <td className="px-4 py-3.5">
                      <div className="font-semibold text-slate-200">{appt.user?.name}</div>
                      {appt.user?.profile?.phone && (
                        <div className="text-[10px] text-slate-500 font-mono mt-0.5">{appt.user.profile.phone}</div>
                      )}
                    </td>
                    <td className="px-4 py-3.5 text-slate-350">{appt.title || 'Khám tổng quát'}</td>
                    <td className="px-4 py-3.5">
                      <div className="text-slate-200 font-medium">
                        {new Date(appt.date).toLocaleDateString('vi-VN')}
                      </div>
                      <div className="text-[10px] text-slate-500 font-mono mt-0.5">
                        {new Date(appt.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${cfg?.color || ''}`}>
                        {cfg?.label || appt.status}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center justify-end gap-2">
                        {isPending && (
                          <>
                            <button
                              onClick={() => handleUpdateStatus(appt.id, 'CANCELLED')}
                              disabled={updatingId === appt.id}
                              className="px-2.5 py-1.5 border border-red-500/20 bg-red-500/10 hover:bg-red-500/20 text-red-400 rounded-md transition text-[11px] font-semibold disabled:opacity-55"
                            >
                              Từ chối
                            </button>
                            <button
                              onClick={() => handleUpdateStatus(appt.id, 'CONFIRMED')}
                              disabled={updatingId === appt.id}
                              className="px-2.5 py-1.5 bg-teal-600 hover:bg-teal-500 text-white rounded-md transition text-[11px] font-bold disabled:opacity-55"
                            >
                              Duyệt
                            </button>
                          </>
                        )}
                        {(isConfirmed || isCheckin) && (
                          <button
                            onClick={() => router.push(`/doctor/appointments/${appt.id}/prescribe`)}
                            className="flex items-center gap-1 px-3 py-1.5 bg-teal-600 hover:bg-teal-500 text-white rounded-md text-[11px] font-bold transition shadow-sm"
                          >
                            <Stethoscope className="w-3.5 h-3.5" />
                            Khám bệnh
                          </button>
                        )}
                        {!isPending && !isConfirmed && !isCheckin && (
                          <span className="text-slate-600 text-[11px] italic">Không có hành động</span>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

    </div>
  );
}

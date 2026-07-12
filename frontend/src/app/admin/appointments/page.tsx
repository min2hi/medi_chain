'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAdminUser } from '../layout';
import { StaffApi, Appointment } from '@/services/staff.service';
import { 
  Calendar, Search, Check, X, ShieldAlert, 
  AlertCircle, CheckCircle2, Clock
} from 'lucide-react';

const STATUS_CONFIG = {
  PENDING:    { label: 'Chờ duyệt',   color: 'bg-amber-950/40 text-amber-400 border border-amber-900/50' },
  CONFIRMED:  { label: 'Đã xác nhận', color: 'bg-teal-950/40 text-teal-400 border border-teal-900/50' },
  CHECKED_IN: { label: 'Đã check-in', color: 'bg-blue-950/40 text-blue-400 border border-blue-900/50' },
  COMPLETED:  { label: 'Hoàn thành',  color: 'bg-emerald-950/40 text-emerald-400 border border-emerald-900/50' },
  CANCELLED:  { label: 'Đã hủy',      color: 'bg-red-950/40 text-red-405 border border-red-900/50' },
} as const;

const PAYMENT_STATUS_CONFIG = {
  UNPAID:  { label: 'Chưa thanh toán', color: 'bg-slate-900 text-slate-500 border border-slate-800/60' },
  PENDING: { label: 'Đang thanh toán', color: 'bg-amber-950/40 text-amber-400 border border-amber-900/50' },
  PAID:    { label: 'Đã thanh toán',   color: 'bg-emerald-950/40 text-emerald-400 border border-emerald-900/50' },
  FAILED:  { label: 'Thất bại',         color: 'bg-red-950/40 text-red-405 border border-red-900/50' },
} as const;

export default function AppointmentsPage() {
  const router = useRouter();
  const user = useAdminUser();

  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  // Filters
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');



  const loadAppointments = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await StaffApi.getAppointments(statusFilter);
      if (res.success && res.data) {
        setAppointments(res.data);
      }
    } catch {
      setError('Không thể tải danh sách lịch hẹn');
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    void loadAppointments();
  }, [loadAppointments]);

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 3500);
  };

  const handleUpdateStatus = async (id: string, newStatus: 'CONFIRMED' | 'CANCELLED') => {
    const appt = appointments.find(a => a.id === id);
    if (newStatus === 'CONFIRMED' && appt && appt.paymentStatus !== 'PAID') {
      showToast('Bệnh nhân chưa thanh toán. Không thể xác nhận vào khám.', 'error');
      return;
    }

    setUpdatingId(id);
    try {
      const res = await StaffApi.updateAppointmentStatus(id, newStatus);
      if (res.success) {
        setAppointments(prev => prev.map(a => a.id === id ? { ...a, status: newStatus } : a));
        showToast(`Đã ${newStatus === 'CONFIRMED' ? 'xác nhận' : 'hủy'} lịch hẹn khám thành công`);
      } else {
        showToast(res.message || 'Cập nhật lịch hẹn thất bại', 'error');
      }
    } catch {
      showToast('Lỗi kết nối máy chủ', 'error');
    } finally {
      setUpdatingId(null);
    }
  };

  const handleCheckIn = async (id: string) => {
    setUpdatingId(id);
    try {
      const res = await StaffApi.checkInAppointment({ appointmentId: id, type: 'medichain_checkin' });
      if (res.success) {
        setAppointments(prev => prev.map(a => a.id === id ? { ...a, status: 'CHECKED_IN' } : a));
        showToast('Check-in thành công cho bệnh nhân');
      } else {
        showToast(res.message || 'Check-in thất bại', 'error');
      }
    } catch {
      showToast('Lỗi kết nối máy chủ', 'error');
    } finally {
      setUpdatingId(null);
    }
  };



  // Filter local state by search query
  const filteredAppointments = appointments.filter(a => {
    const term = searchQuery.toLowerCase().trim();
    if (!term) return true;
    return (
      a.user.name.toLowerCase().includes(term) ||
      a.title.toLowerCase().includes(term) ||
      (a.user.profile?.phone && a.user.profile.phone.includes(term))
    );
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Calendar className="w-5 h-5 text-slate-400" />
            <h1 className="text-base font-semibold text-white">Quản lý lịch hẹn khám</h1>
            <span className="text-[11px] bg-slate-800 text-slate-400 border border-slate-700 px-2 py-0.5 rounded-full">
              {appointments.length} cuộc hẹn
            </span>
          </div>
          <p className="text-xs text-slate-500">
            Cập nhật trạng thái cuộc hẹn khám và thực hiện check-in cho bệnh nhân.
          </p>
        </div>
      </div>



      {/* Toast notifications */}
      {toast && (
        <div className={`flex items-center gap-2 border px-4 py-3 rounded-lg text-xs animate-in fade-in slide-in-from-top-2 duration-200 ${
          toast.type === 'success' 
            ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400' 
            : 'bg-red-500/10 border-red-500/20 text-red-400'
        }`}>
          {toast.type === 'success' ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <AlertCircle className="w-4 h-4 shrink-0" />}
          {toast.message}
        </div>
      )}

      {/* Filters & Search Row */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-500" />
          <input
            type="text"
            placeholder="Tìm tên bệnh nhân, lý do khám..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="w-full bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-md pl-8 pr-3 py-2 focus:outline-none focus:border-slate-650"
          />
        </div>
        
        {/* Status Filters Tabs */}
        <div className="flex bg-slate-900 border border-slate-800 p-0.5 rounded-lg text-xs overflow-x-auto">
          {['ALL', 'PENDING', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED'].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1.5 rounded-md transition-all whitespace-nowrap ${
                statusFilter === st 
                  ? 'bg-slate-800 text-white font-medium shadow-sm' 
                  : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              {st === 'ALL' ? 'Tất cả' : STATUS_CONFIG[st as keyof typeof STATUS_CONFIG].label}
            </button>
          ))}
        </div>
      </div>

      {/* Table view */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-16 gap-2 text-slate-500 text-xs">
            <div className="w-4 h-4 border-2 border-slate-700 border-t-blue-400 rounded-full animate-spin" />
            Đang tải danh sách...
          </div>
        ) : error ? (
          <div className="text-center py-16 text-red-400 text-xs">{error}</div>
        ) : filteredAppointments.length === 0 ? (
          <div className="text-center py-16 text-slate-600 text-xs">Không có cuộc hẹn khám nào phù hợp.</div>
        ) : (
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-slate-800 text-left">
                <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Bệnh nhân</th>
                <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Ngày & Giờ</th>
                <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Lý do khám</th>
                <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Phí khám</th>
                <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Thanh toán</th>
                <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Trạng thái</th>
                <th className="px-4 py-3 text-right text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {filteredAppointments.map(appt => {
                const conf = STATUS_CONFIG[appt.status];
                const apptDate = new Date(appt.date);
                const isPending = appt.status === 'PENDING';
                const isConfirmed = appt.status === 'CONFIRMED';
                
                return (
                  <tr key={appt.id} className="hover:bg-slate-800/20 transition-colors">
                    <td className="px-4 py-3.5">
                      <div className="font-semibold text-slate-200">{appt.user.name}</div>
                      <div className="text-[10px] text-slate-550 font-mono mt-0.5">{appt.user.profile?.phone || 'Chưa cập nhật SĐT'}</div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="text-slate-300 font-medium">{apptDate.toLocaleDateString('vi-VN')}</div>
                      <div className="text-[10px] text-slate-550 font-mono mt-0.5 flex items-center gap-1">
                        <Clock className="w-3 h-3 text-slate-600" />
                        {apptDate.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="text-slate-300 max-w-xs truncate">{appt.title}</div>
                    </td>
                    <td className="px-4 py-3.5 text-slate-405 font-mono">
                      {(appt.consultFee).toLocaleString('vi-VN')} đ
                    </td>
                    <td className="px-4 py-3.5">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        PAYMENT_STATUS_CONFIG[appt.paymentStatus]?.color || 'bg-slate-800 text-slate-450'
                      }`}>
                        {PAYMENT_STATUS_CONFIG[appt.paymentStatus]?.label || appt.paymentStatus}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${conf.color}`}>
                        {conf.label}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center justify-end gap-2">
                        {isPending && (
                          <>
                            <button
                              onClick={() => handleUpdateStatus(appt.id, 'CONFIRMED')}
                              disabled={updatingId === appt.id}
                              className={`p-1 rounded transition border ${
                                appt.paymentStatus === 'PAID'
                                  ? 'text-emerald-400 hover:bg-emerald-500/10 border-emerald-500/20'
                                  : 'text-slate-500 hover:bg-slate-800/30 border-slate-800'
                              }`}
                              title={appt.paymentStatus === 'PAID' ? "Xác nhận lịch khám" : "Chờ thanh toán trước khi xác nhận"}
                            >
                              <Check className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => handleUpdateStatus(appt.id, 'CANCELLED')}
                              disabled={updatingId === appt.id}
                              className="p-1 text-red-400 hover:bg-red-500/10 border border-red-500/20 rounded transition"
                              title="Hủy lịch hẹn"
                            >
                              <X className="w-3.5 h-3.5" />
                            </button>
                          </>
                        )}
                        {isConfirmed && (
                          <>
                            <button
                              onClick={() => handleCheckIn(appt.id)}
                              disabled={updatingId === appt.id}
                              className="p-1 text-blue-400 hover:bg-blue-500/10 border border-blue-500/20 rounded transition"
                              title="Thực hiện check-in"
                            >
                              <CheckCircle2 className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => handleUpdateStatus(appt.id, 'CANCELLED')}
                              disabled={updatingId === appt.id}
                              className="p-1 text-red-400 hover:bg-red-500/10 border border-red-500/20 rounded transition"
                              title="Hủy lịch hẹn"
                            >
                              <X className="w-3.5 h-3.5" />
                            </button>
                          </>
                        )}
                        {!isPending && !isConfirmed && (
                          <span className="text-slate-600 text-[10px]">Không có thao tác</span>
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

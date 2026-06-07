'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAdminUser } from '../layout';
import { StaffApi, Appointment } from '@/services/staff.service';
import { 
  Calendar, Search, Check, X, ShieldAlert, 
  Stethoscope, QrCode, AlertCircle, CheckCircle2, Clock
} from 'lucide-react';

const STATUS_CONFIG = {
  PENDING:    { label: 'Chờ duyệt',   color: 'bg-amber-500/15 text-amber-400 border border-amber-500/25' },
  CONFIRMED:  { label: 'Đã xác nhận', color: 'bg-teal-500/15 text-teal-400 border border-teal-500/25' },
  CHECKED_IN: { label: 'Đã check-in', color: 'bg-blue-500/15 text-blue-400 border border-blue-500/25' },
  COMPLETED:  { label: 'Hoàn thành',  color: 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/25' },
  CANCELLED:  { label: 'Đã hủy',      color: 'bg-red-500/15 text-red-400 border border-red-500/25' },
} as const;

export default function AppointmentsPage() {
  const router = useRouter();
  const user = useAdminUser();
  const role = user?.role;

  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  // Filters
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // QR Check-in Simulator
  const [qrInput, setQrInput] = useState('');
  const [qrLoading, setQrLoading] = useState(false);

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

  const handleQrCheckIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!qrInput.trim()) return;

    setQrLoading(true);
    try {
      // Clean up string first
      const cleanInput = qrInput.trim();
      let payload: { appointmentId: string; type: string; exp?: number };

      try {
        const parsed = JSON.parse(cleanInput);
        if (parsed.type !== 'medichain_checkin' || !parsed.appointmentId) {
          throw new Error();
        }
        payload = {
          appointmentId: parsed.appointmentId,
          type: parsed.type,
          exp: parsed.exp
        };
      } catch {
        // Fallback: If it's just a raw UUID string, assume it is the appointmentId directly
        if (cleanInput.length > 20 && !cleanInput.includes('{')) {
          payload = {
            appointmentId: cleanInput,
            type: 'medichain_checkin'
          };
        } else {
          showToast('Định dạng mã QR Check-in không hợp lệ', 'error');
          setQrLoading(false);
          return;
        }
      }

      const res = await StaffApi.checkInAppointment(payload);
      if (res.success && res.data) {
        showToast(`Check-in thành công cho bệnh nhân: ${res.data.user.name}`);
        setQrInput('');
        void loadAppointments();
      } else {
        showToast(res.message || 'Xác thực Check-in thất bại', 'error');
      }
    } catch {
      showToast('Không thể kết nối máy chủ để kiểm tra QR', 'error');
    } finally {
      setQrLoading(false);
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

      {/* QR Code Check-in Simulator */}
      <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-3">
        <div className="flex items-center gap-2">
          <QrCode className="w-4 h-4 text-blue-400" />
          <h2 className="text-xs font-semibold text-white uppercase tracking-wider">Trình mô phỏng QR Check-in</h2>
        </div>
        <p className="text-[11px] text-slate-500">
          Nhập mã JSON payload check-in (ví dụ: <code className="text-slate-400 font-mono">{"{ \"type\": \"medichain_checkin\", \"appointmentId\": \"id_cuoc_hen\" }"}</code>) hoặc điền trực tiếp mã UUID lịch hẹn để cập nhật trạng thái <span className="text-blue-400 font-medium">Đã check-in</span>.
        </p>
        <form onSubmit={handleQrCheckIn} className="flex gap-2">
          <input
            type="text"
            placeholder="Dán nội dung mã QR Check-in..."
            value={qrInput}
            onChange={e => setQrInput(e.target.value)}
            className="flex-1 bg-slate-950 border border-slate-850 text-xs text-slate-200 rounded-md px-3 py-2.5 placeholder-slate-700 focus:outline-none focus:border-slate-700"
          />
          <button
            type="submit"
            disabled={qrLoading || !qrInput.trim()}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white rounded-md text-xs font-semibold transition flex items-center gap-2 shrink-0"
          >
            {qrLoading && <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />}
            Xác thực
          </button>
        </form>
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
                const isCheckin = appt.status === 'CHECKED_IN';
                
                return (
                  <tr key={appt.id} className="hover:bg-slate-800/20 transition-colors">
                    <td className="px-4 py-3.5">
                      <div className="font-semibold text-slate-200">{appt.user.name}</div>
                      <div className="text-[10px] text-slate-500 font-mono mt-0.5">{appt.user.profile?.phone || 'Chưa cập nhật SĐT'}</div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="text-slate-300 font-medium">{apptDate.toLocaleDateString('vi-VN')}</div>
                      <div className="text-[10px] text-slate-500 font-mono mt-0.5 flex items-center gap-1">
                        <Clock className="w-3 h-3 text-slate-600" />
                        {apptDate.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="text-slate-300 max-w-xs truncate">{appt.title}</div>
                    </td>
                    <td className="px-4 py-3.5 text-slate-400 font-mono">
                      {(appt.consultFee).toLocaleString('vi-VN')} đ
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
                              className="p-1 text-emerald-400 hover:bg-emerald-500/10 border border-emerald-500/20 rounded transition"
                              title="Xác nhận lịch khám"
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
                        {(isConfirmed || isCheckin) && role === 'DOCTOR' && (
                          <button
                            onClick={() => router.push(`/admin/appointments/${appt.id}/prescribe`)}
                            className="flex items-center gap-1 px-2.5 py-1.5 bg-emerald-600 hover:bg-emerald-550 text-white rounded-md text-[11px] font-semibold transition"
                          >
                            <Stethoscope className="w-3 h-3" />
                            Khám bệnh
                          </button>
                        )}
                        {!isPending && !(role === 'DOCTOR' && (isConfirmed || isCheckin)) && (
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

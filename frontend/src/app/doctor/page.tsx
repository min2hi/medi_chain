'use client';

import React, { useEffect, useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { StaffApi, Appointment } from '@/services/staff.service';
import { AuthService } from '@/services/auth.client';
import {
  Calendar, CheckCircle, Clock, AlertCircle, ArrowRight,
  ClipboardList, RefreshCw, ChevronRight, BookOpen, Settings, QrCode, X,
  UserCheck, ClipboardCheck, Stethoscope
} from 'lucide-react';

export default function DoctorDashboard() {
  const router = useRouter();
  
  // State variables
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [doctorName, setDoctorName] = useState('Bác sĩ');
  const [scratchpad, setScratchpad] = useState('');
  
  // QR Check-in Simulator modal state
  const [isQrModalOpen, setIsQrModalOpen] = useState(false);
  const [qrInput, setQrInput] = useState('');
  const [qrLoading, setQrLoading] = useState(false);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // ── Stable Today String Memo ─────────────────────────────────────────────
  const todayStr = useMemo(() => {
    return new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
  }, []);

  // Initialize selected date to today directly (prevents layout shift / delayed filter)
  const [selectedDateStr, setSelectedDateStr] = useState(todayStr);

  // Load name and local scratchpad on mount (safety check for SSR hydration)
  useEffect(() => {
    const u = AuthService.getCurrentUser();
    if (u) {
      setDoctorName(u.name || 'Bác sĩ');
    }
    const saved = localStorage.getItem('doctor_scratchpad') || '';
    setScratchpad(saved);
  }, []);

  const handleScratchpadChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const val = e.target.value;
    setScratchpad(val);
    localStorage.setItem('doctor_scratchpad', val);
  };

  const loadData = async (silent = false) => {
    if (!silent) setLoading(true);
    setError(null);
    try {
      const res = await StaffApi.getAppointments();
      if (res.success && res.data) {
        setAppointments(res.data);
      } else {
        setError(res.message || 'Không thể tải danh sách ca khám.');
      }
    } catch {
      setError('Đã xảy ra lỗi kết nối.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    void loadData();
  }, []);

  const handleRefresh = () => {
    setRefreshing(true);
    void loadData(true);
  };

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 3500);
  };

  const handleUpdateStatus = async (id: string, status: 'CONFIRMED' | 'CANCELLED') => {
    try {
      const res = await StaffApi.updateAppointmentStatus(id, status);
      if (res.success) {
        showToast(status === 'CONFIRMED' ? 'Đã duyệt lịch hẹn khám thành công!' : 'Đã hủy lịch hẹn khám!');
        void loadData(true);
      } else {
        showToast(res.message || 'Không thể cập nhật trạng thái.', 'error');
      }
    } catch (err) {
      console.error('Failed to update status:', err);
      showToast('Đã xảy ra lỗi kết nối.', 'error');
    }
  };

  const handleQrCheckIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!qrInput.trim()) return;

    setQrLoading(true);
    try {
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
        setIsQrModalOpen(false);
        void loadData(true);
      } else {
        showToast(res.message || 'Xác thực Check-in thất bại', 'error');
      }
    } catch {
      showToast('Không thể kết nối máy chủ để kiểm tra QR', 'error');
    } finally {
      setQrLoading(false);
    }
  };

  // ── Stable UI Calculations (Memoized) ────────────────────────────────────
  const greeting = useMemo(() => {
    const h = new Date().getHours();
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }, []);

  const formattedDate = useMemo(() => {
    const now = new Date();
    const wds = ['CN', 'Hai', 'Ba', 'Tư', 'Năm', 'Sáu', 'Bảy'];
    const wd = now.getDay();
    const prefix = wd === 0 ? 'CN' : `Thứ ${wd + 1}`;
    return `${prefix}, ${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}`;
  }, []);

  const weeklyDays = useMemo(() => {
    const days = [];
    const current = new Date();
    const day = current.getDay();
    const diff = current.getDate() - day + (day === 0 ? -6 : 1);
    const startOfWeek = new Date(current.setDate(diff));

    for (let i = 0; i < 7; i++) {
      const d = new Date(startOfWeek);
      d.setDate(startOfWeek.getDate() + i);
      const wds = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      days.push({
        date: d,
        dayLabel: wds[d.getDay()],
        dateLabel: d.getDate(),
        dateStr: d.toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10),
      });
    }
    return days;
  }, []);

  // O(N) counts mapping helper instead of O(7 * N) nested scans
  const dateCountMap = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const a of appointments) {
      if (a.status === 'CANCELLED') continue;
      const key = new Date(a.date).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      counts[key] = (counts[key] || 0) + 1;
    }
    return counts;
  }, [appointments]);

  // Selected Date appointments: memoized and sorted
  const selectedDateApts = useMemo(() => {
    return appointments
      .filter(a => {
        const itemStr = new Date(a.date).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
        return itemStr === selectedDateStr && a.status !== 'CANCELLED';
      })
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
  }, [appointments, selectedDateStr]);

  // General Stats: memoized to avoid redundant allocations on keystrokes
  const todayApts = useMemo(() => {
    return appointments.filter(a => {
      const itemStr = new Date(a.date).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      return itemStr === todayStr && a.status !== 'CANCELLED';
    });
  }, [appointments, todayStr]);

  const pending = useMemo(() => {
    return appointments.filter(a => a.status === 'PENDING');
  }, [appointments]);

  const confirmed = useMemo(() => {
    return appointments.filter(a => a.status === 'CONFIRMED' || a.status === 'CHECKED_IN');
  }, [appointments]);

  const completedToday = useMemo(() => {
    return appointments.filter(a => {
      const itemStr = new Date(a.date).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      return itemStr === todayStr && a.status === 'COMPLETED';
    });
  }, [appointments, todayStr]);

  // Quick Action triggers
  const handleNextDiagnosis = () => {
    const activeToday = appointments.filter(a => {
      const itemStr = new Date(a.date).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      return itemStr === todayStr && (a.status === 'CHECKED_IN' || a.status === 'CONFIRMED');
    }).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

    if (activeToday.length > 0) {
      router.push(`/doctor/appointments/${activeToday[0].id}/prescribe`);
    } else {
      showToast('Không có ca khám nào đang chờ tiếp theo hôm nay.', 'error');
    }
  };

  const handleQuickConfirm = () => {
    setSelectedDateStr(todayStr);
    const element = document.getElementById('appointments-section');
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
    showToast('Đã chuyển sang lịch khám hôm nay. Bạn có thể duyệt trực tiếp ở danh sách bên dưới.');
  };

  const handlePrescribeAction = () => {
    router.push('/doctor/appointments');
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-3">
        <RefreshCw className="w-5 h-5 text-teal-600 animate-spin" />
        <span className="text-slate-500 text-xs font-mono">ĐANG TẢI DỮ LIỆU...</span>
      </div>
    );
  }

  return (
    <div className="space-y-7 max-w-6xl mx-auto pb-10 text-slate-800">
      
      {/* Toast Notifications */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-2 border px-4 py-3 rounded-xl text-xs shadow-2xl animate-in slide-in-from-top-2 duration-200 ${
          toast.type === 'success' 
            ? 'bg-white border-emerald-200 text-emerald-600 shadow-md shadow-emerald-500/10' 
            : 'bg-white border-red-200 text-red-600 shadow-md shadow-red-500/10'
        }`}>
          {toast.type === 'success' ? <CheckCircle className="w-4 h-4 shrink-0 animate-bounce" /> : <AlertCircle className="w-4 h-4 shrink-0 animate-pulse" />}
          {toast.message}
        </div>
      )}

      {/* Premium curved banner with clinical styling */}
      <div className="relative bg-gradient-to-br from-teal-600 to-teal-700 rounded-3xl p-6 overflow-hidden shadow-md text-white">
        <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-white/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="absolute -bottom-20 left-1/3 w-[300px] h-[300px] bg-white/5 rounded-full blur-[80px] pointer-events-none" />
        
        <div className="relative z-10 flex flex-col sm:flex-row sm:items-center justify-between gap-6">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-2xl bg-white/20 border border-white/30 flex items-center justify-center shadow-md shrink-0">
              <span className="text-2xl font-black text-white uppercase">{doctorName.charAt(0)}</span>
            </div>
            
            <div className="space-y-1">
              <p className="text-[10px] text-teal-100 font-extrabold uppercase tracking-widest">{formattedDate}</p>
              <h1 className="text-xl font-bold text-white tracking-tight">
                {greeting}, {doctorName}
              </h1>
              <p className="text-xs text-teal-100/80">Chào mừng bạn quay trở lại. Hãy sẵn sàng cho các buổi khám sắp tới.</p>
            </div>
          </div>

          <div className="flex items-center gap-2 self-start sm:self-auto">
            <span className="text-[9px] bg-white/20 text-white border border-white/30 font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-full backdrop-blur-sm flex items-center gap-1.5 shadow-sm">
              <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
              Trực tuyến
            </span>
            <button 
              onClick={() => router.push('/doctor/cai-dat')}
              className="p-2 bg-white/20 hover:bg-white/30 border border-white/30 rounded-full text-white transition duration-200 active:scale-95 shadow-sm cursor-pointer"
              title="Cài đặt chuyên môn"
            >
              <Settings className="w-4 h-4" />
            </button>
            <button
              onClick={handleRefresh}
              disabled={refreshing}
              className="p-2 bg-white/20 hover:bg-white/30 border border-white/30 rounded-full text-white transition duration-200 active:scale-95 shadow-sm cursor-pointer"
              title="Tải lại dữ liệu"
            >
              <RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Stats Grid - Aligned Standalone */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Hôm nay', count: todayApts.length, sub: 'Tổng số lịch hẹn', icon: Calendar },
          { label: 'Chờ duyệt', count: pending.length, sub: 'Yêu cầu chờ duyệt', icon: Clock },
          { label: 'Xác nhận', count: confirmed.length, sub: 'Ca hẹn sắp diễn ra', icon: UserCheck },
          { label: 'Hoàn thành', count: completedToday.length, sub: 'Đã hoàn thành hôm nay', icon: ClipboardCheck },
        ].map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <div 
              key={idx} 
              className="bg-white border border-slate-200/80 hover:border-teal-500/20 p-5 rounded-2xl transition-all duration-300 flex flex-col justify-between shadow-sm group cursor-pointer"
            >
              <div className="flex items-center justify-between">
                <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider">{stat.label}</span>
                <Icon className="w-4.5 h-4.5 text-slate-400 group-hover:text-teal-600 transition-colors" />
              </div>
              <div className="mt-3 space-y-0.5">
                <p className="text-3xl font-black font-mono text-slate-800 leading-none">{stat.count}</p>
                <p className="text-[10px] text-slate-500">{stat.sub}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* 2 Column Details grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Area (2 cols) */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Lịch trình tuần này */}
          <div className="bg-white border border-slate-200/85 p-5 rounded-3xl space-y-4 shadow-sm">
            <div className="flex justify-between items-center px-1">
              <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest flex items-center gap-2">
                <Calendar className="w-4 h-4 text-teal-600" />
                Lịch trình tuần này
              </h3>
              <span className="text-[10px] text-slate-400 font-semibold font-mono">
                {weeklyDays[0].dateLabel} - {weeklyDays[6].dateLabel} Thg {weeklyDays[0].date.getMonth() + 1}
              </span>
            </div>
            
            <div className="grid grid-cols-7 gap-2">
              {weeklyDays.map((day) => {
                const isSelected = day.dateStr === selectedDateStr;
                const count = dateCountMap[day.dateStr] || 0;
                const isDayToday = day.dateStr === todayStr;
                
                return (
                  <button
                    key={day.dateStr}
                    onClick={() => setSelectedDateStr(day.dateStr)}
                    className={`py-3.5 rounded-2xl flex flex-col items-center justify-center gap-1 transition-all duration-300 relative border cursor-pointer ${
                      isSelected
                        ? 'bg-gradient-to-b from-teal-500 to-teal-600 text-white font-bold border-teal-400/50 shadow-md shadow-teal-500/10 scale-105 z-10'
                        : 'bg-white border-slate-200 text-slate-500 hover:text-slate-900 hover:bg-slate-50/50'
                    }`}
                  >
                    <span className="text-[10px] uppercase font-bold tracking-wider">{day.dayLabel}</span>
                    <span className="text-base font-black font-mono leading-none">{day.dateLabel}</span>
                    
                    {count > 0 && (
                      <span className={`w-1.5 h-1.5 rounded-full ${isSelected ? 'bg-white' : 'bg-teal-500'} mt-1`} />
                    )}
                    {isDayToday && !isSelected && (
                      <span className="absolute top-1 right-1.5 w-1.5 h-1.5 bg-teal-600 rounded-full animate-pulse" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Thao tác nhanh (Quick Actions) */}
          <div className="space-y-3">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest px-1">Thao tác nhanh</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {[
                { label: 'Bắt đầu khám tiếp', sub: 'Khám ca đang chờ', action: handleNextDiagnosis, icon: Stethoscope },
                { label: 'Duyệt nhanh lịch', sub: 'Xác nhận yêu cầu', action: handleQuickConfirm, icon: UserCheck },
                { label: 'Kê đơn thuốc mới', sub: 'Xem các ca kê đơn', action: handlePrescribeAction, icon: ClipboardCheck },
                { label: 'Quét mã check-in', sub: 'Check-in QR nhanh', action: () => setIsQrModalOpen(true), icon: QrCode },
              ].map((act, i) => {
                const Icon = act.icon;
                return (
                  <button 
                    key={i}
                    onClick={act.action}
                    className="bg-white hover:bg-teal-50/10 border border-slate-200/80 hover:border-teal-500/20 p-4 rounded-2xl flex items-center gap-3.5 transition-all duration-300 group text-left shadow-sm hover:shadow-md active:scale-98 cursor-pointer"
                  >
                    <div className="w-10 h-10 rounded-xl bg-teal-500/10 flex items-center justify-center text-teal-600 group-hover:bg-teal-600 group-hover:text-white transition-all duration-300 shrink-0">
                      <Icon className="w-5 h-5" />
                    </div>
                    <div className="space-y-0.5 min-w-0">
                      <span className="text-xs font-bold text-slate-750 group-hover:text-teal-700 transition block truncate">{act.label}</span>
                      <span className="text-[9px] text-slate-400 block truncate">{act.sub}</span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Đăng ký ca rảnh khám bệnh */}
          <button
            onClick={() => router.push('/doctor/slots')}
            className="w-full bg-white hover:bg-teal-50/10 border border-slate-200/80 hover:border-teal-500/20 p-4 rounded-2xl flex items-center justify-between shadow-sm transition-all duration-300 active:scale-[0.99] group text-left relative overflow-hidden cursor-pointer"
          >
            <div className="absolute left-0 top-0 bottom-0 w-1 bg-teal-600" />
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-xl bg-teal-50 flex items-center justify-center text-teal-600 group-hover:bg-teal-600 group-hover:text-white transition duration-305 shrink-0">
                <Calendar className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-700 group-hover:text-teal-700 transition uppercase tracking-wider">Quản lý lịch rảnh khám bệnh</h4>
                <p className="text-[10px] text-slate-500 mt-0.5">Thiết lập các ca làm việc của bạn để bệnh nhân chủ động đặt hẹn khám trực tuyến.</p>
              </div>
            </div>
            <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-teal-600 group-hover:translate-x-1 transition duration-300" />
          </button>

          {/* Lịch hẹn trong ngày đã chọn */}
          <div id="appointments-section" className="space-y-3 scroll-mt-20">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest px-1">
              Chi tiết lịch hẹn ngày {new Date(selectedDateStr).toLocaleDateString('vi-VN')} ({selectedDateApts.length})
            </h3>

            {selectedDateApts.length === 0 ? (
              <div className="bg-white border border-slate-200 rounded-2xl p-6 text-center text-slate-400 text-xs shadow-sm">
                Không có lịch hẹn nào cho ngày này.
              </div>
            ) : (
              <div className="grid grid-cols-1 gap-3">
                {selectedDateApts.map((apt) => {
                  const isPending = apt.status === 'PENDING';
                  const isConfirmed = apt.status === 'CONFIRMED' || apt.status === 'CHECKED_IN';
                  const isDone = apt.status === 'COMPLETED';
                  const firstChar = apt.user?.name?.charAt(0) || 'B';
                  
                  return (
                    <div 
                      key={apt.id} 
                      className="bg-white border border-slate-200/85 hover:border-slate-355 rounded-2xl p-4 flex flex-col sm:flex-row justify-between sm:items-center gap-4 transition-all duration-300 hover:shadow-md shadow-sm group"
                    >
                      <div className="flex items-center gap-3.5">
                        <div className="w-10 h-10 rounded-xl bg-teal-50 border border-teal-100 flex items-center justify-center text-teal-600 font-extrabold text-xs uppercase shrink-0">
                          {firstChar}
                        </div>
                        <div className="space-y-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="font-bold text-xs text-slate-800">{apt.user?.name}</span>
                            <span className="text-[9px] font-mono text-slate-500 bg-slate-50 border border-slate-200 px-1.5 py-0.5 rounded font-bold">
                              {new Date(apt.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </span>
                          </div>
                          <p className="text-[11px] text-slate-500 truncate">Triệu chứng: {apt.title}</p>
                        </div>
                      </div>

                      <div className="flex items-center gap-2.5 shrink-0 self-end sm:self-auto">
                        <span className={`text-[9px] px-2 py-0.5 rounded-md font-semibold border ${
                          isDone ? 'bg-teal-50 text-teal-600 border-teal-200' :
                          isPending ? 'bg-amber-50 text-amber-600 border-amber-200' :
                          'bg-blue-50 text-blue-600 border-blue-200'
                        }`}>
                          {apt.status === 'PENDING' ? 'Chờ duyệt' : apt.status === 'CONFIRMED' ? 'Đã duyệt' : apt.status === 'CHECKED_IN' ? 'Đã check-in' : apt.status === 'COMPLETED' ? 'Đã khám' : apt.status}
                        </span>

                        {isPending && (
                          <div className="flex items-center gap-1.5">
                            <button
                              onClick={() => handleUpdateStatus(apt.id, 'CANCELLED')}
                              className="px-3 py-1.5 border border-red-200 bg-red-50 hover:bg-red-100 text-red-600 text-xs font-bold rounded-lg transition duration-200 cursor-pointer"
                            >
                              Từ chối
                            </button>
                            <button
                              onClick={() => handleUpdateStatus(apt.id, 'CONFIRMED')}
                              className="px-3 py-1.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-bold rounded-lg transition duration-200 cursor-pointer"
                            >
                              Duyệt
                            </button>
                          </div>
                        )}

                        {isConfirmed && (
                          <button
                            onClick={() => router.push(`/doctor/appointments/${apt.id}/prescribe`)}
                            className="flex items-center gap-1.5 px-3 py-1.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-semibold rounded-lg transition duration-200 shadow-sm cursor-pointer"
                          >
                            Bắt đầu khám
                            <ChevronRight className="w-3.5 h-3.5 text-white" />
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

        </div>

        {/* Right Area (1 col) */}
        <div className="space-y-6">
          
          {/* Sổ tay ghi chú nhanh */}
          <div className="bg-white border border-slate-200/80 rounded-3xl p-5 space-y-3.5 shadow-sm relative overflow-hidden">
            <div className="flex justify-between items-center">
              <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest flex items-center gap-2">
                <BookOpen className="w-4 h-4 text-teal-600" />
                Ghi chú lâm sàng
              </h3>
              <span className="text-[9px] text-teal-700 bg-teal-50 border border-teal-200 px-2 py-0.5 rounded-full font-bold">Tự động lưu</span>
            </div>
            <textarea
              value={scratchpad}
              onChange={handleScratchpadChange}
              placeholder="Nhập ghi chú nhanh tại đây (ví dụ: dị ứng thuốc, ghi chú bệnh nhân đặc biệt)..."
              className="w-full h-36 bg-slate-50 border border-slate-200/70 hover:border-slate-300 text-xs text-slate-700 rounded-xl p-3 focus:outline-none focus:border-teal-500 focus:bg-white transition duration-200 resize-none font-medium placeholder-slate-400 leading-relaxed"
            />
          </div>

          {/* Lịch khám hôm nay timeline */}
          <div className="bg-white border border-slate-200 rounded-3xl p-5 space-y-4 shadow-sm">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest flex items-center gap-2">
              <ClipboardList className="w-4 h-4 text-slate-400" />
              Lịch trình khám hôm nay ({todayApts.length})
            </h3>
            
            {todayApts.length === 0 ? (
              <p className="text-center text-slate-400 text-xs py-4">Chưa có lịch khám nào trong hôm nay.</p>
            ) : (
              <div className="relative border-l border-slate-200 pl-4 ml-2.5 space-y-4">
                {todayApts.map((apt) => {
                  const isDone = apt.status === 'COMPLETED';
                  const isPending = apt.status === 'PENDING';
                  return (
                    <div key={apt.id} className="relative group">
                      <span className={`absolute -left-[21.5px] top-1.5 w-2.5 h-2.5 rounded-full border-2 border-white transition duration-300 ${
                        isDone ? 'bg-emerald-500' : isPending ? 'bg-amber-400' : 'bg-blue-400'
                      }`} />
                      
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="text-xs font-bold text-slate-800">{apt.user?.name}</p>
                          <p className="text-[10px] text-slate-550 mt-0.5 font-medium">
                            {new Date(apt.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} · {apt.title}
                          </p>
                        </div>
                        <span className={`text-[9px] px-1.5 py-0.5 rounded font-mono font-semibold ${
                          isDone ? 'bg-emerald-50 text-emerald-600' :
                          isPending ? 'bg-amber-50 text-amber-600' :
                          'bg-blue-50 text-blue-600'
                        }`}>
                          {apt.status === 'PENDING' ? 'Chờ duyệt' : apt.status === 'CONFIRMED' ? 'Đã duyệt' : apt.status === 'CHECKED_IN' ? 'Đã check-in' : apt.status === 'COMPLETED' ? 'Đã khám' : apt.status}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

        </div>

      </div>

      {/* QR Check-In Simulator Modal */}
      {isQrModalOpen && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-3xl p-6 w-full max-w-md shadow-2xl relative animate-in fade-in zoom-in-95 duration-200">
            <button 
              onClick={() => setIsQrModalOpen(false)}
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-700 transition cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
            
            <div className="flex items-center gap-2 mb-3">
              <QrCode className="w-5 h-5 text-teal-600" />
              <h3 className="text-base font-bold text-slate-850">Trình mô phỏng quét mã QR Check-in</h3>
            </div>
            
            <p className="text-xs text-slate-500 mb-4">
              Nhập payload JSON check-in hoặc điền trực tiếp mã UUID lịch hẹn để cập nhật trạng thái <span className="text-teal-600 font-semibold">Đã check-in</span>.
            </p>

            <form onSubmit={handleQrCheckIn} className="space-y-4">
              <textarea
                placeholder='Dán nội dung mã QR (ví dụ: { "type": "medichain_checkin", "appointmentId": "id_cuoc_hen" } hoặc chỉ điền mã UUID)'
                value={qrInput}
                onChange={e => setQrInput(e.target.value)}
                rows={3}
                className="w-full bg-slate-50 border border-slate-200 text-xs text-slate-700 rounded-xl p-3 placeholder-slate-400 focus:outline-none focus:border-teal-500 resize-none font-mono"
              />
              <div className="flex gap-3 justify-end">
                <button
                  type="button"
                  onClick={() => setIsQrModalOpen(false)}
                  className="px-4 py-2 border border-slate-200 hover:bg-slate-50 text-slate-550 hover:text-slate-800 rounded-xl text-xs font-semibold transition cursor-pointer"
                >
                  Đóng
                </button>
                <button
                  type="submit"
                  disabled={qrLoading || !qrInput.trim()}
                  className="px-5 py-2 bg-teal-600 hover:bg-teal-555 disabled:opacity-50 text-white rounded-xl text-xs font-semibold transition flex items-center gap-2 cursor-pointer"
                >
                  {qrLoading && <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />}
                  Xác thực
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}

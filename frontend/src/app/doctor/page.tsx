'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { StaffApi, Appointment } from '@/services/staff.service';
import { AuthService } from '@/services/auth.client';
import {
  Calendar, CheckCircle, Clock, AlertCircle, ArrowRight,
  ClipboardList, ShieldAlert, RefreshCw,
  Activity, ChevronRight, BookOpen, Settings, QrCode, X,
  UserCheck, ClipboardCheck, Stethoscope
} from 'lucide-react';

export default function DoctorDashboard() {
  const router = useRouter();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [doctorName, setDoctorName] = useState('Bác sĩ');

  // Selected date for scheduler (defaults to today's date YYYY-MM-DD)
  const [selectedDateStr, setSelectedDateStr] = useState('');
  // Scratchpad state
  const [scratchpad, setScratchpad] = useState('');

  // QR Check-in Simulator modal state
  const [isQrModalOpen, setIsQrModalOpen] = useState(false);
  const [qrInput, setQrInput] = useState('');
  const [qrLoading, setQrLoading] = useState(false);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  useEffect(() => {
    const u = AuthService.getCurrentUser();
    if (u) {
      setDoctorName(u.name || 'Bác sĩ');
    }
    const todayStr = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
    setSelectedDateStr(todayStr);

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
    setTimeout(() => setToast(null), 3000);
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

  // ── Helpers ──────────────────────────────────────────────────────────────
  const greeting = () => {
    const h = new Date().getHours();
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  };

  const getFormattedVietnameseDate = () => {
    const now = new Date();
    const wds = ['CN', 'Hai', 'Ba', 'Tư', 'Năm', 'Sáu', 'Bảy'];
    const wd = now.getDay();
    const prefix = wd === 0 ? 'CN' : `Thứ ${wd + 1}`;
    return `${prefix}, ${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}`;
  };

  const getWeeklyDays = () => {
    const days = [];
    const current = new Date();
    const day = current.getDay();
    // Adjust start day to Monday
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
  };

  const isToday = (dateStr: string) => {
    const todayStr = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
    const itemStr = new Date(dateStr).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
    return todayStr === itemStr;
  };

  const getAppointmentsCountForDate = (dateStr: string) => {
    return appointments.filter(a => {
      const itemStr = new Date(a.date).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      return itemStr === dateStr && a.status !== 'CANCELLED';
    }).length;
  };

  // Filter & sort appointments for the SELECTED date
  const selectedDateApts = appointments
    .filter(a => {
      const itemStr = new Date(a.date).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      return itemStr === selectedDateStr && a.status !== 'CANCELLED';
    })
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  // Filter for stats
  const todayApts = appointments.filter(a => isToday(a.date) && a.status !== 'CANCELLED');
  const pending = appointments.filter(a => a.status === 'PENDING');
  const confirmed = appointments.filter(a => a.status === 'CONFIRMED');
  const completedToday = appointments.filter(a => isToday(a.date) && a.status === 'COMPLETED');

  // Next patient logic
  const confirmedToday = todayApts.filter(a => a.status === 'CONFIRMED' || a.status === 'CHECKED_IN');
  const nextApt = confirmedToday.length > 0 ? confirmedToday[0] : null;

  const weeklyDays = getWeeklyDays();

  // Quick Action triggers
  const handleNextDiagnosis = () => {
    const todayStr = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
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
    const todayStr = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
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
      <div className="flex flex-col items-center justify-center min-h-[70vh] gap-4 bg-slate-50/50 text-slate-800 rounded-3xl border border-slate-100/50 shadow-sm animate-pulse duration-1000">
        <div className="relative flex items-center justify-center w-16 h-16 rounded-full bg-teal-50 border border-teal-100/60 shadow-sm shadow-teal-500/5 animate-bounce">
          <div className="absolute inset-0 rounded-full border border-teal-500/20 animate-ping opacity-40"></div>
          <Activity className="w-6 h-6 text-teal-600" />
        </div>
        <div className="text-center space-y-1">
          <span className="text-slate-700 text-xs font-bold tracking-wider uppercase block">Đang khởi tạo hệ thống...</span>
          <span className="text-[10px] text-slate-400 font-medium block">Vui lòng đợi trong giây lát</span>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10 bg-slate-50 text-slate-850">
      
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

      {/* Premium curved banner with mobile alignment */}
      <div className="relative bg-teal-600 rounded-3xl p-6 overflow-hidden shadow-lg text-white">
        <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-white/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="absolute -bottom-20 left-1/3 w-[300px] h-[300px] bg-white/5 rounded-full blur-[80px] pointer-events-none" />
        
        <div className="relative z-10 space-y-6">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 rounded-2xl bg-white/20 border border-white/30 flex items-center justify-center shadow-lg relative">
                <span className="text-2xl font-bold text-white uppercase">{doctorName.charAt(0)}</span>
                <span className="absolute -bottom-1 -right-1 w-3.5 h-3.5 bg-green-500 rounded-full border-2 border-teal-600 flex items-center justify-center">
                  <span className="w-1.5 h-1.5 bg-white rounded-full animate-ping" />
                </span>
              </div>
              
              <div className="space-y-1">
                <p className="text-[10px] text-teal-100 font-extrabold uppercase tracking-widest">{getFormattedVietnameseDate()}</p>
                <div className="flex items-center gap-2">
                  <h1 className="text-xl font-black text-white tracking-tight">
                    {greeting()}, Dr. {doctorName}
                  </h1>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-[9px] bg-white/20 text-white border border-white/30 font-bold uppercase tracking-wider px-2.5 py-1 rounded-full backdrop-blur-sm flex items-center gap-1.5 shadow-sm">
                <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
                Trực tuyến
              </span>
              <button 
                onClick={() => router.push('/doctor/cai-dat')}
                className="p-1.5 bg-white/20 hover:bg-white/30 border border-white/30 rounded-full text-white transition duration-300 active:scale-90 shadow-sm"
                title="Cài đặt chuyên môn"
              >
                <Settings className="w-4 h-4" />
              </button>
              <button
                onClick={handleRefresh}
                disabled={refreshing}
                className="p-1.5 bg-white/20 hover:bg-white/30 border border-white/30 rounded-full text-white transition duration-300 active:scale-90 shadow-sm shrink-0"
                title="Tải lại dữ liệu"
              >
                <RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} />
              </button>
            </div>
          </div>

          {/* Stats aligned beautifully on web inside/below banner */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mt-6">
            {[
              { label: 'Hôm nay', count: todayApts.length },
              { label: 'Chờ duyệt', count: pending.length },
              { label: 'Xác nhận', count: confirmed.length },
              { label: 'Xong', count: completedToday.length },
            ].map((stat, idx) => (
              <div 
                key={idx} 
                className="bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 p-4 rounded-2xl transition-all duration-300 flex flex-col justify-between shadow-sm"
              >
                <span className="text-[10px] text-white/80 font-bold uppercase tracking-widest">{stat.label}</span>
                <p className="text-3xl font-black mt-2 leading-none font-mono text-white">{stat.count}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Columns (lg:col-span-2) */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Lịch trình tuần này */}
          <div className="bg-white border border-slate-200 p-4 rounded-3xl space-y-3 shadow-sm">
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
                const count = getAppointmentsCountForDate(day.dateStr);
                const isDayToday = isToday(day.dateStr);
                
                return (
                  <button
                    key={day.dateStr}
                    onClick={() => setSelectedDateStr(day.dateStr)}
                    className={`py-3 rounded-2xl flex flex-col items-center justify-center gap-1 transition-all duration-300 relative border ${
                      isSelected
                        ? 'bg-gradient-to-b from-teal-500 to-teal-600 text-white font-bold border-teal-400/50 shadow-md shadow-teal-500/10 scale-105 z-10'
                        : 'bg-slate-900 border-slate-850/60 text-slate-400 hover:text-slate-200 hover:border-slate-800'
                    }`}
                  >
                    <span className="text-[10px] uppercase font-bold tracking-wider">{day.dayLabel}</span>
                    <span className="text-base font-black font-mono leading-none">{day.dateLabel}</span>
                    
                    {count > 0 && (
                      <span className={`w-1.5 h-1.5 rounded-full ${isSelected ? 'bg-white' : 'bg-teal-550'} mt-1`} />
                    )}
                    {isDayToday && !isSelected && (
                      <span className="absolute top-1 right-1.5 w-1.5 h-1.5 bg-blue-500 rounded-full" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Thao tác nhanh (Quick Actions) */}
          <div className="space-y-3">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest px-1">Thao tác nhanh</h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              <button 
                onClick={handleNextDiagnosis}
                className="bg-white hover:bg-teal-50/30 border border-slate-200 hover:border-teal-200 p-4 rounded-2xl flex flex-col items-center justify-center gap-2.5 transition duration-300 group hover:-translate-y-0.5 active:scale-95 text-center shadow-sm"
              >
                <div className="w-12 h-12 rounded-full bg-teal-50 flex items-center justify-center text-teal-600 group-hover:bg-teal-600 group-hover:text-white transition duration-300 shadow-sm animate-pulse hover:animate-none">
                  <Stethoscope className="w-5 h-5" />
                </div>
                <span className="text-xs font-bold text-slate-600 group-hover:text-teal-700 transition">Khám tiếp</span>
              </button>

              <button 
                onClick={handleQuickConfirm}
                className="bg-white hover:bg-teal-50/30 border border-slate-200 hover:border-teal-200 p-4 rounded-2xl flex flex-col items-center justify-center gap-2.5 transition duration-300 group hover:-translate-y-0.5 active:scale-95 text-center shadow-sm"
              >
                <div className="w-12 h-12 rounded-full bg-teal-50 flex items-center justify-center text-teal-600 group-hover:bg-teal-600 group-hover:text-white transition duration-300 shadow-sm">
                  <UserCheck className="w-5 h-5" />
                </div>
                <span className="text-xs font-bold text-slate-600 group-hover:text-teal-700 transition">Xác nhận</span>
              </button>

              <button 
                onClick={handlePrescribeAction}
                className="bg-white hover:bg-teal-50/30 border border-slate-200 hover:border-teal-200 p-4 rounded-2xl flex flex-col items-center justify-center gap-2.5 transition duration-300 group hover:-translate-y-0.5 active:scale-95 text-center shadow-sm"
              >
                <div className="w-12 h-12 rounded-full bg-teal-50 flex items-center justify-center text-teal-600 group-hover:bg-teal-600 group-hover:text-white transition duration-300 shadow-sm">
                  <ClipboardCheck className="w-5 h-5" />
                </div>
                <span className="text-xs font-bold text-slate-600 group-hover:text-teal-700 transition">Kê đơn</span>
              </button>

              <button 
                onClick={() => setIsQrModalOpen(true)}
                className="bg-white hover:bg-teal-50/30 border border-slate-200 hover:border-teal-200 p-4 rounded-2xl flex flex-col items-center justify-center gap-2.5 transition duration-300 group hover:-translate-y-0.5 active:scale-95 text-center shadow-sm"
              >
                <div className="w-12 h-12 rounded-full bg-teal-50 flex items-center justify-center text-teal-600 group-hover:bg-teal-600 group-hover:text-white transition duration-300 shadow-sm">
                  <QrCode className="w-5 h-5" />
                </div>
                <span className="text-xs font-bold text-slate-600 group-hover:text-teal-700 transition">Scan QR</span>
              </button>
            </div>
          </div>

          {/* Banner đăng ký lịch trực */}
          <button
            onClick={() => router.push('/doctor/slots')}
            className="w-full bg-gradient-to-r from-teal-600 to-teal-800 hover:from-teal-500 hover:to-teal-700 border border-teal-500/30 p-4 rounded-2xl flex items-center justify-between shadow-md shadow-teal-500/10 transition duration-300 active:scale-[0.99] group text-left"
          >
            <div className="flex items-center gap-4">
              <div className="w-11 h-11 rounded-xl bg-white/10 flex items-center justify-center text-white">
                <Calendar className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-white uppercase tracking-wider">Quản lý lịch rảnh khám bệnh</h4>
                <p className="text-[11px] text-white/80 mt-0.5">Đăng ký các ca làm việc của bạn để bệnh nhân đặt hẹn</p>
              </div>
            </div>
            <ArrowRight className="w-4 h-4 text-white/80 group-hover:translate-x-1 transition duration-300" />
          </button>

          {/* Lịch hẹn ngày đã chọn */}
          <div id="appointments-section" className="space-y-3 scroll-mt-20">
            <div className="flex justify-between items-center px-1">
              <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest">
                Lịch hẹn ngày {new Date(selectedDateStr).toLocaleDateString('vi-VN')} ({selectedDateApts.length})
              </h3>
            </div>

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
                  
                  return (
                    <div 
                      key={apt.id} 
                      className="bg-white border border-slate-200 hover:border-slate-300 rounded-2xl p-4 flex flex-col sm:flex-row justify-between sm:items-center gap-4 transition duration-300 hover:shadow-sm shadow-sm"
                    >
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-xs text-slate-800">{apt.user?.name}</span>
                          <span className="text-[10px] font-mono text-slate-500 bg-slate-50 border border-slate-200 px-1.5 py-0.5 rounded font-medium">
                            {new Date(apt.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                        </div>
                        <p className="text-xs text-slate-500">Triệu chứng: {apt.title}</p>
                      </div>

                      <div className="flex items-center gap-2.5 shrink-0 self-end sm:self-auto">
                        <span className={`text-[10px] px-2 py-0.5 rounded-md font-semibold border ${
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
                              className="px-3 py-1.5 border border-red-200 bg-red-50 hover:bg-red-100 text-red-600 text-xs font-semibold rounded-lg transition duration-200"
                            >
                              Từ chối
                            </button>
                            <button
                              onClick={() => handleUpdateStatus(apt.id, 'CONFIRMED')}
                              className="px-3 py-1.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-bold rounded-lg transition duration-200"
                            >
                              Duyệt
                            </button>
                          </div>
                        )}

                        {isConfirmed && (
                          <button
                            onClick={() => router.push(`/doctor/appointments/${apt.id}/prescribe`)}
                            className="flex items-center gap-1.5 px-3 py-1.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-semibold rounded-lg transition duration-200 shadow-sm"
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

        {/* Right Column (lg:col-span-1) */}
        <div className="space-y-6">
          
          {/* Sổ tay ghi chú nhanh */}
          <div className="bg-white border border-slate-200 rounded-3xl p-5 space-y-3.5 shadow-sm relative overflow-hidden">
            <div className="flex justify-between items-center">
              <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest flex items-center gap-2">
                <BookOpen className="w-4 h-4 text-teal-600" />
                Sổ tay ghi chú nhanh
              </h3>
              <span className="text-[9px] text-teal-700 bg-teal-50 px-2 py-0.5 rounded-full font-bold border border-teal-200/50">Đã lưu</span>
            </div>
            <div className="border-l-2 border-teal-500 pl-3">
              <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Ghi chú cá nhân lâm sàng</p>
              <textarea
                value={scratchpad}
                onChange={handleScratchpadChange}
                placeholder="Nhập ghi chú nhanh tại đây (ví dụ: dị ứng, ca hội chẩn, lưu ý thuốc)..."
                className="w-full h-36 bg-slate-50 border border-slate-200 hover:border-slate-350 text-xs text-slate-700 rounded-xl p-3 focus:outline-none focus:border-teal-500 transition duration-300 resize-none font-medium placeholder-slate-400 leading-relaxed focus:bg-white"
              />
            </div>
          </div>

          {/* Lịch khám hôm nay timeline */}
          <div className="bg-white border border-slate-200 rounded-3xl p-5 space-y-4 shadow-sm">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest flex items-center gap-2">
              <ClipboardList className="w-4 h-4 text-slate-400" />
              Lịch khám hôm nay ({todayApts.length})
            </h3>
            
            {todayApts.length === 0 ? (
              <p className="text-center text-slate-500 text-xs py-4">Chưa có lịch khám nào trong hôm nay.</p>
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
                          <p className="text-[10px] text-slate-500 mt-0.5 font-medium">
                            {new Date(apt.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} · {apt.title}
                          </p>
                        </div>
                        <span className={`text-[9px] px-1.5 py-0.5 rounded font-mono font-semibold ${
                          isDone ? 'bg-emerald-50 text-emerald-600' :
                          isPending ? 'bg-amber-50 text-amber-600' :
                          'bg-blue-50 text-blue-600'
                        }`}>
                          {apt.status}
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
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-700 transition"
            >
              <X className="w-5 h-5" />
            </button>
            
            <div className="flex items-center gap-2 mb-3">
              <QrCode className="w-5 h-5 text-teal-600" />
              <h3 className="text-base font-bold text-slate-800">Trình mô phỏng quét mã QR Check-in</h3>
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
                  className="px-4 py-2 border border-slate-200 hover:bg-slate-50 text-slate-550 hover:text-slate-800 rounded-xl text-xs font-semibold transition"
                >
                  Đóng
                </button>
                <button
                  type="submit"
                  disabled={qrLoading || !qrInput.trim()}
                  className="px-5 py-2 bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white rounded-xl text-xs font-semibold transition flex items-center gap-2"
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

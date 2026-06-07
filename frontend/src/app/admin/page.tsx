'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAdminUser } from './layout';
import { StaffApi, StaffStats, PaymentOverview, Appointment, Transaction } from '@/services/staff.service';
import { RevenueChart } from '@/components/admin/RevenueChart';
import { 
  Users, ShieldCheck, Layers, Activity, Calendar, 
  TrendingUp, CheckCircle2, Clock, ClipboardList, 
  Settings, DollarSign, AlertCircle, RefreshCw,
  Search, ArrowRight, UserCheck, Stethoscope
} from 'lucide-react';

export default function AdminDashboardPage() {
  const router = useRouter();
  const user = useAdminUser();
  const role = user?.role;

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Admin stats
  const [adminStats, setAdminStats] = useState<StaffStats | null>(null);
  const [paymentOverview, setPaymentOverview] = useState<PaymentOverview | null>(null);
  const [transactions, setTransactions] = useState<Transaction[]>([]);

  // Doctor stats & appointments
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [scratchpad, setScratchpad] = useState('');

  const loadData = async () => {
    if (!role) return;
    setLoading(true);
    setError(null);
    try {
      if (role === 'ADMIN') {
        const [statsRes, paymentsRes, transactionsRes] = await Promise.all([
          StaffApi.getStats(),
          StaffApi.getPaymentOverview(),
          StaffApi.getTransactions()
        ]);
        if (statsRes.success && statsRes.data) setAdminStats(statsRes.data);
        if (paymentsRes.success && paymentsRes.data) setPaymentOverview(paymentsRes.data);
        if (transactionsRes.success && transactionsRes.data) setTransactions(transactionsRes.data);
      } else if (role === 'DOCTOR') {
        const apptRes = await StaffApi.getAppointments('ALL');
        if (apptRes.success && apptRes.data) setAppointments(apptRes.data);
        
        // Load scratchpad from localStorage
        const savedNotes = localStorage.getItem(`medichain_scratchpad_doctor_${user?.email || 'anon'}`);
        setScratchpad(savedNotes || '');
      }
    } catch (err) {
      setError('Không thể tải dữ liệu bảng điều khiển');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadData();
  }, [role]);

  const handleSaveScratchpad = (text: string) => {
    setScratchpad(text);
    localStorage.setItem(`medichain_scratchpad_doctor_${user?.email || 'anon'}`, text);
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-3">
        <RefreshCw className="w-6 h-6 text-blue-400 animate-spin" />
        <span className="text-slate-500 text-xs">Đang tải dữ liệu bảng điều khiển...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs p-4 rounded-lg flex items-center justify-between">
        <span>{error}</span>
        <button onClick={loadData} className="px-3 py-1 bg-red-500/20 hover:bg-red-500/30 rounded border border-red-500/35 transition">
          Thử lại
        </button>
      </div>
    );
  }

  if (role === 'ADMIN') {
    return renderAdminView();
  }

  if (role === 'DOCTOR') {
    return renderDoctorView();
  }

  return (
    <div className="text-slate-400 text-xs text-center py-10">
      Không xác định được vai trò người dùng.
    </div>
  );

  // ─── ADMIN DASHBOARD VIEW ──────────────────────────────────────────────────
  function renderAdminView() {
    const totalUsers = adminStats?.users.total ?? 0;
    const adminCount = adminStats?.users.admins ?? 0;
    const doctorCount = adminStats?.users.doctors ?? 0;
    const patientCount = adminStats?.users.patients ?? 0;
    const pendingReview = adminStats?.system.pendingReview ?? 0;
    const activeKeywords = adminStats?.system.activeKeywords ?? 0;
    const activeCombos = adminStats?.system.activeCombos ?? 0;
    const queries = adminStats?.activity.aiQueriesLast24h ?? 0;
    const alerts = adminStats?.activity.blockedAlertsLast24h ?? 0;
    const cacheHitRate = adminStats?.cache.hitRate ?? 'N/A';

    return (
      <div className="space-y-6">
        {/* Welcome Section */}
        <div>
          <h1 className="text-base font-semibold text-white mb-1">Bảng điều khiển hệ thống</h1>
          <p className="text-xs text-slate-500">Giám sát hiệu suất hệ thống, tri thức y tế lâm sàng và doanh thu.</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-slate-500 text-xs font-medium">Tài khoản</span>
              <Users className="w-4 h-4 text-blue-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-xl font-semibold text-white">{totalUsers}</span>
              <span className="text-[10px] text-slate-400">tổng số</span>
            </div>
            <div className="text-[10px] text-slate-500 flex justify-between border-t border-slate-800/60 pt-2">
              <span>Bác sĩ: {doctorCount}</span>
              <span>Bệnh nhân: {patientCount}</span>
            </div>
          </div>

          <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-slate-500 text-xs font-medium">Tri thức lâm sàng</span>
              <Layers className="w-4 h-4 text-emerald-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-xl font-semibold text-white">{activeKeywords + activeCombos}</span>
              <span className="text-[10px] text-slate-400">quy tắc hoạt động</span>
            </div>
            <div className="text-[10px] text-slate-500 flex justify-between border-t border-slate-800/60 pt-2">
              <span>Từ khóa: {activeKeywords}</span>
              <span>Tổ hợp: {activeCombos}</span>
            </div>
          </div>

          <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-slate-500 text-xs font-medium">Phê duyệt AI</span>
              <ShieldCheck className="w-4 h-4 text-amber-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-xl font-semibold text-white">{pendingReview}</span>
              <span className="text-[10px] text-slate-400">đề xuất mới</span>
            </div>
            <div className="text-[10px] text-slate-500 border-t border-slate-800/60 pt-2 flex justify-between">
              <span>Đang chờ duyệt kiểm duyệt y tế</span>
              <button 
                onClick={() => router.push('/admin/clinical-rules')}
                className="text-amber-400 hover:text-amber-300 font-medium"
              >
                Phê duyệt ngay
              </button>
            </div>
          </div>

          <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-slate-500 text-xs font-medium">Hiệu năng Cache</span>
              <Activity className="w-4 h-4 text-indigo-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-xl font-semibold text-white">{cacheHitRate}</span>
              <span className="text-[10px] text-slate-400">hit rate</span>
            </div>
            <div className="text-[10px] text-slate-500 border-t border-slate-800/60 pt-2">
              <span>Giúp phản hồi AI nhanh & tối ưu chi phí</span>
            </div>
          </div>
        </div>

        {/* Second Row: Revenue overview & Quick tools */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Revenue Panel */}
          <div className="md:col-span-2 bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-xs font-semibold text-white uppercase tracking-wider">Doanh thu và Tài chính</h3>
                <p className="text-[10px] text-slate-500">Tổng quan tình hình thanh toán lịch hẹn khám.</p>
              </div>
              <DollarSign className="w-4 h-4 text-emerald-500" />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2">
              <div className="bg-slate-950/60 border border-slate-800/80 p-3 rounded-lg">
                <span className="text-[10px] text-slate-500 block mb-1">Doanh thu tháng này</span>
                <span className="text-base font-semibold text-emerald-400 font-mono">
                  {paymentOverview ? (paymentOverview.revenue).toLocaleString('vi-VN') : 0} đ
                </span>
              </div>
              <div className="bg-slate-950/60 border border-slate-800/80 p-3 rounded-lg">
                <span className="text-[10px] text-slate-500 block mb-1">Doanh thu chờ duyệt</span>
                <span className="text-base font-semibold text-amber-400 font-mono">
                  {paymentOverview ? (paymentOverview.pendingRevenue).toLocaleString('vi-VN') : 0} đ
                </span>
              </div>
              <div className="bg-slate-950/60 border border-slate-800/80 p-3 rounded-lg">
                <span className="text-[10px] text-slate-500 block mb-1">Phí khám cơ bản</span>
                <span className="text-base font-semibold text-blue-400 font-mono">
                  {paymentOverview ? (paymentOverview.consultationFee).toLocaleString('vi-VN') : 0} đ
                </span>
              </div>
            </div>

            {/* 7-Day Revenue Trend Chart */}
            <div className="w-full pt-1 overflow-hidden">
              <RevenueChart 
                transactions={transactions} 
                height={135} 
                viewBox="0 0 500 135" 
                gridYMax={110} 
              />
            </div>

            <div className="text-[10px] text-slate-500 flex justify-between items-center border-t border-slate-800/60 pt-3">
              <span>Tỷ lệ hoàn tất thanh toán: {paymentOverview ? Math.round((paymentOverview.paidCount / (paymentOverview.totalCount || 1)) * 100) : 0}%</span>
              <button 
                onClick={() => router.push('/admin/payments')} 
                className="text-xs text-blue-400 hover:text-blue-300 font-medium flex items-center gap-1"
              >
                Chi tiết tài chính <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          {/* Quick Tools */}
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-4">
            <h3 className="text-xs font-semibold text-white uppercase tracking-wider">Hành động nhanh</h3>
            <div className="space-y-2">
              <button 
                onClick={() => router.push('/admin/users')}
                className="w-full flex items-center justify-between p-2.5 rounded-lg border border-slate-800 hover:border-slate-700 bg-slate-950/40 hover:bg-slate-950/80 text-left text-slate-300 hover:text-white transition-all duration-200"
              >
                <div className="flex items-center gap-2">
                  <UserCheck className="w-4 h-4 text-blue-400" />
                  <span>Xác thực bác sĩ</span>
                </div>
                <ArrowRight className="w-3.5 h-3.5 text-slate-500" />
              </button>

              <button 
                onClick={() => router.push('/admin/appointments')}
                className="w-full flex items-center justify-between p-2.5 rounded-lg border border-slate-800 hover:border-slate-700 bg-slate-950/40 hover:bg-slate-950/80 text-left text-slate-300 hover:text-white transition-all duration-200"
              >
                <div className="flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-emerald-400" />
                  <span>Quản lý lịch khám</span>
                </div>
                <ArrowRight className="w-3.5 h-3.5 text-slate-500" />
              </button>

              <button 
                onClick={() => router.push('/admin/config')}
                className="w-full flex items-center justify-between p-2.5 rounded-lg border border-slate-800 hover:border-slate-700 bg-slate-950/40 hover:bg-slate-950/80 text-left text-slate-300 hover:text-white transition-all duration-200"
              >
                <div className="flex items-center gap-2">
                  <Settings className="w-4 h-4 text-slate-400" />
                  <span>Cấu hình ngưỡng an toàn</span>
                </div>
                <ArrowRight className="w-3.5 h-3.5 text-slate-500" />
              </button>
            </div>
          </div>
        </div>

        {/* Activity Logs Telemetry */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-xs font-semibold text-white uppercase tracking-wider">Hoạt động AI (24h qua)</h3>
              <p className="text-[10px] text-slate-500">Giám sát các yêu cầu truy vấn thuốc và cảnh báo an toàn từ AI.</p>
            </div>
            <span className="text-[10px] px-2 py-0.5 bg-slate-800 text-slate-400 border border-slate-700 rounded-full font-mono">
              Live telemetry
            </span>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-slate-950/50 p-4 rounded-lg border border-slate-800/80 text-center">
              <span className="text-[10px] text-slate-500 block mb-1">Số lượt tư vấn AI</span>
              <span className="text-2xl font-bold text-white font-mono">{queries}</span>
            </div>
            <div className="bg-slate-950/50 p-4 rounded-lg border border-slate-800/80 text-center">
              <span className="text-[10px] text-slate-500 block mb-1">Cảnh báo lâm sàng bị chặn</span>
              <span className="text-2xl font-bold text-red-400 font-mono">{alerts}</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ─── DOCTOR DASHBOARD VIEW ─────────────────────────────────────────────────
  function renderDoctorView() {
    const todayStr = new Date().toDateString();
    
    // Sort & partition appointments
    const doctorTodayAppts = appointments
      .filter(a => new Date(a.date).toDateString() === todayStr)
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

    const pendingCount = appointments.filter(a => a.status === 'PENDING').length;
    const confirmedCount = doctorTodayAppts.filter(a => a.status === 'CONFIRMED' || a.status === 'CHECKED_IN').length;
    const completedTodayCount = doctorTodayAppts.filter(a => a.status === 'COMPLETED').length;

    // Next patient to examine (either CHECKED_IN first, then CONFIRMED)
    const nextApt = doctorTodayAppts.find(a => a.status === 'CHECKED_IN') || 
                    doctorTodayAppts.find(a => a.status === 'CONFIRMED');

    // Simple greeting
    const hour = new Date().getHours();
    const greeting = hour < 12 ? 'Chào buổi sáng' : hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';

    return (
      <div className="space-y-6">
        {/* Welcome Doctor Banner */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-slate-900 border border-slate-800 rounded-xl p-5">
          <div className="space-y-1">
            <h1 className="text-base font-semibold text-white">
              {greeting}, Bác sĩ {user?.name || 'MediChain'}!
            </h1>
            <p className="text-xs text-slate-400">
              Hôm nay bạn có <span className="text-emerald-450 font-semibold">{doctorTodayAppts.length} lịch hẹn khám</span> tại phòng mạch.
            </p>
          </div>
          <div className="text-right">
            <div className="text-xs font-semibold text-emerald-450">
              {new Date().toLocaleDateString('vi-VN', { weekday: 'long', day: '2-digit', month: '2-digit' })}
            </div>
            <div className="text-[10px] text-slate-500 font-mono">Giờ phòng khám hoạt động</div>
          </div>
        </div>

        {/* Doctor Stats Row */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-slate-900/60 border border-slate-850 p-4 rounded-xl text-left space-y-1">
            <span className="text-[10px] text-slate-500 block uppercase tracking-wider">Chờ xác nhận</span>
            <span className="text-xl font-bold text-amber-500 font-mono">{pendingCount}</span>
          </div>
          <div className="bg-slate-900/60 border border-slate-850 p-4 rounded-xl text-left space-y-1">
            <span className="text-[10px] text-slate-500 block uppercase tracking-wider">Chưa khám hôm nay</span>
            <span className="text-xl font-bold text-blue-400 font-mono">{confirmedCount}</span>
          </div>
          <div className="bg-slate-900/60 border border-slate-850 p-4 rounded-xl text-left space-y-1">
            <span className="text-[10px] text-slate-500 block uppercase tracking-wider">Đã hoàn thành</span>
            <span className="text-xl font-bold text-emerald-400 font-mono">{completedTodayCount}</span>
          </div>
        </div>

        {/* Next Patient Card & Scratchpad */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Next Patient Card (Hero) */}
          <div className="md:col-span-2 space-y-4">
            <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Bệnh nhân tiếp theo</h2>
            
            {nextApt ? (
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-4 relative overflow-hidden">
                <div className="flex items-start justify-between">
                  <div>
                    <span className="text-[10px] font-semibold text-emerald-400 border border-emerald-500/20 bg-emerald-500/10 px-2 py-0.5 rounded uppercase">
                      {nextApt.status === 'CHECKED_IN' ? 'Đã Check-in' : 'Đã Xác nhận'}
                    </span>
                    <h3 className="text-base font-semibold text-white mt-2">{nextApt.user.name}</h3>
                    <p className="text-xs text-slate-400 mt-0.5 flex items-center gap-1.5">
                      <Clock className="w-3.5 h-3.5 text-slate-500" />
                      {new Date(nextApt.date).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                  
                  <div className="text-right text-[11px] text-slate-500">
                    <span className="block font-medium text-slate-400">{nextApt.title}</span>
                    <span>SĐT: {nextApt.user.profile?.phone || 'Không có'}</span>
                  </div>
                </div>

                <div className="border-t border-slate-800/80 pt-4 flex items-center justify-between">
                  <span className="text-[10px] text-slate-500">Bắt đầu ghi nhận lâm sàng & đơn thuốc.</span>
                  <button 
                    onClick={() => router.push(`/admin/appointments/${nextApt.id}/prescribe`)}
                    className="flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-750 text-white rounded-lg text-xs font-semibold transition"
                  >
                    <Stethoscope className="w-3.5 h-3.5" />
                    Bắt đầu khám
                  </button>
                </div>
              </div>
            ) : (
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-8 text-center text-slate-500 text-xs">
                Không có lịch hẹn khám nào tiếp theo.
              </div>
            )}
          </div>

          {/* Scratchpad */}
          <div className="space-y-4">
            <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Sổ tay nháp bác sĩ</h2>
            <div className="bg-slate-900 border-l-2 border-l-amber-500 border-y border-r border-slate-800 rounded-r-xl p-4 flex flex-col gap-3 h-[180px]">
              <textarea
                placeholder="Ghi chú nhanh thông tin lâm sàng tạm thời (tự động lưu nháp)..."
                value={scratchpad}
                onChange={e => handleSaveScratchpad(e.target.value)}
                className="w-full flex-1 bg-transparent border-none p-0 text-xs text-slate-200 placeholder-slate-650 focus:outline-none resize-none leading-relaxed font-mono"
              />
              <div className="flex items-center justify-between text-[9px] text-slate-550">
                <span>Tự động lưu nháp</span>
                <span>{scratchpad.length} ký tự</span>
              </div>
            </div>
          </div>
        </div>

        {/* Today's Timeline list */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xs font-semibold text-white uppercase tracking-wider">Lịch hẹn khám hôm nay</h2>
            <span className="text-[10px] text-slate-500">{doctorTodayAppts.length} lịch hẹn</span>
          </div>

          {doctorTodayAppts.length === 0 ? (
            <p className="text-xs text-slate-600 text-center py-6">Không có lịch hẹn khám nào trong ngày.</p>
          ) : (
            <div className="space-y-2 divide-y divide-slate-800/40">
              {doctorTodayAppts.map((appt, i) => {
                const isCompleted = appt.status === 'COMPLETED';
                const isCheckin = appt.status === 'CHECKED_IN';
                const isConfirmed = appt.status === 'CONFIRMED';
                const isPending = appt.status === 'PENDING';
                
                return (
                  <div key={appt.id} className={`flex items-center justify-between py-3 ${i > 0 ? 'border-t border-slate-800/40' : ''}`}>
                    <div className="flex items-center gap-3">
                      <div className="font-mono text-xs text-slate-400 bg-slate-950/80 px-2 py-1 rounded border border-slate-800">
                        {new Date(appt.date).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                      </div>
                      <div>
                        <div className="text-xs font-semibold text-slate-200">{appt.user.name}</div>
                        <div className="text-[10px] text-slate-500">{appt.title}</div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className={`text-[9px] px-1.5 py-0.5 rounded font-semibold ${
                        isCompleted ? 'bg-emerald-500/10 text-emerald-455 border border-emerald-500/20' :
                        isCheckin ? 'bg-blue-500/10 text-blue-455 border border-blue-500/20' :
                        isConfirmed ? 'bg-teal-500/10 text-teal-455 border border-teal-500/20' :
                        isPending ? 'bg-amber-500/10 text-amber-455 border border-amber-500/20' :
                        'bg-slate-800 text-slate-400'
                      }`}>
                        {isCompleted ? 'Hoàn thành' : isCheckin ? 'Đã check-in' : isConfirmed ? 'Đã xác nhận' : isPending ? 'Chờ duyệt' : appt.status}
                      </span>

                      {(isConfirmed || isCheckin) && (
                        <button
                          onClick={() => router.push(`/admin/appointments/${appt.id}/prescribe`)}
                          className="flex items-center gap-1 px-2.5 py-1 bg-emerald-600/10 hover:bg-emerald-600/25 border border-emerald-500/30 text-emerald-400 rounded transition text-[10px]"
                        >
                          Khám
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
    );
  }
}

'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAdminUser } from './layout';
import { StaffApi, StaffStats, PaymentOverview } from '@/services/staff.service';
import { 
  Users, ShieldCheck, Layers, Calendar, 
  TrendingUp, ClipboardList, Settings, 
  AlertCircle, RefreshCw, ArrowRight, Stethoscope
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

  const loadData = async () => {
    if (!role) return;
    setLoading(true);
    setError(null);
    try {
      if (role === 'ADMIN') {
        const [statsRes, paymentsRes] = await Promise.all([
          StaffApi.getStats(),
          StaffApi.getPaymentOverview(),
        ]);
        if (statsRes.success && statsRes.data) setAdminStats(statsRes.data);
        if (paymentsRes.success && paymentsRes.data) setPaymentOverview(paymentsRes.data);
      }
    } catch (err) {
      setError('Không thể tải dữ liệu bảng điều khiển');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (role === 'DOCTOR') {
      router.replace('/doctor');
      return;
    }
    void loadData();
  }, [role, router]);

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

  return (
    <div className="text-slate-400 text-xs text-center py-10">
      Không xác định được vai trò người dùng.
    </div>
  );

  // ─── ADMIN DASHBOARD VIEW ──────────────────────────────────────────────────
  function renderAdminView() {
    const totalUsers = adminStats?.users.total ?? 0;
    const doctorCount = adminStats?.users.doctors ?? 0;
    const patientCount = adminStats?.users.patients ?? 0;
    const pendingReview = adminStats?.system.pendingReview ?? 0;
    const activeKeywords = adminStats?.system.activeKeywords ?? 0;
    const activeCombos = adminStats?.system.activeCombos ?? 0;

    // Simple greeting
    const hour = new Date().getHours();
    const greeting = hour < 12 ? 'Chào buổi sáng' : hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';
    
    // Formatting Vietnamese date
    const now = new Date();
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    const dateStr = `${days[now.getDay()]}, ${now.getDate().toString().padStart(2, '0')}/${(now.getMonth() + 1).toString().padStart(2, '0')}/${now.getFullYear()}`;

    return (
      <div className="space-y-6 max-w-4xl mx-auto animate-fade-in">
        {/* Header (Premium Operations Banner) */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-[#182030] border border-[#2a3a50] rounded-2xl p-5 shadow-lg">
          <div className="space-y-1">
            <span className="text-[10px] uppercase font-bold tracking-wider text-[#8a9bb5]">{greeting}</span>
            <h1 className="text-lg font-extrabold text-white tracking-tight">Hệ thống MediChain</h1>
            <p className="text-xs text-[#8a9bb5]">Trung tâm vận hành và cấu hình nền tảng y tế.</p>
          </div>
          <div className="flex items-center gap-2 bg-[#0d1520] border border-[#2a3a50] px-3 py-1.5 rounded-lg shadow-inner">
            <Calendar className="w-3.5 h-3.5 text-[#8a9bb5]" />
            <span className="text-xs font-mono font-semibold text-[#8a9bb5]">{dateStr}</span>
          </div>
        </div>

        {/* Stats Grid (2x2) */}
        <div>
          <div className="flex items-center gap-1.5 px-1 mb-3">
            <TrendingUp className="w-3.5 h-3.5 text-[#8a9bb5]" />
            <span className="text-[10px] font-bold text-[#8a9bb5] uppercase tracking-wider">Thống kê hệ thống</span>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {/* Patients */}
            <div className="bg-[#182030] border border-[#2a3a50] p-4 rounded-xl space-y-1 shadow-sm">
              <div className="flex items-center justify-between text-[#8a9bb5]">
                <span className="text-xs font-semibold">Bệnh nhân</span>
                <Users className="w-4 h-4 text-emerald-400" />
              </div>
              <p className="text-2xl font-bold text-white font-mono">{patientCount}</p>
              <p className="text-[10px] text-[#8a9bb5] pt-1 border-t border-[#2a3a50]/40">Hoạt động</p>
            </div>
            {/* Doctors */}
            <div className="bg-[#182030] border border-[#2a3a50] p-4 rounded-xl space-y-1 shadow-sm">
              <div className="flex items-center justify-between text-[#8a9bb5]">
                <span className="text-xs font-semibold">Bác sĩ</span>
                <Stethoscope className="w-4 h-4 text-blue-400" />
              </div>
              <p className="text-2xl font-bold text-white font-mono">{doctorCount}</p>
              <p className="text-[10px] text-[#8a9bb5] pt-1 border-t border-[#2a3a50]/40">Đã xác minh</p>
            </div>
            {/* Accounts */}
            <div className="bg-[#182030] border border-[#2a3a50] p-4 rounded-xl space-y-1 shadow-sm">
              <div className="flex items-center justify-between text-[#8a9bb5]">
                <span className="text-xs font-semibold">Tổng tài khoản</span>
                <ShieldCheck className="w-4 h-4 text-amber-500" />
              </div>
              <p className="text-2xl font-bold text-white font-mono">{totalUsers}</p>
              <p className="text-[10px] text-[#8a9bb5] pt-1 border-t border-[#2a3a50]/40">Đang hoạt động</p>
            </div>
            {/* Appointments */}
            <div className="bg-[#182030] border border-[#2a3a50] p-4 rounded-xl space-y-1 shadow-sm">
              <div className="flex items-center justify-between text-[#8a9bb5]">
                <span className="text-xs font-semibold">Tổng lịch hẹn</span>
                <Calendar className="w-4 h-4 text-indigo-400" />
              </div>
              <p className="text-2xl font-bold text-white font-mono">{paymentOverview?.totalCount ?? 0}</p>
              <p className="text-[10px] text-[#8a9bb5] pt-1 border-t border-[#2a3a50]/40">
                {paymentOverview?.pendingCount ?? 0} chờ duyệt
              </p>
            </div>
          </div>
        </div>

        {/* Command Center Sections */}
        <div className="space-y-5">
          {/* Section: Duyệt & Kiểm soát */}
          <div className="space-y-2">
            <span className="text-[10px] font-bold text-[#4e6280] uppercase tracking-wider px-1">Duyệt & Kiểm soát</span>
            <div className="bg-[#182030] border border-[#2a3a50] rounded-2xl overflow-hidden divide-y divide-[#2a3a50]">
              {/* Row 1 */}
              <button 
                onClick={() => router.push('/admin/clinical-rules')}
                className="w-full flex items-center justify-between p-4 hover:bg-[#1f2a3f] text-left transition-all duration-200"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#6366f1]/10 flex items-center justify-center text-[#6366f1]">
                    <ShieldCheck className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white flex items-center gap-2">
                      <span>Duyệt đề xuất AI</span>
                      {pendingReview > 0 && (
                        <span className="bg-amber-500/10 text-amber-400 border border-amber-500/25 px-1.5 py-0.5 rounded text-[9px] font-mono font-bold">
                          {pendingReview}
                        </span>
                      )}
                    </div>
                    <div className="text-[10px] text-[#8a9bb5]">Xem xét phê duyệt các đề xuất keyword tự động của AI</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-[#4e6280]" />
              </button>
              {/* Row 2 */}
              <button 
                onClick={() => router.push('/admin/telemetry')}
                className="w-full flex items-center justify-between p-4 hover:bg-[#1f2a3f] text-left transition-all duration-200"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#10b981]/10 flex items-center justify-center text-[#10b981]">
                    <ClipboardList className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white">Nhật ký hoạt động</div>
                    <div className="text-[10px] text-[#8a9bb5]">Theo dõi các cảnh báo và luồng tương tác hệ thống</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-[#4e6280]" />
              </button>
            </div>
          </div>

          {/* Section: Tri thức lâm sàng */}
          <div className="space-y-2">
            <span className="text-[10px] font-bold text-[#4e6280] uppercase tracking-wider px-1">Tri thức lâm sàng</span>
            <div className="bg-[#182030] border border-[#2a3a50] rounded-2xl overflow-hidden divide-y divide-[#2a3a50]">
              {/* Row 1 */}
              <button 
                onClick={() => router.push('/admin/clinical-rules/keywords')}
                className="w-full flex items-center justify-between p-4 hover:bg-[#1f2a3f] text-left transition-all duration-200"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#ef4444]/10 flex items-center justify-center text-[#ef4444]">
                    <AlertCircle className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white flex items-center gap-2">
                      <span>Từ khóa an toàn</span>
                      <span className="bg-[#ef4444]/10 text-red-400 border border-[#ef4444]/20 px-1.5 py-0.5 rounded text-[9px] font-mono">
                        {activeKeywords} active
                      </span>
                    </div>
                    <div className="text-[10px] text-[#8a9bb5]">Danh mục từ khóa hạn chế và mức độ ưu tiên lâm sàng</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-[#4e6280]" />
              </button>
              {/* Row 2 */}
              <button 
                onClick={() => router.push('/admin/clinical-rules/combos')}
                className="w-full flex items-center justify-between p-4 hover:bg-[#1f2a3f] text-left transition-all duration-200"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#8b5cf6]/10 flex items-center justify-center text-[#8b5cf6]">
                    <Layers className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white flex items-center gap-2">
                      <span>Quy tắc tổ hợp</span>
                      <span className="bg-[#8b5cf6]/10 text-purple-400 border border-[#8b5cf6]/20 px-1.5 py-0.5 rounded text-[9px] font-mono">
                        {activeCombos} active
                      </span>
                    </div>
                    <div className="text-[10px] text-[#8a9bb5]">Tổ hợp triệu chứng sinh học kích hoạt cảnh báo nguy cấp</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-[#4e6280]" />
              </button>
            </div>
          </div>

          {/* Section: Người dùng & Hệ thống */}
          <div className="space-y-2">
            <span className="text-[10px] font-bold text-[#4e6280] uppercase tracking-wider px-1">Người dùng & Hệ thống</span>
            <div className="bg-[#182030] border border-[#2a3a50] rounded-2xl overflow-hidden divide-y divide-[#2a3a50]">
              {/* Row 1 */}
              <button 
                onClick={() => router.push('/admin/users')}
                className="w-full flex items-center justify-between p-4 hover:bg-[#1f2a3f] text-left transition-all duration-200"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#3b82f6]/10 flex items-center justify-center text-[#3b82f6]">
                    <Users className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white">Quản lý người dùng</div>
                    <div className="text-[10px] text-[#8a9bb5]">Xem danh sách thành viên, phân quyền và duyệt chứng chỉ hành nghề bác sĩ</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-[#4e6280]" />
              </button>
              {/* Row 2 */}
              <button 
                onClick={() => router.push('/admin/config')}
                className="w-full flex items-center justify-between p-4 hover:bg-[#1f2a3f] text-left transition-all duration-200"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#f59e0b]/10 flex items-center justify-center text-[#f59e0b]">
                    <Settings className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white">Cấu hình hệ thống</div>
                    <div className="text-[10px] text-[#8a9bb5]">Thiết lập giới hạn tần suất gọi AI và thông số an toàn toàn cục</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-[#4e6280]" />
              </button>
            </div>
          </div>
        </div>

        {/* Role Boundary Note */}
        <div className="bg-[#101927]/60 border border-[#2a3a50]/60 rounded-xl p-4 text-center">
          <p className="text-[10.5px] leading-relaxed text-[#4e6280]">
            Vai trò quản trị hệ thống: Quyền giám sát AI, từ điển y khoa lâm sàng và điều phối người dùng ứng dụng.
          </p>
        </div>
      </div>
    );
  }
}

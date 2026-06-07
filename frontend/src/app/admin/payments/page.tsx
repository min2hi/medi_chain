'use client';

import { useState, useEffect } from 'react';
import { StaffApi, PaymentOverview, Transaction } from '@/services/staff.service';
import { 
  CreditCard, DollarSign, TrendingUp, HelpCircle, 
  Settings2, ArrowUpRight, CheckCircle2, XCircle, Clock,
  RefreshCw, Save
} from 'lucide-react';

const STATUS_CONFIG = {
  PAID:    { label: 'Thành công', color: 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/20' },
  PENDING: { label: 'Chờ duyệt',   color: 'bg-amber-500/15 text-amber-400 border border-amber-500/20' },
  FAILED:  { label: 'Thất bại',    color: 'bg-red-500/15 text-red-400 border border-red-500/20' },
} as const;

export default function PaymentsPage() {
  const [overview, setOverview] = useState<PaymentOverview | null>(null);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Consultation fee editor states
  const [feeInput, setFeeInput] = useState<string>('');
  const [updatingFee, setUpdatingFee] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const loadPaymentsData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [overRes, transRes] = await Promise.all([
        StaffApi.getPaymentOverview(),
        StaffApi.getTransactions()
      ]);
      if (overRes.success && overRes.data) {
        setOverview(overRes.data);
        setFeeInput(overRes.data.consultationFee.toString());
      }
      if (transRes.success && transRes.data) {
        setTransactions(transRes.data);
      }
    } catch {
      setError('Không thể tải dữ liệu tài chính');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadPaymentsData();
  }, []);

  const handleUpdateFee = async (e: React.FormEvent) => {
    e.preventDefault();
    const feeNum = parseFloat(feeInput);
    if (isNaN(feeNum) || feeNum < 0) {
      alert('Vui lòng nhập số tiền hợp lệ');
      return;
    }

    setUpdatingFee(true);
    try {
      const res = await StaffApi.updateConsultationFee(feeNum);
      if (res.success) {
        setToast('Đã cập nhật phí tư vấn khám thành công');
        setTimeout(() => setToast(null), 3000);
        // Refresh overview
        const overRes = await StaffApi.getPaymentOverview();
        if (overRes.success && overRes.data) {
          setOverview(overRes.data);
        }
      } else {
        alert(res.message || 'Cập nhật phí khám thất bại');
      }
    } catch {
      alert('Lỗi kết nối máy chủ');
    } finally {
      setUpdatingFee(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <CreditCard className="w-5 h-5 text-slate-400" />
            <h1 className="text-base font-semibold text-white">Doanh thu và Tài chính</h1>
            <span className="text-[10px] bg-slate-800 text-slate-400 border border-slate-700 px-2.5 py-0.5 rounded-full font-mono uppercase">
              Admin Only
            </span>
          </div>
          <p className="text-xs text-slate-500">
            Thống kê doanh thu thực tế, cấu hình phí dịch vụ phòng khám và lịch sử giao dịch.
          </p>
        </div>
        <button 
          onClick={loadPaymentsData} 
          className="p-1.5 bg-slate-900 border border-slate-800 text-slate-400 hover:text-slate-200 rounded-lg hover:border-slate-700 transition"
          title="Tải lại dữ liệu"
        >
          <RefreshCw className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Toast */}
      {toast && (
        <div className="flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2.5 rounded-lg animate-in fade-in duration-200">
          <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />
          {toast}
        </div>
      )}

      {error && (
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs px-4 py-2.5 rounded-lg">
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center py-20 gap-3 text-slate-500 text-xs">
          <div className="w-5 h-5 border-2 border-slate-700 border-t-blue-400 rounded-full animate-spin" />
          Đang tải dữ liệu tài chính...
        </div>
      ) : (
        <>
          {/* Financial Metrics Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2 relative overflow-hidden">
              <div className="flex items-center justify-between">
                <span className="text-slate-500 text-xs font-medium">Doanh thu hoàn tất</span>
                <DollarSign className="w-4 h-4 text-emerald-500" />
              </div>
              <div className="flex items-baseline gap-2">
                <span className="text-xl font-bold text-white font-mono">
                  {overview ? overview.revenue.toLocaleString('vi-VN') : 0} đ
                </span>
              </div>
              <p className="text-[10px] text-slate-500">Thanh toán hoàn tất trong tháng.</p>
              <div className="absolute right-0 bottom-0 translate-x-2 translate-y-2 opacity-5 pointer-events-none">
                <TrendingUp className="w-20 h-20 text-emerald-400" />
              </div>
            </div>

            <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2 relative overflow-hidden">
              <div className="flex items-center justify-between">
                <span className="text-slate-500 text-xs font-medium">Doanh thu chờ duyệt</span>
                <Clock className="w-4 h-4 text-amber-500" />
              </div>
              <div className="flex items-baseline gap-2">
                <span className="text-xl font-bold text-white font-mono">
                  {overview ? overview.pendingRevenue.toLocaleString('vi-VN') : 0} đ
                </span>
              </div>
              <p className="text-[10px] text-slate-500">Các cuộc hẹn chưa thanh toán hoặc đang duyệt.</p>
            </div>

            <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2 relative overflow-hidden">
              <div className="flex items-center justify-between">
                <span className="text-slate-500 text-xs font-medium">Lịch hẹn thanh toán</span>
                <TrendingUp className="w-4 h-4 text-blue-500" />
              </div>
              <div className="flex items-baseline gap-2">
                <span className="text-xl font-bold text-white font-mono">
                  {overview ? overview.totalCount : 0}
                </span>
                <span className="text-[10px] text-slate-400">giao dịch</span>
              </div>
              <p className="text-[10px] text-slate-500">Tỷ lệ thanh toán hoàn tất: {overview ? Math.round((overview.paidCount / (overview.totalCount || 1)) * 100) : 0}%</p>
            </div>
          </div>

          {/* Consultation Fee Config Panel */}
          <div className="bg-slate-900 border border-slate-800 p-5 rounded-xl space-y-4">
            <div className="flex items-center gap-2">
              <Settings2 className="w-4 h-4 text-blue-400" />
              <h2 className="text-xs font-semibold text-white uppercase tracking-wider">Cấu hình phí tư vấn cơ bản</h2>
            </div>
            <p className="text-[11px] text-slate-500">
              Thiết lập số tiền phí dịch vụ khám lâm sàng cơ bản của phòng khám được áp dụng tự động cho mỗi lịch hẹn đăng ký mới.
            </p>
            
            <form onSubmit={handleUpdateFee} className="flex max-w-xs gap-2 items-center">
              <div className="relative flex-1">
                <input
                  type="text"
                  required
                  placeholder="Nhập phí khám..."
                  value={feeInput}
                  onChange={e => setFeeInput(e.target.value.replace(/[^0-9]/g, ''))}
                  className="w-full bg-slate-950 border border-slate-800 text-xs text-slate-200 rounded-md pl-3 pr-8 py-2 focus:outline-none focus:border-slate-750 font-mono"
                />
                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] text-slate-600 font-medium">đ</span>
              </div>
              <button
                type="submit"
                disabled={updatingFee}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-md transition flex items-center gap-1.5"
              >
                {updatingFee ? '...' : <Save className="w-3.5 h-3.5" />}
                Lưu
              </button>
            </form>
          </div>

          {/* Transactions Table Log */}
          <div className="space-y-3">
            <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Lịch sử giao dịch (Gần nhất)</h2>
            <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
              {transactions.length === 0 ? (
                <div className="text-center py-12 text-slate-600 text-xs">Chưa ghi nhận giao dịch nào.</div>
              ) : (
                <table className="w-full text-xs text-left">
                  <thead>
                    <tr className="border-b border-slate-800">
                      <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Giao dịch</th>
                      <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Bệnh nhân</th>
                      <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Loại dịch vụ</th>
                      <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Số tiền</th>
                      <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Trạng thái</th>
                      <th className="px-4 py-3 text-right text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Thời gian</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60 font-medium text-slate-300">
                    {transactions.map(tx => {
                      const st = STATUS_CONFIG[tx.status];
                      return (
                        <tr key={tx.id} className="hover:bg-slate-800/20 transition-colors">
                          <td className="px-4 py-3 font-mono text-[10px] text-slate-500">
                            #{tx.id.substring(0, 8).toUpperCase()}
                          </td>
                          <td className="px-4 py-3 text-slate-200">{tx.patientName}</td>
                          <td className="px-4 py-3 text-slate-550">{tx.type}</td>
                          <td className="px-4 py-3 font-mono text-slate-200">
                            {tx.amount.toLocaleString('vi-VN')} đ
                          </td>
                          <td className="px-4 py-3">
                            <span className={`px-2 py-0.5 rounded text-[10px] font-semibold flex items-center gap-1 w-max ${st.color}`}>
                              {tx.status === 'PAID' && <CheckCircle2 className="w-2.5 h-2.5" />}
                              {tx.status === 'PENDING' && <Clock className="w-2.5 h-2.5" />}
                              {tx.status === 'FAILED' && <XCircle className="w-2.5 h-2.5" />}
                              {st.label}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-right text-slate-500 font-mono text-[11px]">
                            {new Date(tx.date).toLocaleDateString('vi-VN')} {new Date(tx.date).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}

'use client';

import React, { useEffect, useState } from 'react';
import { DoctorSlotsApi } from '@/services/api.client';
import { 
  Plus, Loader2, AlertCircle, CheckCircle2, 
  CalendarDays, ShieldCheck, HelpCircle, Sun, 
  Moon, Sparkles
} from 'lucide-react';

interface Slot {
  id: string;
  startTime: string;
  endTime: string;
  isBooked: boolean;
}

interface Preset {
  id: string;
  label: string;
  start: string;
  end: string;
  period: 'morning' | 'afternoon';
}

const TIME_PRESETS: Preset[] = [
  // Morning shifts
  { id: 'm1', label: '08:00 - 09:00', start: '08:00', end: '09:00', period: 'morning' },
  { id: 'm2', label: '09:00 - 10:00', start: '09:00', end: '10:00', period: 'morning' },
  { id: 'm3', label: '10:00 - 11:00', start: '10:00', end: '11:00', period: 'morning' },
  { id: 'm4', label: '11:00 - 12:00', start: '11:00', end: '12:00', period: 'morning' },
  // Afternoon shifts
  { id: 'a1', label: '13:00 - 14:00', start: '13:00', end: '14:00', period: 'afternoon' },
  { id: 'a2', label: '14:00 - 15:00', start: '14:00', end: '15:00', period: 'afternoon' },
  { id: 'a3', label: '15:00 - 16:00', start: '15:00', end: '16:00', period: 'afternoon' },
  { id: 'a4', label: '16:00 - 17:00', start: '16:00', end: '17:00', period: 'afternoon' },
  { id: 'a5', label: '17:00 - 18:00', start: '17:00', end: '18:00', period: 'afternoon' },
];

export default function DoctorSlots() {
  const [slots, setSlots] = useState<Slot[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [submittingCustom, setSubmittingCustom] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Selected date for slot manager (defaults to today's date YYYY-MM-DD)
  const [selectedDateStr, setSelectedDateStr] = useState('');
  
  // Custom slot form states
  const [customStartTime, setCustomStartTime] = useState('08:00');
  const [customEndTime, setCustomEndTime] = useState('09:00');

  useEffect(() => {
    const todayStr = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
    setSelectedDateStr(todayStr);
  }, []);

  const loadSlots = async () => {
    setLoading(true);
    try {
      const res = await DoctorSlotsApi.list();
      if (res.success && res.data) {
        setSlots(res.data);
      } else {
        setError(res.message || 'Không thể tải danh sách khung giờ làm việc');
      }
    } catch {
      setError('Lỗi kết nối máy chủ');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadSlots();
  }, []);

  const getWeeklyDays = () => {
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
  };

  const weeklyDays = getWeeklyDays();

  // Helper: check if a specific date has any slots
  const getSlotsCountForDate = (dateStr: string) => {
    return slots.filter(s => {
      const localDateStr = new Date(s.startTime).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      return localDateStr === dateStr;
    }).length;
  };

  // Filter slots for the currently selected date
  const getSlotsForSelectedDate = () => {
    return slots.filter(s => {
      const localDateStr = new Date(s.startTime).toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10);
      return localDateStr === selectedDateStr;
    });
  };

  const selectedDateSlots = getSlotsForSelectedDate();

  // Format a local date + time string into ISO format safely
  const createISODatetime = (dateStr: string, timeStr: string) => {
    // Return ISO string for Local date + time using Asia/Ho_Chi_Minh timezone
    const [h, m] = timeStr.split(':');
    const dateObj = new Date(`${dateStr}T${h}:${m}:00+07:00`);
    return dateObj.toISOString();
  };

  // Toggle activation (create or delete slot)
  const handleTogglePresetSlot = async (preset: Preset) => {
    setError(null);
    setSuccess(null);

    const startIso = createISODatetime(selectedDateStr, preset.start);
    const endIso = createISODatetime(selectedDateStr, preset.end);

    // Check if slot already exists in DB
    const existingSlot = selectedDateSlots.find(s => {
      const startLocalTime = new Date(s.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
      return startLocalTime === preset.start;
    });

    if (existingSlot) {
      if (existingSlot.isBooked) {
        setError('Không thể hủy khung giờ đã được bệnh nhân đặt lịch.');
        return;
      }

      // Delete/cancel slot
      setActionLoadingId(existingSlot.id);
      try {
        const res = await DoctorSlotsApi.delete(existingSlot.id);
        if (res.success) {
          setSuccess(`Đã hủy khung giờ ${preset.label} thành công.`);
          // Reload list
          const listRes = await DoctorSlotsApi.list();
          if (listRes.success && listRes.data) setSlots(listRes.data);
        } else {
          setError(res.message || 'Lỗi khi hủy khung giờ.');
        }
      } catch {
        setError('Lỗi kết nối máy chủ');
      } finally {
        setActionLoadingId(null);
      }
    } else {
      // Chặn ca trực trong quá khứ
      if (new Date(startIso) < new Date()) {
        setError('Không thể mở ca trực trong quá khứ.');
        return;
      }

      // Kiểm tra trùng lặp lịch trực
      const presetStart = new Date(startIso);
      const presetEnd = new Date(endIso);
      const localOverlap = slots.find(s => {
        const existingStart = new Date(s.startTime);
        const existingEnd = new Date(s.endTime);
        return existingStart < presetEnd && existingEnd > presetStart;
      });

      if (localOverlap) {
        const overlapStart = new Date(localOverlap.startTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Asia/Ho_Chi_Minh' });
        const overlapEnd = new Date(localOverlap.endTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Asia/Ho_Chi_Minh' });
        setError(`Không thể mở ca trực này vì trùng lặp với lịch trực đã có: ${overlapStart} - ${overlapEnd}`);
        return;
      }

      // Create/open slot
      setActionLoadingId(preset.id);
      try {
        const res = await DoctorSlotsApi.create({ startTime: startIso, endTime: endIso });
        if (res.success) {
          setSuccess(`Đã mở khung giờ ${preset.label} thành công.`);
          // Reload list
          const listRes = await DoctorSlotsApi.list();
          if (listRes.success && listRes.data) setSlots(listRes.data);
        } else {
          setError(res.message || 'Lỗi khi mở khung giờ.');
        }
      } catch {
        setError('Lỗi kết nối máy chủ');
      } finally {
        setActionLoadingId(null);
      }
    }
  };

  // Add custom slot manually (custom time picker)
  const handleAddCustomSlot = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmittingCustom(true);
    setError(null);
    setSuccess(null);

    const startIso = createISODatetime(selectedDateStr, customStartTime);
    const endIso = createISODatetime(selectedDateStr, customEndTime);
    const newStart = new Date(startIso);
    const newEnd = new Date(endIso);

    if (newStart >= newEnd) {
      setError('Thời gian bắt đầu phải trước thời gian kết thúc');
      setSubmittingCustom(false);
      return;
    }

    if (newStart < new Date()) {
      setError('Không thể đăng ký lịch trực trong quá khứ.');
      setSubmittingCustom(false);
      return;
    }

    // Kiểm tra trùng lặp lịch trực cục bộ
    const localOverlap = slots.find(s => {
      const existingStart = new Date(s.startTime);
      const existingEnd = new Date(s.endTime);
      return existingStart < newEnd && existingEnd > newStart;
    });

    if (localOverlap) {
      const overlapStart = new Date(localOverlap.startTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Asia/Ho_Chi_Minh' });
      const overlapEnd = new Date(localOverlap.endTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Asia/Ho_Chi_Minh' });
      const overlapDate = new Date(localOverlap.startTime).toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
      setError(`Khung giờ này trùng lặp với lịch trực đã có: ${overlapStart} - ${overlapEnd} ngày ${overlapDate}`);
      setSubmittingCustom(false);
      return;
    }

    try {
      const res = await DoctorSlotsApi.create({ startTime: startIso, endTime: endIso });
      if (res.success) {
        setSuccess('Đã đăng ký khung giờ rảnh tùy chỉnh!');
        const listRes = await DoctorSlotsApi.list();
        if (listRes.success && listRes.data) setSlots(listRes.data);
      } else {
        setError(res.message || 'Lỗi khi đăng ký khung giờ rảnh');
      }
    } catch {
      setError('Lỗi kết nối máy chủ');
    } finally {
      setSubmittingCustom(false);
    }
  };

  // Render Preset Slots list Helper
  const renderPresetCard = (preset: Preset) => {
    const matchedSlot = selectedDateSlots.find(s => {
      const startLocalTime = new Date(s.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
      return startLocalTime === preset.start;
    });

    const isPendingAction = actionLoadingId === preset.id || (matchedSlot && actionLoadingId === matchedSlot.id);
    const isBooked = matchedSlot?.isBooked || false;
    const isOpened = !!matchedSlot && !isBooked;

    let cardStyle = 'bg-white border-slate-200 text-slate-500 hover:border-slate-350 hover:text-slate-800 shadow-sm';
    if (isBooked) {
      cardStyle = 'bg-blue-50 border-blue-200 text-blue-600 cursor-not-allowed';
    } else if (isOpened) {
      cardStyle = 'bg-teal-50 border-teal-205 text-teal-600 hover:bg-teal-100/50';
    }

    return (
      <button
        key={preset.id}
        onClick={() => !isBooked && void handleTogglePresetSlot(preset)}
        disabled={isBooked || isPendingAction}
        className={`w-full py-3.5 px-4 rounded-2xl border text-xs font-bold text-center transition-all duration-300 relative group active:scale-[0.98] ${cardStyle}`}
      >
        {isPendingAction ? (
          <div className="flex items-center justify-center gap-1.5">
            <Loader2 className="w-3.5 h-3.5 animate-spin text-teal-400" />
            <span>Đang lưu...</span>
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center gap-0.5">
            <span className="font-mono text-xs">{preset.label}</span>
            {isBooked ? (
              <span className="text-[9px] bg-blue-50 border border-blue-200 px-1.5 py-0.5 rounded-full font-bold uppercase tracking-wider mt-1 text-blue-600">
                Đã đặt lịch
              </span>
            ) : isOpened ? (
              <span className="text-[9px] bg-teal-50 border border-teal-205 px-1.5 py-0.5 rounded-full font-bold uppercase tracking-wider mt-1 text-teal-600 flex items-center gap-0.5">
                <CheckCircle2 className="w-2.5 h-2.5" />
                Đang rảnh
              </span>
            ) : (
              <span className="text-[9px] text-slate-400 border border-slate-200 px-1.5 py-0.5 rounded-full font-bold uppercase tracking-wider mt-1 group-hover:border-slate-300 transition">
                Mở ca rảnh
              </span>
            )}
          </div>
        )}
      </button>
    );
  };

  const bookedCount = slots.filter(s => s.isBooked).length;
  const openedCount = slots.filter(s => !s.isBooked && new Date(s.endTime) > new Date()).length;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      
      {/* Page Header Banner */}
      <div className="relative bg-teal-600 p-6 rounded-3xl overflow-hidden shadow-lg text-white">
        <div className="absolute top-0 right-0 w-[200px] h-[200px] bg-white/10 rounded-full blur-[60px] pointer-events-none" />
        
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 relative z-10">
          <div className="space-y-1">
            <div className="flex items-center gap-1.5 text-xs text-teal-100 font-bold uppercase tracking-wider">
              <CalendarDays className="w-4 h-4 text-white" />
              Lịch trình trực tuyến
            </div>
            <h1 className="text-xl font-black text-white tracking-tight">Quản lý lịch rảnh của bạn</h1>
            <p className="text-xs text-teal-50">
              Nhấp để mở hoặc hủy các khung giờ làm việc rảnh của bạn. Bệnh nhân sẽ nhìn thấy và đặt lịch.
            </p>
          </div>
          
          <div className="flex items-center gap-3 bg-white/20 border border-white/30 p-3 rounded-2xl shrink-0 font-medium">
            <div className="text-center px-3 border-r border-white/20">
              <p className="text-[10px] text-teal-100 font-bold uppercase">Lịch đã đặt</p>
              <p className="text-sm font-bold text-white font-mono">{bookedCount}</p>
            </div>
            <div className="text-center px-3">
              <p className="text-[10px] text-teal-100 font-bold uppercase">Ca đang rảnh</p>
              <p className="text-sm font-bold text-white font-mono">{openedCount}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Main Alert Notification Area */}
      {(error || success) && (
        <div className="space-y-2">
          {error && (
            <div className="p-4 bg-white border border-red-200 text-red-600 text-xs rounded-2xl flex gap-2.5 items-start shadow-sm shadow-red-500/5 animate-in fade-in duration-200">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-red-500 animate-pulse" />
              <span>{error}</span>
            </div>
          )}
          {success && (
            <div className="p-4 bg-white border border-emerald-200 text-emerald-600 text-xs rounded-2xl flex gap-2.5 items-start shadow-sm shadow-emerald-500/5 animate-in fade-in duration-200">
              <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5 text-emerald-500 animate-bounce" />
              <span>{success}</span>
            </div>
          )}
        </div>
      )}

      {/* Week Selector Bar (Large Size) */}
      <div className="bg-white border border-slate-200 p-4 rounded-3xl space-y-3.5 shadow-sm">
        <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest px-1">
          Chọn ngày làm việc trong tuần
        </h3>
        <div className="grid grid-cols-7 gap-2.5">
          {weeklyDays.map((day) => {
            const isSelected = day.dateStr === selectedDateStr;
            const count = getSlotsCountForDate(day.dateStr);
            const isTodayDate = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).substring(0, 10) === day.dateStr;
            
            return (
              <button
                key={day.dateStr}
                onClick={() => {
                  setSelectedDateStr(day.dateStr);
                  setError(null);
                  setSuccess(null);
                }}
                className={`py-3.5 rounded-2xl flex flex-col items-center justify-center gap-1 transition-all duration-300 relative border ${
                  isSelected
                    ? 'bg-teal-600 text-white font-bold border-teal-500 shadow-md shadow-teal-500/10 scale-105 z-10'
                    : 'bg-white border-slate-200 text-slate-500 hover:text-slate-800 hover:bg-slate-50 hover:border-slate-300'
                }`}
              >
                <span className="text-[10px] uppercase font-extrabold tracking-wider">{day.dayLabel}</span>
                <span className="text-base font-black font-mono leading-none">{day.dateLabel}</span>
                {count > 0 && (
                  <span className={`text-[9px] font-mono px-1.5 py-0.25 rounded-md mt-1 ${isSelected ? 'bg-white/20 text-white' : 'bg-teal-50 text-teal-600 border border-teal-200'}`}>
                    {count} ca
                  </span>
                )}
                {isTodayDate && !isSelected && (
                  <span className="absolute top-1.5 right-2 w-1.5 h-1.5 bg-blue-500 rounded-full" />
                )}
              </button>
            );
          })}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Column: Preset grid selectors */}
        <div className="lg:col-span-2 space-y-6 bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
          <div className="flex justify-between items-center mb-2">
            <h2 className="text-sm font-extrabold text-slate-850 tracking-tight flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-teal-600" />
              Khung giờ trực ngày {new Date(selectedDateStr).toLocaleDateString('vi-VN')}
            </h2>
            <span className="text-[10px] text-slate-400 font-semibold uppercase tracking-widest">Click to Toggle</span>
          </div>

          {loading ? (
            <div className="text-slate-400 text-xs py-12 text-center flex flex-col items-center justify-center gap-2">
              <Loader2 className="w-5 h-5 animate-spin text-teal-600" />
              <span>Đang đồng bộ lịch trình...</span>
            </div>
          ) : (
            <div className="space-y-6">
              {/* Morning period */}
              <div className="space-y-3">
                <div className="flex items-center gap-1.5 text-xs text-slate-700 font-bold tracking-wide border-b border-slate-200 pb-1.5">
                  <Sun className="w-4 h-4 text-amber-500" />
                  Ca Sáng (08:00 - 12:00)
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  {TIME_PRESETS.filter(p => p.period === 'morning').map(renderPresetCard)}
                </div>
              </div>

              {/* Afternoon period */}
              <div className="space-y-3">
                <div className="flex items-center gap-1.5 text-xs text-slate-700 font-bold tracking-wide border-b border-slate-200 pb-1.5">
                  <Moon className="w-4 h-4 text-indigo-500" />
                  Ca Chiều (13:00 - 18:00)
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  {TIME_PRESETS.filter(p => p.period === 'afternoon').map(renderPresetCard)}
                </div>
              </div>
            </div>
          )}

          <div className="mt-5 p-3.5 bg-slate-50 border border-slate-200 rounded-2xl flex items-start gap-2 text-[10px] text-slate-500 leading-normal font-medium">
            <HelpCircle className="w-3.5 h-3.5 text-slate-400 shrink-0 mt-0.5" />
            <p>
              Hướng dẫn: Ô viền xám là ca chưa mở. Ô xanh sáng là ca đang rảnh. Click vào ô xanh để hủy rảnh, click ô xám để mở rảnh. Ca đã được đặt lịch không thể hủy.
            </p>
          </div>
        </div>

        {/* Right Column: Custom Time Creator Card */}
        <div className="space-y-6">
          <div className="bg-white border border-slate-200 rounded-3xl p-5 space-y-4 shadow-sm">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-widest flex items-center gap-2">
              <Plus className="w-4 h-4 text-teal-600" />
              Đăng ký khung giờ lẻ
            </h3>
            
            <form onSubmit={void handleAddCustomSlot} className="space-y-4">
              <div>
                <label className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Ngày áp dụng</label>
                <div className="w-full bg-slate-50 border border-slate-200 text-slate-600 text-xs rounded-xl p-3 font-semibold font-mono">
                  {new Date(selectedDateStr).toLocaleDateString('vi-VN')}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Giờ bắt đầu</label>
                  <input
                    type="time"
                    required
                    value={customStartTime}
                    onChange={e => setCustomStartTime(e.target.value)}
                    className="w-full bg-white border border-slate-200 text-xs text-slate-700 rounded-xl p-3 focus:outline-none focus:border-teal-500 transition duration-300 font-mono"
                  />
                </div>
                <div>
                  <label className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Giờ kết thúc</label>
                  <input
                    type="time"
                    required
                    value={customEndTime}
                    onChange={e => setCustomEndTime(e.target.value)}
                    className="w-full bg-white border border-slate-200 text-xs text-slate-700 rounded-xl p-3 focus:outline-none focus:border-teal-500 transition duration-300 font-mono"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={submittingCustom}
                className="w-full flex items-center justify-center gap-1.5 px-4 py-3 bg-teal-600 hover:bg-teal-500 active:scale-98 text-white text-xs font-bold rounded-xl transition duration-300 shadow-md disabled:opacity-50"
              >
                {submittingCustom ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <Plus className="w-3.5 h-3.5" />
                )}
                Đăng ký ca trực lẻ
              </button>
            </form>
          </div>

          {/* Secure Medical Advice Badge */}
          <div className="p-4 bg-teal-50/50 border border-teal-200 rounded-3xl flex gap-3 shadow-sm">
            <ShieldCheck className="w-8 h-8 text-teal-600 shrink-0" />
            <div className="space-y-0.5">
              <h4 className="text-xs font-bold text-teal-900">Đồng bộ lịch MediChain</h4>
              <p className="text-[10px] text-teal-700/80 leading-normal font-medium">
                Tất cả các ca khám của bác sĩ được bảo mật trên blockchain và đồng bộ tức thời với ứng dụng di động của bệnh nhân.
              </p>
            </div>
          </div>
        </div>

      </div>

    </div>
  );
}

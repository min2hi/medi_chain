'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { StaffApi, Appointment } from '@/services/staff.service';
import { 
  Stethoscope, User, ArrowLeft, Pill, AlertTriangle, 
  Plus, Trash2, CheckCircle2, ShieldAlert, Calculator, Clock
} from 'lucide-react';

interface PrescribedDrug {
  name: string;
  strength: string; // e.g. 500mg
  frequency: string; // e.g. 2 lần/ngày
  days: number;
}

export default function PrescribePage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const appointmentId = params.id;

  const [appointment, setAppointment] = useState<Appointment | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Notes state
  const [diagnosis, setDiagnosis] = useState('');
  const [instructions, setInstructions] = useState('');
  
  // Medications state
  const [medications, setMedications] = useState<PrescribedDrug[]>([
    { name: '', strength: '', frequency: '2 lần/ngày', days: 5 }
  ]);

  // Pediatric Helper calculator state
  const [isPediatric, setIsPediatric] = useState(false);
  const [childWeight, setChildWeight] = useState<number>(12);
  const [multiplier, setMultiplier] = useState<number>(15); // mg/kg/day
  const [calcResult, setCalcResult] = useState<number>(180); // suggested daily dose

  // Safety Warnings state
  const [safetyAlerts, setSafetyAlerts] = useState<string[]>([]);
  const [interactionAlerts, setInteractionAlerts] = useState<string[]>([]);

  useEffect(() => {
    const fetchAppointment = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await StaffApi.getAppointments('ALL');
        if (res.success && res.data) {
          const found = res.data.find(a => a.id === appointmentId);
          if (found) {
            setAppointment(found);
          } else {
            setError('Không tìm thấy thông tin lịch hẹn khám');
          }
        }
      } catch {
        setError('Lỗi tải thông tin lịch hẹn');
      } finally {
        setLoading(false);
      }
    };
    void fetchAppointment();
  }, [appointmentId]);

  // Recalculate pediatric dose
  useEffect(() => {
    setCalcResult(childWeight * multiplier);
  }, [childWeight, multiplier]);

  // Run clinical safety alerts in real-time
  useEffect(() => {
    const alerts: string[] = [];
    const interactions: string[] = [];

    // 1. Cumulative ingredient limit (Paracetamol limit is 4000mg/day)
    let totalParaMgPerDay = 0;
    
    medications.forEach(med => {
      const nameLower = med.name.toLowerCase();
      if (nameLower.includes('paracetamol') || nameLower.includes('acetaminophen')) {
        // Try to parse strength (e.g. 500mg, 650mg, 1g)
        const mgMatch = med.strength.match(/(\d+)\s*(mg|g)/i);
        if (mgMatch) {
          let mg = parseInt(mgMatch[1]);
          if (mgMatch[2].toLowerCase() === 'g') {
            mg = mg * 1000;
          }
          // Try to parse frequency (e.g. 2 lần/ngày, 3 lần/ngày, mỗi 6 tiếng -> 4 lần)
          let times = 1;
          const freqMatch = med.frequency.match(/(\d+)\s*lần/i);
          if (freqMatch) {
            times = parseInt(freqMatch[1]);
          } else if (med.frequency.includes('6 tiếng')) {
            times = 4;
          } else if (med.frequency.includes('8 tiếng')) {
            times = 3;
          } else if (med.frequency.includes('12 tiếng')) {
            times = 2;
          }
          totalParaMgPerDay += mg * times;
        }
      }
    });

    if (totalParaMgPerDay > 4000) {
      alerts.push(`Cảnh báo liều lượng: Tổng lượng Paracetamol/Acetaminophen kê đơn là ${totalParaMgPerDay}mg/ngày, vượt quá ngưỡng an toàn tối đa (4000mg/ngày). Có nguy cơ gây ngộ độc và suy gan cấp.`);
    }

    // 2. Drug-Drug Interactions
    const medNames = medications.map(m => m.name.toLowerCase().trim()).filter(Boolean);
    
    const hasDrug = (keyword: string) => medNames.some(name => name.includes(keyword));

    if (hasDrug('aspirin') && (hasDrug('ibuprofen') || hasDrug('meloxicam') || hasDrug('diclofenac') || hasDrug('nsaid'))) {
      interactions.push('Tương tác Aspirin + NSAID: Dùng chung làm tăng đáng kể nguy cơ viêm loét và xuất huyết tiêu hóa.');
    }
    if (hasDrug('clopidogrel') && (hasDrug('omeprazole') || hasDrug('esomeprazole'))) {
      interactions.push('Tương tác Clopidogrel + Omeprazole: PPI (Omeprazole) ức chế CYP2C19 làm giảm hoạt tính chống kết tập tiểu cầu của Clopidogrel.');
    }
    if (hasDrug('warfarin') && hasDrug('aspirin')) {
      interactions.push('Tương tác Warfarin + Aspirin: Tăng nguy cơ xuất huyết nghiêm trọng. Cần theo dõi chỉ số đông máu INR.');
    }
    if (hasDrug('sildenafil') && (hasDrug('nitroglycerin') || hasDrug('isosorbide') || hasDrug('nitrate'))) {
      interactions.push('Tương tác Sildenafil + Nitrate: Chống chỉ định tuyệt đối. Gây hạ huyết áp nghiêm trọng đe dọa tính mạng.');
    }

    setSafetyAlerts(alerts);
    setInteractionAlerts(interactions);
  }, [medications]);

  const handleAddMedication = () => {
    setMedications(prev => [
      ...prev,
      { name: '', strength: '', frequency: '2 lần/ngày', days: 5 }
    ]);
  };

  const handleRemoveMedication = (index: number) => {
    setMedications(prev => prev.filter((_, idx) => idx !== index));
  };

  const handleMedicationChange = (index: number, field: keyof PrescribedDrug, value: string | number) => {
    setMedications(prev => prev.map((med, idx) => {
      if (idx === index) {
        return { ...med, [field]: value };
      }
      return med;
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!diagnosis.trim()) {
      alert('Vui lòng điền chẩn đoán lâm sàng');
      return;
    }

    setSubmitting(true);
    try {
      // 1. Format the notes into standard unstructured string matching mobile representation
      const parts: string[] = [];
      const diagVal = diagnosis.trim();
      if (diagVal) parts.push(`CHẨN ĐOÁN: ${diagVal}`);

      const validMeds = medications.filter(m => m.name.trim());
      if (validMeds.length > 0) {
        if (parts.length > 0) parts.push('───────────────────────────');
        parts.push('THUỐC KÊ:');
        validMeds.forEach(med => {
          const dose = med.strength.trim() ? ` ${med.strength.trim()}` : '';
          parts.push(`• ${med.name.trim()}${dose} — ${med.frequency} — ${med.days} ngày`);
        });
      }

      const instVal = instructions.trim();
      if (instVal) {
        if (parts.length > 0) parts.push('───────────────────────────');
        parts.push(`LỜI DẶN: ${instVal}`);
      }

      const doctorNotes = parts.join('\n');

      // 2. Submit PATCH
      const res = await StaffApi.completeAppointment(appointmentId, { doctorNotes });
      if (res.success) {
        router.push('/admin/appointments');
      } else {
        alert(res.message || 'Gửi kết quả khám bệnh thất bại');
      }
    } catch {
      alert('Lỗi kết nối máy chủ');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-3">
        <div className="w-5 h-5 border-2 border-slate-700 border-t-emerald-400 rounded-full animate-spin" />
        <span className="text-slate-500 text-xs">Đang tải bệnh án...</span>
      </div>
    );
  }

  if (error || !appointment) {
    return (
      <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs p-4 rounded-lg flex items-center justify-between">
        <span>{error || 'Lỗi tải trang khám bệnh'}</span>
        <button onClick={() => router.push('/admin/appointments')} className="px-3 py-1 bg-red-500/20 hover:bg-red-500/30 rounded border border-red-500/35 transition">
          Quay lại
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-12">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button 
          onClick={() => router.push('/admin/appointments')}
          className="p-1.5 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-400 hover:text-slate-200 rounded-lg transition"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="text-base font-semibold text-white flex items-center gap-2">
            <Stethoscope className="w-4.5 h-4.5 text-emerald-400" />
            Khám bệnh & Kê đơn thuốc điện tử (eRx)
          </h1>
          <p className="text-xs text-slate-500">
            Kê đơn điện tử tích hợp các bộ lọc cảnh báo tương tác thuốc và liều dùng tự động.
          </p>
        </div>
      </div>

      {/* Patient Header Card */}
      <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-blue-500/15 border border-blue-500/25 flex items-center justify-center text-blue-400">
            <User className="w-4 h-4" />
          </div>
          <div>
            <span className="text-[9px] bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded uppercase font-semibold">
              Bệnh nhân
            </span>
            <h3 className="text-sm font-semibold text-white mt-1">{appointment.user.name}</h3>
          </div>
        </div>

        <div className="text-left sm:text-right text-xs text-slate-500 grid grid-cols-2 sm:block gap-2">
          <div>Lý do khám: <span className="text-slate-300 font-medium">{appointment.title}</span></div>
          <div>Số điện thoại: <span className="text-slate-300 font-mono">{appointment.user.profile?.phone || 'Chưa cập nhật'}</span></div>
        </div>
      </div>

      {/* Safety Alerts Display */}
      {(safetyAlerts.length > 0 || interactionAlerts.length > 0) && (
        <div className="space-y-2.5">
          {safetyAlerts.map((msg, i) => (
            <div key={i} className="flex gap-2.5 bg-red-950/20 border border-red-900/40 p-3.5 rounded-lg text-xs text-red-400 animate-in fade-in duration-200">
              <ShieldAlert className="w-4 h-4 shrink-0 text-red-400" />
              <div>{msg}</div>
            </div>
          ))}
          {interactionAlerts.map((msg, i) => (
            <div key={i} className="flex gap-2.5 bg-amber-950/20 border border-amber-900/40 p-3.5 rounded-lg text-xs text-amber-400 animate-in fade-in duration-200">
              <AlertTriangle className="w-4 h-4 shrink-0 text-amber-400" />
              <div>{msg}</div>
            </div>
          ))}
        </div>
      )}

      {/* Diagnosis & Prescribing Form */}
      <form onSubmit={handleSubmit} className="space-y-6">
        
        {/* Clinical notes inputs */}
        <div className="bg-slate-900 border border-slate-800 p-5 rounded-xl space-y-4">
          <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Chẩn đoán lâm sàng</h2>
          <div className="space-y-3">
            <div>
              <label className="text-[10px] text-slate-500 uppercase block mb-1">Chẩn đoán của bác sĩ <span className="text-red-500">*</span></label>
              <textarea
                required
                placeholder="Ghi chẩn đoán lâm sàng chi tiết (ví dụ: Viêm họng cấp, Trào ngược dạ dày thực quản...)"
                value={diagnosis}
                onChange={e => setDiagnosis(e.target.value)}
                className="w-full bg-slate-950 border border-slate-850 rounded-lg p-3 text-xs text-slate-200 placeholder-slate-700 focus:outline-none focus:border-slate-700 min-h-[70px] resize-y"
              />
            </div>
            
            <div>
              <label className="text-[10px] text-slate-500 uppercase block mb-1">Lời dặn & Hướng dẫn sử dụng</label>
              <textarea
                placeholder="Lời dặn bác sĩ gửi tới bệnh nhân (ví dụ: Uống nhiều nước ấm, nghỉ ngơi, kiêng đồ lạnh, tái khám sau 5 ngày...)"
                value={instructions}
                onChange={e => setInstructions(e.target.value)}
                className="w-full bg-slate-950 border border-slate-850 rounded-lg p-3 text-xs text-slate-200 placeholder-slate-700 focus:outline-none focus:border-slate-700 min-h-[60px] resize-y"
              />
            </div>
          </div>
        </div>

        {/* Prescription details */}
        <div className="bg-slate-900 border border-slate-800 p-5 rounded-xl space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <Pill className="w-4 h-4 text-emerald-400" />
              Đơn thuốc điện tử
            </h2>
            <button
              type="button"
              onClick={() => setIsPediatric(!isPediatric)}
              className={`flex items-center gap-1 px-2.5 py-1 rounded text-[10px] border transition ${
                isPediatric 
                  ? 'bg-blue-500/10 border-blue-500/25 text-blue-400' 
                  : 'bg-slate-950/60 border-slate-800 text-slate-500 hover:text-slate-300'
              }`}
            >
              <Calculator className="w-3 h-3" />
              Tính liều trẻ em
            </button>
          </div>

          {/* Pediatric Dose Helper Calculator */}
          {isPediatric && (
            <div className="bg-slate-950/70 border border-blue-900/20 p-4 rounded-lg space-y-3">
              <div className="text-[10px] font-semibold text-blue-400 uppercase tracking-wider">Công cụ hỗ trợ tính liều nhi khoa (Weight-based dose)</div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="text-[9px] text-slate-500 block mb-1">Cân nặng (kg)</label>
                  <input
                    type="number"
                    value={childWeight}
                    onChange={e => setChildWeight(Math.max(1, parseFloat(e.target.value) || 0))}
                    className="w-full bg-slate-900 border border-slate-800 rounded p-1.5 text-xs text-slate-300 focus:outline-none focus:border-slate-750"
                  />
                </div>
                <div>
                  <label className="text-[9px] text-slate-500 block mb-1">Hệ số (mg/kg/ngày)</label>
                  <select
                    value={multiplier}
                    onChange={e => setMultiplier(parseInt(e.target.value))}
                    className="w-full bg-slate-900 border border-slate-800 rounded p-1.5 text-xs text-slate-300 focus:outline-none focus:border-slate-750"
                  >
                    <option value={10}>10 mg/kg/ngày</option>
                    <option value={15}>15 mg/kg/ngày (Paracetamol chuẩn)</option>
                    <option value={20}>20 mg/kg/ngày</option>
                    <option value={25}>25 mg/kg/ngày</option>
                    <option value={40}>40 mg/kg/ngày (Kháng sinh nhi)</option>
                  </select>
                </div>
                <div className="bg-blue-500/5 border border-blue-500/10 rounded p-2 flex flex-col justify-center">
                  <span className="text-[9px] text-blue-400 block uppercase">Liều lượng khuyến cáo</span>
                  <span className="text-xs font-bold text-white font-mono">{calcResult} mg / ngày</span>
                </div>
              </div>
            </div>
          )}

          {/* Medications Form List */}
          <div className="space-y-3">
            {medications.map((med, index) => (
              <div key={index} className="flex flex-col sm:flex-row gap-2 bg-slate-950/40 p-3 rounded-lg border border-slate-800/80 items-end sm:items-center">
                
                {/* Medication Name */}
                <div className="flex-1 w-full">
                  <label className="text-[9px] text-slate-600 block mb-0.5 sm:hidden">Tên thuốc</label>
                  <input
                    type="text"
                    required
                    placeholder="Tên thuốc (ví dụ: Paracetamol, Amoxicillin...)"
                    value={med.name}
                    onChange={e => handleMedicationChange(index, 'name', e.target.value)}
                    className="w-full bg-slate-900 border border-slate-800 rounded px-2.5 py-1.5 text-xs text-slate-200 placeholder-slate-700 focus:outline-none focus:border-slate-700"
                  />
                </div>

                {/* Strength */}
                <div className="w-full sm:w-28">
                  <label className="text-[9px] text-slate-600 block mb-0.5 sm:hidden">Hàm lượng</label>
                  <input
                    type="text"
                    required
                    placeholder="Hàm lượng (e.g. 500mg)"
                    value={med.strength}
                    onChange={e => handleMedicationChange(index, 'strength', e.target.value)}
                    className="w-full bg-slate-900 border border-slate-800 rounded px-2.5 py-1.5 text-xs text-slate-200 placeholder-slate-700 focus:outline-none focus:border-slate-700"
                  />
                </div>

                {/* Frequency */}
                <div className="w-full sm:w-36">
                  <label className="text-[9px] text-slate-600 block mb-0.5 sm:hidden">Tần suất</label>
                  <select
                    value={med.frequency}
                    onChange={e => handleMedicationChange(index, 'frequency', e.target.value)}
                    className="w-full bg-slate-900 border border-slate-800 rounded px-2 py-1.5 text-xs text-slate-300 focus:outline-none focus:border-slate-700"
                  >
                    <option value="1 lần/ngày">1 lần/ngày</option>
                    <option value="2 lần/ngày">2 lần/ngày</option>
                    <option value="3 lần/ngày">3 lần/ngày</option>
                    <option value="4 lần/ngày">4 lần/ngày</option>
                    <option value="Mỗi 6 tiếng">Mỗi 6 tiếng</option>
                    <option value="Mỗi 8 tiếng">Mỗi 8 tiếng</option>
                    <option value="Mỗi 12 tiếng">Mỗi 12 tiếng</option>
                  </select>
                </div>

                {/* Days */}
                <div className="w-full sm:w-20">
                  <label className="text-[9px] text-slate-600 block mb-0.5 sm:hidden">Số ngày</label>
                  <input
                    type="number"
                    min={1}
                    required
                    value={med.days}
                    onChange={e => handleMedicationChange(index, 'days', parseInt(e.target.value) || 1)}
                    className="w-full bg-slate-900 border border-slate-800 rounded px-2 py-1 text-xs text-slate-200 text-center focus:outline-none focus:border-slate-700"
                  />
                </div>

                {/* Action Trash */}
                {medications.length > 1 && (
                  <button
                    type="button"
                    onClick={() => handleRemoveMedication(index)}
                    className="p-2 text-red-500 hover:bg-red-500/10 rounded transition self-end sm:self-center"
                    title="Xóa thuốc"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={handleAddMedication}
            className="flex items-center gap-1 text-[11px] text-blue-400 hover:text-blue-300 font-semibold px-2 py-1.5 rounded bg-slate-950/60 border border-slate-850 hover:border-slate-800 transition"
          >
            <Plus className="w-3.5 h-3.5" />
            Thêm loại thuốc
          </button>
        </div>

        {/* Submit */}
        <div className="flex justify-end gap-3">
          <button
            type="button"
            onClick={() => router.push('/admin/appointments')}
            disabled={submitting}
            className="px-4 py-2 border border-slate-850 hover:border-slate-800 text-slate-400 hover:text-slate-200 rounded-lg text-xs font-semibold transition"
          >
            Hủy bỏ
          </button>
          
          <button
            type="submit"
            disabled={submitting}
            className="flex items-center gap-2 px-5 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white rounded-lg text-xs font-semibold transition"
          >
            {submitting && <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />}
            Hoàn thành & Gửi đơn thuốc (eRx)
          </button>
        </div>
      </form>
    </div>
  );
}

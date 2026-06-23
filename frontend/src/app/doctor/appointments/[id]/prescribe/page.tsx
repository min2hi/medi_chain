'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { StaffApi, Appointment } from '@/services/staff.service';
import { MedicinesApi, AIApi } from '@/services/api.client';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import { 
  Stethoscope, User, ArrowLeft, AlertTriangle, 
  Plus, Trash2, CheckCircle2, ShieldAlert, Calculator, Clock, Loader2,
  Sparkles, Search
} from 'lucide-react';

interface PrescribedDrug {
  name: string;
  strength: string; // e.g. 500mg
  frequency: string; // e.g. 2 lần/ngày
  days: number;
}

interface PatientMedicine {
  id: string;
  name: string;
  dosage?: string | null;
  frequency?: string | null;
  endDate?: string | null;
}

export default function DoctorPrescribe({ params }: { params: { id: string } }) {
  const router = useRouter();
  const appointmentId = params.id;

  const [appointment, setAppointment] = useState<Appointment | null>(null);
  const [patientMeds, setPatientMeds] = useState<PatientMedicine[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [showConfirmSubmit, setShowConfirmSubmit] = useState(false);

  // Clinical Notes state
  const [diagnosis, setDiagnosis] = useState('');
  const [instructions, setInstructions] = useState('');
  
  // Medications state
  const [medications, setMedications] = useState<PrescribedDrug[]>([
    { name: '', strength: '', frequency: '2 lần/ngày', days: 5 }
  ]);

  // Pediatric Dose Calculator state
  const [isPediatric, setIsPediatric] = useState(false);
  const [childWeight, setChildWeight] = useState<number>(12);
  const [multiplier, setMultiplier] = useState<number>(15); // mg/kg/day
  const [calcResult, setCalcResult] = useState<number>(180); // suggested daily dose
  const [activeCalcIdx, setActiveCalcIdx] = useState<number | null>(null);

  // Safety Warnings state
  const [safetyAlerts, setSafetyAlerts] = useState<string[]>([]);
  const [interactionAlerts, setInteractionAlerts] = useState<{ severity: 'danger' | 'warning'; message: string }[]>([]);

  // AI Drug Recommendation states
  const [symptomsQuery, setSymptomsQuery] = useState('');
  const [aiRecommendations, setAiRecommendations] = useState<any[]>([]);
  const [aiPredictedDiseases, setAiPredictedDiseases] = useState<any[]>([]);
  const [aiSafetyWarnings, setAiSafetyWarnings] = useState<string[]>([]);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState<string | null>(null);

  const fetchRecommendations = async (customQuery?: string, overridePatientId?: string) => {
    const query = (customQuery !== undefined ? customQuery : symptomsQuery).trim();
    const pId = overridePatientId || appointment?.userId;
    if (!query || query.length < 5 || !pId) return;
    setAiLoading(true);
    setAiError(null);
    try {
      const res = await AIApi.consult(query, undefined, pId);
      if (res.success && res.data) {
        setAiRecommendations(res.data.recommendedMedicines || []);
        setAiPredictedDiseases(res.data.predictedDiseases || []);
        setAiSafetyWarnings(res.data.safetyWarnings || []);
      } else {
        setAiError(res.message || 'Không lấy được gợi ý thuốc');
      }
    } catch (err: any) {
      console.error('Failed to fetch AI recommendations:', err);
      setAiError(err.message || 'Lỗi kết nối dịch vụ khuyến nghị');
    } finally {
      setAiLoading(false);
    }
  };

  const handleQuickAdd = (rec: any) => {
    const isEmptyFirst = medications.length === 1 && medications[0].name === '';
    const cleanInstruction = rec.instruction ? ` (${rec.instruction})` : '';
    const cleanFrequency = rec.frequency ? `${rec.frequency}${cleanInstruction}` : '2 lần/ngày';
    
    const newMed: PrescribedDrug = {
      name: rec.name,
      strength: rec.dosage || '500mg',
      frequency: cleanFrequency,
      days: 5
    };
    
    if (isEmptyFirst) {
      setMedications([newMed]);
    } else {
      setMedications(prev => [...prev, newMed]);
    }
  };

  // Fetch appointment details and patient's existing active medications
  useEffect(() => {
    const fetchAllData = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await StaffApi.getAppointments('ALL');
        if (res.success && res.data) {
          const found = res.data.find(a => a.id === appointmentId);
          if (found) {
            setAppointment(found);
            setDiagnosis(found.title || '');
            setSymptomsQuery(found.title || '');
            
            // Fetch patient's active medicines
            const medsRes = await MedicinesApi.list(found.userId);
            if (medsRes.success && medsRes.data) {
              const activeMeds = (medsRes.data as unknown as PatientMedicine[]).filter(med => {
                if (!med.endDate) return true;
                return new Date(med.endDate) > new Date();
              });
              setPatientMeds(activeMeds);
            }

            // Trigger initial AI recommendations
            if (found.title && found.title.trim().length >= 5) {
              void fetchRecommendations(found.title, found.userId);
            }
          } else {
            setError('Không tìm thấy thông tin ca hẹn khám');
          }
        }
      } catch (err) {
        console.error('Failed to load prescribe data:', err);
        setError('Lỗi tải dữ liệu ca khám y tế');
      } finally {
        setLoading(false);
      }
    };
    void fetchAllData();
  }, [appointmentId]);

  // Recalculate pediatric dose
  useEffect(() => {
    setCalcResult(childWeight * multiplier);
  }, [childWeight, multiplier]);

  // Apply pediatric calculation to selected drug dosage/strength field
  const applyCalcToMed = (idx: number) => {
    const times = 2; // default divided times
    const dosePerTime = Math.round(calcResult / times);
    handleMedicationChange(idx, 'strength', `${dosePerTime}mg`);
    handleMedicationChange(idx, 'frequency', `${times} lần/ngày (chia đều)`);
    setIsPediatric(false);
  };

  // Run clinical safety alerts in real-time
  useEffect(() => {
    const alerts: string[] = [];
    const interactions: { severity: 'danger' | 'warning'; message: string }[] = [];

    // 1. Cumulative ingredient limit (Paracetamol limit is 4000mg/day)
    let totalParaMgPerDay = 0;
    
    const allDrugsToCheck = [
      ...medications.map(m => ({ name: m.name, strength: m.strength, frequency: m.frequency })),
      ...patientMeds.map(m => ({ name: m.name, strength: m.dosage || '', frequency: m.frequency || '' }))
    ];

    allDrugsToCheck.forEach(med => {
      const nameLower = med.name.toLowerCase();
      if (nameLower.includes('paracetamol') || nameLower.includes('acetaminophen') || nameLower.includes('panadol')) {
        const mgMatch = med.strength.match(/(\d+)\s*(mg|g)/i);
        if (mgMatch) {
          let mg = parseInt(mgMatch[1]);
          if (mgMatch[2].toLowerCase() === 'g') {
            mg = mg * 1000;
          }
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
      alerts.push(`Cảnh báo liều lượng: Tổng lượng Paracetamol đang dùng là ${totalParaMgPerDay}mg/ngày (bao gồm đơn mới và tủ thuốc bệnh nhân), vượt quá ngưỡng an toàn tối đa (4000mg/ngày). Có nguy cơ gây ngộ độc và suy gan cấp.`);
    }

    // 2. Drug-Drug Interactions (Dynamic config mapping check)
    const medNames = medications.map(m => m.name.toLowerCase().trim()).filter(Boolean);
    const existingNames = patientMeds.map(m => m.name.toLowerCase().trim()).filter(Boolean);

    const knownInteractions: Record<string, { severity: 'danger' | 'warning'; message: string; targets: string[] }> = {
      'warfarin': {
        severity: 'danger',
        message: 'Tăng nguy cơ xuất huyết nghiêm trọng đe dọa tính mạng.',
        targets: ['aspirin', 'ibuprofen', 'paracetamol', 'ginkgo biloba', 'hoạt huyết dưỡng não', 'clopidogrel']
      },
      'sintrom': {
        severity: 'danger',
        message: 'Tăng nguy cơ xuất huyết nghiêm trọng.',
        targets: ['aspirin', 'ibuprofen', 'paracetamol', 'ginkgo biloba', 'hoạt huyết dưỡng não', 'clopidogrel']
      },
      'aspirin': {
        severity: 'danger',
        message: 'Ibuprofen có thể đối kháng tác dụng bảo vệ tim mạch của Aspirin và tăng nguy cơ loét dạ dày khi dùng chung với Corticosteroid/NSAID khác.',
        targets: ['warfarin', 'sintrom', 'ibuprofen', 'corticosteroid', 'clopidogrel', 'mobic', 'celecoxib']
      },
      'metformin': {
        severity: 'danger',
        message: 'Tăng nguy cơ nhiễm toan acid lactic hoặc mất kiểm soát đường huyết.',
        targets: ['rượu', 'cồn', 'alcohol', 'ethanol', 'corticosteroid', 'prednisolone', 'dexamethasone', 'methylprednisolone', 'contrast media', 'chất cản quang']
      },
      'digoxin': {
        severity: 'danger',
        message: 'Nguy cơ ngộ độc Digoxin gây loạn nhịp tim nguy hiểm do thay đổi kali huyết.',
        targets: ['thuốc lợi tiểu', 'diuretic', 'furosemide', 'hydrochlorothiazide', 'corticosteroid', 'prednisolone', 'methylprednisolone', 'spironolactone', 'amiodarone']
      },
      'ibuprofen': {
        severity: 'danger',
        message: 'Tăng nguy cơ loét dạ dày, xuất huyết tiêu hóa hoặc suy thận.',
        targets: ['aspirin', 'warfarin', 'sintrom', 'corticosteroid', 'prednisolone', 'methylprednisolone', 'methotrexate']
      },
      'clarithromycin': {
        severity: 'danger',
        message: 'Tăng nguy cơ độc cơ vân do statin hoặc ngộ độc Colchicine.',
        targets: ['simvastatin', 'atorvastatin', 'lovastatin', 'colchicine']
      },
      'erythromycin': {
        severity: 'danger',
        message: 'Tăng nguy cơ độc cơ vân do statin hoặc ngộ độc Colchicine.',
        targets: ['simvastatin', 'atorvastatin', 'lovastatin', 'colchicine']
      },
      'ciprofloxacin': {
        severity: 'warning',
        message: 'Làm giảm hấp thu kháng sinh nhóm Quinolone.',
        targets: ['antacid', 'maalox', 'calcium', 'canxi', 'sắt', 'iron', 'kẽm', 'zinc']
      },
      'levofloxacin': {
        severity: 'warning',
        message: 'Làm giảm hấp thu kháng sinh Quinolone hoặc tăng nguy cơ kéo dài khoảng QT.',
        targets: ['antacid', 'maalox', 'calcium', 'canxi', 'sắt', 'iron', 'kẽm', 'zinc', 'amiodarone']
      },
      'enalapril': {
        severity: 'warning',
        message: 'Nguy cơ tăng kali huyết nghiêm trọng.',
        targets: ['spironolactone', 'kali', 'potassium']
      },
      'lisinopril': {
        severity: 'warning',
        message: 'Nguy cơ tăng kali huyết nghiêm trọng.',
        targets: ['spironolactone', 'kali', 'potassium']
      },
      'metronidazole': {
        severity: 'danger',
        message: 'Phản ứng disulfiram-like (đỏ bừng, tim đập nhanh, buồn nôn) khi phối hợp cồn.',
        targets: ['rượu', 'cồn', 'alcohol', 'ethanol']
      },
      'sildenafil': {
        severity: 'danger',
        message: 'Tụt huyết áp nghiêm trọng đe dọa tính mạng.',
        targets: ['nitroglycerin', 'isosorbide', 'nitrate']
      },
      'tadalafil': {
        severity: 'danger',
        message: 'Tụt huyết áp nghiêm trọng đe dọa tính mạng.',
        targets: ['nitroglycerin', 'isosorbide', 'nitrate']
      },
      'ginkgo biloba': {
        severity: 'warning',
        message: 'Tăng nguy cơ chảy máu khi dùng chung thuốc chống đông/chống kết tập tiểu cầu.',
        targets: ['warfarin', 'sintrom', 'aspirin', 'clopidogrel']
      },
      'hoạt huyết dưỡng não': {
        severity: 'warning',
        message: 'Tăng nguy cơ chảy máu khi dùng chung thuốc chống đông/chống kết tập tiểu cầu.',
        targets: ['warfarin', 'sintrom', 'aspirin', 'clopidogrel']
      }
    };

    const checkedPairs = new Set<string>();

    allDrugsToCheck.forEach((med1, idx1) => {
      const name1 = med1.name.toLowerCase().trim();
      if (!name1) return;

      Object.keys(knownInteractions).forEach(drugKey => {
        if (name1.includes(drugKey)) {
          const rule = knownInteractions[drugKey];
          
          allDrugsToCheck.forEach((med2, idx2) => {
            if (idx1 === idx2) return;
            const name2 = med2.name.toLowerCase().trim();
            if (!name2) return;

            rule.targets.forEach(target => {
              if (name2.includes(target)) {
                // Chỉ cảnh báo nếu ít nhất một trong hai thuốc thuộc đơn kê mới (tránh cảnh báo thừa về tủ thuốc cũ của bệnh nhân)
                const isOneKeting = idx1 < medications.length || idx2 < medications.length;
                if (!isOneKeting) return;

                const pairId = [name1, name2].sort().join('||');
                if (checkedPairs.has(pairId)) return;
                checkedPairs.add(pairId);

                const severityText = rule.severity === 'danger' ? 'Tương tác Nguy hiểm' : 'Tương tác Cần lưu ý';
                interactions.push({
                  severity: rule.severity,
                  message: `${severityText}: ${med1.name} + ${med2.name}. ${rule.message}`
                });
              }
            });
          });
        }
      });
    });

    // 3. Duplicate Drug / Therapy Warning
    const duplicates: string[] = [];
    medNames.forEach(name => {
      if (existingNames.includes(name)) {
        if (!duplicates.includes(name)) {
          duplicates.push(name);
        }
      }
    });

    const seenSubmitDrugs = new Set<string>();
    medications.forEach(med => {
      const nameClean = med.name.toLowerCase().trim();
      if (nameClean) {
        if (seenSubmitDrugs.has(nameClean)) {
          if (!duplicates.includes(nameClean)) {
            duplicates.push(nameClean);
          }
        }
        seenSubmitDrugs.add(nameClean);
      }
    });

    if (duplicates.length > 0) {
      alerts.push(`Cảnh báo trùng thuốc: Thuốc "${duplicates.map(d => d.toUpperCase()).join(', ')}" đã có sẵn trong tủ thuốc đang uống của bệnh nhân hoặc bị kê lặp lại trong đơn. Cần lưu ý điều chỉnh liều hoặc dừng đơn cũ.`);
    }

    // 4. Duplicate therapy check (NSAIDs / Paracetamol lặp lại nhóm hoạt chất)
    let nsaidCount = 0;
    const nsaidList: string[] = [];
    const nsaidKeywords = ['ibuprofen', 'aspirin', 'diclofenac', 'meloxicam', 'naproxen', 'celecoxib', 'ketoprofen', 'piroxicam'];
    
    allDrugsToCheck.forEach(med => {
      const nameLower = med.name.toLowerCase().trim();
      for (const kw of nsaidKeywords) {
        if (nameLower.includes(kw)) {
          nsaidCount++;
          nsaidList.push(med.name);
          break;
        }
      }
    });

    if (nsaidCount > 1) {
      alerts.push(`Cảnh báo trùng lặp nhóm điều trị: Phát hiện sử dụng nhiều thuốc kháng viêm NSAID cùng lúc (${nsaidList.join(', ')}). Việc phối hợp các NSAID làm tăng gấp đôi nguy cơ xuất huyết tiêu hóa, loét dạ dày và suy thận.`);
    }

    let paracetamolCount = 0;
    const paracetamolList: string[] = [];
    const paracetamolKeywords = ['paracetamol', 'acetaminophen', 'panadol', 'hapacol', 'efferalgan', 'tiffy', 'decolgen'];
    
    allDrugsToCheck.forEach(med => {
      const nameLower = med.name.toLowerCase().trim();
      for (const kw of paracetamolKeywords) {
        if (nameLower.includes(kw)) {
          paracetamolCount++;
          paracetamolList.push(med.name);
          break;
        }
      }
    });

    if (paracetamolCount > 1) {
      alerts.push(`Cảnh báo trùng lặp nhóm điều trị: Phát hiện sử dụng đồng thời nhiều thuốc có chứa hoạt chất Paracetamol/Acetaminophen (${paracetamolList.join(', ')}). Nguy cơ rất cao gây ngộ độc gan cấp tính.`);
    }

    setSafetyAlerts(alerts);
    setInteractionAlerts(interactions);
  }, [medications, patientMeds]);

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

  const checkAndSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!diagnosis.trim()) {
      alert('Vui lòng nhập chẩn đoán lâm sàng');
      return;
    }

    const hasEmptyDrugs = medications.some(m => !m.name.trim());
    if (hasEmptyDrugs) {
      alert('Vui lòng điền đầy đủ tên cho tất cả thuốc kê đơn hoặc xóa dòng thuốc trống.');
      return;
    }

    const hasDangerAlerts = interactionAlerts.some(a => a.severity === 'danger');
    if (hasDangerAlerts) {
      setShowConfirmSubmit(true);
    } else {
      void executeSubmit();
    }
  };

  const executeSubmit = async () => {
    setShowConfirmSubmit(false);
    setSubmitting(true);
    try {
      const parts: string[] = [];
      parts.push(`CHẨN ĐOÁN: ${diagnosis.trim()}`);
      
      const validMeds = medications.filter(m => m.name.trim());
      if (validMeds.length > 0) {
        parts.push('───────────────────────────');
        parts.push('THUỐC KÊ ĐƠN:');
        validMeds.forEach(med => {
          parts.push(`• ${med.name.trim()} (${med.strength}) — ${med.frequency} — Uống ${med.days} ngày`);
        });
      }

      if (instructions.trim()) {
        parts.push('───────────────────────────');
        parts.push(`LỜI DẶN BÁC SĨ: ${instructions.trim()}`);
      }

      const doctorNotes = parts.join('\n');

      const medicationsPayload = validMeds.map(m => ({
        name: m.name.trim(),
        dosage: m.strength.trim(),
        frequency: m.frequency,
        days: m.days
      }));

      const res = await StaffApi.completeAppointment(appointmentId, {
        doctorNotes,
        medications: medicationsPayload
      });

      if (res.success) {
        router.push('/doctor/appointments');
      } else {
        alert(res.message || 'Lỗi khi lưu thông tin ca khám');
      }
    } catch (err) {
      console.error(err);
      alert('Lỗi kết nối máy chủ');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4 bg-slate-50/50 text-slate-800 rounded-3xl border border-slate-100/50 shadow-sm animate-pulse duration-1000">
        <div className="relative flex items-center justify-center w-16 h-16 rounded-full bg-teal-50 border border-teal-100/60 shadow-sm shadow-teal-500/5 animate-bounce">
          <div className="absolute inset-0 rounded-full border border-teal-500/20 animate-ping opacity-40"></div>
          <Stethoscope className="w-6 h-6 text-teal-600" />
        </div>
        <div className="text-center space-y-1">
          <span className="text-slate-700 text-xs font-bold tracking-wider uppercase block">Đang tải hồ sơ bệnh án...</span>
          <span className="text-[10px] text-slate-400 font-medium block">Vui lòng đợi trong giây lát</span>
        </div>
      </div>
    );
  }

  if (error || !appointment) {
    return (
      <div className="bg-white border border-red-200 text-red-600 text-xs p-4 rounded-xl flex items-center justify-between shadow-sm shadow-red-500/5">
        <span>{error || 'Lỗi tải trang khám bệnh'}</span>
        <button onClick={() => router.push('/doctor/appointments')} className="px-3 py-1 bg-red-50 hover:bg-red-100 rounded border border-red-200 text-red-600 transition">
          Quay lại
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-12">
      
      {/* Header Navigation */}
      <div className="flex items-center gap-3">
        <button 
          onClick={() => router.push('/doctor/appointments')}
          className="p-1.5 bg-white border border-slate-200 hover:border-slate-350 text-slate-500 hover:text-slate-800 rounded-lg transition shadow-sm"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="text-base font-semibold text-slate-800 flex items-center gap-2">
            <Stethoscope className="w-4.5 h-4.5 text-teal-600" />
            Khám bệnh & Kê đơn thuốc điện tử (eRx)
          </h1>
          <p className="text-xs text-slate-400">
            Kê đơn tích hợp công cụ kiểm tra chéo tương tác với tủ thuốc thực tế của bệnh nhân.
          </p>
        </div>
      </div>

      {/* Patient info details */}
      <div className="bg-white border border-slate-200 p-4 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-blue-50 border border-blue-200 flex items-center justify-center text-blue-600">
            <User className="w-4.5 h-4.5" />
          </div>
          <div>
            <span className="text-[9px] bg-teal-50 text-teal-600 border border-teal-200 px-2 py-0.5 rounded font-bold uppercase tracking-wider">
              Bệnh nhân điều trị
            </span>
            <h3 className="text-sm font-semibold text-slate-800 mt-1">{appointment.user.name}</h3>
          </div>
        </div>

        <div className="text-left md:text-right text-xs text-slate-400 space-y-1">
          <div>Lý do khám: <span className="text-slate-700 font-medium">{appointment.title}</span></div>
          {appointment.user.profile?.phone && (
            <div>Điện thoại: <span className="text-slate-700 font-mono">{appointment.user.profile.phone}</span></div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left main form column */}
        <div className="lg:col-span-2 space-y-5">
          <form onSubmit={checkAndSubmit} className="space-y-5">
            
            {/* Diagnosis notes block */}
            <div className="bg-white border border-slate-200 p-5 rounded-2xl space-y-4 shadow-sm">
              <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider">1. Chẩn đoán lâm sàng</h3>
              <div className="space-y-3">
                <div>
                  <label className="block text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Chẩn đoán chính *</label>
                  <input
                    type="text"
                    required
                    value={diagnosis}
                    onChange={e => setDiagnosis(e.target.value)}
                    placeholder="Ví dụ: Viêm họng cấp, Tăng huyết áp vô căn..."
                    className="w-full bg-slate-50 border border-slate-200 text-xs text-slate-700 rounded-lg p-2.5 focus:outline-none focus:border-teal-500 focus:bg-white transition"
                  />
                </div>
                <div>
                  <label className="block text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Lời dặn & Hướng dẫn sinh hoạt</label>
                  <textarea
                    value={instructions}
                    onChange={e => setInstructions(e.target.value)}
                    placeholder="Uống nhiều nước ấm, nghỉ ngơi, tái khám sau 5 ngày hoặc khi có dấu hiệu bất thường..."
                    className="w-full h-20 bg-slate-50 border border-slate-200 text-xs text-slate-700 rounded-lg p-2.5 focus:outline-none focus:border-teal-500 focus:bg-white transition resize-none"
                  />
                </div>
              </div>
            </div>

            {/* Prescribe meds details */}
            <div className="bg-white border border-slate-200 p-5 rounded-2xl space-y-4 shadow-sm">
              <div className="flex justify-between items-center">
                <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider">2. Đơn thuốc chỉ định</h3>
                <button
                  type="button"
                  onClick={handleAddMedication}
                  className="flex items-center gap-1 text-[11px] text-teal-600 hover:text-teal-700 font-bold transition"
                >
                  <Plus className="w-3.5 h-3.5" />
                  Thêm thuốc
                </button>
              </div>

              {medications.length === 0 ? (
                <div className="text-center py-6 text-slate-400 text-xs">Chưa kê thuốc nào. Bấm nút Thêm thuốc để chỉ định.</div>
              ) : (
                <div className="space-y-3.5">
                  {medications.map((med, idx) => (
                    <div key={idx} className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-3 relative group shadow-sm">
                      
                      <button
                        type="button"
                        onClick={() => handleRemoveMedication(idx)}
                        className="absolute right-3 top-3 opacity-50 hover:opacity-100 text-red-500 transition"
                        title="Xóa thuốc"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider mb-1">Tên thuốc *</label>
                          <input
                            type="text"
                            required
                            placeholder="Ví dụ: Paracetamol, Amoxicillin..."
                            value={med.name}
                            onChange={e => handleMedicationChange(idx, 'name', e.target.value)}
                            className="w-full bg-white border border-slate-200 text-xs text-slate-700 rounded-lg p-2 focus:outline-none focus:border-teal-500 transition"
                          />
                        </div>

                        <div className="grid grid-cols-3 gap-2">
                          <div className="col-span-2">
                            <label className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider mb-1 flex items-center gap-1">
                              Liều dùng *
                              <button
                                type="button"
                                onClick={() => {
                                  setActiveCalcIdx(idx);
                                  setIsPediatric(true);
                                }}
                                className="text-teal-600 hover:text-teal-700"
                                title="Tính liều nhi khoa"
                              >
                                <Calculator className="w-3 h-3" />
                              </button>
                            </label>
                            <input
                              type="text"
                              required
                              placeholder="500mg, 1 viên"
                              value={med.strength}
                              onChange={e => handleMedicationChange(idx, 'strength', e.target.value)}
                              className="w-full bg-white border border-slate-200 text-xs text-slate-700 rounded-lg p-2 focus:outline-none focus:border-teal-500 transition"
                            />
                          </div>
                          <div>
                            <label className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider mb-1">Số ngày *</label>
                            <input
                              type="number"
                              required
                              min={1}
                              value={med.days}
                              onChange={e => handleMedicationChange(idx, 'days', parseInt(e.target.value) || 1)}
                              className="w-full bg-white border border-slate-200 text-xs text-slate-700 rounded-lg p-2 focus:outline-none focus:border-teal-500 transition"
                            />
                          </div>
                        </div>
                      </div>

                      <div>
                        <label className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider mb-1">Tần suất & Lời dặn uống thuốc</label>
                        <input
                          type="text"
                          placeholder="Ví dụ: 2 lần/ngày (sáng 1 viên, tối 1 viên sau ăn)"
                          value={med.frequency}
                          onChange={e => handleMedicationChange(idx, 'frequency', e.target.value)}
                          className="w-full bg-white border border-slate-200 text-xs text-slate-700 rounded-lg p-2 focus:outline-none focus:border-teal-500 transition"
                        />
                      </div>

                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Action buttons */}
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => router.push('/doctor/appointments')}
                className="px-5 py-2.5 bg-white border border-slate-200 hover:border-slate-300 text-slate-600 text-xs font-semibold rounded-lg transition shadow-sm"
              >
                Hủy bỏ
              </button>
              <button
                type="submit"
                disabled={submitting}
                className="flex items-center gap-1.5 px-5 py-2.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-bold rounded-lg transition disabled:opacity-50"
              >
                {submitting ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <CheckCircle2 className="w-3.5 h-3.5" />}
                Hoàn thành ca khám
              </button>
            </div>

          </form>
        </div>

        {/* Right Safety Sidebar Column */}
        <div className="space-y-5">
          
          {/* Pediatric Dose Calculator Tool */}
          {isPediatric && (
            <div className="bg-teal-50/50 border border-teal-200 p-4 rounded-2xl space-y-3.5 relative shadow-sm">
              <h4 className="text-xs font-bold text-teal-800 uppercase tracking-wider flex items-center gap-1.5">
                <Calculator className="w-4 h-4" />
                Dose Calculator (Nhi khoa)
              </h4>
              
              <div className="space-y-2">
                <div>
                  <label className="block text-[9px] text-slate-500 font-bold uppercase tracking-wider mb-1">Cân nặng bé (kg)</label>
                  <input
                    type="number"
                    min={1}
                    value={childWeight}
                    onChange={e => setChildWeight(parseFloat(e.target.value) || 0)}
                    className="w-full bg-white border border-teal-200 text-xs text-teal-900 rounded-lg p-2 focus:outline-none focus:border-teal-500 transition"
                  />
                </div>
                <div>
                  <label className="block text-[9px] text-slate-500 font-bold uppercase tracking-wider mb-1">Liều lượng (mg/kg/ngày)</label>
                  <select
                    value={multiplier}
                    onChange={e => setMultiplier(parseInt(e.target.value))}
                    className="w-full bg-white border border-teal-200 text-xs text-teal-900 rounded-lg p-2 focus:outline-none focus:border-teal-500 transition"
                  >
                    <option value={15}>15 mg/kg (Paracetamol chuẩn)</option>
                    <option value={30}>30 mg/kg (Amoxicillin nhẹ)</option>
                    <option value={50}>50 mg/kg (Amoxicillin nặng)</option>
                    <option value={10}>10 mg/kg (Ibuprofen chuẩn)</option>
                  </select>
                </div>
              </div>

              <div className="bg-white p-3 rounded-lg border border-teal-200/60 text-center shadow-sm">
                <p className="text-[10px] text-slate-500 uppercase font-bold">Tổng liều gợi ý / ngày</p>
                <p className="text-base font-bold text-teal-600 mt-1">{Math.round(calcResult)} mg</p>
                <p className="text-[9px] text-slate-500 mt-0.5">Mỗi lần: {Math.round(calcResult / 2)}mg (chia làm 2 lần)</p>
              </div>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setIsPediatric(false)}
                  className="flex-1 py-1.5 border border-teal-200 bg-white hover:bg-teal-50/50 text-teal-700 text-xs font-semibold rounded-lg transition"
                >
                  Đóng
                </button>
                {activeCalcIdx !== null && (
                  <button
                    type="button"
                    onClick={() => applyCalcToMed(activeCalcIdx)}
                    className="flex-1 py-1.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-bold rounded-lg"
                  >
                    Áp dụng liều
                  </button>
                )}
              </div>
            </div>
          )}

          {/* Real-time Clinical Safety Panel */}
          <div className="bg-white border border-slate-200 p-5 rounded-2xl space-y-4 shadow-sm">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center gap-1.5">
              <ShieldAlert className="w-4 h-4 text-teal-600" />
              Cảnh báo Lâm sàng (eRx)
            </h3>

            {safetyAlerts.length === 0 && interactionAlerts.length === 0 ? (
              <div className="text-slate-400 text-xs py-4 text-center">
                Chưa phát hiện nguy cơ lâm sàng. Đơn thuốc tạm thời an toàn.
              </div>
            ) : (
              <div className="space-y-3">
                {/* Interaction list */}
                {interactionAlerts.map((alert, idx) => (
                  <div
                    key={idx}
                    className={`p-3 rounded-lg border text-xs flex gap-2.5 items-start leading-relaxed ${
                      alert.severity === 'danger'
                        ? 'bg-red-50 border-red-200 text-red-600 shadow-sm shadow-red-500/5'
                        : 'bg-amber-50 border-amber-200 text-amber-750 shadow-sm shadow-amber-500/5'
                    }`}
                  >
                    <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                    <span>{alert.message}</span>
                  </div>
                ))}

                {/* Dosage & Duplication list */}
                {safetyAlerts.map((alert, idx) => (
                  <div
                    key={idx}
                    className="p-3 bg-red-50 border border-red-200 text-red-600 rounded-lg text-xs flex gap-2.5 items-start leading-relaxed shadow-sm shadow-red-500/5"
                  >
                    <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                    <span>{alert}</span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Patient current medicine list */}
          <div className="bg-white border border-slate-200 p-5 rounded-2xl space-y-3.5 shadow-sm">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center gap-1.5">
              <Clock className="w-4 h-4 text-slate-500" />
              Tủ thuốc bệnh nhân đang dùng
            </h3>
            
            {patientMeds.length === 0 ? (
              <div className="text-slate-500 text-xs py-4 text-center">
                Tủ thuốc bệnh nhân hiện tại đang trống.
              </div>
            ) : (
              <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
                {patientMeds.map((med) => (
                  <div key={med.id} className="bg-slate-50 p-2.5 rounded-lg border border-slate-200 flex justify-between items-center text-xs shadow-sm">
                    <div>
                      <p className="font-semibold text-slate-700">{med.name}</p>
                      <p className="text-[10px] text-slate-500 mt-0.5">{med.dosage || 'Không rõ liều'} · {med.frequency || 'Không rõ tần suất'}</p>
                    </div>
                    <span className="text-[9px] bg-blue-50 text-blue-600 border border-blue-200 px-1.5 py-0.5 rounded font-mono">
                      Active
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* AI Drug Recommendation Assistant Panel */}
          <div className="bg-white border border-slate-200 p-5 rounded-2xl space-y-4 shadow-sm">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-purple-600" />
              Trợ lý Kê đơn AI
            </h3>

            <div className="flex gap-2">
              <div className="relative flex-1">
                <input
                  type="text"
                  placeholder="Triệu chứng khám..."
                  value={symptomsQuery}
                  onChange={e => setSymptomsQuery(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 text-xs text-slate-750 rounded-lg pl-8 pr-2.5 py-2.5 focus:outline-none focus:border-teal-500 focus:bg-white transition"
                  onKeyDown={e => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      void fetchRecommendations();
                    }
                  }}
                />
                <Search className="w-3.5 h-3.5 text-slate-400 absolute left-2.5 top-3.5" />
              </div>
              <button
                type="button"
                onClick={() => void fetchRecommendations()}
                disabled={aiLoading || !symptomsQuery.trim()}
                className="px-3 py-2 bg-teal-600 hover:bg-teal-500 text-white text-xs font-bold rounded-lg transition disabled:opacity-50 flex items-center justify-center shrink-0"
                title="Lấy gợi ý AI"
              >
                {aiLoading ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : 'Gợi ý'}
              </button>
            </div>

            {aiError && (
              <div className="bg-red-50 border border-red-200 text-red-600 text-[10px] p-2.5 rounded-lg">
                {aiError}
              </div>
            )}

            {/* Disease Predictions */}
            {aiPredictedDiseases.length > 0 && (
              <div className="space-y-1.5">
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Chẩn đoán dự đoán</p>
                <div className="flex flex-wrap gap-1.5">
                  {aiPredictedDiseases.map((d, idx) => (
                    <span key={idx} className="text-[10px] bg-blue-50 text-blue-700 border border-blue-200 px-2 py-0.5 rounded-full font-medium">
                      {d.nameVi || d.name} ({Math.round(d.probability * 100)}%)
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Safety Alerts (from AI session) */}
            {aiSafetyWarnings.length > 0 && (
              <div className="space-y-1.5">
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Cảnh báo An toàn AI</p>
                <div className="space-y-1.5">
                  {aiSafetyWarnings.map((warning, idx) => (
                    <div key={idx} className="p-2.5 bg-amber-50 border border-amber-250 text-amber-800 rounded-lg text-[10px] leading-normal flex gap-1.5 items-start">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0 text-amber-600 mt-0.5" />
                      <span>{warning}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Recommended Medicines List */}
            <div className="space-y-3.5">
              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Thuốc được khuyến nghị</p>
              
              {aiRecommendations.length === 0 ? (
                <div className="text-slate-400 text-xs py-4 text-center border border-dashed border-slate-200 rounded-xl bg-slate-50/50">
                  {aiLoading ? (
                    <div className="flex flex-col items-center gap-1.5 py-2">
                      <Loader2 className="w-4 h-4 animate-spin text-teal-600" />
                      <span className="text-[10px] text-slate-500">Đang tìm kiếm thuốc tối ưu...</span>
                    </div>
                  ) : (
                    'Chưa có gợi ý thuốc. Nhấn Gợi ý để tải.'
                  )}
                </div>
              ) : (
                <div className="space-y-3 max-h-[350px] overflow-y-auto pr-1">
                  {aiRecommendations.map((rec) => (
                    <div key={rec.drugId} className="bg-slate-50 border border-slate-200 rounded-xl p-3.5 space-y-2.5 shadow-sm text-xs relative group hover:border-slate-300 transition">
                      <div className="flex justify-between items-start gap-2">
                        <div className="min-w-0 flex-1">
                          <p className="font-semibold text-slate-800 text-[13px] truncate" title={rec.name}>{rec.name}</p>
                          <p className="text-[10px] text-slate-400 font-medium italic mt-0.5 truncate" title={rec.genericName}>{rec.genericName}</p>
                        </div>
                        <button
                          type="button"
                          onClick={() => handleQuickAdd(rec)}
                          className="px-2 py-1 bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200 rounded text-[10px] font-bold transition flex items-center gap-0.5 shrink-0"
                        >
                          <Plus className="w-3 h-3" />
                          Kê đơn
                        </button>
                      </div>

                      {/* Score Badges */}
                      <div className="flex flex-wrap gap-1">
                        <span className="text-[9px] bg-emerald-50 text-emerald-700 border border-emerald-250 px-1.5 py-0.5 rounded font-medium">
                          Khớp: {Math.round((rec.scores?.profile ?? 0) * 100)}%
                        </span>
                        <span className="text-[9px] bg-teal-50 text-teal-700 border border-teal-250 px-1.5 py-0.5 rounded font-medium">
                          An toàn: {Math.round((rec.scores?.safety ?? 0) * 100)}%
                        </span>
                        {rec.scores?.evidence > 0 && (
                          <span className="text-[9px] bg-purple-50 text-purple-700 border border-purple-250 px-1.5 py-0.5 rounded font-medium">
                            Y văn: {Math.round((rec.scores?.evidence ?? 0) * 100)}%
                          </span>
                        )}
                      </div>

                      {/* Dosage info */}
                      {rec.dosage && (
                        <p className="text-[10px] text-slate-655 bg-white p-2 rounded border border-slate-100">
                          <span className="font-bold text-slate-700">Liều:</span> {rec.dosage} - {rec.frequency} {rec.instruction ? `(${rec.instruction})` : ''}
                        </p>
                      )}

                      {/* Interaction Warnings */}
                      {rec.interactionWarnings?.length > 0 && (
                        <div className="p-2 bg-red-50/50 border border-red-200 text-red-600 rounded text-[10px] leading-normal space-y-0.5">
                          {rec.interactionWarnings.map((w: string, idx: number) => (
                            <div key={idx} className="flex gap-1 items-start">
                              <span className="mt-0.5 shrink-0 text-red-500">•</span>
                              <span>{w}</span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

        </div>

      </div>

      {/* safety check confirmation modal */}
      <ConfirmModal
        isOpen={showConfirmSubmit}
        onClose={() => setShowConfirmSubmit(false)}
        onConfirm={executeSubmit}
        title="Cảnh báo an toàn lâm sàng"
        message="Hệ thống phát hiện tương tác thuốc nguy hại ở mức Đỏ (Nguy hiểm) giữa đơn thuốc đang kê với các thuốc trong tủ hiện tại của bệnh nhân. Bạn có chắc chắn muốn tiếp tục lưu đơn thuốc này không?"
        confirmText="Tôi chịu trách nhiệm - Vẫn lưu đơn"
        cancelText="Quay lại sửa đơn"
        type="warning"
      />

    </div>
  );
}

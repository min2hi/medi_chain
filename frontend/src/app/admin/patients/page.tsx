'use client';

import { useState, useEffect, useCallback } from 'react';
import { StaffApi, PatientRecord } from '@/services/staff.service';
import { 
  HeartPulse, Search, User, Phone, Mail, 
  ChevronRight, Calendar, Stethoscope, Pill, X, Clock,
  ClipboardList
} from 'lucide-react';

export default function PatientsPage() {
  const [patients, setPatients] = useState<PatientRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  
  // Selected patient for side drawer
  const [selectedPatient, setSelectedPatient] = useState<PatientRecord | null>(null);

  const loadPatients = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await StaffApi.getPatients();
      if (res.success && res.data) {
        setPatients(res.data);
      }
    } catch {
      setError('Không thể tải danh sách bệnh nhân');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadPatients();
  }, [loadPatients]);

  const filteredPatients = patients.filter(p => {
    const q = search.toLowerCase().trim();
    if (!q) return true;
    return (
      p.name.toLowerCase().includes(q) ||
      p.email.toLowerCase().includes(q) ||
      (p.phone && p.phone.includes(q))
    );
  });

  // Helper to parse unstructured doctor notes (diagnosis, meds, instructions)
  const parseNotes = (notes: string | null | undefined) => {
    if (!notes) return { diagnosis: '', meds: [] as string[], instructions: '' };
    
    const lines = notes.split('\n');
    let diagnosis = '';
    const meds: string[] = [];
    let instructions = '';
    
    let currentMode: 'diagnosis' | 'meds' | 'instructions' | null = null;
    
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('───')) continue;
      
      if (trimmed.startsWith('CHẨN ĐOÁN:')) {
        diagnosis = trimmed.replace('CHẨN ĐOÁN:', '').trim();
        currentMode = 'diagnosis';
      } else if (trimmed.startsWith('THUỐC KÊ:')) {
        currentMode = 'meds';
      } else if (trimmed.startsWith('LỜI DẶN:')) {
        instructions = trimmed.replace('LỜI DẶN:', '').trim();
        currentMode = 'instructions';
      } else {
        if (currentMode === 'meds' && (trimmed.startsWith('•') || trimmed.startsWith('-'))) {
          meds.push(trimmed.substring(1).trim());
        } else if (currentMode === 'diagnosis') {
          diagnosis += ' ' + trimmed;
        } else if (currentMode === 'instructions') {
          instructions += ' ' + trimmed;
        }
      }
    }
    
    // Fallback if notes are plain freeform text
    if (!diagnosis && !meds.length && !instructions) {
      diagnosis = notes;
    }
    
    return { diagnosis, meds, instructions };
  };

  return (
    <div className="relative min-h-[80vh]">
      <div className={`space-y-5 transition-all duration-300 ${selectedPatient ? 'pr-[440px]' : ''}`}>
        
        {/* Header */}
        <div>
          <div className="flex items-center gap-2 mb-1">
            <HeartPulse className="w-5 h-5 text-slate-400" />
            <h1 className="text-base font-semibold text-white">Danh bạ bệnh nhân</h1>
            <span className="text-[11px] bg-slate-800 text-slate-400 border border-slate-700 px-2 py-0.5 rounded-full">
              {patients.length} bệnh nhân
            </span>
          </div>
          <p className="text-xs text-slate-500">
            Xem hồ sơ thông tin và bệnh án lịch sử của bệnh nhân đã khám tại phòng khám.
          </p>
        </div>

        {/* Search */}
        <div className="relative max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-500" />
          <input
            type="text"
            placeholder="Tìm tên, SĐT, email bệnh nhân..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-md pl-8 pr-3 py-2 focus:outline-none focus:border-slate-650"
          />
        </div>

        {/* Directory grid/table */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-16 gap-2 text-slate-500 text-xs">
              <div className="w-4 h-4 border-2 border-slate-700 border-t-blue-400 rounded-full animate-spin" />
              Đang tải danh bạ...
            </div>
          ) : error ? (
            <div className="text-center py-16 text-red-400 text-xs">{error}</div>
          ) : filteredPatients.length === 0 ? (
            <div className="text-center py-16 text-slate-600 text-xs font-medium">Không tìm thấy bệnh nhân nào.</div>
          ) : (
            <table className="w-full text-xs text-left">
              <thead>
                <tr className="border-b border-slate-800">
                  <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Bệnh nhân</th>
                  <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Thông tin liên hệ</th>
                  <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase text-center">Lượt khám</th>
                  <th className="px-4 py-3 text-[10px] text-slate-600 font-semibold tracking-wider uppercase">Lần khám cuối</th>
                  <th className="px-4 py-3 text-right"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/50">
                {filteredPatients.map(patient => (
                  <tr 
                    key={patient.id} 
                    onClick={() => setSelectedPatient(patient)}
                    className={`hover:bg-slate-800/20 cursor-pointer transition-colors ${
                      selectedPatient?.id === patient.id ? 'bg-blue-500/5 border-l-2 border-l-blue-500' : ''
                    }`}
                  >
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 rounded-full bg-slate-850 flex items-center justify-center text-slate-400">
                          <User className="w-3.5 h-3.5" />
                        </div>
                        <div className="font-semibold text-slate-200">{patient.name}</div>
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex flex-col gap-0.5">
                        <span className="text-slate-400 flex items-center gap-1">
                          <Phone className="w-2.5 h-2.5 text-slate-600" />
                          {patient.phone || 'Chưa có SĐT'}
                        </span>
                        <span className="text-[10px] text-slate-500 flex items-center gap-1">
                          <Mail className="w-2.5 h-2.5 text-slate-600" />
                          {patient.email}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-center font-semibold text-slate-300 font-mono">
                      {patient.count}
                    </td>
                    <td className="px-4 py-3.5 text-slate-500">
                      {patient.lastVisit 
                        ? new Date(patient.lastVisit).toLocaleDateString('vi-VN') 
                        : 'N/A'}
                    </td>
                    <td className="px-4 py-3.5 text-right">
                      <ChevronRight className="w-4 h-4 text-slate-600 inline" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Slide-over side drawer */}
      {selectedPatient && (
        <div className="fixed inset-y-12 right-0 w-[420px] bg-slate-900 border-l border-slate-800 z-30 shadow-2xl flex flex-col animate-in slide-in-from-right duration-200">
          {/* Drawer Header */}
          <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/40">
            <div className="flex items-center gap-2">
              <User className="w-4 h-4 text-blue-400" />
              <h2 className="text-xs font-semibold text-white uppercase tracking-wider">Hồ sơ bệnh án chi tiết</h2>
            </div>
            <button 
              onClick={() => setSelectedPatient(null)}
              className="p-1 hover:bg-slate-850 rounded text-slate-500 hover:text-slate-300 transition"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Drawer Body */}
          <div className="flex-1 overflow-y-auto p-5 space-y-6">
            
            {/* Patient overview card */}
            <div className="bg-slate-950/60 border border-slate-800 p-4 rounded-xl space-y-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-blue-500/10 border border-blue-500/25 flex items-center justify-center text-blue-400">
                  <User className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-white">{selectedPatient.name}</h3>
                  <span className="text-[10px] text-slate-500 font-mono">Mã HS: {selectedPatient.id.substring(0, 8).toUpperCase()}</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 pt-2 text-[11px] border-t border-slate-800/40">
                <div className="text-slate-500">
                  SĐT: <span className="text-slate-300 font-medium">{selectedPatient.phone || 'Chưa cập nhật'}</span>
                </div>
                <div className="text-slate-500 text-right">
                  Lượt khám: <span className="text-slate-300 font-semibold font-mono">{selectedPatient.count}</span>
                </div>
                <div className="text-slate-500 col-span-2 truncate">
                  Email: <span className="text-slate-300 font-medium font-mono">{selectedPatient.email}</span>
                </div>
              </div>
            </div>

            {/* Visit History Timeline */}
            <div className="space-y-4">
              <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                <ClipboardList className="w-3.5 h-3.5" />
                Lịch sử thăm khám ({selectedPatient.appointments.length})
              </h3>

              {selectedPatient.appointments.length === 0 ? (
                <p className="text-xs text-slate-600 text-center py-6">Không có dữ liệu lịch sử khám bệnh.</p>
              ) : (
                <div className="relative border-l border-slate-800 pl-4 ml-2 space-y-5">
                  {selectedPatient.appointments.map(appt => {
                    const parsed = parseNotes(appt.doctorNotes);
                    return (
                      <div key={appt.id} className="relative group">
                        
                        {/* Timeline point indicator */}
                        <div className="absolute -left-[21px] top-1 w-2.5 h-2.5 rounded-full bg-slate-900 border-2 border-slate-700 group-hover:border-blue-400 transition-colors" />
                        
                        {/* Appointment Card */}
                        <div className="bg-slate-950/40 hover:bg-slate-950/80 border border-slate-800/80 rounded-xl p-3.5 space-y-3 transition-colors">
                          <div className="flex items-center justify-between border-b border-slate-800/30 pb-2">
                            <span className="text-[10px] text-slate-500 font-mono flex items-center gap-1">
                              <Calendar className="w-3 h-3 text-slate-600" />
                              {new Date(appt.date).toLocaleDateString('vi-VN')}
                            </span>
                            <span className="text-[10px] px-1.5 py-0.5 bg-slate-800 border border-slate-700 text-slate-400 rounded">
                              {appt.status}
                            </span>
                          </div>

                          <div className="text-xs text-slate-300 font-medium flex items-center gap-1.5">
                            <Stethoscope className="w-3.5 h-3.5 text-blue-400" />
                            Lý do: {appt.title}
                          </div>

                          {/* Notes parsing details */}
                          {appt.doctorNotes ? (
                            <div className="space-y-2 pt-1 border-t border-slate-800/30 text-[11px] leading-relaxed">
                              {parsed.diagnosis && (
                                <div className="text-slate-400">
                                  <span className="text-slate-500 font-semibold uppercase text-[9px] block">Chẩn đoán</span>
                                  {parsed.diagnosis}
                                </div>
                              )}
                              
                              {parsed.meds.length > 0 && (
                                <div className="text-slate-400 space-y-0.5">
                                  <span className="text-slate-500 font-semibold uppercase text-[9px] block flex items-center gap-1">
                                    <Pill className="w-2.5 h-2.5 text-emerald-400" /> Thuốc kê đơn
                                  </span>
                                  <ul className="list-disc list-inside pl-1 space-y-0.5 text-slate-300">
                                    {parsed.meds.map((med, idx) => (
                                      <li key={idx} className="marker:text-emerald-500">{med}</li>
                                    ))}
                                  </ul>
                                </div>
                              )}

                              {parsed.instructions && (
                                <div className="text-slate-400">
                                  <span className="text-slate-500 font-semibold uppercase text-[9px] block">Lời dặn bác sĩ</span>
                                  {parsed.instructions}
                                </div>
                              )}
                            </div>
                          ) : (
                            <div className="text-[10px] text-slate-600 italic">Không có ghi chép bệnh án lâm sàng.</div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

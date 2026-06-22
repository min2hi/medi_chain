'use client';

import React, { useEffect, useState } from 'react';
import { StaffApi, PatientRecord } from '@/services/staff.service';
import { Search, User, FileText, Phone, Mail, Loader2, Calendar } from 'lucide-react';

export default function DoctorPatients() {
  const [patients, setPatients] = useState<PatientRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedPatient, setSelectedPatient] = useState<PatientRecord | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchPatients = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await StaffApi.getPatients();
        if (res.success && res.data) {
          setPatients(res.data);
          if (res.data.length > 0) {
            setSelectedPatient(res.data[0]);
          }
        } else {
          setError(res.message || 'Không thể tải danh sách bệnh án bệnh nhân');
        }
      } catch {
        setError('Lỗi kết nối máy chủ');
      } finally {
        setLoading(false);
      }
    };
    void fetchPatients();
  }, []);

  const filtered = patients.filter(p =>
    p.name?.toLowerCase().includes(search.toLowerCase()) || p.email?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-5">
      
      {/* Header */}
      <div>
        <div className="flex items-center gap-2 mb-1">
          <User className="w-5 h-5 text-slate-400" />
          <h1 className="text-base font-semibold text-white">Danh sách bệnh án bệnh nhân</h1>
        </div>
        <p className="text-xs text-slate-500">
          Tra cứu hồ sơ thông tin, tiền sử bệnh án và lịch sử đơn thuốc của bệnh nhân đã khám.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left column: Patients Directory */}
        <div className="bg-slate-900 border border-slate-850 rounded-2xl p-4 flex flex-col gap-3 h-[70vh]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-500" />
            <input
              type="text"
              placeholder="Tìm bệnh nhân..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 text-slate-205 text-xs rounded-lg pl-8 pr-3 py-2.5 focus:outline-none"
            />
          </div>

          <div className="flex-1 overflow-y-auto space-y-1.5 pr-1">
            {loading ? (
              <div className="text-slate-600 text-xs py-12 text-center flex items-center justify-center gap-1.5">
                <Loader2 className="w-3.5 h-3.5 animate-spin text-teal-400" />
                Đang tải...
              </div>
            ) : filtered.length === 0 ? (
              <div className="text-slate-655 text-xs py-12 text-center">Không tìm thấy bệnh nhân nào.</div>
            ) : (
              filtered.map(p => {
                const isSelected = selectedPatient?.id === p.id;
                return (
                  <button
                    key={p.id}
                    onClick={() => setSelectedPatient(p)}
                    className={`w-full text-left p-3 rounded-xl border transition flex items-center gap-3 ${
                      isSelected
                        ? 'bg-slate-950 border-slate-800 text-white shadow-sm'
                        : 'bg-transparent border-transparent text-slate-400 hover:bg-slate-950/40 hover:text-slate-250'
                    }`}
                  >
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold ${
                      isSelected ? 'bg-teal-500/10 text-teal-400 border border-teal-500/20' : 'bg-slate-800 text-slate-405'
                    }`}>
                      {p.name?.slice(0, 2).toUpperCase() || 'BN'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-semibold truncate leading-none mb-1">{p.name}</p>
                      <p className="text-[10px] text-slate-500 truncate">{p.email}</p>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* Right column: Patient Clinical History */}
        <div className="lg:col-span-2 bg-slate-900 border border-slate-850 p-5 rounded-2xl flex flex-col h-[70vh]">
          {selectedPatient ? (
            <div className="flex flex-col h-full overflow-hidden">
              
              {/* Header profile info */}
              <div className="border-b border-slate-850 pb-4 shrink-0 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h2 className="text-sm font-bold text-white">{selectedPatient.name}</h2>
                  <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-slate-500 text-[10px] mt-1.5">
                    <span className="flex items-center gap-1"><Mail className="w-3 h-3" /> {selectedPatient.email}</span>
                    {selectedPatient.phone && (
                      <span className="flex items-center gap-1"><Phone className="w-3 h-3" /> {selectedPatient.phone}</span>
                    )}
                  </div>
                </div>
                <div className="text-left sm:text-right shrink-0">
                  <span className="text-[9px] bg-slate-800 text-slate-405 border border-slate-700 px-2 py-0.5 rounded font-mono">
                    Lần khám cuối: {selectedPatient.lastVisit ? new Date(selectedPatient.lastVisit).toLocaleDateString('vi-VN') : 'Chưa khám'}
                  </span>
                </div>
              </div>

              {/* Appointments History List */}
              <div className="flex-1 overflow-y-auto py-4 space-y-4 pr-1">
                <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                  <FileText className="w-4 h-4 text-slate-555" />
                  Lịch sử ca khám bệnh ({selectedPatient.appointments?.length || 0})
                </h3>

                {!selectedPatient.appointments || selectedPatient.appointments.length === 0 ? (
                  <div className="text-slate-655 text-xs py-12 text-center">Bệnh nhân chưa có lịch hẹn khám nào.</div>
                ) : (
                  <div className="space-y-3">
                    {selectedPatient.appointments
                      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                      .map((apt) => (
                        <div key={apt.id} className="bg-slate-950 border border-slate-855 p-4 rounded-xl space-y-3">
                          <div className="flex justify-between items-start">
                            <div>
                              <p className="text-xs font-bold text-slate-205">{apt.title}</p>
                              <p className="text-[10px] text-slate-500 mt-1 flex items-center gap-1">
                                <Calendar className="w-3 h-3" />
                                {new Date(apt.date).toLocaleDateString('vi-VN')} lúc {new Date(apt.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </p>
                            </div>
                            <span className={`text-[9px] px-1.5 py-0.5 rounded font-semibold ${
                              apt.status === 'COMPLETED' ? 'bg-teal-500/10 text-teal-400 border border-teal-500/20' :
                              apt.status === 'CANCELLED' ? 'bg-red-500/10 text-red-400 border border-red-500/20' :
                              'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                            }`}>
                              {apt.status}
                            </span>
                          </div>

                          {apt.doctorNotes && (
                            <div className="bg-slate-900 border border-slate-850 p-3 rounded-lg text-xs leading-relaxed text-slate-350 font-medium whitespace-pre-wrap">
                              {apt.doctorNotes}
                            </div>
                          )}
                        </div>
                      ))}
                  </div>
                )}
              </div>

            </div>
          ) : (
            <div className="text-slate-650 text-xs py-24 text-center m-auto">Vui lòng chọn một bệnh nhân để xem chi tiết bệnh án.</div>
          )}
        </div>

      </div>

    </div>
  );
}

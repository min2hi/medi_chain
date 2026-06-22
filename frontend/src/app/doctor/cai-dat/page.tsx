'use client';

import React, { useEffect, useState } from 'react';
import { ProfileApi } from '@/services/api.client';
import { Settings, Shield, User, Loader2, AlertCircle, CheckCircle2 } from 'lucide-react';

export default function DoctorSettings() {
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // States
  const [licenseNumber, setLicenseNumber] = useState('');
  const [specialty, setSpecialty] = useState('');
  const [clinicAddress, setClinicAddress] = useState('');
  const [licenseVerified, setLicenseVerified] = useState(false);

  useEffect(() => {
    const fetchProfile = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await ProfileApi.get();
        if (res.success && res.data) {
          const profile = res.data.profile as {
            licenseNumber?: string;
            specialty?: string;
            clinicAddress?: string;
            licenseVerified?: boolean;
          } | null;
          setLicenseNumber(profile?.licenseNumber || '');
          setSpecialty(profile?.specialty || '');
          setClinicAddress(profile?.clinicAddress || '');
          setLicenseVerified(!!profile?.licenseVerified);
        } else {
          setError(res.message || 'Không thể tải thông tin bác sĩ');
        }
      } catch {
        setError('Lỗi kết nối máy chủ');
      } finally {
        setLoading(false);
      }
    };
    void fetchProfile();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await ProfileApi.update({
        profile: {
          licenseNumber: licenseNumber.trim(),
          specialty: specialty.trim(),
          clinicAddress: clinicAddress.trim(),
        }
      });

      if (res.success) {
        setSuccess('Cập nhật thông tin hành nghề thành công!');
      } else {
        setError(res.message || 'Lỗi khi cập nhật thông tin');
      }
    } catch {
      setError('Lỗi kết nối máy chủ');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-3">
        <Loader2 className="w-5 h-5 text-teal-600 animate-spin" />
        <span className="text-slate-400 text-xs">Đang tải thông tin cá nhân...</span>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      
      {/* Header */}
      <div>
        <div className="flex items-center gap-2 mb-1">
          <Settings className="w-5 h-5 text-slate-500" />
          <h1 className="text-base font-semibold text-slate-800">Cài đặt thông tin hành nghề</h1>
        </div>
        <p className="text-xs text-slate-400">
          Cập nhật thông tin chuyên khoa, chứng chỉ y tế hành nghề và địa chỉ phòng khám của bạn.
        </p>
      </div>

      <div className="bg-white border border-slate-200 p-6 rounded-2xl space-y-5 shadow-sm">
        
        {/* Status verification banner */}
        <div className={`p-4 rounded-xl border flex gap-3 items-start text-xs ${
          licenseVerified 
            ? 'bg-teal-50 border-teal-200 text-teal-800 shadow-sm shadow-teal-500/5' 
            : 'bg-amber-50 border-amber-200 text-amber-800 shadow-sm shadow-amber-500/5'
        }`}>
          <Shield className="w-5 h-5 shrink-0 mt-0.5" />
          <div>
            <p className="font-bold uppercase tracking-wider text-[10px]">
              Trạng thái chứng chỉ: {licenseVerified ? 'Đã xác thực thành công' : 'Đang chờ xác thực'}
            </p>
            <p className="mt-1 leading-relaxed text-slate-600">
              {licenseVerified 
                ? 'Thông tin hành nghề của bạn đã được quản trị viên duyệt. Bạn hiện có đầy đủ quyền hạn mở lịch trực rảnh và khám bệnh.' 
                : 'Thông tin của bạn đang đợi Admin kiểm duyệt. Bạn sẽ không thể mở lịch làm việc rảnh cho đến khi được duyệt.'
              }
            </p>
          </div>
        </div>

        {error && (
          <div className="p-3.5 bg-white border border-red-200 text-red-600 text-xs rounded-lg flex gap-2 items-start shadow-sm shadow-red-500/5">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-red-500" />
            <span>{error}</span>
          </div>
        )}

        {success && (
          <div className="p-3.5 bg-white border border-teal-200 text-teal-600 text-xs rounded-lg flex gap-2 items-start shadow-sm shadow-teal-500/5">
            <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5 text-teal-500" />
            <span>{success}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Số chứng chỉ hành nghề (CCHN) *</label>
              <input
                type="text"
                required
                value={licenseNumber}
                onChange={e => setLicenseNumber(e.target.value)}
                placeholder="Ví dụ: 012345/BYT-CCHN"
                className="w-full bg-slate-50 border border-slate-200 text-xs text-slate-700 rounded-lg p-2.5 focus:outline-none focus:border-teal-500 focus:bg-white transition"
              />
            </div>

            <div>
              <label className="block text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Chuyên khoa *</label>
              <input
                type="text"
                required
                value={specialty}
                onChange={e => setSpecialty(e.target.value)}
                placeholder="Ví dụ: Nội tổng quát, Nhi khoa..."
                className="w-full bg-slate-50 border border-slate-200 text-xs text-slate-700 rounded-lg p-2.5 focus:outline-none focus:border-teal-500 focus:bg-white transition"
              />
            </div>
          </div>

          <div>
            <label className="block text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1.5">Địa chỉ phòng khám làm việc *</label>
            <input
              type="text"
              required
              value={clinicAddress}
              onChange={e => setClinicAddress(e.target.value)}
              placeholder="Ví dụ: Tầng 2, Phòng khám 204, Bệnh viện Bạch Mai..."
              className="w-full bg-slate-50 border border-slate-200 text-xs text-slate-700 rounded-lg p-2.5 focus:outline-none focus:border-teal-500 focus:bg-white transition"
            />
          </div>

          <div className="pt-2 flex justify-end">
            <button
              type="submit"
              disabled={submitting}
              className="flex items-center gap-1.5 px-5 py-2.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-bold rounded-lg transition disabled:opacity-50"
            >
              {submitting ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : null}
              Lưu thay đổi
            </button>
          </div>

        </form>

      </div>

    </div>
  );
}

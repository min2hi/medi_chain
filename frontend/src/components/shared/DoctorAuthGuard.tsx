'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AuthService } from '@/services/auth.client';
import { ProfileApi } from '@/services/api.client';
import { ShieldAlert, Loader2, LogOut, CheckCircle2 } from 'lucide-react';

export const DoctorAuthGuard = ({ children }: { children: React.ReactNode }) => {
    const router = useRouter();
    const [status, setStatus] = useState<'loading' | 'unauthorized' | 'pending_verification' | 'verified'>('loading');
    const [doctorName, setDoctorName] = useState('');

    useEffect(() => {
        const checkAuth = async () => {
            const u = AuthService.getCurrentUser();
            if (!u) {
                router.replace('/auth/login?redirect=' + window.location.pathname);
                return;
            }

            if (u.role !== 'DOCTOR') {
                setStatus('unauthorized');
                return;
            }

            setDoctorName(u.name || 'Bác sĩ');

            try {
                const res = await ProfileApi.get();
                if (res.success && res.data) {
                    const profile = (res.data.profile || res.data) as Record<string, any> | null;
                    if (profile?.licenseVerified) {
                        setStatus('verified');
                    } else {
                        setStatus('pending_verification');
                    }
                } else {
                    setStatus('pending_verification');
                }
            } catch (err) {
                console.error('Failed to load doctor profile:', err);
                setStatus('pending_verification');
            }
        };

        void checkAuth();
    }, [router]);

    const handleLogout = () => {
        AuthService.logout();
        router.replace('/auth/login');
    };

    if (status === 'loading') {
        return (
            <div className="min-h-screen bg-slate-950 flex items-center justify-center">
                <div className="flex flex-col items-center gap-3">
                    <Loader2 className="w-8 h-8 text-teal-400 animate-spin" />
                    <span className="text-slate-400 text-xs">Đang xác thực thông tin bác sĩ...</span>
                </div>
            </div>
        );
    }

    if (status === 'unauthorized') {
        return (
            <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
                <div className="bg-slate-900 border border-slate-800 p-8 rounded-xl text-center max-w-sm w-full">
                    <ShieldAlert className="w-10 h-10 text-red-500 mx-auto mb-4" />
                    <h2 className="text-base font-semibold text-white mb-2">Truy cập bị từ chối</h2>
                    <p className="text-slate-400 text-sm mb-6">
                        Khu vực này chỉ dành riêng cho Bác sĩ điều trị.
                    </p>
                    <button
                        onClick={() => router.push('/')}
                        className="px-5 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition"
                    >
                        Về trang chủ
                    </button>
                </div>
            </div>
        );
    }

    if (status === 'pending_verification') {
        return (
            <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
                <div className="bg-slate-900 border border-slate-800 p-8 rounded-2xl text-center max-w-md w-full shadow-2xl">
                    <div className="w-14 h-14 rounded-full bg-amber-500/10 border border-amber-500/20 flex items-center justify-center mx-auto mb-5">
                        <ShieldAlert className="w-7 h-7 text-amber-400" />
                    </div>
                    <h2 className="text-lg font-semibold text-white mb-2">
                        Chờ Admin xác thực chứng chỉ
                    </h2>
                    <p className="text-slate-400 text-xs leading-relaxed mb-6">
                        Chào Bác sĩ <span className="text-teal-400 font-semibold">{doctorName}</span>. Tài khoản bác sĩ của bạn đang trong trạng thái chờ Quản trị viên duyệt chứng chỉ hành nghề y tế. 
                        Vui lòng đợi hoặc liên hệ Ban quản trị để được hỗ trợ nhanh nhất.
                    </p>
                    <div className="flex flex-col gap-3">
                        <button
                            onClick={() => window.location.reload()}
                            className="px-5 py-2.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-semibold rounded-lg transition"
                        >
                            Tải lại trang
                        </button>
                        <button
                            onClick={handleLogout}
                            className="flex items-center justify-center gap-1.5 px-5 py-2.5 bg-slate-800 hover:bg-slate-750 text-slate-300 text-xs font-medium rounded-lg border border-slate-700 transition"
                        >
                            <LogOut className="w-3.5 h-3.5" />
                            Đăng xuất
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    return <>{children}</>;
};

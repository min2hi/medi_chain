'use client';

import { useState, useRef } from 'react';
import { Lock, Eye, EyeOff, ShieldCheck, AlertCircle } from 'lucide-react';

interface AdminElevationModalProps {
  onSuccess: (password: string) => Promise<boolean>;
  isLoading: boolean;
  error: string | null;
}

// ── Admin Elevation Modal — Web Layer 1 ───────────────────────────────────────
// Tương đương FaceID/Fingerprint trên mobile nhưng dùng Password Re-confirm.
// Xuất hiện khi user navigate vào /admin lần đầu hoặc sau khi session hết hạn.
// Pattern: giống Google "Verify it's you" dialog khi truy cập tài khoản nhạy cảm.
export function AdminElevationModal({ onSuccess, isLoading, error }: AdminElevationModalProps) {
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!password.trim()) return;
    const ok = await onSuccess(password);
    if (!ok) {
      setPassword('');
      inputRef.current?.focus();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/95 backdrop-blur-sm">
      <div className="w-full max-w-sm mx-4">
        {/* Card */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-8 shadow-2xl">
          {/* Icon */}
          <div className="flex justify-center mb-6">
            <div className="w-16 h-16 rounded-full bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center">
              <ShieldCheck className="w-8 h-8 text-indigo-400" />
            </div>
          </div>

          {/* Text */}
          <h2 className="text-white text-lg font-semibold text-center mb-1">
            Xác thực vào Admin Portal
          </h2>
          <p className="text-slate-400 text-sm text-center mb-6 leading-relaxed">
            Nhập lại mật khẩu để xác nhận danh tính.
            <br />
            Phiên Admin có hiệu lực trong <span className="text-indigo-400 font-medium">30 phút</span>.
          </p>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="relative">
              <input
                ref={inputRef}
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Mật khẩu của bạn"
                autoFocus
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 pr-11 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500/50 transition"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 transition"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>

            {/* Error */}
            {error && (
              <div className="flex items-center gap-2 text-red-400 text-xs bg-red-500/10 border border-red-500/20 rounded-lg px-3 py-2">
                <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {/* Submit */}
            <button
              type="submit"
              disabled={isLoading || !password.trim()}
              className="w-full flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-500 disabled:bg-slate-700 disabled:cursor-not-allowed text-white rounded-xl py-3 text-sm font-semibold transition"
            >
              {isLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Đang xác thực...
                </>
              ) : (
                <>
                  <Lock className="w-4 h-4" />
                  Xác thực
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}

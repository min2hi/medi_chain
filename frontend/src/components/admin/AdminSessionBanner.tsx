'use client';

import { Timer, RefreshCw } from 'lucide-react';

interface AdminSessionBannerProps {
  remainingMinutes: number;
  onRenew: () => void;
}

// ── Admin Session Countdown Banner — Web Layer 3 ──────────────────────────────
// Hiện banner vàng phía trên khi phiên Admin còn ≤ 5 phút.
// Pattern: AWS Console, Google Cloud Console đều có countdown banner tương tự.
export function AdminSessionBanner({ remainingMinutes, onRenew }: AdminSessionBannerProps) {
  if (remainingMinutes > 5) return null;

  const isUrgent = remainingMinutes <= 2;

  return (
    <div
      className={`flex items-center justify-between px-5 py-2 text-xs font-medium transition-colors ${
        isUrgent
          ? 'bg-red-500/15 border-b border-red-500/25 text-red-400'
          : 'bg-amber-500/15 border-b border-amber-500/25 text-amber-400'
      }`}
    >
      <div className="flex items-center gap-2">
        <Timer className="w-3.5 h-3.5 shrink-0" />
        <span>
          {isUrgent
            ? `⚠ Phiên Admin hết hạn trong ${remainingMinutes} phút — hãy lưu công việc`
            : `Phiên Admin còn ${remainingMinutes} phút`}
        </span>
      </div>
      <button
        onClick={onRenew}
        className={`flex items-center gap-1.5 hover:opacity-75 transition ${
          isUrgent ? 'text-red-400' : 'text-amber-400'
        }`}
      >
        <RefreshCw className="w-3 h-3" />
        Gia hạn
      </button>
    </div>
  );
}

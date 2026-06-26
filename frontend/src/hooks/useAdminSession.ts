'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { request } from '@/services/api.client';

const ADMIN_TOKEN_KEY = 'adminToken';
const ADMIN_TOKEN_EXPIRY_KEY = 'adminTokenExpiry';
const ADMIN_TTL_MS = 30 * 60 * 1000; // 30 phút

// ── Quản lý Admin Session Token ────────────────────────────────────────────────
// Lưu adminToken riêng (scope='admin', TTL=30 phút) vào sessionStorage.
// sessionStorage: tự xóa khi đóng tab — không bao giờ tồn tại qua phiên làm việc.
// Khác với localStorage: nếu để máy tính mở, attacker phải làm mới tab mới xong.
export const adminTokenStorage = {
  save(token: string) {
    const expiry = Date.now() + ADMIN_TTL_MS;
    sessionStorage.setItem(ADMIN_TOKEN_KEY, token);
    sessionStorage.setItem(ADMIN_TOKEN_EXPIRY_KEY, String(expiry));
  },

  get(): string | null {
    const token = sessionStorage.getItem(ADMIN_TOKEN_KEY);
    const expiry = Number(sessionStorage.getItem(ADMIN_TOKEN_EXPIRY_KEY));
    if (!token || !expiry) return null;
    if (Date.now() > expiry) {
      this.clear();
      return null;
    }
    return token;
  },

  clear() {
    sessionStorage.removeItem(ADMIN_TOKEN_KEY);
    sessionStorage.removeItem(ADMIN_TOKEN_EXPIRY_KEY);
  },

  remainingMs(): number {
    const expiry = Number(sessionStorage.getItem(ADMIN_TOKEN_EXPIRY_KEY));
    if (!expiry) return 0;
    return Math.max(0, expiry - Date.now());
  },
};

// ── Hook chính: useAdminSession ────────────────────────────────────────────────
// Trả về state và actions cho Admin session management.
// Dùng trong admin layout để kiểm soát step-up auth + session countdown.
export function useAdminSession() {
  const [isElevated, setIsElevated] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [remainingMinutes, setRemainingMinutes] = useState(30);
  const countdownRef = useRef<NodeJS.Timeout | null>(null);

  // Kiểm tra session còn hiệu lực khi mount
  useEffect(() => {
    const token = adminTokenStorage.get();
    if (token) {
      setIsElevated(true);
      startCountdown();
    }
    return () => stopCountdown();
  }, []);

  const startCountdown = useCallback(() => {
    stopCountdown();
    countdownRef.current = setInterval(() => {
      const remaining = adminTokenStorage.remainingMs();
      const minutes = Math.ceil(remaining / 60000);
      setRemainingMinutes(minutes);

      if (remaining <= 0) {
        // Token hết hạn
        adminTokenStorage.clear();
        setIsElevated(false);
        stopCountdown();
      }
    }, 10000); // Cập nhật mỗi 10 giây
  }, []);

  const stopCountdown = useCallback(() => {
    if (countdownRef.current) {
      clearInterval(countdownRef.current);
      countdownRef.current = null;
    }
  }, []);

  // Gọi /api/auth/admin-elevate với password, nhận adminToken
  const elevate = useCallback(async (password: string): Promise<boolean> => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await request<any>('/auth/admin-elevate', {
        method: 'POST',
        body: JSON.stringify({ password }),
      });
      if (result.success && result.data?.adminToken) {
        adminTokenStorage.save(result.data.adminToken);
        setIsElevated(true);
        setRemainingMinutes(30);
        startCountdown();
        return true;
      } else {
        setError(result.message || 'Xác thực thất bại');
        return false;
      }
    } catch {
      setError('Lỗi kết nối máy chủ');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, [startCountdown]);

  const endSession = useCallback(() => {
    adminTokenStorage.clear();
    setIsElevated(false);
    stopCountdown();
  }, [stopCountdown]);

  return {
    isElevated,
    isLoading,
    error,
    remainingMinutes,
    elevate,
    endSession,
    getAdminToken: adminTokenStorage.get.bind(adminTokenStorage),
  };
}

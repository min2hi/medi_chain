const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

function getAuthHeaders(): HeadersInit {
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

async function request<T>(path: string, options: RequestInit = {}): Promise<{ success: boolean; data?: T; message?: string }> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: { ...getAuthHeaders(), ...(options.headers as HeadersInit) },
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) return { success: false, message: json.message || 'Lỗi kết nối' };
  return json;
}

// Profile
export const ProfileApi = {
  get: () => request<Record<string, unknown>>('/user/profile'),
  update: (body: Record<string, unknown>) =>
    request('/user/profile', { method: 'PUT', body: JSON.stringify(body) }),
};

// Hồ sơ bệnh án (Medical records)
export const RecordsApi = {
  list: () => request<Array<Record<string, unknown>>>('/user/records'),
  get: (id: string) => request<Record<string, unknown>>(`/user/records/${id}`),
  create: (body: { title: string; content?: string; diagnosis?: string; treatment?: string; hospital?: string; date?: string }) =>
    request('/user/records', { method: 'POST', body: JSON.stringify(body) }),
  update: (id: string, body: Partial<{ title: string; content: string; diagnosis: string; treatment: string; hospital: string; date: string }>) =>
    request(`/user/records/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  delete: (id: string) => request(`/user/records/${id}`, { method: 'DELETE' }),
};

// Thuốc (Medicines)
export const MedicinesApi = {
  list: () => request<Array<Record<string, unknown>>>('/user/medicines'),
  get: (id: string) => request<Record<string, unknown>>(`/user/medicines/${id}`),
  create: (body: { name: string; dosage?: string; frequency?: string; instruction?: string; startDate?: string; endDate?: string }) =>
    request('/user/medicines', { method: 'POST', body: JSON.stringify(body) }),
  update: (id: string, body: Partial<{ name: string; dosage: string; frequency: string; instruction: string; startDate: string; endDate: string }>) =>
    request(`/user/medicines/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  delete: (id: string) => request(`/user/medicines/${id}`, { method: 'DELETE' }),
};

// Lịch hẹn (Appointments)
export const AppointmentsApi = {
  list: () => request<Array<Record<string, unknown>>>('/user/appointments'),
  get: (id: string) => request<Record<string, unknown>>(`/user/appointments/${id}`),
  create: (body: { title: string; date: string; notes?: string }) =>
    request('/user/appointments', { method: 'POST', body: JSON.stringify(body) }),
  update: (id: string, body: Partial<{ title: string; date: string; status: string; notes: string }>) =>
    request(`/user/appointments/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  delete: (id: string) => request(`/user/appointments/${id}`, { method: 'DELETE' }),
};

// Chỉ số (Health metrics)
export const MetricsApi = {
  list: (limit?: number) =>
    request<Array<Record<string, unknown>>>(limit ? `/user/metrics?limit=${limit}` : '/user/metrics'),
  create: (body: { type: string; value: number; unit: string; date?: string }) =>
    request('/user/metrics', { method: 'POST', body: JSON.stringify(body) }),
};

// AI Services
export const AIApi = {
  consult: (symptoms: string) =>
    request<any>('/ai/consult', { method: 'POST', body: JSON.stringify({ symptoms }) }),
};

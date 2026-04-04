const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

function getAuthHeaders(): HeadersInit {
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
  const viewAsId = typeof window !== 'undefined' ? localStorage.getItem('viewing_as_userId') : null;

  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(viewAsId ? { 'X-Viewing-As': viewAsId } : {}),
  };
}

async function request<T>(path: string, options: RequestInit = {}): Promise<{ success: boolean; data?: T; message?: string }> {
  try {
    const res = await fetch(`${API_BASE_URL}${path}`, {
      ...options,
      headers: { ...getAuthHeaders(), ...(options.headers as HeadersInit) },
    });

    // Handle 204 No Content or empty responses
    if (res.status === 204) return { success: true };

    const json = await res.json().catch(() => ({}));

    if (!res.ok) {
      // Handle Unauthorized (401)
      if (res.status === 401) {
        if (typeof window !== 'undefined') {
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          window.location.href = '/auth/login?expired=true';
        }
        return { success: false, message: 'Phiên đăng nhập hết hạn hoặc Token không hợp lệ. Vui lòng đăng nhập lại.' };
      }

      // Handle other specific error structures
      const errorMsg = json.message || json.error || `Error ${res.status}`;
      return { success: false, message: errorMsg };
    }

    return json;
  } catch (err: unknown) {
    console.error(`API Request Error [${path}]:`, err);
    return { success: false, message: 'Lỗi kết nối máy chủ' };
  }
}

// Profile & Dashboard
export const ProfileApi = {
  get: () => request<Record<string, unknown>>('/user/profile'),
  update: (body: Record<string, unknown>) =>
    request('/user/profile', { method: 'PUT', body: JSON.stringify(body) }),
  getDashboard: () => request<any>('/user/dashboard'),
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
  create: (body: {
    name: string;
    dosage?: string;
    frequency?: string;
    instruction?: string;
    startDate?: string;
    endDate?: string;
    // Data lineage — chỉ truyền khi thêm từ phiên tư vấn
    drugCandidateId?: string;
    recommendationSessionId?: string;
  }) =>
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
export interface AIMessage {
  id: string; // Changed from string to match backend response which likely returns id
  role: 'USER' | 'ASSISTANT' | 'SYSTEM';
  content: string;
  createdAt: string;
  safetyCheckResult?: string;
  medicalContext?: string;
}

export interface AIConversation {
  id: string;
  type: 'CHAT' | 'CONSULT';
  title?: string;
  createdAt: string;
  lastMessageAt?: string;
}

export interface AIChatResponse {
  conversationId: string;
  message: AIMessage;
  usage?: Record<string, number>;
}

// Recommendation Engine Interfaces
export interface RecommendationResponse extends AIChatResponse {
  sessionId: string;
  recommendedMedicines: Array<{
    drugId: string;       // ID trong bảng DrugCandidate — cần để submit feedback
    name: string;
    genericName: string;
    ingredients: string;
    category: string;
    rank: number;
    finalScore: number;
    sideEffects: string;
    scores: {
      profile: number;
      safety: number;
      history: number;
    }
  }>;
  safetyWarnings: string[];
  engineStats: {
    totalCandidates: number;
    filteredOut: number;
    finalRanked: number;
    processingMs: number;
  };
  source: 'RECOMMENDATION_ENGINE';
}

export const AIApi = {
  // Chat thường (kết nối Backend)
  chat: async (message: string, conversationId?: string) => {
    return request<AIChatResponse>('/ai/chat', {
      method: 'POST',
      body: JSON.stringify({ message, conversationId })
    });
  },

  // Cập nhật: Sử dụng Recommendation Engine cho Tư vấn
  consult: async (symptoms: string, conversationId?: string) => {
    return request<RecommendationResponse>('/recommendation/consult', {
      method: 'POST',
      body: JSON.stringify({ symptoms, conversationId })
    });
  },

  // Lấy danh sách hội thoại
  getConversations: (type?: 'CHAT' | 'CONSULT') =>
    request<AIConversation[]>(type ? `/ai/conversations?type=${type}` : '/ai/conversations'),

  // Lấy tin nhắn
  getMessages: (conversationId: string) =>
    request<AIMessage[]>(`/ai/conversations/${conversationId}/messages`),

  // Xóa hội thoại
  deleteConversation: (id: string) =>
    request(`/ai/conversations/${id}`, { method: 'DELETE' }),
};

export const RecommendationApi = {
  // Lấy feedback hiện tại (null = chưa đánh giá)
  getFeedback: (sessionId: string, drugId: string) =>
    request<{
      id: string; rating: number; outcome: string;
      sideEffect?: string; note?: string; usedDays?: number;
    } | null>(`/recommendation/feedback?sessionId=${sessionId}&drugId=${encodeURIComponent(drugId)}`),

  // Submit feedback cho thuốc (upsert - tạo mới hoặc cập nhật)
  submitFeedback: (body: {
    sessionId: string;
    drugId: string;
    rating: number;
    outcome: 'EFFECTIVE' | 'PARTIALLY_EFFECTIVE' | 'NOT_EFFECTIVE' | 'SIDE_EFFECT' | 'NOT_TAKEN';
    usedDays?: number;
    sideEffect?: string;
    note?: string;
  }) => request('/recommendation/feedback', { method: 'POST', body: JSON.stringify(body) }),

  // Lấy lịch sử phiên tư vấn
  getSessions: (page = 1, limit = 10) =>
    request<any>(`/recommendation/sessions?page=${page}&limit=${limit}`),

  // Lấy chi tiết phiên tư vấn
  getSessionDetail: (id: string) =>
    request<any>(`/recommendation/sessions/${id}`),
};


import { request } from './api.client';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface PendingKeyword {
  id: number;
  keyword: string;
  groupId: string;
  groupLabel: string;
  similarityScore: number;
  sourceKeyword?: { keyword: string; groupId: string } | null;
  changeNote?: string;
  createdAt: string;
}

export interface SafetyKeyword {
  id: number;
  groupId: string;
  groupLabel: string;
  keyword: string;
  language: string;
  isActive: boolean;
  guidelineRef?: string | null;
  changeNote?: string | null;
  createdAt: string;
  updatedAt: string;
  createdBy?: string | null;
  activatedBy?: string | null;
  activatedAt?: string | null;
  versionTag?: string | null;
  reviewStatus?: string | null;
}

export interface ComboRule {
  id: number;
  name: string;
  label: string;
  symptomGroups: string[];
  minMatch: number;
  isActive: boolean;
  guidelineRef?: string | null;
  changeNote?: string | null;
  createdAt: string;
  createdBy?: string | null;
  activatedBy?: string | null;
  activatedAt?: string | null;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: 'ADMIN' | 'DOCTOR' | 'USER';
  createdAt: string;
}

export interface AdminUserListResponse {
  users: AdminUser[];
  pagination: PaginationMeta;
}

export interface CacheStats {
  cache: Record<string, unknown>;
  db: { activeKeywords: number; activeCombos: number; pendingReview: number };
}

export interface AuditEntry {
  id: number;
  groupId: string;
  keyword: string;
  isActive: boolean;
  createdBy: string | null;
  createdAt: string;
  activatedBy: string | null;
  activatedAt: string | null;
  changeNote: string | null;
  versionTag: string | null;
  guidelineRef: string | null;
}

// ─── API ──────────────────────────────────────────────────────────────────────

export const AdminApi = {
  // ─── Pending Review Queue ───────────────────────────────────────────────────
  getPendingReviews: (page = 1, limit = 20, groupId?: string) => {
    let url = `/admin/clinical-rules/pending-review?page=${page}&limit=${limit}`;
    if (groupId) url += `&groupId=${groupId}`;
    return request<{ data: PendingKeyword[]; pagination: PaginationMeta; hint?: string }>(url);
  },
  approveKeyword: (id: number, guidelineRef?: string, changeNote?: string) =>
    request(`/admin/clinical-rules/pending-review/${id}/approve`, {
      method: 'POST',
      body: JSON.stringify({ guidelineRef, changeNote }),
    }),
  rejectKeyword: (id: number, changeNote?: string) =>
    request(`/admin/clinical-rules/pending-review/${id}/reject`, {
      method: 'POST',
      body: JSON.stringify({ changeNote }),
    }),

  // ─── Safety Keywords CRUD ───────────────────────────────────────────────────
  listKeywords: (params?: { groupId?: string; isActive?: boolean }) => {
    let url = '/admin/clinical-rules/keywords?language=vi';
    if (params?.groupId)   url += `&groupId=${params.groupId}`;
    if (params?.isActive !== undefined) url += `&isActive=${params.isActive}`;
    return request<SafetyKeyword[]>(url);
  },
  createKeyword: (body: Partial<SafetyKeyword> & { keyword: string; groupId: string; groupLabel: string }) =>
    request('/admin/clinical-rules/keywords', {
      method: 'POST',
      body: JSON.stringify(body),
    }),
  updateKeyword: (id: number, body: Partial<SafetyKeyword>) =>
    request(`/admin/clinical-rules/keywords/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  activateKeyword: (id: number) =>
    request(`/admin/clinical-rules/keywords/${id}/activate`, { method: 'PATCH' }),
  deactivateKeyword: (id: number, changeNote?: string) =>
    request(`/admin/clinical-rules/keywords/${id}/deactivate`, {
      method: 'PATCH',
      body: JSON.stringify({ changeNote }),
    }),

  // ─── Combo Rules CRUD ───────────────────────────────────────────────────────
  listCombos: (isActive?: boolean) => {
    let url = '/admin/clinical-rules/combos';
    if (isActive !== undefined) url += `?isActive=${isActive}`;
    return request<ComboRule[]>(url);
  },
  createCombo: (body: { name: string; label: string; symptomGroups: string[]; minMatch?: number; guidelineRef?: string; changeNote?: string }) =>
    request('/admin/clinical-rules/combos', {
      method: 'POST',
      body: JSON.stringify(body),
    }),
  activateCombo: (id: number) =>
    request(`/admin/clinical-rules/combos/${id}/activate`, { method: 'PATCH' }),

  // ─── Cache / Telemetry ──────────────────────────────────────────────────────
  invalidateCache: () =>
    request('/admin/clinical-rules/cache/invalidate', { method: 'POST' }),
  getCacheStats: () =>
    request<CacheStats>('/admin/clinical-rules/cache/stats'),
  getAuditLog: (limit = 50, offset = 0) =>
    request<AuditEntry[]>(`/admin/clinical-rules/audit-log?limit=${limit}&offset=${offset}`),

  // ─── User Management ────────────────────────────────────────────────────────
  listUsers: (params?: { role?: string; search?: string; page?: number; limit?: number }) => {
    const q = new URLSearchParams();
    if (params?.role)   q.set('role',   params.role);
    if (params?.search) q.set('search', params.search);
    if (params?.page)   q.set('page',   String(params.page));
    if (params?.limit)  q.set('limit',  String(params.limit));
    return request<{ users: AdminUser[]; pagination: PaginationMeta }>(`/admin/users?${q.toString()}`);
  },
  updateUserRole: (userId: string, role: 'USER' | 'DOCTOR') =>
    request<AdminUser>(`/admin/users/${userId}/role`, {
      method: 'PATCH',
      body: JSON.stringify({ role }),
    }),
};


import { request } from './api.client';

export interface Appointment {
  id: string;
  userId: string;
  doctorId: string | null;
  date: string;
  title: string;
  status: 'PENDING' | 'CONFIRMED' | 'CHECKED_IN' | 'COMPLETED' | 'CANCELLED';
  paymentStatus: 'UNPAID' | 'PENDING' | 'PAID' | 'FAILED';
  consultFee: number;
  doctorNotes: string | null;
  completedAt: string | null;
  createdAt: string;
  user: {
    id: string;
    name: string;
    profile?: {
      phone?: string | null;
    } | null;
  };
}

export interface PatientRecord {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  lastVisit: string | null;
  count: number;
  appointments: Array<{
    id: string;
    date: string;
    title: string;
    status: string;
    paymentStatus: string;
    consultFee: number;
    doctorNotes?: string | null;
  }>;
}

export interface PaymentOverview {
  revenue: number;
  pendingRevenue: number;
  paidCount: number;
  pendingCount: number;
  todayCount: number;
  totalCount: number;
  lastMonthDiff: number;
  consultationFee: number;
  feeUpdatedAt: string | null;
}

export interface Transaction {
  id: string;
  patientName: string;
  type: string;
  amount: number;
  status: 'PAID' | 'PENDING' | 'FAILED';
  date: string;
}

export interface StaffStats {
  users: {
    total: number;
    admins: number;
    doctors: number;
    patients: number;
  };
  system: {
    pendingReview: number;
    activeKeywords: number;
    activeCombos: number;
  };
  activity: {
    aiQueriesLast24h: number;
    blockedAlertsLast24h: number;
  };
  cache: {
    hitRate: string;
  };
  fetchedAt: string;
}

export const StaffApi = {
  // ─── Dashboard Stats ────────────────────────────────────────────────────────
  getStats: () => {
    return request<StaffStats>('/admin/stats');
  },

  // ─── Appointments Management ────────────────────────────────────────────────
  getAppointments: (status?: string) => {
    const url = status && status !== 'ALL' 
      ? `/admin/appointments?status=${status}` 
      : '/admin/appointments';
    return request<Appointment[]>(url);
  },

  updateAppointmentStatus: (id: string, status: 'CONFIRMED' | 'CANCELLED') => {
    return request<Appointment>(`/admin/appointments/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  },

  completeAppointment: (id: string, payload: { doctorNotes: string }) => {
    return request<Appointment>(`/admin/appointments/${id}/complete`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },

  checkInAppointment: (payload: { appointmentId: string; type: string; exp?: number }) => {
    return request<Appointment>(`/admin/appointments/checkin`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  // ─── Patients Directory ─────────────────────────────────────────────────────
  getPatients: () => {
    return request<PatientRecord[]>('/admin/patients');
  },

  // ─── Payment Stats & Fees ───────────────────────────────────────────────────
  getPaymentOverview: () => {
    return request<PaymentOverview>('/admin/payments/overview');
  },

  getTransactions: () => {
    return request<Transaction[]>('/admin/payments/transactions');
  },

  updateConsultationFee: (fee: number) => {
    return request<{ key: string; value: string }>(`/admin/payments/fee`, {
      method: 'PATCH',
      body: JSON.stringify({ fee }),
    });
  },

  // ─── Doctor License Verification ────────────────────────────────────────────
  verifyDoctorLicense: (userId: string) => {
    return request<{ licenseVerified: boolean }>(`/admin/users/${userId}/verify-license`, {
      method: 'PATCH',
    });
  },
};

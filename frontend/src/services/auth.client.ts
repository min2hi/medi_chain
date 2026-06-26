import { request } from './api.client';

export interface RegisterPayload {
    name: string;
    email: string;
    password: string;
}

export interface LoginPayload {
    email: string;
    password: string;
}

export const AuthService = {
    async register(data: RegisterPayload) {
        return request<any>('/auth/register', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    async login(data: LoginPayload) {
        const result = await request<any>('/auth/login', {
            method: 'POST',
            body: JSON.stringify(data),
        });

        if (result.success && result.data?.token) {
            // Lưu token vào localStorage (Cách cơ bản)
            localStorage.setItem('token', result.data.token);
            localStorage.setItem('user', JSON.stringify(result.data.user));
        }

        return result;
    },

    logout() {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
    },

    getCurrentUser() {
        const user = localStorage.getItem('user');
        return user ? JSON.parse(user) : null;
    },

    async forgotPassword(email: string) {
        return request<any>('/auth/forgot-password', {
            method: 'POST',
            body: JSON.stringify({ email }),
        });
    },

    async resetPassword(token: string, newPassword: string) {
        return request<any>('/auth/reset-password', {
            method: 'POST',
            body: JSON.stringify({ token, newPassword }),
        });
    }
};

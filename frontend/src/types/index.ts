export interface User {
    id: string;
    name: string | null;
    email: string | null;
    image: string | null;
    role: 'USER' | 'DOCTOR' | 'ADMIN';
}

export interface ApiResponse<T = unknown> {
    success: boolean;
    message?: string;
    data?: T;
    error?: string;
}

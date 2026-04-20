/**
 * Sharing Types: Định nghĩa cấu trúc dữ liệu cho tính năng chia sẻ.
 */

export enum SharingPermission {
    VIEW = 'VIEW',
    MANAGE = 'MANAGE'
}

export interface NewShareInput {
    email: string;
    type: SharingPermission;
    expiresAt?: string;
}

export interface SharingRecord {
    id: string;
    fromUserId: string;
    toUserId: string;
    type: SharingPermission;
    expiresAt: string | null;
    createdAt: string;
    toUser?: {
        id: string;
        name: string | null;
        email: string | null;
        image: string | null;
    };
    fromUser?: {
        id: string;
        name: string | null;
        email: string | null;
        image: string | null;
    };
}

export declare class AuthService {
    static register(data: {
        email: string;
        password: string;
        name?: string;
    }): Promise<{
        email: string | null;
        name: string | null;
        id: string;
        role: import("../generated/client/index.js").$Enums.UserRole;
    }>;
    static login(data: {
        email: string;
        password: string;
    }): Promise<{
        user: {
            id: string;
            email: string | null;
            name: string | null;
            role: import("../generated/client/index.js").$Enums.UserRole;
        };
        token: string;
    }>;
}

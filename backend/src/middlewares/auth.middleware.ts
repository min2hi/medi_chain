import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
    user?: any;
    viewAs?: string; // ID của người dùng mà mình đang xem hồ sơ (nếu có)
}

export const authMiddleware = (req: AuthRequest, res: Response, next: NextFunction) => {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
        return res.status(401).json({
            success: false,
            message: 'Không có token, quyền truy cập bị từ chối',
        });
    }

    try {
        const decoded: any = jwt.verify(token, process.env.JWT_SECRET!);
        req.user = decoded;

        // Xử lý contextual browsing (Senior feature)
        const viewAs = req.headers['x-viewing-as'];
        if (viewAs && typeof viewAs === 'string' && viewAs !== decoded.id) {
            req.viewAs = viewAs;
        }

        next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            message: 'Token không hợp lệ',
        });
    }
};

/**
 * requireAdmin — cho phép ADMIN và DOCTOR truy cập admin API.
 * Dùng sau authMiddleware:  router.use(authMiddleware, requireAdmin)
 *
 * Pattern: Role-Based Access Control (RBAC) — tiêu chuẩn Big Tech
 * DOCTOR được xem clinical data (read-heavy). Các write-sensitive operations
 * (thay đổi user role) được enforce thêm ở controller level nếu cần.
 */
export const requireAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
        return res.status(401).json({ success: false, message: 'Chưa xác thực' });
    }
    const role = req.user.role as string;
    if (role !== 'ADMIN' && role !== 'DOCTOR') {
        return res.status(403).json({
            success:   false,
            message:   'Chỉ ADMIN hoặc DOCTOR mới có quyền truy cập chức năng này',
            errorCode: 'FORBIDDEN',
        });
    }
    next();
};

/**
 * requireAdminToken — xác thực Admin Elevation Token (TTL: 30 phút).
 * Client gửi token trong header: X-Admin-Token: <adminToken>
 * Token phải có claim scope='admin' — cấp bởi /api/auth/admin-elevate.
 */
export const requireAdminToken = (req: AuthRequest, res: Response, next: NextFunction) => {
    const adminToken = req.headers['x-admin-token'] as string;
    if (!adminToken) {
        return res.status(401).json({
            success: false,
            message: 'Admin token là bắt buộc cho endpoint này',
        });
    }
    try {
        const decoded: any = jwt.verify(adminToken, process.env.JWT_SECRET!);
        if (decoded.scope !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Token không có quyền Admin',
            });
        }
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            message: 'Admin token không hợp lệ hoặc đã hết hạn',
        });
    }
};

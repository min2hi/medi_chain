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
 * requireAdmin — chỉ cho phép user có role ADMIN.
 * Dùng sau authMiddleware:  router.use(authMiddleware, requireAdmin)
 *
 * Pattern: Role-Based Access Control (RBAC) — tiêu chuẩn Big Tech
 * Khi cần thêm role MedicalAdvisor → thêm vào điều kiện này, không cần sửa API.
 */
export const requireAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
        return res.status(401).json({ success: false, message: 'Chưa xác thực' });
    }
    if (req.user.role !== 'ADMIN') {
        return res.status(403).json({
            success: false,
            message: 'Chỉ ADMIN mới có quyền truy cập chức năng này',
        });
    }
    next();
};

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
            // Ở đây lý tưởng nhất là gọi SharingService.canAccess
            // Nhưng để tránh vòng lặp circular dependency hoặc dependency quá nặng trong middleware
            // Ta sẽ gán tạm và các Controller sẽ phải check hoặc dùng một middleware bảo vệ riêng.
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

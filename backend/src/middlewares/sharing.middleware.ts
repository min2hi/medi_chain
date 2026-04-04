import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware.js';
import { SharingService } from '../services/sharing.service.js';

const sharingService = new SharingService();

/**
 * Sharing Middleware (Senior Implementation)
 * Bảo vệ các tài nguyên hồ sơ sức khoẻ bằng cách kiểm tra quyền truy cập thực tế.
 */
export const sharingMiddleware = async (req: AuthRequest, res: Response, next: NextFunction) => {
    const currentUserId = req.user?.id;
    const targetUserId = req.viewAs;

    // Nếu không xem hộ ai, hoặc đang xem chính mình -> cho qua
    if (!targetUserId || targetUserId === currentUserId) {
        return next();
    }

    try {
        // Kiểm tra trong database xem currentUserId có quyền xem targetUserId không
        const hasAccess = await sharingService.canAccess(currentUserId, targetUserId);

        if (!hasAccess) {
            console.warn(`[sharingMiddleware] Access denied for ${currentUserId} viewing ${targetUserId}`);
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền truy cập hồ sơ của người dùng này hoặc quyền đã hết hạn."
            });
        }

        console.log(`[sharingMiddleware] Access granted: ${currentUserId} viewing ${targetUserId}`);
        next();
    } catch (error) {
        console.error('[sharingMiddleware] Error:', error);
        return res.status(500).json({ success: false, message: "Lỗi kiểm tra quyền truy cập." });
    }
};

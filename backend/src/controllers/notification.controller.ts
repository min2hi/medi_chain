import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

export class NotificationController {

  // GET /api/notifications — Lấy 30 thông báo gần nhất, unread first
  // ADMIN/DOCTOR: nhận SYSTEM notifications (sự kiện hệ thống)
  // USER: nhận APPOINTMENT / MEDICINE notifications cá nhân
  static async getMyNotifications(req: AuthRequest, res: Response) {
    try {
      const role = req.user?.role ?? 'USER';
      const isStaff = role === 'ADMIN' || role === 'DOCTOR';

      const notifications = await prisma.notification.findMany({
        where: {
          userId: req.user!.id,
          // Nếu có targetRole field → filter theo đó
          // Nếu không có (data cũ) → hiển thị hết (fallback)
          ...(isStaff
            ? { type: 'SYSTEM' }          // staff chỉ thấy system events
            : { NOT: { type: 'SYSTEM' } } // patient không thấy system events
          ),
        },
        orderBy: [{ isRead: 'asc' }, { createdAt: 'desc' }],
        take: 30,
      });
      const unreadCount = notifications.filter(n => !n.isRead).length;
      return res.status(200).json({ success: true, data: { notifications, unreadCount } });
    } catch (e: any) {
      logger.error('Lỗi lấy thông báo:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }


  // PATCH /api/notifications/read — Đánh dấu tất cả đã đọc
  static async markAllRead(req: AuthRequest, res: Response) {
    try {
      await prisma.notification.updateMany({
        where: { userId: req.user!.id, isRead: false },
        data: { isRead: true },
      });
      return res.status(200).json({ success: true });
    } catch (e: any) {
      logger.error('Lỗi mark read thông báo:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

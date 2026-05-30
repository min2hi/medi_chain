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

      const notifications = await prisma.notification.findMany({
        where: {
          userId: req.user!.id,
          // Phân loại thông báo hiển thị theo vai trò (Role-based separation):
          // - Admin: Chỉ xem các thông báo nhật ký hệ thống (SYSTEM)
          // - Doctor: Chỉ xem các thông báo liên quan đến lịch hẹn (APPOINTMENT)
          // - Patient (USER): Xem thông báo lịch hẹn hoặc thuốc (APPOINTMENT, MEDICINE), không xem SYSTEM
          ...(role === 'ADMIN'
            ? { type: 'SYSTEM' }
            : role === 'DOCTOR'
              ? { type: 'APPOINTMENT' }
              : { NOT: { type: 'SYSTEM' } }
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

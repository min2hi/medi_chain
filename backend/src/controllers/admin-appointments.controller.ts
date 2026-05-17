import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

export class AdminAppointmentsController {
  // Lấy danh sách lịch hẹn của phòng khám
  static async getAppointments(req: AuthRequest, res: Response) {
    try {
      const { status } = req.query;

      // DOCTOR và ADMIN đều xem được
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      const whereClause: any = {};
      if (status && status !== 'ALL') {
        whereClause.status = status;
      }

      const appointments = await prisma.appointment.findMany({
        where: whereClause,
        include: {
          user: {
            select: { id: true, name: true, profile: { select: { phone: true } } }
          }
        },
        orderBy: { date: 'asc' }
      });

      return res.status(200).json({ success: true, data: appointments });
    } catch (e: any) {
      logger.error('Lỗi khi lấy lịch hẹn phòng khám:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }

  // Duyệt / Từ chối
  static async updateStatus(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      if (status !== 'CONFIRMED' && status !== 'REJECTED') {
         return res.status(400).json({ success: false, message: 'Status không hợp lệ' });
      }

      const updated = await prisma.appointment.update({
        where: { id: id as string },
        data: { status }
      });

      return res.status(200).json({ success: true, data: updated });
    } catch (e: any) {
      logger.error('Lỗi cập nhật trạng thái lịch hẹn:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

export class AdminPatientsController {
  // Lấy danh sách bệnh nhân đã từng đặt lịch
  static async getPatients(req: AuthRequest, res: Response) {
    try {
      // DOCTOR và ADMIN đều xem được
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      // Tìm những user có ít nhất 1 appointment
      const users = await prisma.user.findMany({
        where: {
          appointments: {
            some: {} // Has at least one appointment
          }
        },
        select: {
          id: true,
          name: true,
          profile: { select: { phone: true } },
          appointments: {
            select: { date: true },
            orderBy: { date: 'desc' }
          },
          _count: {
            select: { appointments: true }
          }
        }
      });

      const formatted = users.map(u => ({
        id: u.id,
        name: u.name,
        phone: u.profile?.phone || null,
        lastVisit: u.appointments.length > 0 ? u.appointments[0].date : null,
        count: u._count.appointments
      }));

      return res.status(200).json({ success: true, data: formatted });
    } catch (e: any) {
      logger.error('Lỗi khi lấy danh sách bệnh nhân:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

export class AdminPatientsController {
  // Lấy danh sách bệnh nhân đã từng đặt lịch
  static async getPatients(req: AuthRequest, res: Response) {
    try {
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      const users = await prisma.user.findMany({
        where: { appointments: { some: {} } },
        select: {
          id: true,
          name: true,
          email: true,
          profile: { select: { phone: true } },
          appointments: {
            select: { id: true, date: true, title: true, status: true, paymentStatus: true, consultFee: true },
            orderBy: { date: 'desc' },
          },
          _count: { select: { appointments: true } }
        }
      });

      const formatted = users.map(u => ({
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.profile?.phone || null,
        lastVisit: u.appointments.length > 0 ? u.appointments[0].date : null,
        count: u._count.appointments,
        // Include appointments for detail sheet (không cần API riêng)
        appointments: u.appointments,
      }));

      return res.status(200).json({ success: true, data: formatted });
    } catch (e: any) {
      logger.error('Lỗi khi lấy danh sách bệnh nhân:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

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

      const isDoctor = req.user?.role === 'DOCTOR';
      const users = await prisma.user.findMany({
        // Chỉ hiện user có ít nhất 1 lịch ACTIVE (không phải CANCELLED) với bác sĩ này (nếu là DOCTOR)
        where: {
          appointments: {
            some: {
              status: { not: 'CANCELLED' },
              ...(isDoctor ? { doctorId: req.user.id } : {}),
            },
          },
        },
        select: {
          id: true,
          name: true,
          email: true,
          profile: { select: { phone: true } },
          // Lấy lịch để hiển thị detail sheet, nếu là doctor thì chỉ lấy lịch của bác sĩ này
          appointments: {
            where: isDoctor ? { doctorId: req.user.id } : undefined,
            select: { id: true, date: true, title: true, status: true, paymentStatus: true, consultFee: true },
            orderBy: { date: 'desc' },
          },
        }
      });

      const formatted = users.map(u => {
        // Chỉ đếm & lấy lastVisit từ lịch ACTIVE (không tính CANCELLED)
        const activeAppointments = u.appointments.filter(a => a.status !== 'CANCELLED');
        return {
          id: u.id,
          name: u.name,
          email: u.email,
          phone: u.profile?.phone || null,
          lastVisit: activeAppointments.length > 0 ? activeAppointments[0].date : null,
          count: activeAppointments.length,
          // Include ALL appointments for detail sheet (hiển thị cả lịch đã hủy trong history)
          appointments: u.appointments,
        };
      });

      return res.status(200).json({ success: true, data: formatted });
    } catch (e: any) {
      logger.error('Lỗi khi lấy danh sách bệnh nhân:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

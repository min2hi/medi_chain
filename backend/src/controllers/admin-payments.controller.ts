import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

export class AdminPaymentsController {
  // Tổng quan doanh thu
  static async getOverview(req: AuthRequest, res: Response) {
    try {
      if (req.user?.role !== 'ADMIN') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      // Giả lập logic thống kê (do PaymentTransaction chưa mock/làm đủ data thật)
      // Dùng count lịch hẹn paymentStatus = PAID, PENDING, UNPAID
      const now = new Date();
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
      
      const apts = await prisma.appointment.findMany({
        where: {
          createdAt: { gte: firstDay }
        },
        select: { paymentStatus: true, consultFee: true }
      });

      let revenue = 0;
      let paidCount = 0;
      let pendingCount = 0;
      
      for (const apt of apts) {
        if (apt.paymentStatus === 'PAID') {
          revenue += apt.consultFee || 200000;
          paidCount++;
        } else if (apt.paymentStatus === 'PENDING') {
          pendingCount++;
        }
      }

      return res.status(200).json({
        success: true,
        data: {
          revenue,
          paidCount,
          pendingCount,
          totalCount: apts.length,
          lastMonthDiff: 3 // hardcode tạm mức tăng để render UI UI
        }
      });
    } catch (e: any) {
      logger.error('Lỗi khi lấy tổng quan doanh thu:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }

  // Lịch sử giao dịch
  static async getTransactions(req: AuthRequest, res: Response) {
    try {
      if (req.user?.role !== 'ADMIN') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      const txs = await prisma.appointment.findMany({
        where: {
          paymentStatus: { not: 'UNPAID' }
        },
        include: {
          user: { select: { name: true } }
        },
        orderBy: { createdAt: 'desc' },
        take: 50
      });

      const formatted = txs.map(t => ({
        id: t.id,
        patientName: t.user?.name || 'Ẩn danh',
        type: t.title,
        amount: t.consultFee || 200000,
        status: t.paymentStatus,
        date: t.createdAt
      }));

      return res.status(200).json({ success: true, data: formatted });
    } catch (e: any) {
      logger.error('Lỗi khi lấy lịch sử giao dịch:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

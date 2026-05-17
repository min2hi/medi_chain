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

      const now = new Date();
      const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      // Đọc phí khám từ ClinicSetting (fallback 200000)
      const feeSetting = await prisma.clinicSetting.findUnique({ where: { key: 'consultationFee' } });
      const consultationFee = feeSetting ? parseInt(feeSetting.value, 10) : 200000;

      // Thống kê tháng này
      const apts = await prisma.appointment.findMany({
        where: { createdAt: { gte: firstDayOfMonth } },
        select: { paymentStatus: true, consultFee: true, createdAt: true }
      });

      let revenue = 0;
      let paidCount = 0;
      let pendingCount = 0;
      let todayCount = 0;

      for (const apt of apts) {
        if (apt.paymentStatus === 'PAID') {
          revenue += apt.consultFee || consultationFee;
          paidCount++;
        } else if (apt.paymentStatus === 'PENDING') {
          pendingCount++;
        }
        if (apt.createdAt >= startOfToday) {
          todayCount++;
        }
      }

      // Tháng trước — tính diff
      const firstDayLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const lastMonthApts = await prisma.appointment.count({
        where: { createdAt: { gte: firstDayLastMonth, lt: firstDayOfMonth } }
      });
      const lastMonthDiff = apts.length - lastMonthApts;

      return res.status(200).json({
        success: true,
        data: {
          revenue,
          paidCount,
          pendingCount,
          todayCount,
          totalCount: apts.length,
          lastMonthDiff,
          consultationFee,
          feeUpdatedAt: feeSetting?.updatedAt ?? null,
        }
      });
    } catch (e: any) {
      logger.error('Lỗi khi lấy tổng quan doanh thu:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }

  // Cập nhật phí khám
  static async updateFee(req: AuthRequest, res: Response) {
    try {
      if (req.user?.role !== 'ADMIN') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }
      const { fee } = req.body;
      if (!fee || isNaN(Number(fee)) || Number(fee) < 0) {
        return res.status(400).json({ success: false, message: 'Phí khám không hợp lệ' });
      }
      const setting = await prisma.clinicSetting.upsert({
        where: { key: 'consultationFee' },
        update: { value: String(fee) },
        create: { key: 'consultationFee', value: String(fee) },
      });
      return res.status(200).json({ success: true, data: setting });
    } catch (e: any) {
      logger.error('Lỗi khi cập nhật phí khám:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }

  // Lịch sử giao dịch
  static async getTransactions(req: AuthRequest, res: Response) {
    try {
      if (req.user?.role !== 'ADMIN') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      const feeSetting = await prisma.clinicSetting.findUnique({ where: { key: 'consultationFee' } });
      const defaultFee = feeSetting ? parseInt(feeSetting.value, 10) : 200000;

      const txs = await prisma.appointment.findMany({
        where: { paymentStatus: { not: 'UNPAID' } },
        include: { user: { select: { name: true } } },
        orderBy: { createdAt: 'desc' },
        take: 50
      });

      const formatted = txs.map(t => ({
        id: t.id,
        patientName: t.user?.name || 'Ẩn danh',
        type: t.title,
        amount: t.consultFee || defaultFee,
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

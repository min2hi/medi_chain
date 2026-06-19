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

      const { range } = req.query;
      const now = new Date();
      let startDate: Date | undefined;

      if (range === 'TODAY') {
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      } else if (range === '7DAYS') {
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      } else if (range === 'MONTH') {
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      } else if (range === 'ALL') {
        startDate = undefined; // No filter by date
      } else {
        startDate = new Date(now.getFullYear(), now.getMonth(), 1); // Default to current month
      }

      const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      // Đọc phí khám từ ClinicSetting (fallback 200000)
      const feeSetting = await prisma.clinicSetting.findUnique({ where: { key: 'consultationFee' } });
      const consultationFee = feeSetting ? parseInt(feeSetting.value, 10) : 200000;

      const whereClause: any = {
        status: { not: 'CANCELLED' }
      };
      if (startDate) {
        whereClause.createdAt = { gte: startDate };
      }

      // Thống kê theo khoảng thời gian — loại trừ lịch hẹn đã hủy
      const apts = await prisma.appointment.findMany({
        where: whereClause,
        select: { paymentStatus: true, consultFee: true, createdAt: true }
      });

      let revenue = 0;
      let pendingRevenue = 0;
      let paidCount = 0;
      let pendingCount = 0;
      let todayCount = 0;

      for (const apt of apts) {
        if (apt.paymentStatus === 'PAID') {
          revenue += apt.consultFee || consultationFee;
          paidCount++;
        } else if (apt.paymentStatus === 'PENDING' || apt.paymentStatus === 'UNPAID') {
          pendingCount++;
          pendingRevenue += apt.consultFee || consultationFee;
        }
        if (apt.createdAt >= startOfToday) {
          todayCount++;
        }
      }

      // So sánh với tháng trước (chỉ tính khi xem mốc tháng)
      let lastMonthDiff = 0;
      if (range === 'MONTH' || !range) {
        const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const firstDayLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const lastMonthApts = await prisma.appointment.count({
          where: { createdAt: { gte: firstDayLastMonth, lt: firstDayOfMonth } }
        });
        lastMonthDiff = apts.length - lastMonthApts;
      }

      return res.status(200).json({
        success: true,
        data: {
          revenue,
          pendingRevenue,
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

      // Giao dịch: chỉ những appointment đã có tương tác thanh toán,
      // loại trừ CANCELLED (đã void) và UNPAID thuần túy
      const txs = await prisma.appointment.findMany({
        where: {
          paymentStatus: { notIn: ['UNPAID'] },
          status: { not: 'CANCELLED' },
        },
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

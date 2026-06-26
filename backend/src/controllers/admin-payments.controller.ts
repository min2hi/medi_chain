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

      // Tính ngày hiện tại theo timezone Asia/Ho_Chi_Minh
      const formatter = new Intl.DateTimeFormat('en-US', {
        timeZone: 'Asia/Ho_Chi_Minh',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      });
      const parts = formatter.formatToParts(now);
      const year = parts.find(p => p.type === 'year')?.value || String(now.getFullYear());
      const month = parts.find(p => p.type === 'month')?.value || String(now.getMonth() + 1).padStart(2, '0');
      const day = parts.find(p => p.type === 'day')?.value || String(now.getDate()).padStart(2, '0');

      const startOfToday = new Date(`${year}-${month}-${day}T00:00:00+07:00`);
      let startDate: Date | undefined;

      if (range === 'TODAY') {
        startDate = startOfToday;
      } else if (range === '7DAYS') {
        startDate = new Date(startOfToday.getTime() - 6 * 24 * 60 * 60 * 1000); // 7 ngày bao gồm cả hôm nay
      } else if (range === 'MONTH') {
        startDate = new Date(`${year}-${month}-01T00:00:00+07:00`);
      } else if (range === 'ALL') {
        startDate = undefined; // Không lọc theo ngày
      } else {
        startDate = new Date(`${year}-${month}-01T00:00:00+07:00`); // Mặc định là tháng hiện tại
      }

      // Đọc phí khám từ ClinicSetting
      const feeSetting = await prisma.clinicSetting.findUnique({ where: { key: 'consultationFee' } });
      const consultationFee = feeSetting ? parseInt(feeSetting.value, 10) : 150000;

      const whereClause: any = {};
      if (startDate) {
        whereClause.createdAt = { gte: startDate };
      }

      // Lấy danh sách lịch hẹn
      const apts = await prisma.appointment.findMany({
        where: whereClause,
        select: { status: true, paymentStatus: true, consultFee: true, createdAt: true }
      });

      let revenue = 0;
      let pendingRevenue = 0;
      let paidCount = 0;
      let pendingCount = 0;
      let todayCount = 0;
      let totalCount = 0;

      for (const apt of apts) {
        // Loại bỏ các lịch hẹn rác bị hủy do hết hạn thanh toán khỏi thống kê
        if (apt.status === 'CANCELLED' && apt.paymentStatus !== 'PAID') {
          continue;
        }

        const fullFee = apt.consultFee || consultationFee;
        const depositAmount = Math.round(fullFee * 0.5);
        totalCount++;

        if (apt.paymentStatus === 'PAID') {
          revenue += depositAmount;
          paidCount++;
          // Chỉ thu nốt 50% tại quầy nếu ca khám chưa bị hủy
          if (apt.status !== 'CANCELLED') {
            pendingRevenue += (fullFee - depositAmount);
          }
        } else if (apt.paymentStatus === 'PENDING' || apt.paymentStatus === 'UNPAID') {
          pendingCount++;
          pendingRevenue += depositAmount; // Cọc dự thu online
        }

        if (apt.createdAt >= startOfToday) {
          todayCount++;
        }
      }

      // So sánh với tháng trước (chỉ tính khi xem mốc tháng)
      let lastMonthDiff = 0;
      if (range === 'MONTH' || !range) {
        const firstDayOfMonth = new Date(`${year}-${month}-01T00:00:00+07:00`);
        
        const currentMonthVal = parseInt(month, 10);
        const lastMonthVal = currentMonthVal === 1 ? 12 : currentMonthVal - 1;
        const lastMonthYearVal = currentMonthVal === 1 ? parseInt(year, 10) - 1 : parseInt(year, 10);
        const lastMonthStr = String(lastMonthVal).padStart(2, '0');
        const lastMonthYearStr = String(lastMonthYearVal);
        
        const firstDayLastMonth = new Date(`${lastMonthYearStr}-${lastMonthStr}-01T00:00:00+07:00`);

        const lastMonthAptsCount = await prisma.appointment.count({
          where: {
            createdAt: { gte: firstDayLastMonth, lt: firstDayOfMonth },
            NOT: {
              status: 'CANCELLED',
              paymentStatus: { not: 'PAID' }
            }
          }
        });
        lastMonthDiff = totalCount - lastMonthAptsCount;
      }

      return res.status(200).json({
        success: true,
        data: {
          revenue,
          pendingRevenue,
          paidCount,
          pendingCount,
          todayCount,
          totalCount,
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

      // Giao dịch: lấy các lịch hẹn đã từng phát sinh giao dịch thanh toán
      // (bao gồm cả các lịch hẹn bị CANCELLED để hiển thị lịch sử hủy)
      const txs = await prisma.appointment.findMany({
        where: {
          paymentStatus: { notIn: ['UNPAID'] },
        },
        include: { user: { select: { name: true } } },
        orderBy: { createdAt: 'desc' },
        take: 50
      });

      const formatted = txs.map(t => {
        // Nếu lịch hẹn bị hủy mà chưa thanh toán thành công, hiển thị trạng thái giao dịch là FAILED
        let displayStatus = t.paymentStatus;
        if (t.status === 'CANCELLED' && t.paymentStatus !== 'PAID') {
          displayStatus = 'FAILED';
        }

        return {
          id: t.id,
          patientName: t.user?.name || 'Ẩn danh',
          type: t.title,
          amount: t.consultFee || defaultFee,
          status: displayStatus,
          date: t.createdAt
        };
      });

      return res.status(200).json({ success: true, data: formatted });
    } catch (e: any) {
      logger.error('Lỗi khi lấy lịch sử giao dịch:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

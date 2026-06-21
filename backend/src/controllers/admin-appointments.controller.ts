import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';
import jwt from 'jsonwebtoken';

export class AdminAppointmentsController {

  // ─── GET /admin/appointments ──────────────────────────────────────────────
  static async getAppointments(req: AuthRequest, res: Response) {
    try {
      const { status } = req.query;
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }
      const whereClause: any = {};
      if (status && status !== 'ALL') whereClause.status = status;
      if (req.user?.role === 'DOCTOR') {
        whereClause.doctorId = req.user.id;
      }

      const feeSetting = await prisma.clinicSetting.findUnique({ where: { key: 'consultationFee' } });
      const consultationFee = feeSetting ? parseInt(feeSetting.value, 10) : 200000;

      const appointments = await prisma.appointment.findMany({
        where: whereClause,
        include: {
          user: { select: { id: true, name: true, profile: { select: { phone: true } } } },
        },
        orderBy: { date: 'desc' },
      });

      const mapped = appointments.map((apt) => ({
        ...apt,
        consultFee: apt.consultFee ?? consultationFee,
      }));

      return res.status(200).json({ success: true, data: mapped });
    } catch (e: any) {
      logger.error('Lỗi khi lấy lịch hẹn phòng khám:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }


  // ─── PATCH /admin/appointments/:id/status ────────────────────────────────
  // CONFIRM → gán doctorId nếu DOCTOR, notify bệnh nhân
  // CANCEL  → void payment (PENDING/UNPAID → FAILED), notify bệnh nhân
  static async updateStatus(req: AuthRequest, res: Response) {
    try {
      const id = String(req.params.id);
      const { status } = req.body;
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }
      if (status !== 'CONFIRMED' && status !== 'CANCELLED') {
        return res.status(400).json({
          success: false,
          message: 'Status không hợp lệ. Chỉ chấp nhận: CONFIRMED, CANCELLED',
        });
      }

      const apt = await prisma.appointment.findUnique({ where: { id } });
      if (!apt) {
        return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
      }

      // 1. Idempotency Check: Tránh gửi thông báo lặp khi nhấn xác nhận/hủy nhiều lần
      if (apt.status === status) {
        return res.status(200).json({ success: true, data: apt });
      }

      // 2. State Machine Transition Guards
      if (apt.status === 'COMPLETED') {
        return res.status(400).json({ success: false, message: 'Lịch hẹn đã hoàn thành khám, không thể thay đổi trạng thái.' });
      }
      if (apt.status === 'CANCELLED') {
        return res.status(400).json({ success: false, message: 'Lịch hẹn đã bị hủy trước đó, không thể thay đổi trạng thái.' });
      }
      if (status === 'CONFIRMED' && apt.status !== 'PENDING') {
        return res.status(400).json({ success: false, message: 'Chỉ có thể xác nhận các lịch hẹn đang ở trạng thái PENDING.' });
      }

      // Kiểm tra an toàn: Bác sĩ chỉ được thao tác lịch của mình hoặc lịch chưa gán ai
      if (req.user?.role === 'DOCTOR' && apt.doctorId && apt.doctorId !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Bạn không có quyền thao tác trên lịch hẹn của bác sĩ khác' });
      }

      const updateData: any = { status };

      // Chỉ tự gán doctorId nếu người xác nhận là DOCTOR.
      // Nếu ADMIN (lễ tân) confirm → doctorId giữ null,
      // để bác sĩ thực sự tự nhận ca từ danh sách đã xác nhận.
      if (status === 'CONFIRMED' && req.user?.role === 'DOCTOR') {
        updateData.doctorId = req.user!.id;
      }

      // Khi HỦY: void payment nếu chưa thanh toán.
      // PAID → giữ nguyên (admin xử lý hoàn tiền thủ công nếu cần).
      if (status === 'CANCELLED') {
        if (apt.paymentStatus !== 'PAID') {
          updateData.paymentStatus = 'FAILED'; // void — không phải lỗi thanh toán
        }
      }

      const updated = await prisma.appointment.update({
        where: { id },
        data: updateData,
        include: { user: { select: { name: true } } },
      });

      const dateFormatted = new Date(updated.date).toLocaleDateString('vi-VN', {
        day: '2-digit', month: '2-digit', year: 'numeric',
        hour: '2-digit', minute: '2-digit',
      });

      const notificationsToCreate: any[] = [];

      // 1. Notify bệnh nhân (APPOINTMENT)
      notificationsToCreate.push({
        userId: updated.userId,
        title: status === 'CONFIRMED' ? 'Lịch hẹn được xác nhận' : 'Lịch hẹn bị hủy',
        message: status === 'CONFIRMED'
          ? 'Lịch hẹn của bạn đã được xác nhận. Vui lòng đến đúng giờ.'
          : 'Lịch hẹn của bạn đã bị hủy. Liên hệ phòng khám nếu cần đặt lại.',
        type: 'APPOINTMENT',
      });

      // 2. Notify Bác sĩ được gán (APPOINTMENT)
      if (updated.doctorId) {
        notificationsToCreate.push({
          userId: updated.doctorId,
          title: status === 'CONFIRMED' ? 'Lịch hẹn được xác nhận' : 'Lịch hẹn bị hủy',
          message: status === 'CONFIRMED'
            ? `Lịch hẹn của bệnh nhân ${updated.user.name} vào ${dateFormatted} đã được xác nhận.`
            : `Lịch hẹn của bệnh nhân ${updated.user.name} vào ${dateFormatted} đã bị hủy.`,
          type: 'APPOINTMENT',
        });
      }

      // 3. Notify tất cả Admin (SYSTEM) để ghi nhật ký hệ thống
      const admins = await prisma.user.findMany({
        where: { role: 'ADMIN' },
        select: { id: true },
      });
      for (const admin of admins) {
        notificationsToCreate.push({
          userId: admin.id,
          title: status === 'CONFIRMED' ? 'Xác nhận lịch hẹn' : 'Hủy lịch hẹn',
          message: `Lịch hẹn của bệnh nhân ${updated.user.name} vào lúc ${dateFormatted} đã được ${status === 'CONFIRMED' ? 'xác nhận' : 'hủy'}.`,
          type: 'SYSTEM',
        });
      }

      await prisma.notification.createMany({
        data: notificationsToCreate,
      });

      return res.status(200).json({ success: true, data: updated });
    } catch (e: any) {
      logger.error('Lỗi cập nhật trạng thái lịch hẹn:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }


  // ─── PATCH /admin/appointments/:id/complete ───────────────────────────────
  // Bác sĩ hoàn thành khám: lưu ghi chú lâm sàng (doctorNotes), notify bệnh nhân
  static async completeAppointment(req: AuthRequest, res: Response) {
    try {
      const id = String(req.params.id);
      const { doctorNotes, medications } = req.body;

      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      const apt = await prisma.appointment.findUnique({
        where: { id },
        include: { user: { select: { name: true } } },
      });
      if (!apt) {
        return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
      }

      // Kiểm tra an toàn: Bác sĩ chỉ được hoàn thành lịch của mình
      if (req.user?.role === 'DOCTOR' && apt.doctorId && apt.doctorId !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Bạn không có quyền hoàn thành lịch hẹn của bác sĩ khác' });
      }

      if (apt.status === 'COMPLETED') {
        return res.status(200).json({ success: true, data: apt });
      }

      if (apt.status !== 'CONFIRMED' && (apt.status as string) !== 'CHECKED_IN') {
        return res.status(400).json({
          success: false,
          message: 'Chỉ có thể hoàn thành lịch hẹn đã được xác nhận hoặc đã check-in',
        });
      }

      const updated = await (prisma.appointment as any).update({
        where: { id },
        data: {
          status: 'COMPLETED',
          doctorNotes: doctorNotes?.trim() || null,
          completedAt: new Date(),
          // Chỉ ghi đè doctorId khi hoàn thành nếu người làm là DOCTOR
          // (ADMIN hoàn thành thay không được claim là bác sĩ điều trị)
          ...(req.user?.role === 'DOCTOR' ? { doctorId: req.user!.id } : {}),
        },
      });

      // Sync medications directly to the patient's medicine cabinet
      if (Array.isArray(medications) && medications.length > 0) {
        const medicinesToCreate = medications
          .filter((m: any) => m && m.name && m.name.trim().length > 0)
          .map((m: any) => {
            const startDate = new Date();
            let endDate = null;
            const days = parseInt(m.days, 10);
            if (!isNaN(days) && days > 0) {
              endDate = new Date(startDate.getTime() + days * 24 * 60 * 60 * 1000);
            }
            return {
              userId: apt.userId,
              name: m.name.trim(),
              dosage: m.dosage ? m.dosage.trim() : null,
              frequency: m.frequency ? m.frequency.trim() : null,
              startDate,
              endDate,
            };
          });

        if (medicinesToCreate.length > 0) {
          await prisma.medicine.createMany({
            data: medicinesToCreate,
          });
        }
      }

      const notificationsToCreate: any[] = [];

      // 1. Notify bệnh nhân (APPOINTMENT)
      notificationsToCreate.push({
        userId: apt.userId,
        title: 'Kết quả khám đã có',
        message: doctorNotes?.trim()
          ? 'Bác sĩ đã để lại ghi chú sau buổi khám. Mở ứng dụng để xem.'
          : 'Bác sĩ đã hoàn thành buổi khám của bạn.',
        type: 'APPOINTMENT',
      });

      // 2. Notify Admin (SYSTEM) để lưu nhật ký hệ thống
      const admins = await prisma.user.findMany({
        where: { role: 'ADMIN' },
        select: { id: true },
      });
      const completedBy = req.user?.role === 'DOCTOR' ? 'Bác sĩ' : 'Admin';
      for (const admin of admins) {
        notificationsToCreate.push({
          userId: admin.id,
          title: 'Hoàn thành ca khám',
          message: `${completedBy} đã hoàn thành buổi khám cho bệnh nhân ${apt.user?.name ?? 'bệnh nhân'}.`,
          type: 'SYSTEM',
        });
      }

      await prisma.notification.createMany({
        data: notificationsToCreate,
      });

      logger.info(`Appointment ${id} completed by doctor ${req.user!.id}`);
      return res.status(200).json({ success: true, data: updated });
    } catch (e: any) {
      logger.error('Lỗi hoàn thành lịch hẹn:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }

  // ─── POST /admin/appointments/checkin ────────────────────────────────────
  // Staff (ADMIN/DOCTOR) scan QR bệnh nhân → xác nhận bệnh nhân đã đến.
  // Body: { appointmentId, type, exp }  (payload được parse từ QR JSON)
  //
  // Luồng: CONFIRMED → CHECKED_IN
  // Sau khi khám xong: CHECKED_IN → COMPLETED  (route complete hiện có)
  static async checkIn(req: AuthRequest, res: Response) {
    try {
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      const { appointmentId, type, exp, token } = req.body;
      let targetId = appointmentId;

      if (token) {
        try {
          const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret') as any;
          if (decoded.type !== 'medichain_checkin' || !decoded.appointmentId) {
            return res.status(400).json({
              success: false,
              errorCode: 'INVALID_QR',
              message: 'Token QR không hợp lệ',
            });
          }
          targetId = decoded.appointmentId;
        } catch (err: any) {
          const isExpired = err.name === 'TokenExpiredError';
          return res.status(400).json({
            success: false,
            errorCode: isExpired ? 'QR_EXPIRED' : 'INVALID_QR',
            message: isExpired 
              ? 'Mã QR đã hết hạn. Bệnh nhân cần mở lại ứng dụng để lấy mã mới.' 
              : 'Mã QR không hợp lệ hoặc chữ ký số sai.',
          });
        }
      } else {
        // Fallback for backward compatibility
        if (type !== 'medichain_checkin' || !appointmentId) {
          return res.status(400).json({
            success: false,
            errorCode: 'INVALID_QR',
            message: 'Mã QR không hợp lệ hoặc không phải mã MediChain',
          });
        }

        if (exp) {
          const now = Math.floor(Date.now() / 1000);
          if (now > exp) {
            return res.status(400).json({
              success: false,
              errorCode: 'QR_EXPIRED',
              message: 'Mã QR đã hết hạn. Bệnh nhân cần mở lại ứng dụng để lấy mã mới.',
            });
          }
        }
      }

      // 3. Tìm appointment
      const apt = await prisma.appointment.findUnique({
        where: { id: targetId },
        include: {
          user: { select: { id: true, name: true, profile: { select: { phone: true } } } },
        },
      });

      if (!apt) {
        return res.status(404).json({
          success: false,
          errorCode: 'NOT_FOUND',
          message: 'Không tìm thấy lịch hẹn này trong hệ thống',
        });
      }

      // Kiểm tra an toàn: Bác sĩ chỉ được check-in lịch của mình
      if (req.user?.role === 'DOCTOR' && apt.doctorId && apt.doctorId !== req.user.id) {
        return res.status(403).json({
          success: false,
          errorCode: 'FORBIDDEN',
          message: 'Bạn không có quyền check-in lịch hẹn của bác sĩ khác',
        });
      }

      // 4. Chỉ check-in được khi CONFIRMED
      // Dùng string comparison vì CHECKED_IN chưa có trong Prisma enum AppStatus
      // (sẽ cập nhật schema trong sprint tiếp theo — xem ADR)
      const checkedInStr = 'CHECKED_IN';
      if ((apt.status as string) === checkedInStr) {
        return res.status(409).json({
          success: false,
          errorCode: 'ALREADY_CHECKED_IN',
          message: 'Bệnh nhân đã check-in trước đó',
          data: apt,
        });
      }

      if (apt.status !== 'CONFIRMED') {
        return res.status(400).json({
          success: false,
          errorCode: 'WRONG_STATUS',
          message: `Không thể check-in. Lịch hẹn đang ở trạng thái: ${apt.status}`,
        });
      }

      // 5. Cập nhật → CHECKED_IN
      const updated = await (prisma.appointment as any).update({
        where: { id: targetId },
        data: {
          status: 'CHECKED_IN',
          // Ghi nhận staff thực hiện check-in nếu là DOCTOR
          ...(req.user?.role === 'DOCTOR' ? { doctorId: req.user!.id } : {}),
        },
        include: {
          user: { select: { id: true, name: true, profile: { select: { phone: true } } } },
        },
      });

      const notificationsToCreate: any[] = [];

      // 1. Notify bệnh nhân (APPOINTMENT)
      notificationsToCreate.push({
        userId: updated.userId,
        title: 'Check-in thành công',
        message: 'Bạn đã check-in thành công. Vui lòng ngồi chờ, bác sĩ sẽ gọi bạn.',
        type: 'APPOINTMENT',
      });

      // 2. Notify Bác sĩ được gán (APPOINTMENT)
      if (updated.doctorId) {
        notificationsToCreate.push({
          userId: updated.doctorId,
          title: 'Bệnh nhân đã check-in',
          message: `Bệnh nhân ${updated.user.name} đã check-in thành công cho lịch hẹn của bạn.`,
          type: 'APPOINTMENT',
        });
      }

      // 3. Notify tất cả Admin (SYSTEM) để lưu nhật ký hệ thống
      const admins = await prisma.user.findMany({
        where: { role: 'ADMIN' },
        select: { id: true },
      });
      for (const admin of admins) {
        notificationsToCreate.push({
          userId: admin.id,
          title: 'Bệnh nhân check-in',
          message: `Bệnh nhân ${updated.user.name} đã check-in thành công tại phòng khám.`,
          type: 'SYSTEM',
        });
      }

      await prisma.notification.createMany({
        data: notificationsToCreate,
      });

      logger.info(`Check-in: appointment ${appointmentId} by staff ${req.user!.id}`);

      let warning: string | null = null;
      if (updated.paymentStatus !== 'PAID') {
        warning = 'Bệnh nhân chưa đặt cọc online. Vui lòng nhắc bệnh nhân hoàn tất thanh toán qua ứng dụng trước khi bắt đầu khám.';
      }

      return res.status(200).json({ success: true, data: updated, warning });
    } catch (e: any) {
      logger.error('Lỗi check-in lịch hẹn:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

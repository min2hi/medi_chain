import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

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

      const appointments = await prisma.appointment.findMany({
        where: whereClause,
        include: {
          user: { select: { id: true, name: true, profile: { select: { phone: true } } } },
        },
        orderBy: { date: 'desc' },
      });
      return res.status(200).json({ success: true, data: appointments });
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
        const current = await prisma.appointment.findUnique({
          where: { id },
          select: { paymentStatus: true },
        });
        if (current && current.paymentStatus !== 'PAID') {
          updateData.paymentStatus = 'FAILED'; // void — không phải lỗi thanh toán
        }
      }

      const updated = await prisma.appointment.update({ where: { id }, data: updateData });

      // Notify bệnh nhân — targetRole: USER để admin portal không thấy
      await prisma.notification.create({
        data: {
          userId: updated.userId,
          title: status === 'CONFIRMED' ? '✅ Lịch hẹn được xác nhận' : '❌ Lịch hẹn bị hủy',
          message: status === 'CONFIRMED'
            ? 'Lịch hẹn của bạn đã được xác nhận. Vui lòng đến đúng giờ.'
            : 'Lịch hẹn của bạn đã bị hủy. Liên hệ phòng khám nếu cần đặt lại.',
          type: 'APPOINTMENT',
        } as any,
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
      const { doctorNotes } = req.body;

      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'DOCTOR') {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }

      const apt = await prisma.appointment.findUnique({ where: { id } });
      if (!apt) {
        return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
      }
      if (apt.status !== 'CONFIRMED') {
        return res.status(400).json({
          success: false,
          message: 'Chỉ có thể hoàn thành lịch hẹn đã được xác nhận',
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

      // Notify bệnh nhân: kết quả khám đã có
      await prisma.notification.create({
        data: {
          userId: apt.userId,
          title: '🩺 Kết quả khám đã có',
          message: doctorNotes?.trim()
            ? 'Bác sĩ đã để lại ghi chú sau buổi khám. Mở ứng dụng để xem.'
            : 'Bác sĩ đã hoàn thành buổi khám của bạn.',
          type: 'APPOINTMENT',
        },
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

      const { appointmentId, type, exp } = req.body;

      // 1. Validate QR payload structure
      if (type !== 'medichain_checkin' || !appointmentId) {
        return res.status(400).json({
          success: false,
          errorCode: 'INVALID_QR',
          message: 'Mã QR không hợp lệ hoặc không phải mã MediChain',
        });
      }

      // 2. Validate expiry — QR chỉ valid trong ngày khám (exp = end-of-day Unix timestamp)
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

      // 3. Tìm appointment
      const apt = await prisma.appointment.findUnique({
        where: { id: appointmentId },
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
        where: { id: appointmentId },
        data: {
          status: 'CHECKED_IN',
          // Ghi nhận staff thực hiện check-in nếu là DOCTOR
          ...(req.user?.role === 'DOCTOR' ? { doctorId: req.user!.id } : {}),
        },
        include: {
          user: { select: { id: true, name: true, profile: { select: { phone: true } } } },
        },
      });

      // 6. Notify bệnh nhân
      await prisma.notification.create({
        data: {
          userId: apt.userId,
          title: '✅ Check-in thành công',
          message: 'Bạn đã check-in thành công. Vui lòng ngồi chờ, bác sĩ sẽ gọi bạn.',
          type: 'APPOINTMENT',
        },
      });

      logger.info(`Check-in: appointment ${appointmentId} by staff ${req.user!.id}`);
      return res.status(200).json({ success: true, data: updated });
    } catch (e: any) {
      logger.error('Lỗi check-in lịch hẹn:', e);
      return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
  }
}

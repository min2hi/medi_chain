import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { MedicalService } from '../services/medical.service.js';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

export class UserController {
    static async getDashboard(req: AuthRequest, res: Response) {
        try {
            const targetId = req.viewAs || req.user.id;

            // Lấy thông tin user mới nhất từ DB thay vì chỉ dùng dữ liệu từ Token
            const [user, stats] = await Promise.all([
                prisma.user.findUnique({
                    where: { id: targetId },
                    select: { id: true, name: true, email: true, role: true }
                }),
                MedicalService.getStats(targetId)
            ]);

            return res.status(200).json({
                success: true,
                data: {
                    user: user || req.user,
                    stats: stats
                }
            });
        } catch (error: any) {
            logger.error({ err: error, userId: req.user?.id }, 'getDashboard failed');
            return res.status(500).json({
                success: false,
                message: 'Lỗi khi tải dữ liệu dashboard',
            });
        }
    }

    /**
     * PATCH /api/user/doctor-profile
     * Bác sĩ tự cập nhật chứng chỉ hành nghề.
     * licenseVerified KHÔNG được cập nhật ở đây — chỉ Admin verify.
     */
    static async updateDoctorProfile(req: AuthRequest, res: Response) {
        // Chỉ DOCTOR mới được cập nhật thông tin chứng chỉ
        // USER bình thường KHÔNG được tự nhập licenseNumber
        if (req.user.role !== 'DOCTOR') {
            return res.status(403).json({
                success:   false,
                message:   'Chỉ tài khoản bác sĩ mới có thể cập nhật thông tin chứng chỉ',
                errorCode: 'FORBIDDEN_ROLE',
            });
        }
        try {
            const userId = req.user.id;
            const { licenseNumber, specialty, clinicAddress } = req.body as {
                licenseNumber?: string;
                specialty?: string;
                clinicAddress?: string;
            };
            const profile = await MedicalService.updateDoctorProfile(userId, {
                licenseNumber, specialty, clinicAddress,
            });
            return res.json({
                success: true,
                data: profile,
                message: 'Cập nhật thông tin bác sĩ thành công',
            });
        } catch {
            return res.status(500).json({ success: false, message: 'Lỗi khi cập nhật thông tin bác sĩ' });
        }
    }

    /**
     * GET /api/user/doctors
     * Lấy danh sách toàn bộ bác sĩ trong hệ thống kèm profile của họ.
     */
    static async getDoctors(req: AuthRequest, res: Response) {
        try {
            const doctors = await prisma.user.findMany({
                where: { 
                    role: 'DOCTOR',
                    profile: {
                        licenseVerified: true
                    }
                },
                select: {
                    id: true,
                    name: true,
                    email: true,
                    image: true,
                    profile: {
                        select: {
                            specialty: true,
                            clinicAddress: true,
                            licenseVerified: true,
                        }
                    }
                }
            });
            return res.status(200).json({
                success: true,
                data: doctors,
            });
        } catch (error: any) {
            logger.error({ err: error }, 'getDoctors failed');
            return res.status(500).json({
                success: false,
                message: 'Lỗi khi tải danh sách bác sĩ',
            });
        }
    }

    static async getDoctorSlots(req: AuthRequest, res: Response) {
        if (req.user.role !== 'DOCTOR') {
            return res.status(403).json({ success: false, message: 'Forbidden' });
        }
        try {
            const profile = await prisma.profile.findUnique({
                where: { userId: req.user.id }
            });
            if (!profile || !profile.licenseVerified) {
                return res.status(403).json({
                    success: false,
                    message: 'Tài khoản bác sĩ của bạn chưa được xác nhận chứng chỉ hành nghề. Không thể lấy lịch rảnh.',
                    errorCode: 'LICENSE_NOT_VERIFIED'
                });
            }
            const slots = await prisma.doctorAvailability.findMany({
                where: { doctorId: req.user.id as string },
                orderBy: { startTime: 'asc' },
            });
            return res.status(200).json({ success: true, data: slots });
        } catch (error: any) {
            logger.error({ err: error }, 'getDoctorSlots failed');
            return res.status(500).json({ success: false, message: 'Lỗi khi tải lịch làm việc' });
        }
    }

    /**
     * POST /api/user/doctor/slots
     * Bác sĩ đăng ký lịch rảnh (đăng ký slot).
     * Body: { startTime: string, endTime: string }
     */
    static async createDoctorSlot(req: AuthRequest, res: Response) {
        if (req.user.role !== 'DOCTOR') {
            return res.status(403).json({ success: false, message: 'Forbidden' });
        }
        try {
            const profile = await prisma.profile.findUnique({
                where: { userId: req.user.id }
            });
            if (!profile || !profile.licenseVerified) {
                return res.status(403).json({
                    success: false,
                    message: 'Tài khoản bác sĩ của bạn chưa được xác nhận chứng chỉ hành nghề. Không thể đăng ký lịch rảnh.',
                    errorCode: 'LICENSE_NOT_VERIFIED'
                });
            }
            const { startTime, endTime } = req.body;
            if (!startTime || !endTime) {
                return res.status(400).json({ success: false, message: 'Thiếu thông tin thời gian bắt đầu hoặc kết thúc' });
            }

            const start = new Date(startTime);
            const end = new Date(endTime);

            if (isNaN(start.getTime()) || isNaN(end.getTime())) {
                return res.status(400).json({ success: false, message: 'Định dạng thời gian không hợp lệ' });
            }

            if (start >= end) {
                return res.status(400).json({ success: false, message: 'Thời gian bắt đầu phải trước thời gian kết thúc' });
            }

            if (start < new Date()) {
                return res.status(400).json({ success: false, message: 'Không thể đăng ký lịch trực trong quá khứ' });
            }

            // Check xem slot này có trùng lặp với lịch trực đã có không
            const overlap = await prisma.doctorAvailability.findFirst({
                where: {
                    doctorId: req.user.id as string,
                    startTime: { lt: end },
                    endTime: { gt: start },
                }
            });

            if (overlap) {
                const overlapStart = new Date(overlap.startTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Asia/Ho_Chi_Minh' });
                const overlapEnd = new Date(overlap.endTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Asia/Ho_Chi_Minh' });
                return res.status(400).json({
                    success: false,
                    message: `Khung giờ này trùng lặp với lịch trực đã có: ${overlapStart} - ${overlapEnd}`,
                });
            }

            const slot = await prisma.doctorAvailability.create({
                data: {
                    doctorId: req.user.id as string,
                    startTime: start,
                    endTime: end,
                    isAvailable: true,
                }
            });

            return res.status(201).json({ success: true, data: slot });
        } catch (error: any) {
            logger.error({ err: error }, 'createDoctorSlot failed');
            return res.status(500).json({ success: false, message: 'Lỗi khi đăng ký lịch rảnh' });
        }
    }

    /**
     * DELETE /api/user/doctor/slots/:id
     * Bác sĩ xóa slot rảnh của mình.
     */
    static async deleteDoctorSlot(req: AuthRequest, res: Response) {
        if (req.user.role !== 'DOCTOR') {
            return res.status(403).json({ success: false, message: 'Forbidden' });
        }
        try {
            const slotId = req.params.id as string;
            const slot = await prisma.doctorAvailability.findFirst({
                where: { id: slotId, doctorId: req.user.id as string }
            });

            if (!slot) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy khung giờ này' });
            }

            // Kiểm tra xem đã có lịch hẹn nào trùng giờ này mà chưa bị hủy chưa
            const appointment = await prisma.appointment.findFirst({
                where: {
                    doctorId: req.user.id as string,
                    date: slot.startTime,
                    status: { not: 'CANCELLED' }
                }
            });

            if (appointment) {
                return res.status(400).json({
                    success: false,
                    message: 'Khung giờ này đã được bệnh nhân đặt lịch hẹn. Vui lòng hủy cuộc hẹn trước khi xóa khung giờ này.'
                });
            }

            await prisma.doctorAvailability.delete({ where: { id: slotId } });
            return res.status(200).json({ success: true, message: 'Đã xóa khung giờ làm việc' });
        } catch (error: any) {
            logger.error({ err: error }, 'deleteDoctorSlot failed');
            return res.status(500).json({ success: false, message: 'Lỗi khi xóa lịch rảnh' });
        }
    }

    /**
     * GET /api/user/doctors/:doctorId/slots
     * Bệnh nhân lấy danh sách slot rảnh của bác sĩ để đặt lịch theo ngày.
     */
    static async getAvailableDoctorSlots(req: AuthRequest, res: Response) {
        try {
            const doctorId = req.params.doctorId as string;
            const { date } = req.query as { date?: string }; // YYYY-MM-DD

            if (!date) {
                return res.status(400).json({ success: false, message: 'Thiếu tham số ngày (date)' });
            }

            // Phép tính ngày giờ chính xác theo múi giờ Asia/Ho_Chi_Minh (+07:00)
            const startOfDay = new Date(`${date}T00:00:00.000+07:00`);
            if (isNaN(startOfDay.getTime())) {
                return res.status(400).json({ success: false, message: 'Định dạng ngày không hợp lệ' });
            }
            const endOfDay = new Date(`${date}T23:59:59.999+07:00`);

            // 1. Lấy tất cả slot rảnh của bác sĩ trong ngày đó
            const slots = await prisma.doctorAvailability.findMany({
                where: {
                    doctorId,
                    isAvailable: true,
                    startTime: {
                        gte: startOfDay,
                        lt: endOfDay,
                    }
                },
                orderBy: { startTime: 'asc' },
            });

            // 2. Lấy các lịch hẹn đã đặt trong ngày đó
            const bookedAppointments = await prisma.appointment.findMany({
                where: {
                    doctorId,
                    status: { not: 'CANCELLED' },
                    date: {
                        gte: startOfDay,
                        lt: endOfDay,
                    }
                },
                select: { date: true }
            });

            const bookedTimes = bookedAppointments.map(a => a.date.getTime());

            // 3. Lọc bỏ các slot đã bị đặt lịch
            const availableSlots = slots.filter(slot => {
                return !bookedTimes.includes(slot.startTime.getTime());
            });

            return res.status(200).json({ success: true, data: availableSlots });
        } catch (error: any) {
            logger.error({ err: error }, 'getAvailableDoctorSlots failed');
            return res.status(500).json({ success: false, message: 'Lỗi khi tải danh sách khung giờ trống' });
        }
    }
}

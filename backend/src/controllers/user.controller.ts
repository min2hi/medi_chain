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
}

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { MedicalService } from '../services/medical.service.js';
import prisma from '../config/prisma.js';

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
            return res.status(500).json({
                success: false,
                message: 'Lỗi khi tải dữ liệu dashboard',
            });
        }
    }
}

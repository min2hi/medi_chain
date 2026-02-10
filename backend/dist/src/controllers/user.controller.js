import { MedicalService } from '../services/medical.service.js';
export class UserController {
    static async getDashboard(req, res) {
        try {
            const userId = req.user.id;
            const stats = await MedicalService.getStats(userId);
            return res.status(200).json({
                success: true,
                data: {
                    user: req.user,
                    stats: stats
                }
            });
        }
        catch (error) {
            return res.status(500).json({
                success: false,
                message: 'Lỗi khi tải dữ liệu dashboard',
            });
        }
    }
}
//# sourceMappingURL=user.controller.js.map
/**
 * Health Twin Controller — Bóng Sức Khỏe
 * ============================================================
 * Xử lý HTTP request cho các API endpoint của Health Twin.
 * Controller chỉ làm nhiệm vụ nhận request, gọi service, trả response.
 * Mọi business logic nằm hoàn toàn trong HealthTwinService.
 * ============================================================
 */

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
import { HealthTwinService } from '../services/health-twin.service.js';

export class HealthTwinController {

    /**
     * GET /api/health-twin/status
     * Trả về trạng thái sức khỏe tổng quan + isStable + anomalies gần nhất.
     */
    static async getStatus(req: AuthRequest, res: Response) {
        try {
            const userId = req.user.id;
            const status = await HealthTwinService.getStatus(userId);

            res.json({
                success: true,
                data: status,
            });
        } catch (error: any) {
            console.error('[HealthTwinController.getStatus]', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi khi lấy trạng thái sức khỏe',
            });
        }
    }

    /**
     * GET /api/health-twin/timeline
     * Trả về lịch sử sự kiện sức khỏe được nhóm theo tháng.
     */
    static async getTimeline(req: AuthRequest, res: Response) {
        try {
            const userId  = req.user.id;
            const timeline = await HealthTwinService.getTimeline(userId);

            res.json({
                success: true,
                data:    timeline,
            });
        } catch (error: any) {
            console.error('[HealthTwinController.getTimeline]', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi khi lấy timeline sức khỏe',
            });
        }
    }

    /**
     * GET /api/health-twin/anomalies
     * Trả về danh sách 10 anomaly gần nhất của user.
     */
    static async getAnomalies(req: AuthRequest, res: Response) {
        try {
            const userId   = req.user.id;
            const anomalies = await HealthTwinService.getAnomalies(userId);

            res.json({
                success: true,
                data:    anomalies,
            });
        } catch (error: any) {
            console.error('[HealthTwinController.getAnomalies]', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi khi lấy danh sách bất thường',
            });
        }
    }

    /**
     * POST /api/health-twin/checkin
     * Ghi nhận check-in hàng tuần.
     * Body: { feeling: 'good' | 'normal' | 'tired' | 'bad' }
     */
    static async weeklyCheckin(req: AuthRequest, res: Response) {
        try {
            const userId  = req.user.id;
            const { feeling } = req.body;

            // Validate feeling input
            const validFeelings = ['good', 'normal', 'tired', 'bad'];
            if (!feeling || !validFeelings.includes(feeling)) {
                return res.status(400).json({
                    success:   false,
                    message:   `"feeling" phải là một trong: ${validFeelings.join(', ')}`,
                    errorCode: 'INVALID_FEELING',
                });
            }

            await HealthTwinService.submitWeeklyCheckin(userId, feeling);

            res.json({
                success: true,
                message: 'Check-in hàng tuần đã được ghi nhận thành công!',
            });
        } catch (error: any) {
            console.error('[HealthTwinController.weeklyCheckin]', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi khi ghi nhận check-in',
            });
        }
    }

    /**
     * POST /api/health-twin/anomalies/:id/dismiss
     * User đã xem và dismiss một anomaly.
     */
    static async dismissAnomaly(req: AuthRequest, res: Response) {
        try {
            const userId = req.user.id;
            const id = String(req.params.id);

            await HealthTwinService.dismissAnomaly(userId, id);

            res.json({ success: true, message: 'Đã đánh dấu đã xem' });
        } catch (error: any) {
            console.error('[HealthTwinController.dismissAnomaly]', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi khi dismiss anomaly',
            });
        }
    }
}

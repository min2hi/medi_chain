import { Response } from 'express';
import { SharingService } from '../services/sharing.service.js';
import { AuthRequest } from '../middlewares/auth.middleware.js';

/**
 * SharingController: Chịu trách nhiệm HTTP Interface.
 */
export class SharingController {
    private static service = new SharingService();

    /**
     * [POST] /api/sharing
     */
    static async shareRecord(req: AuthRequest, res: Response) {
        console.log(`[SharingController.shareRecord] Request received from user: ${req.user?.id}`);
        try {
            const currentUserId = req.user?.id;
            if (!currentUserId || typeof currentUserId !== 'string') {
                return res.status(401).json({ success: false, message: "Unauthorized: User ID missing" });
            }

            const { email, type, expiresAt } = req.body;

            if (!email) {
                return res.status(400).json({ success: false, message: "Email là bắt buộc." });
            }

            console.log(`[SharingController.shareRecord] Creating share for ${email} with type ${type}`);
            const result = await SharingController.service.createSharing(currentUserId, { email, type, expiresAt });

            console.log(`[SharingController.shareRecord] Share created successfully: ${result.id}`);
            return res.status(201).json({
                success: true,
                message: "Chia sẻ thành công",
                data: result
            });
        } catch (error: any) {
            console.error('[SharingController.shareRecord] Error:', error.message);
            return res.status(error.message.includes('không tồn tại') ? 404 : 400).json({
                success: false,
                message: error.message
            });
        }
    }

    /**
     * [GET] /api/sharing/me
     */
    static async getMySharings(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId || typeof userId !== 'string') {
                return res.status(401).json({ success: false, message: "Unauthorized" });
            }

            const data = await SharingController.service.getSharingsInitiatedByMe(userId);
            return res.json({ success: true, data });
        } catch (error: any) {
            console.error('[SharingController.getMySharings] Error:', error.message);
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    /**
     * [GET] /api/sharing/shared-with-me
     */
    static async getSharedWithMe(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId || typeof userId !== 'string') {
                return res.status(401).json({ success: false, message: "Unauthorized" });
            }

            const data = await SharingController.service.getSharingsSharedWithMe(userId);
            return res.json({ success: true, data });
        } catch (error: any) {
            console.error('[SharingController.getSharedWithMe] Error:', error.message);
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    /**
     * [DELETE] /api/sharing/:id
     */
    static async deleteSharing(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            // Ép kiểu tường minh để tránh lỗi linting string | string[]
            const sharingId = String(req.params.id);

            if (!userId || typeof userId !== 'string') {
                return res.status(401).json({ success: false, message: "Unauthorized" });
            }

            if (!sharingId) {
                return res.status(400).json({ success: false, message: "ID chia sẻ không hợp lệ." });
            }

            console.log(`[SharingController.deleteSharing] Revoking share ${sharingId} by user ${userId}`);
            await SharingController.service.revokeSharing(sharingId, userId);

            return res.json({ success: true, message: "Đã thu hồi quyền truy cập." });
        } catch (error: any) {
            console.error('[SharingController.deleteSharing] Error:', error.message);
            return res.status(400).json({ success: false, message: error.message });
        }
    }
}

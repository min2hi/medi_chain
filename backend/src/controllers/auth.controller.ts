import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service.js';

// Augment Request type to include user from JWT middleware
interface AuthRequest extends Request {
    user?: { id: string; email: string; role: string };
}

export class AuthController {
    static async register(req: Request, res: Response) {
        try {
            const user = await AuthService.register(req.body);
            return res.status(201).json({
                success: true,
                message: 'Đăng ký thành công',
                data: user,
            });
        } catch (error: any) {
            return res.status(400).json({
                success: false,
                message: error.message || 'Lỗi đăng ký',
            });
        }
    }

    static async login(req: Request, res: Response) {
        try {
            const result = await AuthService.login(req.body);
            return res.status(200).json({
                success: true,
                message: 'Đăng nhập thành công',
                data: result,
            });
        } catch (error: any) {
            return res.status(400).json({
                success: false,
                message: error.message || 'Lỗi đăng nhập',
            });
        }
    }

    static async forgotPassword(req: Request, res: Response) {
        try {
            const { email } = req.body;
            await AuthService.forgotPassword(email);
            return res.status(200).json({
                success: true,
                message: 'Nếu email tồn tại trong hệ thống, chúng tôi đã gửi link đặt lại mật khẩu.',
            });
        } catch (error: any) {
            return res.status(400).json({
                success: false,
                message: error.message || 'Lỗi gửi email',
            });
        }
    }

    static async resetPassword(req: Request, res: Response) {
        try {
            const { token, newPassword } = req.body;
            await AuthService.resetPassword(token, newPassword);
            return res.status(200).json({
                success: true,
                message: 'Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập lại.',
            });
        } catch (error: any) {
            return res.status(400).json({
                success: false,
                message: error.message || 'Lỗi đặt lại mật khẩu',
            });
        }
    }

    // ──────────────────────────────────────────────────────
    // SETTINGS ENDPOINTS
    // ──────────────────────────────────────────────────────

    static async changePassword(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });
            const { currentPassword, newPassword } = req.body;
            await AuthService.changePassword(userId, currentPassword, newPassword);
            return res.status(200).json({
                success: true,
                message: 'Đổi mật khẩu thành công',
            });
        } catch (error: any) {
            return res.status(400).json({
                success: false,
                message: error.message || 'Lỗi đổi mật khẩu',
            });
        }
    }

    static async getPreferences(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });
            const prefs = await AuthService.getPreferences(userId);
            return res.status(200).json({ success: true, data: prefs });
        } catch (error: any) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async updatePreferences(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });
            const updated = await AuthService.updatePreferences(userId, req.body);
            return res.status(200).json({ success: true, data: updated });
        } catch (error: any) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async getSessions(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });
            const sessions = await AuthService.getSessions(req);
            return res.status(200).json({ success: true, data: sessions });
        } catch (error: any) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async revokeSession(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });
            const id = req.params.id as string;
            await AuthService.revokeSession(userId, id);
            return res.status(200).json({ success: true, message: 'Session revoked' });
        } catch (error: any) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async revealRecoveryKey(req: AuthRequest, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });
            const { password } = req.body;
            const recoveryKey = await AuthService.revealRecoveryKey(userId, password);
            return res.status(200).json({ success: true, data: { recoveryKey } });
        } catch (error: any) {
            return res.status(400).json({ success: false, message: error.message });
        }
    }
}

import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service.js';

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
}

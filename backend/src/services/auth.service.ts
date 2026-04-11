import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import prisma from '../config/prisma.js';
import { EmailService } from './email.service.js';

export class AuthService {
    static async register(data: { email: string; password: string; name?: string }) {
        const { email, password, name } = data;

        if (!email || !password) {
            throw new Error('Email và mật khẩu là bắt buộc');
        }

        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            throw new Error('Email đã được sử dụng');
        }

        const hashedPassword = await bcrypt.hash(password, 12);

        const user = await prisma.user.create({
            data: {
                email,
                password: hashedPassword,
                name,
                profile: {
                    create: {}
                }
            },
            select: {
                id: true,
                email: true,
                name: true,
                role: true,
            },
        });

        return user;
    }

    static async login(data: { email: string; password: string }) {
        const { email, password } = data;

        if (!email || !password) {
            throw new Error('Email và mật khẩu là bắt buộc');
        }

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user || !user.password) {
            throw new Error('Email hoặc mật khẩu không chính xác');
        }

        const isPasswordCorrect = await bcrypt.compare(password, user.password);
        if (!isPasswordCorrect) {
            throw new Error('Email hoặc mật khẩu không chính xác');
        }

        const jwtSecret = process.env.JWT_SECRET!; // Được đảm bảo bởi index.ts check khi khởi động
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            jwtSecret,
            { expiresIn: (process.env.JWT_EXPIRES_IN || '7d') as jwt.SignOptions['expiresIn'] }
        );

        return {
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
            },
            token,
        };
    }

    // ──────────────────────────────────────────────────────
    // FORGOT PASSWORD
    // ──────────────────────────────────────────────────────

    static async forgotPassword(email: string): Promise<void> {
        if (!email) throw new Error('Email là bắt buộc');

        const user = await prisma.user.findUnique({ where: { email } });

        // Luôn trả về success dù email có tồn tại hay không (security: không leaking)
        if (!user) return;

        // Vô hiệu hoá các token cũ chưa dùng của user này
        await prisma.passwordResetToken.updateMany({
            where: { userId: user.id, used: false },
            data: { used: true },
        });

        // Tạo token mới — 32 bytes hex = 64 chars
        const rawToken = crypto.randomBytes(32).toString('hex');
        const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 giờ

        await prisma.passwordResetToken.create({
            data: {
                token: rawToken,
                userId: user.id,
                expiresAt,
            },
        });

        // Link deep link mở app:  medichain://reset-password?token=...
        // Hoặc dùng web link nếu user trên browser
        const appLink = `medichain://reset-password?token=${rawToken}`;
        const webFallback = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${rawToken}`;

        await EmailService.sendPasswordResetEmail(email, webFallback, appLink, user.name ?? undefined);
    }

    // ──────────────────────────────────────────────────────
    // RESET PASSWORD
    // ──────────────────────────────────────────────────────

    static async resetPassword(token: string, newPassword: string): Promise<void> {
        if (!token || !newPassword) {
            throw new Error('Token và mật khẩu mới là bắt buộc');
        }

        if (newPassword.length < 6) {
            throw new Error('Mật khẩu phải từ 6 ký tự trở lên');
        }

        const resetToken = await prisma.passwordResetToken.findUnique({
            where: { token },
            include: { user: true },
        });

        if (!resetToken) {
            throw new Error('Link đặt lại mật khẩu không hợp lệ');
        }

        if (resetToken.used) {
            throw new Error('Link đặt lại mật khẩu đã được sử dụng');
        }

        if (new Date() > resetToken.expiresAt) {
            throw new Error('Link đặt lại mật khẩu đã hết hạn. Vui lòng yêu cầu lại.');
        }

        // Hash mật khẩu mới
        const hashedPassword = await bcrypt.hash(newPassword, 12);

        // Update user password + đánh dấu token đã dùng (atomic transaction)
        await prisma.$transaction([
            prisma.user.update({
                where: { id: resetToken.userId },
                data: { password: hashedPassword },
            }),
            prisma.passwordResetToken.update({
                where: { id: resetToken.id },
                data: { used: true },
            }),
        ]);
    }
}

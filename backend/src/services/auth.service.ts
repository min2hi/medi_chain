import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../config/prisma.js';

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

        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'secret',
            { expiresIn: (process.env.JWT_EXPIRES_IN as any) || '7d' }
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
}

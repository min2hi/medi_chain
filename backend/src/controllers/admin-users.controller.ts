/**
 * Admin: User Management Controller
 * ─────────────────────────────────────────────────────────────────────────────
 * Cho phép ADMIN xem và cập nhật role của tất cả users trong hệ thống.
 * Pattern tham khảo từ Athenahealth "Practice Management" + Epic "User Admin".
 */

import { Request, Response } from 'express';
import { UserRole } from '../generated/client/index.js';
import prisma from '../config/prisma.js';

/**
 * GET /api/admin/users
 * Trả về danh sách toàn bộ users — không expose password.
 */
export const listUsers = async (req: Request, res: Response): Promise<void> => {
    try {
        const { role, search, page = '1', limit = '20' } = req.query;

        const pageNum  = Math.max(1, parseInt(page as string, 10));
        const limitNum = Math.min(100, parseInt(limit as string, 10));
        const skip     = (pageNum - 1) * limitNum;

        // Validate role filter against Prisma enum
        const roleFilter = role && Object.values(UserRole).includes(role as UserRole)
            ? role as UserRole
            : undefined;

        const searchStr = typeof search === 'string' ? search : undefined;

        const where = {
            ...(roleFilter ? { role: roleFilter } : {}),
            ...(searchStr  ? { OR: [
                { name:  { contains: searchStr, mode: 'insensitive' as const } },
                { email: { contains: searchStr, mode: 'insensitive' as const } },
            ]} : {}),
        };

        const [users, total] = await Promise.all([
            prisma.user.findMany({
                where,
                skip,
                take: limitNum,
                orderBy: { createdAt: 'desc' },
                select: {
                    id:        true,
                    name:      true,
                    email:     true,
                    role:      true,
                    createdAt: true,
                    // Doctor credential fields
                    profile: {
                        select: {
                            licenseNumber:   true,
                            specialty:       true,
                            licenseVerified: true,
                        },
                    },
                },
            }),
            prisma.user.count({ where }),
        ]);

        res.json({
            success: true,
            data: {
                users,
                pagination: {
                    page:       pageNum,
                    limit:      limitNum,
                    total,
                    totalPages: Math.ceil(total / limitNum),
                },
            },
        });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Lỗi khi lấy danh sách người dùng' });
    }
};

/**
 * PATCH /api/admin/users/:id/role
 * Cập nhật role của user. Chỉ cho phép USER ↔ DOCTOR.
 */
export const updateUserRole = async (req: Request, res: Response): Promise<void> => {
    try {
        const id   = String(req.params['id']);
        const body = req.body as { role?: string };

        // Only USER and DOCTOR are assignable (never ADMIN)
        const ASSIGNABLE: UserRole[] = [UserRole.USER, UserRole.DOCTOR];
        const newRole = body.role as UserRole;

        if (!ASSIGNABLE.includes(newRole)) {
            res.status(400).json({
                success:   false,
                message:   'Role không hợp lệ. Chỉ chấp nhận: USER, DOCTOR',
                errorCode: 'INVALID_ROLE',
            });
            return;
        }

        const target = await prisma.user.findUnique({
            where:  { id },
            select: { id: true, email: true, role: true },
        });

        if (!target) {
            res.status(404).json({ success: false, message: 'Người dùng không tồn tại' });
            return;
        }

        if (target.role === UserRole.ADMIN) {
            res.status(403).json({
                success:   false,
                message:   'Không thể thay đổi role của tài khoản ADMIN',
                errorCode: 'CANNOT_MODIFY_ADMIN',
            });
            return;
        }

        const updated = await prisma.user.update({
            where:  { id },
            data:   { role: newRole },
            select: { id: true, name: true, email: true, role: true },
        });

        res.json({
            success: true,
            data:    updated,
            message: `Đã cập nhật role thành ${newRole} cho ${updated.email}`,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Lỗi khi cập nhật role người dùng' });
    }
};

/**
 * PATCH /api/admin/users/:id/verify-license
 * Admin xác nhận chứng chỉ hành nghề bác sĩ.
 * Toggle: nếu đang verified → unverify, nếu chưa → verify.
 */
export const verifyDoctorLicense = async (req: Request, res: Response): Promise<void> => {
    try {
        const id = String(req.params['id']);

        const user = await prisma.user.findUnique({
            where:  { id },
            select: { id: true, role: true, profile: { select: { licenseVerified: true } } },
        });

        if (!user) {
            res.status(404).json({ success: false, message: 'Người dùng không tồn tại' });
            return;
        }
        if (user.role !== UserRole.DOCTOR) {
            res.status(400).json({ success: false, message: 'Chỉ DOCTOR mới có chứng chỉ hành nghề' });
            return;
        }

        const currentVerified = user.profile?.licenseVerified ?? false;
        const profile = await prisma.profile.upsert({
            where:  { userId: id },
            create: { userId: id, licenseVerified: !currentVerified },
            update: { licenseVerified: !currentVerified },
            select: { licenseVerified: true, licenseNumber: true, specialty: true },
        });

        // Tạo thông báo cho bác sĩ
        if (profile.licenseVerified) {
            await prisma.notification.create({
                data: {
                    userId: id,
                    title: 'Xác thực chứng chỉ thành công',
                    message: 'Chúc mừng! Chứng chỉ hành nghề y tế của bạn đã được Quản trị viên phê duyệt thành công. Bạn hiện đã có thể đăng ký lịch rảnh và nhận lịch hẹn khám từ bệnh nhân.',
                    type: 'SYSTEM',
                }
            }).catch(err => {
                console.error('Failed to create notification for verified doctor:', err);
            });
        }

        res.json({
            success: true,
            data:    profile,
            message: profile.licenseVerified ? 'Chứng chỉ đã được xác nhận' : 'Hủy xác nhận chứng chỉ',
        });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Lỗi khi cập nhật trạng thái xác nhận' });
    }
};

import prisma from '../config/prisma.js';

/**
 * SharingService: Xử lý logic nghiệp vụ liên quan đến chia sẻ hồ sơ.
 */
export class SharingService {
    /**
     * Tạo một yêu cầu chia sẻ mới.
     */
    async createSharing(fromUserId: string, data: { email: string; type: string; expiresAt?: string }) {
        const { email, type, expiresAt } = data;

        // 1. Tìm toUser dựa trên email
        const toUser = await prisma.user.findUnique({
            where: { email }
        });

        if (!toUser) {
            throw new Error("Người dùng không tồn tại trong hệ thống.");
        }

        // 2. Kiểm tra nếu chia sẻ cho chính mình
        if (toUser.id === fromUserId) {
            throw new Error("Bạn không thể chia sẻ hồ sơ với chính mình.");
        }

        // 3. Kiểm tra đã tồn tại chia sẻ chưa
        const existingSharing = await prisma.sharing.findFirst({
            where: {
                fromUserId,
                toUserId: toUser.id,
            }
        });

        if (existingSharing) {
            throw new Error("Bạn đã chia sẻ hồ sơ với người này rồi.");
        }

        // 4. Validate thời gian hết hạn
        let expirationDate = null;
        if (expiresAt) {
            expirationDate = new Date(expiresAt);
            if (isNaN(expirationDate.getTime())) {
                throw new Error("Định dạng ngày hết hạn không hợp lệ.");
            }
            if (expirationDate <= new Date()) {
                throw new Error("Ngày hết hạn phải ở tương lai.");
            }
        }

        // 5. Tạo record
        return await prisma.sharing.create({
            data: {
                fromUserId,
                toUserId: toUser.id,
                type: type || "VIEW",
                expiresAt: expirationDate
            },
            include: {
                toUser: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        image: true
                    }
                }
            }
        });
    }

    /**
     * Lấy danh sách những người mình đang chia sẻ hồ sơ cho họ.
     */
    async getSharingsInitiatedByMe(userId: string) {
        return await prisma.sharing.findMany({
            where: { fromUserId: userId },
            include: {
                toUser: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        image: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
    }

    /**
     * Thu hồi quyền chia sẻ.
     */
    async revokeSharing(sharingId: string, ownerId: string) {
        const sharing = await prisma.sharing.findUnique({
            where: { id: sharingId }
        });

        if (!sharing) {
            throw new Error("Bản ghi chia sẻ không tồn tại.");
        }

        if (sharing.fromUserId !== ownerId) {
            throw new Error("Bạn không có quyền thu hồi chia sẻ này.");
        }

        return await prisma.sharing.delete({
            where: { id: sharingId }
        });
    }

    /**
     * Lấy danh sách những người đang chia sẻ hồ sơ cho mình.
     */
    async getSharingsSharedWithMe(userId: string) {
        return await prisma.sharing.findMany({
            where: {
                toUserId: userId,
                OR: [
                    { expiresAt: null },
                    { expiresAt: { gt: new Date() } }
                ]
            },
            include: {
                fromUser: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        image: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
    }

    /**
     * Logic mở rộng: Kiểm tra xem A có quyền xem hồ sơ của B không?
     */
    async canAccess(requesterId: string, targetUserId: string) {
        if (requesterId === targetUserId) return true;

        const sharing = await prisma.sharing.findFirst({
            where: {
                fromUserId: targetUserId,
                toUserId: requesterId,
                OR: [
                    { expiresAt: null },
                    { expiresAt: { gt: new Date() } }
                ]
            }
        });

        return !!sharing;
    }
}

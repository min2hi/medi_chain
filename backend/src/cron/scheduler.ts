/**
 * ============================================================
 * CronJob Scheduler - MediChain Backend
 * ============================================================
 *
 * Đây là "Bộ điều khiển hẹn giờ" (Job Scheduler) của hệ thống.
 * Sử dụng thư viện `node-cron` để lập lịch chạy các tác vụ nặng
 * vào ban đêm (khi server rảnh rỗi), tránh làm lag trải nghiệm
 * người dùng ban ngày.
 *
 * Các job được đăng ký ở đây:
 *  1. CF Matrix Rebuild    (2:00 AM hàng ngày)
 *     → Gom toàn bộ Feedback → Tính điểm Weighted → Cache vào DB
 *
 *  2. Drug ETL Pipeline    (3:00 AM hàng ngày)
 *     → Kéo thuốc mới từ OpenFDA → Normalize → Embed → Upsert vào DB
 */

import cron from 'node-cron';
import { buildCollaborativeMatrix } from './cf-matrix-builder.js';
import { runDrugETL } from './drug-etl.js';
import { HealthTwinService } from '../services/health-twin.service.js';
import prisma from '../config/prisma.js';

/**
 * Hàm khởi động toàn bộ các CronJob.
 * Được gọi 1 lần duy nhất khi Server khởi động (từ src/index.ts).
 */
export function startScheduler() {
    console.log('⏰ [Scheduler] Khởi động Job Scheduler...');

    // ─────────────────────────────────────────────────────────────
    // JOB 0: Health Twin Baseline Update — Bóng Sức Khỏe
    // Cron Expression: "0 1 * * *" — 1:00 AM mỗi ngày
    // Cập nhật baseline cá nhân cho mọi user có dữ liệu sức khỏe
    // ─────────────────────────────────────────────────────────────
    cron.schedule('0 1 * * *', async () => {
        const now = new Date().toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
        console.log(`\n🧠 [HealthTwin-Job] Bắt đầu lúc ${now} (1:00 AM tự động)...`);
        try {
            // Lấy danh sách user có ít nhất 1 log sức khỏe
            const usersWithLogs = await prisma.healthLog.findMany({
                distinct:  ['userId'],
                select:    { userId: true },
            });
            let updated = 0;
            for (const { userId } of usersWithLogs) {
                await HealthTwinService.updateBaseline(userId);
                updated++;
            }
            console.log(`✅ [HealthTwin-Job] Hoàn thành. Đã cập nhật ${updated} baseline.`);
        } catch (err: any) {
            console.error('❌ [HealthTwin-Job] Lỗi không mong muốn:', err.message);
        }
    }, {
        timezone: 'Asia/Ho_Chi_Minh',
    });

    console.log('✅ [Scheduler] Đã đăng ký Health Twin Baseline Job (Every day 1:00 AM ICT)');

    // ─────────────────────────────────────────────────────────────
    // JOB 1: Collaborative Filtering Matrix Rebuild
    // Cron Expression: "0 2 * * *"
    //   0       → Phút 0
    //   2       → Giờ 2 (2:00 AM)
    //   * * *   → Mọi ngày, mọi tháng, mọi thứ trong tuần
    // ─────────────────────────────────────────────────────────────
    cron.schedule('0 2 * * *', async () => {
        const now = new Date().toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
        console.log(`\n🔄 [CF-Job] Bắt đầu lúc ${now} (2:00 AM tự động)...`);

        try {
            await buildCollaborativeMatrix();
            console.log('✅ [CF-Job] Hoàn thành. CF Score đã được cập nhật vào DB.');
        } catch (err: any) {
            // Lỗi trong job KHÔNG được crash Server — chỉ log lại để debug
            console.error('❌ [CF-Job] Lỗi không mong muốn:', err.message);
        }
    }, {
        timezone: 'Asia/Ho_Chi_Minh',
    });

    console.log('✅ [Scheduler] Đã đăng ký CF Matrix Job (Every day 2:00 AM ICT)');

    // ─────────────────────────────────────────────────────────────
    // JOB 2: Drug ETL Pipeline (OpenFDA)
    // Cron Expression: "0 3 * * *"
    //   Chạy sau CF Job 1 tiếng → tránh tranh tài nguyên DB
    //   Crawl thuốc mới nhất từ FDA → generate embedding → upsert
    // ─────────────────────────────────────────────────────────────
    cron.schedule('0 3 * * *', async () => {
        const now = new Date().toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
        console.log(`\n🌐 [ETL-Job] Bắt đầu lúc ${now} (3:00 AM tự động)...`);

        try {
            await runDrugETL();
            console.log('✅ [ETL-Job] Hoàn thành. Drug database đã được cập nhật.');
        } catch (err: any) {
            console.error('❌ [ETL-Job] Lỗi không mong muốn:', err.message);
        }
    }, {
        timezone: 'Asia/Ho_Chi_Minh',
    });

    console.log('✅ [Scheduler] Đã đăng ký Drug ETL Job (Every day 3:00 AM ICT)');

    // ─────────────────────────────────────────────────────────────
    // JOB 3: Clean up expired PENDING appointments (every 10 minutes)
    // Hủy các lịch hẹn PENDING mà sau 15 phút chưa thanh toán cọc
    // để giải phóng khung giờ khám cho bệnh nhân khác.
    // ─────────────────────────────────────────────────────────────
    cron.schedule('*/10 * * * *', async () => {
        const now = new Date();
        const fifteenMinutesAgo = new Date(now.getTime() - 15 * 60 * 1000);

        try {
            // Bước 1: Tìm TẤT CẢ các lịch hẹn sắp bị hủy TRƯỚC khi update
            // (updateMany không trả về các records bị ảnh hưởng)
            const expiredAppointments = await prisma.appointment.findMany({
                where: {
                    status: 'PENDING',
                    createdAt: { lte: fifteenMinutesAgo },
                },
                select: {
                    id: true,
                    userId: true,
                    doctorId: true,
                    title: true,
                    date: true,
                },
            });

            if (expiredAppointments.length === 0) return;

            // Bước 2: Hủy tất cả (Lịch hẹn + Giao dịch liên quan) atomically
            await prisma.$transaction([
                prisma.appointment.updateMany({
                    where: {
                        id: { in: expiredAppointments.map(a => a.id) },
                        status: 'PENDING', // Double-guard: chỉ hủy nếu vẫn còn PENDING
                    },
                    data: {
                        status: 'CANCELLED',
                        paymentStatus: 'FAILED',
                    },
                }),
                prisma.paymentTransaction.updateMany({
                    where: {
                        appointmentId: { in: expiredAppointments.map(a => a.id) },
                        status: 'PENDING',
                    },
                    data: {
                        status: 'FAILED',
                    },
                }),
            ]);

            // Bước 3: Gửi notification cho từng lịch hẹn bị hủy
            const notificationData: any[] = [];
            for (const apt of expiredAppointments) {
                const dateFormatted = new Date(apt.date).toLocaleDateString('vi-VN', {
                    day: '2-digit', month: '2-digit', year: 'numeric',
                    hour: '2-digit', minute: '2-digit',
                });

                // Thông báo bệnh nhân: slot đã được giải phóng, đặt lại nếu muốn
                notificationData.push({
                    userId: apt.userId,
                    title: 'Lịch hẹn đã bị hủy tự động',
                    message: `Lịch hẹn "${apt.title}" vào ${dateFormatted} đã bị hủy vì chưa hoàn tất đặt cọc trong 15 phút. Bạn có thể đặt lại bất kỳ lúc nào.`,
                    type: 'APPOINTMENT',
                });

                // Thông báo bác sĩ nếu đã được chỉ định
                if (apt.doctorId) {
                    notificationData.push({
                        userId: apt.doctorId,
                        title: 'Lịch hẹn bị hủy tự động',
                        message: `Lịch hẹn "${apt.title}" vào ${dateFormatted} đã bị hủy do bệnh nhân không hoàn tất đặt cọc. Khung giờ này đã được mở lại.`,
                        type: 'APPOINTMENT',
                    });
                }
            }

            if (notificationData.length > 0) {
                await prisma.notification.createMany({ data: notificationData });
            }

            console.log(`🧹 [Cleanup-Job] Đã hủy ${expiredAppointments.length} lịch hẹn PENDING hết hạn và gửi ${notificationData.length} thông báo.`);
        } catch (err: any) {
            console.error('❌ [Cleanup-Job] Lỗi dọn dẹp lịch hẹn hết hạn:', err.message);
        }
    });

    console.log('✅ [Scheduler] Đã đăng ký Cleanup Expired Bookings Job (Every 10 mins)');

    // ─────────────────────────────────────────────────────────────
    // Chạy ngay 1 lần khi server vừa khởi động (Development mode)
    // Đảm bảo có CF Score ngay từ đầu, không phải chờ đến 2am.
    // ─────────────────────────────────────────────────────────────
    if (process.env.NODE_ENV !== 'production') {
        console.log('🧪 [Scheduler] Dev mode: Chạy thử CF Matrix Job ngay bây giờ...');
        void buildCollaborativeMatrix();
    }
}

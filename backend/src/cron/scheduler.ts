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

/**
 * Hàm khởi động toàn bộ các CronJob.
 * Được gọi 1 lần duy nhất khi Server khởi động (từ src/index.ts).
 */
export function startScheduler() {
    console.log('⏰ [Scheduler] Khởi động Job Scheduler...');

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
    // Chạy ngay 1 lần khi server vừa khởi động (Development mode)
    // Đảm bảo có CF Score ngay từ đầu, không phải chờ đến 2am.
    // ─────────────────────────────────────────────────────────────
    if (process.env.NODE_ENV !== 'production') {
        console.log('🧪 [Scheduler] Dev mode: Chạy thử CF Matrix Job ngay bây giờ...');
        void buildCollaborativeMatrix();
    }
}

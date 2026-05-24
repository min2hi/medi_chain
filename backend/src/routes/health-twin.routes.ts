/**
 * Health Twin Routes — Bóng Sức Khỏe
 * ============================================================
 * Đăng ký các API endpoint cho tính năng Health Twin.
 * Tất cả routes đều yêu cầu xác thực (authMiddleware).
 *
 * Endpoints:
 *   GET  /api/health-twin/status      → Trạng thái sức khỏe + isStable
 *   GET  /api/health-twin/timeline    → Lịch sử sự kiện theo tháng
 *   GET  /api/health-twin/anomalies   → Danh sách bất thường gần nhất
 *   POST /api/health-twin/checkin     → Check-in hàng tuần
 * ============================================================
 */

import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { HealthTwinController } from '../controllers/health-twin.controller.js';

const router = Router();

// GET  /api/health-twin/status → Trạng thái sức khỏe tổng quan
router.get('/status', authMiddleware, HealthTwinController.getStatus);

// GET  /api/health-twin/timeline → Timeline sự kiện theo tháng
router.get('/timeline', authMiddleware, HealthTwinController.getTimeline);

// GET  /api/health-twin/anomalies → 10 anomaly gần nhất
router.get('/anomalies', authMiddleware, HealthTwinController.getAnomalies);

// POST /api/health-twin/checkin → Check-in hàng tuần { feeling }
router.post('/checkin', authMiddleware, HealthTwinController.weeklyCheckin);

// POST /api/health-twin/anomalies/:id/dismiss → Đánh dấu anomaly đã xem
router.post('/anomalies/:id/dismiss', authMiddleware, HealthTwinController.dismissAnomaly);

export default router;

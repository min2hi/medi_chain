import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { NotificationController } from '../controllers/notification.controller.js';

const router = Router();
router.use(authMiddleware);

router.get('/', NotificationController.getMyNotifications);
router.patch('/read', NotificationController.markAllRead);

export default router;

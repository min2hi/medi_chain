import { Router } from 'express';
import { SharingController } from '../controllers/sharing.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

const router = Router();

// Tất cả các thao tác chia sẻ cần phải đăng nhập
router.use(authMiddleware);

router.post('/', SharingController.shareRecord);
router.get('/me', SharingController.getMySharings);
router.get('/shared-with-me', SharingController.getSharedWithMe);
router.delete('/:id', SharingController.deleteSharing);

export default router;

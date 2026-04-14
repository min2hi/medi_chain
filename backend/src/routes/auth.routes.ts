import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

const router = Router();

router.post('/register', AuthController.register);
router.post('/login', AuthController.login);
router.post('/forgot-password', AuthController.forgotPassword);
router.post('/reset-password', AuthController.resetPassword);

// Settings — requires auth
router.put('/change-password', authMiddleware, AuthController.changePassword);
router.get('/preferences', authMiddleware, AuthController.getPreferences);
router.put('/preferences', authMiddleware, AuthController.updatePreferences);

export default router;

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

// Sessions & Recovery key
router.get('/sessions', authMiddleware, AuthController.getSessions);
router.delete('/sessions/:id', authMiddleware, AuthController.revokeSession);
router.post('/recovery-key/reveal', authMiddleware, AuthController.revealRecoveryKey);

export default router;

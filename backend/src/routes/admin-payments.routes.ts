import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { AdminPaymentsController } from '../controllers/admin-payments.controller.js';

const router = Router();
router.use(authMiddleware);

router.get('/overview', AdminPaymentsController.getOverview);
router.get('/transactions', AdminPaymentsController.getTransactions);
router.patch('/fee', AdminPaymentsController.updateFee);

export default router;

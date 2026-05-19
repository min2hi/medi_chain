import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { AdminAppointmentsController } from '../controllers/admin-appointments.controller.js';

const router = Router();
router.use(authMiddleware);

router.get('/', AdminAppointmentsController.getAppointments);
router.patch('/:id/status', AdminAppointmentsController.updateStatus);
router.patch('/:id/complete', AdminAppointmentsController.completeAppointment);

export default router;

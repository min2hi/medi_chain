import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { AdminPatientsController } from '../controllers/admin-patients.controller.js';

const router = Router();
router.use(authMiddleware);

router.get('/', AdminPatientsController.getPatients);

export default router;

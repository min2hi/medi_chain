import { Router } from 'express';
import { UserController } from '../controllers/user.controller.js';
import { MedicalController } from '../controllers/medical.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { sharingMiddleware } from '../middlewares/sharing.middleware.js';

const router = Router();

// Dashboard & Profile (Read)
router.get('/dashboard', authMiddleware, sharingMiddleware, UserController.getDashboard);
router.get('/profile', authMiddleware, sharingMiddleware, MedicalController.getProfile);
router.put('/profile', authMiddleware, MedicalController.upsertProfile);

// Hồ sơ bệnh án (Read)
router.get('/records', authMiddleware, sharingMiddleware, MedicalController.getRecords);
router.get('/records/:id', authMiddleware, sharingMiddleware, MedicalController.getRecord);
router.post('/records', authMiddleware, MedicalController.createRecord);
router.put('/records/:id', authMiddleware, MedicalController.updateRecord);
router.delete('/records/:id', authMiddleware, MedicalController.deleteRecord);

// Thuốc (Read)
router.get('/medicines', authMiddleware, sharingMiddleware, MedicalController.getMedicines);
router.get('/medicines/:id', authMiddleware, sharingMiddleware, MedicalController.getMedicine);
router.post('/medicines', authMiddleware, MedicalController.createMedicine);
router.put('/medicines/:id', authMiddleware, MedicalController.updateMedicine);
router.delete('/medicines/:id', authMiddleware, MedicalController.deleteMedicine);

// Lịch hẹn (Read)
router.get('/appointments', authMiddleware, sharingMiddleware, MedicalController.getAppointments);
router.get('/appointments/:id', authMiddleware, sharingMiddleware, MedicalController.getAppointment);
router.post('/appointments', authMiddleware, MedicalController.createAppointment);
router.put('/appointments/:id', authMiddleware, MedicalController.updateAppointment);
router.delete('/appointments/:id', authMiddleware, MedicalController.deleteAppointment);

// Chỉ số (Read)
router.get('/metrics', authMiddleware, sharingMiddleware, MedicalController.getMetrics);
router.post('/metrics', authMiddleware, MedicalController.createMetric);

export default router;

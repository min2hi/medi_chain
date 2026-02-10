import { Router } from 'express';
import { UserController } from '../controllers/user.controller.js';
import { MedicalController } from '../controllers/medical.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

const router = Router();

router.get('/dashboard', authMiddleware, UserController.getDashboard);

// Profile
router.get('/profile', authMiddleware, MedicalController.getProfile);
router.put('/profile', authMiddleware, MedicalController.upsertProfile);

// Hồ sơ bệnh án (Medical records)
router.get('/records', authMiddleware, MedicalController.getRecords);
router.get('/records/:id', authMiddleware, MedicalController.getRecord);
router.post('/records', authMiddleware, MedicalController.createRecord);
router.put('/records/:id', authMiddleware, MedicalController.updateRecord);
router.delete('/records/:id', authMiddleware, MedicalController.deleteRecord);

// Thuốc (Medicines)
router.get('/medicines', authMiddleware, MedicalController.getMedicines);
router.get('/medicines/:id', authMiddleware, MedicalController.getMedicine);
router.post('/medicines', authMiddleware, MedicalController.createMedicine);
router.put('/medicines/:id', authMiddleware, MedicalController.updateMedicine);
router.delete('/medicines/:id', authMiddleware, MedicalController.deleteMedicine);

// Lịch hẹn (Appointments)
router.get('/appointments', authMiddleware, MedicalController.getAppointments);
router.get('/appointments/:id', authMiddleware, MedicalController.getAppointment);
router.post('/appointments', authMiddleware, MedicalController.createAppointment);
router.put('/appointments/:id', authMiddleware, MedicalController.updateAppointment);
router.delete('/appointments/:id', authMiddleware, MedicalController.deleteAppointment);

// Chỉ số (Health metrics)
router.get('/metrics', authMiddleware, MedicalController.getMetrics);
router.post('/metrics', authMiddleware, MedicalController.createMetric);

export default router;

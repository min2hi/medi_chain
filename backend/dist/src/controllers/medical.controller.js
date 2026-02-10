import { MedicalService } from '../services/medical.service.js';
function paramId(req) {
    const id = req.params.id;
    return Array.isArray(id) ? id[0] : id;
}
export class MedicalController {
    static async getProfile(req, res) {
        try {
            const profile = await MedicalService.getProfile(req.user.id);
            return res.status(200).json({ success: true, data: profile });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải hồ sơ' });
        }
    }
    static async upsertProfile(req, res) {
        try {
            const body = req.body || {};
            const profile = await MedicalService.upsertProfile(req.user.id, {
                bloodType: body.bloodType,
                allergies: body.allergies,
                weight: body.weight != null ? Number(body.weight) : undefined,
                height: body.height != null ? Number(body.height) : undefined,
                gender: body.gender,
                birthday: body.birthday ? new Date(body.birthday) : undefined,
                address: body.address,
                phone: body.phone,
            });
            return res.status(200).json({ success: true, data: profile });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi cập nhật hồ sơ' });
        }
    }
    static async getRecords(req, res) {
        try {
            const list = await MedicalService.getRecords(req.user.id);
            return res.status(200).json({ success: true, data: list });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải danh sách hồ sơ' });
        }
    }
    static async getRecord(req, res) {
        try {
            const record = await MedicalService.getRecordById(req.user.id, paramId(req));
            if (!record)
                return res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ' });
            return res.status(200).json({ success: true, data: record });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải hồ sơ' });
        }
    }
    static async createRecord(req, res) {
        try {
            const body = req.body || {};
            if (!body.title)
                return res.status(400).json({ success: false, message: 'Thiếu tiêu đề' });
            const record = await MedicalService.createRecord(req.user.id, {
                title: body.title,
                content: body.content,
                diagnosis: body.diagnosis,
                treatment: body.treatment,
                hospital: body.hospital,
                date: body.date ? new Date(body.date) : undefined,
            });
            return res.status(201).json({ success: true, data: record });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tạo hồ sơ' });
        }
    }
    static async updateRecord(req, res) {
        try {
            const body = req.body || {};
            const record = await MedicalService.updateRecord(req.user.id, paramId(req), {
                title: body.title,
                content: body.content,
                diagnosis: body.diagnosis,
                treatment: body.treatment,
                hospital: body.hospital,
                date: body.date ? new Date(body.date) : undefined,
            });
            return res.status(200).json({ success: true, data: record });
        }
        catch (e) {
            if (e?.code === 'P2025')
                return res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ' });
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi cập nhật hồ sơ' });
        }
    }
    static async deleteRecord(req, res) {
        try {
            await MedicalService.deleteRecord(req.user.id, paramId(req));
            return res.status(200).json({ success: true });
        }
        catch (e) {
            if (e?.code === 'P2025')
                return res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ' });
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi xóa hồ sơ' });
        }
    }
    static async getMedicines(req, res) {
        try {
            const list = await MedicalService.getMedicines(req.user.id);
            return res.status(200).json({ success: true, data: list });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải danh sách thuốc' });
        }
    }
    static async getMedicine(req, res) {
        try {
            const item = await MedicalService.getMedicineById(req.user.id, paramId(req));
            if (!item)
                return res.status(404).json({ success: false, message: 'Không tìm thấy thuốc' });
            return res.status(200).json({ success: true, data: item });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải thuốc' });
        }
    }
    static async createMedicine(req, res) {
        try {
            const body = req.body || {};
            if (!body.name)
                return res.status(400).json({ success: false, message: 'Thiếu tên thuốc' });
            const item = await MedicalService.createMedicine(req.user.id, {
                name: body.name,
                dosage: body.dosage,
                frequency: body.frequency,
                instruction: body.instruction,
                startDate: body.startDate ? new Date(body.startDate) : undefined,
                endDate: body.endDate ? new Date(body.endDate) : undefined,
            });
            return res.status(201).json({ success: true, data: item });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi thêm thuốc' });
        }
    }
    static async updateMedicine(req, res) {
        try {
            const body = req.body || {};
            const item = await MedicalService.updateMedicine(req.user.id, paramId(req), {
                name: body.name,
                dosage: body.dosage,
                frequency: body.frequency,
                instruction: body.instruction,
                startDate: body.startDate ? new Date(body.startDate) : undefined,
                endDate: body.endDate ? new Date(body.endDate) : undefined,
            });
            return res.status(200).json({ success: true, data: item });
        }
        catch (e) {
            if (e?.code === 'P2025')
                return res.status(404).json({ success: false, message: 'Không tìm thấy thuốc' });
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi cập nhật thuốc' });
        }
    }
    static async deleteMedicine(req, res) {
        try {
            await MedicalService.deleteMedicine(req.user.id, paramId(req));
            return res.status(200).json({ success: true });
        }
        catch (e) {
            if (e?.code === 'P2025')
                return res.status(404).json({ success: false, message: 'Không tìm thấy thuốc' });
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi xóa thuốc' });
        }
    }
    static async getAppointments(req, res) {
        try {
            const list = await MedicalService.getAppointments(req.user.id);
            return res.status(200).json({ success: true, data: list });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải lịch hẹn' });
        }
    }
    static async getAppointment(req, res) {
        try {
            const item = await MedicalService.getAppointmentById(req.user.id, paramId(req));
            if (!item)
                return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
            return res.status(200).json({ success: true, data: item });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải lịch hẹn' });
        }
    }
    static async createAppointment(req, res) {
        try {
            const body = req.body || {};
            if (!body.title)
                return res.status(400).json({ success: false, message: 'Thiếu tiêu đề' });
            if (!body.date)
                return res.status(400).json({ success: false, message: 'Thiếu ngày hẹn' });
            const item = await MedicalService.createAppointment(req.user.id, {
                title: body.title,
                date: new Date(body.date),
                notes: body.notes,
            });
            return res.status(201).json({ success: true, data: item });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tạo lịch hẹn' });
        }
    }
    static async updateAppointment(req, res) {
        try {
            const body = req.body || {};
            const item = await MedicalService.updateAppointment(req.user.id, paramId(req), {
                title: body.title,
                date: body.date ? new Date(body.date) : undefined,
                status: body.status,
                notes: body.notes,
            });
            return res.status(200).json({ success: true, data: item });
        }
        catch (e) {
            if (e?.code === 'P2025')
                return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi cập nhật lịch hẹn' });
        }
    }
    static async deleteAppointment(req, res) {
        try {
            await MedicalService.deleteAppointment(req.user.id, paramId(req));
            return res.status(200).json({ success: true });
        }
        catch (e) {
            if (e?.code === 'P2025')
                return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi xóa lịch hẹn' });
        }
    }
    static async getMetrics(req, res) {
        try {
            const limit = req.query.limit ? parseInt(String(req.query.limit), 10) : 50;
            const list = await MedicalService.getMetrics(req.user.id, limit);
            return res.status(200).json({ success: true, data: list });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi tải chỉ số' });
        }
    }
    static async createMetric(req, res) {
        try {
            const body = req.body || {};
            if (body.type == null || body.value == null || body.unit == null)
                return res.status(400).json({ success: false, message: 'Thiếu type, value hoặc unit' });
            const item = await MedicalService.createMetric(req.user.id, {
                type: String(body.type),
                value: Number(body.value),
                unit: String(body.unit),
                date: body.date ? new Date(body.date) : undefined,
            });
            return res.status(201).json({ success: true, data: item });
        }
        catch (e) {
            return res.status(500).json({ success: false, message: e?.message || 'Lỗi thêm chỉ số' });
        }
    }
}
//# sourceMappingURL=medical.controller.js.map
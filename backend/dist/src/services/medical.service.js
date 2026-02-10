import prisma from '../config/prisma.js';
function formatRelativeTime(date) {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    if (diffMins < 1)
        return 'Vừa xong';
    if (diffMins < 60)
        return `${diffMins} phút trước`;
    if (diffHours < 24)
        return `${diffHours} giờ trước`;
    if (diffDays === 1)
        return 'Hôm qua';
    if (diffDays < 7)
        return `${diffDays} ngày trước`;
    return date.toLocaleDateString('vi-VN');
}
export class MedicalService {
    static async getStats(userId) {
        const [profile, latestRecord, medicines, recentRecords, recentMedicines, upcomingAppointment, latestMetrics, notifications] = await Promise.all([
            prisma.profile.findUnique({ where: { userId } }),
            prisma.medicalRecord.findFirst({ where: { userId }, orderBy: { date: 'desc' } }),
            prisma.medicine.findMany({ where: { userId }, orderBy: { updatedAt: 'desc' } }),
            prisma.medicalRecord.findMany({ where: { userId }, orderBy: { updatedAt: 'desc' }, take: 5 }),
            prisma.medicine.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 5 }),
            prisma.appointment.findFirst({
                where: { userId, status: 'PENDING', date: { gte: new Date() } },
                orderBy: { date: 'asc' },
            }),
            prisma.healthMetric.findMany({ where: { userId }, orderBy: { date: 'desc' }, take: 10 }),
            prisma.notification.findMany({ where: { userId, isRead: false }, take: 5 }),
        ]);
        const activities = [];
        for (const r of recentRecords.slice(0, 3)) {
            activities.push({ id: r.id, title: r.title, time: formatRelativeTime(r.updatedAt), date: r.updatedAt, type: 'record' });
        }
        for (const m of recentMedicines.slice(0, 2)) {
            activities.push({ id: m.id, title: `Thêm thuốc: ${m.name}`, time: formatRelativeTime(m.createdAt), date: m.createdAt, type: 'medicine' });
        }
        activities.sort((a, b) => b.date.getTime() - a.date.getTime());
        const recentActivities = activities.slice(0, 5).map(({ id, title, time, type }) => ({ id, title, time, type }));
        const vitals = latestMetrics
            .filter((m) => ['huyết áp', 'huyet ap', 'blood_pressure'].some((t) => m.type.toLowerCase().includes(t)))
            .slice(0, 1);
        const latestVital = vitals[0];
        const latestVitalsText = latestVital
            ? `HA ${latestVital.value} ${latestVital.unit} (${formatRelativeTime(latestVital.date)})`
            : null;
        const alerts = [];
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        if (latestRecord && latestRecord.updatedAt < thirtyDaysAgo) {
            alerts.push({ id: 'profile-stale', message: 'Hồ sơ chưa cập nhật hơn 30 ngày', type: 'info' });
        }
        const sevenDaysFromNow = new Date();
        sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
        for (const m of medicines) {
            if (m.endDate && m.endDate <= sevenDaysFromNow && m.endDate >= new Date()) {
                alerts.push({ id: `med-${m.id}`, message: `Thuốc "${m.name}" sắp hết (${m.endDate.toLocaleDateString('vi-VN')})`, type: 'warning' });
            }
        }
        for (const n of notifications) {
            alerts.push({ id: n.id, message: n.message, type: n.type });
        }
        return {
            status: latestRecord?.title || 'Bình thường',
            latestDiagnosis: latestRecord?.diagnosis || null,
            upcomingAppointment: upcomingAppointment
                ? { title: upcomingAppointment.title, date: upcomingAppointment.date }
                : null,
            medicineCount: medicines.length,
            medicines: medicines.slice(0, 10).map((m) => ({ id: m.id, name: m.name, dosage: m.dosage, frequency: m.frequency })),
            recentActivities,
            profile: profile
                ? {
                    bloodType: profile.bloodType,
                    allergies: profile.allergies,
                    gender: profile.gender,
                    weight: profile.weight,
                    height: profile.height,
                    birthday: profile.birthday,
                    lastRecordUpdated: latestRecord?.updatedAt,
                }
                : null,
            latestVitalsText,
            latestVitalDate: latestVital?.date,
            alerts: alerts.slice(0, 5),
        };
    }
    static async getRecords(userId) {
        return await prisma.medicalRecord.findMany({
            where: { userId },
            orderBy: { date: 'desc' },
        });
    }
    static async getRecordById(userId, id) {
        return await prisma.medicalRecord.findFirst({
            where: { id, userId },
        });
    }
    static async createRecord(userId, data) {
        return await prisma.medicalRecord.create({
            data: {
                userId,
                title: data.title,
                content: data.content ?? null,
                diagnosis: data.diagnosis ?? null,
                treatment: data.treatment ?? null,
                hospital: data.hospital ?? null,
                date: data.date ? new Date(data.date) : new Date(),
            },
        });
    }
    static async updateRecord(userId, id, data) {
        await prisma.medicalRecord.findFirstOrThrow({ where: { id, userId } });
        return await prisma.medicalRecord.update({
            where: { id },
            data: {
                ...(data.title !== undefined && { title: data.title }),
                ...(data.content !== undefined && { content: data.content }),
                ...(data.diagnosis !== undefined && { diagnosis: data.diagnosis }),
                ...(data.treatment !== undefined && { treatment: data.treatment }),
                ...(data.hospital !== undefined && { hospital: data.hospital }),
                ...(data.date !== undefined && { date: new Date(data.date) }),
            },
        });
    }
    static async deleteRecord(userId, id) {
        await prisma.medicalRecord.findFirstOrThrow({ where: { id, userId } });
        return await prisma.medicalRecord.delete({ where: { id } });
    }
    static async getMedicines(userId) {
        return await prisma.medicine.findMany({
            where: { userId },
            orderBy: { updatedAt: 'desc' },
        });
    }
    static async getMedicineById(userId, id) {
        return await prisma.medicine.findFirst({
            where: { id, userId },
        });
    }
    static async createMedicine(userId, data) {
        return await prisma.medicine.create({
            data: {
                userId,
                name: data.name,
                dosage: data.dosage ?? null,
                frequency: data.frequency ?? null,
                instruction: data.instruction ?? null,
                startDate: data.startDate ? new Date(data.startDate) : new Date(),
                endDate: data.endDate ? new Date(data.endDate) : null,
            },
        });
    }
    static async updateMedicine(userId, id, data) {
        await prisma.medicine.findFirstOrThrow({ where: { id, userId } });
        const payload = {};
        if (data.name !== undefined)
            payload.name = data.name;
        if (data.dosage !== undefined)
            payload.dosage = data.dosage;
        if (data.frequency !== undefined)
            payload.frequency = data.frequency;
        if (data.instruction !== undefined)
            payload.instruction = data.instruction;
        if (data.startDate !== undefined)
            payload.startDate = new Date(data.startDate);
        if (data.endDate !== undefined)
            payload.endDate = data.endDate ? new Date(data.endDate) : null;
        return await prisma.medicine.update({ where: { id }, data: payload });
    }
    static async deleteMedicine(userId, id) {
        await prisma.medicine.findFirstOrThrow({ where: { id, userId } });
        return await prisma.medicine.delete({ where: { id } });
    }
    static async getAppointments(userId) {
        return await prisma.appointment.findMany({
            where: { userId },
            orderBy: { date: 'asc' },
        });
    }
    static async getAppointmentById(userId, id) {
        return await prisma.appointment.findFirst({
            where: { id, userId },
        });
    }
    static async createAppointment(userId, data) {
        return await prisma.appointment.create({
            data: {
                userId,
                title: data.title,
                date: new Date(data.date),
                notes: data.notes ?? null,
            },
        });
    }
    static async updateAppointment(userId, id, data) {
        await prisma.appointment.findFirstOrThrow({ where: { id, userId } });
        const payload = {};
        if (data.title !== undefined)
            payload.title = data.title;
        if (data.date !== undefined)
            payload.date = new Date(data.date);
        if (data.status !== undefined)
            payload.status = data.status;
        if (data.notes !== undefined)
            payload.notes = data.notes;
        return await prisma.appointment.update({ where: { id }, data: payload });
    }
    static async deleteAppointment(userId, id) {
        await prisma.appointment.findFirstOrThrow({ where: { id, userId } });
        return await prisma.appointment.delete({ where: { id } });
    }
    static async getProfile(userId) {
        return await prisma.profile.findUnique({
            where: { userId },
        });
    }
    static async upsertProfile(userId, data) {
        const updatePayload = {};
        if (data.bloodType !== undefined)
            updatePayload.bloodType = data.bloodType;
        if (data.allergies !== undefined)
            updatePayload.allergies = data.allergies;
        if (data.weight !== undefined)
            updatePayload.weight = data.weight;
        if (data.height !== undefined)
            updatePayload.height = data.height;
        if (data.gender !== undefined)
            updatePayload.gender = data.gender;
        if (data.birthday !== undefined)
            updatePayload.birthday = new Date(data.birthday);
        if (data.address !== undefined)
            updatePayload.address = data.address;
        if (data.phone !== undefined)
            updatePayload.phone = data.phone;
        return await prisma.profile.upsert({
            where: { userId },
            create: {
                userId,
                bloodType: data.bloodType ?? null,
                allergies: data.allergies ?? null,
                weight: data.weight ?? null,
                height: data.height ?? null,
                gender: data.gender ?? null,
                birthday: data.birthday ? new Date(data.birthday) : null,
                address: data.address ?? null,
                phone: data.phone ?? null,
            },
            update: updatePayload,
        });
    }
    static async getMetrics(userId, limit = 50) {
        return await prisma.healthMetric.findMany({
            where: { userId },
            orderBy: { date: 'desc' },
            take: limit,
        });
    }
    static async createMetric(userId, data) {
        return await prisma.healthMetric.create({
            data: {
                userId,
                type: data.type,
                value: data.value,
                unit: data.unit,
                date: data.date ? new Date(data.date) : new Date(),
            },
        });
    }
}
//# sourceMappingURL=medical.service.js.map
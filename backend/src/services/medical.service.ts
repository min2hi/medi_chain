import prisma from '../config/prisma.js';

function formatRelativeTime(date: Date): string {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    if (diffMins < 1) return 'Vừa xong';
    if (diffMins < 60) return `${diffMins} phút trước`;
    if (diffHours < 24) return `${diffHours} giờ trước`;
    if (diffDays === 1) return 'Hôm qua';
    if (diffDays < 7) return `${diffDays} ngày trước`;
    return date.toLocaleDateString('vi-VN');
}

const appointmentSelect = {
    id: true,
    title: true,
    date: true,
    status: true,
    userId: true,
    doctorId: true,
    notes: true,
    doctorNotes: true,
    completedAt: true,
    paymentStatus: true,
    consultFee: true,
    createdAt: true,
} as const;

export class MedicalService {
    static async getStats(userId: string) {
        const [profile, latestRecord, medicines, recentRecords, recentMedicines, upcomingAppointment, latestMetrics, notifications, recentAppointments] = await Promise.all([
            prisma.profile.findUnique({ where: { userId } }),
            prisma.medicalRecord.findFirst({ where: { userId }, orderBy: { date: 'desc' } }),
            prisma.medicine.findMany({ where: { userId }, orderBy: { updatedAt: 'desc' } }),
            prisma.medicalRecord.findMany({ where: { userId }, orderBy: { updatedAt: 'desc' }, take: 15 }),
            prisma.medicine.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 15 }),
            prisma.appointment.findFirst({
                where: { userId, status: 'PENDING', date: { gte: new Date() } },
                orderBy: { date: 'asc' },
                select: appointmentSelect,
            }),
            prisma.healthMetric.findMany({ where: { userId }, orderBy: { date: 'desc' }, take: 10 }),
            prisma.notification.findMany({ where: { userId, isRead: false }, take: 5 }),
            prisma.appointment.findMany({
                where: { userId, status: { in: ['COMPLETED', 'CONFIRMED'] } },
                orderBy: { date: 'desc' },
                take: 10,
                select: { id: true, title: true, date: true, status: true },
            }),
        ]);

        const activities: { id: string; title: string; time: string; date: Date; type: string }[] = [];
        for (const r of recentRecords) {
            activities.push({ id: r.id, title: r.title, time: formatRelativeTime(r.updatedAt), date: r.updatedAt, type: 'record' });
        }
        for (const m of recentMedicines) {
            activities.push({ id: m.id, title: `Thêm thuốc: ${m.name}`, time: formatRelativeTime(m.createdAt), date: m.createdAt, type: 'medicine' });
        }
        for (const a of recentAppointments) {
            const label = a.status === 'COMPLETED' ? `Khám xong: ${a.title}` : `Lịch hẹn xác nhận: ${a.title}`;
            activities.push({ id: `apt-${a.id}`, title: label, time: formatRelativeTime(a.date), date: a.date, type: 'appointment' });
        }
        activities.sort((a, b) => b.date.getTime() - a.date.getTime());
        const recentActivities = activities.slice(0, 20).map(({ id, title, time, type }) => ({ id, title, time, type }));

        const vitals = latestMetrics
            .filter((m) => ['huyết áp', 'huyet ap', 'blood_pressure'].some((t) => m.type.toLowerCase().includes(t)))
            .slice(0, 1);
        const latestVital = vitals[0];
        const latestVitalsText = latestVital
            ? `HA ${latestVital.value} ${latestVital.unit} (${formatRelativeTime(latestVital.date)})`
            : null;

        const alerts: { id: string; message: string; type: string }[] = [];
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
            // Chỉ đưa vào alerts những thông báo sức khỏe/thuốc (MEDICINE, SYSTEM).
            // Type 'APPOINTMENT' (xác nhận/hủy/check-in) đã hiển thị trong màn hình
            // danh sách lịch hẹn — không push vào alerts để tránh trùng lặp.
            if (n.type !== 'APPOINTMENT') {
                alerts.push({ id: n.id, message: n.message, type: n.type });
            }
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

    static async getRecords(userId: string) {
        return await prisma.medicalRecord.findMany({
            where: { userId },
            orderBy: { date: 'desc' },
        });
    }

    static async getRecordById(userId: string, id: string) {
        return await prisma.medicalRecord.findFirst({
            where: { id, userId },
        });
    }

    static async createRecord(userId: string, data: { title: string; content?: string; diagnosis?: string; treatment?: string; hospital?: string; date?: Date }) {
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

    static async updateRecord(userId: string, id: string, data: Partial<{ title: string; content: string; diagnosis: string; treatment: string; hospital: string; date: Date }>) {
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

    static async deleteRecord(userId: string, id: string) {
        await prisma.medicalRecord.findFirstOrThrow({ where: { id, userId } });
        return await prisma.medicalRecord.delete({ where: { id } });
    }

    static async getMedicines(userId: string) {
        return await prisma.medicine.findMany({
            where: { userId },
            orderBy: { updatedAt: 'desc' },
            select: {
                id: true, name: true, dosage: true, frequency: true,
                instruction: true, startDate: true, endDate: true,
                createdAt: true, updatedAt: true,
                drugCandidateId: true,
                recommendationSessionId: true,
            },
        });
    }

    static async getMedicineById(userId: string, id: string) {
        return await prisma.medicine.findFirst({
            where: { id, userId },
        });
    }

    static async createMedicine(
        userId: string,
        data: {
            name: string;
            dosage?: string;
            frequency?: string;
            instruction?: string;
            startDate?: Date;
            endDate?: Date;
            // Data lineage (optional, chỉ có khi thêm từ tư vấn)
            drugCandidateId?: string;
            recommendationSessionId?: string;
        }
    ) {
        return await prisma.medicine.create({
            data: {
                userId,
                name: data.name,
                dosage: data.dosage ?? null,
                frequency: data.frequency ?? null,
                instruction: data.instruction ?? null,
                startDate: data.startDate ? new Date(data.startDate) : new Date(),
                endDate: data.endDate ? new Date(data.endDate) : null,
                ...(data.drugCandidateId !== undefined && { drugCandidateId: data.drugCandidateId }),
                ...(data.recommendationSessionId !== undefined && { recommendationSessionId: data.recommendationSessionId }),
            },
        });
    }

    static async updateMedicine(userId: string, id: string, data: Partial<{ name: string; dosage: string; frequency: string; instruction: string; startDate: Date; endDate: Date }>) {
        await prisma.medicine.findFirstOrThrow({ where: { id, userId } });
        const payload: any = {};
        if (data.name !== undefined) payload.name = data.name;
        if (data.dosage !== undefined) payload.dosage = data.dosage;
        if (data.frequency !== undefined) payload.frequency = data.frequency;
        if (data.instruction !== undefined) payload.instruction = data.instruction;
        if (data.startDate !== undefined) payload.startDate = new Date(data.startDate);
        if (data.endDate !== undefined) payload.endDate = data.endDate ? new Date(data.endDate) : null;
        return await prisma.medicine.update({ where: { id }, data: payload });
    }

    static async deleteMedicine(userId: string, id: string) {
        await prisma.medicine.findFirstOrThrow({ where: { id, userId } });
        return await prisma.medicine.delete({ where: { id } });
    }

    static async getAppointments(userId: string) {
        return await prisma.appointment.findMany({
            where: { userId },
            orderBy: { date: 'asc' },
            select: appointmentSelect,
        });
    }

    static async getAppointmentById(userId: string, id: string) {
        return await prisma.appointment.findFirst({
            where: { id, userId },
            select: appointmentSelect,
        });
    }

    static async createAppointment(userId: string, data: { title: string; date: Date; notes?: string; doctorId?: string }) {
        const apt = await prisma.appointment.create({
            data: {
                userId,
                title: data.title,
                date: new Date(data.date),
                notes: data.notes ?? null,
                doctorId: data.doctorId ?? null,
            },
            select: appointmentSelect,
        });

        // Notify Bác sĩ (APPOINTMENT) và Admin (SYSTEM) về lịch hẹn mới
        // Pattern: fan-out notification — mỗi người nhận riêng để có thể mark-read độc lập
        const patient = await prisma.user.findUnique({
            where: { id: userId },
            select: { name: true },
        });

        const dateFormatted = new Date(data.date).toLocaleDateString('vi-VN', {
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit',
        });

        const notificationData: any[] = [];

        // 1. Gửi thông báo APPOINTMENT cho Doctor
        if (data.doctorId) {
            notificationData.push({
                userId: data.doctorId,
                title: 'Lịch hẹn mới',
                message: `${patient?.name ?? 'Bệnh nhân'} đặt lịch "${data.title}" vào ${dateFormatted} với bạn.`,
                type: 'APPOINTMENT',
            });
        } else {
            // Nếu không chỉ định bác sĩ, thông báo cho tất cả bác sĩ để họ nhận lịch
            const doctors = await prisma.user.findMany({
                where: { role: 'DOCTOR' },
                select: { id: true },
            });
            for (const doc of doctors) {
                notificationData.push({
                    userId: doc.id,
                    title: 'Lịch hẹn mới',
                    message: `${patient?.name ?? 'Bệnh nhân'} đặt lịch hẹn mới vào ${dateFormatted}.`,
                    type: 'APPOINTMENT',
                });
            }
        }

        // 2. Gửi thông báo SYSTEM cho Admin để ghi nhật ký hệ thống
        const admins = await prisma.user.findMany({
            where: { role: 'ADMIN' },
            select: { id: true },
        });
        for (const admin of admins) {
            notificationData.push({
                userId: admin.id,
                title: 'Lịch hẹn mới',
                message: `${patient?.name ?? 'Bệnh nhân'} đặt lịch "${data.title}" vào ${dateFormatted}.`,
                type: 'SYSTEM',
            });
        }

        if (notificationData.length > 0) {
            await prisma.notification.createMany({
                data: notificationData,
            });
        }

        return apt;
    }

    static async updateAppointment(userId: string, id: string, data: Partial<{ title: string; date: Date; status: string; notes: string }>) {
        await prisma.appointment.findFirstOrThrow({ where: { id, userId }, select: { id: true } });
        const payload: any = {};
        if (data.title !== undefined) payload.title = data.title;
        if (data.date !== undefined) payload.date = new Date(data.date);
        if (data.status !== undefined) payload.status = data.status;
        if (data.notes !== undefined) payload.notes = data.notes;
        return await prisma.appointment.update({ where: { id }, data: payload, select: appointmentSelect });
    }

    static async deleteAppointment(userId: string, id: string) {
        await prisma.appointment.findFirstOrThrow({ where: { id, userId }, select: { id: true } });
        return await prisma.appointment.delete({ where: { id }, select: appointmentSelect });
    }

    static async getProfile(userId: string) {
        return await prisma.profile.findUnique({
            where: { userId },
        });
    }

    static async upsertProfile(userId: string, data: { bloodType?: string; allergies?: string; weight?: number; height?: number; gender?: string; birthday?: Date; address?: string; phone?: string; chronicConditions?: string; isPregnant?: boolean; isBreastfeeding?: boolean }) {
        const updatePayload: any = {};
        if (data.bloodType !== undefined) updatePayload.bloodType = data.bloodType;
        if (data.allergies !== undefined) updatePayload.allergies = data.allergies;
        if (data.weight !== undefined) updatePayload.weight = data.weight;
        if (data.height !== undefined) updatePayload.height = data.height;
        if (data.gender !== undefined) updatePayload.gender = data.gender;
        if (data.birthday !== undefined) updatePayload.birthday = new Date(data.birthday);
        if (data.address !== undefined) updatePayload.address = data.address;
        if (data.phone !== undefined) updatePayload.phone = data.phone;
        if (data.chronicConditions !== undefined) updatePayload.chronicConditions = data.chronicConditions;
        if (data.isPregnant !== undefined) updatePayload.isPregnant = data.isPregnant;
        if (data.isBreastfeeding !== undefined) updatePayload.isBreastfeeding = data.isBreastfeeding;

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
                chronicConditions: data.chronicConditions ?? null,
                isPregnant: data.isPregnant ?? null,
                isBreastfeeding: data.isBreastfeeding ?? null,
            },
            update: updatePayload,
        });
    }

    /**
     * Cập nhật thông tin chứng chỉ bác sĩ (DOCTOR tự nhập).
     * Không cho phép tự set licenseVerified — chỉ Admin mới verify được.
     */
    static async updateDoctorProfile(userId: string, data: {
        licenseNumber?: string;
        specialty?: string;
        clinicAddress?: string;
    }) {
        const updatePayload: Record<string, unknown> = {};
        if (data.licenseNumber !== undefined) updatePayload.licenseNumber = data.licenseNumber;
        if (data.specialty     !== undefined) updatePayload.specialty     = data.specialty;
        if (data.clinicAddress !== undefined) updatePayload.clinicAddress = data.clinicAddress;

        return await prisma.profile.upsert({
            where:  { userId },
            create: { userId, ...updatePayload },
            update: updatePayload,
        });
    }

    static async getMetrics(userId: string, limit = 50) {
        return await prisma.healthMetric.findMany({
            where: { userId },
            orderBy: { date: 'desc' },
            take: limit,
        });
    }

    static async createMetric(userId: string, data: { type: string; value: number; unit: string; date?: Date }) {
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

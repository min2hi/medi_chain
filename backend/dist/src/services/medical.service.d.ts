export declare class MedicalService {
    static getStats(userId: string): Promise<{
        status: string;
        latestDiagnosis: string | null;
        upcomingAppointment: {
            title: string;
            date: Date;
        } | null;
        medicineCount: number;
        medicines: {
            id: string;
            name: string;
            dosage: string | null;
            frequency: string | null;
        }[];
        recentActivities: {
            id: string;
            title: string;
            time: string;
            type: string;
        }[];
        profile: {
            bloodType: string | null;
            allergies: string | null;
            gender: string | null;
            weight: number | null;
            height: number | null;
            birthday: Date | null;
            lastRecordUpdated: Date | undefined;
        } | null;
        latestVitalsText: string | null;
        latestVitalDate: Date;
        alerts: {
            id: string;
            message: string;
            type: string;
        }[];
    }>;
    static getRecords(userId: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        title: string;
        content: string | null;
        diagnosis: string | null;
        treatment: string | null;
        hospital: string | null;
        date: Date;
    }[]>;
    static getRecordById(userId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        title: string;
        content: string | null;
        diagnosis: string | null;
        treatment: string | null;
        hospital: string | null;
        date: Date;
    } | null>;
    static createRecord(userId: string, data: {
        title: string;
        content?: string;
        diagnosis?: string;
        treatment?: string;
        hospital?: string;
        date?: Date;
    }): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        title: string;
        content: string | null;
        diagnosis: string | null;
        treatment: string | null;
        hospital: string | null;
        date: Date;
    }>;
    static updateRecord(userId: string, id: string, data: Partial<{
        title: string;
        content: string;
        diagnosis: string;
        treatment: string;
        hospital: string;
        date: Date;
    }>): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        title: string;
        content: string | null;
        diagnosis: string | null;
        treatment: string | null;
        hospital: string | null;
        date: Date;
    }>;
    static deleteRecord(userId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        title: string;
        content: string | null;
        diagnosis: string | null;
        treatment: string | null;
        hospital: string | null;
        date: Date;
    }>;
    static getMedicines(userId: string): Promise<{
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        dosage: string | null;
        frequency: string | null;
        instruction: string | null;
        startDate: Date;
        endDate: Date | null;
    }[]>;
    static getMedicineById(userId: string, id: string): Promise<{
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        dosage: string | null;
        frequency: string | null;
        instruction: string | null;
        startDate: Date;
        endDate: Date | null;
    } | null>;
    static createMedicine(userId: string, data: {
        name: string;
        dosage?: string;
        frequency?: string;
        instruction?: string;
        startDate?: Date;
        endDate?: Date;
    }): Promise<{
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        dosage: string | null;
        frequency: string | null;
        instruction: string | null;
        startDate: Date;
        endDate: Date | null;
    }>;
    static updateMedicine(userId: string, id: string, data: Partial<{
        name: string;
        dosage: string;
        frequency: string;
        instruction: string;
        startDate: Date;
        endDate: Date;
    }>): Promise<{
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        dosage: string | null;
        frequency: string | null;
        instruction: string | null;
        startDate: Date;
        endDate: Date | null;
    }>;
    static deleteMedicine(userId: string, id: string): Promise<{
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        dosage: string | null;
        frequency: string | null;
        instruction: string | null;
        startDate: Date;
        endDate: Date | null;
    }>;
    static getAppointments(userId: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        date: Date;
        status: import("../generated/client/index.js").$Enums.AppStatus;
        doctorId: string | null;
        notes: string | null;
    }[]>;
    static getAppointmentById(userId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        date: Date;
        status: import("../generated/client/index.js").$Enums.AppStatus;
        doctorId: string | null;
        notes: string | null;
    } | null>;
    static createAppointment(userId: string, data: {
        title: string;
        date: Date;
        notes?: string;
    }): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        date: Date;
        status: import("../generated/client/index.js").$Enums.AppStatus;
        doctorId: string | null;
        notes: string | null;
    }>;
    static updateAppointment(userId: string, id: string, data: Partial<{
        title: string;
        date: Date;
        status: string;
        notes: string;
    }>): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        date: Date;
        status: import("../generated/client/index.js").$Enums.AppStatus;
        doctorId: string | null;
        notes: string | null;
    }>;
    static deleteAppointment(userId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        date: Date;
        status: import("../generated/client/index.js").$Enums.AppStatus;
        doctorId: string | null;
        notes: string | null;
    }>;
    static getProfile(userId: string): Promise<{
        id: string;
        bloodType: string | null;
        allergies: string | null;
        weight: number | null;
        height: number | null;
        gender: string | null;
        birthday: Date | null;
        address: string | null;
        phone: string | null;
        userId: string;
    } | null>;
    static upsertProfile(userId: string, data: {
        bloodType?: string;
        allergies?: string;
        weight?: number;
        height?: number;
        gender?: string;
        birthday?: Date;
        address?: string;
        phone?: string;
    }): Promise<{
        id: string;
        bloodType: string | null;
        allergies: string | null;
        weight: number | null;
        height: number | null;
        gender: string | null;
        birthday: Date | null;
        address: string | null;
        phone: string | null;
        userId: string;
    }>;
    static getMetrics(userId: string, limit?: number): Promise<{
        id: string;
        userId: string;
        date: Date;
        type: string;
        value: number;
        unit: string;
    }[]>;
    static createMetric(userId: string, data: {
        type: string;
        value: number;
        unit: string;
        date?: Date;
    }): Promise<{
        id: string;
        userId: string;
        date: Date;
        type: string;
        value: number;
        unit: string;
    }>;
}

import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
export declare class MedicalController {
    static getProfile(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static upsertProfile(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static getRecords(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static getRecord(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static createRecord(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateRecord(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteRecord(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static getMedicines(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static getMedicine(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static createMedicine(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateMedicine(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteMedicine(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static getAppointments(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static getAppointment(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static createAppointment(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateAppointment(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteAppointment(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static getMetrics(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    static createMetric(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
}

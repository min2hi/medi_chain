import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware.js';
export declare class UserController {
    static getDashboard(req: AuthRequest, res: Response): Promise<Response<any, Record<string, any>>>;
}

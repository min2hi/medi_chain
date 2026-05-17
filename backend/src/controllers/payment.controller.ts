import { Request, Response } from 'express';
import { PaymentService } from '../services/payment.service.js';
import { logger } from '../utils/logger.js';

export class PaymentController {

  // POST /api/payment/create-order
  // Patient tạo đơn thanh toán cho appointment
  static async createOrder(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const { appointmentId } = req.body as { appointmentId?: string };

      if (!appointmentId) {
        return res.status(400).json({ success: false, message: 'appointmentId là bắt buộc' });
      }

      const result = await PaymentService.createOrder({ userId, appointmentId });
      return res.json({ success: true, data: result });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Lỗi tạo đơn thanh toán';
      return res.status(400).json({ success: false, message });
    }
  }

  // POST /api/payment/webhook  ← PUBLIC (không có authMiddleware)
  // PayOS gọi vào đây sau khi user thanh toán xong
  static async handleWebhook(req: Request, res: Response) {
    try {
      // PayOS webhook body: { code, desc, data: { orderCode, amount, ... }, signature }
      // Signature được tính HMAC-SHA256 trên sub-object "data" (keys sorted alphabetically),
      // KHÔNG phải toàn body. orderCode cũng nằm trong data, không phải top-level.
      const body = req.body as {
        code: string;
        desc: string;
        data: Record<string, unknown>;
        signature: string;
      };

      const { data, signature, code } = body;

      if (!data || !signature) {
        return res.status(400).json({ success: false, message: 'Missing data or signature' });
      }

      // Verify signature trên data sub-object (đúng spec PayOS)
      if (!PaymentService.verifyWebhookSignature(data, signature)) {
        logger.warn({ body }, 'PayOS webhook: invalid signature');
        return res.status(400).json({ success: false, message: 'Invalid signature' });
      }

      // orderCode nằm trong data, không phải top-level
      const orderCode = String(data['orderCode'] ?? '');

      if (!orderCode) {
        return res.status(400).json({ success: false, message: 'Missing orderCode' });
      }

      // code '00' = thành công theo spec PayOS
      if (code === '00') {
        await PaymentService.handleWebhookSuccess(orderCode, body);
      } else {
        await PaymentService.handleWebhookFailed(orderCode, body);
      }

      // PayOS yêu cầu response 200 nhanh (không quá 30s)
      return res.json({ success: true });
    } catch (error) {
      logger.error({ err: error }, 'PayOS webhook handler error');
      // Vẫn trả 200 để PayOS không retry liên tục
      return res.json({ success: false });
    }
  }

  // GET /api/payment/history
  // Lịch sử thanh toán của user đang đăng nhập
  static async getHistory(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const history = await PaymentService.getHistory(userId);
      return res.json({ success: true, data: history });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Lỗi tải lịch sử thanh toán';
      return res.status(400).json({ success: false, message });
    }
  }

  // GET /api/payment/status/:orderCode
  // Kiểm tra trạng thái 1 đơn (dùng khi app mở lại sau khi thanh toán)
  static async getStatus(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const orderCode = String(req.params['orderCode'] ?? '');
      const result = await PaymentService.getOrderStatus(orderCode, userId);
      return res.json({ success: true, data: result });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Lỗi kiểm tra trạng thái';
      return res.status(404).json({ success: false, message });
    }
  }

  // GET /api/payment/settings/fee
  // Lấy phí khám hiện tại (patient dùng để hiển thị trước khi thanh toán)
  static async getFee(req: Request, res: Response) {
    try {
      const fee = await PaymentService.getConsultationFee();
      return res.json({ success: true, data: { consultationFee: fee } });
    } catch (error) {
      return res.status(500).json({ success: false, message: 'Lỗi tải phí khám' });
    }
  }

  // PUT /api/payment/settings/fee  ← ADMIN only
  // Admin cập nhật phí khám
  static async updateFee(req: Request, res: Response) {
    try {
      const adminId = (req as any).user.id;
      const { fee } = req.body as { fee?: number };

      if (!fee || typeof fee !== 'number') {
        return res.status(400).json({ success: false, message: 'fee phải là số nguyên (VND)' });
      }

      await PaymentService.setConsultationFee(fee, adminId);
      return res.json({ success: true, message: `Đã cập nhật phí khám: ${fee.toLocaleString('vi-VN')} VND` });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Lỗi cập nhật phí khám';
      return res.status(400).json({ success: false, message });
    }
  }
}

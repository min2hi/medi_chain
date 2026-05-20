import crypto from 'crypto';
import prisma from '../config/prisma.js';
import { logger } from '../utils/logger.js';

// ─── Types ───────────────────────────────────────────────────────────────────

export interface CreatePaymentOrderDto {
  userId: string;
  appointmentId: string;
}

export interface PayOSOrderResponse {
  checkoutUrl: string;
  orderCode: string;
  paymentLinkId: string;
  amount: number; // Giá thực tế đã được confirm — frontend dùng cái này, không gọi fee API riêng
}

// ─── PaymentService ───────────────────────────────────────────────────────────

export class PaymentService {

  // ── Tạo lệnh thanh toán với PayOS ─────────────────────────────────────────
  static async createOrder(dto: CreatePaymentOrderDto): Promise<PayOSOrderResponse> {
    if (!dto.userId || !dto.appointmentId) {
      throw new Error('userId và appointmentId là bắt buộc');
    }

    // 1. Verify appointment thuộc về user này
    const appointment = await prisma.appointment.findFirst({
      where: { id: dto.appointmentId, userId: dto.userId },
      select: { id: true, title: true, paymentStatus: true, consultFee: true },
    });
    if (!appointment) {
      throw new Error('Không tìm thấy lịch hẹn');
    }
    if (appointment.paymentStatus === 'PAID') {
      throw new Error('Lịch hẹn này đã được thanh toán');
    }

    // 2. Lấy phí khám từ ClinicSetting — CÙNG bảng với Admin screen
    //    Key: 'consultationFee' (không phải 'consultation_fee')
    const feeSetting = await prisma.clinicSetting.findUnique({
      where: { key: 'consultationFee' },
    });
    const amount = feeSetting ? parseInt(feeSetting.value, 10) : 200000;

    // 3. Tạo orderCode duy nhất (timestamp + random — PayOS yêu cầu số nguyên)
    const orderCode = Date.now();

    // 4. Gọi PayOS API
    const payosClientId = process.env.PAYOS_CLIENT_ID!;
    const payosApiKey = process.env.PAYOS_API_KEY!;
    const payosChecksumKey = process.env.PAYOS_CHECKSUM_KEY!;
    const returnUrl = process.env.PAYOS_RETURN_URL || 'medichain://payment/return';
    const cancelUrl = process.env.PAYOS_CANCEL_URL || 'medichain://payment/cancel';

    if (!payosClientId || !payosApiKey || !payosChecksumKey) {
      throw new Error('PayOS credentials chưa được cấu hình trong .env');
    }

    // Tạo signature theo đúng spec PayOS
    const signatureData = `amount=${amount}&cancelUrl=${cancelUrl}&description=Phi kham benh&orderCode=${orderCode}&returnUrl=${returnUrl}`;
    const signature = crypto
      .createHmac('sha256', payosChecksumKey)
      .update(signatureData)
      .digest('hex');

    const payosBody = {
      orderCode,
      amount,
      description: 'Phi kham benh',
      items: [{ name: appointment.title.slice(0, 25), quantity: 1, price: amount }],
      returnUrl,
      cancelUrl,
      signature,
    };

    const payosRes = await fetch('https://api-merchant.payos.vn/v2/payment-requests', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-client-id': payosClientId,
        'x-api-key': payosApiKey,
      },
      body: JSON.stringify(payosBody),
    });

    if (!payosRes.ok) {
      const errText = await payosRes.text();
      logger.error({ errText }, 'PayOS API error');
      throw new Error('Không thể tạo link thanh toán. Vui lòng thử lại.');
    }

    const payosData = (await payosRes.json()) as {
      code: string;
      desc: string;
      data?: { checkoutUrl: string; paymentLinkId: string };
    };

    if (payosData.code !== '00' || !payosData.data) {
      throw new Error(`PayOS: ${payosData.desc}`);
    }

    const { checkoutUrl, paymentLinkId } = payosData.data;
    const orderCodeStr = orderCode.toString();

    // 5. Lưu transaction + update appointment atomically
    await prisma.$transaction([
      prisma.paymentTransaction.create({
        data: {
          orderCode: orderCodeStr,
          userId: dto.userId,
          appointmentId: dto.appointmentId,
          amount,
          status: 'PENDING',
          providerRef: paymentLinkId,
          checkoutUrl,
        },
      }),
      prisma.appointment.update({
        where: { id: dto.appointmentId },
        data: {
          paymentStatus: 'PENDING',
          consultFee: amount,
        },
      }),
    ]);

    return { checkoutUrl, orderCode: orderCodeStr, paymentLinkId, amount };
  }

  // ── Verify HMAC-SHA256 Webhook từ PayOS ───────────────────────────────────
  static verifyWebhookSignature(data: Record<string, unknown>, receivedSignature: string): boolean {
    const checksumKey = process.env.PAYOS_CHECKSUM_KEY!;
    if (!checksumKey) return false;

    // PayOS ký theo alphabet sort của các key trong data object
    const sortedKeys = Object.keys(data).sort();
    const signatureStr = sortedKeys
      .map((key) => `${key}=${data[key]}`)
      .join('&');

    const expectedSignature = crypto
      .createHmac('sha256', checksumKey)
      .update(signatureStr)
      .digest('hex');

    return crypto.timingSafeEqual(
      Buffer.from(expectedSignature, 'hex'),
      Buffer.from(receivedSignature, 'hex'),
    );
  }

  // ── Xử lý Webhook Payment Success ─────────────────────────────────────────
  static async handleWebhookSuccess(orderCode: string, webhookRaw: unknown): Promise<void> {
    // Atomic update: chỉ update nếu status CHƯA là PAID (idempotency + race condition safe)
    // updateMany với điều kiện kép — chỉ 1 trong 2 concurrent requests thắng
    const updateResult = await prisma.paymentTransaction.updateMany({
      where: {
        orderCode,
        status: { not: 'PAID' }, // guard chống double-processing
      },
      data: {
        status: 'PAID',
        webhookData: webhookRaw as never,
      },
    });

    if (updateResult.count === 0) {
      logger.info({ orderCode }, 'Webhook: đã xử lý trước đó (idempotency guard)');
      return;
    }

    // Tìm appointmentId để update (chỉ chạy 1 lần nhờ guard trên)
    const tx = await prisma.paymentTransaction.findUnique({
      where: { orderCode },
      select: { appointmentId: true },
    });

    if (tx) {
      await prisma.appointment.update({
        where: { id: tx.appointmentId },
        data: { paymentStatus: 'PAID' },
      });
    }

    logger.info({ orderCode }, '✅ Payment marked PAID');
  }

  // ── Xử lý Webhook Payment Cancelled/Failed ────────────────────────────────
  static async handleWebhookFailed(orderCode: string, webhookRaw: unknown): Promise<void> {
    const tx = await prisma.paymentTransaction.findUnique({
      where: { orderCode },
      select: { id: true, status: true, appointmentId: true },
    });
    if (!tx || tx.status === 'PAID') return;

    await prisma.$transaction([
      prisma.paymentTransaction.update({
        where: { orderCode },
        data: { status: 'FAILED', webhookData: webhookRaw as never },
      }),
      prisma.appointment.update({
        where: { id: tx.appointmentId },
        data: { paymentStatus: 'UNPAID' },
      }),
    ]);

    logger.warn({ orderCode }, '❌ Payment marked FAILED');
  }

  // ── Lịch sử thanh toán của user ───────────────────────────────────────────
  static async getHistory(userId: string) {
    if (!userId) throw new Error('userId là bắt buộc');

    return prisma.paymentTransaction.findMany({
      where: { userId },
      select: {
        id: true,
        orderCode: true,
        amount: true,
        status: true,
        createdAt: true,
        appointment: {
          select: { id: true, title: true, date: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  // ── Kiểm tra trạng thái 1 đơn ────────────────────────────────────────────
  static async getOrderStatus(orderCode: string, userId: string) {
    const tx = await prisma.paymentTransaction.findFirst({
      where: { orderCode, userId },
      select: { orderCode: true, status: true, amount: true, createdAt: true, checkoutUrl: true },
    });
    if (!tx) throw new Error('Không tìm thấy giao dịch');
    return tx;
  }

  // ── Lấy phí khám hiện tại — đọc từ ClinicSetting (CÙNG bảng Admin screen ghi) ──
  static async getConsultationFee(): Promise<number> {
    const setting = await prisma.clinicSetting.findUnique({
      where: { key: 'consultationFee' },
    });
    return setting ? parseInt(setting.value, 10) : 200000;
  }

  // ── Admin: Set phí khám — ghi vào ClinicSetting (đồng bộ với Admin screen) ──
  // Route /payment/settings/fee vẫn hoạt động để không break client cũ
  static async setConsultationFee(fee: number, _adminId: string): Promise<void> {
    if (!fee || fee < 0) throw new Error('Phí khám không hợp lệ');
    if (fee > 10_000_000) throw new Error('Phí khám không được vượt quá 10,000,000 VND');

    await prisma.clinicSetting.upsert({
      where: { key: 'consultationFee' },
      create: { key: 'consultationFee', value: fee.toString() },
      update: { value: fee.toString() },
    });
  }
}

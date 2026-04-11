import nodemailer, { Transporter } from 'nodemailer';

// ─── Types ────────────────────────────────────────────────────────────────────

interface EmailPayload {
    to: string;
    subject: string;
    html: string;
}

// ─── Transporter Factory (Singleton) ─────────────────────────────────────────
// Tạo 1 lần duy nhất khi module load, tái sử dụng connection pool.
// Pattern này giống cách Stripe, GitHub dùng nodemailer internally.

let _transporter: Transporter | null = null;

function getTransporter(): Transporter {
    if (_transporter) return _transporter;

    const user = process.env.EMAIL_USER;
    const pass = process.env.EMAIL_PASS;

    if (!user || !pass) {
        throw new Error(
            '❌ EMAIL_USER hoặc EMAIL_PASS chưa được cấu hình trong .env. ' +
            'Email service không thể khởi động. ' +
            'Xem hướng dẫn tại: https://myaccount.google.com/apppasswords'
        );
    }

    _transporter = nodemailer.createTransport({
        host: process.env.EMAIL_HOST || 'smtp.gmail.com',
        port: Number(process.env.EMAIL_PORT) || 587,
        secure: false,          // TLS (STARTTLS) — port 587 không cần secure:true
        auth: { user, pass },
        pool: true,             // Dùng connection pool thay vì tạo connection mới mỗi lần gửi
        maxConnections: 5,      // Tối đa 5 kết nối song song
        maxMessages: 100,       // Tối đa 100 email / connection trước khi tạo mới
        rateDelta: 1000,        // Throttle: tối thiểu 1 giây giữa các lần gửi
        rateLimit: 5,           // Tối đa 5 email / rateDelta (tránh Gmail chặn)
    });

    return _transporter;
}

// ─── Core Send Function (có Retry) ───────────────────────────────────────────
// Chuẩn production: retry 3 lần với exponential backoff nếu SMTP tạm thời lỗi.
// GitHub, Stripe đều implement retry pattern tương tự.

async function sendWithRetry(
    payload: EmailPayload,
    maxRetries = 3
): Promise<void> {
    const transporter = getTransporter();
    const from = `"MediChain" <${process.env.EMAIL_FROM || process.env.EMAIL_USER}>`;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const info = await transporter.sendMail({
                from,
                to: payload.to,
                subject: payload.subject,
                html: payload.html,
            });

            console.log(`✅ [EmailService] Gửi email thành công`, {
                to: payload.to,
                subject: payload.subject,
                messageId: info.messageId,
                attempt,
            });

            return; // Thành công → thoát vòng lặp

        } catch (error: any) {
            const isLastAttempt = attempt === maxRetries;

            console.error(`❌ [EmailService] Lần thử ${attempt}/${maxRetries} thất bại`, {
                to: payload.to,
                subject: payload.subject,
                error: error.message,
                code: error.code,
            });

            if (isLastAttempt) {
                // Đã hết retry — throw để caller xử lý
                throw new Error(
                    `Email gửi thất bại sau ${maxRetries} lần thử. ` +
                    `Lỗi cuối: ${error.message}`
                );
            }

            // Exponential backoff: 1s → 2s → 4s
            const delayMs = Math.pow(2, attempt - 1) * 1000;
            console.log(`⏳ [EmailService] Chờ ${delayMs}ms trước khi thử lại...`);
            await new Promise(resolve => setTimeout(resolve, delayMs));
        }
    }
}

// ─── Email Templates ──────────────────────────────────────────────────────────
// Tách template ra riêng để dễ maintain và test.

function buildPasswordResetEmail(resetLink: string, displayName: string): string {
    return `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Đặt lại mật khẩu — MediChain</title>
</head>
<body style="margin:0;padding:0;background:#F0FDFA;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F0FDFA;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#0F766E,#134E4A);padding:36px 40px;text-align:center;">
              <div style="display:inline-block;background:rgba(255,255,255,0.15);border-radius:12px;padding:10px 14px;margin-bottom:16px;">
                ❤️
              </div>
              <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:-0.3px;">MediChain</h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.75);font-size:13px;">Hệ thống quản lý sức khoẻ thông minh</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:36px 40px;">
              <h2 style="margin:0 0 12px;color:#0F172A;font-size:19px;font-weight:700;">Xin chào, ${displayName}!</h2>
              <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.7;">
                Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn trên <strong>MediChain</strong>.
                Nhấn nút bên dưới để tiến hành đặt lại mật khẩu.
              </p>
              <div style="text-align:center;margin:32px 0;">
                <a href="${resetLink}"
                   style="display:inline-block;background:#14B8A6;color:#ffffff;text-decoration:none;
                          padding:14px 36px;border-radius:12px;font-size:15px;font-weight:700;
                          letter-spacing:0.2px;">
                  Đặt lại mật khẩu
                </a>
              </div>
              <div style="background:#FFF7ED;border:1px solid #FED7AA;border-radius:10px;padding:14px 18px;margin-bottom:20px;">
                <p style="margin:0;color:#9A3412;font-size:13px;line-height:1.6;">
                  ⚠️ <strong>Lưu ý bảo mật:</strong> Link này chỉ có hiệu lực trong <strong>1 giờ</strong>
                  và chỉ sử dụng được một lần. Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.
                </p>
              </div>
              <p style="margin:0;color:#94A3B8;font-size:12px;line-height:1.6;">
                Nếu nút không hoạt động, hãy copy link sau vào trình duyệt:<br/>
                <span style="color:#0F766E;word-break:break-all;">${resetLink}</span>
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;padding:20px 40px;text-align:center;">
              <p style="margin:0;color:#94A3B8;font-size:12px;">
                © 2026 MediChain. Mọi quyền được bảo lưu.<br/>
                Email này được gửi tự động, vui lòng không reply.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

// ─── Public API ───────────────────────────────────────────────────────────────
// Thiết kế theo Facade Pattern: controller/service chỉ gọi EmailService.*
// Không cần biết bên trong dùng nodemailer, SMTP, hay Resend.

export class EmailService {

    /**
     * Gửi email đặt lại mật khẩu.
     * Có retry 3 lần với exponential backoff.
     * Không throw nếu EMAIL_USER chưa được cấu hình (warning thay vì crash)
     * để không block luồng forgot-password khi dev local chưa setup SMTP.
     */
    static async sendPasswordResetEmail(
        toEmail: string,
        resetLink: string,
        userName?: string
    ): Promise<void> {
        const displayName = userName || 'Người dùng';

        // Dev mode: Nếu chưa cấu hình email, log thay vì crash
        if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS ||
            process.env.EMAIL_USER === 'your_gmail@gmail.com') {
            console.warn('⚠️  [EmailService] EMAIL chưa cấu hình — DEV MODE: in link ra console thay vì gửi email thật.');
            console.warn(`🔗 [DEV] Reset link cho ${toEmail}: ${resetLink}`);
            return;
        }

        await sendWithRetry({
            to: toEmail,
            subject: '🔐 Đặt lại mật khẩu MediChain',
            html: buildPasswordResetEmail(resetLink, displayName),
        });
    }

    /**
     * Kiểm tra kết nối SMTP — gọi khi server khởi động.
     * Pattern: Fail-fast detection thay vì phát hiện lỗi lúc user đang dùng.
     */
    static async verifyConnection(): Promise<boolean> {
        if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
            console.warn('⚠️  [EmailService] EMAIL_USER/EMAIL_PASS chưa cấu hình — Email service bị tắt.');
            return false;
        }

        try {
            const transporter = getTransporter();
            await transporter.verify();
            console.log('✅ [EmailService] SMTP kết nối thành công →', process.env.EMAIL_USER);
            return true;
        } catch (error: any) {
            console.error('❌ [EmailService] SMTP kết nối thất bại:', {
                user: process.env.EMAIL_USER,
                host: process.env.EMAIL_HOST || 'smtp.gmail.com',
                error: error.message,
                hint: 'Kiểm tra EMAIL_PASS là App Password (không phải mật khẩu Gmail thường). ' +
                      'Xem: https://myaccount.google.com/apppasswords',
            });
            return false;
        }
    }
}

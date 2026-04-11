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
        port: Number(process.env.EMAIL_PORT) || 465,
        secure: true,           // SSL/TLS cho port 465
        auth: { user, pass },
        connectionTimeout: 10000, // 10 giây fail-fast nếu không kết nối được
        greetingTimeout: 5000,
        socketTimeout: 10000,
        pool: true,             
        maxConnections: 5,      
        maxMessages: 100,       
        rateDelta: 1000,        
        rateLimit: 5,           
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

    // Nếu cấu hình RESEND_API_KEY, dùng HTTP API (Để xuyên thủng tường lửa mạng Render)
    if (process.env.RESEND_API_KEY) {
        return sendViaResendAPI(payload);
    }

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

            console.log(`✅ [EmailService/SMTP] Gửi email thành công`, {
                to: payload.to,
                attempt,
            });

            return; // Thành công → thoát vòng lặp

        } catch (error: any) {
            const isLastAttempt = attempt === maxRetries;
            console.error(`❌ [EmailService/SMTP] Lần thử ${attempt}/${maxRetries} thất bại. Error: ${error.message}`);

            if (isLastAttempt) {
                throw new Error(`Email gửi thất bại sau ${maxRetries} lần thử. Lỗi cuối: ${error.message}`);
            }

            const delayMs = Math.pow(2, attempt - 1) * 1000;
            await new Promise(resolve => setTimeout(resolve, delayMs));
        }
    }
}

// Hàm gửi thư qua Giao thức HTTP (API của Resend) thay vì SMTP port 465
async function sendViaResendAPI(payload: EmailPayload): Promise<void> {
    const resendApiKey = process.env.RESEND_API_KEY!;
    // Resend dev testing framework: chỉ gửi được cho email của lập trình viên nếu chưa gắn tên miền
    const from = 'onboarding@resend.dev'; 
    
    console.log('🚀 [EmailService] Đang dùng RESEND HTTP API (Xuyên tường lửa)...');
    
    try {
        const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${resendApiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                from: `MediChain <${from}>`,
                to: [payload.to],
                subject: payload.subject,
                html: payload.html
            })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'Lỗi từ Resend API');
        }

        console.log(`✅ [EmailService/Resend] Gửi email thành công tới ${payload.to}`, data);
    } catch (error: any) {
        console.error(`❌ [EmailService/Resend] Gửi thất bại: ${error.message}`);
        throw error;
    }
}

// ─── Email Templates ──────────────────────────────────────────────────────────
// Tách template ra riêng để dễ maintain và test.

function buildPasswordResetEmail(resetLink: string, appLink: string, displayName: string): string {
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
                Hãy chọn một trong hai cách dưới đây để tiếp tục:
              </p>
              
              <!-- Nút mở trên Điện thoại -->
              <div style="text-align:center;margin:20px 0 16px 0;">
                <a href="${appLink}"
                   style="display:inline-block;background:#0F766E;color:#ffffff;text-decoration:none;
                          padding:14px 36px;border-radius:12px;font-size:15px;font-weight:700;
                          letter-spacing:0.2px;width:240px;">
                  📱 Mở trên App MediChain
                </a>
              </div>
              
              <!-- Nút mở trên Web -->
              <div style="text-align:center;margin:0 0 32px 0;">
                <a href="${resetLink}"
                   style="display:inline-block;background:#ffffff;color:#0F766E;text-decoration:none;
                          padding:12px 34px;border-radius:12px;font-size:14px;font-weight:600;
                          border: 2px solid #0F766E;width:240px;">
                  🌐 Mở bằng Trình Duyệt
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
        appLink: string,
        userName?: string
    ): Promise<void> {
        const displayName = userName || 'Người dùng';

        // Dev mode: Nếu chưa cấu hình email, log thay vì crash
        if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS ||
            process.env.EMAIL_USER === 'your_gmail@gmail.com') {
            console.warn('⚠️  [EmailService] EMAIL chưa cấu hình — DEV MODE: in link ra console thay vì gửi email thật.');
            console.warn(`🔗 [DEV] Web Reset link cho ${toEmail}: ${resetLink}`);
            console.warn(`📱 [DEV] App Reset link cho ${toEmail}: ${appLink}`);
            return;
        }

        await sendWithRetry({
            to: toEmail,
            subject: '🔐 Đặt lại mật khẩu MediChain',
            html: buildPasswordResetEmail(resetLink, appLink, displayName),
        });
    }

    /**
     * Kiểm tra kết nối SMTP — gọi khi server khởi động.
     * Pattern: Fail-fast detection thay vì phát hiện lỗi lúc user đang dùng.
     */
    static async verifyConnection(): Promise<boolean> {
        // Ưu tiên 1: Đã cấu hình Resend API => Bỏ qua kiểm tra SMTP lỗi thời
        if (process.env.RESEND_API_KEY) {
            console.log('✅ [EmailService] Chế độ RESEND API HTTP được bật (An toàn, Xuyên tường lửa).');
            return true;
        }

        // Ưu tiên 2: Không có Resend thì mới kiểm tra SMTP
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
                hint: 'Lưu ý: Tường lửa của Server (Render/DigitalOcean) ĐANG CHẶN CỔNG GỬI MAIL. Hãy dùng RESEND_API_KEY để thay thế!',
            });
            return false;
        }
    }
}

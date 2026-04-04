import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: Number(process.env.EMAIL_PORT) || 587,
    secure: false,
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

export class EmailService {
    static async sendPasswordResetEmail(
        toEmail: string,
        resetLink: string,
        userName?: string
    ): Promise<void> {
        const displayName = userName || 'Người dùng';

        const html = `
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

        await transporter.sendMail({
            from: `"MediChain" <${process.env.EMAIL_FROM || process.env.EMAIL_USER}>`,
            to: toEmail,
            subject: '🔐 Đặt lại mật khẩu MediChain',
            html,
        });
    }
}

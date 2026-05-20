# 🏥 MediChain

> **Nền tảng quản lý sức khỏe cá nhân tích hợp AI** — Kết nối bệnh nhân, bác sĩ và quản trị viên trong một hệ sinh thái y tế thống nhất.

[![Flutter](https://img.shields.io/badge/Flutter-3.10-blue?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20-green?logo=node.js)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue?logo=typescript)](https://typescriptlang.org)
[![Prisma](https://img.shields.io/badge/Prisma-ORM-2D3748?logo=prisma)](https://prisma.io)
[![PayOS](https://img.shields.io/badge/PayOS-Payment-orange)](https://payos.vn)

---

## 📋 Mục lục

- [Tổng quan](#-tổng-quan)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Tính năng chính](#-tính-năng-chính)
- [Tech Stack](#-tech-stack)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Cài đặt & Chạy](#-cài-đặt--chạy)
- [Biến môi trường](#-biến-môi-trường)
- [API Overview](#-api-overview)
- [Luồng nghiệp vụ chính](#-luồng-nghiệp-vụ-chính)
- [Phân quyền](#-phân-quyền)
- [Deploy](#-deploy)

---

## 🎯 Tổng quan

MediChain là ứng dụng mobile y tế đa vai trò, cho phép:

| Vai trò | Chức năng |
|---------|-----------|
| **Bệnh nhân (USER)** | Đặt lịch hẹn, thanh toán, chat AI, theo dõi sức khỏe, xem kết quả khám |
| **Bác sĩ (DOCTOR)** | Quản lý lịch hẹn, ghi kết quả khám, xem hồ sơ bệnh nhân |
| **Quản trị viên (ADMIN)** | Quản lý người dùng, phí khám, báo cáo tài chính, cấu hình hệ thống |

---

## 🏗 Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ Patient  │  │  Doctor  │  │  Admin   │  │  AI Chatbot  │  │
│  │  Portal  │  │  Portal  │  │  Portal  │  │   (Dr.AI)    │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘  │
│       │              │              │                │           │
│  ┌────▼──────────────▼──────────────▼────────────────▼──────┐  │
│  │                  BLoC State Management                    │  │
│  │         (flutter_bloc + GetIt DI + go_router)             │  │
│  └────────────────────────┬──────────────────────────────────┘  │
└───────────────────────────┼─────────────────────────────────────┘
                            │ HTTPS + JWT
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Express.js Backend (Node.js 20)                │
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Auth Routes │  │ User Routes  │  │   AI Routes          │  │
│  │  (JWT/bcrypt)│  │ (Dashboard, │  │  (Chat, Consult,     │  │
│  │             │  │  Records,   │  │   Recommendation)     │  │
│  └─────────────┘  │  Medicines) │  └──────────────────────┘  │
│                    └──────────────┘                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Payment     │  │ Admin Routes │  │  Notification Routes  │  │
│  │  (PayOS)    │  │ (Stats, Fee, │  │  (In-app push)        │  │
│  │  Webhook    │  │  Users, Logs)│  └──────────────────────┘  │
│  └─────────────┘  └──────────────┘                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Prisma ORM + PostgreSQL (Neon)              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┴──────────────┐
              ▼                            ▼
    ┌──────────────────┐        ┌──────────────────┐
    │  Groq API        │        │  PayOS API        │
    │  (Llama 3.3 70B) │        │  (QR Payment)     │
    └──────────────────┘        └──────────────────┘
```

---

## ✨ Tính năng chính

### 🤖 AI Medical Assistant (Dr. MediAI)
- **Chat với AI**: Bác sĩ ảo Dr. MediAI (Llama 3.3 70B via Groq) tư vấn dựa trên hồ sơ sức khỏe cá nhân
- **Tư vấn thuốc**: Hệ thống Recommendation Engine chọn thuốc OTC an toàn theo ATC codes, phân tích tương tác thuốc, dị ứng
- **Safety Interception**: Phát hiện tình huống khẩn cấp (đau ngực, khó thở...) và gửi cảnh báo admin
- **Disease Predictor**: Dự đoán bệnh từ triệu chứng, inject context vào AI prompt

### 📅 Quản lý lịch hẹn
- Bệnh nhân đặt lịch hẹn với mô tả triệu chứng
- Bác sĩ xác nhận, khám, ghi kết quả (chẩn đoán, đơn thuốc)
- Timeline trạng thái: PENDING → CONFIRMED → IN_PROGRESS → COMPLETED
- QR Code check-in tại phòng khám
- Thông báo push (24h và 1h trước lịch hẹn)

### 💳 Thanh toán tích hợp (PayOS)
- **In-App WebView**: Không rời khỏi app khi thanh toán
- QR VietQR + ATM + Visa/Mastercard
- Webhook xử lý kết quả thanh toán từ PayOS
- Phí khám cấu hình động bởi Admin (đồng bộ tức thì)
- Deep-link `medichain://payment/return` để xử lý callback

### 📊 Theo dõi sức khỏe
- Ghi chỉ số: huyết áp, nhịp tim, cân nặng, đường huyết...
- Biểu đồ xu hướng theo thời gian (fl_chart)
- Lịch sử bệnh án và đơn thuốc
- Quản lý thuốc đang dùng với lịch nhắc nhở

### 🔒 Bảo mật
- JWT Authentication (access token 7 ngày)
- Rate limiting: Auth 20 req/15min, API 120 req/min
- Helmet.js: 15 HTTP security headers
- Local Auth (Face ID / Fingerprint) để mở app
- CORS whitelist theo `FRONTEND_URL`
- Audit trail: log mọi API call (ai, lúc nào, từ IP nào)

### 🔗 Chia sẻ hồ sơ
- Tạo QR code chia sẻ hồ sơ y tế với bác sĩ/bệnh viện khác
- Token-based access có thời hạn

---

## 🛠 Tech Stack

### Backend
| Công nghệ | Phiên bản | Mục đích |
|-----------|-----------|---------|
| Node.js | 20 LTS | Runtime |
| Express.js | 4.x | Web framework |
| TypeScript | 5.x | Type safety |
| Prisma | 5.x | ORM |
| PostgreSQL | (Neon) | Database production |
| Pino | latest | Structured logging |
| bcryptjs | 2.x | Password hashing |
| jsonwebtoken | 9.x | JWT |
| node-cron | latest | Scheduled jobs |
| Groq SDK | latest | AI (Llama 3.3 70B) |
| PayOS | latest | Payment gateway |
| Nodemailer | latest | Email notifications |

### Mobile (Flutter)
| Package | Version | Mục đích |
|---------|---------|---------|
| Flutter | SDK 3.10 | Cross-platform mobile |
| flutter_bloc | 9.1.1 | State management |
| go_router | 17.2.3 | Navigation |
| get_it + injectable | 9.x | Dependency injection |
| dio | 5.9.2 | HTTP client |
| flutter_secure_storage | 10.x | Lưu JWT an toàn |
| webview_flutter | 4.10.0 | In-app PayOS checkout |
| hive | 2.2.3 | Local cache |
| fl_chart | 1.2.0 | Biểu đồ sức khỏe |
| easy_localization | 3.0.8 | i18n (vi/en) |
| local_auth | 3.0.1 | Biometric auth |
| qr_flutter | 4.1.0 | QR code generation |
| flutter_local_notifications | 18.x | Push notifications |

---

## 📁 Cấu trúc dự án

```
medi_chain/
├── backend/                    # Express.js API Server
│   ├── src/
│   │   ├── index.ts            # Entry point, middleware setup
│   │   ├── controllers/        # Request handlers (15 controllers)
│   │   │   ├── auth.controller.ts
│   │   │   ├── payment.controller.ts
│   │   │   ├── ai.controller.ts
│   │   │   ├── admin-payments.controller.ts
│   │   │   └── ...
│   │   ├── services/           # Business logic
│   │   │   ├── ai.service.ts         # Dr. MediAI + Groq integration
│   │   │   ├── payment.service.ts    # PayOS integration
│   │   │   ├── medical-safety.service.ts  # Drug safety checks
│   │   │   ├── clinical-rules.engine.ts   # Clinical decision rules
│   │   │   ├── disease-predictor.service.ts
│   │   │   └── ...
│   │   ├── routes/             # Route definitions
│   │   ├── middlewares/        # auth, audit, rate-limit
│   │   ├── config/             # Prisma, env
│   │   └── cron/               # Scheduled jobs (nhắc lịch hẹn)
│   └── prisma/
│       └── schema.prisma       # Database schema
│
├── frontend-mobile/            # Flutter App
│   └── lib/
│       ├── main.dart           # App entry, DI setup
│       ├── core/
│       │   ├── di/             # GetIt injection
│       │   ├── network/        # Dio + interceptors
│       │   ├── theme/          # Dark/Light theme
│       │   └── constants/
│       ├── data/
│       │   ├── models/         # JSON serializable models
│       │   └── repositories/   # API calls abstraction
│       ├── logic/              # BLoC state management
│       │   ├── auth/
│       │   ├── payment/
│       │   ├── appointment/
│       │   ├── ai/
│       │   └── ...
│       └── presentation/
│           ├── screens/        # UI screens
│           │   ├── dashboard/
│           │   ├── appointment/
│           │   ├── payment/
│           │   ├── admin/      # Admin portal
│           │   ├── clinic/     # Doctor portal
│           │   └── ai/
│           ├── widgets/        # Shared widgets
│           └── routes/         # go_router configuration
│
└── docs/                       # Architecture docs, ADRs
```

---

## 🚀 Cài đặt & Chạy

### Yêu cầu
- Node.js 20+
- Flutter SDK 3.10+
- PostgreSQL (hoặc Neon account)
- Android Studio / Xcode (cho emulator/simulator)

### Backend

```bash
cd backend

# Cài dependencies
npm install

# Cấu hình env (xem mục Biến môi trường)
cp ../.env.production.example .env

# Migrate database
npx prisma migrate dev

# Generate Prisma client
npx prisma generate

# Chạy dev server (port 5000)
npm run dev

# Build production
npm run build
npm start
```

### Mobile

```bash
cd frontend-mobile

# Cài dependencies
flutter pub get

# Generate code (models, DI)
dart run build_runner build --delete-conflicting-outputs

# Chạy trên emulator/device
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

> **Lưu ý:** URL backend mặc định cho Android Emulator: `http://10.0.2.2:5000`  
> Đổi trong `lib/core/constants/app_constants.dart`

---

## 🔑 Biến môi trường

Tạo file `.env` trong thư mục `backend/`:

```env
# ─── Database ───────────────────────────────────────
DATABASE_URL="postgresql://user:password@host/medichain?sslmode=require"

# ─── Authentication ─────────────────────────────────
JWT_SECRET="your-super-secret-jwt-key-min-32-chars"

# ─── AI Services ────────────────────────────────────
GROQ_API_KEY="gsk_..."               # Groq API (Llama 3.3 70B)
GEMINI_API_KEY="AIza..."             # Google Gemini (vector search, optional)

# ─── Payment (PayOS) ────────────────────────────────
PAYOS_CLIENT_ID="your-client-id"
PAYOS_API_KEY="your-api-key"
PAYOS_CHECKSUM_KEY="your-checksum-key"
PAYOS_RETURN_URL="medichain://payment/return"
PAYOS_CANCEL_URL="medichain://payment/cancel"

# ─── Email ──────────────────────────────────────────
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# ─── Server ─────────────────────────────────────────
PORT=5000
NODE_ENV="development"
FRONTEND_URL="http://localhost:3000,https://your-app.vercel.app"
```

---

## 📡 API Overview

Base URL: `https://medichain-backend-v4bo.onrender.com/api`

### Auth
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/auth/register` | Đăng ký tài khoản |
| POST | `/auth/login` | Đăng nhập, nhận JWT |
| POST | `/auth/refresh` | Refresh token |

### Patient APIs (cần JWT)
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/user/dashboard` | Dashboard tổng quan |
| GET/POST | `/user/appointments` | Lịch hẹn |
| GET/POST | `/user/records` | Bệnh án |
| GET/POST | `/user/medicines` | Thuốc đang dùng |
| GET/POST | `/user/metrics` | Chỉ số sức khỏe |

### Payment
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/payment/create-order` | Tạo đơn PayOS |
| GET | `/payment/settings/fee` | Lấy phí khám |
| GET | `/payment/status/:orderCode` | Kiểm tra trạng thái |
| POST | `/payment/webhook` | Webhook từ PayOS (public) |

### AI
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/ai/chat` | Chat với Dr. MediAI |
| POST | `/ai/consult` | Tư vấn thuốc OTC |
| GET | `/ai/conversations` | Lịch sử hội thoại |

### Admin (cần role ADMIN)
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/admin/stats` | Thống kê tổng quan |
| GET | `/admin/payments` | Doanh thu, giao dịch |
| PUT | `/admin/payments/fee` | Cập nhật phí khám |
| GET | `/admin/users` | Quản lý người dùng |
| GET | `/admin/access-logs` | Audit logs |

---

## 🔄 Luồng nghiệp vụ chính

### Luồng thanh toán (PayOS In-App)

```
Bệnh nhân bấm "Thanh toán"
    ↓
App gọi GET /payment/settings/fee
    → Backend đọc ClinicSetting.consultationFee
    → Hiển thị phí chính xác trên màn hình
    ↓
Bệnh nhân xác nhận → App gọi POST /payment/create-order
    → Backend đọc ClinicSetting.consultationFee (cùng nguồn)
    → Tạo lệnh PayOS với số tiền đúng
    → Trả về { checkoutUrl, orderCode, amount }
    ↓
App mở WebView với checkoutUrl
    → NavigationDelegate theo dõi URL changes
    → Khi redirect về medichain://payment/return
    → App đóng WebView, dispatch PaymentStatusCheckRequested
    ↓
Backend nhận webhook từ PayOS
    → Verify HMAC-SHA256 signature
    → Cập nhật paymentStatus = 'PAID'
    → Gửi notification đến bệnh nhân
```

### Luồng AI Chat

```
User gửi tin nhắn
    ↓
Backend lấy MedicalContext (profile, thuốc, bệnh án, chỉ số)
    ↓
Safety Interception (background, không block response):
    → LLM triage xem có emergency không
    → Nếu emergency → queue vào Admin review
    ↓
Gọi Groq API (Llama 3.3 70B, timeout 25s)
    → System prompt chứa đầy đủ hồ sơ bệnh nhân
    → AI trả lời cá nhân hóa
    ↓
Lưu conversation + tracking (tokens, latency, model)
```

### Luồng tư vấn thuốc

```
User mô tả triệu chứng
    ↓
Safety Check (cứng, không bypass được):
    → Kiểm tra dị ứng thuốc
    → Kiểm tra tương tác với thuốc đang dùng
    → Kiểm tra chống chỉ định (mang thai, bệnh nền)
    → Nếu critical → Chặn, trả cảnh báo ngay (không gọi AI)
    ↓
Disease Predictor (3s timeout, fail-open):
    → Dự đoán bệnh từ triệu chứng
    → Inject vào AI context
    ↓
Recommendation Engine:
    → Chọn thuốc OTC theo ATC codes
    → Scoring theo độ phù hợp + safety profile
    ↓
AI (Llama 3.3 70B):
    → Chỉ GIẢI THÍCH thuốc Engine đã chọn
    → Tính liều theo cân nặng/tuổi
    → Không được tự chọn thuốc thêm
```

---

## 👥 Phân quyền

```
ADMIN
  ├── Tất cả quyền của DOCTOR
  ├── Quản lý người dùng (ban, đổi role)
  ├── Cấu hình phí khám (ClinicSetting)
  ├── Xem audit logs, access logs
  ├── Thống kê doanh thu
  └── Quản lý Clinical Rules (AI safety rules)

DOCTOR
  ├── Xem danh sách lịch hẹn được phân công
  ├── Xác nhận / Hoàn thành lịch hẹn
  ├── Ghi kết quả khám (chẩn đoán, đơn thuốc)
  ├── Xem hồ sơ bệnh nhân
  └── Gửi thông báo cho bệnh nhân

USER (Bệnh nhân)
  ├── Dashboard sức khỏe cá nhân
  ├── Đặt và quản lý lịch hẹn
  ├── Thanh toán phí khám (PayOS)
  ├── Chat với AI Dr. MediAI
  ├── Tư vấn thuốc OTC
  ├── Ghi chỉ số sức khỏe
  ├── Quản lý bệnh án, thuốc
  └── Chia sẻ hồ sơ bằng QR
```

---

## ☁️ Deploy

### Backend (Render.com)
```bash
# Build command
npm run build

# Start command  
npm start

# Root directory: backend/
```

> **Lưu ý Cold Start**: Backend trên Render free tier có thể mất ~30s để khởi động sau thời gian idle.  
> App mobile đã xử lý với timeout 55s và UI "server đang khởi động..." thân thiện.

### Mobile
- **Android**: `flutter build apk --release` hoặc `flutter build appbundle`
- **iOS**: `flutter build ios --release` (cần Apple Developer account)
- **Testing**: `flutter run --release` để test performance thực tế (tránh WebView lag trên debug mode)

---

## 📝 Ghi chú kỹ thuật

### Phí khám — Single Source of Truth
Tất cả đọc/ghi phí khám đều qua **`ClinicSetting.consultationFee`**:
- Admin cập nhật → `PUT /admin/payments/fee` → `ClinicSetting`
- Patient xem phí → `GET /payment/settings/fee` → `ClinicSetting`
- Backend tạo đơn PayOS → `PaymentService.createOrder()` → `ClinicSetting`

### Response format chuẩn
```json
{
  "success": true | false,
  "data": { ... },
  "message": "string (chỉ khi lỗi hoặc thông báo)",
  "errorCode": "ERROR_CODE (optional)"
}
```

### Code generation (Mobile)
Sau khi thay đổi models hoặc DI:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🤝 Contributing

Xem [AGENTS.md](./AGENTS.md) để biết quy trình làm việc với AI agent, hard limits, templates, và memory system.

Xem [CHANGELOG.md](./CHANGELOG.md) để biết lịch sử thay đổi.

---

<div align="center">
  <sub>Built with ❤️ by MediChain Team · 2026</sub>
</div>

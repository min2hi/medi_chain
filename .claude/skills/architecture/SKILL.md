# SKILL: MediChain Architecture Overview

> Đọc file này trước mọi task. Nó cung cấp bản đồ kiến trúc đầy đủ của dự án.

## Stack Công Nghệ

| Layer | Technology | Port |
|-------|-----------|------|
| Backend API | Express.js + TypeScript | 5000 |
| Frontend Web | Next.js 14 (App Router) | 3000 |
| Frontend Mobile | Flutter (Dart) + BLoC | N/A |
| Database | PostgreSQL + Prisma ORM | 5432 |
| Deployment | Docker + Nginx (VPS) | 80/443 |
| AI Engine | Google Gemini API | External |
| Email | Resend API | External |

## Sơ Đồ Kiến Trúc 3 Tầng

```
[Flutter Mobile]  ←→  [Next.js Web]
        ↓                    ↓
    (REST API calls via HTTPS)
        ↓                    ↓
    [Nginx Reverse Proxy :80/:443]
              ↓
    [Express Backend :5000]
         ↓          ↓
    [PostgreSQL]  [Gemini API]
```

## Các Service Chính (Backend)

| Service | File | Chức năng |
|---------|------|-----------|
| `AuthService` | `auth.service.ts` | Register, Login, JWT, Password Reset |
| `AiService` | `ai.service.ts` | Chat AI, Conversation management |
| `MedicalService` | `medical.service.ts` | Records, Medicines, Appointments, Metrics |
| `EmbeddingService` | `embedding.service.ts` | Vector embeddings cho Gemini |
| `MedicalSafetyService` | `medical-safety.service.ts` | Kiểm tra an toàn thuốc |
| `DrugEnrichmentService` | `drug-enrichment.service.ts` | Làm giàu dữ liệu thuốc |
| `EmailService` | `email.service.ts` | Gửi email qua Resend |
| `SharingService` | `sharing.service.ts` | Chia sẻ hồ sơ y tế |

## API Routes Map

```
/api/auth        → auth.routes.ts       → AuthController
/api/user        → user.routes.ts       → MedicalController + UserController
/api/ai          → ai.routes.ts         → AiController
/api/recommendation → recommendation.routes.ts → RecommendationController
/api/sharing     → sharing.routes.ts    → SharingController
```

## Luồng AI Chat (End-to-End)

```
[Flutter/Web] gửi message
    → POST /api/ai/chat
    → authMiddleware (verify JWT)
    → AiController.chat()
    → AiService.sendMessage()
        → Load conversation history từ DB
        → Safety check (MedicalSafetyService)
        → Gọi Gemini API
        → Lưu response vào DB
    → Trả về { conversationId, message }
```

## Luồng Recommendation Engine

```
[Flutter/Web] gửi triệu chứng
    → POST /api/recommendation/consult
    → RecommendationController
    → Load user profile (bệnh sử, thuốc hiện tại, chỉ số)
    → EmbeddingService (vector search DrugCandidates)
    → MedicalSafetyService (lọc tương tác thuốc)
    → Scoring & Ranking
    → Trả về { recommendedMedicines, safetyWarnings, engineStats }
```

## Environment Variables Quan Trọng

| Variable | Required | Mô tả |
|----------|----------|-------|
| `JWT_SECRET` | **CRITICAL** | Server từ chối start nếu thiếu |
| `DATABASE_URL` | **CRITICAL** | PostgreSQL connection string |
| `GEMINI_API_KEY` | WARNING | Fallback sang keyword search nếu thiếu |
| `FRONTEND_URL` | Important | CORS whitelist (comma-separated) |
| `RESEND_API_KEY` | Important | Email service |
| `JWT_EXPIRES_IN` | Optional | Default: 7d |

## Security Architecture

- **Helmet**: 15 HTTP security headers
- **Rate Limiting**: Auth routes 20 req/15min, API 120 req/min
- **CORS**: Chỉ accept origins từ `FRONTEND_URL`
- **Auth**: JWT Bearer token, validated trên mọi protected route
- **Password**: bcrypt với 12 salt rounds
- **Mobile**: Token lưu trong `flutter_secure_storage` (encrypted keychain)

## Deployment (Production)

```
VPS (Debian/Ubuntu)
├── docker-compose.prod.yml
│   ├── nginx (port 80/443)
│   ├── backend (internal :5000)
│   └── postgres (internal :5432)
└── Nginx config: /nginx/
```

> **Lưu ý**: Khi chỉnh sửa docker-compose.prod.yml, PHẢI kiểm tra với DevOps trước khi deploy.

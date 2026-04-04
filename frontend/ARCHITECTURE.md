# MediChain AI - Production Architecture

## 🎯 Kiến trúc Production-Ready

```
┌──────────────────┐
│   Frontend       │
│   (Next.js)      │
└────────┬─────────┘
         │ /api/chat + Bearer Token
         ▼
┌──────────────────┐
│  API Route       │
│  ✓ Rate Limit    │
│  ✓ Auth Check    │
│  ✓ Validation    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  AI Service      │
│  (Business logic)│
└────────┬─────────┘
         │ Bearer GROQ_API_KEY
         ▼
┌──────────────────┐
│   Groq API       │
└──────────────────┘
```

## ✅ Tính năng đã implement

### 1. **Service Layer** (`src/services/ai.service.ts`)
- ✅ Tách biệt logic AI khỏi API route
- ✅ Error handling chi tiết
- ✅ Logging request/response
- ✅ Token usage tracking
- ✅ Input validation
- ✅ Context length management

### 2. **Rate Limiting** (`src/lib/rateLimit.ts`)
- ✅ In-memory rate limiter
- ✅ 10 requests/phút mỗi IP hoặc User
- ✅ Tự động cleanup
- ✅ Response headers chuẩn
- ⚠️ Production: Nên dùng Redis

### 3. **Authentication** (`src/lib/auth.ts`)
- ✅ Lấy Bearer token từ Authorization header
- ✅ Lấy client IP từ request
- ✅ Rate limit theo user hoặc IP
- ⚠️ TODO: Verify JWT với backend

### 4. **API Route** (`src/app/api/chat/route.ts`)
- ✅ Rate limiting check
- ✅ Authentication check (optional)
- ✅ Input validation
- ✅ Comprehensive logging
- ✅ Error handling với status codes đúng
- ✅ Health check endpoint (GET)
- ✅ Response headers chuẩn

### 5. **Client Integration**
- ✅ `api.client.ts`: Gửi token tự động
- ✅ `AIChat.tsx`: Support authentication
- ✅ Handle rate limit errors

## 🔐 Bảo mật

### Environment Variables
```env
# ❌ KHÔNG BAO GIỜ dùng
NEXT_PUBLIC_GROQ_API_KEY=xxx

# ✅ Đúng cách
GROQ_API_KEY=xxx
```

### API Key Protection
- ✅ Key chỉ tồn tại trên server (process.env)
- ✅ Không bao giờ exposed ra client
- ✅ Không bao giờ log ra console

### Request Security
- ✅ Rate limiting để chống spam
- ✅ Input validation để chống injection
- ✅ Error messages không leak sensitive info

## 📊 Logging

Mỗi request được log:
```
[API Chat] New request: {
  user: 'user123' | 'anonymous',
  ip: '192.168.1.1',
  messageLength: 50,
  hasHistory: false,
  timestamp: '2026-02-11T...'
}

[AI Service] Request successful: {
  model: 'llama3-8b-8192',
  tokens: { prompt: 100, completion: 200, total: 300 },
  duration: '1234ms',
  timestamp: '2026-02-11T...'
}

[API Chat] Success: {
  user: 'user123',
  tokens: 300,
  duration: '1500ms',
  remaining: 9  // 9 requests còn lại
}
```

## 🚀 Nâng cấp tiếp theo (Optional)

### 1. Database Logging
Lưu lại mọi request vào database:
- User ID
- Message content
- AI response
- Token usage
- Cost tracking

### 2. Redis Rate Limiting
Thay in-memory bằng Redis để:
- Scale horizontally
- Persistent rate limits
- Shared across instances

### 3. JWT Verification
Verify JWT token đúng cách:
```typescript
import jwt from 'jsonwebtoken';

const decoded = jwt.verify(token, process.env.JWT_SECRET);
```

### 4. Streaming Response
Real-time streaming như ChatGPT:
```typescript
const stream = await AIService.chatStream(message);
// Return stream response
```

### 5. Cost Tracking
Track chi phí API:
```typescript
const cost = calculateCost(usage.total_tokens);
await saveCostToDatabase(userId, cost);
```

## 📝 API Documentation

### POST /api/chat

**Request:**
```json
{
  "message": "Tôi bị đau đầu",
  "conversationHistory": []  // Optional
}
```

**Headers:**
```
Authorization: Bearer <token>  // Optional nhưng recommended
Content-Type: application/json
```

**Response (Success):**
```json
{
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Đau đầu có thể do nhiều nguyên nhân..."
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 200,
    "total_tokens": 300
  },
  "model": "llama3-8b-8192",
  "created": 1234567890
}
```

**Response Headers:**
```
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 9
X-RateLimit-Reset: 1234567890000
```

**Error (Rate Limit):**
```json
{
  "error": "Too many requests",
  "message": "Vui lòng đợi 45 giây trước khi gửi tiếp.",
  "resetIn": 45
}
```

### GET /api/chat

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "service": "MediChain AI Chat",
  "version": "1.0.0",
  "timestamp": "2026-02-11T..."
}
```

## ⚙️ Configuration

### Rate Limit
Chỉnh sửa tại `src/lib/rateLimit.ts`:
```typescript
new RateLimiter(
  10,     // Max requests
  60000   // Window (ms) - 1 phút
)
```

### AI Model
Chỉnh sửa tại `src/services/ai.service.ts`:
```typescript
private static readonly MODEL = 'llama3-8b-8192';
private static readonly MAX_TOKENS = 1024;
private static readonly TEMPERATURE = 0.7;
```

## 🧪 Testing

### Test Rate Limit
```bash
# Gửi 11 requests liên tiếp
for i in {1..11}; do
  curl -X POST http://localhost:3000/api/chat \
    -H "Content-Type: application/json" \
    -d '{"message":"test"}'
done
```

### Test Health Check
```bash
curl http://localhost:3000/api/chat
```

### Test với Auth
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_token_here" \
  -d '{"message":"Tôi bị đau đầu"}'
```

## 📂 File Structure

```
frontend/src/
├── app/api/chat/
│   └── route.ts           # API endpoint chính
├── services/
│   ├── ai.service.ts      # AI business logic
│   └── api.client.ts      # Client API wrapper
├── lib/
│   ├── auth.ts            # Authentication utilities
│   └── rateLimit.ts       # Rate limiter
└── components/
    └── shared/
        └── AIChat.tsx     # Chat UI component
```

## 🎓 Best Practices Implemented

1. ✅ **Separation of Concerns**: Service layer tách biệt
2. ✅ **Error Handling**: Try-catch ở mọi layer
3. ✅ **Logging**: Chi tiết request/response
4. ✅ **Validation**: Input validation nghiêm ngặt
5. ✅ **Security**: API key protection, rate limiting
6. ✅ **Type Safety**: TypeScript strict mode
7. ✅ **Clean Code**: Comments, naming conventions
8. ✅ **Scalability**: Dễ thay đổi AI provider

## ⚠️ Security Checklist

- [x] API key không exposed ra client
- [x] Rate limiting để chống spam
- [x] Input validation để chống injection
- [x] Error messages không leak info
- [ ] JWT verification (TODO)
- [ ] CORS configuration (nếu cần)
- [ ] Request size limits
- [ ] Timeout configuration

## 💡 Notes

- **Rate Limiter**: Hiện dùng in-memory, sẽ reset khi restart server
- **Authentication**: Hiện chỉ check có token, chưa verify JWT
- **Database**: Chưa lưu conversation history
- **Monitoring**: Chỉ có console logs, chưa có proper monitoring

---

**Status**: ✅ Production-ready với những giới hạn trên
**Next Steps**: Redis, JWT verification, Database logging

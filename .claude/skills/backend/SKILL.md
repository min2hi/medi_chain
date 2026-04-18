# SKILL: Backend Development — MediChain

> Đọc file này khi làm việc với bất kỳ file nào trong `backend/src/`.

---

## ⛔ NGUYÊN TẮC DÒ MÌN — Impact Analysis (Đọc trước tiên)

**Trước khi sửa BẤT KỲ hàm/biến/class nào đã tồn tại, AI BẮT BUỘC phải:**

```
Bước 1: Tìm tất cả nơi gọi hàm đó
    → Dùng: gitnexus_impact({target: "TênHàm", direction: "upstream"})
    → Hoặc grep: Ctrl+Shift+F tìm tên hàm trong toàn bộ codebase

Bước 2: Đánh giá blast radius (vùng ảnh hưởng)
    → d=1 (WILL BREAK): Phải cập nhật ngay, KHÔNG được bỏ qua
    → d=2 (LIKELY AFFECTED): Cần test kỹ
    → d=3 (MAY NEED TESTING): Test nếu đây là critical path

Bước 3: Cập nhật TẤT CẢ các nơi bị ảnh hưởng d=1
    → Không chỉ sửa file được yêu cầu — phải cập nhật đồng bộ toàn bộ chain

Bước 4: Thông báo cho user nếu Risk = HIGH hoặc CRITICAL
    → DỪNG và giải thích trước khi tiếp tục
```

> **Tại sao điều này quan trọng:** Lỗi phổ biến nhất của AI là "sửa file A nhưng làm vỡ file B". Nguyên tắc này ép buộc AI hiểu toàn bộ chuỗi phụ thuộc trước khi gõ một chữ.

```typescript
// ✅ ĐÚNG — Sửa AuthService.login() sau khi đã kiểm tra impact
// gitnexus_impact({target: "login", direction: "upstream"}) → tìm thấy:
//   d=1: AuthController.login() → đã cập nhật signature
//   d=2: auth.routes.ts → đã kiểm tra, không ảnh hưởng
// → An toàn để tiến hành

// ❌ SAI — Đổi tên tham số hàm mà không kiểm tra ai đang gọi
async login(credentials: LoginDto) → async login(payload: LoginDto)
// Điều này có thể phá vỡ AuthController đang gọi login(credentials)
```

---

## Pattern Bắt Buộc: Controller → Service → Prisma

```typescript
// ✅ ĐÚNG — Controller chỉ xử lý HTTP, delegate logic sang Service
export const login = async (req: Request, res: Response) => {
    const result = await AuthService.login(req.body);
    res.json({ success: true, data: result });
};

// ❌ SAI — KHÔNG viết business logic trong Controller
export const login = async (req: Request, res: Response) => {
    const user = await prisma.user.findUnique(...); // ← Sai chỗ
    const token = jwt.sign(...);                    // ← Sai chỗ
};
```

## Cấu Trúc File Bắt Buộc

```
backend/src/
├── controllers/   ← HTTP handlers only (req/res) — KHÔNG có business logic
├── services/      ← Business logic, DB queries, external API calls
├── routes/        ← Route definitions + middleware assignment
├── middlewares/   ← Auth, validation, error handling
├── config/        ← prisma.ts, env validation
├── cron/          ← Scheduled jobs
└── index.ts       ← App entry point (KHÔNG sửa nếu không cần thiết)
```

## Prisma Rules

```typescript
// ✅ ĐÚNG — Dùng Prisma ORM
const user = await prisma.user.findUnique({ where: { email } });

// ✅ ĐÚNG — Atomic transaction khi cần
await prisma.$transaction([
    prisma.user.update(...),
    prisma.passwordResetToken.update(...),
]);

// ❌ SAI — KHÔNG viết raw SQL thô
await prisma.$queryRaw`SELECT * FROM users WHERE email = ${email}`;
// (chỉ dùng $queryRaw khi Prisma ORM thực sự không đáp ứng được)

// ❌ SAI — KHÔNG sửa schema.prisma mà không chạy migrate
// Mọi thay đổi schema phải kèm: npx prisma migrate dev --name <tên>
```

## Error Handling Pattern

```typescript
// ✅ ĐÚNG — Service throw Error, Controller catch và format response
// Trong Service:
if (!user) throw new Error('User không tồn tại');

// Trong Controller:
try {
    const result = await SomeService.doSomething(req.body);
    res.json({ success: true, data: result });
} catch (error) {
    const message = error instanceof Error ? error.message : 'Lỗi không xác định';
    res.status(400).json({ success: false, message });
}
```

## Authentication Middleware

```typescript
// Protected routes PHẢI dùng authMiddleware
router.get('/profile', authMiddleware, UserController.getProfile);

// authMiddleware verify JWT và gắn user vào req.user
// Truy cập: req.user.id, req.user.email, req.user.role
```

## Response Format Chuẩn

```typescript
// Success
{ success: true, data: { ... } }

// Error
{ success: false, message: "Mô tả lỗi", errorCode?: "CODE" }
```

## Naming Conventions

| Loại file | Format | Ví dụ |
|-----------|--------|-------|
| Service | `*.service.ts` | `auth.service.ts` |
| Controller | `*.controller.ts` | `auth.controller.ts` |
| Route | `*.routes.ts` | `auth.routes.ts` |
| Middleware | `*.middleware.ts` | `auth.middleware.ts` |

## Always Do ✅

- Luôn dùng `static async` methods trong Service class
- Luôn validate input ở đầu Service method trước khi query DB
- Dùng `select` trong Prisma query để chỉ lấy fields cần thiết (tránh leak password)
- Background tasks (email, notifications): dùng `.catch(err => console.error(err))` — không `await`
- Kiểm tra `process.env.VARIABLE!` với non-null assertion CHỈ khi đã có fail-fast check ở `index.ts`

## Never Do ❌

- KHÔNG tạo file ngoài cấu trúc `src/` trừ khi có lý do rõ ràng
- KHÔNG commit file trong `src/generated/` (auto-generated bởi Prisma)
- KHÔNG để `console.log` debug trong production code — dùng `console.error` cho lỗi thật
- KHÔNG return `password` field trong bất kỳ response nào — dùng `select` để exclude
- KHÔNG gọi Gemini API trực tiếp từ Controller — phải qua Service
- KHÔNG hardcode URLs hay secrets — dùng `process.env`
- KHÔNG sửa hàm có sẵn mà chưa chạy Impact Analysis

---

## ✅ SELF-CHECK — Trước Khi Chốt Code

AI phải tự đọc qua checklist này sau khi viết xong, trước khi gửi code cho user:

```
SECURITY
[ ] Password/secret không bị trả về trong response (dùng `select` để exclude)
[ ] Không có hardcoded secret/API key nào trong code
[ ] JWT token không bị ghi vào console.log hay log file
[ ] Input từ user đã được validate trước khi truyền vào DB query

ERROR HANDLING
[ ] Mọi Controller method đều có try/catch bọc bên ngoài
[ ] Service throw Error có message rõ ràng (không phải generic 'Something went wrong')
[ ] Null/Undefined đã được xử lý (kiểm tra `if (!user)` trước khi dùng `user.email`)
[ ] Async/Await đúng — không bỏ sót `await` trước async calls

ARCHITECTURE
[ ] Business logic nằm trong Service, KHÔNG nằm trong Controller
[ ] Response format đúng chuẩn: { success: true, data: ... } hoặc { success: false, message: ... }
[ ] Protected route đã có authMiddleware
[ ] Prisma query có `select` để chỉ lấy fields cần thiết

IMPACT
[ ] Đã chạy Impact Analysis trước khi sửa hàm cũ
[ ] Tất cả callers d=1 đã được cập nhật đồng bộ
[ ] Không có breaking changes ngầm (thay đổi tham số, return type)

CLEAN CODE
[ ] Không có console.log debug còn sót
[ ] Không có commented-out code block lớn
[ ] Không có import unused
[ ] File nằm đúng thư mục trong cấu trúc src/
```

> 💡 **Template tham khảo**: Khi tạo Controller/Service mới, copy nguyên văn từ `.claude/templates/`. Xem danh sách templates tại `AGENTS.md`.

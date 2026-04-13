# SKILL: Backend Development — MediChain

> Đọc file này khi làm việc với bất kỳ file nào trong `backend/src/`.

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

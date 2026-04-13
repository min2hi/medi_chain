# SKILL: Testing & Clean Code Rules — MediChain

> ⚠️ Đây là skill file quan trọng nhất về hygiene code. Đọc trước khi tạo BẤT KỲ file test/mock nào.

---

## QUY TẮC VÀNG: Mock Data & Test Files

### Vòng đời của file test

```
Tạo file test → Chạy test → Xóa ngay lập tức
     ↑                              ↓
     └──────── KHÔNG BAO GIỜ ───────┘
               commit file test
```

### Nơi được phép tạo file tạm thời

```
✅ .claude/scratch/          ← File tạm thời của AI (an toàn, không bị track)
✅ /tmp/                     ← System temp (bị xóa sau restart)
❌ backend/src/scripts/      ← CHỈ khi file đó là permanent utility
❌ Bất kỳ nơi nào trong src/ ← KHÔNG tạo file test ở đây
```

### Naming Convention Bắt Buộc cho File Test/Script

```
test-*.ts     ← Backend test script (đã gitignore)
test-*.js     ← JavaScript test (đã gitignore)
test-*.dart   ← Flutter test (chỉ trong test/ folder)
seed-*.js     ← Seed data script (chạy xong XÓA ngay)
update-*.ts   ← One-off update script (chạy xong XÓA ngay)
```

> File đặt tên đúng pattern trên đã được `.gitignore` — nhưng vẫn phải XÓA sau khi dùng xong. Không để rác trên filesystem.

---

## CHECKLIST TRƯỚC KHI COMMIT

AI phải tự kiểm tra danh sách này trước khi đề xuất `git commit`:

```
[ ] Không có file test-*.ts, test-*.js nào còn sót lại
[ ] Không có file seed-*.js, update-*.ts nào còn sót lại
[ ] Không có console.log() debug nào trong production code
[ ] Không có TODO comment nào chưa giải quyết (hoặc đã tạo issue)
[ ] Không có hardcoded secrets, API keys, passwords
[ ] Không có commented-out code blocks lớn
[ ] Mọi mock/fixture data đã được xóa hoặc move vào test/ folder đúng chỗ
```

---

## CLEAN CODE RULES

### Không để lại "digital litter"

```typescript
// ❌ SAI — console.log debug
console.log('DEBUG user:', user);
console.log('test response:', JSON.stringify(response));

// ✅ ĐÚNG — Log có ý nghĩa trong production
console.error('❌ Database connection failed:', error);
console.warn('⚠️  GEMINI_API_KEY chưa được set');
```

```typescript
// ❌ SAI — Commented-out code không có lý do
// const oldFunction = async () => { ... };
// await prisma.user.findMany(); // deprecated

// ✅ ĐÚNG — Nếu cần giữ, phải có comment giải thích rõ ràng
// NOTE: Giữ lại để fallback khi Gemini API down (xem issue #42)
```

### Import phải sạch

```typescript
// ❌ SAI — Import không dùng
import { bcrypt, jwt, crypto, fs, path } from '...';

// ✅ ĐÚNG — Chỉ import những gì thực sự dùng
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
```

---

## FLUTTER TESTING RULES

```
frontend-mobile/
└── test/
    ├── unit/        ← Unit tests (BLoC, Repository, Service)
    ├── widget/      ← Widget tests
    └── integration/ ← E2E tests
```

```dart
// ✅ ĐÚNG — Test file nằm đúng thư mục test/
// test/unit/auth_bloc_test.dart

// ❌ SAI — KHÔNG tạo test file trong lib/
// lib/logic/auth/auth_bloc_test.dart ← Sai vị trí
```

---

## MOCK DATA TRONG TEST

```typescript
// ✅ ĐÚNG — Mock data chỉ tồn tại trong scope test
it('should return user', () => {
    const mockUser = { id: '1', email: 'test@test.com' }; // ← Tồn tại trong test function
    expect(AuthService.formatUser(mockUser)).toBeDefined();
});

// ❌ SAI — Mock data file tồn tại độc lập ngoài test
// mock-users.json       ← Không được tồn tại ngoài test/
// seed-production.js    ← Không được commit
```

---

## KHI AI TẠO FILE TEST

AI (Antigravity) phải:
1. **Thông báo rõ**: "Tôi sẽ tạo file test tạm thời — sẽ xóa sau khi test xong"
2. **Đặt tên đúng**: `test-*.ts` hoặc trong `.claude/scratch/`
3. **Tự động xóa** sau khi test hoàn tất và kết quả đã được ghi nhận
4. **KHÔNG đề xuất commit** file test vào repository

---

## PHÁT HIỆN FILE THỪA

Để kiểm tra xem có file thừa không:

```bash
# Tìm file test/script có thể còn sót
Get-ChildItem -Recurse -Filter "test-*.ts" | Where-Object { $_.FullName -notmatch "\.test\." }
Get-ChildItem -Recurse -Filter "seed-*.js"
Get-ChildItem -Recurse -Filter "update-*.ts"
```

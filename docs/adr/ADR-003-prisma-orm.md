# ADR-003: Chọn Prisma ORM thay vì raw pg / TypeORM / Drizzle

**Ngày:** 2026-04-01  
**Trạng thái:** Accepted  
**Người quyết định:** MediChain Team

---

## Bối cảnh (Context)

MediChain backend (Express + TypeScript) cần một giải pháp để tương tác với PostgreSQL. Yêu cầu:
- Type-safe (tránh lỗi query tại runtime)
- Easy migration management
- Developer experience tốt
- Hỗ trợ quan hệ phức tạp (User → MedicalRecord → Medicine → Appointment)

## Các lựa chọn đã cân nhắc (Options Considered)

### Lựa chọn A: Prisma ORM
- **Ưu:**
  - Schema-first: định nghĩa model 1 lần trong `schema.prisma` → generate TypeScript types tự động
  - Migration tự động và có version control (`prisma migrate dev`)
  - Prisma Studio: GUI để xem/sửa data trong development
  - Type-safe queries: không thể query field không tồn tại
  - `select` syntax built-in → dễ control data exposure
- **Nhược:**
  - Generate code → file `src/generated/` phải exclude khỏi git
  - Một số complex query cần `$queryRaw` fallback
  - Bundle size lớn hơn raw pg

### Lựa chọn B: TypeORM
- **Ưu:** Decorator-based, quen thuộc với Java/Spring devs
- **Nhược:**
  - Type safety kém hơn Prisma
  - Migration unreliable — nhiều issue được report trong cộng đồng
  - Ít được maintain tích cực

### Lựa chọn C: Drizzle ORM
- **Ưu:** Nhẹ hơn Prisma, type-safe, không generate code
- **Nhược:**
  - Còn khá mới (2022), ecosystem nhỏ hơn
  - Migration tooling chưa mature bằng Prisma
  - Ít tài liệu và ví dụ

### Lựa chọn D: Raw `pg` driver
- **Ưu:** Kiểm soát hoàn toàn query, nhẹ nhất
- **Nhược:**
  - Không type-safe: dễ SQL injection nếu không cẩn thận
  - Phải viết SQL thủ công → error-prone
  - Không có migration management

## Quyết định (Decision)

**Chọn:** Lựa chọn A — Prisma ORM

**Lý do chính:**
1. Medical data cần type safety cao — không thể để runtime error do query sai field tên
2. Migration versioning quan trọng khi schema thay đổi theo thời gian
3. `select` syntax giúp enforce không leak sensitive fields (password, token)

## Hệ quả (Consequences)

### Tích cực
- Compile-time type checking cho mọi DB query
- `prisma migrate` tạo migration file có thể review trước khi apply
- `prisma generate` tự sync types khi schema thay đổi

### Tiêu cực / Trade-off
- Phải chạy `npx prisma generate` sau khi thay đổi schema
- File `src/generated/` phải gitignore (auto-generated)
- Một số aggregation query phức tạp cần dùng `$queryRaw`

### Conventions bắt buộc từ quyết định này
- Mọi schema change phải có migration: `npx prisma migrate dev --name <tên>`
- KHÔNG commit `src/generated/` vào git
- Mọi Prisma query phải có `select` để tránh expose sensitive data
- KHÔNG dùng `$queryRaw` trừ khi Prisma ORM không đáp ứng được use case

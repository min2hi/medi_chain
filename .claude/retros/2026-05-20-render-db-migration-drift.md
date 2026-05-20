## [2026-05-20] Render DB Migration Drift Fix

### Đã làm
- Xác nhận mobile đã gọi đúng Render backend thay vì local.
- Trace lỗi `Appointment.doctorNotes does not exist in the current database` từ Render API.
- Thêm Prisma migration tạo cột `Appointment.doctorNotes` và `Appointment.completedAt`.
- Thêm `select` explicit cho các query appointment phía patient trong `MedicalService`.
- Sửa Google Fonts runtime fetching vì app chưa bundle Inter `.ttf` trong assets.

### Vấn đề gặp phải & cách giải quyết
- Schema Prisma đã có `doctorNotes`/`completedAt`, nhưng migration history chưa có migration tạo 2 cột này nên production DB drift.
- `npx prisma migrate status` từ máy local bị Neon từ chối quyền `P1010`, nên không apply production DB thủ công từ local.
- Render entrypoint đã chạy `npx prisma migrate deploy`, vì vậy migration mới sẽ được apply khi backend deploy lại.

### Còn dang dở
- Cần deploy backend lên Render để migration chạy trên production DB.
- Chưa verify trực tiếp endpoint authenticated trên Render sau migration vì migration chưa apply được từ local.

### Phải nhớ buổi sau
- Khi thêm field Prisma model phải có migration tương ứng, không chỉ update schema/generated client.
- Nếu GoogleFonts runtime fetching bị tắt thì phải bundle font files trong `pubspec.yaml`, nếu không app sẽ throw exception khi font chưa có cache.

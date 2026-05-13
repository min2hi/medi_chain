## [2026-05-11] Remediation of Critical Gaps & Audit Issues

### Đã làm
- **Auth & Authorization:** Mở quyền truy cập `ADMIN` portal cho role `DOCTOR` (tại `auth.middleware.ts` và `app_router.dart`).
- **Resilience:** Cài đặt pattern Babylon Health (Fail-open) cho `DiseasePredictorService` bằng `Promise.race` với timeout 3s.
- **Security:** Fix lỗi **SQL Injection risk** tiềm ẩn trong `clinical-rules.engine.ts` bằng cách chuyển từ `$queryRawUnsafe` sang `$queryRaw` với template literal an toàn cho pgvector.
- **Data Integrity:** Fix lỗi crash app do Type Mismatch khi map Prisma `Int` sang Flutter `String` trong `PendingReviewModel`, `SafetyKeywordModel` và `ComboRuleModel`. Sửa lỗi `AuditLogModel.id` crash.
- **Logging & Visibility:** Thay thế `console.log` bằng `pino logger` trong production code (`disease-predictor.service.ts`).
- **Compliance (PHI):** Hoàn thiện màn hình Access Logs với Epic-style Audit Trail, xuất CSV qua clipboard zero-dependency, fix màu sắc hiển thị (HIGH vs WARN). Fix lỗi state rebuild của Date Picker trong AppBar.
- **Code Quality:** Fix toàn bộ warnings của `flutter analyze` và `tsc`. Thay thế raw `http.get` bằng `ApiClient` để handle token expiry trong `admin_dashboard_screen.dart`. Sửa lỗi gọi sai key `auth_token` thành `token`.

### Vấn đề gặp phải & cách giải quyết
- **Lỗi ngầm (Silent Bugs):** Flutter app bị crash khi parse JSON API do backend Prisma sử dụng `@id @default(autoincrement())` trả về kiểu `number`, trong khi Flutter object map `j['id'] as String`. Đã giải quyết bằng cách dùng `j['id'].toString()` đồng bộ.
- **Lỗi count không đồng bộ:** Cache stats trả về số pending review bằng cách query `isActive: false`, trong khi dashboard stats trả về bằng cách query `reviewStatus: 'PENDING'`. Đã đồng bộ sang điều kiện `reviewStatus: 'PENDING'`.

### Còn dang dở
- Tạm thời chưa triển khai E2E integration test cho toàn bộ luồng Semantic AI Discovery (đã chạy unit nhưng chưa chạy trên thực tế với traffic thật).
- Search bar trong access_logs chưa được debounce 300ms do độ ưu tiên thấp và đang chạy local data, nhưng cần fix nếu list log quá dài trên server thật.

### Phải nhớ buổi sau
- Prisma query với `pgvector` luôn sử dụng `$queryRaw<T>\`...\`` thay vì `queryRawUnsafe` để tránh SQL Injection.
- Luôn kiểm tra kỹ schema Prisma (các field `Int` vs `String`) trước khi định nghĩa models trong Flutter, vì khác biệt kiểu sẽ làm app crash runtime không báo lỗi compile.
- Gọi các endpoint backend phải ưu tiên dùng `ApiClient` thay vì `http` raw để tự động refresh JWT Token.

# ADR-009: API Access Audit Trail — File-based JSONL Pattern

**Ngày:** 2026-04-28  
**Trạng thái:** Accepted  
**Người quyết định:** Dev Team

---

## Bối cảnh (Context)

MediChain xử lý dữ liệu y tế nhạy cảm (PHI — Protected Health Information): hồ sơ bệnh án, lịch sử thuốc, kết quả AI tư vấn.

Không có audit trail đồng nghĩa:
- Không biết ai đã xem hồ sơ bệnh nhân nào, lúc nào
- Không thể điều tra khi xảy ra rò rỉ dữ liệu
- Không đáp ứng yêu cầu tối thiểu của HIPAA-lite / Nghị định 13/2023/NĐ-CP
- Hospital/partner hỏi "ai access hệ thống lúc 3 giờ sáng?" → không trả lời được

Cần một cơ chế ghi lại **mọi API call**: ai làm gì, lúc nào, từ đâu, kết quả gì.

---

## Các lựa chọn đã cân nhắc (Options Considered)

### Lựa chọn A: Database (Prisma → Neon PostgreSQL)
- **Ưu:** Có thể query phức tạp (JOIN với User, filter theo range), persistent, có index
- **Nhược:**
  - Mỗi request = 1 INSERT → tăng DB load đáng kể (100 req/phút = 6000 inserts/giờ)
  - Nếu DB down → audit cũng down
  - Cần migration, schema management
  - Chi phí Neon tăng theo số writes

### Lựa chọn B: File-based JSONL (1 file/ngày)
- **Ưu:**
  - Zero DB overhead — ghi file async không block event loop
  - Không phụ thuộc vào DB — audit hoạt động ngay cả khi Neon có vấn đề
  - Dễ ship lên CloudWatch/Datadog/Logtail về sau
  - Pattern đã dùng trong `triage-audit.service.ts` — consistent
  - Rotate tự động theo ngày, giữ 30 ngày
- **Nhược:**
  - Không query phức tạp được (không có INDEX)
  - Mất khi Render redeploy (ephemeral disk)
  - Không scale nếu traffic rất cao (file lớn, đọc chậm)

### Lựa chọn C: Third-party Log Service (Datadog, Logtail, CloudWatch)
- **Ưu:** Persistent, searchable, alerting tích hợp, production-grade
- **Nhược:**
  - Chi phí thêm (Datadog: $15+/tháng, CloudWatch: pay-per-GB)
  - Cần setup agent, API key, network call mỗi request
  - Over-engineering cho giai đoạn hiện tại

---

## Quyết định (Decision)

**Chọn:** Lựa chọn B — File-based JSONL

**Lý do:**
1. **Nhất quán với codebase** — `triage-audit.service.ts` đã dùng pattern này, team hiểu rõ
2. **Zero DB overhead** — quan trọng vì backend dùng Neon free tier (connection limits)
3. **Tách biệt khỏi DB** — audit vẫn chạy khi DB có vấn đề
4. **Upgrade path rõ ràng** — khi scale, chỉ cần thay `writeLog()` để gọi HTTP sink (CloudWatch/Logtail) mà không đổi interface

**Thiết kế chi tiết:**
- `audit.middleware.ts` — Express middleware, đăng ký global
- Ghi sau `res.on('finish')` → không ảnh hưởng latency response
- `fs.appendFile` async (không phải `appendFileSync`) → không block event loop
- `cleanOldLogs` chỉ chạy 1 lần/ngày qua `setImmediate` (không chạy mỗi request)
- Path normalize: `/api/user/:cuid` → `/api/user/:id` (không log PII trong URL)
- UserId hash: djb2 → `u_a3f9c2` (obfuscation, không phải cryptographic)

**API cho Admin:**
- `GET /api/admin/access-logs?date=&method=&status=&limit=` — protected bởi authMiddleware + requireAdmin
- Stats tính từ **toàn bộ ngày** (trước filter) → admin không bị mislead
- Flutter `AccessLogsScreen` trong Admin Dashboard

---

## Hệ quả (Consequences)

### Tích cực
- Admin có thể xem ai access gì lúc nào ngay trong app
- Zero chi phí thêm, zero DB load
- Foundation cho compliance (HIPAA-lite, audit trail yêu cầu)
- Detect anomaly: 1 user query 1000 records/phút → thấy ngay

### Tiêu cực / Trade-off
- **Ephemeral disk (Render):** Logs mất khi redeploy → mất tối đa 1 ngày log/lần deploy
- **Không query phức tạp:** Không thể "xem tất cả request của user X trong 7 ngày qua" — phải đọc 7 file riêng
- **UserId chỉ là hash, không reverse được:** Không biết hash `u_a3f9c2` là user nào nếu không có bảng tra cứu

### Rủi ro cần theo dõi
- **File size:** Nếu traffic tăng đột biến, file ngày có thể > 100MB → đọc chậm khi admin query. Cần thêm file size check và rotate theo size (không chỉ theo ngày)
- **Render disk:** Khi có incident forensics, logs có thể đã mất. Giải pháp dài hạn: ship logs ra Logtail (có free tier 3 ngày) hoặc Render persistent disk ($7/tháng)
- **userId obfuscation:** djb2 hash có thể collision (2 user khác nhau → cùng hash). Acceptable cho MVP nhưng cần upgrade lên SHA-256 + per-request salt khi cần forensic-grade audit

---

## Upgrade Path (khi cần scale)

```typescript
// Thay thế writeLog() hiện tại:
async function writeLog(entry: ApiAuditEntry): Promise<void> {
  // Option 1: Logtail (Better Stack)
  await fetch('https://in.logtail.com', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${process.env.LOGTAIL_TOKEN}` },
    body: JSON.stringify(entry),
  });

  // Option 2: CloudWatch (nếu deploy lên AWS)
  await cloudwatch.putLogEvents({ ... });
}
```

Không cần đổi interface của middleware hay controller.

---
> **Liên quan:** ADR-004 (Clinical Rules Engine) đã có pattern triage-audit tương tự.
> File này formalize pattern đó thành chuẩn cho toàn bộ API access logging.

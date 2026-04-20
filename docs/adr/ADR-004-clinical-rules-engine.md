# ADR-004: Clinical Rules Engine — "Rules as Data" Pattern

**Ngày:** 2026-04-20  
**Trạng thái:** Accepted  
**Người quyết định:** Engineering Team (MediChain)

---

## Bối cảnh (Context)

Hệ thống recommendation AI của MediChain sử dụng ~150 emergency keywords và 6 combo rules để phát hiện các trường hợp cấp cứu (ACS, đột quỵ, suy hô hấp...) và chặn gợi ý thuốc không phù hợp.

**Vấn đề với thiết kế cũ (hardcoded):**
- Toàn bộ keywords được khai báo thẳng trong `medical-safety.service.ts` dưới dạng TypeScript array
- Mỗi lần thêm/sửa keyword → phải tạo PR → code review → deploy → ~30 phút downtime risk
- Không có audit trail: không biết ai thêm keyword nào, khi nào, kèm guideline gì
- Vi phạm "separation of concerns": clinical data trộn lẫn với application logic
- Không scale: khi hệ thống mở rộng ra nhiều ngôn ngữ hoặc nhiều thị trường, không thể quản lý

**Benchmark phát hiện:** 25-case adversarial test đạt ~96% sensitivity — nhưng cần mechanism để cập nhật rules mà không cần deploy lại khi bác sĩ report false negative mới.

---

## Các lựa chọn đã cân nhắc (Options Considered)

### Lựa chọn A: Giữ nguyên hardcoded (status quo)
- **Ưu:** Đơn giản, không thêm dependency, zero latency
- **Nhược:** Không có audit trail, mọi thay đổi cần deploy, không scale, vi phạm PDPA nếu bị kiểm tra

### Lựa chọn B: Database-driven + Redis Cache
- **Ưu:** Hot-reload, distributed cache, hỗ trợ multi-instance scaling
- **Nhược:** Phải thêm Redis vào stack (chưa có trong `docker-compose.prod.yml`), tăng infrastructure complexity, chi phí vận hành thêm ~$50-100/tháng trên cloud

### Lựa chọn C: Database-driven + In-Process LRU Cache ✅ (Đã chọn)
- **Ưu:** Hot-reload, audit trail, zero new infrastructure, ~0ms cache hit, fail-safe khi DB down
- **Nhược:** Cache không shared giữa nhiều instance Node.js (nhưng hiện tại là single-instance)

---

## Quyết định (Decision)

**Chọn:** Lựa chọn C — `ClinicalRulesEngine` với 3-tier load strategy

**Lý do:**
1. **Infrastructure constraint:** Redis chưa có trong production stack. Thêm Redis vào thời điểm này = over-engineering cho single-instance deployment
2. **"Rules as Data" pattern đã được validate:** Ada Health, Epic CDS Hooks, Babylon Health đều dùng pattern này — clinical rules nên là data, không phải code
3. **Upgrade path rõ ràng:** Khi cần multi-instance → swap LRU → ioredis trong `clinical-rules.engine.ts`, không thay đổi interface
4. **2-step approval:** `isActive=false` (pending) → Admin activate → tránh lỗi clinical do một người quyết định

**Stack kỹ thuật được thêm:**
- `lru-cache@10` (npm package): In-process LRU cache, 15 phút TTL, max 20 entries
- Prisma tables: `SafetyKeyword` (151 rows), `ComboRule` (6 rows)
- REST Admin API: `POST/GET/PATCH /api/admin/clinical-rules/*`

**LRU Cache là gì?**
> **LRU = Least Recently Used** — thuật toán cache giữ lại các item được truy cập gần đây nhất.  
> Khi cache đầy, item lâu không dùng nhất bị xóa ("evicted") để nhường chỗ cho item mới.  
> Ví dụ: Cache chứa 20 rule sets. Sau 15 phút không dùng → tự expire → request tiếp theo fetch lại từ DB.

---

## Hệ quả (Consequences)

### Tích cực
- **Hot-reload:** Admin thêm keyword mới → `POST /cache/invalidate` → rule active trong <1 giây, không restart server
- **Audit trail:** Mọi thay đổi được ghi `createdBy`, `activatedBy`, `activatedAt`, `changeNote`, `guidelineRef`
- **Fail-safe:** DB down → system fallback về HARDCODED_FAILSAFE_GROUPS (50 critical keywords) → không bao giờ blind
- **Scalable data:** 151 keywords hiện tại, dễ dàng mở rộng lên 500+ mà không đụng code
- **Regulatory ready:** PDPA/HIPAA yêu cầu audit trail cho clinical data changes — đã có

### Tiêu cực / Trade-off
- **Single-instance cache:** Nếu scale lên 2+ Node.js instances, cache không sync giữa chúng → có thể dùng stale rules tối đa 15 phút. Chấp nhận được ở giai đoạn hiện tại.
- **DB dependency:** Lần đầu start (cache miss) tốn ~5-10ms query DB. Không đáng kể.

### Rủi ro cần theo dõi
- **Cache invalidation khi scale:** Nếu deploy multi-instance, cần migrate sang Redis hoặc dùng sticky sessions
- **DB migration drift:** `prisma db push` được dùng thay `prisma migrate dev` do migration history drift — cần xử lý lịch sử migration cho clean
- **Seeder idempotency:** Seeder dùng `upsert` — chạy lại nhiều lần không bị duplicate, nhưng không downgrade `isActive` của record đã tồn tại

---

## Files thay đổi

| File | Loại | Mô tả |
|------|------|--------|
| `prisma/schema.prisma` | MODIFY | Thêm `SafetyKeyword`, `ComboRule`, `ClinicalRuleSeverity` |
| `src/services/clinical-rules.engine.ts` | NEW | Engine chính: LRU → DB → Failsafe |
| `prisma/seeders/safety-keywords.seeder.ts` | NEW | Migration dữ liệu: hardcode → DB |
| `prisma/seed.ts` | MODIFY | Gọi seeder khi `npx prisma db seed` |
| `src/middlewares/auth.middleware.ts` | MODIFY | Thêm `requireAdmin` RBAC |
| `src/controllers/admin-clinical-rules.controller.ts` | NEW | Admin REST API |
| `src/routes/admin-clinical-rules.routes.ts` | NEW | Route definitions |
| `src/index.ts` | MODIFY | Register `/api/admin/clinical-rules` |
| `src/services/medical-safety.service.ts` | MODIFY | Xóa hardcoded arrays, dùng ClinicalRulesEngine |

---
> **Hướng dẫn:** Copy file này, đặt tên `ADR-00N-ten-ngan.md`, điền thông tin, commit.

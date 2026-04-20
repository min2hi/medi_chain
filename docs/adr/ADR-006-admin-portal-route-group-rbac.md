# ADR-006: Admin Portal Architecture — Route Group Isolation & Client-Side RBAC

- **Date**: 2026-04-20
- **Status**: Accepted
- **Deciders**: Team MediChain

---

## Context

MediChain cần một giao diện quản trị (Admin Portal) để bác sĩ và admin quản lý Safety Keywords, Combo Rules, và theo dõi hệ thống AI mà không cần can thiệp developer.

Vấn đề cần quyết định:
1. Admin Portal nên được tách khỏi Patient Portal như thế nào?
2. Cơ chế kiểm soát quyền truy cập (RBAC) nên đặt ở tầng nào?
3. Luồng điều hướng giữa hai portal nên hoạt động ra sao?

---

## Options Considered

### Option A: Middleware-level redirect (server-side)
Dùng Next.js `middleware.ts` để đọc JWT và redirect `/admin/*` nếu không có quyền.

**Pros**: Bảo mật tuyệt đối, không có flash UI.  
**Cons**: Phức tạp hơn, cần parse JWT trong middleware Edge Runtime; layout vẫn cần guard riêng.

### Option B: Separate Next.js app (monorepo)
Tạo `apps/admin` riêng trong monorepo, deploy trên subdomain `admin.medichain.com`.

**Pros**: Hoàn toàn tách biệt, security boundary rõ ràng.  
**Cons**: Overkill với team hiện tại, tăng infrastructure cost, duplicate auth logic.

### Option C: Next.js Route Group + Client-side RBAC guard ✅ **(Chosen)**
Dùng `src/app/admin/` route group với `layout.tsx` riêng, client-side role check từ localStorage.

**Pros**:
- Triển khai nhanh, dùng lại toàn bộ auth infrastructure hiện có
- `layout.tsx` đóng vai trò auth guard — render null + redirect nếu không đủ quyền
- Phù hợp với quy mô hiện tại (internal tool, không phải public-facing)
- Backend API là tuyến phòng thủ cuối cùng (requireAdmin middleware)

**Cons**:
- Có thể flash blank screen trước khi guard check xong (~100ms)
- Token nằm trong localStorage (đã là pattern hiện tại của dự án)

---

## Decision

**Chọn Option C** — Route Group Isolation + Client-side RBAC.

### Rationale

**Defense-in-depth**: Backend API đã enforce `requireAdmin` middleware trên toàn bộ `/api/admin/*`. Client-side guard chỉ là UX enhancement, không phải security boundary duy nhất.

**Simplicity wins**: Team nhỏ, timeline ngắn. Option A và B không mang lại bảo mật cao hơn đáng kể vì security thực sự nằm ở backend.

**Pattern consistency**: Toàn bộ dự án đã dùng localStorage + JWT pattern. Không nên tạo thêm một paradigm mới chỉ cho admin.

---

## Implementation

```
src/app/
├── (patient)/              ← Route group, layout riêng cho bệnh nhân
│   ├── layout.tsx
│   └── [các trang bệnh nhân]
├── admin/                  ← Admin portal
│   ├── layout.tsx          ← RBAC guard + dark theme sidebar
│   ├── not-found.tsx       ← Ở lại trong admin context khi 404
│   ├── clinical-rules/
│   │   ├── page.tsx        ← AI Review Queue
│   │   ├── keywords/       ← Safety Keywords CRUD
│   │   └── combos/         ← Combo Rules management
│   ├── telemetry/          ← Live stats + audit log
│   └── config/             ← AI thresholds + hot-reload
└── auth/                   ← Login (role-aware redirect)
```

### RBAC Flow

```
User đăng nhập
  └─> AuthService.login() → trả về { user, token }
  └─> lưu user.role vào localStorage
  └─> if role === ADMIN/DOCTOR → redirect to /admin/clinical-rules
      else → redirect to /

Truy cập /admin/*
  └─> admin/layout.tsx useEffect đọc localStorage
  └─> if no role or role !== ADMIN/DOCTOR → router.replace('/auth/login?redirect=/admin/clinical-rules')
  └─> else → render Admin portal
```

### Portal Switcher

Người dùng có role ADMIN/DOCTOR thấy nút **"Admin Portal"** ở sidebar bệnh nhân để chuyển sang `/admin/clinical-rules` mà không cần đăng xuất.

---

## Consequences

### Positive
- Admin portal hoàn toàn tách biệt về layout, theme, và navigation
- Thêm trang admin mới chỉ cần tạo file trong `src/app/admin/`
- Backend là security boundary thực sự — frontend guard chỉ là UX

### Negative / Risks
- Nếu token bị XSS steal, attacker có thể thấy admin UI (nhưng API vẫn từ chối vì backend verify JWT)
- Flash blank screen ~100ms khi admin/layout.tsx check role — acceptable với internal tool

### Future
- Khi scale lên, có thể thêm `middleware.ts` để check role server-side và loại bỏ flash
- Có thể tách thành `apps/admin` nếu cần deploy riêng hoặc có team admin riêng

---

## References
- [Next.js Route Groups](https://nextjs.org/docs/app/building-your-application/routing/route-groups)
- `frontend/src/app/admin/layout.tsx` — RBAC guard implementation
- `frontend/src/services/admin.service.ts` — Admin API layer
- ADR-001 (Gemini AI Engine) — backend security model

# ADR-010: Doctor Credential Fields trong Profile Model

**Ngày:** 2026-04-28  
**Trạng thái:** Accepted  
**Người quyết định:** Dev Team

---

## Bối cảnh (Context)

MediChain có 3 role: `USER` (bệnh nhân), `DOCTOR` (bác sĩ), `ADMIN`.

Vấn đề hiện tại:
- Bất kỳ user nào cũng có thể được cấp role `DOCTOR` bởi Admin mà **không cần chứng minh bằng cấp**
- Không có nơi lưu số chứng chỉ hành nghề → không thể verify bác sĩ thật
- Bệnh nhân không biết bác sĩ tư vấn cho mình có chuyên khoa gì
- Về sau khi tích hợp với Bộ Y tế API hoặc FHIR, cần `licenseNumber` làm khóa tra cứu

---

## Các lựa chọn đã cân nhắc (Options Considered)

### Lựa chọn A: Tạo model `DoctorProfile` riêng biệt
- **Ưu:** Tách biệt hoàn toàn, schema rõ ràng
- **Nhược:**
  - Cần migration phức tạp hơn
  - API phải query 2 bảng (Profile + DoctorProfile) khi cần thông tin bác sĩ
  - Over-engineering khi số field chỉ có 4

### Lựa chọn B: Thêm field trực tiếp vào `Profile` (nullable)
- **Ưu:**
  - Đơn giản — 1 table, 1 query
  - Patient không bị ảnh hưởng (field để NULL)
  - Ít migration, ít code thay đổi
  - Có thể thêm field sau khi cần thiết
- **Nhược:**
  - Profile table "biết" về Doctor logic — vi phạm Single Responsibility nhẹ
  - Nếu sau thêm 20 field cho Doctor thì Profile table sẽ phình to

### Lựa chọn C: Dùng `preferences` JSONB để lưu doctor info
- **Ưu:** Không cần migration
- **Nhược:**
  - Không có type safety, không có INDEX
  - Khó query và filter
  - Không thể enforce constraint (e.g., licenseNumber unique)

---

## Quyết định (Decision)

**Chọn:** Lựa chọn B — Thêm field nullable vào `Profile`

**Lý do:**
1. **Đủ cho MVP** — 4 field (licenseNumber, specialty, clinicAddress, licenseVerified) không đủ để tạo bảng riêng
2. **Đơn giản nhất** — 1 migration, không đổi API query pattern
3. **Có thể tách sau** — Khi vượt quá 8-10 field Doctor, extract ra `DoctorProfile` bằng data migration

**Fields thêm vào `Profile`:**

| Field | Type | Mặc định | Mô tả |
|---|---|---|---|
| `licenseNumber` | `String?` | NULL | Số chứng chỉ hành nghề y do Bộ Y tế cấp |
| `specialty` | `String?` | NULL | Chuyên khoa: "Nội khoa", "Da liễu", "Nhi khoa"... |
| `clinicAddress` | `String?` | NULL | Địa chỉ phòng khám / bệnh viện công tác |
| `licenseVerified` | `Boolean` | `false` | Admin đã xác thực số chứng chỉ là thật? |

---

## Hệ quả (Consequences)

### Tích cực
- Foundation cho Doctor verification flow về sau
- `licenseVerified = false` là signal rõ ràng để UI hiển thị "Chưa xác thực"
- `licenseNumber` có thể dùng làm khóa tra cứu với Bộ Y tế API (FHIR `Practitioner.identifier`)
- Patient biết bác sĩ tư vấn chuyên khoa gì

### Tiêu cực / Trade-off
- Profile table bây giờ có logic của cả Patient lẫn Doctor — cần document rõ
- `licenseVerified` chỉ là flag thủ công — Admin verify bằng mắt, không tự động

### Rủi ro cần theo dõi
- **Không enforce uniqueness:** `licenseNumber` hiện tại không có UNIQUE constraint — 2 bác sĩ khác nhau có thể nhập cùng số. Cần thêm UNIQUE INDEX khi có verification flow thật
- **Không có verification workflow:** Hiện tại Admin set `licenseVerified = true` thủ công qua SQL/Admin portal. Cần build màn hình verify trong Admin Portal

---

## Upgrade Path (khi có verification workflow)

```
Bước tiếp theo:
1. Admin Portal: thêm màn hình "Pending Doctor Verification"
   → Doctor upload ảnh chứng chỉ → Admin review → bấm Approve → licenseVerified = true
2. Thêm UNIQUE constraint cho licenseNumber
3. Tích hợp API Bộ Y tế (nếu có) để auto-verify
4. FHIR: map licenseNumber → Practitioner.identifier.value
```

---
> **Liên quan:** ADR-001 (User Role System). Quyết định này mở rộng role DOCTOR
> với metadata credential, không thay đổi RBAC logic.

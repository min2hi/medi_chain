-- Migration: Add Doctor Credential Fields to Profile
-- Thêm các trường cho bác sĩ: số chứng chỉ, chuyên khoa, địa chỉ phòng khám.
-- Dùng IF NOT EXISTS để idempotent (có thể chạy lại an toàn).
-- Patient không bị ảnh hưởng: các trường này mặc định NULL.

ALTER TABLE "Profile"
    ADD COLUMN IF NOT EXISTS "licenseNumber"   TEXT,
    ADD COLUMN IF NOT EXISTS "specialty"       TEXT,
    ADD COLUMN IF NOT EXISTS "clinicAddress"   TEXT,
    ADD COLUMN IF NOT EXISTS "licenseVerified" BOOLEAN NOT NULL DEFAULT false;

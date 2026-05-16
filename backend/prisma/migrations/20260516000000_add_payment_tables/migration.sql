-- PaymentStatus enum đã tồn tại (được tạo trước đó) — bỏ qua CREATE TYPE
-- Chỉ tạo các bảng và cột còn thiếu

-- AlterTable Appointment — add payment fields (safe: IF NOT EXISTS guards)
ALTER TABLE "Appointment"
  ADD COLUMN IF NOT EXISTS "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'UNPAID',
  ADD COLUMN IF NOT EXISTS "consultFee"    INTEGER;

-- CreateTable PaymentTransaction
CREATE TABLE IF NOT EXISTS "PaymentTransaction" (
    "id"           TEXT NOT NULL,
    "orderCode"    TEXT NOT NULL,
    "userId"       TEXT NOT NULL,
    "appointmentId" TEXT NOT NULL,
    "amount"       INTEGER NOT NULL,
    "status"       "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "providerRef"  TEXT,
    "checkoutUrl"  TEXT,
    "webhookData"  JSONB,
    "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PaymentTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable AdminSetting
CREATE TABLE IF NOT EXISTS "AdminSetting" (
    "key"       TEXT NOT NULL,
    "value"     TEXT NOT NULL,
    "label"     TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedBy" TEXT,

    CONSTRAINT "AdminSetting_pkey" PRIMARY KEY ("key")
);

-- CreateIndex (IF NOT EXISTS để idempotent)
CREATE UNIQUE INDEX IF NOT EXISTS "PaymentTransaction_orderCode_key" ON "PaymentTransaction"("orderCode");
CREATE INDEX IF NOT EXISTS "PaymentTransaction_userId_idx" ON "PaymentTransaction"("userId");
CREATE INDEX IF NOT EXISTS "PaymentTransaction_appointmentId_idx" ON "PaymentTransaction"("appointmentId");
CREATE INDEX IF NOT EXISTS "Appointment_userId_paymentStatus_idx" ON "Appointment"("userId", "paymentStatus");

-- AddForeignKey (IF NOT EXISTS không dùng được trực tiếp với FK — dùng DO block)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'PaymentTransaction_userId_fkey'
  ) THEN
    ALTER TABLE "PaymentTransaction"
      ADD CONSTRAINT "PaymentTransaction_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'PaymentTransaction_appointmentId_fkey'
  ) THEN
    ALTER TABLE "PaymentTransaction"
      ADD CONSTRAINT "PaymentTransaction_appointmentId_fkey"
      FOREIGN KEY ("appointmentId") REFERENCES "Appointment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END$$;

-- Seed default consultation fee
INSERT INTO "AdminSetting" (key, value, label, "updatedAt")
VALUES ('consultation_fee', '200000', 'Phí khám tư vấn (VND)', NOW())
ON CONFLICT (key) DO NOTHING;

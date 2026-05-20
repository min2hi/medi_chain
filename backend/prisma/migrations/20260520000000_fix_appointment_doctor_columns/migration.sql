-- Migration: Fix missing doctor clinical columns on Appointment (idempotent)
-- Root cause: P2022 PrismaClientKnownRequestError on production
-- The previous migration folder existed but was empty (no SQL).
-- This migration adds all missing columns safely using IF NOT EXISTS.

-- ─── Appointment: Doctor clinical fields ───────────────────────────────────
ALTER TABLE "Appointment"
  ADD COLUMN IF NOT EXISTS "doctorNotes"  TEXT,
  ADD COLUMN IF NOT EXISTS "completedAt"  TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "doctorId"     TEXT;

-- Foreign key doctor -> User (nullable)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Appointment_doctorId_fkey'
  ) THEN
    ALTER TABLE "Appointment"
      ADD CONSTRAINT "Appointment_doctorId_fkey"
      FOREIGN KEY ("doctorId") REFERENCES "User"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- ─── PaymentTransaction: missing currency + provider columns ────────────────
ALTER TABLE "PaymentTransaction"
  ADD COLUMN IF NOT EXISTS "currency"  TEXT NOT NULL DEFAULT 'VND',
  ADD COLUMN IF NOT EXISTS "provider"  TEXT NOT NULL DEFAULT 'PAYOS';

-- ─── Indexes for clinic appointment dashboard ───────────────────────────────
CREATE INDEX IF NOT EXISTS "Appointment_status_idx"
  ON "Appointment"("status");

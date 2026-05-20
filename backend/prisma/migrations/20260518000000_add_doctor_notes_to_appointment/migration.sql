-- Migration: Add doctor clinical fields to Appointment table
-- These columns were added to schema.prisma but the migration SQL was missing,
-- causing P2022 "column does not exist" errors on production (Neon/PostgreSQL).

ALTER TABLE "Appointment"
  ADD COLUMN IF NOT EXISTS "doctorNotes"   TEXT,
  ADD COLUMN IF NOT EXISTS "completedAt"   TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "doctorId"      TEXT;

-- Foreign key: doctor → User (nullable - appointment may not have a doctor yet)
-- Only add if not already exists (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'Appointment_doctorId_fkey'
  ) THEN
    ALTER TABLE "Appointment"
      ADD CONSTRAINT "Appointment_doctorId_fkey"
      FOREIGN KEY ("doctorId") REFERENCES "User"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- Index for clinic dashboard queries (status-based filtering)
CREATE INDEX IF NOT EXISTS "Appointment_status_idx" ON "Appointment"("status");
CREATE INDEX IF NOT EXISTS "Appointment_userId_paymentStatus_idx" ON "Appointment"("userId", "paymentStatus");

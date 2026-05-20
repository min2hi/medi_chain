-- Add clinical completion fields used when doctors complete appointments.
-- Safe for production drift: existing databases skip columns that already exist.

ALTER TABLE "Appointment"
  ADD COLUMN IF NOT EXISTS "doctorNotes" TEXT,
  ADD COLUMN IF NOT EXISTS "completedAt" TIMESTAMP(3);

-- Migration: Add missing columns that were added directly to DB without migration
-- Fixes: "column does not exist" error on Neon production database

-- Add collaborativeScore to DrugCandidate
ALTER TABLE "DrugCandidate" 
ADD COLUMN IF NOT EXISTS "collaborativeScore" DOUBLE PRECISION;

-- Add symptomContext to TreatmentFeedback (if schema requires it)
ALTER TABLE "TreatmentFeedback"
ADD COLUMN IF NOT EXISTS "symptomContext" TEXT;

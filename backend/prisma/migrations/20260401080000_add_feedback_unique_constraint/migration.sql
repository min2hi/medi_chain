-- Add updatedAt column to TreatmentFeedback for tracking updates
ALTER TABLE "TreatmentFeedback" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Clean up any duplicate feedback records (keep the most recent per user+drug+session)
DELETE FROM "TreatmentFeedback"
WHERE id NOT IN (
    SELECT DISTINCT ON ("userId", "drugId", "sessionId") id
    FROM "TreatmentFeedback"
    ORDER BY "userId", "drugId", "sessionId", "createdAt" DESC
);

-- Add unique constraint to enforce one feedback per user per drug per session
ALTER TABLE "TreatmentFeedback" DROP CONSTRAINT IF EXISTS "TreatmentFeedback_userId_drugId_sessionId_key";
ALTER TABLE "TreatmentFeedback" ADD CONSTRAINT "TreatmentFeedback_userId_drugId_sessionId_key" 
    UNIQUE("userId", "drugId", "sessionId");

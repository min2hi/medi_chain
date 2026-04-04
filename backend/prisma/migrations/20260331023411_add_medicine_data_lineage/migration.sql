-- AlterTable
ALTER TABLE "DrugCandidate" ADD COLUMN     "viIndications" TEXT,
ADD COLUMN     "viSummary" TEXT,
ADD COLUMN     "viWarnings" TEXT;

-- AlterTable
ALTER TABLE "Medicine" ADD COLUMN     "drugCandidateId" TEXT,
ADD COLUMN     "recommendationSessionId" TEXT;

-- CreateIndex
CREATE INDEX "Medicine_recommendationSessionId_idx" ON "Medicine"("recommendationSessionId");

-- AddForeignKey
ALTER TABLE "Medicine" ADD CONSTRAINT "Medicine_drugCandidateId_fkey" FOREIGN KEY ("drugCandidateId") REFERENCES "DrugCandidate"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Medicine" ADD CONSTRAINT "Medicine_recommendationSessionId_fkey" FOREIGN KEY ("recommendationSessionId") REFERENCES "RecommendationSession"("id") ON DELETE SET NULL ON UPDATE CASCADE;

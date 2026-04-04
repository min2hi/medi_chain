-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "vector";

-- AlterTable
ALTER TABLE "DrugCandidate" ADD COLUMN     "embedding" vector(1536);

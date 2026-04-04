/*
  Warnings:

  - You are about to drop the column `contextUsed` on the `AIMessage` table. All the data in the column will be lost.
  - You are about to drop the `HealthRule` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Recommendation` table. If the table is not empty, all the data it contains will be lost.
  - Changed the type of `role` on the `AIMessage` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "ConversationType" AS ENUM ('CHAT', 'CONSULT');

-- CreateEnum
CREATE TYPE "MessageRole" AS ENUM ('USER', 'ASSISTANT', 'SYSTEM');

-- CreateEnum
CREATE TYPE "SessionStatus" AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "FeedbackOutcome" AS ENUM ('EFFECTIVE', 'PARTIALLY_EFFECTIVE', 'NOT_EFFECTIVE', 'SIDE_EFFECT', 'NOT_TAKEN');

-- CreateEnum
CREATE TYPE "LogAction" AS ENUM ('SESSION_CREATED', 'SAFETY_FILTER_APPLIED', 'RANKING_COMPLETED', 'AI_EXPLANATION_SENT', 'FEEDBACK_RECEIVED', 'CRITICAL_ALERT_FIRED');

-- DropForeignKey
ALTER TABLE "Recommendation" DROP CONSTRAINT "Recommendation_userId_fkey";

-- AlterTable
ALTER TABLE "AIConversation" ADD COLUMN     "isArchived" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "lastMessageAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "totalCost" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "totalMessages" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "totalTokens" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "type" "ConversationType" NOT NULL DEFAULT 'CHAT';

-- AlterTable
ALTER TABLE "AIMessage" DROP COLUMN "contextUsed",
ADD COLUMN     "completionTokens" INTEGER,
ADD COLUMN     "estimatedCost" DOUBLE PRECISION,
ADD COLUMN     "medicalContext" TEXT,
ADD COLUMN     "model" TEXT,
ADD COLUMN     "promptTokens" INTEGER,
ADD COLUMN     "responseTimeMs" INTEGER,
ADD COLUMN     "safetyCheckResult" TEXT,
ADD COLUMN     "tokenCount" INTEGER,
DROP COLUMN "role",
ADD COLUMN     "role" "MessageRole" NOT NULL;

-- AlterTable
ALTER TABLE "Profile" ADD COLUMN     "chronicConditions" TEXT,
ADD COLUMN     "isBreastfeeding" BOOLEAN,
ADD COLUMN     "isPregnant" BOOLEAN,
ADD COLUMN     "lastUpdated" TIMESTAMP(3);

-- DropTable
DROP TABLE "HealthRule";

-- DropTable
DROP TABLE "Recommendation";

-- DropEnum
DROP TYPE "RecommendationStatus";

-- CreateTable
CREATE TABLE "DrugCandidate" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "genericName" TEXT NOT NULL,
    "ingredients" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "indications" TEXT NOT NULL,
    "contraindications" TEXT NOT NULL,
    "sideEffects" TEXT NOT NULL,
    "minAge" INTEGER,
    "maxAge" INTEGER,
    "notForPregnant" BOOLEAN NOT NULL DEFAULT false,
    "notForNursing" BOOLEAN NOT NULL DEFAULT false,
    "notForConditions" TEXT,
    "interactsWith" TEXT,
    "baseSafetyScore" DOUBLE PRECISION NOT NULL DEFAULT 80,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DrugCandidate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RecommendationSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "symptoms" TEXT NOT NULL,
    "profileSnapshot" TEXT NOT NULL,
    "totalCandidates" INTEGER NOT NULL DEFAULT 0,
    "filteredOut" INTEGER NOT NULL DEFAULT 0,
    "finalRanked" INTEGER NOT NULL DEFAULT 0,
    "status" "SessionStatus" NOT NULL DEFAULT 'PENDING',
    "aiExplanation" TEXT,
    "processingMs" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RecommendationSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RecommendationItem" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "drugId" TEXT NOT NULL,
    "profileScore" DOUBLE PRECISION NOT NULL,
    "safetyScore" DOUBLE PRECISION NOT NULL,
    "historyScore" DOUBLE PRECISION NOT NULL,
    "finalScore" DOUBLE PRECISION NOT NULL,
    "rank" INTEGER NOT NULL,
    "isRecommended" BOOLEAN NOT NULL DEFAULT true,
    "filterReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RecommendationItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TreatmentFeedback" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "drugId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "outcome" "FeedbackOutcome" NOT NULL,
    "usedDays" INTEGER,
    "sideEffect" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TreatmentFeedback_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RecommendationLog" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "action" "LogAction" NOT NULL,
    "details" TEXT NOT NULL,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RecommendationLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DrugCandidate_name_key" ON "DrugCandidate"("name");

-- CreateIndex
CREATE INDEX "DrugCandidate_category_idx" ON "DrugCandidate"("category");

-- CreateIndex
CREATE INDEX "DrugCandidate_genericName_idx" ON "DrugCandidate"("genericName");

-- CreateIndex
CREATE INDEX "RecommendationSession_userId_createdAt_idx" ON "RecommendationSession"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "RecommendationSession_status_idx" ON "RecommendationSession"("status");

-- CreateIndex
CREATE INDEX "RecommendationItem_sessionId_rank_idx" ON "RecommendationItem"("sessionId", "rank");

-- CreateIndex
CREATE UNIQUE INDEX "RecommendationItem_sessionId_drugId_key" ON "RecommendationItem"("sessionId", "drugId");

-- CreateIndex
CREATE INDEX "TreatmentFeedback_userId_drugId_idx" ON "TreatmentFeedback"("userId", "drugId");

-- CreateIndex
CREATE INDEX "TreatmentFeedback_drugId_outcome_idx" ON "TreatmentFeedback"("drugId", "outcome");

-- CreateIndex
CREATE INDEX "RecommendationLog_sessionId_idx" ON "RecommendationLog"("sessionId");

-- CreateIndex
CREATE INDEX "RecommendationLog_userId_createdAt_idx" ON "RecommendationLog"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "AIConversation_userId_type_idx" ON "AIConversation"("userId", "type");

-- CreateIndex
CREATE INDEX "AIConversation_userId_lastMessageAt_idx" ON "AIConversation"("userId", "lastMessageAt");

-- CreateIndex
CREATE INDEX "AIMessage_conversationId_createdAt_idx" ON "AIMessage"("conversationId", "createdAt");

-- AddForeignKey
ALTER TABLE "RecommendationSession" ADD CONSTRAINT "RecommendationSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecommendationItem" ADD CONSTRAINT "RecommendationItem_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "RecommendationSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecommendationItem" ADD CONSTRAINT "RecommendationItem_drugId_fkey" FOREIGN KEY ("drugId") REFERENCES "DrugCandidate"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TreatmentFeedback" ADD CONSTRAINT "TreatmentFeedback_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TreatmentFeedback" ADD CONSTRAINT "TreatmentFeedback_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "RecommendationSession"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TreatmentFeedback" ADD CONSTRAINT "TreatmentFeedback_drugId_fkey" FOREIGN KEY ("drugId") REFERENCES "DrugCandidate"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================
-- Migration: Clinical Rules Engine — Create Missing Tables
-- Fixed: removed DO $$ EXCEPTION blocks (không tương thích
-- với Neon connection pooler / PgBouncer transaction mode)
-- Production Neon đã xác nhận chưa có SafetyKeyword, ComboRule
-- → dùng SQL thuần, an toàn.
-- ============================================================

-- ─── 1. Enums ────────────────────────────────────────────────────────────────

CREATE TYPE "ClinicalRuleSeverity" AS ENUM (
    'CRITICAL', 'HIGH', 'MEDIUM', 'INFO'
);

CREATE TYPE "KeywordReviewStatus" AS ENUM (
    'ACTIVE', 'PENDING', 'REJECTED'
);

-- ─── 2. SafetyKeyword ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "SafetyKeyword" (
    "id"              SERIAL PRIMARY KEY,
    "groupId"         TEXT NOT NULL,
    "groupLabel"      TEXT NOT NULL,
    "keyword"         TEXT NOT NULL,
    "keywordNorm"     TEXT NOT NULL,
    "language"        TEXT NOT NULL DEFAULT 'vi',
    "severity"        "ClinicalRuleSeverity" NOT NULL DEFAULT 'CRITICAL',
    "guidelineRef"    TEXT,
    "isActive"        BOOLEAN NOT NULL DEFAULT false,
    "activatedBy"     TEXT,
    "activatedAt"     TIMESTAMP(3),
    "reviewStatus"    "KeywordReviewStatus" NOT NULL DEFAULT 'ACTIVE',
    "discoveredBy"    TEXT,
    "similarityScore" DOUBLE PRECISION,
    "sourceKeywordId" INTEGER,
    "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdBy"       TEXT,
    "versionTag"      TEXT NOT NULL DEFAULT 'v2.1',
    "changeNote"      TEXT
);

ALTER TABLE "SafetyKeyword"
ADD CONSTRAINT "SafetyKeyword_groupId_keyword_language_key"
UNIQUE ("groupId", "keyword", "language");

ALTER TABLE "SafetyKeyword"
ADD CONSTRAINT "SafetyKeyword_sourceKeywordId_fkey"
FOREIGN KEY ("sourceKeywordId")
REFERENCES "SafetyKeyword"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "SafetyKeyword_groupId_isActive_idx"
    ON "SafetyKeyword"("groupId", "isActive");

CREATE INDEX "SafetyKeyword_keyword_idx"
    ON "SafetyKeyword"("keyword");

CREATE INDEX "SafetyKeyword_reviewStatus_idx"
    ON "SafetyKeyword"("reviewStatus");

-- ─── 3. ComboRule ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "ComboRule" (
    "id"            SERIAL PRIMARY KEY,
    "name"          TEXT NOT NULL,
    "label"         TEXT NOT NULL,
    "symptomGroups" JSONB NOT NULL,
    "minMatch"      INTEGER NOT NULL DEFAULT 2,
    "severity"      "ClinicalRuleSeverity" NOT NULL DEFAULT 'CRITICAL',
    "guidelineRef"  TEXT,
    "isActive"      BOOLEAN NOT NULL DEFAULT false,
    "activatedBy"   TEXT,
    "activatedAt"   TIMESTAMP(3),
    "createdAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdBy"     TEXT,
    "changeNote"    TEXT
);

ALTER TABLE "ComboRule"
ADD CONSTRAINT "ComboRule_name_key" UNIQUE ("name");

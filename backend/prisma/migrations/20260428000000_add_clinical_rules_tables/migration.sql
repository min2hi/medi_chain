-- ============================================================
-- Migration: Clinical Rules Engine — Create Missing Tables
-- ============================================================
-- Nguyên nhân: SafetyKeyword và ComboRule được tạo bằng
-- `prisma db push` trên local, chưa bao giờ có migration.
-- Neon production DB thiếu 2 bảng này → HTTP 500 toàn bộ
-- endpoints /api/admin/clinical-rules/*
--
-- Pattern: IF NOT EXISTS ở mọi nơi → idempotent (an toàn
-- khi chạy lại trên môi trường đã có bảng, ví dụ local dev).
-- ============================================================

-- ─── 1. Enums ────────────────────────────────────────────────────────────────

DO $$ BEGIN
    CREATE TYPE "ClinicalRuleSeverity" AS ENUM (
        'CRITICAL', 'HIGH', 'MEDIUM', 'INFO'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE "KeywordReviewStatus" AS ENUM (
        'ACTIVE', 'PENDING', 'REJECTED'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ─── 2. SafetyKeyword ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "SafetyKeyword" (
    -- PK
    "id"              SERIAL PRIMARY KEY,

    -- Nhóm emergency
    "groupId"         TEXT NOT NULL,
    "groupLabel"      TEXT NOT NULL,

    -- Keyword
    "keyword"         TEXT NOT NULL,
    "keywordNorm"     TEXT NOT NULL,
    "language"        TEXT NOT NULL DEFAULT 'vi',

    -- Clinical metadata
    "severity"        "ClinicalRuleSeverity" NOT NULL DEFAULT 'CRITICAL',
    "guidelineRef"    TEXT,

    -- 2-step approval workflow
    "isActive"        BOOLEAN NOT NULL DEFAULT false,
    "activatedBy"     TEXT,
    "activatedAt"     TIMESTAMP(3),

    -- Phase 2: Semantic Discovery
    -- embedding column là Unsupported("vector(768)") trong Prisma
    -- Sẽ được thêm riêng bởi pgvector nếu extension đã enable
    "reviewStatus"    "KeywordReviewStatus" NOT NULL DEFAULT 'ACTIVE',
    "discoveredBy"    TEXT,
    "similarityScore" DOUBLE PRECISION,
    "sourceKeywordId" INTEGER,

    -- Audit trail
    "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdBy"       TEXT,
    "versionTag"      TEXT NOT NULL DEFAULT 'v2.1',
    "changeNote"      TEXT
);

-- Unique constraint
DO $$ BEGIN
    ALTER TABLE "SafetyKeyword"
    ADD CONSTRAINT "SafetyKeyword_groupId_keyword_language_key"
    UNIQUE ("groupId", "keyword", "language");
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Self-referential FK (sourceKeyword → SafetyKeyword)
DO $$ BEGIN
    ALTER TABLE "SafetyKeyword"
    ADD CONSTRAINT "SafetyKeyword_sourceKeywordId_fkey"
    FOREIGN KEY ("sourceKeywordId")
    REFERENCES "SafetyKeyword"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS "SafetyKeyword_groupId_isActive_idx"
    ON "SafetyKeyword"("groupId", "isActive");

CREATE INDEX IF NOT EXISTS "SafetyKeyword_keyword_idx"
    ON "SafetyKeyword"("keyword");

CREATE INDEX IF NOT EXISTS "SafetyKeyword_reviewStatus_idx"
    ON "SafetyKeyword"("reviewStatus");

-- ─── 3. ComboRule ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "ComboRule" (
    "id"           SERIAL PRIMARY KEY,
    "name"         TEXT NOT NULL,
    "label"        TEXT NOT NULL,
    "symptomGroups" JSONB NOT NULL,
    "minMatch"     INTEGER NOT NULL DEFAULT 2,
    "severity"     "ClinicalRuleSeverity" NOT NULL DEFAULT 'CRITICAL',
    "guidelineRef" TEXT,
    "isActive"     BOOLEAN NOT NULL DEFAULT false,
    "activatedBy"  TEXT,
    "activatedAt"  TIMESTAMP(3),
    "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdBy"    TEXT,
    "changeNote"   TEXT
);

DO $$ BEGIN
    ALTER TABLE "ComboRule"
    ADD CONSTRAINT "ComboRule_name_key" UNIQUE ("name");
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ─── 4. pgvector embedding column (nếu extension đã enable) ─────────────────
-- SafetyKeyword.embedding: vector(768) — Gemini embedding-001
-- Chạy sau khi extension vector đã được enable bởi migration trước.

DO $$ BEGIN
    ALTER TABLE "SafetyKeyword"
    ADD COLUMN "embedding" vector(768);
EXCEPTION
    WHEN undefined_object   THEN null  -- extension chưa enable → bỏ qua
    WHEN duplicate_column   THEN null; -- cột đã tồn tại → bỏ qua
END $$;

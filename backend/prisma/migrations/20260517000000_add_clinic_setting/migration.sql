-- Migration: Add ClinicSetting table for key-value clinic configuration
-- Purpose: Store consultationFee and other clinic-wide settings

CREATE TABLE "ClinicSetting" (
    "key"       TEXT NOT NULL,
    "value"     TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    
    CONSTRAINT "ClinicSetting_pkey" PRIMARY KEY ("key")
);

-- Seed default consultation fee: 200,000 VND
INSERT INTO "ClinicSetting" ("key", "value", "updatedAt")
VALUES ('consultationFee', '200000', NOW())
ON CONFLICT ("key") DO NOTHING;

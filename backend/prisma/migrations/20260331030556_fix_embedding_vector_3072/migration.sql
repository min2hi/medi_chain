-- Fix embedding dimension: 1536 → 3072
-- gemini-embedding-001 produces 3072-dimensional vectors (state of the art)
-- Previous migrations used 1536 (OpenAI ada-002 era standard)

ALTER TABLE "DrugCandidate" DROP COLUMN IF EXISTS "embedding";
ALTER TABLE "DrugCandidate" ADD COLUMN "embedding" vector(3072);

-- Drop existing index if any (will be recreated after import)
DROP INDEX IF EXISTS "DrugCandidate_embedding_idx";
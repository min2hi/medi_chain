#!/bin/sh
set -e

echo "🔧 [Entrypoint] Generating Prisma client..."
npx prisma generate

echo "🗄️  [Entrypoint] Running database migrations..."
npx prisma migrate deploy

echo "🚀 [Entrypoint] Starting MediChain Backend..."
exec node dist/src/index.js

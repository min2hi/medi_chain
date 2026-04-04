#!/bin/sh
set -e

echo "Generating Prisma client..."
npx prisma generate

echo "Copying generated client to dist..."
cp -r src/generated dist/src/

echo "Running Prisma migrations..."
npx prisma migrate deploy

echo "Starting server..."
exec node dist/src/index.js

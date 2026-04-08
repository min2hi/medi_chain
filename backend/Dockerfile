# ============================================================
# MediChain Backend — Multi-Stage Production Dockerfile
# ============================================================
# Stage 1 (builder): Cài đầy đủ deps, compile TypeScript → JS
# Stage 2 (runner):  Chỉ copy output + production deps → image nhỏ ~70%
# ============================================================

# ---- Stage 1: Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

# Copy package files trước (tận dụng Docker layer cache)
COPY package*.json ./
COPY prisma ./prisma/

# Cài TẤT CẢ dependencies (bao gồm devDependencies để build TypeScript)
RUN npm ci

# Copy toàn bộ source code
COPY . .

# Generate Prisma client (dùng dummy URL — không cần DB thật để generate)
ARG DATABASE_URL=postgresql://user:pass@localhost:5432/db
ENV DATABASE_URL=${DATABASE_URL}
RUN npx prisma generate

# Compile TypeScript → JavaScript (output vào ./dist)
RUN npm run build

# ---- Stage 2: Production Runner ----
FROM node:22-alpine AS runner
WORKDIR /app

# Set production environment
ENV NODE_ENV=production

# Chỉ copy package files rồi cài production-only deps (không có devDeps)
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled output từ stage 1
COPY --from=builder /app/dist ./dist

# Copy Prisma schema + generated client (cần cho runtime)
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/src/generated ./src/generated

# Copy entrypoint script
COPY --from=builder /app/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# Security: Chạy với non-root user (tránh privilege escalation)
RUN addgroup -g 1001 -S nodejs && adduser -S medichain -u 1001 -G nodejs
USER medichain

EXPOSE 5000

CMD ["sh", "./entrypoint.sh"]

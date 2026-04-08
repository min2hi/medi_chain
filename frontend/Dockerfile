# ============================================================
# MediChain Frontend — Multi-Stage Production Dockerfile
# ============================================================
# Stage 1 (deps):    Resolve + cache npm dependencies
# Stage 2 (builder): Build Next.js standalone bundle
# Stage 3 (runner):  Image nhỏ gọn chỉ với runtime artifacts
# ============================================================

# ---- Stage 1: Dependencies ----
FROM node:22-alpine AS deps
WORKDIR /app

# Check xem có thể đọc libc không (cần cho native modules)
RUN apk add --no-cache libc6-compat

COPY package*.json ./
# npm ci = install chính xác theo lock file (deterministic)
RUN npm ci

# ---- Stage 2: Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

# Copy dependencies từ stage trước
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Tắt Next.js telemetry (không gửi data về Vercel khi build)
ENV NEXT_TELEMETRY_DISABLED=1

# NEXT_PUBLIC_API_URL phải được inject lúc BUILD (Next.js bake nó vào bundle)
# Khi deploy production, Nginx sẽ proxy /api → backend nên dùng /api (relative)
ARG NEXT_PUBLIC_API_URL=/api
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# Build Next.js standalone bundle
RUN npm run build

# ---- Stage 3: Production Runner ----
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Security: Non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001 -G nodejs

# Copy static public assets
COPY --from=builder /app/public ./public

# Copy standalone bundle (tất cả trong 1 folder, không cần node_modules đầy đủ)
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# Copy static files của Next.js (CSS, JS chunks, images)
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# server.js được Next.js tạo tự động trong standalone mode
CMD ["node", "server.js"]

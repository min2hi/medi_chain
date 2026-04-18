# 🚀 Full-Stack CI/CD Automation Playbook

> **Playbook tái sử dụng** cho mọi dự án. Copy file này vào project mới, follow từng bước.
> Được đúc kết từ quy trình thực tế của dự án MediChain.

---

## Tổng quan: 9 Quy Trình Tự Động Hóa

```
Code → Push → CI Check → PR → Review → Merge → Auto Deploy → Notify → Release
 ①      ②       ③        ④      ⑤       ⑥        ⑦            ⑧        ⑨
```

| # | Quy trình | Mục đích | Công cụ |
|---|-----------|---------|---------|
| ① | **Branch Protection** | Không ai push thẳng `main`, buộc qua PR | GitHub Settings |
| ② | **CI — Frontend** | Tự động lint + build check code frontend | GitHub Actions |
| ③ | **CI — Backend** | Tự động lint + build check code backend | GitHub Actions |
| ④ | **CI — Mobile** | Tự động analyze + test + build APK | GitHub Actions |
| ⑤ | **CD — Auto Deploy** | Merge xong → deploy tự động | Render + Vercel |
| ⑥ | **Dependabot** | Bot tự update thư viện hàng tuần | GitHub Dependabot |
| ⑦ | **Discord Notifications** | Thông báo khi deploy/fail | GitHub Actions + Discord |
| ⑧ | **Semantic Versioning** | Tự đánh version + viết changelog | release-please |
| ⑨ | **Code Coverage** | Đo % code được test | Codecov / lcov |

---

## ① Branch Protection — Bảo vệ nhánh chính

**Mục đích:** Không cho ai push thẳng vào `main`. Mọi thay đổi phải qua Pull Request + CI pass.

**Setup:** GitHub → Repo → Settings → Rules → Rulesets → New ruleset

```
Tên:           main-protection
Target branch: main
Rules bật:
  ✅ Require a pull request before merging
  ✅ Require status checks to pass
     → Thêm: "Frontend Check", "Backend Check"
  ✅ Block force pushes
```

---

## ② CI — Frontend (Next.js / React / Vue)

**File:** `.github/workflows/ci.yml`

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  frontend-check:
    name: 🌐 Frontend Check
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend   # ← đổi theo project
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - run: npm ci
      - run: npm run lint
      - run: npm run build

  backend-check:
    name: ⚙️ Backend Check
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend    # ← đổi theo project
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - run: npm ci
      - run: npm run build
```

---

## ③ CI — Mobile (Flutter)

**File:** `.github/workflows/mobile-ci.yml`

```yaml
name: Mobile CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'frontend-mobile/**'
      - '.github/workflows/mobile-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'frontend-mobile/**'

jobs:
  flutter-check:
    name: 📱 Flutter Mobile Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install dependencies
        working-directory: frontend-mobile
        run: flutter pub get

      - name: Analyze
        working-directory: frontend-mobile
        run: flutter analyze --fatal-infos

      - name: Test
        working-directory: frontend-mobile
        run: flutter test --reporter=github

      - name: Build APK
        working-directory: frontend-mobile
        run: flutter build apk --debug --no-pub
```

---

## ④ CD — Auto Deploy

### Backend (Render)

**File:** `.github/workflows/cd.yml`

```yaml
name: CD Pipeline

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  deploy-backend:
    name: 🚀 Deploy Backend
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Render Deploy
        run: curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK_BACKEND }}"
```

**Setup Render webhook:**
1. Render Dashboard → Service → Settings → Deploy Hook → Copy URL
2. GitHub → Repo → Settings → Secrets → `RENDER_DEPLOY_HOOK_BACKEND` = URL đó

### Frontend (Vercel)

Vercel tự động deploy khi push — chỉ cần connect repo trên vercel.com.

---

## ⑤ Dependabot — Tự động update thư viện

**File:** `.github/dependabot.yml`

```yaml
version: 2
updates:
  # Frontend dependencies
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "frontend"

  # Backend dependencies
  - package-ecosystem: "npm"
    directory: "/backend"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "backend"

  # Mobile dependencies
  - package-ecosystem: "pub"
    directory: "/frontend-mobile"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 3
```

---

## ⑥ PR Template — Checklist mỗi PR

**File:** `.github/pull_request_template.md`

```markdown
## 📋 Mô tả thay đổi
<!-- Mô tả ngắn gọn: thay đổi gì? Lại sao? -->

## 🔄 Loại thay đổi
- [ ] ✨ Tính năng mới (Feature)
- [ ] 🐛 Sửa lỗi (Bug fix)
- [ ] ♻️ Refactor (Không thay đổi logic)
- [ ] 📄 Tài liệu (Docs)
- [ ] 🔧 Cấu hình / CI/CD

## ✅ Checklist
- [ ] Code đã chạy được ở local
- [ ] Không có `console.log` debug trong production code
- [ ] Không có hardcoded secrets
- [ ] CI pipeline pass ✅
```

---

## ⑦ Discord Notifications — Thông báo tự động

**File:** `.github/workflows/notify.yml`

```yaml
name: Discord Notify

on:
  # Thông báo khi deploy thành công
  workflow_run:
    workflows: ["CD Pipeline"]
    types: [completed]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: 📢 Discord Notification
        uses: sarisia/actions-status-discord@v1
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          status: ${{ github.event.workflow_run.conclusion }}
          title: "MediChain Deploy"
          description: |
            **Branch:** ${{ github.event.workflow_run.head_branch }}
            **Status:** ${{ github.event.workflow_run.conclusion }}
            **Commit:** ${{ github.event.workflow_run.head_sha }}
```

**Setup Discord webhook:**
1. Discord → Server Settings → Integrations → Webhooks → New Webhook
2. Copy Webhook URL
3. GitHub → Repo → Settings → Secrets → `DISCORD_WEBHOOK` = URL đó

---

## ⑧ Semantic Versioning — Tự đánh version

**File:** `.github/workflows/release.yml`

```yaml
name: Auto Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: node
          # Tự đọc commit messages để tạo version:
          #   fix(...) → patch (1.0.1)
          #   feat(...) → minor (1.1.0)
          #   feat!(...) hoặc BREAKING CHANGE → major (2.0.0)
```

**Cách hoạt động:**
- Bạn commit theo format: `fix(auth): sửa lỗi đăng nhập` hoặc `feat(ai): thêm tư vấn AI`
- Bot tự tạo PR "Release v1.2.3" với changelog
- Merge PR đó → tự tạo GitHub Release + tag

---

## ⑨ Code Coverage — Đo % code được test

Thêm vào CI workflow (ví dụ backend):

```yaml
  backend-check:
    # ... các step trước ...
    steps:
      - run: npm ci
      - run: npm run test -- --coverage
      
      - name: 📊 Upload Coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          directory: backend/coverage
          flags: backend
```

**Setup:**
1. Vào [codecov.io](https://codecov.io) → đăng nhập bằng GitHub
2. Thêm repo → Copy token
3. GitHub → Secrets → `CODECOV_TOKEN` = token đó

---

## 🎯 Checklist Setup Nhanh cho Project Mới

```
Bước 1: Tạo repo trên GitHub
Bước 2: Copy các file vào đúng vị trí:
  .github/
  ├── workflows/
  │   ├── ci.yml              ← CI check
  │   ├── cd.yml              ← Auto deploy
  │   ├── mobile-ci.yml       ← Flutter CI (nếu có)
  │   ├── notify.yml           ← Discord thông báo
  │   └── release.yml          ← Auto versioning
  ├── dependabot.yml           ← Auto update thư viện
  └── pull_request_template.md ← PR checklist

Bước 3: Thêm Secrets trên GitHub:
  RENDER_DEPLOY_HOOK_BACKEND   ← Render webhook URL
  DISCORD_WEBHOOK              ← Discord webhook URL
  CODECOV_TOKEN                ← Codecov token (optional)

Bước 4: Bật Branch Protection:
  Settings → Rules → Rulesets → Tạo rule cho main

Bước 5: Connect services:
  - Vercel: connect repo → auto deploy frontend
  - Render: connect repo → auto deploy backend  
  - Codecov: connect repo → auto coverage report

Bước 6: Test thử:
  git checkout -b test/ci-check
  # ... sửa gì đó nhỏ ...
  git push origin test/ci-check
  # → Tạo PR → Xem CI có chạy không → Merge → Xem deploy
```

---

## 📌 Quy trình hàng ngày sau khi setup xong

```
1. Tạo branch mới:     git checkout -b feat/ten-tinh-nang
2. Code xong push:      git push origin feat/ten-tinh-nang
3. Tạo PR trên GitHub:  GitHub tự hiện nút "Compare & pull request"
4. Đợi CI xanh:         Bot tự chạy lint + build + test
5. Merge PR:             Bấm "Merge pull request"
6. Auto deploy:          Render + Vercel tự deploy
7. Discord thông báo:   Bot gửi tin "Deploy thành công!"
8. Auto version:         Bot tạo PR "Release v1.x.x" (merge khi ready)
9. Dependabot:           Thứ 2 hàng tuần bot tạo PR update thư viện
```

> **Bạn chỉ làm bước 1-5. Bước 6-9 máy tự chạy.** 🤖

---

## ⚙️ File cấu hình bổ sung

### `.wslconfig` (Giới hạn Docker RAM)

Đặt tại: `C:\Users\<TÊN>\.wslconfig`

```ini
[wsl2]
memory=3GB
processors=2
swap=1GB
```

### Flutter `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    deprecated_member_use: ignore
    use_build_context_synchronously: ignore

linter:
  rules:
    use_null_aware_elements: false
    curly_braces_in_flow_control_structures: false
```

### ESLint config (Next.js)

```js
// eslint.config.mjs
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
  {
    rules: {
      "react-hooks/set-state-in-effect": "warn",
    },
  },
]);

export default eslintConfig;
```

---

*Playbook version 1.0 — Tạo bởi MediChain DevOps Setup, April 2026*

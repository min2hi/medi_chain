# 🚀 Full-Stack CI/CD Automation Playbook

> **Playbook tái sử dụng** cho mọi dự án. Copy file này vào project mới, follow từng bước.

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
| ④ | **CI — Mobile** | Tự động analyze + test + build app | GitHub Actions |
| ⑤ | **CD — Auto Deploy** | Merge xong → deploy nền máy chủ | Các dịch vụ Cloud (Render, Vercel) |
| ⑥ | **Dependabot** | Bot tự update thư viện hàng tuần | GitHub Dependabot |
| ⑦ | **Notifications** | Thông báo khi deploy/fail | GitHub Actions + Slack/Discord |
| ⑧ | **Semantic Versioning** | Tự đánh version + viết changelog | release-please |
| ⑨ | **Code Coverage** | Đo % code được test bảo mật | Codecov / lcov |

---

## ① Branch Protection — Bảo vệ nhánh chính

**Mục đích:** Không cho ai push thẳng vào nhánh production (`main`/`master`). Mọi thay đổi phải lọt qua cổng CI (Linter Tool) và Pull Request.

**Setup:** GitHub → Repo → Settings → Rules → Rulesets
```text
Target branch: main
Rules bật:
  ✅ Require a pull request before merging
  ✅ Require status checks to pass (Thêm các rule tên của CI)
  ✅ Block force pushes
```

---

## ② CI — Frontend Khung chuẩn 

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
        working-directory: frontend
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
        working-directory: backend
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

## ③ CI — Mobile Application (VD: Flutter / React Native)

**File:** `.github/workflows/mobile-ci.yml`

```yaml
name: Mobile CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'mobile/**'
  pull_request:
    branches: [main, develop]
    paths:
      - 'mobile/**'

jobs:
  mobile-check:
    name: 📱 Mobile Build Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # Template bên dưới là của Flutter (thay đổi linh hoạt theo công nghệ dự án thực tế)
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install dependencies
        working-directory: mobile
        run: flutter pub get

      - name: Analyze
        working-directory: mobile
        run: flutter analyze --fatal-infos

      - name: Build Debug App
        working-directory: mobile
        run: flutter build apk --debug --no-pub
```

---

## ④ CD — Auto Deploy (Deployment hook)

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
    name: 🚀 Trigger Server Deployment
    runs-on: ubuntu-latest
    steps:
      # Ví dụ bắt trigger Webhook của Dịch vụ Máy Chủ Đám Mây:
      - name: Trigger Webhook
        run: curl -X POST "${{ secrets.SERVER_DEPLOY_HOOK }}"
```

---

## ⑤ Dependabot — Tự động update thư viện rỗng/lỗi thời

**File:** `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 3

  - package-ecosystem: "npm"
    directory: "/backend"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 3
    
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 2
```

---

## ⑥ Lịch Trình Quản Trị Hàng Ngày Của Human/AI Coder
Dành riêng cho Quy trình khi Setup hoàn chỉnh:

```text
1. Branch riêng:         git checkout -b feat/tinh-nang-moi
2. Code & Push:         git push origin feat/tinh-nang-moi
3. Lập PR (Pull Req):  Yêu cầu Gộp code
4. Check Cổng Bảo Vệ:  CI chạy xanh lét các bước
5. Merge (Hòa Trộn):    Approved
6. CD Tự Động Push:   Máy chủ đám mây bắt sóng và chạy Build lại hệ thống
7. Thông báo kênh Cty: Tin nhắn gởi Slack/Discord thành công!
```
*Tài liệu tự động hóa quy trình phần mềm (Chuẩn Tái Sử Dụng).*

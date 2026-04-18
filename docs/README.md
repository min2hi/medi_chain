# MediChain — Documentation

> Thư mục này chứa toàn bộ tài liệu kỹ thuật và vận hành của dự án.
> File code context cho AI ở root: `../AGENTS.md`

## 📁 Danh sách tài liệu

| File | Mô tả | Đọc khi... |
|------|-------|------------|
| [DEPLOY.md](./DEPLOY.md) | Hướng dẫn deploy lên VPS/Render/Vercel | Cần deploy production |
| [AI_HARNESS_PLAYBOOK.md](./AI_HARNESS_PLAYBOOK.md) | Kiến trúc AI Harness, cách AI được kiểm soát | Muốn hiểu cách AI agent hoạt động trong dự án |
| [AUTOMATION_PLAYBOOK.md](./AUTOMATION_PLAYBOOK.md) | CI/CD pipeline, automation workflows | Debug pipeline, thêm workflow mới |
| [MASTER_BOOTSTRAP_PLAYBOOK.md](./MASTER_BOOTSTRAP_PLAYBOOK.md) | Setup môi trường từ đầu | Onboard thành viên mới, setup máy mới |
| [MIROFISH_SETUP_PLAYBOOK.md](./MIROFISH_SETUP_PLAYBOOK.md) | Setup MiroFish AI simulation engine | Làm việc với module MiroFish |
| [scoring_formula.md](./scoring_formula.md) | Công thức scoring của Recommendation Engine | Hiểu hoặc sửa logic gợi ý thuốc |
| [mobile_migration_plan.md](./mobile_migration_plan.md) | Kế hoạch migration mobile | Reference lịch sử quyết định kiến trúc |

## 🏗️ Quy tắc thêm tài liệu mới

1. **Tài liệu dành cho developer** → đặt vào `docs/`
2. **Context cho AI agent** → cập nhật `AGENTS.md` hoặc `.claude/skills/`
3. **Hướng dẫn vận hành** → cập nhật `docs/DEPLOY.md`
4. **Template code** → đặt vào `.claude/templates/`

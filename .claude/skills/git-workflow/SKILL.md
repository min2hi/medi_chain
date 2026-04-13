# SKILL: Git Workflow & Re-index Rules — MediChain

> Đọc file này trước khi thực hiện bất kỳ thao tác git nào.

---

## Quy Trình Làm Việc Chuẩn

```
1. Lấy task mới
      ↓
2. [AI] gitnexus_query → Tìm hiểu code liên quan
      ↓
3. [AI] gitnexus_impact → Kiểm tra blast radius
      ↓
4. ✍️  Viết code
      ↓
5. [AI] gitnexus_detect_changes → Verify đúng scope
      ↓
6. git add → git commit (message chuẩn)
      ↓
7. npx gitnexus analyze --embeddings → Re-index
```

---

## Commit Message Format (Conventional Commits)

```
<type>(<scope>): <mô tả ngắn bằng tiếng Việt hoặc Anh>

Types:
  feat     → Tính năng mới
  fix      → Sửa bug
  refactor → Cấu trúc lại code (không thêm tính năng, không fix bug)
  chore    → Công việc bảo trì (update deps, config, gitignore)
  docs     → Chỉ sửa documentation
  test     → Thêm/sửa test
  perf     → Cải thiện hiệu năng
  style    → Format, spacing (không ảnh hưởng logic)

Scope (optional): backend | frontend | mobile | db | docker | nginx

Ví dụ:
  feat(backend): thêm endpoint export hồ sơ bệnh án
  fix(mobile): sửa crash khi token hết hạn trên iOS
  refactor(frontend): tách AIChat component thành sub-components
  chore: cập nhật .gitignore thêm .gitnexus
```

---

## Files KHÔNG BAO GIỜ được commit

```gitignore
# Secrets
.env
.env.production
.env.local

# Build artifacts
dist/
build/
.next/
.dart_tool/

# Dependencies
node_modules/

# Database & AI index
.gitnexus/

# Test & temp files (đã có trong .gitignore)
test-*.ts
test-*.js
seed-*.js
update-*.ts
```

---

## Re-index GitNexus — Khi Nào & Lệnh Nào

### Lệnh chuẩn (luôn dùng cái này)

```bash
npx gitnexus analyze --embeddings
```

### Khi nào cần chạy?

| Sự kiện | Cần re-index? |
|---------|--------------|
| Sau `git commit` có thêm/sửa file `.ts`, `.dart` | ✅ Có |
| Sau `git merge` | ✅ Có |
| Thêm service/controller mới | ✅ Có |
| Chỉ sửa CSS, strings, comments | ❌ Không cần |
| Chỉ sửa config files (docker, nginx) | ❌ Không cần |

### Kết quả bình thường

```
✅ "Analysis complete" → Index đã cập nhật
✅ "Already up to date" → Không có commit mới, bỏ qua — đây là bình thường
```

---

## GitNexus Tools — Khi Nào Dùng Gì

| Tình huống | Tool cần dùng |
|-----------|--------------|
| Bắt đầu task mới, chưa biết code ở đâu | `gitnexus_query({query: "tên tính năng"})` |
| Sắp sửa 1 function/class | `gitnexus_impact({target: "TênSymbol", direction: "upstream"})` |
| Muốn hiểu 1 function gọi ai, ai gọi nó | `gitnexus_context({name: "TênSymbol"})` |
| Sắp commit, muốn verify đúng scope | `gitnexus_detect_changes({scope: "staged"})` |
| Muốn đổi tên function/class an toàn | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |

---

## Risk Level Protocol

| Risk | Hành động bắt buộc |
|------|-------------------|
| LOW | Tiến hành bình thường |
| MEDIUM | Cẩn thận, test kỹ |
| HIGH | **BÁO CHO USER trước khi sửa** |
| CRITICAL | **DỪNG LẠI — Thảo luận kế hoạch với user** |

---

## Branch Strategy (Khuyến nghị)

```
main       ← Production-ready code chỉ
develop    ← Integration branch
feature/*  ← Feature branches (ví dụ: feature/add-medication-reminder)
fix/*      ← Bug fix branches (ví dụ: fix/login-crash-ios)
```

> **Lưu ý**: Không force push lên `main`. Mọi thay đổi lớn phải qua PR/review.

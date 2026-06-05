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
5. [Nếu có quyết định kiến trúc] Tạo ADR trong docs/adr/
      ↓
6. [AI] gitnexus_detect_changes → Verify đúng scope
      ↓
7. git add → git commit (message chuẩn, kèm ADR nếu có)
      ↓
8. gitnexus analyze → Re-index (không cần --embeddings cho bug fix/refactor)
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
# Lệnh chuẩn (luôn dùng cái này)
# Đã cài global: npm install -g gitnexus  ← chạy 1 lần khi setup

# Re-index thường (sau bug fix, refactor)
gitnexus analyze

# Re-index đầy đủ (sau khi thêm feature/service mới)
gitnexus analyze --embeddings

# ⚠️  KHÔNG dùng npx gitnexus trên Windows
# → Gây EPERM vì Windows file-lock trên native .dll bindings
# → Fix: npm install -g gitnexus@1.6.3
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

---

## ADR — Ghi Lại Quyết định Kiến Trúc

### Khi nào tạo ADR?

| Tạo ADR | Không cần |
|----------|-----------|
| Chọn thư viện/framework mới | Bug fix, refactor nhỏ |
| Thay đổi kiến trúc có phạm vi lớn | Thêm field vào model |
| Trade-off rõ ràng được chọn | Thay đổi UI/style |
| Từ chối một cách tiếp cận | Update version (không đổi library) |

### Quy trình tạo ADR

```bash
# 1. Copy template
cp docs/adr/ADR-000-template.md docs/adr/ADR-00N-ten-ngan.md

# 2. Điền nội dung: Context, Options, Decision, Consequences

# 3. Commit CÙNG với code thay đổi (không commit riêng)
docs(adr): add ADR-00N ten quyet dinh
```

> **Nguyên tắc:** ADR phải được viết cùng lúc hoặc trước khi code — không phải sau.
> Nếu không có thể giải thích được tại sao chọn cách này, có lẽ cần suy nghĩ lại.

---

## Atomic Commit Discipline — Quy Tắc Vàng

> Học từ thực tế: 65 files thay đổi, 0 commits = không ai biết gì đã xảy ra.
> **Commit sớm, commit thường xuyên, commit nhỏ.**

### Nguyên tắc 1 — 1 commit = 1 concern

```
✅ ĐÚNG:
  refactor(theme): centralize color tokens    ← chỉ theme
  feat(dashboard): redesign patient dashboard ← chỉ dashboard
  fix(router): remove dead /appointment-new   ← chỉ router

❌ SAI:
  fix: sửa màu + thêm form + xóa route + refactor theme
  (Không ai biết cái gì quan trọng, không revert được từng phần)
```

### Nguyên tắc 2 — Commit theo dependency order

```
Thứ tự đúng (foundation trước, feature sau):

1. Core / Foundation  (theme tokens, constants, base classes)
        ↓
2. Pure refactor      (color migration, rename — zero logic change)
        ↓
3. Shared widgets     (components được dùng bởi nhiều screens)
        ↓
4. Feature screens    (dashboard, appointment, records...)
        ↓
5. Routing changes    (sau khi screens đã hoạt động)
        ↓
6. Cleanup / chore    (xóa file không dùng, update models)
```

### Nguyên tắc 3 — Pre-commit checklist bắt buộc

```bash
# Trước KHI git add → chạy:
flutter analyze --no-fatal-warnings
# → Must: "No issues found!"

# Sau KHI git add, trước git commit → chạy:
git diff --staged --stat
# → Kiểm tra: đúng files mình muốn commit không?
# → Không có file thừa, file test, file .env?

# Nếu có nhiều changes chưa commit → nhóm theo concern:
git add lib/core/theme/app_theme.dart
git commit -m "refactor(theme): ..."

git add lib/presentation/screens/dashboard/...
git commit -m "feat(dashboard): ..."
```

### Nguyên tắc 4 — Commit message chuẩn phải giải thích "tại sao"

```
❌ BAD commit messages:
  fix bug
  update ui
  sửa lỗi appointment

✅ GOOD commit messages:
  fix(appointment): replace bool flag with ValueNotifier<int> trigger

  Problem: openAddDialog: bool is only read once in initState.
  When screen is already mounted in IndexedStack, bool changes
  have no effect → dialog never opens from Quick Action.

  Solution: ValueNotifier<int> counter — screen adds listener in
  initState, HomeScreen increments counter on each Quick Action tap.
  Works correctly for repeated taps without app restart.
```

> **Quy tắc:** Đọc commit message sau 6 tháng vẫn phải hiểu được **vấn đề là gì và tại sao chọn cách này**.

### Nguyên tắc 5 — Kiểm tra trạng thái thường xuyên

```bash
# Bắt đầu buổi làm việc:
git status          # biết mình đang ở đâu
git log --oneline -5  # 5 commits gần nhất

# Sau mỗi feature hoàn chỉnh:
git diff HEAD --stat  # xem có bao nhiêu files chưa commit
# Nếu > 10 files → cần commit ngay, đừng để tích lũy

# Khi muốn biết file nào thay đổi:
git diff HEAD --name-only
```

### Nguyên tắc 6 — Không bao giờ để uncommitted quá lâu

| Số files uncommitted | Hành động |
|---------------------|----------|
| 1-5 files | Bình thường, commit sau feature |
| 6-15 files | Commit ngay theo nhóm concern |
| 15+ files | **DỪNG feature mới** — commit hết cái cũ trước |
| 50+ files | Khủng hoảng — phải lập plan commit, review từng file |

---

## Lệnh Git Hữu Ích — Quick Reference

```bash
# Xem trạng thái
git status --short              # ngắn gọn
git log --oneline -10           # 10 commits gần nhất
git diff HEAD --stat            # tổng quan thay đổi chưa commit
git diff HEAD --name-only       # chỉ tên file

# Stage từng nhóm
git add lib/core/theme/         # stage cả folder
git add lib/presentation/screens/dashboard/*.dart  # wildcard
git add -p                      # interactive: chọn từng hunk

# Kiểm tra trước commit
git diff --staged               # xem chính xác sẽ commit gì
git diff --staged --stat        # summary

# Undo an toàn
git restore lib/path/file.dart  # discard working changes (KHÔNG mất staged)
git checkout HEAD -- lib/path/file.dart  # reset file về HEAD
git restore --staged lib/path/file.dart # unstage (giữ changes)

# Sửa commit cuối (chưa push)
git commit --amend              # thêm file hoặc sửa message
```

# [2026-05-13] Consolidate AI Context Layer

## Đã làm

- Xóa `CLAUDE.md` (root) — nội dung 100% duplicate với block `<!-- gitnexus:start -->` trong `AGENTS.md`
- Di chuyển `docs/MEMORY.md` → `.claude/MEMORY.md`
- Di chuyển `docs/retros/` → `.claude/retros/` (3 files)
- Cập nhật 3 references trong `AGENTS.md` trỏ đúng sang `.claude/`
- Cập nhật `docs/README.md`: làm rõ ranh giới docs-for-humans vs .claude-for-AI

## Lý do thay đổi

- `docs/` và `.claude/` bị lẫn lộn: AI memory (MEMORY.md, retros) nằm trong thư mục tài liệu người dùng
- `CLAUDE.md` và `AGENTS.md` cùng root, cùng nội dung GitNexus → 2 sources of truth dễ out-of-sync
- Nguyên tắc: "One place to look" — AI context tập trung hoàn toàn tại `.claude/`

## Kết quả

```
.claude/          ← AI context (MEMORY, retros, skills, templates)
docs/             ← Tài liệu thuần cho người (deploy, playbooks, ADR)
AGENTS.md (root)  ← Single AI entry point
```

## Phải nhớ buổi sau

- `MEMORY.md` giờ ở `.claude/MEMORY.md` (không còn ở `docs/`)
- `retros/` giờ ở `.claude/retros/` (không còn ở `docs/retros/`)
- `CLAUDE.md` đã bị xóa — không recreate
- Mọi AI memory/retro mới phải tạo trong `.claude/`

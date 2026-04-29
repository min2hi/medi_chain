# MediChain — AI Agent Context

> **Đọc section này trước tiên.** Đây là điểm vào duy nhất cho AI context.  
> Sau đó đọc SKILL.md tương ứng với task đang làm.

## Skills Directory

| Khi làm việc với... | Đọc skill file này |
|--------------------|-------------------|
| Kiến trúc tổng thể, stack, luồng hệ thống | `.claude/skills/architecture/SKILL.md` |
| Backend (`backend/src/**`) | `.claude/skills/backend/SKILL.md` |
| Frontend Web (`frontend/src/**`) | `.claude/skills/frontend/SKILL.md` |
| Mobile Flutter (`frontend-mobile/lib/**`) | `.claude/skills/frontend/SKILL.md` |
| Tạo file test, mock data, cleanup | `.claude/skills/testing/SKILL.md` |
| Git commit, re-index GitNexus | `.claude/skills/git-workflow/SKILL.md` |
| GitNexus tools (query, impact, rename...) | Xem section GitNexus bên dưới |

## Templates Directory

> Khi tạo Service/Controller/Route **mới**, PHẢI copy từ template và thay thế placeholder.  
> KHÔNG tự đặt cấu trúc mới — templates đã encode toàn bộ patterns chuẩn của dự án.

| Khi tạo... | Dùng template này |
|-----------|------------------|
| Service mới (`*.service.ts`) | `.claude/templates/service.template.ts` |
| Controller mới (`*.controller.ts`) | `.claude/templates/controller.template.ts` |
| Route file mới (`*.routes.ts`) | `.claude/templates/routes.template.ts` |

**Quy trình tạo feature mới:**
```
1. Copy service.template.ts   → src/services/<tên>.service.ts
2. Copy controller.template.ts → src/controllers/<tên>.controller.ts
3. Copy routes.template.ts    → src/routes/<tên>.routes.ts
4. Tìm-Thay "Example"/"example" → tên feature của bạn
5. Đăng ký route trong index.ts: app.use('/api/<tên>', <tên>Routes)
6. Xóa các comment hướng dẫn (dòng bắt đầu bằng //*)
```

## Hard Limits — Giới Hạn Cứng Cho AI

> Những giới hạn này ngăn AI "làm quá tay" — đập cả một file chỉ để sửa 1 dòng.
> Đây là văn hóa "Small PR" của Google/Meta áp dụng cho AI agent.

### Giới hạn thay đổi mỗi lần

| Loại task | Tối đa dòng thay đổi | Tối đa commit |
|-----------|:--------------------:|:-------------:|
| Bug fix | 50 dòng | 1 commit |
| Refactor | 150 dòng | 1 commit |
| Feature mới | 300 dòng | Chia nhỏ |

### Giới hạn kích thước file

- **Tối đa 400 dòng/file.** Nếu file sắp vượt → tách logic ra file mới trước khi thêm.
- **Không viết function dài hơn 50 dòng.** Dài hơn → phải extract ra hàm con.

### Quy tắc xác nhận

```
AI KHÔNG ĐƯỢC báo "xong" nếu chưa:
  1. Chạy lệnh verify (tsc --noEmit, npm test, npm run build)
  2. Dán output thực tế của lệnh đó vào chat
  3. Nếu output có lỗi → phải fix xong, không được bỏ qua
```

---

## ADR — Khi Nào Phải Tạo

> **ADR (Architecture Decision Record)** = Nhật ký quyết định kiến trúc.  
> Template: `docs/adr/ADR-000-template.md` — Copy, đặt số tiếp theo, điền vào.

AI **BẮT BUỘC đề xuất tạo ADR mới** khi:

| Tình huống | Ví dụ |
|-----------|-------|
| Chọn thư viện/framework mới | Thêm `zod`, đổi từ `axios` sang `fetch` |
| Thay đổi kiến trúc có phạm vi lớn | Thêm cache layer, tách microservice |
| Quyết định trade-off rõ ràng | Chọn eventual consistency thay vì strong consistency |
| Từ chối một cách tiếp cận | "Không dùng X vì Y" cũng cần ghi lại |

AI **KHÔNG cần tạo ADR** cho:
- Bug fix, refactor nhỏ, thêm field vào model
- Thay đổi UI/style
- Update dependency version (không đổi library)

**Quy trình khi AI gặp tình huống cần ADR:**
```
1. Thông báo: "Quyết định này nên được ghi vào ADR"
2. Đề xuất nội dung ADR (context, options, decision, consequences)
3. Tạo file: docs/adr/ADR-00N-ten-ngan.md
4. Nhắc commit cùng với code thay đổi (không commit riêng sau)
```

## Memory System — Duy Trì Context Giữa Các Buổi Làm Việc

> LLM mất trí nhớ sau mỗi session. Memory System giải quyết vấn đề này.
> Không cần tool phức tạp — chỉ cần 2 file markdown.

### Cấu trúc

```
docs/
├── MEMORY.md              ← Index tổng hợp mọi quyết định đã ghi nhớ
└── retros/
    └── YYYY-MM-DD-topic.md ← Nhật ký sau mỗi buổi làm việc quan trọng
```

### Quy tắc viết Retro

Sau bất kỳ buổi làm việc nào có **thay đổi kiến trúc, fix bug khó, hoặc cài thư viện mới**, AI PHẢI tạo file retro với nội dung:

```markdown
## [YYYY-MM-DD] [Tên ngắn gọn của task]

### Đã làm
- Gạch đầu dòng những gì đã hoàn thành

### Vấn đề gặp phải & cách giải quyết
- Ghi rõ để buổi sau không mò lại từ đầu

### Còn dang dở
- Task nào chưa xong, blocker là gì

### Phải nhớ buổi sau
- Các quyết định kỹ thuật quan trọng cần nhớ
```

### Bắt đầu buổi làm việc mới

```
Bước đầu tiên của MỌI buổi làm việc:
  1. Đọc file retro gần nhất trong docs/retros/
  2. Đọc MEMORY.md để biết các quyết định đã chốt
  3. Chỉ sau đó mới bắt đầu code
```

---

## Self-Check Trước Khi Kết Thúc Task

```
IMPACT ANALYSIS
[ ] Đã chạy gitnexus_impact trước khi sửa BẤT KỲ hàm cũ nào
[ ] Tất cả callers d=1 (WILL BREAK) đã được cập nhật đồng bộ
[ ] Nếu Risk = HIGH/CRITICAL → đã báo cáo cho user trước khi sửa

CODE QUALITY
[ ] Đã đọc SKILL.md tương ứng với task
[ ] Không có file test/mock/seed còn sót lại
[ ] Không có console.log debug trong production code
[ ] Không có hardcoded secrets
[ ] Không có import unused

ARCHITECTURE
[ ] Response format đúng chuẩn { success, data?, message?, errorCode? }
[ ] Controller không chứa business logic
[ ] Protected routes có authMiddleware
[ ] Prisma query dùng select (không leak sensitive fields)

TEMPLATES
[ ] Nếu tạo Service/Controller/Route mới → đã dùng template từ .claude/templates/
[ ] Nếu có quyết định kiến trúc mới → đã tạo hoặc đề xuất ADR tương ứng

HARD LIMITS
[ ] Số dòng thay đổi không vượt giới hạn (bug≤50, feature≤300)
[ ] Không có file nào vượt 400 dòng sau khi chỉnh sửa
[ ] Đã chạy lệnh verify và paste output thực tế vào chat

MEMORY SYSTEM
[ ] Nếu buổi làm việc quan trọng → đã tạo retro trong docs/retros/
[ ] Nếu có quyết định kỹ thuật mới → đã cập nhật MEMORY.md
```

---

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **medi_chain** (2431 symbols, 3595 relationships, 60 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/medi_chain/context` | Codebase overview, check index freshness |
| `gitnexus://repo/medi_chain/clusters` | All functional areas |
| `gitnexus://repo/medi_chain/processes` | All execution flows |
| `gitnexus://repo/medi_chain/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

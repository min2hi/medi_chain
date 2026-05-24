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

## File & Code Organization — Nguyên Tắc SRP

> Không có giới hạn số dòng cứng. Câu hỏi đúng không phải "file này bao nhiêu dòng?"
> mà là **"file này có đúng một lý do để thay đổi không?"** (Single Responsibility Principle)

### Khi nào PHẢI tách file

| Tình huống | Hành động |
|-----------|----------|
| Widget/function có thể **reuse** ở màn hình khác | Tách ra `widgets/` hoặc file riêng |
| Class/widget có **state và logic độc lập** | Tách file — dễ test riêng |
| File có **nhiều hơn 1 concern** rõ ràng | Tách theo concern |
| PR diff quá lớn, reviewer khó đọc | Chia nhỏ thành PR logic |

### Khi nào KHÔNG cần tách

| Tình huống | Giữ nguyên |
|-----------|----------|
| File 600 dòng nhưng **1 class, 1 concern rõ ràng** | OK — Google `cupertino/text_field.dart` là 1600+ dòng |
| Private sub-widget **chỉ dùng trong 1 screen** | Giữ trong cùng file, dùng `_` prefix |
| Logic tách ra sẽ **khó đọc hơn** (over-engineering) | Không tách |

### Câu hỏi để quyết định

```
Trước khi tách file, hỏi:
1. Widget/function này có thể dùng lại ở nơi khác không?
2. File này có nhiều hơn 1 lý do để thay đổi không?
3. Khi tách ra, code có DỄ ĐỌC HƠN không?
4. Widget này có state/lifecycle riêng biệt không?

Nếu ≥ 2 câu = YES → Tách
Còn lại → Giữ nguyên
```

### Quy tắc xác nhận

```
AI KHÔNG ĐƯỢC báo "xong" nếu chưa:
  1. Chạy lệnh verify (tsc --noEmit, npm test, npm run build)
  2. Dán output thực tế của lệnh đó vào chat
  3. Nếu output có lỗi → phải fix xong, không được bỏ qua
```

### Giới hạn thay đổi mỗi lần (Small PR culture)

| Loại task | Guideline |
|-----------|----------|
| Bug fix | Nhỏ nhất có thể — chỉ đủ fix bug |
| Refactor | 1 concern tại 1 thời điểm, không mix feature + refactor |
| Feature mới | Tách thành commits theo layer (schema → service → controller → UI) |


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
.claude/
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
  1. Đọc file retro gần nhất trong .claude/retros/
  2. Đọc .claude/MEMORY.md để biết các quyết định đã chốt
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
[ ] Không có câu lệnh verify bỏ qua — phải paste output thực tế
[ ] Mỗi commit chỉ 1 concern (bug fix không kèm refactor, UI không kèm schema)
[ ] Nếu tách file mới: có ít nhất 1 trong các lý do SRP hợp lệ (reuse/concern/lifecycle)
[ ] Không over-engineer: tách file chỉ khi code DỄ ĐỌC HƠN sau khi tách

MEMORY SYSTEM
[ ] Nếu buổi làm việc quan trọng → đã tạo retro trong .claude/retros/
[ ] Nếu có quyết định kỹ thuật mới → đã cập nhật .claude/MEMORY.md
```

---

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **medi_chain** (5631 symbols, 10825 relationships, 136 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

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

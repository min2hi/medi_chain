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
```

---

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **medi_chain** (1013 symbols, 1776 relationships, 40 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/medi_chain/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/medi_chain/context` | Codebase overview, check index freshness |
| `gitnexus://repo/medi_chain/clusters` | All functional areas |
| `gitnexus://repo/medi_chain/processes` | All execution flows |
| `gitnexus://repo/medi_chain/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index becomes stale. Re-run analyze to update it:

```bash
npx gitnexus analyze
```

If the index previously included embeddings, preserve them by adding `--embeddings`:

```bash
npx gitnexus analyze --embeddings
```

To check whether embeddings exist, inspect `.gitnexus/meta.json` — the `stats.embeddings` field shows the count (0 means no embeddings). **Running analyze without `--embeddings` will delete any previously generated embeddings.**

> Claude Code users: A PostToolUse hook handles this automatically after `git commit` and `git merge`.

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
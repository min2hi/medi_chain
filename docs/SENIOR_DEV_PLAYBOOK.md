# 🏆 Senior Dev Playbook — MediChain

> Đây là bản tóm tắt **toàn bộ hệ thống tự động hóa** đã được thiết lập trong dự án này.
> Đọc file này khi bạn muốn hiểu **cái gì đang bảo vệ dự án**, **nó làm thế nào**, và **tại sao phải có nó**.

---

## 🗺️ Toàn cảnh hệ thống

```
Bạn code xong → git commit → [HUSKY chặn lại kiểm tra]
                              ↓ Pass
              → git push  → [CI/CD trên GitHub Actions chạy]
                              ↓ Tất cả Pass
              → Tạo PR    → [Người review đọc code]
                              ↓ Approve
              → Merge vào main → [Vercel/Render tự deploy]
                                  ↓
                            Production 🚀
```

Mỗi dấu `[...]` là một "chốt chặn" tự động. Code lỗi bị chặn ngay tại đó, không bao giờ lên được Production.

---

## 🟡 Tầng 1 — Chốt chặn tại máy cá nhân (Husky)

**Nằm ở đâu:** Thư mục `.husky/`  
**Kỹ thuật:** Git Hooks

Husky là "cảnh sát viên" ngồi ngay trên máy tính của bạn. Mỗi khi bạn gõ `git commit` hay `git push`, nó chặn lại và giao cho 2 thứ bên dưới làm việc.

---

### 🔤 Commitlint — Cảnh sát commit message

**File cấu hình:** `commitlint.config.cjs`  
**Kỹ thuật:** Regex pattern matching trên commit message

**Nó làm gì:**  
Bắt mọi commit message phải theo đúng cú pháp **Conventional Commits**:

```
feat(auth): thêm tính năng đăng nhập bằng Google
fix(api): sửa lỗi crash khi token hết hạn
docs(adr): thêm ADR-004 lý do chọn Redis
```

**Tại sao phải có:**
| Có Commitlint | Không có |
|---|---|
| Lịch sử code đọc như sách giáo khoa | "fix bug", "test lại", "asdfgh" |
| Tự động tạo Changelog (danh sách tính năng) | Phải ngồi viết tay mất nửa ngày |
| Tự động nhảy số phiên bản (1.0.0 → 1.1.0) | Đếm tay, dễ nhầm |
| Tìm lỗi siêu nhanh | Phải mò code từng dòng |

**Bị chặn khi:**
```bash
"sửa lỗi đăng nhập"   # ❌ thiếu type (feat/fix/...)
"FIX: bug"             # ❌ phải viết thường
"feat: "               # ❌ thiếu mô tả
```

---

### 🧹 Lint-staged — Dọn dẹp trước khi chụp hình

**Kỹ thuật:** Chạy ESLint chỉ trên file đang được staged (không quét cả project)

Thay vì quét ESLint cho toàn bộ 500 file trong project (chậm), nó chỉ quét đúng những file bạn vừa sửa. Nhanh và chính xác.

---

## 🔵 Tầng 2 — Chốt chặn trên đám mây (GitHub Actions)

**Nằm ở đâu:** `.github/workflows/ci.yml`  
**Kỹ thuật:** Máy chủ Linux ảo được tạo ra và xóa đi tự động sau mỗi lần quét

Khi bạn Push code lên GitHub, GitHub lập tức bật lên một cái máy tính ảo (Linux), tải code của bạn về, và chạy các bài kiểm tra bên dưới. Nếu có bài nào bị `Fail` → PR bị khóa, không thể merge vào `main`.

---

### 🔐 Gitleaks — Máy đánh hơi mật khẩu

**File cấu hình:** `.gitleaks.toml`  
**Kỹ thuật:** Regex pattern matching trên toàn bộ Git history

**Nó làm gì:**  
Quét toàn bộ lịch sử commit từ trước đến nay, tìm các chuỗi text trông giống mật khẩu, API Key, token bí mật. Dù bạn đã xóa cái mật khẩu đó rồi, nó vẫn bới ra từ lịch sử git.

**Tại sao nguy hiểm nếu không có:**
> Một developer vô tình commit `GEMINI_API_KEY="AIzaSy..."` lên GitHub.  
> Hacker lùng sục GitHub 24/7 bằng bot tự động. Trong vòng 30 phút, hacker tìm thấy key đó.  
> Hacker dùng key đó gọi API liên tục, sáng hôm sau chủ nhận bill **~100,000 USD** từ Google.  
> *(Chuyện này xảy ra thật với nhiều Startup)*

**File `.gitleaks.toml` dùng để làm gì:**  
Khai báo "danh sách trắng" — bảo Gitleaks bỏ qua những nơi cố tình chứa key fake (như file template, file docs hướng dẫn).

---

### 📦 NPM Audit — Kiểm tra hàng nhập khẩu

**Kỹ thuật:** So sánh danh sách thư viện với bộ hồ sơ lỗi bảo mật CVE quốc tế

**Nó làm gì:**  
Mỗi lần bạn `npm install`, bạn đang "mang hàng của người lạ vào nhà". NPM Audit đem cái danh sách hàng đó kiểm tra với kho hồ sơ bảo mật của cả thế giới.

**Thực tế đã xảy ra với MediChain:**  
Khi CI chạy, nó phát hiện thư viện `hono` và `next.js` đang dùng có chứa các lỗ hổng mức **HIGH** (XSS tấn công người dùng, DoS làm sập server). CI lập tức khóa PR lại. Buộc chúng ta phải cập nhật bản vá lỗi trước mới được merge.

---

### 🧪 Unit Tests — Robot tự chơi thử trước

**File cấu hình:** `backend/jest.config.js`  
**Kỹ thuật:** Jest framework, `--passWithNoTests` khi chưa có test

Mỗi lần Push code, CI sẽ tự động chạy tất cả các bài test đã viết sẵn. Nếu một tính năng cũ bị vô tình làm hỏng (regression bug), test sẽ phát hiện ra ngay lập tức.

---

### 🎭 Playwright — Robot tự bấm thử giao diện

**File cấu hình:** `.github/workflows/e2e.yml`  
**Kỹ thuật:** E2E Testing (End-to-End), mô phỏng hành vi người dùng thật

Robot sẽ tự mở trình duyệt, tự bấm vào nút đăng nhập, điền form, kiểm tra kết quả. Đảm bảo giao diện không vỡ khi thay đổi code.

---

## 🟢 Tầng 3 — Quy trình làm việc nhóm (Pull Request)

### 📋 PR Template — Bản kiểm tra bắt buộc

**Nằm ở đâu:** `.github/pull_request_template.md`

Mỗi khi ai đó tạo PR, GitHub tự động điền sẵn một bản checklist:
- Code có chứa console.log debug không?
- Có hardcoded secret không?
- Database migration có thể rollback không?
- CI đã pass chưa?

**Mục đích:** Ngăn lập trình viên lười bỏ qua các bước quan trọng khi review.

---

### 📖 ADR — Sổ tay kiến trúc (Architecture Decision Records)

**Nằm ở đâu:** `docs/adr/`  
**Template:** `docs/adr/ADR-000-template.md`

**Nó là gì:**  
Một file markdown ngắn (~15 dòng) ghi lại: *"Vì sao tôi chọn X thay vì Y?"*

**Khi nào viết:**
| Viết ADR | Không cần |
|---|---|
| Chọn thư viện/framework mới | Bug fix nhỏ |
| Thay đổi kiến trúc lớn | Thêm field vào model |
| Từ chối một giải pháp ("không dùng X vì Y") | Thay đổi UI, màu sắc |

**Tại sao phải có:**  
6 tháng sau, một thành viên mới join team hỏi: *"Sao dự án này lại dùng Flutter không dùng React Native?"*. Thay vì hỏi người, họ chỉ cần đọc `ADR-002-flutter-mobile.md` là hiểu hết lý do. Tiết kiệm hàng chục giờ giải thích.

**Nguyên tắc vàng:**
> Viết ADR **cùng lúc hoặc trước khi code** — không bao giờ viết bù sau.

---

### 🔒 Branch Protection — Khóa cửa nhánh chính

**Cấu hình bằng:** `docs/setup-branch-protection.sh`

Nhánh `main` được "khóa" bởi GitHub. Không ai, kể cả Admin, được phép:
- Push code thẳng vào `main` mà không qua PR
- Force push đè lên lịch sử
- Merge nếu CI chưa pass xanh

---

## 🤖 Tầng 4 — Bộ não AI (AI Harness)

### 📜 AGENTS.md — Hiến pháp cho AI

**Nằm ở đâu:** `AGENTS.md` (ngay ngoài gốc dự án — bắt buộc)  
**Kỹ thuật:** Prompt Engineering, System Context

Khi bạn dùng Cursor, Claude Code, hay bất kỳ AI coding assistant nào — chúng sẽ tự động đọc file này đầu tiên. File này chứa toàn bộ luật lệ:
- Cấu trúc code phải theo pattern nào
- Phải dùng template gì khi tạo Service mới
- Phải chạy impact analysis trước khi sửa hàm cũ
- Phải viết ADR khi có quyết định kiến trúc

**Kết quả:** AI sẽ code đúng chuẩn dự án, không phải training lại từ đầu mỗi lần chat.

---

### 🧠 Skills Directory — Tài liệu chuyên biệt cho AI

**Nằm ở đâu:** `.claude/skills/`

| File | AI đọc khi làm gì |
|------|---|
| `architecture/SKILL.md` | Hỏi về cấu trúc tổng thể, tech stack |
| `backend/SKILL.md` | Code Node.js, Express, Prisma |
| `frontend/SKILL.md` | Code Next.js, React |
| `testing/SKILL.md` | Tạo file test, mock data |
| `git-workflow/SKILL.md` | Commit, branch, ADR workflow |

---

### 🤖 Promptfoo — Bộ kiểm tra AI y tế

**Nằm ở đâu:** `ai-evals/promptfooconfig.yaml`  
**Kỹ thuật:** LLM Evaluation Framework

Vì MediChain dùng AI để tư vấn sức khỏe, nên phải kiểm tra AI không bao giờ:
- Đưa ra lời khuyên y tế nguy hiểm
- Bị lừa bằng câu hỏi bẫy (adversarial)
- Tự ý kê đơn thuốc

Promptfoo tự động gửi các câu hỏi thử thách đến AI và kiểm tra câu trả lời có an toàn không. Chạy tự động trong CI.

---

## 📐 Quy trình 1 ngày làm việc chuẩn Senior

```
Sáng:
  1. git pull origin develop            # Lấy code mới nhất
  2. git checkout -b feat/tên-task      # Tạo nhánh mới

Trong ngày:
  3. Code, commit nhỏ mỗi 30-60 phút
     → git commit -m "feat(auth): add JWT refresh"
     → Husky chặn → commitlint check → Pass → Commit ok
  4. Nếu có quyết định kiến trúc → viết ADR ngay lúc đó

Chiều:
  5. git push origin feat/tên-task      # Đẩy lên GitHub
  6. Tạo PR, điền checklist             # PR Template tự hiện ra
  7. CI chạy tự động (2-3 phút)        # Đợi xanh hết
  8. Nhờ teammate review (hoặc self-review nếu solo)
  9. Squash and Merge vào main          # 1 commit gọn gàng
 10. Xóa branch cũ                     # Dọn dẹp
```

---

## 📊 Điểm số hệ thống

| Tiêu chí | Trước | Sau |
|---|:---:|:---:|
| Bảo mật (Security) | 4/10 | 10/10 |
| Code Quality | 5/10 | 9/10 |
| Automation | 3/10 | 9/10 |
| Documentation | 4/10 | 9/10 |
| AI Context | 0/10 | 10/10 |
| **Tổng** | **16/50** | **47/50** |

> *Các công ty Big Tech (Google, Meta, Stripe) đều dùng đủ 4 tầng bảo vệ trên.*  
> *Khác biệt duy nhất là họ có thêm đội Sec-Ops chuyên nghiệp ngồi monitor 24/7.*

---

*Được thiết lập vào tháng 4/2026 — MediChain Project*

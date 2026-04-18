# 🌌 THE AI-NATIVE MASTER PLAYBOOK (BIG TECH EDITION)

> **Dành cho Senior Architect & AI Agents.**
> Đây không chỉ là một tài liệu setup cấu hình. Đây là **bản thiết kế lõi (Core Blueprint)** của một hệ sinh thái phần mềm được dẫn dắt bằng Trí tuệ Nhân tạo. Bất kỳ dự án quy mô lớn nào khởi tạo sau này, hãy copy toàn bộ playbook này và ra lệnh cho AI: *"Tái thiết lập hệ thống chuẩn theo kiến trúc trong đây"*.

Sự vĩ đại của hệ thống nằm ở việc kết hợp được **5 Trụ cột Công nghệ** vào làm một:

---

## 🏛️ TRỤ CỘT 1: HẠ TẦNG & TỰ ĐỘNG HÓA (THE INFRASTRUCTURE)

Cỗ máy CI/CD không có điểm mù, trải dài từ Web, Mobile đến Backend.

### 1. The Automation Pipeline (9 Bước CI/CD)
Mọi thao tác commit đều bị hút vào một dây chuyền tự động khép kín:
- **Branch Protection:** Cấm tuyệt đối push thẳng vào `main`. Bắt buộc dùng Pull Request.
- **Continuous Integration (CI):** 
  - `ci.yml`: Chặn cửa code Frontend/Backend lỗi qua `eslint` và `tsc`.
  - `mobile-ci.yml`: Máy chủ CI gánh lệnh `build` và `analyze` cho máy local.
- **Continuous Deployment (CD):** `cd.yml` tự động gọi Webhook bắt Server (Render/Vercel/AWS) release bản mới.
- **The Bots:**
  - `Dependabot` bảo trì update thư viện tự động.
  - `Semantic Release` đọc commit ghi chú (`fix:`, `feat:`) để nâng version phần mềm tự động.
  - Phủ sóng test coverage bằng báo cáo của `Codecov`.
  - Mọi trạng thái thành công/bại đều Ping về nền tảng Chat (Discord/Slack).

### 2. Quản lý Tài nguyên Cục bộ (Local Isolation)
- **`.wslconfig` Capping (Dành cho nền tảng Windows):** Trấn áp mức tiêu hao RAM và Swap tùy theo cấu hình vật lý. Bảo vệ an toàn tuyệt đối chống OOM (Out Of Memory).
- **Docker Multi-Stage:** Database, Frontend, Backend phải dùng cấu trúc Image đa lớp và giới hạn cấp phát RAM nghiêm ngặt cho mỗi Container.

---

## 🧠 TRỤ CỘT 2: HỆ TRI THỨC ĐỒ THỊ (GITNEXUS KNOWLEDGE GRAPH)

AI sẽ mù nếu không có Ngữ cảnh. Biến Codebase của bạn thành Graph Database.

### 1. Các Quy Tắc Cứng (Hard Rules) Kìm Cương AI
*Luôn luôn thêm vào mục AI Rules (ví dụ `AGENTS.md`) của bất kì dự án nào:*
- **NEVER:** Không bao giờ cho AI tự tiện sửa function/Class mà KHÔNG chạy lệnh phân tích `impact` đo độ "nổ" rủi ro.
- **Risk Level Protocol:** Nếu mức tàn phá của code (Blast Radius) là Cấp Độ Cao, AI phải xin phép Architect (Người dùng) trước khi thực thi.
- Yêu cầu AI tự động generate Vector Embeddings sau mỗi đợt cấu trúc dự án.

---

## 🛡️ TRỤ CỘT 3: HARNESS ENGINEERING (LỚP ÁO GIÁP CODE)

Lớp vỏ ngăn chặn thảm họa viết code sai do ảo giác của mô hình ngôn ngữ (Hallucination).

### 1. Output Guardrails (Husky & lint-staged)
- Ở gốc dự án, luôn dùng Tool Hook (ví dụ `husky`) tạo hệ thống chặn cửa.
- Mỗi lần lưu phiên bản (commit), code phải bị chọt qua Linter và Compiler (TypeScript, Dart, v.v.).
- Sai cú pháp -> Commit bị tự động HỦY BỎ. Không khoan nhượng.

### 2. Test Evaluation Harness (Unit Test Kịch Bản Prompt)
- Nếu App có tích hợp AI, luôn thiết lập bộ Eval Harness (ví dụ `Promptfoo` hoặc `DeepEval`).
- Máy chủ sẽ chạy tự động hàng trăm kịch bản ranh giới đỏ (Red-teaming). Kiểm định định kì xem các mô hình có vi phạm các tiêu chuẩn Trọng Hệ (Bảo mật, An toàn nội dung) của dự án hay không.

---

## 🔮 TRỤ CỘT 4: AGENTIC SIMULATION (CỘT MỐC ADVANCED)

Xây dựng kho tri thức mô phỏng sâu (Deep Simulation) khi phát triển nghiệp vụ rủi ro cao.

- Tích hợp một hệ thống mô phỏng Swarm Intelligence (Ví dụ Engine MiroFish / OASIS). Không dùng AI chỉ để Chat 1-1, mà dùng hàng ngàn Agents giả lập hành vi người dùng, đánh trận giả các quy trình nghiệp vụ trước khi tung ra thị trường cho người thật dùng. 

---

## 🚀 TRỤ CỘT 5: RUNTIME RESILIENCE (BẢO VỆ SERVER THỰC TẾ)

Bảo vệ máy chủ trước áp lực tải (Scale-up) hàng ngàn Users gọi API cùng lúc.

### 1. Database Transaction Pooling
- **Luật:** Không bao giờ cho App Server chọc thẳng 1:1 vào Database.
- **Áp dụng:** Nhúng Connection Pooler (Ví dụ `PgBouncer` cho Postgres) đứng làm Proxy điều phối nội bộ. Ngăn chặn vỡ Transaction Limit khi thực thi các tác vụ lấy dữ liệu lớn.

### 2. Structured JSON Logging
- **Luật:** Xóa sổ hoàn toàn cơ chế log đồng bộ thô sơ (`console.log`) trên môi trường Production.
- **Áp dụng:** Dùng bộ thư viện Logging xử lý dạng JSON (Như `Pino` cho Node). Log được ghi siêu tốc, máy chủ Cloud giám sát dễ dàng search và filter mà không làm sập Event Loop.

### 3. Centralized Error Handler (Lưới Hứng Đạn Cuốn Cùng)
- **Luật:** Cấm Unhandled Rejections làm văng Memory Server.
- **Áp dụng:** Tại lớp nền phía sau cùng của Router hệ thống, setup Middleware dọn dẹp lỗi. Trả kết quả JSON giấu nhẹm StackTrace ra khỏi môi trường Prod nhưng vẫn thông báo lỗi cho quản trị viên.

### 4. Code & Env Quality Gates (Thiết Quân Luật)
- **Static Environment Guard:** Dùng thư viện Validation (Zod / t3-env / Joi) bọc toàn bộ Biến Môi Trường `process.env`. Thiếu 1 trường cấu hình, App **TỪ CHỐI KHỞI ĐỘNG** ngay ở giây số 0 và báo đỏ, tránh lỗi logic ngầm lúc Data vận hành.
- **Commitlint:** Ép buộc định dạng Conventional Commits. Bất kể là AI hay Lập trình viên nếu gõ message rác ("fix loi ne") sẽ bị Hook đá văng ra khỏi quá trình gởi code, bắt buộc tuân thủ (VD: `fix(auth): ...`).

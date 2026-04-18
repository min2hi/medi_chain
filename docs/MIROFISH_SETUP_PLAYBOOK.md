# 🐋 MIROFISH SOWRM INTELLIGENCE - SETUP PLAYBOOK

> **Công năng:** Cẩm nang này giúp bạn cài đặt, vận hành và nhúng **Engine Giả lập Bầy đàn AI - Multi-agent Engine** vào bất kỳ dự án hệ thống nghiệp vụ lõi nào. Bạn sử dụng khung này để setup mạng lưới các AI Agents "nói chuyện" và "mô phỏng" thực tại thay vì chỉ tạo Chatbot tương tác 1 vòng lặp.

---

## 🛠️ YÊU CẦU HỆ THỐNG (Prerequisites)

Nền tảng này lai ghép giữa Frontend Node và Engine mô phỏng Python:

1. **Node.js:** Phiên bản `18+` (Bắt buộc).
2. **Python:** Dùng đúng phiên bản `3.11` hoặc `3.12` (Không xài cao hơn do dependency thư viện lõi AI có thể lỗi thời).
3. **uv:** Trình quản lý package Python hiện đại chuẩn mới (Chạy `curl -LsSf https://astral.sh/uv/install.sh | sh` hoặc tham khảo cách cài UV gốc).

---

## 🔑 BIẾN MÔI TRƯỜNG DỮ LIỆU ĐÁM MÂY

File cấu hình `.env` bắt buộc:

```env
# 1. Cổng LLM API (Tương thích OpenAI REST SDK)
LLM_API_KEY=your_api_key_goc
LLM_BASE_URL=https://api.groq.com/openai/v1   # Khuyên dùng cổng Groq để tiết kiệm API Rate
LLM_MODEL_NAME=llama3-70b-8192

# 2. Hệ Thống Cấy Ghép Ký Ức (Zep Memory API)
# Cho phép 100 Agent giao tiếp chéo không tràn ngữ cảnh
ZEP_API_KEY=your_zep_key_cloud
```

---

## 🚀 QUY TRÌNH DEPLOY HỆ THỐNG

### Lựa chọn 1: Cài đặt Cục bộ (Trực tiếp bằng Source Code)
Mở cấu trúc tại thư mục Repo và chạy lệnh Setup vĩ mô:

```bash
# Lệnh gom tự động: Cài NPM Packages -> Tổ chức môi trường Python ảo venv
npm run setup:all
```

### Lựa chọn 2: Quản lý qua Container (Chuẩn Big Tech Prod)
Dành cho Server hoặc Host:
```bash
docker compose up -d
```

---

## 🎮 KHỞI ĐỘNG HỆ THỐNG (Bật Máy Móc Mô Phỏng)

Chạy lệnh All-in-one dưới đây, Hệ điều hành sẽ bật song song 2 cổng:

```bash
npm run dev
```

**Truy xuất:**
- 🌐 **Dashboard Theo Dõi (Tương tác UI):** `http://localhost:3000`
- ⚙️ **Engine Mô Phỏng Logic (API):** `http://localhost:5001`

---

## 🧠 SỬ DỤNG CHO DỰ ÁN MỚI NHƯ THẾ NÀO?

Bất cứ dự án Phần Mềm nào khi cấy cái Engine giả lập bầy đàn này vào:

1. **Gieo Tri Thức Mồi:** Bơm tài liệu Data nguồn (Luật công ty, Cẩm nang Kỹ thuật, Phác đồ) vào thư mục Seed.
2. **Tạo Môi Trường Quan Sát Lỗ Hổng:** Tạo kịch bản bắt 10 AI đóng vai "Khách hàng khắt khe" để chất vấn API Backend chính của bạn vào buổi đêm. Đo lường tỷ lệ pass xem có rủi ro lỗ hổng bảo mật hoặc logic nào không.
3. **Cảnh Báo Về Nguồn Lực:** Các LLM Agent tương tác độc lập (N-O-N) kéo cực kỳ nhiều Token. Luôn phải chốt chặn Threshold API. 

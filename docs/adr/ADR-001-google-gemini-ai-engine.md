# ADR-001: Chọn Google Gemini làm AI Engine thay vì GPT-4 / Claude

**Ngày:** 2026-04-01  
**Trạng thái:** Accepted  
**Người quyết định:** MediChain Team

---

## Bối cảnh (Context)

MediChain cần một Large Language Model (LLM) để cung cấp tính năng:
- AI Chat tư vấn sức khỏe
- Medical NLU (entity extraction, disease prediction)
- Recommendation Engine (kết hợp với vector search)

Yêu cầu: chi phí thấp nhất có thể, API ổn định, context window đủ lớn để load lịch sử chat và hồ sơ bệnh nhân.

## Các lựa chọn đã cân nhắc (Options Considered)

### Lựa chọn A: Google Gemini API (gemini-1.5-flash / gemini-2.0-flash)
- **Ưu:**
  - Free tier rất rộng rãi (15 RPM, 1M tokens/day với Flash)
  - Context window 1M tokens — đủ để load cả hồ sơ bệnh án
  - Tốc độ nhanh, latency thấp với Flash model
  - Google AI SDK tích hợp tốt với TypeScript
  - Có embedding API (`text-embedding-004`) dùng cho vector search
- **Nhược:**
  - Chưa phổ biến bằng OpenAI trong cộng đồng
  - Một số safety filter khá strict (cần tune system prompt)

### Lựa chọn B: OpenAI GPT-4o / GPT-4o-mini
- **Ưu:** Phổ biến nhất, tài liệu nhiều, community lớn
- **Nhược:**
  - Không có free tier production — tốn tiền từ ngày đầu
  - GPT-4o-mini rẻ nhưng kém hơn Gemini Flash ở một số task
  - Context window nhỏ hơn (128K vs 1M)

### Lựa chọn C: Anthropic Claude 3 Haiku/Sonnet
- **Ưu:** Rất tốt cho medical reasoning, ít hallucination
- **Nhược:**
  - Không có free tier
  - API pricing cao hơn OpenAI
  - Ít tài liệu tiếng Việt

### Lựa chọn D: Groq (Meta Llama / Mixtral)
- **Ưu:** Tốc độ inference cực nhanh (Groq LPU), free tier
- **Nhược:**
  - Model nhỏ hơn, kém hơn cho medical domain
  - Không có embedding API riêng
  - Dùng cho pipeline NLU nhanh, không phải main AI engine

## Quyết định (Decision)

**Chọn:** Lựa chọn A — Google Gemini API

**Lý do chính:**
1. Free tier đủ cho MVP và demo (không tốn tiền trong giai đoạn phát triển)
2. Context window 1M token — quan trọng để load đầy đủ hồ sơ bệnh nhân vào prompt
3. Có embedding API cùng nhà cung cấp → giảm phụ thuộc vào nhiều vendor

**Groq được dùng bổ sung** cho Medical NLU pipeline (cần tốc độ cao, context ngắn).

## Hệ quả (Consequences)

### Tích cực
- Chi phí $0 trong giai đoạn phát triển
- Có thể load toàn bộ hồ sơ bệnh án vào 1 request
- Embedding và chat cùng nhà cung cấp → đơn giản hơn

### Tiêu cực / Trade-off
- Nếu Google thay đổi pricing hoặc free tier → phải migrate
- Safety filter của Gemini đôi khi từ chối câu hỏi y tế hợp lệ → cần tune system prompt cẩn thận

### Rủi ro cần theo dõi
- Theo dõi thay đổi pricing của Google AI Studio hàng quý
- Nếu Gemini Free tier bị giới hạn → fallback sang Groq (đã có sẵn)

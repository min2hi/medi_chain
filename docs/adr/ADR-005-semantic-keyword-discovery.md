# ADR-005: Semantic Keyword Discovery (Phase 2 Clinical Rules Engine)

## Trạng thái
**Accepted** - 2026-04-20

## Ngữ cảnh
Bất kỳ hệ thống quy tắc y tế (Clinical Rules Engine) dựa trên từ khóa nào cũng có điểm yếu chết người: **không thể lường trước mọi cách diễn đạt của bệnh nhân**. 
Dù có 151 hay 1500 `SafetyKeywords` trong cơ sở dữ liệu, một cụm từ như *"cảm giác bóp nghẹt khó tả ở lồng ngực"* vẫn có thể lọt qua bộ lọc do không khớp chính xác, dẫn đến một **False Negative** rất nguy hiểm.

Ý tưởng ban đầu: Dùng Vector Embeddings để phân tích ngữ nghĩa các triệu chứng bị "miss" bởi hệ thống từ khóa hiện tại. Nếu câu hỏi có độ tương đồng ngữ nghĩa (cosine similarity) cao với các từ khóa khẩn cấp hiện tại (VD: > 0.85), tự động chặn yêu cầu, coi đó là cấp cứu và thêm từ khóa mới vào DB (tự cập nhật).

## Các lựa chọn (Options)

### Mức độ 1: Hoàn toàn tự động (Auto-Append & Auto-Activate)
* **Ý tưởng**: Tính cosine similarity. Nếu ≥ 0.85 → Chặn yêu cầu + Thêm từ khóa vào DB + *Kích hoạt (Activate)* rule đó ngay lập tức để áp dụng cho người dùng sau.
* **Đánh giá**: 
  * Cực kỳ nguy hiểm.
  * Nếu AI bị "ảo giác" (False Positive) hoặc nhầm ngữ cảnh âm tính giả, nó sẽ làm ô nhiễm cơ sở kiến thức cảnh báo y khoa bằng hệ thống các từ khóa sai lệch.
  * Vi phạm chuẩn an toàn của các công ty thiết bị y tế vì "Blackbox AI learning" chưa qua con người duyệt.

### Mức độ 2: Chỉ cảnh báo (No Logging, Discovery Only)
* **Ý tưởng**: Nếu độ tương đồng cao → chặn luồng yêu cầu, in ra log để debug nhưng không thay đổi DB.
* **Đánh giá**:
  * An toàn nhưng "mù". Bác sĩ và đội ngũ y tế sẽ không biết người dùng đang gặp từ khóa rủi ro nào để cải thiện Master Data theo thời gian.

### Mức độ 3: Semantic Fallback với Pending Review (Human-in-the-Loop) - Lựa chọn đã chốt
* **Ý tưởng**: 
  1. Khi người dùng nhập một triệu chứng, hệ thống trước tiên chạy qua các quy tắc (Layer 1-3).
  2. Nếu không có bắt lỗi (Missing Keyword), chạy Layer 4 (Semantic Fallback) với Gemini `embedding-001`.
  3. Tìm kiếm Vector bằng index `HNSW` của thư viện `pgvector` trên Postgres.
  4. Decision gate:
     * Tương đồng ≥ `0.82`: **BLOCK** + Đẩy từ khóa này vào bảng `SafetyKeyword` với trạng thái `PENDING`.
     * Tương đồng ≥ `0.62`: **WARN** + Đẩy từ khóa này vào `PENDING`.
     * Tương đồng < `0.62`: Cho qua.
  5. Các từ khóa `PENDING` được lưu lại nhưng **KHÔNG ĐƯỢC LOAD** vào ClinicalRules Engine (chỉ load trạng thái `ACTIVE`).
  6. Xây dựng API `/pending-review` cho Admin. Bác sĩ/Admin sẽ xác nhận (Approve) từ khóa để chuyển sang `ACTIVE` và tự cập nhật cho hệ thống, hoặc từ chối (Reject).

## Quyết định
Chúng ta chọn **Mức độ 3: Semantic Fallback với Pending Review (Human-in-the-Loop)**.
Mô hình "Rules as Data" bây giờ hoạt động như một hệ thống *Active Learning*: nó tự động phát hiện lỗ hổng tri thức, phản hồi tức thời để bảo vệ bệnh nhân (chặn), nhưng chỉ cho phép tri thức đó được đưa vào vòng sử dụng thực tiễn cho tất cả mọi người khi có sự xác thực của bác sĩ.

## Hệ quả (Consequences)

### Tích cực
1. **Zero-Miss Catch-all**: Nâng cao độ an toàn y tế lên mức sản xuất (Production-grade), theo sát quy trình của các ứng dụng sức khỏe hàng đầu như Ada Health, vốn có các bộ "Semantic Check".
2. **Khả năng tự tiến hóa**: Cơ sở từ khóa sẽ dần mở rộng hiệu quả qua những từ vựng người dùng thực sự nhập, thay vì bác sĩ phải đoán trước tại thời điểm Seed.
3. **An toàn kiểm duyệt**: Không có rủi ro ô nhiễm dữ liệu lâm sàng nhờ có vòng lặp Human-in-the-loop.

### Rủi ro cần quản lý
1. **Chi phí / Rate limit API Embedding**: Mô hình nhúng ngôn ngữ lớn có Rate Limit (đặc biệt khi dùng hàng free). Nếu API Embedding sập, kiến trúc được thiết kế dạng *Fail-open* (Catch exception -> Bỏ qua Layer 4 -> Luồng từ khóa vẫn chạy nhưng fallback an toàn).
2. Tác vụ tạo Embedding ở script `generate-keyword-embeddings.ts` cần được chạy sau mỗi lần Admin thêm mới hàng loạt Keyword chưa có index để cập nhật `HNSW`.

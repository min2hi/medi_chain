# 🏥 MediChain: Advanced Hybrid Recommendation System
## Technical Architecture & Senior Analysis

Tài liệu này phân tích kiến trúc hệ thống khuyến nghị thuốc của MediChain. Đây là sự kết hợp giữa **Expert System (Hệ chuyên gia)** và **Generative AI (AI tạo sinh)**, tạo nên một hệ thống **Deterministic (Định hướng)** và **Safe (An toàn)**.

---

## 1. Bản chất hệ thống: AI hay Recommendation System?

Một con AI thuần túy (như ChatGPT) hoạt động dựa trên xác suất ngôn ngữ. Ngược lại, **MediChain Recommendation System** hoạt động dựa trên **Dữ liệu thực thể** và **Luật y tế**.

| Đặc điểm | AI Chatbot Đơn thuần | MediChain Rec-System |
| :--- | :--- | :--- |
| **Nguồn dữ liệu** | Kiến thức huấn luyện (Cắt mốc thời gian) | Database thực tế (`DrugCandidate`) cập nhật real-time |
| **Độ chính xác** | Dễ bị "ảo giác" (Hallucination) | Chính xác 100% dựa trên danh mục thuốc có sẵn |
| **An toàn** | Chỉ đưa ra lời khuyên chung chung | Chặn cứng thuốc nguy hiểm bằng logic mã nguồn |
| **Cá nhân hóa** | Dựa trên ngữ cảnh chat | Dựa trên Profile Snapshot & Lịch sử Feedback |

---

## 2. Kiến trúc 4 lớp (The 4-Layer Architecture)

Hệ thống được thiết kế theo mô hình luồng dữ liệu một chiều để đảm bảo tính minh bạch:

### Lớp 1: Knowledge Base (Data Layer)
*   **Thực thể**: `DrugCandidate` (Định nghĩa danh mục thuốc OTC).
*   **Chỉ số**: Chứa các trường dữ liệu y tế cứng (Indications, Contraindications, Age Limits, Interaction Map).
*   **Ý nghĩa**: Đây là "chân lý" duy nhất. Hệ thống không bao giờ gợi ý một loại thuốc không tồn tại trong kho này.

### Lớp 2: Deterministic Filter (Expert System Layer)
Trước khi chấm điểm, hệ thống chạy một bộ lọc **Hard Constraints (Ràng buộc cứng)**:
*   **Allergy Check**: Loại bỏ thuốc chứa hoạt chất user bị dị ứng.
*   **Condition Check**: Loại bỏ thuốc chống chỉ định với bệnh nền (mãn tính) của user.
*   **Demographic Check**: Kiểm tra tuổi, trạng thái thai kỳ/cho con bú.
*   👉 *Kết quả: Chỉ những thuốc 100% an toàn mới được đi tiếp.*

### Lớp 3: Scoring Engine (Logic Layer)
Sử dụng thuật toán **Weighted-Sum Ranking**. Mỗi thuốc được chấm điểm từ 0-100 dựa trên:

$$FinalScore = (Profile \times 35\%) + (Safety \times 45\%) + (History \times 20\%)$$

*   **Profile Score (35%)**: Sử dụng NLP cơ bản và Keyword Mapping để khớp triệu chứng người dùng nhập với chỉ định của thuốc.
*   **Safety Score (45%)**: Đánh giá độ "lành tính" của thuốc dựa trên tương tác thuốc (Drug-Drug Interaction) và tác dụng phụ tiềm tàng.
*   **History Score (20%)**: Sử dụng dữ liệu từ bảng `TreatmentFeedback`. Nếu người dùng đã dùng và đánh giá `EFFECTIVE`, thuốc đó sẽ được "boost" điểm.

### Lớp 4: Explanation Layer (AI Overlay)
*   **Input**: Top 3-5 thuốc có điểm cao nhất + Toàn bộ hồ sơ y tế.
*   **Role**: AI đóng vai trò "Dược sĩ tư vấn".
*   **Nhiệm vụ**: Giải thích các con số khô khan bằng lời khuyên tận tâm, hướng dẫn sử dụng và đưa ra cảnh báo khẩn cấp (nếu cần).

---

## 3. Cơ chế tự học (Feedback Loop Mechanism)

Hệ thống của chúng ta không "đứng yên". Nó thông minh hơn qua mỗi lần sử dụng nhờ bảng `TreatmentFeedback`:

1.  **Dùng thuốc**: User nhận đề xuất và sử dụng.
2.  **Phản hồi**: User nhập đánh giá (Hiệu quả, Tác dụng phụ, v.v.).
3.  **Tích lũy**: Engine ghi nhận `usageCount` và hiệu quả thực tế của thuốc đó đối với **riêng cá nhân người dùng đó**.
4.  **Tối ưu**: Lần consult tiếp theo, điểm `historyScore` sẽ ưu tiên những gì đã chứng minh hiệu quả trong quá khứ.

---

## 4. Senior Review: Tại sao kiến trúc này tối ưu?

1.  **Tính kiểm soát (Full Control)**: Lập trình viên có thể điều chỉnh trọng số (Weights) bất cứ lúc nào để thay đổi hành vi hệ thống mà không cần huấn luyện lại model AI.
2.  **Tính an toàn y tế (Medical Compliance)**: Việc tách rời Logic filtering và AI explanation giúp loại bỏ hoàn toàn rủi ro AI tư vấn sai thuốc cấm.
3.  **Tính truy vết (Audit Trail)**: Mọi phiên tư vấn đều được lưu Snapshot (`profileSnapshot`). Nếu có vấn đề xảy ra, chúng ta biết chính xác tại sao hệ thống lại đưa ra kết quả đó tại thời điểm đó.

---
**Kết luận**: Đây là một hệ thống phần mềm hoàn chỉnh, sử dụng AI như một công cụ giao tiếp cao cấp, đặt trên nền tảng logic toán học mạnh mẽ của một Recommendation System hiện đại.

🧪 KỊCH BẢN KIỂM THỬ: "Vụ án thuốc Paracetamol"
Trong kho thuốc (
seed-drugs.ts
), chúng ta có Paracetamol 500mg.

Chỉ định (Symptoms match): "đau đầu, sốt".
Chống chỉ định (Contraindications): "gan, xơ gan, viêm gan".
Tương tác (Interactions): "warfarin".
Case 1: AI thông thường (Typical AI)
User nhập: "Tôi bị đau đầu quá."
AI phản hồi: "Bạn có thể dùng Paracetamol 500mg để giảm đau ngay."
Rủi ro: Nếu bạn đang bị viêm gan mà không nói, và con AI không được lập trình để check Database Profile, nó vẫn sẽ tư vấn Paracetamol. Đây là sai lầm chết người.
Case 2: MediChain Recommendation System (Kiểm chứng thực tế)
Tôi sẽ phân tích luồng chạy của hệ thống chúng ta qua 2 bước thay đổi hồ sơ:

Bước A: Hồ sơ sạch (An toàn)

Bạn nhập: "Tôi bị đau đầu".
Scoring Engine chạy:
Profile Match: 100 điểm (vì Paracetamol trị đau đầu).
Safety Filter: Pass (vì bạn không có bệnh nền gì xung đột).
Kết quả: Hệ thống xếp hạng Paracetamol đứng đầu (Rank 1) với điểm số ~90. AI sẽ khuyên bạn dùng nó.
Bước B: Hồ sơ có "Bệnh nền: Gan" (Ràng buộc an toàn)

Bạn vào trang Hồ sơ, điền vào ô Bệnh nền: "Tôi bị viêm gan B".
Bạn quay lại tư vấn: "Tôi bị đau đầu".
Scoring Engine chạy:
Nó lấy chuỗi "viêm gan B" từ hồ sơ bạn.
Nó đối soát với trường notForConditions của Paracetamol: ['gan', 'xơ gan', 'viêm gan'].
Trigger Hard Alert: Hệ thống tìm thấy từ khóa "gan" khớp nhau.
Kết quả Logic: Thay vì chấm điểm, hệ thống thiết lập isRecommended = false và gán lý do: "Chống chỉ định với bệnh gan".
Kết quả hiển thị: Paracetamol biến mất hoàn toàn khỏi danh sách gợi ý, dù nó trị đau đầu rất tốt. Thay vào đó, hệ thống sẽ đề xuất một loại thuốc giảm đau khác không hại gan, hoặc AI sẽ báo: "Không tìm thấy thuốc an toàn cho tình trạng của bạn, vui lòng đi gặp bác sĩ".
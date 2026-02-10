# 🎨 Visual Guide - Hướng dẫn Trực quan

## 📍 Vị trí các Component trên Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│                        MEDICHAIN DASHBOARD                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  👤 Chào Nguyen Van A, Sổ Y Bạ Gia Đình                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  📋 HÀNH ĐỘNG NHANH                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ Thêm hồ  │ │ Thêm     │ │ Tải lên  │ │ Chia sẻ  │          │
│  │ sơ       │ │ thuốc    │ │ xét nghiệm│ │ hồ sơ   │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  💡 LỜI KHUYÊN SỨC KHỎE  ⭐ NEW!                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 💊 Tầm soát tiểu đường cho nam giới trên 40 tuổi        │  │
│  │    Bạn nên đi khám và xét nghiệm đường huyết...   [✓][✕]│  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │ 🏃 Khuyến nghị vận động cho người trưởng thành           │  │
│  │    Hãy duy trì ít nhất 150 phút vận động...       [✓][✕]│  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  📊 TỔNG QUAN SỨC KHỎE                                          │
│  ┌─────────────────────┐  ┌─────────────────────────────────┐  │
│  │ 💓 Tình trạng       │  │ 📋 Tóm tắt y tế  [✨ Phân tích] │  │
│  │    Bình thường      │  │                      ⭐ NEW!     │  │
│  │                     │  │ • Nhóm máu: O+                  │  │
│  └─────────────────────┘  │ • Dị ứng: Penicillin            │  │
│                            │ • Bệnh nền: Cao huyết áp        │  │
│                            └─────────────────────────────────┘  │
│                                                                  │
│  ... (Các phần khác)                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                                                        ┌──────────┐
                                                        │  🤖      │
                                                        │  AI Chat │
                                                        └──────────┘
                                                        ⭐ NEW! (Floating)
```

---

## 🎯 Các Tính năng Mới

### 1️⃣ Recommendation Widget

**Vị trí**: Giữa "Hành động nhanh" và "Tổng quan sức khỏe"

**Giao diện**:
```
┌────────────────────────────────────────────────────────┐
│ 💡 Lời khuyên sức khỏe              [3 khuyến nghị]   │
├────────────────────────────────────────────────────────┤
│                                                         │
│ 🩺 Tầm soát tiểu đường cho nam giới trên 40 tuổi      │
│    Bạn nên đi khám và xét nghiệm đường huyết...  [✓][✕]│
│                                                         │
│ 🥗 Cảnh báo thừa cân                                   │
│    Chỉ số BMI của bạn cao hơn mức khuyến nghị... [✓][✕]│
│                                                         │
│ 💊 Lưu ý cho người có dị ứng                           │
│    Bạn có tiền sử dị ứng. Hãy luôn thông báo...  [✓][✕]│
│                                                         │
└────────────────────────────────────────────────────────┘

[✓] = Đánh dấu hoàn thành
[✕] = Ẩn khuyến nghị
```

**Tương tác**:
- Click vào khuyến nghị → Expand để xem chi tiết
- Click [✓] → Đánh dấu đã hoàn thành
- Click [✕] → Ẩn khuyến nghị

---

### 2️⃣ AI Chat (Floating Button)

**Vị trí**: Góc dưới bên phải màn hình (fixed position)

**Giao diện Button**:
```
                                    ┌──────────┐
                                    │    💬    │
                                    │          │ ← Floating button
                                    └──────────┘
                                        🟢 ← Online indicator
```

**Giao diện Chat Modal** (khi click vào button):
```
┌────────────────────────────────────────────────┐
│ 🤖 Trợ lý Y tế AI          [✨ New Chat] [✕]  │
│    Luôn sẵn sàng hỗ trợ bạn                    │
├────────────────────────────────────────────────┤
│                                                 │
│  🤖 Xin chào! Tôi là Trợ lý Y tế MediChain    │
│     Tôi có thể giúp bạn tư vấn về sức khỏe... │
│                                                 │
│     💊 Tôi bị đau đầu, nên làm gì?            │
│     📊 Phân tích tình trạng sức khỏe của tôi  │
│                                                 │
├────────────────────────────────────────────────┤
│ [Nhập câu hỏi của bạn...]              [📤]   │
│ ⚠️ Đây chỉ là tham khảo. Hãy hỏi bác sĩ.      │
└────────────────────────────────────────────────┘
```

**Conversation Flow**:
```
┌────────────────────────────────────────────────┐
│ 🤖 Trợ lý Y tế AI                      [✕]    │
├────────────────────────────────────────────────┤
│                                                 │
│                  👤 Tôi bị đau đầu, nên làm gì?│
│                                                 │
│  🤖 Chào bạn! Tôi hiểu bạn đang bị đau đầu.   │
│     Dựa trên hồ sơ của bạn:                    │
│                                                 │
│     1. Nghỉ ngơi ở nơi yên tĩnh                │
│     2. Uống đủ nước                             │
│     3. Có thể dùng Paracetamol 500mg            │
│                                                 │
│     ⚠️ LƯU Ý: Nếu đau đầu kèm buồn nôn...     │
│                                                 │
│                       👤 Cảm ơn bạn!           │
│                                                 │
├────────────────────────────────────────────────┤
│ [Nhập câu hỏi tiếp theo...]            [📤]   │
└────────────────────────────────────────────────┘
```

---

### 3️⃣ AI Analysis Button

**Vị trí**: Trong card "Tóm tắt y tế", góc phải header

**Giao diện**:
```
┌─────────────────────────────────────────────────┐
│ 📋 Tóm tắt y tế           [✨ Phân tích bởi AI] │ ← Button
├─────────────────────────────────────────────────┤
│ • Nhóm máu: O+                                  │
│ • Dị ứng: Penicillin                            │
│ • Bệnh nền: Cao huyết áp                        │
│ • Chỉ số gần nhất: HA 120/80 mmHg               │
└─────────────────────────────────────────────────┘
```

**Modal khi click**:
```
┌────────────────────────────────────────────────┐
│ ✨ Phân tích AI                         [✕]   │
│    Dựa trên dữ liệu y tế của bạn               │
├────────────────────────────────────────────────┤
│                                                 │
│  [Đang phân tích dữ liệu y tế của bạn...]     │
│              ⏳ Loading...                      │
│                                                 │
│  AI đang xem xét hồ sơ bệnh án, thuốc và      │
│  chỉ số sức khỏe                               │
│                                                 │
└────────────────────────────────────────────────┘

↓ Sau khi phân tích xong ↓

┌────────────────────────────────────────────────┐
│ ✨ Phân tích AI                         [✕]   │
├────────────────────────────────────────────────┤
│                                                 │
│  📊 ĐÁNH GIÁ TỔNG QUAN                         │
│  Tình trạng sức khỏe của bạn nhìn chung ổn...  │
│                                                 │
│  🔍 CÁC CHỈ SỐ ĐÁNG CHÚ Ý                      │
│  • Huyết áp: 120/80 mmHg - Bình thường         │
│  • BMI: 24.5 - Trong giới hạn khuyến nghị     │
│                                                 │
│  💡 KHUYẾN NGHỊ CẢI THIỆN                      │
│  1. Duy trì chế độ ăn ít muối                  │
│  2. Tăng cường vận động 30 phút/ngày           │
│                                                 │
│  ⚠️ LƯU Ý CẦN THEO DÕI                         │
│  • Theo dõi huyết áp định kỳ                   │
│                                                 │
├────────────────────────────────────────────────┤
│ ⚠️ Lưu ý: Đây chỉ là phân tích tham khảo.     │
│ Để có chẩn đoán chính xác, hãy hỏi bác sĩ.    │
└────────────────────────────────────────────────┘
```

---

## 🔄 User Flow

### Flow 1: Xem Khuyến nghị
```
User vào Dashboard
    ↓
Scroll xuống phần "Lời khuyên sức khỏe"
    ↓
Xem danh sách khuyến nghị
    ↓
Click vào khuyến nghị → Expand xem chi tiết
    ↓
Chọn action:
    • Click [✓] → Đánh dấu hoàn thành → Khuyến nghị biến mất
    • Click [✕] → Ẩn khuyến nghị → Khuyến nghị biến mất
```

### Flow 2: Chat với AI
```
User thấy floating button 💬 ở góc dưới phải
    ↓
Click vào button
    ↓
Chat modal mở ra
    ↓
User nhập câu hỏi hoặc click suggested question
    ↓
AI trả lời dựa trên hồ sơ y tế của user
    ↓
User tiếp tục hỏi hoặc đóng chat
```

### Flow 3: Phân tích AI
```
User vào Dashboard
    ↓
Scroll đến card "Tóm tắt y tế"
    ↓
Click button "✨ Phân tích bởi AI"
    ↓
Modal mở ra, hiển thị loading
    ↓
AI phân tích dữ liệu y tế
    ↓
Hiển thị kết quả phân tích chi tiết
    ↓
User đọc và đóng modal
```

---

## 🎨 Color Scheme

### Recommendation Categories
```
🩺 SCREENING (Tầm soát)    → 🔴 Red/Orange gradient
🥗 NUTRITION (Dinh dưỡng)  → 🟢 Green/Emerald gradient
🏃 EXERCISE (Vận động)     → 🔵 Blue/Cyan gradient
💊 MEDICATION (Thuốc)      → 🟣 Purple/Pink gradient
```

### AI Components
```
AI Chat Button             → 🟣 Indigo to Purple gradient
AI Analysis Button         → 🟣 Purple to Pink gradient
AI Messages (User)         → 🔵 Blue to Cyan gradient
AI Messages (Assistant)    → ⚪ White/10 opacity
```

---

## 📱 Responsive Design

### Desktop (>1024px)
- RecommendationWidget: Full width
- AI Chat: 420px width modal
- AI Analysis: 800px width modal

### Tablet (768px - 1024px)
- RecommendationWidget: Full width
- AI Chat: 90% width modal
- AI Analysis: 90% width modal

### Mobile (<768px)
- RecommendationWidget: Full width, stack vertically
- AI Chat: Full screen modal
- AI Analysis: Full screen modal

---

## 🎯 Key Features Highlight

```
┌─────────────────────────────────────────────────┐
│  ⭐ RECOMMENDATION SYSTEM                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ✅ Tự động tạo dựa trên quy tắc y tế          │
│  ✅ Cá nhân hóa theo tuổi, giới tính, BMI      │
│  ✅ 6 health rules mẫu từ BYT/WHO              │
│  ✅ UI đẹp với animations                       │
│  ✅ Complete/Dismiss actions                    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  ⭐ AI CHAT WITH RAG                            │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ✅ Context-aware (hiểu hồ sơ bệnh án)         │
│  ✅ Floating button + chat modal                │
│  ✅ Real-time messaging                         │
│  ✅ Typing indicators                           │
│  ✅ Suggested questions                         │
│  ✅ Safety warnings (dị ứng, cấp cứu)          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  ⭐ AI ANALYSIS                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ✅ One-click analysis                          │
│  ✅ Comprehensive health overview               │
│  ✅ Actionable recommendations                  │
│  ✅ Beautiful modal UI                          │
└─────────────────────────────────────────────────┘
```

---

**Enjoy your new features! 🎉**

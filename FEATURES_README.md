# 🚀 Hướng dẫn Tích hợp Hệ thống Khuyến nghị & AI Chat

## 📋 Tổng quan

Đã tích hợp thành công 2 tính năng mới vào MediChain:

### 1. **Hệ thống Khuyến nghị (Recommendation System)**
- ✅ Rule-based engine tự động tạo khuyến nghị dựa trên:
  - Tuổi, giới tính
  - BMI (Body Mass Index)
  - Tiền sử dị ứng
  - Bệnh nền
- ✅ 6 health rules mẫu từ BYT/WHO
- ✅ UI widget đẹp mắt với animations
- ✅ Actions: Complete, Dismiss

### 2. **AI Chat với RAG (Retrieval-Augmented Generation)**
- ✅ Context-aware: AI hiểu hồ sơ bệnh án của từng user
- ✅ Floating chat button
- ✅ Chat modal với typing indicators
- ✅ AI Analysis button trong "Tóm tắt y tế"
- ✅ Mock AI responses (sẵn sàng tích hợp OpenAI/Gemini)

---

## 🗄️ Database Schema

### Models mới:
1. **HealthRule** - Quy tắc y tế
2. **Recommendation** - Khuyến nghị cho user
3. **AIConversation** - Cuộc trò chuyện với AI
4. **AIMessage** - Tin nhắn trong conversation

---

## 🛠️ Cài đặt & Chạy

### Bước 1: Start Database
```powershell
# Từ thư mục root
docker-compose up -d db
```

### Bước 2: Chạy Migration
```powershell
cd backend
npx prisma migrate dev
```

Migration sẽ tạo các bảng mới: `HealthRule`, `Recommendation`, `AIConversation`, `AIMessage`

### Bước 3: Generate Prisma Client
```powershell
npx prisma generate
```

### Bước 4: Seed Health Rules (Tùy chọn)
```powershell
# Cách 1: Qua API (đơn giản hơn)
# Start backend trước, sau đó:
curl -X POST http://localhost:5000/api/recommendations/seed-rules

# Cách 2: Chạy script
npx tsx src/scripts/seed-recommendations.ts
```

### Bước 5: Start Backend
```powershell
npm run dev
```

### Bước 6: Start Frontend
```powershell
cd ../frontend
npm run dev
```

---

## 🎯 API Endpoints

### Recommendation APIs
```
GET    /api/recommendations              # Lấy danh sách khuyến nghị
POST   /api/recommendations/generate     # Tạo khuyến nghị tự động
PUT    /api/recommendations/:id/complete # Đánh dấu hoàn thành
PUT    /api/recommendations/:id/dismiss  # Ẩn khuyến nghị
POST   /api/recommendations/manual       # Tạo khuyến nghị thủ công
POST   /api/recommendations/seed-rules   # Seed health rules
```

### AI Chat APIs
```
POST   /api/ai/chat                      # Chat với AI
GET    /api/ai/conversations             # Lấy danh sách conversations
GET    /api/ai/conversations/:id/messages # Lấy messages
DELETE /api/ai/conversations/:id         # Xóa conversation
POST   /api/ai/analyze                   # Phân tích dữ liệu y tế
```

---

## 🎨 UI Components

### 1. RecommendationWidget
- **Vị trí**: Dashboard, sau "Hành động nhanh"
- **File**: `frontend/src/components/shared/RecommendationWidget.tsx`
- **Features**:
  - Auto-fetch recommendations
  - Category icons & colors
  - Expand/collapse content
  - Complete/Dismiss actions

### 2. AIChat
- **Vị trí**: Global floating button (bottom-right)
- **File**: `frontend/src/components/shared/AIChat.tsx`
- **Features**:
  - Floating action button
  - Chat modal
  - Real-time messaging
  - Typing indicators
  - Suggested questions

### 3. AIAnalysisButton
- **Vị trí**: "Tóm tắt y tế" card header
- **File**: `frontend/src/components/shared/AIAnalysisButton.tsx`
- **Features**:
  - Trigger AI analysis
  - Loading state
  - Modal hiển thị kết quả

---

## 🤖 Tích hợp AI API thật (OpenAI/Gemini)

Hiện tại đang dùng **mock responses**. Để tích hợp AI thật:

### Option 1: OpenAI
```typescript
// backend/src/services/ai.service.ts
// Thay hàm callAI()

static async callAI(systemPrompt: string, userMessage: string): Promise<string> {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
            model: 'gpt-4o-mini',
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userMessage },
            ],
        }),
    });
    
    const data = await response.json();
    return data.choices[0].message.content;
}
```

Thêm vào `.env`:
```
OPENAI_API_KEY=sk-...
```

### Option 2: Google Gemini
```typescript
// Cài package
npm install @google/generative-ai

// Trong ai.service.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

static async callAI(systemPrompt: string, userMessage: string): Promise<string> {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    const prompt = `${systemPrompt}\n\nUser: ${userMessage}`;
    const result = await model.generateContent(prompt);
    return result.response.text();
}
```

---

## 📊 Health Rules Mẫu

Hệ thống đã có 6 rules mẫu:

1. **Tầm soát tiểu đường** (nam/nữ ≥40 tuổi)
2. **Cảnh báo thừa cân** (BMI >25)
3. **Cảnh báo thiếu cân** (BMI <18.5)
4. **Lưu ý dị ứng** (có tiền sử dị ứng)
5. **Khuyến nghị vận động** (≥18 tuổi)

### Thêm Rule mới

```typescript
// Qua API
POST /api/recommendations/manual
{
  "title": "Khám mắt định kỳ",
  "content": "Người trên 60 tuổi nên khám mắt 1 năm/lần",
  "category": "SCREENING",
  "priority": 4,
  "source": "BYT"
}

// Hoặc thêm vào database trực tiếp
await prisma.healthRule.create({
  data: {
    name: "Khám mắt định kỳ cho người cao tuổi",
    description: "...",
    category: "SCREENING",
    priority: 4,
    conditions: JSON.stringify({ age: ">=60" }),
    recommendation: "Bạn nên khám mắt định kỳ 1 năm/lần...",
    source: "BYT",
  }
});
```

---

## 🧪 Testing

### Test Recommendation System
1. Đảm bảo user có profile với đầy đủ thông tin (tuổi, giới tính, cân nặng, chiều cao)
2. Gọi API generate:
```bash
curl -X POST http://localhost:5000/api/recommendations/generate \
  -H "Authorization: Bearer YOUR_TOKEN"
```
3. Kiểm tra dashboard - widget sẽ hiển thị recommendations

### Test AI Chat
1. Click vào floating button (bottom-right)
2. Thử các câu hỏi:
   - "Tôi bị đau đầu, nên làm gì?"
   - "Phân tích tình trạng sức khỏe của tôi"
   - "Tôi có thể uống Paracetamol không?"
3. AI sẽ trả lời dựa trên hồ sơ y tế của bạn

### Test AI Analysis
1. Vào Dashboard
2. Trong card "Tóm tắt y tế", click "Phân tích bởi AI"
3. Xem kết quả phân tích

---

## 🔧 Troubleshooting

### Lỗi: "Property 'aIConversation' does not exist"
**Nguyên nhân**: Prisma Client chưa được generate sau khi thêm models mới

**Giải pháp**:
```powershell
cd backend
npx prisma generate
```

### Lỗi: "Can't reach database server"
**Nguyên nhân**: PostgreSQL chưa chạy

**Giải pháp**:
```powershell
docker-compose up -d db
```

### Recommendations không hiển thị
**Nguyên nhân**: Chưa có health rules hoặc user chưa có profile đầy đủ

**Giải pháp**:
1. Seed health rules: `POST /api/recommendations/seed-rules`
2. Đảm bảo user có profile với birthday, gender, weight, height
3. Generate recommendations: `POST /api/recommendations/generate`

### AI Chat không hoạt động
**Nguyên nhân**: Backend chưa chạy hoặc CORS issue

**Giải pháp**:
1. Kiểm tra backend đang chạy: `http://localhost:5000`
2. Kiểm tra token trong localStorage
3. Xem console log để debug

---

## 📈 Roadmap & Cải tiến

### Ngắn hạn
- [ ] Tích hợp OpenAI/Gemini API thật
- [ ] Thêm nhiều health rules hơn
- [ ] Notification khi có recommendation mới
- [ ] Export recommendations to PDF

### Dài hạn
- [ ] Machine Learning model cho personalized recommendations
- [ ] Voice input cho AI Chat
- [ ] Multi-language support
- [ ] Integration với wearable devices (Apple Watch, Fitbit)

---

## 📝 Notes

- **Security**: Trong production, cần thêm rate limiting cho AI APIs
- **Cost**: OpenAI API có phí, cân nhắc dùng Gemini (free tier) hoặc self-hosted Llama
- **Privacy**: Medical data rất nhạy cảm, đảm bảo encrypt và comply với HIPAA/GDPR
- **Disclaimer**: Luôn nhắc user rằng AI chỉ là tham khảo, không thay thế bác sĩ

---

## 🎉 Kết luận

Bạn đã tích hợp thành công 2 tính năng quan trọng:
1. ✅ **Recommendation System** - Tự động khuyến nghị dựa trên quy tắc y tế
2. ✅ **AI Chat với RAG** - Trợ lý y tế thông minh hiểu context

Hệ thống đã sẵn sàng để demo và phát triển thêm! 🚀

---

**Tác giả**: Antigravity AI Assistant  
**Ngày tạo**: 2026-02-03  
**Version**: 1.0.0
